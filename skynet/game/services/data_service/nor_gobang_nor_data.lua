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

--最大对局日志id
local nor_gobang_nor_race_log_max_id = 0


-- 初始化玩家斗地主自由场数据
function PROTECTED.init_data()

	LOCAL_FUNC.init_nor_gobang_nor_race_log_max_id()

	return true
end


--初始化id
function LOCAL_FUNC.init_nor_gobang_nor_race_log_max_id()
	local sql = "SELECT MAX(id) FROM nor_gobang_nor_race_log;"
	local ret = base.DATA.db_mysql:query(sql)

	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	nor_gobang_nor_race_log_max_id = ret[1]["MAX(id)"] or 0

end


-- 添加比赛对局日志 返回插入的id
function base.CMD.add_nor_gobang_nor_race_log(_game_id,_begin_time,_end_time,_base_score,_base_rate,_max_rate,_operation_list,_first_seat,_settle_type,_players,_game_model,_ext_data)
	
	nor_gobang_nor_race_log_max_id = nor_gobang_nor_race_log_max_id + 1

	-- 对局表 nor_gobang_nor_race_log 的
	local sqls = {string.format([[insert into nor_gobang_nor_race_log
		(id,game_id,begin_time,end_time,base_score,base_rate,max_rate
		,operation_list,first_seat,settle_type,seat1_user,seat2_user,game_model,ext_data)
		values(%u,%d,FROM_UNIXTIME(%u),FROM_UNIXTIME(%u),%d,%d,%d,x'%s',%d,'%s','%s','%s','%s','%s');]],
		nor_gobang_nor_race_log_max_id,_game_id,_begin_time,_end_time,
		_base_score,_base_rate,_max_rate,basefunc.tohex(_operation_list),_first_seat,_settle_type or "",
		_players[1].player_id,_players[2].player_id,_game_model,_ext_data
	)}

	-- 每个玩家 nor_gobang_nor_race_player_log
	for i=1,2 do
		local _pdata = _players[i]
		if _pdata and _pdata.player_id then
			sqls[#sqls + 1] = string.format([[insert into nor_gobang_nor_race_player_log
							(player_id,race_id,seat,score,rate)
							values('%s',%u,%d,%d,%d);]],
				_pdata.player_id,nor_gobang_nor_race_log_max_id,i,_pdata.score,_pdata.rate)
		end
	end

	base.DATA.sql_queue_slow:push_back(table.concat(sqls))
	
	return nor_gobang_nor_race_log_max_id
end

return PROTECTED

