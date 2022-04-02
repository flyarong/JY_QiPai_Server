--
-- Author: lyx
-- Date: 2018/10/9
-- Time: 15:14
-- 说明：托管服务
--


local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
require"printfunc"

local manager = require "tuoguan_service.tuoguan_agent_manager"

local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC

function CMD.start(_service_config)

	DATA.service_config = _service_config
	base.DATA.node_name = skynet.getcfg "my_node_name"

	manager.init()

	return true
end

-- 启动服务
base.start_service()