--
-- Created by lyx.
-- User: hare
-- Date: 2018/7/5
-- Time: 16:21
-- web 后台管理函数
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local cjson = require "cjson"
require"printfunc"


local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

--- 把sql插入队列中
local function db_exec(_sql , _queue_name)
    skynet.send(DATA.service_config.data_service,"lua","db_exec",_sql , _queue_name)
end

--[[ 发送邮件
参数：
    _data_json 数据，json 格式：
    {
        players = {1234,5134,51233,3123} -- 接收邮件的玩家，  id 数组
        mail = -- 邮件数据
        {
            title=,     -- 标题
            context=,   -- 内容
            reason=,   -- 原因
            op_user=, -- 操作人
            props={},   -- 赠送的道具 ， key-value
        }
    }
--]]
function CMD.send_mail(_data_json)

    local data = cjson.decode(_data_json)

    if "ALL_USER" ~= data.players then
        if not data.players or not next(data.players) then
            print("send_mail data.players 1 error:",type(data.players),data.players and #data.players)
            return 1001
        end    
    end

    if not data.mail or not next(data.mail) or not data.mail.title or 
            not data.mail.context or not data.mail.reason or not data.mail.op_user then

        dump(data,"send_mail data.xxxxx 2 error:")
        return 1001
    end

    local _props = {string.format("content='%s'",string.gsub(data.mail.context,"\"","\\\""))}
    for _name,_value in pairs(data.mail.props) do
        _props[#_props + 1] = string.format("%s=%s",_name,_value)
    end

    -- 构造参数
    local arg = 
    {
        players = data.players,
        email=
        {
            type="native",
            title=data.mail.title,
            sender="system",
            valid_time=os.time() + 3600 * 24, -- x 小时后过期（过期自动领取）
            data = "{" .. table.concat(_props,",") .. "}",
        }
    }

    -- 调用邮件服务
    return skynet.call(DATA.service_config.email_service,"lua",
                                            "external_send_email",
                                            arg,
                                            data.mail.op_user,
                                            data.mail.reason)
    
end


function CMD.block_player(_data_json)
    local data = cjson.decode(_data_json)
    if not data then
        print("web manage block_player 1001.1 error:",_data_json)
        return 1001
    end

    return skynet.call(DATA.service_config.data_service,"lua","block_player",data.player_id,data.reason,data.op_user)
end

function CMD.unblock_player(_data_json)
    local data = cjson.decode(_data_json)
    if not data then
        print("web manage unblock_player 1001.1 error:",_data_json)
        return 1001
    end
    
    return skynet.call(DATA.service_config.data_service,"lua","unblock_player",data.player_id,data.reason,data.op_user)
end

function CMD.broadcast(_data_json)
    local data = cjson.decode(_data_json)
    if not data then
        print("web manage broadcast 1001.1 error:",_data_json)
        return 1001
    end

    skynet.send(DATA.service_config.broadcast_center_service,"lua","broadcast",data.channel,data.data)
    
    return 0
end