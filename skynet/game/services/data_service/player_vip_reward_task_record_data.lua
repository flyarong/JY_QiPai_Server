--
-- Author: wss
-- Date: 2018/11/15
-- Time: 10:03
-- 说明：vip 返奖任务的每日记录 数据存储
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local PROTECTED = {}

local LOCAL_FUNC = {}

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

--local reward_task_record_data = {}

function PROTECTED.init_data()

	return true
end


--- 只有新增
function CMD.add_player_vip_reward_task_record(_player_id , _get_award_value , _status , _time )
	
	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_get_award_value = %s;
								SET @_status = %s;
								SET @_time = %s;
								insert into player_vip_reward_task_record
								(player_id,get_award_value,status,time)
								values(@_player_id,@_get_award_value,@_status,@_time);]]
							,_player_id
							,_get_award_value
							,_status
							,_time
							)

	base.DATA.sql_queue_slow:push_back(sql)

end

---- 查询 一个玩家的每日完成情况 ,page_index 第几页 ， page_item_num 每页的显示个数
function CMD.get_player_vip_reward_task_record_complete_info( player_id , page_index , page_item_num , _offset )
	local sql = string.format([[
								SELECT * FROM player_vip_reward_task_record as TEM 
									where TEM.player_id = '%s' and TEM.status != 3 ORDER BY time DESC LIMIT %d, %d ;
							]]
							,player_id
							,(page_index - 1)*page_item_num + _offset
							,page_item_num
							)

	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end
	return ret
end

---- 查询 一个玩家找回 or 领取找回的记录 ,page_index 第几页 ， page_item_num 每页的显示个数
function CMD.get_player_vip_reward_task_record_find_info( player_id , page_index , page_item_num , _offset )
	local sql = string.format([[
								SELECT * FROM player_vip_reward_task_record as TEM 
									where TEM.player_id = '%s' and (TEM.status = 1 or TEM.status = 3) ORDER BY time DESC LIMIT %d, %d ;
							]]
							,player_id
							,(page_index - 1)*page_item_num + _offset
							,page_item_num
							)

	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end
	return ret
end

return PROTECTED