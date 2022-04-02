--
-- Author: wss
-- Date: 2018/12/6
-- Time: 14:36
-- 说明：比赛场盈亏数据
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local PROTECTED = {}

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA


function PROTECTED.init_data()


	return true
end

--- 查找所有的 盈亏数据
function CMD.query_all_game_profit()
	local data = {}
	local sql = "select * from game_profit;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]
		data[row.game_id] = row
	end
	return data
end


---- 更新 or 新增 
function CMD.update_or_add_game_profit(_game_id , _total_profit , _total_loss , _total_profit_loss , _last_record_time , _month_profit ,
											 _month_loss , _month_profit_loss , _cycle_game_num , _cycle_profit_loss , _cycle_player_num ,
											 	 _total_cycle_profit_loss , _total_cycle_player_num , _gain_money_power)

	local sql = string.format([[
								SET @_game_id = '%s';
								SET @_total_profit = %s;
								SET @_total_loss = %s;
								SET @_total_profit_loss = %s;
								SET @_last_record_time = %s;
								SET @_month_profit = %s;
								SET @_month_loss = %s;
								SET @_month_profit_loss = %s;
								SET @_cycle_game_num = %s;
								SET @_cycle_profit_loss = %s;
								SET @_cycle_player_num = %s;
								SET @_total_cycle_profit_loss = %s;
								SET @_total_cycle_player_num = %s;
								SET @_gain_money_power = %s;
								insert into game_profit
								(game_id,total_profit,total_loss,total_profit_loss,last_record_time,month_profit,month_loss,month_profit_loss,cycle_game_num,cycle_profit_loss,cycle_player_num,total_cycle_profit_loss,total_cycle_player_num,gain_money_power)
								values(@_game_id,@_total_profit,@_total_loss,@_total_profit_loss,@_last_record_time,@_month_profit,@_month_loss,@_month_profit_loss,@_cycle_game_num,@_cycle_profit_loss,@_cycle_player_num,@_total_cycle_profit_loss,@_total_cycle_player_num,@_gain_money_power)
								on duplicate key update
								game_id = @_game_id,
								total_profit = @_total_profit,
								total_loss = @_total_loss,
								total_profit_loss = @_total_profit_loss,
								last_record_time = @_last_record_time,
								month_profit = @_month_profit,
								month_loss = @_month_loss,
								month_profit_loss = @_month_profit_loss,
								cycle_game_num = @_cycle_game_num,
								cycle_profit_loss = @_cycle_profit_loss,
								cycle_player_num = @_cycle_player_num,
								total_cycle_profit_loss = @_total_cycle_profit_loss,
								total_cycle_player_num = @_total_cycle_player_num,
								gain_money_power = @_gain_money_power;]]
							,_game_id
							,_total_profit
							,_total_loss
							,_total_profit_loss
							,_last_record_time
							,_month_profit
							,_month_loss
							,_month_profit_loss
							,_cycle_game_num
							,_cycle_profit_loss
							,_cycle_player_num
							,_total_cycle_profit_loss
							,_total_cycle_player_num
							,_gain_money_power
							)

	base.DATA.sql_queue_slow:push_back(sql)

end

----- 新增 每个月的比赛场的收益统计
function CMD.add_game_profit_statistics(_game_id , _profit , _loss , _profit_loss , _record_time , _record_year , _record_month)
	local sql = string.format([[
								SET @_game_id = '%s';
								SET @_profit = %s;
								SET @_loss = %s;
								SET @_profit_loss = %s;
								SET @_record_time = %s;
								SET @_record_year = %s;
								SET @_record_month = %s;
								insert into game_profit_statistics 
								(game_id,profit,loss,profit_loss,record_time,record_year,record_month)
								values(@_game_id,@_profit,@_loss,@_profit_loss,@_record_time,@_record_year,@_record_month);]]
							,_game_id
							,_profit
							,_loss
							,_profit_loss
							,_record_time
							,_record_year
							,_record_month
							)

	base.DATA.sql_queue_slow:push_back(sql)

end


------ 新增 每个周期的结算日志
function CMD.add_game_profit_cycle_log(_game_id , _cycle_game_num , _cycle_player_num , _cycle_profit_loss , _total_player_num , _total_profit_loss , _gain_everyone_value , _wave_trend, _cycle_gain_power )
	local sql = string.format([[
								SET @_game_id = '%s';
								SET @_cycle_game_num = %s;
								SET @_cycle_player_num = %s;
								SET @_cycle_profit_loss = %s;
								SET @_total_player_num = %s;
								SET @_total_profit_loss = %s;
								SET @_gain_everyone_value = %s;
								SET @_wave_trend = '%s';
								SET @_cycle_gain_power = %s;
								insert into game_profit_cycle_log 
								(game_id,cycle_game_num,cycle_player_num,cycle_profit_loss,total_player_num,total_profit_loss,gain_everyone_value,wave_trend,cycle_gain_power)
								values(@_game_id,@_cycle_game_num,@_cycle_player_num,@_cycle_profit_loss,@_total_player_num,@_total_profit_loss,@_gain_everyone_value,@_wave_trend,@_cycle_gain_power);]]
							,_game_id
							,_cycle_game_num
							,_cycle_player_num
							,_cycle_profit_loss
							,_total_player_num
							,_total_profit_loss
							,_gain_everyone_value
							,_wave_trend
							,_cycle_gain_power
							)

	base.DATA.sql_queue_slow:push_back(sql)

end


return PROTECTED