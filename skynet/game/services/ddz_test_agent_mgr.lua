-- Author: hw
-- Date: 2018/3/19
-- Time: 15:13
-- 说明：测试代理管理服务
local skynet = require "skynet_plus"
require "skynet.manager"

local base = require "base"

local CMD=base.CMD

local agent_count=10

local node_service

local test_count=0
function CMD.get_count()
	test_count=test_count+1
	if test_count==agent_count then 
		print("tam:  ",os.time())
		test_count=0
	end 
	return agent_count
end

function CMD.start(config)
	node_service=config.node_service
	for i=1,agent_count do
		skynet.call(node_service,"lua","create",nil,"player_agent/player_agent","robot"..i)
	end
	print("测试ddz代理管理服务 start")
end


-- 启动服务
base.start_service(nil,"tam_ser")



