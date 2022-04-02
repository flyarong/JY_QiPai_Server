--
-- Author: lyx
-- Date: 2018/4/19
-- Time: 19:59
-- 说明：load_and_close_ser_data
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local PROTECTED = {}

local LOCAL_FUNC = {}


--
function base.CMD.query_load_and_close_ser_cfg()

	local sql = "select id,path,unix_timestamp(startTime) as startTime,unix_timestamp(closeTime) as closeTime,isover from load_and_close_ser_cfg;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end
dump(ret,"query_load_and_close_ser_cfg")
	return ret

end


function base.CMD.update_load_and_close_ser_cfg_over(_id,_isover)

	local sql = string.format("update load_and_close_ser_cfg set isover=%s where id=%s;"
								,_isover
								,_id
								)

	base.DATA.sql_queue_fast:push_back(sql)

end


--[[
	id
	path
	startTime
	closeTime
	isover
]]
function base.CMD.insert_load_and_close_ser_cfg(_data)

	-- 写入数据库
	base.DATA.sql_queue_fast:push_back(
		string.format([[
				SET @_id = %d;
				SET @_path = '%s';
				SET @_startTime = FROM_UNIXTIME(%s);
				SET @_closeTime = FROM_UNIXTIME(%s);
				SET @_isover = %d;
				insert into load_and_close_ser_cfg
				(id,path,startTime,closeTime,isover)
				values(@_id,@_path,@_startTime,@_closeTime,@_isover)
				on duplicate key update
				id = @_id,
				path = @_path,
				startTime = @_startTime,
				closeTime = @_closeTime,
				isover = @_isover;
			]],
		_data.id,_data.path,_data.startTime,_data.closeTime,_data.isover
	))

end


function base.CMD.delete_load_and_close_ser_cfg(_id)

	local sql = string.format("delete from load_and_close_ser_cfg where id = %s;",_id)

	base.DATA.sql_queue_fast:push_back(sql)
end



return PROTECTED