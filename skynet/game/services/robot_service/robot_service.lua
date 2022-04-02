--
-- Author: lyx
-- Date: 2018/4/24
-- Time: 20:27
-- 说明：机器人服务（伪）
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
require"printfunc"

require "robot_service.robot_assign_manager"

local monitor_lib = require "monitor_lib"

local robot_pool

local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC

-- 单位：1/100 秒
DATA.LOGIN_WAIT_TIME = 150

DATA.service_config = nil

math.randomseed(os.time())

-- 机器人对象集合： client_id -> robot
DATA.robots = {}

-- 使用中的机器人： login_id => user_data
local using_robot = {}

function PUBLIC.remove_robot(_id)

	if _id and DATA.robots[_id] then

		local _login_id = DATA.robots[_id].login_id

		DATA.robots[_id] = nil

		if not _login_id or _login_id == "" then
			print("remove robot id error: ",_id)
		else
			if using_robot[_login_id] then
				robot_pool[#robot_pool + 1] = using_robot[_login_id]
				using_robot[_login_id] = nil
			end
		end
	end

end

function PUBLIC.get_free_robot_user_data()

	local _count = #robot_pool
	local _index = math.random(_count-1)

	local ret = robot_pool[_index]

	-- 用最后一个补位
	robot_pool[_index] = robot_pool[_count]
	robot_pool[_count] = nil

	using_robot[ret.id] = ret

	return ret
end

-- 收到 player agent 发来的消息
function CMD.request_client(client_id,name,data)
	if not client_id then
		--print("robot_service CMD.request_client client_id is nil !")
		return
	end

	local _robot = DATA.robots[client_id]

	if not _robot then
		--print(string.format("robot_service CMD.request_client client_id '%s' is not exists !",tostring(client_id)))
		return
	end

	_robot:dispatch_message(name,data)
end

-- 收到 player agent 发来的 response
function CMD.response_client(client_id,responeId,data)
	local _robot = DATA.robots[client_id]
	if _robot then
		_robot:wakeup_respones(responeId,data)
	end
end

-- 踢下用户，销毁机器人
function CMD.kick_client(_id,_call_event)
	local _r = DATA.robots[_id]
	if _r then
		_r:exit()
	end
end


function CMD.start(_service_config)

	DATA.service_config = _service_config
	base.DATA.node_name = skynet.getcfg "my_node_name"

	-- ###_temp 整个游戏中暂时 只支持一个 机器人服务
	base.DATA.my_id = "robot_service"
	skynet.call(base.DATA.service_config.node_service,"lua","append",base.DATA.my_id,skynet.self())

	local _robot_file = skynet.getcfg "robot_file"
	if not _robot_file then
		skynet.fail("not found robot_file config !")
		return false
	end

	robot_pool = require(_robot_file)

	if not robot_pool then
		skynet.fail("load robot file error : " .. tostring(_robot_file))
		return false
	end

	-- 加载固定数量的机器人
	skynet.timeout(500,function()
		for i=1,200 do
			local _robot_count = tonumber(skynet.getcfg("robot_count_" .. i))
			local _robot_type = skynet.getcfg("robot_type_" .. i)
			if not _robot_count or not _robot_type then
				break
			end

			if _robot_count > 0 then

				local robots = PUBLIC.create_robots(_robot_type,_robot_count)
				PUBLIC.start_robots(robots)

				if #robots < _robot_count then
					print("warning: start create robot count not enough !")
					break
				end
			end
		end
	end)

	if skynet.getcfg("debug_monitor_system") then
		local _time0 = os.time()
		skynet.timer(0.5,function ()
			local t = os.time()-_time0
			local _count = math.random(1,t * 20)
			for i=1,_count do
				monitor_lib.add_data("test",t * 50)
			end
		end)
	end

	return true
end

-- 启动服务
base.start_service()
