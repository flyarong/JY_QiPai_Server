--
-- 作者: lyx
-- Date: 2018/3/10
-- Time: 14:48
-- gate 的启动文件
--

local skynet = require "skynet"
local cluster = require "skynet.cluster"

skynet.start(function()

--	require("test").main()
--	skynet.sleep(3600000)
--	skynet.exit()

	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end

	skynet.newservice("debug_console",8000)

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

	-- 数据采集服务（供 web 后台采集数据）
	local _collect_svr = skynet.newservice("collect_service/collect_service")
	cluster.register("collect_service", _collect_svr)

	-- webclient
	local _webclient_svr = skynet.newservice("webclient_service")
	cluster.register("webclient_ser", _webclient_svr)

	-- webserver
	local _web_server_service = skynet.newservice("websever_service/websever_service")

	-- 登录
	local _login_svr = skynet.newservice("login_service/login_service")
	cluster.register("login_svr", _login_svr)

	-- 验证
	local _verify_svr = skynet.newservice("verify_service/verify_service")
	cluster.register("verify_svr", _verify_svr)

	-- 邮件
	local _email_svr = skynet.newservice("email_service/email_service")
	cluster.register("email_svr", _email_svr)

	-- 广播
	local _broadcast_svr = skynet.newservice("broadcast_service/broadcast_service")
	cluster.register("broadcast_svr", _broadcast_svr)

	-- 游戏管理服务
	local _game_manager_service = skynet.uniqueservice("game_manager_service/game_manager_service")
	cluster.register("game_manager_service", _game_manager_service)
	
	-- 比赛场
	local _ddz_match_center_service = skynet.uniqueservice("ddz_match_center_service/ddz_match_center_service")
	cluster.register("ddz_match_center_svr", _ddz_match_center_service)

	-- 自由场
	local _ddz_freestyle_center_service = skynet.uniqueservice("ddz_freestyle_center_service/ddz_freestyle_center_service")
	cluster.register("ddz_freestyle_center_svr", _ddz_freestyle_center_service)

	-- 万人场
	local _ddz_million_center_service = skynet.uniqueservice("ddz_million_center_service/ddz_million_center_service")
	cluster.register("ddz_million_center_ser", _ddz_million_center_service)

	-- 自由场 - 麻将
	local _majiang_freestyle_center_service = skynet.uniqueservice("majiang_freestyle_center_service/majiang_freestyle_center_service")
	cluster.register("majiang_freestyle_center_svr", _majiang_freestyle_center_service)


	-- 自由场 - 麻将（血流）
	local _normal_mjxl_freestyle_center_service = skynet.uniqueservice("normal_mjxl_freestyle_center_service/normal_mjxl_freestyle_center_service")
	cluster.register("normal_mjxl_freestyle_center_svr", _normal_mjxl_freestyle_center_service)


	-- 癞子自由场
	local _lzddz_freestyle_center_service = skynet.uniqueservice("lzddz_freestyle_center_service/lzddz_freestyle_center_service")
	cluster.register("lzddz_freestyle_center_svr", _lzddz_freestyle_center_service)


	-- 听用自由场
	local _tyddz_freestyle_center_service = skynet.uniqueservice("tyddz_freestyle_center_service/tyddz_freestyle_center_service")
	cluster.register("tyddz_freestyle_center_svr", _tyddz_freestyle_center_service)



	-- 支付服务
	local _pay_service = skynet.uniqueservice("pay_service/pay_service")
	cluster.register("pay_svr", _pay_service)



	-- 机器人
	local _robot_service = skynet.newservice("robot_service/robot_service")

	-- 节点服务
	local _node_service = skynet.uniqueservice("node_service")
	local _register_name="node_ser_1"
	cluster.register(_register_name, _node_service)

	-- 控制服务台
	local _service_console = skynet.newservice("admin_console_service/admin_console_service",7001)

	------------------------------------------------------
	-- 初始化相关服务
	--

	-- 环境配置数据
	local _service_config = {
			center_service=_center_service,
			data_service=_data_svr,
			collect_service=_collect_svr,
			login_service=_login_svr,
			verify_service=_verify_svr,
			ddz_match_center_service = _ddz_match_center_service,
			ddz_freestyle_center_service=_ddz_freestyle_center_service,
			ddz_million_center_service=_ddz_million_center_service,
			majiang_freestyle_center_service=_majiang_freestyle_center_service,
			normal_mjxl_freestyle_center_service=_normal_mjxl_freestyle_center_service,
			lzddz_freestyle_center_service=_lzddz_freestyle_center_service,
			tyddz_freestyle_center_service=_tyddz_freestyle_center_service,
			robot_service=_robot_service,
			node_service=_node_service,
			webclient_service=_webclient_svr,
			email_service=_email_svr,
			pay_service=_pay_service,
			broadcast_svr=_broadcast_svr,
			web_server_service=_web_server_service, -- 通常不会被调用，只是纳入关机管理
			service_console=_service_console,
			game_manager_service=_game_manager_service,
	}

	-- 初始化节点服务
	local  _node_id=skynet.call(_center_service, "lua", "get_node_id")
	skynet.call(_node_service, "lua", "start",{
													id=_node_id,
													res=5000,
													node_name=_node_name,
													register_name=_register_name,
												},
												_service_config
											)

	skynet.call(_webclient_svr, "lua", "start" ,_service_config)
	skynet.call(_login_svr, "lua", "start" ,_service_config)
	skynet.call(_data_svr, "lua", "start" ,_service_config)
	skynet.call(_collect_svr, "lua", "start" ,_service_config)
	skynet.call(_gate_svr, "lua", "start" ,_service_config)
	skynet.call(_verify_svr, "lua", "start" ,_service_config)
	skynet.call(_email_svr, "lua", "start",_service_config)
	skynet.call(_pay_service, "lua", "start",_service_config)
	skynet.call(_broadcast_svr, "lua", "start",_service_config)
	skynet.call(_ddz_match_center_service, "lua", "start",_service_config)
	skynet.call(_robot_service, "lua", "start",_service_config)
	skynet.call(_ddz_freestyle_center_service, "lua", "start",_service_config)
	skynet.call(_lzddz_freestyle_center_service, "lua", "start",_service_config)
	skynet.call(_tyddz_freestyle_center_service, "lua", "start",_service_config)
	skynet.call(_ddz_million_center_service, "lua", "start",_service_config)
	skynet.call(_majiang_freestyle_center_service, "lua", "start",_service_config)
	skynet.call(_normal_mjxl_freestyle_center_service, "lua", "start",_service_config)
	skynet.call(_service_console, "lua", "start",_service_config)
	skynet.call(_web_server_service, "lua", "start",_service_config)
	skynet.call(_game_manager_service, "lua", "start",_service_config)

	skynet.exit()
end)
