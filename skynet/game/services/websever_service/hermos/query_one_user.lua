local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

-- local user,errcode = skynet.call(host.service_config.collect_service,"lua","query_user",
-- 	request.get.user_id,request.get.weixin_union_id)
local user,errcode = skynet.call(host.service_config.data_service,"lua","query_one_user",
	request.get.user_id,request.get.weixin_union_id)

if user then
	user.result=0
	echo(cjson.encode(user))
else
	echo(string.format("{\"result\":%d}",errcode))
end
