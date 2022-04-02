--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：机器人分配管理
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"
local cjson = require "cjson"

require "printfunc"

local DATA = base.DATA
local CMD = base.CMD
local PUBLIC=base.PUBLIC

local _last_client_id = 0

-- 创建机器人
-- 参数 _game_info ：游戏信息， 即 xxx_req_game_list 中返回的一项
-- 返回：机器人的 client id 列表
function PUBLIC.create_robots(_robot_type,_count,_game_info)
	local robot_class = require("robot_service.robot_" .. _robot_type)

	local _clients = {}

	for i=1,_count do

		local _user_data = PUBLIC.get_free_robot_user_data()
		if not _user_data then
			return _clients
		end

		_last_client_id = _last_client_id + 1

		DATA.robots[_last_client_id]  = robot_class.new(_last_client_id,_user_data,_game_info)

		_clients[#_clients + 1] = _last_client_id

	end

	return _clients
end

-- 启动机器人列表
function PUBLIC.start_robots(_robot_clients)

	for _,_id in ipairs(_robot_clients) do
		skynet.fork(DATA.robots[_id].start,DATA.robots[_id])
	end
end

-- 销毁机器人列表
function PUBLIC.destroy_robots(_robot_clients)
	for _,_id in ipairs(_robot_clients) do
		PUBLIC.remove_robot(_id)
	end
end

-- 指派指定类型和数量的机器人到 给定的服务
-- 参数 _game_info ：游戏信息， 即 xxx_req_game_list 中返回的一项
-- 返回：0 或 错误号
function CMD.assign_robot(_robot_type,_count,_game_info)

	-- print("assign robot,type,count,game_id:",_robot_type,_count,_game_info.game_id)

	local robots = PUBLIC.create_robots(_robot_type,_count,_game_info)
	if #robots < _count then
		PUBLIC.destroy_robots(robots)
		print("warning: assign_robot robot count not enough ! ",_robot_type,_count)
		return 1007
	else
		PUBLIC.start_robots(robots)
		return 0
	end
end
