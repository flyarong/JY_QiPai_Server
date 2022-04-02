--
-- Author: hw
-- Date: 2018/6/11
-- Time: 
-- 说明：癞子比赛场斗地主桌子服务
--tyddz_match_room_service
local skynet = require "skynet_plus"
require "skynet.manager"
require"printfunc"
local nodefunc = require "nodefunc"
local base=require "base"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA



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
    _seat_no 座位号(1-3)
    _opt_type
        0-14 : 出牌(15种牌型) data:数据为牌的数组 长度(0-n) (如果是0不出牌可以不用传数据)
        20  :叫地主 data: 数据为叫的分数(0-3)长度1
        21  :加倍 data: nil长度0
        22  :不加倍 data:nil长度0
        23  :托管 data:nil长度0
        24  :取消托管 data:nil长度0

        25：闷
        26：看牌
        27：抓牌
        28：不抓
        29：倒
        30：不倒
        31：拉
        32：不拉
]]

local ddz_process_data_log={}
local ddz_process_get_permit_time={}


local function get_id(_game_id,_table_id)
	return _game_id.."_".._table_id
end


local function add_race_log(log)

    skynet.send(DATA.service_config.data_service,"lua","add_freestyle_tyddz_race_log",
                    log.game_id,
                    log.begin_time,
                    log.end_time,
                    log.bomb_count,
                    log.spring,
                    log.base_score,
                    log.base_rate,
                    log.operation_list,
                    log.dizhu_seat,
                    log.players,
                    "")

end

local function save_ddz_process_data_log(_id,_seat_no,_opt_type,_data)

    local ddz_process_data=ddz_process_data_log[_id]
    if not ddz_process_data then
        return false
    end

    local data_log={}
    local opt_time = skynet.now()-ddz_process_get_permit_time[_id]
    opt_time = math.min(opt_time*0.1,255)

    data_log[1]=string.char(_seat_no)
    data_log[2]=string.char(math.floor(opt_time))
    data_log[3]=string.char(_opt_type)

    --出牌类型
    if _opt_type < 20 then
        local len = _data and #_data or 0
        data_log[4]=string.char(len)
        for i=1,len do
            data_log[4+i]=string.char(_data[i])
        end
    elseif _opt_type == 20 then
        --叫地主
        data_log[4]=string.char(1)
        data_log[5]=string.char(_data)
    else
        data_log[4]=string.char(0)
    end

    ddz_process_data[#ddz_process_data+1]=table.concat(data_log)

    return true
end

local function concat_ddz_process_data_log(_id)

    local ddz_process_data=ddz_process_data_log[_id]
    if not ddz_process_data then
        return false
    end

    local log_entry=table.concat(ddz_process_data)

    -- print(log_entry)

    ddz_process_data_log[_id]=nil

	return log_entry
end



function PUBLIC.save_ddz_process_get_permit_time(_game_table_data,_table_id)

	local _d = _game_table_data

	local id = get_id(_d.game_id,_table_id)

    ddz_process_get_permit_time[id]=skynet.now()
end


--[[记录过程数据日志
    _seat_no 座位号(1-3)
    _opt_type
        0-14 : 出牌(15种牌型) data:数据为牌的数组 长度(0-n) (如果是0不出牌可以不用传数据)
        20  :叫地主 data: 数据为叫的分数(0-3)长度1
        21  :加倍 data: nil长度0
        22  :不加倍 data:nil长度0
        23  :托管 data:nil长度0
        24  :取消托管 data:nil长度0
]]
function PUBLIC.save_process_data_log(_game_table_data,_table_id,_seat_no,_opt_type,_data)
	
	local _d = _game_table_data

	local id = get_id(_d.game_id,_table_id)

	--记录游戏开始日志
	save_ddz_process_data_log(id,_seat_no,_opt_type,_data)

end


--记录游戏开始日志
function PUBLIC.save_race_start_log(_game_table_data,_table_id)

	local _d=_game_table_data

	local id = get_id(_d.game_id,_table_id)

	ddz_process_data_log[id]={}
    ddz_process_get_permit_time[id]=0

	log[id]={}
	log[id].begin_time=os.time()
	log[id].game_id=_d.game_id

end


--记录一局结束日志
function PUBLIC.save_race_over_log(_game_table_data,_table_id)
	
	local _d=_game_table_data

	--春天或者反春  1春天  2 反春
	local chuntian = {0,0,0}
	if _d.is_chuntian > 0 then
		
		local dz_no = _d.play_data.dizhu
		local nm_no1 = dz_no+1>3 and dz_no-2 or dz_no+1
		local nm_no2 = dz_no+2>3 and dz_no-1 or dz_no+2

		if _d.is_chuntian == 1 then
			chuntian[dz_no]=1
			chuntian[nm_no1]=3
			chuntian[nm_no2]=3
		else
			chuntian[dz_no]=2
			chuntian[nm_no1]=4
			chuntian[nm_no2]=4
		end

	end
	
	local player_data={}

	for seat_no=1,3 do
		player_data[seat_no]={
			player_id = _d.p_seat_number[seat_no],
			score = _d.s_info.award[seat_no],
			rate = _d.p_rate[seat_no],
			bomb_count = _d.p_bomb_count[seat_no],
			spring = chuntian[seat_no],
		}
	end

	local _d=_game_table_data

	local id = get_id(_d.game_id,_table_id)

	log[id].players = player_data
	log[id].bomb_count = _d.bomb_count
	log[id].spring = _d.is_chuntian
	log[id].base_score = _d.init_stake
	log[id].base_rate = _d.init_rate
	log[id].dizhu_seat = _d.play_data.dizhu
	log[id].end_time = os.time()

	log[id].operation_list = concat_ddz_process_data_log(id)

	--比赛结束 日志统计
	add_race_log(log[id])
	
    log[id] = nil
    
end

