--
-- Author: YY
-- Date: 2018/5/10
-- Time: 
-- 说明: 冻结信息
local skynet = require "skynet_plus"
local basefunc=require"basefunc"
require "data_func"
require"printfunc"
local base = require "base"

local nodefunc = require "nodefunc"

local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC
local REQUEST=base.REQUEST
local PROTECT={}

DATA.player_block_status = {}
local player_block_status = DATA.player_block_status


function PROTECT.init_data()
	local sql = "SELECT player_id,block_status FROM player_block_status;"
	local ret = base.DATA.db_mysql:query(sql)

	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i=1,#ret do
		local row = ret[i]
		player_block_status[row.player_id]=row
	end
end



--冻结 锁定一个用户 
function base.CMD.block_player(_player_id,_reason,_op_user)

	if not CMD.is_player_exists(_player_id) then
		return 2159
	end

	nodefunc.send(_player_id,"kick")

	if player_block_status[_player_id] then
		return 2701
	end

	player_block_status[_player_id]=
	{
		player_id = _player_id,
		block_status = 1,
		reason = _reason,
		op_user = _op_user,
	}

	base.DATA.sql_queue_fast:push_back(PUBLIC.safe_insert_sql("player_block_status",player_block_status[_player_id],"player_id"))

	-- 加入到日志
	base.DATA.sql_queue_slow:push_back(PUBLIC.gen_insert_sql("player_block_status_log",player_block_status[_player_id]))

	return 0
end



-- 解除 对用户  的 冻结 锁定
function base.CMD.unblock_player(_player_id,_reason,_op_user)
	
	if not CMD.is_player_exists(_player_id) then
		return 2159
	end

	if not player_block_status[_player_id] then
		return 2702
	end

	local sql = string.format([[delete from player_block_status where player_id='%s';]],
								_player_id)
	
	base.DATA.sql_queue_fast:push_back(sql)
	
	if player_block_status[_player_id] then
		
		player_block_status[_player_id].block_status = 0
		player_block_status[_player_id].reason = _reason
		player_block_status[_player_id].op_user = _op_user
		
		-- 加入到日志
		base.DATA.sql_queue_slow:push_back(PUBLIC.gen_insert_sql("player_block_status_log",player_block_status[_player_id]))

		player_block_status[_player_id]=nil
	end

	return 0
end



--查询冻结的一个玩家
function base.CMD.query_block_player(_player_id)
	return player_block_status[_player_id]
end

--查询冻结列表
function base.CMD.query_block_list()
	return player_block_status
end

--[[从数据库获取直接获取玩家冻结列表
	主要用于外部查询使用
	有频次限制 10/s
]]
local query_block_list_from_db_clock = {}
function base.CMD.query_block_list_from_db()

	local key = os.time()
	local num = query_block_list_from_db_clock[key]
	if not num then
		num = 0
		query_block_list_from_db_clock={}
	end
	query_block_list_from_db_clock[key] = num + 1

	if num > 10 then
		return nil,1000
	end

	local sql = string.format([[
		SELECT
		player_block_status.player_id,
		player_info.`name`,
		bind_phone_number.phone_number,
		player_block_status.block_status,
		player_block_status.block_time,
		player_block_status.reason
		FROM
		player_block_status
		LEFT JOIN player_info ON player_block_status.player_id = player_info.id
		LEFT JOIN bind_phone_number ON player_block_status.player_id = bind_phone_number.player_id;
	 ]])
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		print(string.format("query_user_assets_from_db sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( asset_ret )))
		return nil,1001
	end

	return ret,0
end


return PROTECT

