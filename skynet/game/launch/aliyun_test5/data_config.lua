include "../common/config"
cluster = "./game/launch/" .. _dir_names[1] .. "/clustername.lua"

start = _dir_names[1] .. "/main"	-- main script

logger = "./logs/aliyun_test5_data.log"
daemon = "./logs/aliyun_test5_data.pid"

debug_file = "./debug_aliyun_test5_data.log"
debug_file_size = 100	-- 日志文件大小（单位：MB）：超过此大小即分文件

my_node_name="data"

strict_transfer=1

thread = 8
