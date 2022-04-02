--
-- Author: lyx
-- Date: 2018/5/30
-- Time: 11:09
-- 说明：系统监控 参数配置
--[[
 配置项：
	name  	数据项的名字，目前支持
		register 注册
		login	登录
		pay 	支付
		redshop 红包商城兑换
		diamond 钻石增加
		withdraw 提现
	desc	显示内容
	dur 	数据收集的时长，单位 秒
	degree_inc	监控变量的严重程度增加量 到此值时再次报警：当监控的变量 偏离 报警值 每增加 给定的量，则重复报警一次
			注意：系统会记录 监控变量的最大值，只有手工处理或 重启服务器才会 复位
	comp	数值比较方式
		"greater" 大于
		"less" 小于
	type 	数值类型（在 dur 时段内）
		"count" 次数下限
		"value" 单次数值
		"sum" 	总和(dur 时间内)数值下限
	limit	限制值，意义 由 type 确定
--]]

return
{
	{
		name="test",
		desc="警报测试-次数",
		dur=5,
		degree_inc=50,
		comp="greater",
		type="count",
		limit=100
	},

	{
		name="test",
		desc="警报测试-数量",
		dur=5,
		degree_inc=50,
		comp="greater",
		type="sum",
		limit=200
	},

	{
		name="profit_lose",
		desc="收益盈亏",
		dur=3600,
		degree_inc=0,
		comp="greater",
		type="sum",
		limit=5000000
	},

	{
		name="sql_error",
		desc="sql执行错误",
		dur=60,
		degree_inc=50,
		comp="greater",
		type="count",
		limit=1,
		email="695223392@qq.com,24090841@qq.com",
	},

	{
		name="register",
		desc="注册人数",
		dur=3600,
		degree_inc=50,
		comp="greater",
		type="count",
		limit=100
	},

	{
		name="login",
		desc="登录次数",
		dur=3600,
		degree_inc=50,
		comp="greater",
		type="count",
		limit=500
	},

	{
		name="pay",
		desc="充值数额",
		dur=3600,
		degree_inc=10000,
		comp="greater",
		type="sum",
		limit=500000
	},

	{
		name="pay",
		desc="充值次数",
		dur=3600,
		degree_inc=10,
		comp="greater",
		type="count",
		limit=100
	},

	{
		name="redshop",
		desc="红包兑换次数",
		dur=3600,
		degree_inc=10,
		comp="greater",
		type="count",
		limit=100
	},

	{
		name="redshop",
		desc="红包兑换金额",
		dur=3600,
		degree_inc=1000,
		comp="greater",
		type="sum",
		limit=100000
	},

	{
		name="diamond",
		desc="钻石增加量",
		dur=3600,
		degree_inc=100000,
		comp="greater",
		type="sum",
		limit=500000
	},

	{
		name="withdraw",
		desc="提现次数",
		dur=3600,
		degree_inc=10,
		comp="greater",
		type="count",
		limit=100
	},

	{
		name="withdraw",
		desc="提现金额",
		dur=3600,
		degree_inc=5000,
		comp="greater",
		type="sum",
		limit=100000
	},
	{
		name="game_profit_pass_up_line",
		desc="场次统计，超过上警报线。",
		extra_desc = "场次统计超过上警报线，场次id：%s,警报线：%d,当前线：%d",
		dur=600,
		degree_inc=0,
		comp="greater",
		type="value",
		limit = 99999999999,
	},
	{
		name="game_profit_pass_down_line",
		desc="场次统计，超过下警报线。",
		extra_desc = "场次统计超过下警报线，场次id：%s,警报线：%d,当前线：%d",
		dur=600,
		degree_inc=0,
		comp="greater",
		type="value",
		limit = 99999999999,
	},
	{
		name="game_profit_long_time_out_ctrl",
		desc="场次统计，长时间调整失常。",
		extra_desc = "场次统计太长时间调整失常，场次id：%s,目标调整次数：%d,已调整次数：%d",
		dur=600,
		degree_inc=0,
		comp="greater",
		type="value",
		limit = 99999999999,
	},
}
