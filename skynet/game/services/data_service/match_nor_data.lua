--
-- Author: yy
-- Date: 2018-9-6 20:44:19
-- 说明：普通比赛场的数据存储
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECTED = {}

local match_max_id = 0
local statistics_player_match_rank_data = {}

-- 初始化比赛数据
function PROTECTED.init_data()

	local sql = "SELECT MAX(id) from match_nor_log;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	match_max_id = ret[1]["MAX(id)"] or 0

	
	PROTECTED.init_statistics_player_match_rank()

	return true
end


-- 产生一个比赛实例的id
function base.CMD.gen_match_nor_id()

	match_max_id = match_max_id + 1

	return match_max_id

end


function base.CMD.add_match_nor_log(_log)

	-- 写入数据库
	base.DATA.sql_queue_slow:push_back(
		string.format([[insert into match_nor_log
					(id,game_id,name,game_type,begin_time,end_time,player_count,races)
					values(%s,%s,'%s','%s',FROM_UNIXTIME(%u),FROM_UNIXTIME(%u),%d,'%s');
				]],
		_log.id,_log.game_id,_log.name,_log.game_type,_log.begin_time,_log.end_time,_log.player_count,table.concat(_log.races,",")
	))

end


function base.CMD.add_match_nor_player_log(_logs)

	for i,_log in ipairs(_logs) do
		base.DATA.sql_queue_slow:push_back(
			string.format([[insert into match_nor_player_log
							(player_id,match_id,score,rank,award)
							values('%s',%s,%d,%d,'%s');
			]],
			_log.player_id,_log.match_id,_log.score,_log.rank,_log.award)
		)
	end

end


function base.CMD.update_statistics_player_match_rank(_player_id,_rank)

	statistics_player_match_rank_data[_player_id] = base.CMD.get_statistics_player_match_rank(_player_id)

	if _rank == 1 then
		local cn = statistics_player_match_rank_data[_player_id].first
		statistics_player_match_rank_data[_player_id].first = cn + 1
	elseif _rank == 2 then
		local cn = statistics_player_match_rank_data[_player_id].second
		statistics_player_match_rank_data[_player_id].second = cn + 1
	elseif _rank == 3 then
		local cn = statistics_player_match_rank_data[_player_id].third
		statistics_player_match_rank_data[_player_id].third = cn + 1
	end

	base.DATA.sql_queue_slow:push_back(
		string.format([[
						SET @_player_id = '%s';
						SET @_first = %d;
						SET @_second = %d;
						SET @_third = %d;
						insert into statistics_player_match_rank
						(id,first,second,third)
						values(@_player_id,@_first,@_second,@_third)
						on duplicate key update 
						id = @_player_id,
						first = @_first,
						second = @_second,
						third = @_third;
						]],
						_player_id
						,statistics_player_match_rank_data[_player_id].first
						,statistics_player_match_rank_data[_player_id].second
						,statistics_player_match_rank_data[_player_id].third
						)
	)

end




--[[记录玩家比赛

	数据库表： statistics_player_match_rank

	id --玩家id
	dizhu_win_count
	nongmin_win_count
	defeated_count
	first
	second
	third
]]

function PROTECTED.init_statistics_player_match_rank()

	local sql = "select * from statistics_player_match_rank"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]
		statistics_player_match_rank_data[row.id]=row
	end

end




function base.CMD.get_statistics_player_match_rank(_player_id)
	return statistics_player_match_rank_data[_player_id] or 
	{
		id = _player_id,
		first = 0,
		second = 0,
		third = 0,
	}

end



return PROTECTED