--
-- Author: lyx
-- Date: 2018/5/30
-- Time: 11:09
-- 说明：管理通过 web 团队代理实现的 支付功能（微信，支付宝）
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"

require"printfunc"
require "normal_enum"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local service_zero_time = 6

local create_gift_bag_order_time = {}
local create_gift_bag_order_lock = {}

local return_msg = {result=0}

DATA.shoping_config = {}

DATA.gift_bag_data = {}

DATA.player_gift_bag_data = {}

local function get_wait_gift_bag_time()
	local t = skynet.getcfg "create_order_wait_time"
	return tonumber(t) or 30
end


--查询所有礼包状态
function CMD.query_player_all_gift_bag_status(_player_id)
	
	local data = {}
	for _gift_bag_id,d in pairs(DATA.shoping_config) do

		local ret = CMD.query_player_gift_bag_status(_player_id,_gift_bag_id)
		
		data[#data+1] = {}

		if ret.result == 0 then
			data[#data].status = 1
		else
			data[#data].status = 0
		end

		data[#data].gift_bag_id = _gift_bag_id

	end

	return data
end


function CMD.query_player_gift_bag_status(_player_id,_gift_bag_id)
	
	local d = nil

	local pd = DATA.player_gift_bag_data[_player_id]
	if pd then
		d = pd[_gift_bag_id]
	end

	d = d or {num=0,time=0,permit_num=0,permit_time=0}

	local gb_cfg = DATA.shoping_config[_gift_bag_id]
	if not gb_cfg then
		return_msg.result=1001
		return return_msg
	end
	
	----- 金猪礼包是否能购买
	local pb = skynet.call(base.DATA.service_config.goldpig_center_service,"lua","query_goldpig_gift_can_buy",_player_id,_gift_bag_id)

	if pb ~= nil then
		if pb then
			return_msg.result=0
			return return_msg
		else
			return_msg.result=3401
			return return_msg
		end
	end

	----- 周卡是否能购买
	local zk = skynet.call(base.DATA.service_config.zhouka_system_service,"lua","query_zhouka_can_buy",_player_id,_gift_bag_id) 
	if zk ~= nil then
		if zk then
			return_msg.result=0
			return return_msg
		else
			return_msg.result=3401
			return return_msg
		end
	end


	if d.num > 0 then

		if gb_cfg.buy_limt == 0 then

			return_msg.result=3401
			return return_msg

		elseif gb_cfg.buy_limt == 1 then

			if basefunc.chk_same_date(d.time,os.time(),service_zero_time) then

				return_msg.result=3405
				return return_msg

			else
				--ok
			end
		
		elseif gb_cfg.buy_limt == 2 then
			--ok 无限制购买
			
		else
			error("DATA.shoping_config buy_limt error")
		end

	end

	local permit_time = nil

	-- 包含触发条件的礼包
	if gb_cfg.condition then
		--dump( d , "--------------------------------------query_player_gift_bag_status d" )
		if d.permit_num > gb_cfg.condition.limit or d.permit_time < os.time() then
			return_msg.result=3406
			return return_msg
		end

		permit_time = d.permit_time
	end

	return {
		result = 0,
		permit_time = permit_time,
	}

end

--创建礼包订单
function CMD.get_create_gift_bag_order_status(_player_id,_gift_bag_id)

	local stop = skynet.getcfg("stop_buy_gift_bag_" .. _gift_bag_id)
	if stop then
		return_msg.result=1002
		return return_msg
	end

	local gb_cfg = DATA.shoping_config[_gift_bag_id]

	if not gb_cfg then
		return_msg.result=1001
		return return_msg
	end

	if gb_cfg.on_off ~= 1 then
		return_msg.result=3404
		return return_msg
	end


	if not DATA.gift_bag_data[_gift_bag_id] then
		return_msg.result=1001
		return return_msg
	end

	-- 时间验证
	if (create_gift_bag_order_time[_player_id] or 0) > os.time() then

		return_msg.result=3402
		return return_msg

	end

	if create_gift_bag_order_lock[_player_id] then
		return_msg.result=1008
		return return_msg
	end
	create_gift_bag_order_lock[_player_id] = true

	local d = CMD.query_player_gift_bag_status(_player_id,_gift_bag_id)

	if d.result ~= 0 then
		create_gift_bag_order_lock[_player_id] = nil
		return_msg.result=d.result
		return return_msg
	end

	local num = DATA.gift_bag_data[_gift_bag_id].count
	if num < 1 then
		create_gift_bag_order_lock[_player_id] = nil
		return_msg.result=3403
		return return_msg
	end

	if (os.time() < (gb_cfg.start_time or 0))
		or (os.time() > (gb_cfg.end_time or 2551318590))then
			create_gift_bag_order_lock[_player_id] = nil
			return_msg.result=3404
			return return_msg
	end

	create_gift_bag_order_time[_player_id] = os.time() + get_wait_gift_bag_time()

	create_gift_bag_order_lock[_player_id] = nil
	return_msg.result=0
	return return_msg
end



function CMD.query_gift_bag_num(_gift_bag_id)

	if DATA.gift_bag_data[_gift_bag_id] then
		return DATA.gift_bag_data[_gift_bag_id].count
	end
	return 0

end


-- 玩家进行了购买礼包
function CMD.player_buy_gift_bag(_player_id,_gift_bag_id,_n)

	if not DATA.gift_bag_data[_gift_bag_id] then
		return
	end
	
	local pd = DATA.player_gift_bag_data[_player_id] or {}
	DATA.player_gift_bag_data[_player_id] = pd

	local pdid = pd[_gift_bag_id] or 
				{
					gift_bag_name = DATA.gift_bag_data[_gift_bag_id].gift_bag_name,
					num = 0,
					time = 0,
					permit_num = 0,
					permit_time = 0,
				}
	pd[_gift_bag_id] = pdid
	pdid.num = pdid.num + 1
	pdid.time = os.time()


	skynet.send(base.DATA.service_config.data_service,"lua","update_player_gift_bag_data"
					,_player_id,_gift_bag_id,pdid.gift_bag_name,pdid.num,pdid.time
					,pdid.permit_num,pdid.permit_time)


	if DATA.gift_bag_data[_gift_bag_id].count < 1 then
		return
	end

	DATA.gift_bag_data[_gift_bag_id].count = DATA.gift_bag_data[_gift_bag_id].count - (_n or 1)

	skynet.send(base.DATA.service_config.data_service,"lua","update_gift_bag_data"
		,{
			gift_bag_id = _gift_bag_id,
			count = DATA.gift_bag_data[_gift_bag_id].count,
		})

	create_gift_bag_order_time[_player_id] = nil
	
end


-- 有玩家触发了礼包的购买条件
function CMD.player_trigger_condition(_player_id,_gift_bag_id)

	local gb_cfg = DATA.shoping_config[_gift_bag_id]

	if not gb_cfg.condition then
		return 0
	end

	local pd = DATA.player_gift_bag_data[_player_id] or {}
	DATA.player_gift_bag_data[_player_id] = pd

	local pdid = pd[_gift_bag_id] or 
				{
					gift_bag_name = DATA.gift_bag_data[_gift_bag_id].gift_bag_name,
					num = 0,
					time = 0,
					permit_num = 0,
					permit_time = 0,
				}
	pd[_gift_bag_id] = pdid

	-- 权限时间还有 不要触发了
	if os.time() < pdid.permit_time then
		return 0
	end

	-- 每天重置 如果最后一次的触发权限时间 和 现在 跨越了一天 就重置
	if not basefunc.chk_same_date(pdid.permit_time-gb_cfg.condition.duration,os.time(),service_zero_time) then
		pdid.permit_num = 0
		pdid.permit_time = 0
	end

	-- 权限次数大于了 不用处理了
	if pdid.permit_num > gb_cfg.condition.limit then
		return 0
	end

	pdid.permit_num = pdid.permit_num + 1
	pdid.permit_time = os.time() + gb_cfg.condition.duration

	skynet.send(base.DATA.service_config.data_service,"lua","update_player_gift_bag_data"
					,_player_id,_gift_bag_id,pdid.gift_bag_name,pdid.num,pdid.time
					,pdid.permit_num,pdid.permit_time)

	
	--skynet.fork(function ()
			
		local ret = CMD.query_player_gift_bag_status(_player_id,_gift_bag_id)

		local status = 0

		if ret.result == 0 then
			status = 1
		else
			status = 0
		end

		nodefunc.send(_player_id,"gift_bag_status_change_msg",_gift_bag_id,status,ret.permit_time)

	return status

	--end)

end


-- 更新商城配置
function CMD.update_shoping_config(_cfg,_ver)

	DATA.shoping_config = _cfg

	PUBLIC.init_gift_bag()

end


-- 临时调整礼包的数据 num
function CMD.update_gift_bag_data(_gift_bag_id,_num)

	if DATA.gift_bag_data[_gift_bag_id] then
		local n = tonumber(_num)
		if n then
			DATA.gift_bag_data[_gift_bag_id].count = n

			skynet.send(base.DATA.service_config.data_service,"lua","update_gift_bag_data"
				,{
					gift_bag_id = _gift_bag_id,
					count = DATA.gift_bag_data[_gift_bag_id].count,
				})

		end
	end

end


-- 初始化 礼包
function PUBLIC.init_gift_bag()

	local gb_cfg = DATA.shoping_config.gift_bag
	local gb_condi_cfg = DATA.shoping_config.gift_bag_condition

	if not gb_cfg then
		return
	end
	
	local sc = {}

	for i,d in ipairs(gb_cfg) do
		
		if d.on_off == 1 then

			local gd = skynet.call(base.DATA.service_config.data_service,"lua","query_gift_bag_data",d.id)
			if not gd then
				gd = 
				{
					gift_bag_id = d.id,
					gift_bag_name = d.pay_title,
					count = d.count,
				}
				skynet.send(base.DATA.service_config.data_service,"lua","update_gift_bag_data",gd)
			end

			if d.condition then
				d.condition = gb_condi_cfg[d.condition]
			end
			
			DATA.gift_bag_data[gd.gift_bag_id]=gd

		end
		
		sc[d.id] = d

	end

	DATA.shoping_config = sc

	if not DATA.player_gift_bag_data or not next(DATA.player_gift_bag_data) then
		DATA.player_gift_bag_data = skynet.call(base.DATA.service_config.data_service,"lua","query_player_gift_bag_data")
	end

end
