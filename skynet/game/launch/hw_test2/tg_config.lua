include "../common/config"
cluster = "./game/launch/" .. _dir_names[1] .. "/clustername.lua"

start = _dir_names[1] .. "/tg_main"	-- main script

-- logger = "./logs/hw_test2_tg.log"
-- daemon = "./logs/hw_test2_tg.pid"

debug_file = "./debug_hw_test2_tg.log"
debug_file_size = 100	-- 日志文件大小（单位：MB）：超过此大小即分文件

my_node_name="tg"

thread = 2

strict_transfer=0

resource = 500000

block_connect_ip_1 = "192.168.0.103"
block_connect_port_1 = 4104
