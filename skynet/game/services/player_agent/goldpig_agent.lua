--
-- Created by wss.
-- User: hare
-- Date: 2019/1/3
-- Time: 17:49
-- 金猪  agent
--


local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local task_initer = require "task.init"
local nodefunc = require "nodefunc"

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST
local PUBLIC = base.PUBLIC

local PROTECT = {}

local MSG = {}

---- 玩家的金猪数据
DATA.goldpig_data = {
	is_buy_goldpig = 0,            ---- 是否购买 (旧版) 金猪礼包1
	goldpig_remain_num = 0,        ---- (旧版) 金猪礼包1 剩余的领取次数
	is_buy_goldpig1 = 0,           ---- 是否购买 (新版) 金猪礼包1
	goldpig_remain_num1 = 0,       ---- (新版) 金猪礼包1 剩余的领取次数
	is_buy_goldpig2 = 0,           ---- 是否购买 金猪礼包2
	goldpig_remain_num2 = 0,       ---- 金猪礼包2 剩余的领取次数
	today_get_task_num2 = 0,       --- 今日领取金猪礼包2 任务的次数
}


local function add_or_upate_data()
	
	skynet.send(DATA.service_config.goldpig_center_service,"lua","add_or_update_goldpig_data",DATA.my_id ,
		DATA.goldpig_data.is_buy_goldpig , DATA.goldpig_data.goldpig_remain_num , DATA.goldpig_data.is_buy_goldpig1, DATA.goldpig_data.goldpig_remain_num1 ,
		 DATA.goldpig_data.is_buy_goldpig2 , DATA.goldpig_data.goldpig_remain_num2 , DATA.goldpig_data.today_get_task_num2)
end

---
local function get_ob_data()
	local data =  skynet.call(DATA.service_config.goldpig_center_service,"lua","query_player_goldpig_data",DATA.my_id)
	if data then
		DATA.goldpig_data.is_buy_goldpig = data.is_buy_goldpig or 0
		DATA.goldpig_data.goldpig_remain_num = data.remain_task_num or 0

		DATA.goldpig_data.is_buy_goldpig1 = data.is_buy_goldpig1 or 0
		DATA.goldpig_data.goldpig_remain_num1 = data.remain_task_num1 or 0

		DATA.goldpig_data.is_buy_goldpig2 = data.is_buy_goldpig2 or 0
		DATA.goldpig_data.goldpig_remain_num2 = data.remain_task_num2 or 0
		DATA.goldpig_data.today_get_task_num2 = data.today_get_task_num2 or 0
	else
		add_or_upate_data()
	end
end



--- 监听购买 金猪礼包1  (只适用，新版金猪礼包1) 
function CMD.buy_goldpig( now_remain_num )
	print("------------- agent , buy_goldpig ")

	---- (旧版内容)
	--DATA.goldpig_data.is_buy_goldpig = 1
	--DATA.goldpig_data.goldpig_remain_num = now_remain_num
	
	DATA.goldpig_data.is_buy_goldpig1 = 1
	DATA.goldpig_data.goldpig_remain_num1 = now_remain_num

	--- 加上金猪任务
	CMD.distribute_task()

	--- 通知客户端，剩余次数改变
	PUBLIC.request_client("goldpig_task_remain_change_msg",
								{ task_remain = DATA.goldpig_data.goldpig_remain_num1 })
end

--- 监听购买 金猪礼包2
function CMD.buy_goldpig2( now_remain_num )
	print("------------- agent , buy_goldpig ")

	---- (旧版内容)
	--DATA.goldpig_data.is_buy_goldpig = 1
	--DATA.goldpig_data.goldpig_remain_num = now_remain_num
	
	DATA.goldpig_data.is_buy_goldpig2 = 1
	DATA.goldpig_data.goldpig_remain_num2 = now_remain_num
	DATA.goldpig_data.today_get_task_num2 = 0

	--- 加上金猪任务
	CMD.distribute_task()

	--- 通知客户端，剩余次数改变
	PUBLIC.request_client("goldpig2_task_remain_change_msg",
								{ task_remain = DATA.goldpig_data.goldpig_remain_num2 })

	---- 触发一次资产观察。
	PUBLIC.asset_observe()
end

--- 任务完成并领取奖励 ---- 金猪礼包1 (旧版)
function MSG.goldpig_task_get_award(_, award_value )
	DATA.goldpig_data.goldpig_remain_num = DATA.goldpig_data.goldpig_remain_num - 1
	add_or_upate_data( )

	
	--- 通知 生财之道 中心服务
	skynet.send(DATA.service_config.sczd_center_service,"lua","add_income_details_goldpig_task",
		DATA.my_id , DATA.player_data.player_info.name , award_value )

	--- 通知客户端，剩余次数改变
	PUBLIC.request_client("goldpig_task_remain_change_msg",
								{ task_remain = DATA.goldpig_data.goldpig_remain_num })

	--- 删掉金猪任务
	if DATA.goldpig_data.goldpig_remain_num <= 0 then
		PUBLIC.delete_goldpig_task()
	end
end

--- 任务完成并领取奖励 ---- 金猪礼包1 (新版)
function MSG.goldpig_task_get_award_new(_, award_value )
	DATA.goldpig_data.goldpig_remain_num1 = DATA.goldpig_data.goldpig_remain_num1 - 1
	add_or_upate_data( )

	
	--- 通知 生财之道 中心服务
	skynet.send(DATA.service_config.sczd_center_service,"lua","add_income_details_goldpig_task",
		DATA.my_id , DATA.player_data.player_info.name , award_value )

	--- 通知客户端，剩余次数改变
	PUBLIC.request_client("goldpig_task_remain_change_msg",
								{ task_remain = DATA.goldpig_data.goldpig_remain_num1 })

	--- 删掉金猪任务
	if DATA.goldpig_data.goldpig_remain_num1 <= 0 then
		PUBLIC.delete_goldpig_task()
	end
end

--- 获取金猪任务数据 ---- 金猪礼包1 (新旧通用)
function REQUEST.query_goldpig_task_data()
	local ret = {}
	for task_id ,task_obj in pairs(DATA.task_list) do
		if task_obj.config.own_type == "goldpig" or task_obj.config.own_type == "goldpig_new" then
			local last_index = #ret + 1
			ret[last_index] = {}
			ret[last_index].id = task_id
			ret[last_index].now_total_process = task_obj.process
			ret[last_index].now_lv = task_obj.lv
			ret[last_index].now_process = task_obj.get_now_process()
			ret[last_index].need_process = task_obj.get_need_process()
			ret[last_index].task_round = task_obj.task_round
			ret[last_index].award_status = task_obj.get_award_status()
			ret[last_index].award_get_status = task_obj.task_award_get_status or 0

		end
	end

	return {
		result = 0,
		task_list = ret,
	}

end
-- 获取剩余的 领取次数 ---- 金猪礼包1 (新旧通用)
function REQUEST.query_goldpig_task_remain()
	local remain_num = DATA.goldpig_data.goldpig_remain_num
	if DATA.goldpig_data.is_buy_goldpig1 == 1 then
		remain_num = DATA.goldpig_data.goldpig_remain_num1
	end

	return {
		result = 0,
		remain_num = remain_num,
	}
end




--- 获取金猪任务的奖励 ---- 金猪礼包1 (新旧通用)
function REQUEST.get_goldpig_task_award(self)
	--- 参数检查
	if not self or not self.id or type(self.id)~="number" then
		return {
			result = 1001,
		}
	end

	if PUBLIC.get_action_lock("get_goldpig_task_award" ) then
		return 1008
	end
	PUBLIC.on_action_lock("get_goldpig_task_award" )

	local result_code = PUBLIC.get_task_award(self.id)

	PUBLIC.off_action_lock("get_goldpig_task_award")
	return {
		result = result_code,
		id = self.id,
	}

end

--- 任务完成并领取奖励 ---- 金猪礼包2
function MSG.goldpig2_task_get_award_new(_, award_value )
	DATA.goldpig_data.goldpig_remain_num2 = DATA.goldpig_data.goldpig_remain_num2 - 1
	add_or_upate_data( )

	
	--- 通知 生财之道 中心服务
	--[[skynet.send(DATA.service_config.sczd_center_service,"lua","add_income_details_goldpig_task",
		DATA.my_id , DATA.player_data.player_info.name , award_value )
--]]
	--- 通知客户端，剩余次数改变
	PUBLIC.request_client("goldpig2_task_remain_change_msg",
								{ task_remain = DATA.goldpig_data.goldpig_remain_num2 })

	--- 删掉金猪任务
	if DATA.goldpig_data.goldpig_remain_num2 <= 0 then
		PUBLIC.delete_goldpig2_task()
	end
end

--- 获取金猪任务数据 ---- 金猪礼包2 
function REQUEST.query_goldpig2_task_data()
	local ret = {}
	for task_id ,task_obj in pairs(DATA.task_list) do
		if task_obj.config.own_type == "goldpig_new2" then
			local last_index = #ret + 1
			ret[last_index] = {}
			ret[last_index].id = task_id
			ret[last_index].now_total_process = task_obj.process
			ret[last_index].now_lv = task_obj.lv
			ret[last_index].now_process = task_obj.get_now_process()
			ret[last_index].need_process = task_obj.get_need_process()
			ret[last_index].task_round = task_obj.task_round
			ret[last_index].award_status = task_obj.get_award_status()
			ret[last_index].award_get_status = task_obj.task_award_get_status or 0
			
		end
	end

	return {
		result = 0,
		task_list = ret,
	}

end
-- 获取剩余的 领取次数 ---- 金猪礼包2
function REQUEST.query_goldpig2_task_remain()
	return {
		result = 0,
		remain_num = DATA.goldpig_data.goldpig_remain_num2,
	}
end

-- 获取 今日 剩余的 领取次数 ---- 金猪礼包2
function REQUEST.query_goldpig2_task_today_data()
	local total_num = 0
	local remain_num = 0
	for task_id ,task_obj in pairs(DATA.task_list) do
		if task_obj.config.own_type == "goldpig_new2" then
			total_num = task_obj.max_task_round
			remain_num = task_obj.max_task_round - task_obj.task_round + 1
		end
	end

	return {
		result = 0,
		total_num = total_num,
		remain_num = remain_num,
	}
end


--- 设置 新金猪1任务的剩余次数（测试用）
function CMD.set_goldpig1_remain(num)
	DATA.goldpig_data.goldpig_remain_num1 = num
end

--- 设置 新金猪2任务的剩余次数（测试用）
function CMD.set_goldpig2_remain(num)
	DATA.goldpig_data.goldpig_remain_num2 = num
end


function PROTECT.init()
	get_ob_data()

	DATA.msg_dispatcher:register( MSG , MSG )

end

return PROTECT