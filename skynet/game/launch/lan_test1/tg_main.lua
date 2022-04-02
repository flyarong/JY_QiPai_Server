local skynet = require "skynet"
local cluster = require "skynet.cluster"
require "printfunc"

skynet.start(function()
	math.randomseed(os.time())
	local _node_name=skynet.getenv "my_node_name"
	cluster.open (_node_name)
	
	local services_cfg=cluster.call("data", "center_service","get_public_services",_node_name)

	local _node_service = skynet.uniqueservice("node_service")
	skynet.sleep(200)
	skynet.call(_node_service, "lua", "start",services_cfg,_node_name.."node_1")
	
	
end)