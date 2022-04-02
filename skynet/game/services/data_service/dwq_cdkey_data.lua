--
-- Author: hw
-- Date: 2018/5/8
-- 说明：兑物券数据
-- dwq_cdkey_data

local skynet = require "skynet_plus"
local base = require "base"
local DATA = base.DATA
local PUBLIC=base.PUBLIC
local CMD=base.CMD
local basefunc = require "basefunc"

local player_cdkey={}
local cdkey={}

local function load_dwq_cdkey_data()
	local sql="select * from dwq_cdkey"
	local ret = base.DATA.db_mysql:query(sql)
	if ret.errno then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]
		cdkey[row.cdkey]=row
		player_cdkey[row.player_id]=player_cdkey[row.player_id] or {}
		player_cdkey[row.player_id][cdkey]=row
	end	
end

function CMD.query_player_cdkey(_p_id)
	return player_cdkey[_p_id]
end
function CMD.query_all_cdkey()
	return cdkey
end
function CMD.add_cdkey(data)
	cdkey[data.cdkey]=data
	player_cdkey[data.player_id]=player_cdkey[data.player_id] or {}
	player_cdkey[data.player_id][cdkey]=data
	local sql = string.format("insert into dwq_cdkey(player_id,asset_type,cdkey,time) values ('%s','%s','%s',FROM_UNIXTIME(%u));",data.player_id,data.asset_type,data.cdkey,data.time)
	base.DATA.sql_queue_fast:push_back(sql)
	return true
end
--type:1 被使用 2 自动销毁
function CMD.use_cdkey(_cdkey,_use_id,_use_time,_use_type)
	local data=cdkey[_cdkey]
	if data then
		cdkey[_cdkey]=nil
		player_cdkey[data.player_id][_cdkey]=nil
		--增加和扣除相应的财产
		-- if _use_type==1 then
			
		-- else
			
		-- end
		--写入日志和清除对应row
		local sql = string.format("delete from cdkey where cdkey='%s';",_cdkey)
		base.DATA.sql_queue_fast:push_back(sql)
		local sql = string.format("insert into dwq_cdkey_use_log(use_id,owner_id,asset_type,cdkey,use_type,use_time,create_time) values ('%s','%s','%s','%s',%u,FROM_UNIXTIME(%u),FROM_UNIXTIME(%u))",_use_id,data.player_id,data.asset_type,data.cdkey,_use_type,_use_time,data.time)
		base.DATA.sql_queue_slow:push_back(sql)
	end
	return false
end
-- 初始化玩家信息
function PUBLIC.init_dwq_cdkey_data()

	load_dwq_cdkey_data()

	return true
end


