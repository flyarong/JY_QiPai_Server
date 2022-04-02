--
-- Author: lyx
-- Date: 2018/3/26
-- Time: 8:58
-- 说明：生财之道 的 数据访问
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "data_func"
require "normal_enum"
require "printfunc"

local monitor_lib = require "monitor_lib"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECTED = {}

function PROTECTED.init()
    
end

function CMD.sczd_period_settle(_settle_data)
    for _player_id ,_data in pairs(_settle_data) do
        if _data.income and _data.income>0 then
            CMD.change_asset(_player_id,"prop_jicha_cash",_data.my_income,"period_settle")
        end
        DATA.sql_queue_slow:push_back(string.format([[insert into sczd_gjhhr_settle_log(id,achievements,tuikuan,income,my_income,percentage)
         values('%s',%s,%s,%s,%s,%s)]],_player_id,tostring(_data.all_achievements),tostring(_data.tuikuan),tostring(_data.income),tostring(_data.my_income),tostring(_data.percentage)))
    end
    -- dump(_settle_data)
    CMD.sczd_clear_cur_period_achievements()
end

function CMD.sczd_clear_cur_period_achievements()
    DATA.sql_queue_slow:push_back("call sczd_gjhhr_month_settle();")
end

function CMD.sczd_add_player_achievements(_datas)

    for _player_id,_d in pairs(_datas) do

        DATA.sql_queue_slow:push_back(string.format("update sczd_player_all_achievements set all_achievements=%s where id='%s';",
            tostring(_d),_player_id))

    end
    
end

function CMD.sczd_add_gjhhr_refund(_datas)

    for _player_id,_tuikuan in pairs(_datas) do

        DATA.sql_queue_slow:push_back(string.format("update sczd_player_all_achievements set tuikuan=%s where id='%s';",
            tostring(_tuikuan),_player_id))
        
    end
    
end

function CMD.sczd_load_player_achievements(_player_id)
    local ret = PUBLIC.db_query_va("select * from sczd_player_all_achievements where id = '%s' ",_player_id)

    local data

    if ret[1] then
        data = ret[1]
    else
        
        DATA.sql_queue_slow:push_back(string.format([[insert into sczd_player_all_achievements(id,all_achievements,yesterday_all_achievements,tuikuan,yesterday_tuikuan) 
                values('%s',0,0,0,0) on duplicate key update yesterday_tuikuan=yesterday_tuikuan; ]],_player_id))

        data = {
            id=_player_id,
            all_achievements=0,
            yesterday_all_achievements=0,
            tuikuan=0,
            yesterday_tuikuan=0,
        }
    end

    return data
end


function CMD.sczd_load_sczd_gjhhr_info()
    local ret = PUBLIC.db_query("select * from sczd_gjhhr_info")
    if not ret then
        return nil
    end

    local data={}
    for _,_d in ipairs(ret) do
        _d.name=CMD.get_player_info(_d.id,"player_info","name")
        data[_d.id] = _d
    end
   
    return data
end 

function CMD.op_change_gjhhr_status(op_player, player_id, status)
    DATA.sql_queue_slow:push_back(string.format("update sczd_gjhhr_info set status='%s' where id='%s';",status,player_id))

    -- 不是 nil 才表示 是 人在操作
    if op_player then 
        DATA.sql_queue_slow:push_back(string.format("insert into admin_op_log(admin_id,op_type,player_id1,op_data1) values('%s','change_gjhhr_status','%s','%s')",op_player,player_id,status))
    end
end

--[[

--]]
function CMD.op_new_gjhhr(op_player,become_time,status,player_id)
    DATA.sql_queue_slow:push_back(string.format("insert sczd_gjhhr_info(id,status,become_time) values('%s','%s',FROM_UNIXTIME(%u));", player_id,
                                                                                                                                        status,
                                                                                                                                        become_time
                                                                                                                                        ))
    
    CMD.record_sczd_gjhhr_info_change_log(op_player,become_time,status,player_id)

    if op_player then
        DATA.sql_queue_slow:push_back(string.format("insert into admin_op_log(admin_id,op_type,player_id1,op_data1) values('%s','new_gjhhr','%s','nor')",op_player,player_id))    
    end
end
function CMD.record_sczd_gjhhr_info_change_log(op_player,become_time,status,player_id)
    DATA.sql_queue_slow:push_back(string.format("insert sczd_gjhhr_info_change_log(id,status,become_time,op_player,change_time) values('%s','%s',FROM_UNIXTIME(%u),%s,now());", player_id,
                                                                                                                                                 status,
                                                                                                                                                 become_time,
                                                                                                                                                 PUBLIC.value_to_sql(op_player)
                                                                                                                                                        ))
end

function CMD.op_delete_gjhhr(op_player,player_id)
    DATA.sql_queue_slow:push_back(string.format("delete from sczd_gjhhr_info where id = '%s';",player_id))

    if op_player then
        DATA.sql_queue_slow:push_back(string.format("insert into admin_op_log(admin_id,op_type,player_id1) values('%s','delete_gjhhr','%s')",op_player,player_id))    
    end
end

-- 记录操作日志 base.PUBLIC.value_to_sql(v)
-- 参数 player_id1,player_id2,data1,data2,data3 可选 
function CMD.record_op_log(op_player,op_type,player_id1,player_id2,data1,data2,data3)

    if op_player then
        DATA.sql_queue_slow:push_back(string.format(
            [[insert into admin_op_log(admin_id,op_type,player_id1,player_id2,op_data1,op_data2,op_data3) 
            values('%s','%s',%s,%s,%s,%s,%s)]],op_player,op_type,
            PUBLIC.value_to_sql(player_id1),
            PUBLIC.value_to_sql(player_id2),
            PUBLIC.value_to_sql(data1),
            PUBLIC.value_to_sql(data2),
            PUBLIC.value_to_sql(data3)
        ))        
    end
end

return PROTECTED





