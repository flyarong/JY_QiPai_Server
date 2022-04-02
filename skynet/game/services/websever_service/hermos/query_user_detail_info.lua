local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"


--[[

]]

local info,errcode = skynet.call(host.service_config.data_service,"lua","query_user_detail_info_from_db",
										request.get.user_id,
										request.get.name,
										request.get.phone_number)

if info then
	echo(cjson.encode({data=info,result=0}))
else
	echo(string.format("{\"result\":%d}",errcode))
end
