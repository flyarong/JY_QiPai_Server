include "../common/config"

harbor = 1
standalone = "127.0.0.1:4101"
master = "127.0.0.1:4101"
address = "127.0.0.1:4201"

luaservice = luaservice .. "./test/?.lua;"

cluster = "./game/launch/" .. _dir_names[1] .. "/clustername.lua"

start = _dir_names[1] .. "/single_main"	-- main script

--daemon = "./gate.pid"

debug_file = "./jy_game_yy.log"
debug_file_size = 10	-- 日志文件大小（单位：MB）：超过此大小即分文件

my_node_name="single_node"

strict_transfer=1

-- 网关配置
gate_port = 5001		-- 监听端口
gate_maxclient = 5000	-- 同时在线
max_request_rate = 100	-- 每个客户端 5 秒内最大的请求数

-- 数据服务配置
mysql_host = "192.168.0.203"
mysql_dbname = "yy_test"
mysql_port = 23456
mysql_user = "jy"
mysql_pwd = "123456"
