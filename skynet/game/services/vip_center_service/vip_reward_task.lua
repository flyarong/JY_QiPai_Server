--
-- Author: wss
-- Date: 2018/11/14
-- Time: 9:48
-- 说明：vip 返奖任务(对局红包) 的管理
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECT = {}

--- 晚上几点开始提醒玩家还未完成对局红包游戏
DATA.task_alert_start = 20    
DATA.task_alert_num = 5           -- 提示几次
DATA.task_alert_now_count = 0
DATA.task_alert_delay = 600       -- 每次提示的间隔


local REWARD_TASK_STATUS = {
	not_complete = 0,       -- 未完成返奖任务
	complete_not_get = 1,   -- 完成返奖任务但未主动领取(系统帮领)
	complete_get = 2,       -- 完成返奖任务并主动领取了
	get_find_award = 3,     -- 领取了找回的返奖任务奖励
}

---- 所有的返奖奖励的数据，key是player_id
DATA.reward_task_data = nil

----- 返奖任务的每日完成情况的记录的缓存
DATA.reward_task_record_complete_info_cache = {}

----- 返奖任务的找回奖励和领取情况的记录的缓存、
DATA.reward_task_record_find_info_cache = {}

---- 载入数据库数据
local load_ob_data = function()
	DATA.reward_task_data = skynet.call(DATA.service_config.data_service,"lua","query_all_reward_task_data")
	if not DATA.reward_task_data then
		error("load_reward_task_data --- query_all_reward_task_data , get DATA.reward_task_data error !")
	end
end

local updata_or_add_data = function(data)
	--- 没有就要新增
	skynet.send(DATA.service_config.data_service,"lua","update_or_add_player_vip_reward_task"
					,data.player_id
					,data.reward_task_status
					,data.last_op_time
					,data.award_value
					,data.total_get_award
					,data.total_find_award)
end

--- 新增每日记录
local add_every_day_record = function(_player_id , _get_award_value , _status , _time)

	skynet.send(DATA.service_config.data_service,"lua","add_player_vip_reward_task_record"
					,_player_id
					,_get_award_value
					,_status
					,_time)

	
	---- 新纪录插入缓存中
	if _status ~= REWARD_TASK_STATUS.get_find_award then
		local record_data = DATA.reward_task_record_complete_info_cache[player_id]
		if record_data and record_data.data
				and record_data.clear_delay > 0 and #record_data.data > 0 then
			local data = {}
			data.player_id = _player_id
			data.get_award_value = _get_award_value
			data.status = _status
			data.time = _time

			table.insert(record_data.data , 1 , data)
			record_data.dynamic_insert_num = record_data.dynamic_insert_num + 1
		end
	end

	if _status == REWARD_TASK_STATUS.get_find_award or _status == REWARD_TASK_STATUS.complete_not_get then
		local record_data = DATA.reward_task_record_find_info_cache[player_id]
		if record_data and record_data.data
				and record_data.clear_delay > 0 and #record_data.data > 0 then
			local data = {}
			data.player_id = _player_id
			data.get_award_value = _get_award_value
			data.status = _status
			data.time = _time

			table.insert(record_data.data , 1 , data)
			record_data.dynamic_insert_num = record_data.dynamic_insert_num + 1
		end
	end

end

--- 完成返奖任务，还未领取
function CMD.complete_reward_task( player_id , award_value)
	local data = DATA.reward_task_data[player_id]
	local now_time = os.time()
	if data then
		data.reward_task_status = REWARD_TASK_STATUS.complete_not_get
		data.last_op_time = now_time
		data.award_value = award_value
	else
		DATA.reward_task_data[player_id] = {}
		data = DATA.reward_task_data[player_id]
		data.player_id = player_id
		data.reward_task_status = REWARD_TASK_STATUS.complete_not_get
		data.last_op_time = now_time
		data.award_value = award_value
		data.total_get_award = 0
		data.total_find_award = 0
	end

	updata_or_add_data(data)
end

--- 领取了返奖任务
function CMD.get_reward_task_award( player_id )
	--- 操作限制
	if PUBLIC.get_action_lock( "get_reward_task_award" , player_id ) then
		return 1008
	end
	PUBLIC.on_action_lock( "get_reward_task_award" , player_id )

	local data = DATA.reward_task_data[player_id]
	local now_time = os.time()
	assert( data , "get_reward_task_award must have data" )

	--- 如果没有完成是不能领的
	if data.reward_task_status ~= REWARD_TASK_STATUS.complete_not_get then
		return 3801
	end

	if data.reward_task_status == REWARD_TASK_STATUS.complete_get and now_time - data.last_op_time < 86400 then
		--error("--------------- get_reward_task_award , one day get more times!! ")
		PUBLIC.off_action_lock( "get_reward_task_award" , player_id )
		return 3802
	end

	data.reward_task_status = REWARD_TASK_STATUS.complete_get
	data.last_op_time = now_time
	data.total_get_award = data.total_get_award + data.award_value
	--data.award_value = 0

	--------- 发wx奖励 --------


	-- 广播
	skynet.send(DATA.service_config.broadcast_center_service,"lua"
						,"fixed_broadcast"
						,"vip_20_award"
						,DATA.all_vip_players[player_id].name)


	updata_or_add_data(data)

	--记录
	add_every_day_record( player_id , data.award_value , REWARD_TASK_STATUS.complete_get , now_time )

	PUBLIC.off_action_lock( "get_reward_task_award" , player_id )
end

--- 领取找回的返奖任务奖励，注意隔离性操作
function CMD.get_find_reward_task_award(player_id )
	--- 操作限制
	if PUBLIC.get_action_lock( "get_find_reward_task_award" , player_id ) then
		return 1008
	end
	PUBLIC.on_action_lock( "get_find_reward_task_award" , player_id )

	---- 只有vip用户才能领取奖励
	if not DATA.working_vip_players[player_id] then
		PUBLIC.off_action_lock( "get_find_reward_task_award" , player_id )
		return 4005
	end

	local now_time = os.time()
	local can_get_value = data.total_find_award
	data.total_find_award = 0

	if can_get_value <= 0 then
		PUBLIC.off_action_lock( "get_find_reward_task_award" , player_id )
		return 3803
	end

	--------- 发wx奖励 --------


	--- 记录
	add_every_day_record( player_id , can_get_value , REWARD_TASK_STATUS.get_find_award , now_time )

	local ret_record = { id = -1 , get_award_value = can_get_value , status = REWARD_TASK_STATUS.get_find_award , time = now_time }


	PUBLIC.off_action_lock( "get_find_reward_task_award" , player_id )

	return 0 , ret_record
end

---- 获得每日完成情况记录
function CMD.get_reward_task_complete_info( player_id , page_index , page_item_num )
	
	return PUBLIC.get_record_with_cache( DATA.reward_task_record_complete_info_cache , "get_player_vip_reward_task_record_complete_info" , player_id , page_index , page_item_num )

end

---- 获取找回记录&找回领取记录
function CMD.get_reward_task_find_info(player_id , page_index , page_item_num)

	return PUBLIC.get_record_with_cache( DATA.reward_task_record_find_info_cache , "get_player_vip_reward_task_record_find_info" , player_id , page_index , page_item_num )

end

--- 查 返奖任务的总共获取的奖励值
function CMD.query_reward_task_total_get(player_id)
	if not DATA.reward_task_data[player_id] then
		return 0
	end
	return DATA.reward_task_data[player_id].total_get_award
end

--- 查 返奖任务的总共找回的奖励值
function CMD.query_reward_task_total_find(player_id)
	if not DATA.reward_task_data[player_id] then
		return 0
	end
	return DATA.reward_task_data[player_id].total_find_award
end

---- 重置
function PROTECT.reset_data(player_id)
	local data = DATA.reward_task_data[player_id]
	local now_time = os.time()
	--- 如果没有数据，说明是没有完成今日任务
	if not data then
		add_every_day_record( player_id , 0 , REWARD_TASK_STATUS.not_complete , now_time )
	else
		--- 如果有再看是否完成，
		if now_time - data.last_op_time > 86400 then
			add_every_day_record( player_id , 0 , REWARD_TASK_STATUS.not_complete , now_time )
		else
			if data.reward_task_status == REWARD_TASK_STATUS.not_complete then
				add_every_day_record( player_id , 0 , REWARD_TASK_STATUS.not_complete , now_time )
			elseif data.reward_task_status == REWARD_TASK_STATUS.complete_not_get then
				add_every_day_record( player_id , data.award_value , REWARD_TASK_STATUS.complete_not_get , now_time )
				--- 系统帮领，弄到回报任务奖励找回表中去
				data.total_find_award = data.total_find_award + data.award_value
				updata_or_add_data(data)
				
			elseif data.reward_task_status == REWARD_TASK_STATUS.complete_get then
				-- 完成并领取了在那一刻就该记录上。
				--add_every_day_record( player_id , data.award_value , REWARD_TASK_STATUS.complete_get , now_time )
			end
		end
	end

end

---- 任务 未完成 的提示 , app 推送
local function alert_rewara_task_not_complete()
	local now_time = os.time()
	local wait_time = 0
	DATA.task_alert_now_count = DATA.task_alert_now_count + 1
	if DATA.task_alert_now_count > DATA.task_alert_num then
		DATA.task_alert_now_count = 0
		wait_time = basefunc.get_diff_target_time(DATA.task_alert_start)
		if wait_time == 0 then
			wait_time = 1
		end
	else
		wait_time = DATA.task_alert_delay
	end

	----
	
	for player_id , data in pairs(DATA.working_vip_players) do
		local is_deal_alert = false
		if not DATA.reward_task_data[player_id] then
			is_deal_alert = true
		else
			local is_same_day = basefunc.is_same_day( now_time , DATA.reward_task_data[player_id].last_op_time , DATA.REST_TIME )
			if is_same_day then
				if DATA.reward_task_data[player_id].reward_task_status == REWARD_TASK_STATUS.not_complete then
					is_deal_alert = true
				end
			else
				is_deal_alert = true
			end

		end


		---- APP 推送
		if is_deal_alert then
			skynet.send(DATA.service_config.third_agent_service,"lua","push_notify"
	       ,"broadcast"
	       ,"领取vip红包"
	       ,""
	       ,string.format("尊贵的%s，您今日的Vip奖金还未领取，玩游戏就能领奖金哦，赶快来吧！" , DATA.all_vip_players[player_id].name ))

		end

	end

	----
	skynet.timeout(wait_time * 100, function() 
		alert_rewara_task_not_complete()
	end)

end

function PROTECT.init()
	load_ob_data()

	PUBLIC.add_record_cache( DATA.reward_task_record_complete_info_cache )
	PUBLIC.add_record_cache( DATA.reward_task_record_find_info_cache )

	local next_reset_wait = basefunc.get_diff_target_time(DATA.task_alert_start)

    if next_reset_wait==0 then 
		next_reset_wait=1
	end 
	skynet.timeout(next_reset_wait * 100, function() 
		alert_rewara_task_not_complete()
	end)

end

function PROTECT.update(dt)

end

return PROTECT
