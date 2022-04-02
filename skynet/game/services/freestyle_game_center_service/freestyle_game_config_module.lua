--
-- Author: lyx
-- Date: 2018/4/4
-- Time: 15:28
-- 说明：比赛配置数据
--

local skynet = require "skynet_plus"
local basefunc = require "basefunc"
local base = require "base"
local nodefunc = require "nodefunc"
require "normal_enum"
require "printfunc"

local PUBLIC=base.PUBLIC
local DATA=base.DATA
local PROTECT = {}

local refresh_config_dt = 10

local config_last_change_time = 0
local mj_last_kaiguan_time = 0
local ddz_last_kaiguan_time = 0

-- 加载所有比赛
local function load_config(_raw_config)

	local _config = basefunc.deepcopy(_raw_config)
	
	local config_infos = {}

	local game_rule = {}
	local enter_cfg = {}
	local room_rent = {}
	local nice_pai_rate = {}

	for i,d in ipairs(_config.game_rule) do
		game_rule[d.game_id]=d
	end

	for i,d in ipairs(_config.enter_cfg) do
		local ec = enter_cfg[d.enter_cfg_id] or {}
		enter_cfg[d.enter_cfg_id] = ec
		ec[#ec+1] = d
	end

	for i,d in ipairs(_config.room_rent) do
		room_rent[d.game_id]=d
	end

	--- 自己人nice牌概率
	for key ,data in pairs(_config.nice_pai_rate) do
		nice_pai_rate[data.game_id] = {
			rate = data.rate

		}
	end


	for i,info in ipairs(_config.game_main) do

		local game_id = info.game_id

		local game_info = info

		--- add by wss
		if game_info.kaiguan_multi then
			local kaiguan_cfg = nodefunc.get_kaiguan_multi_cfg( game_info.game_type )
			if kaiguan_cfg then
				game_info.kaiguan_multi = nodefunc.trans_kaiguan_multi_cfg( kaiguan_cfg , game_info.kaiguan_multi )
			end
		end

		game_info.game_rule = game_rule[game_id]

		game_info.enter_cfg = basefunc.deepcopy(enter_cfg[game_info.game_rule.enter_cfg_id])

		game_info.room_rent = room_rent[game_id]

		--并入房费
		game_info.enter_cfg[#game_info.enter_cfg+1] = game_info.room_rent

		game_info.game_rule.enter_cfg_id = nil

		game_info.nice_pai_rate = nice_pai_rate[game_id] or {}

		config_infos[game_id] = game_info

	end

	return config_infos
end

--- 刷新配置
function PROTECT.refresh_configs()
	-- print("=-------->>>>>> refresh_configs")
	local mj_kaiguan_cfg,mj_kaiguan_time = nodefunc.get_global_config("mj_kaiguan_multi") 
	--local ddz_kaiguan_cfg,ddz_kaiguan_time = nodefunc.get_global_config("ddz_kaiguan_multi") 

	local mj_need_refresh = false
	local ddz_need_refresh = false
	local need_refresh = false

	if mj_last_kaiguan_time ~= mj_kaiguan_time then
		mj_need_refresh = true
	end
	mj_last_kaiguan_time = mj_kaiguan_time

	--[[if ddz_last_kaiguan_time ~= ddz_kaiguan_time then
		ddz_need_refresh = true
	end
	ddz_last_kaiguan_time = ddz_kaiguan_time
	--]]

	local raw_configs,_time = nodefunc.get_global_config("freestyle_server") 
	if config_last_change_time ~= _time then
		need_refresh = true
	end
	config_last_change_time = _time

	if not mj_need_refresh and not ddz_need_refresh and not need_refresh then
		return
	end

	local config_infos = load_config(raw_configs)

	for game_id , cfg_data in pairs(config_infos) do
		if not DATA.game_configs[game_id] then
			DATA.game_configs[game_id] = cfg_data

			PUBLIC.reload_config( cfg_data )
		else
			local play_type = GAME_TYPE_TO_PLAY_TYPE[cfg_data.game_type]
			if (need_refresh and cfg_data.version ~= DATA.game_configs[game_id].version) 
				or (play_type == "mj" and mj_need_refresh) 
				or (play_type == "ddz" and ddz_need_refresh) then

				DATA.game_configs[game_id] = cfg_data
				PUBLIC.reload_config( cfg_data )

			end
		end
	end

end

function PROTECT.init()
	PROTECT.refresh_configs()

	skynet.timer( refresh_config_dt , PROTECT.refresh_configs )

end

return PROTECT