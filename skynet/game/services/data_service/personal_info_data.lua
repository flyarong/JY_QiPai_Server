--
-- Author: yy
-- Date: 2018/4/19
-- Time: 19:59
-- 说明：个人数据
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local PROTECTED = {}

local LOCAL_FUNC = {}

--[[
 玩家斗地主自由场数据： 玩家 id  到 数据的映射
数据库表： real_name_authentication
数据库 玩家 id 是主键
-- 数据结构说明：
	id = {
		id,				--玩家id
		name,			--名字
		identity_number,	--身份证号码
	}
--]]
PROTECTED.real_name_authentication = {}
local real_name_authentication = PROTECTED.real_name_authentication




--[[
 玩家斗地主自由场数据： 玩家 id  到 数据的映射
数据库表： real_name_authentication
数据库 玩家 id 是主键
-- 数据结构说明：
	id = {
		id,				--玩家id
		name,			--名字
		phone_number,	--电话号码
		address,		--地址
	}
--]]
PROTECTED.shipping_address = {}
local shipping_address = PROTECTED.shipping_address




PROTECTED.bind_phone_number = {}
local bind_phone_number = PROTECTED.bind_phone_number


local bind_phone_number_exist = {}


--手机验证码cd
PROTECTED.phone_verify_code_cd = {}
local phone_verify_code_cd = PROTECTED.phone_verify_code_cd


local gift_bag_data = {}


-- 初始化玩家斗地主自由场数据
function PROTECTED.init_personal_info_data()

	LOCAL_FUNC.init_real_name_authentication()
	LOCAL_FUNC.init_shipping_address()
	LOCAL_FUNC.init_bind_phone_number()
	LOCAL_FUNC.init_player_gift_bag_data()

	return true
end



--初始化real_name_authentication
function LOCAL_FUNC.init_real_name_authentication()
	local sql = "SELECT * FROM real_name_authentication;"
	local ret = base.DATA.db_mysql:query(sql)

	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i=1,#ret do
		local row = ret[i]
		real_name_authentication[row.id]=row
	end

end



--初始化手机号绑定信息
function LOCAL_FUNC.init_bind_phone_number()
	local sql = "SELECT * FROM bind_phone_number;"
	local ret = base.DATA.db_mysql:query(sql)

	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i=1,#ret do
		local row = ret[i]
		bind_phone_number[row.player_id]=row
		bind_phone_number_exist[row.phone_number] = 1
	end

end





--初始化shipping_address
function LOCAL_FUNC.init_shipping_address()
	local sql = "SELECT * FROM shipping_address;"
	local ret = base.DATA.db_mysql:query(sql)

	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i=1,#ret do
		local row = ret[i]
		shipping_address[row.id]=row
	end

end



--初始化shipping_address
function LOCAL_FUNC.init_player_gift_bag_data()

	local sql = "SELECT * FROM gift_bag_data;"
	local ret = base.DATA.db_mysql:query(sql)

	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i=1,#ret do
		local row = ret[i]
		gift_bag_data[row.gift_bag_id] = row
	end

end



-- 根据 player_id 数据 
function base.CMD.get_real_name_authentication(_player_id)

	return real_name_authentication[_player_id]

end


-- 根据 插入 数据 
function base.CMD.insert_real_name_authentication(_player_id,_name,_identity_number)

	if real_name_authentication[_player_id] then
		return false
	end

	real_name_authentication[_player_id]=
	{
		id = _player_id ,
		name = _name ,
		identity_number = _identity_number ,
	}

	local sql = string.format([[insert into real_name_authentication(
								id,
					 			name,
					 			identity_number)
								values('%s','%s','%s');]],
								_player_id,_name,_identity_number)
	base.DATA.sql_queue_fast:push_back(sql)

	return true
end


-- 根据 player_id  数据 
function base.CMD.get_shipping_address(_player_id)

	return shipping_address[_player_id]

end


-- 根据 插入 数据 
function base.CMD.update_shipping_address(_player_id,_name,_phone_number,_address)

	shipping_address[_player_id]=
	{
		id = _player_id ,
		name = _name ,
		phone_number = _phone_number ,
		address = _address ,
	}

	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_name = '%s';
								SET @_phone_number = '%s';
								SET @_address = '%s';
								insert into shipping_address
								(id,name,phone_number,address)
								values(@_player_id,@_name,@_phone_number,@_address)
								on duplicate key update 
								id = @_player_id,
								name = @_name,
								phone_number = @_phone_number,
								address = @_address;
								]],
								_player_id,_name,_phone_number,_address)
	base.DATA.sql_queue_fast:push_back(sql)

end





-- 根据 插入 数据 
function base.CMD.add_bind_phone_number(_player_id,_phone_number)

	-- 更新
	if bind_phone_number[_player_id] then
		bind_phone_number_exist[bind_phone_number[_player_id].phone_number] = nil
	end

	bind_phone_number[_player_id]=
	{
		player_id = _player_id,
		phone_number = _phone_number,
		bind_time = os.time(),
	}

	bind_phone_number_exist[_phone_number] = 1

	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_phone_number = '%s';
								SET @_bind_time = FROM_UNIXTIME(%u);
								insert into bind_phone_number
								(player_id,phone_number,bind_time)
								values(@_player_id,@_phone_number,@_bind_time)
								on duplicate key update
								player_id = @_player_id,
								phone_number = @_phone_number,
								bind_time = @_bind_time;
								]],
								_player_id,
								_phone_number,
								bind_phone_number[_player_id].bind_time)
	
	base.DATA.sql_queue_fast:push_back(sql)

	return true
end



-- 更新绑定的手机号 提供外部调用
function base.CMD.external_update_bind_phone_number(_player_id,_phone_number,_opt_admin)

	if type(_phone_number)~="string" 
		or string.len(_phone_number)~= 11
		or not tonumber(_phone_number) then
		return {result=1001}
	end

	if type(_player_id)~="string" or string.len(_player_id)<1 then
		return 1001
	end

	if type(_opt_admin)~="string" or string.len(_opt_admin)<1 or string.len(_opt_admin)>50 then
		return 1001
	end

	local old_phone_number = bind_phone_number[_player_id].phone_number

	if not old_phone_number then
		return nil,2604
	end

	if old_phone_number == _phone_number then
		return nil,2605
	end

	base.CMD.add_bind_phone_number(_player_id,_phone_number)

	local sql = string.format([[
								insert into bind_phone_number_opt_log
								(id,player_id,old_phone_number,new_phone_number,opt_time,opt_admin)
								values(NULL,'%s','%s','%s',FROM_UNIXTIME(%u),'%s');
								]],
								_player_id,
								old_phone_number,
								_phone_number,
								os.time(),
								_opt_admin)
	
	base.DATA.sql_queue_slow:push_back(sql)

	return 0
end



-- 根据
function base.CMD.query_bind_phone_number(_player_id)

	if bind_phone_number[_player_id] then
		return bind_phone_number[_player_id].phone_number
	end

	return nil

end



-- 根据
function base.CMD.query_bind_phone_number_is_exist(_phone_number)

	if bind_phone_number_exist[_phone_number] then
		return 1
	end

	return 0

end


-- 增加的cd
function base.CMD.add_phone_verify_code_cd(_player_id)

	local pd = phone_verify_code_cd[_player_id] or {}
	phone_verify_code_cd[_player_id] = pd
	pd.verify_count = (pd.verify_count or 0) + 1

	if pd.verify_count < 4 then
		pd.cd = 60 + os.time()
	else
		pd.cd = 240*(2^(pd.verify_count-4)) + os.time()
	end

	return pd.cd - os.time()
end


-- 查询手机验证码的cd
function base.CMD.query_phone_verify_code_cd(_player_id)

	if phone_verify_code_cd[_player_id] then
		return phone_verify_code_cd[_player_id].cd
	else
		return 0
	end

end


-- 更新 礼包 数据
function base.CMD.update_gift_bag_data(_gift_bag_data)

	local gd = gift_bag_data[_gift_bag_data.gift_bag_id] or {}
	gift_bag_data[_gift_bag_data.gift_bag_id] = gd

	gd.gift_bag_id = _gift_bag_data.gift_bag_id
	gd.gift_bag_name = _gift_bag_data.gift_bag_name or gd.gift_bag_name
	gd.count = _gift_bag_data.count or gd.count

	local sql = string.format([[
								SET @_gift_bag_id = %s;
								SET @_gift_bag_name = '%s';
								SET @_count = %s;
								insert into gift_bag_data
								(gift_bag_id,gift_bag_name,count)
								values(@_gift_bag_id,@_gift_bag_name,@_count)
								on duplicate key update
								gift_bag_name = @_gift_bag_name,
								count = @_count;
								]],
								gd.gift_bag_id,
								gd.gift_bag_name,
								gd.count)
	
	base.DATA.sql_queue_fast:push_back(sql)

end



-- 查询 礼包
function base.CMD.query_gift_bag_data(_gift_bag_id)

	return gift_bag_data[_gift_bag_id]

end




-- 更新玩家礼包
function base.CMD.update_player_gift_bag_data(_player_id,_gift_bag_id,_gift_bag_name,_num,_time,_permit_num,_permit_time)

	local sql = string.format([[
								SET @_player_id = '%s';
								SET @_gift_bag_id = %s;
								SET @_gift_bag_name = '%s';
								SET @_num = %s;
								SET @_time = %u;
								SET @_permit_num = %s;
								SET @_permit_time = %s;
								insert into player_gift_bag_status
								(player_id,gift_bag_id,gift_bag_name,num,time,permit_num,permit_time)
								values(@_player_id,@_gift_bag_id,@_gift_bag_name,@_num,@_time,@_permit_num,@_permit_time)
								on duplicate key update
								gift_bag_name = @_gift_bag_name,
								num = @_num,
								time = @_time,
								permit_num = @_permit_num,
								permit_time = @_permit_time;
								]],
								_player_id,
								_gift_bag_id,
								_gift_bag_name,
								_num,
								_time,
								_permit_num,
								_permit_time)
	
	base.DATA.sql_queue_fast:push_back(sql)

end


-- 查询 玩家 礼包 
function base.CMD.query_player_gift_bag_data()

	local sql = "SELECT * FROM player_gift_bag_status;"
	local ret = base.DATA.db_mysql:query(sql)

	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	local player_gift_bag_data = {}

	for i=1,#ret do
		local row = ret[i]
		local d = player_gift_bag_data[row.player_id] or {}
		player_gift_bag_data[row.player_id] = d
		d[row.gift_bag_id] = row
		row.player_id = nil
		row.gift_bag_id = nil
	end

	return player_gift_bag_data

end


return PROTECTED