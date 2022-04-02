--
-- Author: lyx
-- Date: 2018/3/26
-- Time: 8:58
-- 说明：玩家信息数据
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "data_func"
require "normal_enum"
require "printfunc"

local monitor_lib = require "monitor_lib"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

-- 后台数据需要拉取日志的财富类型
local back_sys_log_assets =
{
	["diamond"] 		= true,
	["jing_bi"] 		= true,
	["room_card"] 		= true,
}

local sql_strv = base.PUBLIC.sql_strv

local function get_asset_log_id(_asset_type)
	if not back_sys_log_assets[_asset_type] then
		return -1 -- 不更新
	end

	return PUBLIC.auto_inc_id("last_asset_log_seq")
end

local PROTECTED = {}

--[[
-- 玩家的信息数据： userId -> 数据
-- 数据结构说明：
	userId = {
		--玩家信息
		player_info = {
			id = ,
			login_channel = ,
			...
 		},
 		--玩家设备
		player_device_info = {
			...
 		}
 		--玩家财务
		player_asset = {
			match_ticket = ,
			room_card = ,
			...
 		}
 		--玩家道具（一 对 多）
		player_prop = {
			prop_type1 = { prop_count=,... },
			prop_type2 = { prop_count=,... },
			...
 		}
		--登录验证表
		player_verify = {
			phone = { login_id=,... },
			weixin_gz = { login_id=,... },
			...
 		}
 		--玩家open_id
 		open_id={
				[key=app_id]=open_id
 		}
 		--玩家alipay_account
 		alipay_account={
 			name
 			account
 		}
	}
--]]
PUBLIC.player_info = {}
local player_info = PUBLIC.player_info

-- 验证表 player_verify 中的数据。
-- ###_warning 注意： 始终保证这里是全量数据！新注册用户必须加进来
-- channel_type,login_id 两层映射： channel_type -> {login_id -> {行数据} }
-- 并且附带一个总数 count
PUBLIC.player_verify_data = {}
local player_verify_data = PUBLIC.player_verify_data

--[[ 所有玩家状态： id => {
	status="off"/"on"(离线/在线),
	channel=渠道,time=上线/离线时间,
	first_login_time=首次登录时间（惰性加载）
 }
--]]
PUBLIC.all_player_status = {}
local all_player_status = PUBLIC.all_player_status

-- 微信的 open id 缓存
local wechat_open_id_cache = {}

-- 玩家在线人数： channel => 数量
PUBLIC.onine_player_count = {}
onine_player_count = PUBLIC.onine_player_count

local player_init_loaded = false

local player_xsyd_status = {}

local player_everyday_shared_status = {}


local player_broke_subsidy_data = {}
-----------------------------------------------------------
-- 内部函数
--

-- 初始化用户清单
local function init_player_list()

	-- 加载用户 id 清单

	local _now = os.time()

	-- 加载用户状态 ###_temp 可能要 将不活跃用户定期清理到历史表！！
	local sql = "select id from player_info"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
	else
		for i = 1,#ret do
			all_player_status[ret[i].id] = {status="off",time=_now,channel=nil}
		end
	end

	-- 加载验证数据

	local sql = "select * from player_verify"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
	end

	for i = 1,#ret do
		local row = ret[i]
		local channel = player_verify_data[row.channel_type] or {}
		player_verify_data[row.channel_type] = channel

		local pstatus = all_player_status[row.id]
		if pstatus then
			pstatus.channel = row.channel_type
		else
			print(string.format("user id '%s' is not exist,login id:'%s'!",row.id,row.login_id))
		end

		channel[row.login_id] = row
	end

	player_verify_data.count = #ret

end

-- 加载指定的表
-- 参数：
--		_userId,_table_name 用户id，数据表名； 
--				特殊情况： 如果 _userId 是一个表，则为 {字段名,值} 的格式
--		_field_names 需要载入的字段，默认载入所有字段值
--		_sub_key_name 子键名，如果不为空，则数据放在 以此字段为键 的 lua 表中
-- 返回：数据行数，出错返回 nil
function PROTECTED.load_player_table(_data_out,_userId,_table_name,_field_names,_sub_key_name)
	local fields
	if _field_names then
		fields = table.concat(_field_names,",")
	else
		fields = "*"
	end

	local sql
	if type(_userId) == "table" then
		sql = string.format("select %s from %s where %s='%s'",fields,_table_name,_userId[1],_userId[2])
	else
		sql = string.format("select %s from %s where id='%s'",fields,_table_name,_userId)
	end
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return nil
	end
	base.PUBLIC.gen_cache_data(_data_out,ret,_table_name,_sub_key_name)

	return #ret
end

-- function PROTECTED.load_player_open_id(user,_userId)
-- 	local sql = string.format("select * from player_open_id where player_id = '%s'",_userId)
-- 	local row = base.DATA.db_mysql:query(sql)

-- 	if( row.errno ) then
-- 		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( row )))
-- 		return false
-- 	end
-- 	user.open_id={}	

-- 	for key,data in ipairs(row) do
-- 		user.open_id[data.app_id] = data.open_id
-- 	end

-- 	return ret
-- end
-- function PROTECTED.load_player_alipay_account(user,_userId)
-- 	local sql = string.format("select * from player_alipay_account where player_id = '%s'",_userId)
-- 	local row = base.DATA.db_mysql:query(sql)

-- 	if( row.errno ) then
-- 		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( row )))
-- 		return false
-- 	end
	

-- 	for key,data in ipairs(row) do
-- 		user.alipay_account=data
-- 	end

-- 	return ret
-- end

function base.PUBLIC.get_open_id(_user_id)

	local _oid = wechat_open_id_cache[_user_id]
	if _oid then
		return _oid
	end

	local sql = string.format("select extend_1 from player_verify where channel_type = 'wechat' and id='%s'",_user_id)
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return nil,1010
	end

	if not ret[1] or not ret[1].extend_1 then
		return nil,2159
	end

	wechat_open_id_cache[_user_id] = ret[1].extend_1
	return ret[1].extend_1
end

-- 根据登录 id 、渠道， 找到玩家id
-- 如果 _channel_type 为 nil，则每个渠道尝试，并且 在第二个参数返回 渠道
function base.CMD.userId_from_login_id(_login_id,_channel_type)
	if _channel_type then
		if not player_verify_data[_channel_type] then
			return nil
		else
			local _d = player_verify_data[_channel_type][_login_id]
			return _d and _d.id or nil
		end
	end

	for _ct,_data in pairs(player_verify_data) do
		if _data[_login_id] then
			return _data[_login_id],_ct
		end
	end

	return nil
end

-- 加载玩家信息
function base.PUBLIC.load_player_info(_userId)

	if player_info[_userId] then return player_info[_userId] end

	local user = {}

	local info_result = PROTECTED.load_player_table(user,_userId,"player_info")
	if not info_result or info_result == 0 then
		return nil -- 没有用户数据
	end
	if player_info[_userId] then return player_info[_userId] end

	PROTECTED.load_player_table(user,_userId,"player_asset")
	if player_info[_userId] then return player_info[_userId] end

	PROTECTED.load_player_table(user,_userId,"player_device_info")
	if player_info[_userId] then return player_info[_userId] end

	PROTECTED.load_player_table(user,_userId,"player_prop",nil,"prop_type")
	if player_info[_userId] then return player_info[_userId] end

	PROTECTED.load_player_table(user,_userId,"player_register",{"register_time","market_channel"})
	if player_info[_userId] then return player_info[_userId] end

	-- PROTECTED.load_player_open_id(user,_userId)
	-- if player_info[_userId] then return player_info[_userId] end
	
	-- PROTECTED.load_player_alipay_account(user,_userId)
	-- if player_info[_userId] then return player_info[_userId] end

	PROTECTED.load_player_table(user,{"player_id",_userId},"player_open_id",nil,"app_id")
	if player_info[_userId] then return player_info[_userId] end

	PROTECTED.load_player_table(user,{"player_id",_userId},"player_alipay_account")
	if player_info[_userId] then return player_info[_userId] end

	-- 初始化道具
	user.object_data = base.CMD.query_player_object_data(_userId)

	player_info[_userId]  = user

	return user
end
local load_player_info = base.PUBLIC.load_player_info


-- 初始化玩家信息
function PROTECTED.init_player_info()

	--初始化用户清单
	init_player_list()

	-- 在这里载入活跃用户 ###_temp 应该是放一个列表中，或者一个 专门的lua 文件中，作为配置文件
	-- load_player_info("userid_1")
	-- load_player_info("userid_2")

	PROTECTED.init_player_xsyd_status()

	PROTECTED.init_shared_award_status()

	PROTECTED.init_broke_subsidy_data()

	-- 每分钟写入在线统计数据
	skynet.timer(60,function ()

		if "wait" == base.DATA.current_service_status then
			return false
		end

		local _sqls = {"set @_now_time=now();\n"}
		for _channel,_count in pairs(onine_player_count) do
			_sqls[#_sqls + 1] = string.format("insert into statistics_system_realtime(time,channel,player_count) values(@_now_time,'%s',%u);\n",_channel,_count)
		end

		base.DATA.sql_queue_slow:push_back(table.concat(_sqls))
	end)

	player_init_loaded = true
	return true
end

-- 面额数组，从大到小排序
local shop_gold_faces

-- 根据金额拆分 面额
-- 返回表 type => 数量
local function regroup_shop_gold(_gold)

	if not shop_gold_faces then
		shop_gold_faces = {}
		for _value,_ in pairs(SHOP_GOLD_PROPTYPES) do
			shop_gold_faces[#shop_gold_faces + 1] = _value
		end

		table.sort(shop_gold_faces,function (v1,v2)
			return v1 > v2
		end)
	end

	local _ret = {}

	for _,_v in ipairs(shop_gold_faces) do
		if _v <= _gold then
			local _count = math.modf(_gold/_v)
			_gold = math.fmod(_gold,_v)

			local _type = SHOP_GOLD_PROPTYPES[_v]
			_ret[_type] = (_ret[_type] or 0) + _count
		end
	end

	return _ret
end

-- 重组购物金面额
local function regroup_shop_gold_face(_userId,_user,_new_value)

	-- 新的面额： prop_type -> prop_count
	local _new_golds = regroup_shop_gold(_new_value)

	local sqls = {}

	-- 重组现有的面额，注意：因为总金额已有日志，这里没有日志，强制设置！
	for _type,_value in pairs(SHOP_GOLD_FACEVALUES) do
		local prop = _user.player_prop[_type] or {prop_type=_type}
		_user.player_prop[_type] = prop
		prop.prop_count = _new_golds[_type] or 0

		if prop.prop_count > 0 then
			sqls[#sqls + 1] = string.format("INSERT INTO player_prop(id,prop_type,prop_count)VALUES('%s','%s',%f) on duplicate key update prop_count=%f;",
			_userId,_type,_new_golds[_type],_new_golds[_type])
		else
			sqls[#sqls + 1] = string.format("DELETE FROM player_prop where id = '%s' and prop_type = '%s';",
			_userId,_type)
		end
	end

	base.DATA.sql_queue_fast:push_back(table.concat(sqls,"\n"))
end

-- 修改玩家的财富值
--	_table_name 表名字
--	_field_name 字段名字
--	_inc_value 要修改的值
--	_sql_fast 是否插入到高速 sql 队列，默认插入到 低速 队列
-- 返回：
--	成功，则返回新的值； 失败返回 nil
-- 注意：此函数不支持更新带有子键的 表
function PROTECTED.change_player_asset(_userId,_table_name,_field_name,_inc_value,_sql_fast)

	-- 从数据库载入到缓存
	local user = load_player_info(_userId)

	if not user then
		print(string.format("change_player_asset %s error:not found player '%s'",tostring(_table_name),tostring(_userId)))
		return nil
	end

	if not _table_name then
		skynet.fail("_table_name cannt be nil !")
		return nil
	end

	local tdata = user[_table_name]
	if not tdata then
		skynet.fail(string.format("change_player_asset error:table %s,field %s data not found!",_table_name,_field_name))
		return nil
	end

	local new_value = tdata[_field_name] + _inc_value
	-- if new_value < 0 then
	-- 	skynet.fail(string.format("change_player_asset error:user %s, table %s,field %s ,cur %s,inc %s,less zero!!",
	-- 		tostring(_userId),_table_name,_field_name,tdata[_field_name] , _inc_value))
	-- 	return nil
	-- end

	-- 修改缓存值
	tdata[_field_name] = new_value

	-- 插入到 sql 队列
	local sql = string.format("update %s set %s=%s where id='%s'",
		_table_name,_field_name,base.PUBLIC.value_to_sql(tdata[_field_name]),_userId)
	if _sql_fast then
		base.DATA.sql_queue_fast:push_back(sql)
	else
		base.DATA.sql_queue_slow:push_back(sql)
	end

	-- 重组购物金
	if _field_name == "shop_gold_sum" then
		regroup_shop_gold_face(_userId,user,tdata[_field_name])
	end

	return tdata[_field_name]
end

---------------------------------------------------
-- 供外部服务调用的命令
--

-- 获取验证数据（供验证服务调用）
function base.CMD.get_all_verify_data()

	while not player_init_loaded do
		skynet.sleep(10)
	end

	return player_verify_data

end

-- 收集一组用户的设备 token
function base.CMD.get_users_device_token(_user_ids)

	-- 这是临时方案，一次性发送大量用户时，要 通过 列表实现（一次性加载大量用户 可能导致性能问题）
	assert(#_user_ids < 10,"too many users!!")

	local ret = {ios={},android={}}
	for _,_user_id in ipairs(_user_ids) do
		local user = load_player_info(_user_id)
		local di = user and user.player_device_info
		if di and di.device_token and di.device_type and ret[di.device_type] then

			table.insert(ret[di.device_type],di.device_token)
		end
	end

	return ret
end


-- 获取验证数据
function base.CMD.get_player_verify_data(_login_id,_channel_type)

	local vd = player_verify_data[_channel_type]
	if vd then
		return vd[_login_id]
	end

	return nil
end



-- 更新验证数据（如果没改变则不会更新）
function base.PUBLIC.update_verify_data(_channel_type,_login_id,_data)

	if not player_verify_data[_channel_type] then
		print("update_verify_data error:login id '%s',not found channel '%s' !",tostring(_login_id),tostring(_channel_type))
		return false
	end

	local verify_data = player_verify_data[_channel_type][_login_id]
	if not verify_data then
		print("update_verify_data error:not found login id '%s',channel '%s' !",tostring(_login_id),tostring(_channel_type))
		return false
	end

	-- sql 的 set 子句
	local _set_sql = base.PUBLIC.gen_update_fields_sql(_data,function(_name)
		if _data[_name] ~= verify_data[_name] then
			verify_data[_name] = _data[_name]
			return true
		else
			return false
		end
	end)

	if _set_sql ~= "" then
		base.DATA.sql_queue_slow:push_back("update player_verify set " .. _set_sql .. string.format(" where login_id='%s' and channel_type='%s';",_login_id,_channel_type))
	end

end

-- 更新用户基础数据（如果没改变则不会更新）
function base.PUBLIC.update_base_player_info(_userId,_data)

	local user = load_player_info(_userId)

	if not user then
		print(string.format("update_base_player_info error:not found player '%s'",tostring(_userId)))
		return false
	end

	-- 检查是否有改变
	local _changed = false
	for _name,_value in pairs(_data) do
		if _data[_name] ~= user.player_info[_name] then
			_changed = true
			break
		end
	end

	if not _changed then
		print("player info not change old:",basefunc.tostring(user.player_info))
		print("player info not change new:",basefunc.tostring(_data))
		return
	end

	-- 增长同步序号
	_data.sync_seq = PUBLIC.auto_inc_id("last_player_info_seq")

	-- sql 的 set 子句
	local _set_sql = base.PUBLIC.gen_update_fields_sql(_data,function(_name)
		if _data[_name] ~= user.player_info[_name] then
			user.player_info[_name] = _data[_name]
			return true
		else
			return false
		end
	end)

	if _set_sql ~= "" then
		print("update_base_player_info:",_set_sql,_userId)
		base.DATA.sql_queue_slow:push_back("update player_info set " .. _set_sql .. string.format(" where id='%s';",_userId))
	else

		print("player info sql not change old:",basefunc.tostring(user.player_info))
		print("player info sql not change new:",basefunc.tostring(_data))

	end

	return true
end

-- 验证用户修改
-- 注意：新用户首次登录不会调用此函数
-- 返回 0 或 错误号
function base.CMD.verify_user(_channel_type,_userId,_verify_data,_user_data)

	-- 检查是否被临时禁止登录
	if base.DATA.reject_login_users[_userId] then
		if base.DATA.reject_login_users[_userId] > os.time() then
			return 2158
		end

		base.DATA.reject_login_users[_userId] = nil
	end

	if base.DATA.player_block_status[_userId] then
		return 2158
	end

	local _user = base.PUBLIC.load_player_info(_userId)

	if not _user then
		return 1004
	end

	if _user.is_block == 1 then
		return 2158
	end

	if _user_data then
		base.PUBLIC.update_base_player_info(_userId,_user_data)
	else
		print("_user_data is nil,not update user info:",_channel_type,_userId,basefunc.tostring(_verify_data),basefunc.tostring(_user_data))
	end

	base.PUBLIC.update_verify_data(_channel_type,_verify_data.login_id,_verify_data)

	if not _user.player_info.name or "" == _user.player_info.name then
		print("error ,user name is nil:",_channel_type,_userId,basefunc.tostring(_verify_data),basefunc.tostring(_user_data))
	end

	return 0
end


math.randomseed( os.time() + os.clock() * 100000 ) -- 随机种子
local function gen_user_id(_login_id)

	if string.sub(_login_id,1,5) == "robot" then
		-- 机器人的 login id 和 user id 用同一个
		return _login_id
	else
		local sysvar = base.DATA.system_variant

		sysvar.last_user_index = sysvar.last_user_index + math.random(10)

		-- 前2位暂时保留为 服务器id，以便以后分服
		return "10" .. tostring(sysvar.last_user_index)
	end
end

--[[
	创建玩家信息（新注册玩家时 使用）
	先检查 登录 id ，如果已经存在， 则直接直接返回 id
	参数：
	  	_register_data : （必须）用户注册数据。
			{
				channel_type=, (必须)渠道类型，参见 verify_service.lua
				introducer=, (可选) 推荐人的用户 id
				register_os=, (可选) 注册的操作系统
				register_ip=, (可选)注册的ip
			}
	  	_verify_data : （必须）验证结果数据，如果失败，则为错误号。
			{
				login_id=, (必须)登录id
				password=, (可选) 用户密码
				refresh_token=, (可选) 刷新凭据，某些渠道需要，比如微信
				extend_1=, (可选)扩展数据1
				extend_2=, (可选)扩展数据2
			}
	  	_user_data : （可选）用户数据
			{
				name=, (可选)昵称
				head_image=, (可选)头像
				sex = (可选)性别
				sign=, (可选)签名
			}
	多个返回值：
		userId      成功返回用户 id；失败 返回 nil
		error_code  错误代码（用户 id 为 nil 时）；
]]
local _creating_login_id = {} -- 正在创建的 login_id
function base.CMD.create_player_info(_register_data,_verify_data,_user_data)

	local _channel_data = player_verify_data[_register_data.channel_type] or {}
	player_verify_data[_register_data.channel_type] = _channel_data

	-- 已经存在，直接返回
	if _channel_data[_verify_data.login_id] then
		print("create_player_info user is created:",_verify_data.login_id)
		return nil,1010
	end

	local _channel_creating = _creating_login_id[_register_data.channel_type] or {}
	_creating_login_id[_register_data.channel_type] = _channel_creating

	if _channel_creating[_verify_data.login_id] then
		print("channel login id is creating:",_verify_data.login_id)
		return nil,1038
	end

	-- 开始创建，锁定 login_id
	_channel_creating[_verify_data.login_id] = true

	local userId = gen_user_id(_verify_data.login_id)

	-- 添加到验证缓存
	_verify_data.id = userId
	_verify_data.channel_type = _register_data.channel_type
	_channel_data[_verify_data.login_id] = _verify_data

	-- 添加到用户数据缓存
	_user_data = _user_data or {}
	_user_data.id = userId
	_user_data.sync_seq = PUBLIC.auto_inc_id("last_player_info_seq")
	--_user_data.introducer = _register_data.introducer
	_user_data.kind = _register_data.channel_type=="robot" and "robot" or "normal"
	_user_data.name = _user_data.name or "未登录用户"
	_register_data.register_time = os.date("%Y-%m-%d %H:%M:%S")
	PUBLIC.player_info[userId] = {
		player_info = _user_data,
		player_asset = {id = userId,diamond=0,shop_ticket=0,cash=0,jing_bi=0,shop_gold_sum=0},
		player_prop = {},
		object_data = {},
		player_device_info = {},
		player_verify = _verify_data,
		player_register = _register_data,
	}

	-- 更新到数据库
	local sqls = {"start transaction;"}

	-- 表 player_info
	sqls[#sqls + 1] = base.PUBLIC.gen_insert_sql("player_info",_user_data)

	-- 表 player_verify
	sqls[#sqls + 1] = base.PUBLIC.gen_insert_sql("player_verify",_verify_data)

	-- 表 player_register
	sqls[#sqls + 1] = base.PUBLIC.gen_insert_sql("player_register",{
		id = userId,
		register_channel = _register_data.channel_type,
		login_id = _verify_data.login_id,
		introducer = _register_data.introducer,
		market_channel = _register_data.market_channel,
		register_ip = _register_data.register_ip,
		register_os = _register_data.register_os,
	})

	-- 表 player_asset
	sqls[#sqls + 1] = string.format("INSERT INTO `player_asset` (`id`) VALUES ('%s');",userId)

	sqls[#sqls + 1] = "commit;"

	--local _sqlexec = table.concat(sqls,"\n")
	--print("create_player_info:",_sqlexec)
	--base.DATA.sql_queue_fast:push_back(_sqlexec)
	base.DATA.sql_queue_fast:push_back(table.concat(sqls,"\n"))

	-- 如果有推荐人，设置上级玩家
	--[[if _register_data.introducer then
		PUBLIC.club_set_user_parent(userId,_register_data.introducer)
	end--]]

	-- 解除锁定
	_channel_creating[_verify_data.login_id] = nil

	all_player_status[userId] = {status="off",time=os.time(),channel=_register_data.channel_type}

	if _register_data.channel_type == "wechat" then
		monitor_lib.add_data("register",1)
	end

	return userId
end

-- function base.CMD.ensure_player_info(_userId)

-- 	return load_player_info(_userId) and true or false
-- end

-- 得到玩家信息
-- 参数：
--	_table_name 表名字，可选； 如果没给出，则返回所有数据
--	_field_name 字段名字，字符串 或 lua 表（多个字段名）； 如果为 nil ，则返回表的所有字段；
-- 返回
--	如果 _field_name 是一个字段名，则直接返回 值
--	如果 _field_name 是多个字段名的数组，则返回一个 键-值 表
--	出错则返回一个 nil
function base.CMD.get_player_info(_userId,_table_name,_field_name)
	local user = load_player_info(_userId)

	if not user then
		print(string.format("get_player_info %s error:not found player '%s'",tostring(_table_name),tostring(_userId)))
		return nil
	end

	-- 表名为空，返回所有数据
	if not _table_name then
		return user
	end

	local tdata = user[_table_name]
	if not tdata then
		print(string.format("get user '%s' data error: table '%s' not found!",tostring(_userId),tostring(_table_name)))
		return nil
	end

	-- 字段名为空，返回表的所有字段
	if not _field_name then
		return tdata
	end

	-- 返回多个字段值
	if "table" == type(_field_name) then
		local ret = {}
		for _,fname in pairs(_field_name) do
			ret[fname] = tdata[fname]
		end
		return ret
	end

	-- 返回单一的值
	return tdata[_field_name]

end

-- 函数保存到 local ，会快一点
local get_player_info = base.CMD.get_player_info
local change_player_asset = PROTECTED.change_player_asset

function base.CMD.query_asset(_palyer_id,_asset_type)
	-- 从数据库载入到缓存
	local user = load_player_info(_palyer_id)

	return user.player_asset[_asset_type] or 
		(user.player_prop[_asset_type] and user.player_prop[_asset_type].prop_count or 0)
end

-- 修改玩家信息
-- 参数：
--	_table_name 表名字
--	_values 字段名-值的 映射： {name1 = value1,...} 。注意：这些字段必须是同一个表的
--	_sql_fast 是否插入到高速 sql 队列，默认插入到 低速 队列
--	_not_inc_seq 不增长更新序号
-- 注意：此函数不支持更新带有子键的 表
-- 返回值： 0 或 错误号
function base.CMD.modify_player_info(_userId,_table_name,_values,_sql_fast,_not_inc_seq)

	local fname1 = next(_values)
	if not fname1 then
		return 1001
	end

	if not _table_name then
		skynet.fail("_table_name cannt be nil !")
		return 1001
	end

	-- 不允许对财富、道具直接修改
	if _table_name == "player_asset" or _table_name == "player_prop" then
		return 1001
	end

	-- 从数据库载入到缓存
	local user = load_player_info(_userId)

	if not user then
		print(string.format("modify_player_info %s error:not found player '%s'",tostring(_table_name),tostring(_userId)))
		return 1004
	end

	local tdata = user[_table_name]
	if not tdata then
		skynet.fail(string.format("update_player_info error:table %s data not found!",_table_name))
		return 1001
	end

	local sql

	if tdata.id then	-- id 存在，则为更新

		local up_set_sql = {}
		for k,v in pairs(_values) do
			-- 修改缓存值

			if tdata[k] ~= v then
				tdata[k] = v

				-- 生成 sql
				up_set_sql[#up_set_sql + 1] = string.format("%s=%s",k,base.PUBLIC.value_to_sql(v))
			end

		end

		if not up_set_sql[1] then
			return 0
		end

		if not _not_inc_seq then
			up_set_sql[#up_set_sql + 1] = string.format("sync_seq=%d",PUBLIC.auto_inc_id("last_player_info_seq"))
		end

		sql = string.format("update %s set %s where id='%s';",
			_table_name,table.concat(up_set_sql,","),_userId)

	else 			-- id 不存在，则为 新增

		local sql_fields = {"id"}
		local sql_values = {"'" .. _userId .. "'"}

		tdata.id = _userId
		for k,v in pairs(_values) do
			tdata[k] = v

			sql_fields[#sql_fields + 1] = "`" .. k .. "`"
			sql_values[#sql_values + 1] = base.PUBLIC.value_to_sql(v)
		end

		sql = string.format("insert into %s(%s) values(%s)",
			_table_name,table.concat(sql_fields,","),table.concat(sql_values,","))

	end

	if _sql_fast then
		base.DATA.sql_queue_fast:push_back(sql)
	else
		base.DATA.sql_queue_slow:push_back(sql)
	end

	return 0
end

-- 修改（增量） 现金
function base.CMD.change_cash(_userId,_assetType,_change,_change_type,_change_id,_change_way,_change_way_id)
	local newvalue = change_player_asset(_userId,"player_asset","cash",_change,true)
	if not newvalue then
		return false
	end

	-- 插入日志
	if basefunc.is_real_player(_userId) then
		local sql = string.format("insert into player_asset_log(id,asset_type,change_value,change_type,current,change_id,sync_seq,change_way,change_way_id) values ('%s','cash',%f,'%s',%f,'%s',%s,'%s','%s')",
			_userId,_change or 0,_change_type,newvalue or 0,_change_id,tostring(get_asset_log_id(_assetType)),_change_way or "",_change_way_id or 0)
		base.DATA.sql_queue_slow:push_back(sql)
	end

	return true
end

-- 修改（增量） 钻石
function base.CMD.change_diamond(_userId,_assetType,_change,_change_type,_change_id,_change_way,_change_way_id)
	local newvalue = change_player_asset(_userId,"player_asset","diamond",_change,true)
	if not newvalue then
		return false
	end

	-- 插入日志
	if basefunc.is_real_player(_userId) then
		local sql = string.format("insert into player_asset_log(id,asset_type,change_value,change_type,current,change_id,sync_seq,change_way,change_way_id) values ('%s','diamond',%f,'%s',%f,'%s',%s,'%s','%s')",
			_userId,_change or 0,_change_type,newvalue or 0,_change_id,tostring(get_asset_log_id(_assetType)),_change_way or "",_change_way_id or 0)
		base.DATA.sql_queue_slow:push_back(sql)

		if _change > 0 then
			monitor_lib.add_data("diamond",_change)
		end
	end

	return true
end


-- 修改（增量） 鲸币
function base.CMD.change_jing_bi(_userId,_assetType,_change,_change_type,_change_id,_change_way,_change_way_id)
	local newvalue = change_player_asset(_userId,"player_asset","jing_bi",_change,true)
	if not newvalue then
		return false
	end

	-- 插入日志
	if basefunc.is_real_player(_userId) then
		local sql = string.format("insert into player_asset_log(id,asset_type,change_value,change_type,current,change_id,sync_seq,change_way,change_way_id) values ('%s','jing_bi',%f,'%s',%f,'%s',%s,'%s','%s')",
			_userId,_change or 0,_change_type,newvalue or 0,_change_id,tostring(get_asset_log_id(_assetType)),_change_way or "",_change_way_id or 0)
		base.DATA.sql_queue_slow:push_back(sql)
	end

	return true
end

-- 修改购物金
function base.CMD.change_shop_gold_sum(_userId,_assetType,_change,_change_type,_change_id,_change_way,_change_way_id)
	local newvalue = change_player_asset(_userId,"player_asset","shop_gold_sum",_change,true)
	if not newvalue then
		return false
	end

	-- 插入日志
	if basefunc.is_real_player(_userId) then
		local sql = string.format("insert into player_asset_log(id,asset_type,change_value,change_type,current,change_id,sync_seq,change_way,change_way_id) values ('%s','shop_gold_sum',%f,'%s',%f,'%s',%s,'%s','%s')",
			_userId,_change or 0,_change_type,newvalue or 0,_change_id,tostring(get_asset_log_id(_assetType)),_change_way or "",_change_way_id or 0)
		base.DATA.sql_queue_slow:push_back(sql)
	end

	return true
end

-- 修改（增量） 抵用券
function base.CMD.change_shop_ticket(_userId,_assetType,_change,_change_type,_change_id,_change_way,_change_way_id)
	local newvalue = change_player_asset(_userId,"player_asset","shop_ticket",_change,true)
	if not newvalue then
		return false
	end

	-- 插入日志
	if basefunc.is_real_player(_userId) then
		local sql = string.format("insert into player_asset_log(id,asset_type,change_value,change_type,current,change_id,sync_seq,change_way,change_way_id) values ('%s','shop_ticket',%f,'%s',%f,'%s',%s,'%s','%s')",
			_userId,_change or 0,_change_type,newvalue,_change_id,tostring(get_asset_log_id(_assetType)),_change_way or "",_change_way_id or 0)
		base.DATA.sql_queue_slow:push_back(sql)
	end
	
	return true
end

-- 装扮类道具
function base.CMD.change_dress(_userId,_assetType,_change,_change_type,_change_id,_change_way,_change_way_id)
	
	local _t,_i = basefunc.parse_dress_asset(_assetType)

	-- 目前只有数量和时间
	local num,time=nil,nil
	num=_change

	if basefunc.is_real_player(_userId) then
		base.CMD.insert_player_dress_info_log(
				_userId,
				_t,
				_i,
				num or 0,
				time or 0,
				_change_type
			)
	end

	local dd = CMD.query_player_dress_info_data(_userId)
	local dt = dd[_t]
	if dt and dt[_i] then
		if dt[_i].num and dt[_i].num >= 0 then
			num = dt[_i].num + num
		else
			num = -1
		end
	end

	base.CMD.update_player_dress_info_data(
		_userId,
		_t,
		_i,
		num,
		time or 0
	)

	return true
end


-- 记牌器改变
function base.CMD.change_jipaiqi(_userId,_assetType,_change,...)
	
	-- 从数据库载入到缓存
	local user = load_player_info(_userId)

	if not user then
		print(string.format("change_jipaiqi error:not found player '%s'",tostring(_userId)))
		return nil -- 玩家数据加载失败
	end

	if not _change then
		return nil
	end

	local object_data = user.object_data

	local jipaiqi_data = {}

	for object_id,d in pairs(object_data) do
		
		if d.object_type == "jipaiqi" then

			jipaiqi_data.object_id = object_id
			jipaiqi_data.valid_time = 0

			if d.attribute.valid_time then
				jipaiqi_data.valid_time = tonumber(d.attribute.valid_time)
			elseif d.attribute.always then
				-- 暂无
			end
			
		end

	end

	local time = 0

	if jipaiqi_data.object_id then

		time = os.time() + math.floor(_change*3600*24)

		if jipaiqi_data.valid_time > os.time() then
			time = jipaiqi_data.valid_time + math.floor(_change*3600*24)
		end

	else
		time = os.time() + math.floor(_change*3600*24)
	end

	local _obj_data = 
	{
		player_id = _userId,
		object_id = jipaiqi_data.object_id,
		object_type = "jipaiqi",
		attribute = {valid_time=time},
	}
	base.CMD.change_object(_userId,_obj_data,true,...)

	return _obj_data
end

local change_asset_func_map

-- 修改财物和道具
function base.CMD.change_asset(_userId,_assetType,_change_value,...)
	
	local func = change_asset_func_map[_assetType]
	if not func then
		
		if basefunc.is_dress_asset(_assetType) then
			func = base.CMD.change_dress
		elseif basefunc.is_object_asset(_assetType) then
			error("please use multi_change_asset_and_sendMsg !!!")
		else
			func = base.CMD.change_prop
		end

	end

	if not func then
		skynet.fail(string.format("change asset error:not found asset type '%s'",_assetType))
		return false
	end

	return func(_userId,_assetType,_change_value,...)
end

-- 修改财物和道具并且向玩家发送消息(通常是其他外部服务对玩家资产进行操作)
-- 记牌器还是普通资产一样调用 按数量计算一天的时间多个的时候进行累加
-- 不支持obj类型的道具 走(multi_change_asset_and_sendMsg 函数)
function base.CMD.change_asset_and_sendMsg(_userId,_assetType,_change_value,_change_type,...)
	local ret = base.CMD.change_asset(_userId,_assetType,_change_value,_change_type,...)
	if ret then
		local jpq_id = nil
		if _assetType == "jipaiqi" then
			jpq_id = ret.object_id
		end
		nodefunc.send(_userId,"multi_asset_on_change_msg",{[1]={asset_type=_assetType,value=_change_value,object_id=jpq_id}},_change_type)
	end
end

--[[修改财物和道具并且向玩家发送消息(通常是其他外部服务对玩家资产进行操作)
-- 记牌器还是普通资产一样调用 按数量计算一天的时间多个的时候进行累加
_asset_data={
		{asset_type=jing_bi,value=100},
		{asset_type=object_tick,value=o20125a1d21s,attribute={valid_time=123}},(增加减少道具都只能一个一个来)
	}
]] 
function base.CMD.multi_change_asset_and_sendMsg(_userId,_asset_datas,...)
	for i,asset in ipairs(_asset_datas) do

		if tonumber(asset.value) then

			local ret = base.CMD.change_asset(_userId,asset.asset_type,asset.value,...)

			if not ret then
				error("base.CMD.multi_change_asset_and_sendMsg".._userId)
				--dump(_asset_datas)
				return
			end

			local jpq_id = nil
			if asset.asset_type == "jipaiqi" then
				jpq_id = ret.object_id
			end
			asset.object_id = jpq_id
			
		else

			if asset.asset_type == "jipaiqi" then
				error("error add jipaiqi error")
			end

			local _obj_data = 
			{
				player_id = _userId,
				 object_type = asset.asset_type,
				 object_id = asset.value,
				 attribute = asset.attribute,
			}

			base.CMD.change_object(_userId,_obj_data,true,...)

			asset.value = _obj_data.object_id

		end

	end

	nodefunc.send(_userId,"multi_asset_on_change_msg",_asset_datas,...)

end


----------------------------------------------------------------------------------------------------
-- 修改不可重叠的物品道具 内部实现仍然是调用的 multi_asset_on_change_msg 接口

--[[
{
	object_id = xx21s2aw,
	object_type = _type, --新增时需要
	attribute = _data, -- nil 代表删除此物品
}
]]
function base.CMD.change_object(_userId,_obj_data,_not_send_msg,...)

	local user = load_player_info(_userId)

	if not user then
		print(string.format("change_object error:not found player '%s'",tostring(_userId)))
		return nil -- 玩家数据加载失败
	end
	
	user.object_data = user.object_data or {}

	local obj = user.object_data[_obj_data.object_id]

	if obj then

		if _obj_data.attribute then

			if type(_obj_data.attribute)~="table" 
				or not next(_obj_data.attribute) then

					print("update object error attribute is error or empty ")
					return
			end

			user.object_data[_obj_data.object_id].attribute = _obj_data.attribute
			local d = {
				player_id = _userId,
				object_id = _obj_data.object_id,
				object_type = _obj_data.object_type,
				attribute = _obj_data.attribute,
			}
			base.CMD.update_object_data(d,...)

		else

			user.object_data[_obj_data.object_id] = nil
			local d = {
				player_id = _userId,
				object_id = _obj_data.object_id,
				object_type = _obj_data.object_type,
			}
			base.CMD.delete_object_data(d,...)

		end

	else

		if not _obj_data.attribute 
			or not _obj_data.object_type 
			or type(_obj_data.attribute)~="table" 
			or not next(_obj_data.attribute) then

				print("add object error attribute is nil or empty 1 ")
				return
		end

		local d = {
			player_id = _userId,
			object_type = _obj_data.object_type,
			attribute = _obj_data.attribute,
		}
		_obj_data.object_id = base.CMD.insert_object_data(d,...)

		user.object_data[_obj_data.object_id] = _obj_data

	end
	
	if not _not_send_msg then
		nodefunc.send(_userId,"multi_asset_on_change_msg",{[1]={
				asset_type = _obj_data.object_type,
				value = _obj_data.object_id,
				attribute = _obj_data.attribute,
			}}
			,...)
	end

	return _obj_data
end


function base.CMD.multi_change_object(_userId,_obj_datas,_not_send_msg,...)

	local asset_datas = {}

	for i,_obj_data in pairs(_obj_datas) do
		base.CMD.change_object(_userId,_obj_data,true,...)

		if not _not_send_msg then
			asset_datas[#asset_datas+1] = 
			{
				asset_type = _obj_data.object_type,
				value = _obj_data.object_id,
				attribute = _obj_data.attribute,
			}
		end

	end

	if not _not_send_msg then
		nodefunc.send(_userId,"multi_asset_on_change_msg",asset_datas,...)
	end

end



----------------------------------------------------------------------------------------------------



-- 修改财物和道具并且向玩家发送消息 为 兑换码设计的
function base.CMD.give_assets_packet_by_redeem_code(_userId,_code,_change_type,_asset_datas)

	base.CMD.multi_change_asset_and_sendMsg(_userId,_asset_datas
				,ASSET_CHANGE_TYPE.REDEEM_CODE_AWARD,_change_type,"redeem_code",_code)

end



-- 得到道具数量
--	出错则返回一个 nil
function base.CMD.get_prop(_userId,_prop_type)
	local user = load_player_info(_userId)
	if not user then
		print(string.format("get_prop %s error:not found player '%s'",tostring(_prop_type),tostring(_userId)))
		return nil
	end

	local prop_data = user.player_prop[_prop_type]
	return prop_data and prop_data.prop_count or 0 -- 没有道具数据 则为 0
end

-- 修改购物金面额
--	成功，则返回新的值； 失败返回 nil
function base.CMD.change_shop_gold_face(_userId,_prop_type,_change,_change_type,_change_id,_change_way,_change_way_id)

	return base.CMD.change_shop_gold_sum(_userId,"shop_gold_sum",SHOP_GOLD_FACEVALUES[_prop_type] * _change,
		_change_type,_change_id,_change_way,_change_way_id)
end

-- 修改道具
--	成功，则返回新的值； 失败返回 nil
function base.CMD.change_prop(_userId,_prop_type,_change,_change_type,_change_id,_change_way,_change_way_id)

	-- 从数据库载入到缓存
	local user = load_player_info(_userId)

	if not user then
		print(string.format("change_prop %s error:not found player '%s'",tostring(_prop_type),tostring(_userId)))
		return nil -- 玩家数据加载失败
	end

	if not _change then
		return nil
	end

	if 0 == _change then
		return true -- 不用改变 也认为是成功
	end

	local prop_data = user.player_prop[_prop_type]
	if not prop_data then
		prop_data = {prop_count = 0,id=_userId,prop_type=_prop_type }
		user.player_prop[_prop_type] = prop_data
	end

	local new_value = prop_data.prop_count + _change
	if new_value < 0 then
		skynet.fail(string.format("change_prop %s error:player '%s' ,cur %s,inc %s,less zero!!",
			tostring(_prop_type),tostring(_userId),prop_data.prop_count , _change))
		return nil
	end

	prop_data.prop_count = new_value

	-- 对值的修改加到快速队列
	local sql = string.format("INSERT INTO player_prop(id,prop_type,prop_count)VALUES('%s','%s',%f) on duplicate key update prop_count=prop_count + %f;",
		_userId,_prop_type,prop_data.prop_count,_change)
	base.DATA.sql_queue_fast:push_back(sql)

	-- 日志 加到慢速队列
	sql = string.format("insert into player_prop_log(id,prop_type,change_value,change_type,current,change_id,shop_gold_sync_seq,change_way,change_way_id) values ('%s','%s',%f,'%s',%f,'%s',%s,'%s','%s')",
		_userId,_prop_type,_change or 0,_change_type,prop_data.prop_count,_change_id,tostring(get_asset_log_id(_prop_type)),_change_way or "",_change_way_id or 0)
	base.DATA.sql_queue_slow:push_back(sql)

	return true
end

change_asset_func_map = {
	diamond 			=base.CMD.change_diamond, 		-- 钻石
	jing_bi				=base.CMD.change_jing_bi, 		-- 鲸币
	cash 				=base.CMD.change_cash, 			-- 现金
	shop_gold_sum		=base.CMD.change_shop_gold_sum, -- 购物金，各面额的总数

	jipaiqi				=base.CMD.change_jipaiqi, 		-- 记牌器，用普通道具的接口(历史遗留)

	-- 面额处理新方式：根据新的总数（shop_gold_sum）重组面额
	shop_gold_10 		=base.CMD.change_shop_gold_face, 		-- 一毛钱的购物金
	shop_gold_100 		=base.CMD.change_shop_gold_face, 		-- 一块的购物金
	shop_gold_1000 		=base.CMD.change_shop_gold_face, 		-- 十块的购物金
	shop_gold_10000 	=base.CMD.change_shop_gold_face, 		-- 一百块的购物金
}

-- 物品兑换日志
function base.CMD.goods_exchange_log(_log_datas)
	base.DATA.sql_queue_slow:push_back(base.PUBLIC.gen_insert_sql("goods_exchange_log",_log_datas))
end

-- 判断用户是否加载，返回 true/false
function base.CMD.is_player_load(_userId)

	return player_info[_userId] ~= nil

end

-- 判断用户是否存在： 返回 true/false
-- 参数 _userId 可以是 一个 id  或数组；是数组 则任何一个不存在 均返回 false
function base.CMD.is_player_exists(_userId)

	if not _userId then
		return false
	elseif "string" == type(_userId) then
		return all_player_status[_userId] and true or false
	else
		for _,_id in ipairs(_userId) do
			if not all_player_status[_id] then
				return false
			end
		end

		return true
	end
end

-- 玩家是否在线： 返回 true/false
-- 参数 _userId 可以是 一个 id  或数组；是数组 则任何一个不在线 均返回 false
function base.CMD.is_player_online(_userId)
	if "string" == type(_userId) then
		return all_player_status[_userId] and all_player_status[_userId].status == "on" and true or false
	else
		for _,_id in ipairs(_userId) do
			if all_player_status[_id] and all_player_status[_id].status ~= "on" then
				return false
			end
		end

		return true
	end
end

--- add by wss
-- 获得一个玩家的最后一次登录的时间
function base.CMD.get_player_status_time( player_id )
	return all_player_status[_userId] and all_player_status[_userId].time or nil
end

-- 查询用户列表
function base.CMD.get_player_status_list()

	-- status = on / off

	return all_player_status

end

--- add by wss
-- 查询 真实 用户列表
function base.CMD.get_real_player_status_list()

	-- status = on / off
	local all_real_player_status = {}

	for player_id,data in pairs(all_player_status) do
		if basefunc.is_real_player(player_id) and data.status == "on" then
			all_real_player_status[player_id] = data
		end
	end

	return all_real_player_status

end


-- 用户登录：记录日志
function base.CMD.player_login(_userId,_login_ip,_login_os)

	local pstatus = all_player_status[_userId]
	if not pstatus then
		print("data service login error, user not exists:",_userId,_login_ip,_login_os)
		return
	end

	local _channel = pstatus.channel or "unknown"
	if _channel == "wechat" then
		monitor_lib.add_data("login",1)
	end

	if "on" ~= pstatus.status then
		onine_player_count[_channel] = (onine_player_count[_channel] or 0) + 1
	end

	pstatus.status = "on"
	pstatus.time = os.time()

	local sql = string.format("CALL sp_login('%s','%s','%s');",_userId,_login_ip or "",_login_os or "") ..

			-- 增长更新序号
			string.format("update player_info set sync_seq=%d where id='%s';",base.PUBLIC.auto_inc_id("last_player_info_seq"),_userId)

	base.DATA.sql_queue_slow:push_back(sql)

end

-- 用户登出： 记录日志
function base.CMD.player_logout(_userId)

	local pstatus = all_player_status[_userId]
	if not pstatus then
		print("data service logout error, user not exists:",_userId)
		return
	end

	if "on" == pstatus.status then
		local _channel = pstatus.channel or "unknown"
		onine_player_count[_channel] = math.max((onine_player_count[_channel] or 0) - 1,0)
	end

	pstatus.status = "off"
	pstatus.time = os.time()

	local sql = string.format("CALL sp_logout('%s');",_userId)
	base.DATA.sql_queue_slow:push_back(sql)

end


-------------------------新手引导相关------------------------

-- 用户登出： 记录日志
function PROTECTED.init_player_xsyd_status()

	-- 加载用户状态
	local sql = "select * from player_xsyd_status"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
	else
		for i = 1,#ret do
			player_xsyd_status[ret[i].player_id] = ret[i]
		end
	end

end


--
function base.CMD.player_xsyd_finish(_userId)

	if player_xsyd_status[_userId] then
		return
	end

	player_xsyd_status[_userId]=
	{
		player_id = _userId,
		status = 1,
		time = os.time(),
	}

	local sql = string.format([[insert into player_xsyd_status(
								player_id,
					 			status,
					 			time)
								values('%s',%d,FROM_UNIXTIME(%u));]]
								,_userId
								,1
								,os.time())
	base.DATA.sql_queue_fast:push_back(sql)

end


--
function base.CMD.query_player_xsyd(_userId)

	if player_xsyd_status[_userId] then
		return 1
	else
		return 0
	end

end


-- 新手引导的话费充过了
function base.CMD.player_xsyd_pay_finish(_userId)

	if not player_xsyd_status[_userId] then
		return 2801
	end

	if player_xsyd_status[_userId].status ~= 1 then
		return 2802
	end

	player_xsyd_status[_userId].status = 2

	local sql = string.format([[update player_xsyd_status set status = %s where player_id='%s';]]
								,2
								,_userId)
	base.DATA.sql_queue_fast:push_back(sql)

	return 0
end


-------------------------新手引导相关------------------------




-------------------------分享奖励相关------------------------

--初始化数据
function PROTECTED.init_shared_award_status()

	-- 加载用户状态
	local sql = "select * from player_everyday_shared_status"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
	else
		for i = 1,#ret do
			local ps = player_everyday_shared_status[ret[i].player_id] or {}
			player_everyday_shared_status[ret[i].player_id] = ps
			ps[ret[i].type] = {
								status = ret[i].status,
								time = ret[i].time,
							}

		end
	end

end

--[[type
	"shared_friend"
	"shared_timeline"
	"flaunt"
]]
function base.CMD.set_shared_award_status(_player_id,_type,_time,_status)

	_status = _status or 1

	local ps = player_everyday_shared_status[_player_id] or {}
	player_everyday_shared_status[_player_id] = ps

	local pst = ps[_type] or {}
	ps[_type] = pst
	pst.status = _status
	pst.time = _time

	local sql = string.format([[
				SET @_player_id = '%s';
				SET @_type = '%s';
				SET @_status = %d;
				SET @_time = %d;
				insert into player_everyday_shared_status
				(player_id,type,status,time)
				values(@_player_id,@_type,@_status,@_time)
				on duplicate key update
				status = @_status,
				time = @_time;
			]],_player_id,_type,pst.status,pst.time)

	base.DATA.sql_queue_fast:push_back(sql)

end


--初始化数据
function base.CMD.query_shared_award_status(_player_id)

	return player_everyday_shared_status[_player_id] or {}

end


-------------------------分享奖励相关------------------------



-------------------------破产补助奖励相关------------------------

--初始化数据
function PROTECTED.init_broke_subsidy_data()

	-- 加载用户状态
	local sql = "select * from player_broke_subsidy"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
	else

		for i = 1,#ret do
			player_broke_subsidy_data[ret[i].player_id] = ret[i]
		end

	end

end


function CMD.get_first_login_time(_player_id)

	local _d = PUBLIC.all_player_status[_player_id]
	if not _d then
		print(string.format("player status data error:'%s'!",_player_id))
		return os.time()
	end
	if _d.first_login_time then
		return _d.first_login_time
	end

	local ret = base.DATA.db_mysql:query(PUBLIC.format_sql("select UNIX_TIMESTAMP(first_login_time) utime from player_login_stat where id = %s;",_player_id))
	if ret.errno or not ret[1] then
		_d.first_login_time = os.time()
	else
		_d.first_login_time = ret[1].utime or os.time()
	end	

	return _d.first_login_time
end

--初始化数据
function base.CMD.update_broke_subsidy_data(_player_id,_data)

	local pbsd = player_broke_subsidy_data[_player_id] or {}
	player_broke_subsidy_data[_player_id] = pbsd

	pbsd.num = _data.num or 0
	pbsd.time = _data.time or 0
	pbsd.free_num = _data.free_num or 0
	pbsd.free_time = _data.free_time or 0
	pbsd.start_time = _data.start_time or CMD.get_first_login_time(_player_id)

	local sql = string.format([[
				SET @_player_id = '%s';
				SET @_num = %s;
				SET @_time = %d;
				SET @_free_num = %s;
				SET @_free_time = %d;
				SET @_start_time = %u;
				insert into player_broke_subsidy
				(player_id,num,time,free_num,free_time,start_time)
				values(@_player_id,@_num,@_time,@_free_num,@_free_time,@_start_time)
				on duplicate key update
				num = @_num,
				time = @_time,
				free_num = @_free_num,
				free_time = @_free_time,
				start_time = @_start_time;
			]],_player_id,pbsd.num,pbsd.time,pbsd.free_num,pbsd.free_time,pbsd.start_time)
			
	base.DATA.sql_queue_fast:push_back(sql)

end


--初始化数据
function base.CMD.query_broke_subsidy_data(_player_id)

	return player_broke_subsidy_data[_player_id] or 
	{
		num=0,
		time=0,
		free_num=0,
		free_time=0,
		start_time=CMD.get_first_login_time(_player_id)
	}
end



-------------------------破产补助奖励相关------------------------


--初始化数据
function base.CMD.add_gift_coupon_log(_player_id,_parent_id,_gift_coupon_content)

	local sql = PUBLIC.format_sql([[
				insert into player_gift_coupon_log
				(player_id,parent_id,gift_coupon_content,time)
				values(%s,%s,%s,FROM_UNIXTIME(%s));
			]],_player_id,_parent_id,_gift_coupon_content,os.time())

	base.DATA.sql_queue_fast:push_back(sql)

end


--初始化数据
function base.CMD.query_gift_coupon_data()

	local sql = "select * from player_gift_coupon_log;"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
	end

	return ret

end






--[[从数据库获取直接获取玩家的实时货币和道具
	主要用于外部查询使用
	有频次限制 10/s
]]
local query_user_assets_from_db_clock = {}
function base.CMD.query_user_assets_from_db(_userId)

	if type(_userId)~="string" or string.len(_userId)<1 then
		return nil,1001
	end

	local key = os.time()
	local num = query_user_assets_from_db_clock[key]
	if not num then
		num = 0
		query_user_assets_from_db_clock={}
	end
	query_user_assets_from_db_clock[key] = num + 1

	if num > 10 then
		return nil,1000
	end

	local sql = string.format([[select * from player_asset where id='%s';]]
				,_userId)
	local asset_ret = base.DATA.db_mysql:query(sql)
	if( asset_ret.errno ) then
		print(string.format("query_user_assets_from_db sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( asset_ret )))
		return nil,1001
	end
	if not asset_ret[1] then
		print(string.format("query_user_assets_from_db asset_ret[1] is nil"))
		return nil,1001
	end


	sql = string.format([[select * from player_prop where id='%s';]]
				,_userId)
	local prop_ret = base.DATA.db_mysql:query(sql)
	if( prop_ret.errno ) then
		print(string.format("query_user_assets_from_db sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( prop_ret )))
		return nil,1001
	end

	local ret = {}
	ret = asset_ret[1]

	if #prop_ret > 0 then
		for k,v in pairs(prop_ret) do
			if v.prop_type then
				ret[v.prop_type] = v.prop_count
			end
		end
	end

	return ret,0
end






--[[从数据库获取直接获取玩家的实时货币和道具
	主要用于外部查询使用
	有频次限制 10/s
]]
local query_user_detail_info_from_db_clock = {}
function base.CMD.query_user_detail_info_from_db(_userId,_name,_phone_number)

	if not _userId and not _name and not _phone_number then
		return nil,1001
	end

	if _userId and (type(_userId)~="string" or string.len(_userId)<1) then
		return nil,1001
	end

	if _name and (type(_name)~="string" or string.len(_name)<1) then
		return nil,1001
	end

	if _phone_number and (type(_phone_number)~="string" or string.len(_phone_number)<1) then
		return nil,1001
	end

	local key = os.time()
	local num = query_user_detail_info_from_db_clock[key]
	if not num then
		num = 0
		query_user_detail_info_from_db_clock={}
	end
	query_user_detail_info_from_db_clock[key] = num + 1

	if num > 10 then
		return nil,1000
	end

	local condi_str = ""
	if _userId then
		condi_str = string.format("WHERE player_info.id='%s'",_userId)
	elseif _phone_number then
		condi_str = string.format("WHERE bind_phone_number.phone_number='%s'",_phone_number)
	elseif _name then
		condi_str = string.format("WHERE player_info.`name` LIKE '%%%s%%'",_name)
	end


	local sql = string.format([[
		SELECT
		player_info.id,
		player_info.`name`,
		player_info.head_image,
		player_info.sex,
		bind_phone_number.phone_number,
		real_name_authentication.`name` as real_name,
		real_name_authentication.identity_number,
		shipping_address.phone_number as shopping_phone_number,
		shipping_address.address,
		player_block_status.block_status,
		player_block_status.block_time,
		player_block_status.reason,
		player_register.register_time,
		player_login.logout_time
		FROM
		player_info
		LEFT JOIN bind_phone_number ON player_info.id = bind_phone_number.player_id
		LEFT JOIN player_block_status ON player_info.id = bind_phone_number.player_id
		LEFT JOIN real_name_authentication ON player_info.id = real_name_authentication.id
		LEFT JOIN shipping_address ON player_info.id = shipping_address.id
		LEFT JOIN player_register ON player_info.id = player_register.id
		LEFT JOIN player_login ON player_info.id = player_login.id
		%s;]]
			,condi_str)
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		print(string.format("query_user_assets_from_db sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return nil,1001
	end
	if not ret[1] then
		return {},0
	end

	for i,d in ipairs(ret) do

		local time = skynet.call(DATA.service_config.collect_service,"lua","query_user_online_time",d.id)
		if time then
			d.online_time = math.floor(time.time/3600)
		end
	end

	return ret,0
end


--[[管理员进行扣除财产
	扣除过多并不会报错，最多能扣除到0
]]
local admin_decrease_player_asset_clock = {}
function base.CMD.admin_decrease_player_asset(_userId,_asset_type,_asset_value,_opt_admin,_reason)

	if type(_userId)~="string" or string.len(_userId)<1 then
		return nil,1001
	end

	if type(_asset_type)~="string" then
		return nil,1001
	end

	if type(_opt_admin)~="string" or string.len(_opt_admin)<1 or string.len(_opt_admin)>50 then
		return nil,1001
	end

	if type(_reason)~="string" or string.len(_reason)<1 or string.len(_reason)>100 then
		return nil,1001
	end

	_asset_value = tonumber(_asset_value)
	if not _asset_value or _asset_value >= 0 then
		return nil,1001
	end

	local key = os.time()
	local num = admin_decrease_player_asset_clock[key]
	if not num then
		num = 0
		admin_decrease_player_asset_clock={}
	end
	admin_decrease_player_asset_clock[key] = num + 1

	if num > 10 then
		return nil,1000
	end

	if not basefunc.is_asset(_asset_type) then
		return nil,1001
	end


	local user_data = base.PUBLIC.load_player_info(_userId)

	if not user_data then
		return nil,2251
	end

	-- 资产
	local cas = user_data.player_asset[_asset_type]

	-- 道具
	if not cas then
		cas = user_data.player_prop[_asset_type]
		if cas then
			cas = cas.prop_count
		end
	end

	-- 记牌器
	if not cas and _asset_type == "jipaiqi" then
		
		local object_data = user_data.object_data or {}

		local jipaiqi_data = {}

		for object_id,d in pairs(object_data) do
			
			if d.object_type == "jipaiqi" then

				jipaiqi_data.object_id = object_id
				jipaiqi_data.valid_time = 0

				if d.attribute.valid_time then
					jipaiqi_data.valid_time = tonumber(d.attribute.valid_time)
				elseif d.attribute.always then
					-- 暂无
				end
				
			end

		end

		local valid_time = jipaiqi_data.valid_time or 0

		-- 本来时间就没有了，不用减了
		if valid_time < os.time() then
			return 0
		else
			cas = math.ceil((valid_time-os.time())/(3600*24))
		end

	end

	-- 表情 单独特殊处理(后面装扮系统全面后再做吧)

	if not cas then
		return nil,1004
	end

	local rcas = _asset_value
	if cas+_asset_value < 0 then
		rcas = -cas
	end

	-- 插入扣减日志
	local sql = string.format([[
		insert into admin_decrease_asset_log
		(log_id,id,asset_type,change_value,current,date,opt_admin,reason)
		values(NULL,'%s','%s',%d,%d,FROM_UNIXTIME(%u),'%s','%s');
		]],
		_userId,_asset_type,rcas,cas,os.time(),_opt_admin,_reason)

	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		print(string.format("admin_decrease_player_asset sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return nil,1001
	end

	local change_id = ret.insert_id
	base.CMD.change_asset_and_sendMsg(_userId,_asset_type,rcas,
										ASSET_CHANGE_TYPE.ADMIN_DECREASE_ASSET,
										change_id)

	return 0

end




local loadstring = rawget(_G, "loadstring") or load
--解析邮件数据
local function parse_email_data(email_data)

	local code = "return " .. email_data
	local ok, ret = xpcall(function ()
		local data = loadstring(code)()
		if type(data) ~= 'table' then
			data = {}
			print("parse_email_data error : {}")
		end
		return data
	end
	,function (err)
		local errStr = "parse_email_data error : "..email_data
		print(errStr)
		print(err)
		print( errStr )
	end)

	if not ok then
		ret = {}
	end

	return ret or {},ok
end

--[[从数据库获取直接获取玩家的实时货币和道具
	主要用于外部查询使用
	有频次限制 10/s
]]
local query_user_give_award_info_from_db_clock = {}
function base.CMD.query_user_give_award_info_from_db(_userId)

	if not _userId then
		return nil,1001
	end

	if (type(_userId)~="string" or string.len(_userId)<1) then
		return nil,1001
	end

	local key = os.time()
	local num = query_user_give_award_info_from_db_clock[key]
	if not num then
		num = 0
		query_user_give_award_info_from_db_clock={}
	end
	query_user_give_award_info_from_db_clock[key] = num + 1

	if num > 10 then
		return nil,1000
	end

	local sql = string.format([[
		SELECT
		emails_admin_opt_log.player_id,
		player_info.`name`,
		bind_phone_number.phone_number,
		emails_admin_opt_log.data,
		emails_admin_opt_log.time,
		emails_admin_opt_log.opt_admin,
		emails_admin_opt_log.reason
		FROM
		emails_admin_opt_log
		LEFT JOIN bind_phone_number ON emails_admin_opt_log.player_id = bind_phone_number.player_id
		LEFT JOIN player_info ON emails_admin_opt_log.player_id = player_info.id
		WHERE emails_admin_opt_log.player_id='%s';]]
			,_userId)
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		print(string.format("query_user_assets_from_db sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return nil,1001
	end
	if not ret[1] then
		return {},0
	end

	local data = {}
	for i,d in ipairs(ret) do
		local pd = parse_email_data(d.data)
		if pd and pd.email and pd.email.data then
			ret[i].data = pd.email.data
		end

		for dk,dv in pairs(ret[i].data) do
			if not basefunc.is_asset(dk) then
				ret[i].data[dk] = nil
			end
		end

		if next(ret[i].data) then
			data[#data+1] = ret[i]
		end

	end

	-- dump(data)

	return data,0
end

function CMD.change_player_other_baseinfo(player_id,base_info,op_player)
    DATA.sql_queue_slow:push_back(PUBLIC.format_sql([[insert player_other_base_info(id,real_name,phone,weixin,shengfen,chengshi,qu) values(%s,%s,%s,%s,%s,%s,%s) 
    											on duplicate key update 
												real_name=%s,
												phone=%s,
												weixin=%s,
												shengfen=%s,
												chengshi=%s,
												qu=%s;]], player_id,                                         
															base_info.real_name,
															base_info.phone,
															base_info.weixin,
															base_info.shengfen,
															base_info.chengshi,
															base_info.qu,
															base_info.real_name,
															base_info.phone,
															base_info.weixin,
															base_info.shengfen,
															base_info.chengshi,
															base_info.qu
															))
	DATA.sql_queue_slow:push_back(PUBLIC.format_sql([[insert player_other_base_info_change_log(id,real_name,phone,weixin,shengfen,chengshi,qu,time,op_player) 
											values(%s,%s,%s,%s,%s,%s,%s,now(),%s);]], 
												player_id,    
												base_info.real_name,
												base_info.phone,
												base_info.weixin,
												base_info.shengfen,
												base_info.chengshi,
												base_info.qu,
												op_player
												))
end

--获得玩家的 openid 
function CMD.get_player_openid(player_id,app_id)
	if not player_id or not app_id then
		--数据不合法
		return nil,1004
	end

	local user=base.CMD.get_player_info(player_id)
	if user and user.player_open_id and user.player_open_id[app_id] then
		return {open_id=user.player_open_id[app_id],app_id=app_id}
	end

	--数据不存在
	return nil ,1003

end

function CMD.add_player_openid(player_id,app_id,open_id)
	if not player_id or not app_id or not open_id then
		--数据不合法
		return 1004
	end
	local user=base.PUBLIC.load_player_info(player_id)
	if not user then
		--玩家不存在
		return 1003
	end

	user.player_open_id = user.player_open_id or {}

	local _row = user.player_open_id[app_id]
	if _row then
		_row.open_id = open_id
		DATA.sql_queue_slow:push_back(PUBLIC.format_sql([[update player_open_id set open_id=%s where player_id=%s and app_id = %s;]],
				open_id,player_id,app_id))
	else
		user.player_open_id[app_id] = {player_id=player_id,open_id=open_id,app_id=app_id}

		DATA.sql_queue_slow:push_back(PUBLIC.format_sql([[insert into player_open_id(player_id,app_id,open_id) values(%s,%s,%s) 
				on duplicate key update app_id=%s,open_id=%s;]],
				player_id,app_id,open_id,app_id,open_id))
	end

	return 0
end

function CMD.add_alipay_account(player_id,name,alipay_account)
	if not player_id or not name or not alipay_account then
		--数据不合法
		return 1004
	end
	local user=base.PUBLIC.load_player_info(player_id)
	if not user then
		--玩家不存在
		return 1003
	end

	user.player_alipay_account = user.player_alipay_account or {}
	user.player_alipay_account.name = name
	user.player_alipay_account.alipay_account = alipay_account

	--插入数据库
	DATA.sql_queue_slow:push_back(PUBLIC.format_sql([[insert into player_alipay_account(player_id,name,alipay_account) values(%s,%s,%s) 
													on duplicate key update name=%s,alipay_account=%s;]],
													player_id,
													name,
													alipay_account,
													name,
													alipay_account))



	return 0
end

function CMD.get_alipay_account(player_id)
	if not player_id  then
		--数据不合法
		return nil,1004
	end

	local user=base.CMD.get_player_info(player_id)
	if user and user.player_alipay_account and next(user.player_alipay_account) then
		return {
			name=user.player_alipay_account.name,  
			alipay_account= user.player_alipay_account.alipay_account
		}
	end
	--数据不存在
	return nil ,1003
end


return PROTECTED








