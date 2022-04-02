local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

local errcode = skynet.call(host.service_config.collect_service,"lua","update_agent_role",request.get.user_id,request.get.is_agent)

echo(string.format("{\"result\":%d}",errcode))
