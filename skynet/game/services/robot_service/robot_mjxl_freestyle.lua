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

local robot_mjxl_freestyle = basefunc.class(robot_base)

local signup_count = 0

function robot_mjxl_freestyle:logic()
	
	-- skynet.fork(function ()
		
	-- 	while self._running do
	-- 		skynet.sleep(math.random(400,800))
	-- 		local ret = self:agent_request("nmjxlfg_signup",{id=self.signup_service_id})
	-- 		if ret.result == 0 then
	-- 			signup_count = signup_count  + 1
	-- 			--self:show_info("robot %s ,nmjxlfg_signup %s ok! (%d)",self.user_id,self.signup_service_id,signup_count)
	-- 		end
	-- 	end

	-- end)

	skynet.fork(function ()

		while self._running do
			skynet.sleep(math.random(2500,6000))
			self:agent_request("nmjxlfg_quit_game")

			--self:show_info("robot %s ,nmjxlfg_quit_game %s !!",self.user_id,self.signup_service_id)
		end

	end)

end


-- 开始
function robot_mjxl_freestyle:start()
	robot_mjxl_freestyle.super.start(self)

	-- 登录
	if not self:login() then
		self:exit()
		return false
	end

	-- 等一下报名
	skynet.sleep(base.DATA.LOGIN_WAIT_TIME)


	-- 拉取游戏列表
	local list = self:agent_request("nmjxlfg_req_game_list")
	if list.result ~= 0 then
		print(string.format("robot nmjxlfg_req_game_list error:%s",tostring(list.result)))
		self:exit()
		return false
	end

	--dump(list,"=============== nmjxlfg_req_game_list result ==================")
	self.signup_service_id = 1

	
	if self.game_info then
		self.signup_service_id = self.game_info.game_id
	end

	-- 报名
	local ret = self:agent_request("nmjxlfg_signup",{id=self.signup_service_id})
	if ret.result == 0 then
		signup_count = signup_count  + 1
		self:show_info("robot %s ,nmjxlfg_signup %s ok! (%d)",self.user_id,self.signup_service_id,signup_count)
	end

	self:logic()

	return true
end




return robot_mjxl_freestyle