--
-- Author: hw
-- Date: 2018/5/17
-- 说明：广播服务
--[[
	启动说明：
	此服务只会启动一个
	他主要操作配置的更新和向所有节点广播信息

]]

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local broadcast_config = require "broadcast_config"
local broadcast_content = require "broadcast_center_service.broadcast_content"
require "printfunc"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA



local update_timer

--当前时间刻度id-零点的刻度是60*24
local cur_time_id = 0

--结束时间刻度id-凌晨3点
local end_time_id = 60*3

--结束时间正点数 凌晨3点
local end_time_point = 3

--时间map表 1天为一轮 每天凌晨3点和启动的时候更新
--配置变化的时候全部清除重新载入
local time_func_map

local load_time_func_map


--[[固定格式广播 参见 broadcast_content
]]
function CMD.fixed_broadcast(type,...)

	if not BROADCAST_CONTENT[type] then
		print("error not BROADCAST_CONTENT "..type)
		return 1001
	end

	local bcmsg = {
			type=1,
			format_type=1,
			content=string.format(BROADCAST_CONTENT[type],...),
		}

	skynet.send(DATA.service_config.broadcast_svr
				,"lua"
				,"broadcast"
				,1
				,bcmsg)
	return 0
end


function CMD.broadcast(...)

	skynet.send(DATA.service_config.broadcast_svr
				,"lua"
				,"broadcast"
				,...)

end


--外部更新配置
function CMD.external_refresh_config(config)
	if config and type(config)~="table" then
		return 1001
	end

	--本地文件重新载入
	if not config then
		broadcast_config = base.reload_config("broadcast_config")
	end

	return load_time_func_map(config)

end


local function chk_config(config)
	for i,c in ipairs(config) do

		if type(c.id)~="number"
			or type(c.interval)~="number"
			or type(c.start_time)~="number"
			or type(c.content)~="string"
			or type(c.end_time)~="number"
			or type(c.channel)~="number"
					then
				return false
		end

	end

	return true

end

--只载入1天的刻度
load_time_func_map = function(config)
	
	if config then
		local len = #broadcast_config.config+1
		broadcast_config.config[len]=config
	end
	config = broadcast_config.config
	
	if not chk_config(config) then
		return 1001
	end
	
	local h = tonumber(os.date("%H"))
	local s = tonumber(os.date("%M"))
	cur_time_id = h*60 + s

	local cur_time = os.time()
	local cur_date = tonumber(os.date("%Y%m%d"))

	time_func_map={}
	for i,c in ipairs(config) do
		
		local start_date = tonumber(os.date("%Y%m%d",c.start_time))
		local end_date = tonumber(os.date("%Y%m%d",c.end_time))

		--[[
			从现在到晚上12:00
		]]

		if (start_date <= cur_date)
			and(c.end_time>cur_time or c.end_time<0)
			and c.interval > 0 then

			local _start_time_id
			--今天的起点
			if start_date < cur_date then
				_start_time_id = 0
			else
				local h = tonumber(os.date("%H",c.start_time))
				local s = tonumber(os.date("%M",c.start_time))
				_start_time_id = h*60 + s
				if c.start_time < 1 then
					_start_time_id = cur_time_id
				end
			end
			
			_start_time_id = math.max(_start_time_id,cur_time_id)

			local _end_time_id
			if end_date == cur_date then
				local h = tonumber(os.date("%H",c.end_time))
				local s = tonumber(os.date("%M",c.end_time))
				_end_time_id = h*60 + s
				if c.end_time < 1 then
					_end_time_id = 24*60
				end
			else
				_end_time_id = 24*60
			end
			-- print("-************---------1----_start_time_id:".._start_time_id)
			-- print("-************---------1----_end_time_id:".._end_time_id)
			for s_i=_start_time_id,_end_time_id,c.interval do
				
				local fm = time_func_map[s_i] or {}
				time_func_map[s_i]=fm
				local len = #fm+1
				fm[len]=
				function()

						CMD.broadcast(c.channel
										,{
										--广播类型 1系统广播 2 其他广播
										type=1,
										--广播消息格式类型 1 纯文本 其他指定格式
										format_type=1,
										--内容
										content=c.content,
										})
						
						-- print("*****BROAD-CAST****",c.content)
				end

			end

		end

		--[[
			从晚上12:00到明天3:00 end_time_point
		]]
		local next_time = cur_time+basefunc.get_diff_target_time(0)
		local next_date = tonumber(os.date("%Y%m%d",os.time()+24*3600))

		if (c.start_time < next_time+end_time_id*60)
			and(c.end_time>next_time or c.end_time<0)
			and c.interval > 0 then

			--明天天的起点
			local _start_time_id
			if (start_date < next_date) then
				_start_time_id = 0
			else
				local h = tonumber(os.date("%H",c.start_time))
				local s = tonumber(os.date("%M",c.start_time))
				_start_time_id = h*60 + s
				if c.start_time < 1 then
					_start_time_id = cur_time_id
				end
			end
			
			local _end_time_id
			if (end_date > next_date) then
				_end_time_id = end_time_id
			else
				local h = tonumber(os.date("%H",c.end_time))
				local s = tonumber(os.date("%M",c.end_time))
				_end_time_id = h*60 + s
				if c.end_time < 1 then
					_end_time_id = end_time_id
				end
			end
			-- print("-************---------2----_start_time_id:".._start_time_id)
			-- print("-************---------2----_end_time_id:".._end_time_id)
		
			for s_i=_start_time_id,_end_time_id,c.interval do
				
				local fm = time_func_map[s_i] or {}
				time_func_map[s_i]=fm
				local len = #fm+1
				fm[len]=
				function()
						CMD.broadcast(c.channel
										,{
										--广播类型 1系统广播 2 其他广播
										type=1,
										--广播消息格式类型 1 纯文本 其他指定格式
										format_type=1,
										--内容
										content=c.content,
										})
						-- print("*****BROAD-CAST****",c.content)
				end

			end

		end
	
	end

	-- dump(time_func_map)
	return 0
end

local function exec_time_func(time_id)
	if not time_func_map then return end
	local list = time_func_map[time_id]
	if list then
		for i,func in ipairs(list) do
			func()
		end
	end
end

local function update()

	cur_time_id=cur_time_id+1
	if cur_time_id > 60*24 then
		cur_time_id = 1
	end

	exec_time_func(cur_time_id)

	if cur_time_id == end_time_id then
		load_time_func_map()
	end

end


local function init_update_timer()
	
	local next_sec = 60-tonumber(os.date("%S"))
	skynet.timeout(next_sec*100,
		function()
			update()
			update_timer=skynet.timer(60,update)
		end
	)

end


function CMD.start(_service_config)
	DATA.service_config = _service_config

	load_time_func_map()

	init_update_timer()

end

-- 启动服务
base.start_service()