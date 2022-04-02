--
-- Author: lyx
-- Date: 2018/4/19
-- Time: 19:59
-- 说明：斗地主的数据存储
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
require"printfunc"

local cjson = require "cjson"
cjson.encode_sparse_array(true,1,0)


local PROTECTED = {}

local LOCAL_FUNC = {}

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA


local player_object_data = {}
local object_attribute_data = {}

local object_seq_id = 0

function PROTECTED.init_data()

	local sql = "select * from player_object;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]
		local pod = player_object_data[row.player_id] or {}
		player_object_data[row.player_id] = pod
		pod[row.object_id]=row.object_type
	end


	local sql = "select * from object_attribute;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
		local row = ret[i]
		local oad = object_attribute_data[row.object_id] or {}
		object_attribute_data[row.object_id] = oad
		oad[row.attribute_name] = row.attribute_value
	end

	return true
end


-- 产生新的物品ID号
local function gen_object_id()

	object_seq_id = object_seq_id + 1

    if object_seq_id > 999 then
    	object_seq_id = 1
    end

    local ts = os.date("%Y%m%d%H%M%S")

    return string.format("o%s%s%s",ts,skynet.random_str(3),object_seq_id)
end


--[[
	{
		"2018123456987xzsaf"={
			object_type = "prop_xzad",
			attribute={
				name=value,
				time=1254201364,
			}
		},
		"2018123456987xzsaf"={
			object_type = "prop_xzad",
			attribute={
				name=value,
				time=1254201364,
			}
		},
	}
]]
function CMD.query_player_object_data(_player_id)

	local d = {}
	local pod = player_object_data[_player_id]
	if pod then
		for object_id,object_type in pairs(pod) do
			d[object_id]=
			{
				object_type = object_type,
				attribute = object_attribute_data[object_id]
			}
		end
	end
	--dump(d,"d++++++")
	return d
end



--[[增加一个道具物品 (返回 object_id)
	_data = 
	{
		player_id = "1016524",
		object_type = "prop_xzad",

		attribute={
			name=value,
			time=1254201364,
		}
	}
]]
function CMD.insert_object_data(_data,...)
	
	_data.object_id = gen_object_id()

	local pod = player_object_data[_data.player_id] or {}
	player_object_data[_data.player_id] = pod
	pod[_data.object_id] = _data.object_type

	object_attribute_data[_data.object_id] = _data.attribute

	-- 只记录真人的
	if not basefunc.chk_player_is_real(_data.player_id) then
		return _data.object_id
	end

	local sqls = {}

	sqls[#sqls+1] = PUBLIC.format_sql([[
					insert into player_object
					(player_id,object_id,object_type)
					values(%s,%s,%s);
				]]
				,_data.player_id,_data.object_id,_data.object_type)
	
	for k,v in pairs(_data.attribute) do
		
		sqls[#sqls+1] = PUBLIC.format_sql([[
						insert into object_attribute
						(object_id,attribute_name,attribute_value)
						values(%s,%s,%s);
					]]
		,_data.object_id,k,v)
	end

	base.DATA.sql_queue_slow:push_back(table.concat(sqls))

	LOCAL_FUNC.object_opt_log(_data.player_id,_data.object_id,_data.object_type,"add"
								,_data.attribute,nil,...)

	return _data.object_id
end



--[[修改一个道具物品(属性)
	_data = 
	{
		object_id = "2018123456987xzsaf",
		player_id = "1016524",
		object_type = "xcx",

		attribute={
			name=value,
			time=1254201364,
		}
	}
]]
function CMD.update_object_data(_data,...)

	-- 只记录真人的
	if not basefunc.chk_player_is_real(_data.player_id) then
		return
	end

	LOCAL_FUNC.object_opt_log(_data.player_id,_data.object_id,_data.object_type,"update"
								,object_attribute_data[_data.object_id],_data.attribute,...)

	local delete_attribute = {}
	for k,v in pairs(object_attribute_data[_data.object_id]) do
		if not _data.attribute[k] then
			delete_attribute[k]=true
		end
	end

	object_attribute_data[_data.object_id] = _data.attribute
	
	local sqls = {}

	for k,v in pairs(_data.attribute) do
		
		sqls[#sqls+1] = PUBLIC.format_sql([[
						SET @_object_id = %s;
						SET @_attribute_name = %s;
						SET @_attribute_value = %s;
						insert into object_attribute
						(object_id,attribute_name,attribute_value)
						values(@_object_id,@_attribute_name,@_attribute_value)
						on duplicate key update
						attribute_value = @_attribute_value;
					]]
		,_data.object_id,k,v)
	end

	for k,v in pairs(delete_attribute) do
		
		sqls[#sqls+1] = PUBLIC.format_sql([[
						delete from object_attribute where object_id=%s and attribute_name=%s;
					]]
		,_data.object_id,k)
	end

	base.DATA.sql_queue_slow:push_back(table.concat(sqls))


end



--[[删除一个道具物品
	_data = 
	{
		object_id = "2018123456987xzsaf",
		player_id = "1016524",
		object_type = "xcx",
	}
]]
function CMD.delete_object_data(_data,...)

	-- 只记录真人的
	if not basefunc.chk_player_is_real(_data.player_id) then
		return
	end

	LOCAL_FUNC.object_opt_log(_data.player_id,_data.object_id,_data.object_type,"delete"
								,object_attribute_data[_data.object_id],nil,...)

	player_object_data[_data.player_id][_data.object_id] = nil
	object_attribute_data[_data.object_id] = nil
	
	local sqls = {}

	sqls[#sqls+1] = PUBLIC.format_sql([[
					delete from player_object where player_id=%s and object_id=%s;
				]]
	,_data.player_id,_data.object_id)

	sqls[#sqls+1] = PUBLIC.format_sql([[
					delete from object_attribute where object_id=%s;
				]]
	,_data.object_id)

	base.DATA.sql_queue_slow:push_back(table.concat(sqls))

end



--[[

	player_id
	object_id
	object_type
	object_opt
	ori_attribute
	final_attribute
	time
	change_type
	change_id
	change_way
	change_way_id

]]

function LOCAL_FUNC.object_opt_log(_player_id,_object_id,_object_type,_object_opt,_ori_attribute,_final_attribute,_change_type,_change_id,_change_way,_change_way_id)
	
	if _ori_attribute then
		_ori_attribute = cjson.encode(_ori_attribute)
	end

	if _final_attribute then
		_final_attribute = cjson.encode(_final_attribute)
	end
	
	local sql = PUBLIC.format_sql([[
					insert into player_object_log
					(player_id,object_id,object_type,object_opt,ori_attribute,final_attribute
						,time,change_type,change_id,change_way,change_way_id)
					values(%s,%s,%s,%s,%s,%s,FROM_UNIXTIME(%s),%s,%s,%s,%s);
				]]
				,_player_id,_object_id,_object_type,_object_opt,_ori_attribute,_final_attribute
				,os.time(),_change_type,_change_id,_change_way,_change_way_id)
	

	base.DATA.sql_queue_slow:push_back(sql)

end




return PROTECTED