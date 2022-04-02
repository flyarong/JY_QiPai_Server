
local skynet = require "skynet_plus"
local basefunc = require "basefunc"
require"printfunc"
local nor_mj_base_lib = require "nor_mj_base_lib"

local nor_mj_room_lib={}

nor_mj_room_lib.flowers =
{
	[1]=true,
	[2]=true,
	[3]=true,
}

---- 麻将发牌的数量
nor_mj_room_lib.fapai_num = 13

---- 麻将的座位的数量
nor_mj_room_lib.seat_count = 4

local fahaopai_algorithm=require "mj_fahaopai_algorithm_lib"

-- 托管 在玩家未听牌时 胡牌的概率
nor_mj_room_lib.hupai_prob_not_ting = 30
-- 托管 在玩家听牌时 胡牌的概率
nor_mj_room_lib.hupai_prob_ting = 70



-- 调试模式的洗牌
local function debug_pai_pool()

	-- gang
	local _pai={
			11,12,13,14,15,16,17,18,19,
			11,12,13,14,15,16,17,18,19,
			11,12,13,14,15,16,17,18,19,
			11,12,13,14,15,16,17,18,19,

			24,25,26,27,28,29,
			24,25,26,27,28,29,
			24,25,26,27,28,29,
			28,29,

			21,22,23,
			21,22,23,
			21,22,23,
			21,22,23,24,

			34,35,36,
			34,35,36,
			34,35,36,
			34,35,36,25,

			37,38,39,
			37,38,39,
			37,38,39,
			37,38,39,26,

			31,32,33,
			31,32,33,
			31,32,33,
			31,32,33,27,
		}

	-- 7 dui
	-- local _pai={
	-- 		16,17,18,19,
	-- 		11,12,13,14,15,16,
	-- 		11,12,13,14,15,16,19,
	-- 		11,12,13,14,15,16,

	-- 		21,22,23,24,25,26,27,28,
	-- 		21,22,23,24,25,26,27,28,29,

	-- 		27,28,
	-- 		27,28,

	-- 		17,17,18,19,18,29,
	-- 		11,12,29,13,14,15,

	-- 		21,22,23,24,25,26,
	-- 		21,22,23,24,25,26,17,

	-- 		34,35,36,37,38,39,
	-- 		34,35,36,37,38,39,18,

	-- 		37,38,39,31,32,33,
	-- 		37,38,39,31,32,33,19,

	-- 		31,32,33,34,35,36,
	-- 		31,32,33,34,35,36,29,
	-- 	}


	-- -- da dui zi
	-- local _pai={
	-- 		11,12,13,14,15,
	-- 		11,12,13,14,15,
	-- 		11,12,13,14,15,
	-- 		15,

	-- 		21,22,23,24,25,26,27,28,29,
	-- 		28,39,
	-- 		28,39,
	-- 		28,39,

	-- 		31,32,33,34,35,36,37,38,39,

	-- 		16,17,18,19,
	-- 		16,17,18,19,
	-- 		16,17,18,19,

	-- 		11,12,13,14,

	-- 		24,25,26,27,
	-- 		24,25,26,27,
	-- 		24,25,26,27,16,

	-- 		29,21,22,23,
	-- 		29,21,22,23,
	-- 		29,21,22,23,17,

	-- 		35,36,37,38,
	-- 		35,36,37,38,
	-- 		35,36,37,38,18,

	-- 		31,32,33,34,
	-- 		31,32,33,34,
	-- 		31,32,33,34,19,
	-- 	}



	-- -- long qi dui
	-- local _pai={
	-- 		16,17,18,19,
	-- 		11,12,13,14,15,16,
	-- 		11,12,13,14,15,16,19,
	-- 		11,12,13,14,15,16,

	-- 		26,21,23,24,25,26,27,28,
	-- 		26,21,23,24,25,26,27,28,29,

	-- 		27,28,
	-- 		27,28,

	-- 		17,17,18,19,18,29,
	-- 		11,12,29,13,14,15,

	-- 		22,21,22,23,24,25,
	-- 		22,21,22,23,24,25,17,

	-- 		37,35,36,37,38,39,
	-- 		37,35,36,37,38,39,18,

	-- 		33,38,34,39,32,33,
	-- 		33,38,34,39,32,33,19,

	-- 		31,31,32,34,35,36,
	-- 		31,31,32,34,35,36,29,
	-- 	}


	-- -- qing yi se - 7 dui
	-- local _pai={
	-- 		11,12,13,14,15,16,17,18,
	-- 		11,12,13,14,15,16,17,18,
	-- 		17,18,
	-- 		17,18,19,

	-- 		21,22,23,24,25,26,27,28,29,
	-- 		21,22,23,24,25,26,27,28,
	-- 		27,28,
	-- 		27,28,

	-- 		37,38,39,


	-- 		29,29,19,19,
	-- 		37,38,39,39,38,37,37,

	-- 		11,12,13,14,15,16,
	-- 		11,12,13,14,15,16,19,

	-- 		21,22,23,24,25,26,
	-- 		21,22,23,24,25,26,29,

	-- 		31,32,33,34,35,36,
	-- 		31,32,33,34,35,36,38,

	-- 		31,32,33,34,35,36,
	-- 		31,32,33,34,35,36,39,
	-- 	}


	-- -- qing yi se
	-- local _pai={
	-- 		11,12,13,14,15,16,17,18,
	-- 		11,12,13,14,15,16,17,
	-- 		17,18,19,
	-- 		14,18,

	-- 		24,25,26,27,28,29,
	-- 		21,22,23,24,29,
	-- 		27,28,29,
	-- 		21,22,23,24,25,26,27,29,

	-- 		31,33,34,37,38,
	-- 		31,34,37,38,

	-- 		39,28,19,18,19,

	-- 		11,12,13,14,15,16,
	-- 		11,12,13,15,16,17,19,

	-- 		21,22,23,24,25,26,
	-- 		21,22,23,25,26,27,28,

	-- 		31,32,33,37,38,39,
	-- 		32,34,35,37,38,39,36,

	-- 		31,32,33,36,36,36,
	-- 		32,33,34,35,35,35,39,
	-- 	}


	-- -- qing long qi dui
	-- local _pai={
	-- 		11,12,13,14,15,16,17,18,19,
	-- 		11,12,13,14,15,16,17,18,19,
	-- 		11,12,13,14,15,16,17,18,19,
	-- 		11,12,13,14,15,16,17,18,19,

	-- 		22,23,24,26,

	-- 		32,33,34,35,36,
	-- 		38,39,28,

	-- 		29,29,27,28,37,38,37,39,

	-- 		32,33,34,35,36,
	-- 		35,38,39,37,
	-- 		35,38,39,29,

	-- 		22,23,24,26,
	-- 		25,26,27,28,
	-- 		25,26,27,28,29,

	-- 		21,21,21,21,
	-- 		22,23,24,25,
	-- 		22,23,24,25,27,

	-- 		31,31,31,31,
	-- 		32,33,34,36,
	-- 		32,33,34,36,37,

	-- 	}


	-- duan yao jiu
	-- local _pai={
	-- 		11,12,13,14,15,16,17,18,19,
	-- 		11,12,13,14,15,16,17,18,19,
	-- 		11,12,13,14,15,16,17,18,19,
	-- 		11,12,13,14,15,16,17,18,19,

	-- 		21,22,29,

	-- 		31,31,36,37,39,


	-- 		31,36,38,39,28,37,28,38,35,38,39,
	-- 		31,

	-- 		21,22,23,24,25,26,
	-- 		21,29,27,21,29,29,39,

	-- 		32,33,34,23,24,25,
	-- 		32,33,34,26,27,28,28,

	-- 		32,33,34,35,36,37,
	-- 		22,23,24,25,26,27,35,

	-- 		32,33,34,35,36,37,
	-- 		22,23,24,25,26,27,38,

	-- 	}

	-- jiang dui
	-- local _pai={
	-- 	11,13,14,16,17,19,
	-- 	11,13,14,16,17,19,
	-- 	11,13,14,16,17,19,
	-- 	11,12,13,14,15,16,17,19,

	-- 	21,23,24,26,27,29,
	-- 	21,23,24,26,27,29,
	-- 	21,29,
	-- 	21,22,23,24,25,26,27,28,29,

	-- 	31,33,34,18,36,18,39,

	-- 	32,33,34,35,36,37,38,
	-- 	31,33,34,36,37,31,

	-- 	31,33,34,36,37,39,39,
	-- 	23,24,26,27,37,39,

	-- 	32,35,12,15,18,
	-- 	32,35,12,15,
	-- 	32,35,12,15,

	-- 	22,25,28,38,
	-- 	22,25,28,38,
	-- 	22,25,28,38,18,

	-- }


	-- 天胡
	--[[local _pai={

			26,28,
			26,28,
			
			26,33,34,35,
			35,11,

			36,36,37,37,37,38,38,38,39,39,39,
			31,31,31,32,32,32,33,33,33,34,34,34,35,
			21,21,22,22,24,24,36,25,35,39,25,

			18,19,15,31,32,15,15,36,37,38,17,

			11,11,11,12,12,12,13,13,13,14,15,16,17,
			17,18,19,16,16,16,21,22,23,14,14,18,19,
			29,29,29,23,23,24,24,25,25,27,28,29,17,
			21,22,23,26,27,28,12,13,14,27,27,18,19,
		}--]]

	-- 地胡
	-- local _pai={

	-- 		26,28,
	-- 		26,28,
			
	-- 		26,33,34,35,
	-- 		35,11,

	-- 		36,36,37,37,37,38,38,38,39,39,39,
	-- 		31,31,31,32,32,32,33,33,33,34,34,34,35,
	-- 		21,22,22,24,24,36,25,35,39,25,

	-- 		18,19,15,31,32,36,37,38,17,18,19,17,

	-- 		11,11,11,12,12,12,13,13,13,14,15,16,17,
	-- 		17,18,19,16,16,16,21,22,23,14,14,15,15,
	-- 		29,29,29,23,23,24,24,25,25,27,28,29,21,
	-- 		21,22,23,26,27,28,12,13,14,27,27,18,19,
	-- 	}


	-- 杠上炮 ; 转雨
	local _pai={
			35,35,36,36,
			34,33,33,33,
			28,28,

			29,29,37,37,37,38,38,38,39,39,39,
			29,28,39,38,37,36,36,35,35,34,34,34,33,
			19,19,19,18,18,18,17,17,17,16,16,

			16,14,15,13,15,13,15,13,14,14,13,

			23,24,25,26,27,28,29,14,15,16,17,18,19,
			31,31,31,31,32,32,32,32,23,24,25,26,27,
			11,11,11,11,12,12,12,12,23,24,25,26,27,
			21,21,21,21,22,22,22,22,23,24,25,26,27,
		}

	-- 一手好牌 过手胡
	-- local _pai={


	-- 		26,11,28,
	-- 		26,28,
	-- 		26,
	-- 		34,34,34,35,
	-- 		35,

	-- 		36,36,36,37,37,37,38,38,38,39,39,39,27,
	-- 		21,21,22,22,22,23,23,23,24,24,24,36,25,
	-- 		16,17,18,19,16,17,18,19,16,17,18,19,16,

	-- 		18,19,15,15,15,21,

	-- 		26,27,28,29,31,31,31,32,32,32,33,33,33,
	-- 		35,27,27,29,29,29,24,12,13,25,17,25,38,
	-- 		14,21,22,23,31,32,33,34,35,39,28,25,37,
	-- 		11,11,11,12,12,12,13,13,13,14,14,14,15,
	-- 	}
	--一炮多响
	-- local _pai={

	-- 		16,17,18,19,
	-- 		16,17,18,19,
	-- 		16,17,18,19,
	-- 		16,17,18,19,

	-- 		26,11,28,
	-- 		26,28,
	-- 		26,
	-- 		26,27,28,29,
	-- 		35,36,38,37,

	-- 		15,35,15,27,27,29,29,29,24,12,13,
	-- 		14,21,22,23,31,32,33,34,35,39,15,28,25,25,25,
	-- 		36,36,36,37,37,37,38,38,24,39,21,33,11,
	-- 		11,12,13,14,15,16,31,32,33,33,33,31,37,
	-- 		24,25,26,27,28,29,12,13,14,14,15,16,21,
	-- 		24,25,26,27,28,29,12,13,14,14,15,16,21,
	-- 		24,25,26,27,28,29,12,13,14,14,15,16,21,
	-- 	}
	--弯杠和抢杠胡
	--[[local _pai={

			16,17,18,19,
			16,17,18,19,
			16,17,18,19,
			16,17,18,19,

			26,11,28,
			26,28,
			26,
			26,27,28,29,
			35,36,38,37,

			15,35,15,27,27,29,29,29,24,12,13,
			14,21,22,23,31,32,33,34,35,39,15,28,25,25,25,
			36,36,36,37,35,38,38,16,38,21,33,16,

			21,35,36,36,35,35,34,34,19,19,19,18,18,
			11,12,13,14,13,13,16,16,39,39,39,39,38,
			24,25,26,27,28,29,12,13,14,14,15,21,21,
			31,31,31,32,33,34,37,11,11,22,22,36,36,
		}--]]
	--弯杠
	-- local _pai={
	-- 38,38,37,36,22,23,24,25,26,27,28,26,27,33,34,34,36,36,29,38,39,28,
	-- 12,11,35,23,39,39,37,
	-- 32,
	-- 21,22,23,24,25,26,27,28,31,33,35,17,17,
	-- 21,22,23,24,25,26,27,28,31,33,35,17,17,
	-- 21,22,23,24,25,31,32,33,38,39,36,11,12,
	-- 11,11,12,12,13,13,14,14,21,24,26,28,31,
	-- }

	--杠但无叫
	-- local _pai={
	--
	--
	-- 		19,36,31,31,19,36,37,35,14,38,14,25,25,38,14,36,36,36,36,28,28,28,28,
	--
	-- 		19,19,19,14,14,14,12,11,13,31,32,13,36,
	-- 		39,39,39,38,36,36,36,27,28,29,36,38,37,
	-- 		24,24,24,25,25,25,26,27,28,29,21,21,22,
	-- 		31,32,33,35,36,37,26,27,28,22,23,24,28,
	-- 	}

	--快速胡牌结束
	-- local _pai={
	-- 
	-- 
	-- 		28,28,
	-- 
	-- 		19,19,19,14,14,14,12,11,13,31,32,13,36,
	-- 		39,39,39,38,36,36,36,27,28,29,36,38,37,
	-- 		24,24,24,25,25,25,26,27,28,29,21,21,22,
	-- 		31,32,33,35,36,37,26,27,28,22,23,24,28,
	-- 	}

	-- local _pai={
	-- 		11,12,13,14,15,16,17,18,19,
	-- 		11,12,13,14,15,16,17,18,19,
	-- 		11,12,13,14,15,16,17,18,19,
	-- 		11,12,13,14,15,16,17,18,19,
	
	-- 		21,22,23,24,25,26,27,28,29,
	-- 		21,22,23,24,25,26,27,28,29,
	-- 		21,22,23,24,25,26,27,28,29,
	-- 		21,22,23,24,25,26,27,28,29,
	
	-- 		31,32,33,34,35,36,37,38,39,
	-- 		31,32,33,34,35,36,37,38,39,
	-- 		31,32,33,34,35,36,37,38,39,
	-- 		31,32,33,34,35,36,37,38,39,
	-- 	}

	-- 查叫： 花猪、无叫
	--[[local _pai={
		19,12,13,
		15,26,17,18,14,11,29,19,29,15,26,17,18,

		32,33,34,31,31,31,35,35,35,36,36,36,15,
		22,23,24,21,21,21,25,25,25,26,26,26,35,
		12,13,14,11,11,11,15,15,15,16,16,16,25,
	 }--]]


	---- 我抢杠胡
	--[[local _pai = {
			39,39,39,39,38,38,38,38,37,37,37,
			36,36,35,34,34,33,29,29,29,15,28,
			28,28,27,27,26,25,25,22,21,19,19,
			19,19,18,18,18,31,11,31,11,31,11,
			31,11,31,11,31,11,31,11,31,11,31,27,

			
			
			
			31,32,33,34,35,36,27,21,22,23,24,25,26,
			31,31,32,32,34,34,35,35,37,37,38,38,39,
			11,12,13,14,15,16,27,21,22,23,24,25,26,
			11,11,12,12,14,14,15,15,17,17,18,18,19,
		}--]]


	return _pai
end

local function random_list(list)
	local _count=#list
	local _rand=1
	local _jh
	for _i=1,_count-1 do
		_jh=list[_i]
		_rand=math.random(_i,_count)
		list[_i]=list[_rand]
		list[_rand]=_jh
	end
end
nor_mj_room_lib.random_list = random_list

--洗牌
local function new_pai_pool() 

	local _pai={
			11,12,13,14,15,16,17,18,19,
			11,12,13,14,15,16,17,18,19,
			11,12,13,14,15,16,17,18,19,
			11,12,13,14,15,16,17,18,19,

			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,

			31,32,33,34,35,36,37,38,39,
			31,32,33,34,35,36,37,38,39,
			31,32,33,34,35,36,37,38,39,
			31,32,33,34,35,36,37,38,39,
		}

	random_list(_pai)

	return _pai
end

--洗牌 - 没有 万字牌
local function new_pai_pool_no_wan()

	local _pai={
			11,12,13,14,15,16,17,18,19,
			11,12,13,14,15,16,17,18,19,
			11,12,13,14,15,16,17,18,19,
			11,12,13,14,15,16,17,18,19,

			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,
		}

	random_list(_pai)

	return _pai
end

--洗牌 - 没有 万字牌
local function debug_pai_pool_no_wan()

	local _pai={
			11,12,13,14,15,16,17,18,19,
			11,12,13,14,15,16,17,18,19,
			11,12,13,14,15,16,17,18,19,
			11,12,13,14,15,16,17,18,19,
	
			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,
		}

	--[[-- 一手好牌，天胡
	 local _pai={
			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,

			15,16,17,18,19,
			15,16,17,18,19,
			15,16,17,18,19,
			15,16,17,18,19,


	 		14,14,11,11,
	 		14,14,13,13,
	 		12,12,13,13,
	 		11,11,12,12,
	 	}--]]

	 --[[-- 一手好牌，天胡 6 番]]
	 local _pai={
			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,

			15,16,17,18,19,
			15,16,17,18,19,
			15,16,17,18,19,
			15,16,17,18,19,


	 		14,14,12,12,
	 		14,14,13,13,
	 		12,12,13,13,
	 		11,11,11,11,
	 	}

	-- 地胡
	 local _pai={
			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,
			21,22,23,24,25,26,27,28,

			15,16,17,18,
			15,16,17,18,
			15,16,17,18,19,12,13,
			15,16,17,18,14,11,19,19,29,


	 		12,13,14,13,12,14,19,
	 		12,13,14,11,11,11,29,
	 	}

	-- 一手好牌，杠
	-- local _pai={
	-- 		21,22,23,24,25,26,27,28,29,
	-- 		21,22,23,24,25,26,27,28,29,
	-- 		21,22,23,24,25,26,27,28,29,
	-- 		21,22,23,24,25,26,27,28,29,
	--
	-- 		15,16,17,18,19,
	-- 		15,16,17,18,19,
	-- 		15,16,17,18,19,
	-- 		15,16,17,18,19,
	--
	--
	--  		14,14,14,14,
	--  		13,13,13,13,
	--  		12,12,12,12,
	--  		11,11,11,11,
	--  	}

	-- 一手好牌，快速结束
	-- local _pai={
	-- 
	--  		15,13,
	-- 
	--  		13,13,13,14,14,14,15,
	--  		11,11,11,12,12,12,13,
	--  	}

	-- 一手好牌，暗杠
	-- local _pai={
	--
	--  		25,12,12,14,14,
	--
	--  		13,13,13,14,14,14,15,
	--  		11,11,11,12,12,12,18,
	--  	}

	 -- local _pai={
	
	 --  		31,32,33,34,36,37,38,39,
	 -- 		31,32,33,34,36,37,38,39,
	 -- 		31,32,33,34,37,38,39,
	 -- 		31,32,33,34,37,38,39,
	
	 -- 		17,17,17,17,
	 -- 		18,18,18,18,
	 -- 		19,19,19,19,

	 -- 		11,12,13,14,15,16,
	 -- 		11,12,13,14,15,16,
	
	 -- 		35,35,36,36,

	 --  		11,12,13,14,15,16,35,
	 --  		11,12,13,14,15,16,35,
	 --  	}

	return _pai
end

--洗牌 - 没有 万字牌
local function new_pai_pool_no_wan_qhtg(qhtg_data)
	local data=qhtg_data.hp_type
	local hu_pai=qhtg_data.hp_pai
	local r_pai={}
	local max_len=0
	if data then
		for pos,_d in pairs(data) do
			for _,v in pairs(_d) do
				r_pai[_d]=r_pai[_d] or 0
				r_pai[_d]=r_pai[_d]+1
			end
			if pos>max_len and _d then
				max_len=pos
			end
		end
	end
	local _pai_1={
			11,12,13,14,15,16,17,18,19,
			11,12,13,14,15,16,17,18,19,
			11,12,13,14,15,16,17,18,19,
			11,12,13,14,15,16,17,18,19,

			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,
		}
	local _pai={}
	--要胡的牌先加入的栈底部
	for _,_d in pairs(hu_pai) do
		_pai[#_pai+1]=_d
	end
	
	for _,_d in ipairs(_pai_1) do
		if not r_pai[_d] or r_pai[_d]==0 then
			_pai[#_pai+1]=_d
		else
			r_pai[_d]=r_pai[_d]-1
		end
	end

	local _count=#_pai
	local _rand=1
	local _jh
	for _i=1,_count-1 do
		_jh=_pai[_i]
		_rand=math.random(_i,_count)
		_pai[_i]=_pai[_rand]
		_pai[_rand]=_jh
	end
	for i=max_len,i>0,-1 do
		if data[i] then
			for _,v in pairs(data[i]) do
				_pai[#_pai+1]=v
			end
		end
	end

	return _pai
end


local function get_xsyd_real_player_seat(_d)
	local player_seat = nil
	for i,v in ipairs(_d.p_info) do
		if basefunc.chk_player_is_real(v.id) then
			player_seat=v.seat_num
			break
		end
	end
	return player_seat
end


local function fapai_nor(_d,_zhuang_seat,zhangshu)
	local fapaiNum = nor_mj_room_lib.fapai_num

	zhangshu=zhangshu or 4
	if zhangshu> fapaiNum then
		zhangshu=fapaiNum
	end

	local _play_data = _d.play_data

	-- 先每人发 N 张
	local _len = #_play_data.pai_pool
	local _count=fapaiNum
	local _pai
	while _count>0 do
		for i=1,nor_mj_room_lib.seat_count do
			for j=1,zhangshu do
				_pai=_play_data.pai_pool[_len]
				_play_data[i].pai[_pai] = (_play_data[i].pai[_pai] or 0) + 1
				_play_data.pai_pool[_len]=nil
				_len=_len-1
			end
		end
		_count=_count-zhangshu
		if zhangshu>_count then
			zhangshu=_count
		end
	end

	-- 庄家再发一张
	_pai=nor_mj_room_lib.pop_pai(_d)
	_play_data[_zhuang_seat].pai[_pai] = (_play_data[_zhuang_seat].pai[_pai] or 0) + 1

end

local function fapai_special(_d,_zhuang_seat,zhangshu)
	local fapaiNum = nor_mj_room_lib.fapai_num
	zhangshu=zhangshu or 4
	if zhangshu> fapaiNum then
		zhangshu=fapaiNum
	end

	--发牌
	local _play_data = _d.play_data

	-- 先每人发 N 张
	local _len = #_play_data.pai_pool
	local _count=fapaiNum
	local _pai
	while _count>0 do
		for i=1,nor_mj_room_lib.seat_count do
			--- 不给控制的托管发牌
			if not _d.special_deal_data[i] then
				for j=1,zhangshu do
					_pai=_play_data.pai_pool[_len]
					_play_data[i].pai[_pai] = (_play_data[i].pai[_pai] or 0) + 1
					_play_data.pai_pool[_len]=nil
					_len=_len-1
				end
			end
		end
		_count=_count-zhangshu
		if zhangshu>_count then
			zhangshu=_count
		end
	end
	-- 庄家再发一张
	_pai=nor_mj_room_lib.special_pop_pai(_d,_zhuang_seat)
	_play_data[_zhuang_seat].pai[_pai] = (_play_data[_zhuang_seat].pai[_pai] or 0) + 1

end

local function fapai_xsyd(_d,_zhuang_seat,_zhangshu)
	local fapaiNum = nor_mj_room_lib.fapai_num

	fapai_nor(_d,_zhuang_seat,_zhangshu)
	local seat = get_xsyd_real_player_seat(_d)

	_d.play_data[seat].pai,_d.play_data.pai_pool=_d.mj_algo:adjust_nice_pai(_d.play_data[seat].pai,_d.play_data.pai_pool)

	-- local _play_data = _d.play_data
	-- zhangshu=13

	-- local pl = #_play_data.pai_pool - zhangshu*p
	-- local pr = pl + zhangshu

	-- local r = math.random(7,10)

	-- local ph = nor_mj_base_lib.flower(_play_data.pai_pool[pl])
	-- local pol_idx = 1
	-- for pp=pl+1,pr do
		
	-- 	local cp = _play_data.pai_pool[pp]
	-- 	if nor_mj_base_lib.flower(cp) ~= ph then

	-- 		for pi=pol_idx,#_play_data.pai_pool do
				
	-- 			local cp = _play_data.pai_pool[pi]
	-- 			if nor_mj_base_lib.flower(cp) == ph then

	-- 				_play_data.pai_pool[pi],_play_data.pai_pool[pp] =
	-- 				_play_data.pai_pool[pp],_play_data.pai_pool[pi]

	-- 				pol_idx = pi+1
	-- 				break
	-- 			end

	-- 		end

	-- 	end

	-- 	r = r - 1
	-- 	if r < 1 then
	-- 		break
	-- 	end

	-- end

	-- -- 先每人发 N 张
	-- local _len = #_play_data.pai_pool
	-- local _count=fapaiNum
	-- local _pai
	-- while _count>0 do
	-- 	for i=1,nor_mj_room_lib.seat_count do
	-- 		for j=1,zhangshu do
	-- 			_pai=_play_data.pai_pool[_len]
	-- 			_play_data[i].pai[_pai] = (_play_data[i].pai[_pai] or 0) + 1
	-- 			_play_data.pai_pool[_len]=nil
	-- 			_len=_len-1
	-- 		end
	-- 	end
	-- 	_count=_count-zhangshu
	-- 	if zhangshu>_count then
	-- 		zhangshu=_count
	-- 	end
	-- end

	-- -- 庄家再发一张
	-- _pai=nor_mj_room_lib.pop_pai(_d)
	-- _play_data[_zhuang_seat].pai[_pai] = (_play_data[_zhuang_seat].pai[_pai] or 0) + 1

end

-- 定缺是否完成
function nor_mj_room_lib.is_ding_que_finished(_values,_seat_count)
	for i=1,(_seat_count or nor_mj_room_lib.seat_count) do
		if not _values[i] or not nor_mj_room_lib.flowers[_values[i]]  then
			return false
		end
	end

	return true
end

--发牌
function nor_mj_room_lib.fapai(_d,_zhuang_seat,zhangshu)

	--- 调试
	if nor_mj_room_lib.dev_debug then
		zhangshu = 13
		fapai_nor(_d,_zhuang_seat,zhangshu)
		print("------------------- fapai_dev_debug ")
		return
	end


	if _d.game_tag == "xsyd" then
		fapai_xsyd(_d,_zhuang_seat,zhangshu)
	else
		if _d.lucky_seat_num then
			fapai_nor(_d,_zhuang_seat,zhangshu)
			_d.play_data[_d.lucky_seat_num].pai, _d.play_data.pai_pool = _d.mj_algo:adjust_nice_pai( _d.play_data[_d.lucky_seat_num].pai , _d.play_data.pai_pool)
		elseif _d.play_data.tuoguan_ctrl then
			for seat_num,data in pairs(_d.special_deal_data) do
				for _,_pai in ipairs(data.fapai_list) do
					_d.play_data[seat_num].pai[_pai] = (_d.play_data[seat_num].pai[_pai] or 0) + 1
				end
			end
			fapai_special(_d,_zhuang_seat,zhangshu)
		else
			fapai_nor(_d,_zhuang_seat,zhangshu)
		end
	end

end


---- 把一个位置的牌调优
function nor_mj_room_lib.adjust_nice_pai(_play_data , _seat_num )

end


function nor_mj_room_lib.pai_count(_d)

	local _count = 0
	for _,_data in pairs(_d.special_deal_data) do
		_count = _count + #_data.mopai_list + (_data.hupai and 1 or 0)
	end

	return #_d.play_data.pai_pool + _count
end

function nor_mj_room_lib.pop_pai(_d)
	
	local _play_data=_d.play_data

	if _play_data.pai_empty then
		return nil
	end

	local len=#_play_data.pai_pool
	if len == 0 then
		return nil
	end
	
	local pai=_play_data.pai_pool[len]
	_play_data.pai_pool[len]=nil
	len=len-1
	if  len==0 then
		_play_data.pai_empty = true
	end
	
	return pai
	
end

-- 检查是否还 有 被保留的牌
local function has_remain_pai(_d)

	for _seat_num,_spec in pairs(_d.special_deal_data) do
		if _spec.hupai or next(_spec.mopai_list) then
			return true
		end
	end

	return false
end

-- 弹出被保留的牌（牌池摸完后使用）
local function pop_remain_pai(_d)

	-- 先拿 mopai_list
	for _seat_num,_spec in pairs(_d.special_deal_data) do
		if next(_spec.mopai_list) then
			local _pai = _spec.mopai_list[#_spec.mopai_list]
			_spec.mopai_list[#_spec.mopai_list] = nil
			print("pop_remain_pai from mopai_list:",_seat_num,_pai)

			if not has_remain_pai(_d) then
				_d.play_data.pai_empty = true
			end

			return _pai
		end	
	end

	-- 拿胡牌 list
	local _pai
	for _seat_num,_spec in pairs(_d.special_deal_data) do
		if _spec.hupai then
			if not _pai then
				_pai = _spec.hupai
				_spec.hupai = nil
				print("pop_remain_pai from hupai:",_seat_num,_pai)
			end
		end
	end

	if not has_remain_pai(_d) then
		_d.play_data.pai_empty = true
	end

	return _pai
end

function nor_mj_room_lib.special_pop_pool_pai(_d,_seat_num)

	local _play_data=_d.play_data

	if _play_data.pai_empty then
		return nil
	end

	local len=#_play_data.pai_pool
	if len == 0 then

		return pop_remain_pai(_d)
	end
	
	local pai=_play_data.pai_pool[len]

	-- 托管：如果 被控制托管 不允许 杠，则取 下一张
	local _spec = _d.special_deal_data[_seat_num]
	if _spec and not _spec.gang_map[pai] and 
		(_d.play_data[_seat_num].pg_pai[pai]==3 or _d.play_data[_seat_num].pai[pai]==3) then
		if len > 1 then
			pai=_play_data.pai_pool[len-1]
			_play_data.pai_pool[len-1] = _play_data.pai_pool[len]
		end
	end

	_play_data.pai_pool[len]=nil

	if 1 == len and not has_remain_pai(_d) then
		_play_data.pai_empty = true
	end
	
	return pai
	
end

function nor_mj_room_lib.has_flower(_pai_map,_flower)
	for _pai,_count in pairs(_pai_map) do
		if nor_mj_base_lib.flower(_pai) == _flower then
			return true
		end
	end

	return false
end

-- 托管：处理用自己内部 的 hupai 自摸
-- 返回: true/false
function nor_mj_room_lib.tuoguan_special_can_zimo(_d,_spec)

	-- 检查，有 为自己点炮的，则不 自摸
	if _spec.hu_pao and next(_spec.hu_pao) then
		for _seat2,_ in pairs(_spec.hu_pao) do
			if not _d.play_data[_seat2].hu_order then
				return false   -- 至少一个 点炮 人 还没胡
			end
		end
	end

	-- 统计真实玩家胡牌情况
	local _player_data 
	for _seat2,_pid in pairs(_d.real_player) do
		if not _d.play_data[_seat2].hu_order then

			if _player_data then
				return true 	-- 未胡牌 玩家 数量 大于 1 ，自然 胡牌
			end

			_player_data = _d.play_data[_seat2]
		end
	end

	-- 单个玩家
	if _player_data then
		if _player_data.ting_info then
			return math.random(100) <= nor_mj_room_lib.hupai_prob_ting
		else
			return math.random(100) <= nor_mj_room_lib.hupai_prob_not_ting
		end
	else    -- 没有 未胡牌玩家了，赶紧胡牌走人
		return true
	end
end



function nor_mj_room_lib.special_pop_pai(_d,_seat_num)
	
	local _spec = _d.special_deal_data[_seat_num]

	if _spec then

		-- 胡牌 步数  倒计时
		_spec.hupai_bushu_cd = _spec.hupai_bushu_cd - 1

		-- 托管： 已经听牌
		if _spec.hupai_bushu_cd < 1 and _d.play_data[_seat_num].ting_info then

			-- 判断是否可以自摸
			if nor_mj_room_lib.tuoguan_special_can_zimo(_d,_spec) then

				-- 弹出 hupai 自摸
				local _hupai = _spec.hupai
				if _hupai then	
					_spec.hupai = nil
					return _hupai,"zi_mo"
				end
			end
		end

		-- 如果A给B点炮，检查A是否能点炮 B
		if _spec.dianpao and next(_spec.dianpao) then

			local _dq = _d.play_data.p_ding_que[_seat_num]
			
			for _pao_seat,_ in pairs(_spec.dianpao) do
				local _spec2 = _d.special_deal_data[_pao_seat]
				if _spec2 and  _spec2.hupai_bushu_cd and _spec2.hupai_bushu_cd < 1 and _spec2.ting_pai then
					local _hupai = _spec2.hupai
					if _hupai and (nor_mj_base_lib.flower(_hupai) == _dq or not nor_mj_room_lib.has_flower(_pai_map,_dq)) then
						_spec2.hupai = nil
						_spec.dianpao[_pao_seat] = nil

						return _hupai,"dian_pao"
					end
				end
			end

		end

		if next(_spec.mopai_list) then

			local _pai = _spec.mopai_list[#_spec.mopai_list]
			_spec.mopai_list[#_spec.mopai_list] = nil
	
			return _pai,"mopai_list"
		end	
		
	end

	return nor_mj_room_lib.special_pop_pool_pai(_d,_seat_num)
end

-- 下一个 有操作 权座位号
function nor_mj_room_lib.next_oper_seat(_play_data,_cur_seat,_seat_count)
	for i=1,(_seat_count or nor_mj_room_lib.seat_count) do
		_cur_seat = math.fmod(_cur_seat,nor_mj_room_lib.seat_count) + 1

		-- 未胡牌的 才有发言权
		if not _play_data[_cur_seat].hu_order then
			return _cur_seat
		end
	end

	return nil
end

function nor_mj_room_lib.reset_seat_data(_datas,_value,_seat_count)
	for i=1,(_seat_count or nor_mj_room_lib.seat_count) do
		_datas[i] = basefunc.deepcopy(_value)
	end
end

function nor_mj_room_lib.seat_p_count(_datas,_seat_count)

	local _count = 0
	for i=1,(_seat_count or nor_mj_room_lib.seat_count) do
		if _datas[i] then
			_count = _count + 1
		end
	end

	return _count
end

function nor_mj_room_lib.set_game_type(_g_type)
	nor_mj_room_lib.game_type=_g_type
end

function nor_mj_room_lib.new_game(_seat_count,_g_type)

	local _play_data={}

	-- 庄家
	_play_data.zhuang_seat=0

	--当前有摸牌权限的人
	_play_data.cur_p=0

	-- 当前出牌
	_play_data.cur_chupai={p=nil,pai=nil}

	if _g_type then
		nor_mj_room_lib.set_game_type(_g_type)
	end

	nor_mj_room_lib.seat_count = _seat_count or 4

	-- 牌池
	if nor_mj_room_lib.dev_debug then

		if nor_mj_room_lib.game_type == "nor_mj_xzdd_er_7" or nor_mj_room_lib.game_type == "nor_mj_xzdd_er_13" then
			_play_data.pai_pool = debug_pai_pool_no_wan()
		else
			_play_data.pai_pool = debug_pai_pool()
		end

	else

		if nor_mj_room_lib.game_type == "nor_mj_xzdd_er_7" or nor_mj_room_lib.game_type == "nor_mj_xzdd_er_13" then
			_play_data.pai_pool = new_pai_pool_no_wan()
		else
			_play_data.pai_pool = new_pai_pool()
		end

	end

	_play_data.pai_empty = false -- 牌池是否为空

	--_play_data.remain_card_count=108

	-- 正在等待选择 碰杠胡的 人 seat_num => 函数 get_peng_gang_hu 返回的数据
	_play_data.wait_pengganghu_data={}

	-- 正在等待选择 胡的 人 seat_num => 胡牌类型 "zimo"/"pao"/"qghu" , 自摸/别人点炮/抢杠胡 ，如果有，则需要挂起碰杠
	_play_data.wait_hu_data={}

	-- 挂起的碰杠（收到消息，但挂起操作），{pg_type="peng"/"wg"/"zg",pai=,seat_num=}
	_play_data.suspend_peng_gang = nil

	-- 定缺数据
	_play_data.p_ding_que = {}

	--玩家数据 key=位置号（1，2，... nor_mj_room_lib.seat_count）
	for i=1,(nor_mj_room_lib.seat_count) do

		_play_data[i]={

			--手里牌列表：key -> count ；！！注意：为 0 的时候一定要设为 nil
			pai={},
			--倒下的牌：碰或杠， pai -> count ，注意： .pai 和 .pg_pai 中不会重复
			pg_pai={},
			--碰杠类型 pai -> zg/wg/ag/peng
			pg_type={},
			-- 碰杠 牌的数组，按顺序 。客户端用作保证结算时的顺序
			pg_vec={},
			--当前摸到的牌
			mo_pai = nil,

			-- 听牌信息：每次 出牌后 计算
			ting_info = nil,

			--胡牌顺序号，nil 表示未胡牌
			hu_order=nil,
			--胡的牌
			hu_pai=nil,

			-- ‘过’ 牌标志：记录最近一次 放弃胡牌的 牌 和 座位号；用于在过庄之前不允许胡这张牌
			guo_pai = nil, -- {pai=,seat=}

			-- 离开：已经离开房间
			is_quit = false,

			--- 打飘的值
			piaoNum = -1,

			is_huan_pai = 0,


		}

	end




	return _play_data
end



--- 换牌
function nor_mj_room_lib.huan_pai( _d , _seat_num , old_pai_vec)
	--- 打印换牌，验证换牌后是否正确
	local _play_data = _d.play_data
	-- dump( _play_data.pai_pool , "----------- nor_mj_room_lib.huan_pai , old pai_pool:" )
	-- dump(old_pai_vec , "-------------------- old old_pai_vec:")

	-- by lyx 托管的极端情况
	if not _play_data.pai_pool[1] then
		return basefunc.copy(old_pai_vec)
	end

	local random_vec = {}

	local new_pai_vec = {}
	local num = #old_pai_vec
	for i=1 , num do
		
		random_vec[i] = {}

		local _len = #_play_data.pai_pool
		local random = math.random(1,_len)
		-- print("---------- random:",random)

		local random_pai = _play_data.pai_pool[random]
		new_pai_vec[#new_pai_vec+1] = random_pai

		_play_data.pai_pool[random] = old_pai_vec[i]

		------
		random_vec[i].key = random
		random_vec[i].pai = random_pai

		--- 手上的对应的牌减少
		local paimap = _play_data[_seat_num].pai
		paimap[ old_pai_vec[i] ] = paimap[ old_pai_vec[i] ] and paimap[ old_pai_vec[i] ] - 1

		--- 新的牌增加
		paimap[ random_pai ] = paimap[ random_pai ] and paimap[ random_pai ] + 1 or 1

	end

	-- dump(_play_data.pai_pool , "----------- nor_mj_room_lib.huan_pai , new pai_pool:" )
	-- dump(_play_data,"-----------------  shoushang de pai:" )
	--- 最后验证一下，所有的牌是不是都是4张
	local is_error = false
	for i=11,39 do
		repeat
			if i==20 or i == 30 then
				break
			end
			local total = 0
			for key,value in pairs(_play_data.pai_pool) do
				if value == i then
					total = total + 1
				end
			end
			for j=1,nor_mj_room_lib.seat_count do
				for key,num in pairs(_play_data[j].pai) do
					if key == i then
						total = total + num
					end
				end
			end
			---- 托管的管制的牌,加到数量判定中去
			for seat_num,data in pairs(_d.special_deal_data) do
				for _,pai in pairs(data.mopai_list) do
					if pai == i then
						total = total + 1
					end
				end
				if data.hupai and data.hupai == i then
					total = total + 1
				end
			end

			-- print("---------- huanPai: i, total:",i,total)
			if total ~= 0 and total ~= 4 then
				--error(string.format("huanpai error,total error! %s, %s ",i,total))
				print(string.format("-------------error------------- huanpai error,total error! %s, %s ",i,total))
				is_error = true
			end
		until true
	end

	----------------------------- 如果出错,换牌回退 -----------------------------
	if is_error then
		for key,data in pairs(random_vec) do
			---- 牌池回退
			_play_data.pai_pool[data.key] = data.pai

			---- 手牌回退
			local paimap = _play_data[_seat_num].pai
			paimap[ old_pai_vec[key] ] = paimap[ old_pai_vec[key] ] and paimap[ old_pai_vec[key] ] + 1 or 1

		    ---
			paimap[ data.pai ] = paimap[ data.pai ] and paimap[ data.pai ] - 1
		end

		new_pai_vec = old_pai_vec
	end

	return new_pai_vec
end

--- 是否换牌完成
function nor_mj_room_lib.is_huan_pai_finished(_play_data)
	for i=1,nor_mj_room_lib.seat_count do
		if not _play_data[i] or not _play_data[i].is_huan_pai or _play_data[i].is_huan_pai == 0 then
			return false
		end
	end

	return true
end

--- 是否打漂完成
function nor_mj_room_lib.is_da_piao_finish(_play_data)
	for i=1,nor_mj_room_lib.seat_count do
		if not _play_data[i] or not _play_data[i].piaoNum or _play_data[i].piaoNum == -1 then
			return false
		end
	end

	return true
end


return nor_mj_room_lib
