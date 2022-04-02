--
-- Author: lyx
-- Date: 2018/4/25
-- Time: 10:52
-- 说明：普通 机器人
--

local skynet = require "skynet_plus"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local base = require "base"

local robot_base = require "robot_service/robot_base"

math.randomseed(os.time())

local robot_normal = basefunc.class(robot_base)


function robot_normal:logic()
	
	skynet.fork(function ()
		
		while true do
			skynet.sleep(math.random(4000,6000))
			local ret = self:agent_request("nor_mg_xsyd_signup")
			if ret == 0 then
				return
			end
		end

	end)

end



-- 开始
function robot_normal:start()
	robot_normal.super.start(self)

	-- 登录
	if not self:login() then
		self:exit()
		return false
	end

	-- 等一下报名，否则没有钱 :)
	skynet.sleep(300)

	-- 报名
	local ret = self:agent_request("nor_mg_xsyd_signup")

	-- dump(ret,"dmg_xsyd_signup")

	if ret.result ~= 0 then
		self:logic()
	end

	return true
end

return robot_normal