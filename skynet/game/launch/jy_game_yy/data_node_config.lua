include "../common/config"

harbor = 0
cluster = "./game/launch/" .. _dir_names[1] .. "/clustername.lua"
start = _dir_names[1] .. "/data_node_main"	-- main script

my_node_name="data_node" --see clustername.lua

strict_transfer=1

-- 数据服务配置
mysql_host = "192.168.0.203"
mysql_dbname = "yy_test"
mysql_port = 23456
mysql_user = "jy"
mysql_pwd = "123456"

