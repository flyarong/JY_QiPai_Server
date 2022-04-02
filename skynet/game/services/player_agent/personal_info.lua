--
-- Author: YY
-- Date: 2018/5/10
-- Time: 
-- 说明: 个人信息
local skynet = require "skynet_plus"
local basefunc=require"basefunc"
local identity_number_vertify = require "identity_number_vertify"
require"printfunc"
local base = require "base"
local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC
local REQUEST=base.REQUEST
local PROTECT={}

local act_lock = nil

--实名认证状态 上来就缓存 因为这个东西每次基本上都会被查询
local real_name_authentication_status = 0
function PUBLIC.init_real_name_authentication()
	local data = skynet.call(DATA.service_config.data_service,"lua",
								"get_real_name_authentication",DATA.my_id)
	if data then
		real_name_authentication_status = 1
	end
end


function REQUEST.query_real_name_authentication(self)
	return {result=0,status = real_name_authentication_status}
end


function REQUEST.proceed_real_name_authentication(self)
	if real_name_authentication_status == 0 then
		if self.name 
			and type(self.name)=="string"
			and string.len(self.name) > 2
			and string.len(self.name) < 20
			and self.identity_number 
			and type(self.identity_number)=="string"
			and string.len(self.identity_number) < 50 then

			if identity_number_vertify.verifyIDCard(self.identity_number) then
				skynet.send(DATA.service_config.data_service,"lua",
								"insert_real_name_authentication",
								DATA.my_id,self.name,self.identity_number)
				real_name_authentication_status = 1
				return {result=0}
			else
				return {result=2202}
			end
		else
			return {result=1001}
		end
		
	else
		return {result=2201}
	end
	
end


function REQUEST.query_shipping_address(self)
	local data = skynet.call(DATA.service_config.data_service,"lua",
								"get_shipping_address",DATA.my_id)

	return {result=0,shipping_address=data}
end



function REQUEST.update_shipping_address(self)

	if self.name
		and self.phone_number
		and self.address

		and type(self.name)=="string"
		and type(self.phone_number)=="string"
		and type(self.address)=="string"

		and string.len(self.name) > 0
		and string.len(self.name) < 50
		and string.len(self.phone_number) > 2
		and string.len(self.phone_number) < 50
		and string.len(self.address) > 2
		and string.len(self.address) < 200 then

		skynet.send(DATA.service_config.data_service,"lua",
					"update_shipping_address",DATA.my_id,
					self.name,self.phone_number,self.address)

		return {result=0}
	end


	return {result=1001}
end



--设置性别
function REQUEST.set_sex(self)

	if type(self.sex) ~= "number" then
		return {result=1001}
	end

	if self.sex ~= 0 and self.sex ~= 1 then
		return {result=1001}
	end

	if self.sex ~= DATA.player_data.player_info.sex then
		skynet.send(DATA.service_config.data_service,"lua","modify_player_info",
						DATA.my_id,"player_info",{sex=self.sex})
		DATA.player_data.player_info.sex = self.sex
	end

	return {result=0}
end


local bind_phone_info = nil
-- 查询 绑定手机号 信息
function REQUEST.query_bind_phone(self)

	if bind_phone_info then
		return bind_phone_info
	end

	local cd = skynet.call(DATA.service_config.data_service,"lua","query_phone_verify_code_cd",
						DATA.my_id)

	local bp = skynet.call(DATA.service_config.data_service,"lua","query_bind_phone_number",
						DATA.my_id)

	cd = math.max(cd-os.time(),0)

	bind_phone_info={
		result = 0,
		cd=cd,
		phone_no = bp,
	}
	return bind_phone_info
end

local function gen_phone_verify_code()
	return tostring(math.random(100000,999999))
end

local phone_verify_code={}

local phone_verify_lock = nil

--绑定手机号
function REQUEST.send_bind_phone_verify_code(self)
	if type(self.phone_no)~="string" 
		or string.len(self.phone_no)~= 11
		or not tonumber(self.phone_no) then
		return {result=1001}
	end

	if phone_verify_lock then
		return {result=1008}
	end
	phone_verify_lock = true

	local cd = skynet.call(DATA.service_config.data_service,"lua","query_phone_verify_code_cd",
						DATA.my_id)

	if cd then
		if os.time() < cd then
			print("短信cd没到")
			phone_verify_lock = nil
			return {result=1002}
		end
	end

	local bp = skynet.call(DATA.service_config.data_service,"lua","query_bind_phone_number",
						DATA.my_id)
	if not bp then
		bp = self.phone_no
	end

	local status = skynet.call(DATA.service_config.data_service,"lua","query_bind_phone_number_is_exist",
						self.phone_no)
	if status > 0 then
		phone_verify_lock = nil
		return {result=2603}
	end

	local verify_code = gen_phone_verify_code()

	print("send_phone_bind_code:user id,code",DATA.my_id,verify_code)

	-- 发送验证短信
	local send_ret = skynet.call(base.DATA.service_config.third_agent_service,"lua","send_phone_bind_code",bp,verify_code)
	if send_ret ~= 0 then
		phone_verify_lock = nil
		return {result=send_ret}
	end

	phone_verify_code["bind_phone"]={
		phone_no = self.phone_no,
		verify_code = verify_code,
		time = os.time(),
	}

	cd = skynet.call(DATA.service_config.data_service,"lua","add_phone_verify_code_cd",
						DATA.my_id)

	phone_verify_lock = nil
	return {result=0,cd=cd}

end


--绑定手机号
function REQUEST.verify_bind_phone_code(self)
	if type(self.code)~="string" 
		or string.len(self.code)~=6 then
		return {result=2601}
	end
	
	if not phone_verify_code["bind_phone"] then
		return {result=2606}
	end

	if phone_verify_code["bind_phone"].verify_code ~= self.code then
		print("verify_bind_phone_code error:user id,code send,code verify",DATA.my_id,phone_verify_code["bind_phone"].verify_code,self.code)
		return {result=2601}
	end

	if phone_verify_code["bind_phone"].time + 10*60 < os.time() then
		return {result=2602}
	end

	skynet.send(DATA.service_config.data_service,"lua","add_bind_phone_number",
						DATA.my_id,
						phone_verify_code["bind_phone"].phone_no)


	--更新缓存
	local cd = skynet.call(DATA.service_config.data_service,"lua","add_phone_verify_code_cd",
						DATA.my_id)
	bind_phone_info={
		result = 0,
		cd=cd,
		phone_no = phone_verify_code["bind_phone"].phone_no,
	}

	phone_verify_code["bind_phone"] = nil

	return {result=0}
end



--强制绑定电话
function PUBLIC.force_bind_phone(phone_no)
	skynet.send(DATA.service_config.data_service,"lua","add_bind_phone_number",
						DATA.my_id,
						phone_no)
	bind_phone_info={
		result = 0,
		cd=0,
		phone_no = phone_no,
	}
end

-- 得到分享链接
function REQUEST.get_share_url(_data)

	
	return skynet.call(base.DATA.service_config.third_agent_service,"lua","get_share_url",DATA.my_id,DATA.player_data.player_register.market_channel)

end


-- 设置登录设备信息
function REQUEST.device_info(_data)

	DATA.player_data.player_device_info.device_token = _data.device_token
	DATA.player_data.player_device_info.device_type = _data.device_type
	
	skynet.call(base.DATA.service_config.data_service,"lua","modify_player_info",DATA.my_id,"player_device_info",
		{
			device_token=_data.device_token,
			device_type=_data.device_type,
			refresh_time={__sql_expr="now()"}
		},false,true)

end

return PROTECT

