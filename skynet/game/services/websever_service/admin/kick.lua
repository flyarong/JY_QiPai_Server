local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

local errcode = skynet.call(host.service_config.service_console,"lua","kick_user",request.get.user_id)

echo(string.format("{\"result\":%d}",errcode))