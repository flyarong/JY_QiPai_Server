--
-- Author: lyx
-- Date: 2018/5/30
-- Time: 11:09
-- 说明：绑定手机
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

-- 阿里云的 短信发送接口
local function send_sms_aliyun(_phone,_code)

	local sms_url = skynet.getcfg("send_phone_sms_url")
	local signName = skynet.getcfg("signName_bind_phone") --basefunc.escape_uri(skynet.getcfg("signName_bind_phone"))
	local templateCode = skynet.getcfg("templateCode_bind_phone")

	if not sms_url or not signName or not templateCode then
		return 2405
	end

	local ok,content = skynet.call(base.DATA.service_config.webclient_service,"lua",
									"request",sms_url,{
											templateCode=templateCode,
											mobile=_phone,
											signName=signName,
											code=_code,
										})
	if not ok then
		return 2406
	end

	local ok, _ret = pcall( cjson.decode, content )

	if not ok then
		print("sms server result error:",content,_ret)
		return 2407
	end

	if not _ret or not _ret.code then
		return 2402
	end

	if "ok" ~= string.lower(_ret.code) then
		print("send sms error:",content)
		return 2406
	end

	return 0
end

-- 一个不知名平台的 发送接口
local function send_sms2(_phone,_text)

	local sms_url = skynet.getcfg("send_phone_sms_url")
	if not sms_url then
		print("send sms error:not config 'send_phone_sms_url' !")
		return 2405
	end

	local ok,content = skynet.call(base.DATA.service_config.webclient_service,"lua",
									"request",sms_url,{
											mobile=_phone,
											msg=_text,
										})
	if not ok then
		print("request sms server error:",content,_phone)
		return 2406
	end

	local ok, _ret = pcall( cjson.decode, content )

	if not ok then
		print("sms server result error:",content,_ret,_phone)
		return 2407
	end

	if not _ret or not _ret.status then
		print("request sms server error:no result!",_phone)
		return 2402
	end

	if "yes" ~= string.lower(_ret.status) then
		print("send sms error:",content,_phone)
		return 2406
	end

	print(string.format("send phone '%s' sms succ:%s",tostring(_phone),tostring(_text)))

	return 0

end

-- 发送手机 绑定短信
-- 返回值： 成功 0 ，其它值为错误号
function CMD.send_phone_bind_code(_phone,_code)

	local cfg = skynet.getcfg("bind_phone_code_sms")

	if not cfg or type(cfg)~="string" then
		print("send sms error:not config 'bind_phone_code_sms' !")
		return 2405
	end

	return send_sms2(_phone,string.format(cfg,_code))

end

-- 单纯的只是 发送短信
function CMD.send_phone_sms(_phone,_text)
	return send_sms2(_phone,_text)
end