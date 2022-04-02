--
-- Author: lyx
-- Date: 2018/10/9
-- Time: 15:14
-- 说明：托管 agent 的公共功能
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
require"printfunc"
local nodefunc = require "nodefunc"

local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC

-- 座位数
DATA.seat_count = nil

-- 游戏信息：游戏模式、游戏类型等
DATA.game_info = nil

--[[ 房间信息
    game_id=,
    t_num=桌子号,
    seat_num=座位号,
    init_stake=,
    init_rate=,
--]]
DATA.room_info = nil

--[[ 所有玩家，以 座位号 为 键
 数据： {
	 seat_num=,
	 id=玩家id,
	 name=,
	 head_link=,
	 sex=,
	 score=游戏中的分数
	}
]]
DATA.players_info = nil

DATA.ddz_data = {}

local PROTECTED = {}

-- 
function PROTECTED.init(_game_info)

	DATA.game_info = _game_info

	DATA.seat_count = GAME_TYPE_SEAT[_game_info.game_type]

end

function PUBLIC.on_enter_room(_room_info,_players_info)

	print("agent common on_enter_room:",DATA.player_id)

	DATA.room_info =_room_info
	DATA.players_info = _players_info
	
end

function PUBLIC.on_player_enter(_p_info)

	DATA.players_info[_p_info.seat_num]=_p_info
end


function PUBLIC.on_player_leave(_seat_num)

	DATA.players_info[_seat_num]=nil
	
end


function PUBLIC.ddz_is_my_permit(_cur_p)
	-- 0 : 所有人
	-- 4 : 所有的农民
	-- 5 : 地主

	local D = DATA.ddz_nor_data

	if 0 == _cur_p then
		return true
	elseif DATA.room_info and 4 == _cur_p and D.s_info.dizhu ~= DATA.room_info.seat_num then
		return true
	elseif DATA.room_info and 5 == _cur_p and D.s_info.dizhu == DATA.room_info.seat_num then
		return true
	elseif DATA.room_info then
		return _cur_p == DATA.room_info.seat_num
	else
		return false
	end
end

return PROTECTED
