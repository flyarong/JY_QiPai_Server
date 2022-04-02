--
-- Author: hw
-- Date: 2018/3/19
-- Time: 15:13
-- 说明：测试代理
local skynet = require "skynet_plus"
require "skynet.manager"

local base = require "base"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local test_agent_manager
local node_service

local my_id

local value=1
local other_value={}
function CMD.test(id,value)
	local k=0
	for i=0, 200 do
		k=k+i
	end
	other_value[id]=other_value[id] or 0
	if value~=other_value[id]+1 then
		print(id.."   error!!!")
	end
	other_value[id]=value
	return k
end
function CMD.begin(_id)
	skynet.fork(function ()
		while true do
			skynet.sleep(20)
			local count=skynet.call(test_agent_manager,"lua","get_count")
			skynet.call(node_service,"lua","call",_id,"test",my_id,value)
			value=value+1
		end
		-- body
	end)
end
function CMD.start(id,config)
	test_agent_manager=config.test_agent_manager
	node_service=config.node_service
	my_id=id

	return 0
end

-- 启动服务
base.start_service()
