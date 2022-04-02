local skynet = require "skynet"
local netpack = require "skynet.netpack"
local socket = require "skynet.socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local WATCHDOG
local host
local send_request

local CMD = {}
local REQUEST = {}
local client_fd


-- 将 value 转换成一个可读的调试字符串
function valuetostring( value, recMax )

	-- by lyx
	if type(value) ~= "table" then
		return tostring(value)
	end

	recMax = recMax or 3
	local stringBuffer = {}

	local function __tab_string( count )
		local tabl = {}
		for i = 1, count do
			table.insert( tabl, "  " )
		end
		return table.concat( tabl, "" )
	end

	local function __table_to_string( tableNow, recNow )

		-- by lyx
		if value == nil then return "nil" end

		if( recNow > recMax ) then
			table.insert( stringBuffer, tostring( tableNow ) .. ",\n" )
			return
		end

		table.insert( stringBuffer, "{\n" )
		for k, v in pairs( tableNow ) do
			table.insert( stringBuffer, __tab_string(recNow) .. tostring( k ) .. "=" )
			if( "table" ~= type(v) ) then
				table.insert( stringBuffer, tostring( v ) .. ",\n" )
			else
				__table_to_string( v, recNow + 1 )
			end
		end
		table.insert( stringBuffer, __tab_string(recNow-1) .. "},\n" )
	end

	__table_to_string( value, 1 )
	return table.concat( stringBuffer, "" )
end

function REQUEST:get()
	print("get", self.what)
	local r = skynet.call("SIMPLEDB", "lua", "get", self.what)
	return { result = r }
end

function REQUEST:set()
	print("set", self.what, self.value)
	local r = skynet.call("SIMPLEDB", "lua", "set", self.what, self.value)
end

function REQUEST:handshake()
	return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end

function REQUEST:quit()
	skynet.call(WATCHDOG, "lua", "close", client_fd)
end

local function request(name, args, response)
	local f = assert(REQUEST[name])
	local r = f(args)
	if response then
		return response(r)
	end
end

local function send_package(pack)
	local package = string.pack(">s2", pack)
	socket.write(client_fd, package)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		local tmp = {host:dispatch(msg, sz) }
		print("ddddd",valuetostring(tmp))
		return table.unpack(tmp)
		--return host:dispatch(msg, sz)
	end,
	dispatch = function (_1, _2, type, ...)
		local tmp = {_1, _2, type, ... }
		print("fffffffffff",valuetostring(tmp))
		if type == "REQUEST" then
			local ok, result  = pcall(request, ...)
			if ok then
				if result then
					send_package(result)
				end
			else
				skynet.error(result)
			end
		else
			assert(type == "RESPONSE")
			error "This example doesn't support request client"
		end
	end
}

function CMD.start(conf)
	local fd = conf.client
	local gate = conf.gate
	WATCHDOG = conf.watchdog
	-- slot 1,2 set at main.lua
	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
	skynet.fork(function()
		while true do
			send_package(send_request "heartbeat")
			skynet.sleep(500)
		end
	end)

	client_fd = fd
	skynet.call(gate, "lua", "forward", fd)
end

function CMD.disconnect()
	-- todo: do something before exit
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
