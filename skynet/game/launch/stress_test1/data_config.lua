include "../common/config"
cluster = "./game/launch/" .. _dir_names[1] .. "/clustername.lua"

start = _dir_names[1] .. "/main"	-- main script
logger = "./logs/stress_test1_data.log"
daemon = "./logs/stress_test1_data.pid"

debug_file = "./debug_stress_test1_data.log"
debug_file_size = 100	-- 日志文件大小（单位：MB）：超过此大小即分文件

my_node_name="data"

thread = 2

strict_transfer=1

-- 注意：配置了此项，即为中心服务器，集群中仅允许一个中心服务器！
center = "./game/launch/" .. _dir_names[1] .. "/center"
