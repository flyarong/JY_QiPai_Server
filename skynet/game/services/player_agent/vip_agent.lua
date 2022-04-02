--
-- Author: wss
-- Date: 2018/11/14
-- Time: 

local skynet = require "skynet_plus"
local basefunc=require"basefunc"
local nodefunc = require "nodefunc"
require"printfunc"

local base = require "base"
local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC
local REQUEST=base.REQUEST
local PROTECT={}

local msg = {}
DATA.vip_status = {
	never_is = 0,     -- 从未是vip
	is_vip = 1,       -- 当前是vip
	past_is = 2,      -- 以前是vip
}

local function init_data()
	
	DATA.player_data.vip_data = skynet.call(DATA.service_config.vip_center_service,"lua","query_vip_data",DATA.my_id) 

end


function msg.vip_reward_task_complete(_,reward_value)
	skynet.send(DATA.service_config.vip_center_service,"lua","complete_reward_task",DATA.my_id , reward_value)
end

function msg.vip_reward_task_get(_)
	skynet.send(DATA.service_config.vip_center_service,"lua","get_reward_task_award",DATA.my_id )
end




function CMD.notify_vip_change_msg(vip_data)
	DATA.player_data.vip_data = vip_data

	PUBLIC.request_client("notify_vip_change_msg",
						{
							vip_data = vip_data,
						})


end

--- 推广奖励改变
function CMD.generalize_award_change_msg(award_value , total_award_value)
	PUBLIC.request_client("generalize_award_change_msg",
						{
							award_value = award_value,
							total_award_value = total_award_value,
						})
end

---------------------------------------------------------------- 请求


---- vip红包任务的每日记录
function REQUEST.query_reward_task_complete_record( self )


	local ret = {}
	local data = skynet.call(DATA.service_config.vip_center_service,"lua","get_reward_task_complete_info",DATA.my_id , self.page_index , self.page_num)
	local total_get = skynet.call(DATA.service_config.vip_center_service,"lua","query_reward_task_total_get",DATA.my_id , self.page_index , self.page_num)
	
	if type(data) == "number" then
		ret.result = data
	else
		ret.result = 0
		ret.total_get = total_get
		ret.record_data = data
	end

	return ret
end

---- vip红包任务的找回记录
function REQUEST.query_reward_task_find_record( self )

	local ret = {}
	local data = skynet.call(DATA.service_config.vip_center_service,"lua","get_reward_task_find_info",DATA.my_id , self.page_index , self.page_num)
	local total_find = skynet.call(DATA.service_config.vip_center_service,"lua","query_reward_task_total_find",DATA.my_id , self.page_index , self.page_num)
	
	if type(data) == "number" then
		ret.result = data
	else
		ret.result = 0
		ret.total_find = total_find
		ret.record_data = data
	end

	return ret
end

---- 领取  vip红包找回奖金的领取
function REQUEST.get_reward_task_finded_award()
	local ret = {}
	local result , record_data = skynet.call(DATA.service_config.vip_center_service,"lua","get_find_reward_task_award",DATA.my_id )

	ret.result = result
	ret.late_record = record_data

	return ret
end



-------------------------------------------------------------------
--- #领取 推广奖金
function REQUEST.get_generalize_award()
	local ret = {}
	local result,award_value = skynet.call(DATA.service_config.vip_center_service,"lua","get_generalize_award",DATA.my_id )

	ret.result = result
	ret.award_value = 0
	if ret.result == 0 then
		ret.award_value = award_value
	end
	return ret
end

-- 查 我的推广奖金
function REQUEST.query_generalize_award()
	
	local award_value , total_award_value = skynet.call(DATA.service_config.vip_center_service,"lua","query_generalize_award",DATA.my_id )

	local ret = {}
	ret.result = 0
	ret.award_value = award_value
	ret.total_award_value = total_award_value

	return ret
end

---查 推广奖金的获得记录
function REQUEST.query_generalize_award_get_record( self )
	local ret = {}
	local data = skynet.call(DATA.service_config.vip_center_service,"lua","get_player_vip_payback_record",DATA.my_id , self.page_index , self.page_num)

	if type(data) == "number" then
		ret.result = data
	else
		ret.result = 0
		ret.record_data = data
	end
	return ret
end

---查 提现 推广奖金的记录
function REQUEST.query_generalize_award_extract_record( self )
	local ret = {}
	local data = skynet.call(DATA.service_config.vip_center_service,"lua","get_generalize_extract_record",DATA.my_id , self.page_index , self.page_num)

	if type(data) == "number" then
		ret.result = data
	else
		ret.result = 0
		ret.record_data = data
	end
	return ret
end

--- 查 推广奖金的统计
function REQUEST.query_generalize_statistics()
	local ret = {}
	local statis_data = skynet.call(DATA.service_config.vip_center_service,"lua","get_vip_payback_statistics_all_day",DATA.my_id)
	dump(statis_data , ">>>>>>>>>>> query_generalize_statistics:")
	if not statis_data then
		ret.result = 4004
	else
		ret.result = 0
		ret.record_data = {}
		ret.total = 0
		ret.cur_month = 0
		ret.today = 0

		local now_time_date = os.date("*t")
		for year,year_data in pairs(statis_data.years) do
			ret.total = ret.total + year_data.value
			
			for month , month_data in pairs(year_data.months) do
				local is_same_year_month = false
				if now_time_date.year == year and now_time_date.month == month then
					ret.cur_month = month_data.value
					is_same_year_month = true
				end
				local next_index = #ret.record_data+1
				ret.record_data[next_index] = {}
				ret.record_data[next_index].year = year
				ret.record_data[next_index].month = month
				ret.record_data[next_index].total = month_data.value
				ret.record_data[next_index].record_data = {}
				local record_data = ret.record_data[next_index].record_data
				for day,day_data in pairs(month_data.days) do
					if is_same_year_month and now_time_date.day == day then
						ret.today = day_data.value
					end

					local record_next = #record_data + 1
					record_data[record_next] = {}
					record_data[record_next].day = day
					record_data[record_next].total = day_data.value
				end
			end
		end
	end

	return ret
end

-----
function REQUEST.query_generalize_children( self )
	local ret = {}
	local ob_data = skynet.call(DATA.service_config.vip_center_service,"lua","get_generalize_children",DATA.my_id,self.page_index , self.page_num)
	--dump(ob_data , ">>>>>>>>>>> query_generalize_children:")
	ret.result = 0
	ret.children_data = {}
	for key,data in ipairs(ob_data) do
		local index = #ret.children_data + 1
		ret.children_data[index] = {}
		ret.children_data[index].player_id = data.player_id
		ret.children_data[index].player_name = data.name
		ret.children_data[index].vip_day = skynet.call(DATA.service_config.vip_center_service,"lua","get_player_vip_day",DATA.my_id) 

	end
	

	return ret
end


function PROTECT.init()
	--- 注册消息监听
	DATA.msg_dispatcher:register( msg , msg )

	init_data()

end

return PROTECT