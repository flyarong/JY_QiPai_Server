--
-- 作者: lyx
-- Date: 2018/3/10
-- Time: 14:48
-- 启动文件
--

local skynet = require "skynet_plus"

skynet.start(function()
	local stest = skynet.uniqueservice("stest_service")
	skynet.send(stest,"lua","start")
	skynet.exit()
end)
