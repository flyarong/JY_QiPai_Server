--
-- Author: yy
-- Date: 2018/3/30
-- Time: 15:14
-- 说明：邮件管理
--

local skynet = require "skynet_plus"
local base = require "base"

local PROTECTED = {}

local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC
local REQUEST=base.REQUEST


--查询邮件的数量
function base.REQUEST.query_email_count(self)
	local count = skynet.call(DATA.service_config.email_service,"lua","get_email_count",DATA.my_id)

	return {result=0,count=count}
end


--获取邮件id列表
function base.REQUEST.get_email_ids(self)
	local list = skynet.call(DATA.service_config.email_service,"lua","get_email_list",DATA.my_id)

	return {result=0,list=list}
end


--获取邮件
function base.REQUEST.get_email(self)
	
	if not self.email_id 
		or type(self.email_id)~="number"
		or self.email_id < 1 then
		return {result=1001}
	end

	local state,email = skynet.call(DATA.service_config.email_service,"lua",
										"get_email",DATA.my_id,self.email_id)

	return {result=state,email=email}
end

--获取所有邮件
function base.REQUEST.get_all_email(self)
	
	local state,emails = skynet.call(DATA.service_config.email_service,"lua",
										"get_all_email",DATA.my_id)

	return {result=state,emails=emails}
end


--阅读邮件
function base.REQUEST.read_email(self)
	
	if not self.email_id 
		or type(self.email_id)~="number"
		or self.email_id < 1 then
		return {result=1001}
	end

	local state = skynet.call(DATA.service_config.email_service,"lua",
										"opt_email",DATA.my_id,self.email_id,"read")

	return {result=state,email_id=self.email_id}
end


--删除邮件
function base.REQUEST.delete_email(self)
	
	if not self.email_id 
		or type(self.email_id)~="number"
		or self.email_id < 1 then
		return {result=1001}
	end

	local state = skynet.call(DATA.service_config.email_service,"lua",
										"opt_email",DATA.my_id,self.email_id,"delete")

	return {result=state,email_id=self.email_id}
end



--获取邮件附件
function base.REQUEST.get_email_attachment(self)
	
	if not self.email_id 
		or type(self.email_id)~="number"
		or self.email_id < 1 then
		return {result=1001}
	end

	local state = skynet.call(DATA.service_config.email_service,"lua",
										"get_email_attachment",DATA.my_id,self.email_id)

	return {result=state,email_id=self.email_id}
end



--一键获取所有邮件的附件
function base.REQUEST.get_all_email_attachment(self)
	
	local state,email_ids = skynet.call(DATA.service_config.email_service,"lua",
										"get_all_email_attachment",DATA.my_id)

	return {result=state,email_ids=email_ids}
end




--通知新邮件
function base.CMD.notify_new_email_msg(email_id)

	local state,email = skynet.call(DATA.service_config.email_service,"lua",
										"get_email",DATA.my_id,email_id)

	base.PUBLIC.request_client("notify_new_email_msg",{email=email})
	
end


return PROTECTED