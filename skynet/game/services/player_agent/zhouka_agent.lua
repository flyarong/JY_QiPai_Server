-- 周卡 agent
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

---- 玩家的 周卡 数据
DATA.zhouka_data = {
	is_buy_jingbi_zhouka = 0,            ---- 是否购买 鲸币周卡
	jingbi_zhouka_remain = 0,            ---- 鲸币周卡 剩余的领取次数
	is_buy_qys_zhouka = 0,               ---- 是否购买 千元赛周卡
	qys_zhouka_remain = 0,               ---- 千元赛周卡 剩余的领取次数
}

local function add_or_upate_data()
	
	skynet.send(DATA.service_config.zhouka_system_service,"lua","add_or_update_zhouka_data",DATA.my_id ,
		DATA.zhouka_data.is_buy_jingbi_zhouka , DATA.zhouka_data.jingbi_zhouka_remain , DATA.zhouka_data.is_buy_qys_zhouka, DATA.zhouka_data.qys_zhouka_remain )
end

local function get_ob_data()
	local data =  skynet.call(DATA.service_config.zhouka_system_service,"lua","query_player_zhouka_data",DATA.my_id)
	if data then
		DATA.zhouka_data.is_buy_jingbi_zhouka = data.is_buy_jingbi_zhouka or 0
		DATA.zhouka_data.jingbi_zhouka_remain = data.jingbi_zhouka_remain or 0

		DATA.zhouka_data.is_buy_qys_zhouka = data.is_buy_qys_zhouka or 0
		DATA.zhouka_data.qys_zhouka_remain = data.qys_zhouka_remain or 0

	else
		add_or_upate_data()
	end
end

--- 监听购买 鲸币周卡
function CMD.buy_jingbi_zhouka( now_remain_num )
	print("------------- agent , buy_jingbi_zhouka ")

	
	DATA.zhouka_data.is_buy_jingbi_zhouka = 1
	DATA.zhouka_data.jingbi_zhouka_remain = now_remain_num

	--- 加上 周卡 任务
	CMD.distribute_task()

	--- 通知客户端，剩余次数改变
	PUBLIC.request_client("jinbgi_zhouka_remain_change_msg",
								{ task_remain = DATA.zhouka_data.jingbi_zhouka_remain })
end

--- 监听购买 鲸币周卡
function CMD.buy_qys_zhouka( now_remain_num )
	print("------------- agent , buy_qys_zhouka ")

	
	DATA.zhouka_data.is_buy_qys_zhouka = 1
	DATA.zhouka_data.qys_zhouka_remain = now_remain_num

	--- 加上 周卡 任务
	CMD.distribute_task()

	--- 通知客户端，剩余次数改变
	local next_get_day = PUBLIC.get_qys_next_start_day( )
	PUBLIC.request_client("qys_zhouka_remain_change_msg",
								{ 
									task_remain = DATA.zhouka_data.qys_zhouka_remain, 
									next_get_day = next_get_day,
								})
end

--- 任务完成并领取奖励 ---- 金币周卡
function MSG.jingbi_zhouka_task_get_award(_ )
	DATA.zhouka_data.jingbi_zhouka_remain = DATA.zhouka_data.jingbi_zhouka_remain - 1
	add_or_upate_data( )

	
	--- 通知客户端，剩余次数改变
	PUBLIC.request_client("jinbgi_zhouka_remain_change_msg",
								{ task_remain = DATA.zhouka_data.jingbi_zhouka_remain })

	--- 删掉周卡任务
	if DATA.zhouka_data.jingbi_zhouka_remain <= 0 then
		PUBLIC.delete_jingib_zhouka_task()
	end
end

--- 任务完成并领取奖励 ---- 千元赛周卡
function MSG.qys_zhouka_task_get_award(_ )
	DATA.zhouka_data.qys_zhouka_remain = DATA.zhouka_data.qys_zhouka_remain - 1
	add_or_upate_data( )

	
	--- 通知客户端，剩余次数改变
	local next_get_day = PUBLIC.get_qys_next_start_day( true )
	PUBLIC.request_client("qys_zhouka_remain_change_msg",
								{ 
									task_remain = DATA.zhouka_data.qys_zhouka_remain,
									next_get_day = next_get_day,
								 })

	--- 删掉周卡任务
	if DATA.zhouka_data.qys_zhouka_remain <= 0 then
		PUBLIC.delete_qys_zhouka_task()
	end
end

---- 请求鲸币周卡剩余次数
function REQUEST.query_jingbi_zhouka_remain(self)
	local remain_num = DATA.zhouka_data.jingbi_zhouka_remain

	print("xxxx-------------------query_jingbi_zhouka_remain:",remain_num)
	return {
		result = 0,
		remain_num = remain_num,
	}
end



---- 请求千元赛周卡剩余次数
function REQUEST.query_qys_zhouka_remain(self)
	local remain_num = DATA.zhouka_data.qys_zhouka_remain

	--- 查看今日是否领取了
	local is_get_award = false
	if DATA.task_list[54] and DATA.task_list[54].task_award_get_status then
		local get_status = basefunc.decode_task_award_status( DATA.task_list[54].task_award_get_status )
		if get_status[1] then
			is_get_award = true
		end
	end


	local next_get_day = PUBLIC.get_qys_next_start_day( is_get_award )

	print("xxxx-------------------query_qys_zhouka_remain:",remain_num,next_get_day)
	return {
		result = 0,
		remain_num = remain_num,
		next_get_day = next_get_day,
	}
end

function PROTECT.init()
	get_ob_data()

	DATA.msg_dispatcher:register( MSG , MSG )

end

return PROTECT