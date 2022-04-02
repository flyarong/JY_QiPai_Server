--
-- Author: lyx
-- Date: 2018/4/26
-- Time: 17:34
-- 说明：一个控制会话
--

local skynet = require "skynet_plus"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local base=require "base"

require "normal_enum"

require "admin_console_service.service_manager"

local cluster = require "skynet.cluster"

require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local console_session = basefunc.class()

console_session.command = {}

function console_session:ctor(_echo_func)

	-- 回显函数
	self._echo_func = _echo_func

	-- 当前命令的执行序号，每执行一次 增长 1
	self.cmd_index = 0

	-- 当前命令是否正在运行
	self.cmd_running = false
end

-- 解析参数
-- 带 '-' 前缀的为参数名； 不带 '-' 的为值，总是属于前一个参数名；
-- 一个参数名可能包含0个或多个值
-- 在第一个 '-' 之前的参数 以数组的方式放在返回值中
function console_session:parse_args(...)
	local _args = table.pack(...)

	local _ret_data = {}
	local _cur_arg
	for i = 1,_args.n do
		if string.sub(_args[i],1,1) == '-' then
			_cur_arg = {}
			_ret_data[string.sub(_args[i],2)] = _cur_arg
		else
			if _cur_arg then
				_cur_arg[#_cur_arg +1] = _args[i]
			else
				_ret_data[#_ret_data +1] = _args[i]
			end
		end
	end

	return _ret_data
end

function console_session:echo(...)
	self._echo_func(...)
end 
function console_session.command:help()
	self:echo [[

	============== 服务和节点 ====================
    nodes                         列出所有节点.
    services [-n node]            列出所有服务.
        参数:
            -n node: 只显示给出的节点上的服务.
            -e : 包含无法访问的服务（可能已经退出）.
    status [-n node]              查看服务状态.
        参数:
            -n node: 只显示给出的节点上的服务.
    shutdown [-n node] [-t time] 停止所有服务并关机.
        参数:
            -n node: 只关闭给定的节点.
            -t time: 在给定时间内正确停止服务，则关机；否则放弃；0 表示无限等待直到停止服务成功。
			-f time: 在给定时间内强制关机，即时服务未正确停止!

	============== 代码热修补 ====================
		参数 <file> 说明： 放在 hotfix 文件夹下的 文件，不包含路径和扩展名
	hf_inc_ver <file> 	增长版本号，以便让所有服务执行一次热修补
	hf_show_info <file>	显示当前热修补信息
	hf_enable <file>	启用热修补（注意：执行 hf_inc_ver 时会自动启用）
	hf_disable <file>	禁用热修补

	============== 配置管理 ====================
    getenv <name>                 得到只读配置（仅限当前节点，下同）
    setcfg <name> <value>         设置配置值
    setcfgi <name> <value>        设置配置值（数字）
    getcfg <name>                 得到配置值
    nsetcfg <node name> <name> <value>    给节点名 设置配置值
    nsetcfgi <node name> <name> <value>   给节点名 设置配置值（数字）
    ngetcfg <node name> <name>            给节点名 得到配置值
	
	============== 访问服务 ====================
    insvr                         列出内部服务列表
    call <service> <cmd> [param ...] 根据名字调用内部服务
    node_call <id> <cmd> [param ...] 根据 id 调用 node service 管理的服务
    incmd <service name>          列出内部服务的命令列表
    reloadcfg <service name>      重载一个服务的配置
	nm_reload_joinid		      重载冠名赛的加入id
	
    give <players>,<type>,<value> 给玩家发钱
            参数：
                players ： 玩家 id，一个或多个，例如："10106069",{"10990027","10102157"}
                type    ： 财富类型，例如："jing_bi","diamond","shop_gold_sum"
                value   ： 钱的数量
            举例：
                give "10106069","jing_bi",675
                give {"10990027","10102157"},"jing_bi",675
				give "ALL_USER","jing_bi",675
    money <players>,<type>,<value> 用法和 give 相同，区别是 不通过邮件，直接发
	]]
end

function console_session.command:services(...)
	local _args = self:parse_args(...)

	local _node_name = _args.n and _args.n[1]

	local _out_sers = base.CMD.get_servcies(_node_name,_args.e)

	if #_out_sers > 0 then
		self:echo("\n")
		self:echo(string.format("%-9s %-8s %-40s %-15s %s","addr","res","id","node","launch args"))
		self:echo("-------------------------------------------------------------------------------------------")

		for _,_service in pairs(_out_sers) do
			self:echo(string.format(":%08x %-8s %-40s %-15s %s",
					_service.addr,tostring(_service.res),_service.id,
					_service.node_name,_service.arg))
		end
		self:echo("-------------------------------------------------------------------------------------------")
		self:echo(string.format("total service count:%d\n",#_out_sers))
	else
		self:echo("not found service !\n")
	end

end

function console_session:echo_nodes(_nodes)
	local _count = 0

	if _nodes and next(_nodes) then
		self:echo(string.format("\n%-9s %-5s %-15s %s","addr","id","name","resouce"))
		self:echo("---------------------------------------------------")
		for _node_name,_data in pairs(_nodes) do
			_count = _count + 1
			self:echo(string.format("%-9s %-5s %-15s %s",string.format(":%08x",_data.node_service_addr),
				_data.node_service_id,_node_name,_data.res))
		end
		self:echo("---------------------------------------------------")
	end
	self:echo(string.format("total node count:%d\n",_count))
end

function console_session.command:nodes()

	local _nodes = skynet.call(DATA.service_config.center_service,"lua","get_node_list")

	self:echo_nodes(_nodes)

end

function console_session.command:hf_inc_ver(_file)
	if not _file or "" == _file then
		self:echo("please input file !")
		return
	end

	local _cfg_name = tostring(_file) .. "_ver"

	local _old = tonumber(skynet.getcfg(_cfg_name)) or 0
	skynet.setcfg(_cfg_name,_old + 1)
	skynet.setcfg(tostring(_file) .. "_enable",true)

	self:echo(string.format("version:%s => %s",tostring(_old),tostring(skynet.getcfg(_cfg_name))))
end

function console_session.command:hf_show_info(_file)
	if not _file or "" == _file then
		self:echo("please input file !")
		return
	end

	self:echo(string.format("\nversion=%s\nstatus=%s\n",
		skynet.getcfg(tostring(_file) .. "_ver"),
		skynet.getcfg(tostring(_file) .. "_enable")))
end

function console_session.command:hf_enable(_file)
	if not _file or "" == _file then
		self:echo("please input file !")
		return
	end

	local _cfg_name = tostring(_file) .. "_enable"

	local _old = skynet.getcfg(_cfg_name)
	skynet.setcfg(_cfg_name,true)
	
	self:echo(string.format("status:%s => %s",tostring(_old),tostring(skynet.getcfg(_cfg_name))))
end

function console_session.command:hf_disable(_file)
	if not _file or "" == _file then
		self:echo("please input file !")
		return
	end

	local _cfg_name = tostring(_file) .. "_enable"

	local _old = skynet.getcfg(_cfg_name)
	skynet.setcfg(_cfg_name,false)
	
	self:echo(string.format("status:%s => %s",tostring(_old),tostring(skynet.getcfg(_cfg_name))))
end

function console_session.command:getenv(_name)

	if not _name then
		self:echo("name is nil!\n")
		return
	end

	if skynet.getenv(_name) then
		self:echo(string.format("%s='%s'",_name,tostring(skynet.getenv(_name))))
	else
		self:echo(string.format("%s=nil",_name))
	end

end

function console_session.command:setcfg(_name,_value)
	if not _name then
		self:echo("name is nil!\n")
		return
	end

	local _old = skynet.getcfg(_name)
	skynet.setcfg(_name,_value)
	self:echo(string.format("%s='%s:%s=>%s:%s'",_name,
		type(_old),tostring(_old),
		type(skynet.getcfg(_name)),tostring(skynet.getcfg(_name))))

end


function console_session.command:setcfgi(_name,_value)

	console_session.command.setcfg(self,_name,tonumber(_value))

end

function console_session.command:getcfg(_name)

	if not _name then
		self:echo("name is nil!\n")
		return
	end

	local v = skynet.getcfg(_name)
	self:echo(string.format("%s='%s:%s'",_name,type(v),tostring(v)))

end

function console_session:set_node_cfg(_node,_name,_value)
	local ok,ret = pcall(cluster.call,_node,"node_service","update_config",_name,_value)
	if ok then
		return true
	else
		self:echo(string.format("error:%s\n",tostring(ret)))
		return false
	end
end
function console_session:get_node_cfg(_node,_name)
	local ok,ret = pcall(cluster.call,_node,"node_service","query_config",_name)
	if not ok then
		self:echo(string.format("error:%s\n",tostring(ret)))
	end

	return ok,ret
end

function console_session.command:nsetcfg(_node,_name,_value)
	if not _name then
		self:echo("name is nil!\n")
		return
	end
	if not _node then
		self:echo("node name is nil!\n")
		return
	end

	local ok,_old = self:get_node_cfg(_node,_name)
	if not ok then
		return
	end

	if not self:set_node_cfg(_node,_name,_value) then
		return
	end

	local ok2,_new = self:get_node_cfg(_node,_name)
	
	self:echo(string.format("%s='%s:%s=>%s:%s'",_name,
		type(_old),tostring(_old),
		type(_new),tostring(_new)))

end

function console_session.command:nsetcfgi(_node,_name,_value)
	console_session.command.nsetcfg(self,_node,_name,tonumber(_value))
end

function console_session.command:ngetcfg(_node,_name,_value)
	local ok,v = self:get_node_cfg(_node,_name)
	if not ok then
		return
	end

	self:echo(string.format("%s='%s:%s'",_name,type(v),tostring(v)))
end

function console_session.command:incmd(_service)

	local srv_addr = DATA.service_config[_service]
	if not srv_addr then
		self:echo(string.format("not found service:%s\n",_service))
		return
	end

	local ok,ret = pcall(skynet.call,srv_addr,"lua","incmd")
	if ok then
		for i,v in ipairs(ret) do
			self:echo(string.format("    %3d.%s",i,v))
		end
	else
		self:echo(string.format("service incmd error:\n%s\n",tostring(ret)))
	end
end


function console_session.command:reloadcfg(_service)

	local srv_addr = DATA.service_config[_service]
	if not srv_addr then
		self:echo(string.format("not found service:%s\n",_service))
		return
	end

	local ok,ret = pcall(skynet.call,srv_addr,"lua","reload_config")
	if ok then
		if ret == 0 then
			self:echo(string.format("service reloadcfg ok:\n%s\n",_service))
		end
	else
		self:echo(string.format("service reloadcfg error:\n%s\n",tostring(ret)))
	end
end


function console_session.command:nm_reload_joinid()

	local srv_addr = DATA.service_config["match_center_service"]
	if not srv_addr then
		self:echo("not found service:match_center_service\n")
		return
	end

	local ok,ret = pcall(skynet.call,srv_addr,"lua","nm_reload_join_id")
	if ok then
		if ret == 0 then
			self:echo("service nm_reload_joinid ok:\n\n")
		end
	else
		self:echo(string.format("service nm_reload_joinid error:\n%s\n",tostring(ret)))
	end
end


local function parse_lua_line(...)
	local _param = table.pack(...)
	for i=1,_param.n do
		_param[i] = _param[i] and tostring(_param[i]) or ""
	end

	return load("return " .. table.concat(_param),"[debug call param]")
end

local function error_handle(self,msg)
	self:echo(string.format("call service error:\n%s\n%s\n",tostring(msg),debug.traceback()))
end	

function console_session:check_call_return(ok,err,...)
	if ok then
		return ok,err,...
	else
		self:echo(string.format("call service error:\n%s\n",tostring(err)))
		return false,err
	end	
end

function console_session:safe_call_service(_service,_cmd,...)

	local srv_addr = DATA.service_config[_service] or _service

	return self:check_call_return(xpcall(skynet.call,function(msg) error_handle(self,msg) end,srv_addr,"lua",_cmd,...))
end

function console_session.command:call(_service,_cmd,...)

	local _param_func,err = parse_lua_line(...)
	if _param_func then
		local ok,ret = self:safe_call_service(_service,_cmd,_param_func())
		if ok then
			self:echo(string.format("result:\n%s\n",basefunc.tostring(ret)))
		end
	else
		self:echo(string.format("parse param error:\n%s\n",tostring(err)))
	end
end

function console_session:safe_call_node_service(id,func,...)

	return self:check_call_return(xpcall(nodefunc.call,function(msg) error_handle(self,msg) end,id,func,...))
end

function console_session.command:node_call(id,func,...)

  local _param_func,err = parse_lua_line(...)
  if _param_func then
    local ok,ret = self:safe_call_node_service(id,func,_param_func())
    if ok then
      self:echo(string.format("result:\n%s\n",basefunc.tostring(ret)))
    end
  else
    self:echo(string.format("parse param error:\n%s\n",tostring(err)))
  end
end

function console_session.command:money(_players,_type,_value)

	local _param_func,err = parse_lua_line(_players,_type,_value)
	if _param_func then
		local _players2,_type2,_value2 = _param_func()

		if not basefunc.is_asset(_type2) then
			self:echo("错误：参数 type 不正确！")
			return
		end

		if type(_value2) ~= "number" then
			self:echo("错误：参数 value 不正确！")
			return
		end

		if not _players2 then
			self:echo("错误：参数 players 不能为 nil！\n如果要给所有人发放，请传入 \"ALL_USER\"")
			return
		end

		if type(_players2) == "string" then
			_players2 = {_players2}
		elseif type(_players2) == "table" then
			if not next(_players2) then
				self:echo("错误：参数 players 不能为空！\n如果要给所有人发放，请传入 \"ALL_USER\"")
				return
			end
		else
			self:echo("错误：参数 players 错误！")
			return
		end

		for _,_pid in ipairs(_players2) do
	
			skynet.send(DATA.service_config.data_service,"lua","change_asset_and_sendMsg",
				_pid , _type2 ,_value2, "debug_console_send" , "null" )

		end

	else
		self:echo(string.format("parse param error:\n%s\n",tostring(err)))
	end

end

function console_session.command:give(_players,_type,_value)

	local _param_func,err = parse_lua_line(_players,_type,_value)
	if _param_func then
		local _players2,_type2,_value2 = _param_func()

		if not basefunc.is_asset(_type2) then
			self:echo("错误：参数 type 不正确！")
			return
		end

		if type(_value2) ~= "number" then
			self:echo("错误：参数 value 不正确！")
			return
		end

		if not _players2 then
			self:echo("错误：参数 players 不能为 nil！\n如果要给所有人发放，请传入 \"ALL_USER\"")
			return
		end

		if "ALL_USER" == _players2 then
			_players2 = nil -- nil 表示发给所有人
		elseif type(_players2) == "string" then
			_players2 = {_players2}
		elseif type(_players2) == "table" then
			if not next(_players2) then
				self:echo("错误：参数 players 不能为空！\n如果要给所有人发放，请传入 \"ALL_USER\"")
				return
			end
		else
			self:echo("错误：参数 players 错误！")
			return
		end

		-- 构造邮件参数
		local arg =
		{
			players = _players2,
			email=
			{
				type="native",
				title="hello monkey!",
				sender="system",
				valid_time=os.time() + 3600, -- 一小时后过期（过期自动领取）
				data = string.format("{content='恭喜你获得了%d %s,尽情享用吧',%s=%d}",_value2,_type2,_type2,_value2),
			}
		}

		-- 调用邮件服务
		local errcode = skynet.call(DATA.service_config.email_service,"lua",
												"external_send_email",
												arg,
												"admin_debug_console",
												"debug_test")

	else
		self:echo(string.format("parse param error:\n%s\n",tostring(err)))
	end
end

function console_session.command:give_obj(_players,_type,_attribute)

	local _param_func,err = parse_lua_line(_players,_type,_attribute)
	if _param_func then
		local _p,_t,_a = _param_func()

		if not basefunc.is_object_asset(_t) or _t == "jipaiqi" then
			self:echo("错误：参数 type 不正确！")
			return
		end

		if type(_a) ~= "string" then

			self:echo("错误：参数 value 不正确！")
			return
		end

		if not _p then
			self:echo("错误：参数 players 不能为 nil！\n如果要给所有人发放，请传入 \"ALL_USER\"")
			return
		end

		if "ALL_USER" == _p then
			_p = nil -- nil 表示发给所有人
		elseif type(_p) == "string" then
			_p = {_p}
		elseif type(_p) == "table" then
			if not next(_p) then
				self:echo("错误：参数 players 不能为空！\n如果要给所有人发放，请传入 \"ALL_USER\"")
				return
			end
		else
			self:echo("错误：参数 players 错误！")
			return
		end

		-- 构造邮件参数
		local arg =
		{
			players = _p,
			email=
			{
				type="native",
				title="hello monkey!",
				sender="system",
				valid_time=os.time() + 3600, -- 一小时后过期（过期自动领取）
				data = string.format("{content='恭喜你获得了 %s,尽情享用吧',%s=true,attribute={%s}}",_t,_t,_a),
			}
		}

		-- 调用邮件服务
		local errcode = skynet.call(DATA.service_config.email_service,"lua",
												"external_send_email",
												arg,
												"admin_debug_console",
												"debug_test")

	else
		self:echo(string.format("parse param error:\n%s\n",tostring(err)))
	end
end


function console_session.command:insvr()

	local _count = 0
	for _name,_addr in pairs(DATA.service_config) do
		_count = _count + 1
		self:echo(string.format("    %3d [:%08x] %s",_count,_addr,_name))
	end
end


function console_session.command:shutdown(...)

	local _args = self:parse_args(...)

	-- ###_temp 这个 时间暂时未用，完善后的实现方法： 如果提供了，则在这个时间后强制退出进程；没提供则等所有服务停止后退出进程。
	local _time = _args.t and _args.t[1]
	local _node = _args.n and _args.n[1]

	local _ok,_datas = CMD.shutdown(_node,_args.f,_time or 5)

	if _ok then
		self:echo("shutdown succ:\n")
 		self:echo_nodes(_datas)
	else
		self:echo("shutdown error, services not stop:\n")
 		self:echo_services_satus(_datas)
	end
end

function console_session:echo_services_satus( _services )

	self:echo("\n")
	if #_services > 0 then
		self:echo(string.format("%-9s %-40s %-15s %-8s %s","addr","id","node","status","info"))
		self:echo("-------------------------------------------------------------------------------------------------")
		for _,_service in pairs(_services) do

			self:echo(string.format(":%08x %-40s %-15s %-8s %s",_service.addr,_service.id,_service.node_name,_service.status,_service.info))

		end


		self:echo("-------------------------------------------------------------------------------------------------")
		self:echo(string.format("total service count:%d\n",#_services))
	else
		self:echo("no service is runing !\n")
	end

end

function console_session.command:status(...)
	local _args = self:parse_args(...)

	local _node_name = _args.n and _args.n[1]

	local _services = CMD.get_status(_node_name)

	self:echo_services_satus(_services)

end

function console_session.command:exec_sql(...)
	local _args = self:parse_args(...)

	local ret = skynet.call(DATA.service_config.data_service,"lua","debug_exec_sql",table.concat(_args," "),_args.qname and _args.qname[1])
	self:echo(basefunc.tostring(ret))
end

function console_session.command:sql_status(...)
	local ret = skynet.call(DATA.service_config.data_service,"lua","debug_get_status")
	self:echo(ret)
end

function console_session.command:online_count(...)
	local _count = skynet.call(DATA.service_config.data_service,"lua","get_online_user_count")
	self:echo(_count)
end

function console_session:dispatch_command(_cmd,...)

	local _cur_index= self.cmd_index
	local f = console_session.command[_cmd]
	if f then
		if false ~= f(self,...) and _cur_index == self.cmd_index then
			self:echo("cmd ok!")
		end
	else
		self:echo(string.format("error:not found command '%s'!",tostring(_cmd)))
	end
end


return console_session
