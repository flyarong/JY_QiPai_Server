--
-- 作者: lyx
-- Date: 2018/3/10
-- Time: 14:48
-- 服务的配置文件，所有服务信息 都配置在这里
--

-- 商城服务器
--shoping_server = "http://mall-webapp-user.jyhd919.cn"
local shoping_server = "http://jy-mall-webapp-user.ngrok.wd310.com"

-- 充值服务器
local payment_server = "http://test-es-caller.jyhd919.cn"
--payment_server = "http://jy-es-caller.ngrok.wd310.com"

--------------------------------------------------
-- 全局参数配置，分发到每个节点
local configs = 
{
	-- 支付测试：为 true 则表示支付行为在测试环境
	is_pay_test = true,

	-- 网关配置
	gate_port = 5001,		-- 监听端口
	gate_maxclient = 5000,	-- 同时在线
	max_request_rate = 100,	-- 每个客户端 5 秒内最大的请求数

	-- 支付测试：为 true 则表示支付行为在测试环境
	is_pay_test = true,
	
	client_message_log = 1,

	-- 商城接口 url
	shoping_url = shoping_server .. "/#/?token=@token@",

	-- 支付接口的 url
	payment_url = payment_server .. "/Pay.apply.do?order_id=@order_id@",

	-- 提现接口 url
	withdraw_url = payment_server .. "/Withdraw.apply.do?withdrawId=@withdrawId@",

	-- 分享 url
	get_share_url = payment_server .. "/MpWeixinPublic.generateUserRecommendQrCode.do?userId=@userId@",

	-- 发送短信 url
	send_phone_sms_url = payment_server .. "/Sms.send.do",
	signName_bind_phone = "竟娱互动",
	templateCode_bind_phone = "SMS_136171608",

	-- 商城 token 的超时时间（秒）
	shop_token_timeout = 180,

	-- 客户端bug报告文件
	clientBugTrackLog = "logs/client_bug_report_",
	
	-- 管理控制台端口：管理服务状态、关机
	admin_console_port = 7001,

	dev_debug = 1,

	client_message_log = 1,

	--web
	webserver_port = 8001,
	webserver_agent_num = 1,
	webserver_disable_cache = true,

	mysql_host = "192.168.0.203",
	mysql_dbname = "hewei_test",
	mysql_port = 23456,
	mysql_user = "jy",
	mysql_pwd = "123456",

	-- skynet 调试控制台端口
	debug_console_port = 8000,
}

--------------------------------------------------
-- 节点参数配置，可覆盖全局配置
-- 系统参数说明：
--	resource 可分配的资源数量
--	resource_types 可分配的资源类型集合
--		格式： {"ddz_test_agent","player_agent/player_agent"}
--		默认：不填则允许所有类型
--

local nodes =
{
	-- 节点
	node_1 =
	{
		resource = 50000,
	},
}

--------------------------------------------------
-- 服务配置
-- 说明：
--	launch 启动文件，给出启动的 lua 文件位置
--	deploy 部署配置，指定要部署到哪些节点，并给出名字：
--		1、全局服务，在每个节点均有唯一名字，例如：
--			{test_name1=node_1,test_name2=node_2,...}
--		2、私有服务，在不同节点名字均相同，例如：
--			{test_name={node_1,node_2,...}}
--
--			特别的，部署到所有节点：{test_name="*"}
--

local services =
{
	{	-- 数据
		launch = "data_service/data_service",
		deploy = {data_service="node_1"},
	},
	{	-- 后台管理系统：数据采集
		launch = "collect_service/collect_service",
		deploy = {collect_service="node_1"},
	},
	{	-- 登录
		launch = "login_service/login_service",
		deploy = {login_service="node_1"},
	},
	{	-- 验证
		launch = "verify_service/verify_service",
		deploy = {verify_service="node_1"},
	},
	{	-- 比赛场
		launch = "match_center_service/match_center_service",
		deploy = {match_center_service="node_1"},
	},
	{	-- 斗地主自由场
		launch = "ddz_freestyle_center_service/ddz_freestyle_center_service",
		deploy = {ddz_freestyle_center_service="node_1"},
	},
	{	-- 斗地主百万大奖赛
		launch = "ddz_million_center_service/ddz_million_center_service",
		deploy = {ddz_million_center_service="node_1"},
	},
	{	-- 血战麻将自由场
		launch = "majiang_freestyle_center_service/majiang_freestyle_center_service",
		deploy = {majiang_freestyle_center_service="node_1"},
	},
	{	-- 血流麻将自由场
		launch = "normal_mjxl_freestyle_center_service/normal_mjxl_freestyle_center_service",
		deploy = {normal_mjxl_freestyle_center_service="node_1"},
	},
	{	-- 癞子斗地主自由场
		launch = "lzddz_freestyle_center_service/lzddz_freestyle_center_service",
		deploy = {lzddz_freestyle_center_service="node_1"},
	},
	{	-- 听用斗地主自由场
		launch = "tyddz_freestyle_center_service/tyddz_freestyle_center_service",
		deploy = {tyddz_freestyle_center_service="node_1"},
	},
	{	-- 房卡
		launch = "friendgame_center_service/friendgame_center_service",
		deploy = {friendgame_center_service="node_1"},
	},
	{	-- 邮件服务
		launch = "email_service/email_service",
		deploy = {email_service="node_1"},
	},
	{	-- 支付服务
		launch = "pay_service/pay_service",
		deploy = {pay_service="node_1"},
	},
	{	-- 广播服务
		launch = "broadcast_service/broadcast_service",
		deploy = {broadcast_svr="*"},
	},
	{	-- web 服务
		launch = "websever_service/websever_service",
		deploy = {web_server_service="node_1"},
	},
	{	-- 广播中心
		launch = "broadcast_center_service/broadcast_center_service",
		deploy = {broadcast_center_service="node_1"},
	},
	{	-- 服务管理
		launch = "admin_console_service/admin_console_service",
		deploy = {service_console="node_1"},
	},
	{	-- load_and_stop_ser_service
		launch = "load_and_stop_ser_service",
		deploy = {load_and_stop_ser_service="node_1"},
	},
	{	-- 游戏管理
		launch = "game_manager_service/game_manager_service",
		deploy = {game_manager_service="node_1"},
	},
	{	-- 第三方服务代理，如 短信、分享
		launch = "third_agent_service/third_agent_service",
		deploy = {third_agent_service="node_1"},
	},
	{	-- 自由场机器人调度器：为排队过久的用户安排陪玩机器人
		launch = "freestyle_robot_observer_service/freestyle_robot_observer_service",
		deploy = {free_bot_ob_service="node_1"},
	},
	{	-- 聊天室服务
		launch = "chat_service/chat_service",
		deploy = {chat_service="node_1"},
	},
	{	-- web客户端服务：转发 http 请求
		launch = "webclient_service",
		deploy = {webclient_service="*"},
	},
	{	-- 网关
		launch = "gate_service/gate_service",
		deploy = {gate_service="node_1"},
	},
}


return {
	
	configs = configs,
	nodes = nodes,
	services = services,
}


