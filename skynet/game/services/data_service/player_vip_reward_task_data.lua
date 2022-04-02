--
-- Author: wss
-- Date: 2018/11/13
-- Time: 19:03
-- 说明：vip 返奖任务的数据存储
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local PROTECTED = {}

local LOCAL_FUNC = {}

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

--local reward_task_data = {}

function PROTECTED.init_data()
	

	return true
end

--- 查找所有的vip用户
function CMD.query_all_reward_task_data()
	local reward_task_data = {}

	local sql = "select * from player_vip_reward_task;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]
		reward_task_data[row.player_id] = row
	end

	return reward_task_data
end

---- 更新 or 新增 vip信息
function CMD.update_or_add_player_vip_reward_task(_player_id , _reward_task_status , _last_op_time , _award_value , _total_get_award , _total_find_award )
	
	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_reward_task_status = %s;
								SET @_last_op_time = %s;
								SET @_award_value = %s;
								SET @_total_get_award = %s;
								SET @_total_find_award = %s;
								insert into player_vip_reward_task
								(player_id,reward_task_status,last_op_time,award_value,total_get_award,total_find_award)
								values(@_player_id,@_reward_task_status,@_last_op_time,@_award_value,@_total_get_award,@_total_find_award)
								on duplicate key update
								player_id = @_player_id,
								reward_task_status = @_reward_task_status,
								last_op_time = @_last_op_time,
								award_value = @_award_value,
								total_get_award = @_total_get_award,
								total_find_award = @_total_find_award;]]
							,_player_id
							,_reward_task_status
							,_last_op_time
							,_award_value
							,_total_get_award
							,_total_find_award
							)

	base.DATA.sql_queue_slow:push_back(sql)

end


return PROTECTED