include "../common/config"
cluster = "./game/launch/" .. _dir_names[1] .. "/clustername.lua"

start = _dir_names[1] .. "/main"	-- main script

logger = "./logs/yy_mulit_test_game.log"
daemon = "./logs/yy_mulit_test_game.pid"

debug_file = "./debug_yy_mulit_test_game.log"
debug_file_size = 100	-- 日志文件大小（单位：MB）：超过此大小即分文件

my_node_name="game"

thread = 8

strict_transfer=1
