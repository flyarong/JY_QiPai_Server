--
-- Created by lyx.
-- User: hare
-- Date: 2018/6/4
-- Time: 1:44
-- 查询提现单
--

local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

local withdraw_data,errcode = skynet.call(host.service_config.data_service,"lua","query_withdraw_data",request.get.withdraw_id)

if withdraw_data then
	withdraw_data.result = 0
	echo(cjson.encode(withdraw_data))
else
	echo(string.format("{\"result\":%d}",errcode))
end

