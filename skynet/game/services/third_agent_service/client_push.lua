--
-- Author: lyx
-- Date: 2018/5/30
-- Time: 11:09
-- 说明：向客户端推送消息
--
-- 友盟文档： https://developer.umeng.com/docs/66632/detail/68343
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local md5 = require "md5"
local cjson = require "cjson"

require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local umeng_send_url = "http://msg.umeng.com/api/send"


-- 推送通知消息 android
function CMD.push_android_notify(_device_tokens,_ticker,_title,_text)

	local appkey = skynet.getcfg("umeng_android_appkey")
	local secret = skynet.getcfg("umeng_android_master_secret")

	if not appkey or not secret then
		return 2405
	end

	local _type,_token
	if not _device_tokens then
		_type = "broadcast"
	elseif type(_device_tokens) == "table" then
		_type = "listcast"
		_token = table.concat(_device_tokens,",")
	else
		_type = "unicast"
		_token = _device_tokens
	end

	local body = {
		appkey=appkey,
		timestamp=os.time()*1000,
		type=_type,
		device_tokens=_token,
		payload={
			display_type="notification",
			body={
				ticker = _ticker,
				title = _title,
				text = _text,
				after_open = "go_app",
				ticker = _ticker,
			},
		},
	}

	local json_body = cjson.encode(body)

	local sign = md5.sumhexa("POST" .. umeng_send_url .. json_body .. secret)
	local ok,content = skynet.call(base.DATA.service_config.webclient_service,"lua",
									"request",
									umeng_send_url,
									{sign=sign},
									json_body
						)

	--dump({ok=ok,content=content,token=_token},"push_android_notify android 1:")

	if not ok then
		print("push android error,call fail,token:",basefunc.tostring(_token))
		return 2402
	end

	if not content then
		print("push android error,contest is nil,token:",basefunc.tostring(_token))
		return 2407
	end

	local con = cjson.decode(content)

	if not con or con.ret ~= "SUCCESS" then
		print("push android error,token,errmsg:",basefunc.tostring(_token),con and con.error_msg)
		return 2406
	end

	return 0
end

-- 推送通知消息 ios
function CMD.push_ios_notify(_device_tokens,_title,_sub_title,_text)

	local appkey = skynet.getcfg("umeng_ios_appkey")
	local secret = skynet.getcfg("umeng_ios_master_secret")
	local pmode = skynet.getcfg("umeng_ios_pmode")

	if not appkey or not secret then
		return 2405
	end

	local _type,_token
	if not _device_tokens then
		_type = "broadcast"
	elseif type(_device_tokens) == "table" then
		_type = "listcast"
		_token = table.concat(_device_tokens,",")
	else
		_type = "unicast"
		_token = _device_tokens
	end

	local body = {
		appkey=appkey,
		timestamp=os.time()*1000,
		type=_type,
		device_tokens=_token,
		payload={
			aps = {
				alert={
					title = _title,
					subtitle = _sub_title,
					body = _text,
				},
			}
		},
		production_mode = pmode,
	}

	local json_body = cjson.encode(body)

	local sign = md5.sumhexa("POST" .. umeng_send_url .. json_body .. secret)
	local ok,content = skynet.call(base.DATA.service_config.webclient_service,"lua",
									"request",
									umeng_send_url,
									{sign=sign},
									json_body
						)

	--dump({ok=ok,content=content,token=_token},"push_ios_notify ios 1:")

	if not ok then
		print("push ios error,call fail,token:",basefunc.tostring(_token))
		return 2402
	end

	if not content then
		print("push ios error,contest is nil,token:",basefunc.tostring(_token))
		return 2407
	end

	local con = cjson.decode(content)

	if not con or con.ret ~= "SUCCESS" then
		print("push ios error,token,errmsg:",basefunc.tostring(_token),con and con.error_msg)
		return 2406
	end

	return 0
end

function CMD.push_notify(_user_ids,_title,_sub_title,_text)

	-- 广播
	if "broadcast" == _user_ids then
		CMD.push_android_notify(nil,_title,_sub_title,_text)
		CMD.push_ios_notify(nil,_title,_sub_title,_text)
		return
	end

	if type(_user_ids) ~= "table" then
		_user_ids = {_user_ids}
	end
	
	local user_tokens = skynet.call(DATA.service_config.data_service,"lua","get_users_device_token",_user_ids)

	if next(user_tokens.android) then
		CMD.push_android_notify(user_tokens.android,_title,_sub_title,_text)
	end

	if next(user_tokens.ios) then
		CMD.push_ios_notify(user_tokens.ios,_title,_sub_title,_text)
	end
end