--
-- Created by lyx.
-- User: hare
-- Date: 2018/7/5
-- Time: 15:06
-- 说明：聊天室服务
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

local nodes_stat_data = {}

local service_exited = {}

local function check_deal_count(_datas,_count)
	for _,_c in pairs(_datas) do
		if _c < _count then
			return false
		end
	end
	
	return true
end

local function prepare_all_services()

	-- 创建服务
	local node_created = {}
	for _,_data in ipairs(DATA.nodes) do

		for i=1,service_count do
			skynet.fork(function ()
				skynet.call(_data.addr,"lua","create",true,"node_test_service/node_test_service",PUBLIC.get_srv_id(i,_data.name))
				node_created[_data.name] = (node_created[_data.name] or 0) + 1
				if math.fmod(node_created[_data.name],100) == 0 then
					print("services created:",_data.name,node_created[_data.name])
				end
			end)
		end
	end

	-- 等待完成
	while not check_deal_count(node_created,service_count) do
		skynet.sleep(5)
	end

	print("services finished create:",basefunc.tostring(node_created))

	-- 初始化 所有 服务
	local node_inited = {}
	for _,_data in ipairs(DATA.nodes) do

		for i=1,service_count do
			skynet.fork(function ()
				nodefunc.call(PUBLIC.get_srv_id(i,_data.name),"init_service")
				node_inited[_data.name] = (node_inited[_data.name] or 0) + 1
				if math.fmod(node_inited[_data.name],100) == 0 then
					print("services inited:",_data.name,node_inited[_data.name])
				end
			end)
		end
	end

	-- 等待完成
	while not check_deal_count(node_inited,service_count) do
		skynet.sleep(5)
	end

	print("services finished init:",basefunc.tostring(node_inited))

	-- 定期创建已删除的
	skynet.timeout(100 * 2,function ( ... )
		while true do
			local _create_list = basefunc.deepcopy(service_exited)
			service_exited = {}
			for _id,_node in pairs(_create_list) do
				skynet.fork(function ()
					skynet.sleep(math.random(200))		-- 随机停留 1 秒
					skynet.call(DATA.node_map[_node].addr,"lua","create",true,"node_test_service/node_test_service",_id,true)
				end)
			end

			skynet.sleep(1)
		end
	end)

	-- 调用的统计数据
	skynet.timer(tonumber(skynet.getenv("stat_time_interval")),function ( ... )
		print("========= nodes call stat data ========= ",basefunc.tostring(nodes_stat_data))
	end)

end


-- 汇总节点的统计数据
function CMD.node_stat_data(_node,_data)
	local _sd = nodes_stat_data[_node] or {}
	nodes_stat_data[_node] = _sd

	_sd.max_result_time = math.max(_sd.max_result_time or 0,_data.max_result_time)
	_sd.call_count = math.min(_sd.call_count or 0,_data.call_count)
	_sd.data_error_count = math.max(_sd.data_error_count or 0,_data.data_error_count)
	_sd.call_fail_count = math.max(_sd.call_fail_count or 0,_data.call_fail_count)
	_sd.call_succ_count = math.max(_sd.call_succ_count or 0,_data.call_succ_count)
	_sd.in_call_count = math.max(_sd.in_call_count or 0,_data.in_call_count)
	
end

-- 服务的动态删除、创建 统计数据： id => {{op="exit"/"create"/"call"/"call_ret",time=,node=,addr=,caller_id=,caller_addr=,ret_type=,ret_time=},...}
function CMD.service_op(_id,_data)

	if _id then
		if _data.op == "exit" then
			service_exited[_id] = _data.node
		end
	end

	print(string.format("[%-15s]service op log:%-12s,%-10s,%-5s,call sn %-7s,ret(%-12s,%-7s,%-5s,%-8s,%s)",
		tostring(_data.time),
		tostring(_id),
		_data.op,
		tostring(_data.addr),
		tostring(_data.call_sn),

		tostring(_data.caller_id),
		tostring(_data.ret_sn),
		tostring(_data.caller_addr),
		tostring(_data.ret_type),
		tostring(_data.ret_time)
	))
end

function CMD.start(_service_config)

	test_service = skynet.getcfg("test_service")

	DATA.service_config=_service_config

	math.randomseed(os.time())

	skynet.timeout(1,function ()
		
		PUBLIC.query_node()

		print("query node:",basefunc.tostring(DATA.nodes))

		skynet.timeout(1,prepare_all_services)
	end)
end

-- 启动服务
base.start_service()