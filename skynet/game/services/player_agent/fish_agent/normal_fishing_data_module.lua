--- 鱼的返奖控制

require "normal_enum"
local skynet = require "skynet_plus"
local basefunc=require"basefunc"
local nodefunc = require "nodefunc"
require"printfunc"
local base = require "base"
local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC

local cjson = require "cjson"
cjson.encode_sparse_array(true,1,0)


local FIP = base.fish_interface_protect

local LOCAL = {}

local statistics_fish_assets_data_minute
-- 统计捕鱼的资产数据的缓存 每个整分钟时刻写一次
local statistics_fish_assets_data_cache = {}

-- 初始化加载数据
function FIP.load_fish_game_data()
	
	local s_info = DATA.fish_game_data.game_data

	local fish_data = skynet.call(DATA.service_config.fishing_game_center_service,"lua"
									,"get_player_game_data"
									,DATA.my_id
									,DATA.fish_game_data.room_info.game_id)

	-- 激光数据
	LOCAL.init_laser_data(fish_data)

	-- 波动数据
	LOCAL.init_wave_data(fish_data)

	-- 返奖数据
	LOCAL.init_reward_data(fish_data)

	LOCAL.init_fanjiang_base_cfg_data()

	s_info.missile_data = {
		[1]={value = 1,num = 1},
		[2]={value = 0,num = 0},
		[3]={value = 0,num = 0},
		[4]={value = 0,num = 0},
	}

end

-- 保存数据
function FIP.save_fish_game_data()

	local s_info = DATA.fish_game_data.game_data
	
	if not s_info then
		return
	end

	LOCAL.save_statistics_fish_assets_data_cache()
	
	-- dump({
	-- 					laser_data = s_info.laser_data[1].value,
	-- 					wave_data = s_info.wave_data[1],
	-- 					buyu_fj_data = s_info.buyu_fj_data[1],
	-- 				},"++++++++save_fish_game_data++++++++")

	skynet.call(DATA.service_config.fishing_game_center_service,"lua"
					,"save_player_game_data"
					,DATA.my_id
					,DATA.fish_game_data.room_info.game_id
					,{
						laser_data = s_info.laser_data[1].value,
						wave_data = s_info.wave_data[1],
						buyu_fj_data = s_info.buyu_fj_data[1],
					})

end


--[[统计捕鱼的资产数据
	"bullet",stake,jing_bi,fish_coin,activity_type

	"return_bullet",stake,jing_bi,fish_coin

	"fish_dead",stake,fish_ids,money,["boom"|"electric"|"laser"|activity_type("normal"|"free_bullet"|"crit"|"power")]
]]
function FIP.statistics_fish_assets_data(_type,_arg1,_arg2,_arg3,_arg4,_arg5)
	local s_info = DATA.fish_game_data.game_data

	if _type == "bullet" then
		
		local d = statistics_fish_assets_data_cache["bullet"] or 
							{assets={jing_bi=0,fish_coin=0},info={}}
		statistics_fish_assets_data_cache["bullet"] = d

		d.assets.jing_bi = d.assets.jing_bi + _arg2
		d.assets.fish_coin = d.assets.fish_coin + _arg3

		local key = _arg4 .. "_" .. _arg1
		d.info[key] = (d.info[key] or 0) + 1

	elseif _type == "return_bullet" then

		local d = statistics_fish_assets_data_cache["return_bullet"] or 
							{assets={jing_bi=0,fish_coin=0},info={}}
		statistics_fish_assets_data_cache["return_bullet"] = d

		d.assets.jing_bi = d.assets.jing_bi + _arg2
		d.assets.fish_coin = d.assets.fish_coin + _arg3

		local key = tostring(_arg1)
		d.info[key] = (d.info[key] or 0) + 1


	elseif _type == "shell_dead" then
		---------- 处理贝壳
		if not _arg2 or not next(_arg2) then
			return
		end
		local d = statistics_fish_assets_data_cache["fish_dead"] or 
							{assets={jing_bi=0},info={}}
		statistics_fish_assets_data_cache["fish_dead"] = d

		d.assets.jing_bi = d.assets.jing_bi + _arg3

		for i,data in ipairs(_arg2) do
			local key = "shell_".._arg4 .. "_" .. _arg1 .. "_" .. data.shell_id
			d.info[key] = {money = data.money}
		end


	elseif _type == "fish_dead" then
		if not _arg2 or not next(_arg2) then
			return
		end
		local d = statistics_fish_assets_data_cache["fish_dead"] or 
							{assets={jing_bi=0},info={}}
		statistics_fish_assets_data_cache["fish_dead"] = d

		d.assets.jing_bi = d.assets.jing_bi + _arg3

		-- dump(s_info.fish_data,"s_info.fish_data++++++++++/*-/*---")
		-- dump(_arg2,"++++++++++-*/-/-----")

		for i,fid in ipairs(_arg2) do
			local fish_type = s_info.fish_data[fid].type
			local types = {}
			if not fish_type then
				types = s_info.fish_data[fid].types
			else
				types = {fish_type}
			end

			for i,t in ipairs(types) do
				
				local key = _arg4 .. "_" .. _arg1 .. "_" .. t
				local info = d.info[key] or {num = 0,money = 0,type = t}
				d.info[key] = info
				info.num = info.num + 1

				local fd = s_info.fish_config.use_fish[t]
				local rate = s_info.fish_config.use_fish[fd.base_id].rate

				----- 发出一个鱼死的消息
				-- print("xxxxx--------------------- buyu_fish_dead")
				--DATA.msg_dispatcher:call("buyu_fish_dead" , DATA.fish_game_data.room_info.game_id , _arg5 , fd )
				PUBLIC.trigger_msg( {name = "buyu_fish_dead"} , DATA.fish_game_data.room_info.game_id , _arg5 , fd  )

				if _type == "crit" then
					rate = rate * 2
				end

				info.money = info.money + rate

			end

		end

	end

end

function FIP.data_module_update()
	
	local minute = tonumber(os.date("%M"))

	local save_cache = true
	if not statistics_fish_assets_data_minute then
		statistics_fish_assets_data_minute = minute
		save_cache = false
	else
		if minute == statistics_fish_assets_data_minute then
			save_cache = false
		end
	end
	if save_cache then
		statistics_fish_assets_data_minute = minute
		LOCAL.save_statistics_fish_assets_data_cache()
	end

end

--初始化返奖的一些基本
function LOCAL.init_fanjiang_base_cfg_data()
	local s_info = DATA.fish_game_data.game_data
	s_info.by_xyhuishou_rate_limit=skynet.getcfg_2number("by_xyhuishou_rate_limit") or 5
	s_info.by_laser_bc_max=skynet.getcfg_2number("by_laser_bc_max") or 150
	s_info.by_storefj_max=skynet.getcfg_2number("by_storefj_max") or 120
end

function LOCAL.init_laser_data(_fish_data)

	local s_info = DATA.fish_game_data.game_data

	s_info.laser_data = {}
	
	for seat_num=1,4 do

		s_info.laser_data[seat_num] = 
		{
			value = math.random(200,600),
			change = false,
		}

		if seat_num == 1 then
			s_info.laser_data[seat_num].value = 0
			if _fish_data then
				s_info.laser_data[seat_num].value = _fish_data.laser_data
			end
		end

	end

end


function LOCAL.init_wave_data(_fish_data)
	
	local s_info = DATA.fish_game_data.game_data
	
	-- 波动数据
	s_info.wave_data = {}

	for seat_num=1,4 do
		
		s_info.wave_data[seat_num] = {}

		for id,v in pairs(s_info.fish_config.gun) do
			
			s_info.wave_data[seat_num][id] =
			{
				all_times = 0,     --总次数
				cur_times = 0,      --当前次数
				store_value = 0,  --被存储下的值
				is_zheng = 0,    --当前波动是正还是负值
				bd_factor = 0,	--当前的波动系数
				bd_type = 1, --波动类型
			}

			if seat_num == 1 then
				if _fish_data then

					if _fish_data.wave_data[id] then
						s_info.wave_data[seat_num][id] = _fish_data.wave_data[id]
					end

				end
			end

		end

	end

end

function LOCAL.init_reward_data(_fish_data)

	local s_info = DATA.fish_game_data.game_data

	s_info.buyu_fj_data = {}

	for seat_num=1,4 do

		s_info.buyu_fj_data[seat_num] = 
		{
			real_all_fj = 0,
			real_laser_bc = 0,
			pao_lv = {},
			dayu_fj = {},
			act_fj = {},
		}

		if seat_num == 1 then
			if _fish_data then
				s_info.buyu_fj_data[seat_num].real_all_fj = _fish_data.buyu_fj_data.real_all_fj
				s_info.buyu_fj_data[seat_num].real_laser_bc = _fish_data.buyu_fj_data.real_laser_bc
			end
		end

		for id,v in pairs(s_info.fish_config.gun) do

			s_info.buyu_fj_data[seat_num].pao_lv[id] = 
			{
				all_fj = 0,--总返奖  = store_fj+xyBuDy_fj
				store_fj = 0,	--存储返奖
				xyBuDy_fj = 0,  --小鱼补大鱼返奖
				laser_bc_fj = 0,  --激光补偿
			}

			s_info.buyu_fj_data[seat_num].dayu_fj[id] = 0

			s_info.buyu_fj_data[seat_num].act_fj[id] = 0

			if seat_num == 1 then
				if _fish_data then
					if _fish_data.buyu_fj_data.pao_lv[id] then
						s_info.buyu_fj_data[seat_num].pao_lv[id] = _fish_data.buyu_fj_data.pao_lv[id]
						s_info.buyu_fj_data[seat_num].dayu_fj[id] = _fish_data.buyu_fj_data.dayu_fj[id]
						s_info.buyu_fj_data[seat_num].act_fj[id] = _fish_data.buyu_fj_data.act_fj[id]
					end
				end
			end 

		end


	end

end



function LOCAL.save_statistics_fish_assets_data_cache()

	local s_info = DATA.fish_game_data.game_data

	-- 记录数据

	-- dump(statistics_fish_assets_data_cache,"statistics_fish_assets_data_cache++++++++",99999)
	
	local sfadc = statistics_fish_assets_data_cache

	if next(sfadc) then

		sfadc.bullet_assets = ""
		sfadc.bullet_info = ""
		sfadc.return_bullet_assets = ""
		sfadc.return_bullet_info = ""
		sfadc.fish_dead_assets = ""
		sfadc.fish_dead_info = ""

		if sfadc.bullet then
			sfadc.bullet_assets = cjson.encode(sfadc.bullet.assets)
			sfadc.bullet_info = cjson.encode(sfadc.bullet.info)
		end

		if sfadc.return_bullet then
			sfadc.return_bullet_assets = cjson.encode(sfadc.return_bullet.assets)
			sfadc.return_bullet_info = cjson.encode(sfadc.return_bullet.info)
		end

		if sfadc.fish_dead then
			sfadc.fish_dead_assets = cjson.encode(sfadc.fish_dead.assets)
			sfadc.fish_dead_info = cjson.encode(sfadc.fish_dead.info)
		end

		skynet.send(DATA.service_config.data_service,"lua","add_fish_game_race_player_log"
	                        ,DATA.my_id
	                        ,DATA.fish_game_data.room_info.game_id
	                        ,sfadc
	                        )
	end

	statistics_fish_assets_data_cache = {}
end





