--
-- Author: wss
-- Date: 2018/11/13
-- Time: 19:03
-- 说明：vip用户的数据存储
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local PROTECTED = {}

local LOCAL_FUNC = {}

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

--local vip_data = {}


function PROTECTED.init_data()


	return true
end

--- 查找所有的vip用户
function CMD.query_all_vip_players()
	local vip_data = {}
	local sql = "select * from player_vip;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]
		vip_data[row.player_id] = row
	end
	return vip_data
end


---- 更新 or 新增 vip信息，允许传部分值
function CMD.update_or_add_player_vip(_player_id , _vip_time , _vip_day_time )

	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_vip_time = %s;
								SET @_vip_day_time = %s;
								insert into player_vip
								(player_id,vip_time,vip_day_time)
								values(@_player_id,@_vip_time,@_vip_day_time)
								on duplicate key update
								player_id = @_player_id,
								vip_time = @_vip_time,
								vip_day_time = @_vip_day_time;]]
							,_player_id
							,_vip_time
							,_vip_day_time
							)

	base.DATA.sql_queue_slow:push_back(sql)

end


return PROTECTED