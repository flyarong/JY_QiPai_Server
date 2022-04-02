--
-- Author: wss
-- Date: 2018/11/16
-- Time: 18:28
-- 说明：vip 推广奖励领取记录的数据
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local PROTECTED = {}


local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

--local reward_task_record_data = {}

function PROTECTED.init_data()

	return true
end


--- 只有新增
function CMD.add_player_vip_generalize_extract_record(_player_id , _extract_value , _extract_time )
	
	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_extract_value = %s;
								SET @_extract_time = %s;
								insert into player_vip_generalize_extract_record 
								(player_id,extract_value,extract_time)
								values(@_player_id,@_extract_value,@_extract_time);]]
							,_player_id
							,_extract_value
							,_extract_time
							)

	base.DATA.sql_queue_slow:push_back(sql)

end

---- 查询 一个玩家的推广提取记录
function CMD.get_player_vip_generalize_extract_record( player_id , page_index , page_item_num , _offset )
	local sql = string.format([[
								SELECT * FROM player_vip_generalize_extract_record as TEM 
									where TEM.player_id = '%s' ORDER BY extract_time DESC LIMIT %d, %d ;
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