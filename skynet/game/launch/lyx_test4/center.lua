--
-- 作者: lyx
-- Date: 2018/3/10
-- Time: 14:48
-- 服务的配置文件，所有服务信息 都配置在这里
--


-- -- 商城服务器
-- local shoping_server = "http://jy-mall-webapp-user.ngrok.wd310.com"

-- -- 充值服务器
-- local payment_server = "http://jy-es-caller.ngrok.wd310.com"

-- 商城服务器
local shoping_server = "http://test.mall-webapp-user.jyhd919.cn"

local shoping_api_server = "http://test.mall-server-user.jyhd919.cn/"

-- 充值服务器
local payment_server = "http://test.es-caller.jyhd919.cn"

--------------------------------------------------
-- 全局参数配置，分发到每个节点
local configs =
{

	-- 如果不是调试阶段，则注释掉此行
	debug = 1,

	-- 支付测试：为 true 则表示支付行为在测试环境
	is_pay_test = true,

	-- 强化托管玩家： id , 名字, 头像
	tuoguan_list = "robot_list_tg",

	-- 网关配置
	gate_port = 5004,		-- 监听端口
	gate_maxclient = 1000000,	-- 同时在线
	max_request_rate = 100,	-- 每个客户端 5 秒内最大的请求数

	-- 支付测试：为 true 则表示支付行为在测试环境
	is_pay_test = true,
	
	-- 发布准备状态倒计时，单位 秒。 服务启动时，在倒计时结束后才允许登录
	--publish_prepare_cd = 900,

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

	-- 管理控制台端口：管理服务状态、关机
	admin_console_port = 7004,

	--dev_debug = 1,
	--client_message_log = 1,

	-- 语音聊天最大长度（单位 kB）
	voice_max_len = 30,

	--web
	webserver_port = 8004,
	webserver_agent_num = 1,
	webserver_disable_cache = true,

	-- mysql_host = "192.168.0.203",
	-- mysql_dbname = "jygame",
	-- mysql_port = 23456,
	-- mysql_user = "jy",
	-- mysql_pwd = "123456",

	mysql_host = "127.0.0.1",
	mysql_dbname = "jygame",
	mysql_port = 3306,
	mysql_user = "root",
	mysql_pwd = "123456",
	
	-- skynet 调试控制台端口
	debug_console_port = 28004,

	-- 客户端bug报告文件
	clientBugTrackLog = "logs/client_bug_report_",

	-- 友盟推送
	umeng_android_appkey = "5b8d0566f29d98698d0000c8",
	umeng_android_master_secret = "jx9o6uplgm7tftdzjl45sgnhufq3zpoi",
	umeng_ios_appkey = "5b8e1f8eb27b0a1355000063",
	umeng_ios_master_secret = "furryknmq5xq05xhzuerpoxmzfy70khp",

	-- 产品模式： false 表示只发送给测试设备
	umeng_ios_pmode = "false",

	-- 禁止游客登录
	forbid_youke = nil,

	-- 禁止 sql 日志
	--forbid_sql_log = true,

	-- 禁止强化托管代码
	--forbid_tuoguan_manager = true,
	
	tuoguan_max_count = 5,

	-- ddz lv1 tuoguan
	nor_ddz_hp_shuangfei=40,
	nor_ddz_hp_sanfei=50,
	nor_ddz_hp_max_boom=2,
	nor_ddz_hp_boom=60,
	nor_ddz_hp_limit_dp_count=50,

	-- 给指定 游戏模式的 指定 id 分配托管： tuoguan_[游戏模式]_[id]
	-- 特别的 tuoguan_[游戏模式]_x 表示 所有该游戏模式的场次
	tuoguan_match_game_2 = true,
	tuoguan_match_game_3 = true,
	tuoguan_freestyle_game_1 = true,
	tuoguan_freestyle_game_2 = true,
	tuoguan_freestyle_game_13 = true,
	tuoguan_freestyle_game_14 = true,
	tuoguan_freestyle_game_17 = true,
	tuoguan_freestyle_game_18 = true,

	-- 强化托管操作延时：1/100 秒
	tuoguan_mj_delay_1 = 50,
	tuoguan_mj_delay_2 = 250,
	tuoguan_ddz_delay_1 = 50,
	tuoguan_ddz_delay_2 = 250,

	--tuoguan_freestyle_game_x = true,

	-- 调试警报系统
	--debug_monitor_system = true,

	-- 打开系统报警功能
	enable_monitor = true,

	-- 每种报警数据 发送告警邮件的最短时间间隔（秒）
	monitor_email_time = 5,

	-- 不真正发邮件，仅仅输出日志（测试用）
	monitor_mock_email = true,

	-- 接收报警数据 的 邮件地址（支持多个，逗号隔开）
	monitor_recieve_email = "695223392@qq.com,421951953@qq.com,24090841@qq.com,949652665@qq.com,344813836@qq.com,83046971@qq.com,liangpai@163.com",
	--- 任务系统 是否启用
	--task_system_is_open = true,

	--- 步步生财 是否启用
	stepstep_money_is_open = true,
	
	-- 禁止 外部创建订单。目前就是 微信公总号支付
	--forbid_external_order = true,

	-- 登录调试
	--network_error_debug = true,

	-- 重加载中心 调试模式
	debug_reload_center = true,

	-- 自由的托管（不限于入场范围）
	free_tuoguan_count = 100,

	-- 托管可以随便发互动表情
	tuoguan_interaction_always = true,

	--麻将发好牌配置************************start
	er_mj_hp_hu_time_min=2,
	er_mj_hp_hu_time_max=4,
	er_mj_hp_ddz_gailv=40,
	er_mj_hp_peng_gailv=60,
	er_mj_hp_gang_gailv=40,
	nor_mj_hp_hu_time_min=4,
	nor_mj_hp_hu_time_max=7,
	nor_mj_hp_ddz_gailv=40,
	nor_mj_hp_peng_gailv=60,
	nor_mj_hp_gang_gailv=40,
	er_mj_hp_qys_gailv=95,
	er_mj_hp_lqd_gailv=40,
	nor_mj_hp_qys_gailv=60,
	nor_mj_hp_lqd_gailv=20,
	--麻将发好牌配置************************end	

	tuoguan_er_mj_dapiao_gailv = 25,
	--------------------------free matching--------------------------------
	-- 自由场随机匹配的阀值，小于用托管补充 默认值为15
	-- tuoguan_freestyle_game_free_match_player_min_num_1 = 3,
	-- tuoguan_freestyle_game_free_match_player_min_num_2 = 3,
	-- tuoguan_freestyle_game_free_match_player_min_num_3 = 3,
	-- tuoguan_freestyle_game_free_match_player_min_num_4 = 3,

	-- 托管请求间隔
	freestyle_game_tuoguan_update_interval_19 = 16,
	freestyle_game_tuoguan_update_interval_20 = 16,
	-- 托管请求间隔随机浮动值
	-- tuoguan_update_interval_random_1 = 2,
	---------------------------------------------------------
	---- 幸运号 ******************************* ↓↓↓
    -- 幸运号地主概率
    lock_id_ddz_dz_rate = 60,
    -- 幸运账号个数
    lucky_id_num = 0,
    
    --
    lucky_id_1 = "",

    ---- 幸运号 ******************************* ↑↑↑

	-- ddz lv1 tuoguan
	nor_ddz_hp_shuangfei=40,
	nor_ddz_hp_sanfei=50,
	nor_ddz_hp_max_boom=2,
	nor_ddz_hp_boom=60,
	nor_ddz_hp_limit_dp_count=50,
	
	zajindan_is_open = true,

	debug_gain_power = 0,

	--tuoguan_v_tuoguan = true,

	-- 经典斗地主
	tuoguan_ob_freestyle_game_1 = true,
	tuoguan_ob_freestyle_game_2 = true,
	tuoguan_ob_freestyle_game_3 = true,
	tuoguan_ob_freestyle_game_4 = true,

	-- 川渝斗地主
	tuoguan_ob_freestyle_game_21 = true,
	tuoguan_ob_freestyle_game_22 = true,
	tuoguan_ob_freestyle_game_23 = true,
	tuoguan_ob_freestyle_game_24 = true,
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
	{	-- 重加载 中心
		launch = "reload_center/reload_center",
		deploy = {reload_center="node_1"},
	},
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
	{	-- 资产服务
		launch = "asset_service/asset_service",
		deploy = {asset_service="node_1"},
	},
	{	-- 砸金蛋 管理 服务
		launch = "zajindan_manager_service/zajindan_manager_service",
		deploy = {zajindan_manager_service="node_1"},
	},
	{	-- 步步生财 中心服务
		launch = "bbsc_center_service/bbsc_center_service",
		deploy = {bbsc_center_service="node_1"},
	},
	{	-- 生财之道中心服务
		launch = "sczd_center_service/sczd_center_service",
		deploy = {sczd_center_service="node_1"},
	},
	{	-- 生财之道  高级合伙人 中心服务
		launch = "sczd_gjhhr_service/sczd_gjhhr_service",
		deploy = {sczd_gjhhr_service="node_1"},
	},
	{	-- 金猪  中心
		launch = "goldpig_center_service/goldpig_center_service",
		deploy = {goldpig_center_service="node_1"},
	},
	{	-- 强化托管服务
		launch = "tuoguan_service/tuoguan_service",
		deploy = {tuoguan_service="node_1"},
	},
	{	-- 比赛场
		launch = "match_center_service/match_center_service",
		deploy = {match_center_service="node_1"},
	},
	{	-- 冠名赛辅助服务
		launch = "naming_match_assist_service",
		deploy = {naming_match_assist_service="node_1"},
	},
	{	-- 分享服务
		launch = "shared_game_center_service",
		deploy = {shared_game_center_service="node_1"},
	},
	{	-- 自由场
		launch = "freestyle_game_center_service/freestyle_game_center_service",
		deploy = {freestyle_game_center_service="node_1"},
	},
	{	-- 斗地主百万大奖赛
		launch = "ddz_million_center_service/ddz_million_center_service",
		deploy = {ddz_million_center_service="node_1"},
	},
	{	-- 血流麻将自由场
		launch = "normal_mjxl_freestyle_center_service/normal_mjxl_freestyle_center_service",
		deploy = {normal_mjxl_freestyle_center_service="node_1"},
	},
	{	-- 听用斗地主自由场
		launch = "tyddz_freestyle_center_service/tyddz_freestyle_center_service",
		deploy = {tyddz_freestyle_center_service="node_1"},
	},
	{	-- 房卡
		launch = "friendgame_center_service/friendgame_center_service",
		deploy = {friendgame_center_service="node_1"},
	},
	{	-- 游戏 盈亏统计 管理
		launch = "game_profit_manager_service/game_profit_manager",
		deploy = {game_profit_manager="node_1"},
	},
	{	-- 邮件服务
		launch = "email_service/email_service",
		deploy = {email_service="node_1"},
	},
	{	-- 支付服务
		launch = "pay_service/pay_service",
		deploy = {pay_service="node_1"},
	},
	{	-- 商城配置中心服务
		launch = "shoping_config_center_service",
		deploy = {shoping_config_center_service="node_1"},
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
	{	-- 荣耀中心
		launch = "glory_center_service",
		deploy = {glory_center_service="node_1"},
	},
	{	-- 任务中心
		launch = "task_center_service/task_center_service",
		deploy = {task_center_service="node_1"},
	},
	--[[{	-- vip 中心服务
		launch = "vip_center_service/vip_center_service",
		deploy = {vip_center_service="node_1"},
	},--]]
	{	-- 抽奖中心
		launch = "lottery_center_service",
		deploy = {lottery_center_service="node_1"},
	},
	{	-- 兑换码中心
		launch = "redeem_code_center_service/redeem_code_center_service",
		deploy = {redeem_code_center_service="node_1"},
	},
	{	-- 自由场活动中心 服务
		launch = "freestyle_activity_center_service/freestyle_activity_center_service",
		deploy = {freestyle_activity_center_service="node_1"},
	},
	{	-- 服务管理
		launch = "admin_console_service/admin_console_service",
		deploy = {service_console="node_1"},
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
	{	-- 客户端bug记录服务
		launch = "client_bug_log_service/client_bug_log_service",
		deploy = {cbug_log_service="node_1"},
	},
	{	-- 系统监控服务
		launch = "monitor_service/monitor_service",
		deploy = {monitor_service="node_1"},
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