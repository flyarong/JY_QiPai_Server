--
-- Author: lyx
-- Date: 2018/3/14
-- Time: 9:23
-- 说明：客户端对象，每个客户端连接（fd） 对应一个
--		注意：不缓存 session 和此对象的映射关系，客户端断开即销毁。
-- 		因为：此对象创建时 还未收到任何数据，无法知道 fd 和 用户的对应关系
--

local skynet = require "skynet_plus"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local base = require "base"
local socket = require "skynet.socket"
local sprotoloader = require "sprotoloader"
local sproto_core = require "sproto.core"
local netpack = require "skynet.netpack"

local cluster = require "skynet.cluster"

local client = basefunc.class()

local node_name = skynet.getenv("my_node_name")

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

-- 协议解包/打包
local host
local send_request

-- client 对象的 id ，在当前 gate agent 中唯一
local last_client_id = 0

function client.init()

	-- 加载协议
	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
	
end

function client:ctor()

	last_client_id = last_client_id + 1
	self.id = last_client_id

	self.gate_link =
	{
		node = node_name,
		addr = skynet.self(),
		client_id = self.id,
	}
end

-- 连接的时候调用
function client:on_connect(fd,addr)
	self.fd = fd
	self.ip = string.gsub(addr,"(:.*)","")

	print("new client fd:",fd)

	-- 用于匹配发回 response 的 id
	self._last_responeId = 0

	-- 发回的 response 暂存
	self.responses = {}

	-- 玩家 agent 的 service id
	self.player_agent_id = nil

	-- 玩家agent 连接
	self.agent_link = nil

	-- 登录 id，登录成功后有效
	self.login_id = nil

	-- 用户 id，登录成功后有效
	self.user_id = nil

	-- 消息序号
	self._request_number = 0

	-- 连接已断开
	self._dis_connected = false

	-- 已经禁止收数据
	self._forbid_request = false

	-- 消息限制计数器
	self.__limit_request_counter = 0

	-- 等待踢出
	self._wait_kick = false

	-- 通讯密码
	self.proto_key = nil
end

-- 断开的时候调用
function client:on_disconnect()

	self._dis_connected = true

	if self.agent_link then
		cluster.send(self.agent_link.node,self.agent_link.addr,"disconnected",self.gate_link)
	end

end

function client:send_package(pack)

	if self.fd then
		
		if self.proto_key then
			pack = sproto_core.xteaencrypt(pack,self.proto_key)
		end

		local package = string.pack(">s2", pack)
		--print("send_package",string.len(pack),basefunc.tohex(package))
		socket.write(self.fd, package)
	end	
end

-- 来自客户端的请求
function client:request(msg,sz)

	if self.proto_key then
		sproto_core.xteadecrypt_c(self.proto_key,msg,sz)
	end

	local ok,type,name,args,response = xpcall(host.dispatch,basefunc.error_handle,host,msg,sz)
	if ok then
		if type == "REQUEST" then
			local ok, result  = xpcall(client.dispatch_request,basefunc.error_handle,self,response, name,args)
			if not ok then
				print("call dispatch_request error:",self.fd,result)
			end
		else
			if type ~= "RESPONSE" then
				print(string.format("error:not suport msg type '%s'! ", tostring(type)))
			end
			print( "error:doesn't support request client")
		end
	end
	
end

-- 向客户端发送请求
function client:request_client(name,data)
	self:send_package(send_request(name,data))
end

-- 向客户端发送 response
function client:response_client(responeId,data)

	local resp = self.responses[responeId]
	self.responses[responeId] = nil  -- 取出后 马上清除
	if resp and data then
		self:send_package(resp(data))
	end
end

-- 更新函数
function client:update(dt)

	if self._wait_kick then
		print(string.format("client kick fd %d.", self.fd))
		skynet.send(DATA.gate,"lua","kick",self.fd)
		self._wait_kick = false
		return
	end

	-- 每 5 秒请求次数限制
	self.__req_time = (self.__req_time or 0) + 1
	if self.__req_time >= 5 then
		self.__limit_request_counter = 0
		self.__req_time = 0
	end
end


-- 登录
function client:login(response,name,data)

	if data.channel_type == "robot" then
		self._forbid_request = true

		print("error:request login channel_type 'robot' is unvalid!")
		self._wait_kick = true
		self:send_package(response({result=1039}))
		return
	end

	if data.channel_type == "youke" and skynet.getcfg("forbid_youke") then
		self._forbid_request = true

		print("error:request login channel_type 'youke' is unvalid!")
		self._wait_kick = true
		self:send_package(response({result=1039}))
		return
	end

	if data.login_id and not basefunc.is_real_player(data.login_id) then
		self._forbid_request = true

		print(string.format("error:request login id '%s' is unvalid!",data.login_id))
		self._wait_kick = true
		self:send_package(response({result=1033}))
		return
	end

	-- 发送到 login
	local result = skynet.call(DATA.service_config.login_service,"lua","client_login",data,self.gate_link,self.ip)
	if result.result ~= 0 then
		self._forbid_request = true
		print(string.format("error:result id %s!",tostring(result.result)))

		self._wait_kick = true
		self:send_package(response(result))
		return
	end

	-- 在等待其他服务过程中 断开，则直接返回
	if self._dis_connected then
		return
	end

	self.player_agent_id = result.player_agent_id
	self.agent_link = result.agent_link

	if skynet.getcfg("network_error_debug") then
		print(string.format("<socket fd(%s)> logined:",tostring(self.fd)),self.id,basefunc.tostring(data),basefunc.tostring(result))
	end

	self.login_id = result.login_id
	self.user_id = result.user_id

	if skynet.getcfg("proto_encrypt") then

		-- 如果 socket 未断的情况下重新 login 则不重新生成 key， 因为客户端可能同步不及时
		result.proto_token = self.proto_key or skynet.gen_encrypt_key(30,self.login_id)

		-- 发送 response 信息
		self:send_package(response(result))

		-- 发送完 key，则保存
		self.proto_key = result.proto_token
	else
		-- 发送 response 信息
		self:send_package(response(result))
	end
end

-- 中转
function client:transit(response,name,data)
	-- 第一个不是登录消息
		if self._request_number == 1 then
			self._forbid_request = true
			print("error:first request is not login!")

			self._wait_kick = true
			self:send_package(response({result=1034}))
			return
		end

		if self.player_agent_id then

			-- 不是 login 消息，直接转发到游戏服务器

			local _responeId

			if response then
				self._last_responeId = self._last_responeId + 1
				_responeId = self._last_responeId

				self.responses[_responeId] = response
			end

			if skynet.getcfg("network_error_debug") then
				--print(string.format("<socket fd(%d)>",self.fd), "request",name,self.id,_responeId, basefunc.tostring(data))
				print(string.format("<socket fd(%s)> request:",tostring(self.fd)),name,self.agent_link.client_id,responeId)
			end

			-- gm 用户验证
			if not skynet.getcfg("gm_user_debug") then
				if self.user_id and name == "gm_command" then
					local gm_list = nodefunc.get_global_config("gm_user_list")
					if not gm_list[self.user_id] then
						self:send_package(response({result="错误：你不是管理员用户！"}))
						return
					end
				end
			end

			cluster.send(self.agent_link.node,self.agent_link.addr,"request",name,data,_responeId)
		else
			-- 还未登录
			self._forbid_request = true
			print(string.format("error:ip %s, fd %d, request name '%s'. but have not logined   ! ", tostring(self.ip), self.fd,name))

			self._wait_kick = true
			self:send_package(response({result=1035}))
		end
end

-- 客户端消息分发
function client:dispatch_request(response,name,data)

	if skynet.getcfg("network_error_debug") then
		--print("dispatch_request:",self.ip,self.fd,name,basefunc.tostring(data))
		print(string.format("<socket fd(%s)> disp req:",tostring(self.fd)),name,basefunc.tostring(data))
	end

	if self._forbid_request or self._dis_connected then
		return
	end

	self._request_number = self._request_number + 1

	-- 客户端发送请求太频繁，则断开
	self.__limit_request_counter = self.__limit_request_counter + 1
	if self.__limit_request_counter >= DATA.max_request_rate then
		self._forbid_request = true

		print(string.format("error:request too much , max is %d ,but %d!",DATA.max_request_rate,self.__limit_request_counter))

		self._wait_kick = true
		self:send_package(response({result=1031}))
		return
	end

	if name == "login" then
		-- 登录
		self:login(response,name,data)

	elseif name == "client_breakdown_info" then
		if DATA.service_config.cbug_log_service then
			skynet.send(DATA.service_config.cbug_log_service,"lua","write_bug_log",data.error,self.player_agent_id)
		end
	else
		-- 转发消息
		self:transit(response,name,data)
	end

end

return client
