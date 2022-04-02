--
-- Author: lyx
-- Date: 2018/5/30
-- Time: 11:09
-- 说明：商城购物 和 商家服务购买
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local cjson = require "cjson"
require"printfunc"

require "normal_enum"

local monitor_lib = require "monitor_lib"

local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC

local PROTECTED = {}

local broadcast_data = {}

--[[
-- 玩家在商城的 token ： token -> 数据
-- 数据结构说明：
	token = {user_id=,create_time=,}
--]]
PROTECTED.shop_token = {}
local shop_token = PROTECTED.shop_token


local used_order_ids = {}



-- 进行广播
function PROTECTED.broadcast_msg(_user_name,_desc,_order_id)

	local content = string.gsub(_desc,"_%d$","")

	-- if string.find(_desc,"红包") then
	-- 	content = string.gsub(_desc,"_%d$","")
	-- else
	-- 	content = string.gsub(_desc,"_"," ") .. "件"
	-- end

	broadcast_data[_order_id] = {
		time = os.time() + 10,
		func = function ()
			skynet.send(base.DATA.service_config.broadcast_center_service,"lua",
							"fixed_broadcast","user_shoping_gold_pay",_user_name,content)
		end
	}

	skynet.timeout(1000,function ()
		
		local d = broadcast_data[_order_id]

		if d then
			d.func()
			broadcast_data[_order_id] = nil
		end

	end)

end


-- 创建 token
-- 返回值：
--		1、token，出错则为 nil
--		2、如果出错，则为错误号
function base.CMD.create_shop_token(_userId)

	if not _userId then
		return nil,2251
	end

	if skynet.getcfg("forbid_shoping") then
		return nil,2403
	end

	local user_name = base.CMD.get_player_info(_userId,"player_info","name")
	if not user_name then
		return nil,2251
	end

	local token = skynet.random_str(30)
	shop_token[token] = {user_id=_userId,name=user_name,create_time=os.time() }

	print("create_shop_token,userId,token:",_userId,token)
	return token
end


-- 得到 玩家购物金道具：各种面额的集合
-- 注意：面额 为字符串，否则 转为 json 会报错
local function get_shop_golds(_userId)

	local ret = {}

	for _type,_face in pairs(SHOP_GOLD_FACEVALUES) do
		ret[tostring(_face)] = base.CMD.get_prop(_userId,_type)
	end


	return ret
end

-- 根据 userid 得到用户 购物相关的信息
-- 返回值：
--		1、用户信息表，出错则为 nil
--		2、如果出错，则为错误号
function base.CMD.get_shop_info_by_id(_userId)

	if not _userId then
		return nil,2251
	end

	local user = base.PUBLIC.load_player_info(_userId)
	if not user then
		return nil,2251
	end

	if not user.player_info then
		return nil,1010
	end


	local user_name = base.CMD.get_player_info(_userId,"player_info","name")
	if not user_name then
		return nil,2251
	end

	return {
		user_id=_userId,
		nickname=user.player_info.name,
		-- shop_golds=get_shop_golds(_userId),
		shop_golds={["1"]=user.player_asset.shop_gold_sum},
		status=user.player_info.is_block == 1 and "disable" or  "enable"
	}

end

-- 根据 token 得到用户 购物相关的信息
-- 返回值：
--		1、用户信息表，出错则为 nil
--		2、如果出错，则为错误号
function base.CMD.get_shop_info_by_token(_token)

	if not _token then
		return nil,2252
	end

	local user_info = shop_token[_token]

	if not user_info then
		return nil,2252
	end

	local token_timeout = tonumber(skynet.getcfg("shop_token_timeout")) or 180

	if os.time() - user_info.create_time > token_timeout then
		shop_token[_token] = nil
		return nil,2252
	end

	return base.CMD.get_shop_info_by_id(user_info.user_id)

	-- return {
	-- 	user_id=user_info.user_id,
	-- 	nickname=user_info.name,
	-- 	shop_golds=get_shop_golds(user_info.user_id),
	-- 	status="enable"
	-- }

end

-- 用于通过购物金 买东西
-- 返回值：
--		1、true/false 是否成功
--		2、如果出错，则为错误号
function base.CMD.user_shoping_gold_pay(_userId,_amount,_order_id,_shoping_desc)

	if not _userId then
		return nil,2251
	end

	if not _order_id then
		return nil,2254
	end
	
	if used_order_ids[_order_id] then
		return nil,2254
	end

	local user = base.PUBLIC.load_player_info(_userId)
	if not user then
		return nil,2159
	end	
	
	_amount = tonumber(_amount)

	if not _amount then
		return nil,1001
	end

	if user.player_asset.shop_gold_sum < _amount then
		return nil,2253
	end

	if _shoping_desc and type(_shoping_desc)== "string" then
		PROTECTED.broadcast_msg(user.player_info.name,_shoping_desc,_order_id)
	end

	base.CMD.add_consume_statistics(_userId,"cost_shop_gold",-_amount)

	used_order_ids[_order_id] = true

	base.CMD.change_asset_and_sendMsg(_userId,"shop_gold_sum",-_amount,ASSET_CHANGE_TYPE.SHOPING,_order_id)

	-- 记录日志
	base.DATA.sql_queue_slow:push_back(PUBLIC.format_sql("insert into player_shop_order(order_id,player_id,props_json,amount,shoping_desc) values(%s,%s,%s,%s,%s); ",
	_order_id,_userId,"",_amount,_shoping_desc or ""))

	monitor_lib.add_data("redshop",_amount)

	return true
end

-- 退款（购物金 买东西）
-- 返回值：
--		1、true/false 是否成功
--		2、如果出错，则为错误号
function base.CMD.user_shoping_gold_refund(_order_id)
	-- _userId,_amount,_order_id,_shoping_desc

	local sql = string.format("select player_id,order_status,amount from player_shop_order where order_id='%s'",tostring(_order_id))
	local ret = base.DATA.db_mysql:query(sql)
	
	if( ret.errno ) then
		print(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return nil,1010
	end

	local _order = ret[1]

	if not _order then
		return nil,2231
	end

	if _order.order_status ~= "complete" then
		return nil,2255
	end
	
	local user = base.PUBLIC.load_player_info(_order.player_id)
	if not user then
		return nil,2159
	end	
	
	_order.amount = tonumber(_order.amount)

	if not _order.amount then
		return nil,1004
	end

	base.CMD.add_consume_statistics(_order.player_id,"cost_shop_gold",_order.amount)


	base.CMD.change_asset_and_sendMsg(_order.player_id,"shop_gold_sum",_order.amount,ASSET_CHANGE_TYPE.SHOPING_REFUND,_order_id)

	-- 记录日志
	base.DATA.sql_queue_slow:push_back(string.format("update player_shop_order set order_status='refund',refund_time=FROM_UNIXTIME(%u) where order_id='%s'",os.time(),_order_id))


	-- 去掉广播
	broadcast_data[_order_id] = nil

	-- monitor_lib.add_data("redshop",_amount)

	return true
end

-- 专属的退款（购物金 买东西）
-- （退给另外的人，并且扣 手续费）
-- 参数 ：_player_id 收款玩家
--		 _cancel_fee 扣手续费
-- 返回值：
--		1、true/false 是否成功
--		2、如果出错，则为错误号
function base.CMD.user_reserve_shoping_gold_refund(_order_id,_player_id,_cancel_fee)
	
	if not type(_player_id) == "string" then
		return nil,1001
	end

	_cancel_fee = tonumber(_cancel_fee)
	if not _cancel_fee or _cancel_fee < 0 then
		return nil,1001
	end

	if not base.CMD.is_player_exists(_player_id) then
		return nil,1001
	end

	local sql = string.format("select player_id,order_status,amount from player_shop_order where order_id='%s'",tostring(_order_id))
	local ret = base.DATA.db_mysql:query(sql)
	
	if( ret.errno ) then
		print(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return nil,1010
	end

	local _order = ret[1]

	if not _order then
		return nil,2231
	end

	if _order.order_status ~= "complete" then
		return nil,2255
	end
	
	local user = base.PUBLIC.load_player_info(_order.player_id)
	if not user then
		return nil,2159
	end	
	
	_order.amount = tonumber(_order.amount)

	if not _order.amount then
		return nil,1004
	end

	if _cancel_fee >= _order.amount then
		return nil,1013
	end

	base.CMD.add_consume_statistics(_player_id,"cost_shop_gold",_order.amount - _cancel_fee)


	base.CMD.change_asset_and_sendMsg(_player_id,"shop_gold_sum",_order.amount - _cancel_fee,ASSET_CHANGE_TYPE.SHOPING_REFUND,_order_id)

	-- 记录日志
	base.DATA.sql_queue_slow:push_back(string.format("update player_shop_order set order_status='refund',refund_time=FROM_UNIXTIME(%u) where order_id='%s'",os.time(),_order_id))


	-- 去掉广播
	broadcast_data[_order_id] = nil

	-- monitor_lib.add_data("redshop",_amount)

	return true	
end

-- 记录最近用过的订单，做重复检查
local used_merchant_order_ids = {}

-- 用于通过购物金 从线下商家 买服务
-- 返回值：
--		1、true/false 是否成功
--		2、如果出错，则为错误号
function base.CMD.user_merchant_gold_pay(_userId,_amount,_order_id,_shoping_desc)

	if not _userId then
		return nil,2251
	end

	if not _order_id then
		return false,2254
	end

	if used_merchant_order_ids[_order_id] then
		return false,2254
	end

	local user = base.PUBLIC.load_player_info(_userId)
	if not user then
		return nil,2159
	end	
	
	_amount = tonumber(_amount)

	if not _amount then
		return nil,1001
	end

	if user.player_asset.shop_gold_sum < _amount then
		return nil,2253
	end

	base.CMD.add_consume_statistics(_userId,"cost_shop_gold",-_amount)

	used_merchant_order_ids[_order_id] = true



	base.CMD.change_asset_and_sendMsg(_userId,"shop_gold_sum",-_amount,ASSET_CHANGE_TYPE.MERCHANT_BUY,_order_id)

	-- 记录日志
	base.DATA.sql_queue_slow:push_back(PUBLIC.format_sql("insert into player_merchant_order(order_id,player_id,props_json,amount,shoping_desc) values(%s,%s,%s,%s,%s); ",
	_order_id,_userId,"",_amount,_shoping_desc or ""))

	return true
end

return PROTECTED