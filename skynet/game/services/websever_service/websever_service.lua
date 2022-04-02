local skynet = require "skynet_plus"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local base=require "base"
local basefunc = require "basefunc"

local filter = require "websever_service.filter"

require "printfunc"

local nodefunc = require "nodefunc"

local CMD = base.CMD

local table = table
local string = string

local mode = ...

if mode == "agent" then

	-- 主机对象，可在服务脚本中访问
	local host = {
		CMD=CMD, -- 本服务器的命令
		service_config = nil, -- 服务配置
	}

	function CMD.start(_service_config)
		host.service_config = _service_config
		base.DATA.service_config = _service_config
	end

	local function print(p1,...)
		skynet.send(host.service_config.web_server_service,"lua","web_log",os.date("[%Y-%m-%d %H:%M:%S] ") .. tostring(p1) ,...) 
	end

	local root_path = "./game/services/websever_service"

	-- 加载文件，返回：文件内容， 类型
	local function web_filereader(file)

		-- 只有这些文件可以被访问
		local webapi = nodefunc.get_global_config("webserver_api")

		local item = webapi[file]
		if item then

			return basefunc.path.read(root_path .. file .. (item.postfix or "")),item.type or "lweb"
		end

		return nil,404
	end

	-- 解析请求
	local function parse_request(url, method, header, body,addr)
		local path, query = urllib.parse(url)

		local request = {url=url,source=addr,method=method,header=header,body=body }
		if "POST" == method then
			request.post = urllib.parse_query(body)
		elseif "GET" == method then
			request.get = urllib.parse_query(query)
		end

		print("<" .. tostring(addr) .. "> request:\n" .. basefunc.tostring(request))

		host.is_debug = skynet.getcfg("debug")

		-- 先处理过滤器
		local handled,code,resp = filter.handle(path,host,request,web_filereader)
		if not handled then
			code,resp = httpd.parse_htmlua(path,host,request,web_filereader,skynet.getcfg("webserver_disable_cache"))
		end

		print("<" .. tostring(addr) .. "> response:" .. "code=" .. tostring(code) .. ",resp=" .. tostring(resp) .. "\n")

		if 200 == code then
			return code,resp
		elseif 600 == code then
			return parse_request(resp, method, header, body)
		else
			return code,"[file:" .. path .. "]" .. tostring(resp or "empty")
		end
	end

	local function response(fd,addr, ...)
		local ok, err = httpd.write_response(sockethelper.writefunc(fd), ...)
		if not ok then
			-- if err == sockethelper.socket_error , that means socket closed.
			print(string.format("fd = %d,addr=%s, %s", fd,tostring(addr), err))
		end
	end

	function CMD.web_request(fd,addr)

		socket.start(fd)
		-- limit request body size to 8192 (you can pass nil to unlimit)
		local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(fd), 8192)
		if code then
			if code == 200 then
				response(fd,addr, parse_request(url, method, header, body,addr) )
			else
				response(fd,addr, code)
			end
		else
			if url == sockethelper.socket_error then
				print("socket closed")
			else
				print(url)
			end
		end
		socket.close(fd)
	end

	-- 启动服务
	base.start_service()
else

	local _log_queue = {""}
	local _log_file 

	function CMD.web_log(...)
		local _count = select("#",...)
		if _count > 0 then
			_log_queue[#_log_queue + 1] = table.concat({...},"\t",1,_count)
		end
	end

	local print_orgi = print
	local print = CMD.web_log

	local function print(p1,...)
		CMD.web_log(os.date("[%Y-%m-%d %H:%M:%S] ") .. tostring(p1) ,...)
	end

	local webserver_port = skynet.getenv "webserver_port"
	local webserver_agent_num = skynet.getenv "webserver_agent_num"

	--处理单元实例
	local agent = {}

	function CMD.start(_service_config)

		for i= 1, webserver_agent_num do
			agent[i] = skynet.newservice(SERVICE_NAME, "agent")
			skynet.call(agent[i], "lua", "start",_service_config)
		end

		local balance = 1

		print("Listen web port :"..webserver_port)
		local fd = socket.listen("0.0.0.0", webserver_port)
		socket.start(fd , function(accept_fd, addr)
			if "running" ~= base.DATA.current_service_status then
				print("websever_service will close refuse connect")
				return
			end
			print(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
			skynet.send(agent[balance], "lua", "web_request", accept_fd,addr)
			balance = balance + 1
			if balance > #agent then
				balance = 1
			end
		end)
	end


	-----------------------------
	-- 日志写入功能

	local function open_log_file()

		if _log_file then
	
			return _log_file ~= "open error"
	
		else
			local err
			_log_file,err = io.open("./logs/web_access.log","a")
			if not _log_file then
				_log_file = "open error"
				print_orgi(string.format("open './logs/web_access.log' error:%s!", tostring(err)))
				return false
			end
	
			return true
		end
	end
	
	local function flush_log()
	
		if _log_file and _log_file ~= "open error" then
	
			_log_file:close()
	
			_log_file = nil
		end
	end	

	local _flush_counter = 0
	local _error_data_dirty = false
	skynet.timer(1,function ()

		_flush_counter = _flush_counter + 1
		if _error_data_dirty and _flush_counter % 10 == 0 then
			flush_log()
			_error_data_dirty = false
		end
	
		if next(_log_queue) and open_log_file() then
			local _tmp = _log_queue
			_log_queue = {""}
			_log_file:write(table.concat(_tmp,"\n"))
			_error_data_dirty = true
		end
	end)

	-- 启动服务
	base.start_service()
end
