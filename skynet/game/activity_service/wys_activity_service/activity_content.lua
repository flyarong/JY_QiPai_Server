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
require "printfunc"

local DATA = base.DATA
local CMD = base.CMD

local PROTECTED = {} 

local send_email_data = {}


local service_zero_time = 6

local begin_date = 20190209

local end_date = 20190209


--万元赛邮件
local function send_wys_email()

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

	if errcode then
		print("wys_activity_service activity send_email error : " .. errcode)
	end

end

--执行具体活动的内容
function PROTECTED.update()

	local cur_time = os.time()
	local cur_h = tonumber(os.date("%H",cur_time))
	local cur_m = tonumber(os.date("%M",cur_time))
	local cur_s = tonumber(os.date("%S",cur_time))
	local cur_date = tonumber(os.date("%Y%m%d",cur_time))


	if cur_date >= begin_date and cur_date <= end_date then
		if not send_email_data[cur_date] and cur_h==6 and cur_m==0 and cur_s<5 then
			send_email_data[cur_date] = true

			send_wys_email()

		end
	end


end


return PROTECTED