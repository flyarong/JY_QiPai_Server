--
-- Author: lyx
-- Date: 2018/5/30
-- Time: 11:09
-- 说明：vip 控制数值配置

return
{
    day_begin_time = 6, -- 单位天的 起始时间（小时）

    jing_bi_rate = 100, -- 鲸币 - 人民币（分） 的汇率
    room_rate=5000, -- 房费 1 把
    game_count=20, -- 每天游戏次数，20把
    period=10, -- 周期 天

    -- 控制类型
    control =
    {
        A = {lucky_power=2,tuoguan=0},
        B = {lucky_power=1,tuoguan=0},
        C = {lucky_power=1,tuoguan=1},
    },

    lucky_base = 1000000, -- 抽奖基础值
    lucky_range = {80,140}, -- 对局 抽奖 浮动百分比

    baoji_base = 1000000, -- 暴击抽奖基础值
    baoji_range = {80,140}, -- 暴击抽奖 抽奖 浮动百分比

    day_debt_range = {75,125}, -- 每天分债浮动范围

    qudao_percent = 10, -- 渠道分成百分比
    fanjiang_percent=20, --返奖百分比
}
