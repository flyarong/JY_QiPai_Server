-- Author: hw
-- Date: 2018/3/19
-- Time: 15:13
-- 说明：测试代理管理服务
local skynet = require "skynet_plus"
require "skynet.manager"
local base = require "base"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local agent_count=10000

local node_service

local test_count=0
local last_time
local agent_node={}
function CMD.get_count()
	test_count=test_count+1
	if test_count==agent_count*60*5 then 
		local cur_time=os.time()
		print("cost time:  ",cur_time-last_time)
		last_time=cur_time
		test_count=0
	end 
	return agent_count
end

function CMD.start(config)
	node_service=config.node_service
	last_time=os.time()
	for i=1,agent_count do 
		local id="agent"..i
		skynet.call(node_service,"lua","create",nil,"test_agent",id)
		local nodeID=skynet.call(node_service,"lua","create",id)
		assert(nodeID)
		agent_node[nodeID]=agent_node[nodeID] or {}
		agent_node[nodeID][#agent_node[nodeID]+1]=id
	end

	print("测试代理管理服务 start")
	local flag=true
	while flag do
		local a={}
		for k,v in pairs(agent_node) do
			a[#a+1]=v[#v]
			v[#v]=nil
			if #v==0 then
				flag=false
			end
		end
		for i=1,#a do
			if i==#a then
				skynet.call(node_service,"lua","call",a[i],"begin",a[i+1])
			else
				skynet.call(node_service,"lua","call",a[i],"begin",a[1])
			end
		end
	end

end

-- 启动服务
base.start_service(nil,"tam_ser")



