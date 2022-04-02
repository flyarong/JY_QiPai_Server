local skynet = require "skynet_plus"
local cjson = require "cjson"
require "printfunc"
local basefunc = require "basefunc"

if skynet.getcfg("forbid_external_order") then
	
	echo("{\"result\":2403}")

else

	local get = request.get

	local order_id,errcode = skynet.call(host.service_config.pay_service,"lua","create_pay_order",
		get.user_id,get.channel_type,"web",tonumber(get.goods_id),get.convert)

	if order_id then
		echo(string.format("{\"result\":0,\"order_id\":\"%s\"}",order_id))
	else
		echo(string.format("{\"result\":%d}",tostring(errcode)))
	end
end

