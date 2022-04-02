
local skynet = require "skynet_plus"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"

require "normal_enum"

require "printfunc"

local DATA = base.DATA
local CMD = base.CMD
local PUBLIC=base.PUBLIC

DATA.service_config = nil

DATA.shared_game_config = {

	shared_match = {
		shared_num = 20,
		assets_type = PLAYER_ASSET_TYPES.JING_BI,
		assets_num = 100,
	},

	one_yuan_match = {
		shared_num = 3,
		assets_type = "prop_5",
		assets_num = 1,
	},

	flaunt = {
		shared_num = 1,
		assets_type = PLAYER_ASSET_TYPES.JING_BI,
		assets_num = 1000,
	},

	-- shared_timeline = {
	-- 	shared_num = 1,
	-- 	assets_type = PLAYER_ASSET_TYPES.JING_BI,
	-- 	assets_num = 1000,
	-- },


	-- 万元赛 分享 每天只能分享一次，总共能分享五次
	wys_shared = {
		[1] = 
		{
			shared_num = 1,
			assets_type = PLAYER_ASSET_TYPES.JING_BI,
			assets_num = 1000,
		},
		[2] = 
		{
			shared_num = 1,
			assets_type = PLAYER_ASSET_TYPES.JING_BI,
			assets_num = 2000,
		},
		[3] =
		{
			shared_num = 1,
			assets_type = PLAYER_ASSET_TYPES.FISH_COIN,
			assets_num = 5000,
		},
		[4] = 
		{
			shared_num = 1,
			assets_type = "prop_5y",
			assets_num = 1,
		},
		[5] = 
		{
			shared_num = 1,
			assets_type = "prop_20y",
			assets_num = 1,
		},

	},

	qys_shared = {
		shared_num = 1,
		assets_type = PLAYER_ASSET_TYPES.PROP_2,
		assets_num = 1,
	},
	
}

local return_msg={result=0}


-- 设置配置
function CMD.update_config_shared_num(_type,_shared_num)

	if type(_type)~="string" 
		or not DATA.shared_game_config[_type]
		or not tonumber(_shared_num) then

		return_msg.result = 1001
		return return_msg
	end

	DATA.shared_game_config[_type].shared_num = _shared_num


	return_msg.result = 0
	return return_msg
end


-- 设置配置
function CMD.update_config_assets(_type,_assets_type,_assets_num)

	if type(_type)~="string" 
		or not DATA.shared_game_config[_type]
		or type(_assets_type)~="_assets_type"
		or not basefunc.is_asset(_assets_type)
		or not tonumber(_assets_num) then

		return_msg.result = 1001
		return return_msg
	end

	DATA.shared_game_config[_type].assets_type = _assets_type
	DATA.shared_game_config[_type].assets_num = _assets_num

	return_msg.result = 0
	return return_msg
end


-- 获取配置
function CMD.get_config()

	return DATA.shared_game_config

end


function CMD.start(_service_config)

	DATA.service_config = _service_config

end

-- 启动服务
base.start_service()
