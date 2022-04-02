local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"


--[[

]]

local assets,errcode = skynet.call(host.service_config.data_service,"lua","query_user_assets_from_db",
										request.get.user_id)

if assets then
	echo(cjson.encode({data=assets,result=0}))
else
	echo(string.format("{\"result\":%d}",errcode))
end
