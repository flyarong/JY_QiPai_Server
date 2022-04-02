--
-- Author: lyx
-- Date: 2018/4/19
-- Time: 19:59
-- 说明：玩家 任务 的数据存储
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

--- 请求所有玩家的任务数据
function CMD.query_all_player_task_data()
	local sql = "select * from player_task;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	local data = {}
	for i = 1,#ret do
		local row = ret[i]
		
		data[row.player_id] = data[row.player_id] or {}
		data[row.player_id][row.task_id] = row

	end

	return data
end

--[[function CMD.query_player_task(_player_id)
	
	return task_data[_player_id]

end--]]

function CMD.update_player_task( _player_id,_task_id,_process,_task_round,_create_time,_task_award_get_status)
	if _task_id == 201 then
		print("xxxxxxxxxxxxx------------update_data4:",201)
	end

	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_task_id = %s;
								SET @_process = %s;
								SET @_task_round = %s;
								SET @_create_time = %s;
								SET @_task_award_get_status = %s;
								insert into player_task
								(player_id,task_id,process,task_round,create_time,task_award_get_status)
								values(@_player_id,@_task_id,@_process,@_task_round,@_create_time,@_task_award_get_status)
								on duplicate key update
								player_id = @_player_id,
								task_id = @_task_id,
								process = @_process,
								task_round = @_task_round,
								create_time = @_create_time,
								task_award_get_status = @_task_award_get_status;]]
							,_player_id
							,_task_id
							,_process
							,_task_round
							,_create_time
							,_task_award_get_status)


	base.DATA.sql_queue_slow:push_back(sql)
	

end

function CMD.update_player_task_other_data(_player_id,_task_id,_other_data)
	local sql = string.format([[
								SET @_other_data = '%s';
								update player_task set 
								other_data = @_other_data
								where player_id = '%s' and task_id = %s;]]
							,_other_data
							,_player_id
							,_task_id
							)

	base.DATA.sql_queue_slow:push_back(sql)
end

function CMD.delete_player_task(_player_id,_task_id)

	local sql = string.format("delete from player_task where player_id='%s' and task_id=%s;"
								,_player_id,_task_id)

	DATA.sql_queue_slow:push_back(sql)

end

---- 写日志
function CMD.add_player_task_log(_player_id , _task_id , _progress_change , _now_progress )
	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_task_id = %s;
								SET @_progress_change = %s;
								SET @_now_progress = %s;
								insert into player_task_log 
								(player_id,task_id,progress_change,now_progress)
								values(@_player_id,@_task_id,@_progress_change,@_now_progress);]]
							,_player_id
							,_task_id
							,_progress_change
							,_now_progress
							)

	base.DATA.sql_queue_slow:push_back(sql)

end

------ 任务奖励日志
function CMD.add_player_task_award_log(_player_id , _task_id , _award_progress_lv , _award_asset_type , _award_asset_value)
	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_task_id = %s;
								SET @_award_progress_lv = %s;
								SET @_award_asset_type = '%s';
								SET @_award_asset_value = %s;
								insert into player_task_award_log 
								(player_id,task_id,award_progress_lv,award_asset_type,award_asset_value)
								values(@_player_id,@_task_id,@_award_progress_lv,@_award_asset_type,@_award_asset_value);]]
							,_player_id
							,_task_id
							,_award_progress_lv
							,_award_asset_type
							,_award_asset_value
							)

	base.DATA.sql_queue_slow:push_back(sql)
end



return PROTECTED