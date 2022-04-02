local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

local errcode = skynet.call(host.service_config.service_console,"lua","modify_user",
	request.get.user_id,
	request.get.status,
	request.get.phone,
	request.get.sex,
	request.get.nickname,
	request.get.block_reason
	)

echo(string.format("{\"result\":%d}",errcode))