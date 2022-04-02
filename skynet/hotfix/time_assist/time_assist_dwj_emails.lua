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


local exec_key = {}


local function do_something()

	local data={
		email={
			type = "native",
			title = "端午狂欢送福利",
			sender = "系统",
			valid_time = 2021547864,
			data = "{content='鲸鱼斗地主祝您端午安康，现送上端午福利，请笑纳！！！（6月4日-6月10日每天都有）',prop_fish_lock=30,prop_fish_frozen=10}",
		},
	}

	--全局邮件
	local errcode = skynet.call(DATA.service_config.email_service,"lua",
										"external_send_email",
										data,
										"系统",
										"dwj_fl")

	print("dwj send_email finish !!!")

	if errcode then
		print(" dwj send_email error : " .. errcode)
	end

end


--执行具体活动的内容
function PUBLIC.update()

	local cur_time = os.time()
	local cur_h = tonumber(os.date("%H",cur_time))
	local cur_m = tonumber(os.date("%M",cur_time))
	-- local cur_s = tonumber(os.date("%S",cur_time))
	local cur_date = tonumber(os.date("%Y%m%d",cur_time))

	if cur_date >= 20190604 and cur_h==6 and cur_m>=0  and cur_m<5 then
		
		if not exec_key[cur_date] then
			
			do_something()

			exec_key[cur_date] = true

		end

	end

	-- 结束了
	if cur_date >= 20190610 and cur_h >= 6 and exec_key[cur_date] then

		print("dwj fl finish")

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