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

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local glory_data = {}


function PROTECTED.init_data()

	local sql = "select * from player_glory;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]
		
		glory_data[row.player_id] = row

	end

	return true
end



function CMD.query_player_glory_data(_player_id)

	return glory_data[_player_id] or {
		player_id = _player_id,
		level = 1,
		score = 0,
	}

end

function CMD.update_player_glory_data(_player_id,_level,_score)

	local pgd = CMD.query_player_glory_data(_player_id)
	glory_data[_player_id] = pgd

	pgd.level = _level or pgd.level
	pgd.score = _score or pgd.score

	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_level = %s;
								SET @_score = %s;
								insert into player_glory
								(player_id,level,score)
								values(@_player_id,@_level,@_score)
								on duplicate key update
								level = @_level,
								score = @_score;]]
							,_player_id
							,pgd.level
							,pgd.score)

	base.DATA.sql_queue_slow:push_back(sql)

end




return PROTECTED