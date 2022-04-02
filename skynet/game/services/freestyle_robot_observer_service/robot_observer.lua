--
-- Author: lyx
-- Date: 2018/5/30
-- Time: 11:09
-- 说明：机器人调度的观察者
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"

require"printfunc"
require "normal_enum"

local function error_handle(msg)
	print(tostring(msg) .. ":\n" .. tostring(debug.traceback()))
	return msg
end


local random = math.random

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECTED = {}

-- 只有这里的 比赛模式 才会处理托管
local robot_match_types =
{
	match_game = true,
	freestyle_game = true,
}

-- 检查并加入 机器人
local function check_and_assign_robot(_game_info,_count)

	print("check_and_assign_robot->assign_tuoguan_player:",_count)
	skynet.call(DATA.service_config.tuoguan_service,"lua","assign_tuoguan_player",_count,_game_info)

end

local game_id_maps = {}
local function get_config_name(_name,_id)
	local g = game_id_maps[_name] or {}
	game_id_maps[_name] = g

	local cfg_name = g[_id] or "tuoguan_ob_" .. _name .. "_" .. _id
	g[_id] = cfg_name

	return cfg_name
end

local function check_tuoguan_cfg(_model_name,_game_id)
	if skynet.getcfg(get_config_name(_model_name,"x")) then
		return true
	end

	if skynet.getcfg(get_config_name(_model_name,_game_id)) then
		return true
	end

	return false
end

local error_models = {}

local function deal_game_robot(dt)

	-- 此服务 仅处理 tuoguan_v_tuoguan 的情况
	if not skynet.getcfg("tuoguan_v_tuoguan") then
		return
	end

	-- 得到游戏列表
	local _centers = skynet.call(DATA.service_config.game_manager_service,"lua","get_game_center_services")
	if not _centers or not next(_centers) then
		print("tuoguan centers info error.")
		return
	end

	-- 检查每个游戏中心
	for _name,_data in pairs(_centers) do repeat

		if not robot_match_types[_name] then break end

		local _game_map = skynet.call(DATA.service_config[_data.service_name],"lua","get_game_map")
		if not _game_map or not next(_game_map) then break end

		for game_id,d in pairs(_game_map) do
			if "match_game" ~= _name or game_id ~= 1 then -- 跳过特殊场次
				if check_tuoguan_cfg(_name,game_id) then

					local ok,err = xpcall(check_and_assign_robot,error_handle,{
											game_id=game_id, -- 1,2,3
											game_type=d.game_type, --nor_mj_xzdd,nor_ddz_nor
											service_id=d.service_id,
											match_name = _name, -- freestyle_game,match_game
										},3)
					if not ok and not error_models[_name] then
						error_models[_name] = true

						print(string.format("check_and_assign_robot error,model name:%s,game id:%s,game type:%s",
							tostring(_name),tostring(game_id),tostring(d.game_type)))

						break
					end
				end
			end
		end

	until true end

end


function PROTECTED.init_robot_observer()

	-- 检查是否需要机器人
	skynet.timeout(500,function ()
		skynet.timer(1,deal_game_robot)
	end)

end

return PROTECTED
