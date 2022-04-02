--
-- Author: yy
-- Date: 2018-9-6 20:44:19
-- 说明：普通比赛场的数据存储
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
require "data_func"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECTED = {}

local match_max_id = 0
local statistics_player_match_rank_data = {}

-- 初始化比赛数据
function PROTECTED.init_data()

	local sql = "SELECT MAX(id) from freestyle_race_log;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	match_max_id = ret[1]["MAX(id)"] or 0

	return true
end


-- 产生一个比赛实例的id
function base.CMD.gen_freestyle_race_id()

	match_max_id = match_max_id + 1

	return match_max_id

end


function base.CMD.add_freestyle_race_log(_log)

	-- 写入数据库
	base.DATA.sql_queue_slow:push_back(
		PUBLIC.format_sql([[insert into freestyle_race_log
					(id,game_id,name,game_type,begin_time,end_time,player_count,races)
					values(%s,%s,%s,%s,FROM_UNIXTIME(%s),FROM_UNIXTIME(%s),%s,%s);
				]]
		,_log.id,_log.game_id,_log.name,_log.game_type,_log.begin_time
		,_log.end_time,_log.player_count,table.concat(_log.races,",")
	))

end


function base.CMD.add_freestyle_race_player_log(_logs)

	for i,_log in ipairs(_logs) do
		base.DATA.sql_queue_slow:push_back(
			PUBLIC.format_sql([[insert into freestyle_race_player_log
							(player_id,match_id,score,real_score,room_rent)
							values(%s,%s,%s,%s,%s);
			]]
			,_log.player_id,_log.match_id,_log.score,_log.real_score,_log.room_rent)
		)
	end

end



return PROTECTED