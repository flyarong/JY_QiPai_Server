include "../common/config"
cluster = "./game/launch/" .. _dir_names[1] .. "/clustername.lua"

start = _dir_names[1] .. "/main"	-- main script

logger = "./logs/aliyun_release_game.log"
daemon = "./logs/aliyun_release_game.pid"

debug_file = "./debug_aliyun_release_game.log"

my_node_name="game"

thread = 8

strict_transfer=1

block_connect_ip_1 = "172.18.107.238"
block_connect_port_1 = 4704
