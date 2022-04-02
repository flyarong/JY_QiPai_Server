--
-- Author: lyx
-- Date: 2018/5/24
-- Time: 15:14
-- 说明：处理支付
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "normal_enum"

local DATA = base.DATA
local CMD = base.CMD
local PUBLIC = base.PUBLIC
local REQUEST = base.REQUEST

local act_lock = nil

function REQUEST.create_pay_order(_data)
	
	if type(_data.channel_type)~="string"
		or type(_data.goods_id)~="number"
		or (_data.convert and not ASSETS_CONVERT_TYPE[_data.convert] )
		 	then
		return {result=1001}
	end

	local config_pay_url = skynet.getcfg("payment_url")

	local order_id,errcode = skynet.call(DATA.service_config.pay_service,"lua","create_pay_order",
											DATA.my_id,_data.channel_type,"game",_data.goods_id,_data.convert)

	if order_id then
		return {result=0,order_id=order_id,url = "y" == _data.geturl and config_pay_url or nil }
	else
		return {result=errcode }
	end
end


function PUBLIC.query_all_gift_bag_status()
	local d = skynet.call(base.DATA.service_config.pay_service,"lua","query_player_all_gift_bag_status",DATA.my_id)
	return d
end


--查询礼包  0-no  1-yes
function REQUEST.query_gift_bag_status(_data)

	if act_lock then
		return {result = 1008}
	end

	if not _data or not _data.gift_bag_id or type(_data.gift_bag_id)~="number" then
		return {result = 1002}
	end

	act_lock = true

	local d = skynet.call(base.DATA.service_config.pay_service,"lua","query_player_gift_bag_status",DATA.my_id,_data.gift_bag_id)
	
	act_lock = nil

	local status = 1

	if d.result ~= 0 then
		status = 0
	end
	
	return {
				result=0,
				status=status,
				gift_bag_id=_data.gift_bag_id,
				permit_time = d.permit_time,
			}

end


function CMD.gift_bag_status_change_msg(_gift_bag_id,_status,_permit_time)
	
	base.PUBLIC.request_client("gift_bag_status_change_msg",{
		status = _status,
		gift_bag_id = _gift_bag_id,
		permit_time = _permit_time,
	})

end


--查询礼包 num
function REQUEST.query_gift_bag_num(_data)

	if act_lock then
		return {result = 1008}
	end

	if not _data or not _data.gift_bag_id or type(_data.gift_bag_id)~="number" then
		return {result = 1002}
	end

	act_lock = true

	local num = skynet.call(base.DATA.service_config.pay_service,"lua","query_gift_bag_num",_data.gift_bag_id)
	
	act_lock = nil
	
	return {
				result=0,
				num=num,
				gift_bag_id=_data.gift_bag_id,
			}

end


-- 订单充值结果
-- 参数 _result ：如果为 0 表示成功，其他值表示出错，错误信息在 _errinfo 中
function CMD.notify_pay_order_status(_result,_errinfo,_order_id,_goods_id,_goods_detail,_transaction_id,_definition_id)
	
	base.PUBLIC.request_client("notify_pay_order_msg",{
		result = _result,
		error_info = _errinfo,
		order_id = _order_id,
		goods_id = _goods_id,
		transaction_id = _transaction_id,
		definition_id = _definition_id,
	})

end

function CMD.notify_pay_order_asset_change_msg(_goods_detail,_log_type,_order_id)
	
	if _goods_detail then

		local asset_datas = {}
		for _,_asset in ipairs(_goods_detail) do
			asset_datas[#asset_datas+1]={
				asset_type = _asset.asset_type,
				value = _asset.asset_count,
			}
		end
		
		base.CMD.multi_asset_on_change_msg(asset_datas,_log_type)

	end

end