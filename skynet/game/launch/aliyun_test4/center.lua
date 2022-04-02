--
-- 作者: lyx
-- Date: 2018/3/10
-- Time: 14:48
-- 服务的配置文件，所有服务信息 都配置在这里
--

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

	-- 商城接口 url
	shoping_url = shoping_server .. "/#/?token=@token@",

	-- 支付接口的 url
	payment_url = payment_server .. "/Pay.apply.do?order_id=@order_id@",

	-- 提现接口 url
	withdraw_url = payment_server .. "/Withdraw.apply.do?withdrawId=@withdrawId@",

	-- 分享 url
	--get_share_url = payment_server .. "/MpWeixinPublic.generateUserRecommendQrCode.do?userId=@userId@",
	get_share_url = "https://testgjhhrht.jyhd919.cn/jyhd/common/generateUserRecommendQrCode?playerId=@userId@",

	-- 1元话费url
	pay_phone_tariffe_url = shoping_api_server .. "/OrderTransactor.goodsOrderPlaceForShoppingGoldPay.command",

	-- 1元话费商品id
	pay_phone_tariffe_goodsid="89181",

	-- 绑定手机的验证码通知短信
	bind_phone_code_sms = "【鲸鱼斗地主】亲爱的鲸鱼斗地主用户，您的验证码为：%s，该验证码有效时限为5分钟，请尽快确认。请注意不要泄露验证码，若非本人操作，请联系官方客服",

	-- 发送短信 url
	send_phone_sms_url = "http://es-caller.jyhd919.cn/Sms.send.do",
--	signName_bind_phone = "竟娱互动",
--	templateCode_bind_phone = "SMS_136171608",

	client_message_log = 1,
	-- 商城 token 的超时时间（秒）
	shop_token_timeout = 36000000,

	--web
	webserver_port = 8004,
	webserver_agent_num = 50,

	-- 数据服务配置
	mysql_host = "172.18.107.229",
	mysql_dbname = "jygame4",
	mysql_port = 3306,
	mysql_user = "game",
	mysql_pwd = "jYserVer135",

	gate_port = 5004,		-- 监听端口
	gate_maxclient = 100000,-- 同时在线

		-- 友盟推送
	umeng_android_appkey = "5b8d0566f29d98698d0000c8",
	umeng_android_master_secret = "jx9o6uplgm7tftdzjl45sgnhufq3zpoi",
	umeng_ios_appkey = "5b8e1f8eb27b0a1355000063",
	umeng_ios_master_secret = "furryknmq5xq05xhzuerpoxmzfy70khp",

	-- 产品模式： false 表示只推送给测试设备
	umeng_ios_pmode = "true",

	-- 每个agent承载的连接数
	--gate_agent_capacity = 200,

	-- 连接信息打印时间间隔（秒）
	--gate_info_print_time = 10,

	-- 客户端bug报告文件
	clientBugTrackLog = "logs/client_bug_report_",

	max_request_rate = 150,	-- 每个客户端 5 秒内最大的请求数

	-- 调试警报系统
	--debug_monitor_system = true,

	-- 打开系统报警功能
	enable_monitor = true,

	-- 每种报警数据 发送告警邮件的最短时间间隔（秒）
	monitor_email_time = 5,

	-- 不真正发邮件，仅仅输出日志（测试用）
	monitor_mock_email = true,

	-- 接收报警数据 的 邮件地址（支持多个，逗号隔开）
	monitor_recieve_email = "695223392@qq.com,421951953@qq.com,949652665@qq.com,24090841@qq.com,344813836@qq.com,83046971@qq.com,liangpai@163.com",

	-- ★ 非正式配置。注意： 正式发布要去掉！！！

	is_pay_test = true,
	debug_player_prefix = "P_",

	client_message_log = 1,		-- 打印客户端消息信息

	ddz_auto_jdz = true,		-- 自动叫地主

	-- 客户端bug报告文件
	clientBugTrackLog = "logs/client_bug_report_",

	-- dev_debug = 1,
	
	
	-- 禁止游客登录
	--forbid_youke = true,

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
	-- tuoguan_freestyle_game_free_match_player_min_num_1 = 15,
	-- 托管请求间隔
	freestyle_game_tuoguan_update_interval_19 = 16,
	freestyle_game_tuoguan_update_interval_20 = 16,
	-- 托管请求间隔随机浮动值
	-- tuoguan_update_interval_random_1 = 2,
	---------------------------------------------------------

	------------------cp cd---------------------
	tuoguan_mj_delay_1 = 100,
	tuoguan_mj_delay_2 = 150,

	tuoguan_ddz_delay_1 = 100,
	tuoguan_ddz_delay_2 = 200,

	player_agent_robot_cd=12,
	----------------------------------------

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

	-- 登录调试
	network_error_debug = true,

	free_tuoguan_count = 400,

	tuoguan_max_count = 700,
	
	-- 强化托管玩家的 id 清单
	tuoguan_list = "robot_list_tg",

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

	create_order_wait_time = 30,

	must_huan_zhuo_game_num = 2,
	
	tuoguan_freestyle_game_free_match_player_min_num_25 = 0,
	-- tuoguan_freestyle_game_free_match_player_min_num_1 = 0,
	-- tuoguan_freestyle_game_free_match_player_min_num_5 = 0,
	-- tuoguan_freestyle_game_free_match_player_min_num_9 = 0,
	-- tuoguan_freestyle_game_free_match_player_min_num_13 = 0,
	-- tuoguan_freestyle_game_free_match_player_min_num_17 = 0,


	--- 任务系统 是否启用
	task_system_is_open = true,

	--- 步步生财 是否启用
	stepstep_money_is_open = true,
	
	--- 砸金蛋是否启用
	zajindan_is_open = true,

	-- 烂牌 的情况下 抢地主的概率
	freestyle_game_down_bad_pai_dizhu = 80,
	freestyle_game_free_bad_pai_dizhu = 1,
	freestyle_game_up_bad_pai_dizhu = 2,
	match_game_down_bad_pai_dizhu = 80,
	match_game_free_bad_pai_dizhu = 3,
	match_game_up_bad_pai_dizhu = 4,

	ddz_tuoguan_imp_c=true,

	
	-- 是否对客户端-服务端通讯进行加密
	--proto_encrypt = true,

	-- 所有人都是 gm 用户（正式服 千万不能要这行！！！！）
	gm_user_debug = true,


	--砸金蛋
	--财神模式
	zjd_caishen_model=true,
	zjd_cs_lisnsheng_round=1,
	zjd_cs_lisnsheng_level_3=true,
	zjd_cs_lisnsheng_level_4=true,
	zjd_cs_lisnsheng_start=1556450713,
	zjd_cs_lisnsheng_end=1557071999,

	
	--高级合伙人自动结算
	gjhhr_auto_period_settle=true,
	--高级合伙人提现关闭  每月最后一天关闭
	-- wait_jicha_settle=true,
	--强制同意高级合伙人提现
	-- gjhhr_tx_force_agree=true,

	-- 自由场对局结算兑换红包的比例，如果为0或者nil即未开启
	freestyle_game_settle_exchange_hongbao = 0.005,

	
	-- 幸运宝箱抽奖
	luck_box_lottery_open = true,
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
		resource = 500000,

		-- skynet 调试控制台端口
		debug_console_port = 8104,

		-- 管理控制台端口：管理服务状态、关机
		admin_console_port = 7104,
	},

	-- 数据
	data =
	{
		-- skynet 调试控制台端口
		debug_console_port = 8104,

		-- 管理控制台端口：管理服务状态、关机
		admin_console_port = 7104,
	},

	-- 网关
	gate =
	{
		-- skynet 调试控制台端口
		debug_console_port = 8104,

		-- 管理控制台端口：管理服务状态、关机
		admin_console_port = 7104,

		network_error_debug = false,

	},

	-- 托管
	-- tg =
	-- {
	-- 	-- skynet 调试控制台端口
	-- 	debug_console_port = 8105,

	-- 	-- 管理控制台端口：管理服务状态、关机
	-- 	admin_console_port = 7105,
	-- },
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
		deploy = {reload_center="data"},
	},
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
	{	-- 消息通知中心
		launch = "msg_notification_center_service/msg_notification_center_service",
		deploy = {msg_notification_center_service="game"},
	},
	{	-- 调试控制服务
		launch = "debug_console_service/debug_console_service",
		deploy = {debug_console_service="game"},
	},
	{	-- 资产服务
		launch = "asset_service/asset_service",
		deploy = {asset_service="game"},
	},
	{	-- 礼券服务
		launch = "gift_coupon_center_service",
		deploy = {gift_coupon_center_service="game"},
	},
	{	-- 砸金蛋 管理 服务
		launch = "zajindan_manager_service/zajindan_manager_service",
		deploy = {zajindan_manager_service="game"},
	},
	--[[{	-- 砸金蛋 活动 服务
		launch = "zajindan_activity_service/zajindan_activity_service",
		deploy = {zajindan_activity_service="game"},
	},--]]
	{	-- 消消乐 管理 服务
		launch = "xiaoxiaole_manager_service/xiaoxiaole_manager_service",
		deploy = {xiaoxiaole_manager_service="game"},
	},
	{	-- 消消乐 开奖中心 服务
		launch = "xiaoxiaole_lottery_center_service/xiaoxiaole_lottery_center_service",
		deploy = {xiaoxiaole_lottery_center_service="game"},
	},
	{	-- 步步生财 中心服务
		launch = "bbsc_center_service/bbsc_center_service",
		deploy = {bbsc_center_service="game"},
	},
	{	-- 生财之道中心服务
		launch = "sczd_center_service/sczd_center_service",
		deploy = {sczd_center_service="game"},
	},
	{	-- 生财之道  高级合伙人 中心服务
		launch = "sczd_gjhhr_service/sczd_gjhhr_service",
		deploy = {sczd_gjhhr_service="game"},
	},
	{	-- 大富豪活动 服务 
		launch = "da_fu_hao_activity_service/da_fu_hao_activity_service",
		deploy = {da_fu_hao_activity_service="game"},
	},
	{	-- 金猪  中心
		launch = "goldpig_center_service/goldpig_center_service",
		deploy = {goldpig_center_service="game"},
	},
	{	-- 周卡
		launch = "zhouka_system_service/zhouka_system_service",
		deploy = {zhouka_system_service="game"},
	},
	{	-- vip 礼包
		launch = "sczd_vip_lb_service/sczd_vip_lb_service",
		deploy = {sczd_vip_lb_service="game"},
	},
	{	-- 房卡场
		launch = "friendgame_center_service/friendgame_center_service",
		deploy = {friendgame_center_service="game"},
	},
	{	-- 比赛场
		launch = "match_center_service/match_center_service",
		deploy = {match_center_service="game"},
	},
	{	-- 捕鱼
		launch = "fishing_game_center_service/fishing_game_center_service",
		deploy = {fishing_game_center_service="game"},
	},
	{	-- 玩家保护服务
		launch = "player_protect_service/player_protect_service",
		deploy = {player_protect_service="game"},
	},
	{	-- 冠名赛辅助服务
		launch = "naming_match_assist_service",
		deploy = {naming_match_assist_service="game"},
	},
	{	-- 分享服务
		launch = "shared_game_center_service",
		deploy = {shared_game_center_service="game"},
	},
	{	-- 自由场
		launch = "freestyle_game_center_service/freestyle_game_center_service",
		deploy = {freestyle_game_center_service="game"},
	},
	{	-- 斗地主百万大奖赛
		launch = "ddz_million_center_service/ddz_million_center_service",
		deploy = {ddz_million_center_service="game"},
	},
	{	-- 血流麻将自由场
		launch = "normal_mjxl_freestyle_center_service/normal_mjxl_freestyle_center_service",
		deploy = {normal_mjxl_freestyle_center_service="game"},
	},
	{	-- 听用斗地主自由场
		launch = "tyddz_freestyle_center_service/tyddz_freestyle_center_service",
		deploy = {tyddz_freestyle_center_service="game"},
	},
	{	-- 游戏 盈亏统计 管理
		launch = "game_profit_manager_service/game_profit_manager",
		deploy = {game_profit_manager="game"},
	},
	{	-- 邮件服务
		launch = "email_service/email_service",
		deploy = {email_service="data"},
	},
	{	-- 支付服务
		launch = "pay_service/pay_service",
		deploy = {pay_service="data"},
	},
	{	-- 商城配置中心服务
		launch = "shoping_config_center_service",
		deploy = {shoping_config_center_service="game"},
	},
	{	-- 广播服务
		launch = "broadcast_service/broadcast_service",
		deploy = {broadcast_svr="*"},
	},
	{	-- web 服务
		launch = "websever_service/websever_service",
		deploy = {web_server_service="data"},
	},
	{	-- 广播中心
		launch = "broadcast_center_service/broadcast_center_service",
		deploy = {broadcast_center_service="data"},
	},
	{	-- 荣耀中心
		launch = "glory_center_service",
		deploy = {glory_center_service="game"},
	},
	{	-- 任务中心
		launch = "task_center_service/task_center_service",
		deploy = {task_center_service="game"},
	},
	{	-- 抽奖中心
		launch = "lottery_center_service",
		deploy = {lottery_center_service="game"},
	},
	{	-- 兑换码中心
		launch = "redeem_code_center_service/redeem_code_center_service",
		deploy = {redeem_code_center_service="game"},
	},
	{	-- 自由场活动中心 服务
		launch = "freestyle_activity_center_service/freestyle_activity_center_service",
		deploy = {freestyle_activity_center_service="game"},
	},
	{	-- 服务管理
		launch = "admin_console_service/admin_console_service",
		deploy = {service_console={"game","gate","data"}},
	},
	{	-- 游戏管理
		launch = "game_manager_service/game_manager_service",
		deploy = {game_manager_service="game"},
	},
	{	-- 第三方服务代理，如 短信、分享
		launch = "third_agent_service/third_agent_service",
		deploy = {third_agent_service="data"},
	},
	{	-- 自由场机器人调度器：为排队过久的用户安排陪玩机器人
		launch = "freestyle_robot_observer_service/freestyle_robot_observer_service",
		deploy = {free_bot_ob_service="game"},
	},
	{	-- 聊天室服务
		launch = "chat_service/chat_service",
		deploy = {chat_service="data"},
	},
	{	-- web客户端服务：转发 http 请求
		launch = "webclient_service",
		deploy = {webclient_service="*"},
	},
	{	-- 强化托管服务
		launch = "tuoguan_service/tuoguan_service",
		deploy = {tuoguan_service="game"},
	},
	{	-- 客户端bug记录服务
		launch = "client_bug_log_service/client_bug_log_service",
		deploy = {cbug_log_service="gate"},
	},
	{	-- 系统监控服务
		launch = "monitor_service/monitor_service",
		deploy = {monitor_service="data"},
	},
	{	-- 网关
		launch = "gate_service/gate_service",
		deploy = {gate_service="gate"},
	},
	{	-- z砸金蛋 财神模式  连胜活动活动
		launch = "activity_service/zjd_cs_liansheng_act_service",
		deploy = {zjd_cs_liansheng_act_service="game"},
	},
}

return {

	configs = configs,
	nodes = nodes,
	services = services,
}
