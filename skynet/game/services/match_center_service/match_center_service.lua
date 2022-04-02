--
-- Author: hw
-- Date: 2018/3/28
-- Time: 
-- 说明：比赛场游戏服务
-- ddz_match_service
local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local match_config_module = require "match_center_service/match_config_module"
require "printfunc"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

DATA.cmd_signal = basefunc.signal.new()

-- 服务配置
DATA.service_config = nil

-- 比赛配置（数据库  match_info 表相关数据）
DATA.match_config = {}

-- 比赛管理 服务 列表： match_info id -> {match_manager_service_id=,...}
local match_manager_services = {}

---- 刷新配置
--[[local refresh_config_dt = 1000
local refresh_config = function()
	CMD.reload_config()
	
	skynet.timeout( refresh_config_dt , refresh_config )
end--]]

-- 设置 比赛中 报名点的状态
--	参数 _signup_my_id ： 报名点的 服务 id
function CMD.set_match_signup_status(_signup_my_id,_status_data)

end

function CMD.create_service_id(_config)
	return "match_service_".._config.game_id
end


local function create_one_normal_service(_match_id,_config,match_model,match_model_path)
	local new_service_id = CMD.create_service_id(_config)
	if not match_model_path then
		skynet.fail(string.format("lauch %s not exist ",match_model_path))
	end
	local ok,state = skynet.call("node_service","lua","create",false,match_model_path,new_service_id,_config)
	if ok then
		match_manager_services[_match_id] = 
		{
			service_id = new_service_id,
			game_type = _config.game_type,
			match_model = _config.match_model,
			match_model_path = match_model_path,
		}
	else
		skynet.fail(string.format("lauch %s error : %s!",match_model_path,tostring(state)))
	end
end



local function create_one_match_service(_match_id,_config)

	if _config.enable == 1 then
		create_one_normal_service(_match_id,_config,_config.match_model,_config.match_model_path)
	else
		print("match_service is disable : ".._match_id)
	end

end




-- 创建比赛场的所有服务
-- 根据 match_info 数据，每行创建一个 服务
local function create_all_match_services()

	for _match_id,_config in pairs(match_config) do

		create_one_match_service(_match_id,_config)

	end

end

function CMD.get_game_map()
	return match_manager_services
end


-- 比赛已经完成销毁了
function CMD.manager_service_destory(_match_id)
	match_manager_services[_match_id] = nil
	print(_match_id.."is over destory! ")
end




-- 管理指令： 准备关闭，锁定服务器，不允许新场、等待自然结束
--function CMD.control_prepare_close()
--	for id,manager in pairs(match_manager_services) do
--		manager:match_lock()
--	end
--end

-- 重新加载配置， by lyx
-- 失败 返回 错误号
function PUBLIC.reload_config(config)

	if match_manager_services[config.game_id] then
		nodefunc.call(match_manager_services[config.game_id].service_id,"reload_config",config)
	else
		create_one_match_service(config.game_id , config)
	end


	return 0
end


--冠名赛 从数据重新载入 join_id
function CMD.nm_reload_join_id()

	for _match_id,d in pairs(match_manager_services) do
		if d.match_model_path == "naming_match_manager_service/naming_match_manager_service" then
			nodefunc.call(d.service_id,"reload_join_id")
		end
	end

	return 0
end



function CMD.start(_service_config)

	DATA.service_config=_service_config

	nodefunc.register_game("match_game")

	match_config_module.init()

end

-- 启动服务
base.start_service()

