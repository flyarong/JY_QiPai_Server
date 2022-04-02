local skynet = require "skynet"
local cluster = require "skynet.cluster"

skynet.start(function()
	math.randomseed(os.time())
	local _node_name=skynet.getenv "my_node_name"
	cluster.open (_node_name)
	
	local _center_service_add = cluster.query("center_node","center_service")
	local services_cfg=cluster.call("center_node", _center_service_add,"lua", "get_public_services",_node_name)

	skynet.call(_node_service, "lua", "start",services_cfg)
	
	
end)