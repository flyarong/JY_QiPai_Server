--
-- Author: hw
-- Date: 2018/3/10
-- Time: 15:13
-- 说明：节点服务管理器


local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
require "printfunc"
local nodefunc = require "nodefunc"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

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
local service_id_qz="fuzhu_ser_qwsa_"
local update_dt=100

local function loadService(v)
	local id =service_id_qz..v.id
	local _ser=skynet.newservice(v.path)
	skynet.call("node_service","lua","append",id,_ser)
	local _ser_ret=skynet.call(_ser, "lua","start",id,DATA.service_config)
	v.service_id=id
end
local function closeService(v)
	nodefunc.send(v.service_id,"stop_and_exit")
	v.is_close=true
	v.isover=1
	data[v.id]=nil
	--向数据库写入 已完成
	skynet.call(DATA.service_config.data_service,"lua","update_load_and_close_ser_cfg_over",v.id,v.isover)
end


local function loadOrStop()
	local cur_time=os.time()
	for id,v in pairs(data) do
		if v.path and  v.isover==0 then
			--启动
			if not v.service_id and v.startTime then
				if cur_time>v.startTime then
					loadService(v)
				end
			end	
			--关闭
			if v.service_id and v.closeTime and not v.is_close then
				if cur_time>v.closeTime then
					closeService(v)
				end
			end
		end
	end
end

local function update()
	while true do
		skynet.sleep(update_dt)
		loadOrStop()
	end
end

function CMD.refreshData()
 	--读取
 	local _data=skynet.call(DATA.service_config.data_service,"lua","query_load_and_close_ser_cfg")
 	for k,v in pairs(_data) do
 		if v.isover==0 then
 			CMD.refreshOrAddOneCmd(v.id,v.path,v.startTime,v.closeTime)
 		end
 	end
end 

--not_floor  是否落地  默认落地  
function CMD.refreshOrAddOneCmd(id,path,startTime,closeTime,isover,not_floor)
	if data[id] then
		if data[id].isover==0 then
			data[id].path=path
			data[id].startTime=startTime
			data[id].closeTime=closeTime
			data[id].isover=isover
			if not not_floor then
				--修改数据库
				skynet.call(DATA.service_config.data_service,"lua","insert_load_and_close_ser_cfg",data[id])
			end
		end
	else
		data[id]={	
					id=id,
					path=path,
					startTime=startTime,
					closeTime=closeTime,
					isover=0,
				}
		--插入数据库
		if not not_floor then
			skynet.call(DATA.service_config.data_service,"lua","insert_load_and_close_ser_cfg",data[id])
		end

	end
end

function CMD.getAndDumpData()
	dump(data)
	return data
end


function CMD.start(_service_config)

	DATA.service_config=_service_config
	CMD.refreshData()

	skynet.fork(update)

end





-- 启动服务
base.start_service(nil,"loadstopser")





