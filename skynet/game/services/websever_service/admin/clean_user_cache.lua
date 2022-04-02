local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

local errcode = skynet.call(host.service_config.data_service,"lua","clean_user_cache",request.get.offline_time)

echo(string.format("{\"result\":%d}",errcode))