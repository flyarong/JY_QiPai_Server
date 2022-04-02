--
-- Author: wss
-- Date: 2018/11/16
-- Time: 16:35
-- 说明：vip 推广的数据存储
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

--- 查找所有的vip推广数据
function CMD.query_all_generalize_data()
	local ret_data = {}

	local sql = "select * from player_vip_generalize;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]
		ret_data[row.player_id] = row
	end

	return ret_data
end

---- 更新 or 新增 vip推广
function CMD.update_or_add_player_vip_generalize(_player_id , _award_value , _today_get_award , _last_get_time , _total_award_value )
	
	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_award_value = %s;
								SET @_today_get_award = %s;
								SET @_last_get_time = %s;
								SET @_total_award_value = %s;
								insert into player_vip_generalize
								(player_id,award_value,today_get_award,last_get_time,total_award_value)
								values(@_player_id,@_award_value,@_today_get_award,@_last_get_time,@_total_award_value)
								on duplicate key update
								player_id = @_player_id,
								award_value = @_award_value,
								today_get_award = @_today_get_award,
								last_get_time = @_last_get_time,
								total_award_value = @_total_award_value;]]
							,_player_id
							,_award_value
							,_today_get_award
							,_last_get_time
							,_total_award_value
							)

	base.DATA.sql_queue_slow:push_back(sql)

end

return PROTECTED