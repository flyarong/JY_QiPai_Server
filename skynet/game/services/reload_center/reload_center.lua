--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：重加载中心，负责配置、代码的重加载
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"

require "printfunc"

local CMD=base.CMD
local DATA=base.DATA

-- 全局配置数据：name => {time=,file=,config=,}
local global_config_data = {}

local _config_dir = skynet.getenv("game_config_dir") or "./game/config/"

-- 配置改变通知: service_hash_id => {name => link}
local config_notify = {}

-- 源码改变通知： service_hash_id => {file => link}
local lua_notify = {}

local function get_link_hash(_link)
	return tostring(_link.node) .. tostring(_link.addr)
end

local function add_notify(_notify,_service_hash_id,_link,_name)
	local _s_data = _notify[_service_hash_id] or {}
	_notify[_service_hash_id] = _s_data

	_s_data[_name] = _link
end

local function del_notify(_notify,_service_hash_id,_name)

	if _name then
		local _s_data = _notify[_service_hash_id]
		if _s_data then
			_s_data[_name] = nil
		end
	else
		_notify[_service_hash_id] = nil
	end

end

local function send_notify(_notify,_name,_cmd,...)
	for _service_hash_id,_data in pairs(_notify) do
		local _link = _data[_name]
		if _link then
			cluster.send(_link.node,_link.addr,_cmd,...)
		end
	end	
end

function CMD.register_config(_link,_name)

	add_notify(config_notify,get_link_hash(_link),_link,_name)
end

function CMD.unregister_config(_link)
	del_notify(config_notify,get_link_hash(_link))
end

function CMD.register_lua(_link,_name)

	add_notify(lua_notify,get_link_hash(_link),_link,_name)
end

function CMD.unregister_lua(_link)
	del_notify(lua_notify,get_link_hash(_link))
end

-- 重加载配置
function CMD.reload_config(_name)
	local _data = basefunc.path.reload_lua(_config_dir .. _name .. ".lua")
	send_notify(config_notify,_name,"on_config_changed",_name,_data)
end

function CMD.get_config(_name)
	return basefunc.path.reload_lua(_config_dir .. _name .. ".lua")
end

-- 重加载源代码
function CMD.reload_lua(_name)

	send_notify(lua_notify,_name,"on_lua_changed",_name)
end

-- 收集名字集合
local function collect_notify_names(_notify)
	local ret = {}
	
	for _service_hash_id,_data in pairs(_notify) do
		for _name,_ in pairs(_data) do
			ret[_name] = true
		end
	end	

	return ret
end

local function debug_reload_all()
	if not skynet.getcfg("debug_reload_center") then
		return
	end

	-- 配置
	local _configs = collect_notify_names(config_notify)
	for _name,_ in pairs(_configs) do
		CMD.reload_config(_name)
	end

	-- 源码
	local _luas = collect_notify_names(lua_notify)
	for _name,_ in pairs(_luas) do
		CMD.reload_lua(_name)
	end
	
end

function CMD.start(_service_config)

	DATA.service_config = _service_config
	
	--skynet.timer(5,debug_reload_all)
end

-- 启动服务
base.start_service()
