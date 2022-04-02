--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：登录服务
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"

local login_config = require "login_service.login_config"

require "printfunc"

local DATA = base.DATA
local CMD = base.CMD
local PUBLIC = base.PUBLIC

DATA.login_data = DATA.login_data or 
{
	-- 玩家数据表
	players = {},

	-- 处理中的玩家
	players_logining = {},

	-- 服务器 实例 id
	instance_id,
}
local D = DATA.login_data


local function safe_get_instance_id()
	if not D.instance_id then
		D.instance_id = skynet.call(DATA.service_config.data_service,"lua","get_instance_id")
	end

	return D.instance_id
end

function CMD.set_login_switch(_channels)

	for _name,_value in pairs(_channels) do
		if nil ~= login_config.login_switch[_name] then
			login_config.login_switch[_name] = _value
		end
	end

	return 0
end

function CMD.get_login_switch()
	return login_config.login_switch
end

-- 增长服务器实例 id
function CMD.inc_instance_id()
	D.instance_id = skynet.call(DATA.service_config.data_service,"lua","inc_instance_id")
end

-- 返回
--	data
--	nil , 错误号
function PUBLIC.deal_login_data(_login_msg,_gate_link,_ip,userId,login_id,is_new_user,refresh_token)

	local player = D.players[userId] or {}

	if player.gate_link and not nodefunc.equal_gate_link(player.gate_link,_gate_link) then

		if skynet.getcfg("network_error_debug") then
			print("login will_kick_reason:",userId,player.gate_link.addr,player.gate_link.client_id)
		end

		-- 将原来的登录踢下线
		local ok = pcall(cluster.call,player.gate_link.node,player.gate_link.addr,"request_client",player.gate_link.client_id,"will_kick_reason",{reason="relogin"})
		if ok then
			cluster.send(player.gate_link.node,player.gate_link.addr,"kick_client",player.gate_link.client_id,true)
		end
		
		if not basefunc.is_real_player(userId) then
			skynet.send(DATA.service_config.tuoguan_service,"lua","tuoguan_agent_kicked",userId)
		end

	end
	
	local gm_list = nodefunc.get_global_config("gm_user_list")

	-- 扩展数据
	local extend_data =
	{
		login_id = login_id,
		is_new_user = is_new_user,
		ip = _ip,
		player_level = gm_list[userId],
	}

	local respone = {
		result = 0,
		user_id = userId,
		channel_type = _login_msg.channel_type,
		login_id = login_id,
	}

	local player_data = nil

	if player.player_agent_id then

		print(string.format("login -> restart player servie : %s",userId))
		local result = nodefunc.call(player.player_agent_id,"restart",
			userId,_gate_link,_login_msg,extend_data)

		if result=="CALL_FAIL" then

			if (player.re_call_count or 0) >= 1 then  -- 超过次数强制踢
				CMD.force_outline(player.player_agent_id,"call_fail_" .. player.re_call_count)
				return nil,1065
			else

				local _unode = skynet.call(DATA.service_config.center_service,"lua","query_service_node",userId)
				print("login -> restart player servie fail (uid,node):",userId,_unode)

				if _unode then
					player.sleep_retry = (player.sleep_retry or 0) + 1
					return nil,1065
				else
					CMD.force_outline(player.player_agent_id,"call_fail")
					return nil,1065
				end

			end

		elseif result.result == 0 then

			player.agent_link=result.agent_link

			respone.location = result.location
			respone.vice_location = result.vice_location
			respone.game_id = result.game_id
			
			if result.player_data then
				player_data = result.player_data
			end	
		
		else
			return nil,result.result
		end
	
	else

		-- 登录
		print(string.format("login -> start player servie : %s",userId))

		local ok,result = skynet.call(DATA.service_config.node_service,"lua","create",nil,
							"player_agent/player_agent",userId,
							_gate_link,_login_msg,extend_data)
		if ok then

			player.agent_link=result.agent_link

			if result.player_data then
				player_data = result.player_data
			end
		else
			return nil,result
		end

	end

	-- 成功时，才能赋值！！！

	player.sleep_retry = 0
	player.player_agent_id=userId
	player.gate_link = _gate_link
	player.login_data = _login_msg

	D.players[userId] = player

	if player_data then


		local debug_player_prefix = skynet.getcfg("debug_player_prefix")
		
		if debug_player_prefix then
			respone.name = debug_player_prefix .. player_data.player_info.name
		else
			respone.name = player_data.player_info.name
		end

		respone.sex = player_data.player_info.sex
		respone.head_image = player_data.player_info.head_image
		respone.introducer = player_data.player_info.introducer
		respone.xsyd_status = player_data.xsyd_status
		respone.million_cup_status = player_data.million_cup_status
		respone.player_asset = player_data.player_asset
		respone.player_ticket = player_data.player_ticket
		respone.glory_data = player_data.glory_data
		respone.dressed_head_frame = player_data.dress_data.dressed_head_frame
		respone.vip_data = player_data.vip_data
		respone.step_task_status = player_data.step_task_status
		respone.gift_bag_data = player_data.gift_bag_data
		respone.refresh_token = refresh_token
	end

	respone.player_agent_id = player.player_agent_id
	respone.agent_link=player.agent_link
	respone.instance_id = safe_get_instance_id()

	-- gm 用户
	if skynet.getcfg("gm_user_debug") then
		respone.player_level = 1
	else
		respone.player_level = gm_list[userId]
	end

	--dump(respone,"login respone data:")

	return respone	
end

-- 用户登录消息
function CMD.client_login(_login_msg,_gate_link,_ip)

	if not _login_msg.channel_type then
		if skynet.getcfg("network_error_debug") then
			print("channel_type is nil!")
		end

		return {result=1003}
	end

	if "robot" ~= _login_msg.channel_type and not login_config.login_switch[_login_msg.channel_type] then
		if skynet.getcfg("network_error_debug") then
			print("channel_type error:",_login_msg.channel_type)
		end

		return {result=2403}
	end


	if ((_login_msg.password
		and(type(_login_msg.password)~="string" 
			or string.len(_login_msg.password)>50))
		or (_login_msg.device_os 
			and(type(_login_msg.device_os)~="string" 
				or string.len(_login_msg.device_os)>500))
		or (_login_msg.introducer 
			and(type(_login_msg.introducer)~="string" 
				or string.len(_login_msg.introducer)>50))
		or (_login_msg.channel_args 
			and(type(_login_msg.channel_args)~="string" 
				or string.len(_login_msg.channel_args)>256))
		)then

		if skynet.getcfg("network_error_debug") then
			print("login error:",basefunc.tostring(_login_msg))
		end

		return {result=1003}
	end

	-- 玩家验证
	--dump(_login_msg,"login_service: login _login_msg")
	local userId,login_id,is_new_user,refresh_token =skynet.call(DATA.service_config.verify_service,"lua",
														"verify",_login_msg,_ip)

	-- 验证失败
	if not userId then
		if skynet.getcfg("network_error_debug") then
			print("verify error:",userId,login_id,is_new_user,basefunc.tostring(_login_msg))
		end

		return {result=login_id}
	end
	
	if D.players_logining[login_id] then
		return {result=1063}
	end

	D.players_logining[login_id] = true
	local ok,respone,code
	for i=1,3 do

		ok,respone,code = xpcall(PUBLIC.deal_login_data,basefunc.error_handle,_login_msg,_gate_link,_ip,userId,login_id,is_new_user,refresh_token)

		if not ok then
			D.players_logining[login_id] = false
			return {result=1041}
		elseif respone then
			D.players_logining[login_id] = false
			return respone
		elseif 1065 == code or 1064 == code then
			skynet.sleep(50) -- 半秒后重试
		else
			break
		end
	end

	D.players_logining[login_id] = false
	return {result=code}
end

function CMD.force_outline(userId,_reason)

	local p=D.players[userId]

	if p then
		D.players[userId]=nil
		print("login out force_outline clear:",userId)

		local ok = pcall(cluster.call,p.gate_link.node,p.gate_link.addr,"request_client",p.gate_link.client_id,"will_kick_reason",{reason=_reason})

		if ok then
			cluster.send(p.gate_link.node,p.gate_link.addr,"kick_client",p.gate_link.client_id,true)
		end

		if not basefunc.is_real_player(userId) then
			skynet.send(DATA.service_config.tuoguan_service,"lua","tuoguan_agent_kicked",userId)
		end

		return "ok"
	else
		return "not found!"
	end
end

-- 强制断开网络连接（仅用于管理指令，针对违规玩家强制下线！！！）
function CMD.force_kick(userId,_reason)
	local p=D.players[userId]
	if p then

		local ok = pcall(cluster.call,p.gate_link.node,p.gate_link.addr,"request_client",p.gate_link.client_id,"will_kick_reason",{reason=_reason})

		if ok then
			cluster.send(p.gate_link.node,p.gate_link.addr,"kick_client",p.gate_link.client_id,true)
		end

		return "ok"
	else
		return "not found!"
	end
end

function CMD.client_outline(userId,_gate_link,_reason)

	local p=D.players[userId]
	print("login out client_outline:",basefunc.tostring({userId,_gate_link,_reason,p}))
	if p and _gate_link and p.gate_link and nodefunc.equal_gate_link(p.gate_link,_gate_link) then

		CMD.force_outline(userId,_reason)
		
	end
end


function CMD.start(_service_config)
	DATA.service_config = _service_config
end

-- 启动服务
base.start_service()
