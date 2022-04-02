--
-- Author: hw
-- Date: 2018/3/10
-- Time: 15:13
-- 说明：节点服务管理器

local skynet = require "skynet_plus"
require "skynet.manager"
local cluster = require "skynet.cluster"
require "printfunc"

local sharedata = require "skynet.sharedata"

local basefunc = require "basefunc"

-- 节点共享数据
local node_share = 
{
	-- 集群中的节点集合： node name => true
	nodes = {},

	-- 本节点的共享配置表（替代 skynet.getenv）
	node_configs = {},
}


local clusterd

local CMD = {}

--当前服务器剩余资源，当资源不足时就会向其他服务器请求资源
local resource=0
--by lyx:可分配的资源类型集合： restype => true
local allow_res_types = nil -- nil 表示未限制
--
--本地的服务或地址 key=id value=addr
local local_service={}
--本地服务的信息（如：类型，占用资源量等等）
local local_service_msg={}
--代理或服务所在的node key=id value=nodeName
local service_to_nodeName = {}
local service_to_addr = {}
local service_type=	require "service_type"
local my_id=nil
local node_name=skynet.getenv "my_node_name"

local SYSTEM={}
local service_config

local node_is_joined = false
local start_ok = false

local node_ready = false

local function refresh_is_ready()
	node_ready = node_is_joined and start_ok
end

local function query_service_node(id)
	local _node_name,addr= skynet.call(service_config.center_service, "lua","query_service_node",id)
	if _node_name then
		service_to_nodeName[id]=_node_name
		service_to_addr[id]=addr
	end
	return service_to_nodeName[id]
end
function CMD.query(id)
	if local_service[id] then
		return true
	else
		return false
	end
end
--hewei 4.25 test
function CMD.query_service_node(id)
	return skynet.call(service_config.center_service, "lua","query_service_node",id)
end

function CMD.create(is_must,type,id,...)

	-- 没准备好
	if not node_ready then
		return false,1002
	end

	if service_type[type] then 
		-- ###_test 目前的资源调配限制只是暂时的
		if (is_must or (not allow_res_types or allow_res_types[type])
			and resource-service_type[type].resource>=resource*0.2)
			and (not service_type[type].node_name or service_type[type].node_name==node_name) then
			
			if local_service[id] then
				print("error create local_service id is exist !!",id)
				return false,1066 
			end
			-- lock id
			local lock_status=skynet.call(service_config.center_service, "lua","lock_service_id",id)
			if not lock_status then
				print("error create lock id fail !!",id)
				--锁定失败
				return false,1067 
			end


			resource=resource-service_type[type].resource
			local _ser=skynet.newservice(type)
			print("node service created:",node_name,type,_ser,...)
			local_service[id]=_ser
			local_service_msg[id]=type
			local status,_ser_ret=pcall(skynet.call,_ser, "lua","start",id,service_config,...)
			if not status then
				print("error create call start fail!!")
			end
			skynet.call(service_config.center_service, "lua","set_service_to_nodeID",id,node_name,_ser,-service_type[type].resource)
			return true,_ser_ret
		else

			-- by lyx
			-- local _node_name=skynet.call(service_config.center_service, "lua","get_res",type)
			local _node_name= service_type[type].node_name or skynet.call(service_config.center_service, "lua","get_res",type)
			if _node_name then
				if _node_name==node_name then
					return  CMD.create(true,type,id,...)
				elseif service_to_nodeName[_node_name] or query_service_node(_node_name) then
					local status,s1,s2=pcall(cluster.call,_node_name,service_to_addr[_node_name],"create",true,type,id,...)
					if status then
						return s1,s2
					end
					return false,1000
				end
			end
			return false,1007
		end
	end

	return false,1006
end

function CMD.destroy(id)
	if local_service[id] then
		local_service[id]=nil
		resource=resource+service_type[local_service_msg[id]].resource
		skynet.call(service_config.center_service, "lua","clear_service_to_nodeID",id,node_name,service_type[local_service_msg[id]].resource)
		local_service_msg[id]=nil
		return 0
	else
		local _node_name=service_to_nodeName[id] or query_service_node(id)
		if _node_name then
			local _node_service=service_to_addr[_node_name]
			local status,s1=pcall(cluster.call,_node_name, _node_service,"destroy",id)
			if status then
				return s1
			end
			return 1000
		else
			return 1
		end
	end 
end

-- by lyx 根据地址 destroy
-- 说明：此函数 仅在关机时使用，故不考虑性能
function CMD.destroy_byaddr( _addr)

	if _addr == skynet.self() then
		return
	end

	for _id,_address in pairs(local_service) do
		if _address == _addr then
			--print("CMD.destroy_byaddr succ : ",string.format(":%08x",_addr),_id)
			CMD.destroy(_id)
			return
		end
	end

	--print("CMD.destroy_byaddr : " ,string.format(":%08x",skynet.self()))
	--dump(local_service,"destroy_byaddr : " .. string.format(":%08x",_addr))
end

function CMD.sync(_node_change_list)

	for _,_data in ipairs(_node_change_list) do

		-- op=1 表示 设置， op=2 表示清除
		if _data.op == 1 then
			service_to_nodeName[_data.id]=_data.node
			service_to_addr[_data.id]=_data.addr
		else
			service_to_nodeName[_data.id]=nil
			service_to_addr[_data.id]=nil
		end
	end

end

function CMD.add_node(_node_name,_node_service_addr,_node_service_id)
	service_to_nodeName[_node_name]=_node_name
	service_to_addr[_node_name]=_node_service_addr

	service_to_nodeName[_node_service_id]=_node_name
	service_to_addr[_node_service_id]=_node_service_addr
	return 0
end

--[[ 收集本节点的服务 (by lyx 2018-4-27)
（此命令供管理控制台 即时获取服务信息 使用）
注意，只收集以下两类服务：
	1、通过 node_service 创建的服务
	2、配置 service_config 中的服务地址（不包括通过 cluster.proxy 得到的服务地址）
返回数组，每项内容：
	id 		服务的唯一 id ，如果是 main 配置文件手工创建，则为名字
	res		服务所需消耗的资源，如果不是 node_service 创建的，则为 nil
	addr	服务的本地地址
	arg		服务的启动参数
--]]
function CMD.gather_services()
	local ret_data = {}

	-- 先得到所有服务信息
	local _svr2arg = {}
	local _list = skynet.call(".launcher", "lua", "LIST")
	if _list then
		for _addr,_arg in pairs(_list) do
			_svr2arg[_addr] = _arg
		end
	end

	-- 得到 node_service 创建的服务
	for _id,_addr in pairs(local_service) do
		ret_data[#ret_data + 1] = {
			id = _id,
			addr = _addr,
			res = service_type[local_service_msg[_id]].resource,
			arg = _svr2arg[skynet.address(_addr)],
		}
	end


	-- 得到手工启动的服务
	for _name,_addr in pairs(service_config) do
		if _addr ~= skynet.self() then
			local _arg = _svr2arg[skynet.address(_addr)]

			-- 过滤掉代理服务
			if _arg then
				if not string.find(_arg,"clusterproxy") then
					ret_data[#ret_data + 1] = {
						id = _name,
						addr = _addr,
						arg = _arg,
					}
				end
			else
				ret_data[#ret_data + 1] = {
					id = _name,
					addr = _addr, 
					arg = nil,
				}
			end
		end
	end


	return ret_data
end

-- 退出进程 by lyx
function CMD.exit()
	os.exit()
end

local function init_node()
	--请求node列表
	skynet.call(service_config.center_service, "lua","add_node",node_name,skynet.self(),my_id,resource)
	local node_list=skynet.call(service_config.center_service, "lua","get_node_list")
	for _node_name,_data in pairs(node_list) do
		if _node_name~=node_name then
			--通知其他node
			service_to_nodeName[_node_name]=_data._node_name
			service_to_addr[_node_name]=_data.node_service_addr

			service_to_nodeName[_data.node_service_id]=_data._node_name
			service_to_addr[_data.node_service_id]=_data.node_service_addr

			cluster.call(_node_name, service_to_addr[_node_name],"add_node",node_name,skynet.self(),my_id)
		end	
	end	

end

-- by lyx
function CMD.stop_service()
	return "free"
end
-- by lyx 为接口兼容
function CMD.set_service_name(_service_name)

end


-- by lyx ，加入创建好的服务
-- 参数 _type ： 默认为 system_service
function CMD.append(id,_ser,_type)
	local_service[id]=_ser
	local_service_msg[id]=_type or "system_service"
	skynet.call(service_config.center_service, "lua","set_service_to_nodeID",id,node_name,_ser,0)
end

-- 创建系统服务：不在资源系统的管理中
function CMD.create_system_service(_name,_launch )
	local _addr = skynet.uniqueservice(_launch)
	skynet.call(_addr,"lua","set_service_name",_name)
	return _addr
end

-- 开始系统服务
function CMD.start_system_service(_addr)
	skynet.call(_addr,"lua","start",service_config)
end

-- 节点已加入到中心
function CMD.node_joined(_nodes,_configs)

	for _name,_value in pairs(_configs) do
		if type(_value) ~= "table" then -- 不是表的 配置，设置为 skynet 配置
			skynet.setenv(_name,tostring(_value))
		end
	end

	-- 共享数据
	node_share.nodes = _nodes
	node_share.node_configs = _configs
	sharedata.new("node_share",node_share)

	-- 处理某些参数

	my_id=_configs.id
	resource=_configs.resource or tonumber(skynet.getenv("resource")) or 0
	if _configs.resource_types then
		allow_res_types = {}
		for _,_type in ipairs(_configs.resource_types) do
			allow_res_types[_type] = true
		end
	end

	if not skynet.getenv "daemon" then
		skynet.uniqueservice("console")
	end

	local _dcp = skynet.getenv("debug_console_port")
	if _dcp then
		skynet.newservice("debug_console",tonumber(_dcp))
	end

	node_is_joined = true
	refresh_is_ready()
end

-- 更新配置
function CMD.update_config(_name,_value)
	node_share.node_configs[_name] = _value

	sharedata.update("node_share",node_share)
end

-- 查询配置
function CMD.query_config(_name)
	return node_share.node_configs[_name]
end

-- 更新共享数据
function CMD.update_share(_name,_data)

	node_share[_name] = _data

	sharedata.update("node_share",node_share)
end

-- 参数：
--	_service_config 服务配置：每个服务的地址，传递给其它服务
function CMD.start(_service_config,_my_id)
	if _my_id then
		my_id=_my_id
	end
	clusterd = skynet.uniqueservice("clusterd")

	-- node service 是自己
	service_config = {node_service=skynet.self()}
	for _name,_service in pairs(_service_config) do
		if _service.node == node_name then
			service_config[_name] = _service.addr
		else
			service_config[_name] = cluster.proxy(_service.node, _service.addr)
		end
	end

	init_node()

	start_ok = true
	refresh_is_ready()
end


local _call_err_count = 0

local _last_print_call_err = os.time()

local function call_error_handle(msg)
	_call_err_count = _call_err_count + 1

	-- 10 秒打印一次错误
	if _call_err_count == 1 or os.time() - _last_print_call_err > 10 then
		print(tostring(msg) .. " => error count:" .. tostring(_call_err_count),debug.traceback())
		_last_print_call_err = os.time()
	end
end

local function error_handle(msg)
	print(tostring(msg) .. ":\n" .. tostring(debug.traceback()))
	return msg
end	

--[[
main:
	local _center_service = cluster.query( "center", "center_service" )
	local _center_service_agent = cluster.proxy("center", "center_service")
	local _node_service = skynet.uniqueservice("node_service")
	skynet.call(_node_service, "lua", "start",{
													id=skynet.call(_center_service_agent, "lua", "get_node_id"),
													res=,
													,

													})
--]]

local function call(id,msg,sz)

  if local_service[id] then
    local  _ok,_msg,_sz=xpcall(skynet.rawcall,call_error_handle,local_service[id], "lua",msg,sz)
    if _ok then
	  return _msg,_sz
    end
  else
    local _node_name=service_to_nodeName[id] or query_service_node(id)
    if _node_name then 
      local  _ok,_msg,_sz=xpcall(skynet.rawcall,call_error_handle,clusterd, "lua", skynet.pack("req", _node_name,  service_to_addr[id], msg, sz))
      if _ok then
        return _msg,_sz
      end
    end
  end
  return skynet.pack("CALL_FAIL")
end
skynet.register_protocol {
    name = "call",
    id = skynet.PTYPE_JY_CALL,
    unpack = function (...) return ... end,
}
skynet.register_protocol {
    name = "send",
    id = skynet.PTYPE_JY_SEND,
    unpack = function (...) return ... end,
}
local forward_map = {
  [skynet.PTYPE_JY_CALL] = skynet.PTYPE_JY_CALL,
  [skynet.PTYPE_JY_SEND] = skynet.PTYPE_JY_SEND,
  [skynet.PTYPE_RESPONSE] = skynet.PTYPE_RESPONSE,
}


skynet.start(function()
  skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
      local f = CMD[cmd]
	  if f then
		local ok ,err= xpcall(function(...)
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end,error_handle,...)
		if not ok then
			error(string.format("node cmd '%s' error:%s",tostring(cmd),tostring(err)))
		end
      else
        print(subcmd,...)
        error("not found cmd:"..cmd)
        assert(f)
      end
  end)
  
  -- by lyx : 注册名字，以便本节点内，用此名字调用节点服务
  skynet.register "node_service"
  cluster.register("node_service",skynet.self())

  -- 如果配置为中心，则启动
  local _center_info = skynet.getenv("center")
  if _center_info then

    local _nodes_config = require(_center_info)

    local _center_service = skynet.uniqueservice("center_service")
    skynet.call(_center_service, "lua", "start",_nodes_config,skynet.self())
  end
end)

skynet.forward_type( forward_map ,function()
  skynet.dispatch("call", function (session, source, msg, sz)
    local id =skynet.get_jy_id(msg, sz)
    skynet.ret(call(id,msg,sz))
  end)
  skynet.dispatch("send", function (session, source, msg, sz)
    local id =skynet.get_jy_id(msg, sz)
     if local_service[id] then
        pcall(skynet.rawsend,local_service[id], "lua",msg,sz)
    else
      local _node_name=service_to_nodeName[id] or query_service_node(id)
      if _node_name then 
    	xpcall(skynet.rawsend,call_error_handle,clusterd, "lua", skynet.pack("push", _node_name, service_to_addr[id] , msg, sz))
      end
    end
  end)
end)

