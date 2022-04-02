local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

local param = {}
for _name,_value in pairs(request.get) do
	param[_name] = "enable" == _value
end

local errcode = skynet.call(host.service_config.login_service,"lua","set_login_switch",param)

echo(string.format("{\"result\":%d}",errcode))
