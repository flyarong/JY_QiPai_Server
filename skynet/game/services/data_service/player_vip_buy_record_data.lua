--
-- Author: wss
-- Date: 2018/11/15
-- Time: 17:47
-- 说明：vip 购买记录
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

--- 新增
function CMD.add_player_vip_buy_record(_player_id , _payback_player_id , _payback_value , _buy_vip_day , _buy_time )
	local id = PUBLIC.auto_inc_id("last_vip_record_id")

	local sql = string.format([[
								SET @_id = %d;
								SET @_player_id = '%s';
								SET @_payback_player_id = '%s';
								SET @_payback_value = %s;
								SET @_buy_vip_day = %s;
								SET @_buy_time = %s;
								insert into player_vip_buy_record
								(id,player_id,payback_player_id,payback_value,buy_vip_day,buy_time,buy_time_year,buy_time_month,buy_time_day)
								values(@_id,@_player_id,@_payback_player_id,@_payback_value,@_buy_vip_day,@_buy_time
								,DATE_FORMAT(FROM_UNIXTIME(@_buy_time),'%%Y')
								,DATE_FORMAT(FROM_UNIXTIME(@_buy_time),'%%m')
								,DATE_FORMAT(FROM_UNIXTIME(@_buy_time),'%%d') );]]
							,id
							,_player_id
							,_payback_player_id
							,_payback_value
							,_buy_vip_day
							,_buy_time
							)

	base.DATA.sql_queue_slow:push_back(sql)

	return id
end

--- 查询一个玩家获得 FL 的记录
function CMD.get_player_vip_payback_record(player_id , page_index , page_item_num , _offset)
	local sql = string.format([[
								SELECT RECORD.id,RECORD.player_id,RECORD.payback_player_id,RECORD.payback_value,RECORD.buy_vip_day,RECORD.buy_time,player_info.name 
								FROM player_vip_buy_record as RECORD,player_info
									where player_info.id = RECORD.player_id and RECORD.payback_player_id = '%s' ORDER BY RECORD.id DESC LIMIT %d, %d ;
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

--- 查询 玩家的 FL 统计,所有年
function CMD.get_player_vip_payback_statistics_year(player_id)
	--[[ old sql 备份
	SELECT DATE_FORMAT(FROM_UNIXTIME(buy_time),'%Y') as YY,SUM(payback_value) as total FROM player_vip_buy_record as TEM 
									where TEM.payback_player_id = '%s' group by YY; 
	--]]

	local sql = string.format([[
								SELECT buy_time_year as _year,SUM(payback_value) as total FROM player_vip_buy_record as TEM 
									where TEM.payback_player_id = '%s' GROUP BY _year;
							]]
							,player_id
							)

	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end
	return ret
end

--- 查询 玩家的 FL 统计,某年所有月
function CMD.get_player_vip_payback_statistics_month(player_id,year)
	--[[ old sql 备份
		SELECT DATE_FORMAT(FROM_UNIXTIME(buy_time),'%m') as MM,SUM(payback_value) as total FROM player_vip_buy_record as TEM 
									where TEM.payback_player_id = '%s' and 
									DATE_FORMAT(FROM_UNIXTIME(buy_time),'%Y') = %d group by MM;
	--]]

	local sql = string.format([[
								SELECT buy_time_month as _month,SUM(payback_value) as total FROM player_vip_buy_record as TEM 
									where TEM.payback_player_id = '%s' and 
									buy_time_year = %d group by _month;
							]]
							,player_id
							,year
							)

	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end
	return ret
end

--- 查询 玩家的 FL 统计，某年某月所有日
function CMD.get_player_vip_payback_statistics_day(player_id,year,month)
	--[[ old sql 备份
		SELECT DATE_FORMAT(FROM_UNIXTIME(buy_time),'%d') as DD,SUM(payback_value) as total FROM player_vip_buy_record as TEM 
									where TEM.payback_player_id = '%s' and 
									DATE_FORMAT(FROM_UNIXTIME(buy_time),'%Y') = %d and DATE_FORMAT(FROM_UNIXTIME(buy_time),'%m') = %d group by DD;
	--]]

	local sql = string.format([[
								SELECT buy_time_day as _day,SUM(payback_value) as total FROM player_vip_buy_record as TEM 
									where TEM.payback_player_id = '%s' and 
									buy_time_year = %d and buy_time_month = %d group by _day;
							]]
							,player_id
							,year
							,month
							)

	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end
	return ret
end

------------------------------------------------- 
--- 查询 玩家的 FL 统计，某年某月所有日
function CMD.get_player_vip_payback_statistics_all_day(player_id)
	--[[ old sql 备份
		SELECT DATE_FORMAT(FROM_UNIXTIME(buy_time),'%d') as DD,SUM(payback_value) as total FROM player_vip_buy_record as TEM 
									where TEM.payback_player_id = '%s' and 
									DATE_FORMAT(FROM_UNIXTIME(buy_time),'%Y') = %d and DATE_FORMAT(FROM_UNIXTIME(buy_time),'%m') = %d group by DD;
	--]]

	local sql = string.format([[
								SELECT buy_time_year as _year,buy_time_month as _month,buy_time_day as _day,SUM(payback_value) as total FROM player_vip_buy_record as TEM 
									where TEM.payback_player_id = '%s' group by _day;
							]]
							,player_id
							)

	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end
	return ret
end



return PROTECTED