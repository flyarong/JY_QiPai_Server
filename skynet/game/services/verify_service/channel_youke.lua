--
-- Author: lyx
-- Date: 2018/3/28
-- Time: 15:39
-- 说明：游客登录
--

local skynet = require "skynet_plus"
local base = require "base"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

PUBLIC.channels.youke = {}


--[[产生一个账号 25-32位

]]

--1-63
local Digit={'0','1','2','3','4','5','6','7','8','9','_','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}
local function getDigit(num)
	if num < 1 then return "" end
	if num > #Digit then return "" end
	return Digit[num]
end

--获取一个独一无二的登陆ID
function PUBLIC.youke_gen_login_id()
	local login_id_str = ""
	local count = base.DATA.player_verify_data.count+1

	local di = getDigit(math.random(12,#Digit))
	login_id_str=login_id_str..di

	local idstr = count..""
	local idlen = string.len(idstr)

	for i=1,idlen do
		local num = (tonumber(string.sub(idstr,i,i))+1) * 3
		local di = getDigit(num)
		login_id_str=login_id_str..di
	end

	local accountLen = string.len(login_id_str)
	local dlen = math.random(25,32)
	if accountLen < dlen then
		dlen = dlen-accountLen
	end

	for i=1,dlen do
		local di = getDigit(math.random(1,#Digit))
		login_id_str=login_id_str..di
	end

	return login_id_str
end




--[[
  用户验证函数

  参数：_login_data 玩家登录数据。（参见客户端协议 login ）

  返回值：succ,verify_data, user_data
  	succ : true/false ，验证成功 或 失败
  	verify_data : （必须）验证结果数据，如果失败，则为错误号。
		{
			login_id=, (必须)登录id
			password=, (可选) 用户密码
			refresh_token=, (可选) 刷新凭据，某些渠道需要，比如微信
			extend_1=, (可选)扩展数据1
			extend_2=, (可选)扩展数据2
		}
  	user_data : （可选）用户数据，如果为 nil ，则表明用户数据未改变（此前至少登录过）。如果失败 ，则为错误 描述
		{
			name=, (可选)昵称
			head_image=, (可选)头像
			sex = (可选)性别
			sign=, (可选)签名
		}
	★ 注意：返回表里不要包含其他字段，否则 会导致 更新的 sql 出错！！！
--]]
function PUBLIC.channels.youke.verify(_login_data)

	local _login_id = _login_data.login_id or ""

	local _channel = base.DATA.player_verify_data.youke
	local _user = _channel and _channel[_login_id]

	if _user then
		return true,{
			login_id=_login_id,
		}
	else

		if "" == _login_id then
			_login_id = PUBLIC.youke_gen_login_id()
		end

		return true,{
			login_id=_login_id,
		},{
			name="游客"..(base.DATA.player_verify_data.count+1),
			sex=1,
		}

	end
end

