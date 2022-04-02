--
-- Author: lyx
-- Date: 2018/4/26
-- Time: 17:34
-- 说明：服务管理功能函数
--

local skynet = require "skynet_plus"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local base=require "base"

local cjson = require "cjson"
cjson.encode_sparse_array(true,1,0)

local cluster = require "skynet.cluster"


local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

-- 等待传入的数据表 _datas  中所有数据都满足条件才返回
function PUBLIC.wait_data_table(_datas,_time_out,_cb_ok)
	local _time1 = os.time()
	local _done = false
	while not _done and os.time()-_time1 < (_time_out or 5) do
		skynet.sleep(10)
		_done = true
		for _k,_v in pairs(_datas) do
			if not _cb_ok(_k,_v) then
				_done = false
				break
			end
		end
	end
end

-- 得到服务
function CMD.get_servcies(_node_name,_exited)

	local _out_sers = {}
	local _services = skynet.call(DATA.service_config.center_service,"lua","gather_services")

	for _,_service in ipairs(_services) do
		if (not _node_name or _node_name == _service.node_name) and (_exited or _service.arg)  then

			_out_sers[#_out_sers + 1] = _service
		end
	end	

	return _out_sers
end

-- 得到给定服务状态
-- _node_name 节点名 或 服务列表
-- timeout ： 单位 秒
function CMD.get_status(_node_name,_time_out)

	local _local_leave = false

	local _services = CMD.get_servcies(_node_name)

	for _,_service in pairs(_services) do
		_service.status_return = false -- 状态调用是否已经返回
	end

	for _,_service in pairs(_services) do


		skynet.fork(function()

			local ok,status,info = pcall(cluster.call,_service.node_name,_service.addr,"get_service_status")

			if _local_leave then return end

			_service.status_return = true

			if ok then 
				_service.status = status
				_service.info = info or ""
			else
				_service.status = "error"
				_service.info = status
			end

		end)

	end

	-- 等待
	PUBLIC.wait_data_table(_services,_time_out or 5,function(_,v) 
		return v.status_return
	end)
	
	_local_leave = true

	return _services
end

-- 检查能否关机： 全都是 stop 即可关机
function CMD.can_shutdown(_node_name,_time_out)
	local _services = CMD.get_status(_node_name,_time_out)

	for _,_service in ipairs(_services) do
		if "stop" ~= _service.status and "free" ~= _service.status then
			return false
		end
	end

	return true
end

-- 执行关机
-- 返回已经关机的节点表
local function do_shutdown(_node_name)

	local _nodes = {}

	local _nodes = skynet.call(DATA.service_config.center_service,"lua","get_node_list")
	local _self_node_name = skynet.getenv("my_node_name")
	for _name,_data in pairs(_nodes) do

		-- 自己留到最后关闭
		if (not _node_name or _name == _node_name) and _name ~= _self_node_name then
			_nodes[#_nodes + 1] = _name
			cluster.send(_data.node_name,_data.node,"exit")
		end
	end

	if not _node_name or _self_node_name == _node_name then

		_nodes[#_nodes + 1] = _node_name

		-- 自己等下再关，以便执行完返回逻辑
		skynet.timeout(50,function() 
			skynet.send("node_service","lua","exit")
		end)
	end

	return _nodes
end

-- 发送停止服务指令
-- 参数 _time_out ： 等待状态返回的时间
function PUBLIC.stop_services(_node_name,_time_out)

	local _local_leave = false

	local _services = CMD.get_servcies(_node_name)

	local _out_sers = {}
	for _,_service in pairs(_services) do
		skynet.fork(function()

			_out_sers[#_out_sers + 1] = _service

			local ok,status,info = pcall(cluster.call,_service.node_name,_service.addr,"stop_service")
			if _local_leave then return end
			if ok then 
				_service.status = status
				_service.info = info or ""
			else
				_service.status = "error"
				_service.info = status
			end
		end)
	end

	-- 最多等 3 秒
	PUBLIC.wait_data_table(_out_sers,_time_out or 5,function(k,v) 
		return v.status
	end)

	_local_leave = true
	return _out_sers
end


-- 关机
-- timeout ： 单位 秒；
-- _force ： 给定时间内强制关机，否则仅在服务正确停止后才关机；
-- 返回值：
--	true/false: 是否执行关机 
--  nodes : 已经关机的 节点 列表/服务列表及其状态
function CMD.shutdown(_node_name,_force,_time_out)

	if _force then
		return do_shutdown(_node_name)
	end

	PUBLIC.stop_services(_node_name)

	local _time1 = os.time()
	while not CMD.can_shutdown(_node_name) do 

		skynet.sleep(1)

		if os.time() - _time1 >= (_time_out or 5) then
			if _force then
				return true,do_shutdown(_node_name)
			else
				return false,CMD.get_status(_node_name)
			end
		end
	end

	return true,do_shutdown(_node_name)
end

--[[ 
	供 http 方式调用任意服务（供 web 接口调用）
	{
		service_name=, 	-- 服务名字
		cmd_name=,		-- 命令名字
		params = {}, 	-- 参数，数组
	}
--]]
function CMD.http_call_service(_data_json)

	local ok,data = xpcall(cjson.decode,basefunc.error_handle,_data_json)
	if not ok then
		return data
	end
	
	if data.params then
		return skynet.call(DATA.service_config[data.service_name],"lua",data.cmd_name,table.unpack(data.params))
	else
		return skynet.call(DATA.service_config[data.service_name],"lua",data.cmd_name)
	end
end
function CMD.http_str_call_service(_data_json)
	return CMD.http_call_service(_data_json)
end


--[[ 
	供 http 方式调用任意 id（供 web 接口调用）
	{
		service_id=, 	-- id
		cmd_name=,		-- 命令名字
		params = {}, 	-- 参数，数组
	}
--]]
function CMD.http_call_id(_data_json)

	local ok,data = xpcall(cjson.decode,basefunc.error_handle,_data_json)
	if not ok then
		return data
	end
	
	if data.params then
		return nodefunc.call(data.service_id,data.cmd_name,table.unpack(data.params))
	else
		return nodefunc.call(data.service_id,data.cmd_name)
	end
end
function CMD.http_str_call_id(_data_json)
	return CMD.http_call_id(_data_json)
end


--[[ 
	供 http 方式调用任意 console 命令（供 web 接口调用）
	{
		cmd_name=,		-- 命令名字
		params = {}, 	-- 参数，数组
	}
--]]
function CMD.http_console_cmd(_data_json)

	local console_session = require "admin_console_service.console_session"

	local ok,data = xpcall(cjson.decode,basefunc.error_handle,_data_json)
	if not ok then
		return data
	end
	
	local _ret = {}

	local function _echo(...)
		local t = table.pack(...)
		for i=1,t.n do
			t[i] = tostring(t[i])
		end

		_ret[#_ret + 1] = table.concat(t,"  ")
	end

	local cs = console_session.new(_echo)

	cs.cmd_index = cs.cmd_index + 1
	cs.cmd_running = true
	local ok,msg 
	if data.params then
		ok,msg = pcall(cs.dispatch_command,cs,data.cmd_name,table.unpack(data.params))
	else
		ok,msg = pcall(cs.dispatch_command,cs,data.cmd_name)
	end

	if not ok then
		_echo(msg)
	end
	cs.cmd_running = false

	return _ret
end