--
-- Author: lyx
-- Date: 2018/10/9
-- Time: 15:14
-- 说明：麻将 血战到底  托管好牌控制

--[[ 模式说明：
	2 个托管：
		1 点 2 炮，1 自摸
		都自摸
	3 个托管：
		1 点 2 炮，1 点 3 炮 ，1 自摸
		1 点 2 炮，2 点 3 炮 ，1 自摸
		1 点 3 炮，1 自摸, 2 自摸
		1 自摸, 2 自摸 3 自摸
--]]



local config = {}

-- 手动配置 等级
config.shoudong_levels =false

-- 每个场的等级
config.shoudong_levels_cfg = 
{
	default = 4,
	freestyle_game=
	{
		default=2,
		[17] = 3,
		[18] = 5,
		[19] = 1,
		[20] = 2,
		-- 。。。 加其他场次
	},
	match_game=
	{
		default=7,
		[5] = 5,
		[6] = 5,
		[7] = 5,
		-- 。。。 加其他场次
	},
}

-- 默认配置
config.levels = 
{
	-- 等级 1
	{
		control_prob = 00,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制
		ctrl_count_prob = {00,00,100}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 10,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {15,25},   -- 胡牌步数，范围内随机
		model_prob = {{50,50},{25,25,25,25}}, -- 托管数量为 2, 或 3 时， 模式选择概率（参见 模式说明）
	},
	-- 等级 2
	{
		control_prob = 10,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制
		ctrl_count_prob = {10,10,80}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 20,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {15,20},   -- 胡牌步数，范围内随机
		model_prob = {{50,50},{25,25,25,25}}, -- 托管数量为 2, 或 3 时， 模式选择概率（参见 模式说明）
	},
	-- 等级 3
	
	{
		control_prob = 20,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制
		ctrl_count_prob = {50,30,20}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 30,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {12,18},   -- 胡牌步数，范围内随机
		model_prob = {{50,50},{25,25,25,25}}, -- 托管数量为 2, 或 3 时， 模式选择概率（参见 模式说明）
	},
	-- 等级 4
	{
		control_prob = 40,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制
		ctrl_count_prob = {50,30,20}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 40,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {8,18},   -- 胡牌步数，范围内随机
		model_prob = {{50,50},{25,25,25,25}}, -- 托管数量为 2, 或 3 时， 模式选择概率（参见 模式说明）
	},
	-- 等级 5
	{
		control_prob = 50,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制
		ctrl_count_prob = {30,50,20}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 50,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {8,15},   -- 胡牌步数，范围内随机
		model_prob = {{30,70},{15,15,35,35}}, -- 托管数量为 2, 或 3 时， 模式选择概率（参见 模式说明）
	},
	-- 等级 6
	{
		control_prob = 100,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制
		ctrl_count_prob = {40,50,10}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 60,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {8,15},   -- 胡牌步数，范围内随机
		model_prob = {{30,70},{15,25,25,35}}, -- 托管数量为 2, 或 3 时， 模式选择概率（参见 模式说明）
	},
	-- 等级 7
	{
		control_prob = 100,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制
		ctrl_count_prob = {10,30,60}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 70,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {8,15},   -- 胡牌步数，范围内随机
		model_prob = {{30,70},{15,15,35,35}}, -- 托管数量为 2, 或 3 时， 模式选择概率（参见 模式说明）
	},
	-- 等级 8
	{
		control_prob = 100,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制
		ctrl_count_prob = {10,20,70}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 80,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {8,15},   -- 胡牌步数，范围内随机
		model_prob = {{30,70},{15,15,35,35}}, -- 托管数量为 2, 或 3 时， 模式选择概率（参见 模式说明）
	},
	-- 等级 9
	{
		control_prob = 100,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制
		ctrl_count_prob = {10,20,70}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 90,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {8,15},   -- 胡牌步数，范围内随机
		model_prob = {{30,70},{15,15,35,35}}, -- 托管数量为 2, 或 3 时， 模式选择概率（参见 模式说明）
	},
	-- 等级 10
	{
		control_prob = 100,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制
		ctrl_count_prob = {00,20,80}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 100,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {8,10},   -- 胡牌步数，范围内随机
		model_prob = {{30,70},{15,15,35,35}}, -- 托管数量为 2, 或 3 时， 模式选择概率（参见 模式说明）
	},
}

-- 胡牌番数配置
config.hupai_fanshu_config = 
{
	-- 1 番
	{
		{prob=25, hu_pai_type="ddz"},
		{prob=35, hu_pai_type="nor",zhongzhang=true},
		{prob=15, hu_pai_type="nor",gen_count=1},
		{prob=25, hu_pai_type="nor",menqing=true},
	},

	-- 2 番
	{
		{prob=25, hu_pai_type="nor",qiyise=true},
		{prob=15, hu_pai_type="ddz",zhongzhang=true},
		{prob=15, hu_pai_type="nor",zhongzhang=true,gen_count=1},
		{prob=5, hu_pai_type="ddz",gen_count=1},
		{prob=5, hu_pai_type="nor",gen_count=2},
		{prob=35, hu_pai_type="nor",zhongzhang=true,menqing=true},
    },
    
	-- 3 番 
	{
		{prob=15, hu_pai_type="nor",qiyise=true,zhongzhang=true},
		{prob=15, hu_pai_type="ddz",qiyise=true},
		{prob=15, hu_pai_type="nor",qiyise=true,menqing=true},
		{prob=20, hu_pai_type="ddz",zhongzhang=true,gen_count=1},
		{prob=20, hu_pai_type="nor",qiyise=true,gen_count=1},
		{prob=5, hu_pai_type="ddz",gen_count=2},
		{prob=10, hu_pai_type="qidui"},
	},
}


-- 好牌概率配置
config.haopai_fsbs_map = 
{
    -- bushu , hupai_fanshu 为概率数组，例如： 1 ， 2 ，3 番的概率

	{haopai_prob=10,bushu={00,00,100},hupai_fanshu={100,00,00}}, 
	{haopai_prob=20,bushu={00,30,70},hupai_fanshu={90,10,00}}, 
	{haopai_prob=30,bushu={00,40,60},hupai_fanshu={80,20,00}}, 
	{haopai_prob=40,bushu={00,50,50},hupai_fanshu={30,60,10}},
	{haopai_prob=50,bushu={30,50,20},hupai_fanshu={20,60,20}},
	{haopai_prob=60,bushu={30,40,30},hupai_fanshu={30,50,20}},
	{haopai_prob=70,bushu={40,30,30},hupai_fanshu={10,60,30}},
	{haopai_prob=80,bushu={50,30,20},hupai_fanshu={10,40,50}},
	{haopai_prob=90,bushu={60,30,10},hupai_fanshu={10,30,60}},
	{haopai_prob=100,bushu={90,10,0},hupai_fanshu={0,20,80}},
}

-- 内部配置
config.base_bushu_cfg = {
    {3,5},
    {5,7},
    {7,9},
    --{2,4},
   -- {3,5},
    --{4,6},
}

config.try_count = 5
return config
