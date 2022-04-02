--
-- Author: yy
-- Date: 2018-9-6 20:44:19
-- 说明：普通比赛场的数据存储
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECTED = {}

-- 初始化比赛数据
function PROTECTED.init_data()

	return true
end


function CMD.query_redeem_code_log()

	local sql = "select id,key_code,code_sub_type,player_id,code_type,UNIX_TIMESTAMP(use_time) time from redeem_code_log order by id;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	return ret

end




function CMD.query_redeem_code_data()

	local sql = "select * from redeem_code_data;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	return ret

end


function CMD.add_redeem_code_data(_name,_code_type,_code_sub_type,_use_type,_use_args,_start_time,_end_time,_register_limit_time,_assets)

	DATA.sql_queue_slow:push_back(
		string.format([[insert into redeem_code_data
						(name,code_type,code_sub_type,use_type,use_args,start_time,end_time,register_limit_time,assets)
						values('%s','%s','%s','%s','%s', %d , %d , %d , '%s')
						on duplicate key update
						code_type = code_type;
		]],
		_name,_code_type,_code_sub_type,_use_type,_use_args,_start_time,_end_time,_register_limit_time,_assets)
	)

end

function CMD.delete_add_redeem_code_data(_code_type,_code_sub_type)
	
	-- if _code_sub_type then
	-- 	DATA.sql_queue_slow:push_back(
	-- 		string.format([[delete from redeem_code_data where code_type='%s' and code_sub_type='%s';]],
	-- 		_code_type,_code_sub_type)
	-- 	)
	-- else
	-- 	DATA.sql_queue_slow:push_back(
	-- 		string.format([[delete from redeem_code_data where code_type='%s' and code_sub_type='%s';]],
	-- 		_code_type)
	-- 	)
	-- end

	CMD.delete_redeem_code_content_by_type(_code_type,_code_sub_type)

end



function CMD.query_redeem_code_content()

	local sql = "select * from redeem_code_content;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	return ret

end

function CMD.add_redeem_code_content(_code_type,_code_sub_type,_key_codes)

	for i,c in ipairs(_key_codes) do
		
		DATA.sql_queue_slow:push_back(
			string.format([[insert into redeem_code_content
							(code_type,code_sub_type,key_code,used_count)
							values('%s','%s','%s',0)
							on duplicate key update
							used_count = 0;
			]],
			_code_type,_code_sub_type,c)
		)

	end

end


function CMD.update_redeem_code_content(_key_code,_used_num)

		DATA.sql_queue_slow:push_back(
			string.format([[update redeem_code_content set used_count=%d where key_code='%s';
			]]
			,_used_num
			,_key_code)
		)
end



function CMD.delete_redeem_code_content_by_type(_code_type,_code_sub_type)

	if _code_sub_type then
		DATA.sql_queue_slow:push_back(
			string.format([[delete from redeem_code_content where code_type='%s' and code_sub_type='%s';]],
			_code_type,_code_sub_type)
		)
	else
		DATA.sql_queue_slow:push_back(
			string.format([[delete from redeem_code_content where code_type='%s';]],
			_code_type)
		)
	end

end


function CMD.delete_redeem_code_content_by_code(_key_codes)

	for i,c in ipairs(_key_codes) do
		
		DATA.sql_queue_slow:push_back(
			string.format([[delete from redeem_code_content where key_code='%s';]],
			c)
		)

	end

end



function CMD.add_redeem_code_log(_player_id,_key_code,_code_type,_code_sub_type,_comment)

	DATA.sql_queue_slow:push_back(
		string.format([[insert into redeem_code_log
						(key_code,player_id,code_type,code_sub_type,comment,use_time)
						values('%s','%s','%s','%s','%s',FROM_UNIXTIME(%u));
		]],
		_key_code,_player_id,_code_type,_code_sub_type,_comment,os.time())
	)

end


function CMD.add_redeem_code_opt_log(_type,_comment)

	DATA.sql_queue_slow:push_back(
		string.format([[insert into redeem_code_opt_log
						(type,comment,opt_time)
						values('%s','%s',FROM_UNIXTIME(%u));
		]],
		_type,_comment,os.time())
	)

end


return PROTECTED