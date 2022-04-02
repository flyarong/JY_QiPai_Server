--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：发公告
-- 使用方法：
-- call broadcast_center_service exe_file "hotfix/fix_broadcast.lua"
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

return function()

    -- CMD.broadcast(1,{type=2,format_type=1,content="鲸鱼斗地主将于2月1日 （明早）8：30-9：00进行服务器例行维护，届时将无法进行游戏，请大家注意游戏时间以免给您造成损失。"})
    
    -- call broadcast_center_service exe_file "hotfix/fix_broadcast.lua"
    
	CMD.broadcast(1,{type=2,format_type=1,content="鲸鱼斗地主将于 5 分钟后进行服务器例行维护，届时将无法进行游戏，请大家注意游戏时间以免给您造成损失。"})

    return "send ok!!!"

end