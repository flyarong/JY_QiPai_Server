--
-- Author: wss
-- Date: 2019/4/29
-- Time: 15:11
-- 说明：任务  可能需要的一些通用函数

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST
local PUBLIC = base.PUBLIC

local loadstring = rawget(_G, "loadstring") or load

local task_base_func = {}


--- 获得最大的进程值
function task_base_func.get_max_process(process_data)
	local max_process = 0
	local max_task_round = 0   --- 最大的领取等级
	if process_data and type(process_data) == "table" then
		for key,process_value in pairs(process_data) do
			if process_value ~= -1 then
				max_process = max_process + process_value
				max_task_round = max_task_round + 1
			else
				max_process = 99999999999
				max_task_round = 99999999
				break
			end
		end
	end
	return max_process , max_task_round
end

--- 获得达到一个等级所需的总共进度
function task_base_func.get_grade_total_process(process_data,grade)
	local total_process = 0
	
	if not process_data or not grade or type(process_data) ~= "table" or type(grade) ~= "number" then
		return total_process
	end

	
	local index = 0
	local process_index = 1
	while true do
		index = index + 1
		if index >= grade then
			break
		end

		local lv_process = process_data[process_index]
		if not lv_process then
			break
		elseif lv_process == -1 then
			process_index = process_index - 1
			lv_process = process_data[process_index]
		end

		process_index = process_index + 1

		total_process = total_process + lv_process

	end

	return total_process
end

function task_base_func.parse_activity_data(_data)
	if not _data then
		return nil
	end

	local code = "return " .. _data
	local ok, ret = xpcall(function ()
		local data = loadstring(code)()
		if type(data) ~= 'table' then
			data = {}
			print("parse_activity_data error : {}")
		end
		return data
	end
	,function (err)
		print("parse_activity_data error : ".._data)
		print(err)
	end)

	if not ok then
		ret = {}
	end

	return ret or {},ok
end


return task_base_func