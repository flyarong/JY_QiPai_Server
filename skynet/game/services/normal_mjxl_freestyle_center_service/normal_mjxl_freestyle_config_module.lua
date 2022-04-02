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
-- 比赛配置数据： config_info id -> 数据
-- 数据结构说明：
	config_info id = {

		id = 1,
		name = "练习场",
		game_model = 0,
		scheme = 1,
		base_score = 1,
		ui_order = 1,
		enable = 1,

		-- 进入条件配置
		enter_cfg = {
			{
				{asset_type = "diamond",asset_count = 100,judge_type = 3,},
				{asset_type = "diamond",asset_count = 100,judge_type = 3,},
				...
			},
			...
 		},
		
	}
--]]
local config_info = {}

--[[自由场的房费
	[1]=
	{
		enter_cfg_id|配置id（与条件）
		asset_type|财富类型	
		asset_count|财富数量	
		judge_type|判断方式

	},
	...
]]
local room_rent = {}

--检验数据是否正确完整
local function check_data()
	return true
end


--获取"1~3"中的1和3
local function get_range_bound(str)
	local left,right=string.match(str,"(%d+)~(%d+)")
	return left,right
end


-- 加载所有比赛 
--scheme == 1 才会加载
local function load_data(_config)

	if _config.game then

		local config_info_id = 0
		for id,cfg in ipairs(_config.game) do
			
			if cfg.scheme == 1 then
				
				config_info_id=config_info_id+1

				config_info[config_info_id] = {
					id = cfg.id,
					name = cfg.name,
					game_model = cfg.game_model,
					base_score = cfg.base_score,
					max_coin = cfg.max_coin,
					min_coin = cfg.min_coin,
					ui_order = cfg.ui_order,
					cancel_cd = cfg.cancel_cd or 10,
					enable = cfg.enable,
					enter_cfg = {},
				}

				local cur_enter_cfg = config_info[id].enter_cfg
				if _config.enter_cfg then
					
					for or_id,cfg_id in ipairs(cfg.enter_cfg_id) do
						cur_enter_cfg[or_id] = {}
						for and_id,and_cfg in ipairs(_config.enter_cfg) do
							
							if cfg_id == and_cfg.enter_cfg_id then
								cur_enter_cfg[or_id][#cur_enter_cfg[or_id]+1]=
								{
									asset_type = and_cfg.asset_type,
									asset_count = and_cfg.asset_count,
									judge_type = and_cfg.judge_type,
								}
							end

						end

						--房费
						if _config.room_rent then
							for rid,rcfg in ipairs(_config.room_rent) do
								if rcfg.enter_cfg_id == cfg_id then
									cur_enter_cfg[or_id][#cur_enter_cfg[or_id]+1]=
									{
										asset_type = rcfg.asset_type,
										asset_count = rcfg.asset_count,
										judge_type = rcfg.judge_type,
									}
									room_rent[id]=
									{
										asset_type = rcfg.asset_type,
										asset_count = rcfg.asset_count,
									}
								end
							end
						end

					end


				end


			end

		end

	end

	return check_data()
end

-- 初始化比赛信息
function PROTECT.init_config_info()

	--local raw_freestyle_configs = require "normal_mjxl_freestyle_server"
	local raw_freestyle_configs = base.reload_config("normal_mjxl_freestyle_server")
	load_data(raw_freestyle_configs)
	return true
end


-- 重新加载配置信息 by lyx
function PROTECT.reload_config_info()
	--package.loaded["normal_mjxl_freestyle_server"] = nil
	return PROTECT.init_config_info()
end


-- 得到所有场次配置
function PROTECT.get_datas()
	return basefunc.deepcopy(config_info)
end

-- 得到给定 id 的比赛配置数据
function PROTECT.get_data(id)
	return config_info[id]
end



-- 得到所有场次的房费
function PROTECT.get_room_rents()
	return basefunc.deepcopy(room_rent)
end


return PROTECT