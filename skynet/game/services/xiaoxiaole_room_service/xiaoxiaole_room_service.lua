--- add by wss
---  消消乐房间服务


local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local skynet = require "skynet_plus"
require "normal_enum"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

function CMD.start(_id,_ser_cfg,_config)
	DATA.service_config = _ser_cfg


	base.import("game/services/xiaoxiaole_room_service/xiaoxiaole_room_config.lua")
	base.import("game/services/xiaoxiaole_room_service/xiaoxiaole_room_interface.lua")

	
	PUBLIC.init(_id,_ser_cfg,_config)

	

	return 0
end

-- 启动服务
base.start_service()