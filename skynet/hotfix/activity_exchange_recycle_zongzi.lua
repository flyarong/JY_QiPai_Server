--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：测试
-- 使用方法：
--  call <service addr> exe_file "hotfix/fixtest.lua"
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"
require "normal_enum"


require "printfunc"

local DATA = base.DATA
local CMD = base.CMD
local PUBLIC = base.PUBLIC


-- 2019/6/12 6:10:0
DATA.recycle_zongzi_time = 1560291000

DATA.recycle_zongzi_execed = false

DATA.recycle_zongzi_value = 400

local function exec()
	
	-- 如果有系统配置就用
	local rt = skynet.getcfg_2number("activity_exchange_zongzi_recycle_time")
	if rt then
		DATA.recycle_zongzi_time = rt
	end

	if os.time() < DATA.recycle_zongzi_time then
		return
	end

	if not DATA.recycle_zongzi_execed then
		DATA.recycle_zongzi_execed = true


		-- 强行发放奖励
		local sql = "SELECT id player_id,prop_count num FROM player_prop WHERE prop_type = 'prop_zongzi' AND prop_count > 0 AND id NOT LIKE 'robot%';"
		local pd = skynet.call(DATA.service_config.data_service,"lua","db_query",sql)

		local email = 
		{
			type="native",
			title="端午节活动结束",
			sender="系统",
			receiver="",
			data={content="端午节活动已经结束，系统回收了您在活动期间获得的粽子，下面是您的奖励。"},
		}

		--发给所有玩家
		for i,d in ipairs(pd) do
			
			local yb = d.num * DATA.recycle_zongzi_value
			
			email.receiver = d.player_id
			email.data[PLAYER_ASSET_TYPES.FISH_COIN] = yb

			skynet.send(DATA.service_config.email_service,"lua","send_email",email)

			skynet.send(DATA.service_config.data_service,"lua","change_asset_and_sendMsg",
												d.player_id,"prop_zongzi",
												-d.num,"activity_exchange_recycle",0)

			skynet.sleep(1)
		end

		dump(pd,"recycle_zongzi+++")
	end
end

local function update()
	
	while true do

		exec()
		
		skynet.sleep(100*60)
		
	end

end


return function()

	-- 延迟等待一下
	skynet.timeout(1000,function ()
		skynet.fork(update)
	end)

	return "ok recycle zongzi"
end