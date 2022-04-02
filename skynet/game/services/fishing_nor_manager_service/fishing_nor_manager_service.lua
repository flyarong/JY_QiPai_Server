--人满分配
--auther ：hewei

local basefunc = require "basefunc"
require"printfunc"

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "printfunc"

local fishing_matching = require "fishing_nor_manager_service.fishing_matching"


local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA
local PROTECTED = {}

 
--最大同时在线人数
local max_game_palyers=600


local return_table={result=0}


local dt=0.2
local function update()
	while true do
		
		PUBLIC.matching_update(dt)
		
		skynet.sleep(dt*100)
		
	end
end

local function use_config()
	
	--报名结果缓存
	DATA.player_signup_result_cache = {
		result = 0,
		name = DATA.game_config.game_name,
		game_type = DATA.game_config.game_type,
		game_model = DATA.game_config.game_model,
		init_rate = DATA.game_config.game_rule.init_rate,
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


	DATA.signup_status = 1

	if DATA.game_config.enable ~= 1 then
		DATA.signup_status = 0
	end

end



local function init()

	--所有的玩家总数
	DATA.all_player_count = 0

	--所有的玩家信息
	DATA.all_player_info = {}

	DATA.real_player_count=0
	
	use_config()

	PUBLIC.init()
	
	skynet.fork(update)
	
end



function PUBLIC.check_allow_signup()

	-- 禁用
	if DATA.signup_status == 0 then
		return false,1009
	end

	-- 所有玩家数量超过场次的最大人数，显示错误:系统繁忙
	if DATA.all_player_count>=max_game_palyers then
		--服务器繁忙 请稍后再试
		return false,1008
	end

	return true
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
		condi_data = DATA.enter_game_cfg,
		game_type = DATA.game_type,
		game_level = DATA.game_config.game_rule.game_level,
	}

end


--一局游戏完成  
function CMD.table_finish(_room,_table)
	local players = DATA.running_game[_room][_table]
	if players then

		for i,_player_id in pairs(players) do
			local p = DATA.all_player_info[_player_id]
			if p then
				p.ready = 0
				p.status = "waiting"
			end
		end

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

	DATA.all_player_info[player_info.id]=player_info

	DATA.all_player_count=DATA.all_player_count +1
	if not DATA.all_player_info[player_info.id].is_robot then
		DATA.real_player_count = DATA.real_player_count + 1
	end
	
	-- 一人一桌 直接分配
	PUBLIC.distribution_players({player_info.id})

	print("fsg player_signup "..player_info.id )

	return_table.result = 0
	return return_table
end


-- 玩家退出了
function CMD.player_exit_game(_player_id)

	local player_info = DATA.all_player_info[_player_id]
	
	if not player_info then
		print("freestyle player_exit_game player_info is nil "..(_player_id or "") )
		return_table.result = 1002
		return return_table
	end

	DATA.all_player_count = DATA.all_player_count - 1 
	if not player_info.is_robot then
		DATA.real_player_count = DATA.real_player_count - 1
	end

	DATA.all_player_info[_player_id]=nil
	
	return_table.result = 0
	return return_table

end


function CMD.reload_config(_config)
	set_all_player_cfg_reload()

	DATA.game_config = _config

	use_config()

end


function CMD.start(_id,_service_config,_game_config)

	math.randomseed(os.time()*37187)


	DATA.service_config=_service_config

	DATA.my_id=_id

	DATA.game_config = _game_config

	init()

end

-- 启动服务
base.start_service()


