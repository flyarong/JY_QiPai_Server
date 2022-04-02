--
-- Author: lyx
-- Date: 2018/10/10
-- Time: 10:52
-- 说明：自由场模式 的托管逻辑
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

-- 自己是否发送了准备
local self_ready = false

--已完成几把牌
local over_round_count = 0

--PROTECTED["gamer_money"] = {}

-- 状态定义
local status =
{
	init = {}, -- 初始状态

	signuping = {}, -- 报名中
	signuped = {},-- 报名成功
	join = {}, -- 加入房间
	gaming = {},-- 游戏中
	ready = {}, -- 准备中：等待所有人准备好

	waiting = {},-- 等待状态，通常用于过度
	quit = {},-- 退出游戏
}
for _name,_data in pairs(status) do -- 加入名字，方便调试
	_data.name = _name
end

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

	over_round_count = 0

	PUBLIC.quit_game()
end

function status.signuping.on_begin()

	skynet.timeout(30,function ()

		local xsyd = nil
		--xsyd
		if DATA.game_info.game_tag == "xsyd" then
			xsyd = 1
		end

		local ret = PUBLIC.request_agent("fg_signup",{id=DATA.game_info.game_id,xsyd=xsyd})

		if ret.result ~= 0 then
			print(string.format("tuoguan fg_signup ,user id=%s ,game id=%s, error:%s",tostring(DATA.player_id),tostring(DATA.game_info.game_id),tostring(ret.result)))

			PUBLIC.send_to_agent("fg_quit_game")
			change_status(status.quit)
			return
		end

		print("xxxxxxxxxxxxx tuoguan fg_signup succ:",DATA.player_id,DATA.game_info.game_id)

		DATA.game_info.jdz_type = ret.jdz_type

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

		print("xxxxxxxxxxxxxxxxxx status.signuped.update quit:",DATA.player_id)
		local ret = PUBLIC.request_agent("fg_quit_game")
		if ret.result == 0 then
			change_status(status.quit)
		end
	end
end

function status.ready.update(dt)

	-- 完成一局后，太久没准备好，则 退出
	if over_round_count > 0 and status_dur > 15 then

		print("xxxxxxxxxxxxxxxxxx status.ready.update quit:",DATA.player_id)
		local ret = PUBLIC.request_agent("fg_quit_game")
		if ret.result == 0 then
			change_status(status.quit)
		end
	end
end


function MSG.fg_ready_msg(_data)

	if not self_ready then

		local _rand
		if 2 == DATA.seat_count then
			_rand = 20
		elseif 4 == DATA.seat_count then
			_rand = 10
		else
			_rand = 15
		end

		if math.random(100) < _rand  or PUBLIC.request_agent("fg_ready").result ~= 0 then
			print("xxxxxxxxxxxxxxxxxx MSG.fg_ready_msg quit:",DATA.player_id)
			local ret = PUBLIC.request_agent("fg_quit_game")
			if ret.result == 0 then
				self_ready = true
				change_status(status.quit)
			end
		end
	end

end

function MSG.fg_enter_room_msg(_data)

	PUBLIC.on_enter_room(_data, _data.players_info)

	game_type_module.on_join_room(_data)

	change_status(status.join)
end

function MSG.fg_join_msg(_data)
	PUBLIC.on_player_enter(_data.player_info)
end

function MSG.fg_leave_msg(_data)
	PUBLIC.on_player_leave(_data.seat_num)
end

function MSG.fg_gameover_msg(_data)

	over_round_count = over_round_count + 1
	self_ready = false

	print("tuoguan freestyle gameover:",DATA.player_id,over_round_count)

	change_status(status.ready)

end

-- 被踢出
function MSG.fg_auto_quit_game_msg(_data)

	print("xxxxxxxxxxxxxxxxxx fg_auto_quit_game_msg:",DATA.player_id)

	PUBLIC.request_agent("fg_quit_game")
	change_status(status.quit)

end

function PUBLIC.on_begin_msg(_cur_race)
	change_status(status.gaming)

end

local function get_condi_range(_condi,_type)

	local _m1,m2

	for i,v in ipairs(_condi) do
		if v.asset_type == _type then
			if v.condi_type == NOR_CONDITION_TYPE.GREATER or v.condi_type == NOR_CONDITION_TYPE.CONSUME then
				m1 = math.max(v.value,m1 or v.value)
			elseif v.condi_type == NOR_CONDITION_TYPE.LESS then
				m2 = math.min(v.value,m2 or v.value)
			elseif v.condi_type == NOR_CONDITION_TYPE.EQUAL then
				return v.value,v.value
			end
		end
	end

	return m1,m2
end

-- 确保托管的 钱在给定的范围
local function adjust_money()

	local  ok,condi = nodefunc.call( DATA.game_info.service_id,"get_enter_info",DATA.game_info.game_id )
	if 0 ~= ok then
		print("tuoguan get_enter_info error:",tostring(condi))
		return false
	end

	local _money1,_money2 = get_condi_range(condi["condi_data"],PLAYER_ASSET_TYPES.JING_BI)
	print("tuoguan freestyle enter condi(game id,player,money1,money2):",DATA.game_info.game_id,DATA.player_id,_money1,_money2)

	if not _money1 and not _money2 then
		return true -- 不用调节
	end


	local _jing_bi = nodefunc.call(DATA.player_id,"query_asset_by_type",PLAYER_ASSET_TYPES.JING_BI)
	print("tuoguan freestyle enter(player,money):",DATA.player_id,_jing_bi)
	if "CALL_FAIL" == _jing_bi then
		
		return false
	end

	if _jing_bi >= (_money1 or 0) and _jing_bi <= (_money2 or math.maxinteger) then
		return true
	end
	
	_money1 = _money1 or 0
	_money2 = _money2 or (_money1 + 300000)

    if _jing_bi < _money1 or _jing_bi > _money2 then
		local _inc_value = math.random(_money1,_money2)-_jing_bi
		print("tuoguan freestyle enter change money(money,player,change):",_jing_bi+_inc_value,DATA.player_id,_inc_value)
        nodefunc.call(DATA.player_id,"change_asset_multi",{{asset_type=PLAYER_ASSET_TYPES.JING_BI,value=_inc_value}},
            ASSET_CHANGE_TYPE.TUOGUAN_ADJUST,"0")
	end
	
	return true
end


function PROTECTED.start_game()

	if game_type_module then
		game_type_module.destroy()
		game_type_module = nil
	end

	if not adjust_money() then
		return
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
