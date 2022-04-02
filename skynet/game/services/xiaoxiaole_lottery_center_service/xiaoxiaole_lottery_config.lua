local base=require "base"
local DATA=base.DATA


----- lucky 基础配置
DATA.lucky_base = {
	max_lucky_num_min = 0.3,
	max_lucky_num_max = 0.7,
	max_lucky_num = 6,
}

----- 3连的配置
DATA.lian3_lucky = {
	{ lian3_num = 0 , weight = 80 , true_rate = 70 },
	{ lian3_num = 1 , weight = 10 , true_rate = 70 },
	{ lian3_num = 2 , weight = 10 , true_rate = 70 },

}

----- 3连是真的配置
DATA.lian3_real_lucky = {
	--- 不要只有3个的真3连
	--{ lian_num = 3 , weight = 0 },

	{ lian_num = 4 , weight = 60 },
	{ lian_num = 5 , weight = 40 },
}

----- 3连是假的配置
DATA.lian3_fake_lucky = {
	--- 不要3连
	--[[
	{ lian_num = 3 , weight = 20 },--]]

	{ lian_num = 2 , weight = 20 },
	{ lian_num = 4 , weight = 60 },
	{ lian_num = 5 , weight = 20 },

}

----- 假5连的真4连 概率
DATA.lian4_5lian_gl = 30
