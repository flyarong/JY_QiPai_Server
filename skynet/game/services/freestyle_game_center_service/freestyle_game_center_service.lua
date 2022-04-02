
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
local config_module = require "freestyle_game_center_service.freestyle_game_config_module"
require "printfunc"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA


-- 服务配置
DATA.service_config = nil

DATA.game_configs = {}

local manager_services = {}


function CMD.create_service_id(_config)
	return "freestyle_service_".._config.game_id
end


local function create_one_game_service(_game_id,_config)

	if _config.enable == 1 then

		local new_service_id = CMD.create_service_id(_config)

		local ok,state = skynet.call("node_service","lua","create",false,_config.manager_path,new_service_id,_config)
		if ok then
			manager_services[_game_id] = {service_id = new_service_id,game_type=_config.game_type}
		else
			skynet.fail(string.format("freestyle lauch %s error : %s!",_config.manager_path,tostring(state)))
		end

	else
		print("freestyle_service is disable : ".._game_id)
	end

end


--获取游戏列表
function CMD.get_game_map()
	
	return manager_services
end


--获取游戏列表
function CMD.get_game_config()
	return DATA.game_configs
end

-- 重新加载配置， by lyx
-- 失败 返回 错误号
function PUBLIC.reload_config( config )

	if manager_services[config.game_id] then
		nodefunc.call(manager_services[config.game_id].service_id,"reload_config",config)
	else
		create_one_game_service(config.game_id,config)
	end

	return 0
end

function CMD.start(_service_config)

	DATA.service_config=_service_config

	nodefunc.register_game("freestyle_game")

	config_module.init()
end

-- 启动服务
base.start_service(nil,"f_centerice")

