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
			skynet.sleep(math.random(1000,6000))
			local ret = self:agent_request("nor_mg_signup",{id=self.signup_service_id})
			-- dump(ret,"robot-dmg_signup")
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
	skynet.sleep(base.DATA.LOGIN_WAIT_TIME)

	skynet.sleep(200+math.random(100,500))

	self.signup_service_id = 5

	-- 报名
	local ret = self:agent_request("nor_mg_signup",{id=self.signup_service_id})
	if ret.result ~= 0 then
		print(string.format("robot nor_mg_signup error:%s",tostring(ret.result)))
		self:exit()
		return false
	end
	self:show_info("nor_mg_signup ok!")


	self:logic()

	return true
end

return robot_normal