--
-- Created by lyx.
-- User: hare
-- Date: 2018/11/6
-- Time: 14:59
-- 抽奖管理器
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require"printfunc"
require "normal_enum"

local cjson = require "cjson"
cjson.encode_sparse_array(true,1,0)

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST
local PUBLIC = base.PUBLIC

local return_msg={result=0}

local player_lottery_data = {}
local player_luck_box_data = {}
local lottery_config = {}

-- 幸运宝箱状态缓存(查询过程过于复杂)
local query_luck_box_lottery_status_cache = {}
local query_luck_box_lottery_status_cache_time = 10

local service_zero_time = 6

-- 666表情的抽奖次数
DATA.lottery_expression_666_time = 0


--获取"1~3"中的1和3
local function get_range_bound(str)
	local left,right=string.match(str,"(.+)~(.+)")
	return {min=tonumber(left),max=tonumber(right)}
end


--- 加载配置
local function load_config(raw_config)

	lottery_config = {}

	-- 666
	lottery_config.expression_666={}

	lottery_config.expression_666.cycle = raw_config.expression_666[1].cycle
	lottery_config.expression_666.item_count = get_range_bound(raw_config.expression_666[1].item_count)
	lottery_config.expression_666.asset_type = raw_config.expression_666[1].asset_type
	lottery_config.expression_666.asset_value = get_range_bound(raw_config.expression_666[1].asset_value)
	lottery_config.expression_666.items = {}

	for i,d in ipairs(raw_config.expression_666[1].items) do
		lottery_config.expression_666.items[i]={
			item = d,
			num = raw_config.expression_666[1].items_num[i],
		}
	end


	-- shuitong
	lottery_config.expression_shuitong={}

	lottery_config.expression_shuitong.cycle = raw_config.expression_shuitong[1].cycle
	lottery_config.expression_shuitong.item_count = get_range_bound(raw_config.expression_shuitong[1].item_count)
	lottery_config.expression_shuitong.asset_type = raw_config.expression_shuitong[1].asset_type
	lottery_config.expression_shuitong.asset_value = get_range_bound(raw_config.expression_shuitong[1].asset_value)
	lottery_config.expression_shuitong.items = {}

	for i,d in ipairs(raw_config.expression_shuitong[1].items) do
		lottery_config.expression_shuitong.items[i]={
			item = d,
			num = raw_config.expression_shuitong[1].items_num[i],
		}
	end

	lottery_config.condition = {}
	for i,d in ipairs(raw_config.condition) do
		if d.time then
			lottery_config.condition[d.time] = d.limit
		end
	end


	-- luck box

	local lbc = {}
	for i,d in ipairs(raw_config.luck_box_content) do
		local bcs = lbc[d.id] or {weight=0}
		lbc[d.id] = bcs

		bcs.weight = bcs.weight + d.weight

		bcs[#bcs+1] = 
		{
			asset_type = d.item,
			asset_value = d.item_num,
			index = d.no,
			weight = d.weight,
		}

	end

	lottery_config.luck_box = {}

	if raw_config.luck_box then

		for k,v in pairs(raw_config.luck_box) do
			
			lottery_config.luck_box[k] = 
			{
				cycle = v.cycle,
				jb_max_num = v.jb_max_num,
				box_rate = get_range_bound(v.box_rate),
				content = lbc[v.content],
				condition = raw_config.condition[v.condition].limit,
				consume = v.consume,
			}

		end
		
	end

	-- print("lottery_config-------*-*-*-*-*:",basefunc.tostring(lottery_config,10))
end



local function load_data()

	player_lottery_data = skynet.call(DATA.service_config.data_service,"lua","query_player_lottery_data")

	player_luck_box_data = skynet.call(DATA.service_config.data_service,"lua","query_player_lottery_luck_box_data")

end


local mt = 100
function PUBLIC.luck_box_reset_and_emails()

	local dt = 0

	local email = 
	{
		type="native",
		title="幸运抽奖宝箱奖励",
		sender="系统",
		receiver="",
		data={content="亲，您昨日完成了2次%s抽奖后忘记领取宝箱了，系统自动将宝箱奖励发放给您。"},
	}

	local names = 
	{
		"普通",
		"贵族",
		"至尊",
	}

	for player_id,_ in pairs(player_luck_box_data) do
		
		local pds = CMD.query_luck_box_lottery_data(player_id)
	
		for id,pd in ipairs(pds) do
			
			-- 领奖 并 重置
			if pd.lottery_num > 0 then

				if not basefunc.chk_same_date(pd.lottery_time,os.time(),service_zero_time) then
					
					local ret = CMD.open_luck_box(player_id,id)

					-- 领奖
					if type(ret) == "table" then

						email.receiver = player_id
						
						for ri,as in ipairs(ret) do
							email.data[as.asset_type] = as.value
						end

						email.data.content = string.format(email.data.content,names[id])

						skynet.send(DATA.service_config.email_service,"lua","send_email",email)

					end
					
					--重置
					pd.lottery_num = 0
					pd.box = 0
					pd.lottery_result = {}
					pd.lottery_jb_num = 0

				end

			end

		end

		dt = dt + 1
		if dt > mt then
			dt = 0
			skynet.sleep(1)
		end
	end

end


local exe_key = nil
local dt = 60
local function update()
	while true do

		local ct = os.time()
		local cur_date = tonumber(os.date("%Y%m%d",ct))
		local cur_h = tonumber(os.date("%H",ct))
		local cur_m = tonumber(os.date("%M",ct))

		-- 开机初始化一次 之后6点来
		if not exe_key or (exe_key ~= cur_date and cur_h >= service_zero_time) then

			-- 帮忙直接开宝箱
			PUBLIC.luck_box_reset_and_emails()

			exe_key = cur_date
		end


		skynet.sleep(dt*100)
	end
end



-- 666表情 - 次数
function CMD.lottery_expression_666(_player_id,_time)
	
	local cfg = lottery_config.expression_666

	local itmes = {
		dress_data = {expression={}},
		asset_data = {},
	}

	local is_cycle = nil
	if _time == cfg.cycle then
		is_cycle = true
	end

	local defult_data = {
							player_id = _player_id,
							lottery_time = 0,
							lottery_asset = 0,
							lottery_item_count = math.random(cfg.item_count.min,cfg.item_count.max),
							lottery_asset_time = 0,
						}
	local pld = nil

	if is_cycle then
		pld = defult_data
	else
		pld = player_lottery_data[_player_id] or defult_data
		player_lottery_data[_player_id] = pld
	end

	local asset_count = cfg.cycle - pld.lottery_item_count
	local asset_ave = math.ceil((cfg.asset_value.min + cfg.asset_value.max)*0.5/asset_count)

	function one_lottery()
		
		--需要抽红包的次数
		local cc = asset_count - pld.lottery_asset_time

		--总共还要抽的次数
		local rc = cfg.cycle - pld.lottery_time

		--asset
		if math.random(1,rc) <= cc then

			local r = math.random(
					math.ceil(asset_ave*0.2),
					math.ceil(asset_ave*1.8)
				)

			-- 最后一次抽红包了 红包数量一定要达到预定
			if cc <= 1 then
				local fr = math.random(
					math.max(pld.lottery_asset+1,cfg.asset_value.min),
					cfg.asset_value.max)
				r = fr - pld.lottery_asset
			else

				if pld.lottery_asset + r > cfg.asset_value.max - (cc-1)*10 then

					r = cfg.asset_value.max - (cc-1)*10 - pld.lottery_asset

				end

			end

			pld.lottery_asset = pld.lottery_asset + r

			pld.lottery_asset_time = pld.lottery_asset_time + 1

			itmes.asset_data[#itmes.asset_data+1]={
				asset_type=cfg.asset_type,
				value=r,
			}

		else
			--item
			local index = math.random(1,#cfg.items)
			local it = cfg.items[index]

			
			if basefunc.is_asset(it.item) then
				itmes.asset_data[#itmes.asset_data+1]={
								asset_type=it.item,
								value=it.num,
							}
			elseif it.item == "expression" then
				local id = 54
				itmes.dress_data.expression[#itmes.dress_data.expression+1]={
					id = id,
					num = it.num
				}

			else
				dump(it,"lottery_config error")
				error("lottery_config error !!!")
			end

		end

		pld.lottery_time = pld.lottery_time + 1

		if pld.lottery_time >= cfg.cycle then
			pld.lottery_time = 0
			pld.lottery_asset = 0
			pld.lottery_asset_time = 0
		end

	end

	for i=1,_time do
		one_lottery()
	end
	
	if not is_cycle then
		skynet.send(DATA.service_config.data_service,"lua","update_player_lottery_data",pld)
	end

	return itmes
end


-- 666表情 - 次数
function CMD.lottery_expression_shuitong(_player_id,_time)
	
	local cfg = lottery_config.expression_666

	local itmes = {
		dress_data = {expression={}},
		asset_data = {},
	}

	local is_cycle = nil
	if _time == cfg.cycle then
		is_cycle = true
	end

	local defult_data = {
							player_id = _player_id,
							lottery_time = 0,
							lottery_asset = 0,
							lottery_item_count = math.random(cfg.item_count.min,cfg.item_count.max),
							lottery_asset_time = 0,
						}
	local pld = nil

	if is_cycle then
		pld = defult_data
	else
		pld = player_lottery_data[_player_id] or defult_data
		player_lottery_data[_player_id] = pld
	end

	local asset_count = cfg.cycle - pld.lottery_item_count
	local asset_ave = math.ceil((cfg.asset_value.min + cfg.asset_value.max)*0.5/asset_count)

	function one_lottery()
		
		--需要抽红包的次数
		local cc = asset_count - pld.lottery_asset_time

		--总共还要抽的次数
		local rc = cfg.cycle - pld.lottery_time

		--asset
		if math.random(1,rc) <= cc then

			local r = math.random(
					math.ceil(asset_ave*0.2),
					math.ceil(asset_ave*1.8)
				)

			-- 最后一次抽红包了 红包数量一定要达到预定
			if cc <= 1 then
				local fr = math.random(
					math.max(pld.lottery_asset+1,cfg.asset_value.min),
					cfg.asset_value.max)
				r = fr - pld.lottery_asset
			else

				if pld.lottery_asset + r > cfg.asset_value.max - (cc-1)*10 then

					r = cfg.asset_value.max - (cc-1)*10 - pld.lottery_asset

				end

			end

			pld.lottery_asset = pld.lottery_asset + r

			pld.lottery_asset_time = pld.lottery_asset_time + 1

			itmes.asset_data[#itmes.asset_data+1]={
				asset_type=cfg.asset_type,
				value=r,
			}

		else
			--item
			local index = math.random(1,#cfg.items)
			local it = cfg.items[index]

			
			if basefunc.is_asset(it.item) then
				itmes.asset_data[#itmes.asset_data+1]={
								asset_type=it.item,
								value=it.num,
							}
			elseif it.item == "expression" then
				local id = 56
				itmes.dress_data.expression[#itmes.dress_data.expression+1]={
					id = id,
					num = it.num
				}

			else
				dump(it,"lottery_config error")
				error("lottery_config error !!!")
			end

		end

		pld.lottery_time = pld.lottery_time + 1

		if pld.lottery_time >= cfg.cycle then
			pld.lottery_time = 0
			pld.lottery_asset = 0
			pld.lottery_asset_time = 0
		end

	end

	for i=1,_time do
		one_lottery()
	end
	
	if not is_cycle then
		skynet.send(DATA.service_config.data_service,"lua","update_player_lottery_data",pld)
	end

	return itmes
end


-- 判断抽奖状态 单抽和十连抽
function CMD.check_lottery_status(_player_id,_time,_jing_bi)
	local c = lottery_config.condition[_time]
	if c then
		if _jing_bi >= c then
			return 0
		else
			return 3906
		end
	else
		return 1002
	end
end




-- luck box data
function save_luck_box_data(_player_id,_id)

	local pds = CMD.query_luck_box_lottery_data(_player_id)
	local pd = pds[_id]
	pd.open = pds.open
	
	local lottery_result = pd.lottery_result

	pd.lottery_result = cjson.encode(lottery_result)

	skynet.send(DATA.service_config.data_service,"lua","update_player_lottery_luck_box_data",_player_id,_id,pd)
	
	pd.open = nil
	pd.lottery_result = lottery_result

end

-- luck box 抽奖状态
function CMD.query_luck_box_lottery_status(_player_id)
	
	-- 总开关配置
	if not skynet.getcfg("luck_box_lottery_open") then
		return 1002
	end

	local pd = CMD.query_luck_box_lottery_data(_player_id)
	if pd.open == 1 then
		return 0
	end

	local bls = query_luck_box_lottery_status_cache[_player_id] or {time=0}
	query_luck_box_lottery_status_cache[_player_id] = bls

	-- 过期
	if os.time() - bls.time > query_luck_box_lottery_status_cache_time then
		bls.time = os.time()
	else
		return 1002
	end


	-- >= 6 元的充值
	local sql = string.format(
					[[SELECT COUNT(*) num FROM player_pay_order 
						WHERE 
							player_id = "%s" 
							AND end_time > "2019-06-12 10:00:00" 
							AND money >= 600 
							AND order_status = "complete";]]
					,_player_id)
	
	local ret = skynet.call(DATA.service_config.data_service,"lua","db_query",sql)

	if type(ret) == "table" and ret[1] and ret[1].num and ret[1].num > 0 then
		pd.open = 1
		save_luck_box_data(_player_id,1)
		query_luck_box_lottery_status_cache[_player_id] = nil
		return 0 
	end

	local sql = string.format(
					[[SELECT COUNT(*) num FROM player_pay_order_log
						WHERE 
							player_id = "%s" 
							AND end_time > "2019-06-12 10:00:00" 
							AND money >= 600 
							AND order_status = "complete";]]
					,_player_id)
	
	local ret = skynet.call(DATA.service_config.data_service,"lua","db_query",sql)

	if type(ret) == "table" and ret[1] and ret[1].num and ret[1].num > 0 then
		pd.open = 1
		save_luck_box_data(_player_id,1)
		query_luck_box_lottery_status_cache[_player_id] = nil
		return 0 
	end

	return 1002

end

-- luck box 抽奖次数
function CMD.query_luck_box_lottery_data(_player_id)

	local pd = player_luck_box_data[_player_id] or {}

	for id,v in ipairs(lottery_config.luck_box) do
		pd[id] = pd[id] or
		{
			lottery_num = 0, -- 抽奖次数
			lottery_jb_num = 0, -- 抽到鲸币的次数
			lottery_time = 0, -- 最近一次抽奖时间
			box = 0,			-- 是否开过宝箱
			lottery_result = {}, -- 抽奖结果(数组)
		}
	end

	pd.open = pd.open or 0

	player_luck_box_data[_player_id] = pd

	return pd
	
end

-- luck box 抽奖
function CMD.lottery_luck_box(_player_id,_id,_jing_bi)

	local status = CMD.query_luck_box_lottery_status(_player_id)
	if status ~= 0 then
		return status
	end

	if not lottery_config.luck_box then
		return 1002
	end

	local cfg = lottery_config.luck_box[_id]
	if not cfg then
		return 1001
	end

	if cfg.condition > _jing_bi or cfg.consume > _jing_bi then
		return 1023
	end

	local pds = CMD.query_luck_box_lottery_data(_player_id)
	local pd = pds[_id]

	if pd.lottery_num >= cfg.cycle then
		return 4800
	end


	-- 开始抽奖

	-- 鲸币已经达到最大次数了，不能再抽鲸币了
	local njb = pd.lottery_jb_num >= cfg.jb_max_num

	local lottery_result = 
	{
		consume = cfg.consume,
		index = 0,
		assets = nil,
	}

	while true do

		local r = math.random(1,cfg.content.weight)

		local idx = 0
		for i,d in ipairs(cfg.content) do
			r = r - d.weight
			if r < 1 then
				idx = i
				break
			end
		end

		local ct = cfg.content[idx]

		if njb and ct.asset_type == "jing_bi" then
			-- 不能抽鲸币，又是鲸币 重新抽
		else

			lottery_result.index = ct.index
			lottery_result.assets = 
			{
				asset_type = ct.asset_type,
				value = ct.asset_value,
			}

			break
		end

	end

	pd.lottery_num = pd.lottery_num + 1
	
	-- 第一次才设时间
	if pd.lottery_num == 1 then
		pd.lottery_time = os.time()
	end

	pd.lottery_result[#pd.lottery_result+1] = lottery_result.assets

	if lottery_result.assets.asset_type == "jing_bi" then
		pd.lottery_jb_num = pd.lottery_jb_num + 1
	end

	save_luck_box_data(_player_id,_id)

	return lottery_result
end


-- 获取最后的宝箱红包 开宝箱
function CMD.open_luck_box(_player_id,_id)
	
	local cfg = lottery_config.luck_box[_id]

	local pds = CMD.query_luck_box_lottery_data(_player_id)
	local pd = pds[_id]

	if pd.lottery_num < cfg.cycle then
		return 4801
	end

	if pd.box ~= 0 then
		return 4802
	end

	local pc = 0
	for i,v in ipairs(pd.lottery_result) do
		pc = pc + basefunc.trans_asset_to_jingbi( v.asset_type , v.value )
	end

	local ap = cfg.consume * pd.lottery_num

	local r = math.random(math.floor(cfg.box_rate.min*1000),math.floor(cfg.box_rate.max*1000))
	r = r * 0.001

	local ret = math.floor(r*ap - pc)

	local hb_rate = PLAYER_ASSET_TRANS_JINGBI[PLAYER_ASSET_TYPES.SHOP_GOLD_SUM]

	ret = math.floor(ret / hb_rate)

	ret = math.max(ret,1)

	pd.box = 1
	
	save_luck_box_data(_player_id,_id)

	return 
	{
		[1] = 
		{
			asset_type = PLAYER_ASSET_TYPES.SHOP_GOLD_SUM,
			value = ret,
		},
	}

end



function CMD.start(_service_config)

	math.randomseed(os.time()*769435)

	DATA.service_config = _service_config

	load_data()

	nodefunc.query_global_config("lottery_config",load_config)

	skynet.fork(update)

end

-- 启动服务
base.start_service()
