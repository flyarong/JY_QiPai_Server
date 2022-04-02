--
-- Author: lyx
-- Date: 2018/10/9
-- Time: 15:14
-- 说明：麻将的 托管好牌控制

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

-- 默认配置
config.default = 
{
    control_prob = 80,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制 3 个托管
    ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
    haopai_prob = 20,       -- 好牌概率 ： 1 ~ 100
	hupai_bushu = {8,17},   -- 胡牌步数，范围内随机
	model_prob = {{50,50},{25,25,25,25}}, -- 托管数量为 2, 或 3 时， 模式选择概率（参见 模式说明）
}

-- 自由场配置
config.freestyle_game = 
{
	-- 默认配置
    default = {
		control_prob = 80,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制 3 个托管
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 20,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {8,17},   -- 胡牌步数，范围内随机
	
	}, 
	
	-- 场次 13 配置
    [13] = {
		control_prob = 80,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制 3 个托管
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 20,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {8,17},   -- 胡牌步数，范围内随机
	}, 
	
	[14] = {
		control_prob = 80,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制 3 个托管
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 20,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {8,17},   -- 胡牌步数，范围内随机
	}, 
	
	[15] = {
		control_prob = 80,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制 3 个托管
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 40,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {9,19},   -- 胡牌步数，范围内随机
	}, 
	
	[16] = {
		control_prob = 80,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制 3 个托管
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 20,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {8,17},   -- 胡牌步数，范围内随机
	}, 
	
	[17] = {
		control_prob = 80,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制 3 个托管
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 20,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {8,17},   -- 胡牌步数，范围内随机
	}, 
	
	[18] = {
		control_prob = 80,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制 3 个托管
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 20,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {8,17},   -- 胡牌步数，范围内随机
	}, 
	
	[19] = {
		control_prob = 70,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制 3 个托管
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 20,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {7,19},   -- 胡牌步数，范围内随机
	}, 
	
	[20] = {
		control_prob = 80,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制 3 个托管
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 20,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {8,17},   -- 胡牌步数，范围内随机
	}, 
}

-- 比赛场配置
config.match_game = 
{
default = {
		control_prob = 80,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制 3 个托管
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 20,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {8,17},   -- 胡牌步数，范围内随机
	}, 
	[5] = {
		control_prob = 80,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制 3 个托管
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 20,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {8,17},   -- 胡牌步数，范围内随机
	}, 
	[6] = {
		control_prob = 80,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制 3 个托管
		ctrl_count_prob = {20,50,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 20,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {8,17},   -- 胡牌步数，范围内随机
	}, 
	[7] = {
		control_prob = 60,      -- 介入控制的概率： 0 表示不控制， 100 表示 总是控制 3 个托管
		ctrl_count_prob = {30,40,30}, -- 介入 1,2,3 个托管的概率，加起来 100
		haopai_prob = 20,       -- 好牌概率 ： 1 ~ 100
		hupai_bushu = {8,17},   -- 胡牌步数，范围内随机
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


-- 胡牌番数配置（二人）
config.hupai_er_fanshu_config = 
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
	{haopai_prob=30,bushu={30,50,20},hupai_fanshu={30,50,20}}, 
	{haopai_prob=60,bushu={10,60,30},hupai_fanshu={20,40,40}},
	{haopai_prob=100,bushu={10,30,60},hupai_fanshu={10,20,70}},
}

-- 好牌概率配置（二人）
config.haopai_er_fsbs_map = 
{
    -- bushu , hupai_fanshu 为概率数组，例如： 1 ， 2 ，3 番的概率
	{haopai_prob=30,bushu={30,50,20},hupai_fanshu={30,50,20}}, 
	{haopai_prob=60,bushu={10,60,30},hupai_fanshu={20,40,40}},
	{haopai_prob=100,bushu={10,30,60},hupai_fanshu={10,20,70}},
}

-- 内部配置
config.base_bushu_cfg = {
    {3,5},
    {5,7},
    {7,9}
}

-- 内部配置（二人）
config.base_er_bushu_cfg = {
    {3,5},
    {4,6},
    {5,7}
}


config.try_count = 5
return config
