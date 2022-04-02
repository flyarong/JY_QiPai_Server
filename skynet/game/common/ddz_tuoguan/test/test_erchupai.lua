package.cpath = "../../luaclib/?.so;"..package.cpath

local basefunc= require "basefunc"
local dz_chupai=require "ddz_tuoguan.dz_chupai"
local nm_chupai=require "ddz_tuoguan.nm_chupai"
local landai_util=require "ddz_tuoguan.landai_util"
local cp_algorithm=require "ddz_tuoguan.ddz_tuoguan_cp_algorithm"
local ddz_tg_assist_lib= require "ddz_tuoguan.ddz_tg_assist_lib"
local nor_ddz_base_lib=require "nor_ddz_base_lib"
require "printfunc"

print(os.time())



 data = {
     base_info = {
         dz_seat      = 1,
         my_seat      = 2,
         seat_count   = 2,
         seat_type = {
             [1] = 1,
             [2] = 0,
         },
     },
     cp_count = {
         [1] = 1,
         [2] = 1,
         [3] = 0,
     },
     firstplay           = true,
     game_over_cfg = {
         [1] = 0,
         [2] = 2,
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
             [1] = 6,
         },
         type   = 1,
     },
     last_seat           = 2,
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
     origin_seat_cards = {
         [1] = {
             [1] = true,
             [2] = true,
             [11] = true,
             [12] = true,
             [17] = true,
             [21] = true,
             [23] = true,
             [25] = true,
             [27] = true,
             [30] = true,
             [32] = true,
             [35] = true,
             [36] = true,
             [40] = true,
             [41] = true,
             [43] = true,
             [49] = true,
             [52] = true,
             [54] = true,
         },
         [2] = {
             [3] = true,
             [4] = true,
             [5] = true,
             [8] = true,
             [9] = true,
             [10] = true,
             [29] = true,
             [34] = true,
             [37] = true,
             [38] = true,
             [39] = true,
             [42] = true,
             [48] = true,
             [50] = true,
             [51] = true,
             [53] = true,
         },
     },
     pai_map = {
         [1] = "W22KKQJJTT998875533",
         [2] = "w22AKQQQJT554433",
     },
 }
--W22KKQJJTT998875533[D]  ,  w22AKQQQJT554433[AC]






for k,v in ipairs(data.pai_map) do 
	data.pai_map[k]= landai_util.cards2pai(landai_util.ss2cards(v))
end




ddz_tg_assist_lib.set_game_type("nor")
data.kaiguan = ddz_tg_assist_lib.data_ddz_cfg.kaiguan


--dump(data.kaiguan)


for i =1,1 do 

	--data.game_over_cfg={0,0,0}
	cp_algorithm.fenpai_for_all(data)

	for k,v in ipairs(data.fen_pai) do 
		v.abs_xiaojiao=ddz_tg_assist_lib.check_is_xiajiao_absolute(v,k,data.query_map)
	end


	dump(data.fen_pai)



	data.pai_count=data.query_map.seat_card_nu

	local is_firstplay=data.firstplay 

	if is_firstplay then 
		local boyi_map,boyi_list=ddz_tg_assist_lib.get_cp_value_map(data,data.base_info.my_seat,nil)
		data.boyi_map=boyi_map 
		data.boyi_list=boyi_list

	else 

		local boyi_map,boyi_list=ddz_tg_assist_lib.get_cp_value_map(data,data.base_info.my_seat,{
			p=data.last_seat ,
			type=data.last_pai.type,
			pai=data.last_pai.pai
		})

		data.boyi_map=boyi_map 
		data.boyi_list=boyi_list
	end


	data.boyi_max_score,data.boyi_min_score=ddz_tg_assist_lib.get_best_cp_score(data.boyi_list)


	--手上剩余的牌
	data.pai_re_count={}
	for k,v in ipairs(data.pai_map) do
		data.pai_re_count[k]=0
		for _,c in pairs(v) do 
			data.pai_re_count[k]=data.pai_re_count[k]+c
		end
	end


	--dump(data.boyi_list,"bossssssssssssssssssss")
	--  ###_test by hewei
	local maxxx=1000

	local boyi_list_total=#data.boyi_list

	local boyi_list_win=0 
	local boyi_list_lose=0 
	local boyi_list_unkown=0 



	for k,v in ipairs(data.boyi_list) do
		if v.score<=maxxx then
			maxxx= v.score
		else
			dump(data.boyi_list)
			error("sort error !!!!!")
		end
		if v.score > 0 then 
			boyi_list_win= boyi_list_win +1 

		elseif v.score ==0 then 
			boyi_list_unkown= boyi_list_unkown+1 
		elseif v.score <0 then 
			boyi_list_lose = boyi_list_lose + 1
		end
	end

	data.boyi_list_total = boyi_list_total 
	data.boyi_list_win= boyi_list_win 
	data.boyi_list_lose= boyi_list_lose
	data.boyi_list_unkown= boyi_list_unkown

	local _chu_pai
	if data.base_info.dz_seat==data.base_info.my_seat  then 
		_chu_pai = dz_chupai.dizhu_chupai(is_firstplay,data)
	else 
		_chu_pai = nm_chupai.nongmin_chupai(is_firstplay,data)
	end

	dump(_chu_pai,"chu_pai")

	cp_type=_chu_pai.type 
	--cp_list= nor_ddz_base_lib.get_pai_list_by_data( data.origin_seat_cards[data.base_info.my_seat], _chu_pai.type, _chu_pai.pai)




end

print(os.time())

