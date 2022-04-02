-- vip礼包 agent
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

DATA.vip_lb_agent = {}
local PROTECT = DATA.vip_lb_agent
PROTECT.task_over_timer = nil

local MSG = {}

---- 玩家的 vip lb 数据
DATA.vip_lb_data = {
	is_buy_vip_lb = 0,                ---- 是否购买 vip礼包
	now_vip_task_get_num1 = 0,        ---- 1号vip任务已经获取的次数
	now_vip_task_max_num1 = 0,		  ---- 1号vip任务总共获取的次数
	now_vip_task_get_num2 = 0,		  ---- 2号vip任务已经获取的次数
	now_vip_task_max_num2 = 0,        ---- 2号vip任务总共获取的次数
	now_vip_rebate_xj_num = 0,        ---- 当前已经返利的下级人数
	max_vip_rebate_xj_num = 0,        ---- 总共可以返利的下级人数
	task_overdue_time = os.time(),    ---- 任务过期时间
}

function PROTECT.add_or_upate_data()
	skynet.send(DATA.service_config.sczd_vip_lb_service,"lua","add_or_update_vip_lb_data",DATA.my_id ,
		DATA.vip_lb_data.is_buy_vip_lb , DATA.vip_lb_data.now_vip_task_get_num1 , DATA.vip_lb_data.now_vip_task_max_num1,
		 DATA.vip_lb_data.now_vip_task_get_num2 , DATA.vip_lb_data.now_vip_task_max_num2 , DATA.vip_lb_data.now_vip_rebate_xj_num 
		 , DATA.vip_lb_data.max_vip_rebate_xj_num , DATA.vip_lb_data.task_overdue_time )
end

local function get_ob_data()
	local data =  skynet.call(DATA.service_config.sczd_vip_lb_service,"lua","query_player_vip_lb_data",DATA.my_id)
	if data then
		DATA.vip_lb_data.is_buy_vip_lb = data.is_buy_vip_lb or 0
		DATA.vip_lb_data.now_vip_task_get_num1 = data.now_vip_task_get_num1 or 0
		DATA.vip_lb_data.now_vip_task_max_num1 = data.now_vip_task_max_num1 or 0
		DATA.vip_lb_data.now_vip_task_get_num2 = data.now_vip_task_get_num2 or 0
		DATA.vip_lb_data.now_vip_task_max_num2 = data.now_vip_task_max_num2 or 0
		DATA.vip_lb_data.now_vip_rebate_xj_num = data.now_vip_rebate_xj_num or 0
		DATA.vip_lb_data.max_vip_rebate_xj_num = data.max_vip_rebate_xj_num or 0
		DATA.vip_lb_data.task_overdue_time = data.task_overdue_time or 0
		
	else
		PROTECT.add_or_upate_data()
	end

	PROTECT.deal_task_overdue_time()
end

--- 任务完成并领取奖励
function MSG.vip_lb_task1_get_award(_ )
	DATA.vip_lb_data.now_vip_task_get_num1 = DATA.vip_lb_data.now_vip_task_get_num1 + 1
	PROTECT.add_or_upate_data( )

	local lb_num = skynet.call( DATA.service_config.pay_service , "lua" , "query_gift_bag_num" , 43 ) or 0
	--- 通知客户端，剩余次数改变
	PUBLIC.request_client("vip_lb_base_info_change_msg",
								{ 
									is_buy_vip_lb = DATA.vip_lb_data.is_buy_vip_lb , 
									task_get_num1 = DATA.vip_lb_data.now_vip_task_get_num1 , 
									task_max_num1 = DATA.vip_lb_data.now_vip_task_max_num1 , 
									task_get_num2 = DATA.vip_lb_data.now_vip_task_get_num2 , 
									task_max_num2 = DATA.vip_lb_data.now_vip_task_max_num2 , 
									task_overdue_time = DATA.vip_lb_data.task_overdue_time , 
									remain = lb_num
								})

	--- 删掉 任务
	if DATA.vip_lb_data.now_vip_task_get_num1 >= DATA.vip_lb_data.now_vip_task_max_num1 then
		PUBLIC.delete_vip_lb_task_1()
	end
end

--- 任务完成并领取奖励
function MSG.vip_lb_task2_get_award(_ )
	DATA.vip_lb_data.now_vip_task_get_num2 = DATA.vip_lb_data.now_vip_task_get_num2 + 1
	PROTECT.add_or_upate_data( )

	
	local lb_num = skynet.call( DATA.service_config.pay_service , "lua" , "query_gift_bag_num" , 43 ) or 0
	--- 通知客户端，剩余次数改变
	PUBLIC.request_client("vip_lb_base_info_change_msg",
								{ 
									is_buy_vip_lb = DATA.vip_lb_data.is_buy_vip_lb , 
									task_get_num1 = DATA.vip_lb_data.now_vip_task_get_num1 , 
									task_max_num1 = DATA.vip_lb_data.now_vip_task_max_num1 , 
									task_get_num2 = DATA.vip_lb_data.now_vip_task_get_num2 , 
									task_max_num2 = DATA.vip_lb_data.now_vip_task_max_num2 , 
									task_overdue_time = DATA.vip_lb_data.task_overdue_time ,
									remain = lb_num
								})

	--- 删掉 任务
	if DATA.vip_lb_data.now_vip_task_get_num2 >= DATA.vip_lb_data.now_vip_task_max_num2 then
		PUBLIC.delete_vip_lb_task_2()
	end
end

--- 监听购买 vip 礼包
function CMD.buy_vip_lb( sczd_vip_task1_max_num , sczd_vip_task2_max_num , task_overdue_time )
	print("------------- agent , buy_vip_lb ")

	
	DATA.vip_lb_data.is_buy_vip_lb = 1
	DATA.vip_lb_data.now_vip_task_get_num1 = 0
	DATA.vip_lb_data.now_vip_task_max_num1 = sczd_vip_task1_max_num
	DATA.vip_lb_data.now_vip_task_get_num2 = 0
	DATA.vip_lb_data.now_vip_task_max_num2 = sczd_vip_task2_max_num
	DATA.vip_lb_data.task_overdue_time = task_overdue_time

	--- 加上 任务
	CMD.distribute_task()

	local lb_num = skynet.call( DATA.service_config.pay_service , "lua" , "query_gift_bag_num" , 43 ) or 0

	--- 通知客户端，
	PUBLIC.request_client("vip_lb_base_info_change_msg",
								{ 
									is_buy_vip_lb = DATA.vip_lb_data.is_buy_vip_lb , 
									task_get_num1 = DATA.vip_lb_data.now_vip_task_get_num1 , 
									task_max_num1 = DATA.vip_lb_data.now_vip_task_max_num1 , 
									task_get_num2 = DATA.vip_lb_data.now_vip_task_get_num2 , 
									task_max_num2 = DATA.vip_lb_data.now_vip_task_max_num2 , 
									task_overdue_time = DATA.vip_lb_data.task_overdue_time , 
									remain = lb_num
								})

	
	PROTECT.deal_task_overdue_time()

end

function PROTECT.deal_task_overdue_time()
	----- 如果有任务超时时间
	if DATA.vip_lb_data.task_overdue_time > 0 then
		if PROTECT.task_over_timer and type(PROTECT.task_over_timer) == "function" then
			PROTECT.task_over_timer()
		end

		PROTECT.task_over_timer = basefunc.cancelable_timeout( 100*(DATA.vip_lb_data.task_overdue_time - os.time()) , function()
			print("xxxxx-----------deal_task_overdue_time")
			PUBLIC.deal_vip_lb_task_auto_get()
			
			PUBLIC.delete_vip_lb_task_1()
			PUBLIC.delete_vip_lb_task_2()
		end)
	end
end


function CMD.set_max_vip_rebate_xj_num(max_rebate_xj_num)
	DATA.vip_lb_data.max_vip_rebate_xj_num = max_rebate_xj_num

end


----- 请求基本数据
function REQUEST.query_vip_lb_base_info(self)

	local lb_num = skynet.call( DATA.service_config.pay_service , "lua" , "query_gift_bag_num" , 43 ) or 0


	return {
		result = 0,
		is_buy_vip_lb = DATA.vip_lb_data.is_buy_vip_lb,
		task_get_num1 = DATA.vip_lb_data.now_vip_task_get_num1,
		task_max_num1 = DATA.vip_lb_data.now_vip_task_max_num1,
		task_get_num2 = DATA.vip_lb_data.now_vip_task_get_num2,
		task_max_num2 = DATA.vip_lb_data.now_vip_task_max_num2,
		task_overdue_time = DATA.vip_lb_data.task_overdue_time,
		remain = lb_num
	}

end



function PROTECT.init()
	get_ob_data()

	DATA.msg_dispatcher:register( MSG , MSG )

end





return PROTECT