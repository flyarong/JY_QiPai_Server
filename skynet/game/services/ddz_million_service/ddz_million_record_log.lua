--
-- Author: yy
-- Date: 2018/3/28
-- Time: 
-- 说明：比赛场服务 进行匹配和安排

local skynet = require "skynet_plus"
local cjson = require "cjson"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "printfunc"
require "ddz_match_enum"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA


function PUBLIC.add_match_player_log(_player_id,_score,_final_round,_final_win,_award)
    local award = ""
    if _award then
        award = cjson.encode(_award)
    end

    skynet.send(DATA.service_config.data_service,"lua","add_ddz_million_player_log"
        ,_player_id,
        1,
        DATA.match_config.base_info.issue,
        _score,
        _final_round,
        _final_win,
        award
        )
end




function PUBLIC.start_match_log()

    skynet.send(DATA.service_config.data_service,"lua","start_ddz_million",
                1,
                DATA.match_config.base_info.issue,
                #DATA.players)

end

function PUBLIC.end_match_log()
    skynet.send(DATA.service_config.data_service,"lua","end_ddz_million",
                1,
                DATA.match_config.base_info.issue)
end


