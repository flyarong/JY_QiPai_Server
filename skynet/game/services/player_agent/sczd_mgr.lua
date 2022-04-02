---- 生财之道agent | 合伙人的agent 

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local task_initer = require "task.init"

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST
local PUBLIC = base.PUBLIC

local PROTECT = {}

PROTECT.sort_type = {
	gx_asc = 1,        -- 贡献升序
	gx_desc = 2,       -- 贡献降序
	register_time_asc = 3,     -- 注册时间升序，第一个是最老注册
	register_time_desc = 4,    -- 注册时间降序，第一个是最新注册
	last_gx_time_asc = 5,      -- 最新贡献时间升序，第一个时间是最老的
	last_gx_time_desc = 6,     -- 最新贡献时间降序，第一个时间是最新的
}


--- 缓存失效的时间,单位秒
DATA.cache_past_time = 300   -- 300    --- 正式为5分钟   --- 10       -- test

--- 返回每页记录的数量
DATA.page_num = 20

---- 默认为 贡献升序，第一个贡献最小
DATA.my_son_main_info_sort_type = PROTECT.sort_type.last_gx_time_desc

--- 缓存我的son的main数据,key = my_id , value = { last_get_time = xxx , data = xxx }
DATA.my_son_main_info_cache = DATA.my_son_main_info_cache or {}


--- 缓存我的son的贡献的详细缓存 ,key = son_id , value = { last_get_time = xxx , base_info = xxx , details_info = xxx }
DATA.my_son_contribute_cache = DATA.my_son_contribute_cache or {}

--- 我的收入的明细缓存,key = my_id , value = { last_get_time = xxx , data = xxx }
DATA.my_income_details_cache = DATA.my_income_details_cache or {}

--- 我的提现记录缓存
DATA.my_extrace_details_cache = DATA.my_extrace_details_cache or {}

---- 从中心服务获取我的所有的son的main信息
function PROTECT.load_all_my_son_main_info()
	local now_time = os.time()

	DATA.my_son_main_info_cache[DATA.my_id] = DATA.my_son_main_info_cache[DATA.my_id] or {}
	DATA.my_son_main_info_cache[DATA.my_id].last_get_time = now_time

	local all_main_info = skynet.call(DATA.service_config.sczd_center_service,"lua","get_player_all_son_data" , DATA.my_id) 
	if type(all_main_info) == "number" then
		return all_main_info
	end
	dump( all_main_info , "----->>> load_all_my_son_main_info:" )
	DATA.my_son_main_info_cache[DATA.my_id].data = all_main_info

	--- 载入数据后，排一次序
	PROTECT.sort_all_my_son_main_info()

end

---- 排序
function PROTECT.sort_all_my_son_main_info()
	assert(DATA.my_son_main_info_cache[DATA.my_id] and DATA.my_son_main_info_cache[DATA.my_id].data , "sort_all_my_son_main_info must have data")

	local function sort_by_gx(data_a , data_b)
		if data_a.my_all_gx < data_b.my_all_gx then
			return true
		elseif data_a.my_all_gx == data_b.my_all_gx then
			return data_a.register_time > data_b.register_time
		else
			return false
		end
	end

	local function sort_by_register_time(data_a , data_b)
		if data_a.register_time > data_b.register_time then
			return true
		elseif data_a.register_time == data_b.register_time then
			return data_a.my_all_gx < data_b.my_all_gx
		else
			return false
		end
	end

	local function sort_by_last_gx_time(data_a , data_b)
		--- 最新根据贡献时间来排序
		if data_a.last_gx_time > data_b.last_gx_time then
			return true
		else
			return false
		end

	end

	if DATA.my_son_main_info_sort_type == PROTECT.sort_type.gx_asc or DATA.my_son_main_info_sort_type == PROTECT.sort_type.gx_desc then
		table.sort( DATA.my_son_main_info_cache[DATA.my_id].data , sort_by_gx )
	end

	if DATA.my_son_main_info_sort_type == PROTECT.sort_type.register_time_asc or DATA.my_son_main_info_sort_type == PROTECT.sort_type.register_time_desc then
		table.sort( DATA.my_son_main_info_cache[DATA.my_id].data , sort_by_register_time )
	end

	if DATA.my_son_main_info_sort_type == PROTECT.sort_type.last_gx_time_asc or DATA.my_son_main_info_sort_type == PROTECT.sort_type.last_gx_time_desc then
		table.sort( DATA.my_son_main_info_cache[DATA.my_id].data , sort_by_last_gx_time )
	end

	--dump(DATA.my_son_main_info_cache[DATA.my_id].data , "--------------after sort , load_all_my_son_main_info")
end

--- 请求我自己的生财之道的基本信息
function REQUEST.get_player_sczd_base_info()
	local ret = {}
	local my_base_info = skynet.call(DATA.service_config.sczd_center_service,"lua","get_base_info" , DATA.my_id)

	if type(my_base_info) == "number" then
		ret.result = my_base_info
		return ret
	end

	ret.result = 0

	ret.is_activate_bbsc_profit = my_base_info.is_activate_bbsc_profit
	ret.is_activate_xj_profit = my_base_info.is_activate_xj_profit
	ret.is_activate_tglb_profit = my_base_info.is_activate_tglb_profit
	ret.is_activate_tglb_cache = my_base_info.is_activate_tglb_cache
	ret.is_activate_bisai_profit = my_base_info.is_activate_bisai_profit

	ret.is_activate_gjhhr = my_base_info.gjhhr_status == "nor" and 1 or 0

	ret.my_get_award = my_base_info.total_get_award

	--- 如果有缓存，和缓存 保持一致
	if DATA.my_son_main_info_cache[DATA.my_id] and DATA.my_son_main_info_cache[DATA.my_id].data then
		ret.my_all_son_count = #DATA.my_son_main_info_cache[DATA.my_id].data  
	else
		ret.my_all_son_count = my_base_info.all_son_count
	end

	ret.goldpig_profit_cache = my_base_info.goldpig_profit_cache

	return ret
end

--- 请求我所有的son的main信息
function REQUEST.query_my_son_main_info( self )
	local now_time = os.time()
	local target_page_index = self.page_index
	local ret = {}
	ret.result = 0
	if not self.sort_type or not self.page_index or type(self.sort_type) ~= "number" or type(self.page_index) ~= "number" then
		ret.result = 1001
		return ret
	end

	ret.is_clear_old_data = 0
	ret.son_main_infos = {}

	--- 如果没有，或者请求第一页的时候时间失效，重新获取
	if not DATA.my_son_main_info_cache[DATA.my_id] or (self.page_index == 1 and now_time - DATA.my_son_main_info_cache[DATA.my_id].last_get_time > DATA.cache_past_time) then
		local error_code = PROTECT.load_all_my_son_main_info()
		if error_code then
			ret.result = error_code
			return ret
		end
		ret.is_clear_old_data = 1
	end

	--- 是否重排序
	if self.sort_type ~= DATA.my_son_main_info_sort_type then
		-- DATA.my_son_main_info_sort_type = self.sort_type
		--- 暂时强行改成按最新贡献时间排序
		DATA.my_son_main_info_sort_type = PROTECT.sort_type.last_gx_time_desc


		PROTECT.sort_all_my_son_main_info()
		target_page_index = 1
		ret.is_clear_old_data = 1
	end

	---- 升序 or 降序
	local data_length = #DATA.my_son_main_info_cache[DATA.my_id].data

	local start_index = (target_page_index-1) * DATA.page_num + 1
	local for_offset = 1
	if DATA.my_son_main_info_sort_type == PROTECT.sort_type.gx_desc or DATA.my_son_main_info_sort_type == PROTECT.sort_type.register_time_desc
			or DATA.my_son_main_info_sort_type == PROTECT.sort_type.last_gx_time_asc then
		start_index = data_length - (target_page_index-1) * DATA.page_num
		for_offset = -1
	end

	local is_can_get_data = true
	if start_index < 0 or start_index > data_length then
		is_can_get_data = false
	end

	if is_can_get_data then
		local end_index = start_index + for_offset * DATA.page_num - for_offset * 1

		if end_index < 0 then
			end_index = 0
		end
		if end_index > data_length then
			end_index = data_length
		end

	    for i = start_index,end_index,for_offset do
	    	local data = DATA.my_son_main_info_cache[DATA.my_id].data[i]

	    	ret.son_main_infos[#ret.son_main_infos + 1] = {
	    		id = data.id,
				name = data.name,
				is_have_login = data.logined,
			    my_all_gx = data.my_all_gx,
			    m_register_time = data.register_time,
			    last_login_time = data.last_login_time,
	    	}
	    end
	end

	return ret
end

function PROTECT.load_son_contribute_info(son_id)
	local now_time = os.time()
	DATA.my_son_contribute_cache[son_id] = DATA.my_son_contribute_cache[son_id] or {}
	DATA.my_son_contribute_cache[son_id].last_get_time = now_time
	
	local all_main_info = skynet.call(DATA.service_config.sczd_center_service,"lua","get_son_details" , son_id) 

	if type(all_main_info) == "number" then
		return all_main_info
	end

	DATA.my_son_contribute_cache[son_id].base_info = all_main_info
	DATA.my_son_contribute_cache[son_id].details_info = nil
end

--- 载入一个son的具体的贡献数据
function PROTECT.load_son_contribute_details_info(son_id)
	local cache_data = DATA.my_son_contribute_cache[son_id]
	local data = skynet.call(DATA.service_config.sczd_center_service,"lua","get_son_contribute_details" , son_id)

	if type(data) == "number" then
		return data
	end

	cache_data.details_info = data

	--- 按时间降序排列
	table.sort( cache_data.details_info , function(data_a , data_b) 
		return data_a.time > data_b.time
	end)

end


---- 获取我的son的 基本贡献数据
function REQUEST.query_son_base_contribute_info( self )
	local ret = {}
	ret.result = 0
	if not self.son_id or type(self.son_id) ~= "string" then
		ret.result = 1001
		return ret
	end

	local now_time = os.time()
	
	local cache_data = DATA.my_son_contribute_cache[self.son_id]
	--- 如果没有,或没有详情贡献数据，或时间过期，重新获得
	if not cache_data or not cache_data.details_info or now_time - cache_data.last_get_time > DATA.cache_past_time then
		local error_code = PROTECT.load_son_contribute_info(self.son_id)
		if error_code then
			ret.result = error_code
			return ret
		end

		cache_data = DATA.my_son_contribute_cache[self.son_id]
	end

	local my_base_info = cache_data.base_info

	--ret.my_is_buy_tgli = my_base_info.my_is_buy_tgli
	ret.son_id = self.son_id
	ret.son_tgli_gx = my_base_info.my_tgli_gx
	ret.son_bbsc_gx = my_base_info.my_bbsc_gx
	ret.son_vip_lb_gx = my_base_info.my_vip_lb_gx
	ret.son_bbsc_progress = my_base_info.my_bbsc_progress

	return ret
end

--- 获取我的son的 具体的贡献数据
function REQUEST.query_son_details_contribute_info( self )
	local ret = {}
	ret.result = 0

	if not self.page_index or type(self.page_index) ~= "number" or not self.son_id or type(self.son_id) ~= "string" then
		ret.result = 1001
		return ret
	end
	
	if not DATA.my_son_contribute_cache[self.son_id] then
		ret.result = 1004
		return ret
	end

	ret.son_id = self.son_id
	ret.detail_infos = {}

	local now_time = os.time()
	
	local cache_data = DATA.my_son_contribute_cache[self.son_id]
	--- 如果没有，或者请求第一页的时候时间失效，重新获取
	if not cache_data.details_info then
		local error_code = PROTECT.load_son_contribute_details_info(self.son_id)
		if error_code then
			ret.result = error_code
			return ret
		end
	end

	if cache_data and type(cache_data)=="table" and cache_data.details_info then
		local data_length = #cache_data.details_info
		--- 取数据
		local start_index = (self.page_index-1)*DATA.page_num + 1
		

		local is_can_get_data = true
		if start_index < 0 or start_index > data_length then
			is_can_get_data = false
		end

		if is_can_get_data then
			local end_index = start_index + DATA.page_num - 1
			
			if end_index < 0 then
				end_index = 0
			end
			if end_index > data_length then
				end_index = data_length
			end

			for i = start_index , end_index do
				ret.detail_infos[#ret.detail_infos + 1] = {
					id = DATA.my_id,
					name = DATA.player_data.player_info.name,
					treasure_type = cache_data.details_info[i].treasure_type,
				    treasure_value = cache_data.details_info[i].treasure_value,
				    time = cache_data.details_info[i].time,
				    is_active = cache_data.details_info[i].is_active,
				}

			end
		end

	end

	return ret
end


function PROTECT.load_my_income_details()
	DATA.my_income_details_cache[DATA.my_id] = DATA.my_income_details_cache[DATA.my_id] or {}
	DATA.my_income_details_cache[DATA.my_id].last_get_time = os.time()
	local income_data = skynet.call(DATA.service_config.sczd_center_service,"lua","get_my_income_details" , DATA.my_id)

	if type(income_data) == "number" then
		return income_data
	end

	DATA.my_income_details_cache[DATA.my_id].data = income_data

	table.sort( DATA.my_income_details_cache[DATA.my_id].data , function(data_a , data_b)
		return data_a.time > data_b.time
	end )

end

--- 获取我的收入记录
function REQUEST.query_my_sczd_income_details(self)
	local ret = {}
	ret.result = 0

	if not self.page_index or type(self.page_index) ~= "number" then
		ret.result = 1001
		return ret
	end

	ret.detail_infos = {}

	local now_time = os.time()
	local cache_data = DATA.my_income_details_cache[DATA.my_id]
	--- 如果没有，或者请求第一页时过期
	if not cache_data or (self.page_index == 1 and now_time - cache_data.last_get_time > DATA.cache_past_time) then
		local error_code = PROTECT.load_my_income_details()
		if error_code then
			ret.result = error_code
			return ret
		end
		cache_data = DATA.my_income_details_cache[DATA.my_id]
	end
	if cache_data and type(cache_data)=="table" and cache_data.data then
		--- 读取数据
		local data_length = #cache_data.data
		--- 取数据
		local start_index = (self.page_index-1)*DATA.page_num + 1
		

		local is_can_get_data = true
		if start_index < 0 or start_index > data_length then
			is_can_get_data = false
		end

		if is_can_get_data then
			local end_index = start_index + DATA.page_num - 1
			if end_index < 0 then
				end_index = 0
			end
			if end_index > data_length then
				end_index = data_length
			end

			for i = start_index , end_index do
				ret.detail_infos[#ret.detail_infos + 1] = {
					id = cache_data.data[i].player_id,
					name = cache_data.data[i].name,
					treasure_type = cache_data.data[i].treasure_type,
				    treasure_value = cache_data.data[i].treasure_value,
				    time = cache_data.data[i].time,
				    is_active = cache_data.data[i].is_active,
				}

			end
		end
	end

	return ret
end

function PROTECT.load_my_extract_details()
	DATA.my_extrace_details_cache[DATA.my_id] = DATA.my_extrace_details_cache[DATA.my_id] or {}

	DATA.my_extrace_details_cache[DATA.my_id].last_get_time = os.time()
	local extract_data = skynet.call(DATA.service_config.sczd_center_service,"lua","get_my_spending_details" , DATA.my_id)

	if type(extract_data) == "number" then
		return extract_data
	end

	DATA.my_extrace_details_cache[DATA.my_id].data = extract_data

	table.sort( DATA.my_extrace_details_cache[DATA.my_id].data , function(data_a , data_b)
		return data_a.spending_time > data_b.spending_time
	end )
end

--- 获取我的提现记录
function REQUEST.query_my_sczd_spending_details(self)
	local ret = {}
	ret.result = 0

	if not self.page_index or type(self.page_index) ~= "number" then
		ret.result = 1001
		return ret
	end

	ret.extract_infos = {}
	local now_time = os.time()
	local cache_data = DATA.my_extrace_details_cache[DATA.my_id]
	--- 如果没有，或者请求第一页时过期
	if not cache_data or (self.page_index == 1 and now_time - cache_data.last_get_time > DATA.cache_past_time) then
		local error_code = PROTECT.load_my_extract_details()
		if error_code then
			ret.result = error_code
			return ret
		end

		cache_data = DATA.my_extrace_details_cache[DATA.my_id]
	end
	
	if cache_data and type(cache_data)=="table" and cache_data.data then
		--- 读取数据
		local data_length = #cache_data.data
		--- 取数据
		local start_index = (self.page_index-1)*DATA.page_num + 1
		

		local is_can_get_data = true
		if start_index < 0 or start_index > data_length then
			is_can_get_data = false
		end

		if is_can_get_data then
			local end_index = start_index + DATA.page_num - 1
			if end_index < 0 then
				end_index = 0
			end
			if end_index > data_length then
				end_index = data_length
			end

			for i = start_index , end_index do
				ret.extract_infos[#ret.extract_infos + 1] = {
					id = i,
					extract_value = cache_data.data[i].spending_value,
					extract_time = cache_data.data[i].spending_time,
				}

			end
		end

	end

	return ret

end

---- 搜索某个son的信息
function REQUEST.search_son_by_id(self)
	local ret = {}
	ret.result = 0

	if not self.id or type(self.id) ~= "string" then
		ret.result = 1001
		return ret
	end

	if not DATA.my_son_main_info_cache[DATA.my_id] or not DATA.my_son_main_info_cache[DATA.my_id].data then
		ret.result = 1004
		return ret
	end

	ret.son_info = {}
	for key,data in pairs(DATA.my_son_main_info_cache[DATA.my_id].data) do
		if data.id == self.id then
			ret.son_info.id = data.id
			ret.son_info.name = data.name
			ret.son_info.is_have_login = data.logined
			ret.son_info.my_all_gx = data.my_all_gx
			ret.son_info.m_register_time = data.register_time
			ret.son_info.last_login_time = data.last_login_time
		end
	end

	
	return ret
end


---- 领取生财之道奖励
--[[function REQUEST.get_sczd_cash()
	local ret = {}
	ret.result = 0

	local error_code = skynet.call(DATA.service_config.sczd_center_service,"lua","get_sczd_cash" , DATA.my_id)
	if error_code then
		ret.result = error_code
		return ret
	end

	return ret
end--]]


---- 激活推广礼包收益
function CMD.activate_tglb_profit(_is_active_tglb1_profit)
	PUBLIC.request_client("tglb_profit_activate",
								{ is_active_tglb1_profit = _is_active_tglb1_profit})

	--- 发一个购买 金猪礼包
	--DATA.msg_dispatcher:call("buy_goldpig")

	
end

---- 金猪礼包缓存改变
function CMD.goldpig_profit_cache_change(now_cache)
	
	PUBLIC.request_client("goldpig_profit_cache_change",
								{ now_goldpig_profit_cache = now_cache})
end


----- sczd各种开关改变
function CMD.sczd_activate_change_msg(_is_activate_xj_profit,_is_activate_tglb_profit,_gjhhr_status , _bisai_profit)
	print("xxxxxxxxxxxxxxxx sczd_activate_change_msg",_is_activate_xj_profit,_is_activate_tglb_profit,_gjhhr_status , _bisai_profit)
	PUBLIC.request_client("sczd_activate_change_msg",
								{ is_activate_xj_profit = _is_activate_xj_profit ,
								  is_activate_tglb_profit = _is_activate_tglb_profit , 
								  is_activate_gjhhr = _gjhhr_status == "nor" and 1 or 0,
								  is_activate_bisai_profit = _bisai_profit ,
								   })
end


function PROTECT.init()


end

return PROTECT