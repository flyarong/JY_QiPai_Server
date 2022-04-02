--
-- Author: lyx
-- Date: 2018/4/19
-- Time: 19:59
-- 说明：斗地主的数据存储
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
require "data_func"

local PROTECTED = {}

local LOCAL_FUNC = {}

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local player_friendgame_history_record_ids = {}

local friendgame_history_record_max_id = 0

local friendgame_room_log_max_id = 0


-- 初始化玩家斗地主自由场数据
function PROTECTED.init_data()

	local sql = "select * from friendgame_player_history;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]

		player_friendgame_history_record_ids[row.player_id]=basefunc.string.split_num(row.records)

	end
	
	local sql = "SELECT MAX(id) FROM friendgame_history_record;"
	local ret = base.DATA.db_mysql:query(sql)

	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	friendgame_history_record_max_id = ret[1]["MAX(id)"] or 0


	local sql = "SELECT MAX(id) FROM friendgame_room_log;"
	local ret = base.DATA.db_mysql:query(sql)

	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	friendgame_room_log_max_id = ret[1]["MAX(id)"] or 0

end



--添加一个记录id
function LOCAL_FUNC.add_player_record_id(_player_id,_record_id)

	local record_ids = player_friendgame_history_record_ids[_player_id] or {}
	player_friendgame_history_record_ids[_player_id] = record_ids
	
	record_ids[#record_ids+1]=_record_id

	if #record_ids > 10 then
		table.remove(record_ids,1)
	end

	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_record_ids = '%s';
								insert into friendgame_player_history
								(player_id,records)
								values(@_player_id,@_record_ids)
								on duplicate key update
								player_id = @_player_id,
								records = @_record_ids;]]
							,_player_id
							,table.concat(record_ids,","))
	base.DATA.sql_queue_slow:push_back(sql)

end

--[[添加一个记录
	id
	game_name
	time
	room_no

	player_infos={
		{
			id,
			name,
			head_img_url,
			score,
		},
	}

]]
function base.CMD.add_friendgame_history_record(_data)
	friendgame_history_record_max_id = friendgame_history_record_max_id + 1
	_data.id = friendgame_history_record_max_id

	local p_data = {}
	for i=1,4 do
		local info = _data.player_infos[i] or {}
		info.id = info.id or ""
		info.name = PUBLIC.sql_strv(info.name or "")
		info.head_img_url = info.head_img_url or ""
		info.score = info.score or 0

		if info.id ~= "" then
			LOCAL_FUNC.add_player_record_id(info.id,friendgame_history_record_max_id)
		end

		p_data[i] = info
	end

	-- 写入数据库
	base.DATA.sql_queue_fast:push_back(
		string.format([[
				insert into friendgame_history_record
				(id,game_name,time,room_no,p1_id,p1_name,p1_head_img_url,p1_score,p2_id,p2_name,p2_head_img_url,p2_score,p3_id,p3_name,p3_head_img_url,p3_score,p4_id,p4_name,p4_head_img_url,p4_score)
				values(%d,'%s',%d,'%s','%s','%s','%s',%d,'%s','%s','%s',%d,'%s','%s','%s',%d,'%s','%s','%s',%d);
			]],
		_data.id,_data.game_name,_data.time,_data.room_no,
		p_data[1].id,p_data[1].name,p_data[1].head_img_url,p_data[1].score,
		p_data[2].id,p_data[2].name,p_data[2].head_img_url,p_data[2].score,
		p_data[3].id,p_data[3].name,p_data[3].head_img_url,p_data[3].score,
		p_data[4].id,p_data[4].name,p_data[4].head_img_url,p_data[4].score
	))

end


--查询
function base.CMD.query_friendgame_record_ids(_player_id)

	return player_friendgame_history_record_ids[_player_id] or {}

end



local function get_friendgame_history_record(_id)

	local sql = string.format("select * from friendgame_history_record where id = %s;",_id)
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	local data = {
		id = ret[1].id,
		game_name = ret[1].game_name,
		time = ret[1].time,
		room_no = ret[1].room_no,
		player_infos = {},
	}

	for i=1,4 do
		
		local t = ret[1]["p"..i.."_name"]
		if t and string.len(t)>0 then
			data.player_infos[i]={
				id = ret[1]["p"..i.."_id"],
				name = PUBLIC.sql_strv(ret[1]["p"..i.."_name"]),
				head_img_url = ret[1]["p"..i.."_head_img_url"],
				score = ret[1]["p"..i.."_score"],
			}
		end

	end

	return data

end

local query_history_record_lock = {}
--查询
function base.CMD.query_friendgame_history_record(_player_id,_id)

	local t = query_history_record_lock[_player_id] or 0
	if t+1 >= os.time() then
		return {}
	end
	query_history_record_lock[_player_id] = os.time()


	local ids = player_friendgame_history_record_ids[_player_id]

	local datas = {}
	for i,id in ipairs(ids) do
		if _id then
			if _id == id then
				return get_friendgame_history_record(id)
			end
		else
			datas[#datas+1] = get_friendgame_history_record(id)
		end
	end

	return datas

end







--[[

]]
local function add_friendgame_room_race_record_log(_room_id,_race_id)

	-- 写入数据库
	base.DATA.sql_queue_slow:push_back(
		string.format([[
				insert into friendgame_room_race_log
				(id,room_id,race_id)
				values(NULL,%d,%d);
			]]
			,_room_id
			,_race_id
	))

end

--[[
	id
	game_type
	room_no
	room_owner
	room_rent
	room_options
	begin_time
	end_time
	over_reason

]]
function base.CMD.add_friendgame_room_record_log(game_type,room_no,room_owner,room_rent,room_options,begin_time,end_time,over_reason,race_ids)
	friendgame_room_log_max_id = friendgame_room_log_max_id + 1

	local log = {
		id = friendgame_room_log_max_id,
		game_type = game_type,
		room_no = room_no,
		room_owner = room_owner,
		room_rent = room_rent,
		room_options = room_options,
		begin_time = begin_time,
		end_time = end_time,
		over_reason = over_reason,
	}

	-- 写入数据库
	base.DATA.sql_queue_slow:push_back(
		string.format([[
				insert into friendgame_room_log
				(id,game_type,room_no,room_owner,room_rent,room_options,begin_time,end_time,over_reason)
				values(%d,'%s','%s','%s',%d,'%s',FROM_UNIXTIME(%u),FROM_UNIXTIME(%u),'%s');
			]]
			,log.id
			,log.game_type
			,log.room_no
			,log.room_owner
			,log.room_rent
			,log.room_options
			,log.begin_time
			,log.end_time
			,log.over_reason
	))
	
	for i,race_id in ipairs(race_ids) do
		add_friendgame_room_race_record_log(friendgame_room_log_max_id,race_id)
	end

end






return PROTECTED