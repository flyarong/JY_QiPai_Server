--
-- Created by lyx.
-- User: hare
-- Date: 2018/11/6
-- Time: 14:59
-- 任务进程管理器
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local task_initer = require "task.init"
local task_base_func = require "task.task_base_func"

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST
local PUBLIC = base.PUBLIC

---- 任务的重置时间
DATA.REST_TIME = 6

local is_send = false

---奖励状态
DATA.award_status = {
	not_can_get = 0,
	can_get = 1,
	complete = 2,
	not_open = 3,     --- 未开启
}

DATA.task_mgr_protect = {}
local PROTECT = DATA.task_mgr_protect
--- 当前拥有的任务列表，-- key 值是任务id,value 是任务obj
DATA.task_list = {}    

---- 增加一个任务
function PUBLIC.add_one_task(task_id,data , task_list)
	print("add_one_task:",task_id,data)
	local task_config = skynet.call(DATA.service_config.task_center_service,"lua","get_main_config")
	local config = task_config[task_id]
	if not config or not data then
		error("not task config!")
	end

	---- 如果是步步生财任务，就不能加入任务列表里面
	if config.own_type == "step_task" then
		return
	end

	local task_obj = task_initer.gen_task_obj(config,data)

	if task_obj then
		print("add_one_task:task_obj",task_obj)
		task_obj.init()

		if task_list then
			task_list[task_id] = task_obj
		else
			DATA.task_list[task_id] = task_obj
		end

		if task_id == 201 then
			dump(DATA.task_list[task_id] , "xxxxxxxxx--------------201 task")
		end

	end

	if is_send then
		PUBLIC.deal_task_progress_change(task_obj)
		
	end
end



local function load_ob_data()
	local history_task = skynet.call(DATA.service_config.task_center_service,"lua","query_player_task_data",DATA.my_id)
	--dump(history_task , "--------------------  history_task")
	
	if history_task and type(history_task) == "table" then
		for task_id,d in pairs(history_task) do
			PUBLIC.add_one_task(task_id,d)
		end
	end

end


---- 删掉一个任务
function PUBLIC.delete_one_task( task_id )
	if DATA.task_list and DATA.task_list[task_id] then
		DATA.task_list[task_id].destory()
		DATA.task_list[task_id] = nil
		
		skynet.send(DATA.service_config.task_center_service,"lua","delete_player_task",DATA.my_id,task_id)
	end
end

----- 给外部调用的删除任务列表
function CMD.delete_tasks(task_id_vec)
	for key,task_id in ipairs(task_id_vec) do
		PUBLIC.delete_one_task( task_id )
	end
end

----- 删掉金猪任务
function PUBLIC.delete_goldpig_task()
	for task_id , task_obj in pairs(DATA.task_list) do
		if task_obj.config.own_type == "goldpig" or task_obj.config.own_type == "goldpig_new" then
			PUBLIC.delete_one_task( task_id )
		end
	end
end

----- 删掉金猪任务2
function PUBLIC.delete_goldpig2_task()
	for task_id , task_obj in pairs(DATA.task_list) do
		if task_obj.config.own_type == "goldpig_new2" then
			PUBLIC.delete_one_task( task_id )
		end
	end
end

function PUBLIC.delete_jingib_zhouka_task()
	for task_id , task_obj in pairs(DATA.task_list) do
		if task_obj.config.own_type == "jingbi_zhouka" then
			PUBLIC.delete_one_task( task_id )
		end
	end
end

function PUBLIC.delete_qys_zhouka_task()
	for task_id , task_obj in pairs(DATA.task_list) do
		if task_obj.config.own_type == "qys_zhouka" then
			PUBLIC.delete_one_task( task_id )
		end
	end
end

---- 
function PUBLIC.delete_vip_lb_task_1()
	for task_id , task_obj in pairs(DATA.task_list) do
		if task_obj.config.own_type == "vip_task1" then
			PUBLIC.delete_one_task( task_id )
		end
	end
end

function PUBLIC.delete_vip_lb_task_2()
	for task_id , task_obj in pairs(DATA.task_list) do
		if task_obj.config.own_type == "vip_task2" then
			PUBLIC.delete_one_task( task_id )
		end
	end
end

function PUBLIC.deal_vip_lb_task_auto_get()
	for task_id , task_obj in pairs(DATA.task_list) do
		if task_obj.config.own_type == "vip_task1" or task_obj.config.own_type == "vip_task2" then
			if task_obj.auto_get_task_award then
				task_obj.auto_get_task_award()
			end
		end
	end
end

function CMD.distribute_task()
	is_send = true
	PROTECT.distribute_task()
	is_send = false
end


------ 更新一个任务的其他数据
function PUBLIC.update_task_other_data(task_id , data)
	local ser_data = data and basefunc.safe_serialize(data) or nil

	if ser_data then
		skynet.send(DATA.service_config.task_center_service,"lua","update_player_task_other_data",DATA.my_id,task_id , ser_data)
	end
end


---派发任务；根据玩家的自身条件返回一个任务id列表
--[[
	玩家刚进入，执行一次，需要有任务增删的地方执行一次

--]]
function PROTECT.distribute_task()
	print("xxxxx-----------------distribute_task:" , DATA.my_id)
	local task_config = skynet.call(DATA.service_config.task_center_service,"lua","get_main_config")
	local own_task_table = {}
	local now_time = os.time()
	--dump(task_config , "-----------------distribute_task----task_config")
	for task_id,task_data in pairs(task_config) do
		repeat

			--- 不启用
			if task_data.enable == 0 then
				break
			end

			if task_data.own_type == "normal" then
				own_task_table[task_id] = true
			--elseif task_data.own_type == "zajindan_activity" then
			--	own_task_table[task_id] = true
			elseif task_data.own_type == "vip" then
				--- 如果自己是vip,这个任务加给他
				-- print("<<<<< distribute_task >>>>>>> DATA.player_data.vip_data.status ",DATA.player_data.vip_data.status)
				if DATA.player_data.vip_data and DATA.player_data.vip_data.status == DATA.vip_status.is_vip then
					own_task_table[task_id] = true
				end
			elseif task_data.own_type == "goldpig" then
				if DATA.goldpig_data.is_buy_goldpig == 1 and DATA.goldpig_data.goldpig_remain_num > 0 then
					own_task_table[task_id] = true
				end
			elseif task_data.own_type == "goldpig_new" then 
				if DATA.goldpig_data.is_buy_goldpig1 == 1 and DATA.goldpig_data.goldpig_remain_num1 > 0 then
					own_task_table[task_id] = true
				end
			elseif task_data.own_type == "goldpig_new2" then 
				if DATA.goldpig_data.is_buy_goldpig2 == 1 and DATA.goldpig_data.goldpig_remain_num2 > 0 then
					own_task_table[task_id] = true
				end
			elseif task_data.own_type == "jingbi_zhouka" then 
				if DATA.zhouka_data and DATA.zhouka_data.is_buy_jingbi_zhouka == 1 and DATA.zhouka_data.jingbi_zhouka_remain > 0 then
					own_task_table[task_id] = true
				end
			elseif task_data.own_type == "qys_zhouka" then 
				if DATA.zhouka_data and DATA.zhouka_data.is_buy_qys_zhouka == 1 and DATA.zhouka_data.qys_zhouka_remain > 0 then
					own_task_table[task_id] = true
				end
			elseif task_data.own_type == "vip_task1" then 
				if DATA.vip_lb_data and DATA.vip_lb_data.is_buy_vip_lb == 1 and DATA.vip_lb_data.now_vip_task_get_num1 < DATA.vip_lb_data.now_vip_task_max_num1
					and DATA.vip_lb_data.task_overdue_time > now_time then
					own_task_table[task_id] = true
				end
			elseif task_data.own_type == "vip_task2" then 
				if DATA.vip_lb_data and DATA.vip_lb_data.is_buy_vip_lb == 1 and DATA.vip_lb_data.now_vip_task_get_num2 < DATA.vip_lb_data.now_vip_task_max_num2 
					and DATA.vip_lb_data.task_overdue_time > now_time then
					own_task_table[task_id] = true
				end
			elseif task_data.own_type == "buyu_daily_task1" or task_data.own_type == "buyu_daily_task2" or task_data.own_type == "buyu_daily_task3" or task_data.own_type == "buyu_daily_task4" then 
				own_task_table[task_id] = true

			elseif task_data.own_type == "bbsc_big_step_task" then 
				--- 新版的bbsc的任务
				local bbsc_data = skynet.call(DATA.service_config.data_service,"lua","query_player_stepstep_money" , DATA.my_id )
				if not bbsc_data or bbsc_data.bbsc_version == "new" then
					own_task_table[task_id] = true
				end

			end

		until true
	end 
	--dump(own_task_table , "-----------------distribute_task----own_task_table")
	PROTECT.add_or_delete_task( own_task_table )
end


function PROTECT.add_or_delete_task( own_task_table )
	-- dump(own_task_table , "----->>>>>add_or_delete_task1")
	-- dump(DATA.task_list , "----->>>>>add_or_delete_task2 , DATA.task_list")
	local task_table_temp = basefunc.deepcopy(own_task_table)
	local task_config = skynet.call(DATA.service_config.task_center_service,"lua","get_main_config")

	for task_id,data in pairs(DATA.task_list) do
		local isFind = false
		for own_task_id,data in pairs(task_table_temp) do
			if task_id == own_task_id then
				isFind = true
				task_table_temp[own_task_id] = nil

				--- 如果找到了，更新一下
				DATA.task_list[task_id].refresh_config( task_config[task_id] ) 
				break
			end
		end

		--- 没找到做移除
		if not isFind then
			----------先判断一下是不是 别人的子任务
			local is_need_delete = true
			for _task_id,data in pairs(DATA.task_list) do
				local is_break = false
				if data.children_task_ids and type(data.children_task_ids) == "table" then
					for _key,c_task_id in pairs(data.children_task_ids) do
						if c_task_id == task_id then

							is_need_delete = false
							is_break = true
							break
						end
					end
				end
				if is_break then
					break
				end
			end

			if is_need_delete then
				PUBLIC.delete_one_task( task_id )
			end
		end
	end

	-- dump(task_table_temp , "----->>>>>add_or_delete_task , task_table_temp")
	--- 做新增
	for new_task_id,_ in pairs(task_table_temp) do

		local data = {
				process = 0,
				task_round = 1,
				create_time = os.time(),
				task_award_get_status = 0,
			}

		PUBLIC.add_one_task(new_task_id,data)

		PUBLIC.update_task(new_task_id,data.process,data.task_round,data.create_time , data.task_award_get_status)
		
	end

end


function PROTECT.init()
	print("------------ task mgr init -----------------------")

	--###test
	if DATA.service_config.vip_center_service then
		--- 重置时间和vip中心保存一致
		DATA.REST_TIME = skynet.call(DATA.service_config.vip_center_service,"lua","get_rest_time") or DATA.REST_TIME
	end

	--从数据库获取任务进度，初始化任务对象列表
	load_ob_data()

	PROTECT.distribute_task()


	--- 触发一下，资产观察,方便登录领取任务奖励
	skynet.timeout(200 , function() 
		PUBLIC.asset_observe()
	end)
	
end


---- 更新一个任务
function PUBLIC.update_task(_task_id,_process,_task_round,_create_time , _task_award_get_status)
	if _task_id == 201 then
		print("xxxxxxxxxxxxx------------update_data2:",201)
	end

	skynet.send(DATA.service_config.task_center_service,"lua","add_or_update_task_data"
					,DATA.my_id
					,_task_id
					,_process
					,_task_round
					,_create_time
					,_task_award_get_status)
end

---- 增加日志
function PUBLIC.add_player_task_log(_task_id,_process_change,_now_progress)
	skynet.send(DATA.service_config.task_center_service,"lua","add_player_task_log"
					,DATA.my_id
					,_task_id
					,_process_change
					,_now_progress)

end

---
function PUBLIC.add_player_task_award_log(_task_id ,_award_progress_lv,_asset_type , _asset_value)
	print("xxxxxxxx---------add_player_task_award_log:",_task_id ,_award_progress_lv,_asset_type , _asset_value)
	skynet.send(DATA.service_config.task_center_service,"lua","add_player_task_award_log"
					,DATA.my_id
					,_task_id
					,_award_progress_lv
					,_asset_type
					,_asset_value )

end

---- 通知客户端一个任务进度改变
function PUBLIC.task_process_change( task_id )
	if DATA.task_list[task_id] then
		PUBLIC.request_client("task_change_msg",
								{ task_item = PROTECT.get_one_task_data( DATA.task_list[task_id] , {} ) })
	end
end



---- 通知客户端一个 金猪 任务进度改变
function PUBLIC.goldpig_task_process_change( task_id )
	if DATA.task_list[task_id] then
		PUBLIC.request_client("goldpig_task_change_msg",
								{ task_item = PROTECT.get_one_task_data(DATA.task_list[task_id] , {} ) })
	end
end

-------- 领取奖励的额外处理
function PUBLIC.get_award_extra_deal(task_id)
	local task_obj = DATA.task_list[task_id]
	if task_obj then
		if task_obj.config.own_type == "qys_zhouka" then
			---- 如果今天没有千元赛 or 今天的时间不在 20:55之前 就不能领
			local now_time_data = os.date("*t")
			if now_time_data.hour > 20 or (now_time_data.hour == 20 and now_time_data.min > 55) then
				return 3809
			end
			local next_get_day = PUBLIC.get_qys_next_start_day()
			if next_get_day > 0 then
				return 3809
			end
		end
	end

	return 0
end


function PUBLIC.get_task_award(task_id , award_progress_lv)
	local task_obj = DATA.task_list[task_id]

	----- 处理一下额外的情况，领取限制之内的
	local extra_deal_code = PUBLIC.get_award_extra_deal(task_id)

	if extra_deal_code ~= 0 then
		return extra_deal_code , {}
	end

	local task_award = nil
	if task_obj then
		task_award = task_obj.get_award(award_progress_lv)
	end

	local result_code = 0

	if task_award then
		if type(task_award) == "table" and next(task_award) then
			local change_type = PUBLIC.get_task_award_change_type(task_obj)

			CMD.change_asset_multi(task_award, change_type ,task_id)
		end

		if type(task_award) == "number" then
			result_code = task_award
		end
	else
		
	end

	return result_code , type(task_award) == "table" and task_award or {}
end


function REQUEST.get_task_award(self)
	-- dump(self , "---------- get_task_award")
	if not self or not self.id or type(self.id)~="number" then
		return {
			result = 1001,
		}
	end

	if PUBLIC.get_action_lock("get_task_award" ) then
		return 1008
	end
	PUBLIC.on_action_lock("get_task_award" )

	local result_code = PUBLIC.get_task_award(self.id)

	PUBLIC.off_action_lock("get_task_award")
	return {
		result = result_code,
		id = self.id,
	}

end

---------------------------------------------------------------------------------------------- 新版获取任务奖励
function REQUEST.get_task_award_new(self)
	-- dump(self , "---------- get_task_award")
	if not self or not self.id or type(self.id)~="number" or not self.award_progress_lv or type(self.award_progress_lv)~="number" then
		return {
			result = 1001,
		}
	end

	if PUBLIC.get_action_lock("get_task_award_new" ) then
		return 1008
	end
	PUBLIC.on_action_lock("get_task_award_new" )

	local result_code , task_award = PUBLIC.get_task_award(self.id , self.award_progress_lv)

	local award_data = {}
	if task_award and type(task_award) == "table" then
		for key , data in pairs(task_award) do
			award_data[#award_data + 1] = { asset_type = data.asset_type , asset_value = data.value }
		end
	end
	
	PUBLIC.off_action_lock("get_task_award_new")
	return {
		result = result_code,
		id = self.id,
		award_list = award_data,
	}

end

----- 获取一个任务的数据
function PROTECT.get_one_task_data(task_obj , target_value)
	target_value.id = task_obj.id
	target_value.now_total_process = task_obj.process
	target_value.now_lv = task_obj.lv
	target_value.now_process = task_obj.get_now_process()
	target_value.need_process = task_obj.get_need_process()
	target_value.task_round = task_obj.task_round
	target_value.award_status = task_obj.get_award_status()
	target_value.award_get_status = task_obj.task_award_get_status or 0

	return target_value
end


--- 请求所有任务数据
function REQUEST.query_task_data()
	local ret = {}

	for task_id ,task_obj in pairs(DATA.task_list) do
		if task_obj.config.own_type == "normal" then
			local last_index = #ret + 1
			ret[last_index] = {}
			PROTECT.get_one_task_data(task_obj , ret[last_index])
		end
	end
	
	return {
		result = 0,
		vip_duiju_task_ui_id = PUBLIC.get_vip_duiju_hongbao_task_client_ui_id and PUBLIC.get_vip_duiju_hongbao_task_client_ui_id() or 1,
		task_list = ret,
	}

end

--- 请求所有任务数据
function REQUEST.query_one_task_data(self)
	if not self or not self.task_id then
		return { result = 1001 }
	end

	local _task_data = nil

	for task_id ,task_obj in pairs(DATA.task_list) do
		if task_id == self.task_id then
			_task_data = {}

			PROTECT.get_one_task_data(task_obj , _task_data)

			break
		end
	end
	
	return {
		result = 0,
		task_data = _task_data,
	}

end

----- 请求一个任务当前的子任务id
function REQUEST.query_fish_daily_children_tasks(self)
	if not self or not self.fish_game_id or type(self.fish_game_id) ~= "number" or self.fish_game_id < 1 or self.fish_game_id > 4 then
		return { result = 1001 }
	end

	local children_task_ids = {}

	local fish_daily_task_map = {57,58,59,60}

	local target_task_id = fish_daily_task_map[self.fish_game_id]

	for task_id ,task_obj in pairs(DATA.task_list) do
		if task_id == target_task_id then
			children_task_ids = task_obj.children_task_ids or {}
			break
		end
	end
	dump(children_task_ids , "xxxx----------------------children_task_ids:")
	local children_tasks = {}
	for key,task_id in pairs(children_task_ids) do
		for _task_id ,task_obj in pairs(DATA.task_list) do
			if _task_id == task_id then
				_task_data = {}

				PROTECT.get_one_task_data(task_obj , _task_data)

				children_tasks[#children_tasks + 1] = _task_data

			end
		end
	end


	return {
		result = 0,
		children_tasks = children_tasks
	}

end

function PUBLIC.children_task_id_change(obj)

	local children_tasks = {}
	if obj.children_task_ids and type(obj.children_task_ids) == "table" then
		for key,task_id in pairs(obj.children_task_ids) do
			for _task_id ,task_obj in pairs(DATA.task_list) do
				if _task_id == task_id then
					_task_data = {}

					PROTECT.get_one_task_data(task_obj , _task_data)

					children_tasks[#children_tasks + 1] = _task_data

				end
			end
		end
	end

	PUBLIC.request_client("fish_daily_children_tasks_change_msg",
								{
									task_id = obj.id , 
									children_tasks = children_tasks or {}
								})

end

return PROTECT