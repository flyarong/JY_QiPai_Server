--
-- Author: hw
-- Date: 2018/3/28
-- Time: 
-- 说明：比赛场管理服务

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "ddz_match_enum"
require "normal_enum"

-- 场次管理模块： 开场条件，场次服务创建 报名
local manager = require "ddz_match_xsyd_manager_service.ddz_match_xsyd_manager"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

DATA.service_config = nil
DATA.match_config = nil
DATA.my_id = nil


-- 检查是否可以停止服务
function PUBLIC.try_stop_service(_count,_time)

	manager.stop_signup()

	local num = manager.get_run_player_num()
	if num > 0 then
		return "wait",string.format("player %s is runing!",num)
	else
		return "stop"
	end

end

function CMD.reload_config(_cfg,_mode)

	DATA.match_config = _cfg

	PUBLIC.use_new_config()

	print(string.format("ddz_match_manager config id %d reloaded !",_cfg.id))

	return 0
end


function PUBLIC.use_new_config()

	manager.use_new_config()

end

--查询比赛状态
function CMD.query_start_time()
	return "CALL_FAIL"
end

--查询比赛总排行
function CMD.query_all_rank()
	return "CALL_FAIL"
end

function CMD.record_players_info(_player_id,_player_name,_head_link)
	
end

function CMD.get_enter_info()
	
end

function CMD.start(_id,_service_config,_match_config)

	math.randomseed(os.time()*78437)

	DATA.service_config=_service_config
	DATA.my_id=_id

	DATA.match_config = _match_config

	manager.init()

end

-- 启动服务
base.start_service()



