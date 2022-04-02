--
-- Author: lyx
-- Date: 2018/5/30
-- Time: 11:09
-- 说明：数据统计模块
--


local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"

local min = math.min
local max = math.max

local DATA = base.DATA
local CMD = base.CMD

local PROTECTED = {}

-- 统计数据记录： 配置名称 => 数组
local stat_data = {}

-- 各类型 的 报警检测函数
local WarnningCheck = {}

-- 从配置数据 更新 stat_data
local function refresh_config_map()

	if not skynet.getcfg("enable_monitor") then
		return
	end

	nodefunc.query_global_config("monitor_config",function (_config)

		-- 配置有改变，初始化统计数据

		stat_data = {}

		local _now = os.time()
		for _,_cfg in ipairs(_config) do

			local _d = stat_data[_cfg.name] or {}
			stat_data[_cfg.name] = _d

			_d[#_d + 1] = {
				config=_cfg,
				warning_time = 0,
				stat_time=_now,
				begin_time=_now,
				max_degree=-1, -- 监控的变量 超过 报警值的程度； -1 表示未达到； 0 表示达到； 大于零 表示超过的程度
				data={
					count = 0,
					value_sum = 0,
					value_min = 0,
					value_max = 0,
				}
			}
		end

	end)

end

-- 统计数据 复位
local function reset_stat(_stat)
	_stat.data.count = 0
	_stat.data.value_sum = 0
	_stat.data.value_min = 0
	_stat.data.value_max = 0
end

-- 格式化 秒
local function format_second(_second)
	local m = math.modf(_second/60)
	local s = math.fmod(_second,60)

	if m == 0 then
		return tostring(s) .. "秒"
	end

	if s == 0 then
		return tostring(m) .. "分钟"
	end

	return tostring(m) .. "分钟" .. tostring(s) .. "秒"
end

-- 格式化数值

-- 统计数据  报警
local function stat_warning(_stat,_cur_value,_degree)

	local _title,_text
	if "less" == _stat.config.comp then
		_title = string.format("\"平台警告：【%s】 在%s内降至 %s，低于临界值！\"",
			tostring(_stat.config.desc),
			format_second(_stat.config.dur),
			tostring(_cur_value))
	else
		_title = string.format("\"平台警告：【%s】 在%s内达到 %s，超过临界值！\"",
			tostring(_stat.config.desc),
			format_second(_stat.config.dur),
			tostring(_cur_value))
	end

	_text = string.format("\"配置详情：name=%s,dur=%s,degree_inc=%s,type=%s,limit=%s\"",
		_stat.config.name,
		_stat.config.dur,
		_stat.config.degree_inc,
		_stat.config.type,
		_stat.config.limit
		)

	-- 优先使用警告项的配置
	local _email = _stat.config.email or skynet.getcfg("monitor_recieve_email") 

	if skynet.getcfg("monitor_mock_email") then
		print(">>>>> mock send email:",
			"\"" .. _email .. "\"",
			_title,_text)
	else
		print(">>>>> real send email:",
			"\"" .. _email .. "\"",
			_title,_text)
		skynet.call(DATA.service_config.third_agent_service,"lua","send_email",
			"\"" .. _email .. "\"",
			_title,_text)
	end

	_stat.warning_time = os.time()
	_stat.max_degree = _degree

end

-- 检查是否可以发报警邮件
-- 参数 _degree ： 监控变量警报的严重程度， 正向越大 越严重。
local function can_warning_email(_stat,_degree)

	-- 未达到报警值
	if _degree < 0 then
		return false
	end

	-- 超过之前的报警值
	if _stat.max_degree > 0 and (_degree - _stat.max_degree <= _stat.config.degree_inc)  then
		return false
	end

	-- 上次报警 还未冷却
	if os.time() - _stat.warning_time < skynet.getcfg("monitor_email_time") then
		return false
	end

	return true
end

-- 得到当前值
local function get_current_value(_stat)

	if "sum" == _stat.config.type then
		return _stat.data.value_sum
	end

	if "count" == _stat.config.type then
		return _stat.data.count
	end

	if "value" ~= _stat.config.type then
		error(string.format("monitor config type error:%s",basefunc.tostring(_stat.config)))
	end

	if "less" == _stat.config.comp then
		return _stat.data.value_min
	else
		return _stat.data.value_max
	end
end

-- 得到警报 超过 值
local function get_degree(_stat,_cur_value)

	if "less" == _stat.config.comp then
		return _stat.config.limit - _cur_value
	else
		return _cur_value - _stat.config.limit
	end
end

-- 数据检查
local function warnning_check()

	if not skynet.getcfg("enable_monitor") then
		return
	end

	local _now = os.time()
	for _name,_stats in pairs(stat_data) do
		for _,_stat in ipairs(_stats) do

			-- 达到 数据收集时间
			if _now - _stat.stat_time >= _stat.config.dur then

				local _value = get_current_value(_stat)
				local _degree = get_degree(_stat,_value)

				if can_warning_email(_stat,_degree) then
					stat_warning(_stat,_value,_degree)
				end

				reset_stat(_stat)
				_stat.stat_time = _now

			end
		end
	end
end

function PROTECTED.init()

	-- 刷新配置
	refresh_config_map()

	-- 检查数据
	skynet.timer(5,warnning_check)
end

-- 加入统计数据
-- 参数 _datas ：  name => {count=,value_sum=,value_min=,value_max=}
function CMD.add_datas(_datas)

	for _name,_data in pairs(_datas) do
		local _stat_datas = stat_data[_name]

		if _stat_datas then

			-- 累积数据
			for _,_stat in ipairs(_stat_datas) do
				_stat.data.count = _stat.data.count + _data.count
				_stat.data.value_sum = _stat.data.value_sum + _data.value_sum
				_stat.data.value_min = min(_stat.data.value_min,_data.value_min)
				_stat.data.value_max = max(_stat.data.value_max,_data.value_max)

			end
		end
	end

end

return PROTECTED
