local skynet = require "skynet"
local cluster = require "skynet.cluster"

skynet.start(function()

	math.randomseed(os.time())
	
	local _node_name=skynet.getenv "my_node_name"
	cluster.open(_node_name)

	local _data_ser = skynet.uniqueservice("data_service/data_service")
	cluster.register("data_ser", _data_ser)
	skynet.call(_data_ser, "lua", "start")

	skynet.exit()
end)