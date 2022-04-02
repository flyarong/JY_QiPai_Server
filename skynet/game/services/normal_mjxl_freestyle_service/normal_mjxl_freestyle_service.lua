--
-- Author: hw
-- Date: 2018/3/28
-- Time: 
-- 说明：比赛场服务 进行匹配和安排

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "normal_enum"
require "printfunc"
require "normal_mjxl_freestyle_service.normal_mjxl_freestyle_matching"
require "normal_mjxl_freestyle_service.normal_mjxl_freestyle_record_log"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

DATA.service_config = nil
DATA.my_id = nil

-- 对局 局数
DATA.game_num = 0

DATA.game_config = nil


--[[玩家的信息 player_id => info
	{
	grades=1254501,	--分数
	status=0,	-- 0-等待中 1-游戏中 2-结算中
	}
]]
DATA.player_infos={}

-- 房间集合：room_id => tables[table_id => info]
DATA.room_infos={}

--玩家总数
DATA.player_count=0

--真实玩家总数
DATA.real_player_count=0

--[[最后有玩家活动的时间点
	有玩家报名或取消报名进行重置
	有桌子打完比赛进行重置
]]
DATA.player_last_opt_time=0

--可用的空桌子队列 {room_id}
DATA.available_tables = basefunc.queue.new()

--正在排队中的玩家们 ids
DATA.wait_players={}

-- 0-ok  1-no
local signup_status = 0

local enter_condition_cache = nil
local replay_condition_cache = nil

local function init_enter_condition()
	enter_condition_cache = {}
	replay_condition_cache = {}
	for or_i,or_cfg in ipairs(DATA.game_config.enter_cfg) do
		enter_condition_cache[or_i]={}
		replay_condition_cache[or_i]={}
		for and_i,and_cfg in ipairs(or_cfg) do
			enter_condition_cache[or_i][and_i]=
			{
				condi_type = and_cfg.judge_type,
				asset_type = and_cfg.asset_type,
				value = and_cfg.asset_count,
			}
			replay_condition_cache[or_i][and_i]=
			{
				condi_type = and_cfg.judge_type,
				asset_type = and_cfg.asset_type,
				value = and_cfg.asset_count,
			}
			if and_cfg.judge_type == NOR_CONDITION_TYPE.GREATER then
				replay_condition_cache[or_i][and_i].value = DATA.game_config.min_coin
			end
		end
	end
end


--获取进入条件
function CMD.get_enter_condition(_enter_config_id,_is_replay)

	_enter_config_id = _enter_config_id or 1

	if _is_replay then

		if replay_condition_cache[_enter_config_id] then
			return 0,replay_condition_cache[_enter_config_id]
		else
			return 2002
		end

	end
	
	if enter_condition_cache[_enter_config_id] then
		return 0,enter_condition_cache[_enter_config_id]
	else
		return 2002
	end

end



--报名
function CMD.player_signup(_player_id)

	if "running" == DATA.current_service_status then

		if signup_status ~= 0 then
			return {result=2018}
		end

		local player_info = DATA.player_infos[_player_id]
		if player_info then
			return {result=2010}
		else
			print("freestyle mjxl player_signup ok. userid,service id :",_player_id,DATA.my_id)
			DATA.player_infos[_player_id]=
			{
				status=0,
				grades=0,
			}
			DATA.wait_players[#DATA.wait_players+1]=_player_id
			DATA.player_count = DATA.player_count + 1
			if basefunc.chk_player_is_real(_player_id)then
				DATA.real_player_count = DATA.real_player_count + 1
			end
			DATA.player_last_opt_time = os.time()
			PUBLIC.start_match()

			return 
			{
				result=0,
				name = DATA.game_config.name,
				is_cancel_signup=1,
				match_svr_id=DATA.my_id,
				game_model=DATA.game_config.game_model,
				max_coin = DATA.game_config.max_coin,
				min_coin = DATA.game_config.min_coin,
				cancel_signup_cd=DATA.game_config.cancel_cd,
			}
		end

	else
		return {result=1009}
	end

end

--取消报名
function CMD.cancel_signup(_player_id)

	local player_info = DATA.player_infos[_player_id]
	if player_info then
		
		if player_info.status == 0 then
			DATA.player_infos[_player_id]=nil

			for i,player_id in ipairs(DATA.wait_players) do
				if player_id == _player_id then
					table.remove(DATA.wait_players,i)
					break
				end
			end
			DATA.player_count = DATA.player_count - 1
			if basefunc.chk_player_is_real(_player_id)then
				DATA.real_player_count = DATA.real_player_count - 1
			end
			DATA.player_last_opt_time = os.time()


			print("freestyle cancel_signup ok:",_player_id)
			return 0
		else
			return 2012
		end

	else
		return 2011
	end

end


--胡完牌了，提前退出--不能提前退出


--查询游戏玩家状态
function CMD.query_game_player_status()
	

	return 
	{
		wait_player_count = #DATA.wait_players,
		player_count = DATA.player_count,
		real_player_count = DATA.real_player_count,
		player_last_opt_time = os.time() - DATA.player_last_opt_time
	}
end



--停止游戏状态
local stop_game_state = nil

--停止游戏
local function stop_game()
	
	if stop_game_state then
		--已经在停止了
		return
	end

	--###test
	print("mjxl freestyle stop_game")
	stop_game_state = 1

	skynet.timeout(200,function ()

		--销毁房间
		for room_id,_ in pairs(DATA.room_infos) do
			nodefunc.send(room_id,"destroy")
		end

		--销毁自己
    	nodefunc.destroy(DATA.my_id)
		skynet.exit()

	end)

end


function PUBLIC.try_stop_service(_count,_time)

	--查看还有几个人再玩呢
	local player_num = 0
	for k,v in pairs(DATA.player_infos) do
		player_num = player_num + 1
	end

	if player_num > 1 then
		return "wait","match game is running ! player num:"..player_num
	else
		stop_game()
		return "wait","recording log !"
	end
	
end


function CMD.reload_config(_cfg)
	DATA.game_config = _cfg
	
	init_enter_condition()

	if DATA.game_config.enable == 1 then
		signup_status = 0
	else
		signup_status = 1
	end

	print(string.format("mjxl_freestyle_service config %d reloaded !",_cfg.id))

	return 0
end


function CMD.start(_my_id,_service_config,_cfg)

	math.randomseed(os.time()*78415)

	DATA.service_config=_service_config
	DATA.my_id = _my_id
	DATA.game_config = _cfg

	init_enter_condition()

	PUBLIC.init_matching()
	
end


-- 启动服务
base.start_service()