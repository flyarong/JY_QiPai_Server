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


function PROTECTED.init_data()

end



function CMD.query_all_player_withdraw_status()

	local sql = "select * from player_withdraw_status;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	local data = {}

	for i = 1,#ret do
		local row = ret[i]
		
		data[row.player_id] = row
		row.player_id = nil

	end
	
	return data
end

function CMD.update_player_withdraw_status(_player_id,_data)

	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_withdraw_num = %s;
								SET @_withdraw_money = %s;
								SET @_opt_time = %s;
								insert into player_withdraw_status
								(player_id,withdraw_num,withdraw_money,opt_time)
								values(@_player_id,@_withdraw_num,@_withdraw_money,@_opt_time)
								on duplicate key update
								withdraw_num = @_withdraw_num,
								withdraw_money = @_withdraw_money,
								opt_time = @_opt_time;]]
							,_player_id
							,_data.withdraw_num
							,_data.withdraw_money
							,_data.opt_time)

	base.DATA.sql_queue_slow:push_back(sql)

end





function CMD.query_all_gjhhr_withdraw_status()

	local sql = "select * from gjhhr_withdraw_status;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	local data = {}

	for i = 1,#ret do
		local row = ret[i]
		
		data[row.player_id] = row
		row.player_id = nil

	end
	
	return data
end

function CMD.update_gjhhr_withdraw_status(_player_id,_data)

	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_withdraw_num = %s;
								SET @_withdraw_money = %s;
								SET @_opt_time = %s;
								insert into gjhhr_withdraw_status
								(player_id,withdraw_num,withdraw_money,opt_time)
								values(@_player_id,@_withdraw_num,@_withdraw_money,@_opt_time)
								on duplicate key update
								withdraw_num = @_withdraw_num,
								withdraw_money = @_withdraw_money,
								opt_time = @_opt_time;]]
							,_player_id
							,_data.withdraw_num
							,_data.withdraw_money
							,_data.opt_time)

	base.DATA.sql_queue_slow:push_back(sql)

end



return PROTECTED