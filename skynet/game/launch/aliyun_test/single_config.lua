include "../common/config"

harbor = 0

luaservice = luaservice .. "./test/?.lua;"

cluster = "./game/launch/" .. _dir_names[1] .. "/clustername.lua"

is_real_linux = 1

start = _dir_names[1] .. "/single_main"	-- main script

logger = "./aliyun_single.log"
daemon = "./aliyun_single.pid"

debug_file = "./debug_aliyun_test.log"
debug_file_size = 100	-- 日志文件大小（单位：MB）：超过此大小即分文件

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

robot_type_7 = "robot_tyfreestyle"
robot_count_7 = 0
-- 机器人列表的文件名：放在 config 中的 lua 文件；如果不配置，则随机产生
robot_file = "robot_list"

-- 网关配置
gate_port = 5001		-- 监听端口
gate_maxclient = 5000	-- 同时在线
max_request_rate = 100	-- 每个客户端 5 秒内最大的请求数

-- 商城服务器
shoping_server = "http://mall-webapp-user.jyhd919.cn"

-- 充值服务器
payment_server = "http://test-es-caller.jyhd919.cn"

-- 商城接口 url
shoping_url = shoping_server .. "/#/?token=@token@"

-- 支付接口的 url
payment_url = payment_server .. "/Pay.apply.do?order_id=@order_id@"

-- 提现接口 url
withdraw_url = payment_server .. "/Withdraw.apply.do?withdrawId=@withdrawId@"

-- 发送短信 url
send_phone_sms_url = payment_server .. "/Sms.send.do"
signName_bind_phone = "竟娱互动"
templateCode_bind_phone = "SMS_136161517"


-- 商城 token 的超时时间（秒）
shop_token_timeout = 180

--web
webserver_port = 8001
webserver_agent_num = 20

-- 数据服务配置
mysql_host = "127.0.0.1"
mysql_dbname = "jygame"
mysql_port = 3306
mysql_user = "root"
mysql_pwd = "jY123"
