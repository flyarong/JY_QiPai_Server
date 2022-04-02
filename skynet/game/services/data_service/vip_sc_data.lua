--
-- Author: lyx
-- Date: 2018/5/30
-- Time: 11:09
-- 说明：vip 数据访问
-- 注意：这里不做缓存，由 vip_sc 服务自行缓存
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local cjson = require "cjson"
require"printfunc"

require "normal_enum"

local monitor_lib = require "monitor_lib"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECTED = {}

-- 得到 vip 数据
function CMD.load_vip_sc_data(_player_id)

    local sql = string.format("select * from vip_sc_data where player_id='%s';",_player_id)
    local ret = base.DATA.db_mysql:query(sql)
    if( ret.errno ) then
		error(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
	end

    if not ret[1] then
        return nil
    end

    local _data = {}

    _data.player_id = _player_id
    _data.remain_vip_count = assert(ret[1].remain_vip_count)
    _data.vipfanjiang_debt = ret[1].vipfanjiang_debt)
    _data.presented_debt = ret[1].presented_debt)
    _data.status = assert(ret[1].status)
    _data.cur_vip_start_time = assert(ret[1].cur_vip_start_time)
    _data.cur_debt = assert(ret[1].cur_debt)
    _data.cur_remain_debt = assert(ret[1].cur_remain_debt)
    _data.cur_qhtg_cost = assert(ret[1].cur_qhtg_cost)


    sql = string.format("select * from vip_sc_days where player_id='%s' order by day_index;",_player_id)
    ret = base.DATA.db_mysql:query(sql)
    if( ret.errno ) then
		error(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
	end

    if "run" then
        local _days = {}
        for _,_day in ipairs(ret) do
    		_days[_day.day_index] = _day
    	end

        _data.cur_days = _days
    end

    return _data
end


-- 更新 vip 数据 （###_temp 暂未 保存购买记录）
function CMD.update_vip_sc_data(_player_id,_buy_id,_remain_vip_count,_vipfanjiang_debt,_presented_debt)

    local sql = string.format([[
        SET @_remain_vip_count = %d;
        SET @_vipfanjiang_debt = %d;
        SET @_presented_debt = %d;
        insert into vip_sc_data(player_id,
            remain_vip_count,
            vipfanjiang_debt,
            presented_debt)
        values('%s',
            @_remain_vip_count,
            @_vipfanjiang_debt,
            @_presented_debt)
        on duplicate key update
            remain_vip_count= @_remain_vip_count,
            vipfanjiang_debt=@_vipfanjiang_debt,
            presented_debt=@_presented_debt,
        ]],

        _remain_vip_count,
        _vipfanjiang_debt,
        _presented_debt,
        _player_id
    )

    DATA.sql_queue_fast:push_back(sql)
end

-- 更新当前状态数据
function CMD.update_cur_status (_player_id,_data)

    local sql = string.format([[
        update vip_sc_data set
            remain_vip_count= %d,
            vipfanjiang_debt=%d,
            presented_debt=%d,
            status=%d,
            cur_day_index= %d,
            cur_vip_start_time= FROM_UNIXTIME(%u),
            cur_debt= %d,
            cur_remain_debt= %d,
            cur_qhtg_cost= %d
            where player_id = '%s';
        ]],

        _data.remain_vip_count,
        _data.vipfanjiang_debt,
        _data.presented_debt,
        _data.status,
        _data.cur_day_index,
        _data.cur_vip_start_time,
        _data.cur_debt,
        _data.cur_remain_debt,
        _data.cur_qhtg_cost,
        _player_id
    )

    DATA.sql_queue_fast:push_back(sql)
end

local _days_fields =
{
    today_debt=true,
    done_debt=true,

    game_count=true,

    qhtg_vd =true,
    --cur_game_is_qhtg=true,

    today_lucky=true,
    done_luck=true,
}

-- 更新当前周期，某1天的 vip 数据
-- 说明：  nil 的项表示不更新
function CMD.update_vip_sc_day(_player_id,_day_index,_day_data)

    local _values = basefunc.copy(_day_data,_days_fields)
    _values.player_id = _player_id
    _values.day_index = _day_index

    local sql = string.format("delete from vip_sc_days where player_id='%s' and day_index=%d;%s",
        _player_id,_day_index,PUBLIC.gen_insert_sql(vip_sc_days,_values)
    )

    DATA.sql_queue_fast:push_back(sql)
end

return PROTECTED
