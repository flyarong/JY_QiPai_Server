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

return function()

    -- 托管的延迟参数
    cluster.call("tg","node_service","update_config","tuoguan_mj_delay_1",100)
    cluster.call("tg","node_service","update_config","tuoguan_mj_delay_2",150)

    return "完成!"

end