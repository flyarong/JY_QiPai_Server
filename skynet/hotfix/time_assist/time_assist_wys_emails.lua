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

local exec_date = 20190209
local exec_h = 6
local exec_m = 0


local function do_something()

	local data={
		email={
			type = "native",
			title = "万元大奖赛等你来战",
			sender = "系统",
			valid_time = 1736657298,
			data = "{content='亲爱的老板大大们：万元赛来袭！2月9日大年初五晚19点30报名，20:00开赛！购买过金猪礼包的朋友，一定要记得参加比赛，比赛入口-公益锦标赛-千元大奖赛，冠军1万元等你来战！ \\n                                                                                鲸鱼斗地主 \\n                                                                            2019年2月9日'}",
		},
	}

	--全局邮件
	local errcode = skynet.call(DATA.service_config.email_service,"lua",
										"external_send_email",
										data,
										"系统",
										"万元大奖赛")

	print("wys send_email finish !!!")

	if errcode then
		print(" wys send_email error : " .. errcode)
	end

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