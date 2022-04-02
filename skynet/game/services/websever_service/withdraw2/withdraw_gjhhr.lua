local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

------ # 注意： 高级合伙人专用接口

local get = request.get

local player_id = get.user_id or get.player_id

local _data,errcode = skynet.call(host.service_config.sczd_gjhhr_service,"lua","withdraw_gjhhr",
										get.player_id,get.channel_type,get.channel_receiver_id,get.money)

if _data then
	_data.result = tostring(_data.result or 0)
	echo(cjson.encode(_data))
else
	echo(string.format("{\"result\":\"%d\"}",errcode))
end
