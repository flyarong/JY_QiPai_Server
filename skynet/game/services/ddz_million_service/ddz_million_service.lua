--
-- Author: hw


local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "ddz_match_enum"
require "normal_enum"

-- 报名模块
local signup = require "ddz_million_service/ddz_million_signup"

-- 场次管理模块： 开场条件，场次服务创建
local manager = require "ddz_million_service/ddz_million_manager"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

DATA.my_id = nil
DATA.service_config = nil
DATA.match_config = nil


--[[ 当前 状态
	DDZM_STATUS.READY 未开始
	DDZM_STATUS.SIGNUP 报名
	DDZM_STATUS.MATCH 比赛中
	DDZM_STATUS.FINISHED 比赛结束
	DDZM_STATUS.STOP 自行了断中

 ]]
DATA.status = nil



local function start_game()

	if DATA.status == DDZM_STATUS.READY then
		
		print("万人大奖赛开始报名了...")

		manager.init()

		-- 初始化报名模块
		signup.init(manager)

		DATA.status = DDZM_STATUS.SIGNUP

		skynet.send(DATA.service_config.ddz_million_center_service,"lua",
						"change_match_status",DATA.status)

	end

end



--游戏完成结束
function PUBLIC.game_final_finish()

	skynet.send(DATA.service_config.ddz_million_center_service,"lua",
				"change_match_status",DDZM_STATUS.FINISHED)
	

	skynet.timeout(500,function ()

		--销毁房间
		for room_id,_ in pairs(DATA.room_infos) do
			nodefunc.send(room_id,"destroy")
		end

		skynet.call(DATA.service_config.node_service,"lua","destroy",base.DATA.my_id)

		--销毁自己
		skynet.exit()

	end)
	
end

----外部调用停止自己
--function CMD.stop_service()
--	if DATA.status==DDZM_STATUS.READY then
--
--		DATA.status = DDZM_STATUS.STOP
--		skynet.call(DATA.service_config.node_service,"lua","destroy",DATA.my_id)
--		--销毁自己
--		skynet.exit()
--
--		return true
--	end
--
--	return false
--end

-- 检查是否可以停止服务
function PUBLIC.try_stop_service(_count,_time)

	if DATA.status==DDZM_STATUS.READY then

		DATA.status = DDZM_STATUS.STOP
		skynet.call(DATA.service_config.node_service,"lua","destroy",DATA.my_id)

		return "stop"
	end

	return "wait","game is runing !"
end


function CMD.start(_id,_service_config,_match_config)

	math.randomseed(os.time()*783137)

	DATA.service_config = _service_config
	DATA.match_config = _match_config
	DATA.my_id = _id
	DATA.status = DDZM_STATUS.READY

	local start_time_delay = DATA.match_config.base_info.signup_time-os.time()

	skynet.timeout(start_time_delay*100,start_game)

end

-- 启动服务
base.start_service()
