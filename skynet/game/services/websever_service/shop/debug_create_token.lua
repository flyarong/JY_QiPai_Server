local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

if not host.is_debug then
	echo("only allow in debug !")
	return
end

local token,errcode = skynet.call(host.service_config.data_service,"lua","create_shop_token",request.get.user_id)

if token then

	echo(cjson.encode({result=0,token=token}))
else
	echo(string.format("{\"result\":%d}",errcode))
end


