local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

local ret = skynet.call(host.service_config.game_manager_service,"lua","reload_config")

echo(cjson.encode(ret))

