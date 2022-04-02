--
-- Author: lyx
-- Date: 2018/4/4
-- Time: 15:28
-- 说明：比赛配置数据
--

local skynet = require "skynet_plus"
local basefunc = require "basefunc"
local base = require "base"
require "normal_enum"
require "printfunc"

local PROTECT = {}


-- 启动几个服务
local service_num = 1



function PROTECT.init()

	return {
		service_num = service_num,
	}

end


function PROTECT.get_config()

	return {
		service_num = service_num,
	}

end


return PROTECT