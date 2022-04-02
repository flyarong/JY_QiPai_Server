include "../common/config"
cluster = "./game/launch/" .. _dir_names[1] .. "/clustername.lua"

start = _dir_names[1] .. "/main"	-- main script

logger = "./logs/aliyun_release_data.log"
daemon = "./logs/aliyun_release_data.pid"

debug_file = "./debug_aliyun_release_data.log"

my_node_name="data"

strict_transfer=1

thread = 4

-- 注意：配置了此项，即为中心服务器，集群中仅允许一个中心服务器！
center = "./game/launch/" .. _dir_names[1] .. "/center"

block_connect_ip_1 = "172.18.107.238"
block_connect_port_1 = 4704
