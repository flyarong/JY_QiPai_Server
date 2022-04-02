--
-- Author: lyx
-- Date: 2018/4/14
-- Time: 10:31
-- 说明：配置转换 函数
-- 游戏过程、规则、 agent

local funcs = require "normal_func"
local basefunc = require "basefunc"

local friendgame = {}

-- 游戏过程配置
friendgame.game_trans =
{

	-- 配置项清单
	-- 特殊处理： 值为 "_use_real" ，则使用传入的配置项中的 value
	configs = 
	{
		-- 局数
		race_count_4 = {race_count=4},
		race_count_8 = {race_count=8},
		race_count_16 = {race_count=16},

		-- 封顶
		feng_ding_32b = {feng_ding=32},
		feng_ding_64b = {feng_ding=64},
		feng_ding_128b = {feng_ding=128},
		feng_ding_256b = {feng_ding=256},

		-- 加倍
		jia_bei = {jia_bei=1},

	},

	-- 单选控制：多个里面只能选一个，且必须选一个
	onlyone=
	{
		nor_ddz_nor = 
		{
			{"race_count_4","race_count_8","race_count_16"},
			{"feng_ding_32b","feng_ding_64b","feng_ding_128b","feng_ding_256b"},
		},

		nor_mj_xzdd = 
		{
			{"race_count_4","race_count_8","race_count_16"},
		},
	},
}

friendgame.game_option = 
{
	race_count = 4,
	-- seat_count = 4,
	init_stake = 1,
	init_rate = 1,
	feng_ding = 999999,

	-- 麻将 换三张
	-- mj_huan_san_zhang = false,
}

-- 玩家 agent 配置
friendgame.agent_trans = 
{
	configs = {},
}
friendgame.agent_option = 
{
	onlyone={},
}


local function translate_options(_options,_trans_config,_defaults)
	local ret = {}

	basefunc.merge(_defaults,ret)

	for _,_opt in ipairs(_options) do
		local _trans = _trans_config[_opt.option]
		if _trans then

			for _k,_v in pairs(_trans) do
				if "_use_real" == _v then
					ret[_k] = _opt.value
				else
					ret[_k] = _v
				end
			end
		end
	end

	return ret
end

-- 检查参数
function friendgame.check( _options,_game_type )

	local gtype_trans = require(GAME_TYPE_CFG_TRANS[_game_type])

	return funcs.check_client_option(_options,{
			gtype_trans.trans.onlyone,
			friendgame.game_trans.onlyone[_game_type],
			friendgame.agent_trans.onlyone,
		})
end

-- 转换游戏过程选项
-- 返回值： 游戏过程选项
function friendgame.translate_game(_options)
	
	return translate_options(_options,friendgame.game_trans.configs,friendgame.game_option)
	
end

-- 转换 agent 选项
-- 返回值： agent 选项 
function friendgame.translate_agent(_options)
	
	return translate_options(_options,friendgame.agent_trans.configs,friendgame.agent_option)
	
end

return friendgame