local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

local order_data,errcode = skynet.call(host.service_config.pay_service,"lua","query_pay_order",request.get.order_id)

if order_data then
	order_data.result = 0
	echo(cjson.encode(order_data))
else
	echo(string.format("{\"result\":%d}",errcode))
end


