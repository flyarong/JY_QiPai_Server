--
-- Author: lyx
-- Date: 2018/4/4
-- Time: 15:28
-- 说明：比赛配置数据
--

local skynet = require "skynet_plus"
local basefunc = require "basefunc"
local base = require "base"
require "normal_enum"
require "printfunc"

local PROTECT = {}

--[[

BASE:
	id	
	signup_time|报名时间格林威治	
	begin_time|比赛开始开始时间	
	max_player|最大参赛人数
	min_player|最少参赛人数	
	min_winner|最少获奖人数	
	bonus|奖金（rmb）	
	ticket|报名费用(钻石)	
	init_score|初始分数

PROCESS:	
	match_id	
	rise_score|晋级分数	
	init_stake|底分	
	init_rate|底倍	
	race_times|比赛次数（打几副牌）	
	award|安慰奖(钻石)

--]]
local million_config_info = {}

local function load_match_data(_config)

	if _config.match_cfg then

		local process={}

		for id,v in ipairs(_config.process_cfg) do
			process[v.process_id] = process[v.process_id] or {}
			local len = #process[v.process_id]+1
			process[v.process_id][len]=v
		end

		for match_id,info in ipairs(_config.match_cfg) do
			million_config_info[match_id]={}
			million_config_info[match_id].base_info=info
			million_config_info[match_id].process=process[info.process_id]
		end

	end

end

-- 初始化比赛信息
function PROTECT.init_million_config_info()

	--local million_config = require "ddz_million_server"
	local million_config = base.reload_config("ddz_million_server")
	
	load_match_data(million_config)

	return true
end

-- 重新加载配置信息 by lyx
function PROTECT.reload_config_info()
	--package.loaded["ddz_million_server"] = nil
	return PROTECT.init_million_config_info()
end

-- 得到所有场次配置
function PROTECT.get_match_datas()
	return million_config_info
end

return PROTECT









