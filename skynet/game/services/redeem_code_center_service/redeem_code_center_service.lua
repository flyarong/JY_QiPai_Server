
local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"

local cjson = require "cjson"
cjson.encode_sparse_array(true,1,0)

require "normal_enum"

require "printfunc"

local DATA = base.DATA
local CMD = base.CMD
local PUBLIC=base.PUBLIC

DATA.service_config = nil

local service_zero_time = 6

DATA.redeem_code_data = {}
DATA.redeem_code_content = {}


-- 用户对某个类型的码使用记录
DATA.redeem_code_type_used_data = {}

-- 操作锁
local player_act_lock = {}

-- 操作时间限制 3*2^N
local player_opt_time = {}

local return_msg = {result=0,time=0}

-- 玩家输入错误 进行时间惩罚处理 [2,4,8,240,240*30,240*30*30,...]
-- 跨天 重置
local function player_input_error(_player_id)
	local ot = player_opt_time[_player_id] or {pun_time=0.01}
	player_opt_time[_player_id] = ot

	ot.pun_time = ot.pun_time + 0.01

	ot.error_time = os.time()

	if ot.pun_time > 0.1 then

		ot.pun_time = 8*3600

	end

end


local function update_data(_code_data,_key_codes)
	
	local rcd = DATA.redeem_code_data[_code_data.code_type] or {}
	DATA.redeem_code_data[_code_data.code_type] = rcd

	rcd[_code_data.code_sub_type] = _code_data

	for i,c in ipairs(_key_codes) do
		
		local cc = DATA.redeem_code_content[_code_data.code_type] or {}
		DATA.redeem_code_content[_code_data.code_type] = cc

		local cst = cc[_code_data.code_sub_type] or {}
		cc[_code_data.code_sub_type] = cst

		cst[c] = {used_count=0}

	end

	skynet.send(DATA.service_config.data_service,"lua","add_redeem_code_data"
				,_code_data.name
				,_code_data.code_type
				,_code_data.code_sub_type
				,_code_data.use_type
				,cjson.encode(_code_data.use_args)
				,_code_data.start_time
				,_code_data.end_time
				,_code_data.register_limit_time
				,cjson.encode(_code_data.assets)
				)

	skynet.send(DATA.service_config.data_service,"lua","add_redeem_code_content"
														,_code_data.code_type
														,_code_data.code_sub_type
														,_key_codes)

end

local function init_data()

	-- 获取码的数据
	local code_data = skynet.call(DATA.service_config.data_service,"lua","query_redeem_code_data")
	for i,v in ipairs(code_data) do
		
		local rcd = DATA.redeem_code_data[v.code_type] or {}
		DATA.redeem_code_data[v.code_type] = rcd

		rcd[v.code_sub_type] = v

		v.id = nil
		v.use_args = cjson.decode(v.use_args)
		v.assets = cjson.decode(v.assets)
	end


	local content = skynet.call(DATA.service_config.data_service,"lua","query_redeem_code_content")
	for i,v in ipairs(content) do
		
		local cc = DATA.redeem_code_content[v.code_type] or {}
		DATA.redeem_code_content[v.code_type] = cc

		local cst = cc[v.code_sub_type] or {}
		cc[v.code_sub_type] = cst

		cst[v.key_code] = {used_count=v.used_count}

	end

	-- dump(DATA.redeem_code_data,"DATA.redeem_code_data+++++++++")
	-- dump(DATA.redeem_code_content,"DATA.redeem_code_content+++++++++++++")

	-- 使用过的码的数据
	local used_log = skynet.call(DATA.service_config.data_service,"lua","query_redeem_code_log")
	for i,v in ipairs(used_log) do

		local rctud = DATA.redeem_code_type_used_data[v.player_id] or {}
		DATA.redeem_code_type_used_data[v.player_id] = rctud

		local ctd = rctud[v.code_type] or {num=0,time=0}

		ctd.num = ctd.num + 1
		ctd.time = v.time

	end

	-- dump(DATA.redeem_code_type_used_data,"DATA.redeem_code_type_used_data+++++++++++++")

	print("redeem_code_used_data ready ok")

end

-- 查找码的数据
local function get_redeem_code_data(_key_code)

	local code_data = nil
	local code_used_data = nil
	for _code_type,cc in pairs(DATA.redeem_code_content) do

		for st,d in pairs(cc) do
			code_used_data = d[_key_code]
			if code_used_data then
				code_data = DATA.redeem_code_data[_code_type]
				if code_data then
					code_data = code_data[st]
				end
				return code_data,code_used_data
			end

		end

	end

end

-- 错误时间
local function check_error_time_limit(_player_id)
	
	local ot = player_opt_time[_player_id]
	if ot then

		-- 跨天清空
		if not basefunc.chk_same_date(ot.error_time,os.time(),service_zero_time) then
			player_opt_time[_player_id] = nil
		else
			
			local et = ot.error_time+ot.pun_time - os.time()

			if et > 0 then
				return_msg.result = 4103
				return_msg.time = math.floor(et)
				return return_msg
			end

		end

	end

	return_msg.result = 0
	return return_msg
end

-- 使用时间(码的有效时间以及用户注册的时间)
local function check_use_time_limit(_code_data,_code_used_data,_player_id,_key_code)
	
	if not _code_data or not _code_used_data then
		return_msg.result = 4102
		return return_msg
	end

	local ct = os.time()

	--有效时间
	if ct < _code_data.start_time or ct > _code_data.end_time then
		return_msg.result = 4105
		return return_msg
	end

	local reg_time = 0

	local sql = string.format("SELECT UNIX_TIMESTAMP(register_time) time FROM player_register WHERE id='%s';",_player_id)
	local reg_data = skynet.call(DATA.service_config.data_service,"lua","db_query",sql)
	if reg_data and reg_data[1] then
		reg_time = reg_data[1].time or 0
	end

	if reg_time < _code_data.register_limit_time then
		return_msg.result = 4106
		return return_msg
	end

	return_msg.result = 0
	return return_msg
end

--[[

	"use_args" : {a,b,c...}

	"A" (这个类型的一个兑换码只能用一次,一个用户可以使用a个兑换码)参数：a

	"B" (这个类型的一个兑换码能用a次,一个用户只能使用一个兑换码)参数：a

	"C" (这个类型的一个兑换码只能用一次,一个用户每天只能使用一个兑换码)

]]
local function check_use_limit(_code_data,_code_used_data,_player_id,_key_code)
	
	-- 查找码的数据
	local code_data = _code_data
	local code_used_data = _code_used_data

	return_msg.result = 0
	return_msg.time = nil

	-- 码存在且正确
	if not code_data or not code_used_data then

		return_msg.result = 4102

	else

		-- 判断码的次数等限制是否满足
		if code_data.use_type == "A" then

			if code_used_data.used_count > 0 then
				
				return_msg.result = 4101

			else

				local ud = DATA.redeem_code_type_used_data[_player_id]
				if ud then
					local udt = ud[code_data.code_type]
					if udt then
						if udt.num >= code_data.use_args[1] then
							return_msg.result = 4104
						end
					end
				end

			end

		elseif code_data.use_type == "B" then

			if code_used_data.used_count >= code_data.use_args[1] then
				
				return_msg.result = 4107

			else

				local ud = DATA.redeem_code_type_used_data[_player_id]
				if ud then
					local udt = ud[code_data.code_type]
					if udt then
						if udt.num >= 1 then
							return_msg.result = 4104
						end
					end
				end

			end

		elseif code_data.use_type == "C" then

			if code_used_data.used_count > 0 then
				
				return_msg.result = 4101

			else

				local ud = DATA.redeem_code_type_used_data[_player_id]
				if ud then
					local udt = ud[code_data.code_type]
					if udt then
						
						if not basefunc.chk_same_date(udt.time,os.time(),service_zero_time) then
							udt.num  = 0
						end

						if udt.num >= 1 then
							return_msg.result = 4108
						end
					end
				end

			end

		end

	end



	if return_msg.result ~= 0 then

		player_input_error(_player_id)

		local ot = player_opt_time[_player_id]
		local et = ot.error_time+ot.pun_time - os.time()

		return_msg.time = math.floor(et)

	end

	return return_msg

end


-- 清除一个玩家的错误
function CMD.clear_error(_player_id)
	player_opt_time[_player_id] = nil
	player_act_lock[_player_id] = nil
	return 0
end

-- 使用一个码
function CMD.use_key_code(_player_id,_key_code)
	
	if player_act_lock[_player_id] then
		return_msg.result = 1008
		return_msg.time = nil
		return return_msg
	end

	-- 操作时间限制判断
	local ret = check_error_time_limit(_player_id)
	if ret.result ~= 0 then
		return ret
	end

	player_act_lock[_player_id] = true

	-- 转换为纯小写
	_key_code = string.lower(_key_code)

	local code_data,code_used_data = get_redeem_code_data(_key_code)
	
	if not code_data or not code_used_data then
		
		player_input_error(_player_id)
		
		player_act_lock[_player_id] = nil

		return_msg.result = 4102
		return return_msg
	end

	-- 使用时间判断
	local ret = check_use_time_limit(code_data,code_used_data,_player_id,_key_code)
	if ret.result ~= 0 then
		player_act_lock[_player_id] = nil
		return ret
	end

	-- 码是否可用判断
	local ret = check_use_limit(code_data,code_used_data,_player_id,_key_code)
	if ret.result ~= 0 then
		player_act_lock[_player_id] = nil
		return ret
	end

	local ret = check_use_limit(code_data,code_used_data,_player_id,_key_code)
	if ret.result ~= 0 then
		player_act_lock[_player_id] = nil
		return ret
	end

	-- 执行码对应的操作
	skynet.send(DATA.service_config.data_service,"lua","give_assets_packet_by_redeem_code"
						,_player_id,_key_code,code_data.code_type,code_data.assets)

	local ud = DATA.redeem_code_type_used_data[_player_id] or {}
	DATA.redeem_code_type_used_data[_player_id] = ud

	local udt = ud[code_data.code_type] or {num=0,time=0}
	ud[code_data.code_type] = udt

	udt.num = udt.num + 1
	udt.time = os.time()

	code_used_data.used_count = code_used_data.used_count + 1
	skynet.send(DATA.service_config.data_service,"lua","update_redeem_code_content"
		,_key_code
		,code_used_data.used_count
		)

	-- 记录
	skynet.send(DATA.service_config.data_service,"lua","add_redeem_code_log"
		,_player_id
		,_key_code
		,code_data.code_type
		,code_data.code_sub_type
		,string.format("award:%s",basefunc.safe_serialize(code_data.assets))
		)

	-- ok 后 解除错误时间限制
	player_opt_time[_player_id] = nil

	player_act_lock[_player_id] = nil

	return_msg.result = 0
	return_msg.time = nil
	return return_msg

end






--[[外部直接调用 增加兑换码
	{
		"name" : "十元礼包"
		"code_type" : "tenyuan"
		"start_time" : 15201236541
		"end_time" : 15301236541
		"use_type" : "A"
		"use_args" : {1,20}
		"assets" : {"jing_bi" : 1000,"diamond" : 100}
		"codes" : {"as4521346","as4521346","as4521346","as4521346","as4521346"}
	}

	"use_args" : {a,b,c...}

	"A" (这个类型的一个兑换码只能用一次,一个用户可以使用a个兑换码)参数：a

	"B" (这个类型的一个兑换码能用a次,一个用户只能使用一个兑换码)参数：a

	"C" (这个类型的一个兑换码只能用一次,一个用户每天只能使用一个兑换码)
]]
function CMD.add_redeem_code_data(_data)

	local ok, arg = xpcall(function ()
			return cjson.decode(_data)
		end,
		function (error)
			print(error)
		end)
	
	if not ok or not arg then
		return nil,1001
	end

	dump(arg,"arg+++++++++++++++")

	if type(arg.name) ~= "string" 
		or type(arg.code_type) ~= "string"
		or type(arg.code_sub_type) ~= "string"
		or type(arg.start_time) ~= "number"
		or type(arg.end_time) ~= "number"
		or type(arg.register_limit_time) ~= "number"
		or type(arg.use_type) ~= "string"
		or type(arg.use_args) ~= "table"
		or type(arg.assets) ~= "table"
		or type(arg.codes) ~= "table" then

		return nil,1001

	end

	arg.start_time = math.floor(arg.start_time)
	arg.end_time = math.floor(arg.end_time)
	arg.register_limit_time = math.floor(arg.register_limit_time)

	local assets = {}
	for k,v in pairs(arg.assets) do
		if not basefunc.is_asset(k) then
			return nil,1001
		else
			if basefunc.is_object_asset(k) then
			else
				assets[#assets+1] = 
				{
					asset_type = k,
					value = math.floor(v),
				}
			end
		end
	end
	arg.assets = assets

	for i,v in ipairs(arg.codes) do
		if type(v) ~= "string" then
			return nil,1001
		end
		arg.codes[i] = string.lower(v)
	end

	if arg.use_type == "A" or arg.use_type == "B" then

		if type(arg.use_args[1]) ~= "number" or arg.use_args[1] < 0 then
			return nil,1001
		end

		arg.use_args[1] =  math.floor(arg.use_args[1])

	end


	dump(arg,"x arg+++++++++++++++")
	print(basefunc.tostring(arg),"++++++++/*-/*-/-")


	local cd = basefunc.copy(arg)
	cd.codes = nil
	update_data(cd,arg.codes)

	skynet.send(DATA.service_config.data_service,"lua","add_redeem_code_opt_log","add_redeem_code_data",_data)

	return {result=0}
end

--[[
	删除一部分兑换码
]]
function CMD.delete_redeem_code_data(_data)

	local ok, arg = xpcall(function ()
			return cjson.decode(_data)
		end,
		function (error)
			print(error)
		end)
	
	if not ok or not arg then
		return nil,1001
	end

	dump(arg,"arg+++++++++++++++")

	if type(arg.codes) == "table" then

		for i,c in ipairs(arg.codes) do
			
			c = string.lower(c)
			arg.codes[i] = c

			local code_data,code_used_data = get_redeem_code_data(c)

			if code_data and code_used_data then

				local cc = DATA.redeem_code_content[code_data.code_type][code_data.code_sub_type]

				if cc then
					cc[c] = nil
				end

			end

		end

		skynet.send(DATA.service_config.data_service,"lua","delete_redeem_code_content_by_code",arg.codes)

		skynet.send(DATA.service_config.data_service,"lua","add_redeem_code_opt_log","delete_redeem_code_content",_data)


	elseif type(arg.code_type) == "string" then

		if DATA.redeem_code_data[arg.code_type] then
			
			if type(arg.code_sub_type) == "string" then

				-- 删除一个子类
				local rcd = DATA.redeem_code_data[arg.code_type]
				local cst = rcd[arg.code_sub_type]
				if cst then

					rcd[arg.code_sub_type] = nil
					
					local rcc = DATA.redeem_code_content[arg.code_type]
					if rcc then
						rcc[arg.code_sub_type] = nil
					end
				
				else

					return {result=0}--nil,1001

				end

			else

				arg.code_sub_type = nil

				-- 全部删除
				DATA.redeem_code_data[arg.code_type] = nil
				DATA.redeem_code_content[arg.code_type] = nil

			end

			skynet.send(DATA.service_config.data_service,"lua","delete_add_redeem_code_data",arg.code_type,arg.code_sub_type)

			skynet.send(DATA.service_config.data_service,"lua","add_redeem_code_opt_log","delete_redeem_code_data",_data)
		
		else

			return {result=0}--nil,1001

		end

	else

		return {result=0}--nil,1001

	end


	return {result=0}

end



function CMD.start(_service_config)

	DATA.service_config = _service_config

	init_data()

end

-- 启动服务
base.start_service()
