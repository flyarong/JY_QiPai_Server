--
-- Author: lyx
-- Date: 2018/4/19
-- Time: 19:59
-- 说明：斗地主的数据存储
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local PROTECTED = {}

local LOCAL_FUNC = {}

--最大对局日志id
local freestyle_nmjxl_mj_log_max_id = 0


PROTECTED.statistics_player_data = {}
local statistics_player_data = PROTECTED.statistics_player_data


-- 初始化玩家斗地主自由场数据
function PROTECTED.init_player_nmjxl_freestyle()

	LOCAL_FUNC.init_freestyle_nmjxl_race_log_max_id()
	LOCAL_FUNC.init_statistics_player_data()

	return true
end



--初始化id
function LOCAL_FUNC.init_freestyle_nmjxl_race_log_max_id()
	local sql = "SELECT MAX(id) FROM freestyle_nmjxl_race_log;"
	local ret = base.DATA.db_mysql:query(sql)

	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	freestyle_nmjxl_mj_log_max_id = ret[1]["MAX(id)"] or 0

end



--[[ 添加比赛对局日志 返回插入的id
	id
	game_id
	game_model
	begin_time
	end_time
	gang_count
	geng_count
	base_score
	operation_list
	zhuang_seat
	seat1_user
	seat2_user
	seat3_user
	seat4_user

	id
	player_id
	race_id
	seat
	score
	multi
	gang_info
	pai_info

]]
function base.CMD.add_freestyle_nmjxl_race_log(_game_id,_begin_time,_end_time,_gang_count,_geng_count,_base_score,_operation_list,_zhuang_seat,_players,_game_model)
	
	freestyle_nmjxl_mj_log_max_id = freestyle_nmjxl_mj_log_max_id + 1

	-- 对局表 freestyle_nmjxl_race_log 的
	local sqls = {string.format([[insert into freestyle_nmjxl_race_log
		(id,game_id,begin_time,end_time,gang_count,
		geng_count,base_score,operation_list,zhuang_seat,seat1_user,seat2_user,seat3_user,seat4_user,game_model)
		values(%u,%u,FROM_UNIXTIME(%u),FROM_UNIXTIME(%u),%d,%d,%d,x'%s',%d,'%s','%s','%s','%s','%s');]],
		freestyle_nmjxl_mj_log_max_id,_game_id,_begin_time,_end_time,_gang_count,_geng_count,
		_base_score,basefunc.tohex(_operation_list),_zhuang_seat,
		_players[1].player_id,_players[2].player_id,_players[3].player_id,_players[4].player_id,_game_model
	)}

	-- 每个玩家 freestyle_nmjxl_race_player_log
	for i=1,4 do
		local _pdata = _players[i]
		sqls[#sqls + 1] = string.format([[insert into freestyle_nmjxl_race_player_log
						(player_id,race_id,seat,score,multi,gang_info,pai_info)
						values('%s',%u,%d,%d,%d,'%s','%s');]],
			_pdata.player_id,freestyle_nmjxl_mj_log_max_id,i,_pdata.score,
			_pdata.multi,_pdata.gang_info,_pdata.pai_info)
	end

	base.DATA.sql_queue_slow:push_back(table.concat(sqls))
	
	return freestyle_nmjxl_mj_log_max_id
end





-- 统计相关 ***************
--[[
{
	id = _player_id,
	win_count = win_count,
	defeated_count = defeated_count,
}
]]
function LOCAL_FUNC.init_statistics_player_data()

	local sql = "select * from statistics_player_freestyle_mjxl"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]
		statistics_player_data[row.id]=row
	end

end


function base.CMD.update_statistics_player_freestyle_mjxl(_player_id,_data)

	statistics_player_data[_player_id]=_data

	base.DATA.sql_queue_slow:push_back(
		string.format([[
						SET @_player_id = '%s';
						SET @_win_count = %d;
						SET @_defeated_count = %d;

						insert into statistics_player_freestyle_mjxl
						(id,
						win_count,
						defeated_count)

						values						
						(@_player_id,
						@_win_count,
						@_defeated_count)

						on duplicate key update 
						id = @_player_id,
						win_count = @_win_count,
						defeated_count = @_defeated_count;
						]],
						_data.id,
						_data.win_count,
						_data.defeated_count)
	)

end


function base.CMD.get_statistics_player_freestyle_mjxl(_player_id)
	return statistics_player_data[_player_id] or 
	{
		id = _player_id,
		win_count = 0,
		defeated_count = 0,
	}

end



return PROTECTED