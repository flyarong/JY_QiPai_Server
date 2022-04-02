--- 炸弹场 斗地主 托管好牌的配置

local config = {}

--- 牌型类型
local PAI_TYPE = {
	danpai = "danpai",
	duizi = "duizi",
	liandui = "liandui",
	sanzhang = "sanzhang",
	shunzi = "shunzi",
	shuangfei = "shuangfei",
	boom = "boom",
	shuangwang = "shuangwang",
}

--- 概率类型
local GAILV_TYPE = {
		random = 1,               --- 完全随机
		Z_ratio_by_power = 2,     --- 根据控制力度正比例
		F_ratio_by_power = 3,     --- 根据控制力度负比例
		fix_all = 4,              --- 填补
	}

-------------------------------------------------------------------------------------------------------------------------------------------
--- 垃圾牌生成策略
local laji_pai_create = {
	[1] = {
		--[1] = { pai_type = PAI_TYPE.danpai  , min_num = 0, max_num = 2 , min_pai = 16 , max_pai = 17, gailv_type = GAILV_TYPE.random },
		[1] = { pai_type = PAI_TYPE.boom  , min_num = 1, max_num = 2 , min_pai = 3 , max_pai = 15, gailv_type = GAILV_TYPE.random },
		[2] = { pai_type = PAI_TYPE.danpai  , min_num = 0, max_num = 0 , min_pai = 3 , max_pai = 17, gailv_type = GAILV_TYPE.fix_all },
	},
	[2] = {
		[1] = { pai_type = PAI_TYPE.boom  , min_num = 1, max_num = 2 , min_pai = 3 , max_pai = 15, gailv_type = GAILV_TYPE.random },
		[2] = { pai_type = PAI_TYPE.danpai  , min_num = 0, max_num = 0 , min_pai = 3 , max_pai = 16, gailv_type = GAILV_TYPE.fix_all },
	},
	[3] = {
		[1] = { pai_type = PAI_TYPE.boom  , min_num = 1, max_num = 2 , min_pai = 3 , max_pai = 15, gailv_type = GAILV_TYPE.random },
		[2] = { pai_type = PAI_TYPE.danpai  , min_num = 0, max_num = 0 , min_pai = 3 , max_pai = 15, gailv_type = GAILV_TYPE.fix_all },
	},
	[4] = {
		[1] = { pai_type = PAI_TYPE.boom  , min_num = 1, max_num = 2 , min_pai = 3 , max_pai = 14, gailv_type = GAILV_TYPE.random },
		[2] = { pai_type = PAI_TYPE.danpai  , min_num = 0, max_num = 0 , min_pai = 3 , max_pai = 15, gailv_type = GAILV_TYPE.fix_all },
	},
	[5] = {
		[1] = { pai_type = PAI_TYPE.boom  , min_num = 2, max_num = 3 , min_pai = 3 , max_pai = 14, gailv_type = GAILV_TYPE.random },
		[2] = { pai_type = PAI_TYPE.danpai  , min_num = 0, max_num = 0 , min_pai = 3 , max_pai = 14, gailv_type = GAILV_TYPE.fix_all },
	},
	[6] = {
		[1] = { pai_type = PAI_TYPE.boom  , min_num = 1, max_num = 2 , min_pai = 3 , max_pai = 13, gailv_type = GAILV_TYPE.random },
		[2] = { pai_type = PAI_TYPE.danpai  , min_num = 0, max_num = 2 , min_pai = 15 , max_pai = 15, gailv_type = GAILV_TYPE.random },
		[3] = { pai_type = PAI_TYPE.danpai  , min_num = 0, max_num = 0 , min_pai = 3 , max_pai = 14, gailv_type = GAILV_TYPE.fix_all },
	},
}

local haopai_type_gailv = {
	[1] = {
		danpai = 60,
		duizi = 50,
		liandui = 40,
		sanzhang = 40,
		shunzi = 40,
		shuangfei = 40,
		boom = 5,
		shuangwang = 20,
		shuangwang_dan = 80,
	},
	[2] = {
		danpai = 60,
		duizi = 50,
		liandui = 40,
		sanzhang = 40,
		shunzi = 40,
		shuangfei = 40,
		boom = 5,
		shuangwang = 20,
		shuangwang_dan = 80,
	},
	[3] = {
		danpai = 60,
		duizi = 50,
		liandui = 40,
		sanzhang = 40,
		shunzi = 40,
		shuangfei = 40,
		boom = 5,
		shuangwang = 20,
		shuangwang_dan = 80,
	},
	[4] = {
		danpai = 60,
		duizi = 50,
		liandui = 40,
		sanzhang = 40,
		shunzi = 40,
		shuangfei = 40,
		boom = 5,
		shuangwang = 20,
		shuangwang_dan = 80,
	},
	[5] = {
		danpai = 60,
		duizi = 50,
		liandui = 40,
		sanzhang = 40,
		shunzi = 40,
		shuangfei = 40,
		boom = 5,
		shuangwang = 20,
		shuangwang_dan = 80,
	},
	[6] = {
		danpai = 60,
		duizi = 50,
		liandui = 40,
		sanzhang = 40,
		shunzi = 40,
		shuangfei = 40,
		boom = 5,
		shuangwang = 20,
		shuangwang_dan = 80,
	},
}

config.pai_map = {
	[3] = 4,
	[4] = 4,
	[5] = 4,
	[6] = 4,
	[7] = 4,
	[8] = 4,
	[9] = 4,
	[10] = 4,
	[11] = 4,
	[12] = 4,
	[13] = 4,
	[14] = 4,
	[15] = 4,
	[16] = 1,
	[17] = 1,
}

local hao_pai_gailv = {
	default = 65,
	freestyle = {
		[33] = 65,
		[34] = 65,
		[35] = 65,
		[36] = 65,
		
	},
	matchstyle = {
		
	},

}

local hao_pai_gailv2 = {
	default = 70,
	freestyle = {
		[33] = 70,
		[34] = 70,
		[35] = 70,
		[36] = 70,
		
	},
	matchstyle = {
		
	},

}

local hao_pai_gailv3 = {
	default = 75,
	freestyle = {
		[33] = 75,
		[34] = 75,
		[35] = 75,
		[36] = 75,
		
	},
	matchstyle = {
		
	},

}

local hao_pai_gailv4 = {
	default = 80,
	freestyle = {
		[33] = 80,
		[34] = 80,
		[35] = 80,
		[36] = 80,
		
	},
	matchstyle = {
		
	},

}

local hao_pai_gailv5 = {
	default = 90,
	freestyle = {
		[33] = 90,
		[34] = 90,
		[35] = 90,
		[36] = 90,
		
	},
	matchstyle = {
		
	},

}


config.grade = {
	[1] = {
		laji_pai_create = laji_pai_create[1],
		min_boom_num = 5,
		max_boom_num = 6,
		select_boom_type = "max",
		haopai_type_gailv = haopai_type_gailv[1],
		fa_hao_pai_gailv = hao_pai_gailv,
		is_broke_remain_boom = true,
	},
	[2] = {
		laji_pai_create = laji_pai_create[2],
		min_boom_num = 5,
		max_boom_num = 7,
		select_boom_type = "max",
		haopai_type_gailv = haopai_type_gailv[3],
		fa_hao_pai_gailv = hao_pai_gailv2,
		is_broke_remain_boom = true,
	},
	[3] = {
		laji_pai_create = laji_pai_create[3],
		min_boom_num = 5,
		max_boom_num = 7,
		select_boom_type = "max",
		haopai_type_gailv = haopai_type_gailv[3],
		fa_hao_pai_gailv = hao_pai_gailv3,
		is_broke_remain_boom = true,
	},
	[4] = {
		laji_pai_create = laji_pai_create[4],
		min_boom_num = 5,
		max_boom_num = 7,
		select_boom_type = "max",
		haopai_type_gailv = haopai_type_gailv[4],
		fa_hao_pai_gailv = hao_pai_gailv4,
		is_broke_remain_boom = true,
	},
	[5] = {
		laji_pai_create = laji_pai_create[5],
		min_boom_num = 4,
		max_boom_num = 9,
		select_boom_type = "max",
		haopai_type_gailv = haopai_type_gailv[5],
		fa_hao_pai_gailv = hao_pai_gailv5,
		is_broke_remain_boom = true,
		extra_boom_num = 1,
	},
	[6] = {
		laji_pai_create = laji_pai_create[6],
		min_boom_num = 4,
		max_boom_num = 8,
		select_boom_type = "max",
		haopai_type_gailv = haopai_type_gailv[5],
		fa_hao_pai_gailv = hao_pai_gailv,
		is_broke_remain_boom = true,
	},
}


return config