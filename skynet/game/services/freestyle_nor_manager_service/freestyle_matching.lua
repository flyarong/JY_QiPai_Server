--人满分配
--auther ：hewei

local basefunc = require "basefunc"
require"printfunc"

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "ddz_match_enum"
require "normal_enum"
require "printfunc"

local monitor_lib = require "monitor_lib"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA
local PROTECTED = {}

local distribution_queue=basefunc.queue.new()

local min_table_num = 3 

local once_max_distribution=30

local room_count_id=0
--创建房间id
local function create_room_id()
	room_count_id=room_count_id+1
	return DATA.my_id.."_room_"..room_count_id
end
local max_table_num=nil
local function new_room()
	local room_id=create_room_id()
	if room_id then
		--创建房间
		local ret,state = skynet.call(DATA.service_config.node_service,"lua","create",nil,
						DATA.game_room_service_type,
						room_id,{mgr_id=DATA.my_id,game_type=DATA.game_type,jdz_type=DATA.jdz_type , game_model = "freestyle" , game_id = DATA.game_config.game_id })
		if not ret then
			print(string.format("freestyle_matching error:call  state:%s",state))
			return
		end
		if not max_table_num then
			local num=nodefunc.call(room_id,"get_free_table_num")
			if num=="CALL_FAIL" then
				print(string.format("freestyle_matching error:call get_free_table_num room_id:%s",room_id))
				return
			else
				max_table_num=num
			end
		end
		DATA.free_table_room_map[room_id]=max_table_num
		DATA.all_table_count=DATA.all_table_count+max_table_num
	end
	-- body
end
local function new_table(_game_tag)
	local room_id
	for id,v in pairs(DATA.free_table_room_map) do
		room_id=id
		break
	end

	---- 没有房间就先创建
	if not room_id then
		new_room()
		for id,v in pairs(DATA.free_table_room_map) do
			room_id=id
			break
		end
	end
	if room_id then
		DATA.free_table_room_map[room_id]=DATA.free_table_room_map[room_id]-1
		DATA.all_table_count=DATA.all_table_count-1
		if DATA.free_table_room_map[room_id]==0 then
			DATA.busy_table_room_map[room_id]=DATA.free_table_room_map[room_id]
			DATA.free_table_room_map[room_id]=nil
		end
		if DATA.all_table_count < min_table_num then
			new_room()
		end

		--创建桌子
		local t_num=nodefunc.call(room_id,"new_table",
									{	model_name = DATA.game_config.game_model,
										game_type = DATA.game_type,
										jdz_type = DATA.jdz_type,
										rule_config = DATA.table_rule_config,
										game_config = DATA.table_game_config,
										nice_pai_rate = DATA.game_config.nice_pai_rate.rate or 0,
										game_tag = _game_tag,
									},
									{
										game_id=DATA.game_config.game_id
									})
		if t_num=="CALL_FAIL" then
			print(string.format("freestyle_matching error:call new_table room_id:%s",room_id))
			return nil
		end
		return room_id,t_num
	end
	return nil
end

local function distribution()
	local count=once_max_distribution
	while count>0 do
		if distribution_queue:empty() then
			break
		end
		
		local players=distribution_queue:pop_front()
		local game_tag = DATA.all_player_info[players[1]].game_tag
		local room_id,t_num=new_table(game_tag)

		if room_id and t_num then
			DATA.running_game[room_id]=DATA.running_game[room_id] or {}
			DATA.running_game[room_id][t_num]=players
			dump(players,"xxxxxxxxdistributionxxxxxxxxx")
			for i,player_id in ipairs(players) do
				DATA.all_player_info[player_id].status="gaming"
				DATA.all_player_info[player_id].room=room_id
				DATA.all_player_info[player_id].table=t_num

				--- 因为每次开一局，都会到这里来，所以房间的开关刷新在new_table就做了，所以agent的刷新放这里
				local is_reload_cfg = false
				if DATA.is_reload_config[player_id] then
					is_reload_cfg = true

					DATA.is_reload_config[player_id] = nil
				end

				nodefunc.send(player_id,"fg_enter_room_msg",room_id,t_num,i , is_reload_cfg)
			end

			count=count-1

			PUBLIC.start_match_log(room_id,t_num,game_tag)

		end
	end
end


local destroyRoomCountDown=0
local destroyRoomCountDownIn=300
local function destroyRoom()
	local player_num=distribution_queue:size() or 0
	if max_table_num and DATA.all_table_count-player_num>max_table_num*2 then
		for id,v in pairs(DATA.free_table_room_map) do
			if v==max_table_num then
				DATA.free_table_room_map[id]=nil
				DATA.all_table_count=DATA.all_table_count-max_table_num
				nodefunc.send(id,"destroy")
				if DATA.all_table_count-player_num<=max_table_num*2 then
					break
				end
			end
		end
	end
end


function PUBLIC.distribution_players(_players)
	distribution_queue:push_back(_players)
end


function PUBLIC.table_finish(_room_id,_t_num )
	print("PUBLIC.table_finish!!",_room_id,_t_num)
	---清理
	if _room_id and _t_num and DATA.running_game[_room_id] and DATA.running_game[_room_id][_t_num] then
		local players = DATA.running_game[_room_id][_t_num]
		
		dump(players,"send fg_gameover_msg")

		for k,player_id in pairs(players) do

			nodefunc.send(player_id,"fg_gameover_msg",is_reload_cfg)

		end

		local settlement_score_data = DATA.settlement_score_data[_room_id .. _t_num]
		if settlement_score_data and type(settlement_score_data) == "table" then
			local is_submit_profit = false
			local profit_loss = 0
			local profit = 0
			local loss = 0
			local real_player_num = 0

			for player_id , data in pairs(settlement_score_data) do
				--- 加日志
				PUBLIC.add_match_player_log(_room_id,_t_num,player_id
					,data.score
					,data.real_score)

				--- 如果是托管，就累计
				if not basefunc.chk_player_is_real(player_id) then
					is_submit_profit = true
					profit_loss = profit_loss + data.real_score
					if data.real_score >= 0 then
						profit = profit + data.real_score
					else
						loss = loss + data.real_score
					end
				else
					real_player_num = real_player_num + 1
				end

			end

			--- 上报
			if is_submit_profit then
				skynet.send(DATA.service_config.game_profit_manager,"lua","submit_match_profit_loss" , GAME_FORM.freestyle ,DATA.game_config.game_id , profit , loss , real_player_num)
				--- 报警提示
				monitor_lib.add_data("profit_lose",-profit_loss)
			end
			
		end
		--dump( settlement_score_data , ">>>>>  table_finish 22 ")
		DATA.settlement_score_data[_room_id .. _t_num] = nil


		PUBLIC.add_match_log(_room_id,_t_num)
		DATA.running_game[_room_id][_t_num] = nil
	end

end


-- 归还桌子
function PUBLIC.return_table(_room_id,_t_num )

	DATA.all_table_count=DATA.all_table_count+1

	if DATA.free_table_room_map[_room_id] then
		DATA.free_table_room_map[_room_id]=DATA.free_table_room_map[_room_id]+1
	elseif DATA.busy_table_room_map[_room_id] then
		DATA.busy_table_room_map[_room_id]=DATA.busy_table_room_map[_room_id]+1
		DATA.free_table_room_map[_room_id]=DATA.busy_table_room_map[_room_id]
		DATA.busy_table_room_map[_room_id]=nil
	else
		skynet.fail(string.format("freestyle_matching table_finish error:room_id not exist room_id:%s",_room_id))
		return 
	end

end





function PUBLIC.matching_update(dt)
	distribution()
	destroyRoomCountDown=destroyRoomCountDown+dt
	if destroyRoomCountDown>=destroyRoomCountDownIn then
		destroyRoomCountDown=0
		destroyRoom()
	end
end
function PUBLIC.init()
	DATA.free_table_room_map={}
	DATA.busy_table_room_map={}
	DATA.running_game={}
	DATA.all_table_count=0
	
end


return PROTECTED









