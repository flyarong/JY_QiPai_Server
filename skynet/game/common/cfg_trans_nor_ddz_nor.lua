--
-- Author: lyx
-- Date: 2018/4/14
-- Time: 10:31
-- 说明：血战到底 配置转换 函数
--

local basefunc = require "basefunc"

local config = {}

config.trans = 
{
	-- 配置项清单
	configs = 
	{
		san_dai_dui = {kaiguan={[5]=true}},
		si_dai_2dui = {kaiguan={[9]=true}},
		san_bi_dai = {kaiguan={[3]=false}},
		
	},

	-- 配置项 默认值
	configs_default = 
	{
		kaiguan=
		{
			[5]=false,
			[9]=false,
		},
		multi = 
		{
		},
	},

	-- 单选控制：多个里面只能选一个，且必须选一个
	onlyone=
	{
	},
}

-- 开关配置
config.kaiguan = 
{
    [0]=true,
    [1]=true,
    [2]=true,
    [3]=true,
    [4]=true,
    [5]=true,
    [6]=true,
    [7]=true,
    [8]=true,
    [9]=true,
    [10]=true,
    [11]=true,
    [12]=true,
    [13]=true,
    [14]=true,
    [15]=true,	
}

-- 番数配置
config.multi = 
{
}

local function copy_trans_value(_trans_values,_outs)
	if _trans_values then
		for _k,_v in pairs(_trans_values) do
			if "_use_real" == _v then
				_outs[_k] = _opt.value
			else
				_outs[_k] = _v
			end
		end
	end
end

-- 转换 游戏规则
-- 返回值： 开关表，番数表
function config.translate(_options)
	
	-- 拷贝原始配置
	local ret = {
		kaiguan = basefunc.deepcopy(config.kaiguan),
		multi = basefunc.deepcopy(config.multi),
	}

	-- 拷贝 trans 定义的默认配置
	basefunc.merge(config.trans.configs_default.kaiguan,ret.kaiguan)
	basefunc.merge(config.trans.configs_default.multi,ret.multi)

	-- 依次处理
	for _,_opt in ipairs(_options) do
		local _trans = config.trans.configs[_opt.option]
		if _trans then

			copy_trans_value(_trans.kaiguan,ret.kaiguan)
			copy_trans_value(_trans.multi,ret.multi)

		end
	end

	return ret
end

return config