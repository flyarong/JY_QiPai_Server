local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local skynet = require "skynet_plus"
require "normal_enum"
require "printfunc"
local task_base_func = require "task.task_base_func"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECT = {}

function PUBLIC.add_one_task_progress( player_id , task_id , add_pro )
	local task_config = skynet.call(DATA.service_config.task_center_service,"lua","get_main_config")
	--- 加进度
	local task_ob_data = skynet.call(DATA.service_config.task_center_service,"lua","query_player_task_data" , player_id )
	if task_ob_data then
		task_ob_data = task_ob_data[task_id]
		local task_config = task_config[task_id]

		task_ob_data = task_ob_data or {
			player_id = player_id,
			task_id = task_id,
			process = 0,
			task_round = 1,
			create_time = os.time(),
			task_award_get_status = 0,
		}

		local max_process = task_base_func.get_max_process(task_config.process_data)

		if task_ob_data.process < max_process then
			task_ob_data.process = task_ob_data.process + add_pro
			if task_ob_data.process > max_process then
				task_ob_data.process = max_process
			end

			--- 加日志
			--PUBLIC.add_player_task_log(task_ob_data.task_id , 1 , task_ob_data.process)
			skynet.send(DATA.service_config.task_center_service,"lua","add_player_task_log"
					,task_ob_data.player_id
					,task_ob_data.task_id
					, add_pro
					,task_ob_data.process)

			skynet.send(DATA.service_config.task_center_service,"lua","add_or_update_task_data"
				,task_ob_data.player_id
				,task_ob_data.task_id
				,task_ob_data.process
				,task_ob_data.task_round
				,task_ob_data.create_time
				,task_ob_data.task_award_get_status )


			---- 通知，进度增加
			nodefunc.send(player_id,"update_step_task_process", task_id , task_ob_data.process , task_ob_data.process == max_process )
		end

	end
end

--玩家 充值消息
function CMD.player_charge_msg(player_id , product_id , pay_money ,_channel_type)

	local player_bbsc_data = skynet.call(DATA.service_config.data_service,"lua","query_player_stepstep_money" , player_id ) 

	if player_bbsc_data then

		local now_big_step = player_bbsc_data.now_big_step
		local now_little_step = player_bbsc_data.now_little_step

		----- 过期了，任务不加
		if player_bbsc_data.over_time then
			local now_time = os.time()
			if now_time > player_bbsc_data.over_time then
				return
			end
		end

		local config = skynet.call(DATA.service_config.task_center_service,"lua","get_stepstep_money_config")

		local task_config = skynet.call(DATA.service_config.task_center_service,"lua","get_main_config")

		local target_task_vec = config.task
		if player_bbsc_data.bbsc_version == "new" then
			target_task_vec = config.task_new
		end

		for key,data in pairs(target_task_vec) do
			--- 未到这一步，依旧可以加进度。在这一步可以加，过去了就不能加了
			if data.big_step_id > now_big_step or (data.big_step_id == now_big_step and data.little_step_id >= now_little_step) then
				local task_id = data.task_id
				local task_config = task_config[task_id]

				if task_config.condition_type == "charge_any" then
					local c_data = task_config.condition_data
					
					--- 加进度
					PUBLIC.add_one_task_progress( player_id , task_id , pay_money )
				end

				if task_config.condition_type == "buy_gift" then
					local c_data = task_config.condition_data
					--print("xxx-----------buy_gift:" , product_id)
					--dump( c_data.gift_id , "xxx-----------------buy_gift , c_data.gift_id ")

					if (not c_data.gift_id or basefunc.compare_value( product_id , c_data.gift_id.condition_value , c_data.gift_id.judge_type ) ) then

						--- 加进度
						PUBLIC.add_one_task_progress( player_id , task_id , 1 )

					end
				end

			end
		end
	
	end

end



return PROTECT