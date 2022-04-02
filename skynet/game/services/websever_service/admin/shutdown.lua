local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

skynet.timeout(1,function ()
	skynet.call(host.service_config.service_console,"lua","shutdown")
end)


-- 关机指令，总是返回成功
echo("{\"result\":0}")