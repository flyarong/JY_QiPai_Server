--
-- Author: wss
-- Date: 2018/12/11
-- Time: 19:59
-- 说明 玩家步步生财数据
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local PROTECTED = {}

local LOCAL_FUNC = {}

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local ob_data = {}

function PROTECTED.init_data()

	local sql = "select * from player_stepstep_money;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end


	for i = 1,#ret do
		local row = ret[i]
		ob_data[row.player_id] = row
	end

	return true
end



function CMD.query_player_stepstep_money(_player_id)

	return ob_data[_player_id]
end

function CMD.update_player_stepstep_money(_player_id,_now_big_step,_now_little_step,_last_op_time,_can_do_big_step , _bbsc_version , _over_time )
	ob_data[_player_id] = ob_data[_player_id] or {}
	ob_data[_player_id].player_id = _player_id
	ob_data[_player_id].now_big_step = _now_big_step
	ob_data[_player_id].now_little_step = _now_little_step
	ob_data[_player_id].last_op_time = _last_op_time
	ob_data[_player_id].can_do_big_step = _can_do_big_step
	ob_data[_player_id].bbsc_version = _bbsc_version
	ob_data[_player_id].over_time = _over_time

	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_now_big_step = %s;
								SET @_now_little_step = %s;
								SET @_last_op_time = %s;
								SET @_can_do_big_step = %s;
								SET @_bbsc_version = '%s';
								SET @_over_time = %s;
								insert into player_stepstep_money
								(player_id,now_big_step,now_little_step,last_op_time,can_do_big_step, bbsc_version , over_time )
								values(@_player_id,@_now_big_step,@_now_little_step,@_last_op_time,@_can_do_big_step , @_bbsc_version , @_over_time )
								on duplicate key update
								player_id = @_player_id,
								now_big_step = @_now_big_step,
								now_little_step = @_now_little_step,
								last_op_time = @_last_op_time,
								can_do_big_step = @_can_do_big_step,
								bbsc_version = @_bbsc_version,
								over_time = @_over_time;]]
							,_player_id
							,_now_big_step
							,_now_little_step
							,_last_op_time
							,_can_do_big_step
							,_bbsc_version
							,_over_time
							)

	base.DATA.sql_queue_slow:push_back(sql)

end



return PROTECTED