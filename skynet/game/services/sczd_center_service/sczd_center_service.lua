--- 生财之道中心服务


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

	
	base.import("game/services/sczd_center_service/sczd_data.lua")
	base.import("game/services/sczd_center_service/sczd_query_interface.lua")
	base.import("game/services/sczd_center_service/sczd_change_interface.lua")
	base.import("game/services/sczd_center_service/sczd_config.lua")

	PUBLIC.load_player_relation()
	PUBLIC.init_cfg()

	--- 提现消息
	--[[skynet.send(DATA.service_config.data_service,"lua", 
		"register_msg" ,"sczd_center"
		,{
			node = skynet.getenv("my_node_name"),
			addr = skynet.self(),
			cmd = "player_tixian_msg"
		}
		, "on_withdraw_success" )--]]

	----  向新消息通知中心注册
	skynet.send(DATA.service_config.msg_notification_center_service,"lua", 
		"add_msg_listener" , "on_withdraw_success"
		,{
			msg_tag = "sczd_center",
			node = skynet.getenv("my_node_name"),
			addr = skynet.self(),
			cmd = "player_tixian_msg"
		}
		)
	

end

-- 启动服务
base.start_service()