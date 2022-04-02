--
-- Author: lyx
-- Date: 2018/5/30
-- Time: 11:09
-- 说明：管理通过 web 团队代理实现的 支付功能（微信，支付宝）
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"

require"printfunc"
require "normal_enum"


local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECT = {}

local service_zero_time = 6

local withdraw_cash_config

local player_withdraw_cash_data

local system_withdraw_money = 0

local withdraw_cash_cache = {
	status = 0,
	min_withdraw_limit = 0,
	everyday_withdraw_max_limit = 0,

	cur_withdraw_num = 0,
	cur_withdraw_money = 0,

	can_withdraw_money = 0,
}


local function init_data()
	player_withdraw_cash_data = skynet.call(DATA.service_config.data_service,"lua","query_all_player_withdraw_status")
end

local function load_cfg(_raw_config)

	local _config = basefunc.deepcopy(_raw_config)

	withdraw_cash_config = _config

	withdraw_cash_cache.min_withdraw_limit = withdraw_cash_config.min_withdraw_limit
	withdraw_cash_cache.everyday_withdraw_max_limit = withdraw_cash_config.everyday_withdraw_max_limit
end


function PROTECT.update(dt)

	-- 每天 到点 清空	
	local time=os.date("*t")
    if time.hour==service_zero_time and time.min==0 and time.sec<5 then
    	system_withdraw_money = 0
    end

end


function CMD.query_player_withdraw_cash_status(_player_id,_money)
	local pwcd = player_withdraw_cash_data[_player_id] or {withdraw_num=0,withdraw_money=0,opt_time=0}
	player_withdraw_cash_data[_player_id] = pwcd

	if not basefunc.chk_same_date(pwcd.opt_time,os.time(),service_zero_time) then
		pwcd.withdraw_num = 0
		pwcd.withdraw_money = 0
	end

	withdraw_cash_cache.can_withdraw_money = 0

	if _money < withdraw_cash_config.min_withdraw_limit then

		withdraw_cash_cache.status = 2264

	else

		if pwcd.withdraw_num >= withdraw_cash_config.everyday_withdraw_num then
			withdraw_cash_cache.status = 2266
		elseif pwcd.withdraw_money >= withdraw_cash_config.everyday_withdraw_max_limit then
			withdraw_cash_cache.status = 2268
		elseif system_withdraw_money >= withdraw_cash_config.system_everyday_withdraw_max_limit then
			withdraw_cash_cache.status = 2267
		else
			withdraw_cash_cache.status = 0
			local _can_withdraw_money = withdraw_cash_config.everyday_withdraw_max_limit - pwcd.withdraw_money
			local _system_can_withdraw_money = withdraw_cash_config.system_everyday_withdraw_max_limit - system_withdraw_money
			_can_withdraw_money = math.min(_can_withdraw_money,_system_can_withdraw_money)
			_can_withdraw_money = math.min(_can_withdraw_money,_money)
			withdraw_cash_cache.can_withdraw_money = _can_withdraw_money
			if _can_withdraw_money < withdraw_cash_config.min_withdraw_limit then 
				withdraw_cash_cache.status = 2269
				withdraw_cash_cache.can_withdraw_money = 0
			end
		end	

	end	

	withdraw_cash_cache.cur_withdraw_num = pwcd.withdraw_num
	withdraw_cash_cache.cur_withdraw_money = pwcd.withdraw_money

	return withdraw_cash_cache
end


function CMD.player_withdraw_cash(_player_id,_money)
	
	local ret = CMD.query_player_withdraw_cash_status(_player_id,_money)

	if ret.status == 0 then

		local pwcd = player_withdraw_cash_data[_player_id]

		pwcd.withdraw_num = pwcd.withdraw_num + 1
		pwcd.withdraw_money = pwcd.withdraw_money + _money
		pwcd.opt_time = os.time()

		system_withdraw_money = system_withdraw_money + _money

		skynet.send(DATA.service_config.data_service,"lua","update_player_withdraw_status",_player_id,pwcd)
	end

end


--[[直接手动调用，设置参数进行更新配置
	1.个人单次 额度 限制
	2.每天 个人 额度限制
	3.每天 个人 次数限制
	4.每天 所有人总额 限制
]]
function CMD.set_withdraw_cash_cfg(_min_withdraw_limit,_everyday_withdraw_max_limit,_everyday_withdraw_num,_system_everyday_withdraw_max_limit)

	local cfg = {

		min_withdraw_limit = _min_withdraw_limit or withdraw_cash_config.min_withdraw_limit,
		everyday_withdraw_max_limit = _everyday_withdraw_max_limit or withdraw_cash_config.everyday_withdraw_max_limit,
		everyday_withdraw_num = _everyday_withdraw_num or withdraw_cash_config.everyday_withdraw_num,

		system_everyday_withdraw_max_limit = _system_everyday_withdraw_max_limit or withdraw_cash_config.system_everyday_withdraw_max_limit,

	}

	load_cfg(cfg)

	return 0
end


function PROTECT.init()

	init_data()
	
	nodefunc.query_global_config("withdraw_cash_config",load_cfg)

end

return PROTECT