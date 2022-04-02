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

local act_lock = nil

-- 创建一个订单，返回订单号
-- 返回值：
--	 1、订单号，出错则为 nil
--	 2、如果出错，则返回错误号
function CMD.create_pay_order(_userId,_channel_type,_source_type,_goods_id,_convert)
	if not _channel_type then
		return nil,1001
	end

	if DATA.pay_switch_config[_channel_type] == false then
		return nil,2403
	end

	if act_lock then
		return nil,1008
	end

	act_lock = true

	if DATA.shoping_config[_goods_id] then

		local ret = CMD.get_create_gift_bag_order_status(_userId,_goods_id)
		if ret.result ~= 0 then
			act_lock = nil
			return nil,ret.result
		end

	end

	local ret,errcode = skynet.call(DATA.service_config.data_service,"lua","create_pay_order",_userId,_channel_type,_source_type,_goods_id,_convert)

	act_lock = nil

	return ret,errcode
end


-- 查询一个订单。注意：不能查日志中的订单
-- 返回：
--	1、订单数据
--	2、错误号，如果出错，返回错误号
function CMD.query_pay_order(_order_id)
	return skynet.call(DATA.service_config.data_service,"lua","query_pay_order",_order_id)
end


-- 修改一个订单。注意：不能修改日志中的订单
-- 返回：
--      1、true/false
--      2、错误号 ： 如果失败，则返回错误号
function CMD.modify_pay_order(_order_id,_order_status,_error_desc,_channel_account_id,_channel_order_id,_channel_product_id,_itunes_trans_id)
	return skynet.call(DATA.service_config.data_service,"lua","modify_pay_order",_order_id,_order_status,_error_desc,_channel_account_id,_channel_order_id,_channel_product_id,_itunes_trans_id)
end