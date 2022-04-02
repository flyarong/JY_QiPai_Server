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
require "printfunc"

local DATA = base.DATA
local CMD = base.CMD

local update_timer

function CMD.stop_and_exit()
	if update_timer then
		update_timer:stop()
		update_timer=nil
	end
	print("wys_activity_service --> stop")
	
	skynet.timeout(100,function ()
		skynet.exit()
	end)
	
end


function CMD.start(my_id,_service_config)
	DATA.service_config = _service_config

	local activity_content = base.require("game/activity_service/wys_activity_service/","activity_content")

	update_timer=skynet.timer(1,activity_content.update)

	print("start wys_activity_service ****************************>>>>>")

end


-- 启动服务
base.start_service()
