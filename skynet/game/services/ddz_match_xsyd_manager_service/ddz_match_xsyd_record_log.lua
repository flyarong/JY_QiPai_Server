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

    match_log.races[#match_log.races+1] = _race_id

end

function PUBLIC.add_match_log(_room_id,_t_num)
	local match_log = match_logs[_room_id.._t_num]
	local match_player_log = match_player_logs[_room_id.._t_num]

    skynet.send(DATA.service_config.data_service,"lua","add_match_nor_player_log",match_player_log)

    match_log.end_time = os.time()
    skynet.send(DATA.service_config.data_service,"lua","add_match_nor_log",match_log)

    match_logs[_room_id.._t_num] = nil
    match_player_logs[_room_id.._t_num] = nil

end

function PUBLIC.add_match_player_log(_room_id,_t_num,player_id,grades,rank,award)
	local match_player_log = match_player_logs[_room_id.._t_num] or {}
	match_player_logs[_room_id.._t_num] = match_player_log

    local len = 1 + #match_player_log
    match_player_log[len]={}
    match_player_log[len].player_id = player_id
    match_player_log[len].match_id = DATA.match_id
    match_player_log[len].score = grades
    match_player_log[len].rank = rank
    match_player_log[len].award = cjson.encode(award)

end

function PUBLIC.start_match_log(_room_id,_t_num)
	local match_log = {}
	match_logs[_room_id.._t_num] = match_log

    local _match_id = skynet.call(DATA.service_config.data_service,"lua","gen_match_nor_id")
    if not _match_id then
        skynet.fail(string.format("PUBLIC.start_match_log error: %s",_match_id))
    end

    match_log.id = _match_id
    match_log.name = DATA.match_config.match_data_config.name
    match_log.game_type = DATA.match_config.game_type
    match_log.game_id = DATA.match_config.game_id
    match_log.begin_time = os.time()
    match_log.player_count = 3
    match_log.races = {}

    DATA.match_id = _match_id
end


