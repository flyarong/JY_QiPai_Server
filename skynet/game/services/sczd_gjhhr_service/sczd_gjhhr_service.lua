--- 生财之道 高级合伙人 中心服务

local skynet = require "skynet_plus"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "normal_enum"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA


function CMD.start(_service_config)
	
	DATA.service_config = _service_config

	base.import("game/services/sczd_gjhhr_service/sczd_gjhhr_data.lua")
	base.import("game/services/sczd_gjhhr_service/sczd_gjhhr_interface.lua")
	
	PUBLIC.init_data()
	
	---- 向 数据服务 注册消息监听
	--[[skynet.send(DATA.service_config.data_service,"lua", 
		"register_msg" ,"sczd_gjhhr"
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
			msg_tag = "sczd_gjhhr",
			node = skynet.getenv("my_node_name"),
			addr = skynet.self(),
			cmd = "player_pay_msg"
		}
		)

end

-- 启动服务
base.start_service()