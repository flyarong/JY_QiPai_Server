local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"


--[[
	is_history 可不填 默认为不是历史 否则则认为是历史 内容可以填字符串或者数字都可以
]]

local list,errcode = skynet.call(host.service_config.data_service,"lua","query_block_list_from_db")

if list then
	echo(cjson.encode({data=list,result=0}))
else
	echo(string.format("{\"result\":%d}",errcode))
end
