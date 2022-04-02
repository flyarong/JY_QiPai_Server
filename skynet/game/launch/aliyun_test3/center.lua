--
-- 作者: lyx
-- Date: 2018/3/10
-- Time: 14:48
-- 服务的配置文件，所有服务信息 都配置在这里
--

-- 商城服务器
shoping_server = "http://test.mall-webapp-user.jyhd919.cn"

shoping_api_server = "http://test.mall-server-user.jyhd919.cn/"

-- 充值服务器
payment_server = "http://test.es-caller.jyhd919.cn"

--------------------------------------------------
-- 全局参数配置，分发到每个节点
local configs = 
{
	-- 支付测试：为 true 则表示支付行为在测试环境
	is_pay_test = true,

	-- 网关配置
	gate_port = 5003,		-- 监听端口
	gate_maxclient = 5000,	-- 同时在线
	max_request_rate = 100,	-- 每个客户端 5 秒内最大的请求数

	-- 商城接口 url
	shoping_url = shoping_server .. "/#/?token=@token@",

	-- 支付接口的 url
	payment_url = payment_server .. "/Pay.apply.do?order_id=@order_id@",

	-- 提现接口 url
	withdraw_url = payment_server .. "/Withdraw.apply.do?withdrawId=@withdrawId@",

	-- 分享 url
	get_share_url = payment_server .. "/MpWeixinPublic.generateUserRecommendQrCode.do?userId=@userId@",

	-- 1元话费url
	pay_phone_tariffe_url = shoping_api_server .. "/OrderTransactor.goodsOrderPlaceForShoppingGoldPay.command",

	-- 1元话费商品id
	pay_phone_tariffe_goodsid="89181",

	-- 发送短信 url
	send_phone_sms_url = payment_server .. "/Sms.send.do",
	-- signName_bind_phone = "竟娱互动",
	-- templateCode_bind_phone = "SMS_136171608",
	
	-- 客户端bug报告文件
	clientBugTrackLog = "logs/client_bug_report_",
	
	client_message_log = 1,

	-- 商城 token 的超时时间（秒）
	shop_token_timeout = 180,
	--web
	webserver_port = 8003,
	webserver_agent_num = 20,

	debug_player_prefix = "S3",
}

--------------------------------------------------
-- 节点参数配置，可覆盖全局配置
-- 系统参数说明：
--	resource 可分配的资源数量
--	resource_types 可分配的资源类型集合
--		格式： {"ddz_test_agent","player_agent/player_agent"}
--		默认：不填则允许所有类型
--	reject_resource_types 拒绝的资源类型集合（暂未实现）
--

local nodes = 
{
	-- 游戏
	game = 
	{

	},

	-- 数据
	data = 
	{
		resource = 500000,

		-- 数据服务配置
		mysql_host = "127.0.0.1",
		mysql_dbname = "jygame3",
		mysql_port = 3306,
		mysql_user = "game",
		mysql_pwd = "jYserVer135",
		--mysql_user = "root",
		--mysql_pwd = "jY123",



		-- skynet 调试控制台端口
		debug_console_port = 8513,

		-- 管理控制台端口：管理服务状态、关机
		admin_console_port = 7003,
	},

	-- 网关
	gate = 
	{

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
		deploy = {data_service="data"},
	},
	{	-- 后台管理系统：数据采集
		launch = "collect_service/collect_service",
		deploy = {collect_service="data"},
	},
	{	-- 登录
		launch = "login_service/login_service",
		deploy = {login_service="data"},
	},
	{	-- 验证
		launch = "verify_service/verify_service",
		deploy = {verify_service="data"},
	},
	{	-- 房卡场
		launch = "friendgame_center_service/friendgame_center_service",
		deploy = {friendgame_center_service="data"},
	},
	{	-- 斗地主比赛场
		launch = "ddz_match_center_service/ddz_match_center_service",
		deploy = {ddz_match_center_service="data"},
	},
	{	-- 斗地主自由场
		launch = "ddz_freestyle_center_service/ddz_freestyle_center_service",
		deploy = {ddz_freestyle_center_service="data"},
	},
	{	-- 斗地主百万大奖赛
		launch = "ddz_million_center_service/ddz_million_center_service",
		deploy = {ddz_million_center_service="data"},
	},
	{	-- 血战麻将自由场
		launch = "majiang_freestyle_center_service/majiang_freestyle_center_service",
		deploy = {majiang_freestyle_center_service="data"},
	},
	{	-- 血流麻将自由场
		launch = "normal_mjxl_freestyle_center_service/normal_mjxl_freestyle_center_service",
		deploy = {normal_mjxl_freestyle_center_service="data"},
	},
	{	-- 癞子斗地主自由场
		launch = "lzddz_freestyle_center_service/lzddz_freestyle_center_service",
		deploy = {lzddz_freestyle_center_service="data"},
	},
	{	-- 听用斗地主自由场
		launch = "tyddz_freestyle_center_service/tyddz_freestyle_center_service",
		deploy = {tyddz_freestyle_center_service="data"},
	},
	{	-- 邮件服务
		launch = "email_service/email_service",
		deploy = {email_service="data"},
	},
	{	-- 支付服务
		launch = "pay_service/pay_service",
		deploy = {pay_service="data"},
	},
	{	-- 广播服务
		launch = "broadcast_service/broadcast_service",
		deploy = {broadcast_svr="*"},
	},
	{	-- web 服务
		launch = "websever_service/websever_service",
		deploy = {web_server_service="data"},
	},
	{	-- 服务管理
		launch = "admin_console_service/admin_console_service",
		deploy = {service_console="data"},
	},
	{	-- 游戏管理
		launch = "game_manager_service/game_manager_service",
		deploy = {game_manager_service="data"},
	},
	{	-- 第三方服务代理，如 短信、分享
		launch = "third_agent_service/third_agent_service",
		deploy = {third_agent_service="data"},
	},
	{	-- 自由场机器人调度器：为排队过久的用户安排陪玩机器人
		launch = "freestyle_robot_observer_service/freestyle_robot_observer_service",
		deploy = {free_bot_ob_service="data"},
	},
	{	-- 聊天室服务
		launch = "chat_service/chat_service",
		deploy = {chat_service="data"},
	},
	{	-- web客户端服务：转发 http 请求
		launch = "webclient_service",
		deploy = {webclient_service="*"},
	},
	{	-- 网关
		launch = "gate_service/gate_service",
		deploy = {gate_service="data"},
	},
}


return {
	
	configs = configs,
	nodes = nodes,
	services = services,
}