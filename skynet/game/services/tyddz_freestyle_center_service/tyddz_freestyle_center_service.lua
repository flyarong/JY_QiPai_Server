
local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "normal_enum"
require "printfunc"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local config_module = require "tyddz_freestyle_center_service.tyfreestyle_config_module"

local game_list = {}
local game_map = {}

local PROTECTED = {}

local service_count = 0
local function create_service_id()
	service_count = service_count + 1

	return "tyddz_freestyle_service_" .. service_count
end


-- by lyx
local function launch_one_service(_cfg,_room_rent)

		local _service_id = create_service_id()
		local ok,state = skynet.call("node_service","lua","create",false
										,"tyddz_freestyle_service/tyddz_freestyle_service",
										_service_id,_cfg)

	if ok then

		local _game={
			game_id=_cfg.id,
			game_model=_cfg.game_model,
			ui_order=_cfg.ui_order,
			signup_service_id=_service_id,
			room_rent=_room_rent,
		}

		game_map[_cfg.id]=_game
		game_list[#game_list + 1] = _game

	else
		skynet.fail(string.format("error: %s, create service error:%s !",
											_service_id,state))
	end
end

--启动游戏服务
local function launch_service(_configs,_room_rents)

	for i,cfg in ipairs(_configs) do

		launch_one_service(cfg,_room_rents[i])
	end

end

-- 重新加载配置， by lyx
-- 失败 返回 错误号
function CMD.reload_config()
	config_module.reload_config_info()

	--获取比赛配置
	local configs = config_module.get_datas()
	local room_rents = config_module.get_room_rents()

	for i,cfg in ipairs(configs) do

		if game_map[cfg.id] then

			cfg.room_rent = room_rents[i]
			basefunc.merge(cfg,game_map[cfg.id])

			nodefunc.call(game_map[cfg.id].signup_service_id,"reload_config",cfg)
		else
			launch_one_service(cfg,room_rents[i])
		end
	end

	return 0
end


--获取游戏列表
function CMD.get_game_list()
	return game_list,game_map
end



function CMD.start(_service_config)

	DATA.service_config=_service_config

	-- 初始化比赛配置
	config_module.init_config_info()

	--获取比赛配置
	local configs = config_module.get_datas()
	local room_rents = config_module.get_room_rents()

	launch_service(configs,room_rents)

	nodefunc.register_game("tyddz_freestyle_game")
end


-- 启动服务
base.start_service()

