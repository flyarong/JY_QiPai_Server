local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

local succ,errcode = skynet.call(host.service_config.data_service,"lua",
	"user_reserve_shoping_gold_refund",
	request.get.order_id,
	request.get.player_id,
	request.get.cancel_fee
)

local ret_json = succ and "{\"result\":0}" or string.format("{\"result\":%d}",errcode)

echo(ret_json)
