--
-- Author: lyx
-- Date: 2018/5/30
-- Time: 11:09
-- 说明：系统监控函数库
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"

local DATA = base.DATA
local CMD = base.CMD

local min = math.min
local max = math.max

-- 数据缓存，每 秒提交一次。 name => {count=,value_sum=,value_min=,value_max=}
local data_cache = {}

local PROTECTED = {}

function PROTECTED.add_data(_name,_value)

	if not skynet.getcfg("enable_monitor") then
		return 
	end

	local _data = data_cache[_name] or {count=0,value_sum=0,value_min=0,value_max=0}
	data_cache[_name] = _data

	_value = _value  or 0

	_data.count = _data.count + 1
	_data.value_sum = _data.value_sum + _value
	_data.value_min = min(_data.value_min,_value)
	_data.value_max = max(_data.value_max,_value)
end

-- 每秒将数据提交到 monitor 服务
skynet.timer(1,function ()

	if not skynet.getcfg("enable_monitor") then
		return 
	end

	if next(data_cache) then
	
		skynet.send(DATA.service_config.monitor_service,"lua","add_datas",data_cache)

		data_cache = {}

	end
end)


return PROTECTED	