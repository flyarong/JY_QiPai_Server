local skynet = require "skynet_plus"
local cjson = require "cjson"
require "printfunc"
local basefunc = require "basefunc"

local get = request.get

local ok,errcode = skynet.call(host.service_config.pay_service,"lua","modify_pay_order",
	get.order_id,get.order_status,get.error_desc,get.channel_account_id,get.channel_order_id,get.channel_product_id,get.itunes_trans_id)

if ok then
	echo("{\"result\":0}")
else
	echo(string.format("{\"result\":%d}",errcode))
end


