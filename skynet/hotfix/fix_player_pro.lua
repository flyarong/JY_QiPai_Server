--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：发公告
-- 使用方法：
-- call broadcast_center_service exe_file "hotfix/fix_broadcast.lua"
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


--[[ 选出 好牌 玩家
    返回：好牌分数 + 好牌座位 + 差牌座位
--]]
function PUBLIC.get_haopai_data(data,_p_seat_number)

    local _max_weight = 0
    local _pro_player_id
    local _pro_seat_num
    local _pro_power

    local _laji_seat -- 垃圾牌座位号

    for _seat,_pid in pairs(_p_seat_number) do
    
    
        if basefunc.is_real_player(_pid) then

            if PROTECT_DEBUG then
                PUBLIC.update_protect_player_data(data,_pid,-3000)
            end
    
            local _w,_power = PUBLIC.get_haopai_weight(data,_pid)
            if _w and (not _max_weight or _w > _max_weight) then

                if _pro_seat_num and not _laji_seat then
                    _laji_seat = _pro_seat_num
                end

                _max_weight = _w
                _pro_player_id = _pid
                _pro_seat_num = _seat
                _pro_power = _power
            end

        else
            _laji_seat = _seat
        end
    end

    if not _pro_seat_num then
        print("get_haopai_data 1 error!")
        return nil
    end

    if _pro_player_id then

        if not _laji_seat then

            if not _pro_seat_num then
                print("get_haopai_data 2 error:",_pro_player_id)
                return nil
            end

            if not GAME_TYPE_SEAT[data.game_data.game_type] then
                print("get_haopai_data 3 error:",_pro_player_id,data.game_data.game_type)
                return nil
            end

            _laji_seat = ((_pro_seat_num % GAME_TYPE_SEAT[data.game_data.game_type]) + 1)
        end

        local _pd = data.game_data.players[_pro_player_id]
        _pd.haopai_count = _pd.haopai_count + 1
        _pd.lost_count = 0

        local haopai_cfg,is_xinshou = PUBLIC.get_hao_pai_config(data,_pro_player_id)
        _pd.max_lost_count = PUBLIC.get_random_lose_count(data,haopai_cfg,is_xinshou)
        print("player haopai trigger, data reset:",_pro_player_id,
                                                data.game_info.game_model,data.game_info.game_id,
                                                is_xinshou,_pd.max_lost_count,_pd.haopai_count)

        return _pro_power,_pro_seat_num,_laji_seat

    else
        return nil
    end
end

-- 更新保护数据
-- _player_win ： player_id => 赢的数量
function CMD.udpate_protect_data(_game_info,_player_win)

   
end

function CMD.query_protect_haopai_param(_game_info,_p_seat_number)
    return nil
end

return function()

    
    return "send ok!!!333"

end