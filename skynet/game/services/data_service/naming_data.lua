--
-- Author: yy
-- Date: 2018-9-6 20:44:19
-- 说明：普通比赛场的数据存储
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
require "data_func"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECTED = {}


-- 初始化比赛数据
function PROTECTED.init_data()

	return true
end

-- 查询一个比赛的rank信息
function CMD.query_naming_match_rank(_match_id)

	local sql = string.format([[
						select * from naming_match_rank where match_id = %s order by rank;
					]],_match_id)

	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return {}
	end

	return ret
	
end


-- 更新一条比赛排行信息
function CMD.insert_naming_match_rank(_match_id,_info)

	base.DATA.sql_queue_slow:push_back(
		string.format([[
						SET @_match_id = %s;
						SET @_match_name = '%s';
						SET @_match_model = '%s';
						SET @_player_id = '%s';
						SET @_player_name = '%s';
						SET @_head_link = '%s';
						SET @_score = %s;
						SET @_hide_score = %s;
						SET @_revive_num = %s;
						SET @_rank = %s;
						insert into naming_match_rank
						(match_id,match_name,match_model,player_id,player_name,head_link,score,hide_score,revive_num,rank)
						values(@_match_id,@_match_name,@_match_model,@_player_id,@_player_name,@_head_link,@_score,@_hide_score,@_revive_num,@_rank);
		]],
		_match_id,
		_info.match_name,
		_info.match_model,
		_info.player_id,
		PUBLIC.sql_strv(_info.player_name),
		_info.head_link or '',
		_info.score or 0 ,
		_info.hide_score or 0 ,
		_info.revive_num or 0 ,
		_info.rank or 0)
	)

end



return PROTECTED