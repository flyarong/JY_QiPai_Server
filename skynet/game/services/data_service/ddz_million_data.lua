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

--[[玩家统计信息
	数据库表： statistics_player_million_ddz
	
	id --玩家id
	dizhu_win_count
	nongmin_win_count
	final_win
--]]
PROTECTED.statistics_player_million_ddz_data = {}
local statistics_player_million_ddz_data = PROTECTED.statistics_player_million_ddz_data

--玩家百万大奖赛的奖杯状态
PROTECTED.player_million_cup_status = {}

PROTECTED.init_race_log_max_id = 0

--每周奖金排名list - 1-20 
PROTECTED.player_million_bonus_rank = {}
--每周奖金排名hash - 完整的数据
PROTECTED.player_million_bonus_data = {}

PROTECTED.player_million_bonus_rank_date=0
PROTECTED.player_million_bonus_rank_issue=0

--百万大奖赛分享数据
PROTECTED.player_million_shared_data = {}

-- 初始化比赛数据
function PROTECTED.init()

	PROTECTED.init_race_log_data()

	PROTECTED.init_statistics_player_million_ddz()

	PROTECTED.init_player_million_bonus_rank()

	PROTECTED.init_player_million_shared_data()

	base.PUBLIC.add_fixed_point_callback(4,PROTECTED.ranking_player_million_bonus_rank)
	-- base.PUBLIC.add_fixed_point_callback(4,PROTECTED.clear_player_million_bonus_rank)

	return true
end


-- 开始一个场次实例的 日志数据
function base.CMD.start_ddz_million(_game_id,_issue,_player_count)

	base.DATA.sql_queue_slow:push_back(
		string.format([[insert into million_ddz_log(id,game_id,issue,player_count,begin_time,end_time)
							values(NULL,%u,%u,%d,FROM_UNIXTIME(%u),0);]],
		_game_id,_issue,_player_count,os.time()
	))

end

-- 结束一个场次实例的 日志数据
function base.CMD.end_ddz_million(_game_id,_issue)

	-- 写入数据库
	base.DATA.sql_queue_slow:push_back(
		string.format([[update million_ddz_log set end_time=FROM_UNIXTIME(%u) where game_id=%u and issue=%u;]],
		os.time(),_game_id,_issue
	))

end

-- 记录玩家比赛日志
function base.CMD.add_ddz_million_player_log(_player_id,_game_id,_issue,_score,_final_round,_final_win,_award)

	base.DATA.sql_queue_slow:push_back(
		string.format([[insert into million_ddz_player_log
							(player_id,game_id,issue,score,final_round,final_win,award)
							values('%s',%u,%d,%d,%d,%d,'%s');]],
		_player_id,_game_id,_issue,_score,_final_round,_final_win,_award)
	)

end


function PROTECTED.init_race_log_data()
	
	-- 从数据库加载
	local sql = "SELECT MAX(id) FROM million_ddz_race_log;"
	local ret = base.DATA.db_mysql:query(sql)

	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	PROTECTED.init_race_log_max_id = ret[1]["MAX(id)"] or 0

end



--分享问题
function PROTECTED.init_player_million_shared_data()
	
	-- 从数据库加载
	local sql = "SELECT * FROM million_ddz_shared_status;"
	local ret = base.DATA.db_mysql:query(sql)

	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]
		PROTECTED.player_million_shared_data[row.player_id]=row
	end

end


function base.CMD.add_player_million_shared_data(_player_id)
	
	
	PROTECTED.player_million_shared_data[_player_id]=
	{
		player_id = _player_id,
		time = os.time(),
		status = 0,
	}

	base.DATA.sql_queue_slow:push_back(
		string.format([[
						SET @_player_id = '%s';
						SET @_time = %d;
						SET @_status = %d;
						insert into million_ddz_shared_status
						(player_id,time,status)
						values(@_player_id,@_time,@_status)
						on duplicate key update 
						player_id = @_player_id,
						time = @_time,
						status = @_status;
						]],
						PROTECTED.player_million_shared_data[_player_id].player_id,
						PROTECTED.player_million_shared_data[_player_id].time,
						PROTECTED.player_million_shared_data[_player_id].status)
	)

end

function base.CMD.query_player_million_shared_data(_player_id)

	return PROTECTED.player_million_shared_data[_player_id] or {
						player_id = _player_id,
						time = 0,
						status = 0,
					}

end


-- 记录对局日志
-- 数据库表：million_ddz_race_log,million_ddz_race_player_log
-- 参数：除了 _players ，其他都是 million_ddz_race_log 表的字段
-- 参数 _players ： 玩家数据数组，按座位号顺序放置，包含表 million_ddz_race_player_log 中的字段
function base.CMD.add_ddz_million_race_log(_game_id,_issue,_round,_race,_begin_time,_end_time,_bomb_count,
				_spring,_base_score,_base_rate,_operation_list,_dizhu_seat,_players)
	
	PROTECTED.init_race_log_max_id = PROTECTED.init_race_log_max_id + 1
	local _race_id = PROTECTED.init_race_log_max_id

	-- 对局表 million_ddz_race_log 的
	local sqls = {string.format([[insert into million_ddz_race_log(id,game_id,issue,round,race,begin_time,end_time,bomb_count,
		spring,base_score,base_rate,operation_list,dizhu_seat,seat1_user,seat2_user,seat3_user)
		values(%u,%u,%d,%d,%d,FROM_UNIXTIME(%u),FROM_UNIXTIME(%u),%d,%d,%d,%d,x'%s',%d,'%s','%s','%s');]],
		_race_id,_game_id,_issue,_round,_race,_begin_time,_end_time,_bomb_count,_spring,
		_base_score,_base_rate,
		basefunc.tohex(_operation_list),_dizhu_seat,
		_players[1].player_id,_players[2].player_id,_players[3].player_id
	)}

	-- 每个玩家 million_ddz_race_player_log
	for i=1,3 do
		local _pdata = _players[i]
		sqls[#sqls + 1] = string.format([[insert into million_ddz_race_player_log(player_id,race_id,seat,score,rate,bomb_count,spring)
		values('%s',%u,%d,%d,%d,%d,%d); ]],
			_pdata.player_id,_race_id,i,_pdata.score,
			_pdata.rate,_pdata.bomb_count,_pdata.spring)
	end
	
	base.DATA.sql_queue_slow:push_back(table.concat(sqls))
end



--[[记录玩家比赛

	数据库表： statistics_player_million_ddz

	id --玩家id
	dizhu_win_count
	nongmin_win_count
	defeated_count
	final_win
]]

function PROTECTED.init_statistics_player_million_ddz()

	local sql = "select * from statistics_player_million_ddz"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]
		statistics_player_million_ddz_data[row.id]=row
	end

end


function base.CMD.update_statistics_player_million_ddz(_player_id,_dizhu_win,_nongmin_win,_defeated_count,_final_win)

	statistics_player_million_ddz_data[_player_id]=
	{
		id = _player_id,
		dizhu_win_count = _dizhu_win,
		nongmin_win_count = _nongmin_win,
		defeated_count = _defeated_count,
		final_win = _final_win,
	}

	base.DATA.sql_queue_slow:push_back(
		string.format([[
						SET @_player_id = '%s';
						SET @_dizhu_win = %d;
						SET @_nongmin_win = %d;
						SET @_defeated_count = %d;
						SET @_final_win = %d;
						insert into statistics_player_million_ddz
						(id,dizhu_win_count,nongmin_win_count,defeated_count,final_win)
						values(@_player_id,@_dizhu_win,@_nongmin_win,@_defeated_count,@_final_win)
						on duplicate key update 
						id = @_player_id,
						dizhu_win_count = @_dizhu_win,
						nongmin_win_count = @_nongmin_win,
						defeated_count = @_defeated_count,
						final_win = @_final_win;
						]],
						_player_id,_dizhu_win,_nongmin_win,_defeated_count,_final_win)
	)

end


function base.CMD.get_statistics_player_million_ddz(_player_id)
	return statistics_player_million_ddz_data[_player_id] or 
	{
		id = _player_id,
		dizhu_win_count = 0,
		nongmin_win_count = 0,
		defeated_count = 0,
		final_win = 0,
	}

end



function base.CMD.set_player_million_cup_status(_player_id,_data)
	if _data then
		PROTECTED.player_million_cup_status[_player_id]=_data
	else
		PROTECTED.player_million_cup_status[_player_id]=nil
	end
end

function base.CMD.query_player_million_cup_status(_player_id)
	return PROTECTED.player_million_cup_status[_player_id]
end


local min_rank = 100
local show_rank = 20
function PROTECTED.init_player_million_bonus_rank()

	local sql = "select * from million_ddz_bonus_week order by bonus desc limit "..min_rank .. ";"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	PROTECTED.player_million_bonus_rank = {}
	PROTECTED.player_million_bonus_data = {}

	--这里是前100的人
	for i = 1,#ret do
		local row = ret[i]
		row.rank = i
		row.name = base.CMD.get_player_info(row.player_id,"player_info","name")
		PROTECTED.player_million_bonus_data[row.player_id]=row
		
		if i <= show_rank then
			PROTECTED.player_million_bonus_rank[i]=row
		end

	end

	--这里是所有人的信息
	local sql = "select * from million_ddz_bonus_week"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]

		if not PROTECTED.player_million_bonus_data[row.player_id] then
			row.rank = min_rank
			row.name = base.CMD.get_player_info(row.player_id,"player_info","name")
			PROTECTED.player_million_bonus_data[row.player_id]=row
		end

	end

	PROTECTED.player_million_bonus_rank_date=tostring(os.time())

	PROTECTED.player_million_bonus_rank_issue=0

end


--进行数据重置 每周一 4 点
function PROTECTED.clear_player_million_bonus_rank()
	PROTECTED.player_million_bonus_rank = {}
	PROTECTED.player_million_bonus_data = {}
	local sql = "delete * from million_ddz_bonus_week"
	base.DATA.sql_queue_slow:push_back(sql)
end

--进行数据排行 每天 4 点
function PROTECTED.ranking_player_million_bonus_rank()

	local sql = "select * from million_ddz_bonus_week order by bonus desc limit "..min_rank .. ";"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	--这里是前100的人
	for i = 1,#ret do
		local row = ret[i]
		row.name = base.CMD.get_player_info(row.player_id,"player_info","name")
		PROTECTED.player_million_bonus_data[row.player_id].rank=i
		if i <= show_rank then
			PROTECTED.player_million_bonus_rank[i]=row
		end
	end

	PROTECTED.player_million_bonus_rank_date=tostring(os.time())

end


--[[玩家奖金增加 -- 不可能还减少了
	
	数组形式
	player_id
	bonus

]]
function base.CMD.update_player_million_bonus_rank(datas,_issue)

	for i,data in ipairs(datas) do

		--数据存在
		if PROTECTED.player_million_bonus_data[data.player_id] then
			local player_data = PROTECTED.player_million_bonus_data[data.player_id]
			player_data.bonus = player_data.bonus+data.bonus

			if player_data.rank < show_rank then
				PROTECTED.player_million_bonus_rank[player_data.rank].bonus=player_data.bonus
			end

			local sql = string.format("update million_ddz_bonus_week set bonus=%u where player_id='%s';"
									,player_data.bonus,data.player_id)
			base.DATA.sql_queue_slow:push_back(sql)
		else
		--不存在
			PROTECTED.player_million_bonus_data[data.player_id] = {
				player_id = data.player_id,
				bonus = data.bonus,
				name = base.CMD.get_player_info(data.player_id,"player_info","name"),
			}
			local sql = string.format("insert into million_ddz_bonus_week(player_id,bonus)values('%s',%u);"
									,data.player_id,data.bonus)
			base.DATA.sql_queue_slow:push_back(sql)
		end

	end

	PROTECTED.player_million_bonus_rank_issue=_issue

end

--[[查询排行 前100名的列表 和 我自己的
	{
		rank_list={}
		my_rank={}
	}
]]
function base.CMD.query_player_million_bonus_rank(player_id)

	local my_rank = PROTECTED.player_million_bonus_data[player_id]
	local rank_list = PROTECTED.player_million_bonus_rank

	return {
			my_rank=my_rank,
			rank_list=rank_list,
			date=PROTECTED.player_million_bonus_rank_date,
			issue=PROTECTED.player_million_bonus_rank_issue,
			}
end



return PROTECTED