--
-- Author: lyx
-- Date: 2018/4/25
-- Time: 15:10
-- 说明：机器人 基类
--


local skynet = require "skynet_plus"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local base = require "base"

local robot_base = basefunc.class()

local node_name = skynet.getenv("my_node_name")

-- 接收 player agent 的消息
robot_base.msg = {}

-- 参数：
-- 	_client_id 客户端 标识号
-- 	_game_info 游戏信息， 即 xxx_req_game_list 中返回的一项
function robot_base:ctor(_client_id,_user_data,_game_info)

	self.login_id = _user_data.id
	self.user_data = _user_data

	self.client_id = _client_id

	self.game_info = _game_info

	self.user_id = nil

	self.player_agent_id = nil

	-- 是否运行标志： 如果为 false，则 时钟关闭，删除对象
	self._running = false

	-- 响应 id
	self._respones_id = 0

	-- 正在等待响应的 数据： respones_id -> {thread=线程,respones=响应数据}
	self._waitting_respones = {}

	-- 伪装的网关连接
	self.pretend_gate_link =
	{
		node = node_name,
		addr = skynet.self(),
		client_id = _client_id,
	}
end

-- 开始
function robot_base:start()
	self._running = true
end

-- 分发消息
function robot_base:dispatch_message(_name,_data)

end

-- 登录，返回 true/false
function robot_base:login()

	local login_data = {
		channel_type="robot",
		login_id=self.login_id,
		channel_args=self.user_data.json,
		device_os="[robot_base service] linux",
		device_id="[robot_base service] eee-gdgjkj-888888888888888",
	}
	local result = skynet.call(base.DATA.service_config.login_service,"lua","client_login",login_data,self.pretend_gate_link,"<robot_service>")
	if result.result ~= 0 then

		print(string.format("robot_base login error:result id %s!",tostring(result.result)))

		return false
	end

	self.player_agent_id = result.player_agent_id
	self.user_id = result.user_id

	self:show_info("robot %s logined!",tostring(self.user_id))
	return true
end

function robot_base:show_info(_fmtstr,...)
	print("[" .. tostring(self.user_id) .. "] " .. string.format(_fmtstr,...))
end

-- 退出机器人
function robot_base:exit()

	self:show_info("exited!")
	self._running = false

	base.PUBLIC.remove_robot(self.client_id)
end

-- 发送消息到 player agent （无返回信息）
function robot_base:agent_send(_name,_data)
	nodefunc.send(self.player_agent_id,"request",_name,_data,nil)
end

-- 调用 player agent （ 有返回信息）
function robot_base:agent_request(_name,_data)

	local _resp_id = self._respones_id + 1
	self._respones_id = _resp_id

	self._waitting_respones[_resp_id] = {thread = coroutine.running()}
	nodefunc.send(self.player_agent_id,"request",_name,_data,_resp_id)

	-- 等待回应
	skynet.wait(coroutine.running())

	local resp_data = self._waitting_respones[_resp_id].respones
	self._waitting_respones[_resp_id] = nil

	return resp_data
end

-- 释放给定的 respones_id 的等待线程
function robot_base:wakeup_respones(_resp_id,_resp_data)
	local _resp = self._waitting_respones[_resp_id]
	if _resp then
		_resp.respones = _resp_data
		skynet.wakeup(_resp.thread)
	end
end

return robot_base
