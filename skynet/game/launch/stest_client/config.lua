include "../common/config"

start = _dir_names[1] .. "/main"	-- main script

--logger = "./logs/stest.log"
--daemon = "./logs/stest.pid"

debug_file = "./debug_stest.log"
debug_file_size = 100	-- 日志文件大小（单位：MB）：超过此大小即分文件

thread = 8
