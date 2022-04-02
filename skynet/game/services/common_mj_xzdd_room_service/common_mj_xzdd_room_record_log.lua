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
        1  :定缺 data: 花色
        2  :出牌 data: 牌
        3  :过 data: 牌
        4  :碰 data: 牌
        5  :杠 data: 牌
        6  :胡 data: 牌
        7  :托管 data:nil长度0
        8  :取消托管 data:nil长度0
        9  :换三张 data: 牌
        10 :打飘 data: 是否飘
        11 :破产 data: nil
        12 :摸牌 data: 牌
]]

local ddz_process_data_log={}
local majiang_process_get_permit_time={}


local function get_id(_game_id,_table_id)
	return _game_id.."_".._table_id
end


local function add_race_log(log)

    return skynet.call(DATA.service_config.data_service,"lua","add_nor_mj_xzdd_race_log",
                    log.game_id,
                    log.game_model,
                    log.begin_time,
                    log.end_time,
                    log.init_rate,
                    log.max_rate,
                    log.init_stake,
                    log.fapai,
                    log.operation_list,
                    log.zhuang_seat,
                    log.players)

end


local function save_majiang_process_data_log(_id,_seat_no,_opt_type,_data)
    
    local ddz_process_data=ddz_process_data_log[_id]
    if not ddz_process_data then
        return false
    end

    local data_log={}
    local opt_time = skynet.now()-majiang_process_get_permit_time[_id]
    opt_time = math.min(opt_time*0.1,255)

    data_log[1]=string.char(_seat_no)
    data_log[2]=string.char(math.floor(opt_time))
    data_log[3]=string.char(_opt_type)

    --出牌类型
    if _opt_type < 7 then
        data_log[4]=string.char(1)
        data_log[5]=string.char(_data or 0)
    elseif _opt_type == 9 then
        data_log[4]=string.char(3)
        data_log[5]=string.char(_data[1] or 0)
        data_log[6]=string.char(_data[2] or 0)
        data_log[7]=string.char(_data[3] or 0)
    elseif _opt_type == 10 then
        data_log[4]=string.char(1)
        data_log[5]=string.char(_data or 0)
    elseif _opt_type == 12 then
        data_log[4]=string.char(1)
        data_log[5]=string.char(_data or 0)
    else
        data_log[4]=string.char(0)
    end

    ddz_process_data[#ddz_process_data+1]=table.concat(data_log)

    return true
end

local function concat_majiang_process_data_log(_id)

    local ddz_process_data=ddz_process_data_log[_id]
    if not ddz_process_data then
        return false
    end

    local log_entry=table.concat(ddz_process_data)

    -- print(log_entry)

    ddz_process_data_log[_id]=nil

	return log_entry
end



function PUBLIC.save_majiang_process_get_permit_time(_d,_table_id)

	local id = get_id(_d.game_id,_table_id)

    majiang_process_get_permit_time[id]=skynet.now()
end


--[[记录过程数据日志
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
        9  :换三张
        10 :打漂
        11 :游戏破产

]]
function PUBLIC.save_process_data_log(_game_table_data,_table_id,_seat_no,_opt_type,_data)
	
	local _d = _game_table_data

	local id = get_id(_d.game_id,_table_id)

	save_majiang_process_data_log(id,_seat_no,_opt_type,_data)

end


--记录游戏开始日志
function PUBLIC.save_race_start_log(_d,_table_id)

	local id = get_id(_d.game_id,_table_id)

	ddz_process_data_log[id]={}
    majiang_process_get_permit_time[id]=0

	log[id]={}
    log[id].begin_time=os.time()
    log[id].init_rate = _d.init_rate
    log[id].max_rate = _d.max_rate or 0
    log[id].init_stake = _d.init_stake
	log[id].game_id=_d.game_id
	log[id].game_model=_d.model_name
    log[id].fapai=""

end

--记录日志
function PUBLIC.save_fapai_log(_d,_table_id)

    local id = get_id(_d.game_id,_table_id)
    
    local pai_data = {}
    for _seat_num=1,_d.seat_count do
        pai_data[_seat_num] = _d.play_data[_seat_num].pai
    end

    log[id].fapai=cjson.encode(pai_data)
end

--记录一局结束日志
function PUBLIC.save_race_over_log(_d,_table_id)

    -- 中途解散，则不记录
    if _d.is_break_race then
        return 
    end

	local player_data={}

	for seat_no=1,_d.seat_count do

        local pai_multi = _d.s_info[seat_no].pai_multi
        local pai_info = {
            pai=_d.play_data[seat_no].pai,
            pg_pai=_d.play_data[seat_no].pg_pai,
            multi=pai_multi,
            settle_type=_d.play_data[seat_no].settle_type,
            piaoNum = _d.play_data[seat_no].piaoNum,
        }

		player_data[seat_no]={
			player_id = _d.p_seat_number[seat_no],
			score = _d.s_info[seat_no].score or 0,
			multi = _d.s_info[seat_no].sum_multi or 0,
			gang_info = cjson.encode(_d.s_info[seat_no].gang_score),
            pai_info = cjson.encode(pai_info),
		}

	end

	local id = get_id(_d.game_id,_table_id)

	log[id].players = player_data
	log[id].zhuang_seat = _d.play_data.zhuang_seat
	log[id].end_time = os.time()

	log[id].operation_list = concat_majiang_process_data_log(id)

	--比赛结束 日志统计
	local ret_id = add_race_log(log[id])
    nodefunc.send(DATA.mgr_id,"add_race_id_log",ret_id,DATA.my_id,_table_id)
	
	log[id] = nil

    return ret_id

end

