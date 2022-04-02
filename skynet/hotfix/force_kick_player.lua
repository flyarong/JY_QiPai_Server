--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：修复 get_player_openid  的问题
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

	PUBLIC.logout()

    return "执行成功！"
end