local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"


--[[
	查询用户的消费统计
]]

local data,errcode = skynet.call(host.service_config.data_service,"lua","query_player_consume_statistics",
										request.get.user_id)

if data then
	echo(cjson.encode({data=data,result=0}))
else
	echo(string.format("{\"result\":%d}",errcode))
end
