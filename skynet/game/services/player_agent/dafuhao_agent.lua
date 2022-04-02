--
-- Created by wss.
-- User: hare
-- Date: 2018/12/28
-- Time: 19:29
-- 大富豪  agent
--


local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST
local PUBLIC = base.PUBLIC

--- 玩家的大富豪数据
DATA.player_dafuhao_data = {}

DATA.common_task_protect = {}
local PROTECT = DATA.common_task_protect


function REQUEST.query_dafuhao_base_info()
	local ret = {}
	--- 操作限制
	if PUBLIC.get_action_lock("query_dafuhao_base_info") then
		ret.result = 1008
		return ret
	end
	PUBLIC.on_action_lock( "query_dafuhao_base_info" )

	DATA.player_dafuhao_data = skynet.call( DATA.service_config.da_fu_hao_activity_service , "lua" , "query_one_player_data" , DATA.my_id )

	if not DATA.player_dafuhao_data then
		ret.result = 1004

		PUBLIC.off_action_lock( "query_dafuhao_base_info" )
		return ret
	end

	ret.result = 0
	ret.need_credits = DATA.player_dafuhao_data.need_credits
	ret.now_credits = DATA.player_dafuhao_data.now_credits

	PUBLIC.off_action_lock( "query_dafuhao_base_info" )
	return ret
end

function REQUEST.dafuhao_game_kaijiang()
	local ret = {}
	--- 操作限制
	if PUBLIC.get_action_lock("dafuhao_game_kaijiang") then
		ret.result = 1008
		return ret
	end
	PUBLIC.on_action_lock( "dafuhao_game_kaijiang" )


	local kaijiang = skynet.call( DATA.service_config.da_fu_hao_activity_service , "lua" , "dafuhao_kaijiang" , DATA.my_id , DATA.player_data.player_info.name ) 

	if not kaijiang then
		ret.result = 1004
		PUBLIC.off_action_lock( "dafuhao_game_kaijiang" )
		return ret
	end

	if type(kaijiang) == "number" then
		ret.result = kaijiang
		PUBLIC.off_action_lock( "dafuhao_game_kaijiang" )
		return ret
	end

	ret.result = 0
	ret.award_id = kaijiang.award_id
	DATA.player_dafuhao_data.now_game_num = kaijiang.now_game_num
	DATA.player_dafuhao_data.need_credits = kaijiang.need_credits
	DATA.player_dafuhao_data.now_credits = kaijiang.now_credits

	----- 通知改变
	PUBLIC.request_client("dafuhao_base_info_change",{ 
														need_credits = DATA.player_dafuhao_data.need_credits ,
														now_credits = DATA.player_dafuhao_data.now_credits })


	PUBLIC.off_action_lock( "dafuhao_game_kaijiang" )
	return ret
end

function REQUEST.dafuhao_get_broadcast()
	local ret = {}
	--- 操作限制
	if PUBLIC.get_action_lock("dafuhao_get_broadcast") then
		ret.result = 1008
		return ret
	end
	PUBLIC.on_action_lock( "dafuhao_get_broadcast" )

	local broadcast = skynet.call( DATA.service_config.da_fu_hao_activity_service , "lua" , "get_one_kaijiang_broadcast" ) 

	if type(broadcast) == "number" then
		ret.result = broadcast
		PUBLIC.off_action_lock( "dafuhao_get_broadcast" )
		return ret
	end

	ret.result = 0
	ret.player_name = broadcast.player_name
	ret.award_id = broadcast.award_id

	---- 名字处理一下
	local player_name_vec = basefunc.string.string_to_vec(ret.player_name)
	if player_name_vec and type(player_name_vec) == "table" and next(player_name_vec) then
		if #player_name_vec > 3 then
			ret.player_name = player_name_vec[1] .. "**" .. player_name_vec[#player_name_vec]
		elseif #player_name_vec == 3 then
			ret.player_name = player_name_vec[1] .. "*" .. player_name_vec[#player_name_vec]
		elseif #player_name_vec == 2 then
			ret.player_name = player_name_vec[1] .. "*"
		elseif #player_name_vec == 1 then
			ret.player_name = tostring( player_name_vec[1] )
		end
	end

	PUBLIC.off_action_lock( "dafuhao_get_broadcast" )
	return ret
end


function PROTECT.init()
	DATA.player_dafuhao_data = skynet.call( DATA.service_config.da_fu_hao_activity_service , "lua" , "query_one_player_data" , DATA.my_id )

end

return PROTECT
