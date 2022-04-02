--人满分配
--auther ：hewei

local basefunc = require "basefunc"
require"printfunc"

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "freestyle_nor_manager_service.freestyle_matching"
local quick_matching = require "freestyle_nor_manager_service.quick_matching"
local xsyd_matching = require "freestyle_nor_manager_service.xsyd_matching"

require "freestyle_nor_manager_service.freestyle_record_log"
require "ddz_match_enum"
require "normal_enum"
require "printfunc"

local nor_mj_algorithm_lib = require "nor_mj_algorithm_lib"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA
local PROTECTED = {}

--- 是否重加载过配置,key = room_id .. table_id
DATA.is_reload_config = {}

DATA.PlayerStatus = {
	waiting = "waiting",         --A等待匹配   B方案 
	ready = "ready",      --准备好
	matching = "ready",   --匹配完成 等待分配桌子
	gaming = "gaming",    --游戏中

}

DATA.real_player_count = 0
DATA.player_last_opt_time = 0

--[[
	玩家状态
		waiting  --A等待匹配   B方案 
		ready --准备好
		matching --匹配完成 等待分配桌子
		gaming  --游戏中


--]]
local GAME_STATUS =
{
	DISABLE = -1, -- 禁用（已经被 管理员配置为禁用，不允许再报名）
	WAIT_BEGIN = 0, -- 等待报名开始
	SIGNUP = 1, -- 报名中
	SIGNUP_END = 2, -- 报名结束
	MATCHING= 3, -- 正在比赛
	OVER = 4, -- 比赛结束
	W_DISPATCH=5,
}
 

--最大同时在线人数
local max_game_palyers=2000

--- 预分配的房间数量
local pre_create_room_num = 3

--所有的房间总数
DATA.room_count = 0
--房间信息 room_id={ 1={status=gaming,players={}}}
DATA.room_info = {}


local return_table={result=0}

---- 刷新配置
--[[DATA.config_last_change_time = 0
local refresh_config_dt = 1000
local function refresh_kaiguan_config()
	local data , _time = nodefunc.get_kaiguan_multi_cfg( DATA.game_config.game_type )
	if not data or DATA.config_last_change_time == _time then
		skynet.timeout( refresh_config_dt , refresh_kaiguan_config )
		return
	end
	DATA.config_last_change_time = _time

	local kaiguan_multi_cfg = nodefunc.trans_kaiguan_multi_cfg( data , DATA.game_config.kaiguan_multi )

	DATA.table_rule_config = {}
	---- 传入默认开关，番数
	DATA.kaiguan = kaiguan_multi_cfg and kaiguan_multi_cfg.kaiguan or nil
	DATA.multi = kaiguan_multi_cfg and kaiguan_multi_cfg.multi or nil

	DATA.table_rule_config.kaiguan = DATA.kaiguan
	DATA.table_rule_config.multi = DATA.multi 
	--dump(DATA.kaiguan , "-----------------?>>>> refresh_kaiguan_config ,kaiguan")
	--dump(DATA.multi , "-----------------?>>>> refresh_kaiguan_config ,multi")
	skynet.timeout( refresh_config_dt , refresh_kaiguan_config )
end--]]

function CMD.get_kaiguan_cfg_time()
	return DATA.config_last_change_time
end

function CMD.get_kaiguan_cfg()
	return { kaiguan = DATA.kaiguan , multi = DATA.multi }
end

local function use_config()

	--报名结果缓存
	DATA.player_signup_result_cache = {
		result = 0,
		name = DATA.game_config.game_name,
		game_type = DATA.game_config.game_type,
		jdz_type = DATA.game_config.jdz_type,
		game_model = DATA.game_config.game_model,
		is_cancel_signup = DATA.game_config.game_rule.is_cancel_signup,
		cancel_signup_cd = DATA.game_config.game_rule.cancel_cd,
		init_rate = DATA.game_config.game_rule.init_rate,
		init_stake = DATA.game_config.game_rule.init_stake,
		room_rent = DATA.game_config.room_rent,
	}

	DATA.enter_game_cfg = {}
	for i,cfg in ipairs(DATA.game_config.enter_cfg) do

		DATA.enter_game_cfg[#DATA.enter_game_cfg+1]=
		{
			asset_type = cfg.asset_type,
			value = cfg.asset_count,
			condi_type = cfg.judge_type,
		}
		
	end

	local game_type = DATA.game_config.game_type
	DATA.game_type = game_type
	DATA.game_seat_num = GAME_TYPE_SEAT[game_type]             -- 座位数量
	DATA.game_room_service_type = GAME_TYPE_ROOM[game_type]    -- 房间服务名

	DATA.jdz_type = DATA.game_config.jdz_type

	--麻将和斗地主的封顶 特殊处理一下
	DATA.table_game_config = {
		init_rate=DATA.game_config.game_rule.init_rate,
		init_stake=DATA.game_config.game_rule.init_stake,
		feng_ding=DATA.game_config.game_rule.max_rate,
		yingfengding=DATA.game_config.game_rule.yingfengding,
		break_exit = DATA.game_config.game_rule.break_exit,
	}

	DATA.table_rule_config = {}
	---- 传入默认开关，番数
	DATA.kaiguan = DATA.game_config.kaiguan_multi and DATA.game_config.kaiguan_multi.kaiguan or nil
	DATA.multi = DATA.game_config.kaiguan_multi and DATA.game_config.kaiguan_multi.multi or nil

	DATA.config_last_change_time = os.time()

	DATA.table_rule_config.kaiguan = DATA.kaiguan
	DATA.table_rule_config.multi = DATA.multi 
end

local dt=0.2
local function update()
	while true do
		
		skynet.sleep(dt*100)
		PUBLIC.matching_update(dt*100)

		quick_matching.update(dt*100)

		xsyd_matching.update(dt*100)
		
	end
end


local function init_data()
	---- 处理一下配置
	use_config()

	quick_matching.init()

	xsyd_matching.init()

	--- 数据处理完成，设置状态为可以报名
	DATA.signup_status = GAME_STATUS.SIGNUP
end




local function init()
	--所有的玩家总数
	DATA.all_player_count = 0
	--所有的玩家信息 player_id={status=gaming,room_id,table_id,}
	DATA.all_player_info = {}

	DATA.real_player_count=0

	--等待的玩家 player_id={room_id,table_id,}
	DATA.wait_player = {}
	DATA.wait_player_count=0

	DATA.settlement_score_data = {}

	PUBLIC.init()

	-- 处理一下配置
	init_data()
	
	skynet.fork(update)
	
end

function PUBLIC.check_allow_signup()

	-- 禁用
	if DATA.signup_status == GAME_STATUS.DISABLE then
		return false,1009
	end

	-- 所有玩家数量超过场次的最大人数，显示错误:系统繁忙
	if DATA.all_player_count>=max_game_palyers then
		--服务器繁忙 请稍后再试
		return false,1008
	end

	return true
end




--查询游戏玩家状态
function CMD.query_game_player_status()

	return 
	{-- 永远不需要托管自己来,由我自己请求来
		cur_count = DATA.game_seat_num,--PUBLIC.get_cur_count()
		start_count = DATA.game_seat_num,
		player_last_opt_time = os.time() - DATA.player_last_opt_time,
	}

end

--[[ 请求进入信息---条件和游戏类型
-- 说明：player agent 根据返回的条件，决定 扣除 还是比较 用户的财富值
-- 返回 errcode,数据
-- 如果 errcode 为 0 ，则成功，数据为以下结构：
	{
		{asset_type=PLAYER_ASSET_TYPES.xxx,condi_type=NOR_CONDITION_TYPE.xxx,value=xxx},
		{asset_type=PLAYER_ASSET_TYPES.xxx,condi_type=NOR_CONDITION_TYPE.xxx,value=xxx},
		...
	}
--]]
function CMD.get_enter_info(_enter_config_id)

	-- 判断条件
	local ok,err = PUBLIC.check_allow_signup()
	if not ok then
		return err
	end

	return 0,{
		condi_data=DATA.enter_game_cfg,
		game_type=DATA.game_config.game_type,
		jdz_type=DATA.game_config.jdz_type,
		game_level=DATA.game_config.game_rule.game_level,
	}

end


function CMD.update_player_score(_player_id,_score,_real_score,_cur_score)
	
	local pif = DATA.all_player_info[_player_id]
	if pif then
		pif.score = _cur_score

		--[[DATA.settlement_score_data[_player_id][pif.room .. pif.table]={
			score = _score,
			real_score = _real_score,
		}--]]

		DATA.settlement_score_data[pif.room .. pif.table] = DATA.settlement_score_data[pif.room .. pif.table] or {}
		DATA.settlement_score_data[pif.room .. pif.table][_player_id] = 
		{
			score = _score,
			real_score = _real_score,
		}


	end
	
end

-- 设置玩家可以退出游戏了
function CMD.set_player_game_status(_player_id,_can_exit_game)
	local pif = DATA.all_player_info[_player_id]
	if pif then
		pif.status = "can_exit_game"
	end
end

--一局游戏完成  
function CMD.table_finish(_room,_table)
	print("CMD.table_finish!!",_room,_table)
	local players = DATA.running_game[_room][_table]
	dump(players,"table_finish")
	if players then
		local table_id = nil
		for i,_player_id in pairs(players) do
			DATA.all_player_info[_player_id].ready = 0
			DATA.all_player_info[_player_id].status = "waiting"
			table_id = DATA.all_player_info[_player_id].table_id
		end

		quick_matching.table_finish(table_id)

		xsyd_matching.table_finish(table_id)

		PUBLIC.table_finish(_room,_table)
	else
		print("error!!! freestyle_nor_manager_service table_finish DATA.running_game[_room][_table] is nil",_room,_table)
	end

end


-- 归还桌子
function CMD.return_table(_room_id,_t_num)
	
	PUBLIC.return_table(_room_id,_t_num )

end
--[[报名
]]
function CMD.player_signup(player_info)
	if DATA.all_player_info[player_info.id] then
		print("freestyle player_signup errorxxx "..(player_info.id or ""))
		return_table.result = 2023
		return return_table
	end
	local ok,err = PUBLIC.check_allow_signup()
	if not ok then
		return_table.result = err
		return return_table
	end

	DATA.player_last_opt_time = os.time()

	DATA.all_player_info[player_info.id]=player_info

	DATA.all_player_count=DATA.all_player_count +1
	if not DATA.all_player_info[player_info.id].is_robot then
		DATA.real_player_count = DATA.real_player_count + 1
	end
	
	print("freestyle player_signup "..player_info.id )

	if player_info.game_tag == GAME_TAG.normal then
		return quick_matching.player_signup(player_info.id)
	elseif player_info.game_tag == GAME_TAG.xsyd then
		return xsyd_matching.player_signup(player_info.id)
	end

	return quick_matching.player_signup(player_info.id)

end

-- 玩家退出了
function CMD.player_exit_game(_player_id)
	DATA.is_reload_config[_player_id] = nil

	DATA.player_last_opt_time = os.time()

	local player_info = DATA.all_player_info[_player_id]
	
	if not player_info then
		print("freestyle player_exit_game player_info is nil "..(_player_id or "") )
		return_table.result = 1002
		return return_table 
	end

	local ret
	if player_info.game_tag == GAME_TAG.normal then
		ret = quick_matching.player_exit_game(_player_id)
	elseif player_info.game_tag == GAME_TAG.xsyd then
		ret = xsyd_matching.player_exit_game(_player_id)
	else
		ret = quick_matching.player_exit_game(_player_id)
	end

	if ret and ret.result == 0 then

		DATA.all_player_count = DATA.all_player_count - 1 
		if not player_info.is_robot then
			DATA.real_player_count = DATA.real_player_count - 1
		end

		DATA.all_player_info[_player_id]=nil
		print("freestyle player_exit_game ok ".._player_id )

	end

	dump(ret,"freestyle player_exit_game ret ".._player_id)

	return ret

end

-- 准备
function CMD.ready(_player_id)

	local player_info = DATA.all_player_info[_player_id]

	if not player_info then
		return_table.result = 1002
		return return_table 
	end

	DATA.player_last_opt_time = os.time()

	if player_info.game_tag == GAME_TAG.normal then
		return quick_matching.ready(_player_id)
	elseif player_info.game_tag == GAME_TAG.xsyd then
		return xsyd_matching.ready(_player_id)
	end

	return quick_matching.ready(_player_id)

end

-- 取消准备
function CMD.cancel_ready(_player_id)
end

--[[换桌
--]]
function CMD.huanzhuo(_player_id)

	DATA.player_last_opt_time = os.time()

	local player_info = DATA.all_player_info[_player_id]

	if not player_info then
		return_table.result = 1002
		return return_table 
	end

	if player_info.game_tag == GAME_TAG.normal then
		return quick_matching.huanzhuo(_player_id)
	elseif player_info.game_tag == GAME_TAG.xsyd then
		return xsyd_matching.huanzhuo(_player_id)
	end

	return quick_matching.huanzhuo(_player_id)

end

local function set_all_player_cfg_reload()

	for player_id,data in pairs(DATA.all_player_info) do
		DATA.is_reload_config[player_id] = true
	end
		
end

---- 开关改变时，要让正在运行的房间的开关也改变
function PUBLIC.refresh_room_table_kaiguan(room_id , t_num)
	
	nodefunc.call(room_id,"refresh_kaiguan_multi",t_num , DATA.kaiguan , DATA.multi)

end


function CMD.reload_config(_config)
	set_all_player_cfg_reload()

	DATA.game_config = _config

	use_config()

	if DATA.game_config.enable == 0 then
		DATA.signup_status = GAME_STATUS.DISABLE
	end

end


function CMD.start(_id,_service_config,_game_config)

	math.randomseed(os.time()*37187)


	DATA.service_config=_service_config

	DATA.my_id=_id

	DATA.game_config = _game_config

	init()

	--refresh_kaiguan_config()
end

-- 启动服务
base.start_service()


