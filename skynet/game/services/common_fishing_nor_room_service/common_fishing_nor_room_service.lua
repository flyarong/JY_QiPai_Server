--
-- Author: hw
-- Time: 
-- 说明：自由场斗地主桌子服务
--ddz_freestyle_room_service

require "normal_enum"
local skynet = require "skynet_plus"
require "skynet.manager"
require"printfunc"
local nodefunc = require "nodefunc"
local base=require "base"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA
local basefunc = require "basefunc"

local fishing_creator = require "common_fishing_nor_room_service.fishing_creator"


local fishing_tuoguan = require "common_fishing_nor_room_service.fishing_tuoguan"


--房间ID
DATA.my_id = 0

--上级管理者
DATA.mgr_id = 0

--剩余桌子数量
DATA.table_count = 0

DATA.service_config = nil

--鱼的配置的名字
DATA.fish_config_name = nil

--鱼的配置
DATA.fish_config = nil

DATA.fish_room_data = DATA.fish_room_data or 
{
	fish_crowd_id = 0,

	update_fish_life_time_limit = 10,
	update_fish_life_time = 0,
	
	player_focus_ext_life_time = 30,
	
	--空闲桌子编号列表
	table_list={},
	game_table={},
	
	run=true,
}
local LL = DATA.fish_room_data

DATA.game_table = LL.game_table
DATA.table_list = LL.table_list

function PUBLIC.employ_table()
	local _t_number=LL.table_list[#LL.table_list]
	LL.table_list[#LL.table_list]=nil
	if _t_number then 
		DATA.table_count=DATA.table_count-1
	end
	return _t_number
end
function PUBLIC.return_table(_t_number)
	local _d=LL.game_table[_t_number]
	if DATA.service_config.chat_service and _d and _d.chat_room_id then
		skynet.send(DATA.service_config.chat_service,"lua","destroy_room",_d.chat_room_id)
	end

	LL.game_table[_t_number]=nil
	LL.table_list[#LL.table_list+1]=_t_number
	DATA.table_count=DATA.table_count+1
end

function PUBLIC.load_random_image_config()
	DATA.random_yutu_config = {}
	--dump(DATA.fish_config.random_yutu_no_vec , "xxxxxxxxx----DATA.fish_config.random_yutu_no_vec")
	if DATA.fish_config and DATA.fish_config.random_yutu_no_vec then
		for key , data in pairs(DATA.fish_config.random_yutu_no_vec) do
			
			local _cfg , last_time = nodefunc.get_global_config( data.random_no )
			
			DATA.random_yutu_config = DATA.random_yutu_config or {}

			DATA.random_yutu_config[data.random_no] = DATA.random_yutu_config[data.random_no] or {cfg = nil , image_cfg = nil, last_change_time = 0}
			local yutu_cfg = DATA.random_yutu_config[data.random_no]

			if yutu_cfg.last_change_time and yutu_cfg.last_change_time ~= last_time then
				yutu_cfg.image_cfg = data
				yutu_cfg.cfg = _cfg
				yutu_cfg.last_change_time = last_time
			end

		end
	end

	--dump( DATA.random_yutu_config , "xxxxxxxxx----DATA.random_yutu_config")
end

function PUBLIC.load_guding_image_config(_raw_config)
	local _config = basefunc.deepcopy(_raw_config)

	local total_guding_yutu = {}
	DATA.guding_yutu_config = {}

	if _config and _config.image then
		for key,data in ipairs(_config.image) do
			total_guding_yutu[data.id] = total_guding_yutu[data.id] or {}
			local _cfg = total_guding_yutu[data.id]
			_cfg[#_cfg + 1] = basefunc.deepcopy( data )
		end
	end

	if DATA.fish_config and DATA.fish_config.guding_yutu_no_vec then
		for key,data in pairs(DATA.fish_config.guding_yutu_no_vec) do
			DATA.guding_yutu_config[data.guding_no] = { cfg = basefunc.deepcopy( total_guding_yutu[data.guding_no] ) , image_cfg = data }
		end
	end
end

local function load_fish_config(_raw_config)

	local _config = basefunc.deepcopy(_raw_config)

	DATA.fish_config = _config

	-- DATA.fishery_config = {
	-- 	bullet_config = {},
	-- 	fish_config = _config.fish,
	-- }

	-- for i,d in ipairs(DATA.gun_id) do
	-- 	DATA.fishery_config.bullet_config[d]=DATA.gun_rate[i]
	-- end

	---- 随机固定鱼途
	--dump( DATA.fish_config.image_cfg , "xxxxxxxxxxxx-----DATA.fish_config.image_cfg")
	for key,data in pairs(DATA.fish_config.image_cfg) do
		if data.random_no then
			DATA.fish_config.random_yutu_no_vec = DATA.fish_config.random_yutu_no_vec or {}
			DATA.fish_config.random_yutu_no_vec[#DATA.fish_config.random_yutu_no_vec + 1] = data
		end
		if data.guding_no then
			DATA.fish_config.guding_yutu_no_vec = DATA.fish_config.guding_yutu_no_vec or {}
			DATA.fish_config.guding_yutu_no_vec[#DATA.fish_config.guding_yutu_no_vec + 1] = data
		end
	end


	----------------- 把use_fish 移到 group中
	---- 处理 鱼组，把use_fish 加到 鱼组group中从10001开始
	for key , data in pairs(DATA.fish_config.use_fish) do
		DATA.fish_config.group[ 10000+data.id ] = { ID = 10000+data.id , fish_type = 1 , fish_form = {data.id,} , count = {1,} , rate = data.rate }
	end


	
	print("load_fish_config ... ")

end



--[[
	_create_type
	1 - 一组鱼
	2 - 一个敢死队
]]
function PUBLIC.create_fish(_t_num,_data)
	if skynet.getcfg("debug_stop_create_fish") then
		return 
	end

	local _d=LL.game_table[_t_num]
	
	 -- dump(_data,"----create_fish_data+++++++++")

	-- 一群鱼的id 鱼组使用
	LL.fish_crowd_id = LL.fish_crowd_id + 1

	-- 普通鱼组
	if _data.create_type == 1 then

		local fishs = {}

		for i,_type in ipairs(_data.types) do
			
			_d.fish_id = _d.fish_id + 1

			_d.fish_data[_d.fish_id] = {
				id = _d.fish_id,
				fish_group_id = _data.fish_group_id,
				group_type = 1,
				fish_crowd_id = LL.fish_crowd_id,
				type = _type,
				path = _data.path,
				time = _data.create_time,
				lifetime = _data.lifetime,
				speed = _data.speed,
			}

			fishs[#fishs+1] = _d.fish_data[_d.fish_id]

			if _d.fish_id > 65000 then
				_d.fish_id = 0
			end

		end

		for _seat_num,_pid in pairs(_d.p_seat_number) do
			nodefunc.send(_pid,"nor_fishing_nor_fish_group_come_msg",fishs)
		end
		
	-- 敢死队
	elseif _data.create_type == 2 then

		_d.fish_id = _d.fish_id + 1

		_d.fish_data[_d.fish_id] = {
			id = _d.fish_id,
			fish_group_id = _data.fish_group_id,
			group_type = 2,
			types = _data.types,
			path = _data.path,
			time = _data.create_time,
			lifetime = _data.lifetime,
			speed = _data.speed,
		}

		for _seat_num,_pid in pairs(_d.p_seat_number) do
			nodefunc.send(_pid,"nor_fishing_nor_fish_group_come_msg",{_d.fish_data[_d.fish_id]})
		end

		if _d.fish_id > 65000 then
			_d.fish_id = 0
		end

	-- 一网打尽
	elseif _data.create_type == 3 then

		local fishs = {}

		for i,_type in ipairs(_data.types) do
			
			_d.fish_id = _d.fish_id + 1

			_d.fish_data[_d.fish_id] = {
				id = _d.fish_id,
				fish_group_id = _data.fish_group_id,
				group_type = 3,
				fish_crowd_id = LL.fish_crowd_id,
				type = _type,
				group_id = _data.group_id,
				path = _data.path,
				time = _data.create_time,
				lifetime = _data.lifetime,
				speed = _data.speed,
			}

			fishs[#fishs+1] = _d.fish_data[_d.fish_id]

			if _d.fish_id > 65000 then
				_d.fish_id = 0
			end

		end

		for _seat_num,_pid in pairs(_d.p_seat_number) do
			nodefunc.send(_pid,"nor_fishing_nor_fish_group_come_msg",fishs)
		end

	end

	if LL.fish_crowd_id > 65535 then
		LL.fish_crowd_id = 0
	end

end



function PUBLIC.clear_fish(_t_num)
	
	local _d=LL.game_table[_t_num]
	if not _d then
		return false
	end

	_d.fish_data = {}

	_d.frozen_time_data = {}

	for _seat_num,_pid in pairs(_d.p_seat_number) do
		nodefunc.send(_pid,"nor_fishing_nor_fish_boom_come_msg",
			{
				type = 1,
				begin_time = _d.fishery_data.begin_time,
				fish_map_id = _d.fishery_data.changci_index,
			})
	end

end

function PUBLIC.update_fish_life()
	
	if LL.update_fish_life_time < os.time() then
		LL.update_fish_life_time = os.time() + LL.update_fish_life_time_limit

		for _t_num,_d in pairs(LL.game_table) do

			local elapse = os.time() - math.floor(_d.fishery_data.begin_time*0.1)

			local ext_lifetime = 0
			if _d.focus then
				ext_lifetime = LL.player_focus_ext_life_time
			end

			local dead_fish = {}
			for id,fd in pairs(_d.fish_data) do

				if (fd.time + fd.lifetime)*0.1 + ext_lifetime < elapse then
					dead_fish[#dead_fish+1]=id
				end

			end

			if #dead_fish > 0 then
				CMD.fish_dead(_t_num,nil,dead_fish)

				for _seat_num,_pid in pairs(_d.p_seat_number) do
					nodefunc.send(_pid,"nor_fishing_nor_fish_dead_msg",dead_fish)
				end

			end

		end

	end
end

function PUBLIC.new_game(_t_num)
	local _d=LL.game_table[_t_num]
	if not _d then
		return false
	end

	_d.skill_status = {}

	_d.frozen_time_data = {}

	_d.focus = true

	fishing_creator.init(_t_num )

end

local xxx = 0

local dt=0.1
local function update()
	while LL.run do

		fishing_creator.update(dt)
		
		fishing_tuoguan.update()

		PUBLIC.update_fish_life()

		skynet.sleep(dt*100)

		--[[xxx = xxx + dt

		if xxx > 2 then

			for _t_num,_d in pairs(LL.game_table) do
				

				local max_fish_id = 18

				-- 单鱼
				if math.random(1,100) > 50 then
					local id = math.random(1,max_fish_id)
					create_fish(_t_num,
					{
					  create_type = 1,
					  types = {id},
					  group_id=nil,
					  path = math.random(1,28),

					  create_time = os.time() - _d.begin_time,
					  lifetime = 120,
					  speed=20,

					  cfg = {pro=fish_cfg_test.use_fish[id].shoot},
					})
				end

				-- 炸弹鱼
				if math.random(1,100) > 80 then
					local id = 22
					create_fish(_t_num,
					{
					  create_type = 1,
					  types = {id},
					  group_id=nil,
					  path = math.random(1,28),

					  create_time = os.time() - _d.begin_time,
					  lifetime = 120,
					  speed=20,

					  cfg = {pro=fish_cfg_test.use_fish[id].shoot},
					})
				end

				-- -- 群鱼
				if math.random(1,100) > 70 then
					local id1 = math.random(1,4)
					local id2 = math.random(1,4)
					local id3 = math.random(1,4)
					local id4 = math.random(1,4)
					create_fish(_t_num,
					{
					  create_type = 1,
					  types = {id1,id2,id3,id4},
					  group_id=nil,
					  path = math.random(1,28),

					  create_time = os.time() - _d.begin_time,
					  lifetime = 120,
					  speed=20,

					  cfg = {pro=0.4},
					})

				end

				-- 一网打尽
				if math.random(1,100) > 20 then

					local id = math.random(3,5)
					PUBLIC.create_fish(_t_num,
					{
					  create_type = 3,
					  types = {id},
					  group_id = 1,
					  path = math.random(1,3),

					  create_time = os.time() - _d.begin_time,
					  lifetime = 120,
					  speed=20,

					  cfg = {pro=fish_cfg_test.use_fish[id].shoot},
					})

				end

				-- 敢死队
				-- if math.random(1,100) > 80 then

				-- 	create_fish(_t_num,
				-- 	{
				-- 	  create_type = 2,
				-- 	  types = {math.random(6,8),math.random(6,8),math.random(6,8)},
				-- 	  group_id=nil,
				-- 	  path = math.random(1,28),

				-- 	  create_time = os.time() - _d.begin_time,
				-- 	  lifetime = 120,
				-- 	  speed=20,

				-- 	  cfg = {pro=0.1},
				-- 	})

				-- end

			end


			xxx = 0
		end--]]

	end
end


function CMD.new_table(_table_config,_env)
	local _t_num=PUBLIC.employ_table()
	if not _t_num then 
		return false
	end
	local _d={}

	_d.table_config=_table_config

	_d.time=0
	_d.p_info={}
	--玩家进入房间的标记
	_d.players_join_flag={}
	_d.p_seat_number={}
	_d.p_count=0

	_d.seat_count = 4

	_d.game_tag = _table_config.game_tag

	_d.fish_id = 0
	_d.fish_data = {}

	_d.model_name = _table_config.model_name
	_d.game_type = _table_config.game_type
	_d.game_id = _env.game_id

	LL.game_table[_t_num]=_d

	PUBLIC.new_game(_t_num)

	--###_test  目前是默认创建  可以考虑根据条件创建 比如（根据房卡场等来默认创建）
	if DATA.service_config.chat_service then
		_d.chat_room_id = skynet.call(DATA.service_config.chat_service,"lua","create_room")
	end

	return _t_num
end


function CMD.get_free_table_num()
	return #LL.table_list
end


function CMD.destroy()
	LL.run=nil
   	nodefunc.destroy(DATA.my_id)
	skynet.exit()
end



function CMD.join(_t_num,_p_id,_info)
	local _d=LL.game_table[_t_num]
	
	if not _d or _d.p_count+1>_d.seat_count or _d.players_join_flag[_p_id] then
		return 1002
	end

	local _seat_num = _info.seat_num
	
	if not _seat_num then
		for sn=1,_d.seat_count do
			if not _d.p_seat_number[sn] then
				_seat_num = sn
				break
			end
		end
	end

	if not _seat_num then
		return 1000
	end

	_d.players_join_flag[_p_id]=true 
	_d.p_seat_number[_seat_num]=_p_id
	_d.p_count=_d.p_count+1
	_d.p_info[_seat_num]=_info
	_d.p_info[_seat_num].seat_num=_seat_num

	-- 激活托管
	local tuoguan_info = fishing_tuoguan.init_table(_t_num
		,function(_info)
			if _d.players_join_flag[_p_id] then
				nodefunc.send(_p_id,"nor_fishing_nor_join_msg",_info)
			end
		end
		,function(_seat_num)
			if _d.players_join_flag[_p_id] then
				nodefunc.send(_p_id,"player_leave_msg",_seat_num)
			end
		end
		,_d.game_id
		)

	for _s,_info in pairs(tuoguan_info) do
		_d.p_info[_s] = _info
	end

	local my_join_return={
			seat_num=_info.seat_num,
			p_info=_d.p_info,
			p_count=_d.p_count,
			chat_room_id=_d.chat_room_id,
			skill_status = _d.skill_status,
			frozen_time_data = _d.frozen_time_data,

			gun_id_config = DATA.gun_id_config,
			gun_rate_config = DATA.gun_rate_config,
			fish_config = DATA.fish_config,
		}

	nodefunc.send(_p_id,"nor_fishing_nor_join_msg",nil,my_join_return)

	return 0

end

function CMD.update_tuoguan_info(_t_num,_seat_num,_tg_seat_num,_info)
	
	fishing_tuoguan.update_tuoguan_info(_t_num,_tg_seat_num,_info)

end



function CMD.ready(_t_num,_seat_num)

	local _d = LL.game_table[_t_num]

	if not _d then
		return 1002
	end
	
	nodefunc.send(_d.p_seat_number[_seat_num],"nor_fishing_nor_game_begin_msg",
		{
			fish_data = _d.fish_data,
			begin_time = _d.fishery_data.begin_time,
			fish_map_id = _d.fishery_data.changci_index,
		})

	return 0
end


function CMD.fish_dead(_t_num,_seat_num,_fish_ids)

	local _d = LL.game_table[_t_num]

	if not _d then
		return 1002
	end
	
	-- dump(_fish_ids,"+++++++++notify_fish_dead++++++++".._t_num)

	for i,fid in ipairs(_fish_ids) do

		local fd = _d.fish_data[fid]

		if fd then

			if fd.type then

				fishing_creator.fish_dead(_t_num,fd.group_type,fd.type , fd.group_id)
				
			elseif fd.types then

				for ts,t in ipairs(fd.types) do
					fishing_creator.fish_dead(_t_num,fd.group_type,t , fd.group_id)
				end
			else
				print("fish_dead error !!!!@@@")
			end

			_d.fish_data[fid] = nil

		end

	end

	return 0
end


function CMD.player_leave(_t_num,_seat_num)

	local _d = LL.game_table[_t_num]

	if not _d then
		return 1002
	end

	_d.p_count = _d.p_count - 1

	local _p_id = _d.p_seat_number[_seat_num]

	_d.players_join_flag[_p_id] = nil
	_d.p_seat_number[_seat_num] = nil

	fishing_tuoguan.return_table(_t_num)

	CMD.return_table(_t_num)

	return 0
end


-- 玩家使用技能
function CMD.player_use_skill(_t_num,_seat_num,_skill_seat_num,_skill,_arg1,_arg2)

	local _d = LL.game_table[_t_num]

	if not _d then
		return 1002
	end

	if _skill == "frozen" then
		fishing_creator.event(_t_num,_skill,_arg1,_arg2)
		_d.frozen_time_data[#_d.frozen_time_data+1] = os.time() - math.floor(_d.fishery_data.begin_time*0.1)
	end

	local sd = _d.skill_status[_skill_seat_num] or {}
	_d.skill_status[_skill_seat_num] = sd

	local sds = sd[_skill] or {}
	sd[_skill] = sds

	sds.cd = _arg1

	return 0
end


function CMD.player_update_focus(_t_num,_seat_num,_on)
	
	local _d = LL.game_table[_t_num]

	if not _d then
		return 1002
	end

	_d.focus = false
	if _on==1 then
		_d.focus = true
	end

end


function CMD.tuoguan_broke(_t_num,_seat_num,_tuoguan_seat_num)
	
	fishing_tuoguan.tuoguan_broke(_t_num,_tuoguan_seat_num)

end


-- 返还桌子 销毁
function CMD.return_table(_t_num)
	
	nodefunc.call(DATA.mgr_id,"table_finish",DATA.my_id,_t_num)

	PUBLIC.return_table(_t_num)

	nodefunc.send(DATA.mgr_id,"return_table",DATA.my_id,_t_num)

	-- fishing_creator.destory(_t_num)

end


function CMD.start(_id,_ser_cfg,_config)

	base.set_hotfix_file("fix_common_fishing_nor_room_service")

	math.randomseed(os.time()*72453)
	DATA.service_config =_ser_cfg
	DATA.table_count=10
	DATA.my_id=_id
	DATA.mgr_id=_config.mgr_id
	DATA.game_type=_config.game_type

	DATA.gun_id_config = _config.gun_id_config
	DATA.gun_rate_config = _config.gun_rate_config

	DATA.fish_config_name = _config.fish_config


	nodefunc.query_global_config(DATA.fish_config_name,load_fish_config)


	---- 导入随机&固定鱼途
	skynet.timer(10 , PUBLIC.load_random_image_config)
	PUBLIC.load_random_image_config()

	nodefunc.query_global_config( "fish_yutu_gd",PUBLIC.load_guding_image_config )


	fishing_tuoguan.init()

	--init table
	for i=1,DATA.table_count do 
		LL.table_list[#LL.table_list+1]=i
	end

	skynet.fork(update)

	return 0
end

-- 启动服务
base.start_service()
