local skynet = require "skynet"
local sc = require "skynet.socketchannel"
local socket = require "skynet.socket"
local cluster = require "skynet.cluster.core"
require "printfunc"
local config_name = skynet.getenv "cluster"
local node_address = {}
local node_session = {}
local fd_to_nodeChannel={}
local command = {}
--[[by HW  2018.4.22---
--socket:
-- session 的编号1-50留作框架特殊用途
	1 表示node广播，告知本socket对应的node name
	2 请求再次发送相应的request包
	3 请求再次发送相应的response包
	4 request包缓存已经不存在
	5 response包缓存已经不存在
	6 已经安全的包信息（可以释放缓存）
	7 request包长度
--]]
--read_response:
--[[
	8 response包长度  
--]]

local my_node_name=skynet.getenv "my_node_name"
local is_open_strict_transfer=tonumber(skynet.getenv "strict_transfer")
--报告接受情况间隔
local report_accept_info_interval=1000
local gc_interval=180000
--再次请求数据间隔
local request_package_again_interval=300
--再次请求数据累计次数
local request_package_again_time=3

local loop_interval=100000000
--缓存队列长度
local cache_max_len=30000

local fd_to_nodeName={}
local nodeName_to_fd={}

local session_init=50
local session_max=1073741821

local request_large_package_sz={}
--cache
local request_cache_data={}
local request_cache_request={}
local request_cache_padding={}
local request_cache_sz={}
local request_cache_session={}

--是否是push缓存
local request_cache_isPush={}
local is_need_wait={}
local wait_queue_data={}
local wait_queue={}

--可能已经丢失的request包
local request_missing_map={}
--当前接受到的最大session
local cur_max_session={}

--response
local rp_session_init=50
local rp_session_max=2147483645

local response_large_package_sz={}

local response_result_data_sz={}
--my_session 到 session的映射
local response_myS_to_s={}

local response_cache_data={}
local response_cache={}	
local response_cache_sz={}
local response_cache_session={}

local is_response_need_wait={}
local response_wait_queue_data={}
local response_wait_queue={}

local response_missing_map={}
local cur_max_response_session={}
local response_node_session={}
local node_channel

local cluter_heart_map={}
local heart_ser_adds

local no_sock_err
if is_open_strict_transfer==1 then
		no_sock_err=true
		heart_ser_adds="node_ht_ser"
end


-- by lyx '安静的尝试连接'，不报连接错误
local silent_try_connect = false

-- by lyx 2018-7-25
local function error_handle(_msg)
	if not silent_try_connect then
		skynet.error(tostring(_msg) .. " error : " .. tostring(debug.traceback()))
	end
	return msg
end

function command.set_silent_try_connect(_silent)
	silent_try_connect = _silent
	sc.silent_try_connect = _silent

end

function command.get_cluter_heart_map()
	skynet.ret(skynet.pack(cluter_heart_map))
end

local function add_response_cache(node,response,cur_session,sz)
	--[[
		response_cache_data[node]={
									--当前链长度
									len
									--free_point在哪条链上(0当前，1上一条链)
									free_point_loc
									--当前释放点
									free_point
									--当前释放点session
									free_point_session
									--上一条链的长度
									last_len
									--上一条链的数据
									last_response_cache
									last_response_session
									last_response_sz
								}
	--]]
	response_cache_data[node].len=response_cache_data[node].len+1
	local len=response_cache_data[node].len
	response_cache[node][len]=response
	response_cache_session[node][len]=cur_session
	response_cache_sz[node][len]=sz
	if response_cache_data[node].len==1 and response_cache_data[node].loc==0 then
		response_cache_data[node].free_point=1
		response_cache_data[node].free_point_session=cur_session
	end
end
local function free_response_cache(node,session)
	local _data=response_cache_data[node]
	if session>=_data.free_point_session and session-_data.free_point_session<loop_interval then
		local len=session-_data.free_point_session+1
		--在当前链上的情况
		if _data.free_point_loc==0 then
			_data.free_point=_data.free_point+len
			_data.free_point_session=_data.free_point_session+len
			--检测当前链条是否需要切换
			if _data.len>cache_max_len then
				if _data.free_point>_data.len then
					_data.len=0
					response_cache[node]={}
					response_cache_session[node]={}
					response_cache_sz[node]={}
					_data.free_point=1
			    else
					_data.last_len=_data.len
					_data.len=0
					_data.last_response_cache=response_cache[node]
					_data.last_response_cache_session=response_cache_session[node]
					_data.last_response_cache_sz=response_cache_sz[node]
					response_cache[node]={}
					response_cache_session[node]={}
					response_cache_sz[node]={}
					_data.free_point_loc=1
			    end
			end
		--不在当前链
		else
			if _data.free_point+len>_data.last_len then
				_data.free_point_loc=0
				_data.last_response_cache=nil
				_data.free_point=_data.free_point+len-_data.last_len
				_data.free_point_session=_data.free_point_session+len
				_data.last_len=0
			else
				_data.free_point=_data.free_point+len
				_data.free_point_session=_data.free_point_session+len
			end
		end
		if _data.free_point_session>rp_session_max then
			_data.free_point_session=rp_session_init+_data.free_point_session-rp_session_max-1
		end
	else
		--是否是回绕
		if _data.free_point_session-session>loop_interval then
			free_response_cache(node,rp_session_max)
			free_response_cache(node,session)
		end
	end	
end
local function repeat_send_response_by_point(node,s,e,loc)
	-- print("repeat_send_response_by_point ",s,e,loc)
	local data,data_s,data_sz 
	if loc==0 then
		data =response_cache[node]
		data_s=response_cache_session[node]
		data_sz=response_cache_sz[node]
	else
		data  =response_cache_data[node].last_response_cache
		data_s=response_cache_data[node].last_response_session
		data_sz=response_cache_data[node].last_response_sz
	end
	for point=s,e do
		if type(data[point]) == "table" then
			-- print("repeat cb send sz",data_sz[point],data_s[point])
			-- local _request, _, _padding = cluster.packpush(1, 8, skynet.pack({session=data_s[point],sz=data_sz[point]}))
			-- node_channel[node]:equal_request(_request, nil, _padding)

			local _response,_ = cluster.packresponse(1,8, true, skynet.pack({session=data_s[point],sz=data_sz[point]}))
			socket.write(nodeName_to_fd[node], _response)
			
			for _, v in ipairs(data[point]) do
				if not socket.write(nodeName_to_fd[node], v) then
					-- print("res  break")	
					break
				end
			end
		else
			socket.write(nodeName_to_fd[node], data[point])
		end
	end

end
local function repeat_send_response_by_session(node,s_session,e_session)
	if e_session>=s_session then
		local _data=response_cache_data[node]
		--查找数据起点，终点
		local s,e
		if s_session>=_data.free_point_session and s_session-_data.free_point_session<loop_interval then
			s=_data.free_point+s_session-_data.free_point_session
		elseif _data.free_point_session-s_session>loop_interval then
			s=_data.free_point+rp_session_max-_data.free_point_session+s_session-rp_session_init+1
		--缓存可能已经不存在
		else
			local out_s,out_e
			out_s=s_session
			if s_session<_data.free_point_session then
				if e_session<_data.free_point_session then
					out_e=e_session
				elseif e_session>=_data.free_point_session then
					repeat_send_response_by_session(node,_data.free_point_session,e_session)
					out_e=_data.free_point_session-1
				end
			else
				out_e=e_session
			end
			print(out_s.."--"..out_e.." response缓存已经不存在!!")
			local request, new_session, padding = cluster.packpush(1, 5, skynet.pack({s=out_s,e=out_e}))
			node_channel[node]:equal_request(request, nil, padding)
			return 
		end
		e=s+e_session-s_session
		--确定具体在缓存的位置
		--在当前链上的情况
		if _data.free_point_loc==0 then
			if e>_data.len then
				e=_data.len
			end
			repeat_send_response_by_point(node,s,e,0)
		else
			if s>_data.last_len then
				s=s-_data.last_len
				e=e-_data.last_len
				if e>_data.len then
					e=_data.len
				end
				repeat_send_response_by_point(node,s,e,0)
			else
				if e>_data.last_len then
					repeat_send_response_by_point(node,s,_data.last_len,1)
					e=e-_data.last_len
					if e>_data.len then
						e=_data.len
					end
					repeat_send_response_by_point(node,1,e,0)
				else
					repeat_send_response_by_point(node,s,e,1)
				end
			end
		end
	else
		repeat_send_response_by_session(node,s_session,session_max)
		repeat_send_response_by_session(node,session_init,e_session)
	end
end

--by HW******
local function add_to_response_missing_map(start_s,end_s,node_name,c)
	for k=start_s,end_s do 
		response_missing_map[node_name][k]=0
		response_result_data_sz[node_name][k]=nil
		if c then
			local session=response_myS_to_s[node_name][k]
			
			if session then
				local co  = c.__thread[session]
				if co then
					c.__result[co]=nil
					c.__result_data[co]=nil
				end
			end
		end
	end

	--初始化wait_queue_data
	if not is_response_need_wait[node_name] then
		--start_s：起始包的session  cur_need：当前需要处理的session
		response_wait_queue_data[node_name]={start_s=start_s,cur_need=1}
		response_wait_queue[node_name]={}
	end

	is_response_need_wait[node_name]=true
	--请求重新发送
	-- print("请求重新发送response包 ",start_s,end_s)
	local request, new_session, padding = cluster.packpush(1, 3, skynet.pack({start_s=start_s,end_s=end_s}))
	node_channel[node_name]:equal_request(request, nil, padding)
end

local function add_to_response_wait_queue(node_name,session,msg)
	-- print("add_to_response_wait_queue ",node_name,session)
	response_missing_map[node_name][session]=nil
	local loc=0
	if session<response_wait_queue_data[node_name].start_s then
		loc=rp_session_max-response_wait_queue_data[node_name].start_s+1+session-rp_session_init+1
	else
		loc=session-response_wait_queue_data[node_name].start_s+1
	end
	response_wait_queue[node_name][loc]=msg
	--处理msg
	if loc==response_wait_queue_data[node_name].cur_need then

		local cur_max_loc
		if cur_max_response_session[node_name]<response_wait_queue_data[node_name].start_s then
			cur_max_loc=rp_session_max-response_wait_queue_data[node_name].start_s+1+cur_max_response_session[node_name]-rp_session_init+1
		else
			cur_max_loc=cur_max_response_session[node_name]-response_wait_queue_data[node_name].start_s+1
		end

		local wait_data=response_wait_queue[node_name]

		while true do
			if wait_data[loc] then
				if type(wait_data[loc])=="table" then
					node_channel[node_name]:dispatch_by_session_by_call(wait_data[loc].session, wait_data[loc].ok, wait_data[loc].data, wait_data[loc].padding)
				end
				if loc==cur_max_loc then
					is_response_need_wait[node_name]=false
					response_wait_queue_data[node_name]=nil
					response_wait_queue[node_name]=nil
					break
				end 
			else
				response_wait_queue_data[node_name].cur_need=loc
				break
			end
			loc=loc+1
		end
	end
end
local function deal_no_response_cache(node_name,start_s,start_e)
	for session=start_s,start_e do
		if response_missing_map[node_name][session] then
			add_to_response_wait_queue(node_name,session,true)
		end
	end
end
local function close_channel_socket(name)
	local c=node_channel[name]
	if c.__sock then
		local so = c.__sock
		c.__sock = false
		-- never raise error
		xpcall(socket.close,error_handle,so[1])
	end
end
local function read_response(sock,name)
	local ok,read_value=xpcall(sock.read,error_handle,sock,2)
	if not ok then
		close_channel_socket(name)
		return "socket error wait reconnect"
	end
	local sz = socket.header(read_value)
	local _ok,msg = xpcall(sock.read,error_handle,sock,sz)
	if not _ok then
		close_channel_socket(name)
		return "socket error wait reconnect"
	end
	local session, ok, data,my_session,padding=cluster.unpackresponse(msg)
	if my_session<50 then
		if my_session==8 then
			local msg=skynet.unpack(data)
			response_large_package_sz[name][msg.session]=msg.sz
			return "special_command"
		end
	else
		local _cur_max_response_session=cur_max_response_session[name]

		if  _cur_max_response_session then
			--padding==2为multi end结束标志
			if not padding or padding==2 then
				local msg_sz=response_large_package_sz[name][my_session]
				response_large_package_sz[name][my_session]=nil
				response_myS_to_s[name][my_session]=nil
				if padding==2 then
					--因为padding==2为multi end结束标志所有要置空
					padding=nil
					response_result_data_sz[name][my_session]=response_result_data_sz[name][my_session] or 0
					if data then
						response_result_data_sz[name][my_session]=response_result_data_sz[name][my_session]+string.len(data)
					end
					-- print("cd accpet sz",session,my_session,response_result_data_sz[name][my_session])
					if not msg_sz then
						-- print("cb 数据不合法111 ",session,my_session,response_result_data_sz[name][my_session])
						response_result_data_sz[name][my_session]=nil
						return "data error"
					end 
					msg_sz=response_result_data_sz[name][my_session]-msg_sz
					response_result_data_sz[name][my_session]=nil
					--数据不合法
					if msg_sz<0 or msg_sz>100 then
						-- print("cb 数据不合法222 ",session,my_session,msg_sz)
						return "data error"
					end
				end

				if my_session>_cur_max_response_session then
					--是否已经丢包 （新到的session-当前cur_max_session>1 且他们之间的差距不能太大（因为是sessionID是循环的））
					if my_session-_cur_max_response_session<loop_interval then 
						--cur_max_response_session
						cur_max_response_session[name]=my_session

						--添加到丢包列表
						if my_session-_cur_max_response_session>1 then
							--丢弃可能存在的缓存
							add_to_response_missing_map(_cur_max_response_session+1,my_session-1,name,node_channel[name])
						end 
						
						if is_response_need_wait[name] then
							add_to_response_wait_queue(name,my_session,{session=session, ok=ok, data=data,padding=padding,my_session=my_session})
							return "waiting"
						end
					--若大于1亿则是cur_max_response_session已经完成一轮重头开始，当前包为遗漏包
					else
						if response_missing_map[name][my_session] then
							add_to_response_wait_queue(name,my_session,{session=session, ok=ok, data=data,padding=padding,my_session=my_session})
							return "waiting"
						else
							--这个包已经被处理过了
							local co = node_channel[name].__thread[session]
							if co then
								print("消除response包已过期包缓存！！！！！",session)
								node_channel[name].__result_data[co]=nil
								response_result_data_sz[name][my_session]=nil
							end
							--返回一个找不到的session
							print("response包已过期")
							return "redundant"
						end

					end
				else
					--session已经重新循环的情况
					if _cur_max_response_session-my_session>loop_interval then
						--cur_max_response_session
						cur_max_response_session[name]=my_session
						--末端部分 添加到丢包列表
						if rp_session_max>_cur_max_response_session then
							--丢弃可能存在的缓存
							add_to_response_missing_map(_cur_max_response_session+1,rp_session_max,name,node_channel[name])
						end
						--前端部分 添加到丢包列表
						if my_session>rp_session_init then
							--丢弃可能存在的缓存
							add_to_response_missing_map(rp_session_init,my_session-1,name,node_channel[name])
						end  
						if is_response_need_wait[name] then
							add_to_response_wait_queue(name,my_session,{session=session, ok=ok, data=data,padding=padding,my_session=my_session})
							return "waiting"
						end
					else
						if response_missing_map[name][my_session] then 
							add_to_response_wait_queue(name,my_session,{session=session, ok=ok, data=data,padding=padding,my_session=my_session})
							return "waiting"
						else
							--这个包已经被处理过了
							local co = node_channel[name].__thread[session]
							if co then
								print("消除response包已过期包缓存！！！！！",session)
								node_channel[name].__result_data[co]=nil
								response_result_data_sz[name][my_session]=nil
							end
							print("response包已过期")
							return "redundant"
						end
					end
				end
			else
				response_myS_to_s[name][my_session]=session
				response_result_data_sz[name][my_session]=response_result_data_sz[name][my_session] or 0
				if data then
					response_result_data_sz[name][my_session]=response_result_data_sz[name][my_session]+string.len(data)
				end
			end
		end
		return session,ok,data,padding 
	end
end




local connecting = {}
local function open_channel(t, key)
	local ct = connecting[key]
	if ct then
		local co = coroutine.running()
		table.insert(ct, co)
		skynet.wait(co)
		return assert(ct.channel)
	end
	ct = {}
	connecting[key] = ct
	local address = node_address[key]
	if address == nil then
		local co = coroutine.running()
		assert(ct.namequery == nil)
		ct.namequery = co
		skynet.error("Wating for cluster node [".. key.."]")
		skynet.wait(co)
		address = node_address[key]
		assert(address ~= nil)
	end
	local succ, err, c
	if address then
		local host, port = string.match(address, "([^:]+):(.*)$")
		local connect_cb
		c = sc.channel {
			host = host,
			port = tonumber(port),
			response = function(sock) 
							return read_response(sock,key) 
						end,
			nodelay = true,
			--by hewei socket err不报错
			no_sock_err=no_sock_err,
			--by hw lyx--
			connect_succ_cb=function()
				connect_cb()
            end

            --by hw lyx--

        }
        --by hw lyx--
		connect_cb = function ()
							if is_open_strict_transfer~=1 then 
								return 
							end
							--comments in the head
							local request, new_session, padding = cluster.packpush(1, 1, skynet.pack({my_name=my_node_name,
																											cur_session=node_session[key] or session_init,
																											cur_rp_session=response_node_session[key] or rp_session_init,
																											heart_ser_adds=heart_ser_adds}))
							c:equal_request(request, nil, padding)
			end
		--by hw lyx--	
		succ, err = xpcall(c.connect,error_handle, c, true)
		if succ then
			t[key] = c
			ct.channel = c
		end
	else
		err = "cluster node [" .. key .. "] is down."
	end
	connecting[key] = nil
	for _, co in ipairs(ct) do
		skynet.wakeup(co)
	end
	assert(succ, err)
	return c
end

node_channel = setmetatable({}, { __index = open_channel })

local function loadconfig(tmp)
	if tmp == nil then
		tmp = {}
		if config_name then
			local f = assert(io.open(config_name))
			local source = f:read "*a"
			f:close()
			assert(load(source, "@"..config_name, "t", tmp))()
		end
	end
	for name,address in pairs(tmp) do
		assert(address == false or type(address) == "string")
		if node_address[name] ~= address then
			-- address changed
			if rawget(node_channel, name) then
				node_channel[name] = nil	-- reset connection
			end
			node_address[name] = address
		end
		local ct = connecting[name]
		if ct and ct.namequery then
			skynet.error(string.format("Cluster node [%s] resloved : %s", name, address))
			skynet.wakeup(ct.namequery)
		end
	end
end

function command.reload(source, config)
	loadconfig(config)
	skynet.ret(skynet.pack(nil))
end

function command.listen(source, addr, port)
	local gate = skynet.newservice("gate")
	if port == nil then
		local address = assert(node_address[addr], addr .. " is down")
		addr, port = string.match(address, "([^:]+):(.*)$")
	end
	skynet.call(gate, "lua", "open", { address = addr, port = port })
	skynet.ret(skynet.pack(nil))
end

--*****************
local function add_cache(node,cur_session,request,padding,sz,isPush)
	--[[
		request_cache_data[node]={
									--当前链长度
									len
									--free_point在哪条链上(0当前，1上一条链)
									free_point_loc
									--当前释放点
									free_point
									--当前释放点session
									free_point_session
									--上一条链的长度
									last_len
									--上一条链的数据
									last_request_cache_request
									last_request_cache_padding
									last_request_cache_sz
									last_request_cache_isPush
									last_request_cache_session
								}
	--]]
	request_cache_data[node].len=request_cache_data[node].len+1
	local len=request_cache_data[node].len
	request_cache_request[node][len]=request
	request_cache_padding[node][len]=padding
	request_cache_sz[node][len]		=sz
	request_cache_isPush[node][len]	=isPush
	request_cache_session[node][len]=cur_session
	if request_cache_data[node].len==1 and request_cache_data[node].loc==0 then
		request_cache_data[node].free_point=1
		request_cache_data[node].free_point_session=cur_session
	end

	-- print("add_cache ",request_cache_data[node].len,session)
end
local function free_cache(node,session)
	
	local _data=request_cache_data[node]
	if session>=_data.free_point_session and session-_data.free_point_session<loop_interval then
		local len=session-_data.free_point_session+1
		--在当前链上的情况
		if _data.free_point_loc==0 then
			_data.free_point=_data.free_point+len
			_data.free_point_session=_data.free_point_session+len
			--检测当前链条是否需要切换
			if _data.len>cache_max_len then
				if _data.free_point>_data.len then
					_data.len=0
					_data.free_point=1
					request_cache_request[node]={}
					request_cache_padding[node]={}
					request_cache_sz[node]={}
					request_cache_isPush[node]={}
					request_cache_session[node]={}
				else
					_data.last_len=_data.len
					_data.len=0
					_data.last_request_cache_request=request_cache_request[node]
					_data.last_request_cache_padding=request_cache_padding[node]
					_data.last_request_cache_sz		=request_cache_sz[node]
					_data.last_request_cache_isPush	=request_cache_isPush[node]
					_data.last_request_cache_session=request_cache_session[node]
					request_cache_request[node]={}
					request_cache_padding[node]={}
					request_cache_sz[node]={}
					request_cache_isPush[node]={}
					request_cache_session[node]={}
					_data.free_point_loc=1
				end
			end
		--不在当前链
		else
			if _data.free_point+len>_data.last_len then
				_data.free_point_loc=0
				_data.last_request_cache_request=nil
				_data.last_request_cache_padding=nil
				_data.last_request_cache_sz=nil
				_data.last_request_cache_isPush=nil
				_data.free_point=_data.free_point+len-_data.last_len
				_data.free_point_session=_data.free_point_session+len
				_data.last_len=0
			else
				_data.free_point=_data.free_point+len
				_data.free_point_session=_data.free_point_session+len
			end
		end
		if _data.free_point_session>session_max then
			_data.free_point_session=session_init+_data.free_point_session-session_max-1
		end
	else
		--是否是回绕
		if _data.free_point_session-session>loop_interval then
			free_cache(node,session_max)
			free_cache(node,session)
		end

	end	
end
local function repeat_send_by_point(node,s,e,loc)
	local data_r,data_isP,data_sz,data_p,data_s
	if loc==0 then
		data_r  =request_cache_request[node]
		data_isP=request_cache_isPush[node]
		data_sz =request_cache_sz[node]
		data_p  =request_cache_padding[node]
		data_s 	=request_cache_session[node]
	else
		data_r  =request_cache_data[node].last_request_cache_request
		data_isP=request_cache_data[node].last_request_cache_isPush
		data_sz =request_cache_data[node].last_request_cache_sz
		data_p  =request_cache_data[node].last_request_cache_padding
		data_s  =request_cache_data[node].last_request_cache_session
	end
	for point=s,e do
		local c=node_channel[node]
		if data_p[point] then 
			local _request, _, _padding = cluster.packpush(1, 7, skynet.pack({session=data_s[point],sz=data_sz[point]}))
			c:equal_request(_request, nil, _padding)
		end
		c:no_wait_request(data_r[point],data_isP[point],data_p[point])
	end

end
local function repeat_send_by_session(node,s_session,e_session)
	if e_session>=s_session then
		local _data=request_cache_data[node]
		--查找数据起点，终点
		local s,e
		if s_session>=_data.free_point_session and s_session-_data.free_point_session<loop_interval then
			s=_data.free_point+s_session-_data.free_point_session
		elseif _data.free_point_session-s_session>loop_interval then
			s=_data.free_point+session_max-_data.free_point_session+s_session-session_init+1
		--缓存可能已经不存在
		else
			local out_s,out_e
			out_s=s_session
			if s_session<_data.free_point_session then
				if e_session<_data.free_point_session then
					out_e=e_session
				elseif e_session>=_data.free_point_session then
					repeat_send_by_session(node,_data.free_point_session,e_session)
					out_e=_data.free_point_session-1
				end
			else
				out_e=e_session
			end	
			print(out_s.."--"..out_e.." request缓存已经不存在!!")
			local request, new_session, padding = cluster.packpush(1, 4, skynet.pack({s=out_s,e=out_e}))
			node_channel[node]:equal_request(request, nil, padding)
			return 
		end
		e=s+e_session-s_session

		--确定具体在缓存的位置
		--在当前链上的情况
		if _data.free_point_loc==0 then
			if e>_data.len then
				e=_data.len
			end
			repeat_send_by_point(node,s,e,0)
		else
			if s>_data.last_len then
				s=s-_data.last_len
				e=e-_data.last_len
				if e>_data.len then
					e=_data.len
				end
				repeat_send_by_point(node,s,e,0)
			else
				if e>_data.last_len then
					repeat_send_by_point(node,s,_data.last_len,1)
					e=e-_data.last_len
					if e>_data.len then
						e=_data.len
					end
					repeat_send_by_point(node,1,e,0)
				else
					repeat_send_by_point(node,s,e,1)
				end
			end
		end
	else
		repeat_send_by_session(node,s_session,session_max)
		repeat_send_by_session(node,session_init,e_session)
	end
end
--by HW******
local function add_to_missing_map(start_s,end_s,node_name,requests)
	for k=start_s,end_s do 
		request_missing_map[node_name][k]=0
		if requests  then
			requests[k]=nil
		end
	end

	--初始化wait_queue_data
	if not is_need_wait[node_name] then
		--start_s：起始包的session  cur_need：当前需要处理的session所在的位置（loc）
		wait_queue_data[node_name]={start_s=start_s,cur_need=1}
		wait_queue[node_name]={}
	end

	is_need_wait[node_name]=true

	--请求重新发送
	print("请求重新发送request包 ",start_s,end_s,cur_max_session[node_name])
	local request, new_session, padding = cluster.packpush(1, 2, skynet.pack({start_s=start_s,end_s=end_s}))
	node_channel[node_name]:equal_request(request, nil, padding)
end
local register_name = {}
local function deal_queue_msg(node_name,fd,session,msg,sz,addr,is_push)
	if not msg then
		local response_session=rp_session_init
		if node_name then 
			response_session=response_node_session[node_name] or rp_session_init
		end
		local response,new_response_session = cluster.packresponse(session,response_session, false, "Invalid large req")
		if node_name and response_cache[node_name] then
			response_node_session[node_name]=new_response_session 
			add_response_cache(node_name,response,response_session)
		end
		socket.write(fd, response)
		return
	end
	local ok, response
		if addr == 0 then
			local name = skynet.unpack(msg, sz)
			local addr = register_name[name]
			if addr then
				ok = true
				msg, sz = skynet.pack(addr)
			else
				ok = false
				msg = "name not found"
			end
		elseif is_push then
			skynet.rawsend(addr, "lua", msg, sz)
			return	-- no response
		else
			ok , msg, sz = xpcall(skynet.rawcall,error_handle, addr, "lua", msg, sz)
		end
		if ok then
			local response_session=rp_session_init,new_response_session
			if node_name then 
				response_session=response_node_session[node_name] or rp_session_init
			end 
			response,new_response_session = cluster.packresponse(session,response_session, true, msg, sz)
			if node_name and response_cache[node_name] then
				response_node_session[node_name]=new_response_session 
				add_response_cache(node_name,response,response_session,sz)
				if type(response) == "table" then
					-- print("cb send sz",sz,session,response_session)
					-- local _request, _, _padding = cluster.packpush(1, 8, skynet.pack({session=response_session,sz=sz}))
					-- node_channel[node_name]:equal_request(_request, nil, _padding)

					local _response,_ = cluster.packresponse(1,8, true, skynet.pack({session=response_session,sz=sz}))
					socket.write(fd, _response)
				end
			end
			-- if response_session<rp_session_init+26 or response_session%5~=0 then
			if type(response) == "table" then
				for _, v in ipairs(response) do
					if not socket.write(fd, v) then
						-- print("res  break")
						break
					end
				end
			else
				socket.write(fd, response)
			end
			-- end
		else
			local response_session=rp_session_init,new_response_session
			if node_name then 
				response_session=response_node_session[node_name] or rp_session_init
			end 
			response,new_response_session = cluster.packresponse(session,response_session, false, msg)
			if node_name and response_cache[node_name] then
				response_node_session[node_name]=new_response_session 
				add_response_cache(node_name,response,response_session)
			end
			socket.write(fd, response)
		end
end
local function add_to_wait_queue(node_name,session,msg)
	-- print("add_to_wait_queue ",node_name,session,msg)
	request_missing_map[node_name][session]=nil
	local loc=0
	if session<wait_queue_data[node_name].start_s then
		loc=session_max-wait_queue_data[node_name].start_s+1+session-session_init+1
	else
		loc=session-wait_queue_data[node_name].start_s+1
	end
	wait_queue[node_name][loc]=msg
	--处理msg
	if loc==wait_queue_data[node_name].cur_need then
		local cur_max_loc
		if cur_max_session[node_name]<wait_queue_data[node_name].start_s then
			cur_max_loc=session_max-wait_queue_data[node_name].start_s+1+cur_max_session[node_name]-session_init+1
		else
			cur_max_loc=cur_max_session[node_name]-wait_queue_data[node_name].start_s+1
		end
		local wait_data=wait_queue[node_name]
		while true do
			if wait_data[loc] then
				if type(wait_data[loc])=="table" then
					skynet.fork(deal_queue_msg,node_name,nodeName_to_fd[node_name],wait_data[loc].session,wait_data[loc].msg,wait_data[loc].sz,wait_data[loc].addr,wait_data[loc].is_push)
				end
				if loc==cur_max_loc then
					is_need_wait[node_name]=false
					wait_queue_data[node_name]=nil
					wait_queue[node_name]=nil
					break
				end 
			else
				wait_queue_data[node_name].cur_need=loc
				break
			end
			loc=loc+1
		end
	end
end
local function deal_no_request_cache(node_name,start_s,start_e)
	-- print("deal_no_request_cache ",node_name,start_s,start_e)
	for session=start_s,start_e do
		if request_missing_map[node_name][session] then
			add_to_wait_queue(node_name,session,true)
		end
	end
end
--汇报接受信息
local function report_accept_info()
	local safe_request=-1
	local safe_response=-1
	for node,_ in pairs(nodeName_to_fd) do
		--已经安全的request消息
		if is_need_wait[node] then
			safe_request=wait_queue_data[node].start_s+wait_queue_data[node].cur_need-2
			if safe_request<session_init then
				safe_request=session_max
			elseif safe_request>session_max then
				safe_request=safe_request-session_max+session_init-1
			end
		else
			safe_request=cur_max_session[node]
		end
		--已经安全的response消息
		if is_response_need_wait[node] then
			safe_response=response_wait_queue_data[node].start_s+response_wait_queue_data[node].cur_need-2
			if safe_response<rp_session_init then
				safe_response=rp_session_max
			elseif safe_response>rp_session_max then
				safe_response=safe_response-rp_session_max+rp_session_init-1
			end
		else
			safe_response=cur_max_response_session[node]
		end
		local request, new_session, padding = cluster.packpush(1, 6, skynet.pack({safe_request=safe_request,safe_response=safe_response}))
		node_channel[node]:equal_request(request, nil, padding)
	end

end
local large_request = {}
local function request_package_again(data,type)
	local send_list
	for _node,_set in pairs(data) do
		for _s,_t in pairs(_set) do
			_set[_s]=_set[_s]+1
			if _set[_s]>=request_package_again_time then
				_set[_s]=0
				--清除可能存在的缓存
				if type==2 then
					if nodeName_to_fd[_node] and large_request[nodeName_to_fd[_node]] then
						large_request[nodeName_to_fd[_node]][_s]=nil
					end
				else
					response_result_data_sz[node_name][_s]=nil
					local session=response_myS_to_s[_node][_s]
					if session then
						local co = node_channel[_node].__thread[session]
						if co then
							c.__result[co]=nil
							c.__result_data[co]=nil
						end
					end
				end

				--加入发送队列
				send_list=send_list or {}
				send_list[#send_list+1]=_s
			end
		end
		--排序 合并
		if send_list then
			table.sort(send_list)
			local start_s,end_s
			for _,_s in ipairs(send_list) do
				if not start_s then
					start_s=_s
					end_s=_s
				elseif _s==start_s+1 then
					end_s=_s
				else
					--发送
					--请求重新发送
					print("send agine",type,start_s,end_s)
					local request, new_session, padding = cluster.packpush(1, type, skynet.pack({start_s=start_s,end_s=end_s}))
					node_channel[_node]:equal_request(request, nil, padding)

					start_s=_s
					end_s=_s
				end
			end
			print("send agine",type,start_s,end_s)
			local request, new_session, padding = cluster.packpush(1, type, skynet.pack({start_s=start_s,end_s=end_s}))
			node_channel[_node]:equal_request(request, nil, padding)
			
		end
	end
end


local function send_request(source, node, addr, msg, sz)
	local session = node_session[node] or session_init
	-- msg is a local pointer, cluster.packrequest will free it
	if not addr or addr=="" then
		print("send_request addr error!!",node)
		print(skynet.unpack(msg, sz))
	end
	local request, new_session, padding = cluster.packrequest(addr, session, msg, sz)
	node_session[node] = new_session
	-- --by HW *****
	if request_cache_request[node] then 
		add_cache(node,session,request,padding,sz,session)
	end
	-- if session>session_init+65 and session%5==0 then
	-- 	local c = node_channel[node]

	-- 	return c:request(request, session, padding,true)
	-- else

	-- node_channel[node] may yield or throw error
	local c = node_channel[node]

	if padding and request_cache_request[node] then 
		-- print("send sz ",sz,session)
		local _request, _, _padding = cluster.packpush(1, 7, skynet.pack({session=session,sz=sz}))
		c:equal_request(_request, nil, _padding)
	end

	return c:equal_request(request, session, padding)

	-- end
end

-- by lyx
local function concat_values(_sep,...)
	local _t = table.pack(...)
	local _ret = {}
	for i=1,_t.n do
		_ret[i] = tostring(_t[i])
	end

	return table.concat(_ret,_sep or "\t")
end

function command.req(...)
	local ok, msg, sz = xpcall(send_request,error_handle, ...)
	if ok then
		if type(msg) == "table" then
			-- local m=cluster.concat(msg)
			--print("req ",string.len(m))
			-- print("xxx",cluster.concat(msg))
			skynet.ret(cluster.concat(msg))
		else
			-- print("req ",string.len(msg))
			-- print("zzz",msg)
			skynet.ret(msg)
		end
	else
		skynet.error(msg)
		skynet.response()(false)
	end
end
 

function command.push(source, node, addr, msg, sz)
	local session = node_session[node] or session_init
	local request, new_session, padding = cluster.packpush(addr, session, msg, sz)
	-- --by HW *****
	node_session[node] = new_session
	if request_cache_request[node] then 
		add_cache(node,session,request,padding,sz)
	end
	-- node_channel[node] may yield or throw error

	-- if session>session_init+65 and session%5==0 then/

	local c = node_channel[node]

	if padding and request_cache_request[node] then 
		-- print("send sz ",sz,session)
		local _request, _, _padding = cluster.packpush(1, 7, skynet.pack({session=session,sz=sz}))
		c:equal_request(_request, nil, _padding)
	end

	c:equal_request(request, nil, padding)

	-- end

	-- notice: push may fail where the channel is disconnected or broken.
end

local proxy = {}

function command.proxy(source, node, name)
	local fullname = node .. "." .. name
	if proxy[fullname] == nil then
		proxy[fullname] = skynet.newservice("clusterproxy", node, name)
	end
	skynet.ret(skynet.pack(proxy[fullname]))
end



function command.register(source, name, addr)
	assert(register_name[name] == nil)
	addr = addr or source
	local old_name = register_name[addr]
	if old_name then
		register_name[old_name] = nil
	end
	register_name[addr] = name
	register_name[name] = addr
	skynet.ret(nil)
	skynet.error(string.format("Register [%s] :%08x", name, addr))
end


-- --by HW
function command.socket(source, subcmd, fd, msg)
	if subcmd == "data" then
		local sz
		local addr, session, msg, padding, is_push = cluster.unpackrequest(msg)
		-- --by HW
		local node_name=fd_to_nodeName[fd]
		if session<50 and session>0 then
			msg=skynet.unpack(msg)
			if session==6 then
				if msg.safe_request>0 then
					free_cache(node_name,msg.safe_request)
				end
				if msg.safe_response>0 then
					-- print("safe_response ",msg.safe_response)
					free_response_cache(node_name,msg.safe_response)
				end
			elseif session==7 then
				request_large_package_sz[node_name][msg.session]=msg.sz
            elseif session==2 then
            	-- print("从新发request包 ",msg.start_s,msg.end_s)	
            	repeat_send_by_session(node_name,msg.start_s,msg.end_s)
            elseif session==3 then
            	-- print("从新发response包  ",msg.start_s,msg.end_s)	
            	repeat_send_response_by_session(node_name,msg.start_s,msg.end_s)
            elseif session==4 then
            	-- print("request包 缓存不存在",msg.s,msg.e)	
            	deal_no_request_cache(node_name,msg.s,msg.e)
            elseif session==5 then	
            	-- print("response包 缓存不存在",msg.s,msg.e)	
            	deal_no_response_cache(node_name,msg.s,msg.e)
            --session_init	
            elseif session==1 then 
            	if is_open_strict_transfer~=1 then 
            		return 
            	end
            	node_name=msg.my_name
            	print("通知 我的名字是：",node_name,msg.cur_session,fd)

            	if nodeName_to_fd[node_name] and fd_to_nodeName[nodeName_to_fd[node_name]]==node_name then
            		fd_to_nodeChannel[nodeName_to_fd[node_name]]=nil
            		fd_to_nodeName[nodeName_to_fd[node_name]]=nil
            	end

            	fd_to_nodeName[fd]=node_name
            	fd_to_nodeChannel[fd]=node_channel[node_name]
            	nodeName_to_fd[node_name]=fd
            	--request
            	local cur_session_init=node_session[node_name] or session_init

            	cluter_heart_map[node_name]=msg.heart_ser_adds

            	cur_max_session[node_name]	   	 	=cur_max_session[node_name] or session_init-1
            	request_large_package_sz[node_name] =request_large_package_sz[node_name] or {}
            	request_missing_map[node_name]   	=request_missing_map[node_name] or {}
            	request_cache_request[node_name] 	=request_cache_request[node_name] or {}
				request_cache_padding[node_name] 	=request_cache_padding[node_name] or {}
				request_cache_sz[node_name]		 	=request_cache_sz[node_name] or {}
				request_cache_isPush[node_name]  	=request_cache_isPush[node_name] or {}
				request_cache_session[node_name]	=request_cache_session[node_name] or {}
				is_need_wait[node_name]		     	=is_need_wait[node_name] or false
				request_cache_data[node_name]	 	=request_cache_data[node_name] or {
													--当前链长度
													len=0,
													--free_point在哪条链上(0当前，1上一条链)
													free_point_loc=0,
													--当前释放点
													free_point=1,
													--当前释放点session
													free_point_session=cur_session_init,
												}
				--response								
				cur_max_response_session[node_name] =cur_max_response_session[node_name] or rp_session_init-1
				response_myS_to_s[node_name]		=response_myS_to_s[node_name] or {}
				response_large_package_sz[node_name]=response_large_package_sz[node_name] or {}
				response_result_data_sz[node_name]	=response_result_data_sz[node_name] or {}
				response_missing_map[node_name]	  	=response_missing_map[node_name] or {}
				response_cache[node_name]			=response_cache[node_name] or {}
				response_cache_session[node_name] 	=response_cache_session[node_name] or {}
				response_cache_sz[node_name]		=response_cache_sz[node_name] or {}
				is_response_need_wait[node_name]	=is_response_need_wait[node_name] or false
				response_node_session[node_name]	=response_node_session[node_name] or rp_session_init
				response_cache_data[node_name]	 	=response_cache_data[node_name] or {
														--当前链长度
														len=0,
														--free_point在哪条链上(0当前，1上一条链)
														free_point_loc=0,
														--当前释放点
														free_point=1,
														--当前释放点session
														free_point_session=response_node_session[node_name],
													}												
		 	end
		 	return 
		end
		if padding and padding~=2 then
			local requests = large_request[fd]
			if requests == nil then
				requests = {}
				large_request[fd] = requests
			end
			local req = requests[session] or { addr = addr , is_push = is_push }
			requests[session] = req
			table.insert(req, msg)
			return
		else
			local requests = large_request[fd]
			if requests then
				local req = requests[session]
				if req then
					requests[session] = nil
					table.insert(req, msg)
					msg,sz = cluster.concat(req)
					addr = req.addr
					is_push = req.is_push 
				end
			end
			--有名字缓存且是完整包
			if fd_to_nodeChannel[fd] then
				--超大包完整性检测
				if padding==2 then
					-- print("accpet sz",sz,session)
					if not sz or not request_large_package_sz[node_name][session] or sz~=request_large_package_sz[node_name][session] then
						print("不完整的超大request数据包",session)
						return
					else
						request_large_package_sz[node_name][session]=nil 
					end
				end
				local _cur_max_session=cur_max_session[node_name]
				if session>_cur_max_session then
					--是否已经丢包 （新到的session-当前cur_max_session>1 且他们之间的差距不能太大（因为是sessionID是循环的））
					if session-_cur_max_session<loop_interval then 
						--刷新cur_max_session
						cur_max_session[node_name]=session
						--添加到丢包列表，并请求重新发送
						if session-_cur_max_session>1 then
							--large_request丢弃可能存在的缓存
							add_to_missing_map(_cur_max_session+1,session-1,node_name,large_request[fd])
						end
						--若前面有丢包发生，将包加入等待列表
						if is_need_wait[node_name] then
							add_to_wait_queue(node_name,session,{msg=msg,sz=sz,addr=addr,is_push=is_push,session=session})
							return
						end
					--若大于1亿则是cur_max_session已经完成一轮重头开始，当前包为遗漏包
					else
						if request_missing_map[node_name][session] then 
							add_to_wait_queue(node_name,session,{msg=msg,sz=sz,addr=addr,is_push=is_push,session=session})
							return
						else
							--这个包已经被处理过了
							local requests = large_request[fd]
							if requests  then
								requests[session]=nil
							end
							print("本包已经过期",session)
							return 
						end

					end
				else
					--session已经重新循环的情况
					if _cur_max_session-session>loop_interval then
						--刷新cur_max_session
						cur_max_session[node_name]=session
						--末端部分 添加到丢包列表
						if session_max>_cur_max_session then
							add_to_missing_map(_cur_max_session+1,session_max,node_name,large_request[fd])
						end
						--前端部分 添加到丢包列表
						if session>session_init then
							--丢弃可能存在的缓存
							add_to_missing_map(session_init,session-1,node_name,large_request[fd])
						end  
						--若前面有丢包发生，将包加入等待列表
						if is_need_wait[node_name] then
							add_to_wait_queue(node_name,session,{msg=msg,sz=sz,addr=addr,is_push=is_push,session=session})
							return 
						end
					else
						if request_missing_map[node_name][session] then 
							add_to_wait_queue(node_name,session,{msg=msg,sz=sz,addr=addr,is_push=is_push,session=session})
							return
						else
							--这个包已经被处理过了
							local requests = large_request[fd]
							if requests  then
								requests[session]=nil
							end
							print("本包已经过期",session)
							return 
						end
					end
				end
			end
			if not msg then
				local response_session=rp_session_init
				if node_name then 
					response_session=response_node_session[node_name] or rp_session_init
				end
				local response,new_response_session = cluster.packresponse(session,response_session, false, "Invalid large req")
				if node_name and response_cache[node_name] then
					response_node_session[node_name]=new_response_session 
					add_response_cache(node_name,response,response_session)
				end
				socket.write(fd, response)
				return
			end
		end
		local ok, response
		if addr == 0 then
			local name = skynet.unpack(msg, sz)
			local addr = register_name[name]
			if addr then
				ok = true
				msg, sz = skynet.pack(addr)
			else
				ok = false
				msg = "name not found"
			end
		elseif is_push then
			skynet.rawsend(addr, "lua", msg, sz)
			return	-- no response
		else
			ok , msg, sz = xpcall(skynet.rawcall,error_handle, addr, "lua", msg, sz)
		end
		if ok then
			local response_session=rp_session_init,new_response_session
			if node_name then 
				response_session=response_node_session[node_name] or rp_session_init
			end 
			response,new_response_session = cluster.packresponse(session,response_session, true, msg, sz)
			if node_name and response_cache[node_name] then
				response_node_session[node_name]=new_response_session 
				add_response_cache(node_name,response,response_session,sz)
				if type(response) == "table" then
					-- print("cb send sz",sz,session,response_session)
					-- local _request, _, _padding = cluster.packpush(1, 8, skynet.pack({session=response_session,sz=sz}))
					-- node_channel[node_name]:equal_request(_request, nil, _padding)

					local _response,_ = cluster.packresponse(1,8, true, skynet.pack({session=response_session,sz=sz}))
					socket.write(fd, _response)
				end
			end
			-- print("response_session ",response_session)
			-- if response_session<rp_session_init+26 or response_session%5~=0 then

			if type(response) == "table" then
				for _, v in ipairs(response) do
					if not socket.write(fd, v) then
						-- print("res  break")
						break
					end
				end
			else
				socket.write(fd, response)
			end
			-- end
		else
			local response_session=rp_session_init,new_response_session
			if node_name then 
				response_session=response_node_session[node_name] or rp_session_init
			end 
			--response,new_response_session = cluster.packresponse(session,response_session, false, msg)
			-- by lyx
			local _errstr = string.format("clusterd call service :%08x failed:%s",addr or 0,tostring(msg))
			print(_errstr)
			response,new_response_session = cluster.packresponse(session,response_session, false,_errstr)

			if node_name and response_cache[node_name] then
				response_node_session[node_name]=new_response_session 
				add_response_cache(node_name,response,response_session)
			end
			socket.write(fd, response)
		end
	elseif subcmd == "open" then
		skynet.error(string.format("socket accept from %s", msg))
		skynet.call(source, "lua", "accept", fd)
	else
		large_request[fd] = nil
		skynet.error(string.format("socket %s %d %s", subcmd, fd, msg or ""))
	end
end

if is_open_strict_transfer==1 then
 	skynet.fork(function ()
 		while true do
 			skynet.sleep(gc_interval)
 			collectgarbage "collect"
 		end
 	end)
 	skynet.fork(function ()
 		while true do
 			skynet.sleep(report_accept_info_interval)
 			report_accept_info()
 		end
 	end)
 	skynet.fork(function ()
 		while true do
 			skynet.sleep(request_package_again_interval)
 			request_package_again(request_missing_map,2)
 			request_package_again(response_missing_map,3)
 		end
 	end)
end

skynet.start(function()
	loadconfig()
	skynet.dispatch("lua", function(session , source, cmd, ...)
		local f = assert(command[cmd])
		f(source, ...)
	end)
end)
