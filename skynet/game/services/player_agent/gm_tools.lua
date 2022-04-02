--
-- Created by lyx.
-- User: hare
-- Date: 2018/6/8
-- Time: 14:36
-- 商城：管理员工具
--


local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
require "normal_enum"

local error_code = require "error_code"

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST

print("gm_tools.lua loaded!!!",DATA.my_id) 

local help_string=[[

★ 给玩家发钱
	give 玩家id,财富类型,财富值,邮件标题,邮件内容
		参数：
			玩家id  ： 玩家 id，一个或多个，例如："10106069",{"10990027","10102157"}
			财富类型： 财富类型("jing_bi" 鲸币,"diamond" 钻石,"shop_gold_sum" 红包券,"room_card" 房卡,"jipaiqi" 记牌器)
			财富值  ： 钱的数量。注意：红包券的单位是 分！
		举例：
			give "10106069","jing_bi",200,"奖励","恭喜你获得 200 鲸币！"
			give {"10990027","10102157"},"shop_gold_sum",300,"奖励","恭喜你获得 300 红包券！"

★ 给玩家发钱 
	money 玩家id,财富类型,财富值 
		例如：
			money "10106069","jing_bi",200
		说明：
			前三个参数 和 give 相同，区别是 不需要收邮件，自动加

★ 完成支付订单
	pay 订单号
		例如：
			pay "201905140000001gdjid"

★ 给玩家或者所有玩家发送邮件
	email 玩家id,邮件标题,邮件内容,奖励类型1,奖励数量1,奖励类型2,奖励数量2...
		参数：
			玩家id  ： 玩家 id，一个或多个或所有，例如："10106069",{"10990027","10102157"},"ALL_USER"
		举例：
			email "10106069","通知","恭喜你进入决赛！","jing_bi",1000
			email {"10990027","10102157"},"通知","恭喜你进入决赛！"
			email "ALL_USER","通知","恭喜你进入决赛！"
			email "ALL_USER","通知","恭喜你进入决赛！","jing_bi",1000,"fish_coin",2000

★ 给某个玩家开启n天bbsc权限
	open_bbsc_day_permit 玩家id,开启到第几天
		举例：
		open_bbsc_day_permit "105883",7

★ 给某个玩家的某个任务加进度
	add_task_progress 玩家id,任务id,加的进度
		举例：
		add_task_progress "1013195",8,1

★ 改变上下级
	change_player_relation 玩家id,新上级id,操作人
		举例:
		change_player_relation "1010096","1013137","wss"

★ 开启玩家对的各种收益开关
	set_activate_sczd_profit 玩家id,推广员提现权限,下级玩家奖权限,推广礼包权限,比赛奖权限)
		举例:
		set_activate_sczd_profit "1010052","false","false","false","false"
]]

local function error_handle(msg)
	local _info = string.format("error:\n%s\n%s\n",tostring(msg),debug.traceback())
	print(_info)
	return _info
end	

local gm_cmd = {}


local function parse_lua_line(...)
	local _param = table.pack(...)
	for i=1,_param.n do
		_param[i] = _param[i] and tostring(_param[i]) or ""
	end

	return load("return " .. table.concat(_param),"[gm command param]","bt",{})
end

function gm_cmd.help()
	return help_string
end

function gm_cmd.give(_players,_type,_value,_title,_content)
	
	if not basefunc.is_asset(_type) then
		return "错误：财富类型不正确！"
	end

	if type(_value) ~= "number" then
		return "错误：财富值不正确！"
	end

	if not _players then
		return "错误：玩家 id 不能为 空！"
	end

	if "ALL_USER" == _players then
		--_players = nil -- nil 表示发给所有人
		return "错误：不支持 ALL_USER 玩家！"  -- 不支持
	elseif type(_players) == "string" then
		_players = {_players}
	elseif type(_players) == "table" then
		if not next(_players) then
			return "错误：玩家 id 不能为空表！"
		end
	else
		return "错误：没有输入玩家 id！"
	end

	_content = tostring(_content  or "恭喜你获得了{value} {type},尽情享用吧!")
	_content = string.gsub(_content,"\"","\\\"")
	_content = string.gsub(_content,"{value}",tostring(_value))
	_content = string.gsub(_content,"{type}",tostring(_type))

	-- 构造邮件参数
	local arg =
	{
		players = _players,
		email=
		{
			type="native",
			title=tostring(_title or "系统邮件"),
			sender="鲸鱼斗地主官方",
			valid_time=0,
			data = string.format("{content='%s',%s=%d}",_content,_type,_value),
		}
	}

	-- 调用邮件服务
	local errcode = skynet.call(DATA.service_config.email_service,"lua",
											"external_send_email",
											arg,
											DATA.my_id,
											"gm add award")

	if not errcode or errcode == 0 then
		return "成功完成!"
	else
		return "执行失败：" .. (errcode and error_code[errcode] or tostring(errcode))
	end
end

function gm_cmd.email(_players,_title,_content,...)

	if not _players then
		return "错误：玩家 id 不能为 空！"
	end

	if "ALL_USER" == _players then
		_players = nil -- nil 表示发给所有人
	elseif type(_players) == "string" then
		_players = {_players}
	elseif type(_players) == "table" then
		if not next(_players) then
			return "错误：玩家 id 不能为空表！"
		end
	else
		return "错误：没有输入玩家 id！"
	end

	if type(_content) ~= "string" then
		return "错误：输入的信息内容有误！"
	end

	_content = string.gsub(_content,"\"","\\\"")

	local ad = {}
	local as = {...}
	local al = #as
	if al%2 ~= 0 then
		return "错误：输入的资产内容有误！"
	end
	for i=1,al,2 do
		
		local k = as[i]
		if not basefunc.is_asset(k) then
			return "错误：财富类型不正确！"
		end

		local v = tonumber(as[i+1])
		if not v or v < 1 then
			return "错误：财富数量不正确！"
		end

		ad[k]=v
	end

	-- 构造邮件参数
	local arg =
	{
		players = _players,
		email=
		{
			type="native",
			title=tostring(_title or "系统邮件"),
			sender="鲸鱼斗地主官方",
			valid_time=0,
			data = string.format("{content='%s'",_content),
		}
	}

	for k,v in pairs(ad) do
		arg.email.data = arg.email.data .. "," .. k .."=".. v
	end
	
	arg.email.data = arg.email.data .. "}"

	-- 调用邮件服务
	local errcode = skynet.call(DATA.service_config.email_service,"lua",
											"external_send_email",
											arg,
											DATA.my_id,
											"gm send msg")

	if not errcode or errcode == 0 then
		return "成功完成!"
	else
		return "执行失败：" .. (errcode and error_code[errcode] or tostring(errcode))
	end
end

function gm_cmd.pay(_order_id)

	local ok,errcode = skynet.call(DATA.service_config.pay_service,"lua","modify_pay_order",
	_order_id,"complete","gm shougong complete:" .. tostring(DATA.my_id))
	if ok then
		return "成功完成"
	else
		return "错误 " .. tostring(errcode) .. " :" .. tostring(errcode and error_code[errcode])
	end
end

function gm_cmd.open_bbsc_day_permit(player_id,day_num)
	if not player_id or type(player_id) ~= "string" then
		return "player_id 参数错误"
	end
	if not day_num or type(day_num) ~= "number" then
		return "day_num 参数错误"
	end
	skynet.send(DATA.service_config.task_center_service,"lua","open_bbsc_day_permit",
			player_id , day_num )
end

function gm_cmd.add_task_progress( player_id , task_id , add )
	if not player_id then
		return "错误：参数 players 不能为 nil！"
	end
	if type(player_id) ~= "string" then
		return "player_id 应该为字符串"
	end
	if not task_id or type(task_id) ~= "number" then
		return "task_id 参数错误"
	end
	if not add or type(add) ~= "number" then
		return "add 参数错误"
	end

	skynet.send(DATA.service_config.task_center_service,"lua","add_task_progress",
			player_id , task_id , add )

end

function gm_cmd.change_player_relation(player_id,new_parent,op_player)
	if not player_id or type(player_id) ~= "string" then
		return "player_id 参数错误"
	end
	if not new_parent or type(new_parent) ~= "string" then
		return "new_parent 参数错误"
	end
	if not op_player or type(op_player) ~= "string" then
		return "op_player 参数错误"
	end
	skynet.send(DATA.service_config.sczd_center_service,"lua","change_player_relation",
			player_id,new_parent,op_player )
end

function gm_cmd.set_activate_sczd_profit(player_id , tgy_tx_profit , xj_profit , tglb_profit , basai_profit)
	if not player_id or not tgy_tx_profit or not xj_profit or not tglb_profit or not basai_profit
		or type(player_id) ~= "string" or type(tgy_tx_profit) ~= "string" or type(xj_profit) ~= "string" or type(tglb_profit) ~= "string" or type(basai_profit) ~= "string" 
		or (tgy_tx_profit ~= "true" and tgy_tx_profit~="false") or (xj_profit ~= "true" and xj_profit~="false") or (tglb_profit ~= "true" and tglb_profit~="false") or (basai_profit ~= "true" and basai_profit~="false") then
		return "参数错误"
	end
	skynet.send(DATA.service_config.sczd_center_service,"lua","set_activate_sczd_profit",
			player_id , tgy_tx_profit , xj_profit , tglb_profit , basai_profit )
end

function gm_cmd.money(_players,_type,_value)

	if not basefunc.is_asset(_type) then
		return "错误：参数 type 不正确！"
	end

	if type(_value) ~= "number" then
		return "错误：参数 value 不正确！"
	end

	if not _players then
		return "错误：参数 players 不能为 nil！\n如果要给所有人发放，请传入 \"ALL_USER\""
	end

	if type(_players) == "string" then
		_players = {_players}
	elseif type(_players) == "table" then
		if not next(_players) then
			return "错误：参数 players 不能为空！\n如果要给所有人发放，请传入 \"ALL_USER\""
		end
	else
		return "错误：参数 players 错误！"
	end

	for _,_pid in ipairs(_players) do

		skynet.send(DATA.service_config.data_service,"lua","change_asset_and_sendMsg",
			_pid , _type ,_value, "gm user op:" .. tostring(DATA.my_id) , "null" )

	end

end

-- function gm_cmd.testxx(...)
-- 	return table.concat({...},"--|--")
-- end

function REQUEST.gm_command(_data)

	if not skynet.getcfg("gm_user_debug") then
		if not DATA.extend_data.player_level or DATA.extend_data.player_level < 1 then
			return {result="错误：普通用户不能使用此功能！"}
		end
	end

	if not _data.command or "" == _data.command then
		return {result="错误：不能执行空命令！"}
	end

	local _cmd,_args
	local _pos = string.find(_data.command," ") -- 命令和参数 用空格隔开
	if _pos then
		_cmd = string.sub(_data.command,1,_pos-1)
		_args = string.sub(_data.command,_pos+1)
	else
		_cmd = _data.command
	end

	if not gm_cmd[_cmd] then
		return {result=string.format("错误：不支持的命令 '%s' ！",_cmd)}
	end

	local _param_func = parse_lua_line(_args)
	if not _param_func then
		return {result="错误：参数错误！"}
	end

	local ok,ret = xpcall(gm_cmd[_cmd],error_handle,_param_func())
	if ok then
		return {result=ret}
	else
		return {result="错误：" .. tostring(ret)}
	end
end