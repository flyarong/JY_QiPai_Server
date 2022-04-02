local skynet = require "skynet"
local cluster = require "skynet.cluster"

skynet.start(function()
	
	math.randomseed(os.time())
	
	local _node_name=skynet.getenv "my_node_name"
	cluster.open (_node_name)

	local _data_svr_proxy = cluster.query("data_node", "data_ser")
	local _data_svr = cluster.proxy("data_node", _data_svr_proxy)


	local _center_ser_proxy = cluster.query("center_node", "center_ser")
	local _center_ser = cluster.proxy("center_node", _center_ser_proxy)


	local _node_service = skynet.uniqueservice("node_service")
	local _register_name = "extend_node"
	cluster.register(_register_name, _node_service)

	-- 登录
	local _login_svr = skynet.newservice("login_service/login_service")
	cluster.register("login_svr", _login_svr)

	-- 验证
	local _verify_svr = skynet.newservice("verify_service/verify_service")
	cluster.register("verify_svr", _verify_svr)

	-- 网关
	local _gate_svr = skynet.newservice("gate_service/gate_service")
	cluster.register("gate_svr", _gate_svr)


	-- 环境配置数据
	local _service_config = {
			center_service=_center_ser,
			data_service=_data_svr,
			login_service=_login_svr,
			verify_service=_verify_svr,
			node_service=_node_service,

	}


	skynet.call(_login_svr, "lua", "start" ,_service_config)
	skynet.call(_verify_svr, "lua", "start" ,_service_config)
	skynet.call(_gate_svr, "lua", "start" ,_service_config)

	local _node_ID=skynet.call(_center_service, "lua", "get_node_ID")
	skynet.call(_node_service, "lua", "start",{
													id=_node_ID,
													res=5000,
													node_name=_node_name,
													register_name=_register_name,
													},
												{
													center_service=_center_service,
												})

	skynet.exit()

end)
