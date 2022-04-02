----  
---- 大富豪 活动 任务

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

DATA.da_fu_hao_task_protect = {}
local task = DATA.da_fu_hao_task_protect

--- 大富豪总共的步数
task.total_step_num = 36
--- 摇多少次骰子走完
task.total_game_num = 10

--- 游戏累积赢金每多少金币加1积分
task.game_profit_trans_need = 10000
task.game_profit_trans_been = 1

--- 充值积分转换
task.charge_trans_need = 1000
task.charge_trans_been = 20


function task.gen_task_obj(config,data)
	local obj = common_task.gen_task_obj(config,data)

	---------------------------- 重写部分代码 ----------------------------------
	obj.init = function (is_refresh_cfg)
		print("xxxxx-------------------------------da_fu_hao_task_init:")
		PUBLIC.deal_msg(obj)

		obj.tag = "da_fu_hao_task"

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
			---- 获取任务数据
			local task_data = skynet.call( DATA.service_config.task_center_service , "lua" , "query_player_one_task_data" , DATA.my_id , obj.id )
			
			local is_get_other_data = false
			if task_data and task_data.other_data then
				local other_parse_data = task_base_func.parse_activity_data(task_data.other_data)
				if other_parse_data and other_parse_data.total_game_profit and other_parse_data.total_charge and 
					other_parse_data.now_pos and other_parse_data.step_process then

					---- 总共的游戏累积赢金
					obj.total_game_profit = other_parse_data.total_game_profit
					---- 总共的充值
					obj.total_charge = other_parse_data.total_charge
					----当前所在的大富豪位置
					obj.now_pos = other_parse_data.now_pos
					---- 大富豪每一步的过程
					obj.step_process = other_parse_data.step_process

					is_get_other_data = true
				end
			end

			----- 初始化other_data
			if not is_get_other_data then
				---- 总共的游戏累积赢金
				obj.total_game_profit = 0
				---- 总共的充值
				obj.total_charge = 0
				----当前所在的大富豪位置
				obj.now_pos = 0
				---- 大富豪每一步的过程
				obj.step_process = obj.create_step_process()

				obj.update_other_data()
			end

		end
	end
	
	obj.update_other_data = function()
		PUBLIC.update_task_other_data( obj.id , { total_game_profit = obj.total_game_profit , total_charge = obj.total_charge , now_pos = obj.now_pos , 
												 	step_process = obj.step_process } )
	end

	---- 创建摇骰子过程
	obj.create_step_process = function()
		local step_process = {}
		local total_step = 0
		for i=1,task.total_game_num do
			local random = math.random(6)
			step_process[#step_process + 1] = random
			total_step = total_step + random
		end

		--- 最终再调整
		local step_dif = task.total_step_num - total_step

		local add_factor = step_dif > 0 and 1 or -1
		for i=1, math.abs(step_dif) do

			local rand_start_index = math.random(#step_process)

			for key=1,#step_process do
				local index = (rand_start_index + key - 2) % #step_process + 1
				if add_factor == 1 then
					if step_process[index] < 6 then
						step_process[index] = step_process[index] + 1
						break
					end
				elseif add_factor == -1 then
					if step_process[index] > 2 then
						step_process[index] = step_process[index] - 1
						break
					end
				end
			end
		end

		total_step = 0
		for key,value in ipairs(step_process) do
			total_step = total_step + value
		end
		assert(total_step == task.total_step_num , "total_step must = task.total_step_num")
		return step_process
	end

	---- 增加游戏累积赢金
	obj.add_game_profit = function()
		obj.total_game_profit = obj.total_game_profit + real_change_score
		if obj.total_game_profit > task.game_profit_trans_need then
			obj.total_game_profit = obj.total_game_profit - task.game_profit_trans_need
			obj.add_process(task.game_profit_trans_been)
		end
	end


	----- 监听所有的游戏奖励
	obj.all_game_award_and_charge = function()
		
		--- 自由场奖励
		obj.msg.game_compolete_task = function(_, game_module , game_type , game_level , real_change_score , match_model , rank)
			if real_change_score and real_change_score > 0 then

				obj.total_game_profit = obj.total_game_profit + real_change_score
				if obj.total_game_profit > task.game_profit_trans_need then
					obj.total_game_profit = obj.total_game_profit - task.game_profit_trans_need
					obj.add_process(task.game_profit_trans_been)
				end

			end
					
		end
		--- 砸金蛋奖励
		obj.msg.zajindan_award = function(_, award_value )
			obj.total_game_profit = obj.total_game_profit + award_value
			if obj.total_game_profit > task.game_profit_trans_need then
				obj.total_game_profit = obj.total_game_profit - task.game_profit_trans_need
				obj.add_process(task.game_profit_trans_been)
			end
		end

		--- 捕鱼奖励
		obj.msg.buyu_award = function(_, award_value )
			obj.total_game_profit = obj.total_game_profit + award_value
			if obj.total_game_profit > task.game_profit_trans_need then
				obj.total_game_profit = obj.total_game_profit - task.game_profit_trans_need
				obj.add_process(task.game_profit_trans_been)
			end
		end

		--- 消消乐 奖励
		obj.msg.xiaoxiaole_award = function(_, award_value )
			obj.total_game_profit = obj.total_game_profit + award_value
			if obj.total_game_profit > task.game_profit_trans_need then
				obj.total_game_profit = obj.total_game_profit - task.game_profit_trans_need
				obj.add_process(task.game_profit_trans_been)
			end
		end

		--- 充值

	end




	return obj
end


return task