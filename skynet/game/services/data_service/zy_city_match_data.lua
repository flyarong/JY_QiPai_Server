--
-- Author: lyx
-- Date: 2018/4/19
-- Time: 19:59
-- 说明：load_and_close_ser_data
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local PROTECTED = {}

local LOCAL_FUNC = {}


--
function base.CMD.query_zy_city_match_rank_hx()

	local sql = "select * from zy_city_match_rank_hx;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	return ret

end


function base.CMD.add_zy_city_match_rank_hx(_id,_name,_award,_rank)

	local sql = string.format("insert into zy_city_match_rank_hx values('%s','%s','%s',%s);"
								,_id
								,_name
								,_award
								,_rank
								)

	base.DATA.sql_queue_fast:push_back(sql)

end


--
function base.CMD.query_zy_city_match_rank_fs()

	local sql = "select * from zy_city_match_rank_fs;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end
	
	return ret

end


function base.CMD.add_zy_city_match_rank_fs(_data)

	for i,d in ipairs(_data) do

		local sql = string.format("insert into zy_city_match_rank_fs values('%s','%s','%s',%s);"
									,d.id
									,d.name
									,d.award
									,d.rank
									)

		base.DATA.sql_queue_fast:push_back(sql)

	end

end


function base.CMD.add_zy_city_match_fs_lose(_data)

	for player_id,d in pairs(_data) do

		local sql = string.format("insert into zy_city_match_fs_lose values('%s',%s);"
									,player_id
									,d.rank
									)

		base.DATA.sql_queue_fast:push_back(sql)

	end

end

--
function base.CMD.query_zy_city_match_hx_lose()

	local sql = "select * from zy_city_match_hx_lose;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	return ret

end


function base.CMD.add_zy_city_match_hx_lose(_id)

	local sql = string.format("insert into zy_city_match_hx_lose values('%s');"
								,_id
								)

	base.DATA.sql_queue_fast:push_back(sql)

end


function base.CMD.delete_zy_city_match_hx_lose(_id)

	local sql = string.format("delete from zy_city_match_hx_lose where player_id='%s';"
								,_id
								)

	base.DATA.sql_queue_fast:push_back(sql)

end


return PROTECTED