--
-- Author: lyx
-- Date: 2018/5/30
-- Time: 11:09
-- 说明：绑定手机
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local cjson = require "cjson"

require"printfunc"

require "normal_enum"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA


local act_lock = false

-- 发送手机 绑定短信
-- 返回值： 成功 0 ，其它值为错误号
function CMD.pay_phone_tariffe(_userId,_phone)

	local pay_phone_tariffe_url = skynet.getcfg("pay_phone_tariffe_url")

	local pay_phone_tariffe_goodsid = skynet.getcfg("pay_phone_tariffe_goodsid")

	if not _phone or not _userId then
		return 1001
	end

	if not pay_phone_tariffe_url then
		print("error pay_phone_tariffe_url is nil ")
		return 2045
	end

	if act_lock then
		return 1008
	end
	act_lock = true

	local token,error_code = skynet.call(DATA.service_config.data_service,"lua","create_shop_token",_userId)
	if not token then
		return error_code
	end


	local post_data = string.format([[
									{
										"data":{
											"token":"%s",
											"goodsId":"%s",
											"shippingInfo":{"mobile":"%s"}
										}
									}
									]]
									,token,pay_phone_tariffe_goodsid,_phone)

	dump(post_data)

	local ok,content = skynet.call(base.DATA.service_config.webclient_service,"lua",
									"request_post_json", pay_phone_tariffe_url,post_data)

	if not ok then
		act_lock = false
		return 2406
	end

	local ok, _ret = pcall( cjson.decode, content )

	if not ok then
		print("send_pay_phone_tariffe result error:",content,_ret)
		act_lock = false
		return 2408
	end

	if pay_phone_tariffe_note then
		CMD.send_phone_sms(_phone,skynet.getcfg("pay_phone_tariffe_note"))
	end

	if _ret.data and _ret.data > 0 then
		--ok
		print("pay_phone_tariffe ok : ",_userId,_phone,_ret.data)
	else
		dump(_ret)
		act_lock = false
		return 2408		
	end

	act_lock = false
	return 0
end