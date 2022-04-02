include "../common/config"
cluster = "./game/launch/" .. _dir_names[1] .. "/clustername.lua"

start = _dir_names[1] .. "/main"	-- main script

logger = "./logs/aliyun_release_gate.log"
daemon = "./logs/aliyun_release_gate.pid"

debug_file = "./debug_aliyun_release_gate.log"

my_node_name="gate"

thread = 8

strict_transfer=0

block_connect_ip_1 = "172.18.107.238"
block_connect_port_1 = 4704
