--- 玩家的vip礼包数据

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

function CMD.query_all_vip_lb_data()
	local sql = "select * from sczd_vip_lb_info;"
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

function CMD.add_or_update_vip_lb_data(_player_id , _is_buy_vip_lb , _now_vip_task_get_num1 , _now_vip_task_max_num1 , _now_vip_task_get_num2 ,
										_now_vip_task_max_num2 , _now_vip_rebate_xj_num , _max_vip_rebate_xj_num , _task_overdue_time )
	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_is_buy_vip_lb = %s;
								SET @_now_vip_task_get_num1 = %s;
								SET @_now_vip_task_max_num1 = %s;
								SET @_now_vip_task_get_num2 = %s;
								SET @_now_vip_task_max_num2 = %s;
								SET @_now_vip_rebate_xj_num = %s;
								SET @_max_vip_rebate_xj_num = %s;
								SET @_task_overdue_time = %s;
								insert into sczd_vip_lb_info
								(player_id,is_buy_vip_lb,now_vip_task_get_num1,now_vip_task_max_num1,now_vip_task_get_num2,now_vip_task_max_num2,now_vip_rebate_xj_num,max_vip_rebate_xj_num,task_overdue_time)
								values(@_player_id,@_is_buy_vip_lb,@_now_vip_task_get_num1,@_now_vip_task_max_num1,@_now_vip_task_get_num2,@_now_vip_task_max_num2,@_now_vip_rebate_xj_num,@_max_vip_rebate_xj_num,@_task_overdue_time)
								on duplicate key update
								player_id = @_player_id,
								is_buy_vip_lb = @_is_buy_vip_lb,
								now_vip_task_get_num1 = @_now_vip_task_get_num1,
								now_vip_task_max_num1 = @_now_vip_task_max_num1,
								now_vip_task_get_num2 = @_now_vip_task_get_num2,
								now_vip_task_max_num2 = @_now_vip_task_max_num2,
								now_vip_rebate_xj_num = @_now_vip_rebate_xj_num,
								max_vip_rebate_xj_num = @_max_vip_rebate_xj_num,
								task_overdue_time = @_task_overdue_time;]]
							,_player_id
							,_is_buy_vip_lb
							,_now_vip_task_get_num1
							,_now_vip_task_max_num1
							,_now_vip_task_get_num2
							,_now_vip_task_max_num2
							,_now_vip_rebate_xj_num
							,_max_vip_rebate_xj_num
							,_task_overdue_time )

	base.DATA.sql_queue_slow:push_back(sql)
end


return PROTECT