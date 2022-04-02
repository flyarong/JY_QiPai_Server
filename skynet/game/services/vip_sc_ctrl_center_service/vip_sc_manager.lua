--
-- Author: lyx
-- Date: 2018/3/28
-- 说明：vip sc 管理器，管理 数据加载、周期 的开始、结束

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECTED = {}

local vip_sc_cfg

-- ###_temp 正式后 应该调用 get_rest_time 接口
local day_time_start = os.time({year=2018,month=11,day=1,hour=6,min=0,sec=0})

local function new_vip_data(_player_id)

	return
	{
		player_id = _player_id,
		remain_vip_count = 0,
		vipfanjiang_debt = 0,
		presented_debt = 0,

		status = "init",
        cur_day_index = 1,
		cur_vip_start_time = 0,
		cur_debt = 0,
		cur_remain_debt = 0,
		cur_qhtg_cost = 0,
	}

end

-- 从数据库加载
function PUBLIC.load_vip_sc_data(_player_id)

    local _data = skynet.call(DATA.service_config.data_service,"load_vip_sc_data",_player_id) or new_vip_data()

    DATA.vip_data[_player_id] = _data

	return _data
end

-- 初始化用户 vip 信息，登录时调用
function CMD.init_vip_sc(_player_id)

	local _data = PUBLIC.load_vip_sc_data(_player_id)
	
	PUBLIC.check_vip_status(_data)
end

--[[
玩家购买 vip
参数：
	_player_id 玩家
	_buy_id 购买标识 id
	_price 费用（人民币，分）
	_fanjiang 总返奖额（人民币，分）
	_present 赠送鲸币数量(充值后马上获得的 金币)
	_day_count 天数
--]]
function CMD.buy_vip(_player_id,_buy_id,_price,_fanjiang,_present,_day_count)
    local _data = assert(DATA.vip_data[_player_id])

    _data.remain_vip_count = _data.remain_vip_count + math.floor(_day_count/10)

	-- 返奖
	_data.vipfanjiang_debt = _data.vipfanjiang_debt + (_fanjiang - _price *(1 + vip_sc_cfg.qudao_fencheng)) * vip_sc_cfg.jing_bi_rate

	-- 赠送鲸币
	_data.presented_debt = _data.presented_debt + _present

    -- 将购买存入到数据库
	skynet.call(DATA.service_config.data_service,"update_vip_sc_data",_player_id,_buy_id,_data.remain_vip_count,_data.vipfanjiang_debt,_data.presented_debt)

	-- 检查 vip 状态
	PUBLIC.check_vip_status(_data)
end

-- 得到两个时间 的天 数 之差： _begin_hour 作为 一天的起始
local function get_day_diff (_t1,_t2)

    return math.floor((_t2 - day_time_start)/86400) - math.floor((_t1 - day_time_start)/86400)
end


-- 取出一个周期的总债务
local function take_period_debt (_data)

	local vf = math.floor(_data.vipfanjiang_debt/_data.remain_vip_count)
	local ps = math.floor(_data.presented_debt/_data.remain_vip_count)

	_data.vipfanjiang_debt = _data.vipfanjiang_debt - vf
	_data.presented_debt = _data.presented_debt - ps

	-- 每一期 平均分配
	return vf + ps
end

-- 计算个周期的总红包
local function calc_lucky_data(_data)

	local _lucky = match.random(vip_sc_cfg.lucky_range[1],vip_sc_cfg.lucky_range[2]) * vip_sc_cfg.lucky_base/100

	-- 全用 债务抵消
	_data.cur_debt = _data.cur_debt + _lucky

	return _lucky
end

local function calc_baoji_data(_data)

	local _baoji = match.random(vip_sc_cfg.baoji_range[1],vip_sc_cfg.baoji_range[2]) * vip_sc_cfg.baoji_base/100

	-- 仅仅 基础 值 由债务抵消
	_data.cur_debt = _data.cur_debt + vip_sc_cfg.baoji_base

	return _baoji
end

-- 从数组弹出 多个 数 并求和
local function pop_numbers_sum (_vec,_count)
	local ret = 0
	local _n = math.min(#_vec,_count)
	for i=1,_n do
		ret = ret + _vec[#_vec]
		_vec[#_vec] = nil
	end

	return ret
end

-- 分派 每天 红包
local function dispatch_period_lucky(_data,_ctrl,_lucky)

	local _sum_lucky_weight = 0	-- 红包权重之和

	for _,_c in ipairs(_ctrl) do
		_sum_lucky_weight = _sum_lucky_weight + vip_sc_cfg.control[_c].lucky_power
	end

	assert(_sum_lucky_weight > 0,"dispatch_period_lucky failed!")

	local _lucky_datas = PUBLIC.cur_period_lucky_dispatch(_lucky,_sum_lucky_weight)

	for i,_c in ipairs(_ctrl) do
		_data.cur_days[i].today_lucky = pop_numbers_sum(_lucky_datas,vip_sc_cfg.control[_c].lucky_power)
	end
end

-- 分派 每天 债务
local function dispatch_period_debt(_data,_ctrl)

	local _tuoguan_count = 0 -- 托管介入天数

	for _,_c in ipairs(_ctrl) do
		_tuoguan_count = _tuoguan_count + vip_sc_cfg.control[_c].tuoguan
	end

	assert(_tuoguan_count > 0,"dispatch_period_debt failed!")

	local _debt_datas = PUBLIC.cur_period_debt_dispatch(_data.cur_debt,_tuoguan_count)

	for i,_c in ipairs(_ctrl) do
		_data.cur_days[i].today_debt = pop_numbers_sum(_debt_datas,vip_sc_cfg.control[_c].tuoguan)
	end

end


-- 将未完成的数据分派到 某天
function PUBLIC.use_undone_data(_data,_undone_data,_day)

	-- 红包用来抵债
	local _lucky = _undone_data.lucky - _undone_data.debt

	if _lucky >= 0 then
		_day.today_lucky = _day.today_lucky + _lucky
	else
		_day.today_debt = _day.today_debt - _lucky
	end
end


-- 处理 天 的切换。注意：可能跨 周期
function PUBLIC.switch_vip_day(_data,_day_index)

	-- 结算当天
	PUBLIC.settle_today(_data,_data.cur_day_index)

	if _day_index > vip_sc_cfg.period then -- 跨周期

		local _undone_data = PUBLIC.collect_undone_data(_data,_data.cur_day_index,vip_sc_cfg.period)

		local _diff_period = math.floor(_day_index/vip_sc_cfg.period)

		-- 中间跨过了至少一个周期
		if _diff_period > 1 then

			if _diff_period > _data.remain_vip_count then
				-- 超过 剩余 的 周期数，结束
				
			end

			PUBLIC.deal_empty_period(_data,_diff_period - 1)
		end
		
	else -- 未跨周期

		-- 收集未完成的
		local _undone_data = PUBLIC.collect_undone_data(_data,_data.cur_day_index,_day_index-1)

		-- 抵债
		PUBLIC.use_undone_data(_data,_undone_data,_data.cur_days[_day_index])

		-- 切换到今天
		_data.cur_day_index = _day_index
	end

end

-- 在状态为 "run" 时，检查 天的 的切换
function PUBLIC.check_day_change(_player_id)

    local _data = assert(DATA.vip_data[_player_id])

	if "run" == _data.status then
		local _day_index = get_day_diff(_data.cur_vip_start_time,os.time()) + 1
		if _day_index > _data.cur_day_index then
			PUBLIC.switch_vip_day(_data,_day_index)
		end
	end

end

local function dispatch_period_data(_data,_lucky)

	-- 初始化每一天的 数据
	local _days = {}
	for i=1,vip_sc_cfg.period do
		_days[i] = PUBLIC.new_day_data()
	end
	_data.cur_days = _days

	-- 分派曲线控制
	local _ctrl = PUBLIC.dispatch_period_control(_data)

	-- 分债 
	dispatch_period_debt(_data,_ctrl)

	-- 分红包
	dispatch_period_lucky(_data,_ctrl,_lucky)


end

-- 取得当期数据： 从总数据中 取到 当前数据
function PUBLIC.take_period_data(_data)
	
	-- 债务、红包、暴击
	_data.cur_debt = take_period_debt(_data)
	local _lucky = calc_lucky_data(_data)
	local _baoji = calc_baoji_data(_data)

	-- 处理暴击
	local _half = math.floor(_baoji/2)
	_data.cur_debt = _data.cur_debt - _half
	_lucky = _lucky + (_baoji-_half)

	-- 债务红包 排期
	dispatch_period_data(_data,_lucky)

	_data.remain_vip_count = _data.remain_vip_count - 1
end

-- 在状态不为 'run' 的情况下，开始 vip 周期
function PUBLIC.start_vip_sc_period(_data)

	_data.cur_vip_start_time = os.time()
	_data.cur_giveback_debt = 0
	_data.cur_day_index = 1

	PUBLIC.take_period_data(_data)

	_data.status = "run"
end

-- 检查 vip 状态，如果没开始，就开始
function PUBLIC.check_vip_status(_data)
	if "run" ~= _data.status then
		PUBLIC.start_vip_sc_period(_data)
	end
end

function PROTECTED.init()

    vip_sc_cfg = nodefunc.get_global_config("vip_sc_config")

end

return PROTECTED
