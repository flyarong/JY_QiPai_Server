--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：登录服务
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"

local DATA = base.DATA

local file_handle
local debug_file = skynet.getenv("debug_file")

local file_error = false

local _last_flush_time = os.time()
local _written_after_flush
local _writing = false

local write_queue = basefunc.queue.new()

local function write_queue_size()
	write_queue:push_front(">>>>> log queue size:" .. tostring(write_queue:size()) .. "\n")
end

local function update_write_log()

	while not write_queue:empty() do
		file_handle:write(write_queue:pop_front())
		_written_after_flush = true
	end

	-- 5秒强行写入一次
	if _written_after_flush and os.time()-_last_flush_time > 5 then

		local debug_file_size = (tonumber(skynet.getcfg("debug_file_size")) or 120) * 1024 * 1024

		local _f_size = file_handle:seek("end")
		file_handle:close()
		_written_after_flush = false

		-- 文件太大，重开日志文件
		if debug_file_size > 0 and _f_size >= debug_file_size then

			local _new_name,_repl = string.gsub(debug_file,"%.[^%./\\%s]+$",function(_ext)
				return os.date("_%Y%m%d_%H%M%S") .. _ext
			end)
			--skynet.orig_error(string.format("rename log file :%s!", tostring(_repl)))
			if _repl > 0 then
				os.rename(debug_file,_new_name)
			else
				-- 没有扩展名，直接加后缀
				os.rename(debug_file,debug_file .. os.date("_%Y%m%d_%H%M%S"))
			end
		end

		local err
		file_handle,err = io.open(debug_file,"a")
		if not file_handle then
			file_error = true
			skynet.orig_error(string.format("open log file '%s' error:%s!",debug_file,tostring(err)))
			return false
		end

		_last_flush_time = os.time()
	end
end

function base.CMD.get_queue_size()
	return write_queue:size()
end

-- 用户登录消息 
function base.CMD.write(_text)
	if not file_error then
		write_queue:push_back(_text)
	end
end

if debug_file then

	--os.execute("mkdir -p ./logs") by lyx: 这一句要造成蛋疼

	debug_file = "./logs/" .. debug_file

	local err
	file_handle,err = io.open(debug_file,"a")

	if file_handle then
		base.CMD.write(string.format("[:%08x][%s] log service started!\n",skynet.self(),os.date("%Y-%m-%d %H:%M:%S")))
		skynet.timer(0.5,update_write_log)
		skynet.timer(30,write_queue_size)
	else
		file_error = true
		skynet.orig_error(string.format("open log file '%s' error:%s!", debug_file,tostring(err)))
	end
end


-- 启动服务
base.start_service(nil,"wlog_service")
