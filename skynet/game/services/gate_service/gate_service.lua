--
-- Author: lyx
-- Date: 2018/3/13
-- Time: 17:32
-- 说明：
--

local skynet = require "skynet_plus"
local gateserver = require "snax.gateserver"
local basefunc = require "basefunc"
local handle = require "gate_service.handle_socket"
local base = require "base"

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}

local CMD = {}


function CMD.kick(source, fd)
	gateserver.closeclient(fd)
end

function CMD.set_service_name(source, _service_name)
	handle.service_name = _service_name
end

-- local function countdown_publish_prepare_time()
-- 	local prc = skynet.getcfg("publish_prepare_cd")
-- 	if prc then 
-- 		prc = tonumber(prc) - 1
-- 		if prc < 1 then
-- 			skynet.setcfg("publish_prepare_cd",nil)

-- 			print("===>>>> publish prepare is over <<<<====")
-- 		else
-- 			skynet.setcfg("publish_prepare_cd",prc)

-- 			if math.fmod(prc,5) < 1 then
-- 				print("===>>>> publish prepare count down:",prc)
-- 			end
-- 		end
-- 	end
-- end

function CMD.start(source,_service_config)

	handle.service_config = _service_config

	-- 加载协议
	skynet.uniqueservice("protoloader")

	--skynet.timer(1,countdown_publish_prepare_time)

	skynet.sleep(50)

	handle.start()

	--skynet.call(handle.service_config.third_agent_service,"lua","push_android_notify","ArYxvMfQKs4p108z0zvYosF_Op_POwdXlNeT_LigDzid","aaa ticker","aaa title1","aaa text1呵呵")
	--skynet.call(handle.service_config.third_agent_service,"lua","push_ios_notify","f817f6dacfbacc166f1fa0cf4f54a032f0bc51339f0a7a5fa52ed04f9566bf16","ios aaa ticker","ios aaa title1","ios aaa text1哈哈嘿")
	
	--skynet.call(handle.service_config.third_agent_service,"lua","push_notify",
	--	{"108315283","108316710"},"gg aaa ticker111","zz aaa title2","xxx 3333 ftext1哈哈嘿")

	return skynet.call(skynet.self(), "lua", "open" , {
		port = tonumber(skynet.getenv "gate_port"),
		maxclient = tonumber(skynet.getenv "gate_maxclient" or 5000) * 1.5 ,
		nodelay = true,
	})

end

function CMD.stop_service()
	return "free"
end
function CMD.get_service_status()
	return "free"
end

function handle.command(cmd, source, ...)
	local f = assert(CMD[cmd])
	return f(source, ...)
end

gateserver.start(handle)