--
-- Created by lyx.
-- User: hare
-- Date: 2018/7/5
-- Time: 15:06
-- 说明：测试调用服务
--

local skynet = require "skynet_plus"
local base = require "base"
local nodefunc = require "nodefunc"
local cluster = require "skynet.cluster"
local basefunc = require "basefunc"
require "node_test_service.node_test_func"

require "printfunc"

local my_node_name = skynet.getenv("my_node_name")
local service_count = skynet.getenv("service_count")

local test_service

local DATA = base.DATA
local PUBLIC = base.PUBLIC
local CMD = base.CMD

local _init_stat_data = 
{
	max_result_time = 0,
	call_count = 0,
	data_error_count = 0,
	call_fail_count = 0,
	call_succ_count = 0,
	in_call_count = 0,		-- 被调用次数
}

local last_ret_sn = 0
local function gen_call_sn()
	last_ret_sn = last_ret_sn + 1
	return last_ret_sn
end

local stat_data = basefunc.deepcopy(_init_stat_data)

function CMD.get_my_info(_src_id,_sn,_src_addr)

	stat_data.in_call_count = stat_data.in_call_count + 1
	local _ret_sn = gen_call_sn()

	if test_service[DATA.my_id] then
		skynet.send(DATA.service_config.main_service,"lua","service_op",DATA.my_id,{
						op="call",
						time=os.clock(),
						node=my_node_name,
						caller_id=_src_id,
						caller_addr=_src_addr,
						call_sn=_sn,
						ret_sn=_ret_sn,
						addr=skynet.self(),
			})
	end

	return _sn,_ret_sn,DATA.my_id,skynet.self(),my_node_name
end

-- 上次调用地址记录
local _service_addr = {}

local last_call_sn = 0
local function gen_call_sn()
	last_call_sn = last_call_sn + 1
	return last_call_sn
end

function PUBLIC.call_services()

	while true do

		for i=1,1 do

			local _id = PUBLIC.get_srv_id(math.random(service_count),DATA.nodes[math.random(#DATA.nodes)].name)

			local _t1 = os.clock()
			local call_sn = gen_call_sn()
			local call_sn2,ret_sn,_ret_id,_addr,_node = nodefunc.call(_id,"get_my_info",DATA.my_id,call_sn,skynet.self())
			local _ret_time = os.clock() - _t1

			local ret_type = "normal"
			if call_sn2 == "CALL_FAIL" then
				stat_data.call_fail_count = stat_data.call_fail_count + 1
				ret_type = "CALL_FAIL"
			else
				stat_data.max_result_time = math.max(stat_data.max_result_time,_ret_time)
				stat_data.call_count = stat_data.call_count + 1

				if call_sn ~= call_sn2 or _ret_id ~= _id then
					stat_data.data_error_count = stat_data.data_error_count + 1
					ret_type = "data_error"
				else
					stat_data.call_succ_count = stat_data.call_succ_count + 1
					
					if _service_addr[_id] and _addr ~= _service_addr[_id] then
						ret_type = "addr_changed"
						print("service addr changed:",_id,_service_addr[_id],_addr)
					end
				end

			end

			if test_service[_id] then
				skynet.send(DATA.service_config.main_service,"lua","service_op",_id,{
								op="call_ret",
								time=os.clock(),
								node=_node,
								caller_id=DATA.my_id,
								caller_addr=skynet.self(),
								call_sn=call_sn,
								addr=_addr,
								ret_sn=ret_sn,
								ret_type=ret_type,
								ret_time=_ret_time,
					})
			end
		end

		skynet.sleep(10)
	end
	
end

function CMD.destory_self()

	if DATA.destrying then return end
	DATA.destrying = true

	skynet.send(DATA.service_config.main_service,"lua","service_op",DATA.my_id,{
					op="exit",
					time=os.clock(),
					node=my_node_name,
					addr=skynet.self(),
		})

	nodefunc.destroy(DATA.my_id)

	skynet.sleep(1)
	skynet.exit()
end

-- 所有服务都创建完成时调用
function CMD.init_service()

	-- 先查询出节点
	PUBLIC.query_node()

	skynet.fork(function ()
		PUBLIC.call_services()
	end)

	-- 发送统计数据到 main service
	skynet.timer(tonumber(skynet.getenv("stat_time_interval")),function ()

		skynet.send(DATA.service_config.main_service,"lua","node_stat_data",my_node_name,stat_data)

		stat_data = basefunc.deepcopy(_init_stat_data)
	end)

	-- 10 秒内随机删除自己
	if test_service[DATA.my_id] then
		skynet.timeout(math.random(10) * 100,CMD.destory_self)
	end
end

function CMD.start(_my_id,_service_config,_recreate)

	test_service = skynet.getcfg("test_service")

	DATA.service_config=_service_config
	DATA.my_id = _my_id

	-- 重新创建
	if _recreate then
		skynet.send(DATA.service_config.main_service,"lua","service_op",_my_id,{
						op="create",
						time=os.clock(),
						node=my_node_name,
						addr=skynet.self(),
			})

		-- 20 秒内随机删除自己
		skynet.timeout(math.random(10) * 100,CMD.destory_self)
	end

	math.randomseed(os.time())
end

-- 启动服务
base.start_service()