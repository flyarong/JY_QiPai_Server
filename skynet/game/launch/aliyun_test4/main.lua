--
-- 作者: lyx
-- Date: 2018/3/10
-- Time: 14:48
-- 启动文件
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"

skynet.start(function()

	cluster.open(skynet.getenv "my_node_name")

	skynet.uniqueservice("node_service")

	skynet.exit()
end)
