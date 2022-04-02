--
-- Author: wss
-- Date: 2018/4/11
-- Time: 15:07
-- 说明：
-- 使用方法：
-- call sczd_center_service exe_file "hotfix/fix_sczd_data2.lua"
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

local player_vec = {
	"102661978",
	"10619412",
}

return function()
	
	for key,player_id in pairs(player_vec) do
		PUBLIC.add_palyer_contribute( player_id , "tglb2" , 102 , 10000 )
	end

    return "send ok!!!"

end