--
-- Created by lyx.
-- User: hare
-- Date: 2018/6/4
-- Time: 1:47
--
--

local skynet = require "skynet_plus"
local cjson = require "cjson"
require "printfunc"
local basefunc = require "basefunc" 

local get = request.get

local ok,errcode = skynet.call(host.service_config.data_service,"lua","change_withdraw_status",
	get.withdraw_id,get.withdraw_status,get.channel_withdraw_id,get.error_desc)

if ok then
	echo("{\"result\":0}")
else
	echo(string.format("{\"result\":%d}",errcode))
end


