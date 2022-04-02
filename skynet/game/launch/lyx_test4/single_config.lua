include "../common/config"

harbor = 0

luaservice = luaservice .. "./test/?.lua;"

cluster = "./game/launch/" .. _dir_names[1] .. "/clustername.lua"

start = _dir_names[1] .. "/single_main"	-- main script

--logger = "./logs/lyx_test4.log"
--daemon = "./logs/gate.pid"

debug_file = "./debug_lyx_test4.log"
debug_file_size = 10	-- 日志文件大小（单位：MB）：超过此大小即分文件

start = _dir_names[1] .. "/single_main"	-- main script

my_node_name="node_1"

strict_transfer=0

thread = 1

-- 托管服务 放在指定的测试节点上(用于调试环境)
tuoguan_test_node = "node_1"
plyer_agent_node = "node_1"

-- 注意：配置了此项，即为中心服务器，集群中仅允许一个中心服务器！
center = "./game/launch/" .. _dir_names[1] .. "/center"
