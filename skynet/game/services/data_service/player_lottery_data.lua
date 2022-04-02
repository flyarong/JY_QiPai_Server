--
-- Author: lyx
-- Date: 2018/4/19
-- Time: 19:59
-- 说明：斗地主的数据存储
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local cjson = require "cjson"
cjson.encode_sparse_array(true,1,0)

local PROTECTED = {}

local LOCAL_FUNC = {}

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA




function PROTECTED.init_data()

	return true
end



function CMD.query_player_lottery_data()

	local sql = "select * from player_lottery;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	local lottery_data = {}

	for i = 1,#ret do
		local row = ret[i]
		
		lottery_data[row.player_id] = row

	end

	return lottery_data

end


function CMD.update_player_lottery_data(_data)
	
	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_lottery_time = %s;
								SET @_lottery_asset = %s;
								SET @_lottery_item_count = %s;
								SET @_lottery_asset_time = %s;
								insert into player_lottery
								(player_id,lottery_time,lottery_asset,lottery_item_count,lottery_asset_time)
								values(@_player_id,@_lottery_time,@_lottery_asset,@_lottery_item_count,@_lottery_asset_time)
								on duplicate key update
								lottery_time = @_lottery_time,
								lottery_asset = @_lottery_asset,
								lottery_item_count = @_lottery_item_count,
								lottery_asset_time = @_lottery_asset_time;]]
							,_data.player_id
							,_data.lottery_time
							,_data.lottery_asset
							,_data.lottery_item_count
							,_data.lottery_asset_time)

	base.DATA.sql_queue_slow:push_back(sql)

end


function CMD.query_player_lottery_luck_box_data()

	local sql = "select * from player_lottery_luck_box;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	local lottery_data = {}

	for i = 1,#ret do
		local row = ret[i]
		
		local ld = lottery_data[row.player_id] or {}
		lottery_data[row.player_id] = ld

		ld[row.id] = row

		if not ld.open and row.open == 1 then
			ld.open = 1
		end

		row.lottery_result = cjson.decode(row.lottery_result)

		row.player_id = nil
		row.id = nil
		row.open = nil

	end

	return lottery_data

end


function CMD.update_player_lottery_luck_box_data(_player_id,_id,_data)
	
	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_id = %s;
								SET @_open = %s;
								SET @_lottery_num = %s;
								SET @_lottery_jb_num = %s;
								SET @_lottery_time = %s;
								SET @_lottery_result = '%s';
								SET @_box = %s;

								insert into player_lottery_luck_box
								(player_id,id,open,lottery_num,lottery_jb_num,lottery_time,lottery_result,box)
								values(@_player_id,@_id,@_open,@_lottery_num,@_lottery_jb_num,@_lottery_time,@_lottery_result,@_box)
								on duplicate key update
								open = @_open,
								lottery_num = @_lottery_num,
								lottery_jb_num = @_lottery_jb_num,
								lottery_time = @_lottery_time,
								lottery_result = @_lottery_result,
								box = @_box;]]
							,_player_id
							,_id
							,_data.open
							,_data.lottery_num
							,_data.lottery_jb_num
							,_data.lottery_time
							,_data.lottery_result
							,_data.box
							)

	base.DATA.sql_queue_slow:push_back(sql)

end

return PROTECTED