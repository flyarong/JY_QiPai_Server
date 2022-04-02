--
-- Author: lyx
-- Date: 2018/5/30
-- Time: 11:09
-- 说明：邮件发送服务，发送时启动，发完即退出
--

local skynet = require "skynet_plus"

local base = require "base"

local send_script_path = "python ./game/services/third_agent_service/send_email.py"

function base.CMD.send_email(_to,_subject,_context)

	skynet.timeout(1,function ()

		_subject = _subject or "【系统邮件】"
		_context = _context or "【邮件内容】"

		local _cmdline = send_script_path.." ".._to.." ".._subject .. " " .. _context

		local ok,status,code = os.execute(_cmdline)
		if ok then
			print("send email succ:",_cmdline)
		else
			print("send email fail:",ok,status,code,_cmdline)
		end

		skynet.timeout(1,function ()
			skynet.exit()
		end)
		
	end)
	
end

-- 启动服务
base.start_service()
