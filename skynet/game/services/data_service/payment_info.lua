--
-- Author: lyx
-- Date: 2018/5/22
-- Time: 16:06
-- 说明：玩家的支付信息
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require"printfunc"

require "data_func"

local monitor_lib = require "monitor_lib"

local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC
local REQUEST=base.REQUEST

require "normal_enum"

local payment_config = require "payment_config"

---- 信号消息分发器
base.DATA.events = {
	on_pay_success = basefunc.signal.new(),
	on_withdraw_success = basefunc.signal.new(),
}

local PROTECTED = {}

DATA.payment_info_data = DATA.payment_info_data or 
{
	-- 商品配置表表
	shoping_goods_config = {},
	appstore_shoping_goods_config = {},

	shoping_config = {},

	-- 对修改订单的玩家进行加锁
	modify_pay_order_player_lock = {},

	-- 商品表（供web后台拉取商品）
	goods_list = {},

	goods_list_lock = {},

	-- 商品时间限制
	goods_list_valid_time = {},
	
	--[[
	-- 支付信息数据（ 表 player_pay_order）： orderId -> 数据
	-- 数据结构说明：
		orderId = {订单数据}
	--]]
	payment_info = {},
	appstore_payment_info = {},

	--[[	
	-- 支付信息 详情数据 数据（表 player_pay_order_detail）： orderId -> 数据
	-- 数据结构说明：
		orderId = {[asset_type]=,[asset_type]=,...}
	--]]	
	payment_info_detail = {},

	order_status={
		create=true,
		error=true,
		fail=true,
		complete=true,
		SYSTEMERROR=true,
	},
}
local LL = DATA.payment_info_data


DATA.player_order_wait_time = {}


-- 初始化订单信息
function PROTECTED.init_payment_info()

	-- 缓存订单
	local sql = "select * from player_pay_order;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
        LL.payment_info[ret[i].order_id] = ret[i]

		if ret[i].itunes_trans_id then
        	LL.appstore_payment_info[ret[i].itunes_trans_id] = ret[i]
		end
	end

	-- 缓存订单详情
	sql = [[select * from player_pay_order_detail]]
	ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local _oid = ret[i].order_id
		local detail = LL.payment_info_detail[_oid] or {}
		LL.payment_info_detail[_oid] = detail

		detail[#detail + 1] = {asset_count=ret[i].asset_count,goods_type=ret[i].goods_type,asset_type=ret[i].asset_type}
	end

	-- 刷新配置
	skynet.timer(5,function()
		payment_config = base.require("game/config/","payment_config")
	end)

	return true
end


-- 更新商城配置
function base.CMD.update_shoping_config(_cfg,_ver)

	local sconfig = _cfg
	LL.shoping_config = _cfg
	LL.shoping_goods_config = {}
	LL.appstore_shoping_goods_config = {}
	LL.goods_list = {}

	-- 读取商店配置，并组织成易读的数据
	for _id,_goods in pairs(sconfig.goods) do

		local goolds = basefunc.copy(_goods)
		goolds.assets = {}
		local _id = goolds.id

		for i=1,#_goods.buy_asset_type do
			table.insert(goolds.assets,{goods_type="buy",asset_type=_goods.buy_asset_type[i],count=_goods.buy_asset_count[i]})
		end
		if _goods.gift_asset_type then
			for i=1,#_goods.gift_asset_type do
				table.insert(goolds.assets,{goods_type="gift",asset_type=_goods.gift_asset_type[i],count=_goods.gift_asset_count[i]})
			end
		end

		if "shop" == goolds.shop_type and goolds.gzh_show == 1 then
			LL.goods_list[#LL.goods_list + 1] = {goods_id=_id,price=_goods.price,pay_title=_goods.pay_title,gzh_order=goolds.gzh_order}
		end

		if _goods.platform == "ios" then

			LL.appstore_shoping_goods_config[_goods.product_id] = goolds

		else

			LL.shoping_goods_config[_id] = goolds
			
		end

	end

	-- 读取礼包gift_bag|礼包
	for gi,_goods in pairs(sconfig.gift_bag) do
		local goolds = basefunc.copy(_goods)
		goolds.assets = {}
		local _id = goolds.id

		if _goods.buy_asset_type then
			for i=1,#_goods.buy_asset_type do
				table.insert(goolds.assets,{goods_type="buy",asset_type=_goods.buy_asset_type[i],count=_goods.buy_asset_count[i]})
			end
		end

		LL.shoping_goods_config[_id] = goolds

		-- 简单判断限制
		if goolds.on_off == 1 and goolds.gzh_show == 1 then
			LL.goods_list_valid_time[_id]={start_time=goolds.start_time or 0,end_time=goolds.end_time or 2551318590}
			LL.goods_list[#LL.goods_list + 1] = {goods_id=_id,price=_goods.price,pay_title=_goods.pay_title,gzh_order=goolds.gzh_order}
		end

		if _goods.product_id then

			-- ios 单独走AppStore
			LL.appstore_shoping_goods_config[_goods.product_id] = goolds
			
		end
		
	end

	-- 排序
	table.sort( LL.goods_list, function(a,b)
		return a.gzh_order < b.gzh_order
	end )

end


--- add by wss
--- 增加 消息注册
function base.CMD.register_msg(_key, _target_link , _msg_name )

	base.DATA.events[_msg_name]:bind(_key,function(...)
		cluster.send(_target_link.node,_target_link.addr,_target_link.cmd,...)
	end)
end

function base.CMD.unregister_msg( _key,_msg_name )
	base.DATA.events[_msg_name]:unbind(_key)
end

-- 的得到商品表
function base.CMD.get_goods_list(_player_id)

	if LL.goods_list_lock[_player_id] then
		return 1008
	end

	LL.goods_list_lock[_player_id] = true

	local bag_status = skynet.call(base.DATA.service_config.pay_service,"lua","query_player_all_gift_bag_status"
									,_player_id)

	if #bag_status < 1 then
		LL.goods_list_lock[_player_id] = nil
		return 0,LL.goods_list
	end

	local bag_status_hash = {}
	for i,d in ipairs(bag_status) do
		bag_status_hash[d.gift_bag_id]=d.status
	end

	local player_goods_list = {}

	for i,d in ipairs(LL.goods_list) do
		
		local s = bag_status_hash[d.goods_id]
		if s ~= 0 then
			local t = LL.goods_list_valid_time[d.goods_id]

			-- 礼包时间检测
			if not t or (os.time() > t.start_time and os.time() < t.end_time) then
				
				local n = 999
				-- 礼包数量检测
				if s == 1 then

					n = skynet.call(base.DATA.service_config.pay_service,"lua","query_gift_bag_num"
									,d.goods_id)
					
				end

				if n > 0 then
					player_goods_list[#player_goods_list+1]=d
				end

			end

		end

	end

	LL.goods_list_lock[_player_id] = nil

	return 0,player_goods_list

end

-- 创建新的订单号
function PUBLIC.create_order_id()

	local sysvar = base.DATA.system_variant

    local todayStr = os.date("%Y%m%d")
    if sysvar.last_pay_order_date == todayStr then
        sysvar.last_pay_order_today_index = sysvar.last_pay_order_today_index + 1
    else
        sysvar.last_pay_order_date = todayStr
        sysvar.last_pay_order_today_index = 1
    end

    return string.format("%s%07u%s",todayStr,sysvar.last_pay_order_today_index,skynet.random_str(5))
end

-- 创建一个订单，返回订单号
-- 返回值：
--	 1、订单号，出错则为 nil
--	 2、如果出错，则返回错误号
function base.CMD.create_pay_order(_userId,_channel_type,_source_type,_goods_id,_convert)

	if not _channel_type or not payment_config.channel_types[_channel_type] then
		return nil,2236
	end

	local _cur_dbg_money = skynet.getcfg("debug") and LL.debug_temp_money

	local goods = LL.shoping_goods_config[_goods_id]

	if not goods then
		return nil,2238
	end

	local _money_type = "rmb"

	if goods.price <= 0 then
		return nil,2235
	end

	if not base.CMD.is_player_exists(_userId) then
		return nil,2159
	end

	-- 时间限制
	local ct = os.time()
	local powt = DATA.player_order_wait_time[_userId]
	if powt and ct < powt then
		return nil,3402
	end
	DATA.player_order_wait_time[_userId] = ct + skynet.getcfg_2number("create_order_wait_time",30)


	goods.pay_title = goods.pay_title or ""

	local product_desc_ext = ""
	if _convert then
		product_desc_ext = "->".._convert
	end

    local order = {
        order_id = PUBLIC.create_order_id(),
        player_id = _userId,
        order_status = "init",
        money_type = _money_type,
        money = goods.price,
        channel_type = _channel_type,
        source_type = _source_type,
        product_id = _goods_id,
		product_count = 1,  -- 数量始终是 1 ！
		product_desc = goods.pay_title..product_desc_ext,
        is_test = (skynet.getcfg("is_pay_test") and 1 or 0),
        create_time = os.time(),
        convert = _convert,
        convert_id = goods.convert_id,
	}
	
	if _cur_dbg_money then
		order.money = tonumber(_cur_dbg_money)
	end

    LL.payment_info[order.order_id] = order

	local sqls = {}

	-- 订单表
	sqls[#sqls + 1] = string.format([[insert into player_pay_order
									(order_id,player_id,order_status,money_type,money,channel_type,source_type,product_id,is_test,create_time,product_desc)
									values ('%s','%s',"init",'%s',%d,'%s','%s','%s',%d,FROM_UNIXTIME(%u),'%s');]]
									,order.order_id
									,_userId
									,_money_type
									,_cur_dbg_money or goods.price
									,_channel_type
									,_source_type
									,tostring(_goods_id)
									,(skynet.getcfg("is_pay_test") and 1 or 0)
									,os.time()
									,order.product_desc)

	-- 订单详情表
	local detail = {}
	for _,_asset in ipairs(goods.assets) do
		sqls[#sqls + 1] = string.format("insert into player_pay_order_detail(order_id,asset_type,asset_count,goods_type) values('%s','%s',%d,'%s');",
			order.order_id,_asset.asset_type,_asset.count,_asset.goods_type)

		detail[#detail + 1] = {asset_type=_asset.asset_type,asset_count=_asset.count,goods_type=_asset.goods_type}
	end

	LL.payment_info_detail[order.order_id] = detail

	base.DATA.sql_queue_fast:push_back(table.concat(sqls,"\n"))

    return order.order_id
end

-- 查询一个订单。注意：不能查日志中的订单
-- 返回：
--	1、订单数据
--	2、错误号，如果出错，返回错误号
function base.CMD.query_pay_order(_order_id)

    local order = LL.payment_info[_order_id]

	if order then
		return order
	else
		return nil,2231 -- 订单未找到
	end
end


function PUBLIC.complete_shop_order(_order,_detail)

	if _order.convert then

		local cc = LL.shoping_config[_order.convert]

		if cc then

			local d
			for gi,_goods in pairs(cc) do
				if _order.convert_id == _goods.id then
					d = _goods
				end
			end
			
			local _detail_convert = {}

			local num = d.num
			base.CMD.change_asset(_order.player_id,_order.convert,num,ASSET_CHANGE_TYPE.BUY,_order.order_id)

			_detail_convert[#_detail_convert+1]=
			{
				asset_type = _order.convert,
				asset_count = num,
			}

			for i,v in ipairs(d.gift_asset_type) do
				base.CMD.change_asset(_order.player_id,v,d.gift_asset_count[i],ASSET_CHANGE_TYPE.BUY_GIFT,_order.order_id)
				_detail_convert[#_detail_convert+1]=
				{
					asset_type = v,
					asset_count = d.gift_asset_count[i],
				}
			end

			-- 推送玩家消息
			nodefunc.send(_order.player_id,"notify_pay_order_asset_change_msg",_detail_convert,ASSET_CHANGE_TYPE.BUY,_order.order_id)

			return
		end

		print(" PUBLIC.complete_shop_order convert error: ".._order.convert)
	end


	for _,_asset in ipairs(_detail) do
		if basefunc.is_asset(_asset.asset_type) then
			if _asset.goods_type == "buy" then
				base.CMD.change_asset(_order.player_id,_asset.asset_type,_asset.asset_count,ASSET_CHANGE_TYPE.BUY,_order.order_id)
			else
				base.CMD.change_asset(_order.player_id,_asset.asset_type,_asset.asset_count,ASSET_CHANGE_TYPE.BUY_GIFT,_order.order_id)
			end
		end
	end

	-- 推送玩家消息
	nodefunc.send(_order.player_id,"notify_pay_order_asset_change_msg",_detail,ASSET_CHANGE_TYPE.BUY,_order.order_id)

end


function PUBLIC.complete_gift_bag_order(_order,_detail)

	local assets = {}

	for _,_asset in ipairs(_detail) do
		assets[#assets+1]={
			asset_type = _asset.asset_type,
			value = _asset.asset_count,
		}
	end

	base.CMD.multi_change_asset_and_sendMsg(_order.player_id,assets,"buy_gift_bag_".._order.product_id,_order.order_id)

	skynet.call(base.DATA.service_config.pay_service,"lua","player_buy_gift_bag",_order.player_id,_order.product_id,1)

end



-- 修改一个订单。注意：不能修改日志中的订单
-- 返回：
--      1、true/false
--      2、错误号 ： 如果失败，则返回错误号
function base.CMD.modify_pay_order(_order_id,_order_status,_error_desc,_channel_account_id,_channel_order_id,_channel_product_id,_itunes_trans_id)

    local order = LL.payment_info[_order_id]
    if not order then
        return false,2231
	end

	-- 特别注意：完成后不能再修改，并且完成消息只能有一次，否则后续的资产修改操作会执行多次！！！！
	if "complete" == order.order_status then
		return false,2232
	end

	if _order_status == order.order_status then
		return false,1003
	end

	if not LL.order_status[_order_status] then
		return false,2233
	end

	local procid = tonumber(order.product_id)
	if not procid then
		return false,1001
	end

	if LL.modify_pay_order_player_lock[order.player_id] then
		return false,1008
	end
	LL.modify_pay_order_player_lock[order.player_id] = true

	local _succ,_errcode = true,nil

	local ok,msg = xpcall(function()

		local goods = LL.shoping_goods_config[procid]
		if not goods then

			_order_status = "error"
			_error_desc = "goods_id is not exits,perhaps deleted!"

			_succ = false
			_errcode = 1002

			return
		end

		if goods.shop_type == "gift_bag" and "complete" == _order_status then
			
			local d = skynet.call(base.DATA.service_config.pay_service,"lua","query_player_gift_bag_status"
										,order.player_id,order.product_id)

			if d.result ~= 0 then
				_order_status = "error"
				_error_desc = "gift_bag status error !!! " .. tostring(d.result)

				_succ = false
				_errcode = d.result
			end

		end


		local sql_update_values = {}

		-- 处理需要修改的字段
		local function deal_update_fields(_name,_param_value)
			if nil ~= _param_value and order[_name] ~= _param_value then
				order[_name] = _param_value
				sql_update_values[#sql_update_values + 1] = string.format(" %s=%s ",_name,base.PUBLIC.value_to_sql(_param_value))
			end
		end

		deal_update_fields("order_status",_order_status)
		deal_update_fields("error_desc",_error_desc)
		deal_update_fields("channel_order_id",_channel_order_id)
		deal_update_fields("channel_product_id",_channel_product_id)
		deal_update_fields("itunes_trans_id",_itunes_trans_id)
		deal_update_fields("channel_account_id",_channel_account_id)

		if "complete" == _order_status then
			order["end_time"] = os.time()
			sql_update_values[#sql_update_values + 1] = string.format(" end_time=FROM_UNIXTIME(%u) ",order["end_time"])
		end

		if not next(sql_update_values) then
			LL.modify_pay_order_player_lock[order.player_id] = nil

			_succ = false
			_errcode = 1010
			return
		end

		local sql = string.format([[update player_pay_order set %s where order_id='%s';]],
					table.concat(sql_update_values,","),_order_id)

		-- 通知玩家订单状态（目前 仅成功才通知）
		if "complete" == _order_status then
			--关键打印不能去掉
			dump(order,"normal pay_order complete !!!!!!!!!!!")

			local detail = LL.payment_info_detail[_order_id]
			if not detail then
				nodefunc.send(order.player_id,"notify_pay_order_status",2240,"无法完成购买，订单详情数据丢失！",_order_id,order.product_id)
				LL.modify_pay_order_player_lock[order.player_id] = nil

				_succ = false
				_errcode = 2240
				return
			end

			if goods.shop_type == "shop" then

				PUBLIC.complete_shop_order(order,detail)

			elseif goods.shop_type == "gift_bag" then
				
				PUBLIC.complete_gift_bag_order(order,detail)

			else

				error(string.format("shop_type '%s' is incorrect!",tostring(goods.shop_type)))
			end


			base.CMD.add_consume_statistics(order.player_id,"pay",order.money)

			nodefunc.send(order.player_id,"notify_pay_order_status",0,nil,_order_id,order.product_id,detail)

	
			-- 成功订单统计
			sql = sql .. string.format(
				[[insert into player_pay_order_stat(player_id,first_complete_time,first_order_id,last_complete_time,last_order_id,sum_money) 
				values('%s',FROM_UNIXTIME(%u),'%s',FROM_UNIXTIME(%u),'%s',%d) 
				on duplicate key update last_complete_time=FROM_UNIXTIME(%u),last_order_id='%s',sum_money=sum_money+%d;]],
				order.player_id,os.time(),_order_id,os.time(),_order_id,order.money * order.product_count,
				os.time(),_order_id,order.money * order.product_count) ..

				-- 增长更新序号
				string.format("update player_info set sync_seq=%d where id='%s';",base.PUBLIC.auto_inc_id("last_player_info_seq"),order.player_id)

			monitor_lib.add_data("pay",order.money)

			--- 支付成功消息 --关键打印不能去掉
			dump(order,"normal pay_order on_pay_success trigger !!!!!!!!!!!")
			--- 支付成功消息
			--base.DATA.events.on_pay_success:trigger(order.player_id,procid,order.money,order.channel_type)
			--- 向通知中心触发消息
			skynet.send( base.DATA.service_config.msg_notification_center_service , "lua" , "trigger_msg" , {name = "on_pay_success"} , order.player_id,procid,order.money,order.channel_type )

			DATA.player_order_wait_time[order.player_id] = nil

		elseif "error" == _order_status then

			nodefunc.send(order.player_id,"notify_pay_order_status",2241,_error_desc,_order_id,order.product_id)

		elseif "fail" == _order_status then

			nodefunc.send(order.player_id,"notify_pay_order_status",2242,_error_desc,_order_id,order.product_id)
		end

		base.DATA.sql_queue_fast:push_back(sql)
	end,basefunc.handler)

	LL.modify_pay_order_player_lock[order.player_id] = nil

	if not ok then
		print("modify payment status error:",msg)
	end

    return _succ,_errcode
end



-------------------------------------- appstore ------------------------------------------------------------
-------------------------------------- appstore ------------------------------------------------------------
-------------------------------------- appstore ------------------------------------------------------------


-- 创建一个订单，返回订单号
-- 返回值：
--	 1、订单号，出错则为 nil
--	 2、如果出错，则返回错误号
function base.CMD.create_appstore_order(_userId,_product_id,_transaction_id,_is_sandbox,_convert,_definition_id)

	local _money_type = "rmb"
	local _channel_type = "appstore"

	local goods = LL.appstore_shoping_goods_config[_product_id]
	if not goods then
		print("product_id error : ".._product_id)
		return nil,1001
	end

	goods.pay_title = goods.pay_title or ""

	local product_desc_ext = ""
	if _convert then
		product_desc_ext = "->".._convert
	end

    local order = {
        order_id = PUBLIC.create_order_id(),
        player_id = _userId,
        order_status = "init",
        money_type = _money_type,
        money = goods.price,
        channel_type = _channel_type,
        product_id = goods.id,
		product_count = 1,  -- 数量始终是 1 ！
		product_desc = tostring(goods.pay_title)..product_desc_ext,
        is_test = _is_sandbox,
        channel_product_id = _product_id,
        itunes_trans_id = _transaction_id,
        create_time = os.time(),
        convert = _convert,
		convert_id = goods.convert_id,
		channel_order_id = _definition_id, -- channel_order_id 字段在 appstore 中没用，用来存 definition_id
    }

    LL.appstore_payment_info[_transaction_id] = order

	local sqls = {}

	-- 订单表
	sqls[#sqls + 1] = PUBLIC.format_sql([[insert into player_pay_order
		(order_id,player_id,order_status,money_type,money,
			channel_type,product_id,is_test,create_time,channel_product_id,itunes_trans_id,product_desc,channel_order_id)
		values (%s,%s,"init",%s,%s,%s,%s,%s,FROM_UNIXTIME(%s),%s,%s,%s,%s);]],
			order.order_id,
			_userId,
			_money_type,
			order.money,
			_channel_type,
			order.product_id,
			order.is_test,
			order.create_time,
			order.channel_product_id,
			order.itunes_trans_id,
			order.product_desc,
			order.channel_order_id)

	-- 订单详情表
	local detail = {}
	for _,_asset in ipairs(goods.assets) do
		sqls[#sqls + 1] = string.format("insert into player_pay_order_detail(order_id,asset_type,asset_count,goods_type) values('%s','%s',%d,'%s');",
			order.order_id,_asset.asset_type,_asset.count,_asset.goods_type)

		detail[#detail + 1] = {asset_type=_asset.asset_type,asset_count=_asset.count,goods_type=_asset.goods_type}
	end
	LL.payment_info_detail[order.order_id] = detail

	base.DATA.sql_queue_fast:push_back(table.concat(sqls,"\n"))

    return order.order_id
end

-- 查询一个订单。注意：不能查日志中的订单
-- 返回：
--	1、订单数据
--	2、错误号，如果出错，返回错误号
function base.CMD.query_appstore_order(_itunes_trans_id)

    local order = LL.appstore_payment_info[_itunes_trans_id]

	if order then
		return order
	else
		return nil,2231 -- 订单未找到
	end
end

-- 修改一个订单。注意：不能修改日志中的订单
-- 返回：
--      1、true/false
--      2、错误号 ： 如果失败，则返回错误号
function base.CMD.modify_appstore_order(_order_id,_itunes_trans_id,_order_status,_error_desc,_channel_account_id,_definition_id,_channel_product_id)

    local order = LL.appstore_payment_info[_itunes_trans_id]
    if not order then
        return false,2231
	end

	-- 特别注意：完成后不能再修改，并且完成消息只能有一次，否则后续的资产修改操作会执行多次！！！！
	if "complete" == order.order_status then
		return false,2232
	end

	if not LL.order_status[_order_status] then
		return false,2233
	end

    local sql_update_values = {}
	
    -- 处理需要修改的字段
    local function deal_update_fields(_name,_param_value)
        if nil ~= _param_value and order[_name] ~= _param_value then
            order[_name] = _param_value
            sql_update_values[#sql_update_values + 1] = string.format(" %s=%s ",
									            	_name,
									            	base.PUBLIC.value_to_sql(_param_value))
        end
    end

    deal_update_fields("order_status",_order_status)
    deal_update_fields("error_desc",_error_desc)
    deal_update_fields("channel_order_id",_definition_id)
    deal_update_fields("channel_product_id",_channel_product_id)

	if "complete" == _order_status then
		order["end_time"] = os.time()
		sql_update_values[#sql_update_values + 1] = string.format(" end_time=FROM_UNIXTIME(%u) ",order["end_time"])
	end


	local sql = string.format([[update player_pay_order set %s where order_id='%s';]],
				table.concat(sql_update_values,","),_order_id)

	local goods = LL.appstore_shoping_goods_config[order.channel_product_id]

	-- 通知玩家订单状态（目前 仅成功才通知）
	if "complete" == _order_status then
		--关键打印不能去掉
		dump(order,"pay_order complete !!!!!!!!!!!")
		
		local detail = LL.payment_info_detail[_order_id]
		if not detail then
			nodefunc.send(order.player_id,"notify_pay_order_status",
							2240,"无法完成购买，订单详情数据丢失！",_order_id,order.product_id,_itunes_trans_id,order.channel_order_id)
			return false,2240
		end

		if goods.shop_type == "shop" then

			PUBLIC.complete_shop_order(order,detail)

		elseif goods.shop_type == "gift_bag" then
			
			PUBLIC.complete_gift_bag_order(order,detail)

		else
			error(string.format("shop_type '%s' is incorrect!",tostring(goods.shop_type)))
		end

		base.CMD.add_consume_statistics(order.player_id,"pay",order.money)

		nodefunc.send(order.player_id,"notify_pay_order_status",
						0,nil,_order_id,order.product_id,detail,_itunes_trans_id,order.channel_order_id)
 
		-- 成功订单统计
		sql = sql .. string.format(
			[[insert into player_pay_order_stat(player_id,first_complete_time,first_order_id,last_complete_time,last_order_id,sum_money) 
			values('%s',FROM_UNIXTIME(%u),'%s',FROM_UNIXTIME(%u),'%s',%d) 
			on duplicate key update last_complete_time=FROM_UNIXTIME(%u),last_order_id='%s',sum_money=sum_money+%d;]],
			order.player_id,os.time(),_order_id,os.time(),_order_id,order.money * order.product_count,
			os.time(),_order_id,order.money * order.product_count)..

			-- 增长更新序号
			string.format("update player_info set sync_seq=%d where id='%s';",base.PUBLIC.auto_inc_id("last_player_info_seq"),order.player_id)

		monitor_lib.add_data("pay",order.money)
		--- 支付成功消息 --关键打印不能去掉
		dump(order,"pay_order on_pay_success trigger !!!!!!!!!!!")
		--base.DATA.events.on_pay_success:trigger(order.player_id,tonumber(order.product_id),order.money,order.channel_type)
		--- 向通知中心触发消息
		skynet.send( base.DATA.service_config.msg_notification_center_service , "lua" , "trigger_msg" 
																					, {name = "on_pay_success"} 
																					, order.player_id,tonumber(order.product_id),order.money,order.channel_type)


	elseif "error" == _order_status then

		nodefunc.send(order.player_id,"notify_pay_order_status",
						2241,_error_desc,_order_id,order.product_id,_itunes_trans_id,order.channel_order_id)

	elseif "fail" == _order_status then

		nodefunc.send(order.player_id,"notify_pay_order_status",
						2242,_error_desc,_order_id,order.product_id,_itunes_trans_id,order.channel_order_id)
	end

	base.DATA.sql_queue_fast:push_back(sql)

    return true
end





--[[查询玩家的所有订单表
	主要用于外部查询使用
	有频次限制 10/s
]]
local query_user_pay_order_from_db_clock = {}
function base.CMD.query_user_pay_order_from_db(_userId,_is_history)

	if type(_userId)~="string" or string.len(_userId)<1 then
		return nil,1001
	end

	local key = os.time()
	local num = query_user_pay_order_from_db_clock[key]
	if not num then
		num = 0
		query_user_pay_order_from_db_clock={}
	end
	query_user_pay_order_from_db_clock[key] = num + 1

	if num > 10 then
		return nil,1000
	end

	local order_db = "player_pay_order"
	if _is_history then
		order_db = "player_pay_order_log"
	end

	local sql = string.format([[
		SELECT
		DB_NAME.player_id,
		player_info.`name`,
		DB_NAME.order_id,
		DB_NAME.order_status,
		DB_NAME.error_desc,
		DB_NAME.money_type,
		DB_NAME.money,
		DB_NAME.channel_type,
		DB_NAME.channel_account_id,
		DB_NAME.product_id,
		DB_NAME.product_count,
		DB_NAME.product_desc,
		DB_NAME.is_test,
		DB_NAME.create_time,
		DB_NAME.channel_product_id,
		DB_NAME.channel_order_id,
		DB_NAME.itunes_trans_id,
		DB_NAME.end_time
		FROM
		DB_NAME
		LEFT JOIN player_info ON DB_NAME.player_id = player_info.id
		WHERE DB_NAME.player_id='%s';]]
				,_userId)

	sql = string.gsub(sql,"DB_NAME",order_db)

	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		print(string.format("query_user_pay_order_from_db sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return nil,1001
	end

	-- dump(ret)

	return ret,0
end



--[[查询某个订单的详情
	主要用于外部查询使用
	有频次限制 10/s
]]
local query_user_order_detail_from_db_clock = {}
function base.CMD.query_user_order_detail_from_db(_order_id,_is_history)

	if type(_order_id)~="string" or string.len(_order_id)<1 then
		return nil,1001
	end

	local key = os.time()
	local num = query_user_order_detail_from_db_clock[key]
	if not num then
		num = 0
		query_user_order_detail_from_db_clock={}
	end
	query_user_order_detail_from_db_clock[key] = num + 1

	if num > 10 then
		return nil,1000
	end

	local order_db = "player_pay_order_detail"
	if _is_history then
		order_db = "player_pay_order_detail_log"
	end

	local sql = string.format([[select * from %s where order_id='%s';]]
				,order_db
				,_order_id)
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		print(string.format("query_user_order_detail_from_db sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return nil,1001
	end

	-- dump(ret)

	return ret,0
end

-- 调试环境下 测试充值
function base.CMD.debug_pay(_player_id,_goods_id,_money)
	if not skynet.getcfg("debug") then
		return nil,1002
	end

	LL.debug_temp_money = _money

	local _order_id,_code = base.CMD.create_pay_order(_player_id,"weixin","debug",tonumber(_goods_id) or 4)
	if not _order_id then
		LL.debug_temp_money = nil
		return nil,_code
	end

	local ok,_code = base.CMD.modify_pay_order(_order_id,"complete")

	LL.debug_temp_money = nil

	if ok then
		return {
			money=LL.payment_info[_order_id].money,
			order_id=LL.payment_info[_order_id].order_id,
		}
	else
		return nil,_code
	end
end


-- skynet.timeout(200,function ( ... )
-- 	base.CMD.query_user_pay_order_from_db("01456310")
-- 	base.CMD.query_user_order_detail_from_db("201807180000001YnhM9")
-- end)

return PROTECTED