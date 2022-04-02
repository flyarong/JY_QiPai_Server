--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：测试
-- 使用方法：
--  call <service addr> exe_file "hotfix/fixtest.lua"
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"
require "normal_enum"
require "printfunc"

local DATA = base.DATA
local CMD = base.CMD
local PUBLIC=base.PUBLIC

-- 只支持精确到分钟级别的时间
local updater_dt = 60

local exec_date = 20190201
local exec_h = 9
local exec_m = 10


local function do_something()

	print("do_something finish!!!")

end

--执行具体活动的内容
function PUBLIC.update()

	local cur_time = os.time()
	local cur_h = tonumber(os.date("%H",cur_time))
	local cur_m = tonumber(os.date("%M",cur_time))
	-- local cur_s = tonumber(os.date("%S",cur_time))
	local cur_date = tonumber(os.date("%Y%m%d",cur_time))

	if cur_date >= exec_date and cur_h>=exec_h and cur_m>=exec_m then
		
		do_something()

		if DATA.updater then
			DATA.updater:stop()
			DATA.updater = nil
		end

	end

end


return function()

	if not DATA.updater then
		DATA.updater = skynet.timer(updater_dt,function() PUBLIC.update() end)
		return "start ok !!!"
	end

	return "has started !!!"

end