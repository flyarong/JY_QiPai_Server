local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local skynet = require "skynet_plus"
require "normal_enum"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA


function CMD.open_biggest_egg(player_id , player_name , _hammer_id , _base_money , today_award_num)
	if DATA.activity_status ~= DATA.activity_status_enum.running then
		return
	end

	--[[if today_award_num > 1 then
		return
	end--]]

	--- 操作限制
	if PUBLIC.get_action_lock("open_biggest_egg" , player_id) then
		return 1008
	end
	PUBLIC.on_action_lock( "open_biggest_egg" , player_id)


	---
	local is_give_award = false
	if DATA.activity_level then
		for key,value in pairs(DATA.activity_level) do
			if value == _hammer_id then
				is_give_award = true
				break
			end
		end
	end

	---
	local function get_money_str(base_money)
		if base_money < 10000 then
			return tostring( base_money )
		else
			return math.floor(base_money / 10000) .. "万"
		end
	end

	local time_date = os.date("*t",os.time())

	---- 发送邮件
	if is_give_award then
		local email = {
			type = "zjd_activity_award_evidence",
			receiver = player_id,
			sender = "系统",
			data={player_name=player_name,level=get_money_str(_base_money),time=string.format( "%s/%s/%s %02d:%02d:%02d",time_date.year , time_date.month , time_date.day , time_date.hour , time_date.min , time_date.sec )}
		}

		skynet.send(DATA.service_config.email_service,"lua","send_email",email)
	end


	PUBLIC.off_action_lock( "open_biggest_egg" , player_id)
end




