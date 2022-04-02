local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

local users,errcode = skynet.call(host.service_config.collect_service,"lua","collect_user_after_seq",request.get.seq_start,request.get.count)

if users then
	if users[1] then
		echo(cjson.encode({result=0,users=users}))
	else
		echo("{\"result\":0,\"users\":[]}")
	end
else
	echo(string.format("{\"result\":%d}",errcode))
end
