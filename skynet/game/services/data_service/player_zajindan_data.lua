--- 玩家的砸金蛋数据

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local LOCAL_FUNC = {}

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

---- 
local player_zjd_data = {}

local PROTECT = {}

function PROTECT.init_data()

	local sql = string.format("select * from player_zajindan_info;" )
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]
		
		player_zjd_data[row.player_id] = row
	end

	return true
end

--- 查找一个玩家的 砸金蛋数据
function CMD.query_one_player_zjd_data(player_id)
	
	return player_zjd_data[player_id]
end


---- 更新 or 新增 vip信息
function CMD.update_or_add_player_zjd_data(_player_id , _today_get_award , _today_id , _today_get_biggest_award_num_1 , _today_get_biggest_award_num_2 , _today_get_biggest_award_num_3 , _today_get_biggest_award_num_4)
	player_zjd_data[_player_id] = player_zjd_data[_player_id] or {}
	local data_ref = player_zjd_data[_player_id]

	data_ref.player_id = _player_id
	data_ref.today_get_award = _today_get_award
	data_ref.today_id = _today_id
	data_ref.today_get_biggest_award_num_1 = _today_get_biggest_award_num_1
	data_ref.today_get_biggest_award_num_2 = _today_get_biggest_award_num_2
	data_ref.today_get_biggest_award_num_3 = _today_get_biggest_award_num_3
	data_ref.today_get_biggest_award_num_4 = _today_get_biggest_award_num_4

	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_today_get_award = %s;
								SET @_today_id = %s;
								SET @_today_get_biggest_award_num_1 = %s;
								SET @_today_get_biggest_award_num_2 = %s;
								SET @_today_get_biggest_award_num_3 = %s;
								SET @_today_get_biggest_award_num_4 = %s;
								insert into player_zajindan_info
								(player_id,today_get_award , today_id , today_get_biggest_award_num_1 , today_get_biggest_award_num_2 , today_get_biggest_award_num_3 , today_get_biggest_award_num_4)
								values(@_player_id,@_today_get_award,@_today_id,@_today_get_biggest_award_num_1,@_today_get_biggest_award_num_2,@_today_get_biggest_award_num_3,@_today_get_biggest_award_num_4)
								on duplicate key update
								player_id = @_player_id,
								today_get_award = @_today_get_award,
								today_id = @_today_id,
								today_get_biggest_award_num_1 = @_today_get_biggest_award_num_1,
								today_get_biggest_award_num_2 = @_today_get_biggest_award_num_2,
								today_get_biggest_award_num_3 = @_today_get_biggest_award_num_3,
								today_get_biggest_award_num_4 = @_today_get_biggest_award_num_4;]]
							,_player_id
							,_today_get_award
							,_today_id
							,_today_get_biggest_award_num_1
							,_today_get_biggest_award_num_2
							,_today_get_biggest_award_num_3
							,_today_get_biggest_award_num_4
							)

	base.DATA.sql_queue_slow:push_back(sql)

end



--- 设置 今日已得奖励
function CMD.set_zjd_today_award(_player_id , _today_get_award)
	player_zjd_data[_player_id] = player_zjd_data[_player_id] or {}
	local data_ref = player_zjd_data[_player_id]

	data_ref.player_id = _player_id
	data_ref.today_get_award = _today_get_award

	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_today_get_award = %s;
								update player_zajindan_info set
								today_get_award = @_today_get_award 
								where player_id = @_player_id;]]
							,_player_id
							,_today_get_award
							)

	base.DATA.sql_queue_slow:push_back(sql)
end

--- 设置 今日 id
function CMD.set_zjd_today_id(_player_id , _today_id)
	player_zjd_data[_player_id] = player_zjd_data[_player_id] or {}
	local data_ref = player_zjd_data[_player_id]

	data_ref.player_id = _player_id
	data_ref.today_id = _today_id

	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_today_id = %s;
								update player_zajindan_info set
								today_id = @_today_id 
								where player_id = @_player_id;]]
							,_player_id
							,_today_id
							)

	base.DATA.sql_queue_slow:push_back(sql)
end

--- 设置 今日 
function CMD.set_zjd_today_biggest_award_num(_player_id , _key , _num)
	player_zjd_data[_player_id] = player_zjd_data[_player_id] or {}
	local data_ref = player_zjd_data[_player_id]

	data_ref.player_id = _player_id
	data_ref[_key] = _num

	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_num = %s;
								update player_zajindan_info set
								%s = @_num 
								where player_id = @_player_id;]]
							,_player_id
							,_num
							,_key
							)

	base.DATA.sql_queue_slow:push_back(sql)
end

function CMD.set_zjd_last_game_remain_eggs(_player_id , _key , _data)
	player_zjd_data[_player_id] = player_zjd_data[_player_id] or {}
	local data_ref = player_zjd_data[_player_id]

	data_ref.player_id = _player_id
	data_ref[_key] = _data

	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_data = '%s';
								update player_zajindan_info set
								%s = @_data 
								where player_id = @_player_id;]]
							,_player_id
							,_data
							,_key
							)

	base.DATA.sql_queue_slow:push_back(sql)
end

---- 加日志
function CMD.add_player_zajindan_log(_player_id ,_round_id  , _hammer_id , _egg_no , _award_id , _award_type , _award_value , _award_data )
	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_round_id = %s;
								SET @_hammer_id = %s;
								SET @_egg_no = %s;
								SET @_award_id = %s;
								SET @_award_type = %s;
								SET @_award_value = %s;
								SET @_award_data = '%s';
								insert into player_zajindan_log 
								(player_id,round_id,hammer_id,egg_no,award_id,award_type,award_value,award_data)
								values(@_player_id,@_round_id,@_hammer_id,@_egg_no,@_award_id,@_award_type,@_award_value,@_award_data);]]
							,_player_id
							,_round_id
							,_hammer_id
							,_egg_no
							, _award_id
							,_award_type
							,_award_value
							,_award_data
							)

	base.DATA.sql_queue_slow:push_back(sql)
end

---- 加砸金蛋 轮数 日志
function CMD.add_player_zajindan_round_log(_player_id , _hammer_id , _award_data )
	local id = PUBLIC.auto_inc_id("last_zajindan_round")
	local sql = string.format([[
								SET @_id = %s;
								SET @_player_id = '%s';
								SET @_hammer_id = %s;
								SET @_award_data = '%s';
								insert into player_zajindan_round_log 
								(id,player_id,hammer_id,award_data)
								values(@_id,@_player_id,@_hammer_id,@_award_data);]]
							,id
							,_player_id
							,_hammer_id
							,_award_data
							)

	base.DATA.sql_queue_slow:push_back(sql)
	return id
end


---- 获取排行榜
function CMD.get_zajindan_rank( today_id , show_rank_num )
	local sql = string.format("select * from player_zajindan_info where today_id = %s order by today_get_award desc limit %s;" ,today_id , show_rank_num )
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	return ret
end

--- 获取某人的砸蛋记录
function CMD.get_zajindan_log( player_id , total_show_num )
	local sql = string.format("select player_id,award_value,UNIX_TIMESTAMP(time) as time from player_zajindan_log where player_id = %s order by award_value desc limit %s;" ,player_id , total_show_num )
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	return ret
end


return PROTECT