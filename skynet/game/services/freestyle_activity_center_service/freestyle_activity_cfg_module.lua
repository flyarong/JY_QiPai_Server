local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "printfunc"


local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECT = {}

local switch_week_time = 0

local one_config={}
local two_config={}

-- 获取下一次切换的时间
local function update_next_switch_time()
	
	local time=os.date("*t")

	local cd = time.wday-1
	if cd < 1 then
		cd = 7
	end

	local ct = 7*24*3600 - ((cd-1)*24*3600 + time.hour*3600 + time.min*60 + time.sec)

	switch_week_time = os.time() + ct
end


local function load_config(_raw_config,t)

	local raw_config = basefunc.deepcopy(_raw_config)

	local config = {}
	for i,d in ipairs(raw_config.config) do
		config[d.config_id] = d
		d.no = nil
		d.config_id = nil
	end

	local cfg = {}

	for i,d in ipairs(raw_config.main) do
		
		local c = cfg[d.game_id] or {}
		cfg[d.game_id] = c

		for i,v in ipairs(d.config_id) do
			if config[v] then
				c[#c+1]=config[v]
			else
				print("error!!---- load_config,no config for index")
			end
		end

	end

	if t == 1 then
		one_config = cfg

		if not basefunc.is_double_week() then
			DATA.activity_config = one_config
			PUBLIC.update_config()
		end

	elseif t == 2 then
		two_config = cfg

		if basefunc.is_double_week() then
			DATA.activity_config = two_config
			PUBLIC.update_config()
		end

	end

	-- dump(basefunc.tostring(one_config),"one_config+++++++++++")
	-- dump(basefunc.tostring(two_config),"two_config+++++++++++")

end


local function load_config_one(_raw_config)
	load_config(_raw_config,1)
end

local function load_config_two(_raw_config)
	load_config(_raw_config,2)
end



-- 周一0点 切换一下单双周配置
function PROTECT.update(dt)
	
	if os.time() > switch_week_time then
		
		update_next_switch_time()

		if basefunc.is_double_week() then
			DATA.activity_config = two_config
		else
			DATA.activity_config = one_config
		end

		PUBLIC.update_config()

	end

end



function PROTECT.init()

	nodefunc.query_global_config("free_activity_one_config_server",load_config_one)
	nodefunc.query_global_config("free_activity_two_config_server",load_config_two)

	update_next_switch_time()

end

return PROTECT