--
-- Author: lyx
-- Date: 2018/4/26
-- Time: 17:34
-- 说明：系统管理功能函数
--

local skynet = require "skynet_plus"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local base=require "base"
local payment_config = require "payment_config"

require "normal_enum"

local cluster = require "skynet.cluster"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

-- 设置支付选项
-- 参数 _payments ： channel_type => enable/disable
function CMD.set_payment_switch(_payments)

	-- 检查参数
	for _channel_type,_onoff in pairs(_payments) do
		if not payment_config.channel_types[_channel_type] then
			return 1001
		end
	end

	for _channel_type,_onoff in pairs(_payments) do
		
	end
end