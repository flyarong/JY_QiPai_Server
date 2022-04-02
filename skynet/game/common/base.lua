--
-- Author: lyx
-- Date: 2018/3/22
-- Time: 15:11
-- 说明：程序开始的 基础表
-- 	具体使用举例
--[[

	local base = require "base"

	-- 保护函数
	local PROTECTED = {}

	function PROTECTED.xxxfunc()

	end

	-- 命令处理函数
	function base.CMD.xxxcmd()
		。。。
	end

	-- 公共功能函数
	function base.PUBLIC.xxxfunc()

		base.DATA.nnn = nnn -- 访问公共数据
	end


	return PROTECTED
]]

local skynet = require "skynet_plus"
local basefunc = require "basefunc"
require "skynet.manager"

local cjson = require "cjson"
cjson.encode_sparse_array(true,1,0)

local self_link = {node=skynet.getenv("my_node_name"),addr=skynet.self()}

local base = {

-- 供外部服务调用的命令
	CMD = {},

	-- 客户端的请求
	REQUEST={},

	-- 公共函数
	PUBLIC = {},

	-- 公共数据
	DATA = {},

	CUR_CMD = {},

	-- import 的代码文件
--	FILES
}

local CMD=base.CMD
local DATA = base.DATA
local PUBLIC = base.PUBLIC
CUR_CMD = base.CUR_CMD

local _config_dir = skynet.getenv("game_config_dir")

---- add by wss
--- 操作锁
DATA.action_lock = DATA.action_lock or {}
--- 打开 操作锁,   ！！！！ player_id 不传用于agent；player_id要传用于中心服务
function PUBLIC.on_action_lock( lock_name , player_id )
	if player_id then
		DATA.action_lock[lock_name] = DATA.action_lock[lock_name] or {}
		DATA.action_lock[lock_name][player_id] = true
	else
		DATA.action_lock[lock_name] = true
	end
end	
--- 关闭锁
function PUBLIC.off_action_lock( lock_name , player_id )
	if player_id then
		DATA.action_lock[lock_name] = DATA.action_lock[lock_name] or {}
		DATA.action_lock[lock_name][player_id] = false
	else
		DATA.action_lock[lock_name] = false
	end
end
--- 获得锁
function PUBLIC.get_action_lock( lock_name , player_id )
	if player_id then
		return DATA.action_lock[lock_name] and DATA.action_lock[lock_name][player_id] or false
	else
		return DATA.action_lock[lock_name]
	end
end

-- 重新加载配置文件
function base.reload_config(_config_file)

	package.loaded[_config_file] = basefunc.path.reload_lua(_config_dir .. _config_file .. ".lua")

	return package.loaded[_config_file]
end

-- 重新加载文件
function base.require(_dir,_file)

	package.loaded[_file] = basefunc.path.reload_lua(_dir .. _file .. ".lua")

	return package.loaded[_file]
end

local import_files = {}

local import_update_timer

local function re_import_file(_file,_data)
	local _prev
	if type(_data) == "table" and _data.on_destroy then
		_prev = _data.on_destroy()
	end

	local _cur = basefunc.path.reload_lua(_file)
	if type(_cur) == "table" and _cur.on_load then
		_cur.on_load(_prev)
	end

	import_files[_file] = _cur
end

local function import_update(dt)
	for _file,_data in pairs(import_files) do
		re_import_file(_file,_data)
	end
end

-- 以可热更新的方式加载 lua 文件
function base.import(_file)
	local _ret = import_files[_file] 
	if _ret then 
		return _ret
	end

	_ret = basefunc.path.reload_lua(_file)
	import_files[_file] = _ret

	if type(_ret) == "table" and _ret.on_load then
		_ret.on_load()
	end

	-- 不启用时钟检查，改为：通过 reload_center 的 通知 更新！
	-- if not import_update_timer then
	-- 	import_update_timer = skynet.timer(5,import_update)
	-- end

	-- 注册重新载入通知
	skynet.send(base.DATA.service_config.reload_center,"lua","register_lua",self_link,_file)

	return _ret
end

function base.CMD.on_lua_changed(_name)
	re_import_file(_name,import_files[_name])
end

function base.CMD.debug_modify_data(_name,_value)
	base.DATA[_name] = _value
end
function base.CMD.debug_show_data(_name)
	return base.DATA[_name]
end

function base.CMD.exe_file(_file)

	local _err_stack

	local ok,msg = xpcall(
		function()
			local _ret = basefunc.path.reload_lua(_file)
			if type(_ret) == "table" then
				if _ret.on_load then
					return _ret.on_load()
				end
			elseif type(_ret) == "function" then
				return _ret()
			else
				return "loaded!"
			end
		end,
		function(_msg)
			_err_stack = debug.traceback()
			return _msg
		end
	)

	if ok then
		return basefunc.tostring(msg)
	else
		return "错误:\n" .. tostring(msg) .. ":\n" .. tostring(_err_stack)
	end
end

local _dump_index = 0

-- 导出 base 中的数据
-- 可导出多层子键
function base.CMD.debug_dump(_name,...)
	if not _name then
		return "not input name!"
	end

	local _data = base[_name]
	if not _data then
		return "not found data:" .. tostring(_name)
	end

	local _dname = _name

	local _keys = {...}
	for _,v in ipairs(_keys) do
		if _data[v] then
			_data = _data[v]
			_dname = _dname .. "_" .. tostring(v)
		else
			break
		end 
	end

	_dump_index = _dump_index + 1
	local _serv_name = DATA and DATA.my_id or string.format("%x",skynet.self())
	local _fname = string.format("/dump_%s_%s_%s_%d.txt",_serv_name,_dname,os.date("%Y%m%d_%H%M%S"),_dump_index)
	local _fpath = skynet.getenv("dumpath") or "./logs"

	basefunc.path.write(_fpath .. _fname,basefunc.tostring(_data))

	return true
end

function base.PUBLIC.inner_get_dump_base_data(_name,...)

	if not _name then
		return "not input name!"
	end

	local _data = base[_name]
	if not _data then
		return "not found data:" .. tostring(_name)
	end

	local _keys = {...}
	for _,v in ipairs(_keys) do
		_data = _data[v]
		if not _data then
			break
		end
	end

 	---- 干掉所有的function 类型的
	return basefunc.deepcopy(_data ,{["function"] = true})

end

---- 
function base.CMD.return_data_dump_str(_name,...)

	return basefunc.tostring(base.PUBLIC.inner_get_dump_base_data(_name,...))
end

function base.CMD.return_data_dump_vec(_name,...)

	return base.PUBLIC.inner_get_dump_base_data(_name,...)
end

function base.CMD.return_data_dump_json(_name,...)
	local ret = base.PUBLIC.inner_get_dump_base_data(_name,...)
	if type(ret) == "string" then
		return ret
	elseif ret then
		return cjson.encode(ret)
	else
		return "nil"
	end
end


local _last_dump_file
local _last_dump_file_i = 0

function base.CMD.dump_data()
	local _file = string.format("data_dump_%x_",skynet.self()) ..  os.date("%Y%m%d_%H%M%S")
	if _file == _last_dump_file then
		_last_dump_file_i = _last_dump_file_i + 1
		_file = _file .. "_" .. tostring(_last_dump_file_i)
	else
		_last_dump_file_i = 0
	end

	local ok,err = basefunc.path.write(_file .. ".txt",basefunc.tostring(base.DATA))

	if ok then
		return ok
	else
		return err
	end
end

-- 当前状态 ： 含义参见 try_stop_service 函数
base.DATA.current_service_status = "running"
base.DATA.current_service_info = nil 			-- 说明信息

--[[
尝试停止服务：在这个函数中执行关闭前的事情，比如保存数据
（这里是默认实现，服务应该根据需要实现这个函数）
参数 ：
	_count 被调用的次数，可以用来判断当前是第几次尝试
	_time 距第一次调用以来的时间
返回值：status,info
	status
		"free"		自由状态。没有缓存数据需要写入，可以关机。
		"stop"	    已停止服务，可以关机
		"runing"	正在运行，不能关机
		"wait"      正在关闭，但还未完成，需要等待；
		            如果返回此值，则会一直调用 check_service_status 直到结果不是 "wait"
	info  （可选）可以返回一段文本信息，用于说明当前状态（比如还有 n 个玩家在比赛）
 ]]
function base.PUBLIC.try_stop_service(_count,_time)
	-- 5 秒后允许关闭
	if _time < 5 then
		return "wait",string.format("after %g second stop!",5 - _time)
	else
		return "stop"
	end
end

-- 得到服务状态
function CMD.get_service_status()
	return base.DATA.current_service_status,base.DATA.current_service_info
end

-- 供调试控制台列出所有命令
function CMD.incmd()
	local ret = {}
	for _name,_ in pairs(CMD) do
		ret[#ret + 1] = _name
	end

	table.sort(ret)
	return ret
end

--[[
关闭服务
	返回执行此命令后的状态
返回值： 
	参见 try_stop_service

注意： 如果 返回 "stop" 则在返回后 会立即退出（后续不要再调用此服务）
 ]]
local _last_command_running = false
function CMD.stop_service()

	-- 最近一次还正在执行，则直接返回结果
	if _last_command_running then
		return base.DATA.current_service_status,base.DATA.current_service_info
	end

	-- 停止
	base.DATA.current_service_status,base.DATA.current_service_info = base.PUBLIC.try_stop_service(1,0)

	-- 如果需要等待，则不断查询状态
	if "wait" == base.DATA.current_service_status then

		local _stop_time = skynet.now()
		local _count = 1

		_last_command_running = true
		skynet.timer(0.5,function()
			_count = _count + 1
			base.DATA.current_service_status,base.DATA.current_service_info = base.PUBLIC.try_stop_service(_count,(skynet.now()-_stop_time)*0.01)

			if "stop" == base.DATA.current_service_status then

				-- 停止服务
				skynet.call("node_service","lua","destroy_byaddr",skynet.self())
				skynet.timeout(1,function ()
					skynet.exit()
				end)

				return false

			elseif "wait" ~= base.DATA.current_service_status then

				-- 服务已不是等待状态，不需要再查询
			
				_last_command_running = false
				return false
			end

			_last_command_running = false
		end)
	end

	-- 停止服务
	if "stop" == base.DATA.current_service_status then
		skynet.call("node_service","lua","destroy_byaddr",skynet.self())
		skynet.timeout(1,function ()
			skynet.exit()
		end)
	end

	return base.DATA.current_service_status,base.DATA.current_service_info
end



function CMD.shutdown_service()

end


--[[ 设置热修补文件名
参数 _file_name:	热修补文件名，注意，不包括 路径和扩展名
					文件 固定放置在 hotfix 文件夹下
	使用举例：
		base.set_hotfix_file("fix_common_mj_xzdd_room_service")
--]]
function base.set_hotfix_file(_file_name)
	DATA.hot_fix_file = string.format("hotfix/%s.lua",_file_name)
	DATA.hot_fix_file_ver = 0
	DATA.hot_fix_ver_name = _file_name .. "_ver"
	DATA.hot_fix_status_name = _file_name .. "_enable"

	local function fix()
		if skynet.getcfg(DATA.hot_fix_status_name) then
			local _ver = tonumber(skynet.getcfg(DATA.hot_fix_ver_name))
			if _ver and _ver > DATA.hot_fix_file_ver then
				DATA.hot_fix_file_ver = _ver
				local _hotfix_ret = CMD.exe_file(DATA.hot_fix_file)
				print(string.format("hotfix file '%s' result:%s",DATA.hot_fix_file,_hotfix_ret))
			end
		end
	end

	-- 立即检测一次
	fix()

	-- 5 秒检测一次 是否需要热更行
	skynet.timer(5,fix)
end

-- 得到自己的地址
-- 说明：供外部使用者得到目标服务的真实地址，绕过可能的代理（例如 clusterproxy ）
function base.CMD.self()
	return skynet.self()
end

-- 设置 service_name ： 手动启动的服务名字，必须在 service_config 中存在
function base.CMD.set_service_name(_service_name)
	base.DATA.service_name = _service_name
end

local function cmd_get_args(...)
	if select("#") > 0 then
		return table.pack(...)
	else
		return nil
	end
end

local _service_start_stack_info

-- 默认的消息分发函数
function base.default_dispatcher(session, source, cmd, subcmd, ...)
	local f = CMD[cmd]

	CUR_CMD.session = session
	CUR_CMD.source = source
	CUR_CMD.cmd = cmd
	CUR_CMD.subcmd = subcmd
	CUR_CMD.args = cmd_get_args(...)

	if f then
		if session == 0 then
			f(subcmd, ...)
		else
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	else
		local _err_str
		if _service_start_stack_info then
			_err_str = string.format("error: command '%s' not found.\nservice start %s",cmd,_service_start_stack_info)
		else
			_err_str = string.format("error: command '%s' not found.",cmd)
		end
		print(_err_str)
		error(_err_str)
		-- if session ~= 0 then
		-- 	skynet.ret(skynet.pack("CALL_FAIL"))
		-- end
	end
end
local default_dispatcher = base.default_dispatcher

-- 启动服务
-- 参数:
-- 	_dispatcher    （可选） 协议分发函数
-- 	_register_name （可选） 注册服务名字
function base.start_service(_dispatcher,_register_name)

	-- 记录栈信息，以便在找不到命令是，输出上层文件信息
	_service_start_stack_info = debug.traceback(nil,2)

	skynet.start(function()

		skynet.dispatch("lua", _dispatcher or default_dispatcher)

		if _register_name then
			skynet.register(_register_name)
		end
	end)

end
function base.CMD.change_config(name,data)
	if name then
		base.DATA[name]=data
	end
end

return base


