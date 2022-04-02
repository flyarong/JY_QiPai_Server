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

local service_config

local per_time=12000
--每段时间内最多写入日志条数
local max_log_num=50
local max_log_count=0


function base.CMD.write_bug_log(error_info,user_id)
		
	local log_path=skynet.getcfg("clientBugTrackLog")
	if log_path and error_info and max_log_count<max_log_num then
		local cur_time=os.time()
		local file_name=os.date("%Y-%m-%d",cur_time)
		local nowTime=os.date("%Y-%m-%d-%H-%M-%S",cur_time)
		local path=log_path..file_name..".txt"
		-- print(path)
		local file=io.open(path,'a')
		if file then 
			file:write("\n***************************"..nowTime.."\n")
			if user_id then
				file:write("user_id:  "..user_id.."\n")
			end
			file:write(error_info)
			file:close()
		end
		max_log_count=max_log_count+1

 	end
end



function base.CMD.start(_service_config)
	service_config = _service_config

	skynet.fork(function ()
		while true do
			max_log_count=0
			skynet.sleep(per_time)
		end
	end)
	-- 每隔一段时间拉取 登录开关

end


-- 启动服务
base.start_service()
