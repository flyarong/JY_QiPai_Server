--
-- Author: lyx
-- Date: 2018/3/22
-- Time: 16:06
-- 说明：玩家相关的基础数据

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local service_debug_log = {}


local function write_call_service(session, source, cmd, subcmd, ...)

	if debug_file_handle then
		local _t_info = table.pack(subcmd,...)
		for i=1,_t_info.n do
			_t_info[i] = tostring(_t_info[i])
		end

		debug_file_handle:write(string.format("[%s %f] call from:",os.date("%H:%M:%S"),os.clock()) ..
			string.format("%d %08x %s ",session,source,cmd) ..
			table.concat(_t_info,"\t") .. "\n")
	end
end

local function write_response_service(session,...)

	if debug_file_handle then

		local _t_info = table.pack(subcmd,...)
		for i=1,_t_info.n do
			_t_info[i] = tostring(_t_info[i])
		end

		debug_file_handle:write(string.format("[%s %f] resp:",os.date("%H:%M:%S"),os.clock()) ..
			string.format("%d ",session) ..
			table.concat(_t_info,"\t") .. "\n")

	end

	return ...	
end

skynet.timer(2,function ( ... )
	if debug_file_handle then
		debug_file_handle:flush()
	end
end)

-- 消息分发函数
function service_debug_log.dispatcher(session, source, cmd, subcmd, ...)

	write_call_service(session, source, cmd, subcmd, ...)

	local f = CMD[cmd]
	if f then
		if session == 0 then
			f(subcmd, ...)
		else
			skynet.ret(skynet.pack(write_response_service(session,f(subcmd, ...))))
		end
	else
		print(string.format("error: command '%s' not found.",cmd))
		if session ~= 0 then
			skynet.ret(skynet.pack("command not found !"))
		end
	end
end


return service_debug_log