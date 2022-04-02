--
-- Author: hw
-- Date: 2018/3/23
-- Time: 
-- 说明：比赛场斗地主桌子服务
--ddz_match_room_service
local skynet = require "skynet_plus"
require "skynet.manager"
require"printfunc"
local cjson = require "cjson"
local nodefunc = require "nodefunc"
local base=require "base"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

--启用数组稀疏后自动转换为字符串索引
cjson.encode_sparse_array(true,1,0)

local log = {}

--[[

操作人： 8 bit （座位号）
操作时间： 8 bit （收到权限 后 等了 n 秒 缩小了10倍 即 最大能存储 25.5s）
操作类型： 8 bit
数据长度：8 bit （后面的数据，单位 是 字节(8bit),如果是0，后面就没有了）
牌： 8 bit （多个。。。）

]]

--[[保存斗地主打牌过程数据日志
    一条一条的顺序插入
    _seat_no 座位号(1-4)
    _opt_type
        1  :出牌 data: 牌
        2  :定缺 data: 花色
        3  :过 data: 牌
        4  :碰 data: 牌
        5  :杠 data: 牌
        6  :胡 data: 牌
        7  :托管 data:nil长度0
        8  :取消托管 data:nil长度0
]]

local ddz_process_data_log={}
local normal_mjxl_process_get_permit_time={}


local function get_id(_game_id,_table_id)
	return _game_id.."_".._table_id
end


local function add_race_log(log)

    skynet.send(DATA.service_config.data_service,"lua","add_freestyle_nmjxl_race_log",
                    log.game_id,
                    log.begin_time,
                    log.end_time,
                    log.gang_count,
                    log.geng_count,
                    log.base_score,
                    log.operation_list,
                    log.zhuang_seat,
                    log.players,
                    "")

end


local function save_normal_mjxl_process_data_log(_id,_seat_no,_opt_type,_data)

    local ddz_process_data=ddz_process_data_log[_id]
    if not ddz_process_data then
        return false
    end

    local data_log={}
    local opt_time = skynet.now()-normal_mjxl_process_get_permit_time[_id]
    opt_time = math.min(opt_time*0.1,255)

    data_log[1]=string.char(_seat_no)
    data_log[2]=string.char(math.floor(opt_time))
    data_log[3]=string.char(_opt_type)

    --出牌类型
    if _opt_type < 7 then

        data_log[4]=string.char(1)
        data_log[5]=string.char(_data or 0)
    else
        data_log[4]=string.char(0)
    end

    ddz_process_data[#ddz_process_data+1]=table.concat(data_log)

    return true
end

local function concat_normal_mjxl_process_data_log(_id)

    local ddz_process_data=ddz_process_data_log[_id]
    if not ddz_process_data then
        return false
    end

    local log_entry=table.concat(ddz_process_data)

    -- print(log_entry)

    ddz_process_data_log[_id]=nil

	return log_entry
end



function PUBLIC.save_normal_mjxl_process_get_permit_time(_game_table_data,_table_id)

	local _d = _game_table_data

	local id = get_id(_d.game_id,_table_id)

    normal_mjxl_process_get_permit_time[id]=skynet.now()
end


--[[记录过程数据日志
    _seat_no 座位号(1-3)
    _opt_type
    _seat_no 座位号(1-4)
    _opt_type
        1  :定缺 data: 花色
        2  :出牌 data: 牌
        3  :过 data: 牌
        4  :碰 data: 牌
        5  :杠 data: 牌
        6  :胡 data: 牌
        7  :托管 data:nil长度0
        8  :取消托管 data:nil长度0
]]
function PUBLIC.save_process_data_log(_game_table_data,_table_id,_seat_no,_opt_type,_data)
	
	local _d = _game_table_data

	local id = get_id(_d.game_id,_table_id)

	--记录游戏开始日志
	save_normal_mjxl_process_data_log(id,_seat_no,_opt_type,_data)

end


--记录游戏开始日志
function PUBLIC.save_race_start_log(_game_table_data,_table_id)

	local _d=_game_table_data

	local id = get_id(_d.game_id,_table_id)

	ddz_process_data_log[id]={}
    normal_mjxl_process_get_permit_time[id]=0

	log[id]={}
	log[id].begin_time=os.time()
	log[id].game_id=_d.game_id
	log[id].game_model=1

end


--记录一局结束日志
function PUBLIC.save_race_over_log(_game_table_data,_table_id)
	
	local _d=_game_table_data

	local player_data={}

    local geng_count = 0

	for seat_no=1,4 do

        local pai_multi = _d.s_info[seat_no].pai_multi

        local pai_info = {
            pai=_d.play_data[seat_no].pai,
            pg_pai=_d.play_data[seat_no].pg_pai,
            multi=pai_multi,
            settle_type=_d.play_data[seat_no].settle_type,
            hu_datas=_d.s_info[seat_no].hu_datas,
        }

		player_data[seat_no]={
			player_id = _d.p_seat_number[seat_no],
			score = _d.s_info[seat_no].score or 0,
			multi = _d.s_info[seat_no].sum_multi or 0,
			gang_info = cjson.encode(_d.s_info[seat_no].gang_score),
            pai_info = cjson.encode(pai_info),
		}

        if pai_multi then
            geng_count = geng_count + (pai_multi.dai_geng or 0)
        end

	end

	local id = get_id(_d.game_id,_table_id)

	log[id].players = player_data
	log[id].gang_count = 0
	log[id].geng_count = geng_count
	log[id].base_score = _d.init_stake
	log[id].zhuang_seat = _d.play_data.zhuang_seat
	log[id].end_time = os.time()

	log[id].operation_list = concat_normal_mjxl_process_data_log(id)

	--比赛结束 日志统计
	add_race_log(log[id])
	
	log[id] = nil

end

