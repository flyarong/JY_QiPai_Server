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

--获取"1~3"中的1和3
local function get_range_bound(str)
	local left,right=string.match(str,"(%d+)~(%d+)")
	return left,right
end


-- 加载所有比赛
local function load_match_data(_raw_config)
	
	local _config = basefunc.deepcopy(_raw_config)

	local match_config_info = {}

	local match_data_config = {}
	local renmanjikai = {}
	local dingshikai = {}
	local match_enter_config = {}
	local match_game_config = {}
	local match_award_config = {}
	local broadcast = {}
	local tuoguan_enter_config = {}
	local nice_pai_rate = {}
	local tuoguan_occupy_rank = {}

	for i,d in ipairs(_config.match_data_config) do
		match_data_config[d.game_id]=d
	end

	for i,d in ipairs(_config.renmanjikai) do
		renmanjikai[d.game_id]=d
	end

	for i,d in ipairs(_config.dingshikai) do
		dingshikai[d.game_id]=d
	end

	for i,d in ipairs(_config.match_enter_config) do
		local mec = match_enter_config[d.enter_config_id] or {}
		match_enter_config[d.enter_config_id] = mec
		mec[#mec+1] = d
	end

	for i,d in ipairs(_config.match_game_config) do
		local mgc = match_game_config[d.game_config_id] or {}
		match_game_config[d.game_config_id] = mgc
		mgc[#mgc+1] = d
	end

	for i,d in ipairs(_config.match_award_config) do
	
		local mac = match_award_config[d.award_config_id] or {}
		match_award_config[d.award_config_id] = mac

		local l,r=get_range_bound(d.rank)
		for i=l,r do

			local macr = mac[i] or {}
			mac[i] = macr

			macr[#macr+1] =
			{
				asset_type=d.asset_type,
				value=d.asset_count,
			}

		end

	end

	for i,d in ipairs(_config.broadcast) do
		
		local bc = broadcast[d.game_id] or {}
		broadcast[d.game_id] = bc

		bc[#bc+1] = d.content

	end


	for i,d in ipairs(_config.tuoguan_enter_config) do

		local cfg = renmanjikai[d.game_id]
		if cfg then
			d.all_need_num = cfg.begin_game_condi
		end

		tuoguan_enter_config[d.game_id]=d
	end

	--- 自己人nice牌概率
	for key ,data in pairs(_config.nice_pai_rate) do
	 	nice_pai_rate[data.game_id] = {
	 		rate = data.rate

	 	}
	end

	for i,d in ipairs(_config.tuoguan_occupy_rank) do
		tuoguan_occupy_rank[d.game_id]=d
	end

	for i,info in ipairs(_config.match_info) do

		local game_id = info.game_id

		local match_info = info

		--- add by wss
		if match_info.kaiguan_multi then
			local kaiguan_cfg = nodefunc.get_kaiguan_multi_cfg( match_info.game_type )
			if kaiguan_cfg then
				match_info.kaiguan_multi = nodefunc.trans_kaiguan_multi_cfg( kaiguan_cfg , match_info.kaiguan_multi )
			end
		end

		match_info.match_data_config = match_data_config[game_id]


		if match_info.signup_model == "renmanjikai" then
			match_info.signup_data_config = renmanjikai[game_id]
		elseif match_info.signup_model == "dingshikai" then
			match_info.signup_data_config = dingshikai[game_id]
		end

		match_info.match_enter_config = {}
		for i,enter_config_id in ipairs(match_info.match_data_config.enter_config_id) do
			match_info.match_enter_config[i] = match_enter_config[enter_config_id]
		end

		match_info.match_game_config = basefunc.deepcopy(match_game_config[match_info.match_data_config.game_config_id])
		
		for id,mgc in ipairs(match_info.match_game_config) do

			if mgc.revive_condi then

				local revive_condi = {}
				for i,revive_condi_id in ipairs(mgc.revive_condi) do
					revive_condi[i] = match_enter_config[revive_condi_id]
				end

				mgc.revive_condi = revive_condi

			end

		end
		
		match_info.match_award_config = match_award_config[match_info.match_data_config.award_config_id]
		match_info.broadcast = broadcast[game_id]
		match_info.tuoguan_enter_config = tuoguan_enter_config[game_id]
		match_info.tuoguan_occupy_rank = tuoguan_occupy_rank[game_id]

		match_info.match_data_config.enter_config_id = nil
		match_info.match_data_config.game_config_id = nil
		match_info.match_data_config.award_config_id = nil
		match_info.match_data_config.id = nil

		match_info.nice_pai_rate = nice_pai_rate[game_id] or {}

		match_config_info[game_id] = match_info

	end
	-- print("xxx",basefunc.tostring(match_config_info,10))
	return match_config_info

end

--- 刷新配置
function PROTECT.refresh_configs()
	-- print("=-------->>>>>> match_config_module , refresh_configs")
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

	local raw_configs,_time = nodefunc.get_global_config("match_server") 
	if config_last_change_time ~= _time then
		need_refresh = true
	end
	config_last_change_time = _time

	if not mj_need_refresh and not ddz_need_refresh and not need_refresh then
		return
	end

	local config_infos = load_match_data(raw_configs)

	for game_id , cfg_data in pairs(config_infos) do

		if not DATA.match_config[game_id] then
			DATA.match_config[game_id] = cfg_data

			PUBLIC.reload_config( cfg_data )
		else
			local play_type = GAME_TYPE_TO_PLAY_TYPE[cfg_data.game_type]
			if (need_refresh and cfg_data.version ~= DATA.match_config[game_id].version) 
				or (play_type == "mj" and mj_need_refresh) 
				or (play_type == "ddz" and ddz_need_refresh) then

				DATA.match_config[game_id] = cfg_data
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