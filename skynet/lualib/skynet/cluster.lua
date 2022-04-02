local skynet = require "skynet"

local is_open_strict_transfer=tonumber(skynet.getenv "strict_transfer")
local clusterd
local cluster = {}

local function call_filter(_ok,...)
	
end

function cluster.call(node, address, ...)
	-- skynet.pack(...) will free by cluster.core.packrequest
	return skynet.call(clusterd, "lua", "req", node, address, skynet.pack(...))
end

function cluster.send(node, address, ...)
	-- push is the same with req, but no response
	if not address or 0 == address or tostring(address) == "" then
		error("cluster.send error : " .. tostring(node) .. ",addr:" .. tostring(address))
	end
	skynet.send(clusterd, "lua", "push", node, address, skynet.pack(...))
end

function cluster.open(port)
	if type(port) == "string" then
		skynet.call(clusterd, "lua", "listen", port)
	else
		skynet.call(clusterd, "lua", "listen", "0.0.0.0", port)
	end
end

function cluster.reload(config)
	skynet.call(clusterd, "lua", "reload", config)
end

function cluster.proxy(node, name)
	return skynet.call(clusterd, "lua", "proxy", node, name)
end

function cluster.snax(node, name, address)
	local snax = require "skynet.snax"
	if not address then
		address = cluster.call(node, ".service", "QUERY", "snaxd" , name)
	end
	local handle = skynet.call(clusterd, "lua", "proxy", node, address)
	return snax.bind(handle, name)
end

function cluster.register(name, addr)
	assert(type(name) == "string")
	assert(addr == nil or type(addr) == "number")
	return skynet.call(clusterd, "lua", "register", name, addr)
end

function cluster.query(node, name)
	return skynet.call(clusterd, "lua", "req", node, 0, skynet.pack(name))
end

skynet.init(function()
	if is_open_strict_transfer==1 then
		skynet.uniqueservice("node_heart_service")
	end
	clusterd = skynet.uniqueservice("clusterd")
end)

return cluster
