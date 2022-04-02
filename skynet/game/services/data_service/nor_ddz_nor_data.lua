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
local nor_ddz_nor_race_log_max_id = 0


PROTECTED.statistics_player_nor_ddz_nor_data = {}
local statistics_player_nor_ddz_nor_data = PROTECTED.statistics_player_nor_ddz_nor_data


-- 初始化玩家斗地主自由场数据
function PROTECTED.init_data()

	LOCAL_FUNC.init_nor_ddz_nor_race_log_max_id()

	return true
end


--初始化id
function LOCAL_FUNC.init_nor_ddz_nor_race_log_max_id()
	local sql = "SELECT MAX(id) FROM nor_ddz_nor_race_log;"
	local ret = base.DATA.db_mysql:query(sql)

	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	nor_ddz_nor_race_log_max_id = ret[1]["MAX(id)"] or 0

end


-- 添加比赛对局日志 返回插入的id
function base.CMD.add_nor_ddz_nor_race_log(_game_id,_begin_time,_end_time,_bomb_count,_spring,_base_score,_base_rate,_max_rate,_fapai,_operation_list,_dizhu_seat,_lz_card,_players,_game_model)
	
	nor_ddz_nor_race_log_max_id = nor_ddz_nor_race_log_max_id + 1

	-- 对局表 nor_ddz_nor_race_log 的
	local sqls = {string.format([[insert into nor_ddz_nor_race_log
		(id,game_id,begin_time,end_time,bomb_count,
		spring,base_score,base_rate,max_rate,fapai,operation_list,dizhu_seat,lz_card,seat1_user,seat2_user,seat3_user,game_model)
		values(%u,%d,FROM_UNIXTIME(%u),FROM_UNIXTIME(%u),%d,%d,%d,%d,%d,'%s',x'%s',%d,%d,'%s','%s','%s','%s');]],
		nor_ddz_nor_race_log_max_id,_game_id,_begin_time,_end_time,_bomb_count,_spring,
		_base_score,_base_rate,_max_rate,_fapai,basefunc.tohex(_operation_list),_dizhu_seat,_lz_card or 0,
		_players[1].player_id,_players[2].player_id,_players[3].player_id,_game_model
	)}

	-- 每个玩家 nor_ddz_nor_race_player_log
	for i=1,3 do
		local _pdata = _players[i]
		if _pdata and _pdata.player_id then
			sqls[#sqls + 1] = string.format([[insert into nor_ddz_nor_race_player_log
							(player_id,race_id,seat,score,rate,bomb_count,spring)
							values('%s',%u,%d,%d,%d,%d,%d);]],
				_pdata.player_id,nor_ddz_nor_race_log_max_id,i,_pdata.score,
				_pdata.rate,_pdata.bomb_count,_pdata.spring)
		end
	end

	base.DATA.sql_queue_slow:push_back(table.concat(sqls))
	
	return nor_ddz_nor_race_log_max_id
end

return PROTECTED

