--
-- Author: lyx
-- Date: 2018/4/19
-- Time: 19:59
-- 说明：email_data
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local CMD = base.CMD
local PROTECTED = {}

--当前最大的邮件ID
local email_max_id = 0

-- 初始化数据
function PROTECTED.init_email_data()

	local sql = "SELECT MAX(id) FROM emails_log;"
	local ret = base.DATA.db_mysql:query(sql)

	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	email_max_id = ret[1]["MAX(id)"] or 0

	return true
end


-- 获取邮件的最大ID
function base.CMD.get_email_max_id()

	return email_max_id

end


-- 获取邮件 每次都是从数据库拿原始数据
function base.CMD.get_emails()

	local sql = "select * from emails"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	return ret

end



--插入邮件日志
--[[
	类似邮件列表，但是这里的邮件不删除，和操作日志配合使用
]]
local function insert_email_log(data)

	local sql = string.format("insert into emails_log values(%s,'%s','%s','%s','%s','%s',FROM_UNIXTIME(%u),'%s',FROM_UNIXTIME(%u));"
								,data.id
								,data.type
								,data.title
								,data.sender
								,data.receiver
								,data.state
								,data.valid_time
								,data.data
								,data.create_time
								)

	base.DATA.sql_queue_slow:push_back(sql)
end



--[[插入邮件操作日志
	
	id
	email_id
	opt
	time
	
	对邮件的操作进行记录
	type:
	1:"create" 创建邮件 | 其实邮件自己就有创建的时间，这里只是为了统一，才多此一举
	2:"read" 已读邮件
	3:"sys_delete" 系统删除邮件
	4:"user_delete" 玩家删除邮件
	...

]]
local function insert_email_opt_log(id,opt)

	local sql = string.format("insert into emails_opt_log values(NULL,%s,'%s',FROM_UNIXTIME(%u));"
								,id
								,opt
								,os.time()
								)
	base.DATA.sql_queue_slow:push_back(sql)

end


--[[增加一个邮件

	id
	type
	title
	sender
	receiver
	state
	valid_time
	data
	create_time
	complete_time
]] 
function CMD.insert_email(data)

	local sql = string.format("insert into emails values(%s,'%s','%s','%s','%s','%s',%s,'%s',%s,%s);"
								,data.id
								,data.type
								,data.title
								,data.sender
								,data.receiver
								,data.state
								,data.valid_time
								,data.data
								,data.create_time
								,data.complete_time
								)

	base.DATA.sql_queue_slow:push_back(sql)
	insert_email_log(data)
	insert_email_opt_log(data.id,"create")
end


--删除邮件
--[[
	从邮件列表中删除
	type = "sys" --系统自动删除
	type = "user" --玩家自己删除
]]
function CMD.delete_email(id,type)

	type = type or "user"

	local sql = string.format("delete from emails where id=%s;"
							,id
							)

	base.DATA.sql_queue_slow:push_back(sql)

	if type == "sys" then
		insert_email_opt_log(id,"sys_delete")
	elseif type == "user" then
		insert_email_opt_log(id,"user_delete")
	end

end



--[[设置邮件状态
	1: "normal" --正常
	2: "read" 	--已读
	3: "invalid" --失效
	4: "close" --关闭
]]
function CMD.set_email_state(id,state)
	
	local sql = string.format("update emails set state='%s' where id=%s;"
								,state
								,id
								)

	base.DATA.sql_queue_slow:push_back(sql)
	insert_email_opt_log(id,state)

end



--[[设置邮件完成时间
	这只是逻辑层面不需要记录日志
	完成时间 包括 阅读的时刻 等
	主要用于记录最后一次操作的时刻，用于清理邮件依据
]]
function CMD.set_email_complete_time(id,time)
	
	local sql = string.format("update emails set complete_time=%s where id=%s;"
							,time
							,id
							)

	base.DATA.sql_queue_slow:push_back(sql)

end



--插入邮件日志
--[[
	类似邮件列表，但是这里的邮件不删除，和操作日志配合使用
]]
function base.CMD.insert_email_admin_opt_log(player_id,data,opt_admin,reason)

	local sql = string.format("insert into emails_admin_opt_log values(NULL,'%s','%s',FROM_UNIXTIME(%u),'%s','%s');"
								,player_id
								,data
								,os.time()
								,opt_admin
								,reason
								)

	base.DATA.sql_queue_slow:push_back(sql)
end


return PROTECTED