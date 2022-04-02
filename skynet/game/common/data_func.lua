--
-- Author: lyx
-- Date: 2018/3/22
-- Time: 16:06
-- 说明：玩家相关的基础数据

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

-- 处理 sql 的字符串值，避免被注入
function PUBLIC.sql_strv(_str)
	local _r = string.gsub(tostring(_str),"['\"\\]","\\%0")
	return _r
end
local sql_strv = PUBLIC.sql_strv

function PUBLIC.db_exec(_sql,_queue_name)
	skynet.send(DATA.service_config.data_service,"lua","db_exec",_sql,_queue_name)
end
function PUBLIC.db_query(_sql)
	return skynet.call(DATA.service_config.data_service,"lua","db_query",_sql)
end

function PUBLIC.db_exec_va(_fmt,...)
	PUBLIC.db_exec(PUBLIC.format_sql(_fmt,...))
end
function PUBLIC.db_query_va(_fmt,...)
	return PUBLIC.db_query(PUBLIC.format_sql(_fmt,...))
end

--[[ 构造缓存数据
 参数：
 	_data_out 一个 lua 表，用于容纳输出的数据
	_rows 数据库中的行数据
	_table_name 数据表名称
	_sub_key_name 子健名

 说明：
 在 _data_out 中填充一个整理后的数据表，结构如下：
		table_name1 = {
			field_name1 = ,
			field_name2 = ,
			...
 		},
		table_name2 = {
			field_name1 = ,
			field_name2 = ,
			...
 		}
 		--多行的情况（ 必须给出 _sub_key_name）
		table_name3 = {
			_sub_key1 = { field_name1=,... },
			_sub_key2 = { field_name1=,... },
			...
 		}

--]]
function PUBLIC.gen_cache_data(_data_out,_rows,_table_name,_sub_key_name)

	local table_data = _data_out[_table_name] or {}
	_data_out[_table_name] = table_data

	if _sub_key_name then
		for _,row in ipairs(_rows) do
			local subkey = row[_sub_key_name]

			local sub_data = table_data[subkey] or {}
			table_data[subkey] = sub_data

			for k,v in pairs(row) do
				sub_data[k] = v
			end
		end

	elseif _rows[1] then

		for k,v in pairs(_rows[1]) do
			table_data[k] = v
		end

		if _rows[2] then
			skynet.fail(string.format("multi rows,must has sub key name:%s",_table_name))
		end
	end

end

-- 为 sql 结尾安全的加上分号
function PUBLIC.safe_sql_semicolon(_sql)
	for i=string.len(_sql),1,-1 do
		if ";" == string.sub(_sql,i,i) then
			return _sql
		end
	end

	return _sql .. ";"
end

-- 转换值为 sql 语句各式
function PUBLIC.value_to_sql(v)

	if not v then return "null" end

	if type(v) == "number" then
		return tostring(v)
	end

	-- 存在 __sql_expr 域
	if type(v) == "table" and v.__sql_expr then
		return type(v.__sql_expr) == "string" and v.__sql_expr or v.__sql_expr()
	end

	return table.concat({"'",sql_strv(v),"'"})
end
local value_to_sql = PUBLIC.value_to_sql

-- 格式化 sql 语句，会自动处理 空值、数据类型等
-- 注意：变量全用 %s 占位，并且不要加引号！！
function PUBLIC.format_sql(_str,...)
	local _param = {...}
	local _count = select("#",...)

	for i=1,_count do
		_param[i] = value_to_sql(_param[i])
	end

	return string.format(_str,table.unpack(_param))
end

local function _update_default_filter()
	return true
end

-- 根据给定的 键-值 对生成 sql 的 update set 子句
-- 参数 _filter ： （可选）过滤器表 或 函数，如果 返回 false，则不处理该字段
-- 返回值：如果没有字段更新，则返回空串 ""
function PUBLIC.gen_update_fields_sql(_fields,_filter)
	_filter = _filter or _update_default_filter

	local _set_sql = {}

	for _name,_value in pairs(_fields) do
		if "table" == type(_filter) and _filter[_name] or _filter(_name) then
			_set_sql[#_set_sql + 1] = _name .. "=" .. value_to_sql(_value)
		end
	end

	return table.concat(_set_sql,",")
end

-- 根据给定的字段表，构造数据库插入语句
function PUBLIC.gen_insert_sql(_table_name,_fields)
	local _names = {}
	local _values = {}

	for k,v in pairs(_fields) do
		_names[#_names + 1] = tostring(k)
		_values[#_values + 1] = value_to_sql(v)
	end

	return string.format("insert into %s (%s) values(%s);",tostring(_table_name),table.concat(_names,","),table.concat(_values,","))
end

-- 在 gen_insert_sql 基础上 增加 重复键 容错
-- 参数 _pri_keys ： 主键名称，如果是多个，格式： {key1=1,key2=1}
function PUBLIC.safe_insert_sql(_table_name,_fields,_pri_keys)
	local _names = {}
	local _values = {}

	local _up_set = {}
	
	local _pks
	if "table" == type(_pri_keys) then
		_pks = _pri_keys
	elseif "string" == type(_pri_keys) then
		_pks = {[_pri_keys]=1}
	else
		error(string.format("'gen_safe_insert_sql' ,table '%s' primary key error:%s",tostring(_table_name),tostring(_pri_keys)))
	end

	for k,v in pairs(_fields) do
		_names[#_names + 1] = tostring(k)
		_values[#_values + 1] = value_to_sql(v)

		if not _pks[k] then
			_up_set[#_up_set + 1] = string.format("%s=%s",tostring(k),_values[#_values])
		end
	end

	return string.format("insert into %s (%s) values(%s) on duplicate key update %s;",
		tostring(_table_name),table.concat(_names,","),table.concat(_values,","),table.concat(_up_set,","))
end

-- 执行查询语句
-- 参数：
--	_db_connect ： 数据库连接，可选
--	_sql : sql 语句
function PUBLIC.db_query( _db_connect,_sql )

	if type(_db_connect) ~= "table" then
		_sql = _db_connect
		_db_connect = DATA.db_mysql
	end

	local ret = _db_connect:query(_sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",_sql,basefunc.tostring( ret )))
		return ret
	end

	if not skynet.getcfg("forbid_sql_log") then
		print("sql succ:",_sql)
	end
	return ret
end

function PUBLIC.db_query_va( _db_connect,_sql_fmt,...)
	local _sql
	if type(_db_connect) ~= "table" then
		_sql = string.format(_db_connect,_sql_fmt,...)
		_db_connect = DATA.db_mysql
	else
		_sql = string.format(_sql_fmt,...)
	end

	local ret = _db_connect:query(_sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",_sql,basefunc.tostring( ret )))
		return ret
	end

	if not skynet.getcfg("forbid_sql_log") then
		print("va sql succ:",_sql)
	end
	return ret
end

local system_variant

-- 数据库中原始值，用于判断是否需要 写库保存
local system_variant_orig = {}

-- 得到一个自增长 id
function PUBLIC.auto_inc_id(_name)
	system_variant[_name] = system_variant[_name] + 1
	return system_variant[_name]
end

function PUBLIC.init_system_variant()

	system_variant = DATA.system_variant

	if not system_variant then
		return  -- 未定义系统变量
	end

	local sql = "select * from system_variant"
	local ret = DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do

		local var = system_variant[ret[i].name]
		if var and type(var) == "number" then
			system_variant[ret[i].name] = tonumber(ret[i].value)
		else
			system_variant[ret[i].name] = ret[i].value
		end

		system_variant_orig[ret[i].name] = system_variant[ret[i].name]
	end

	-- ###_temp 临时 写数据库方案，以后 可以使用全局 update 事件
	skynet.timer(1,function()
		if "wait" == DATA.current_service_status then
			return false
		end

		for name,var in pairs(system_variant) do
			if system_variant_orig[name] ~= var then
				local sql = string.format("INSERT INTO system_variant(name,value)VALUES('%s','%s') on duplicate key update value='%s';",
					name,tostring(var),tostring(var))
				DATA.sql_queue_fast:push_back(sql)

				system_variant_orig[name] = var
			end
		end
	end)

	return true
end
