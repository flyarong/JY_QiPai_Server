local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

local consumptions,errcode = skynet.call(host.service_config.collect_service,"lua","collect_consumption_after_seq",request.get.seq_start,request.get.count)

if consumptions then
	if consumptions[1] then
		echo(cjson.encode({result=0,consumptions=consumptions}))
	else
		echo("{\"result\":0,\"consumptions\":[]}")
	end
else
	echo(string.format("{\"result\":%d}",errcode))
end
