--[[ 
    托管的 交互配置

    斗地主牌类型
	-- 0： 过
	-- 1： 单牌  
	-- 2： 对子  
	-- 3： 三不带
	-- 4： 三带一
	-- 5： 三带一对
	-- 6： 顺子  	
	-- 7： 连队		
	-- 8： 四带2    
	-- 9： 四带两对	 
	-- 10：飞机带单牌
	-- 11：飞机带对子
	-- 12：飞机不带 
	-- 13：炸弹
	-- 14：王炸
--]]

return {

    -- 操作分组： 斗地主 出牌、麻将 碰杠
    operation_group = 
    {
        general = {3,4,5,6,7,8,9,"peng"}, -- 一般 的 牌类型
        good = {10,11,12,"gang"}, -- 好牌
        super = {13,14}, -- 很好
    },

    -- 角色配置
    role = 
    {
        -- 测试
        -- {
        --     count_percent = 100, -- 本角色 数量占比

        --     -- 主动评价出牌/操作 的概率 : 0 ~ 100
        --     eval_op_prob = 
        --     {
        --         good = 100,
        --         super = 100,
        --     },
            
        --     urge_timeout = {3,6}, -- 催促的时限（随机范围）：等待 n 秒没操作
        --     urge_prob = 100, -- 催促的概率

        --     reply = 100, -- 回复的概率
        -- },

        -- 无语
        {
            count_percent = 60,

            eval_op_prob = 
            {
                good = 0,
                super = 0,
            },
            
            urge_timeout  = {3,6},
            urge_prob = 0,

            reply = 0,
        },

        -- 安静
        {
            count_percent = 30,

            eval_op_prob = 
            {
                good = 5,
                super = 10,
            },
            
            urge_timeout  = {6,15},
            urge_prob = 10,

            reply = 10,
        },

        -- 活跃
        {
            count_percent = 10,

            eval_op_prob = 
            {
			    general = 20,
                good = 30,
                super = 50,
            },
            
            urge_timeout  = {4,15},
            urge_prob = 20,

            reply = 30,
        },
    },
}