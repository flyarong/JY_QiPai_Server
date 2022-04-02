--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：玩家破产保护
--[[
    1、防沮丧系统：和 抽水 系统 同时起作用。
    2、新手保护： 不受 抽水 系统 影响
]]

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"

require "normal_enum"

require "printfunc"

local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC

--local PROTECT_DEBUG = true


DATA.protect_data = DATA.protect_data or 
{
    -- player id => 首次登录时间
    first_login_time = {},

    --[[ 
        game_model => {
            game_id => {
                game_info 游戏信息
                players : player_id => {
                    lost_count 连续输局数
                    haopai_count 已触发好牌次数
                    last_time 最近一次记录时间

                    game_count 已经玩过的总局数

                    max_lost_count 最大连输次数（达到 则 发好牌）
                }
                
            }
        }
        
    --]]
    player_game_data = {},

    -- 函数：生成好牌参数
    gen_haopai_param = {},
}
local D = DATA.protect_data

function PUBLIC.init_protect()
    
end


function PUBLIC.get_and_refresh_game_data(_game_info)

    local _match_data = D.player_game_data[_game_info.game_model] or {}
    D.player_game_data[_game_info.game_model] = _match_data

    local _game_data = _match_data[_game_info.game_id] or 
    {
        players = {},
    }

    -- 每次都更新 game info
    _game_data.game_info = _game_info

    _match_data[_game_info.game_id] = _game_data
    
    return _game_data
end

-- 得到 玩家是 第 n 天登录的
function PUBLIC.get_login_day_index(_player_id)
   
    local _ltime = D.first_login_time[_player_id]
    if not _ltime then
        _ltime = skynet.call(DATA.service_config.data_service,"lua","get_first_login_time",_player_id)
        D.first_login_time[_player_id] = _ltime
    end

	local _now = tonumber(skynet.getcfg("xinshou_mock_time")) or os.time()
    return basefunc.day_diff(_ltime,_now) + 1
end

-- 得到 连输 的累积 阈值，达到 即触发 发好牌
function PUBLIC.get_random_lose_count(data,_cfg,_kind)

    local _rd = math.random(_cfg.lost_count[1],_cfg.lost_count[2] or _cfg.lost_count[1])
    
    if _kind == "fjs" then
        if data.game_info.profit_status == "up" then
            return math.ceil(_rd * data.config.fj_lost_count_up_scale)
        elseif data.game_info.profit_status == "down" then
            return math.max(1,math.floor(_rd * data.config.fj_lost_count_down_scale))
        else
            return _rd
        end
    else
    
        return _rd
    end
end

-- 更新用户 数据
function PUBLIC.update_protect_player_data(data,_player_id,_win)

    print("protect update_protect_player_data:",_player_id,_win)

    local _player_data = data.game_data.players[_player_id]

    local haopai_cfg,_kind,timeout = PUBLIC.get_hao_pai_config(data,_player_id)

    if _player_data then

        local _timeout = os.time() - (_player_data.last_time or 0) > timeout

        -- 超时 或 赢，则清除 
        if _win >= 0 or _timeout then
            if PROTECT_DEBUG then
                _player_data.lost_count = 1
            else
                _player_data.lost_count = 0
            end

            _player_data.max_lost_count = PUBLIC.get_random_lose_count(data,haopai_cfg,_kind)

            print("update_protect_player_data update max_lost_count:",data.game_info.profit_status,_player_id,_player_data.max_lost_count)
        end

        -- 超时，清除 触发次数
        if _timeout then
            _player_data.haopai_count = 0
        end
    else

        _player_data = {

            lost_count = PROTECT_DEBUG and 1 or 0,

            max_lost_count = PUBLIC.get_random_lose_count(data,haopai_cfg,_kind),

            haopai_count = 0,

            game_count = 0,
        }

        print("update_protect_player_data init max_lost_count:",data.game_info.profit_status,_player_id,_player_data.max_lost_count)

        data.game_data.players[_player_id] = _player_data
    end
    
    if _win < 0 then
        _player_data.lost_count = _player_data.lost_count + 1
        _player_data.last_time = os.time()
    end

    _player_data.game_count = _player_data.game_count + 1
    
end

function PUBLIC.get_fang_jusang_haopai(data)
    local _md = data.config.fang_jusang[data.game_info.game_model]
    if _md then
        return _md[data.game_info.game_id] or _md.default
    else
        return data.config.fang_jusang.default
    end
end

function PUBLIC.get_xin_shou_haopai(data,_player_id)
    local _day_index = PUBLIC.get_login_day_index(_player_id)
    local _day_cfg = data.config.xinshou_day_protected[_day_index]

    return _day_cfg and _day_cfg[data.game_info.game_id]

end

-- 得到好牌配置： 新手好牌，或防沮丧配置
-- 返回 配置 + 类型(fjs,xs) + timeout;
function PUBLIC.get_hao_pai_config(data,_player_id)

    local _xin = PUBLIC.get_xin_shou_haopai(data,_player_id)
    if _xin then
        return _xin,"xs",data.config.xinshou_proect_timeout
    else
        return PUBLIC.get_fang_jusang_haopai(data),"fjs",data.config.fang_jusang_proect_timeout
    end
end

-- 得到新手的 before 数据
function PUBLIC.get_xinshou_before_config(data,_player_id)

    local _gd = data.game_data.players[_player_id]

    local _game_count = (_gd and _gd.game_count or 0) + 1

    local _day_index = PUBLIC.get_login_day_index(_player_id)

    local _cfg = data.config.xinshou_before[data.game_info.game_id]

    if _cfg and _day_index <= _cfg.day and _game_count <= _cfg.count then
        return _cfg
    else
        return nil
    end
end

--[[ 得到保护数据
 类型
 返回 权重 + 好牌分数 + 类型,
        权重: 用于 同桌 人中 选好牌比较， 新手优先（ 额外加 1000）； nil 表示 不处理
        好牌分数: 配置中的 power ，1 ~5 ，牌的好坏程度
         类型 : fjs/xs/before
            fjs 防沮丧
            xs 新手
            before 前 n 天，前 n 把 保护
    }

    返回 nil 表示不保护
--]]
function PUBLIC.get_haopai_weight(data,_player_id)

    -- 优先处理 before 信息
    local _before_cfg = PUBLIC.get_xinshou_before_config(data,_player_id)
    if _before_cfg then

        print("get_haopai_weight use _before_cfg:",_player_id)

        return  2000,                   -- 权重值 最高
                _before_cfg.power,
                "before"
    end

    local _gd = data.game_data.players[_player_id]

    if not _gd then
        return nil
    end

    -- 连输次数还没到
    if _gd.lost_count < _gd.max_lost_count then
        return nil
    end

    local haopai_cfg,_kind = PUBLIC.get_hao_pai_config(data,_player_id)

    if not haopai_cfg then
        return nil
    end

    if _gd.haopai_count >= haopai_cfg.haopai_count then
        return nil
    end

    print("get_haopai_weight:",_player_id,_kind,_gd.max_lost_count,_gd.lost_count,haopai_cfg.haopai_count,_gd.haopai_count)

    return (_gd.lost_count - _gd.max_lost_count) + (_kind=="xs" and 1000 or 0),
            haopai_cfg.power,
            _kind
end

--[[ 选出 好牌 玩家
    返回：好牌分数 + 好牌座位 + 差牌座位
--]]
function PUBLIC.get_haopai_data(data,_p_seat_number)

    local _max_weight = 0
    local _pro_player_id    -- 保护的 玩家 id
    local _pro_seat_num
    local _pro_power
    local _pro_kind

    local _laji_seat -- 垃圾牌座位号

    for _seat,_pid in pairs(_p_seat_number) do
    
    
        if basefunc.is_real_player(_pid) then

            if PROTECT_DEBUG then
                PUBLIC.update_protect_player_data(data,_pid,-3000)
            end
    
            local _w,_power,_kind = PUBLIC.get_haopai_weight(data,_pid)
            if _w and (not _max_weight or _w > _max_weight) then

                if _pro_seat_num and not _laji_seat then -- 把权重 比当前低的 座位（如果有）设为垃圾牌座位
                    _laji_seat = _pro_seat_num
                end

                _max_weight = _w
                _pro_player_id = _pid
                _pro_seat_num = _seat
                _pro_power = _power
                _pro_kind = _kind
            end

        else
            _laji_seat = _seat
        end
    end

    

    if _pro_player_id then

        if not _laji_seat then
            _laji_seat = ((_pro_seat_num % GAME_TYPE_SEAT[data.game_data.game_info.game_type]) + 1)
        end

        local _pd = data.game_data.players[_pro_player_id]
        if _pd then
            _pd.haopai_count = _pd.haopai_count + 1
            _pd.lost_count = 0

            local haopai_cfg,_kind = PUBLIC.get_hao_pai_config(data,_pro_player_id)
            _pd.max_lost_count = PUBLIC.get_random_lose_count(data,haopai_cfg,_kind)
            print("player haopai trigger, data reset:",_pro_player_id,
                                                    data.game_info.game_model,
                                                    data.game_info.game_id,
                                                    _kind,
                                                    _pd.max_lost_count,
                                                    _pd.haopai_count)
        else
            -- 玩家第一把，还没有数据
            print("player haopai trigger, xin shou before:",_pro_player_id)
        end

        return _pro_power,_pro_seat_num,_laji_seat

    else
        return nil
    end
end

--[[ 查询保护数据
    _game_info : 
        {
            game_model=,  比赛名字  matchstyle/freestyle/...
            game_id=,   1,2,3 ...
            game_type=  游戏类型 nor_mj_xzdd/nor_ddz_nor/nor_ddz_er
            gain_power,  水控系统的抽水力度： 0 ~ 100 ，越大  系统抽水力度越强
            profit_status , 水控系统状态： "up" 抽水, "down" 放水
        }

    _p_seat_number : seat_num => player_id
    返回：
        {
            seat_num = ,
            haopai = ,
        }
--]]
function PUBLIC.query_protect_haopai_param(_game_info,_p_seat_number)

    -- 暂时只支持 匹配场
    if _game_info.game_model ~= "freestyle" then
        return nil
    end

    local data = 
    {
        game_info = _game_info,

        config = nodefunc.get_global_config("player_protect_config"),
        game_data = PUBLIC.get_and_refresh_game_data(_game_info),
    }

    local power,nice_pai_seat_num,laji_pai_seat_num = PUBLIC.get_haopai_data(data,_p_seat_number)
    if power then
        return
        {
            power = power,
            nice_pai_seat_num = nice_pai_seat_num,
            laji_pai_seat_num = laji_pai_seat_num,
        }
    else
        return nil
    end


------------------------------------------
-- 测试代码    

    -- local nice_pai_seat_num,laji_pai_seat_num
    
    -- for _seat,_pid in pairs(_p_seat_number) do
    
    
    --     if basefunc.is_real_player(_pid) then
    --         nice_pai_seat_num = _seat
    --     else
    --         laji_pai_seat_num = _seat
    --     end
    -- end

    -- return 
    -- {
    --     power = 5,
    --     nice_pai_seat_num = nice_pai_seat_num,
    --     laji_pai_seat_num = laji_pai_seat_num,
    -- }
    
end

function CMD.query_protect_haopai_param(_game_info,_p_seat_number)

    local ok,ret = xpcall(PUBLIC.query_protect_haopai_param,basefunc.error_handle,_game_info,_p_seat_number)
    if ok then
        print("call query_protect_haopai_param result:",ret)
        return ret
    else
        return nil
    end
end

function PUBLIC.udpate_protect_data(_game_info,_player_win)
    
    -- 暂时只支持 匹配场
    if _game_info.game_model ~= "freestyle" then
        return
    end

    local data = 
    {
        game_info = _game_info,

        config = nodefunc.get_global_config("player_protect_config"),
        game_data = PUBLIC.get_and_refresh_game_data(_game_info),
    }

    for _pid,_win in pairs(_player_win) do

        if basefunc.is_real_player(_pid) then
            PUBLIC.update_protect_player_data(data,_pid,_win)
        end

    end
end

-- 更新保护数据
-- _player_win ： player_id => 赢的数量
function CMD.udpate_protect_data(_game_info,_player_win)
    local ok,msg = xpcall(PUBLIC.udpate_protect_data,basefunc.error_handle,_game_info,_player_win)
    if not ok then
        print("call udpate_protect_data error:",msg)
    end
end