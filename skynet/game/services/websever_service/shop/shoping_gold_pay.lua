local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

local succ,errcode = skynet.call(host.service_config.data_service,"lua","user_shoping_gold_pay",
	request.get.user_id,
	request.get.amount,
	request.get.order_id,
	request.get.shoping_desc
)

local ret_json = succ and "{\"result\":0}" or string.format("{\"result\":%d}",errcode)

echo(ret_json)
