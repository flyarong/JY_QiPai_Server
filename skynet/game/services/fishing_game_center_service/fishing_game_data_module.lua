
--
-- Author: hw
-- Date: 2018/3/28
-- Time: 
-- 说明：比赛场游戏服务
-- ddz_match_service
local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "printfunc"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECT = {}

local clear_save_time = 5*60

DATA.player_data = {}

DATA.player_data_save_time = {}

function CMD.get_player_game_data(_player_id,_game_id)
	
	local pd = DATA.player_data[_player_id]
	if pd then
		local d = pd[_game_id]
		if d then
			return d
		end
	end

	local d = skynet.call(DATA.service_config.data_service,"lua"
							,"query_fish_game_player_data"
							,_player_id
							,_game_id)
	
	if not next(d.player_wave_data) 
		or not next(d.player_reward_data) 
		or not next(d.player_data)
		or not next(d.player_data[1]) then
		return nil
	end
	
	d.player_data = d.player_data[1]

	local player_wave_data = {}
	for i,v in ipairs(d.player_wave_data) do
		player_wave_data[v.pao_lv] = v
		v.id = nil
		v.player_id = nil
		v.game_id = nil
		v.pao_lv = nil
	end

	local player_reward_data = 
	{
		real_all_fj = d.player_data.real_all_fj,
		real_laser_bc = d.player_data.real_laser_bc,
		pao_lv = {},
		dayu_fj = {},
		act_fj = {},
	}
	for i,v in ipairs(d.player_reward_data) do
		player_reward_data.pao_lv[v.pao_lv] = v
		player_reward_data.dayu_fj[v.pao_lv] = v.dayu_fj
		player_reward_data.act_fj[v.pao_lv] = v.act_fj

		v.id = nil
		v.player_id = nil
		v.game_id = nil
		v.pao_lv = nil

		v.dayu_fj = nil
		v.act_fj = nil
	end

	local data = 
	{
		laser_data = d.player_data.laser_data,
		wave_data = player_wave_data,
		buyu_fj_data = player_reward_data,
	}

	local pd = DATA.player_data[_player_id] or {}
	DATA.player_data[_player_id] = pd
	pd[_game_id] = data

	return data
end



--获取游戏列表
function CMD.save_player_game_data(_player_id,_game_id,_data)
	
	local pd = DATA.player_data[_player_id] or {}
	DATA.player_data[_player_id] = pd
	pd[_game_id] = _data
	
	DATA.player_data_save_time[_player_id] = os.time()

	local d = 
	{
		player_data=
		{
			player_id = _player_id,
			game_id = _game_id,
			laser_data = _data.laser_data,
			real_all_fj = _data.buyu_fj_data.real_all_fj,
			real_laser_bc = _data.buyu_fj_data.real_laser_bc,
		},
		player_wave_data = {},
		player_reward_data = {},
	}

	for i,v in ipairs(_data.wave_data) do
		d.player_wave_data[i] = 
		{
			player_id = _player_id,
			game_id = _game_id,
			bd_type=v.bd_type,
			pao_lv = i,
			all_times = v.all_times,
			cur_times = v.cur_times,
			store_value = v.store_value,
			is_zheng = v.is_zheng,
			bd_factor = v.bd_factor,

		}
	end

	for i,v in ipairs(_data.buyu_fj_data.pao_lv) do
		d.player_reward_data[i] = 
		{
			player_id = _player_id,
			game_id = _game_id,
			pao_lv = i,

			all_fj = v.all_fj,
			store_fj = v.store_fj,
			xyBuDy_fj = v.xyBuDy_fj,
			laser_bc_fj = v.laser_bc_fj,
			
			dayu_fj = _data.buyu_fj_data.dayu_fj[i],
			act_fj = _data.buyu_fj_data.act_fj[i],

		}
	end

	skynet.send(DATA.service_config.data_service,"lua"
							,"save_fish_game_player_data"
							,d)
end



local function clear_save_data()
	
	for _player_id,_time in pairs(DATA.player_data_save_time) do
		
		if os.time() - _time > clear_save_time then
			
			DATA.player_data[_player_id] = nil

			DATA.player_data_save_time[_player_id] = nil

		end

	end

end


local function update()
	while true do
		skynet.sleep(5*60*100)

		clear_save_data()

	end
end


function PROTECT.init()
	skynet.fork(update)
end

return PROTECT