--
-- Author: yy
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：全局邮件 - 每个人都有的邮件
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"
require "normal_enum"

local loadstring = rawget(_G, "loadstring") or load

require "printfunc"

local DATA = base.DATA
local CMD = base.CMD
local PUBLIC=base.PUBLIC
local PROTECTED = {}
local LOCAL={}

--在线玩家每秒数量限制
local send_everyone_email_limit = 1000

--全局邮件繁忙中
DATA.send_everyone_email_busy = false


--data 已经就是字符串了
function CMD.send_everyone_email(email)

	if not email 
		or not email.type
		or not email.sender
		then 
			--不合法
			return 1001
	end

	if type(email.type)~="string"
		or type(email.sender)~="string"
		or (email.title and type(email.title)~="string")
		or (email.data and type(email.data)~="string")
			then
		return 1001
	end

	if DATA.send_everyone_email_busy then
		return 1008
	end

	email.valid_time = email.valid_time or 0
	email.data = email.data or "{}"
	email.create_time=os.time()

	email.data=string.gsub(email.data,"'",'"')
	local email_data,data_ok = PUBLIC.parse_email_data(email.data)
	if not data_ok then
		return 1001
	end

	
	email_data.asset_change_data = {change_type=ASSET_CHANGE_TYPE.MANUAL_SEND,change_id=0}

	email.data = email_data

	LOCAL.send_email_to_player(email)

	return 0
end


function LOCAL.send_email_to_player(email)
	
	DATA.send_everyone_email_busy = true
	local num = math.floor(send_everyone_email_limit / 100)

	skynet.fork(function ()
		
		local player_status_list = skynet.call(DATA.service_config.data_service,"lua","get_player_status_list")

		local sn = 0

		--先发在线的玩家
		for player_id,data in pairs(player_status_list) do
			
			if data.status == "on" and basefunc.chk_player_is_real(player_id) then
				
				email.receiver = player_id
				CMD.send_email(basefunc.deepcopy(email))
				sn = sn + 1
				
				if sn > num then
					skynet.sleep(1)
					sn = 0
				end

			end
		end

		for player_id,data in pairs(player_status_list) do
			if data.status == "off" and basefunc.chk_player_is_real(player_id) then
				
				email.receiver = player_id
				CMD.send_email(basefunc.deepcopy(email))
				sn = sn + 1
				
				if sn > num then
					skynet.sleep(1)
					sn = 0
				end

			end
		end

		DATA.send_everyone_email_busy = false

	end)

end

return PROTECTED