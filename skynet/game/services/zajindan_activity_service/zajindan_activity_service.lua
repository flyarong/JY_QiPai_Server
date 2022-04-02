--- 砸金蛋活动 服务


local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local skynet = require "skynet_plus"
require "normal_enum"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

DATA.activity_status_enum = {
	wait = "wait",
	running = "running",
	over = "over",
}

DATA.activity_status = ""

DATA.activity_valid_time = {}

local function cancelable_timeout(ti, func)
  	local function cb()
    	if func then
      		func()
    	end
  	end
  	local function cancel()
    	func = nil
  	end
  	skynet.timeout(ti, cb)
  	return cancel
end

--- 检查启动
function PUBLIC.check_launch()
	if DATA.activity_valid_time then
		local now_time = os.time()
		if now_time >= DATA.activity_valid_time.start_time and now_time <= DATA.activity_valid_time.end_time then
			DATA.activity_status = DATA.activity_status_enum.running

			--- 延迟执行
			DATA.time_outer = cancelable_timeout((DATA.activity_valid_time.end_time - now_time + 1)*100 , function() 
				PUBLIC.check_launch()
			end )

		elseif now_time < DATA.activity_valid_time.start_time then
			DATA.activity_status = DATA.activity_status_enum.wait

			--- 延迟执行
			DATA.time_outer = cancelable_timeout((DATA.activity_valid_time.start_time - now_time + 1)*100 , function() 
				PUBLIC.check_launch()
			end )

		elseif now_time > DATA.activity_valid_time.end_time then
			DATA.activity_status = DATA.activity_status_enum.over
		end
	else
		error("no activity_valid_time config!!")
		--skynet.exit()
	end
end

local function load_config(_config)
	for key,data in pairs(_config.main) do
		if data.key == "activity_valid_time" then
			if type(data.value) == "table" and #data.value == 2 then
				DATA.activity_valid_time.start_time = math.min(data.value[1],data.value[2])
				DATA.activity_valid_time.end_time = math.max(data.value[1],data.value[2])
			end
			
		elseif data.key == "activity_level" then
			DATA.activity_level = data.value
		end
	end

	if DATA.time_outer then
		DATA.time_outer()	
	end

	PUBLIC.check_launch()
end

function CMD.start(_service_config)
	DATA.service_config = _service_config

	--base.import("game/services/zajindan_activity_service/zajindan_activity_config.lua")
	nodefunc.query_global_config("zajindan_activity_cfg_service",load_config)
	base.import("game/services/zajindan_activity_service/zajindan_activity_interface.lua")


	--PUBLIC.check_launch()

end

-- 启动服务
base.start_service()