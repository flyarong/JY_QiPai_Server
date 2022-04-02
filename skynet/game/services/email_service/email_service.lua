--
-- Author: yy
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：邮件服务
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"
local email_everyone = require "email_service.email_everyone"

require "normal_enum"

local loadstring = rawget(_G, "loadstring") or load

require "printfunc"

local DATA = base.DATA
local CMD = base.CMD
local PUBLIC=base.PUBLIC

DATA.service_config = nil

--玩家邮件持有最大数量
local EMAIL_MAX_NUM = 50

--刷新间隔 秒
local UPDATE_INTERVAL = 3*3600

--删除延迟 10天
local DELETE_DELAY = 10*24*3600

-- 邮件 ID
DATA.email_max_id = 0

-- 邮件 [receiver][email_id] => data
DATA.emails = {}

-- 玩家邮件列表 [receiver] => ids
DATA.email_lists = {}

-- 邮件数据 email_id => data(解析后的lua表)
DATA.email_datas = {}


--解析邮件数据
function PUBLIC.parse_email_data(email_data)

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

local function init_data()
	DATA.email_max_id = skynet.call(DATA.service_config.data_service,"lua","get_email_max_id")
	local emails = skynet.call(DATA.service_config.data_service,"lua","get_emails")
	for i,email in ipairs(emails) do

		DATA.emails[email.receiver] = DATA.emails[email.receiver] or {}
		DATA.emails[email.receiver][email.id]=email

		DATA.email_lists[email.receiver] = DATA.email_lists[email.receiver] or {}
		local len = #DATA.email_lists[email.receiver]
		DATA.email_lists[email.receiver][len+1]=email.id

		if email.data and type(email.data) == "string" then
			DATA.email_datas[email.id] = PUBLIC.parse_email_data(email.data)
		end

	end

end

local function gen_email_id()
	DATA.email_max_id = DATA.email_max_id + 1
	return DATA.email_max_id
end


--更新玩家邮件id列表
local function update_email_lists(player_id)
	DATA.email_lists[player_id]={}
	for email_id,email in pairs(DATA.emails[player_id]) do
		local len = #DATA.email_lists[player_id]
		DATA.email_lists[player_id][len+1]=email_id
	end
end



-- 阅读邮件
local function read_email(player_id,email_id)
	local email = DATA.emails[player_id][email_id]

	if email.state == "normal" then
		if email.valid_time > 0 
			and email.valid_time < os.time() then
			return 2302
		end

		--有财产型附件 不能直接阅读
		local email_data = DATA.email_datas[email_id]
		if email_data and next(email_data) then
			for key,value in pairs(email_data) do
				if basefunc.is_asset(key) then
					return 2308
				end
			end
		end

		DATA.emails[player_id][email_id].state = "read"
		skynet.send(DATA.service_config.data_service,"lua",
						"set_email_state",email_id,"read")

		local time = os.time()
		DATA.emails[player_id][email_id].complete_time = time
		skynet.send(DATA.service_config.data_service,"lua",
						"set_email_complete_time",email_id,time)
		return 0
	else

		if email.state == "read" then
			return 2307
		end

		return 2303
	end

end


local delete_email

--[[
	not_valid_time - 不验证时间

	领取成功后就删除
]]
local function get_attachment(player_id,email_id,not_valid_time)
	
	local email_data = DATA.email_datas[email_id]
	if not email_data or not next(email_data) then
		return 2304
	end

	local email = DATA.emails[player_id][email_id]
	if email.state == "read" then
		return 2305
	elseif email.state ~= "normal" then
		return 2303
	end

	if not not_valid_time then

		if email.valid_time > 0 
			and email.valid_time < os.time() then
			return 2302
		end

	end

	local asset_data = {}
	for key,value in pairs(email_data) do

		if basefunc.is_asset(key) then

			asset_data[#asset_data+1]={asset_type=key,value=value}

		elseif basefunc.is_object_asset(key) then

			if type(value) == "table" then

				-- 构建道具属性
				for i,as in ipairs(value) do
					
					if type(as) == "table" then

						-- 有效期 进行初始化
						if as.valid_time then
							as.valid_time = os.time() + as.valid_time
						end

						asset_data[#asset_data+1]=
						{
							asset_type = key,
							attribute = as,
						}

					end

				end

			end

		end
	end

	if next(asset_data)then

		DATA.emails[player_id][email_id].state = "read"
		skynet.send(DATA.service_config.data_service,"lua",
						"set_email_state",email_id,"read")

		local time = os.time()
		DATA.emails[player_id][email_id].complete_time = time
		skynet.send(DATA.service_config.data_service,"lua",
						"set_email_complete_time",email_id,time)
	else
		return 2304
	end

	if #asset_data > 0 then

		local asset_change_data = DATA.email_datas[email_id].asset_change_data
		local change_type = nil
		local change_id = nil
		if asset_change_data then
			change_type = asset_change_data.change_type
			change_id = asset_change_data.change_id
		end

		--向数据库进行修改，并且向玩家发送消息
		skynet.send(DATA.service_config.data_service,"lua","multi_change_asset_and_sendMsg"
									,player_id
									,asset_data
									,change_type
									,change_id
									,"email",email_id)

	end

	--删除
	delete_email(player_id,email_id)

	return 0
end


-- 删除邮件
delete_email = function (player_id,email_id)
	local email = DATA.emails[player_id][email_id]

	--已读或者过期可以删除
	if email.state == "read" or email.valid_time < os.time() then

		--未读邮件进行一次领取奖励
		if email.state == "normal" then
			get_attachment(player_id,email_id,true)
		end

		DATA.emails[player_id][email_id] = nil
		DATA.email_datas[email_id] = nil
		
		update_email_lists(player_id)

		skynet.send(DATA.service_config.data_service,"lua","delete_email",email_id)

		return 0
	else

		if email.state == "normal" then
			return 2306
		end

		return 2303
	end
end



--通知收件人
local function notify_receiver(receiver,id)
	nodefunc.send(receiver,"notify_new_email_msg",id)
end


--[[检测删除玩家溢出的邮件 
	每次玩家获取邮件IDs的时候进行一次
	update 中需要进行
]]
local function chk_delete_overflow_emails(player_id)

	if EMAIL_MAX_NUM < 1 then
		return
	end

	local num = CMD.get_email_count(player_id)
	if num > EMAIL_MAX_NUM then

		local n = num - EMAIL_MAX_NUM
		local email_ids = DATA.email_lists[player_id]

		table.sort( email_ids, function (a,b)
			return a<b
		end )

		for i=1,n do
			email_id = email_ids[i]
			local email = DATA.emails[player_id][email_id]

			if email.state == "normal" then
				--领取附件
				get_attachment(player_id,email_id,true)
			end

			DATA.emails[player_id][email_id] = nil
			DATA.email_datas[email_id] = nil
			
			skynet.send(DATA.service_config.data_service,"lua",
							"delete_email",email_id,"sys")

		end

		update_email_lists(player_id)

	end

end


-- 刷新函数 很久很久才刷新一次
local function update(dt)

	-- 清理删除不需要的邮件
	for player_id,emails in pairs(DATA.emails) do
		
		for email_id,email in pairs(emails) do

			--老的逻辑 过期或阅读后保留时间到了删除
			-- if (email.state=="read" and email.complete_time+DELETE_DELAY<os.time())
			-- 	or (email.valid_time > 0 and email.valid_time+DELETE_DELAY<os.time()) then

			-- 	DATA.emails[player_id][email_id] = nil
			-- 	DATA.email_datas[email_id] = nil
			-- 	update_email_lists(player_id)

			-- 	skynet.send(DATA.service_config.data_service,"lua","delete_email",email_id,"sys")

			-- 	skynet.sleep(10)
			-- end

			--只要过期就删除
			if email.valid_time > 0 and email.valid_time<os.time() then
				
				get_attachment(player_id,email_id,true)

				DATA.emails[player_id][email_id] = nil
				DATA.email_datas[email_id] = nil
				update_email_lists(player_id)

				skynet.send(DATA.service_config.data_service,"lua","delete_email",email_id,"sys")

				skynet.sleep(1)

			end

		end

		--清理离线玩家的邮件
		if not skynet.call(DATA.service_config.center_service,"lua",
								"query_service_node",player_id) then
			chk_delete_overflow_emails(player_id)
		end
		skynet.sleep(1)

	end

end

--[[外部发送邮件
	data={
		players={1,2,3}
		email={
			data -- 选填(默认{}) 这里是字符串形式的
		}
	}
]]
function CMD.external_send_email(data,opt_admin,reason)
	
	if type(data)~="table" or type(data.email)~="table" then
		print("external_send_email 1001.11 data error:",type(data),data and type(data.email))
		return 1001
	end

	if type(opt_admin)~="string" or string.len(opt_admin)<1 or string.len(opt_admin)>50 then
		print("external_send_email 1001.12 opt_admin error:",type(opt_admin),opt_admin)
		return 1001
	end

	if type(reason)~="string" or string.len(reason)<1 or string.len(reason)>5000 then
		print("external_send_email 1001.13 reason error:",type(reason),reason)
		return 1001
	end
	
	if data.players==nil then
		
		local email_data
		if type(data.email.data)=="string" then
			local data_ok
			email_data,data_ok = PUBLIC.parse_email_data(data.email.data)

			if not data_ok then
				print("external_send_email 1001.14 parse_email_data 1 error:",type(data_ok),data_ok)
				return 1001
			end
		end

		local emd = basefunc.deepcopy(data)
		emd.email.data = email_data
		skynet.send(DATA.service_config.data_service,"lua","insert_email_admin_opt_log"
					,"all",basefunc.safe_serialize(emd),opt_admin,reason)

		return CMD.send_everyone_email(data.email)

	elseif type(data.players)=="table" then

		local ok=skynet.call(DATA.service_config.data_service,"lua","is_player_exists",data.players)
		if not ok then
			return 2251
		end

		local email_data
		if type(data.email.data)=="string" then
			local data_ok
			email_data,data_ok = PUBLIC.parse_email_data(data.email.data)

			if not data_ok then
				print("external_send_email 1001.15 parse_email_data 2 error:",type(data_ok),data_ok)
				return 1001
			end
		end
		
		email_data.asset_change_data = {change_type=ASSET_CHANGE_TYPE.MANUAL_SEND,change_id=0}

		local error_code = 0
		for i,player_id in ipairs(data.players) do
			data.email.receiver = player_id
			data.email.data = email_data
			local em = basefunc.deepcopy(data.email)
			error_code = CMD.send_email(em)

			skynet.send(DATA.service_config.data_service,"lua","insert_email_admin_opt_log"
						,player_id,basefunc.safe_serialize(data),opt_admin,reason)

			if error_code ~= 0 then
				break
			end
		end

		return error_code
	else
		print("external_send_email 1001.16 data.players 3 error:",type(data.players))
		return 1001
	end

end



--[[发送邮件
	type
		"sys_welcome" -- 系统欢迎邮件
		"native" -- 原生邮件 邮件内容在data中的content中
	type
	title
	sender
	receiver
	state -- 选填(默认"normal")
	valid_time -- 选填(默认0)大于0才有效
	data -- 选填(默认{})
]]
function CMD.send_email(email)
	if not email 
		or not email.type
		or not email.sender
		or not email.receiver
		then 
			dump(email,"send_email error 1001.1:")
			--不合法
			return 1001
	end
	
	if type(email.type)~="string"
		or type(email.sender)~="string"
		or (email.title and type(email.title)~="string")
		or (email.data and type(email.data)~="table")
			then
			dump(email,"send_email error 1001.2:")
			return 1001
	end

	email.state = email.state or "normal"
	email.valid_time = email.valid_time or 0
	email.data = email.data or {}


	email.create_time=os.time()
	email.complete_time=0
	email.id=gen_email_id()

	DATA.email_datas[email.id]=email.data

	email.data=basefunc.safe_serialize(email.data)


	DATA.emails[email.receiver] = DATA.emails[email.receiver] or {}
	DATA.emails[email.receiver][email.id]=email

	DATA.email_lists[email.receiver] = DATA.email_lists[email.receiver] or {}
	local len = #DATA.email_lists[email.receiver]
	DATA.email_lists[email.receiver][len+1]=email.id

	--通知收件人
	notify_receiver(email.receiver,email.id)

	--存入数据库
	skynet.send(DATA.service_config.data_service,"lua","insert_email",email)

	return 0
end


-- 玩家获取邮件id列表
function CMD.get_email_list(player_id)

	if not DATA.email_lists[player_id] then
		DATA.email_lists[player_id] = {}
	end

	chk_delete_overflow_emails(player_id)
	return DATA.email_lists[player_id]
end


-- 玩家获取邮件数量
function CMD.get_email_count(player_id)
	if DATA.email_lists[player_id] then
		return #DATA.email_lists[player_id]
	else
		return 0
	end
end


-- 玩家获取邮件
function CMD.get_email(player_id,email_id)
	if not DATA.emails[player_id] then
		DATA.emails[player_id] = {}
	end
	local email = DATA.emails[player_id][email_id]
	if email then
		return 0,email
	else
		return 2301
	end

end


-- 玩家获取所有邮件
function CMD.get_all_email(player_id)
	if not DATA.emails[player_id] then
		DATA.emails[player_id] = {}
	end
	local emails = DATA.emails[player_id]
	if emails then
		return 0,emails
	else
		return 2301
	end

end


--对邮件进行操作
function CMD.opt_email(player_id,email_id,opt)

	if not DATA.emails[player_id] then
		DATA.emails[player_id]={}
		return 2301
	end

	local email = DATA.emails[player_id][email_id]
	if not email then
		return 2301
	end

	if opt == "read" then
		return read_email(player_id,email_id)
	elseif opt == "delete" then
		return delete_email(player_id,email_id)
	else
		return 1001
	end

end


--获取一个邮件的附件
function CMD.get_email_attachment(player_id,email_id)
	if not DATA.emails[player_id] then
		DATA.emails[player_id]={}
		return 2301
	end

	local email = DATA.emails[player_id][email_id]
	if not email then
		return 2301
	end

	local result = get_attachment(player_id,email_id)

	return result

end


function CMD.get_all_email_attachment(player_id)

	if CMD.get_email_count(player_id) < 1 then
		return 0,{}
	end

	local email_ids = {}
	for i,email_id in ipairs(DATA.email_lists[player_id]) do
		if get_attachment(player_id,email_id) == 0 then
			email_ids[#email_ids+1]=email_id
		end
	end

	return 0,email_ids
end





-- 检查是否可以停止服务
function base.PUBLIC.try_stop_service(_count,_time)

	-- 还有 执行，则不能结束
	if DATA.send_everyone_email_busy then
		return "wait","send_everyone_email_busy"
	end

	return "stop"
end


function base.CMD.start(_service_config)
	DATA.service_config = _service_config

	init_data()

	skynet.timer(UPDATE_INTERVAL,update)

end

-- 启动服务
base.start_service()
