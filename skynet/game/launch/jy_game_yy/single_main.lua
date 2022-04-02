--
-- 作者: lyx
-- Date: 2018/3/10
-- Time: 14:48
-- gate 的启动文件
--

local skynet = require "skynet"
local cluster = require "skynet.cluster"

skynet.start(function()

	--require("test").main()
	--skynet.exit()

	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end

	local _node_name=skynet.getenv "my_node_name"
	cluster.open (_node_name)

	--------------------------------------------------------
	-- 启动
	--

	-- 中心
	local _center_service = skynet.uniqueservice("center_service")
	cluster.register("center_ser", _center_service)

	-- 网关
	local _gate_svr = skynet.newservice("gate_service/gate_service")
	cluster.register("gate_svr", _gate_svr)

	-- 数据
	local _data_svr = skynet.newservice("data_service/data_service")
	cluster.register("data_svr", _data_svr)

	-- 登录
	local _login_svr = skynet.newservice("login_service/login_service")
	cluster.register("login_svr", _login_svr)

	-- 验证
	local _verify_svr = skynet.newservice("verify_service/verify_service")
	cluster.register("verify_svr", _verify_svr)

	-- 节点服务
	local _node_service = skynet.uniqueservice("node_service")
	local _register_name="node_ser_1"
	cluster.register(_register_name, _node_service)


	local _ddz_match_center_service = skynet.uniqueservice("ddz_match_center_service/ddz_match_center_service")
	cluster.register("ddz_match_center_service", _ddz_match_center_service)

	------------------------------------------------------
	-- 初始化相关服务
	--

	-- 环境配置数据
	local _service_config = {
			center_service=_center_service,
			data_service=_data_svr,
			login_service=_login_svr,
			verify_service=_verify_svr,
			--test_agent_manager=_test_agent_manager,
			node_service=_node_service,
			ddz_match_center_service=_ddz_match_center_service,
	}

	skynet.call(_login_svr, "lua", "start" ,_service_config)
	skynet.call(_data_svr, "lua", "start" ,_service_config)
	skynet.call(_gate_svr, "lua", "start" ,_service_config)
	skynet.call(_verify_svr, "lua", "start" ,_service_config)

	-- 初始化节点服务
	local _node_ID=skynet.call(_center_service, "lua", "get_node_id")
	skynet.call(_node_service, "lua", "start",{
													id=_node_ID,
													res=5000,
													node_name=_node_name,
													register_name=_register_name,
												},
												_service_config
											)

	skynet.call(_ddz_match_center_service, "lua", "start",_service_config)

	skynet.exit()
end)
