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

-- 加载所有比赛
local function load_config(_raw_config)

	local _config = basefunc.deepcopy(_raw_config)
	
	local configs = {}

	local game_rule = {}
	local enter_cfg = {}

	for i,d in ipairs(_config.game_rule) do
		game_rule[d.game_id]=d
	end

	for i,d in ipairs(_config.enter_cfg) do
		local ec = enter_cfg[d.enter_cfg_id] or {}
		enter_cfg[d.enter_cfg_id] = ec
		ec[#ec+1] = d
	end

	for i,info in ipairs(_config.game_main) do

		local game_id = info.game_id

		local game_info = info

		game_info.game_rule = game_rule[game_id]

		game_info.enter_cfg = enter_cfg[game_info.game_rule.enter_cfg_id]

		game_info.game_rule.enter_cfg_id = nil

		configs[game_id] = game_info

	end

	DATA.game_configs = configs

	PUBLIC.reload_config()
	
end


function PROTECT.init()

	nodefunc.query_global_config("fish_server",load_config)

end

return PROTECT