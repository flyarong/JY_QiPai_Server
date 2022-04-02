--
-- Author: yy
-- Date: 2018/4/19
-- Time: 19:59
-- 说明：装扮的数据存储
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local PROTECTED = {}

local LOCAL_FUNC = {}

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local tmp_table = {}

local player_dressed_data = {}

local player_dress_info_data = {}


function PROTECTED.init_data()

	local sql = "select * from player_dressed;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]
		
		player_dressed_data[row.player_id] = row

	end

	local sql = "select * from player_dress_info;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]
		
		player_dress_info_data[row.player_id] = player_dress_info_data[row.player_id] or {}
		local pdid = player_dress_info_data[row.player_id]
		pdid[row.dress_type] = pdid[row.dress_type] or {}
		local pdt = pdid[row.dress_type]
		pdt[row.dress_id]={
			num = row.num,
			time = row.time,
		}

	end

	return true
end


local player_dressed_data_init_data = {dressed_head_frame = 41}
function CMD.query_player_dressed_data(_player_id)

	return player_dressed_data[_player_id] or player_dressed_data_init_data

end

function CMD.update_player_dressed_data(_player_id,_dressed_head_frame)

	player_dressed_data[_player_id] = player_dressed_data[_player_id] or {}
	player_dressed_data[_player_id].player_id = _player_id
	player_dressed_data[_player_id].dressed_head_frame = _dressed_head_frame

	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_dressed_head_frame = %s;
								insert into player_dressed
								(player_id,dressed_head_frame)
								values(@_player_id,@_dressed_head_frame)
								on duplicate key update
								dressed_head_frame = @_dressed_head_frame;]]
							,_player_id
							,_dressed_head_frame)

	base.DATA.sql_queue_slow:push_back(sql)

end


-- 默认的装扮，不需要存储，可以随意无限制使用 直接返回 id HASH
local player_dress_free_data = 
{
	-- head_frame = {

	-- },
	-- expression = {

	-- },
	-- phrase = {

	[1] = true,
	[2] = true,
	[3] = true,
	[4] = true,
	[5] = true,
	[6] = true,
	[7] = true,
	[8] = true,
	[9] = true,
	[10] = true,
	[11] = true,
	[12] = true,
	[13] = true,
	[18] = true,
	[19] = true,
	[20] = true,
	[21] = true,
	[22] = true,
	[23] = true,
	[24] = true,
	[25] = true,
	[26] = true,
	[27] = true,
	[28] = true,
	[29] = true,
	[30] = true,
	[35] = true,
	[36] = true,
	[37] = true,
	[38] = true,
	[39] = true,
	[40] = true,

	-- },
}

--新用户初始化默认的数据
function CMD.query_player_dress_free_data()
	
	return player_dress_free_data

end

function CMD.query_player_dress_info_data(_player_id)

	return player_dress_info_data[_player_id] or tmp_table

end


function CMD.update_player_dress_info_data(_player_id,_dress_type,_dress_id,_num,_time)
	local pdid = player_dress_info_data[_player_id]
	if not pdid then
		player_dress_info_data[_player_id] = {}
		pdid = player_dress_info_data[_player_id]
	end

	pdid[_dress_type] = pdid[_dress_type] or {}

	pdid[_dress_type][_dress_id] = pdid[_dress_type][_dress_id] or {num=-1,time=-1}
	local pdi = pdid[_dress_type][_dress_id]
	pdi.num = _num or pdi.num
	pdi.time = _time or pdi.time

	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_dress_type = '%s';
								SET @_dress_id = %s;
								SET @_num = %s;
								SET @_time = %s;
								insert into player_dress_info
								(player_id,dress_type,dress_id,num,time)
								values(@_player_id,@_dress_type,@_dress_id,@_num,@_time)
								on duplicate key update
								num = @_num,
								time = @_time;]]
							,_player_id
							,_dress_type
							,_dress_id
							,pdi.num
							,pdi.time)

	base.DATA.sql_queue_slow:push_back(sql)

end


--log
function CMD.insert_player_dress_info_log(_player_id,_dress_type,_dress_id,_num,_time,_change_type)

	--[[
		num and time
		+1 增加 1 
		-1 减少 1
		0 解锁
	]]

	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_dress_type = '%s';
								SET @_dress_id = %s;
								SET @_num = %s;
								SET @_time = %s;
								SET @_change_type = '%s';
								SET @_log_time = FROM_UNIXTIME(%u);
								insert into player_dress_info_log
								(id,player_id,dress_type,dress_id,num,time,change_type,log_time)
								values(NULL,@_player_id,@_dress_type,@_dress_id,@_num,@_time,@_change_type,@_log_time);]]
							,_player_id
							,_dress_type
							,_dress_id
							,_num
							,_time
							,_change_type
							,os.time())

	base.DATA.sql_queue_slow:push_back(sql)

end



return PROTECTED