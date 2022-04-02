--
-- Author: hw
-- Time: 
-- 说明：自由场斗地主桌子服务
--ddz_freestyle_room_service

require "normal_enum"
local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"
require"printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

DATA.fishing_creator = {}
local PROTECTED = DATA.fishing_creator

--- 时间缩放
DATA.time_scale = 10

-- 渔场数据
DATA.fishery_data = {}
local fishery_data = DATA.fishery_data

PROTECTED.max_group_id = 1024
PROTECTED.group_id = 0
function PROTECTED.get_new_group_id()
	PROTECTED.group_id = PROTECTED.group_id + 1
	if PROTECTED.group_id > PROTECTED.max_group_id then
		PROTECTED.group_id = 1
	end
	return PROTECTED.group_id
end

function PROTECTED.get_now_time(data)
	if data.virtual_time then
		return data.virtual_time
	end
	local ms=math.floor((skynet.now()-data.skynet_now_time)/10)
	return data.vir_now_time+ms
	
end
-- 通过区域id 获得路径列表
function PROTECTED.get_path_vec_by_area(area_id)
	local path_vec ={}
	if DATA.fish_config then
		for path_id , data in pairs(DATA.fish_config.path) do
			if data.region == area_id then
				path_vec[#path_vec + 1] = basefunc.deepcopy( data )
			end
		end
	end

	return path_vec
end

--- 
function PROTECTED.get_random_path(path_vec , filter)
	local real_path_vec = {}
	if path_vec then
		for key,data in pairs(path_vec) do
			if data.region then
				if not filter then
					real_path_vec[#real_path_vec + 1] = data.id
				else
					if data.id ~= filter then
						real_path_vec[#real_path_vec + 1] = data.id
					end
				end
			end
		end
	end
	if #real_path_vec > 0 then
		return real_path_vec[ math.random(#real_path_vec) ]
	end	

	return nil
end

---- 通过待选鱼组&鱼组权重，选一个要创建的鱼组
function PROTECTED.get_fish_group_by_power( choose_group , power_config )
	local power_vec = {}
	local total_power = 0
	for key,fish_group_id in ipairs(choose_group) do
		local now_power = power_config[fish_group_id] and power_config[fish_group_id].weight or 1
		total_power = total_power + now_power
		power_vec[fish_group_id] = now_power
	end

	local rand_power = math.random(total_power)
	local now_power = 0
	for key,fish_group_id in ipairs(choose_group) do
		local power = power_vec[fish_group_id] or 1
		if rand_power <= now_power + power then
			return fish_group_id
		end
		now_power = now_power + power
	end
	return nil
end

----
function PROTECTED.deal_create_one_fish_group( fd , _fish_group_id , _area_id  )
	--print("xxxxxxxxxxx--------------PROTECTED.deal_create_one_fish_group")
	---- 统计数据
	local statis_data = fd.statis_data
	--- 区域创建的统计数据
	local area_create_data = statis_data.area_create_data or {}
	area_create_data[_area_id] = area_create_data[_area_id] or { last_select_path = -100 }

	local area_path_vec = PROTECTED.get_path_vec_by_area(_area_id) 
	local target_path = PROTECTED.get_random_path( area_path_vec , area_create_data[_area_id].last_select_path ) or 
																PROTECTED.get_random_path( DATA.fish_config.path )
	
	if not target_path then
		print("error !!! ------------no target_path")
	end

	return PROTECTED.create_one_fish_group( fd.t_num , _fish_group_id , _area_id , target_path , nil , true )															
end

----- 检查是否可以创建鱼
function PROTECTED.check_is_can_create_fish_group(fd , _fish_group_id)
	---- 统计数据
	local statis_data = fd.statis_data

	--- 这个鱼组的数据
	local cfg_data = DATA.fish_config.group[_fish_group_id]

	local need_create_fish_type_num_data = need_create_fish_type_num_data or {}
	need_create_fish_type_num_data[cfg_data.fish_type] = 1

	-- 需要创建的鱼的数量
	local need_create_fish_num = 0

	local need_create_act_num_data = {}
	local need_create_rate_fish_num_data = {}
	local need_create_use_fish_num_data = {}
	if cfg_data then
		for key,use_fish_id in ipairs(cfg_data.fish_form) do
			local fish_num = cfg_data.count and cfg_data.count[key] or 1

			need_create_use_fish_num_data[use_fish_id] = (need_create_use_fish_num_data[use_fish_id] or 0) + fish_num

			for i=1,fish_num do
				need_create_fish_num = need_create_fish_num + 1

				local use_fish_cfg = DATA.fish_config.use_fish and DATA.fish_config.use_fish[use_fish_id] or nil
				if use_fish_cfg then

					---- 统计鱼概率
					need_create_rate_fish_num_data[use_fish_cfg.rate] = need_create_rate_fish_num_data[use_fish_cfg.rate] or 0
					need_create_rate_fish_num_data[use_fish_cfg.rate] = need_create_rate_fish_num_data[use_fish_cfg.rate] + 1

					---- 统计活动
					if use_fish_cfg.act_id and DATA.fish_config.activity[ use_fish_cfg.act_id ] then
						local act_data = DATA.fish_config.activity[ use_fish_cfg.act_id ]
						if act_data then

							need_create_act_num_data[ act_data.id ] = need_create_act_num_data[ act_data.id ] or 0

							need_create_act_num_data[ act_data.id ] = need_create_act_num_data[ act_data.id ] + 1

						end
					end
				end

			end
		end

	end

	------------ 统计数据
	local end_stas_data = basefunc.deepcopy( statis_data )

	end_stas_data.all_fish_num = (end_stas_data.all_fish_num or 0) + need_create_fish_num
	end_stas_data.fish_type_num_data = end_stas_data.fish_type_num_data or {}
	end_stas_data.act_num_data = end_stas_data.act_num_data or {}
	end_stas_data.rate_fish_num_data = end_stas_data.rate_fish_num_data or {}
	end_stas_data.use_fish_num_data = end_stas_data.use_fish_num_data or {}

	

	for fish_type,num in pairs(need_create_fish_type_num_data) do
		end_stas_data.fish_type_num_data[fish_type] = (end_stas_data.fish_type_num_data[fish_type] or 0) + num
	end

	for act_id,num in pairs(need_create_act_num_data) do
		end_stas_data.act_num_data[act_id] = (end_stas_data.act_num_data[act_id] or 0) + num
	end

	for rate,num in pairs(need_create_rate_fish_num_data) do
		end_stas_data.rate_fish_num_data[rate] = (end_stas_data.rate_fish_num_data[rate] or 0) + num
	end

	for use_fish_id,num in pairs(need_create_use_fish_num_data) do
		end_stas_data.use_fish_num_data[use_fish_id] = (end_stas_data.use_fish_num_data[use_fish_id] or 0) + num
	end

	

	-----------------------------------------  限制判段
	local limit_data = fd.random_cfg.limit and fd.random_cfg.limit[1]
	if limit_data.max_num and end_stas_data.all_fish_num  > limit_data.max_num then
		-- print( fd.t_num.."---------create fish limit , max_num" , end_stas_data.all_fish_num , limit_data.max_num , os.time() )

		-- dump(statis_data.rate_fish_num_data , "xxxxx--------------------end_stas_data.rate_fish_num_data:")

		return false
	end

	local total_act_num = 0
	local hide_act_num = 0
	local show_act_num = 0
	for act_id , num in pairs(end_stas_data.act_num_data) do
		total_act_num = total_act_num + num
		local act_cfg = DATA.fish_config.activity[ act_id ]
		if act_cfg.show == 0 then
			hide_act_num = hide_act_num + 1
		elseif act_cfg.show == 1 then
			show_act_num = show_act_num + 1
		end
	end
	---- 总共的活动数据
	if total_act_num > limit_data.max_act then
		-- print( "---------create fish limit , max_act" , total_act_num , limit_data.max_act , os.time() )
		return false
	end

	----- 某种活动鱼限制
	act_fish_limit_cfg = fd.random_cfg.act_fish_limit

	if end_stas_data.act_num_data and type(end_stas_data.act_num_data) == "table" then
		for act_id , num in pairs(end_stas_data.act_num_data) do
			if act_fish_limit_cfg and type(act_fish_limit_cfg) == "table" and act_fish_limit_cfg[act_id] then
				local act_limit_data = act_fish_limit_cfg[act_id] or {}
				local now_time = os.time()

				if act_limit_data.start_time and act_limit_data.end_time and 
					type(act_limit_data.start_time) == "number" and type(act_limit_data.end_time) == "number" then
					
					--if now_time > act_limit_data.end_time or now_time < act_limit_data.start_time then
					--	return false
					--else
						if num > act_limit_data.max_num then
							return false
						end
					--end

				end

				
			end
		end
	end
	----- 判断时间只能判断要创建的
	for act_id,num in pairs(need_create_act_num_data) do
		if act_fish_limit_cfg and type(act_fish_limit_cfg) == "table" and act_fish_limit_cfg[act_id] then
			local act_limit_data = act_fish_limit_cfg[act_id] or {}
			local now_time = os.time()

			if act_limit_data.start_time and act_limit_data.end_time and 
				type(act_limit_data.start_time) == "number" and type(act_limit_data.end_time) == "number" then
					
					if now_time > act_limit_data.end_time or now_time < act_limit_data.start_time then
						return false

					end

			end

				
		end
	end
	

	----- 总共的隐藏活动
	if hide_act_num > limit_data.max_hide then
		-- print( "---------create fish limit , max_hide" , hide_act_num , limit_data.max_hide , os.time() )
		return false
	end

	--- 一网打尽个数
	if end_stas_data.fish_type_num_data[4] and end_stas_data.fish_type_num_data[4] > (limit_data.ywdj_max or 0) then
		-- print( "---------create fish limit , ywdj_max" , end_stas_data.fish_type_num_data[4] , limit_data.ywdj_max , os.time() )
		return false
	end

	--- 敢死队个数
	if end_stas_data.fish_type_num_data[3] and end_stas_data.fish_type_num_data[3] > (limit_data.gsd_max or 0) then
		-- print( "---------create fish limit , gsd_max" , end_stas_data.fish_type_num_data[3] , limit_data.gsd_max , os.time() )
		return false
	end

	--- 某种鱼的个数限制
	if end_stas_data.use_fish_num_data and type(end_stas_data.use_fish_num_data) == "table" then
		for use_fish_id , num in pairs(end_stas_data.use_fish_num_data) do
			---- 
			if limit_data and limit_data.target_fish_limit and type(limit_data.target_fish_limit) == "table" and limit_data.target_fish_limit[use_fish_id] then
				if num > limit_data.target_fish_limit[use_fish_id] then
					return false
				end
			end
		end
	end




	---- 大于150倍的鱼限制
	local boss_yu_num = 0
	for rate,num in pairs(end_stas_data.rate_fish_num_data) do
		if rate > 150 then
			boss_yu_num = boss_yu_num + num
		end
	end
	if boss_yu_num > limit_data.boss_max then
		-- print( "---------create fish limit , boss_max" , boss_yu_num , limit_data.boss_max , os.time() )
		return false
	end

	return true
end
--统计函数  统计创建的鱼的各种数据
function PROTECTED.statistics_create_data(data , _fish_group_id)
	local stas_data = data.statis_data or {}
	local cfg_data = DATA.fish_config.group[_fish_group_id]

	if cfg_data then
		for key,use_fish_id in ipairs(cfg_data.fish_form) do
			local fish_num = cfg_data.count and cfg_data.count[key] or 1
			stas_data.all_fish_num = (stas_data.all_fish_num or 0) + fish_num

			local use_fish_cfg = DATA.fish_config.use_fish and DATA.fish_config.use_fish[use_fish_id] or nil
			if use_fish_cfg and use_fish_cfg.act_id then
				stas_data.act_num_data = stas_data.act_num_data or {}
				stas_data.act_num_data[use_fish_cfg.act_id] = (stas_data.act_num_data[use_fish_cfg.act_id] or 0) + fish_num
			end

			stas_data.rate_fish_num_data = stas_data.rate_fish_num_data or {}
			stas_data.rate_fish_num_data[use_fish_cfg.rate] = (stas_data.rate_fish_num_data[use_fish_cfg.rate] or 0) + fish_num

			stas_data.use_fish_num_data = stas_data.use_fish_num_data or {}
			stas_data.use_fish_num_data[use_fish_id] = (stas_data.use_fish_num_data[use_fish_id] or 0) + fish_num
		end

	
		stas_data.fish_type_num_data = stas_data.fish_type_num_data or {}
		stas_data.fish_type_num_data[cfg_data.fish_type] = (stas_data.fish_type_num_data[cfg_data.fish_type] or 0) + 1
	end


end
--立刻创建鱼 发往room
function PROTECTED.create_fish_atOnce(_t_num,finsh_data)
	--print("xxxxxxxxxxxxxxx-------------create_fish_atOnce")
	local data=DATA.game_table[_t_num].fishery_data

	---- 统计数据
	local statis_data = data.statis_data
	--- 区域创建的统计数据
	local area_create_data = statis_data.area_create_data or {}

	if finsh_data.area_id then
		area_create_data[finsh_data.area_id] = area_create_data[finsh_data.area_id] or { last_select_path = -100 }
		area_create_data[finsh_data.area_id].last_select_path = finsh_data.path

		-- print("xxxxxxxxxxx-------------------------last_select_path:", finsh_data.area_id , finsh_data.fish_group_id , area_create_data[finsh_data.area_id].last_select_path )
	end

	-- 调用创鱼接口
	PUBLIC.create_fish(_t_num,finsh_data)

end
---- 创建一个鱼组
--[[
	fd 渔场数据
	_fish_group_id 鱼组id
	_ared_id   区域id

	_create_time  创建时间

]]
-- --1 普通  2敢死队  3一网打尽
-- {
-- 	create_type = 1    
-- 	types = {2,1,2}  --use_fish 的id
-- 	speed= 2
-- 	group_id=
-- 	path = 2

-- 	create_time
-- 	lifetime

-- 	cfg = {pro=0.02}
-- }
function PROTECTED.create_one_fish_group(_t_num, _fish_group_id , _area_id , _guding_path , _guding_speed  ,_is_check , _now_time)
	local data = DATA.game_table[_t_num].fishery_data


	local now_time = _now_time or PROTECTED.get_now_time(data)

	local function create_fish_group_data(cfg_data , create_type , types , group_id , int_time , path_id, speed, create_time)
		--print("xxxxxxxxxx----------------create_fish_group_data",path_id,group_id)
		--dump(DATA.fish_config.path , "---------------------DATA.fish_config.path")
		--dump( types , "---------------------types" )

		local fish_data = {}
		fish_data.fish_group_id = _fish_group_id
		fish_data.create_type = create_type
		fish_data.types = types
		fish_data.speed = speed
		fish_data.group_id = group_id
		fish_data.create_time =  create_time - data.begin_time 
		fish_data.lifetime = DATA.fish_config.path[path_id].time-- * DATA.time_scale
		fish_data.path = path_id
		--- test
		fish_data.area_id = _area_id

		if int_time==0 then
			
			PROTECTED.create_fish_atOnce(_t_num,fish_data)

		else
			fish_data.create_countdown=int_time
			PROTECTED.add_to_createQueue(data,fish_data)
		end
	end

	--只有非固定创建鱼才检查能否创建
	if _is_check then
		if not PROTECTED.check_is_can_create_fish_group(data,_fish_group_id) then
			return false
		end
	end
	---- 统计数据
	PROTECTED.statistics_create_data(data,_fish_group_id)

	-------------------
	if DATA.fish_config and DATA.fish_config.group and DATA.fish_config.group[_fish_group_id] then
		local cfg_data = DATA.fish_config.group[_fish_group_id]

		
		local create_type = 1 
		if cfg_data.fish_type == 3 then
			create_type = 2
		elseif cfg_data.fish_type == 4 then
			create_type = 3
		end

		local group_id 
		--目前只有一网打尽有group_id
		if create_type==3 then
			group_id= PROTECTED.get_new_group_id()

			-------- 
			local statis_data = data.statis_data
			statis_data.deal_group_fish_type = statis_data.deal_group_fish_type or {}
			statis_data.deal_group_fish_type[group_id] = false
		end

		--创建鱼的方式 1一次性创建 和 2逐个创建 
		local is_once_create=1
		if cfg_data.fish_type==2 or cfg_data.int  or (create_type==3 and cfg_data.path and #cfg_data.path>1) then
			is_once_create=2
		end

		-- 一次性创建
		if is_once_create == 1 then
			local types = {}
			for key,use_fish_id in ipairs(cfg_data.fish_form) do
				local fish_num = cfg_data.count and cfg_data.count[key] or 1
				for i=1,fish_num do
					types[#types + 1] = use_fish_id
				end
			end
			--路线规则： group有则用group的 没有则用外部传递的
			local path=_guding_path
			if cfg_data.path then
				path=cfg_data.path[1]
			end
			--速度规则： 外部有传递则用外部的 否则用group的 
			local speed=_guding_speed
			if not speed and cfg_data.speed then
				speed=cfg_data.speed[1]
			end

			create_fish_group_data(cfg_data , create_type , types , group_id , 0 , path,speed, now_time)

		--逐个创建 	
		else
			local created_fish_num = 0
			for key,use_fish_id in ipairs(cfg_data.fish_form) do
				local fish_num = cfg_data.count and cfg_data.count[key] or 1
				for i=1,fish_num do
					local types = {}
					types[#types + 1] = use_fish_id

					local path=_guding_path
					--路线规则： group有则用group的 没有则用外部传递的
					if cfg_data.path then
						if cfg_data.path[key] then
							path=cfg_data.path[key]
						else
							path=cfg_data.path[1]
						end
					end
					--速度规则： 外部有传递则用外部的 否则用group的 
					local speed=_guding_speed
					if not speed and cfg_data.speed then
						if cfg_data.speed[key] then
							speed=cfg_data.speed[key]
						else
							speed=cfg_data.speed[1]
						end
					end
					local int_time=0

					--创建间隔 
					if cfg_data.int then
						int_time=created_fish_num*cfg_data.int
					end	

					created_fish_num = created_fish_num + 1

					create_fish_group_data(cfg_data , create_type , types , group_id , int_time , path, speed, now_time)

				end

			end
		end
	end

	return true
end

function PROTECTED.create_random_fish(fd , _area_id )

	local now_time = PROTECTED.get_now_time(fd)

	--dump(fd.create_fish_style[_area_id] , "xxxxxxxxxxxx-------------fd.create_fish_style")

	if fd.create_fish_style[_area_id] then
		local total_power = 0
		for key,data in pairs(fd.create_fish_style[_area_id]) do
			total_power = total_power + data.power
		end

		local rand = math.random(total_power)
		local now_power = 0
		for key,data in pairs(fd.create_fish_style[_area_id]) do
			if rand <= now_power + data.power then
				---- 要创建鱼组了。
				local fish_group_id = PROTECTED.get_fish_group_by_power( data.data.choose_group  , fd.random_cfg[data.data.create_config] )
				if fish_group_id then
					
					----###test  ***********
						-- local rand_fish_group_vec = {10000+1,10000+2,10000+29,10000+53}
						-- local rand_fish_group_vec = {140}
						-- local rand_fish_group_vec = {10000+1,10000+27,10000+24,10000+25,}
						-- local rand_fish_group_vec = {10000+1,10000+22,}
						-- local rand_fish_group_vec = {10000+102,}
						-- local rand_fish_group_vec = {171,172}
						-- fish_group_id = rand_fish_group_vec[ math.random(#rand_fish_group_vec) ]
					----###test  ***********

					return PROTECTED.deal_create_one_fish_group(fd , fish_group_id , _area_id)
				end
				break
			end
			now_power = now_power + data.power
		end
	else
		print("error-----------no fd.create_fish_style[_area_id]:",_area_id)
	end

	return true
end

function PROTECTED.update_create_fish(fd )
	--print("xxxxxxxxx---------------update_create_fish")
	local now_time = PROTECTED.get_now_time(fd)

	--dump(fd.create_rate_style , "xxxxx------------------fd.create_rate_style")


	for area_id,data in ipairs(fd.create_rate_style) do
		--print("--------------------update_create_fish:",now_time , data.next_create_time)

		if now_time >= data.next_create_time then
			data.next_create_time = now_time + math.random( data.min_time , data.max_time )

			for i=1,10 do
				---- 创建鱼
				local is_created = PROTECTED.create_random_fish(fd , area_id )
				--print("xxxxxxxxxxxxxxxxxxx---------------is_created",is_created)

				if is_created then
					--print("xxxxxxxxxxxxxxxxxxx---------------is_created true")
					break
				end
			end
		end

	end

end

function PROTECTED.create_fish_by_guding(dt,_t_num)
	local data=DATA.game_table[_t_num].fishery_data
	local guding_cfg=data.guding_cfg

	local now_time = PROTECTED.get_now_time(data)

	if guding_cfg then
		for k,v in ipairs(guding_cfg) do
			if v.create_fish_time then

				if v.create_fish_time<=now_time then

					for _pos,fish_g_id in ipairs(v.fish) do
						local path
						local speed
						if v.path then
							path=v.path[_pos] or PROTECTED.get_random_path( DATA.fish_config.path )
						end
						if v.speed then
							speed=v.speed[_pos]
						end
						PROTECTED.create_one_fish_group(_t_num, fish_g_id , nil , path , speed , nil , v.create_fish_time)
					end
					v.create_fish_time = nil
				end
			end
		end
	end

end


function PROTECTED.reset_createQueue(data)
	data.create_queue={}
	data.create_queue_index=1
end
function PROTECTED.add_to_createQueue(data,fish_data)
	data.create_queue[data.create_queue_index]=fish_data
	data.create_queue_index=data.create_queue_index+1
end

-- 按间隔创建鱼
function PROTECTED.create_fish_by_createQueue(dt,_t_num)

		local data=DATA.game_table[_t_num].fishery_data
		if data.create_queue then
			for k,f in pairs(data.create_queue) do
				f.create_countdown=f.create_countdown-dt
				if f.create_countdown<=0 then

					f.create_countdown=nil
					f.create_time=PROTECTED.get_now_time(data)-data.begin_time
					--创建
					PROTECTED.create_fish_atOnce(_t_num,f)
					--
					data.create_queue[k]=nil
				end
			end 
		end
end

--[[
_f.create_fish_cbk(_create_type,_types,_data,_cfg,_path,_create_time,_lifetime)


--1 普通  2敢死队  3一网打尽
{
	create_type = 1    
	types = {2,1,2}  --use_fish 的id
	speed= 2
	group_id=
	path = 2

	create_time
	lifetime

	cfg = {pro=0.02}
}







-- 事件
function PROTECTED.event(_t_num,_event,_arg1,_arg2,_arg3,_arg4)
	local ff = fishery_data[_t_num]
	if not ff then
		return
	end

	if _event == "frozen" then

		ff.next_create_fish_time = ff.next_create_fish_time + _arg1
		ff.fish_boom_time = ff.fish_boom_time + _arg1

	else

	end

end


-- 清除
function PROTECTED.destory(_t_num)
	fishery_data[_t_num] = nil
end

--]]

-- 事件
function PROTECTED.event(_t_num,_event,_arg1,_arg2,_arg3,_arg4)
	local ff = DATA.game_table[_t_num].fishery_data
	if not ff then
		return
	end

	if _event == "frozen" then
		if not _arg2 then
			_arg2 = 0
		end

		ff.frozen_time = ff.frozen_time + _arg2
		if ff.changci_end_time then
			ff.changci_end_time = ff.changci_end_time + _arg2 * DATA.time_scale
		end

		if ff.create_rate_style then
			for key,data in pairs(ff.create_rate_style) do
				if data.next_create_time then
					data.next_create_time = data.next_create_time + _arg2 * DATA.time_scale
				end
			end
		end

		if ff.guding_cfg then
			for k,v in pairs(ff.guding_cfg) do
				if v.create_fish_time then
					v.create_fish_time = v.create_fish_time + _arg2 * DATA.time_scale
				end
			end
		end

	else

	end

end

---- 改变 鱼的创建速率
--[[
	返回一个1~4个区域的列表  { [1] = { min_time = xx,max_time = nn , next_create_time } , [2] = { ... } , ... }
--]]
function PROTECTED.deal_change_create_rate(fd , _now_time)
	local area_data = {}

	if not fd.random_cfg.intensity_style then
		return area_data
	end

	local random_area_data = fd.random_cfg.intensity_style[ math.random(#fd.random_cfg.intensity_style ) ]
	local real_area_data = {}

	for i=1,random_area_data.low do
		real_area_data[#real_area_data + 1] = 1
	end
	for i=1,random_area_data.medium do
		real_area_data[#real_area_data + 1] = 2
	end
	for i=1,random_area_data.high do
		real_area_data[#real_area_data + 1] = 3
	end

	---- 打乱顺序
	for i=1,#real_area_data-1 do
		local rand_index = math.random( 1 , #real_area_data )
		real_area_data[i],real_area_data[rand_index] = real_area_data[rand_index],real_area_data[i]
	end

	for i=1,4 do
		local create_speed_cfg = fd.random_cfg.create_speed_cfg[ real_area_data[i] or 1 ]

		area_data[i] = {}
		area_data[i].min_time = create_speed_cfg.min_time
		area_data[i].max_time = create_speed_cfg.max_time
		area_data[i].next_create_time = _now_time + math.random( area_data[i].min_time  , area_data[i].max_time )
	end

	return area_data
end
---- 改变 鱼的类型
--[[
	返回一个1~4个区域的列表  { [1] = { [1] = {data = data1 , power = xx} , [2] = {data = data1 , power = xx} ... } , [2] = { ... } , ... }
--]]
function PROTECTED.deal_change_create_fish(fd , _now_time)
	local area_data = {}


	for i=1,4 do 
		local create_cfg = basefunc.deepcopy( fd.random_cfg.create )
		local random_cfg = fd.random_cfg.create_style[ math.random( #fd.random_cfg.create_style ) ]

		area_data[i] = area_data[i] or {}
		local a_data = area_data[i]

		for i=1,random_cfg.low do
			local rand_index = math.random(#create_cfg)
			local _data = basefunc.deepcopy( create_cfg[rand_index] )
			table.remove( create_cfg , rand_index )
			local _power = _data.create_pro[1] or 0

			a_data[#a_data + 1] = {data = _data ,power = _power}
		end

		for i=1,random_cfg.medium do
			local rand_index = math.random(#create_cfg)
			local _data = basefunc.deepcopy( create_cfg[rand_index] )
			table.remove( create_cfg , rand_index )
			local _power = _data.create_pro[2] or 0


			a_data[#a_data + 1] = {data = _data ,power = _power}
		end

		for i=1,random_cfg.high do
			local rand_index = math.random(#create_cfg)
			local _data = basefunc.deepcopy( create_cfg[rand_index] )
			table.remove( create_cfg , rand_index )
			local _power = _data.create_pro[3] or 0

			a_data[#a_data + 1] = {data = _data ,power = _power}
		end

	end

	return area_data
end


----- update处理改变风格
function PROTECTED.update_deal_change_create_style(fd )
	if fd then
		local now_time = PROTECTED.get_now_time(fd)
		if now_time > fd.next_change_style_time then
			--print("--------------------- update_deal_change_create_style")
			fd.next_change_style_time = now_time + PROTECTED.get_random_change_style_time(fd)

			fd.create_rate_style = PROTECTED.deal_change_create_rate(fd , now_time)
			fd.create_fish_style = PROTECTED.deal_change_create_fish(fd , now_time)

			--dump(fd.create_fish_style , "xxxxxxxxx-----------------fd.create_fish_style:")

		end
	end
end

function PROTECTED.deal_update( dt , _t_num )
	--print("----------------deal_update")

	local fd = DATA.game_table[_t_num].fishery_data
	--- 随机创鱼
	if fd.random_cfg then
		--print("--------------------xxxxxxxxxxxxxxxxxx----------------deal_update---random_cfg",DATA.my_id , _t_num)
		PROTECTED.update_deal_change_create_style(fd)
		PROTECTED.update_create_fish(fd )
	end
	--- 固定创鱼
	if fd.guding_cfg then
		--print("--------------------xxxxxxxxxxxxxxxxxx----------------deal_update---guding_cfg",DATA.my_id , _t_num)
		PROTECTED.create_fish_by_guding(dt,_t_num)
	end
end

function PROTECTED.update(dt)
	--print("xxxxxx---update")
	for _t_num,v in pairs(DATA.game_table) do
		
		PROTECTED.timemachine_update(1,_t_num , dt , false)
		
	end
end

--按0.1秒为单位
function PROTECTED.timemachine_update(times,_t_num , _dt , is_new_room)
	local dt = _dt or 0.1
	local data = DATA.game_table[_t_num].fishery_data
	if not data then
		return
	end

	local now_run_time = PROTECTED.get_now_time(data)
	if not is_new_room and math.abs( now_run_time - os.time()*DATA.time_scale ) > 5*DATA.time_scale then
		print( string.format( "---------------------time not right:now_run_time:%d , now_time:%d" , now_run_time , os.time()*DATA.time_scale ) )
	end

	local is_frozen = false
	if data.frozen_time and data.frozen_time > 0 then
		data.frozen_time = data.frozen_time - dt
		is_frozen = true
	else
		data.frozen_time = 0
	end

	for i=1,times do
		if data.virtual_time then
			data.virtual_time=data.virtual_time+1
		end
		if not is_frozen then
			PROTECTED.deal_update(1 , _t_num)
			PROTECTED.create_fish_by_createQueue(1,_t_num)
			PROTECTED.changci_run_update(_t_num)
		end
	end
end

function PROTECTED.fish_dead(_t_num,_create_type,_use_fish_id , _group_id)
	local fd =DATA.game_table[_t_num].fishery_data
	local statis_data = fd.statis_data

	statis_data.all_fish_num = (statis_data.all_fish_num or 0) - 1
	-- print("xxxxxx------------------fish_dead --:",_use_fish_id,statis_data.all_fish_num)


	statis_data.deal_group_fish_type = statis_data.deal_group_fish_type or {}
	if _group_id and not statis_data.deal_group_fish_type[_group_id] then
		statis_data.deal_group_fish_type[_group_id] = true
		statis_data.fish_type_num_data = statis_data.fish_type_num_data or {}
		statis_data.fish_type_num_data[_create_type] = (statis_data.fish_type_num_data[_create_type] or 0) - 1
	end

	local use_fish_cfg = DATA.fish_config.use_fish and DATA.fish_config.use_fish[_use_fish_id] or nil

	if use_fish_cfg then


		statis_data.act_num_data = statis_data.act_num_data or {}
		
		if use_fish_cfg.act_id then
			statis_data.act_num_data[use_fish_cfg.act_id] = (statis_data.act_num_data[use_fish_cfg.act_id] or 0) - 1
			-- print("xxxxxx------------------fish_dead --act_id:",_use_fish_id , use_fish_cfg.act_id , statis_data.act_num_data[use_fish_cfg.act_id] )
		end

		statis_data.rate_fish_num_data = statis_data.rate_fish_num_data or {}

		statis_data.rate_fish_num_data[use_fish_cfg.rate] = (statis_data.rate_fish_num_data[use_fish_cfg.rate] or 0) - 1

		statis_data.use_fish_num_data = statis_data.use_fish_num_data or {}
		statis_data.use_fish_num_data[_use_fish_id] = (statis_data.use_fish_num_data[_use_fish_id] or 0) - 1

	else 
		print(_t_num.."---------------error----- no use_fish_cfg for :",_use_fish_id)
	end


end

---- 获得随机的改变style的时间
function PROTECTED.get_random_change_style_time(fd)
	local random_time = 10
	if DATA.fish_config and fd.random_cfg.change_style then
		local data = fd.random_cfg.change_style[1]
		if data then
			random_time = math.random( data.change_time_min  , data.change_time_max  )
		end
	end
	return random_time
end

function PROTECTED.init(_t_num)
	
	if not DATA.fish_config then
		while true do
			-- 鱼的配置还没有 等一会儿
			if DATA.fish_config == nil then
				skynet.sleep(1)
			else
				assert(DATA.fish_config.fish)
				assert(DATA.fish_config.path)
				break
			end
		end
	end

	DATA.game_table[_t_num].fishery_data = {
		t_num = _t_num,
		begin_time = 0,
		next_change_style_time = 0,
		create_rate_style = {} ,
		create_fish_style = {} ,
		statis_data = { all_fish_num = 0, area_create_data = {} } ,
		frozen_time = 0,
		changci_index = 1,
	}


	PROTECTED.new_changci(_t_num,true)

	--return DATA.game_table[_t_num].fishery_data.begin_time
end


function PROTECTED.changci_run_update(_t_num)
	local data=DATA.game_table[_t_num].fishery_data
	local cur_time=os.time()*DATA.time_scale
	
	if data.changci_end_time then
		if cur_time>=data.changci_end_time then
			data.changci_end_time=nil
			PROTECTED.changci_gameover(_t_num)
		end
	end
	if data.new_changci_time then
		if cur_time>=data.new_changci_time then
			PROTECTED.new_changci(_t_num)
		end
	end
end
--[[
	场次调度
	决定本场次鱼的呈现形式
	
	is_new_room --是否是新建房间
	
	begin_time --渔场开始时间
	new_changci_time  --刷新渔场的时间
	changci_end_time  --渔场结束的时间

	random_cfg --随机方式产鱼的配置
	guding_cfg --固定方式产鱼的配置
--]]
function PROTECTED.new_changci(_t_num,is_new_room)
	local data=DATA.game_table[_t_num].fishery_data
	data.new_changci_time=nil

	local cur_time=os.time()*DATA.time_scale

	local tiqian_time=0
	if is_new_room then
		--提前时间  
		tiqian_time = math.random(50,150)
		--tiqian_time = 0
		data.begin_time	=cur_time-tiqian_time
	else
		data.begin_time	=cur_time
	end
	
	data.vir_now_time=cur_time
	data.skynet_now_time= skynet.now()

	data.next_change_style_time = data.begin_time


	PROTECTED.reset_createQueue(data)
	--选择场次
	PROTECTED.choose_changci(data,is_new_room)
	

	--如果是新建房间  调用预创
	if is_new_room then
		data.virtual_time=data.begin_time
		PROTECTED.timemachine_update(tiqian_time,_t_num , nil , true )
		data.virtual_time=nil
	end

end

function PROTECTED.choose_changci(data,is_new_room)
	if is_new_room then
		data.cur_yuchang_type="nor"
	else
		if data.cur_yuchang_type=="nor" then
			data.cur_yuchang_type="guoding"
		else
			data.cur_yuchang_type="nor"
		end
	end
	-- ###_test 暂时简单实现 普通鱼与固定鱼潮交替出
	local yutu_vec = {}
	if data.cur_yuchang_type=="nor" then
		
		data.image_no=1

	else
		--[[local num=math.random(1,100)
		if num<25 then
			data.image_no=2
		elseif num<50 then
			data.image_no=3
		elseif num<75 then
			data.image_no=4
		else
			data.image_no=5
		end--]]

		local guding_yu_vec = {2,3,4,5,6,7,8}

		local while_num = 0
		while true do
			while_num = while_num + 1
			data.image_no = guding_yu_vec[math.random( #guding_yu_vec )]

			if DATA.fish_config.image_cfg[data.image_no] then
				break
			end
			if while_num > 5 then
				data.image_no = 2
				break
			end
		end

	end

	local image_cfg=DATA.fish_config.image_cfg[data.image_no]
	data.changci_end_time=data.begin_time+math.random(image_cfg.over_time_min,image_cfg.over_time_max)

	if image_cfg.random_no then
		data.random_cfg= DATA.random_yutu_config[image_cfg.random_no].cfg --DATA.fish_config[image_cfg.random_no] and DATA.fish_config[image_cfg.random_no].cfg
		dump( data.random_cfg , "xxxxxx--------------------------data.random_cfg" )

		if not data.random_cfg then
			print("error--------- no random cfg!!")
		end
	end
	if image_cfg.guding_no then
		data.guding_cfg=basefunc.deepcopy(DATA.guding_yutu_config[image_cfg.guding_no].cfg )

		print("----------------------image_cfg.guding_no:",image_cfg.guding_no)
		if not data.guding_cfg then
			print("error--------- no guding cfg!!")
		end

		----- 把time_frame换成指定时间
		if data.guding_cfg then
			for k,v in ipairs(data.guding_cfg) do
				v.create_fish_time = data.begin_time + v.time_frame
			end
		end

		dump( data.guding_cfg , "xxxxxx--------------------------data.guding_cfg" )
	end


end
function PROTECTED.changci_gameover(_t_num)
	local data=DATA.game_table[_t_num].fishery_data

	---- 结束之后加，
	data.changci_index = data.changci_index + 1

	local delay_time = 1

	local cur_time=os.time()*DATA.time_scale+ delay_time*DATA.time_scale
	data.begin_time	=cur_time
	--清除鱼 ###_test  !!!!!!!
	PUBLIC.clear_fish(_t_num)

	--- 统计数据清理
	data.statis_data = { all_fish_num = 0, area_create_data = {} }

	data.create_queue=nil
	data.changci_end_time=nil
	data.random_cfg=nil
	data.guding_cfg=nil

	--新开时间  一般要等一段时间在开始创建  
	data.new_changci_time=os.time()*DATA.time_scale + delay_time*DATA.time_scale

end

return PROTECTED














