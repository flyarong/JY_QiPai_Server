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

local begin_date = 20190115

local end_date = 20190121


--敲敲乐活动福利
local function send_qql_email()

	local data={
		email={
			type = "native",
			title = "敲敲乐活动福利",
			sender = "系统",
			valid_time = 1736657298,
			data = "{content='感谢您长期以来对游戏的支持与厚爱，敲敲乐玩法火爆上线，活动期间每天可通过邮件领取30个玩具锤，赶快去体验吧！活动时间：2019年1月16日-2019年1月22日',prop_hammer_1=30}",
		},
	}

	--全局邮件
	local errcode = skynet.call(DATA.service_config.email_service,"lua",
										"external_send_email",
										data,
										"系统",
										"敲敲乐活动福利")

	if errcode then
		print("qql_activity_service activity send_email error : " .. errcode)
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
		if not send_email_data[cur_date] and cur_h==service_zero_time and cur_m==0 and cur_s<5 then
			send_email_data[cur_date] = true

			send_qql_email()

		end
	end


end


return PROTECTED