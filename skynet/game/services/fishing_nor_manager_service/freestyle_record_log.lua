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

local match_logs = {}
local match_player_logs = {}


function CMD.add_race_id_log(_race_id,_room_id,_t_num)

    local match_log = match_logs[_room_id.._t_num]

    if match_log then
        match_log.races[#match_log.races+1] = _race_id
    end

end

function PUBLIC.add_match_log(_room_id,_t_num)
    local match_log = match_logs[_room_id.._t_num]
    local match_player_log = match_player_logs[_room_id.._t_num]

    --dump(match_player_logs , "--->>>>> add_match_log:")
    --print("--->>>>> add_match_log:",_room_id,_t_num)

    if match_player_log then
        skynet.send(DATA.service_config.data_service,"lua","add_freestyle_race_player_log",match_player_log)
    end

    match_log.end_time = os.time()
    skynet.send(DATA.service_config.data_service,"lua","add_freestyle_race_log",match_log)

    match_logs[_room_id.._t_num] = nil
    match_player_logs[_room_id.._t_num] = nil

end

function PUBLIC.add_match_player_log(_room_id,_t_num,player_id,grades,real_grades)
    local index = _room_id.._t_num
    local match_player_log = match_player_logs[index] or {}
    match_player_logs[index] = match_player_log

    local len = 1 + #match_player_log
    match_player_log[len]={}
    match_player_log[len].player_id = player_id
    match_player_log[len].match_id = match_logs[index].id
    match_player_log[len].score = grades or 0
    match_player_log[len].real_score = real_grades or 0
    match_player_log[len].room_rent = DATA.game_config.room_rent.asset_count

    --dump(match_player_logs , "--->>>>> add_match_player_log:")
    --print("--->>>>> add_match_player_log:",_room_id,_t_num)
end

function PUBLIC.start_match_log(_room_id,_t_num,_game_tag)
    local match_log = {}
    match_logs[_room_id.._t_num] = match_log

    local _match_id = 172169200 + math.random(100000,999999)

    match_log.id = _match_id
    match_log.name = DATA.game_config.game_name
    match_log.game_type = DATA.game_config.game_type
    match_log.game_id = DATA.game_config.id
    match_log.begin_time = os.time()
    match_log.player_count = DATA.game_seat_num
    match_log.races = {}

    if _game_tag == "xsyd" then
        match_log.name = match_log.name .. "_xsyd"
    end

    _match_id = skynet.call(DATA.service_config.data_service,"lua","gen_freestyle_race_id")
    
    _match_id = tonumber(_match_id)

    if _match_id then
        match_log.id = _match_id
    end

end


