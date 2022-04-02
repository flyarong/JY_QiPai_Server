--
-- Author: lyx
-- Date: 2018/3/13
-- Time: 19:39
-- 说明：网关的相关处理函数
--

local skynet = require "skynet_plus"
local netpack = require "skynet.netpack"
local gateserver = require "snax.gateserver"
local basefunc = require "basefunc"
require "printfunc"

-- 等待中的链接
local wait_connects = basefunc.queue.new()

-- fd -> {agent , addr,fd,status}
-- status : "wait" ,"open", "closing"
local connections = {}

-- agent -> fd_count
local agents = {}

-- 空闲 agent ： agent -> true
local free_agents = {}

local max = math.max

-- 数量
local agent_count = 0
local fd_count = 0

local handle = {}

local now_time = os.time()

-- agent 唯一 id
local _last_agent_id = 0
local _agent_prefix = nil
local function gen_agent_id()

	if not _agent_prefix then
		_agent_prefix = handle.service_name .. "_agent_"
	end

	_last_agent_id = _last_agent_id + 1
	return _agent_prefix .. tostring(_last_agent_id)
end


local DEFAULT_MAX_CLIENT = 5000
local DEFAULT_MAX_CONN_WAIT = 500
local DEFAULT_MAX_PER_AGENT = 300
local DEFAULT_MAX_AGENT_CREATE = 2

local DEFAULT_MAX_ACCEPT_CYCLE = 20

local DEFAULT_CONN_STAT_INTERVAL = 10

-- 最大连接数
local max_client

-- 连接队列中的最大等待数
local max_connect_wait

-- 每个 agent 最大连接数
local max_per_agent

-- 每秒创建 agent 数量
local max_agent_create

-- 每周期（ 1/10 秒）接受的连接数
local max_accept_cycle

-- 输出统计数据时间间隔
local conn_stat_interval


-- 连接数超过
local conn_count_max_err = false

local conn_count_not_free = false

local conn_queue_max_err = false


local function load_config()

	max_client = tonumber(skynet.getcfg("gate_maxclient") or DEFAULT_MAX_CLIENT)
	max_connect_wait = tonumber(skynet.getcfg("max_connect_wait") or DEFAULT_MAX_CONN_WAIT)
	max_accept_cycle = tonumber(skynet.getcfg("max_accept_cycle") or DEFAULT_MAX_ACCEPT_CYCLE)
	max_agent_create = tonumber(skynet.getcfg("max_agent_create") or DEFAULT_MAX_AGENT_CREATE)
	conn_stat_interval = tonumber(skynet.getcfg("conn_stat_interval") or DEFAULT_CONN_STAT_INTERVAL)

	local _new_max_per_agent = tonumber(skynet.getcfg("max_per_agent") or DEFAULT_MAX_PER_AGENT)

	-- 重新计算空闲 agent
	if max_per_agent ~= _new_max_per_agent then
		max_per_agent = _new_max_per_agent

		for _agent,_count in pairs(agents) do
			if _count < max_per_agent then
				free_agents[_agent] = true
			else
				free_agents[_agent] = nil
			end
		end
	end
end

-- 已创建的 agent 中空闲的 连接
local function get_free_agent_fd_count()
	return agent_count * max_per_agent - fd_count
end

-- 已创建的 agent 中支持的总连接数
local function get_agent_fd_count()
	return agent_count * max_per_agent
end

-- 按时段统计数据
local stat_conn_request_count = 0
local stat_conn_wait_count = 0
local stat_conn_accept_count = 0
local stat_conn_wait_time = 0

local function print_connect_info()

	-- 调试模式不打印，避免干扰调试信息
	if skynet.getcfg("debug") then
		return
	end
	
	if conn_count_max_err then
		conn_count_max_err = false
		print(string.format("error:too many ,max connection count is %d !",max_client))
	end

	if conn_count_not_free then
		conn_count_not_free = false
		print(string.format("error:not found free connect ,cur count:%d !",fd_count))
	end

	if conn_queue_max_err then
		conn_queue_max_err = false
		print("error:wait connect too many !")
	end

	print("gate connect info:")
	print("\tconnected count:" .. fd_count)
	print("\twait count:" .. wait_connects:size())
	print("\tfree count:" .. get_free_agent_fd_count())
	print("\tagent count:" .. agent_count)
	print("\tstat request:" .. (stat_conn_request_count/conn_stat_interval))
	print("\tstat wait:" .. (stat_conn_wait_count/conn_stat_interval))
	print("\tstat accept:" .. (stat_conn_accept_count/conn_stat_interval))
	print("\tstat wait time:" .. (stat_conn_wait_time))

	stat_conn_request_count = 0
	stat_conn_wait_count = 0
	stat_conn_accept_count = 0	
	stat_conn_wait_time = 0
end


local function create_one_agent()

	local agent = skynet.newservice("gate_service/gate_agent")
	skynet.send(agent, "lua", "start" ,skynet.self(),handle.service_config)
	agents[agent] = 0
	free_agents[agent] = true

	agent_count = agent_count + 1
end

local function accept()

	if wait_connects:empty() then
		return
	end

	local fd = wait_connects:front()

	local conn = connections[fd]

	-- 已经断开
	if not conn or "waiting" ~= conn.status then
		return
	end

	local agent = next(free_agents)

	-- 继续等待
	if not agent then
		return
	end

	wait_connects:pop_front()

	agents[agent] = agents[agent] + 1

	if agents[agent] >= max_per_agent then
		free_agents[agent] = nil
	end

	conn.agent = agent
	conn.status = "open"

	print(string.format("socket fd connect : %d",fd))

	stat_conn_accept_count = stat_conn_accept_count + 1
	stat_conn_wait_time = max(now_time-conn.time,stat_conn_wait_time)

	skynet.send(agent,"lua","connect",fd,conn.addr)
	gateserver.openclient(fd)

end 

function handle.start()

	load_config()

	skynet.timer(conn_stat_interval,print_connect_info)

	-- 创建 agent
	skynet.timer(0.5,function()

		now_time = os.time()

		-- 小于总连接数，并且 空闲数少于 agent 容量的一半
		if get_agent_fd_count() < max_client and get_free_agent_fd_count() <= max_per_agent/2 then
			for i=1,max_agent_create do
				create_one_agent()
			end
		end
	end)

	-- 在协程中接受链接
	skynet.timer(0.1,function ()
		for i=1,max_accept_cycle do
			accept()
		end
	end)

	-- 定时刷新配置
	skynet.timer(5,load_config)

end

function handle.message(fd, msg, sz)
    local info = connections[fd]
    if info and info.agent then

		skynet.send(info.agent,"lua","request",fd,msg,sz)
    else
        print(string.format("error: drop message from fd (%d), msg=%s", fd, netpack.tostring(msg,sz)))
	end
end

local function erase_fd(fd)
	local info = connections[fd]
	if not info then
		return
	end

	info.status = "closing"

	fd_count = fd_count - 1
	connections[fd] = nil

	if info.agent then
		skynet.send(info.agent,"lua","disconnect",fd)

		if agents[info.agent] then
			agents[info.agent] = agents[info.agent] - 1

			if agents[info.agent] < max_per_agent then
				free_agents[info.agent] = true
			end
		else
			print(string.format("agent %d is not exist, when fd %d close ! ",info.agent, fd))
		end
	else
		print(string.format("fd %d has not agent when close ! ", fd))
	end
end

function handle.connect(fd, addr)

	stat_conn_request_count = stat_conn_request_count + 1

	if fd_count >= max_client then
		conn_count_max_err = true

		erase_fd(fd)
		gateserver.closeclient(fd)

		return
	end

	if wait_connects:size() > max_connect_wait then
		conn_queue_max_err = true

		erase_fd(fd)

		gateserver.closeclient(fd)
		return
	end

	stat_conn_wait_count = stat_conn_wait_count + 1

    if connections[fd] then

		print(string.format("gate error:addr %s, fd %d , status '%s'! ", addr, fd,tostring(connections[fd].status)))

		-- 此情况可能已出错，必须关闭新来的冲突 fd ，避免 数据混乱
		gateserver.closeclient(fd)

		return
    end

    print("socket wait conncect:",fd,addr)

    connections[fd] =  {
		fd = fd,
		addr = addr,
		status = "waiting",
		time = now_time,
		agent = nil,
	}	

	fd_count = fd_count + 1

	wait_connects:push_back(fd)

end


function handle.disconnect(fd)
	print(string.format("socket  disconnect, fd: %d! ", fd))
	erase_fd(fd)
end

function handle.error(fd, msg)
	print(string.format("socket error:%s,fd %d ",msg, fd))
	erase_fd(fd)
	gateserver.closeclient(fd)
end

function handle.warning(fd, size)
	print(string.format("socket warning:fd %d,size %d ", fd,size))
end

return handle