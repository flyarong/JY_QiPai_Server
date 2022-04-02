local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

local orders,errcode = skynet.call(host.service_config.collect_service,"lua",
"query_payment_order_list",request.get.recharge_time_start)

if orders then
	echo(cjson.encode(orders))
else
	echo(string.format("{\"result\":%d}",errcode))
end
