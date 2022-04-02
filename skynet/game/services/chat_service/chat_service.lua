--
-- Created by lyx.
-- User: hare
-- Date: 2018/7/5
-- Time: 15:06
-- 说明：聊天室服务
--

local skynet = require "skynet_plus"
local base = require "base"
local nodefunc = require "nodefunc"
local cluster = require "skynet.cluster"
local basefunc = require "basefunc"

require "printfunc"

local my_node_name = skynet.getenv("my_node_name")

local DATA = base.DATA
local PUBLIC = base.PUBLIC
local CMD = base.CMD

-- 聊天室。 room_id => {}
local chat_room = {}

local last_room_id = 0

local restart_signal_link = 
{
	node = my_node_name,
	addr = skynet.self(),
	cmd = "on_player_restart",
}

local disconnect_signal_link = 
{
	node = my_node_name,
	addr = skynet.self(),
	cmd = "on_player_disconnect",
}

function CMD.create_room()
	last_room_id = last_room_id + 1

	chat_room[last_room_id] = {players={}}
	return last_room_id
end

function CMD.destroy_room(_room_id)

	local r = chat_room[_room_id]
	if not r then
		return false
	end

	for _id,_data in pairs(r.players) do
		nodefunc.send(_id,"unbind_restart_signal",_data.restart_signal_id)
		nodefunc.send(_id,"unbind_disconnect_signal",_data.disconnect_signal_id)
	end

	chat_room[_room_id] = nil
end

function CMD.chat(_room_id,_sender,_cont)
	local r = chat_room[_room_id]
	if not r then
		return false
	end

	if string.len(_cont) > ((tonumber(skynet.getcfg("voice_max_len")) or 30) * 1024) then
		return false
	end

	for _id,_data in pairs(r.players) do

		if _data.gate_link then
			nodefunc.send_to_client(_data.gate_link,"recv_voice_chat",{player_id=_sender,data=_cont})
		end
	end

	return true
end
function CMD.easy_chat(_room_id,_sender,act_apt_player_id,parm)


	local r = chat_room[_room_id]
	if not r then
		return false
	end

	if string.len(parm) > ((tonumber(skynet.getcfg("voice_max_len")) or 30) * 1024) then
		return false
	end
	
	for _id,_data in pairs(r.players) do

		if _data.gate_link then

			nodefunc.send_to_client(_data.gate_link,"recv_player_easy_chat",{player_id=_sender,act_apt_player_id=act_apt_player_id,parm=parm})
		end
	end

	return true
end

function CMD.on_player_restart(_player_id,_gate_link,_room_id)

	local r = chat_room[_room_id]
	if r then
		local _data = r.players[_player_id]
		if _data then
			_data.gate_link = _gate_link
		end
	end
end

function CMD.on_player_disconnect(_player_id,_room_id)

	local r = chat_room[_room_id]
	if r then
		local _data = r.players[_player_id]
		if _data then
			_data.gate_link = nil
		end
	end
end

function CMD.join_room(_room_id,_player_id,_gate_link)

	local r = chat_room[_room_id]
	if not r then
		return false
	end

	r.players[_player_id] = {

		gate_link = _gate_link,

		-- 捕获 重新登录事件
		restart_signal_id = nodefunc.call(_player_id,"bind_restart_signal",restart_signal_link,_room_id),

		-- 捕获 断线事件
		disconnect_signal_id = nodefunc.call(_player_id,"bind_disconnect_signal",disconnect_signal_link,_room_id),
	}

	return true	
end

function CMD.exit_room(_room_id,_player_id)
	local r = chat_room[_room_id]
	if not r then
		return false
	end

	local _data = r.players[_player_id]

	if _data then
		nodefunc.call(_player_id,"unbind_restart_signal",_data.restart_signal_id)
		nodefunc.call(_player_id,"unbind_disconnect_signal",_data.disconnect_signal_id)
		r.players[_player_id] = nil
	end

	return true
end

function CMD.start(_service_config)

	DATA.service_config=_service_config

end

-- 启动服务
base.start_service()