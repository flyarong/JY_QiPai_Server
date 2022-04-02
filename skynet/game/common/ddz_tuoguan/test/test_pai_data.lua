-- package.path=package.path..";/Users/hewei/project/JyQipai_server/skynet/game/common/?.lua"
local ddz_tuoguan=require "ddz_tuoguan.nor_ddz_ai_base_lib"
local landai_util=require "ddz_tuoguan.landai_util"
local cp_algorithm=require "ddz_tuoguan.ddz_tuoguan_cp_algorithm"
local ddz_tg_assist_lib=require "ddz_tuoguan.ddz_tg_assist_lib"
local tgland = require "tgland.core"
require "printfunc"

math.randomseed(os.time())

function shuffle(tbl)
  size = #tbl
  for i = size, 1, -1 do
    local rand = math.random(size)
    tbl[i], tbl[rand] = tbl[rand], tbl[i]
  end
  return tbl
end


local full_cards= {
	"W", 
	"w", 
	"2","2","2","2",
	"A","A","A","A",
	"K","K","K","K",
	"Q","Q","Q","Q",
	"J","J","J","J",
	"T","T","T","T",
	"9","9","9","9",
	"8","8","8","8",
	"7","7","7","7",
	"6","6","6","6",
	"5","5","5","5",
	"4","4","4","4",
	"3","3","3","3"
}

function rand_cards(size)
	shuffle(full_cards)
	local ret={}

	for i=1,size do 
		table.insert(ret,full_cards[i])
	end
	landai_util.sortscards(ret)

	return table.concat(ret,"")
end


local ttt=os.time()


for i =1,1000000000000000 do 
	local size=20
	--size=math.random(20)
	local sscards=rand_cards(size)
	--local sscards="w2AKQQQJJJT8887754433"
	--local sscards="22KQJT99888777666543"
	--local sscards ="2AAAQQQJT9876443"
	--print(sscards)
	
	--local sscards="555666777"
	
	--local sscards_1="98TJQKA34569222"
	-- local sscards_1="22KQJT99888777666543"0
	-- local sscards_1="98TJQKA34444569222"
	-- local sscards_1="5KAAQJJJK222"
	--local sscards_1="TTTT7"

	-- local sscards_1="5KA222"
	

	local sscards_1 = "2222AAAAKKKKT8"
	local sscards_2= "JJJTTT665544"
	local sscards_3=  "333344566777788w"

	local str_pai={sscards_1,sscards_2,sscards_3}

	--local str_pai={"227333" ,"22AQT988663","2KQQTT999887764"}
	print(str_pai[1],str_pai[2],str_pai[3])

	local pai_maps={}

	for k,v in ipairs(str_pai) do 
		pai_maps[k] =landai_util.cards2pai(v)
	end


	local data={

		pai_map=pai_maps,

		base_info={
			dz_seat=1,
			my_seat=2,
			seat_type={1,0,0},
			seat_count=3
		},

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
		cp_count={2,2,2},
		game_over_cfg={0,0,0}
	}

	ddz_tg_assist_lib.set_game_type("nor")
	data.kaiguan = ddz_tg_assist_lib.data_ddz_cfg.kaiguan
	--dump(data)

	--dump(data,"data")
	-- local paiEnum={}
	-- for k,v in ipairs(data.pai_map) do
	--	paiEnum[k]=ddz_tg_assist_lib.get_paiEnum(v)
	-- end
	-- dump(paiEnum)
	-- do return end 

	cp_algorithm.fenpai_for_all(data)
	tgland.destroy_query_map(data.query_map)
	
	-- dump(data.fen_pai)
	-- pai_map,pai_enum,cur_p,seat_type,game_over_info,cp_data,kaiguan,_times_limit,type_limit
	-- local res,res_list=ddz_tg_assist_lib.get_all_cp_value_boyi(data.pai_map,paiEnum,1,data.base_info.seat_type,{0,0,0},nil,nil)
	-- local res,res_list=ddz_tg_assist_lib.get_all_cp_value_boyi(data.pai_map,paiEnum,2,{1,0,0},{0,0,0},{p=1,type=1,pai=5},nil)
	-- local map,res_list=ddz_tg_assist_lib.get_cp_value_map(data,1,nil)

	-- dump(res)
	--local max,min=ddz_tg_assist_lib.get_best_cp_score(res_list)

	-- dump(res_list)
	-- this.get_cp_value_map_new(data,seat,cur_cp_data)

	-- local map,list=ddz_tg_assist_lib.get_cp_value_map(data,1,nil)

--	local map,list=ddz_tg_assist_lib.get_cp_value_map(data,2,nil)
--	ddz_tg_assist_lib.get_best_cp_score(list)
--	dump(list)
	-- dump(list)
	--print("jieguo ",max,min)
	-- dump(res_list)
	-- print("jieguo ",max,min)
	-- local result=cp_algorithm.fenpai_for_all(data)
	-- dump(result,"result")
	--print(landai_util.pai2ss(result.fenpai))
end

print("use time:  ",os.time()-ttt)

os.exit(0)













