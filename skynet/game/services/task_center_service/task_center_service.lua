
local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"

require "normal_enum"

require "printfunc"

local DATA = base.DATA
local CMD = base.CMD
local PUBLIC=base.PUBLIC

DATA.service_config = nil

DATA.task_main_config = {}

DATA.hongbao_task_config = {}
DATA.vip_duiju_hongbao_task_config = {}
DATA.jingyu_award_box_task_config = {}
DATA.stepstep_money_config = {}

--- 玩家任务数据
DATA.player_task_data = nil

function CMD.start(_service_config)

	DATA.service_config = _service_config

	base.import("game/services/task_center_service/task_center_op_interface.lua")

	PUBLIC.load_all_player_task_data()

	--PUBLIC.refresh_config()

end

-- 启动服务
base.start_service()
