--
-- Author: yy
-- Date: 2018/3/28
-- Time: 
-- 说明：冠名赛管理服务

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "ddz_match_enum"
require "normal_enum"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local LOCAL={}

local launch_entity = nil
DATA.service_config = nil
DATA.my_id = nil
DATA.match_config = nil

DATA.player_msg_name = nil
DATA.game_rule_config = nil
DATA.receive_result_cmd = nil

DATA.player_last_opt_time = 0

local UPDATE_INTERVAL = 1

DATA.tuoguan_num = 0
DATA.begin_time = 0

local return_msg={result=0}

local players_info = {}

local rank_list = {}

local function init()

	--啓動配置
	DATA.player_msg_name={
		begin_msg="nor_mg_begin_msg",
		enter_room_msg="nor_mg_enter_room_msg",
		change_rank_msg="nor_mg_change_rank_msg",
		promoted_final_msg="nor_mg_promoted_final_msg",
		promoted_msg="nor_mg_promoted_msg",
		gameover_msg="nor_mg_gameover_msg",
		wait_result_msg="nor_mg_wait_result_msg",
		score_change_msg="nor_mg_score_change_msg",
		wait_revive_msg="nor_mg_wait_revive_msg",
		free_revive_msg="nor_mg_free_revive_msg",
	}

	DATA.receive_result_cmd = "match_over"


	if DATA.match_config.signup_model == "renmanjikai"  then
		launch_entity = require "match_renmanjikai"
	elseif DATA.match_config.signup_model == "dingshikai" then
		launch_entity = require "match_dingshikai"
	end

	LOCAL.init_data()

	launch_entity.init()
	
end


local function req_tuoguan(_n)

	local _game_info = 
	{
		game_id = DATA.match_config.game_id,
		game_type = DATA.match_config.game_type,
		service_id = DATA.my_id,
		match_name = "match_game",
	}

	skynet.send(DATA.service_config.tuoguan_service,"lua","assign_tuoguan_player",_n,_game_info)

end


-- local req_tuoguan_time = 0
-- local final_req_tuoguan_time = 0
-- local final_req_tuoguan_threshold = nil
-- local function tuoguan_update()

-- 	local need_tuoguan_num = DATA.tuoguan_num

-- 	-- 5分钟后 需要的托管数量为 本身要请求的数量 和 需要开赛的人数 的最大值
-- 	local bt = DATA.begin_time - os.time()
-- 	if bt < 5*60 and bt > 0 then
-- 		local np = DATA.match_services[DATA.signup_match_my_id].data_config.signup_data_config.begin_game_condi 
-- 					- DATA.signup_players_count

-- 		need_tuoguan_num = math.max(DATA.tuoguan_num,np)

-- 	end
-- 	-- 定时请求托管
-- 	if need_tuoguan_num > 0 
-- 		and DATA.tuoguan_signup_num < need_tuoguan_num
-- 		and DATA.begin_time > os.time() 
-- 		and DATA.match_config.signup_data_config.begin_signup_time < os.time() then

-- 		local lt = DATA.begin_time - os.time()
-- 		local n = need_tuoguan_num - DATA.tuoguan_signup_num

-- 		if not final_req_tuoguan_threshold then
-- 			final_req_tuoguan_threshold = math.random(50,100)
-- 		end

-- 		-- 5min 托管会自动取消报名 所有 后面可能会有大量的缺失
-- 		if lt < final_req_tuoguan_threshold then
-- 			-- 时间快到了 全部来吧

-- 			if final_req_tuoguan_time < os.time() then
-- 				req_tuoguan(n)
-- 				final_req_tuoguan_time = os.time() + 20
-- 			end

-- 		else

-- 			-- 留一点时间 避免和 全部拉的时候一起冲突
-- 			if lt < final_req_tuoguan_threshold+20 then
-- 				return
-- 			end

-- 			if req_tuoguan_time < os.time() then 

-- 				local nt = math.random(1,math.ceil(n*0.05))
-- 				req_tuoguan( nt )
	
-- 				local rt = math.floor((nt/n)*lt)
-- 				req_tuoguan_time = os.time() + rt + math.random(-4,2)

-- 			end

-- 		end

-- 	end

-- end


local function refresh_data()
	
	local tec = DATA.match_config.tuoguan_enter_config

	if tec and tec.tuoguan_limit and tec.tuoguan_limit > 0 then

		local t = CMD.query_start_time()
		DATA.begin_time = t.start_time

		DATA.tuoguan_num = tec.tuoguan_limit - 1

		print("nm req tuoguan_num :" , DATA.tuoguan_num)
	end

end


function PUBLIC.exit()

	nodefunc.destroy(DATA.my_id)

	skynet.sleep(200)
	
	skynet.exit()
end

-- 检查是否可以停止服务
function PUBLIC.try_stop_service(_count,_time)

	--立即设置为不可以报名
	DATA.signup_status = MATCH_STATUS.DISABLE

	if DATA.signup_players_count>0 then
		return "wait",string.format(" '%s' is not stopped!",DATA.my_id)
	end

	local num = 1
	for k,ms in pairs(DATA.match_services) do
		if num > 1 then
			return "wait",string.format(" '%s' is not stopped!",DATA.my_id)
		end

		if next(ms.players) then
			return "wait",string.format(" '%s' is not stopped!",DATA.my_id)
		end

		num = num + 1
	end

	return "stop"
end


-- 比赛被放弃
function PUBLIC.match_discard()

	for player_id,d in pairs(DATA.signup_players) do
		nodefunc.send(player_id,"nor_mg_match_discard_msg")
	end

end


--初始化
function LOCAL.init_data()

	rank_list = skynet.call(DATA.service_config.data_service,"lua","query_naming_match_rank",DATA.match_config.game_id)

	refresh_data()
end


function update(dt)
	
	-- tuoguan_update()

end


--查询比赛状态
function CMD.query_start_time()

	local start_time = DATA.match_config.signup_data_config.begin_signup_time
							+DATA.match_config.signup_data_config.signup_dur

	return {result=0,start_time=start_time}
end


--查询比赛配置
function CMD.query_cfg()
	return DATA.match_config
end

--查询比赛总排行
function CMD.query_all_rank()
	if not next(rank_list) then
		return_msg.result=1004
		return return_msg
	end

	return {result=0,rank_list=rank_list}
end


local query_match_active_player_num_time = 0
local query_match_active_player_num_dt = 2
local match_active_player_num_cache = {result=0,num=0}
-- 查询 比赛 活动中的玩家总数 (所有正在玩的玩家)
function CMD.query_match_active_player_num()
	
	if query_match_active_player_num_time > os.time() then
		return match_active_player_num_cache
	end
	query_match_active_player_num_time = os.time() + query_match_active_player_num_dt

	if not DATA.match_services then
		match_active_player_num_cache.num = 0
		return match_active_player_num_cache
	end

	local count = 0
	for k,ms in pairs(DATA.match_services) do
		
		local d = nodefunc.call(ms.match_my_id,"get_match_player_num")
		if type(d) == "table" then
			count = count + d.match_player_num
		end

	end
	
	match_active_player_num_cache.num = count

	return match_active_player_num_cache

end

function CMD.record_players_info(_player_id,_player_name,_head_link)
	players_info[_player_id]={
		player_name = _player_name,
		head_link = _head_link,
	}
end



function CMD.reload_config(_cfg)

	DATA.match_config = _cfg

	launch_entity.use_new_config()

	refresh_data()
	
	return 0
end

--比赛结束了
function CMD.match_over(_match_svr_id,_data)

	rank_list = {}

	for i,winner in ipairs(_data) do

		rank_list[#rank_list+1]=
		{
			match_name = DATA.match_config.match_data_config.name,
			player_id = winner.player_id,
			score = winner.score,
			rank = winner.rank,
			hide_score = winner.hide_score,
			match_model = DATA.match_config.match_model,
			player_name = players_info[winner.player_id].player_name or "",
			revive_num = winner.revive_num,
			head_link = players_info[winner.player_id].head_link or "",

		}

		skynet.send(DATA.service_config.data_service,"lua","insert_naming_match_rank"
				,DATA.match_config.game_id,rank_list[#rank_list])

	end

	launch_entity.game_complete(_match_svr_id)

end



function CMD.start(_id,_service_config,_match_config)

	math.randomseed(os.time()*78415)

	DATA.service_config=_service_config
	DATA.my_id=_id
	DATA.match_config = _match_config

	init()

	local start_time = DATA.match_config.signup_data_config.begin_signup_time
							+DATA.match_config.signup_data_config.signup_dur


	-- 延迟等待一下
	skynet.timeout(500,function ()
		skynet.timer(UPDATE_INTERVAL,update)
	end)

end

-- 启动服务
base.start_service()
