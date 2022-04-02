--
-- Author: wss
-- Date: 2018/4/11
-- Time: 15:07
-- 说明：
-- 使用方法：
-- call task_center_service exe_file "hotfix/fix_task_log.lua"
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
local PUBLIC=base.PUBLIC

function CMD.add_player_task_log( _player_id , _task_id , _process_change , _now_progress )
	if _process_change ~= 0 then
		skynet.send(DATA.service_config.data_service,"lua","add_player_task_log" ,_player_id , _task_id , _process_change , _now_progress )
	end
end

return function()

    return "send ok!!!"

end