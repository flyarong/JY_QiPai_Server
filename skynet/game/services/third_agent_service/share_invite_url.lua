--
-- Author: lyx
-- Date: 2018/5/30
-- Time: 11:09
-- 说明：分享 邀请链接
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local cjson = require "cjson"

require"printfunc"

require "normal_enum"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA


-- 分享 url
local share_url = nil

local share_url_msg = {
	result = 0,
	share_url = nil,
}


function CMD.get_share_url(_userId,_market_channel)

	local config_shop_url = skynet.getcfg("get_share_url")

	if config_shop_url then
		local get_url,n = string.gsub(config_shop_url,"@userId@",_userId)
		if _market_channel then
			get_url = get_url .. "&market_channel=" .. tostring(_market_channel)
		end

		local ok,content = skynet.call(base.DATA.service_config.webclient_service,"lua",
										"request",get_url)
		if ok then

			local xok,_ret_data = xpcall(function ()
				return cjson.decode(content)
			end,function (error)
				print("error:decode url failed.url:",content)
			end)
			if xok then
				print("get share url. resp data ,req url:",basefunc.tostring(_ret_data),get_url)
				--share_url_msg.share_url = _ret_data.url
				share_url_msg.share_url = _ret_data.data and _ret_data.data.qrcodedata and _ret_data.data.qrcodedata.url or "get url error!"
				share_url_msg.result = 0
			else
				share_url_msg.result = 2406
			end
		else
			print("error:call url failed.url:",get_url)
			share_url_msg.result = 2406
		end
	else
		share_url_msg.result = 2405
		share_url_msg.share_url = "error:server not config 'get_share_url' !"
	end

	return share_url_msg
end