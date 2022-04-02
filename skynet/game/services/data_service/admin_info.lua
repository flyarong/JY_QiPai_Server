--
-- Author: lyx
-- Date: 2018/5/30
-- Time: 11:09
-- 说明：后台管理功能
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


local PROTECTED = {}

-- 临时限制登录的用户： userId => 时间（os.time(), 此时间之前不允许登录）
-- 注意：停机不保存
DATA.reject_login_users = {}

function PROTECTED.init_admin_info()


	return true
end


-- 加入临时拒绝登录的用户
--  _time 从现在算起的时间，单位 分钟
function CMD.reject_user( _userId,_time )

	_time = tonumber(_time) or 60
	
	if _time > 0 then
		nodefunc.send(_userId,"kick")
	end

	DATA.reject_login_users[_userId] = os.time() + _time * 60
end

--[[ 清理用户缓存

  _offline_time ：离线时间，单位 分钟。 清理离线超过此时间 的所有用户

 返回值： 清理的用户数
--]]
function CMD.clean_user_cache(_offline_time)

	local _count = 0

	_offline_time = (_offline_time or 1) * 60
	
	local pi = PUBLIC.player_info

	local _now = os.time()
	for _userId,_status in pairs(PUBLIC.all_player_status) do
		if pi[_userId] and _status.status == "off" and (_now - _status.time) >= _offline_time then
			pi[_userId] = nil
			_count = _count + 1
		end
	end

	return _count
end

-- 得到在线用户数
function CMD.get_online_user_count()
	return PUBLIC.onine_player_count
end


return PROTECTED