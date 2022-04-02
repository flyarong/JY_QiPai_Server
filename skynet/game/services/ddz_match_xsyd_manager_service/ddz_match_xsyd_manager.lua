--
-- Author: lyx
-- Date: 2018/4/14
-- Time: 16:33
-- 说明：比赛 报名 模块
--

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "ddz_match_enum"
require "normal_enum"
require "printfunc"

local xsyd_record = require "ddz_match_xsyd_manager_service.ddz_match_xsyd_record_log"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA
local PROTECTED = {}
-- 最大游戏数量
local max_game_player_count = 2000

--游戏状态 0-正常  1-服务器即将关闭  2-新手引导已经关闭
PROTECTED.game_status = 0

local once_max_distribution=60

local player_signup_map={}

local real_player_signup_map={}
local real_player_signup_count=0

local robot_player_signup_map={}
local robot_player_signup_count=0

local busy_table_room_map={}

local free_table_room_map={}
local all_table_count=0

local game_round_config
local award_config
local match_model
local init_prel_score = 1000

--正在运行的游戏  k =room_id  v  ={  k=t_num  v=players } 
local running_game={}
--k playerID v {grades  hide_grafes}
local running_players={}

local distribution_queue=basefunc.queue.new()

local room_count_id = 0

local player_signup_result_cache = {
		result = 0,
		name = "xsyd",
		is_cancel_signup = 0,
		cancel_signup_cd = 0,
		total_players = 3,
		total_round = 1,
		signup_num=1,
	}
--创建房间id
local function create_room_id()
	room_count_id=room_count_id+1
	return DATA.my_id.."_room_"..room_count_id
end
local max_table_num=nil
local function  new_room()
	local room_id=create_room_id()
	if room_id then
		--创建房间
		local ret,state = skynet.call(DATA.service_config.node_service,"lua","create",nil,
						"common_ddz_nor_room_service/common_ddz_nor_room_service",
						room_id,{mgr_id=DATA.my_id,game_type="nor_ddz_nor_xsyd"})
		if not ret then
			skynet.fail(string.format("create_matching_entries error:call ddz_match_room_service state:%s",state))
			return
		end
		if not max_table_num then
			local num=nodefunc.call(room_id,"get_free_table_num")
			if num=="CALL_FAIL" then
				skynet.fail(string.format("create_matching_entries error:call get_free_table_num room_id:%s",room_id))
				return
			else
				max_table_num=num
			end
		end
		free_table_room_map[room_id]=max_table_num
		all_table_count=all_table_count+max_table_num
	end
	-- body
end
local function new_table()
	local room_id
	for id,v in pairs(free_table_room_map) do
		room_id=id
		break
	end
	free_table_room_map[room_id]=free_table_room_map[room_id]-1
	all_table_count=all_table_count-1
	if free_table_room_map[room_id]==0 then
		busy_table_room_map[room_id]=free_table_room_map[room_id]
		free_table_room_map[room_id]=nil
	end
	if all_table_count<2 then
		new_room()
	end

	local t_num=nodefunc.call(room_id,"new_table",
								{	model_name=match_model,
									game_type=DATA.match_config.game_type,
									rule_config = nil,
									game_config = game_round_config,
								},
								{
									game_id=DATA.match_config.game_id
								})
	return room_id,t_num
end

local function addRobot()
	skynet.call(DATA.service_config.robot_service,"lua","assign_robot",
   				"xsyd",2,{game_id=1})

end
local function distribution()
	local count=once_max_distribution
	while count>0 do
		if distribution_queue:empty() then
			break
		end

		local players=distribution_queue:pop_front()
		dump(players)
		local room_id,t_num=new_table()
		running_game[room_id]=running_game[room_id] or {}
		running_game[room_id][t_num]=players

		for i,player_id in ipairs(players) do
			running_players[player_id]={grades=init_prel_score,hide_grades=0}
			nodefunc.send(player_id,"nor_mg_begin_msg",DATA.my_id,
								init_prel_score,1,3)
			nodefunc.send(player_id,"nor_mg_enter_room_msg",
							room_id,t_num,game_round_config)
		end

		PUBLIC.start_match_log(room_id,t_num)
		
		count=count-1
	end
end
local function matching()
	if robot_player_signup_count>1 and real_player_signup_count>0 then
		local players={}
		for id,v in pairs(robot_player_signup_map) do
			players[#players+1]=id
			robot_player_signup_map[id]=nil
			robot_player_signup_count=robot_player_signup_count-1
			if #players==2 then
				break
			end
		end
		for id,v in pairs(real_player_signup_map) do
			players[#players+1]=id
			real_player_signup_map[id]=nil
			real_player_signup_count=real_player_signup_count-1
			break
		end
		--加入分配队列
		if #players==3 then
			distribution_queue:push_back(players)			
		else
			skynet.fail(string.format("matching error:player not right!!!"))
		end
	end
end

local function get_award(rank)
	return award_config[rank] or {}
end

local function gameover(_room_id,_t_num)

	local players=running_game[_room_id][_t_num]
	running_game[_room_id][_t_num]=nil
	local rank={}
	for _,id in ipairs(players) do
		local info=running_players[id]
		running_players[id]=nil
		info.id=id
		rank[#rank+1]=info
		player_signup_map[id]=nil
	end
	table.sort(rank,function (a,b)
			if a.grades>b.grades then
				return true 
			end
			if a.grades<b.grades then
				return false
			end
			if a.hide_grades>b.hide_grades then
				return true
			end
			return false
		end)
	for r,info in ipairs(rank) do
		local award=get_award(r)
		nodefunc.send(info.id,"nor_mg_gameover_msg",r,award,DATA.match_id)

		PUBLIC.add_match_player_log(_room_id,_t_num,info.id,info.grades,r,award)
		
	end

	PUBLIC.add_match_log(_room_id,_t_num)
	
end

local function destroyTable()
	local player_num=distribution_queue:size() or 0
	if max_table_num and all_table_count-player_num>max_table_num*2 then
		for id,v in pairs(free_table_room_map) do
			if v==max_table_num then
				free_table_room_map[id]=nil
				all_table_count=all_table_count-max_table_num
				nodefunc.send(id,"destroy")
				if all_table_count-player_num<=max_table_num*2 then
					break
				end
			end
		end
	end
end

function CMD.table_finish(_room_id,_t_num)
	all_table_count=all_table_count+1

	if free_table_room_map[_room_id] then
		free_table_room_map[_room_id]=free_table_room_map[_room_id]+1
	elseif busy_table_room_map[_room_id] then
		busy_table_room_map[_room_id]=busy_table_room_map[_room_id]+1
		free_table_room_map[_room_id]=busy_table_room_map[_room_id]
		busy_table_room_map[_room_id]=nil
	else
		skynet.fail(string.format("table_finish error:room_id not exist room_id:%s",_room_id))
		return 
	end
	
	gameover(_room_id,_t_num)
end
function CMD.change_grades(player_id,grades,hide_grades)
	running_players[player_id].grades=grades
	running_players[player_id].hide_grades=hide_grades
end
-- 得到已报名人数，要求报名人数
-- 返回： {result=错误码,signup_num=已报名人数}
local _signup_player_count_cache = {result = 0,signup_num=1}
function CMD.get_signup_player_num(_match_svr_id)
	--永远一个人
	return _signup_player_count_cache
end

-- 撤销报名
function CMD.cancel_signup(_match_svr_id,_my_id)
	if player_signup_map[_my_id] then
		local info=player_signup_map[_my_id]
		player_signup_map[_my_id]=nil
		if info.is_robot then
			robot_player_signup_map[_my_id]=nil
			robot_player_signup_count=robot_player_signup_count-1	
		else
			real_player_signup_map[_my_id]=nil
			real_player_signup_count=real_player_signup_count+1
		end

		return 0
	end
	
	return 2004
end

function CMD.player_signup(_my_id,_is_robot)
	if PROTECTED.game_status ~= 0 then
		return {result=1009}
	end
	if player_signup_map[_my_id] then
		return {result=2010}
	end
	player_signup_map[_my_id]={id=_my_id,is_robot=_is_robot}
	if _is_robot then
		robot_player_signup_map[_my_id]=true
		robot_player_signup_count=robot_player_signup_count+1
		--匹配
		matching()
	else
		real_player_signup_map[_my_id]=true
		real_player_signup_count=real_player_signup_count+1
		--添加机器人
		addRobot()
	end
	return player_signup_result_cache
end


function PROTECTED.get_run_player_num()
	local num = distribution_queue:size() + real_player_signup_count
	return num
end

function PROTECTED.stop_signup()
	PROTECTED.game_status = 1
end


function PROTECTED.use_new_config()
	if DATA.match_config.enable == 0 then
		PROTECTED.game_status = 2
	else
		PROTECTED.game_status = 0
		PROTECTED.reload_config()
	end
end


function PROTECTED.reload_config()

	game_round_config = DATA.match_config.match_game_config[1]
	award_config = DATA.match_config.match_award_config
	match_model = DATA.match_config.match_model
	init_prel_score = DATA.match_config.match_data_config.init_prel_score

	return 0
end

-- 初始化 报名模块
function PROTECTED.init()

	new_room()

	PROTECTED.reload_config()

	if not game_round_config or not award_config or not match_model then
		skynet.fail("game_round_config/award_config is error")
		return 
	end

	skynet.fork(function ()
		while true do
			distribution()
			skynet.sleep(100)
		end
	end)
	skynet.fork(function ()
		while true do
			destroyTable()
			skynet.sleep(60000)
		end
	end)
	
end


return PROTECTED

