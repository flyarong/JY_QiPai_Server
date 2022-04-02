local skynet = require "skynet_plus"
local cjson = require "cjson"
require "printfunc"
local basefunc = require "basefunc"

local player_id = request.get.player_id

if not player_id or type(player_id) ~= "string" then
	echo("{\"result\":1001}")
end

local ret,goods_list = skynet.call(host.service_config.data_service,"lua","get_goods_list",player_id)

if ret ~= 0 then
	echo("{\"result\":"..ret.."}")
else
	echo(cjson.encode(goods_list))
end

