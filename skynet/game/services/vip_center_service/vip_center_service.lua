--
-- Author: wss
-- Date: 2018/11/13
-- Time: 11:57
-- 说明：vip 中心服务
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "printfunc"
require "normal_enum"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local vip_reward_task = require "vip_center_service/vip_reward_task"
local vip_generalize = require "vip_center_service/vip_generalize"

--- vip重置的时间，这个搞到配置里
DATA.REST_TIME = 6

--- vip 的配置
DATA.vip_config = nil
DATA.vip_common_config = nil
DATA.vip_buy_config = nil

-- 服务配置
DATA.service_config = nil

--- 所有的vip玩家数据
DATA.all_vip_players = nil
-- 所有的在期的vip玩家数据,
DATA.working_vip_players = {}

---- 记录缓存清理的延迟时间,秒
DATA.cache_clear_delay = 600


----- 所有的缓存表
DATA.all_record_cache = {}

---- 重置队列
DATA.reset_queue = nil

---------  做延迟一定时间清掉工作中的vip数据,购买后应该把对应的player_id的数据清掉，key = player_id , value = { delay }
DATA.delay_kill_working_vip_vec = {}

---------------------------------------------------------------------
--- 更新函数间隔
local update_dt = 1
local clear_update_dt = 10     -- 10 秒更新一次

--- 每次调用要处理的重置的个数
local deal_reset_num_per_second = 100

--- 错误码映射
local error_map = {
	get_player_vip_reward_task_record_complete_info = 3804,
	get_player_vip_reward_task_record_find_info = 3805,
	get_player_vip_payback_record = 3806,
	get_player_vip_generalize_extract_record = 3807,
}




--- 载入配置
local load_config = function()
	DATA.vip_config = base.reload_config("vip_server")

	DATA.vip_common_config = DATA.vip_config.common[1]

	DATA.vip_buy_config = DATA.vip_config.buy

end

--- 新增额外的 vip 数据
local load_vip_extend_data = function(data) 
	local player_info = skynet.call(DATA.service_config.data_service,"lua","get_player_info" , data.player_id )
	local parent_id = player_info.sczd_relation_data and player_info.sczd_relation_data.parent_id or nil
	local name =  player_info.player_info.name

	data.parent_id = parent_id or nil
	data.name = name
end

---- 载入vip玩家数据
local load_vip_data = function()

	DATA.all_vip_players = skynet.call(DATA.service_config.data_service,"lua","query_all_vip_players")
	if not DATA.all_vip_players then
		error("load_vip_data --- query_all_vip_players , get DATA.all_vip_players error !")
	end

	dump(DATA.all_vip_players , "----- DATA.all_vip_players:")
	local now_time = os.time()
	for player_id , data in pairs(DATA.all_vip_players) do
		--- 组织数据
		load_vip_extend_data(data)
		
		if data.vip_time > now_time and data.vip_day_time > 0 then
			DATA.working_vip_players[player_id] = DATA.all_vip_players[player_id]
		else
			--- 如果时间已经过期了，要重置一下天数
			if data.vip_day_time > 0 then
				data.vip_day_time = 0
				updata_or_add_player_vip(data)
			end
		end
	end

end

--- 更新或新增玩家vip数据
local updata_or_add_player_vip = function(vip_data)
	--- 没有就要新增
	skynet.send(DATA.service_config.data_service,"lua","update_or_add_player_vip"
					,vip_data.player_id
					,vip_data.vip_time
					,vip_data.vip_day_time)
end



---- 每日vip重置
local reset_data = function()
	---- 把所有的用户数据塞到一个队列里面，然后慢慢处理
	for player_id , data in pairs(DATA.working_vip_players) do
		DATA.reset_queue:push_back( player_id )
	end

	local wait_time = 86400
	skynet.timeout(wait_time * 100, function() 
		reset_data()
	end)
end

---- 处理一个重置
local deal_reset_data = function(player_id)
	if not DATA.working_vip_players[player_id] then
		return
	end
	local now_time = os.time()

	--- 每重置一次，天数减一
	DATA.working_vip_players[player_id].vip_day_time = DATA.working_vip_players[player_id].vip_day_time - 1
	if DATA.working_vip_players[player_id].vip_day_time <= 0 then
		--- 如果还有vip时间，那么现在天数还不能把天数减为0，
		if now_time < DATA.working_vip_players[player_id].vip_time then
			DATA.working_vip_players[player_id].vip_day_time = 1
			--- 放到一个列表中，到指定时间后清理
			DATA.delay_kill_working_vip_vec[player_id] = DATA.delay_kill_working_vip_vec[player_id] or {}
			DATA.delay_kill_working_vip_vec[player_id].delay = DATA.working_vip_players[player_id].vip_time - now_time
		else
			DATA.working_vip_players[player_id] = nil
		end

		
	end

	---- 如果当前时间都超过了vip时间，直接弄没
	if DATA.working_vip_players[player_id] and now_time >= DATA.working_vip_players[player_id].vip_time then
		DATA.working_vip_players[player_id].vip_day_time = 0
		DATA.working_vip_players[player_id] = nil
	end

	-- 天数改变, 推送改变消息
	nodefunc.send(player_id,"notify_vip_change_msg", CMD.query_vip_data(player_id) )

	updata_or_add_player_vip( DATA.all_vip_players[player_id] )

	---- vip返奖任务重置
	vip_reward_task.reset_data(player_id)

end

local update = function(dt)
	local deal_count = 0
	while deal_count < deal_reset_num_per_second and not DATA.reset_queue:empty() do
		local player_id = DATA.reset_queue:pop_font()

		deal_reset_data(player_id)

		deal_count = deal_count + 1
	end

end

----- 清理缓存的update,调用不用很频繁
local clear_update = function(dt)
	--- 记录缓存清理
	for key,cache_table in ipairs(DATA.all_record_cache) do
		local clear_vec = {}
		for player_id,data in pairs(cache_table) do
			data.clear_delay = data.clear_delay - clear_update_dt
			if data.clear_delay <= 0 then
				--- 清空
				clear_vec[#clear_vec+1] = player_id
			end
		end
		for key,player_id in pairs(clear_vec) do
			cache_table[player_id].data = nil
			cache_table[player_id] = nil
		end
	end

	---- 延迟处理工作中的vip
	local clear_vec = {}
	for player_id , data in pairs(DATA.delay_kill_working_vip_vec) do
		data.delay = data.delay - clear_update_dt
		if data.delay <= 0 then
			--- 清理
			if DATA.working_vip_players[player_id] and DATA.working_vip_players[player_id].vip_day_time == 1 then
				DATA.working_vip_players[player_id].vip_day_time = 0
				DATA.working_vip_players[player_id] = nil

				-- 天数改变, 推送改变消息
				nodefunc.send(player_id,"notify_vip_change_msg", CMD.query_vip_data(player_id) )

				updata_or_add_player_vip( DATA.all_vip_players[player_id] )
			end
			clear_vec[#clear_vec + 1] = player_id
		end
	end
	for key,player_id in pairs(clear_vec) do
		DATA.delay_kill_working_vip_vec[player_id] = nil
	end


end

--- 购买vip ,buy_class 购买的类型
function CMD.buy_vip( player_id , buy_class )
	--- 操作限制
	if PUBLIC.get_action_lock( "buy_vip" , player_id ) then
		return 1008
	end
	PUBLIC.on_action_lock( "buy_vip" , player_id )

	print(player_id,buy_class)
	local config_data = DATA.vip_buy_config[buy_class]

	if not config_data then
		error("-------------- buy_vip no config_data ------------")
		PUBLIC.off_action_lock( "buy_vip" , player_id )
		return 1000
	end

	local day_num = config_data.vip_day
	local payback_value = config_data.payback

	local total_seconds = day_num * 86400 --- 86400 一天的秒数
	local now_time = os.time()

	local vip_data = DATA.all_vip_players[player_id]
	if vip_data then
		---- 如果天数超过上限了
		if vip_data.vip_day_time + day_num > DATA.vip_common_config.max_day then
			PUBLIC.off_action_lock( "buy_vip" , player_id )
			return 4001
		end

		if vip_data.vip_time > now_time then
			vip_data.vip_time = vip_data.vip_time + total_seconds    
		else
			vip_data.vip_time = now_time + total_seconds
		end
		vip_data.vip_day_time = vip_data.vip_day_time + day_num

		-- 	
		if not DATA.working_vip_players[player_id] then
			--- vip已经过期的用户
			DATA.working_vip_players[player_id] = vip_data
		end

		--- 更新一下
		updata_or_add_player_vip(vip_data)
	else
		DATA.all_vip_players[player_id] = {
			player_id = player_id,
			vip_time = now_time + total_seconds,
			vip_day_time = day_num,
		}

		--- 组织额外数据
		load_vip_extend_data(DATA.all_vip_players[player_id])

		vip_data = DATA.all_vip_players[player_id]

		DATA.working_vip_players[player_id] = vip_data
		--- 没有就要新增
		updata_or_add_player_vip(vip_data)
		
	end

	---- 清掉 延迟处理缓存
	if DATA.delay_kill_working_vip_vec[player_id] then
		DATA.delay_kill_working_vip_vec[player_id] = nil
	end


	-- 推送消息
	nodefunc.send(player_id,"notify_vip_change_msg", CMD.query_vip_data(player_id) )

	--- 分发任务 ， 这个一定在 notify_vip_change_msg 之后
	nodefunc.send(player_id,"distribute_task" )

	--- 发送购买时的奖励金币
	nodefunc.send(player_id,"change_asset_multi", { {asset_type = PLAYER_ASSET_TYPES.JING_BI ,value = config_data.gift_gold} },ASSET_CHANGE_TYPE.BUY_VIP_GIFT,0)

	--- 检查并增加推广的数据
	vip_generalize.check_add_generalize_data(player_id)

	---- 记录一下购买记录
	vip_generalize.add_player_vip_buy_record( player_id , vip_data.parent_id , payback_value , day_num , now_time )

	--- 给父节点加推广费
	vip_generalize.add_award_value(vip_data.parent_id,payback_value)


	

	-- 广播
	skynet.send(DATA.service_config.broadcast_center_service,"lua"
						,"fixed_broadcast"
						,"vip_activate"
						,DATA.all_vip_players[player_id].name)

	PUBLIC.off_action_lock( "buy_vip" , player_id )

	return 0
end


-- 检测购买
function CMD.check_buy_vip( player_id , buy_class )

	local config_data = DATA.vip_buy_config[buy_class]

	if not config_data then
		error("-------------- buy_vip no config_data ------------")
		return false
	end

	local day_num = config_data.vip_day
	local payback_value = config_data.payback

	local total_seconds = day_num * 86400 --- 86400 一天的秒数
	local now_time = os.time()

	local vip_data = DATA.all_vip_players[player_id]
	if vip_data then
		---- 如果天数超过上限了
		if vip_data.vip_day_time + day_num > DATA.vip_common_config.max_day then
			return false
		end

	end

	return true
end

---- 查询vip数据
function CMD.query_vip_data(player_id)
	local ret = { status = 0,vip = 0 }

	if DATA.all_vip_players[player_id] then
		ret.status = 2
	end

	if DATA.working_vip_players[player_id] then
		ret.status = 1
		ret.vip = DATA.all_vip_players[player_id].vip_day_time
	end

	return ret
end


function CMD.reload_config()
	load_config()
	return 0
end

--- 获取重置时间
function CMD.get_rest_time()
	return DATA.REST_TIME
end

----
function PUBLIC.add_record_cache( cache_table )
	DATA.all_record_cache[#DATA.all_record_cache+1] = cache_table
end

----- 获取记录
function PUBLIC.get_record_with_cache( cache_table , ob_cmd , player_id , page_index , page_item_num )
	local ret = {}

	local record_data = cache_table[player_id]
	if not record_data then
		cache_table[player_id] = {}
		record_data = cache_table[player_id] 

		record_data.clear_delay = DATA.cache_clear_delay
		record_data.dynamic_insert_num = 0
		record_data.data = {}
	else
		record_data.clear_delay = DATA.cache_clear_delay
	end

	--- 第一页要从头开始取，其他页要加上新加数据的偏移
	if page_index == 1 then
		record_data.dynamic_insert_num = 0
	end

	----

	local get_record_data = function(is_force_get)
		if is_force_get or #record_data.data >= page_index*page_item_num + record_data.dynamic_insert_num then
			for i=(page_index-1)*page_item_num + record_data.dynamic_insert_num  ,  page_index*page_item_num + record_data.dynamic_insert_num do
				if record_data.data[i] then
					ret[#ret+1] = record_data.data[i]
				end
			end
			
			return true
		end
		return false
	end

	---- 先用缓存数据
	if get_record_data() then
		return ret
	end

	--- 
	local now_have_more_num = 0
	if #record_data.data > (page_index-1)*page_item_num + record_data.dynamic_insert_num then
		now_have_more_num = #record_data.data - (page_index-1)*page_item_num + record_data.dynamic_insert_num
	end

	local ob_data = skynet.call(DATA.service_config.data_service,"lua", ob_cmd , player_id , page_index , page_item_num , record_data.dynamic_insert_num + now_have_more_num) 
	if ob_data then
		for key,value in ipairs(ob_data) do
			print( string.format(">>>>>> --- get_record_with_cache,cmd:%s",ob_cmd  ))
			--ret[#ret+1] = value
			local next_index = #record_data.data + 1
			record_data.data[next_index] = value

			----- 额外增加值
			if DATA.payback_record_cache == cache_table then
				record_data.data[next_index].player_name = value.name
			end
		end
	else
		return error_map[ob_cmd]
	end

	---- 拿到新数据后，再收集一次,强制收集，避免数据数量不足
	get_record_data(true)

	return ret

end

---- 获取一个玩家的vip剩余天数
function CMD.get_player_vip_day(player_id)
	if DATA.all_vip_players[player_id] then
		return DATA.all_vip_players[player_id].vip_day_time
	end
	return 0
end

function CMD.start(_service_config)
	DATA.service_config = _service_config
	
	load_config()

	load_vip_data()

	vip_reward_task.init()
	vip_generalize.init()

	

	DATA.reset_queue=basefunc.queue.new()

	---- 下一次重置需要等待的时间
    local next_reset_wait = basefunc.get_diff_target_time(DATA.REST_TIME)

    if next_reset_wait==0 then 
		next_reset_wait=1
	end 
	skynet.timeout(next_reset_wait * 100, function() 
		reset_data()
	end)

	---- update
	skynet.timer( update_dt ,update)

	skynet.timer( clear_update_dt , clear_update)


end

-- 启动服务
base.start_service()
