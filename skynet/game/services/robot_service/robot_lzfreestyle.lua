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

local robot_lzfreestyle = basefunc.class(robot_base)


function robot_lzfreestyle:logic()
	
	-- skynet.fork(function ()
		
	-- 	while self._running do
	-- 		skynet.sleep(math.random(1000,6000))
	-- 		local ret = self:agent_request("lzdfg_signup",{id=self.signup_service_id})
	-- 		--dump(ret,"robot-dmg_signup")
	-- 	end

	-- end)

	skynet.fork(function ()
		
		while self._running do
			skynet.sleep(math.random(500,1000))
			local ret = self:agent_request("lzdfg_quit_game")
			--dump(ret,"robot-dmg_quit_game")
		end

	end)

end



-- 开始
function robot_lzfreestyle:start()
	robot_lzfreestyle.super.start(self)

	-- 登录
	if not self:login() then
		self:exit()
		return false
	end

	-- 拉取游戏列表
	local list = self:agent_request("lzdfg_req_game_list")
	if list.result ~= 0 then
		print(string.format("robot lzdfg_match_list error:%s",tostring(list.result)))
		self:exit()
		return false
	end

	-- 等一下报名，否则没有钱 :)
	skynet.sleep(base.DATA.LOGIN_WAIT_TIME)

	self.signup_service_id = 1

	if self.game_info then
		self.signup_service_id = self.game_info.game_id
	end

	-- 报名
	local ret = self:agent_request("lzdfg_signup",{id=self.signup_service_id})
	if ret.result ~= 0 then
		print(string.format("robot lzdfg_signup error:%s",tostring(ret.result)))
		self:exit()
		return false
	end
	self:show_info("lzdfg_signup ok!")


	self:logic()

	return true
end

return robot_lzfreestyle