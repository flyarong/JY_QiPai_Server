--
-- Author: lyx
-- Date: 2018/5/30
-- Time: 11:09
-- 说明：第三方服务 代理
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"
local cjson = require "cjson"

require "third_agent_service.phone_bind"
require "third_agent_service.share_invite_url"
require "third_agent_service.pay_phone_tariffe"
require "third_agent_service.client_push"

require "normal_enum"
require "printfunc"

local DATA = base.DATA
local CMD = base.CMD
local PUBLIC=base.PUBLIC

-- 发邮件（暂时不支持附件）
function CMD.send_email(_to,_subject,_context)
	
	local _svr = skynet.newservice("third_agent_service/send_email_service")
	if _svr then
		skynet.call(_svr,"lua","send_email",_to,_subject,_context)
	else
		print("launch third_agent_service error!!")
	end
end


function CMD.start(_service_config)

	DATA.service_config = _service_config
end

-- 启动服务
base.start_service()
