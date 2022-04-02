--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：麻将 房间热更新
-- 使用方法： 
--      hf_inc_ver fix_common_mj_xzdd_room_service
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

local this = {}

function this.on_load()
    return "room fix loaded!"
end

return this