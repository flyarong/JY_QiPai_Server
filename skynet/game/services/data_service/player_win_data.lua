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


local statistics_player_ddz_win_data = {}
local statistics_player_mj_win_data = {}


-- 初始化玩家斗地主自由场数据
function PROTECTED.init_data()

	LOCAL_FUNC.init_statistics_player_ddz_win_data()

	LOCAL_FUNC.init_statistics_player_mj_win_data()

	return true
end



-- 统计相关 ***************
--[[
{
	id = _player_id,
	dizhu_win_count = _dizhu_win,
	nongmin_win_count = _nongmin_win,
}
]]

function LOCAL_FUNC.init_statistics_player_ddz_win_data()

	local sql = "select * from statistics_player_ddz_win"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]
		statistics_player_ddz_win_data[row.id]=row
	end

end


--[[
	_type
	0 - lose
	1 - nongmin_win
	2 - dizhu_win
]]
function base.CMD.update_statistics_player_ddz_win_data(_player_id,_type)

	statistics_player_ddz_win_data[_player_id]=base.CMD.get_statistics_player_ddz_win_data(_player_id)

	if _type == 0 then
		local cn = statistics_player_ddz_win_data[_player_id].defeated_count
		statistics_player_ddz_win_data[_player_id].defeated_count = cn + 1
	elseif _type == 1 then
		local cn = statistics_player_ddz_win_data[_player_id].nongmin_win_count
		statistics_player_ddz_win_data[_player_id].nongmin_win_count = cn + 1
	elseif _type == 2 then
		local cn = statistics_player_ddz_win_data[_player_id].dizhu_win_count
		statistics_player_ddz_win_data[_player_id].dizhu_win_count = cn + 1
	end

	base.DATA.sql_queue_slow:push_back(
		string.format([[
						SET @_player_id = '%s';
						SET @_dizhu_win_count = %d;
						SET @_nongmin_win_count = %d;
						SET @_defeated_count = %d;

						insert into statistics_player_ddz_win
						(id,
						dizhu_win_count,
						nongmin_win_count,
						defeated_count)

						values						
						(@_player_id,
						@_dizhu_win_count,
						@_nongmin_win_count,
						@_defeated_count)

						on duplicate key update 
						id = @_player_id,
						dizhu_win_count = @_dizhu_win_count,
						nongmin_win_count = @_nongmin_win_count,
						defeated_count = @_defeated_count;
						]],
						statistics_player_ddz_win_data[_player_id].id,
						statistics_player_ddz_win_data[_player_id].dizhu_win_count,
						statistics_player_ddz_win_data[_player_id].nongmin_win_count,
						statistics_player_ddz_win_data[_player_id].defeated_count)
	)

end


function base.CMD.get_statistics_player_ddz_win_data(_player_id)
	return statistics_player_ddz_win_data[_player_id] or 
	{
		id = _player_id,
		dizhu_win_count = 0,
		nongmin_win_count = 0,
		defeated_count = 0,
	}

end



-- 统计相关 ***************
--[[
{
	id = _player_id,
	dizhu_win_count = _dizhu_win,
	nongmin_win_count = _nongmin_win,
}
]]

function LOCAL_FUNC.init_statistics_player_mj_win_data()

	local sql = "select * from statistics_player_mj_win"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]
		statistics_player_mj_win_data[row.id]=row
	end

end


--[[
	_type
	0 - lose
	1 - win
]]
function base.CMD.update_statistics_player_mj_win_data(_player_id,_type)

	statistics_player_mj_win_data[_player_id]=base.CMD.get_statistics_player_mj_win_data(_player_id)

	if _type == 0 then
		local cn = statistics_player_mj_win_data[_player_id].defeated_count
		statistics_player_mj_win_data[_player_id].defeated_count = cn + 1
	elseif _type == 1 then
		local cn = statistics_player_mj_win_data[_player_id].win_count
		statistics_player_mj_win_data[_player_id].win_count = cn + 1
	end

	base.DATA.sql_queue_slow:push_back(
		string.format([[
						SET @_player_id = '%s';
						SET @_win_count = %d;
						SET @_defeated_count = %d;

						insert into statistics_player_mj_win
						(id,
						win_count,
						defeated_count)

						values						
						(@_player_id,
						@_win_count,
						@_defeated_count)

						on duplicate key update 
						id = @_player_id,
						win_count = @_win_count,
						defeated_count = @_defeated_count;
						]],
						statistics_player_mj_win_data[_player_id].id,
						statistics_player_mj_win_data[_player_id].win_count,
						statistics_player_mj_win_data[_player_id].defeated_count)
	)

end


function base.CMD.get_statistics_player_mj_win_data(_player_id)
	return statistics_player_mj_win_data[_player_id] or 
	{
		id = _player_id,
		win_count = 0,
		defeated_count = 0,
	}

end


return PROTECTED











