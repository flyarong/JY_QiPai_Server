--
-- Author: lyx
-- Date: 2018/4/19
-- Time: 19:59
-- 说明：玩家 活动 的数据存储
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local PROTECTED = {}

local LOCAL_FUNC = {}

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA


function PROTECTED.init_data()

	return true
end

--- 请求所有玩家的 累胜活动 数据
function CMD.query_all_player_activity_cumulate_data()
	local sql = "select * from activity_cumulate_data;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	local data = {}
	for i = 1,#ret do
		local row = ret[i]
		
		data[row.player_id] = row
	end

	return data
end

--- 新增or更新 累胜活动数据
function CMD.add_or_update_activity_cumulate_data(_player_id , _game_id , _progress , _time)
	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_game_id = %s;
								SET @_progress = %s;
								SET @_time = %s;
								insert into activity_cumulate_data
								(player_id,game_id,progress,time)
								values(@_player_id,@_game_id,@_progress,@_time)
								on duplicate key update
								player_id = @_player_id,
								game_id = @_game_id,
								progress = @_progress,
								time = @_time;]]
							,_player_id
							,_game_id
							,_progress
							,_time
							)

	base.DATA.sql_queue_slow:push_back(sql)

end








return PROTECTED