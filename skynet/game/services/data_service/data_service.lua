--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:13
-- 说明：数据服务
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local mysql = require "skynet.db.mysql"
local base = require "base"
require "data_func"

local monitor_lib = require "monitor_lib"
local basefunc = require "basefunc"
local player_info = require "data_service.player_info"
local personal_info_data = require "data_service.personal_info_data"
local ddz_million_data = require "data_service.ddz_million_data"
local normal_mjxl_freestyle_data = require "data_service.normal_mjxl_freestyle_data"
local tyddz_freestyle_data = require "data_service.tyddz_freestyle_data"
local common_mj_xzdd_data = require "data_service.common_mj_xzdd_data"
local nor_ddz_nor_data = require "data_service.nor_ddz_nor_data"
local email_data = require "data_service.email_data"
local payment_info = require "data_service.payment_info"
local withdraw = require "data_service.withdraw"
local player_consume_data = require "data_service.player_consume_data"
local friendgame_data = require "data_service.friendgame_data"

local player_block_data = require "data_service.player_block_data"

local shop_info = require "data_service.shop_info"
local hermos_api = require "data_service.hermos_api"

local admin_info = require "data_service.admin_info"

local match_nor_data = require "data_service.match_nor_data"

local player_win_data = require "data_service.player_win_data"

local zy_city_match_data = require "data_service.zy_city_match_data"

local freestyle_data = require "data_service.freestyle_data"

local naming_data = require "data_service.naming_data"

local player_task_data = require "data_service.player_task_data"

local player_glory_data = require "data_service.player_glory_data"

local player_dress_data = require "data_service.player_dress_data"

local player_duiju_hongbao_award = require "data_service.player_duiju_hongbao_award_data"

local player_vip_data = require "data_service.player_vip_data"

local player_vip_buy_record_data = require "data_service.player_vip_buy_record_data"

local player_vip_generalize_data = require "data_service.player_vip_generalize_data"

local player_vip_generalize_extract_record_data = require "data_service.player_vip_generalize_extract_record_data"

local player_vip_reward_task_data = require "data_service.player_vip_reward_task_data"

local player_vip_reward_task_record_data = require "data_service.player_vip_reward_task_record_data"

local player_vip_generalize_data = require "data_service.player_vip_generalize_data"

local player_lottery_data = require "data_service.player_lottery_data"

local redeem_code_data = require "data_service.redeem_code_data"

local game_profit_data = require "data_service.game_profit_data"

local player_stepstep_money = require "data_service.player_stepstep_money_data"

local player_zjd_data = require "data_service.player_zajindan_data"

local player_goldpig_data = require "data_service.player_goldpig_data"

local player_asset_service_data = require "data_service.player_asset_service_data"

local freestyle_activity_data = require "data_service.freestyle_activity_data"

local nor_gobang_nor_data = require "data_service.nor_gobang_nor_data"

local player_object_data = require "data_service.player_object_data"

local fish_game_data = require "data_service.fish_game_data"

local player_zhouka_data = require "data_service.player_zhouka_data"

local sczd_vip_lb_data = require "data_service.sczd_vip_lb_data"

local player_da_fu_hao_data = require "data_service.player_da_fu_hao_data"

require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

-- 服务配置
DATA.service_config = nil

-- 数据库队列
DATA.sql_queues = 
{
	fast = 
	{
		db_mysql = nil,
		sql_queue = basefunc.queue.new(),
	},
	slow = 
	{
		db_mysql = nil,
		sql_queue = basefunc.queue.new(),
	},
}

DATA.sql_queue_fast = DATA.sql_queues.fast.sql_queue
DATA.sql_queue_slow = DATA.sql_queues.slow.sql_queue

-- 查询用的 mysql 的连接
DATA.db_mysql = nil

DATA.error_write_queue = {}

--定点时刻调用回调函数集合
local fixed_point_callbacks={}

-- sql 语句报错的记录文件
local sql_error_file_handle


-- update 信号
DATA.update_signal = basefunc.signal.new()

-- 数据库中存放的 单一值（表 system_variant ）
-- 由 init_system_variant 函数管理
base.DATA.system_variant = {
	last_match_ddz_game_id = 0,      	-- 表 match_ddz_game 的上一次 id 值
	last_match_ddz_race_log_id = 0,  	-- 表 match_ddz_race_log 的上一次 id 值
	last_pay_order_today_index = 0,  	-- 最近一次的订单当日序号
	last_pay_order_date = "20180101",	-- 最近一次订单的日期
	last_withdraw_today_index = 0,  	-- 最近一次的提现 当日序号
	last_withdraw_date = "20180101",-- 最近一次提现的日期
	last_user_index = 5387,			-- 最近一次用户序号
	last_player_info_seq = 0,		-- 最近一次玩家信息同步序号（和 web 后台同步）
	last_asset_log_seq = 0,			-- 最近一次购物金消费信息同步序号（和 web 后台同步）
	current_instance_id = 0,	-- 服务器 实例 id，每次启动增长一次， 用于客户端判断是否需要重新登录
	last_vip_record_id = 0,	-- 最近一次 vip 购买记录 id
	last_zajindan_round = 0,          --- 最近一次的砸金蛋的轮数
	freestyle_activity_log_id = 200,    --- 最近一次自由场活动的日志id,初始值
}

function PUBLIC.open_sql_error_file()

	if sql_error_file_handle then

		return sql_error_file_handle ~= "open error"

	else
		local err
		sql_error_file_handle,err = io.open("./logs/sql_error.txt","a")
		if not sql_error_file_handle then
			sql_error_file_handle = "open error"
			print(string.format("open './logs/sql_error.txt' error:%s!", tostring(err)))
			return false
		end

		return true
	end
end

function PUBLIC.flush_sql_error()

	if sql_error_file_handle and sql_error_file_handle ~= "open error" then

		sql_error_file_handle:close()

		sql_error_file_handle = nil
	end
end

local _flush_counter = 0
local _error_data_dirty = false

-- 记录 sql 执行错误（如果有的话）
function PUBLIC.write_sql_error_file()

	_flush_counter = _flush_counter + 1
	if _error_data_dirty and _flush_counter % 10 == 0 then
		PUBLIC.flush_sql_error()
		_error_data_dirty = false
	end

	if next(DATA.error_write_queue) and PUBLIC.open_sql_error_file() then

		local _tmp = DATA.error_write_queue
		DATA.error_write_queue = {}

		sql_error_file_handle:write(table.concat(_tmp,"\n"))
		_error_data_dirty = true
	end

end

-- 刷新连接
local function refresh_db_connections()

	DATA.db_mysql:query("select 5;")
	DATA.sql_queues.fast.db_mysql:query("select 5;")
	DATA.sql_queues.slow.db_mysql:query("select 5;")
end

local _sql_succ_count = 0
local _sql_error_count = 0
local _sql_empty_count = 0

local _sql_statement_counter = "set @sql_statement_index=@sql_statement_index+1;"
local _sql_statement_counter_pat = "set @sql_statement_index=@sql_statement_index%+1;"

-- 从队列中取出语句，拼成一个 语句的数组
function PUBLIC.take_sql_array(_queue,_count)
	local sqls = {}
	for i=1,_count do			-- 每次最多合并的行数
		local sql = _queue:pop_front()
		if sql then
			sqls[#sqls + 1] = PUBLIC.safe_sql_semicolon(sql) .. _sql_statement_counter
		else
			break
		end
	end

	return sqls
end

-- 执行语句数组
-- 参数 _start_index,_end_index ： 开始 、 结束 的语句序号
-- 成功返回 true
-- 失败返回 false,错误信息, 出错语句的序号
function PUBLIC.exec_sql_array(_db_mysql,_array,_start_index,_end_index)

	_db_mysql:query("set @sql_statement_index=0;")

	local sql = table.concat(_array,"\n",_start_index,_end_index)
	local _t1 = os.clock()
	local ret = _db_mysql:query(sql)
	if( ret.errno ) then
		local cur_index = _db_mysql:query("select @sql_statement_index ssidx;")
		return false,ret,cur_index[1].ssidx + (_start_index or 1)
	else
		if skynet.getcfg("log_sql_queue") then
			print("succ sql queue:",os.clock() - _t1,sql)
		end
		return true
	end
end

function PUBLIC.record_sql_error(_ret,_sql,_queue_name)

	monitor_lib.add_data("sql_error",1)
	local _error_text = string.format(
[[
%s === %s sql error ===
error info:
%s
sql text:
%s

]],os.date("[%Y-%m-%d %H:%M:%S]"),_queue_name,basefunc.tostring( _ret ),string.gsub(tostring(_sql),_sql_statement_counter_pat,""))

	DATA.error_write_queue[#DATA.error_write_queue + 1] = _error_text
	print(_error_text)

end

function PUBLIC.exec_queue_sql_impl(_queue_name,_count)
	
	local _q_data = DATA.sql_queues[_queue_name]
	
	if not _q_data.db_mysql then
		error(tostring(_queue_name) .. " queue error:not connect!")
	end
	
	while not _q_data.sql_queue:empty() and _count > 0 do

		-- 取出 sql 数组： 每次 取 100
		local _array = PUBLIC.take_sql_array(_q_data.sql_queue,math.min(100,_count))
		if #_array == 0 then
			_sql_empty_count = _sql_empty_count + 1
			break
		end

		_count = _count - #_array

		-- 执行 sql 数组
		local _start_index = 1 -- 从 _array 中开始执行的 语句序号
		while #_array >= _start_index do
			local ok,ret,fail_index = PUBLIC.exec_sql_array(_q_data.db_mysql,_array,_start_index)
			if ok then
				_sql_succ_count = _sql_succ_count + #_array
				break
			else
				_sql_error_count = _sql_error_count + 1

				-- 记录日志
				PUBLIC.record_sql_error(ret,_array[fail_index],_queue_name)
				
				-- 跳过错误语句，继续执行
				_start_index = fail_index + 1
			end
		end
	end
end

-- 执行队列中的 sql 语句
local function exec_queue_sql_fast()
	PUBLIC.exec_queue_sql_impl("fast",5000)
end
local function exec_queue_sql_slow()
	PUBLIC.exec_queue_sql_impl("slow",3000)
end

local function get_sql_status_string()

	local str = string.format("sql status: \n\tfast queue len:%d\n\tslow queue len:%d\n\tsucc count:%d\n\terr count:%d\n\tempty count:%d",
		DATA.sql_queue_fast:size(),DATA.sql_queue_slow:size(),_sql_succ_count,_sql_error_count,_sql_empty_count)
	if DATA.sql_queue_fast:front() then
		str = str .. "\n\tfront fast sql:" .. DATA.sql_queue_fast:front()
	end

	if DATA.sql_queue_slow:front() then
		str = str .. "\n\tfront slow sql:" .. DATA.sql_queue_slow:front()
	end

	return str
end

-- 状态检查
local function check_sql_status()
	print(get_sql_status_string())
end

-- 增长服务器实例 id
function base.CMD.inc_instance_id()
	base.DATA.system_variant.current_instance_id = base.DATA.system_variant.current_instance_id + 1
	return base.DATA.system_variant.current_instance_id
end

-- 得到服务实例 id
function base.CMD.get_instance_id()
	return base.DATA.system_variant.current_instance_id
end

-- 调试接口
function base.CMD.debug_queue_sqls(_is_slow)
	local ret = {}

	local _it = _is_slow and DATA.sql_queue_slow:values() or DATA.sql_queue_fast:values()
	for _sql in _it do
		ret[#ret + 1] = _sql
	end

	return ret
end
function base.CMD.debug_exec_sql(_sql,_queue_name)

	print("debug exec sql:",_sql,_queue_name)

	if _queue_name then
		if DATA.sql_queues[_queue_name] then
			DATA.sql_queues[_queue_name].sql_queue:push_back(_sql)
			return {"add queue ok!"}
		else
			return {"queue '" .. tostring(_queue_name) .. "' invalid!"}
		end
	else
		return DATA.db_mysql:query(_sql)
	end

end
function base.CMD.debug_get_status()

	local _ret = {
		"fast queue len:" .. DATA.sql_queue_fast:size(),
		"slow queue len:" .. DATA.sql_queue_slow:size(),
		"succ count:" .. _sql_succ_count,
		"err count:" .. _sql_error_count,
		"empty count:" .. _sql_empty_count,
	}

	if DATA.sql_queue_fast:front() then
		_ret[#_ret + 1] = "front fast sql:" .. DATA.sql_queue_fast:front()
	end

	if DATA.sql_queue_slow:front() then
		_ret[#_ret + 1] = "front slow sql:" .. DATA.sql_queue_slow:size()
	end

	return _ret
end


-- 通用数据 查询
function base.CMD.db_query(_sql)
	return DATA.db_mysql:query(_sql)
end

-- 插入到队列
-- 参数 _queue_name ： 所加入的队列 "slow" / "fast"
function base.CMD.db_exec(_sql,_queue_name)
	if "fast" == _queue_name then
		DATA.sql_queue_fast:push_back(_sql)
	else
		DATA.sql_queue_slow:push_back(_sql)
	end
end

--[[添加一个定点时刻调用
	每天这个时刻都会被调用 并不保证准时，基本上是在这个时刻后的数秒后
	目前只支持 0点 4点
	一般放进来后，就不能取消
]]
function base.PUBLIC.add_fixed_point_callback(time,func)
	local funcs = fixed_point_callbacks[time]
	if funcs then
		funcs[#funcs+1]=func
	end
end


-- 初始化定点时刻调用
local function init_fixed_point_callback()
	fixed_point_callbacks[0]={}
	fixed_point_callbacks[4]={}

	local function cbk_0()
		
		for i,func in ipairs(fixed_point_callbacks[0]) do
			func()
			skynet.sleep(5)
		end

		skynet.timeout(24*3600*100,cbk_0)
	end

	local function cbk_4()
		
		for i,func in ipairs(fixed_point_callbacks[4]) do
			func()
			skynet.sleep(5)
		end

		skynet.timeout(24*3600*100,cbk_4)
	end

	local t_0=basefunc.get_diff_target_time(0)
	local t_4=basefunc.get_diff_target_time(4)

	skynet.timeout(t_0*100,cbk_0)
	skynet.timeout(t_4*100,cbk_4)

end

-- 每日例行的数据库清理
local function daily_clearup_data()

	-- 数据库清理
	DATA.sql_queue_slow:push_back("CALL daily_clearup_data();")

end

-- 每分钟例行的数据库清理
local function per_minute_clear_data()

	DATA.sql_queue_slow:push_back("call minute_clear_data();")	
end

-- 初始化系统数据
local function init_system_data()
	DATA.sql_queue_fast:push_back(
		[[
			insert into prop_type(prop_type,prop_group,`value`) values ('diamond','diamond',1) on duplicate key update prop_type='diamond',prop_group='diamond',`value`=1 ;
			insert into prop_type(prop_type,prop_group,`value`) values ('jing_bi','jing_bi',1) on duplicate key update prop_type='jing_bi',prop_group='jing_bi',`value`=1 ;

			insert into prop_type(prop_type,prop_group,`value`) values ('cash','cash',1) on duplicate key update prop_type='cash',prop_group='cash',`value`=1 ;
			insert into prop_type(prop_type,prop_group,`value`) values ('match_ticket','match_ticket',1) on duplicate key update prop_type='match_ticket',prop_group='match_ticket',`value`=1 ;
			insert into prop_type(prop_type,prop_group,`value`) values ('hammer','hammer',1) on duplicate key update prop_type='hammer',prop_group='hammer',`value`=1 ;
			insert into prop_type(prop_type,prop_group,`value`) values ('bomb','bomb',1) on duplicate key update prop_type='bomb',prop_group='bomb',`value`=1 ;

			insert into prop_type(prop_type,prop_group,`value`) values ('shop_gold_10','shop_gold',10) on duplicate key update prop_type='shop_gold_10',prop_group='shop_gold',`value`=10 ;
			insert into prop_type(prop_type,prop_group,`value`) values ('shop_gold_100','shop_gold',100) on duplicate key update prop_type='shop_gold_100',prop_group='shop_gold',`value`=100 ;
			insert into prop_type(prop_type,prop_group,`value`) values ('shop_gold_1000','shop_gold',1000) on duplicate key update prop_type='shop_gold_1000',prop_group='shop_gold',`value`=1000 ;
			insert into prop_type(prop_type,prop_group,`value`) values ('shop_gold_10000','shop_gold',10000) on duplicate key update prop_type='shop_gold_10000',prop_group='shop_gold',`value`=10000 ;

			insert into player_change_type_refund(change_type,change_type_refund) values ('freestyle_signup','freestyle_cancel_signup') on duplicate key update change_type_refund='freestyle_cancel_signup';
			insert into player_change_type_refund(change_type,change_type_refund) values ('lz_freestyle_signup','lz_freestyle_cancel_signup') on duplicate key update change_type_refund='lz_freestyle_cancel_signup';
			insert into player_change_type_refund(change_type,change_type_refund) values ('ty_freestyle_signup','ty_freestyle_cancel_signup') on duplicate key update change_type_refund='ty_freestyle_cancel_signup';
			insert into player_change_type_refund(change_type,change_type_refund) values ('million_signup','million_cancel_signup') on duplicate key update change_type_refund='million_cancel_signup';
			insert into player_change_type_refund(change_type,change_type_refund) values ('majiang_freestyle_signup','majiang_freestyle_cancel_signup') on duplicate key update change_type_refund='majiang_freestyle_cancel_signup';
			insert into player_change_type_refund(change_type,change_type_refund) values ('mjxl_majiang_freestyle_signup','mjxl_majiang_freestyle_cancel_signup') on duplicate key update change_type_refund='mjxl_majiang_freestyle_cancel_signup';
			insert into player_change_type_refund(change_type,change_type_refund) values ('match_signup','match_cancel_signup') on duplicate key update change_type_refund='match_cancel_signup';

			insert into system_variant(`name`,`value`) values ('minute_clear_count','0')  on duplicate key update `value` = `value` + 0;

		]])
end


-- 初始化函数（数据库连接成功后调用）
local function on_dbconnected()

	-- sql 快队列执行时钟
	skynet.timer(0.05,exec_queue_sql_fast)

	-- sql 慢队列执行时钟
	skynet.timer(0.15,exec_queue_sql_slow)

	-- sql 状态检查时钟（用于诊断）
	skynet.timer(30,check_sql_status)

	-- 数据 连接 刷新，防止断开
	skynet.timer(3600,refresh_db_connections)

	-- 写入 sql 错误日志
	skynet.timer(0.1,PUBLIC.write_sql_error_file)

	init_fixed_point_callback()

	-- 初始化系统数据
	init_system_data()

	-- 初始化 系统变量
	base.PUBLIC.init_system_variant()

	-- 初始化玩家信息
	player_info.init_player_info()

	-- 初始化玩家个人信息
	personal_info_data.init_personal_info_data()

	-- 初始化比赛数据
	ddz_million_data.init()

	player_object_data.init_data()
	player_zhouka_data.init_data()

	sczd_vip_lb_data.init_data()

	player_da_fu_hao_data.init_data()

	fish_game_data.init_data()

	-- 初始化麻将数据 （血流）
	normal_mjxl_freestyle_data.init_player_nmjxl_freestyle()

	tyddz_freestyle_data.init_player_tyddz_freestyle()
	common_mj_xzdd_data.init_player_comm_mj_xzddz()
	nor_ddz_nor_data.init_data()

	nor_gobang_nor_data.init_data()

	player_win_data.init_data()

	freestyle_data.init_data()

	-- 初始化邮件数据
	email_data.init_email_data()

	-- 初始化订单数据
	payment_info.init_payment_info()

	hermos_api.init_hermos_api()

	player_block_data.init_data()

	player_consume_data.init_data()

	friendgame_data.init_data()

	match_nor_data.init_data()

	naming_data.init_data()

	player_task_data.init_data()
	
	player_glory_data.init_data()

	player_dress_data.init_data()
	
	player_duiju_hongbao_award.init_data()

	player_vip_data.init_data()

	player_vip_buy_record_data.init_data()

	player_vip_generalize_data.init_data()

	player_vip_generalize_extract_record_data.init_data()

	player_vip_reward_task_data.init_data()
	
	player_vip_reward_task_record_data.init_data()

	player_vip_generalize_data.init_data()
	
	player_lottery_data.init_data()

	redeem_code_data.init_data()

	game_profit_data.init_data()
	
	player_stepstep_money.init_data()

	player_zjd_data.init_data()

	player_goldpig_data.init_data()

	player_asset_service_data.init_data()

	freestyle_activity_data.init_data()

	-- 初始化提现单数据
	withdraw.init_withdraw_info()

	admin_info.init_admin_info()

	-- 每日的数据库清理动作
	base.PUBLIC.add_fixed_point_callback(4,daily_clearup_data)

	-- 每分钟的数据库清理动作
	skynet.timer(60,per_minute_clear_data)

	-- 增长服务器 实例 id
	base.CMD.inc_instance_id()

	base.DATA.service_started = true
end

function base.PUBLIC.create_db_connect(_on_connected,...)
	local _param_count = select("#",...)
	local _param = {...}
	mysql.connect({
		host=skynet.getenv("mysql_host"),
		port=tonumber(skynet.getenv("mysql_port")),
		database=skynet.getenv("mysql_dbname"),
		user=skynet.getenv("mysql_user"),
		password=skynet.getenv("mysql_pwd"),
		max_packet_size = 1024 * 1024,
		on_connect = function(db)
			db:query( [[
				set character_set_client='utf8mb4';
				set character_set_connection='utf8mb4';
				set character_set_results='utf8mb4';
			]])

			_on_connected(db,table.unpack(_param,1,_param_count))
		end
	})
end

-- 初始化
local function init_database()

	local _conn_count = 0

	local function connected_callback(db,_queue_name)

		if _queue_name then
			DATA.sql_queues[_queue_name].db_mysql = db
		else
			DATA.db_mysql = db
		end

		_conn_count = _conn_count + 1
		if _conn_count == 3 then
			print("database connected:",skynet.getenv("mysql_host"),tonumber(skynet.getenv("mysql_port")),skynet.getenv("mysql_dbname"))
			on_dbconnected()
		end
	end

	base.PUBLIC.create_db_connect(connected_callback)
	base.PUBLIC.create_db_connect(connected_callback,"fast")
	base.PUBLIC.create_db_connect(connected_callback,"slow")

end

-- 检查是否可以停止服务
function base.PUBLIC.try_stop_service(_count,_time)

	-- 还有 sql 未执行，则不能结束
	if not DATA.sql_queue_fast:empty() then
		return "wait","fast queue is writing : " .. tostring(DATA.sql_queue_fast:front())
	end
	if not DATA.sql_queue_slow:empty() then
		return "wait","slow queue is writing : " .. tostring(DATA.sql_queue_slow:front())
	end

	-- 等待已退出 应用 更新状态数据，避免 gather_services_status 访问无效地址
	skynet.sleep(100)

	-- 检查除自己和center 之外的所有服务，他们都退出了（都可能还要保存数据），自己才能停。
	local _services = skynet.call(DATA.service_config.center_service,"lua","gather_services_status",3)
	for _,_service in pairs(_services) do
		-- 排除 自己和center
		if _service.arg and _service.addr ~= skynet.self() and "free" ~= _service.status and "stop" ~= _service.status then
			return "wait",string.format("service ':%08x' maybe using me!",_service.addr)
		end
	end

	return "stop"
end

function base.CMD.start(_service_config)

	DATA.service_config = _service_config

	base.import("game/services/data_service/sczd_db_info.lua").init()

	init_database()

end

-- 启动服务
base.start_service()



