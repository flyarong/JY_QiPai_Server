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
local freestyle_tyddz_race_log_max_id = 0


PROTECTED.statistics_player_freestyle_tyddz_data = {}
local statistics_player_freestyle_tyddz_data = PROTECTED.statistics_player_freestyle_tyddz_data


-- 初始化玩家斗地主自由场数据
function PROTECTED.init_player_tyddz_freestyle()

	LOCAL_FUNC.init_freestyle_tyddz_race_log_max_id()

	LOCAL_FUNC.init_statistics_player_freestyle_tyddz()


	return true
end


--初始化id
function LOCAL_FUNC.init_freestyle_tyddz_race_log_max_id()
	local sql = "SELECT MAX(id) FROM freestyle_tyddz_race_log;"
	local ret = base.DATA.db_mysql:query(sql)

	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	freestyle_tyddz_race_log_max_id = ret[1]["MAX(id)"] or 0

end


-- 添加比赛对局日志 返回插入的id
function base.CMD.add_freestyle_tyddz_race_log(_game_id,_begin_time,_end_time,_bomb_count,_spring,_base_score,_base_rate,_operation_list,_dizhu_seat,_players,_game_model)
	
	freestyle_tyddz_race_log_max_id = freestyle_tyddz_race_log_max_id + 1

	-- 对局表 freestyle_tyddz_race_log 的
	local sqls = {string.format([[insert into freestyle_tyddz_race_log
		(id,game_id,begin_time,end_time,bomb_count,
		spring,base_score,base_rate,operation_list,dizhu_seat,seat1_user,seat2_user,seat3_user,game_model)
		values(%u,%d,FROM_UNIXTIME(%u),FROM_UNIXTIME(%u),%d,%d,%d,%d,x'%s',%d,'%s','%s','%s','%s');]],
		freestyle_tyddz_race_log_max_id,_game_id,_begin_time,_end_time,_bomb_count,_spring,
		_base_score,_base_rate,basefunc.tohex(_operation_list),_dizhu_seat,
		_players[1].player_id,_players[2].player_id,_players[3].player_id,_game_model
	)}

	-- 每个玩家 freestyle_tyddz_race_player_log
	for i=1,3 do
		local _pdata = _players[i]
		sqls[#sqls + 1] = string.format([[insert into freestyle_tyddz_race_player_log
						(player_id,race_id,seat,score,rate,bomb_count,spring)
						values('%s',%u,%d,%d,%d,%d,%d);]],
			_pdata.player_id,freestyle_tyddz_race_log_max_id,i,_pdata.score,
			_pdata.rate,_pdata.bomb_count,_pdata.spring)
	end

	base.DATA.sql_queue_slow:push_back(table.concat(sqls))
	
	return freestyle_tyddz_race_log_max_id
end





-- 统计相关 ***************
--[[
{
	id = _player_id,
	dizhu_win_count = _dizhu_win,
	nongmin_win_count = _nongmin_win,
}
]]

--[[记录玩家比赛

	数据库表： statistics_player_freestyle_tyddz

	id --玩家id

	练习场
	drivingrange_dizhu_win_count
	drivingrange_nongmin_win_count
	drivingrange_defeated_count

	钻石场
	diamond_field_dizhu_win_count
	diamond_field_nongmin_win_count
	diamond_field_defeated_count

]]

function LOCAL_FUNC.init_statistics_player_freestyle_tyddz()

	local sql = "select * from statistics_player_freestyle_tyddz"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]
		statistics_player_freestyle_tyddz_data[row.id]=row
	end

end


function base.CMD.update_statistics_player_freestyle_tyddz(_player_id,_data)

	statistics_player_freestyle_tyddz_data[_player_id]=_data

	base.DATA.sql_queue_slow:push_back(
		string.format([[
						SET @_player_id = '%s';
						SET @_dizhu_win_count = %d;
						SET @_nongmin_win_count = %d;
						SET @_defeated_count = %d;

						insert into statistics_player_freestyle_tyddz
						(id,
						dizhu_win_count,
						nongmin_win_count,
						defeated_count)

						values						
						(@_player_id,
						@_dizhu_win_count,
						@_nongmin_win_count,
						@_defeated_count)

						on duplicate key update 
						id = @_player_id,
						dizhu_win_count = @_dizhu_win_count,
						nongmin_win_count = @_nongmin_win_count,
						defeated_count = @_defeated_count;
						]],
						_data.id,
						_data.dizhu_win_count,
						_data.nongmin_win_count,
						_data.defeated_count)
	)

end


function base.CMD.get_statistics_player_freestyle_tyddz(_player_id)
	return statistics_player_freestyle_tyddz_data[_player_id] or 
	{
		id = _player_id,
		dizhu_win_count = 0,
		nongmin_win_count = 0,
		defeated_count = 0,
	}

end




return PROTECTED











