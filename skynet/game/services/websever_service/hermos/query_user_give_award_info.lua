local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"


--[[
	is_history 可不填 默认为不是历史 否则则认为是历史 内容可以填字符串或者数字都可以
]]

local data,errcode = skynet.call(host.service_config.data_service,"lua","query_user_give_award_info_from_db"
										,request.get.user_id)

if data then
	echo(cjson.encode({data=data,result=0}))
else
	echo(string.format("{\"result\":%d}",errcode))
end
