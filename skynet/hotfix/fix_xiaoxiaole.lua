--
-- Author: wss
-- Date: 2018/4/11
-- Time: 15:07
-- 说明：
-- 使用方法：
-- call xiaoxiaole_lottery_center_service exe_file "hotfix/fix_xiaoxiaole.lua"
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



function PUBLIC.get_xc_map( rate )
	local award_rate = rate * 10    -- math.random(1,500)

	local xc_map_vec = nil
	local xc_map_string = nil

	if not DATA.lottery_xc_map then
		return xc_map_string,award_rate / 10
	end

	------ 开奖，如果没有找到先去找小一个等级的，如果实在找不到就找打一个等级的
	if not DATA.lottery_xc_map[award_rate] then
		print("xxx-------------not_lottery_xc_map:",award_rate)
		local while_dir = -1
		---- 先找更小的，找到0 再去找更大的

		local while_num = 0
		local max_while_num = 10000
		local now_key = award_rate
		while true do
			while_num = while_num + 1
			if while_num > max_while_num then 
				break
			end
			now_key = now_key + while_dir
			if DATA.lottery_xc_map[now_key] then
				xc_map_vec =  DATA.lottery_xc_map[now_key] 

				award_rate = now_key
				break
			end
			if now_key <= 0 then
				now_key = award_rate
				while_dir = 1
			end
		end
	else
		xc_map_vec =  DATA.lottery_xc_map[award_rate] 
	end

	----- 避免同一个奖励等级里面，拿到相同的消除样式
	if xc_map_vec and type(xc_map_vec) == "table" and #xc_map_vec > 0 then
		
		----- 选一个随机key
		local random_key = math.random( #xc_map_vec )

		xc_map_string = xc_map_vec[random_key]


	end

	return xc_map_string , award_rate / 10
end



return function()

    return "send ok!!!"

end