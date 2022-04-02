--
-- Author: lyx
-- Date: 2018/10/9
-- Time: 15:14
-- 说明：玩家保护配置
--  参数说明：
--      lost_count 连输 n 把之后 触发好牌
--      haopai_count 在 超时 之前，最多触发 好牌的次数
--      power 好牌程度，目前 统一配成 5 

--[[
    -- 测试配置
            default={lost_count={2,2},haopai_count = 5,power=5},
            [1] = {lost_count={2,2},haopai_count = 5,power=5},
            [2] = {lost_count={2,2},haopai_count = 5,power=5},
            [3] = {lost_count={2,2},haopai_count = 5,power=5},
            [4] = {lost_count={2,2},haopai_count = 5,power=5},
            [5] = {lost_count={2,2},haopai_count = 5,power=5},
            [6] = {lost_count={2,2},haopai_count = 5,power=5},
            [7] = {lost_count={2,2},haopai_count = 5,power=5},
            [8] = {lost_count={2,2},haopai_count = 5,power=5},
            [21] = {lost_count={2,2},haopai_count = 5,power=5},
            [22] = {lost_count={2,2},haopai_count = 5,power=5},
            [23] = {lost_count={2,2},haopai_count = 5,power=5},
            [24] = {lost_count={2,2},haopai_count = 5,power=5},
            [33] = {lost_count={2,2},haopai_count = 5,power=5},
            [34] = {lost_count={2,2},haopai_count = 5,power=5},
            [35] = {lost_count={2,2},haopai_count = 5,power=5},
            [36] = {lost_count={2,2},haopai_count = 5,power=5},

]]

return 
{

----------------------------------------------------------------
-- 防沮丧系统    

    -- 防沮丧 连输 计数器 超时时间，单位：秒
    fang_jusang_proect_timeout = 86400, -- 86400 = 1 天

    -- 水控系统 在 up , down 状态下 lost_count 变化系数
    fj_lost_count_up_scale = 2,
    fj_lost_count_down_scale = 1,

    fang_jusang = 
    {
        default = {lost_count={2,3},haopai_count = 5,power=5},
        freestyle=
        {
            default={lost_count={2,2},haopai_count = 5,power=5},
            [1] = {lost_count={2,3},haopai_count = 5,power=5},
            [2] = {lost_count={2,4},haopai_count = 5,power=5},
            [3] = {lost_count={2,4},haopai_count = 5,power=5},
            [4] = {lost_count={2,4},haopai_count = 5,power=5},
            [5] = {lost_count={2,3},haopai_count = 5,power=5},
            [6] = {lost_count={2,4},haopai_count = 5,power=5},
            [7] = {lost_count={2,4},haopai_count = 5,power=5},
            [8] = {lost_count={2,4},haopai_count = 5,power=5},
            [21] = {lost_count={2,3},haopai_count = 5,power=5},
            [22] = {lost_count={2,4},haopai_count = 5,power=5},
            [23] = {lost_count={2,4},haopai_count = 5,power=5},
            [24] = {lost_count={2,4},haopai_count = 5,power=5},
            [33] = {lost_count={2,3},haopai_count = 5,power=5},
            [34] = {lost_count={2,4},haopai_count = 5,power=5},
            [35] = {lost_count={2,4},haopai_count = 5,power=5},
            [36] = {lost_count={2,4},haopai_count = 5,power=5},
            -- 。。。 加其他场次
        },
        matchstyle=
        {
            default={lost_count={2,2},haopai_count = 5,power=5},
            [5] = {lost_count={2,2},haopai_count = 5,power=5},
            [6] = {lost_count={2,2},haopai_count = 5,power=5},
            [7] = {lost_count={2,2},haopai_count = 5,power=5},
            -- 。。。 加其他场次
        },
            
    },

-------------------------------------------------------------------------------    
-- 新手保护 的 玩家好牌控制

    -- 新手保护 连输 计数器 超时时间，单位：秒
    xinshou_proect_timeout = 86400, -- 86400 = 1 天

    -- 新手保护：天序号 => 配置
    xinshou_day_protected = 
    {
        -- 第 1 天
        {
            [1] = {lost_count={2,3},haopai_count = 5,power=5},
            [5] = {lost_count={2,3},haopai_count = 5,power=5},
            [21] = {lost_count={2,3},haopai_count = 5,power=5},
            [33] = {lost_count={2,3},haopai_count = 5,power=5},
			[2] = {lost_count={2,3},haopai_count = 5,power=5},
            [6] = {lost_count={2,3},haopai_count = 5,power=5},
			[22] = {lost_count={2,3},haopai_count = 5,power=5},
            [34] = {lost_count={2,3},haopai_count = 5,power=5},
		},
        -- 第 2 天
        {
            [1] = {lost_count={2,3},haopai_count = 5,power=5},
            [5] = {lost_count={2,3},haopai_count = 5,power=5},
            [21] = {lost_count={2,3},haopai_count = 5,power=5},
            [33] = {lost_count={2,3},haopai_count = 5,power=5},
			[2] = {lost_count={2,3},haopai_count = 5,power=5},
            [6] = {lost_count={2,3},haopai_count = 5,power=5},
			[22] = {lost_count={2,3},haopai_count = 5,power=5},
            [34] = {lost_count={2,3},haopai_count = 5,power=5},
        },
        -- 第 3 天
        {
            [1] = {lost_count={2,4},haopai_count = 5,power=5},
            [5] = {lost_count={2,4},haopai_count = 5,power=5},
            [21] = {lost_count={2,4},haopai_count = 5,power=5},
            [33] = {lost_count={2,4},haopai_count = 5,power=5},
			[2] = {lost_count={2,4},haopai_count = 5,power=5},
            [6] = {lost_count={2,4},haopai_count = 5,power=5},
			[22] = {lost_count={2,4},haopai_count = 5,power=5},
            [34] = {lost_count={2,4},haopai_count = 5,power=5},
        },
    },

    -- 新手保护： 前 n 天，前 n 把 
    xinshou_before = 
    {
        [1] = {day=3,count=1,power=5}, -- 前 3 天， 第 1 把
        [5] = {day=3,count=1,power=5},
        [21] = {day=3,count=1,power=5},
        [33] = {day=3,count=1,power=5},
        [2] = {day=3,count=1,power=5},
        [6] = {day=3,count=1,power=5},
        [22] = {day=3,count=1,power=5},
        [34] = {day=3,count=1,power=5},
    }
    
}