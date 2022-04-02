--
-- Author: lyx
-- Date: 2018/4/26
-- Time: 17:34
-- 说明：管理功能函数
--

local skynet = require "skynet_plus"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local base=require "base"

local cluster = require "skynet.cluster"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA


--[[ 修改用户
  参数
	_user_id ： 玩家 id
	_status ：enable/disable ， disable 表示封禁； enable 表示解封。
	_phone : 电话号码
	_sex :  0 女，1 男
	_nickname : 昵称

 返回值： 0 成功；或错误号
--]]
function CMD.modify_user(_user_id,_status,_phone,_sex,_nickname,_block_reason)

	if not _user_id then
		return 1001
	end

	if not skynet.call(DATA.service_config.data_service,"lua","is_player_exists",_user_id) then
		return 1004
	end

	if _phone and (type(_phone)~="string" or string.len(_phone)<3) then
		return 1001
	end

	local _md_data = {
		phone = _phone,
		name = _nickname,
	}
	if _status then
		_md_data.is_block = "enable" == _status and 0 or 1
		local ret = 0
		if _md_data.is_block == 1 then
			ret = skynet.call(DATA.service_config.data_service,"lua","block_player",_user_id,_block_reason)
		else
			ret = skynet.call(DATA.service_config.data_service,"lua","unblock_player",_user_id,_block_reason)
		end
		if ret ~= 0 then
			return ret
		end
	end
	if _sex then
		_md_data.sex = "0" == _sex and 0 or 1
	end

	-- 直接绑定手机号码
	skynet.send(DATA.service_config.data_service,"lua","add_bind_phone_number",
						_user_id,
						_phone)

	return skynet.call(DATA.service_config.data_service,"lua","modify_player_info",_user_id,"player_info",_md_data)
end

--[[ 强制踢用户下线
	_refuse_time ： 此时间内 不允许登录，单位 分钟
 返回值： 0 成功；或错误号
--]]
function CMD.kick_user(_userId,_refuse_time)

	if not _userId then
		return 1001
	end

	if not skynet.call(DATA.service_config.data_service,"lua","is_player_exists",_userId) then
		return 1004
	end

	skynet.call(DATA.service_config.data_service,"lua","reject_user",_userId,_refuse_time)

	return 0
end
