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
		
		while self._running do

			if not self.is_signup_ok then
				
				local ret = self:agent_request("dbwg_signup",{id=self.signup_service_id})
				
				if ret.result == 0 then
					self.is_signup_ok = true
				end

			end

			skynet.sleep(math.random(300,500))

		end

	end)

	skynet.fork(function ()
		
		while self._running do

			if self.is_signup_ok then

				local ret = self:agent_request("dbwg_quit_game")
				if ret.result == 0 then
					self.is_signup_ok = false
				end
				
			end

			skynet.sleep(math.random(6000,7000))
			
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

	-- 拉取游戏列表
	local list = self:agent_request("dbwg_req_game_list")
	if list.result ~= 0 then
		print(string.format("robot dmg_req_game_list error:%s",tostring(list.result)))
		self:exit()
		return false
	end

	-- 等一下报名，否则没有钱 :)
	skynet.sleep(base.DATA.LOGIN_WAIT_TIME)
	
	self.is_signup_ok = false
	self.signup_service_id = 1
	
	self:logic()

	return true
end

return robot_normal