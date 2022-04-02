--
-- Author: lyx
-- Date: 2018/5/30
-- Time: 11:09
-- 说明：系统 监控服务
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"
local data_statistics = require "monitor_service.data_statistics"

local DATA = base.DATA
local CMD = base.CMD

function CMD.start(_service_config)
	DATA.service_config = _service_config

	data_statistics.init()
end

-- 启动服务
base.start_service()
