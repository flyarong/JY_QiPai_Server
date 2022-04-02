local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

local user_data,errcode = skynet.call(host.service_config.data_service,"lua","get_shop_info_by_token",request.get.token)

if user_data then
	user_data.result = 0
	echo(cjson.encode(user_data))
else
	echo(string.format("{\"result\":%d}",errcode))
end


