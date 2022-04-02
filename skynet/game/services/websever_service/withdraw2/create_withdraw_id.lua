local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

local get = request.get

local player_id = get.user_id or get.player_id

local withdraw_id,errcode = skynet.call(host.service_config.data_service,"lua","create_withdraw_id",
										player_id,get.channel_type,"common_ht","cash",get.channel_receiver_id,get.money,get.comment)

if withdraw_id then

	echo(cjson.encode({result=0,withdraw_id=withdraw_id}))
else
	echo(string.format("{\"result\":%d}",errcode))
end
