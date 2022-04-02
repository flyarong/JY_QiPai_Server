--- add by wss
---  周卡系统


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

	base.import("game/services/zhouka_system_service/zhouka_system_config.lua")
	base.import("game/services/zhouka_system_service/zhouka_system_interface.lua")

	PUBLIC.init()

	---- 向 数据服务 注册消息监听
	--[[skynet.send(DATA.service_config.data_service,"lua", 
		"register_msg" ,"zhouka_system"
		,{
			node = skynet.getenv("my_node_name"),
			addr = skynet.self(),
			cmd = "player_pay_msg"
		}
		, "on_pay_success" )--]]

	----  向新消息通知中心注册
	skynet.send(DATA.service_config.msg_notification_center_service,"lua", 
		"add_msg_listener" , "on_pay_success"
		,{
			msg_tag = "zhouka_system",
			node = skynet.getenv("my_node_name"),
			addr = skynet.self(),
			cmd = "player_pay_msg"
		}
		)
	

end

-- 启动服务
base.start_service()