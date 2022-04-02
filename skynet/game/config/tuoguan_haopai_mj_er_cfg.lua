--
-- Author: lyx
-- Date: 2018/10/9
-- Time: 15:14
-- 说明：麻将 二人 的 托管好牌控制


local config = {}

-- 手动配置 等级
config.shoudong_levels =false

-- 每个场的等级
config.shoudong_levels_cfg = 
{
	default = 3,
	freestyle_game=
	{
		default=7,
		[13] = 4,
		[14] = 5,
		[15] = 6,
		[16] = 7,
		-- 。。。 加其他场次
	},
	match_game=
	{
		default=9,
		[5] = 5,
		-- 。。。 加其他场次
	},
}

-- 默认配置
config.levels = 
{
	-- 等级 1
	{
		control_prob = 00,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 10,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {15,40},   -- 胡牌步数，范围内随机
	},
	-- 等级 2
	{
		control_prob = 20,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 20,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {10,20},   -- 胡牌步数，范围内随机
	},
	-- 等级 3
	{
		control_prob = 30,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 30,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {10,15},   -- 胡牌步数，范围内随机
	},
	-- 等级 4
	{
		control_prob = 40,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 40,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {5,15},   -- 胡牌步数，范围内随机
	},
	-- 等级 5
	{
		control_prob = 50,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 50,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {5,15},   -- 胡牌步数，范围内随机
	},
	-- 等级 6
	{
		control_prob = 100,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 60,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {5,10},   -- 胡牌步数，范围内随机
	},
	-- 等级 7
	{
		control_prob = 100,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 70,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {5,10},   -- 胡牌步数，范围内随机
	},
	-- 等级 8
	{
		control_prob = 100,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 80,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {5,10},   -- 胡牌步数，范围内随机
	},
	-- 等级 9
	{
		control_prob = 100,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 90,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {5,10},   -- 胡牌步数，范围内随机
	},
	-- 等级 10
	{
		control_prob = 100,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 100,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {3,6},   -- 胡牌步数，范围内随机
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
	{haopai_prob=20,bushu={00,10,90},hupai_fanshu={80,20,00}}, 
	{haopai_prob=30,bushu={00,20,80},hupai_fanshu={70,30,00}}, 
	{haopai_prob=40,bushu={30,50,20},hupai_fanshu={30,50,20}},
	{haopai_prob=50,bushu={30,50,20},hupai_fanshu={30,60,10}},
	{haopai_prob=60,bushu={30,60,10},hupai_fanshu={10,60,30}},
	{haopai_prob=70,bushu={30,70,00},hupai_fanshu={10,50,40}},
	{haopai_prob=80,bushu={60,30,10},hupai_fanshu={10,40,50}},
	{haopai_prob=90,bushu={70,20,10},hupai_fanshu={10,30,60}},
	{haopai_prob=100,bushu={70,20,10},hupai_fanshu={10,20,70}},

}

-- 内部配置
config.base_bushu_cfg = {
    -- {3,5},
    -- {4,6},
    -- {5,7},
    {2,4},
    {3,5},
    {4,6},
}

config.try_count = 5
return config
