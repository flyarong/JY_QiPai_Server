local skynet = require "skynet"
local cluster = require "skynet.cluster"

skynet.start(function()
	math.randomseed(os.time())
	local _node_name=skynet.getenv "my_node_name"
	cluster.open (_node_name)
	local _node_service = skynet.uniqueservice("node_service")
	local _register_name="node_ser_2"
	cluster.register(_register_name, _node_service)

	local _center_service_name = cluster.query("node_1","center_ser")
	local _center_service = cluster.proxy("node_1", _center_service_name)
	local _tam_ser_name = cluster.query("node_1","tam_ser")
	local _test_agent_manager = cluster.proxy("node_1", _tam_ser_name)
	local  _node_id=skynet.call(_center_service, "lua", "get_node_id")
	skynet.call(_node_service, "lua", "start",{
													id=_node_id,
													res=5000,
													node_name=_node_name,
													register_name=_register_name,
													},
											{
													center_service=_center_service,
													test_agent_manager=_test_agent_manager,
													node_service=_node_service,
													})
	
end)