include "../common/config"

harbor = 0

luaservice = luaservice .. "./test/?.lua;"

cluster = "./game/launch/" .. _dir_names[1] .. "/clustername.lua"

start = _dir_names[1] .. "/single_main"	-- main script

logger = "./logs/lyx_test_203.log"
daemon = "./logs/lyx_test_203.pid"

debug_file = "./debug_lyx_test_203.log"
debug_file_size = 10	-- 日志文件大小（单位：MB）：超过此大小即分文件

start = _dir_names[1] .. "/single_main"	-- main script

my_node_name="node_1"

strict_transfer=1

robot_type_1 = "robot_normal"
robot_count_1 = 0

robot_type_2 = "robot_freestyle"
robot_count_2 = 0

robot_type_3 = "robot_lzfreestyle"
robot_count_3 = 0

robot_type_4 = "robot_majiang_freestyle"
robot_count_4 = 0

robot_type_5 = "robot_million"
robot_count_5 = 0

robot_type_6 = "robot_mjxl_freestyle"
robot_count_6 = 0

-- 机器人列表的文件名：放在 config 中的 lua 文件，必须配置
robot_file = "robot_list"

-- 网关配置
gate_port = 5001		-- 监听端口
gate_maxclient = 5000	-- 同时在线
max_request_rate = 100	-- 每个客户端 5 秒内最大的请求数

-- 支付测试：为 true 则表示支付行为在测试环境
is_pay_test = true

-- 商城服务器
--shoping_server = "http://mall-webapp-user.jyhd919.cn"
shoping_server = "http://jy-mall-webapp-user.ngrok.wd310.com"

-- 充值服务器
payment_server = "http://test-es-caller.jyhd919.cn"
--payment_server = "http://jy-es-caller.ngrok.wd310.com"

-- 商城接口 url
shoping_url = shoping_server .. "/#/?token=@token@"

-- 支付接口的 url
payment_url = payment_server .. "/Pay.apply.do?order_id=@order_id@"

-- 提现接口 url
withdraw_url = payment_server .. "/Withdraw.apply.do?withdrawId=@withdrawId@"

-- 分享 url
get_share_url = payment_server .. "/MpWeixinPublic.generateUserRecommendQrCode.do?userId=@userId@"

-- 发送短信 url
send_phone_sms_url = payment_server .. "/Sms.send.do"
signName_bind_phone = "竟娱互动"
templateCode_bind_phone = "SMS_136171608"

-- 商城 token 的超时时间（秒）
shop_token_timeout = 180

-- skynet 调试控制台端口
debug_console_port = 8000

-- 管理控制台端口：管理服务状态、关机
admin_console_port = 7001
--web
webserver_port = 8001
webserver_agent_num = 1
webserver_disable_cache = true
-- 数据服务配置
mysql_host = "192.168.0.203"
mysql_dbname = "jygame"
mysql_port = 23456
mysql_user = "jy"
mysql_pwd = "123456"
