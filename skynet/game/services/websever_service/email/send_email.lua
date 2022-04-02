local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"


--[[
	type
		"sys_welcome" -- 系统欢迎邮件
		"native" -- 原生邮件 邮件内容在data中的content中
	title
	sender
	valid_time -- 选填(默认0)大于0才有效
	data -- 选填(默认{})

	\ 反斜杠会被解码两次，所以这里要先对 \ 补一个\

	如果是原生邮件content直接写邮件内容不要带%s 附带的奖励直接写财务类型放到data中

]]

--[[

 {"players": ["0159375"],"email": {"type": "native","title": "hello","sender": "xt","valid_time": 1321547864,"data": "{content='xxx cash120,zjzl',cash=100}"}}&opt_admin=xxx&reason=xxx

	data={
		"players": ["016527"],
		"email": {
			"type": "native",
			"title": "hello",
			"sender": "系统",
			"valid_time": 1321547864,
			"data": "{content='恭喜你获得了cash120,再接再厉',cash=100}"
		}
	}&opt_admin=xxx&reason=xxx
]]

local ok, arg = xpcall(function ()
		request.get.data = string.gsub(request.get.data,"\\","\\\\")
		return cjson.decode(request.get.data)
	end,function (error)
	end)

if not ok then
	echo("{\"result\":1001,\"error\":\"data json parse error\"}")
	return
end


local errcode = skynet.call(host.service_config.email_service,"lua",
										"external_send_email",
										arg,
										request.get.opt_admin,
										request.get.reason)

if errcode then
	echo(string.format("{\"result\":%d}",errcode))
end
