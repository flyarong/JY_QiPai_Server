--
-- Author: wss
-- Date: 2018/11/16
-- Time: 16:32
-- 说明：vip 推广 的管理
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

--- 回报记录的缓存, key = player_id , value = { clear_delay = nn , dynamic_insert_num = nn , data }
--- clear_delay 多少秒后清理缓存，dynamic_insert_num 动态插入的个数, data 数据
DATA.payback_record_cache = {}

--- FL统计的缓存,key = player_id , years = {yearValue = { value = xx, months = { monthValue ={ value = xx , days = {}} } } }
DATA.packback_statistics_cache = {}

--- 领取记录缓存
DATA.generalize_extract_record_cache = {}

--- 下级数据缓存, key = player_id , value = { clear_delay = nn , dynamic_insert_num = nn , data = { [1] = x_player_id } }
DATA.generalize_children_cache = {}

local PROTECT = {}



--- 所有的推广奖励
DATA.generalize_data = nil

local load_ob_data = function()
	DATA.generalize_data = skynet.call(DATA.service_config.data_service,"lua","query_all_generalize_data")
	if not DATA.generalize_data then
		error("load_generalize_data --- query_all_generalize_data , get DATA.generalize_data error !")
	end
end
	
local updata_or_add_data = function(data)
	--- 没有就要新增
	skynet.send(DATA.service_config.data_service,"lua","update_or_add_player_vip_generalize"
					,data.player_id
					,data.award_value
					,data.today_get_award
					,data.last_get_time
					,data.total_award_value)
end

---- 新增提取记录
local function add_generalize_extract_record(player_id , extract_value , extract_time)
	skynet.send(DATA.service_config.data_service,"lua","add_player_vip_generalize_extract_record"
					,player_id
					,extract_value
					,extract_time)

	--- 每次加记录，如果已经有缓存了，要加入一条
	local record_data = DATA.generalize_extract_record_cache[player_id]
	if record_data and record_data.data
		and record_data.clear_delay > 0 and #record_data.data > 0 then
		
		local data = {}
		data.player_id = player_id
		data.extract_value = extract_value
		data.extract_time = extract_time

		table.insert(record_data.data , 1 , data)
		record_data.dynamic_insert_num = record_data.dynamic_insert_num + 1
	end

end

--- 增加推广奖励值
function PROTECT.add_award_value(player_id,value)
	local data = DATA.generalize_data[player_id]
	if data then
		data.award_value = data.award_value + value
		data.total_award_value = data.total_award_value + value

		updata_or_add_data(data)
		nodefunc.send(player_id,"generalize_award_change_msg", data.award_value , data.total_award_value )
	end
end

--- 检查并新增推广的数据
function PROTECT.check_add_generalize_data(player_id)
	local data = DATA.generalize_data[player_id]
	if not data then
		DATA.generalize_data[player_id] = {}
		data = DATA.generalize_data[player_id]
		local now_time = os.time()
		data.player_id = player_id
		data.award_value = 0
		data.today_get_award = 0
		data.last_get_time = now_time
		data.total_award_value = 0
	
		updata_or_add_data(data)
	end

end

--- 增加一条玩家购买vip的记录
function PROTECT.add_player_vip_buy_record(player_id , payback_player_id , payback_value , buy_vip_day , buy_time )
	local buy_id = skynet.call(DATA.service_config.data_service,"lua","add_player_vip_buy_record"
					,player_id
					,payback_player_id or ""
					,payback_value
					,buy_vip_day
					,buy_time)

	
	--- 每次加记录，如果已经有缓存了，要加入一条
	local record_data = DATA.payback_record_cache[player_id]
	if record_data and record_data.data
		and record_data.clear_delay > 0 and #record_data.data > 0 then
		
		local data = {}
		data.player_id = player_id
		data.payback_player_id = payback_player_id
		data.payback_value = payback_value
		data.buy_vip_day = buy_vip_day
		data.buy_time = buy_time
		data.player_name = DATA.all_vip_players[player_id].name

		table.insert(record_data.data , 1 , data)
		record_data.dynamic_insert_num = record_data.dynamic_insert_num + 1
	end

	--- 统计缓存值更新
	local buy_time_data=os.date("*t",buy_time)
	local data = DATA.packback_statistics_cache[payback_player_id]
	if data and data.years then
		data.years[buy_time_data.year] = data.years[buy_time_data.year] or {}
		data = data.years[buy_time_data.year]
		data.months = data.months or {}
		data.value = data.value or 0
		data.value = data.value + payback_value

		data.months[buy_time_data.month] = data.months[buy_time_data.month] or {}
		data = data.months[buy_time_data.month]
		data.days = data.days or {}
		data.value = data.value or 0
		data.value = data.value + payback_value
		
		data.days[buy_time_data.day] = data.days[buy_time_data.day] or {}
		data = data.days[buy_time_data.day]
		data.value = data.value or 0
		data.value = data.value + payback_value

	end

	---- 看是否有 下级 缓存数据
	local cache_data = DATA.generalize_children_cache[payback_player_id]
	if cache_data and cache_data.data then
		---- 看有没有自己
		local is_find_myself = false
		for key,cache_id in ipairs(cache_data.data) do
			if cache_id == player_id then
				is_find_myself = true
				break
			end
		end

		if not is_find_myself then
			for key,cache_id in ipairs(cache_data.data) do
				if DATA.all_vip_players[player_id].vip_day_time < DATA.all_vip_players[cache_id].vip_day_time then
					table.insert( cache_data.data , key , player_id )
					break
				end
				if DATA.all_vip_players[player_id].vip_day_time == DATA.all_vip_players[cache_id].vip_day_time and player_id < cache_id then
					table.insert( cache_data.data , key , player_id )
					break
				end
			end
		end
	end

end


--- 查询我的推广
function CMD.query_generalize_award(player_id)
	if not DATA.generalize_data[player_id] then
		return 0,0
	end

	return DATA.generalize_data[player_id].award_value , DATA.generalize_data[player_id].total_award_value
end

--- 获得返奖记录,
--[[
	player_id 玩家id
	page_index 页面的索引
	page_item_num 页面显示个数
]]
function CMD.get_player_vip_payback_record( player_id , page_index , page_item_num )
	
	return PUBLIC.get_record_with_cache( DATA.payback_record_cache , "get_player_vip_payback_record" , player_id , page_index , page_item_num )
end

--- 领取推广奖励
function CMD.get_generalize_award(player_id )
	--- 操作限制
	if PUBLIC.get_action_lock( "get_generalize_award" , player_id ) then
		return 1008
	end
	PUBLIC.on_action_lock( "get_generalize_award" , player_id )

	---- 只有vip用户才能领取奖励
	if not DATA.working_vip_players[player_id] then
		PUBLIC.off_action_lock( "get_generalize_award" , player_id )
		return 4005
	end

	local data = DATA.generalize_data[player_id]
	assert( data , "func:get_generalize_award , must have data!" )

	local get_value = data.award_value
	if get_value > DATA.vip_common_config.payback_every_limit then
		get_value = DATA.vip_common_config.payback_every_limit
	end

	---保证钱够
	if data.award_value < get_value then
		PUBLIC.off_action_lock( "get_generalize_award" , player_id )
		return 4002
	end

	local now_time = os.time()
	local is_same_day = basefunc.is_same_day( now_time , data.last_get_time , DATA.REST_TIME )
	---- 同一天限制上限
	if is_same_day then --if now_time_day == last_get_time_day then
		if data.today_get_award + get_value > DATA.vip_common_config.payback_day_limit then
			PUBLIC.off_action_lock( "get_generalize_award" , player_id )
			return 4003
		end
	else
		data.today_get_award = 0
		if data.today_get_award + get_value > DATA.vip_common_config.payback_day_limit then
			PUBLIC.off_action_lock( "get_generalize_award" , player_id )
			return 4003
		end
	end

	data.award_value = data.award_value - get_value
	data.today_get_award = data.today_get_award + get_value
	data.last_get_time = now_time

	updata_or_add_data(data)

	--------- 发wx奖励 --------
	

	--- 记录
	add_generalize_extract_record( player_id , get_value , now_time )

	PUBLIC.off_action_lock( "get_generalize_award" , player_id )

	return 0,data.award_value
end

---- 获得 推广领取记录
function CMD.get_generalize_extract_record( player_id , page_index , page_item_num )
	return PUBLIC.get_record_with_cache( DATA.generalize_extract_record_cache , "get_player_vip_generalize_extract_record" , player_id , page_index , page_item_num )
end

--- 获取玩家的推广下级
function CMD.get_generalize_children(player_id , page_index , page_item_num)
	local record_data = DATA.generalize_children_cache[player_id] 

	if not record_data then
		DATA.generalize_children_cache[player_id] = {}
		record_data = DATA.generalize_children_cache[player_id]
		record_data.clear_delay = DATA.cache_clear_delay
		record_data.dynamic_insert_num = 0
		record_data.data = {}

		---- 没有就从服务器拿,全部拿出来
		record_data.data = skynet.call(DATA.service_config.data_service,"lua","get_generalize_children" , player_id)

		-- 排序,按剩余vip天数的降序排，相同按id排
		table.sort( record_data.data , function(id_a , id_b)

			local sort_by_day = false
			local sort_by_id = false

			if not DATA.all_vip_players[id_a] and DATA.all_vip_players[id_b] then
				return false
			end
			if not DATA.all_vip_players[id_b] and DATA.all_vip_players[id_a] then
				return true
			end

			if not DATA.all_vip_players[id_a] and not DATA.all_vip_players[id_b] then
				sort_by_day = false
				sort_by_id = true
			end

			if DATA.all_vip_players[id_a] and DATA.all_vip_players[id_b] then
				sort_by_day = true
				sort_by_id = false
				if DATA.all_vip_players[id_a].vip_day_time == DATA.all_vip_players[id_b].vip_day_time then
					sort_by_day = false
					sort_by_id = true
				end
			end

			if sort_by_day then
				return DATA.all_vip_players[id_a].vip_day_time < DATA.all_vip_players[id_b].vip_day_time
			end

			if sort_by_id then
				return tonumber(id_a) < tonumber(id_b)
			end

		end)

		--dump(record_data.data , "------------- record_data.data >>>>  sort: ")
	end

	local ret = {}
	---- 发-1 就全部返回
	if page_index == -1 and page_item_num == -1 then
		for i=1  , #record_data.data do
			ret[#ret+1] = DATA.all_vip_players[ record_data.data[i] ] or { player_id = record_data.data[i] , name = "test_name" }    -- 这个or用来做测试的，之后删掉
		end
	else
		if #record_data.data >= page_index*page_item_num + record_data.dynamic_insert_num then
			for i=(page_index-1)*page_item_num + record_data.dynamic_insert_num  ,  page_index*page_item_num + record_data.dynamic_insert_num do
				if record_data.data[i] then
					ret[#ret+1] = DATA.all_vip_players[ record_data.data[i] ] or { player_id = record_data.data[i] , name = "test_name" }    -- 这个or用来做测试的，之后删掉
				end
			end
		end
	end

	return ret
end

---- 获取 获得FL奖励的统计 — 年
function CMD.get_vip_payback_statistics_year( player_id , is_not_return)
	local data = DATA.packback_statistics_cache[player_id]
	if not data then
		DATA.packback_statistics_cache[player_id] = {}
		data = DATA.packback_statistics_cache[player_id]
		data.years = {}

		local year_statistics = skynet.call(DATA.service_config.data_service,"lua","get_player_vip_payback_statistics_year",player_id)
		if not year_statistics then
			return false
		end

		for key,row in ipairs(year_statistics) do
			data.years[row._year] = {}
			data.years[row._year].value = row.total
		end

	end

	if not is_not_return then
		local ret = {}
		for year,data in pairs(data.years) do
			ret[year] = data.value
		end

		return ret
	end
end

---- 获取 获得FL奖励的统计 — 一年所有月
function CMD.get_vip_payback_statistics_month(player_id,year,is_not_return)
	CMD.get_vip_payback_statistics_year(player_id , true)

	local data = DATA.packback_statistics_cache[player_id]


	if not data.years[year] then
		data.years[year] = {}
	end

	if not data.years[year].months then
		data.years[year].months = {}

		local month_statistics = skynet.call(DATA.service_config.data_service,"lua","get_player_vip_payback_statistics_month",player_id,year)
		
		if not month_statistics then
			return false
		end
		for key,row in ipairs(month_statistics) do
			data.years[year].months[row._month] = {}
			data.years[year].months[row._month].value = row.total
		end
	end

	if not is_not_return then
		local ret = {}
		for month,data in pairs(data.years[year].months) do
			ret[month] = data.value
		end

		return ret
	end
end

---- 获取 获得FL奖励的统计 — 一年某月所有天
function CMD.get_vip_payback_statistics_day(player_id,year,month)
	
	CMD.get_vip_payback_statistics_month(player_id,year,true)

	local data = DATA.packback_statistics_cache[player_id]

	if not data.years[year].months[month].days then
		data.years[year].months[month].days = {}
		local day_data = data.years[year].months[month].days

		local day_statistics = skynet.call(DATA.service_config.data_service,"lua","get_player_vip_payback_statistics_day",player_id,year,month)
		
		if not day_statistics then
			return false
		end
		
		for key,row in ipairs(day_statistics) do
			day_data[row._day] = {}
			day_data[row._day].value = row.total
		end
	end

	local ret = {}
	for day,data in pairs(data.years[year].months[month].days) do
		ret[day] = data.value
	end

	return ret
end

----- 额外的查询，直接查所有的天  ！！
function CMD.get_vip_payback_statistics_all_day(player_id)
	local data = DATA.packback_statistics_cache[player_id]
	if not data then
		DATA.packback_statistics_cache[player_id] = {}
		data = DATA.packback_statistics_cache[player_id]
		data.clear_delay = DATA.cache_clear_delay
		data.dynamic_insert_num = 0
		data.years = {}

		local all_day_statistics = skynet.call(DATA.service_config.data_service,"lua","get_player_vip_payback_statistics_all_day",player_id)
		--dump(all_day_statistics , "<<>>>>>> get_vip_payback_statistics_all_day:")
		if not all_day_statistics then
			return false
		end

		for key,statis_data in ipairs(all_day_statistics) do
			if not data.years[statis_data._year] then
				data.years[statis_data._year] = {}
				data.years[statis_data._year].value = 0
				data.years[statis_data._year].months = {}
			end
			data.years[statis_data._year].value = data.years[statis_data._year].value + statis_data.total

			if not data.years[statis_data._year].months[statis_data._month] then
				data.years[statis_data._year].months[statis_data._month] = {}
				data.years[statis_data._year].months[statis_data._month].value = 0
				data.years[statis_data._year].months[statis_data._month].days = {}
			end
			data.years[statis_data._year].months[statis_data._month].value = data.years[statis_data._year].months[statis_data._month].value + statis_data.total
			
			if not data.years[statis_data._year].months[statis_data._month].days[statis_data._day] then
				data.years[statis_data._year].months[statis_data._month].days[statis_data._day] = {}
				data.years[statis_data._year].months[statis_data._month].days[statis_data._day].value = 0
			end

			data.years[statis_data._year].months[statis_data._month].days[statis_data._day].value = statis_data.total
		end

	end


	return data
end

function PROTECT.init()
	load_ob_data()

	PUBLIC.add_record_cache( DATA.generalize_extract_record_cache )
	PUBLIC.add_record_cache( DATA.payback_record_cache )
	PUBLIC.add_record_cache( DATA.packback_statistics_cache )
	PUBLIC.add_record_cache( DATA.generalize_children_cache )


end

return PROTECT