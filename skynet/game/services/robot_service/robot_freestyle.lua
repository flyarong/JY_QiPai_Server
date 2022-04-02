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
require "printfunc"

local robot_base = require "robot_service/robot_base"

math.randomseed(os.time())

local robot_freestyle = basefunc.class(robot_base)

function robot_freestyle:logic()
	
	-- skynet.fork(function ()
		
	-- 	while true do
	-- 		skynet.sleep(math.random(1000,6000))
	-- 		local ret = self:agent_request("dfg_signup",{id=self.signup_service_id})
	-- 		--dump(ret,"robot-dfg_signup")
	-- 	end

	-- end)

	skynet.fork(function ()
		
		while self._running do
			skynet.sleep(math.random(500,1000))
			local ret = self:agent_request("dfg_quit_game")
			--dump(ret,"robot-dfg_quit_game")
		end

	end)

end


-- 开始
function robot_freestyle:start()
	robot_freestyle.super.start(self)

	-- 登录
	if not self:login() then
		self:exit()
		return false
	end

	-- 等一下报名
	skynet.sleep(base.DATA.LOGIN_WAIT_TIME)

	-- 拉取游戏列表
	local list = self:agent_request("dfg_req_game_list")
	if list.result ~= 0 then
		print(string.format("robot dfg_req_game_list error:%s",tostring(list.result)))
		self:exit()
		return false
	end


	self.signup_service_id = 2

	if self.game_info then
		self.signup_service_id = self.game_info.game_id
	end

	-- 报名
	local ret = self:agent_request("dfg_signup",{id=self.signup_service_id})
	if ret.result ~= 0 then
		print(string.format("robot dfg_signup error:%s",tostring(ret.result)))
		self:exit()
		return false
	end
	self:show_info("dfg_signup ok!")


	self:logic()

	return true
end












return robot_freestyle