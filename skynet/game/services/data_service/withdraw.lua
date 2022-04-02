--
-- Created by lyx
-- User: hare
-- Date: 2018/6/2
-- Time: 20:06
-- 说明：提现
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require"printfunc"

local monitor_lib = require "monitor_lib"

require "normal_enum"


local PROTECTED = {}

--[[
-- 提现数据 ： withdraw_id -> 数据库 player_withdraw 表数据
-- 数据结构说明：
	withdraw_id =
--]]
PROTECTED.withdraw_datas = {}
local withdraw_datas = PROTECTED.withdraw_datas


-- 初始化提现单信息 ###_temp ： 以后需要优化，增加历史表，这里仅载入 当前数据
function PROTECTED.init_withdraw_info()

	local sql = "select * from player_withdraw"
	local ret = base.DATA.db_mysql:query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return false
	end

	for i = 1,#ret do
        withdraw_datas[ret[i].withdraw_id] = ret[i]
	end


	return true
end

-- 创建新的单号
local function create_withdraw_id()

	local sysvar = base.DATA.system_variant

    local todayStr = os.date("%Y%m%d")
    if sysvar.last_withdraw_date == todayStr then
        sysvar.last_withdraw_today_index = sysvar.last_withdraw_today_index + 1
    else
        sysvar.last_withdraw_date = todayStr
        sysvar.last_withdraw_today_index = 1
    end

    return string.format("%s%07u%s",todayStr,sysvar.last_withdraw_today_index,skynet.random_str(5))
end

-- 创建提现单号
-- 返回值：
--		1、withdraw_id，出错则为 nil
--		2、如果出错，则为错误号
function base.CMD.create_withdraw_id(_userId,_channel_type,_src_type,_asset_type,_channel_receiver_id,_money,_comment)

	if not _userId then
		return nil,1001
	end

	local user = base.PUBLIC.load_player_info(_userId)
	if not user then
		return nil,2251
	end

	_money = tonumber(_money)
	if not _money or _money <= 0 then
		return nil,1003
	end

	if _asset_type then
		if _money > base.CMD.query_asset(_userId,_asset_type) then
			return nil,2261
		end
	else
		-- 只有 兑换红包无需扣除财富
		if "duihuan_hb" ~= _src_type then 
			return 1062
		end
	end

	if not _channel_receiver_id then
		local err
		_channel_receiver_id,err = base.PUBLIC.get_open_id(_userId)
		if not _channel_receiver_id then
			return nil,err
		end
	end

	local id = create_withdraw_id()


	local cur_time = os.time()

	local withdraw_data = {
		withdraw_id=id,
		player_id=_userId,
		withdraw_status="init",
		src_type = _src_type,
		money=_money,
		asset_type = _asset_type,
		channel_type=_channel_type,
		channel_withdraw_id=nil,
		channel_receiver_id=_channel_receiver_id,
		comment = _comment,

		-- 时间暂时采用 sql 表达式，用完后 复原
		create_time={__sql_expr=string.format("FROM_UNIXTIME(%u)",cur_time)},
	}

	-- 插入数据库
	base.DATA.sql_queue_fast:push_back(base.PUBLIC.gen_insert_sql("player_withdraw",withdraw_data))

	withdraw_data.create_time = cur_time

	withdraw_datas[id] = withdraw_data

	return id
end

local withdraw_status={
	error=true,
	call=true, -- （暂未启用）调用 提现 sdk 
	create=true, -- （暂未启用）
	fail=true,
	complete=true,
}

-- 修改提现单状态
-- 返回值：
--		1、true/false，成功/失败
--		2、如果失败，则为错误号
function base.CMD.change_withdraw_status(_withdraw_id,_withdraw_status,_channel_withdraw_id,_error_desc)
	local withdraw = withdraw_datas[_withdraw_id]
	if not withdraw then
		return false,2262
	end

	if not withdraw_status[_withdraw_status] then
		return false,2233
	end

	if "complete" == withdraw.withdraw_status then
		return false,2263
	end
	if "fail" == withdraw.withdraw_status then
		return false,2263
	end

	local cur_time

	local _fields = {
		withdraw_status = _withdraw_status,
		channel_withdraw_id = _channel_withdraw_id,
		error_desc = _error_desc,
	}

	-- 说明： 状态 complete  和 fail 不能 重复处理

	if "complete" == _withdraw_status then
		cur_time = os.time()
		_fields.complete_time = {__sql_expr=string.format("FROM_UNIXTIME(%u)",cur_time)}

		monitor_lib.add_data("withdraw",withdraw.money)

		--- 提现成功消息
		--base.DATA.events.on_withdraw_success:trigger(withdraw.player_id,withdraw.money , withdraw.src_type,withdraw.asset_type )

		--- 向通知中心触发消息
		skynet.send( DATA.service_config.msg_notification_center_service , "lua" , "trigger_msg" 
																				, {name = "on_withdraw_success" } 
																				, withdraw.player_id,withdraw.money , withdraw.src_type,withdraw.asset_type )

	elseif "fail" == _withdraw_status then
		
		-- 退钱
		if withdraw.asset_type then
			base.CMD.change_asset(withdraw.player_id,withdraw.asset_type,withdraw.money,"withdraw refund",_withdraw_id)
		end
	end

	-- 写入到数据库
	local _set_sql = base.PUBLIC.gen_update_fields_sql(_fields)
	if _set_sql ~= "" then
		base.DATA.sql_queue_fast:push_back(string.format("update player_withdraw set %s where withdraw_id='%s'",
			_set_sql,_withdraw_id
		))
	end

	if cur_time then
		_fields.complete_time = cur_time
	end

	basefunc.merge(_fields,withdraw)

	return true,{player_id=withdraw.player_id,money=withdraw.money}
end

-- 查询提现单据
-- 返回：
--	1、单据数据
--	2、错误号，如果出错，返回错误号
function base.CMD.query_withdraw_data(_withdraw_id)

	local withdraw = withdraw_datas[_withdraw_id]
	if withdraw then
		return withdraw
	else
		return false,2262
	end
end

return PROTECTED
