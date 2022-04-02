include "../common/config"
cluster = "./game/launch/" .. _dir_names[1] .. "/clustername.lua"

start = _dir_names[1] .. "/main"	-- main script

-- logger = "./logs/lan_test1_game.log"
-- daemon = "./logs/lan_test1_game.pid"

debug_file = "./debug_lan_test1_game.log"
debug_file_size = 100	-- 日志文件大小（单位：MB）：超过此大小即分文件

my_node_name="game"

thread = 8

strict_transfer=1

block_connect_ip_1 = "192.168.0.103"
block_connect_port_1 = 6014
