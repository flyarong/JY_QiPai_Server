--- 玩家的 大富豪 数据

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local loadstring = rawget(_G, "loadstring") or load

local LOCAL_FUNC = {}

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECT = {}

DATA.player_dafuhao_data = {}

---- 
function PROTECT.parse_step_process_data(_data)
	if not _data then
		return nil
	end

	local code = "return " .. _data
	local ok, ret = xpcall(function ()
		local data = loadstring(code)()
		if type(data) ~= 'table' then
			data = {}
			print("parse_step_process_data error : {}")
		end
		return data
	end
	,function (err)
		print("parse_step_process_data error : ".._data)
		print(err)
	end)

	if not ok then
		ret = {}
	end

	return ret or {},ok
end


function PROTECT.init_data()

	local sql = "select * from player_da_fu_hao_data;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	local data = {}
	for i = 1,#ret do
		local row = ret[i]
		
		row.step_process = PROTECT.parse_step_process_data(row.step_process)

		data[row.player_id] = row

	end

	DATA.player_dafuhao_data = data

	return true
end

function CMD.query_one_player_dafuhao_data(_player_id)
	return DATA.player_dafuhao_data[_player_id]
end


function CMD.add_or_update_dafuhao_data(_player_id , _now_game_profit_acc , _now_charge_profit_acc , _now_credits , _now_game_num , _have_get_award_num )
	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_now_game_profit_acc = %s;
								SET @_now_charge_profit_acc = %s;
								SET @_now_credits = %s;
								SET @_now_game_num = %s;
								SET @_have_get_award_num = %s;
								insert into player_da_fu_hao_data
								(player_id,now_game_profit_acc,now_charge_profit_acc,now_credits,now_game_num,have_get_award_num)
								values(@_player_id,@_now_game_profit_acc,@_now_charge_profit_acc,@_now_credits,@_now_game_num,@_have_get_award_num )
								on duplicate key update
								player_id = @_player_id,
								now_game_profit_acc = @_now_game_profit_acc,
								now_charge_profit_acc = @_now_charge_profit_acc,
								now_credits = @_now_credits,
								now_game_num = @_now_game_num,
								have_get_award_num = @_have_get_award_num;]]
							,_player_id
							,_now_game_profit_acc
							,_now_charge_profit_acc
							,_now_credits
							,_now_game_num
							,_have_get_award_num
							 )

	base.DATA.sql_queue_slow:push_back(sql)
end



return PROTECT