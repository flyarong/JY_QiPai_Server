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

-- 初始化
function PROTECTED.init_data()

	return true
end



function CMD.query_freestyle_activity_all_player_data()

	local sql = "SELECT * from freestyle_activity_player_data;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	return ret

end

function CMD.update_freestyle_activity_player_data(_data)

	-- 写入数据库
	base.DATA.sql_queue_slow:push_back(
		PUBLIC.format_sql([[
								SET @_player_id = %s;
								SET @_game_id = %s;
								SET @_activity_id = %s;
								SET @_index = %s;
								SET @_data = %s;
								insert into freestyle_activity_player_data
								(player_id,game_id,activity_id,`index`,data)
								values(@_player_id,@_game_id,@_activity_id,@_index,@_data)
								on duplicate key update
								data = @_data;]],
								_data.player_id,
								_data.game_id,
								_data.activity_id,
								_data.index,
								_data.data
	))

end



function CMD.delete_freestyle_activity_player_data(_data)

	-- 写入数据库
	base.DATA.sql_queue_slow:push_back(
		PUBLIC.format_sql([[
								delete from freestyle_activity_player_data
								where game_id = %s and activity_id = %s and `index` = %s]],
								_data.game_id,
								_data.activity_id,
								_data.index
	))

end

function CMD.get_freestyle_activity_log_id()
	return PUBLIC.auto_inc_id("freestyle_activity_log_id")
end

function CMD.insert_freestyle_activity_log(_log)
	--local id = PUBLIC.auto_inc_id("freestyle_activity_log_id")
	-- 写入数据库
	base.DATA.sql_queue_slow:push_back(
		PUBLIC.format_sql([[insert into freestyle_activity_log
					(id,game_id,activity_id,name,activity_data,start_time,begin_time,end_time,over_time)
					values(%s,%s,%s,%s,%s,FROM_UNIXTIME(%s),FROM_UNIXTIME(%s),FROM_UNIXTIME(%s),FROM_UNIXTIME(%s));
				]],
		_log.id,_log.game_id,_log.activity_id,_log.name,_log.activity_data,_log.start_time,_log.begin_time,_log.end_time,_log.over_time
	))

end



function CMD.insert_freestyle_activity_player_log(_log)

	-- 写入数据库
	base.DATA.sql_queue_slow:push_back(
		PUBLIC.format_sql([[insert into freestyle_activity_player_log
					(id,player_id,game_id,activity_id,name,activity_data,award,time)
					values(NULL,%s,%s,%s,%s,%s,%s,FROM_UNIXTIME(%s));
				]],
		_log.player_id,_log.game_id,_log.activity_id,_log.name,_log.activity_data,_log.award,_log.time
	))

end


return PROTECTED