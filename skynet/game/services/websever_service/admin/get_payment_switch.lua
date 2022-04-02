local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"


local ret = skynet.call(host.service_config.pay_service,"lua","get_payment_switch")

local switch = {}
for _name,_value in pairs(ret) do
	switch[_name] = _value and "enable" or "disable"
end

echo(cjson.encode({result=0,switch=switch}))
