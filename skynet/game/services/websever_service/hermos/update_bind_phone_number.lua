local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

--[[
	http://127.0.0.1:8001/hermos/update_bind_phone_number?user_id=01100581&phone_number=13201212356&opt_admin=dsd
]]

local status,errcode = skynet.call(host.service_config.data_service,"lua","external_update_bind_phone_number",
										request.get.user_id,
										request.get.phone_number,
										request.get.opt_admin)

if status then
	echo(cjson.encode({result=0}))
else
	echo(string.format("{\"result\":%d}",errcode))
end
