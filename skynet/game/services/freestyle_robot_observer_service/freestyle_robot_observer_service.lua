--
-- Author: lyx
-- Date: 2018/7/9
-- Time: 
-- 说明：游戏观察者服务
--

local skynet = require "skynet_plus"
require "skynet.manager"
local cluster = require "skynet.cluster"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "printfunc"

local robot_observer = require "freestyle_robot_observer_service.robot_observer"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA


function CMD.start(_service_config)
	
	DATA.service_config=_service_config

	robot_observer.init_robot_observer()
end

-- 启动服务
base.start_service()