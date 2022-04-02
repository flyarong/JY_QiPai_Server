include "../common/config"
cluster = "./game/launch/" .. _dir_names[1] .. "/clustername.lua"

start = _dir_names[1] .. "/main"	-- main script

logger = "./logs/yy_mulit_test_tg.log"
daemon = "./logs/yy_mulit_test_tg.pid"

debug_file = "./debug_yy_mulit_test_tg.log"
debug_file_size = 100	-- 日志文件大小（单位：MB）：超过此大小即分文件

my_node_name="tg"

thread = 1

strict_transfer=0
