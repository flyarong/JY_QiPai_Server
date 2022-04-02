local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"


--[[
http://127.0.0.1:8001/hermos/decrease_player_asset?user_id=0110058&asset_type=diamond&change_value=-200&opt_admin=opt_admin&reason=reason
]]

local status,errcode = skynet.call(host.service_config.data_service,"lua","admin_decrease_player_asset",
										request.get.user_id,
										request.get.asset_type,
										request.get.change_value,
										request.get.opt_admin,
										request.get.reason)

if status then
	echo(cjson.encode({result=0}))
else
	echo(string.format("{\"result\":%d}",errcode))
end
