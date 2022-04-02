--
-- Author: lyx
-- Date: 2018/4/26
-- Time: 17:12
-- 说明：管理控制台，提供 服务的一些操作指令，比如 关机
--

local skynet = require "skynet_plus"
local socket = require "skynet.socket"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"

local console_session = require "admin_console_service.console_session"

require "admin_console_service.user_manager"
require "admin_console_service.system_manager"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

DATA.service_config = nil

-- 仅允许本机访问
local ip = "127.0.0.1"
local port = tonumber(skynet.getenv("admin_console_port"))

local function split_cmdline(cmdline)
	local split = {}
	for i in string.gmatch(cmdline, "%S+") do
		table.insert(split,i)
	end
	return split
end

local function console_main_loop(stdin, _echo)
	_echo("Welcome to server console")
	print(stdin, "connected")
	local ok, err = pcall(function()
		local cs = console_session.new(_echo)
		while true do
			local cmdline = socket.readline(stdin, "\n")
			if not cmdline then
				break
			end
			if cmdline ~= "" then
				cs.cmd_index = cs.cmd_index + 1
				cs.cmd_running = true
				local ok,msg = pcall(cs.dispatch_command,cs,table.unpack(split_cmdline(cmdline)))
				if not ok then
					_echo(msg)
				end
				cs.cmd_running = false
			end
		end
	end)
	if not ok then
		print(stdin, err)
	end
	print(stdin, "disconnected")
	socket.close(stdin)
end

function PUBLIC.try_stop_service(_count,_time)
	return "free"
end

function CMD.start(_service_config)
	DATA.service_config=_service_config
end

skynet.start(function()

	-- 分发 lua 调用
	skynet.dispatch("lua", base.default_dispatcher)

	-- 监听 socket
	print("Start debug console at " .. ip .. ":" .. port)
	local listen_socket = socket.listen (ip, port)
	socket.start(listen_socket , function(id, addr)
		local function _echo(...)
			local t = table.pack(...)
			for i=1,t.n do
				t[i] = tostring(t[i])
			end
			socket.write(id, table.concat(t,"\t"))
			socket.write(id, "\n")
		end
		socket.start(id)
		skynet.fork(console_main_loop, id , _echo)
	end)

end)