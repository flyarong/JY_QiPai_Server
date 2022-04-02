--
-- Author: hw
-- Date: 2018/4/26
require"printfunc"
local skynet = require "skynet_plus"
local skynet = require "skynet.manager"
-- local cluster = require "skynet.cluster"
local CMD={}
local node_count={}
local node_limit={}
local clusterd
function CMD.heart()
	return 0
end

function CMD.start()

	return 0
end

skynet.start(function()
	skynet.register("node_ht_ser")
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = CMD[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown CMD %s", tostring(cmd)))
		end
	end)

	skynet.fork(function ()
		skynet.sleep(600)
		clusterd=skynet.uniqueservice("clusterd")
		while true do
			skynet.sleep(100)
			local cluter_list=skynet.call(clusterd,"lua","get_cluter_heart_map")
			if cluter_list then
				for _node,_addr in pairs(cluter_list) do
					node_count[_node]=node_count[_node] or 1
					node_limit[_node]=node_limit[_node] or 1
					if node_count[_node]>=node_limit[_node] then
						if node_limit[_node]<100 then
							node_limit[_node]=node_limit[_node]*2
						end
						skynet.fork(function (node,addr)
							skynet.call(clusterd, "lua", "req", node, addr, skynet.pack("heart"))
							-- print("heart")
							node_limit[node]=1
					 	end,_node,_addr)
					else
						node_count[_node]=node_count[_node]+1
					end
				end
			end
		end
	end)
end)