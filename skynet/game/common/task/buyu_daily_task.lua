---- 
---- 捕鱼每日任务


local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local task_base_func = require "task.task_base_func"
local common_task = require "task.common_task"

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST
local PUBLIC = base.PUBLIC

DATA.buyu_daily_task_protect = {}
local task = DATA.buyu_daily_task_protect

function task.gen_task_obj(config,data)
	local obj = common_task.gen_task_obj(config,data)

	---------------------------- 重写部分代码 ----------------------------------
	obj.init = function (is_refresh_cfg)
		print("xxxxx-------------------------------buyu_daily_task_init:")
		PUBLIC.deal_msg(obj)

		obj.tag = "buyu_daily_task"

		--- 监听消息
		DATA.msg_dispatcher:register( obj , obj.msg )

		if obj.reset_timecancler then
			obj.reset_timecancler()
		end

		--- 处理是否重置进程
		if obj.config.is_reset == 1 then
			PUBLIC.deal_reset_process( obj )   
		end

		obj.max_process , obj.max_task_round = task_base_func.get_max_process(obj.config.process_data) 

		obj.lv = 1
		obj.process_index = 1

		obj.get_lv_info() 

		if not is_refresh_cfg then

			if obj.process < obj.max_process then
				------- 任务的子任务
				--- 从数据库中获取任务的其他数据
				local task_data = skynet.call( DATA.service_config.task_center_service , "lua" , "query_player_one_task_data" , DATA.my_id , obj.id )

				local is_create_children_task = false
				if task_data and task_data.other_data then
					local other_parse_data = task_base_func.parse_activity_data(task_data.other_data)
					if other_parse_data and other_parse_data.children_task_ids and type(other_parse_data.children_task_ids) == "table" and next(other_parse_data.children_task_ids) then
						print("wwww---------------buyu_task_init 1")
						obj.distribute_one_buyu_children_task( other_parse_data.children_task_ids )
						is_create_children_task = true
					end
				end

				if not is_create_children_task then
					obj.distribute_one_buyu_children_task()
				end
			end
		end


	end

	obj.update_other_data = function()
		PUBLIC.update_task_other_data( obj.id , { children_task_ids = obj.children_task_ids } )
	end

	--- 分配一个子任务
	obj.distribute_one_buyu_children_task = function( _old_task_ids )
		obj.children_task_ids = _old_task_ids 
		if not obj.children_task_ids then
			obj.children_task_ids = {}
			for i=1,1 do 
				obj.children_task_ids[#obj.children_task_ids + 1] = obj.get_one_buyu_children_task_id()
			end
		end


		---- 写入
		if not _old_task_ids then
			skynet.timeout( 200 , function()
				obj.update_other_data()
			end)
			
		end

		---- 分配任务
		if obj.children_task_ids and type(obj.children_task_ids) == "table" then
			--dump(DATA.task_list , "wwww------------------DATA.task_list:")
			for key, task_id in pairs(obj.children_task_ids) do
				obj.distribute_children_task(task_id)
			end
		end

	end

	obj.distribute_children_task = function(task_id)
		if not DATA.task_list[task_id] then
			local ob_task_data = skynet.call( DATA.service_config.task_center_service , "lua" , "query_player_one_task_data" , DATA.my_id , task_id )

			local data = ob_task_data or {
				process = 0,
				task_round = 1,
				create_time = os.time(),
				task_award_get_status = 0,
			}

			PUBLIC.add_one_task(task_id,data )
					
			DATA.task_list[task_id].update_data()
		end
	end


	----- 获得一个子任务id
	obj.get_one_buyu_children_task_id = function()
		local buyu_task_config = nodefunc.get_global_config("buyu_daily_task_server") 
		local biao_name = "buyu_daily_task1"

		if obj.config.own_type == "buyu_daily_task1" then
			biao_name = "buyu_daily_task1"
		elseif obj.config.own_type == "buyu_daily_task2" then
			biao_name = "buyu_daily_task2"
		elseif obj.config.own_type == "buyu_daily_task3" then
			biao_name = "buyu_daily_task3"
		elseif obj.config.own_type == "buyu_daily_task4" then
			biao_name = "buyu_daily_task4"
		end

		local target_task_id = 0
		local total_weight = 0

		for key,data in pairs(buyu_task_config[biao_name]) do 
			total_weight = total_weight + data.weight
		end

		local rand_weight = math.random(total_weight)
		local now_weight = 0
		for key,data in pairs(buyu_task_config[biao_name]) do 
			if rand_weight <= now_weight + data.weight then
				target_task_id = data.task_id
				break
			end
			now_weight = now_weight + data.weight
		end

		return target_task_id
	end

	--- 一个子任务完成
	obj.one_children_task_complete = function(c_task_id)
		if obj.children_task_ids and type(obj.children_task_ids) == "table" then
			for key,task_id in pairs(obj.children_task_ids) do
				if c_task_id == task_id then
					PUBLIC.delete_one_task( task_id )
					table.remove( obj.children_task_ids , key )

					if obj.process ~= obj.max_process then 
						--- 再加一个
						local new_task_id = obj.get_one_buyu_children_task_id()
						obj.children_task_ids[#obj.children_task_ids + 1] = new_task_id
						obj.distribute_children_task(new_task_id)
					else
						for _,task_id in pairs(obj.children_task_ids) do
							PUBLIC.delete_one_task( task_id )
						end
						obj.children_task_ids = {}
					end
					---- 通知改变
					PUBLIC.children_task_id_change(obj)

					obj.update_other_data()
					break
				end
			end
		end
	end

	----- 子任务完成
	obj.children_task_complete_deal = function()
		obj.msg.task_complete = function(_ , _task_id)
			if obj.children_task_ids and type(obj.children_task_ids) == "table" then
				for key,task_id in pairs(obj.children_task_ids) do
					if _task_id == task_id then
						local is_change = obj.add_process(1)
						if is_change then

							obj.one_children_task_complete(task_id)
							
						end

						break
					end
				end
			end

			
		end
	end

	return obj
end


return task