--
-- Author: hw
-- Date: 2018/3/23
-- Time: 
-- 说明：比赛场斗地主桌子服务
--gobang_match_room_service
local skynet = require "skynet_plus"
require "skynet.manager"
require"printfunc"
local nodefunc = require "nodefunc"
local base=require "base"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA
local cjson = require "cjson"
cjson.encode_sparse_array(true,1,0)

local log = {}

--[[

操作人： 8 bit （座位号）
操作时间： 8 bit （收到权限 后 等了 n 秒 缩小了10倍 即 最大能存储 25.5s）
操作类型： 8 bit
数据长度：8 bit （后面的数据，单位 是 字节(8bit),如果是0，后面就没有了）
牌： 8 bit （多个。。。）

]]

--[[保存下棋过程数据日志
    一条一条的顺序插入
    _seat_no 座位号(1-2)
    _opt_type
        1  :下棋 data: 数据为xy长度2
        2  :pass data: nil长度0
        3  :求和 data:nil长度0
        4  :悔棋 data:悔棋步数n长度1
        5  :求和反馈 data:1/0长度1
        6  :悔棋反馈 data:1/0长度1
        7  :认输 data:nil长度0
]]

local gobang_process_data_log={}
local gobang_process_get_permit_time={}


local function get_id(_game_id,_table_id)
	return _game_id.."_".._table_id
end


local function add_race_log(log)

    local game_model = log.game_model==0 and "drivingrange" or "diamond_field"
    return skynet.call(DATA.service_config.data_service,"lua","add_nor_gobang_nor_race_log",
                        log.game_id,
                        log.begin_time,
                        log.end_time,
                        log.base_score,
                        log.base_rate,
                        log.max_rate,
                        log.operation_list,
                        log.first_seat,
                        log.settle_type,
                        log.players,
                        game_model,
                        "")

end

local function save_gobang_process_data_log(_id,_seat_no,_opt_type,_data)

    local gobang_process_data=gobang_process_data_log[_id]
    if not gobang_process_data then
        return false
    end

    local data_log={}
    local opt_time = skynet.now()-gobang_process_get_permit_time[_id]
    opt_time = math.min(opt_time*0.01,255)

    data_log[1]=string.char(_seat_no)
    data_log[2]=string.char(math.floor(opt_time))
    data_log[3]=string.char(_opt_type)

    --出牌类型
    if _opt_type == 1 then
        data_log[4]=string.char(2)
        data_log[5]=string.char(_data[1])
        data_log[6]=string.char(_data[2])
    elseif _opt_type == 4 
        or _opt_type == 5
        or _opt_type == 6 then
            data_log[4]=string.char(1)
            data_log[5]=string.char(_data)
    else
        data_log[4]=string.char(0)
    end

    gobang_process_data[#gobang_process_data+1]=table.concat(data_log)

    return true
end

local function concat_gobang_process_data_log(_id)

    local gobang_process_data=gobang_process_data_log[_id]
    if not gobang_process_data then
        return false
    end

    local log_entry=table.concat(gobang_process_data)

    -- print("xxxxxxxx++++++",log_entry)

    gobang_process_data_log[_id]=nil

	return log_entry
end



function PUBLIC.save_gobang_process_get_permit_time(_game_table_data,_table_id)

	local _d = _game_table_data

	local id = get_id(_d.game_id,_table_id)

    gobang_process_get_permit_time[id]=skynet.now()
end


--[[记录过程数据日志
]]
function PUBLIC.save_process_data_log(_game_table_data,_table_id,_seat_no,_opt_type,_data)
	
	local _d = _game_table_data

	local id = get_id(_d.game_id,_table_id)

	--记录游戏开始日志
	save_gobang_process_data_log(id,_seat_no,_opt_type,_data)

end


--记录游戏开始日志
function PUBLIC.save_race_start_log(_game_table_data,_table_id)

	local _d=_game_table_data

	local id = get_id(_d.game_id,_table_id)

	gobang_process_data_log[id]={}
    gobang_process_get_permit_time[id]=0

	log[id]={}
	log[id].begin_time=os.time()
	log[id].game_id=_d.game_id

end



--记录一局结束日志
function PUBLIC.save_race_over_log(_game_table_data,_table_id)
	
	local _d=_game_table_data

	local player_data={}

	for seat_no=1,2 do
		player_data[seat_no]={
			player_id = _d.p_seat_number[seat_no],
			score = _d.settlement_info.award[seat_no],
			rate = _d.p_rate,
		}
	end

	local id = get_id(_d.game_id,_table_id)

	log[id].players = player_data
	log[id].base_score = _d.init_stake
	log[id].base_rate = _d.init_rate
    log[id].max_rate = _d.max_rate or 0
	log[id].first_seat = _d.first_seat
    log[id].settle_type = _d.settlement_info.type
	log[id].end_time = os.time()

	log[id].operation_list = concat_gobang_process_data_log(id)

	--比赛结束 日志统计
	local race_id = add_race_log(log[id])
    nodefunc.send(DATA.mgr_id,"add_race_id_log",race_id,DATA.my_id,_table_id)
	
    log[id] = nil
    
    return race_id
end

