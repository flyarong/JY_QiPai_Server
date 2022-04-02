--[[ 托管自己对局的时候 游戏对应的倍数番数配置

	给出倍数的数组 multi 和 概率权重 weight ，从其中通过概率权重选一个

	斗地主配置的为地主最后打出的总倍数

	麻将配置为最后打出的总番数(不飘,随机进行点炮和自摸)
	
	min_time 一局游戏的最小时间
	max_time 一局游戏的最大时间
]]

return {

    -- nor_ddz_nor_xsyd = nil,

	nor_ddz_er = 
	{
		multi={
			1,2,3,
		},
		weight={
			1,1,4,
		},
		min_time=20,
		max_time=40,

		sort_score=60,--按照分数排序的概率百分比
	},

	nor_ddz_nor = 
	{
		multi={
			1,2,3,
		},
		weight={
			1,1,4,
		},
		min_time=20,
		max_time=40,

		sort_score=60,--按照分数排序的概率百分比
	},

	nor_mj_xzdd = 
	{
		multi={
			0,2,3,
		},
		weight={
			1,1,4,
		},
		min_time=20,
		max_time=40,

		sort_score=60,--按照分数排序的概率百分比
	},

	nor_mj_xzdd_er_7 = 
	{
		multi={
			0,2,3,
		},
		weight={
			1,1,4,
		},
		min_time=20,
		max_time=40,

		sort_score=60,--按照分数排序的概率百分比
	},

	nor_mj_xzdd_er_13 = 
	{
		multi={
			0,2,3,
		},
		weight={
			1,1,4,
		},
		min_time=20,
		max_time=40,

		sort_score=60,--按照分数排序的概率百分比
	},

}