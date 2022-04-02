package.cpath = "../../luaclib/?.so;"..package.cpath

local basefunc= require "basefunc"
local dz_chupai=require "ddz_tuoguan.dz_chupai"
local nm_chupai=require "ddz_tuoguan.nm_chupai"
local landai_util=require "ddz_tuoguan.landai_util"
local cp_algorithm=require "ddz_tuoguan.ddz_tuoguan_cp_algorithm"
local ddz_tg_assist_lib= require "ddz_tuoguan.ddz_tg_assist_lib"
local nor_ddz_base_lib=require "nor_ddz_base_lib"
local skynet = require "skynet_plus"
local ddz_tuoguan= require "ddz_tuoguan.ddz_tuoguan"
require "printfunc"

-- local data = {
--      base_info = {
--          dz_seat      = 1,
--          my_seat      = 1,
--          seat_count   = 3,
--          seat_type = {
--              [1] = 1,
--              [2] = 0,
--              [3] = 0,
--          },
--      },
--      cp_count = {
--          [1] = 2,
--          [2] = 1,
--          [3] = 0,
--      },
--      firstplay           = true,
--      game_over_cfg = {
--          [1] = 0,
--          [2] = 0,
--          [3] = 0,
--      },

--      kaiguan = {
--          [1] = 1,
--          [2] = 1,
--          [3] = 1,
--          [4] = 1,
--          [5] = 1,
--          [6] = 1,
--          [7] = 1,
--          [8] = 1,
--          [9] = 1,
--          [10] = 1,
--          [11] = 1,
--          [12] = 1,
--          [13] = 1,
--          [14] = 1,
--      },
--      last_pai = {
--          pai = {
--              [1] = 15,
--          },
--          type   = 1,
--      },
--      last_seat           = 1,
--      limit_cfg = {
--          sz_max_len = {
--              [1] = 12,
--              [2] = 10,
--              [3] = 6,
--          },
--          sz_min_len = {
--              [1] = 5,
--              [2] = 3,
--              [3] = 2,
--          },
--      },
--      -- origin_seat_cards = {
--      --     [1] = {
--      --         [9] = true,
--      --         [13] = true,
--      --         [14] = true,
--      --         [25] = true,
--      --         [26] = true,
--      --         [27] = true,
--      --         [29] = true,
--      --         [30] = true,
--      --         [31] = true,
--      --         [33] = true,
--      --         [34] = true,
--      --         [35] = true,
--      --         [36] = true,
--      --         [37] = true,
--      --         [38] = true,
--      --         [39] = true,
--      --     },
--      --     [2] = {
--      --         [15] = true,
--      --         [17] = true,
--      --         [18] = true,
--      --         [19] = true,
--      --         [20] = true,
--      --         [21] = true,
--      --         [22] = true,
--      --         [23] = true,
--      --         [24] = true,
--      --         [28] = true,
--      --         [32] = true,
--      --         [41] = true,
--      --         [43] = true,
--      --         [44] = true,
--      --         [45] = true,
--      --         [46] = true,
--      --         [48] = true,
--      --         [53] = true,
--      --         [54] = true,
--      --     },
--      -- },
--      pai_map = {
--         [1] = "33445566889kkAAA222w",
--         [2] = "33455677789OOJJAW",
--         [3]="467899OOJJQQQQKK2"
--      },
--  }
-- --  --QQQJJJJTTT999665[L]  ,  WwAAAKKKT9888877776[D][AC]

-- for k,v in ipairs(data.pai_map) do 
-- 	data.pai_map[k]= landai_util.cards2pai(landai_util.ss2cards(v))
-- end




-- ddz_tg_assist_lib.set_game_type("nor")
-- data.kaiguan = ddz_tg_assist_lib.data_ddz_cfg.kaiguan



-- for i =1,1  do 

-- 	--data.game_over_cfg={0,0,0}
-- 	print(os.time())
-- 	for i=1,1 do 
-- 		cp_algorithm.fenpai_for_all(data)
-- 	end
-- 	print(os.time())

-- 	for k,v in ipairs(data.fen_pai) do 
-- 		v.abs_xiaojiao=ddz_tg_assist_lib.check_is_xiajiao_absolute(v,k,data.query_map)
-- 	end


-- 	-- dump(data.fen_pai)
-- 	--dump(data.xjbest_fenpai)



-- 	--手上剩余的牌
-- 	data.pai_re_count={}
-- 	for k,v in ipairs(data.pai_map) do
-- 		data.pai_re_count[k]=0
-- 		for _,c in pairs(v) do 
-- 			data.pai_re_count[k]=data.pai_re_count[k]+c
-- 		end
-- 	end
-- 	data.pai_count=data.pai_re_count

-- 	--data.pai_count=data.query_map.seat_card_nu

-- 	local is_firstplay=data.firstplay 

-- 	if is_firstplay then 
-- 		local boyi_map,boyi_list=ddz_tg_assist_lib.get_cp_value_map(data,data.base_info.my_seat,nil)
-- 		data.boyi_map=boyi_map 
-- 		data.boyi_list=boyi_list

-- 	else 
-- 		local boyi_map,boyi_list=ddz_tg_assist_lib.get_cp_value_map(data,data.base_info.my_seat,{
-- 			p=data.last_seat ,
-- 			type=data.last_pai.type,
-- 			pai=data.last_pai.pai
-- 		})

-- 		data.boyi_map=boyi_map 
-- 		data.boyi_list=boyi_list
-- 	end


-- 	data.boyi_max_score,data.boyi_min_score=ddz_tg_assist_lib.get_best_cp_score(data.boyi_list)




-- 	-- dump(data.boyi_list,"bossssssssssssssssssss")
-- 	--  ###_test by hewei
-- 	local maxxx=1000

-- 	local boyi_list_total=#data.boyi_list

-- 	local boyi_list_win=0 
-- 	local boyi_list_lose=0 
-- 	local boyi_list_unkown=0 



-- 	for k,v in ipairs(data.boyi_list) do
-- 		if v.score<=maxxx then
-- 			maxxx= v.score
-- 		else
-- 			dump(data.boyi_list)
-- 			error("sort error !!!!!")
-- 		end
-- 		if v.score > 0 then 
-- 			boyi_list_win= boyi_list_win +1 

-- 		elseif v.score ==0 then 
-- 			boyi_list_unkown= boyi_list_unkown+1 
-- 		elseif v.score <0 then 
-- 			boyi_list_lose = boyi_list_lose + 1
-- 		end
-- 	end

-- 	data.boyi_list_total = boyi_list_total 
-- 	data.boyi_list_win= boyi_list_win 
-- 	data.boyi_list_lose= boyi_list_lose
-- 	data.boyi_list_unkown= boyi_list_unkown

-- 	local _chu_pai
-- 	if data.base_info.dz_seat==data.base_info.my_seat  then 
-- 		_chu_pai = dz_chupai.dizhu_chupai(is_firstplay,data)
-- 	else 
-- 		_chu_pai = nm_chupai.nongmin_chupai(is_firstplay,data)
-- 	end

-- 	dump(_chu_pai,"chu_pai")

-- 	cp_type=_chu_pai.type 
-- 	--cp_list= nor_ddz_base_lib.get_pai_list_by_data( data.origin_seat_cards[data.base_info.my_seat], _chu_pai.type, _chu_pai.pai)

-- 	print("use C++",skynet.getenv("ddz_tuoguan_imp_c"))



-- end










--******************
local data = {
     base_info = {
         dz_seat      = 1,
         my_seat      = 1,
         seat_count   = 3,
         seat_type = {
             [1] = 1,
             [2] = 0,
             [3] = 0,
         },
     },
     cp_count = {
         [1] = 2,
         [2] = 1,
         [3] = 0,
     },
     firstplay           = true,
     game_over_cfg = {
         [1] = 0,
         [2] = 0,
         [3] = 0,
     },

     kaiguan = {
         [1] = 1,
         [2] = 1,
         [3] = 1,
         [4] = 1,
         [5] = 1,
         [6] = 1,
         [7] = 1,
         [8] = 1,
         [9] = 1,
         [10] = 1,
         [11] = 1,
         [12] = 1,
         [13] = 1,
         [14] = 1,
     },
     last_pai = {
         pai = {
             [1] = 13,
         },
         type   = 2,
     },
     last_seat           = 1,
     limit_cfg = {
         sz_max_len = {
             [1] = 12,
             [2] = 10,
             [3] = 6,
         },
         sz_min_len = {
             [1] = 5,
             [2] = 3,
             [3] = 2,
         },
     },
     -- origin_seat_cards = 
         --{
         --     [1] = {
         --         [9] = true,
         --         [13] = true,
         --         [14] = true,
         --         [25] = true,
         --         [26] = true,
         --         [27] = true,
         --         [29] = true,
         --         [30] = true,
         --         [31] = true,
         --         [33] = true,
         --         [34] = true,
         --         [35] = true,
         --         [36] = true,
         --         [37] = true,
         --         [38] = true,
         --         [39] = true,
         --     },
         --     [2] = {
         --         [15] = true,
         --         [17] = true,
         --         [18] = true,
         --         [19] = true,
         --         [20] = true,
         --         [21] = true,
         --         [22] = true,
         --         [23] = true,
         --         [24] = true,
         --         [28] = true,
         --         [32] = true,
         --         [41] = true,
         --         [43] = true,
         --         [44] = true,
         --         [45] = true,
         --         [46] = true,
         --         [48] = true,
         --         [53] = true,
         --         [54] = true,
         --     },
         -- },
     pai_map = {
        [1] = "w222AAA966554433",
        [2] = "WAJJ98777655433",
        [3]="2KKQQQQJJTT998764"
     },
 }
--  --QQQJJJJTTT999665[L]  ,  WwAAAKKKT9888877776[D][AC]

for k,v in ipairs(data.pai_map) do 
    data.pai_map[k]= landai_util.cards2pai(landai_util.ss2cards(v))
end
for i =1,1  do 
    data.firstplay=true
    local _chu_pai =ddz_tuoguan.playcards(data.firstplay,nil,data,true)
    dump(_chu_pai)
end
-- print(os.time())







