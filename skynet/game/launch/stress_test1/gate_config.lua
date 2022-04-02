include "../common/config"
cluster = "./game/launch/" .. _dir_names[1] .. "/clustername.lua"

start = _dir_names[1] .. "/main"	-- main script

logger = "./logs/stress_test1_gate.log"
daemon = "./logs/stress_test1_gate.pid"

debug_file = "./debug_stress_test1_gate.log"
debug_file_size = 100	-- 日志文件大小（单位：MB）：超过此大小即分文件

my_node_name="gate"

thread = 10

strict_transfer=1
