--- 任务的消息中心

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local task_base_func = require "task.task_base_func"
local cluster = require "skynet.cluster"

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST
local PUBLIC = base.PUBLIC

DATA.task_msg_center_protect = {}
local task_msg_center = DATA.task_msg_center_protect

DATA.task_center_services_msg_listener = {}

------ 不用往任务中心发送的消息列表
task_msg_center.not_send_to_msg_center_vec = {
	
}


function PUBLIC.trigger_msg( msg_head , ... )
	print("xxx----------------PUBLIC.trigger_msg:",msg_head.name , ...)

	--dump(DATA.task_center_services_msg_listener , "xxxxxx-------------------------DATA.task_center_services_msg_listener:")

	---- 内部的消息通知 ，内部足够快，不用关心阻塞
	DATA.msg_dispatcher:call( msg_head.name , ... )
	
	---- 外部的消息通知，外部用send，也不用关心阻塞
	--[[if DATA.task_center_services_msg_listener[msg_head.name] then
		for key,data in pairs(DATA.task_center_services_msg_listener[msg_head.name]) do
			print("xxx----------------cluster.send:",data.cmd , DATA.my_id)
			cluster.send(data.node,data.addr,data.cmd , DATA.my_id ,...)
		end
	end--]]

	local is_send_to_center = true
	for key,msg_name in pairs( task_msg_center.not_send_to_msg_center_vec ) do
		if msg_head.name == msg_name then
			is_send_to_center = false
			break
		end
	end

	----- 向任务中心触发消息
	if is_send_to_center then
		skynet.send( DATA.service_config.msg_notification_center_service , "lua" , "trigger_msg" , msg_head , DATA.my_id , ... )
	end

end

---- 暂时不用
function CMD.add_service_msg_listener(msg_name , _target_link)
	DATA.task_center_services_msg_listener[msg_name] = DATA.task_center_services_msg_listener[msg_name] or {}

	local data = DATA.task_center_services_msg_listener[msg_name]

	data[_target_link.msg_tag] = {  
								msg_tag = _target_link.msg_tag,
								node = _target_link.node,
								addr = _target_link.addr,
								cmd = _target_link.cmd
							}
end

---- 暂时不用
function CMD.delete_msg_listener( msg_name , msg_tag )
	DATA.task_center_services_msg_listener[msg_name] = DATA.task_center_services_msg_listener[msg_name] or {}

	DATA.task_center_services_msg_listener[msg_name][msg_tag] = nil
end


function task_msg_center.init()
	--- 一上来去拿到外部服务关心的消息监听
	--DATA.task_center_services_msg_listener = skynet.call( DATA.service_config.msg_notification_center_service , "lua" , "query_all_msg_listener" )



end

return task_msg_center
