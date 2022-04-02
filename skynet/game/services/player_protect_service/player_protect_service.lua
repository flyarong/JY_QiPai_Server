--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：玩家破产保护
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"

require "printfunc"

require "player_protect_service.player_protect"

local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC

function CMD.start(_service_config)

	DATA.service_config = _service_config
    
end

-- 启动服务
base.start_service()



