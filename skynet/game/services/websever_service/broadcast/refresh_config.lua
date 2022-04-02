local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"


--[[
	刷新广播的配置
	
	如果有传参数则把参数作为配置添加到已有的配置中去
	如果没有参数则完全重新载入本地配置文件

	{
	"id" : 11,
	"content" : "<color=%2311ff11>祝大家游戏愉快111</color>",
	"interval" : 1,
	"start_time" : 0,
	"end_time" : -1,
	"channel" : 1
	}
]]
local arg
if request.get.config then
	local ok
	ok, arg = xpcall(function ()
			return cjson.decode(request.get.config)
		end,
		function (error)
		end)

	if not ok then
		echo("{\"result\":1001,\"error\":\"data json parse error\"}")
		return
	end
end

local errcode = skynet.call(host.service_config.broadcast_center_service,"lua",
										"external_refresh_config",
										arg)

if errcode then
	echo(string.format("{\"result\":%d}",errcode))
end
