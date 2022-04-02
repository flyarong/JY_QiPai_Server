--- 金猪 ， 中心服务

local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local skynet = require "skynet_plus"
require "normal_enum"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

--- 金猪数据
DATA.player_goldpig_data = nil

function CMD.start(_service_config)
	DATA.service_config = _service_config

	
	base.import("game/services/goldpig_center_service/goldpig_center_op_interface.lua")

	PUBLIC.load_all_goldpig_data()
end

-- 启动服务
base.start_service()