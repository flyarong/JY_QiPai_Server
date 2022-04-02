--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：发公告
-- 使用方法：
-- call data_service exe_file "hotfix/fix_pay_order.lua"
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require"printfunc"

local monitor_lib = require "monitor_lib"

local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC
local REQUEST=base.REQUEST


require "normal_enum"

local payment_config = require "payment_config"

local LL = DATA.payment_info_data


local order_status={
	create=true,
	error=true,
	fail=true,
	complete=true,
    SYSTEMERROR=true,
}

local function complete_shop_order(_order,_detail)

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

		print(" complete_shop_order convert error: ".._order.convert)
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


local function complete_gift_bag_order(_order,_detail)

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

	if not order_status[_order_status] then
		return false,2233
	end

	local procid = tonumber(order.product_id)
	if not procid then
		--print("modify_pay_order 1001 error!",_order_id,order.product_id,tonumber(order.product_id),basefunc.tostring(order))
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

				complete_shop_order(order,detail)

			elseif goods.shop_type == "gift_bag" then
				
				complete_gift_bag_order(order,detail)

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
			skynet.send( DATA.service_config.msg_notification_center_service , "lua" , "trigger_msg" 
																				, {name = "on_pay_success"} 
																				, order.player_id,procid,order.money,order.channel_type )

		elseif "error" == _order_status then

			nodefunc.send(order.player_id,"notify_pay_order_status",2241,_error_desc,_order_id,order.product_id)

		elseif "fail" == _order_status then

			nodefunc.send(order.player_id,"notify_pay_order_status",2242,_error_desc,_order_id,order.product_id)
		end
		
		base.DATA.sql_queue_fast:push_back(sql)
	end,basefunc.error_handle)

	LL.modify_pay_order_player_lock[order.player_id] = nil

	if not ok then
		print("modify payment status error:",msg)
	end

    return _succ,_errcode
end


return function()

    -- return LL.payment_info["201905140000383uyUyH"]
	
	return "3333333"

end