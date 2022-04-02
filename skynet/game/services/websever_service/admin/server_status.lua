local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

local function trans_switch_dict(data)
	local switch = {}
	for _name,_value in pairs(data) do
		switch[_name] = _value and "enable" or "disable"
	end

	return switch
end

local ret_data = {
	online_user_count = skynet.call(host.service_config.data_service,"lua","get_online_user_count"),
	payment_switch = trans_switch_dict(skynet.call(host.service_config.pay_service,"lua","get_payment_switch")),
	login_switch = trans_switch_dict(skynet.call(host.service_config.login_service,"lua","get_login_switch")),
}

echo(cjson.encode(ret_data))