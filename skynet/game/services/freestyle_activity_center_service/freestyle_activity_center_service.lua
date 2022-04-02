
--
-- Author: hw
-- Date: 2019/1/4
-- Time: 
-- 说明：
-- freestyle_activity_center_service
local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "printfunc"

local data_module = require "freestyle_activity_center_service.freestyle_activity_center_data"
local cfg_module = require "freestyle_activity_center_service.freestyle_activity_cfg_module"


local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA


local UPDATE_INTERVAL = 1

-- 下一个活动的时间
local next_activity_time = 0

-- 活动配置 配置模块自动更新
DATA.activity_config = nil

-- 活动服务
DATA.activity_service = {}

DATA.freestyle_game_name = {}

-- 一个游戏中不能同时存在两个相同的活动(不同时间可以存在两个相同的活动)
local function gen_activity_service_id(_game_id,_idx,_activity_id)
	return "freestyle_activity_service_".._game_id.."_".._idx.."_".._activity_id
end



local function init()

	local freestyle_game_cfg = skynet.call(DATA.service_config.freestyle_game_center_service,"lua","get_game_config")
	
	for game_id,c in pairs(freestyle_game_cfg) do
		DATA.freestyle_game_name[game_id] = c.game_name
	end

	-- 先初始化数据
	data_module.init()

	-- 后进行配置初始化(会进行服务创建)
	cfg_module.init()

	-- 本身会延迟一段时间才执行
	data_module.release_cache()
end

local function launch_activity_service(_service_id,_game_id,_idx,_cfg)

	if not _cfg.service_path then
		skynet.fail("launch_activity_service error service_path not exist ")
	end

	_cfg.game_id = _game_id
	_cfg.index = _idx
	_cfg.game_name = DATA.freestyle_game_name[_game_id]

	local ok,state = skynet.call("node_service","lua","create",false,_cfg.service_path,_service_id,_cfg)
	if ok then
		DATA.activity_service[_service_id] = 
		{
			service_id = _service_id,
			game_id = _game_id,
			index = _idx,
			activity_id = _cfg.activity_id,
			config = _cfg,
		}
	else
		skynet.fail(string.format("lauch %s error : %s!",_cfg.service_path,tostring(state)))
	end

end


-- 判断是否应该启动活动的服务了
local function chk_launch_activity_service()
	
	local wt = basefunc.get_week_elapse_time()
	
	next_activity_time = 7*24*3600

	for game_id,gac in pairs(DATA.activity_config) do
		
		for idx,ac in ipairs(gac) do
			
			local sid = gen_activity_service_id(game_id,idx,ac.activity_id)

			if wt >= ac.start_time and wt < ac.over_time then

				if not DATA.activity_service[sid] then
					launch_activity_service(sid,game_id,idx,ac)
				end

			else

				local nt = ac.start_time - wt
				if nt >= 0 and nt < next_activity_time then
					next_activity_time = nt
				end
				
			end

		end

	end

	next_activity_time = os.time() + next_activity_time

end


local function update(dt)
	
	cfg_module.update(dt)

	if os.time() >= next_activity_time then
		chk_launch_activity_service()
	end

end

--获取活动列表
function CMD.get_activity_data()
	return DATA.activity_service
end


-- 配置更新了配置变化的时候会调用一次
function PUBLIC.update_config()
	
	for game_id,gac in pairs(DATA.activity_config) do
		
		for idx,ac in ipairs(gac) do
			
			local sid = gen_activity_service_id(game_id,idx,ac.activity_id)

			if DATA.activity_service[sid] then

				ac.game_id = game_id
				ac.index = idx
				ac.game_name = DATA.freestyle_game_name[game_id] or ""

				nodefunc.send(sid,"reload_config",ac)
			end

		end

	end

	chk_launch_activity_service()

end


--活动服务器自己销毁了
function CMD.activity_service_destory(_service_id)

	data_module.delete_data(
		DATA.activity_service[_service_id].game_id,
		DATA.activity_service[_service_id].activity_id,
		DATA.activity_service[_service_id].index)

	DATA.activity_service[_service_id] = nil
end



function base.CMD.start(_service_config)
	DATA.service_config = _service_config

	init()
	
	skynet.timer(UPDATE_INTERVAL,update)

end

-- 启动服务
base.start_service()