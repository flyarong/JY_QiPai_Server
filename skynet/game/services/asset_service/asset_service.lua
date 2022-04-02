--
-- Author: yy
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：资产服务
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"
local cjson = require "cjson"

local withdraw_cash = require "asset_service.withdraw_cash"
local withdraw_cash_gjhhr = require "asset_service.withdraw_cash_gjhhr"


local DATA = base.DATA
local CMD = base.CMD
local PUBLIC=base.PUBLIC


local function init()
	
	withdraw_cash.init()

	withdraw_cash_gjhhr.init()

end

local function update(dt)
	withdraw_cash.update(dt)
	withdraw_cash_gjhhr.update(dt)
end



function CMD.start(_service_config)
	DATA.service_config = _service_config

	init()

	skynet.timer(2,update)

end

-- 启动服务
base.start_service()

