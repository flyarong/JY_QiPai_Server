--
-- Author: yy
-- Date: 2018/3/28
-- Time: 11:57
-- 说明：验证服务
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
require "printfunc"
local nodefunc = require "nodefunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local _error_handler = basefunc.debug.common_xpcall_handler_type1

------------------------------------------------------------------------------
--[[ 各渠道的验证程序
 【验证程序的 verify 函数接口规范】
  ★ 参数： _login_data 登录数据
  ★ 返回值：succ,verify_data, user_data
  	succ : true/false ，验证成功 或 失败
  	verify_data : （必须）验证结果数据，如果失败，则为错误号。
		{
			login_id=, (必须)登录id
			password=, (可选) 用户密码
			re几千个 fresh_token=, (可选) 刷新凭据，某些渠道需要，比如微信
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
DATA.channels = {
	youke="verify_service.channel_youke", -- 游客登录
	wechat="verify_service.channel_wechat", -- 微信登录
	robot="verify_service.channel_robot", -- 机器人登录 无论如何都只能服务器内部登录
--	phone="verify_service.channel_phone", -- 电话号码登录
--	weixin_gz="verify_service.channel_weixin_gz", -- 微信公众号登录
--	weixin_kf="verify_service.weixin_kf", -- 微信开放平台登录
}
------------------------------------------------------------------------------

-- 登录渠道的函数 表，加载的时候由 渠道代码自己填充
PUBLIC.channels = {}

-- 验证表 player_verify 中的数据
-- channel_type,login_id 两层映射： channel_type -> {login_id -> {is_verifying=是否正在验证,数据表中的字段} }
base.DATA.player_verify_data = nil
local player_verify_data

-- 测试期间 登录限制的倒计时
local function countdown_publish_prepare_time()
	local prc = skynet.getcfg("publish_prepare_cd")
	if prc then 
		prc = tonumber(prc) - 1
		if prc < 1 then
			skynet.setcfg("publish_prepare_cd",nil)

			print("===>>>> publish prepare is over <<<<====")
		else
			skynet.setcfg("publish_prepare_cd",prc)

			if math.fmod(prc,5) < 1 then
				print("===>>>> publish prepare count down:",prc)
			end
		end
	end
end

-- 内部测试中，检查是否 允许登录
-- 返回 false 
local function test_check_allow_login(_login_id)

	if not skynet.getcfg("publish_prepare_cd") then return true end

	local _test_user_list = nodefunc.get_global_config("test_user_list")

	if  not _test_user_list 
		or not _test_user_list.login_on_prepare 
		or not _test_user_list.login_on_prepare[_login_id] then

		print("error:cannt login when server is 'prepare_publish' status!login id:",_login_id)
		return false
	end
	
	return true
end

-- 数据服务
local data_service


function base.CMD.start(_service_config)

	math.randomseed(os.time())

	-- 加载 所有登录模块
	for _name,_m in pairs(DATA.channels) do
		require (_m)
		if not PUBLIC.channels[_name] then
			error(string.format("login channel '%s' init fail!",_name))
		end
	end

	base.DATA.service_config = _service_config
	data_service = _service_config.data_service

	base.DATA.player_verify_data = skynet.call(data_service,"lua","get_all_verify_data")
	player_verify_data = base.DATA.player_verify_data

	-- 向 data service 上报支持的登录方式
	local sp_channels = {}
	for _name,_ in pairs(DATA.channels) do
		sp_channels[_name] = true
	end

	skynet.timer(1,countdown_publish_prepare_time)
end

local function safe_get_verify_data(_channel_type,_login_id)

	local channel_data = player_verify_data[_channel_type] or {}
	player_verify_data[_channel_type] = channel_data

	local _is_new = false

	local cur_verify_data = channel_data[_login_id] 
	if not cur_verify_data then
		cur_verify_data = {login_id=_login_id,channel_type=_channel_type}
		channel_data[_login_id] = cur_verify_data

		_is_new = true
	end

	return cur_verify_data,_is_new
end

function base.CMD.extend_create_user(_channel_type,_login_id,_parentUserId,_register_os)

	local _userId,code = skynet.call(data_service,"lua","create_player_info",
			{channel_type=_channel_type,introducer=_parentUserId,register_os=_register_os},
			{login_id=_login_id} 
		)

	if not _userId then
		return nil,code
	end

	local cur_verify_data = safe_get_verify_data(_channel_type,_login_id)
	cur_verify_data.id = _userId

	return _userId
end


--[[
	用户验证
	参数：
		_login_data 登录数据（参见客户端协议 login ）
		_ip 登录 ip 地址
	多个返回值：userId,login_id
		userId  	验证成功 返回用户 id ，出错则返回 nil
		login_id    用户的登录 id，出错则为错误码

--]]
function base.CMD.verify(_login_data,_ip)
	local channel = PUBLIC.channels[_login_data.channel_type]
	if not channel then
--		print("channel not found:",_login_data.channel_type)
--		dump(_login_data,"vefify_service: _login_data")
		return nil,2151
	end

	-- 调用第三方验证
	local succ,new_verify_data, new_user_data = channel.verify(_login_data)


	-- 出错
	if not succ then
		print(string.format("verify error:ip='%s',login_id='%s',channel_args='%s' !",tostring(_ip),tostring(_login_data.login_id),tostring(_login_data.channel_args)))
		--print("verify error: ",new_user_data,_ip,basefunc.tostring(_login_data))
		dump({login_data = _login_data,addr = _ip,verify_errid=new_user_data},"verify error")
		return nil,new_verify_data
	end

	if not new_verify_data.login_id then
		print(string.format("channel '%s' veirfy error: login_id is nil!",_login_data.channel_type))
		return nil,2157
	end

	if 'robot' ~= _login_data.channel_type and not test_check_allow_login(new_verify_data.login_id) then
		return nil,1002
	end

	-- 查询对应的 用户 id
	local cur_verify_data,is_new_user = safe_get_verify_data(_login_data.channel_type,new_verify_data.login_id)

	-- 由于后续有挂起操作，所以要置标志
	if cur_verify_data.is_verifying then
		return nil,1036
	end

	cur_verify_data.is_verifying = true

	basefunc.merge(new_verify_data,cur_verify_data)

	-- print("user verify data:", basefunc.tostring({verify_data=new_verify_data, user_data=new_user_data}))

	-- 用 xpcall 包起来，避免异常时未恢复 is_verifying 变量
	local ok,_error_code = xpcall(function()

		if is_new_user then

			-- 新用户，数量加 1
			player_verify_data.count = player_verify_data.count + 1
			
			local userId,error_code = skynet.call(data_service,"lua","create_player_info",
			{
				introducer = _login_data.introducer,
				register_os = _login_data.device_os,
				channel_type = _login_data.channel_type,
				register_ip = _ip,
				market_channel = _login_data.market_channel,
			},new_verify_data,new_user_data)

			if userId then
				cur_verify_data.id = userId

				if 'robot' ~= _login_data.channel_type then
					skynet.call(base.DATA.service_config.sczd_center_service,"lua","try_add_player_relation",
						userId,{parent_id=_login_data.introducer,is_tgy=1})
				end
			else
				print(string.format("player verify error:%s",tostring(error_code)))
				return error_code
			end
		else

			-- 已经存在的机器人不需要验证
			if _login_data.channel_type == "robot" then
				return 0
			end

			return skynet.call(data_service,"lua","verify_user",_login_data.channel_type,cur_verify_data.id,new_verify_data,new_user_data)
		end

		return 0

	end,_error_handler)

	cur_verify_data.is_verifying = false

	-- 程序运行错误，继续抛出
	if not ok then
		error(_error_code)
	end

	if _error_code ~= 0 then

		if skynet.getcfg("network_error_debug") then
			print("verify error:",_error_code)
		end

		return nil,_error_code
	end

	return cur_verify_data.id,new_verify_data.login_id,is_new_user,new_verify_data.refresh_token
end

-- 启动服务
base.start_service()
