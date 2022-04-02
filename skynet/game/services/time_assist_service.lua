--
-- Author: yy
-- Date: 2018/3/10
-- Time: 15:13
-- 说明：时间辅助服务

--[[
	根据配置 
	在指定的时间启动或停止指定的服务
	配置可以热更新
	指定的服务可以直接写代码，然后编辑到配置中进行启动
	已经启动了的服务不会被更新
	可以随时新增新服务
]]



local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
require "printfunc"
local nodefunc = require "nodefunc"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA


local config = {}


--[[
	key=id
	value={
			id
			path         --服务路径  services/xxx/xx
			startTime    --启动时间
			service_id   --有这个ID 表示已经启动
			closeTime    --结束时间
			is_close	 --表示是否已经关闭
			isover      --表示是否已经结束
		}
--]]
local data={}

--服务id前缀
local service_id_qz="time_assist_service_"
local update_dt=100

local function start_service(_id,_path)
	local service_id =service_id_qz.._id
	local _ser=skynet.newservice(_path)
	skynet.call("node_service","lua","append",service_id,_ser)
	local _ser_ret=skynet.call(_ser, "lua","start",service_id,DATA.service_config)
	return service_id
end


local function stop_service(_service_id)
	nodefunc.send(_service_id,"stop_and_exit")
	print(_service_id.." stop_and_exit !!!")
end

local function update_status()

	for id,c in pairs(config) do
		
		local p = c.path
		local st = tonumber(c.start_time)
		local et = tonumber(c.end_time) or 2548920402
		local ct = os.time()

		if p and type(p)=="string" and st and st>0 then

			if ct > st and ct < et then
				if not data[id] then
					
					data[id] = 
					{
						config = c,
						service_id = start_service(id,p),
					}

				end

			elseif ct > et then
				if data[id] then
					stop_service(data[id].service_id)
					data[id] = nil
				end
			end

		end

	end

end

local function load_config(_raw_config)
	local _cfg = basefunc.deepcopy(_raw_config)
	
	config = _cfg

	update_status()

end


local function update()
	while true do
		skynet.sleep(update_dt)
		update_status()
	end
end


function CMD.query_status()
	dump(data)
	return data
end

function CMD.start(_service_config)

	DATA.service_config=_service_config

	nodefunc.query_global_config("time_assist_service_config",load_config)

	skynet.fork(update)

end


-- 启动服务
base.start_service(nil,"loadstopser")

