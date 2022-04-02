--
-- Author: hw
-- Date: 2018/3/28
-- Time: 
-- 说明：比赛场管理服务

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "ddz_match_enum"
require "normal_enum"
require "printfunc"
local match_active_player_num_config = require "match_active_player_num_config"

local monitor_lib = require "monitor_lib"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local launch_entity = nil
local tuoguan_enter_ctrl = nil

DATA.service_config = nil
DATA.my_id = nil
DATA.match_config = nil

DATA.player_msg_name = nil
DATA.game_rule_config = nil
DATA.receive_result_cmd = nil

DATA.player_last_opt_time = 0

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
		tuoguan_enter_ctrl = require "match_tuoguan_enter_ctrl"
	elseif DATA.match_config.signup_model == "dingshikai" then
		launch_entity = require "match_dingshikai"
	elseif DATA.match_config.signup_model == "danrenkai" then
		launch_entity = require "match_danrenkai"
	end

	launch_entity.init()
	
	tuoguan_enter_ctrl.init(DATA.match_config.tuoguan_enter_config,launch_entity)
	
end


-- 比赛中的人数
local function get_active_player_num(_game_id)
	local cfg = match_active_player_num_config[_game_id]
	local max_num = 0
	if cfg then
		max_num = cfg.max_num
	end

	local function get_k()
		local t = os.date("*t")
		local k
		if t.hour >= 8 and t.hour <= 10 then
			k = 0.3
		elseif t.hour > 10 and t.hour <= 12 then
			k = 0.4
		elseif t.hour > 12 and t.hour <= 15 then
			k = 0.5
		elseif t.hour > 15 and t.hour <= 17 then
			k = 0.6
		elseif t.hour > 17 and t.hour <= 19 then
			k = 0.7
		elseif t.hour > 19 and t.hour <= 22 then
			k = 0.8
		elseif t.hour > 22 and t.hour <= 24 then
			k = 1
		elseif t.hour >= 0 and t.hour <= 2 then
			k = 0.9
		elseif t.hour > 2 and t.hour < 8 then
			k = 0.1
		end
		return k
	end

	local num = math.floor(get_k() * max_num)

	local t = math.floor(os.time()/10)%10

	local r = ((t+1)*1539632197+_game_id*623547)%20

	return num + r
end



-- 本服务结束 要销毁了
function PUBLIC.exit()

	skynet.send(DATA.service_config.match_center_service,"lua","manager_service_destory",DATA.match_config.game_id)

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
	
	match_active_player_num_cache.num = count + get_active_player_num(DATA.match_config.game_id)

	return match_active_player_num_cache

end


--查询比赛状态
function CMD.query_start_time()
	return "CALL_FAIL"
end

--查询比赛总排行
function CMD.query_all_rank()
	return "CALL_FAIL"
end

function CMD.record_players_info(_player_id,_player_name,_head_link)
	
end

--查询游戏玩家状态
function CMD.query_game_player_status()
	
	local begin_game_condi = DATA.match_config.signup_data_config.begin_game_condi
	
	return 
	{
		cur_count = DATA.signup_players_count,
		start_count = begin_game_condi,
		player_last_opt_time = os.time() - DATA.player_last_opt_time,
	}
end

function CMD.reload_config(_cfg)

	DATA.match_config = _cfg

	launch_entity.use_new_config()

	--下次开更新
	tuoguan_enter_ctrl.delay_reload_config(DATA.match_config.tuoguan_enter_config,launch_entity)

	return 0
end

function CMD.match_over(_match_svr_id,_data)

	-------------------------- 上报 ------------------
	local profit_loss = 0
	local profit = 0
	local loss = 0
	local is_submit_profit = false
	local real_player_num = 0

	for rank , data in pairs(_data) do
		if basefunc.chk_player_is_real(data.player_id) then
			real_player_num = real_player_num + 1
			--- 报名费
			local last_enter_cfg = DATA.match_config.match_enter_config[#DATA.match_config.match_enter_config]

			for key,enter_data in pairs(last_enter_cfg) do

				if enter_data.judge_type == NOR_CONDITION_TYPE.CONSUME then
					local add_value = basefunc.trans_asset_to_jingbi( enter_data.asset_type , enter_data.asset_count )
					profit_loss = profit_loss + add_value
					profit = profit + add_value
				end
			end
			
			is_submit_profit = true
			for key,award_data in pairs(data.award) do
				local loss_value = basefunc.trans_asset_to_jingbi( award_data.asset_type , award_data.value )
				profit_loss = profit_loss - loss_value
				loss = loss - loss_value
			end
		end
	end
	if is_submit_profit then
		--- 报警提示
		monitor_lib.add_data("profit_lose",-profit_loss)
		skynet.send(DATA.service_config.game_profit_manager,"lua","submit_match_profit_loss" , GAME_FORM.matchstyle ,DATA.match_config.game_id , profit , loss , real_player_num)
	end

	--
	launch_entity.game_complete(_match_svr_id)
end



function CMD.start(_id,_service_config,_match_config)

	math.randomseed(os.time()*78415)

	DATA.service_config=_service_config
	DATA.my_id=_id
	DATA.match_config = _match_config

	--dump(DATA.match_config , "----------------- normal_match_manager_service,match_config")

	init()
	
end

-- 启动服务
base.start_service()
