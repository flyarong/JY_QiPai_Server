--- 玩家的周卡数据

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local LOCAL_FUNC = {}

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

---- 

local PROTECT = {}

function PROTECT.init_data()

	return true
end

function CMD.query_all_zhouka_data()
	local sql = "select * from player_zhouka;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	local data = {}
	for i = 1,#ret do
		local row = ret[i]
		
		data[row.player_id] = row

	end

	return data
end

function CMD.add_or_update_zhouka_data(_player_id , _is_buy_jingbi_zhouka , _jingbi_zhouka_remain , _is_buy_qys_zhouka , _qys_zhouka_remain )
	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_is_buy_jingbi_zhouka = %s;
								SET @_jingbi_zhouka_remain = %s;
								SET @_is_buy_qys_zhouka = %s;
								SET @_qys_zhouka_remain = %s;
								insert into player_zhouka
								(player_id,is_buy_jingbi_zhouka,jingbi_zhouka_remain,is_buy_qys_zhouka,qys_zhouka_remain)
								values(@_player_id,@_is_buy_jingbi_zhouka,@_jingbi_zhouka_remain,@_is_buy_qys_zhouka,@_qys_zhouka_remain)
								on duplicate key update
								player_id = @_player_id,
								is_buy_jingbi_zhouka = @_is_buy_jingbi_zhouka,
								jingbi_zhouka_remain = @_jingbi_zhouka_remain,
								is_buy_qys_zhouka = @_is_buy_qys_zhouka,
								qys_zhouka_remain = @_qys_zhouka_remain;]]
							,_player_id
							,_is_buy_jingbi_zhouka
							,_jingbi_zhouka_remain
							,_is_buy_qys_zhouka
							,_qys_zhouka_remain )

	base.DATA.sql_queue_slow:push_back(sql)
end


return PROTECT