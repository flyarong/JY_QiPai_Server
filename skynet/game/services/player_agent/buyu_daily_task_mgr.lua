--
-- Created by wss.
-- User: hare
-- Date: 2019/5/13
-- Time: 11:41
-- 捕鱼每日任务管理
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local task_initer = require "task.init"

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST
local PUBLIC = base.PUBLIC

DATA.buyu_daily_task_protect = {}
local PROTECT = DATA.buyu_daily_task_protect





return PROTECT