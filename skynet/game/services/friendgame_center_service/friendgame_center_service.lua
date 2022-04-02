--
-- Author: lyx
-- Date: 2018/4/23
-- Time: 16:17
-- 说明：管理多个 match_data_config 配置（表 match_ddz_game 中的多行）
--

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "normal_enum"
require "printfunc"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local config_module = require "friendgame_center_service.friendgame_config_module"
local friendgame_center_config = {}

local friendgame_service = {}
local game_room_info = {}

local scend_max_dis_
local PROTECTED = {}

local service_count = 0
local function create_service_id()
	service_count = service_count + 1

	return "friendgame_service_" .. service_count
end

local function create_room_no()
	--if true then return "111111" end
	local no = math.random(100000,999999)
	local time=0
	while game_room_info[no] do
		no = math.random(100000,999999)
		time=time+1
		if time>20 then
			return nil
		end
	end
	return tostring(no)
end

local function launch_one_service()

	local _service_id = create_service_id()
	local ok,state = skynet.call("node_service","lua","create",false
									,"friendgame_service/friendgame_service",
									_service_id)

	if ok then

		-- friendgame_service[_service_id]={
		-- 	game_num = 0,
		-- }
		-- by lyx 2019-1-29
		friendgame_service[_service_id]= 0

	else
		skynet.fail(string.format("error: %s, create service error:%s !",
											_service_id,state))
	end

	return 0
end

local function init()
	
	for i=1,friendgame_center_config.service_num do
		launch_one_service()
	end

end


--创建一个游戏房间
function CMD.gen_game_manager_info(_game_type)

	local manager_id
	local min_game_num
	for id,game_num in pairs(friendgame_service) do
		if not min_game_num or min_game_num>game_num then
			min_game_num=game_num
			manager_id = id
		end
	end

	local no = create_room_no()
	if not no then
		return {result=1008}
	end

	game_room_info[no]=
	{
		manager_id=manager_id,
		game_type=_game_type
	}

	return {result=0,room_no=no,manager_id=manager_id}

end


--查询一个游戏房间
function CMD.query_manager_info(room_no)
	return game_room_info[room_no]
end

function CMD.clear_room_no(room_no)
	game_room_info[room_no]=nil
end

-- 重新加载配置， by lyx
-- 失败 返回 错误号
function CMD.reload_config()

	for _service_id,_d in pairs(friendgame_service) do

		nodefunc.send(_service_id,"reload_config")

	end
	
	return 0
end


function CMD.start(_service_config)

	DATA.service_config=_service_config

	-- 初始化
	config_module.init()
	friendgame_center_config = config_module.get_config()

	init()

end


-- 启动服务
base.start_service()

