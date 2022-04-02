--
-- Author: hw
-- Date: 2018/3/19
-- Time: 15:13
-- 说明：测试代理
--ddz_test_agent
local skynet = require "skynet_plus"
require "skynet.manager"
local base = require "base"

require "printfunc"

local CMD=base.CMD
local DATA=base.DATA
local PROTECT=base.PROTECT
local REQUEST=base.REQUEST
local test_agent_manager
local node_service
require "player_agent.ddz_match_game"

function CMD.start(_id,_ser_config)
	DATA.ser_cfg=_ser_config
	DATA.my_id=_id
	skynet.fork(function ()
			skynet.sleep(200+math.random(50,250))

			--nodefunc.call("ddz_m_1","apply",{id=DATA.my_id})
	end)
	return 0
end

-- 启动服务
base.start_service()
