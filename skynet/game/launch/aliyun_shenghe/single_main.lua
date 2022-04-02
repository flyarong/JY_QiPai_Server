--
-- 作者: lyx
-- Date: 2018/3/10
-- Time: 14:48
-- gate 的启动文件
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"

-- 服务配置： name -> addr
local _service_config = {}

-- 加入服务
-- 参数 _param ：
--	name 服务名字 
--	launch_file 服务的启动文件（lua 代码）
--	remote_node 远程节点名
-- 说明： launch_file ， remote_node 二选一，前者表示从本机启动，后者表示 从 远程代理
local function create_service(_param)

	if _param.launch_file then
		print("launch service: ",_param.name)
		_service_config[_param.name] = skynet.uniqueservice(_param.launch_file)
	else

		if not _param.remote_node then
			error(string.format("service '%s' has not remote_node name !",_param.name))
			return
		end

		print("proxy service: ",_param.name,_param.remote_node)
		_service_config[_param.name] = cluster.proxy(_param.remote_node,_param.name)
	end

end

skynet.start(function()

--	require("test").main()
--	skynet.exit()

	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end

	local _dcp = skynet.getenv("debug_console_port")
	if _dcp then
		skynet.newservice("debug_console",tonumber(_dcp))
	end

	local _my_node_name = skynet.getenv "my_node_name"
	cluster.open(_my_node_name)

	--------------------------------------------------------
	-- 服务列表：
	--	name 		服务名字 
	--	launch_file 服务的启动文件（lua 代码）
	--	remote_node 远程节点名
	--
	-- 说明： launch_file ， remote_node 二选一，前者表示从本机启动，后者表示 从 远程代理
	-- 

	local _services =
	{
		{	-- 中心
			name = "center_service",
			launch_file = "center_service",
		},
		{	-- 节点
			name = "node_service",
			launch_file = "node_service",
		},
		{	-- 网关
			name = "gate_service",
			launch_file = "gate_service/gate_service",
		},
		{	-- 数据
			name = "data_service",
			launch_file = "data_service/data_service",
		},
		{	-- 后台管理系统：数据采集
			name = "collect_service",
			launch_file = "collect_service/collect_service",
		},
		{	-- 登录
			name = "login_service",
			launch_file = "login_service/login_service",
		},
		{	-- 验证
			name = "verify_service",
			launch_file = "verify_service/verify_service",
		},
		{	-- 斗地主比赛场
			name = "ddz_match_center_service",
			launch_file = "ddz_match_center_service/ddz_match_center_service",
		},
		{	-- 斗地主自由场
			name = "ddz_freestyle_center_service",
			launch_file = "ddz_freestyle_center_service/ddz_freestyle_center_service",
		},
		{	-- 斗地主百万大奖赛
			name = "ddz_million_center_service",
			launch_file = "ddz_million_center_service/ddz_million_center_service",
		},
		{	-- 血战麻将自由场
			name = "majiang_freestyle_center_service",
			launch_file = "majiang_freestyle_center_service/majiang_freestyle_center_service",
		},
		{	-- 血流麻将自由场
			name = "normal_mjxl_freestyle_center_service",
			launch_file = "normal_mjxl_freestyle_center_service/normal_mjxl_freestyle_center_service",
		},
		{	-- 癞子斗地主自由场
			name = "lzddz_freestyle_center_service",
			launch_file = "lzddz_freestyle_center_service/lzddz_freestyle_center_service",
		},
		{	-- 听用斗地主自由场
			name = "tyddz_freestyle_center_service",
			launch_file = "tyddz_freestyle_center_service/tyddz_freestyle_center_service",
		},
		{	-- 邮件服务
			name = "email_service",
			launch_file = "email_service/email_service",
		},
		{	-- 支付服务
			name = "pay_service",
			launch_file = "pay_service/pay_service",
		},
		{	-- 广播服务
			name = "broadcast_svr",
			launch_file = "broadcast_service/broadcast_service",
		},
		{	-- web 服务
			name = "web_server_service",
			launch_file = "websever_service/websever_service",
		},
		{	-- 服务管理
			name = "service_console",
			launch_file = "admin_console_service/admin_console_service",
		},
		{	-- 游戏管理
			name = "game_manager_service",
			launch_file = "game_manager_service/game_manager_service",
		},
		{	-- 第三方服务代理，如 短信、分享
			name = "third_agent_service",
			launch_file = "third_agent_service/third_agent_service",
		},
		{	-- 自由场机器人调度器：为排队过久的用户安排陪玩机器人
			name = "free_bot_ob_service",
			launch_file = "freestyle_robot_observer_service/freestyle_robot_observer_service",
		},
		{	-- web客户端服务：转发 http 请求
			name = "webclient_service",
			launch_file = "webclient_service",
		},
	}


	----------------------------------------------------------------
	-- 创建服务：启动 本地服务 或 代理 远程服务

	for _,_ser_info in ipairs(_services) do
		create_service(_ser_info)
	end

	----------------------------------------------------------------
	-- 开始本地服务

	skynet.sleep(30)
	for _,_ser_info in ipairs(_services) do

		if _ser_info.launch_file then -- 只启动本地服务

			local _ser = _service_config[_ser_info.name]

			skynet.call(_ser,"lua","set_service_name",_ser_info.name)
			cluster.register(_ser_info.name, _ser)

			if "node_service" == _ser_info.name then

				local _config = {
							id=skynet.call(_service_config.center_service, "lua", "get_node_id"),
							res=5000,
							node_name=_my_node_name,
							register_name=_ser_info.name,
					}
					
				skynet.call(_ser, "lua", "start",_config,_service_config)
			else
				skynet.call(_ser, "lua", "start",_service_config)
			end
		end
	end

	skynet.exit()
end)
