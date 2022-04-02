--
-- Author: hw
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




return function()
    if DATA.player_achievements then
        for id,v in pairs(DATA.player_achievements) do
            --将player的业绩数据load进来  
            local data = skynet.call(DATA.service_config.data_service,"lua","sczd_load_player_achievements",id)
            if data and type(data)=="table" and data.yesterday_all_achievements and data.yesterday_tuikuan then
                v.yesterday_all_achievements = data.yesterday_all_achievements
                v.yesterday_tuikuan = data.yesterday_tuikuan
            end
        end
    end
    return "更新成功！"
end