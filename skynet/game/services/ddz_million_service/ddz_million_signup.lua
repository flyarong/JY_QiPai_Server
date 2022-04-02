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

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA
local PROTECTED={}

--比赛管理器
local manager

local enter_condition={}
local match_info={}

DATA.signup_players_count = 0
DATA.signup_players_map = {}


local function init_enter_condition()
	
end


local function init_match_info()

	match_info={
		name = DATA.match_config.base_info.name,
		bonus = DATA.match_config.base_info.bonus,
		issue = DATA.match_config.base_info.issue,
		total_round = #DATA.match_config.process,
		signup_time = DATA.match_config.base_info.signup_time,
		begin_time = DATA.match_config.base_info.begin_time,
		match_svr_id = DATA.my_id,
	}

end

--比赛开始
local function match_game_start()

	if DATA.status == DDZM_STATUS.SIGNUP then

		if DATA.signup_players_count<DATA.match_config.base_info.min_player then
			

			--比赛作废
			for id,player_id in pairs(DATA.signup_players_map) do
				nodefunc.send(player_id,"dbwg_discard_msg",
									DATA.signup_players_count,
									DATA.match_config.base_info.min_player
									)
			end

			PUBLIC.game_final_finish()
			print("万人大奖赛 人数不足 本次比赛作废...",
					DATA.signup_players_count,
					DATA.match_config.base_info.min_player)
			
			DATA.status = DDZM_STATUS.FINISHED
			
		else

			
			print("万人大奖赛 比赛开始...")

			skynet.send(DATA.service_config.ddz_million_center_service,"lua",
						"change_match_status",DDZM_STATUS.MATCH)

			manager.game_begin()

			DATA.status = DDZM_STATUS.MATCH

		end

	end
end


--获取进入条件
function CMD.get_enter_condition()
	
	--[[
	{
		{
			asset_type=PLAYER_ASSET_TYPES.xxx,
			condi_type=NOR_CONDITION_TYPE.xxx,
			value=xxx
		},
	}
	]]

	return 0,enter_condition

end


-- 撤销报名
function CMD.cancel_signup(_player_id)

	if DATA.status < DDZM_STATUS.SIGNUP then
		return 2004
	elseif DATA.status > DDZM_STATUS.SIGNUP then
		return 2013
	end

	if DATA.signup_players_map[_player_id] then
		DATA.signup_players_map[_player_id]=nil
		DATA.signup_players_count=DATA.signup_players_count-1
		return 0
	end
	
	return 2011
end


function CMD.player_signup(_player_id)

	if DATA.status < DDZM_STATUS.SIGNUP then
		return 2014
	elseif DATA.status > DDZM_STATUS.SIGNUP then
		return 2015
	end

	if DATA.signup_players_map[_player_id] then
		return 2010
	else

		if DATA.signup_players_count+1>DATA.match_config.base_info.max_player then
			return 2001
		else

			DATA.signup_players_map[_player_id]=_player_id
			DATA.signup_players_count=DATA.signup_players_count+1
			manager.refresh_players_num()
			return 0,match_info

		end

	end

end


function PROTECTED.init(_manager)

	manager = _manager

	init_enter_condition()
	init_match_info()

	DATA.signup_players_map={}
	DATA.signup_players_count = 0

	local start_time_delay = DATA.match_config.base_info.begin_time-os.time()
	skynet.timeout(start_time_delay*100,match_game_start)

end

return PROTECTED

