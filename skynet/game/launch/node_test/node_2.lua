include "../common/config"
cluster = "./game/launch/" .. _dir_names[1] .. "/clustername.lua"

start = _dir_names[1] .. "/main"	-- main script

logger = "./logs/node_test_node_2.log"
daemon = "./logs/node_test_node_2.pid"

debug_file = "./debug_node_test_node_2.log"
debug_file_size = 100	-- 日志文件大小（单位：MB）：超过此大小即分文件

my_node_name="node_2"

thread = 10

strict_transfer=1
