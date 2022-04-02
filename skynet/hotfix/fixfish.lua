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

DATA.error_room_id = 
{
	fishing_service_1_room_3 = true,
}

-- 归还桌子
function CMD.return_table(_room_id,_t_num)
	
	if DATA.error_room_id[_room_id] then
		return
	end

	PUBLIC.return_table(_room_id,_t_num )

end


return function()


	print(" ok ")

end