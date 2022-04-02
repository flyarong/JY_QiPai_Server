--
-- Created by lyx.
-- User: hare
-- Date: 2018/6/8
-- Time: 14:36
-- 商城：线上通过抵扣券买东西
--


local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST

function REQUEST.create_shoping_token(_data)

	local config_shop_url = skynet.getcfg("shoping_url")

	local token,errcode = skynet.call(DATA.service_config.data_service,"lua","create_shop_token",DATA.my_id)

	if token then
		return {result=0,token=token,url = "y" == _data.geturl and config_shop_url or nil }
	else
		return {result=errcode }
	end
end