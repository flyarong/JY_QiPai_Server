--
-- Author: hw
-- Date: 2018/5/17
-- 说明：广播服务
--[[
	启动说明：
	此服务每个节点都会启动一个,只是作为转发基站

]]

require"printfunc"
local skynet = require "skynet_plus"
require "skynet.manager"
local cluster = require "skynet.cluster"
local mc = require "skynet.multicast.core"
local basefunc = require "basefunc"
local broadcast_config = require "broadcast_config"
local base = require "base"
local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC
local REQUEST=base.REQUEST
local service_config
local PROTECT={}


local node_name=skynet.getenv "my_node_name"
--频道
local broadcast_channel
local listen_count
--1-100为保留频道
local broadcast_channel_no=100
local my_id=node_name.."_bc_1"
local other_node_broadcast={}


local function send_other_broadcast(_func,...)
	for _node_name,_addr in pairs(other_node_broadcast) do
		local _ok,_err=pcall(cluster.send,_node_name,_addr,_func,...)
		if not _ok then
			print("send_other_broadcast error!! node_name: ".._node_name,_err)
		end
	end
end
local function call_other_broadcast(_func,...)
	for _node_name,_addr in pairs(other_node_broadcast) do
		local _ok,_err=pcall(cluster.call,_node_name,_addr,_func,...)
		if not _ok then
			print("call_other_broadcast error!! node_name: ".._node_name,_err)
		end
	end
end
--增加一个频道
function CMD.add_channel(_c_id)
	if not broadcast_channel[_c_id] then
		broadcast_channel[_c_id]={}
		listen_count[_c_id]=0
		return true
	end
	return false
end
--新建一个频道
function CMD.new_channel()
	broadcast_channel_no=broadcast_channel_no+1
	local _c_id=my_id..broadcast_channel_no
	call_other_broadcast("add_channel",_c_id)
	broadcast_channel[_c_id]={}
	listen_count[_c_id]=0
	return _c_id
end
--关闭指定频道
function CMD.delete_channel(_c_id,_other)
	if broadcast_channel[_c_id] then
		broadcast_channel[_c_id]=nil
		if not _other then
			call_other_broadcast("delete_channel",_c_id,true)
		end
		return true
	end
	return false
end
--监听某个频道
function CMD.listen(_c_id,_id,_addr)
	-- print("broadcast  listen!!!************---------",_c_id,_id)
 	if broadcast_channel[_c_id] then
		broadcast_channel[_c_id][_id]=_addr
		listen_count[_c_id]=listen_count[_c_id]+1
		return true
	end
	return false
end
--取消监听某个频道
function CMD.cancel_listen(_c_id,_id)
	if broadcast_channel[_c_id] then
		broadcast_channel[_c_id][_id]=nil
		listen_count[_c_id]=listen_count[_c_id]-1
		return true
	end
	return false
end


--[[ 广播消息 

--是否不发送至其他广播节点
_no_send_other

msg格式
{
	--广播类型 1系统广播 2 其他广播
	type
	--广播消息格式类型 1 纯文本 其他指定格式
	format_type
	--广播来源 暂时保留不实现
	*from
	--内容
	content
}
--]]
function CMD.broadcast(_c_id,_msg,_no_send_other)

	local set=broadcast_channel[_c_id]
	if set and listen_count[_c_id]>0 then
		
		--本地广播格式打包进行广播
		local pack,sz = mc.pack(skynet.pack(_msg))
		local msg = skynet.tostring(pack,sz)
		mc.bind(pack, listen_count[_c_id])

		for _,_addr in pairs(set) do
			skynet.rawsend(_addr,"multicast",msg)
		end

	end

	if not _no_send_other then
		send_other_broadcast("broadcast",_c_id,_msg,true)
	end

end


function CMD.add_other_broadcast(_node_name,_broadcast_service_addr)
	other_node_broadcast[_node_name]=_broadcast_service_addr
	return true
end


function CMD.get_all_channel_id()
	local _channel_id_set={}
	for _id,_ in pairs(broadcast_channel) do
		_channel_id_set[#_channel_id_set+1]=_id
	end
	return _channel_id_set
end




local function init_broadcast()
	
	skynet.call(service_config.center_service, "lua","add_node_broadcast",node_name,skynet.self(),my_id)
	
	--请求node列表
	local _broadcast_list=skynet.call(service_config.center_service, "lua","get_node_broadcast_list")
	for _node_name,_data in pairs(_broadcast_list) do
		if _node_name~=node_name then
			other_node_broadcast[_node_name]=_data.addr
			--通知其他node
			cluster.call(_node_name,other_node_broadcast[_node_name],
							"add_other_broadcast",node_name,skynet.self())
		end	
	end

	broadcast_channel={}
	listen_count={}
	--1：全局广播
	broadcast_channel[1]={}
	listen_count[1]=0
	for _node_name,_data in pairs(_broadcast_list) do
		if _node_name~=node_name then
			local _channel_id_set=cluster.call(_node_name,other_node_broadcast[_node_name],
														"get_all_channel_id")
			for _,_id in ipairs(_channel_id_set) do
				broadcast_channel[_id]={}
				listen_count[_id]=0
			end
			break
		end
	end
end


function CMD.start(_config)
	service_config=_config
	init_broadcast()

	print("broadcast  start!!!")
	
end


skynet.start(function()

	-- by lyx
	skynet.dispatch("lua", base.default_dispatcher)

	--只发送，不接收
	skynet.register_protocol {
		name = "multicast",
		id = skynet.PTYPE_MULTICAST,
	}

	skynet.register "bc_service"
end)


