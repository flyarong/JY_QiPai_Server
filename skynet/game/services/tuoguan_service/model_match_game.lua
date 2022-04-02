--
-- Author: lyx
-- Date: 2018/10/10
-- Time: 10:52
-- 说明：比赛场模式 的托管逻辑
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"

require "normal_enum"

require"printfunc"

local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC

-- 游戏玩法模块
local game_type_module

local PROTECTED = {}
local MSG = {}

-- 房间信息
DATA.room_info = nil

-- 玩家信息，按座位索引
DATA.players_info = {}

-- 状态定义
local status = 
{
	init = {}, -- 初始状态

	signuping = {}, -- 报名中
	signuped = {},-- 报名成功
	join = {}, -- 加入房间
	gaming = {},-- 游戏中

	waiting = {},-- 等待状态，通常用于过度
	quit = {},-- 退出游戏
}
for _name,_data in pairs(status) do -- 加入名字，方便调试
	_data.name = _name
end
-- 用户金币
--PROTECTED["gamer_money"] = {}
-- 更新时钟
local update_timer 

-- 当前状态
local cur_status = status.init

local status_cd = nil
local next_status = nil
local status_dur = 0 -- 当前状态计时

-- 切换状态
function PUBLIC.change_status(_status,_time,_next)

	if cur_status then
		if cur_status.on_end then
			cur_status.on_end()
		end
	end

	cur_status = _status

	status_dur = 0

	

	if cur_status.on_begin then
		cur_status.on_begin()
	end

	if _time and _next then
		status_cd = _time
		next_status = _next
	else
		status_cd = nil
	end

end

local change_status = PUBLIC.change_status

function PUBLIC.cur_status()
	return cur_status
end

local function update(dt)

	status_dur = status_dur + dt

	if status_cd then
		status_cd = status_cd - dt
		if status_cd <= 0 then
			status_cd = nil
			change_status(next_status)
		end
	end

	if cur_status and cur_status.update then
		cur_status.update(dt)
	end

end

function status.quit.on_begin()

	PUBLIC.quit_game()
end

function status.signuping.on_begin()

	skynet.timeout(30,function ()
		local ret = PUBLIC.request_agent("nor_mg_signup",{id=DATA.game_info.game_id})
		if ret.result ~= 0 then
			print(string.format("tuoguan nor_mg_signup ,id=%s, error:%s",tostring(DATA.game_info.game_id),tostring(ret.result)))

			PUBLIC.send_to_agent("nor_mg_quit_game")
			change_status(status.quit)
			return
		end
		
		change_status(status.signuped)
	end)

end

function status.signuped.on_begin()
	status.signuped.sended_cancel = false
end

function status.signuped.update(dt)

	-- 报名成功太久没开始游戏，则 退出
	if not status.signuped.sended_cancel and status_dur > 300 then

		status.signuped.sended_cancel = true

		local ret = PUBLIC.request_agent("nor_mg_cancel_signup")
		if ret.result == 0 then
			PUBLIC.send_to_agent("nor_mg_quit_game")
			change_status(status.quit)
		end
	end
end

function MSG.nor_mg_enter_room_msg(_data)
	
	PUBLIC.on_enter_room(_data, _data.players_info)

	game_type_module.on_join_room(_data)

	change_status(status.join)
end

function MSG.nor_mg_join_msg(_data)
	PUBLIC.on_player_enter(_data.player_info)
end

function MSG.nor_mg_gameover_msg(_data)

	print("tuoguan freestyle gameover:",DATA.player_id)

	change_status(status.quit)

end

-- 被踢出
function MSG.nor_mg_auto_cancel_signup_msg(_data)

	PUBLIC.request_agent("nor_mg_quit_game")
	change_status(status.quit)

end

function PUBLIC.on_begin_msg(_cur_race)
	change_status(status.gaming)
end


function PROTECTED.start_game()

	if game_type_module then
		game_type_module.destroy()
		game_type_module = nil
	end

	game_type_module = require(TUOGUAN_GAME[DATA.game_info.game_type])

	game_type_module.start_game()

	change_status(status.signuping)

	if update_timer then
		update_timer:stop()
		update_timer = nil
	end

	update_timer = skynet.timer(0.2,update)

end

function PROTECTED.destroy()

	if game_type_module then
		game_type_module.destroy()
		game_type_module = nil
	end

	if update_timer then
		update_timer:stop()
	end
	update_timer = nil

end

function PROTECTED.dispatch_msg(_name,_data,...)
	
	if game_type_module and game_type_module.dispatch_msg(_name,_data,...) then
		return true
	end

	local f = MSG[_name]
	if f then
		f(_data)
		return true
	else
		return false
	end
end




return PROTECTED