--
-- Author: lyx
-- Date: 2018/3/13
-- Time: 10:12
-- 说明：试验客户端
--

package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;game/protocol/?.lua;game/common/?.lua;"
require "printfunc"
math.randomseed(os.time()) 

if _VERSION ~= "Lua 5.3" then
	error "Use lua 5.3"
end

local HEART_BEAT_TIME = 1

-- 每秒连入用户
local COUNT_PER_SECOND = 200

-- 总用户数量
local MAX_COUNT = 3000

-- 连接服务器
--local SERVER = "119.23.79.170:5000"
--local SERVER = "47.106.175.111:5004"
--local SERVER = "192.168.0.222:5001"
local SERVER = "119.23.79.170:5005"
--local SERVER = "192.168.0.207:5000"
--local SERVER = "127.0.0.1:5001"

local unpack = unpack

if not unpack then
	unpack = table.unpack
end

local socket = require "client.socket"
local proto = require "proto"
local sproto = require "sproto"

-- 创建一个类
function class()
	local cls = {}

	function cls.new(...)
		local ret = setmetatable({class=cls},{__index=cls})
		ret:ctor(...)
		return ret
	end

	return cls
end

-- sleep ，单位 秒
local function sleep(time)
	socket.usleep(time * 1000000)
end

local client_set={}

local error_fds = {}


local session = 0

host = sproto.new(proto.s2c):host "package"
request = host:attach(sproto.new(proto.c2s))

local function error_handle(msg)
	print(tostring(msg) .. ":\n" .. tostring(debug.traceback()))
	return msg
end	

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end

	return text:sub(3,2+s), text:sub(3+s)
end

local function send_package(fd,pack)


	local package = string.pack(">s2", pack)
	local ok,err = xpcall(socket.send,error_handle,fd, package)
	if not ok then
		error(string.format("socket send error,fd %d,err:%s !",fd,tostring(err)))
	end
	return true
end

local function handler(object,func)
	assert(object,"handler error:object is nil!")
	assert(func,"handler error:func is nil!")
	return function(...)
		func(object,...)
	end
end

local _login_succ_count = 0
local _sign_succ_count = 0

----------------------------------------------
-- 类定义

local client = class()

client.msg = {}

function client:ctor()

	self.fd = nil

	self.response_call_back={}
	self.request_call_back={}
	self.timer={}
	self.len=1
	self.is_login=false	
end

function client:on_connected()

	-- 登录
	local device_id="test_client_game."..math.random(10000000,9000000000)

	self:send_request("login",{
			channel_type="youke",
			login_id="",
			device_os="windows 10",
			device_id=device_id,
		},handler(self,self.on_login))
	
end

function client:on_login(data)

	if data.result == 0 then
		_login_succ_count = _login_succ_count + 1

		self.is_login=true

		self:delay_send_request("dfg_req_game_list", {},handler(self,self.on_respone_reg_game_list),2)
	else
		print("login error id:",data.result)
	end


end

function client:on_respone_reg_game_list(data)

	self:delay_send_request("dfg_signup", {id = 2},handler(self,self.on_sign_result))

end

function client:on_sign_result(data)
	if data.result == 0 then
		_sign_succ_count = _sign_succ_count + 1
	else
		print("sign error id:",data.result)
	end
end

function client:connect()
	local host, port = string.match(SERVER, "([^:]+):(.*)$")
	local ok,fd = xpcall(socket.connect,error_handle,host, tonumber(port))
	if ok then
		self.fd = fd

		self:timeout(handler(self,self.on_connected))

		return true
	else
		print("connect error:",fd)
		return false
	end
end

function client:send_request(name, args,cb)

	if not self.fd then return end

	session = session + 1
	local str = request(name, args, session)
	
	self.response_call_back[session]={req=name,cb=cb,time=os.time()}

	if not send_package(self.fd, str) then
		error(string.format("send package error,fd %d,name '%s'!",self.fd,name))
	end
end

function client:delay_send_request(name, args,cb,time)
	self:timeout(self.send_request,time or 0,self,name, args,cb)
end

function client:recv_package(last)
	if not self.fd then
		return nil,last
	end

	local result
	result, last =unpack_package(last)
	if result then
		return result, last
	end
	local ok,r = xpcall(socket.recv,error_handle,self.fd)
	if not ok then
		error(string.format("socket closed:%d ,%s!",self.fd,tostring(r)))
	end

	if not r then
		return nil, last
	end
	if r == "" then
		error(string.format("socket closed:%d !",self.fd))
	end
	return unpack_package(last .. r)
end

function client.msg:dfg_permit_msg(_name,_data)
	if _data and _data.status=="jdz" then
		self:delay_send_request("dfg_jiao_dizhu", {rate=3})
	end

end

local max_update_time = 0
local last_print_htime = os.time()

local max_send_heart_time = -1

local max_response_times = {}

local function update_response_time(_name,_time,_arrive)


	local mrt = max_response_times[_name]
	if mrt then
		if _time > mrt.time then
			mrt.time = _time
			mrt.arrive = _arrive
		end
	else
		mrt = {time=_time,arrive=_arrive}
		max_response_times[_name] = mrt
	end

end


function client:update(dt)

	self:dispatch_package()

	for k,v in pairs(self.timer) do
		v.time=v.time-dt
		if v.time<=0 then
			local ok = xpcall(v.cb,error_handle,unpack(v.params))

			if not ok then
				self.fd = nil
				break
			end

			if not v.keep then
				self.timer[k]=nil
			end
		end
	end

	local now = os.time()

	if self._update_time then
		max_update_time = math.max((now - self._update_time) , max_update_time)
	end

	self._update_time = now

	if now - last_print_htime > 3 then
		print("max update time :",max_update_time)
		last_print_htime = now
	end

	if self.is_login then

		if not self.last_send_heart_time or os.time() - self.last_send_heart_time >= HEART_BEAT_TIME then 

			if self.last_send_heart_time then
				max_send_heart_time = math.max(max_send_heart_time,os.time() - self.last_send_heart_time)
			end

			self.last_send_heart_time = os.time()
			self:delay_send_request("heartbeat", {})
		end
	end

	-- 处理未返回的超时请求
	self._check_resp_time = (self._check_resp_time or 0) + dt
	if self._check_resp_time > 5 then
		self._check_resp_time = 0

		local _now = os.time()
		for _,_data in pairs(self.response_call_back) do
			if _now - _data.time > 5 then
				update_response_time(_data.req,_now - _data.time,false)
			end
		end
	end
end

function client:timeout(cb,time,...)
	self.timer[#self.timer + 1] = {time=time or 0,cb=cb,params={...}}
end


function client:dispatch_package()
	local last = ""
	while true do
		local v
		v, last = self:recv_package(last)
		if not v then
			break
		end

		local t,name,data = host:dispatch(v)
		if t == "REQUEST" then
			if client.msg[arg1] then
				client.msg[arg1](self,name,data)
			end
		else
			assert(t == "RESPONSE")
			local r = self.response_call_back[name]
			if r then

				self.response_call_back[name] = nil

				update_response_time(r.req,os.time() - r.time,true)

				if r.cb then
					r.cb(data)
				end
			end
		end
	end
end
-----------------------------------------------

local clients = {}

local _dt = 0.1

local _stat_cd = 5

local _exit_create = false

local _online_count = 0

local _online_client = {}

local _login_succ_count_last = 0
local _sign_succ_count_last = 0

while true do

	sleep(_dt)

	if not next(_online_client) and #clients==MAX_COUNT then
		print("all client disconnected!")
		break
	end

	-- 每次创建 一部分
	if #clients < MAX_COUNT then
		for i=1,math.max(1,COUNT_PER_SECOND * _dt) do
			if #clients >= MAX_COUNT then
				break
			end

			local _client=client.new()
			if not _client then 
				_exit_create = true
				break 
			end

			if _client:connect() then
				if #clients % 100 == 0 then
					print("connect count, fd:",#clients,_client.fd)
				end

				_online_count = _online_count + 1
				_online_client[_client] = true
			else
				_exit_create = true
				break
			end

			clients[#clients + 1] = _client

			sleep(0.005) -- 0.0045 , 0.0005
		end

		if _exit_create then
			break
		end
	end

	-- 已经创建对象的 update
	for _,client in ipairs(clients) do 
		if client.fd then
			if not xpcall(client.update,error_handle,client,_dt) then
				_online_count = _online_count - 1
				client.fd = nil
				_online_client[client] = nil
			end
		else
			_online_client[client] = nil
		end
	end

	_stat_cd = _stat_cd - _dt
	if _stat_cd <= 0 then
		_stat_cd = 5
		print("==== stat data ====")
		print("online count:",_online_count)
		print("login count:",_login_succ_count)
		print("sign count:",_sign_succ_count)
		print("login per sec =>",(_login_succ_count-_login_succ_count_last)/5)
		print("sign per sec =>",(_sign_succ_count-_sign_succ_count_last)/5)
		print("max heart time:",max_send_heart_time)

		print("max response time:")
		for _name,_data in pairs(max_response_times) do
			if _data.arrive then
				print("",_name,_data.time)
			else
				print("",_name,_data.time,"  time out!")
			end
		end

		_login_succ_count_last = _login_succ_count
		_sign_succ_count_last = _sign_succ_count
		max_response_times = {}
	end
end



