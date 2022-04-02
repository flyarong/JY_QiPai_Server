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
local nor_mj_xzdd_log_max_id = 0


PROTECTED.player_mj_freestyle = {}
local player_mj_freestyle = PROTECTED.player_mj_freestyle


PROTECTED.statistics_player_data = {}
local statistics_player_data = PROTECTED.statistics_player_data


-- 初始化玩家斗地主自由场数据
function PROTECTED.init_player_comm_mj_xzddz()

	LOCAL_FUNC.init_nor_mj_xzdd_race_log_max_id()

	return true
end


--初始化id
function LOCAL_FUNC.init_nor_mj_xzdd_race_log_max_id()
	local sql = "SELECT MAX(id) FROM nor_mj_xzdd_race_log;"
	local ret = base.DATA.db_mysql:query(sql)

	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	nor_mj_xzdd_log_max_id = ret[1]["MAX(id)"] or 0

end


--[[ 添加比赛对局日志 返回插入的id
	id
	game_id
	game_model
	begin_time
	end_time
	gang_count
	geng_count
	base_score
	operation_list
	zhuang_seat
	seat1_user
	seat2_user
	seat3_user
	seat4_user

	id
	player_id
	race_id
	seat
	score
	multi
	gang_info
	pai_info

]]
function base.CMD.add_nor_mj_xzdd_race_log(_game_id,_game_model,_begin_time,_end_time,_init_rate,_max_rate,_init_stake,_fapai,_operation_list,_zhuang_seat,_players)
	
	nor_mj_xzdd_log_max_id = nor_mj_xzdd_log_max_id + 1

	-- 对局表 nor_mj_xzdd_race_log 的
	local sqls = {string.format([[insert into nor_mj_xzdd_race_log
		(id,game_id,begin_time,end_time,init_rate,max_rate,
		init_stake,fapai,operation_list,zhuang_seat,seat1_user,seat2_user,seat3_user,seat4_user,game_model)
		values(%u,%u,FROM_UNIXTIME(%u),FROM_UNIXTIME(%u),%d,%d,%d,'%s',x'%s',%d,'%s','%s','%s','%s','%s');]],
		nor_mj_xzdd_log_max_id,_game_id,_begin_time,_end_time,
		_init_rate,_max_rate,_init_stake,_fapai,basefunc.tohex(_operation_list),_zhuang_seat
		,_players[1] and _players[1].player_id or ""
		,_players[2] and _players[2].player_id or ""
		,_players[3] and _players[3].player_id or ""
		,_players[4] and _players[4].player_id or ""
		,_game_model
	)}

	-- 每个玩家 nor_mj_xzdd_race_player_log
	for i,_pdata in ipairs(_players) do
		sqls[#sqls + 1] = string.format([[insert into nor_mj_xzdd_race_player_log
							(player_id,race_id,seat,score,multi,gang_info,pai_info)
							values('%s',%u,%d,%d,%d,'%s','%s');]],
				_pdata.player_id,nor_mj_xzdd_log_max_id,i,_pdata.score,
				_pdata.multi,_pdata.gang_info,_pdata.pai_info)
	end

	base.DATA.sql_queue_slow:push_back(table.concat(sqls))
	
	return nor_mj_xzdd_log_max_id
end



return PROTECTED