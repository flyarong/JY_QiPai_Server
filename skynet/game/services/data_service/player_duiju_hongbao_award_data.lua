--
-- Author: wss
-- Date: 2018/11/14
-- Time: 17:11
-- 说明：对局红包每日领取奖励 的数据存储
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local PROTECTED = {}

local LOCAL_FUNC = {}

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local award_data = {}


function PROTECTED.init_data()
	local sql = "select * from player_duiju_hongbao_award;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]
		award_data[row.player_id] = row
	end

	return true
end

--- 查找所有的vip用户
function CMD.query_duiju_hongbao_award_data(player_id)
	return award_data[player_id]
end

---- 更新 or 新增 vip信息，允许传部分值
function CMD.update_or_add_duiju_hongbao_award(_player_id , _get_award_value  )
	award_data[_player_id] = award_data[_player_id] or {}
	local td = award_data[_player_id]
	
	
	td.player_id = _player_id or td.player_id
	td.get_award_value = _get_award_value or td.get_award_value

	
	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_get_award_value = %s;
								insert into player_duiju_hongbao_award
								(player_id,get_award_value)
								values(@_player_id,@_get_award_value)
								on duplicate key update
								player_id = @_player_id,
								get_award_value = @_get_award_value;]]
							,td.player_id
							,td.get_award_value
							)

	base.DATA.sql_queue_slow:push_back(sql)

end


return PROTECTED
