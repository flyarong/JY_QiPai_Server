--
-- Author: lyx
-- Date: 2018/3/30
-- Time: 15:14
-- 说明：心跳 的 处理
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

-- 心跳状态变化,通过参数 _is_good 只是心跳状态（好/坏） 
-- n 秒（暂定为 4） 没有心跳就 触发不好的事件；收到 就触发恢复事件
base.DATA.hearbeat_status_change = basefunc.signal.new()

-- 警告时间
local NET_WARNING_INTERVAL = 4

--心跳包间隔（秒）
local HEARTBEAT_INTERVAL=3

--心跳包延迟 诱发网络错误时间（秒）
local NET_ERROR_TIME=HEARTBEAT_INTERVAL * 2.5

-- 客户端心跳计时器： 距离上次收到心跳的时间
local hearbeat_time = 0

-- 网络出错后，诱发 释放引用 agent 的时间（秒）
local FREE_AGENT_TIME = 300

-- 网络出错 已经持续的时间； nil 表示 未出错
local neterror_time

-- 心跳是否运行中
local heart_running = false

-- 最近一次心跳
local last_heart_time = nil

-- 心跳状况
local is_heartbeat_good = true

local PROTECTED = {}


local function trigger_stop_hearbeat_status()
	if is_heartbeat_good then
		is_heartbeat_good = false
		base.DATA.hearbeat_status_change:trigger(is_heartbeat_good)
	end
end

-- 触发网络错误
function PROTECTED.net_error()

	-- 开始网络错误计时
	if not neterror_time then
		neterror_time = 0
	end
end
local net_error = PROTECTED.net_error

-- 停止心跳
function PROTECTED.stop_hearbeat()

	trigger_stop_hearbeat_status()

	heart_running = false -- 停止心跳

	last_heart_time = nil
	
	base.PUBLIC.free_agent("ref_by_hearbeat") -- 释放引用

	
end

local function update(dt)

	-- 心跳包超时 处理
	hearbeat_time = hearbeat_time + dt
	if hearbeat_time > NET_ERROR_TIME then

		if not neterror_time then
			print("hearbeat time out :",hearbeat_time,last_heart_time and (os.time() - last_heart_time),base.DATA.my_id)

			-- 触发网络错误
		   net_error()
		end

		hearbeat_time = 0
	end

	-- 网络错误 超时处理
	if neterror_time then
		neterror_time = neterror_time + dt
		if neterror_time > FREE_AGENT_TIME then
			-- print("hearbeat stop by net error :",last_heart_time and (os.time() - last_heart_time),neterror_time,base.DATA.my_id)
			PROTECTED.stop_hearbeat()
		end
	end

	if last_heart_time then

		-- 误差允许增加一个网络错误
		if os.time() - last_heart_time > NET_WARNING_INTERVAL+NET_ERROR_TIME then
			trigger_stop_hearbeat_status()
		end

	end

end

-- 开始更新函数
skynet.timer(0.5,update)

-- 开始检查心跳包，增加 agent 引用计数
function PROTECTED.start_heartbeat()

	-- 引用 agent
	base.PUBLIC.ref_agent("ref_by_hearbeat")

	base.REQUEST.heartbeat()
	heart_running = true

end

local tmp_table = {}
function base.REQUEST.heartbeat()
	hearbeat_time = 0
	neterror_time = nil

	last_heart_time = os.time()

	--print("heartbeat:",base.DATA.my_id,os.time())

	if not is_heartbeat_good then
		is_heartbeat_good = true
		skynet.timeout(0,function ()
			base.DATA.hearbeat_status_change:trigger(is_heartbeat_good)
		end)
	end

	return tmp_table
	--print("heartbeat!",os.time())
end



return PROTECTED