--- 玩家的 金猪礼包 数据

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local LOCAL_FUNC = {}

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

---- 

local PROTECT = {}

function PROTECT.init_data()
	

	return true
	
end

function CMD.query_all_goldpig_data()
	local sql = "select * from player_goldpig_info;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	local data = {}
	for i = 1,#ret do
		local row = ret[i]
		
		data[row.player_id] = row

	end

	return data
end

--- 查找一个玩家的 砸金蛋数据
--[[function CMD.query_one_player_goldpig_data(player_id)
	
	return player_goldpig_data[player_id]
end--]]

function CMD.add_or_update_goldpig_data(_player_id , _is_buy_goldpig , _remain_task_num, _is_buy_goldpig1 , _remain_task_num1 , _is_buy_goldpig2 , _remain_task_num2 , _today_get_task_num2 )
	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_is_buy_goldpig = %s;
								SET @_remain_task_num = %s;
								SET @_is_buy_goldpig1 = %s;
								SET @_remain_task_num1 = %s;
								SET @_is_buy_goldpig2 = %s;
								SET @_remain_task_num2 = %s;
								SET @_today_get_task_num2 = %s;
								insert into player_goldpig_info
								(player_id,is_buy_goldpig,remain_task_num,is_buy_goldpig1,remain_task_num1,is_buy_goldpig2,remain_task_num2,today_get_task_num2)
								values(@_player_id,@_is_buy_goldpig,@_remain_task_num,@_is_buy_goldpig1,@_remain_task_num1,@_is_buy_goldpig2,@_remain_task_num2,@_today_get_task_num2)
								on duplicate key update
								player_id = @_player_id,
								is_buy_goldpig = @_is_buy_goldpig,
								remain_task_num = @_remain_task_num,
								is_buy_goldpig1 = @_is_buy_goldpig1,
								remain_task_num1 = @_remain_task_num1,
								is_buy_goldpig2 = @_is_buy_goldpig2,
								remain_task_num2 = @_remain_task_num2,
								today_get_task_num2 = @_today_get_task_num2;]]
							,_player_id
							,_is_buy_goldpig
							,_remain_task_num
							,_is_buy_goldpig1
							,_remain_task_num1
							,_is_buy_goldpig2
							,_remain_task_num2
							,_today_get_task_num2 )

	base.DATA.sql_queue_slow:push_back(sql)

end


return PROTECT