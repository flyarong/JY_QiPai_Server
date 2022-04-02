--- add by wss
---  vip礼包 服务


local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local skynet = require "skynet_plus"
require "normal_enum"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

function CMD.start(_service_config)
	DATA.service_config = _service_config

	base.import("game/services/sczd_vip_lb_service/sczd_vip_lb_config.lua")
	base.import("game/services/sczd_vip_lb_service/sczd_vip_lb_interface.lua")

	PUBLIC.init()

end

-- 启动服务
base.start_service()