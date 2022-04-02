----- 步步生财 管理器

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local task_initer = require "task.init"
local task_base_func = require "task.task_base_func"

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST
local PUBLIC = base.PUBLIC

DATA.stepstep_money_mgr_protect = {}
local PROTECT = DATA.stepstep_money_mgr_protect

PROTECT.player_stepstep_money_data = {}
---- 每一步的任务的列表，key 为 step id , value = { [little_step] = { [1] ={ task_id = xxx ... }
PROTECT.step_task_list = {}

---- 运行中的任务列表, key 为 big_step_id , value = {}
PROTECT.gaming_step_task_list = {}

---- 任务列表
PROTECT.task_list = {}

--- 消息处理
PROTECT.msg = {}

---- 步步生财总共可以获取的红包劵数量
DATA.total_step_hongbao_num = 0
---- 步步生财当前已经获取的红包劵数量
DATA.now_step_get_hongbao_num = 0

---- 步步生财过期天数
DATA.stepstep_money_over_day_num = 15


local function load_config()
	local config = skynet.call(DATA.service_config.task_center_service,"lua","get_stepstep_money_config")

	local task_config = skynet.call(DATA.service_config.task_center_service,"lua","get_main_config")

	local target_task_vec = config.task

	if PROTECT.player_stepstep_money_data.bbsc_version == "new" then
		target_task_vec = config.task_new
	end

	for key , data in pairs(target_task_vec) do
		PROTECT.step_task_list[data.big_step_id] = PROTECT.step_task_list[data.big_step_id] or {}
		PROTECT.step_task_list[data.big_step_id][data.little_step_id] = PROTECT.step_task_list[data.big_step_id][data.little_step_id] or {}
		local next_index = #PROTECT.step_task_list[data.big_step_id][data.little_step_id] + 1
		PROTECT.step_task_list[data.big_step_id][data.little_step_id][next_index] = { task_id = data.task_id }

		---- 收集总共的红包劵数量
		if next_index==1 and task_config[data.task_id] then
			local m_task_cfg = task_config[data.task_id]
			local award_data = nil
			if m_task_cfg.award_data[1] then
				award_data = m_task_cfg.award_data[1]
			end
			if award_data then
				--- 找到对局红包卷奖励
				-- dump(award_data , string.format("----------------- award_data, task_id %d" , data.task_id ))
				for key,data in pairs(award_data) do
					if data.asset_type == PLAYER_ASSET_TYPES.SHOP_GOLD_SUM then
						DATA.total_step_hongbao_num = DATA.total_step_hongbao_num + data.value
					end
				end
			end

		end

	end

end

--- 新增or更新
local function add_or_update_data( data )

	skynet.send(DATA.service_config.data_service,"lua","update_player_stepstep_money" 
		, data.player_id 
		, data.now_big_step
		, data.now_little_step
		, data.last_op_time
		, data.can_do_big_step 
		, data.bbsc_version
		, data.over_time
		)

end

local function load_ob_data()
	PROTECT.player_stepstep_money_data = skynet.call(DATA.service_config.data_service,"lua","query_player_stepstep_money" , DATA.my_id )

	--- 没有要新增
	if not PROTECT.player_stepstep_money_data then
		PROTECT.player_stepstep_money_data = {}
		PROTECT.player_stepstep_money_data.player_id = DATA.my_id
		PROTECT.player_stepstep_money_data.now_big_step = 1
		PROTECT.player_stepstep_money_data.now_little_step = 1
		PROTECT.player_stepstep_money_data.last_op_time = os.time()
		PROTECT.player_stepstep_money_data.can_do_big_step = 1

		PROTECT.player_stepstep_money_data.bbsc_version = "new"
		PROTECT.player_stepstep_money_data.over_time = os.time() + DATA.stepstep_money_over_day_num * 86400

		add_or_update_data( PROTECT.player_stepstep_money_data )
	end

	if not PROTECT.player_stepstep_money_data.over_time then
		PROTECT.player_stepstep_money_data.over_time = os.time() + DATA.stepstep_money_over_day_num * 86400
		add_or_update_data( PROTECT.player_stepstep_money_data )
	end

end

local function create_task_obj( config , ob_data )
	
	if not config or not ob_data then
		error("not task config!")
	end

	local task_obj = task_initer.gen_task_obj(config,ob_data)

	if task_obj then
		print("add_one_task:",task_obj.id,task_obj)
		task_obj.init()
	else
		dump(config , "error create_task_obj ------------- config:")
		dump(ob_data , "error create_task_obj ------------- ob_data:")
		error( "error create_task_obj" )
	end

	return task_obj
end

----- 删掉一个大步骤的任务对象
local function delete_big_step_task_obj(big_step)

	if PROTECT.gaming_step_task_list[big_step] then
			

		local big_step_list = PROTECT.gaming_step_task_list[big_step]

		for little_step_id , little_step_data in pairs(big_step_list) do
			for key,task_obj in ipairs(little_step_data) do

				if task_obj then 
					task_obj.destory()
				
					if PROTECT.task_list[task_obj.id] then
						PROTECT.task_list[task_obj.id] = nil
					end
				end
			end
		end

		PROTECT.gaming_step_task_list[big_step] = {}
	end
end

local function create_big_step_task(big_step)
	local now_big_step = PROTECT.player_stepstep_money_data.now_big_step
	local now_little_step = PROTECT.player_stepstep_money_data.now_little_step

	if PROTECT.gaming_step_task_list[big_step] then
		if PROTECT.gaming_step_task_list[big_step][now_little_step] then
			--- 把这个小步骤的都开启
			local little_step_data = PROTECT.gaming_step_task_list[big_step][now_little_step]
		
			for key,task_obj in pairs(little_step_data) do
				task_obj.set_is_open(true)
			end
		end
		

		return true
	end

	if PROTECT.step_task_list[big_step] then
		local task_config = skynet.call(DATA.service_config.task_center_service,"lua","get_main_config")
	
		local history_task = skynet.call(DATA.service_config.task_center_service,"lua","query_player_task_data",DATA.my_id)
		history_task = history_task or {}

		--dump( history_task , "----------------->>>>>>>>>><<<<< --- history_task" )

		local big_step_list = PROTECT.step_task_list[big_step]
		PROTECT.gaming_step_task_list[big_step] = PROTECT.gaming_step_task_list[big_step] or {}
		for little_step_id , little_step_data in pairs(big_step_list) do

			for key,task_data in ipairs(little_step_data) do
				local config = task_config[task_data.task_id]
				local ob_data = history_task[task_data.task_id]

				if not config then
					error( string.format("no config for stepstep_money_task , task_id = %d" , task_data.task_id ) )
					return
				end

				if not ob_data then
					ob_data = {
						process = 0,
						task_round = 1,
						create_time = os.time(),
						task_award_get_status = 0,
					}
					PUBLIC.update_task(task_data.task_id,ob_data.process,ob_data.task_round,ob_data.create_time,ob_data.task_award_get_status )
				end

				PROTECT.gaming_step_task_list[big_step][little_step_id] = PROTECT.gaming_step_task_list[big_step][little_step_id] or {}
				local next_index = #PROTECT.gaming_step_task_list[big_step][little_step_id] + 1
				local task_obj = create_task_obj( config , ob_data )

				PROTECT.gaming_step_task_list[big_step][little_step_id][next_index] = task_obj

				PROTECT.task_list[task_obj.id] = task_obj

				---- 大于当前小步骤的不启用
				if now_big_step < big_step or (now_big_step == big_step and now_little_step < little_step_id) then
					task_obj.set_is_open(false)
				end

				--- 已经过去的不接受消息。
				if now_big_step > big_step or (now_big_step == big_step and now_little_step > little_step_id) then
					task_obj.not_accept_msg()
				end

				--- 如果是当前步骤，又有任一任务可领取。那么就不能接受消息
				if (now_big_step == big_step and now_little_step == little_step_id) then
					local is_complete_one_task = false
					for key,task_obj in pairs(PROTECT.gaming_step_task_list[now_big_step][now_little_step]) do
						if task_obj.get_award_status() == DATA.award_status.can_get then
							is_complete_one_task = true
							break
						end
					end
					if is_complete_one_task then
						for key,task_obj in pairs(PROTECT.gaming_step_task_list[now_big_step][now_little_step]) do
							task_obj.not_accept_msg()
						end
					end
				end

				---- 搜集已经领取的红包卷数量
				if key == 1 and (now_big_step > big_step or (now_big_step == big_step and now_little_step > little_step_id)) then
					if task_config[task_data.task_id] then
						local m_task_cfg = task_config[task_data.task_id]
						local award_data = nil
						if m_task_cfg.award_data[1] then
							award_data = m_task_cfg.award_data[1]
						end
						if award_data then
							--- 找到对局红包卷奖励
							for key,data in pairs(award_data) do
								if data.asset_type == PLAYER_ASSET_TYPES.SHOP_GOLD_SUM then
									DATA.now_step_get_hongbao_num = DATA.now_step_get_hongbao_num + data.value
								end
							end
						end

					end
				end

			end

		end
	else
		return false
	end
	return true
end

function PROTECT.deal_complete_big_step()
	local now_time = os.time()
	local player_data = PROTECT.player_stepstep_money_data
	local old_little_step = player_data.now_little_step
	--- 当前小步骤已经大于了这个大步骤的最大的步骤了
	if player_data.now_little_step > #PROTECT.step_task_list[player_data.now_big_step] then
		if player_data.can_do_big_step == player_data.now_big_step then
			---- 如果只能到达同一个大步骤,延迟处理
			---是否是同一天
			local is_same_day = basefunc.is_same_day( now_time , player_data.last_op_time , DATA.REST_TIME)

			if is_same_day then
				skynet.timeout(  basefunc.get_diff_target_time( DATA.REST_TIME ) * 100 , function() 
					--delete_big_step_task_obj(player_data.now_big_step)
					player_data.can_do_big_step = player_data.can_do_big_step + 1
					player_data.now_big_step = player_data.now_big_step + 1
					player_data.now_little_step = 1
					local is_suc = create_big_step_task(player_data.now_big_step)
					if not is_suc then
						player_data.now_big_step = player_data.now_big_step - 1
						player_data.can_do_big_step = player_data.now_big_step
						player_data.now_little_step = old_little_step
					else
						PROTECT.stepstep_task_big_step_open( player_data.now_big_step )
						create_big_step_task(player_data.now_big_step + 1)
						skynet.send(DATA.service_config.sczd_center_service,"lua","bbsc_big_step_change_msg" , DATA.my_id , player_data.now_big_step)
					end

					add_or_update_data( PROTECT.player_stepstep_money_data )
				end )
			else
				--- 不是同一天，那么就直接创下一天的。
				player_data.can_do_big_step = player_data.can_do_big_step + 1
				player_data.now_big_step = player_data.now_big_step + 1
				player_data.now_little_step = 1
				local is_suc = create_big_step_task(player_data.now_big_step)
				if not is_suc then
					player_data.now_big_step = player_data.now_big_step - 1
					player_data.can_do_big_step = player_data.now_big_step
					player_data.now_little_step = old_little_step
				else
					PROTECT.stepstep_task_big_step_open( player_data.now_big_step )
					create_big_step_task(player_data.now_big_step + 1)
					skynet.send(DATA.service_config.sczd_center_service,"lua","bbsc_big_step_change_msg" , DATA.my_id , player_data.now_big_step)
				end
			end


		elseif player_data.can_do_big_step > player_data.now_big_step then
			--delete_big_step_task_obj(player_data.now_big_step)

			player_data.now_big_step = player_data.now_big_step + 1
			player_data.now_little_step = 1
			local is_suc = create_big_step_task(player_data.now_big_step)
			if not is_suc then
				player_data.now_big_step = player_data.now_big_step - 1
				player_data.can_do_big_step = player_data.now_big_step
				player_data.now_little_step = old_little_step
			else
				PROTECT.stepstep_task_big_step_open( player_data.now_big_step )
				create_big_step_task(player_data.now_big_step + 1)
				skynet.send(DATA.service_config.sczd_center_service,"lua","bbsc_big_step_change_msg" , DATA.my_id , player_data.now_big_step)
			end
		end
	else
		--- 开启这个小步骤的所有任务
		local now_big_step = player_data.now_big_step
		local now_little_step = player_data.now_little_step
		for key,task_obj in pairs(PROTECT.gaming_step_task_list[now_big_step][now_little_step]) do
			if not task_obj.get_is_open() then
				task_obj.set_is_open(true)

				PUBLIC.step_task_process_change( task_obj.id )
			end
		end

		---- 如果有任一任务可领取。那么就不能接受消息
		local is_complete_one_task = false
		for key,task_obj in pairs(PROTECT.gaming_step_task_list[now_big_step][now_little_step]) do
			if task_obj.get_award_status() == DATA.award_status.can_get then
				is_complete_one_task = true
				break
			end
		end
		if is_complete_one_task then
			for key,task_obj in pairs(PROTECT.gaming_step_task_list[now_big_step][now_little_step]) do
				task_obj.not_accept_msg()
			end
		end
		

	end
end

----- 创建运行中的任务
local function create_gaming_step_task()
	--- 把已完成到下一个大步骤的所有任务创建出来
	local now_big_step = PROTECT.player_stepstep_money_data.now_big_step
	for big_step = 1,now_big_step + 1 do
	--for big_step = 1,#PROTECT.step_task_list do
		create_big_step_task(big_step)
	end

	PROTECT.deal_complete_big_step()

	add_or_update_data( PROTECT.player_stepstep_money_data )

	---- 获得第一个大步骤的所有状态
	DATA.player_data.step_task_status = {}
	if now_big_step > 1 then
		for little_step,little_step_data in pairs(PROTECT.gaming_step_task_list[1]) do
			DATA.player_data.step_task_status[little_step] = DATA.award_status.complete
		end
	else
		for little_step,little_step_data in pairs(PROTECT.gaming_step_task_list[1]) do
			local task_status = little_step_data[1].get_award_status()

			local is_status_can_get = false
			local is_status_complete = false
			for key,task_obj in ipairs(little_step_data) do
				local status = task_obj.get_award_status()
				if status == DATA.award_status.can_get then
					is_status_can_get = true
					break
				end
				if status == DATA.award_status.complete then
					is_status_complete = true
					break
				end
			end
			if is_status_can_get then
				task_status = DATA.award_status.can_get
			end
			if is_status_complete then
				task_status = DATA.award_status.complete
			end

			DATA.player_data.step_task_status[little_step] = task_status
		end
		--print("----------player_id:",DATA.my_id)
		--dump( DATA.player_data.step_task_status , "---------------- DATA.player_data.step_task_status , " )
	end

end

----- 
--- 获取一个大步骤的所有的任务


---监听任务完成,其他的同小步骤的任务不能完成
PROTECT.msg.stepstep_money_task_complete = function()
	local now_big_step = PROTECT.player_stepstep_money_data.now_big_step
	local now_little_step = PROTECT.player_stepstep_money_data.now_little_step
	for key,task_obj in pairs(PROTECT.gaming_step_task_list[now_big_step][now_little_step]) do
		print( "------------stepstep_money_task_complete , not_accept_msg," , task_obj.id)
		task_obj.not_accept_msg()
		if now_big_step == 1 then
			DATA.player_data.step_task_status[now_little_step] = DATA.award_status.can_get
		end
	end

end


--- 领取了任务奖励之后
PROTECT.msg.stepstep_money_task_get_task = function(_ , task_id)
	if PUBLIC.get_action_lock("msg_stepstep_money_task_get_task" ) then
		return 1008
	end
	PUBLIC.on_action_lock("msg_stepstep_money_task_get_task" )

	local now_big_step = PROTECT.player_stepstep_money_data.now_big_step
	local now_little_step = PROTECT.player_stepstep_money_data.now_little_step

	local now_time = os.time()
	--- 如果完成的不是第一个小步骤 & 不是同一天完成
	if PROTECT.player_stepstep_money_data.now_little_step ~= 1 and 
		not basefunc.is_same_day( now_time , PROTECT.player_stepstep_money_data.last_op_time , DATA.REST_TIME) then
		PROTECT.player_stepstep_money_data.can_do_big_step = PROTECT.player_stepstep_money_data.now_big_step + 1

	end

	if now_big_step == 1 then
		DATA.player_data.step_task_status[now_little_step] = DATA.award_status.complete
	end

	---- 领奖的这个小步骤的其他步骤不可领奖
	for key,task_obj in pairs(PROTECT.gaming_step_task_list[now_big_step][now_little_step]) do
		if task_obj.id ~= task_id then
			task_obj.set_is_open(false)

			PUBLIC.step_task_process_change( task_obj.id )
			break
		end
	end


	PROTECT.player_stepstep_money_data.now_little_step = PROTECT.player_stepstep_money_data.now_little_step + 1
	PROTECT.player_stepstep_money_data.last_op_time = now_time

	--- 如果完成了这个大步骤
	if PROTECT.player_stepstep_money_data.now_little_step > #PROTECT.step_task_list[now_big_step] then
		skynet.send(DATA.service_config.sczd_center_service,"lua","bbsc_progress_msg" , DATA.my_id , now_big_step)

		--DATA.msg_dispatcher:call("bbsc_big_step_complete" )
		PUBLIC.trigger_msg( {name = "bbsc_big_step_complete"} )
	end

	if now_big_step == 1 and DATA.player_data.step_task_status[PROTECT.player_stepstep_money_data.now_little_step] then
		DATA.player_data.step_task_status[PROTECT.player_stepstep_money_data.now_little_step] = DATA.award_status.not_can_get 
	end

	PROTECT.deal_complete_big_step()



	add_or_update_data( PROTECT.player_stepstep_money_data )

	PUBLIC.off_action_lock("msg_stepstep_money_task_get_task" )
end

------ 场次完成
PROTECT.msg.game_compolete_task = function(_, game_module , game_id , game_type , game_level , real_change_score , match_model , rank)
	print("-------------------step_step_money , game_compolete_task,",DATA.my_id , game_module , game_type , game_level , real_change_score , match_model , rank)


	---- 这里处理预完成的类型
	local player_data = PROTECT.player_stepstep_money_data

	local now_big_step = player_data.now_big_step
	local now_little_step = player_data.now_little_step

	----- 过期了，任务不加
	if player_data.over_time then
		local now_time = os.time()
		if now_time > player_data.over_time then
			return
		end
	end

	local config = skynet.call(DATA.service_config.task_center_service,"lua","get_stepstep_money_config")

	local task_config = skynet.call(DATA.service_config.task_center_service,"lua","get_main_config")

	local target_task_vec = config.task
	if player_data.bbsc_version == "new" then
		target_task_vec = config.task_new
	end

	--dump(config , "--------------config")
	--dump(task_config , "---------------task_config")

	for key,data in pairs(target_task_vec) do
		--- 未到这一步，依旧可以加进度。在这一步可以加，过去了就不能加了
		if data.big_step_id > now_big_step or (data.big_step_id == now_big_step and data.little_step_id >= now_little_step) then
			local task_id = data.task_id
			local task_config = task_config[task_id]

			if task_config.condition_type == "pre_progress_duiju" then
				local c_data = task_config.condition_data

				print("-------------------step_step_money , game_compolete_task_1")
				if (not c_data.game_module or basefunc.compare_value( game_module , c_data.game_module.condition_value , c_data.game_module.judge_type ) )
					and (not c_data.game_id or basefunc.compare_value( game_id , c_data.game_id.condition_value , c_data.game_id.judge_type ) )
					and (not c_data.game_type or basefunc.compare_value( game_type , c_data.game_type.condition_value , c_data.game_type.judge_type ) )
						and (not c_data.game_level or basefunc.compare_value( game_level , c_data.game_level.condition_value , c_data.game_level.judge_type ) )
							and (not c_data.match_model or basefunc.compare_value( match_model , c_data.match_model.condition_value , c_data.match_model.judge_type ) )
							 	and (not c_data.rank or basefunc.compare_value( rank , c_data.rank.condition_value , c_data.rank.judge_type ) ) then

					local is_attain_condition = true
					print("-------------------step_step_money , game_compolete_task_2")
					if c_data.game_success then
						if (real_change_score > 0 and c_data.game_success.condition_value == 1) or (real_change_score < 0 and c_data.game_success.condition_value == 0) then

						else
							is_attain_condition = false
						end
					end

					if is_attain_condition then
						print("-------------------step_step_money , game_compolete_task_3")
						--- 加进度
						local task_ob_data = skynet.call(DATA.service_config.task_center_service,"lua","query_player_task_data" , DATA.my_id )
						if task_ob_data then
							task_ob_data = task_ob_data[task_id]

							task_ob_data = task_ob_data or {
								player_id = DATA.my_id,
								task_id = task_id,
								process = 0,
								task_round = 1,
								create_time = os.time(),
								task_award_get_status = 0,
							}

							local max_process = task_base_func.get_max_process(task_config.process_data)

							if task_ob_data.process < max_process then
								task_ob_data.process = task_ob_data.process + 1

								--- 加日志
								--PUBLIC.add_player_task_log(task_ob_data.task_id , 1 , task_ob_data.process)
								skynet.send(DATA.service_config.task_center_service,"lua","add_player_task_log"
										,task_ob_data.player_id
										,task_ob_data.task_id
										, 1
										,task_ob_data.process)

								skynet.send(DATA.service_config.task_center_service,"lua","add_or_update_task_data"
									,task_ob_data.player_id
									,task_ob_data.task_id
									,task_ob_data.process
									,task_ob_data.task_round
									,task_ob_data.create_time
									,task_ob_data.task_award_get_status )


								---- 通知，进度增加
								--nodefunc.send(DATA.my_id,"update_step_task_process", task_id , task_ob_data.process , task_ob_data.process == max_process )
								CMD.update_step_task_process( task_id , task_ob_data.process , task_ob_data.process == max_process )

							end

						end

					end

				end
			end
		end
	end
end


function REQUEST.query_stepstep_money_data()
	local _data = {}
	_data.result = 0
	_data.now_big_step = PROTECT.player_stepstep_money_data.now_big_step
	_data.total_hongbao_num = DATA.total_step_hongbao_num
	_data.now_get_hongbao_num = DATA.now_step_get_hongbao_num
	_data.step_tasks = {}

	_data.over_time = PROTECT.player_stepstep_money_data.over_time
	_data.version = PROTECT.player_stepstep_money_data.bbsc_version

	--[[if not _data.now_big_step or not PROTECT.gaming_step_task_list[PROTECT.player_stepstep_money_data.now_big_step] then
		_data.result = 1004
		return _data
	end--]]

	if _data.now_big_step and PROTECT.gaming_step_task_list[PROTECT.player_stepstep_money_data.now_big_step] then
		for little_step_id , little_step_data in pairs(PROTECT.gaming_step_task_list[PROTECT.player_stepstep_money_data.now_big_step]) do
			for key,task_obj in ipairs(little_step_data) do
				if task_obj then 
					local task_list ={}
					task_list.id = task_obj.id
					task_list.now_total_process = task_obj.process
					task_list.now_lv = task_obj.lv
					task_list.now_process = task_obj.get_now_process()
					task_list.need_process = task_obj.get_need_process()
					task_list.task_round = task_obj.task_round
					task_list.award_status = task_obj.get_award_status()
					task_list.award_get_status = task_obj.task_award_get_status or 0

					_data.step_tasks[#_data.step_tasks + 1] = task_list
				end
			end
		end
	end

	return _data
end

function REQUEST.query_stepstep_money_big_step_data(self)
	local _data = {}
	_data.result = 0
	_data.step_tasks = {}

	local now_big_step = PROTECT.player_stepstep_money_data.now_big_step
	local now_little_step = PROTECT.player_stepstep_money_data.now_little_step

	if not self or type(self.big_step) ~= "number" or not PROTECT.gaming_step_task_list[self.big_step] then
		_data.result = 1001
		return _data
	end
	
	local big_step_data = PROTECT.gaming_step_task_list[self.big_step]

	for little_step_id,little_step_data in pairs(big_step_data) do
		for key,task_obj in ipairs(little_step_data) do
			if task_obj then 
				local task_list ={}
				task_list.id = task_obj.id
				task_list.now_total_process = task_obj.process
				task_list.now_lv = task_obj.lv
				task_list.now_process = task_obj.get_now_process()
				task_list.need_process = task_obj.get_need_process()
				task_list.task_round = task_obj.task_round
				task_list.award_status = task_obj.get_award_status()
				task_list.award_get_status = task_obj.task_award_get_status or 0

				--- add by wss 如果 当前步骤大于 查询步骤，状态 一定是完成
				if now_big_step > self.big_step or (now_big_step == self.big_step and now_little_step > little_step_id) then
					task_list.award_status = DATA.award_status.complete
				end

				_data.step_tasks[#_data.step_tasks + 1] = task_list
			end
		end
	end
	return _data
end

function REQUEST.get_stepstep_money_task_award(self)
	-- dump(self , "---------- get_task_award")
	if not self or not self.id or type(self.id)~="number" then
		return {
			result = 1001,
		}
	end

	if PUBLIC.get_action_lock("get_stepstep_money_task_award" ) then
		return 1008
	end
	PUBLIC.on_action_lock("get_stepstep_money_task_award" )

	local task_obj = PROTECT.task_list[self.id]

	local task_award = nil
	if task_obj then
		task_award = task_obj.get_award()
	end

	if task_award then
		local result_code = 0

		if type(task_award) == "table" then
			CMD.change_asset_multi(task_award,ASSET_CHANGE_TYPE.TASK_AWARD,self.id)
		end

		if type(task_award) == "number" then
			result_code = task_award
		end

		PUBLIC.off_action_lock("get_stepstep_money_task_award" )
		return {
			result = result_code,
			id = self.id,
			now_get_hongbao_num = DATA.now_step_get_hongbao_num
		}
	end

	PUBLIC.off_action_lock("get_stepstep_money_task_award" )
	return {
		result = 3801,
	}

end

--- 刷新某个任务的进度
function CMD.update_step_task_process(task_id , now_process , is_max_progress )
	if PROTECT.task_list[task_id] then
		PROTECT.task_list[task_id].update_process(now_process)

		PUBLIC.step_task_process_change( task_id )
	end

	--- 如果这个任务 等于了当前 小步骤的任务 并且 等于他的最大进度(也就是完成了。那他的其他小步骤要停止接受消息)
	for big_step_id , big_step_list in pairs(PROTECT.step_task_list) do
		local is_break1 = false
		for little_step_id , little_step_data in pairs(big_step_list) do
			local is_break2 = false
			for key,task_data in ipairs(little_step_data) do

				local now_big_step = PROTECT.player_stepstep_money_data.now_big_step
				local now_little_step = PROTECT.player_stepstep_money_data.now_little_step

				if task_data.task_id == task_id and big_step_id == now_big_step
					and little_step_id == now_little_step and is_max_progress then
					---  处理
					
					for key,task_obj in pairs(PROTECT.gaming_step_task_list[now_big_step][now_little_step]) do
						print( "------------stepstep_money_task_complete22 , not_accept_msg," , task_obj.id)
						task_obj.not_accept_msg()
						if now_big_step == 1 then
							DATA.player_data.step_task_status[now_little_step] = DATA.award_status.can_get
						end
					end

					is_break1 = true
					is_break2 = true
					break
				end
			end

			if is_break2 then
				break
			end
		end

		if is_break1 then
			break
		end
	end

end

---- 通知客户端一个任务进度改变
function PUBLIC.step_task_process_change( task_id )
	if PROTECT.task_list[task_id] then
		PUBLIC.request_client("stepstep_money_task_change_msg",
								{ task_item = { 
												id = task_id ,  
												now_total_process = PROTECT.task_list[task_id].process,
												now_lv = PROTECT.task_list[task_id].lv,
												now_process = PROTECT.task_list[task_id].get_now_process(),
												need_process = PROTECT.task_list[task_id].get_need_process(),
												task_round = PROTECT.task_list[task_id].task_round,
												award_status = PROTECT.task_list[task_id].get_award_status(),
												award_get_status = PROTECT.task_list[task_id].task_award_get_status or 0,

								} })
	end
end

---- 增加一个任务的进度
function CMD.add_task_progress(task_id , add_value)
	if PROTECT.task_list[task_id] then
		PROTECT.task_list[task_id].add_process(add_value)
	end
	if DATA.task_list[task_id] then
		DATA.task_list[task_id].add_process(add_value)
	end
end

--- bbsc大步骤开启
function PROTECT.stepstep_task_big_step_open( big_step )

	if PROTECT.gaming_step_task_list[big_step] then
		local task_items = {}

		local big_step_data = PROTECT.gaming_step_task_list[big_step]

		for little_step_id,little_step_data in pairs(big_step_data) do
			for key,task_obj in ipairs(little_step_data) do
				if task_obj then 
					local task_list ={}
					task_list.id = task_obj.id
					task_list.now_total_process = task_obj.process
					task_list.now_lv = task_obj.lv
					task_list.now_process = task_obj.get_now_process()
					task_list.need_process = task_obj.get_need_process()
					task_list.task_round = task_obj.task_round
					task_list.award_status = task_obj.get_award_status()
					task_list.award_get_status = task_obj.task_award_get_status or 0

					task_items[#task_items + 1] = task_list
				end
			end
		end

		PUBLIC.request_client("stepstep_money_task_big_step_open",
								{
									now_big_step = big_step,
								 	step_tasks = task_items,
								 })
	end

end

---- 
function CMD.set_bbsc_can_day(day_num)
	local old_big_step = PROTECT.player_stepstep_money_data.can_do_big_step
	PROTECT.player_stepstep_money_data.can_do_big_step = day_num
	if PROTECT.player_stepstep_money_data.can_do_big_step > old_big_step then
		PROTECT.deal_complete_big_step()
	end
end

function PROTECT.deal_time_over()
	local now_big_step = PROTECT.player_stepstep_money_data.now_big_step
	local now_little_step = PROTECT.player_stepstep_money_data.now_little_step
	if PROTECT.gaming_step_task_list and PROTECT.gaming_step_task_list[now_big_step] and PROTECT.gaming_step_task_list[now_big_step][now_little_step] then
		for key,task_obj in pairs(PROTECT.gaming_step_task_list[now_big_step][now_little_step]) do
			task_obj.not_accept_msg()
		end
	end

	DATA.msg_dispatcher:unregister( PROTECT.msg )
	---- 奖励自动发邮件.....
	--发送 邮件 奖励
	local send_email = function(auto_send_award , task_id)
		local email = 
		{
			type = "bbsc_over_time_auto_get_award",
			title = "新人红包奖励",
			sender = "系统",
			data = {},
		}
		email.receiver = DATA.my_id
		email.data = 
		{
			asset_change_data = {
				change_type = ASSET_CHANGE_TYPE.TASK_AWARD,
				change_id = task_id,
			}
		}
		for i,aw in ipairs(auto_send_award) do
			--if aw.value then
				email.data[aw.asset_type] = (email.data[aw.asset_type] or 0) + aw.value
			--end
			--[[if aw.attribute then
				email.data[aw.asset_type] = {}
				email.data[aw.asset_type].attribute = aw.attribute
			end--]]

		end

		skynet.send(DATA.service_config.email_service,"lua","send_email",email)
	end

	-----------------
	local auto_send_award = {}
	local bbsc_big_step_task_id = 61
	if DATA.task_list[bbsc_big_step_task_id] then
		local should_award = DATA.task_list[bbsc_big_step_task_id].get_should_get_awards(true)
		basefunc.merge(should_award , auto_send_award)
	end
	if next(auto_send_award) then
		send_email(auto_send_award , bbsc_big_step_task_id)
	end

	auto_send_award = {}
	----- 当前步骤的未领的奖励
	local task_id = 0
	if PROTECT.gaming_step_task_list and PROTECT.gaming_step_task_list[now_big_step] and PROTECT.gaming_step_task_list[now_big_step][now_little_step] then
		for key,task_obj in pairs(PROTECT.gaming_step_task_list[now_big_step][now_little_step]) do
			local should_award = task_obj.get_should_get_awards(true)
			basefunc.merge(should_award , auto_send_award)
			task_id = task_obj.id
			break
		end
	end
	if next(auto_send_award) then
		send_email(auto_send_award , task_id)
	end
end


function PROTECT.init()
	load_ob_data()

	load_config()

	if PROTECT.player_stepstep_money_data.over_time then
		local now_time = os.time()
		if now_time < PROTECT.player_stepstep_money_data.over_time then
			create_gaming_step_task()

			DATA.msg_dispatcher:register( PROTECT.msg , PROTECT.msg )

			---- 弄一个 结束 倒计时
			local over_delay = PROTECT.player_stepstep_money_data.over_time - now_time

			PROTECT.over_time_deal_timeouter = basefunc.cancelable_timeout(over_delay*100 ,function()
				
				PROTECT.deal_time_over()

			end )

		else
			PROTECT.deal_time_over()
		end
	end

	---- test
	--DATA.msg_dispatcher:dump()
end

return PROTECT