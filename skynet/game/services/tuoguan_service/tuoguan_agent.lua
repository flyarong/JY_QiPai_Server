--[[
 Author: lyx
 Date: 2018/10/9
 Time: 15:13
 说明：托管代理服务

 需求整理：
 	1、快速进入功能：只准备，处于待命状态；收到 进入 某个场次指令，立即进入。
	2、调整 参数，以便能进入相应场次
	3、启动时随机决定自己的性格。
		可配置(nodefunc.get_global_config)：
			性格：活跃 一般 冷漠
			哪种性格 的 概率
			每种性格 各行为的概率：
				主动发言：赞队友、猪队友；上家超时 催促；随机发言；
				应答发言
 -]]

require"printfunc"
local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"
local land = require "land.core"

require "normal_enum"

require "tuoguan_service.tuoguan_enum"

local common = require "tuoguan_service.agent_common"

-- 接受 player_agent 发向客户端的消息
local MSG = {}

local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC

local function error_handle(msg)
	print(tostring(msg) .. ":\n" .. tostring(debug.traceback()))
	return msg
end

local node_name = skynet.getenv("my_node_name")

-- 登录成功后返回的数据
DATA.login_data = nil

-- 玩家 ID
DATA.player_id = nil

-- 登录 id
DATA.login_id = nil

local update_timer

-- 伪装的网关连接
local pretend_gate_link =
{
	node = node_name,
	addr = skynet.self(),
	client_id = 1,			-- 目前始终是 1
}

-- 当前运行的游戏模式
local current_model = nil

local function login(_user_data)

	-- 按 robot 方式登录（以后 可以增加 或改成 专门的登录方式，例如 "tuoguan"）
	local login_data = {
		channel_type="robot",
		login_id=_user_data.id,
		channel_args=_user_data.json,
		device_os="[tuoguan service] linux",
		device_id="[tuoguan service] heheh-lilili-HHHHHHHHHHHHHH",
	}
	local ok , ret = pcall(skynet.call,DATA.service_config.login_service,"lua","client_login",
		login_data,pretend_gate_link,"<tuoguan_service>")
	if ok then
		DATA.login_data = ret
		if DATA.login_data.result ~= 0 then
			print(string.format("tuoguan service login error:result id %s!",tostring(DATA.login_data.result)))
			return false
		end
	else
		print("tuoguan login error:",tostring(ret))
		return false
	end

	DATA.player_id = DATA.login_data.user_id
	DATA.login_id = _login_id

	return true

end


local _respones_id = 0
local function gen_response_id()

	_respones_id = _respones_id + 1

	return _respones_id
end

-- 等待回应的请求
local waitting_response = {}

local function heartbeat_update()

	PUBLIC.send_to_agent("heartbeat")
end

-- 发送消息到 player agent （无返回信息）
function PUBLIC.send_to_agent(_name,_data)


	nodefunc.send(DATA.player_id,"request",_name,_data,nil)
end

-- 调用 player agent （ 有返回信息）
function PUBLIC.request_agent(_name,_data)

	local _resp_id = gen_response_id()

	waitting_response[_resp_id] = {thread = coroutine.running()}

	nodefunc.send(DATA.player_id,"request",_name,_data,_resp_id)

	-- 等待回应
	skynet.wait(coroutine.running())

	local resp_data = waitting_response[_resp_id].respones
	waitting_response[_resp_id] = nil

	return resp_data
end

-- 收到 player agent 发来的 response
function CMD.response_client(client_id,responeId,data)
	local _resp = waitting_response[responeId]
	if _resp then
		_resp.respones = data
		skynet.wakeup(_resp.thread)
	end
end

-- 进入游戏
function CMD.enter_game(_game_info)

	if current_model then
		print("error:game is starting:",basefunc.tostring(DATA.game_info))
	end

	common.init(_game_info)

	current_model = require(TUOGUAN_MODEL[_game_info.match_name])

	require("tuoguan_service.behaviour").init()
	
	current_model.start_game()

	if not update_timer then
		update_timer = skynet.timer(1,heartbeat_update)
	end
end

function PUBLIC.safe_destroy_model()
	if current_model then

		if current_model.destroy then
			current_model.destroy()
		end

		current_model = nil
		
	end
end

-- 从游戏中退出
function PUBLIC.quit_game()

	PUBLIC.safe_destroy_model()

	PUBLIC.send_to_agent("player_quit")

end


local error_msg_names = {}

-- 收到 player agent 发来的消息
function CMD.request_client(client_id,name,data,...)

	local bh = require("tuoguan_service.behaviour")
	--local ok,err = xpcall(base.import("game/services/tuoguan_service/behaviour.lua").monitor_msg,error_handle,name,data)
	local ok,err = xpcall(bh.monitor_msg,error_handle,name,data)
	if not ok then
		print(string.format("behaviour.monitor_msg error,msg:%s,err:%s",tostring(name),tostring(err)))
	end


	-- 分发消息： 优先发给 当前游戏模块
	if not current_model or not current_model.dispatch_msg(name,data,...) then
		local f = MSG[name]
		if f then
			f(data,...)
		-- else
		-- 	if not error_msg_names[name] then
		-- 		print("tuoguan agent error: not found MSG:",name)
		-- 		error_msg_names[name] = true
		-- 	end
		end
	end
end

function MSG.will_kick_reason(_data)
	
end


function MSG.notify_asset_change_msg(_data)
	if not _data or not _data.player_asset then
		return
	end

	if not DATA.login_data then
		DATA.login_data ={}
		DATA.login_data.player_asset ={}
	end
	DATA.login_data.player_asset = _data.player_asset

end

function CMD.exit_client()

	PUBLIC.safe_destroy_model()

	nodefunc.destroy(DATA.my_id)

	skynet.exit()
end

-- 踢下用户，销毁 本服务
function CMD.kick_client(_id,_call_event)

	print("CMD.kick_client:",DATA.my_id,DATA.player_id)
	
	-- 退出自己
	CMD.exit_client()	

end

function CMD.start(_my_id,_service_config,_user_data)

	DATA.my_id = _my_id
	DATA.service_config = _service_config

	base.set_hotfix_file("fix_tuoguan_agent")

	if login(_user_data) then

		print("tuoguan login succ:",DATA.my_id,DATA.player_id)

		-- 心跳
		update_timer = skynet.timer(1,heartbeat_update)

		return DATA.login_data
	else
		skynet.timeout(2,CMD.exit_client)
		return nil
	end
end




-- 启动服务
base.start_service()
