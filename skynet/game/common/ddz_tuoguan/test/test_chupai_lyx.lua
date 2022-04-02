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
        dz_seat      = 3,
        my_seat      = 2,
        seat_count   = 3,
        seat_type = {
            [1] = 0,
            [2] = 0,
            [3] = 1,
        },
    },
    firstplay           = true,
    game_over_cfg = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
    },
    last_pai = {
        pai = {
            [1] = 15,
        },
        type   = 1,
    },
    last_seat           = 2,
    origin_seat_cards = {
        [1] = {
            [7] = true,
            [8] = true,
            [22] = true,
            [25] = true,
            [31] = true,
            [35] = true,
            [37] = true,
            [38] = true,
            [42] = true,
            [46] = true,
        },
        [2] = {
            [1] = true,
            [2] = true,
            [3] = true,
            [6] = true,
            [18] = true,
            [26] = true,
            [27] = true,
            [28] = true,
            [43] = true,
            [45] = true,
        },
        [3] = {
            [48] = true,
        },
    },
    pai_map = {
        [1] = "AKQQJT9844",
        [2] = "AK99974333",
        [3] = "A",
    },
}
--AKQQJT9844  ,  AK99974333[AC]  ,  A[D]


for k,v in ipairs(data.pai_map) do 
	data.pai_map[k]= landai_util.cards2pai(landai_util.ss2cards(v))
end

for i =1,1 do 
	cp_algorithm.fenpai_for_all(data)
	-- dump(data.fen_pai)
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
	--dump(data.boyi_list,"boSSSSSSSSSSSSSSSSSSSS")
	--  ###_test by hewei
	local maxxx=1000
	for k,v in ipairs(data.boyi_list) do
		if v.score<=maxxx then

			maxxx= v.score
		else
			dump(data.boyi_list)
			error("sort error !!!!!")
		end
	end

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

