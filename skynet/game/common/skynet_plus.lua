--
-- Author: lyx
-- Date: 2018/3/12
-- Time: 11:21
-- 说明：对 skynet 某些功能增加的函数
--

local skynet = require "skynet"
local basefunc = require "basefunc"
local sharedata = require "skynet.sharedata"

--local _rand_chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
-- 去掉容易混淆的字符
local _rand_chars = "6A9BD4E7FG8HJLMQNKR3TUdYabefhgijkmnqrt2uy"
local _rand_len = string.len(_rand_chars)

local random = math.random

-- uuid 序号
local _uuid_number = 0

-- 出错时调用此函数
function skynet.fail(err)
	if skynet.getenv("debug") == "1" then
		error(tostring(err),2)
	else
		skynet.error(debug.traceback(tostring(err),2))
	end
end

-- 时钟对象
local timer = basefunc.class()
function timer:ctor(_interval,_callback)

	self._interval = _interval * 100 -- 转换为 skynet 的时钟单位
	self._callback = _callback

	self:start()
end


function timer:start()

	local _err_count = 0

	local _last_print_err = os.time()

	local function error_handle(msg)
		_err_count = _err_count + 1

		-- n 秒打印一次错误
		if _err_count == 1 or os.time() - _last_print_err > 60 then
			print(tostring(msg) .. " => error count:" .. tostring(_err_count),debug.traceback())
			_last_print_err = os.time()
		end
	end

	if not self._running then
		self._running = true
		skynet.fork(function()

			-- 更新函数
			local lastDt = skynet.now()
			while self._running do

				skynet.sleep(self._interval)
				if not self._running then
					break
				end
				
				local cur = skynet.now()
				local ok ,ret = xpcall(self._callback, error_handle, (cur - lastDt) * 0.01)

				if ok and false == ret then
					break
				end

				lastDt = cur

			end

		end)
	end
end

function timer:stop()
	self._running = false
end

function timer:set_interval(_interva1)
	self._interval = _interva1 * 100
end

-- 新建时钟： 按 _interval 时间间隔，重复调用 _callback
-- 返回一个时钟对象 timer，支持操作：
--  	timer:stop()  销毁时钟
--  	timer:set_interval()  重新设置时间间隔（秒）
-- 终止时钟（两种方式）：
--		1、调用 timer:stop()
--		2、_callback 返回 false （返回 nil 或 true 均表示继续 ）
function skynet.timer(_interval,_callback)
	return timer.new(_interval,_callback)
end

-- 生成一个随机字符串
function skynet.random_str(_len)
	if _len <= 0 then
		return ""
	end

	local _chars = {}
	for i=1,_len do
		local r = random(_rand_len)
		_chars[#_chars + 1] = string.sub(_rand_chars,r,r)
	end

	return table.concat(_chars)
end

-- 生成一个 uuid
function skynet.generate_uuid()
	_uuid_number = _uuid_number + 1
	local _str = string.format("%u9%u9%u",os.time(),tonumber(skynet.self()),_uuid_number)
	local _ret = {}
	for i=1,string.len(_str) do
		local r = tonumber(string.sub(_str,i,i))
		_ret[#_ret+1] = string.sub(_rand_chars,r,r)
	end

	return table.concat(_ret)
end

-- 生成加密用的 key，参数 _mix_data: 用于混合到生成的 key 中
function skynet.gen_encrypt_key(_len,_mix_data)
	local _ret = {}

	for i=1,_len do
		if _mix_data and #_mix_data > 0 then
			local _i = random(255 + #_mix_data)
			if _i > 255 then
				_ret[#_ret + 1] = string.sub(_mix_data,_i-255,_i-255)
			else
				_ret[#_ret + 1] = string.char(_i)
			end
		else
			_ret[#_ret + 1] = string.char(random(255))
		end
	end

	return table.concat(_ret)
end

local _node_share
local function ensure_node_share()
	if not _node_share then

		--local sharedata = require "skynet.sharedata"

		_node_share = sharedata.query("node_share")
		if not _node_share then
			error("sharedata 'node_share' has not created!")
		end
	end
end

-- 读取一个 sharedata 中的 配置项（用于替代 skynet.getenv）
function skynet.getcfg(_name,_default)
	
	ensure_node_share()

	local _v = _node_share.node_configs[_name]
	if nil == _v then
		return _default 
	else
		return _v
	end
end
function skynet.getcfg_2number(_name,_default)
	return tonumber(skynet.getcfg(_name,_default))
end
-- 得到共享数据
function skynet.getshare(_name)
	ensure_node_share()

	return _node_share[_name]
end

-- 设置配置项
function skynet.setcfg(_name,_value)
	skynet.call("node_service","lua","update_config",_name,_value)
end

-- 得到节点表
function skynet.get_nodes()
	ensure_node_share()
	return _node_share.nodes
end

skynet.orig_print = print
skynet.orig_error = skynet.error

-- 控制台输出信息 加上 辅助信息

local _is_real_linux = (skynet.getenv("is_real_linux") == "1")

local _log_service
local _log_service_error = false

local _last_day = 0

local _orig_print = print
local _orig_error = skynet.error

local debug_file = skynet.getenv("debug_file")

local write_queue = basefunc.queue.new()


local pack = table.pack
-- 参数打包成字符串
local function pack_param(...)
	local _st = pack(...)
	for i=1,_st.n do
		_st[i] = tostring(_st[i])
	end

	return table.concat(_st,"\t")
end


local function debug_write_log(_is_error,_info,...)

	local _va_info = pack_param(...)

	local _d_info = os.date("%H:%M:%S] ") .. tostring(_info)

	if _is_error then
		_orig_error("[" .. _d_info .. _va_info)
	else
		if _is_real_linux then
			_orig_print(_info .. _va_info)
		else
			_orig_print(string.format("[:%08x] [%s ",skynet.self(),_d_info) .. _va_info)
		end
	end

	if debug_file and not _log_service_error then
		write_queue:push_back(string.format("[:%08x][%s %s ",skynet.self(),os.date("%Y-%m-%d"),_d_info) .. _va_info .. "\n")
	end
end

local function flush_log()

	if write_queue:empty() then return end

	if not _log_service then
		_log_service = skynet.uniqueservice("write_logfile_service")
		if not _log_service then
			write_queue:clear()
			_log_service_error = true
			return false
		end
	end

	while not write_queue:empty() do
		skynet.send(_log_service,"lua","write",write_queue:pop_front())
	end
end

if debug_file then
	skynet.timer(0.5,flush_log)
end

local _orig_exit = skynet.exit
function skynet.exit()
	if debug_file then
		flush_log()
	end

	_orig_exit()
end

local function write_day_start_info()
	local _now = os.date("*t")
	local _today = _now.year * 10000 + _now.month * 100 + _now.day * 100
	if _today ~= _last_day then
		_last_day = _today

		debug_write_log(false,string.format(" [%s] ====== new day start ======",os.date("%Y-%m-%d")))

	end
end

function print(_info,...)

	write_day_start_info()

	debug_write_log(false,_info,...)
end


function skynet.error(_info,...)

	write_day_start_info()

	debug_write_log(true,_info,...)
end

return skynet