local dz_chupai=require "ddz_tuoguan.dz_chupai"
local landai_util=require "ddz_tuoguan.landai_util"
local cp_algorithm=require "ddz_tuoguan.ddz_tuoguan_cp_algorithm"
local basefunc= require "basefunc"
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




print(os.time())


for i =1,1000 do 

	--local sspai_map={ "KKKTTT8777653", "w22AKQQTT88776633", "AAKQQ8876533"}
	local sspai_map={rand_cards(math.random(1,20)), rand_cards(math.random(1,20)), rand_cards(math.random(1,20))}

	--local sspai_map={ "JT877766643", "W2AAAKJ9998876543", "KQT73"}
	--local sspai_map={ "22QJJTT9664443", "KT", "22AAAKQQQ98776554"} --op will win fix
	--local sspai_map={ "w22AAKKKJ977753", "6", "W22AKKQJTT8776655"} 
	--local sspai_map={ "W2KKKQT64", "2KQQT7543", "86"} 

	--local sspai_map={"AKQJT966","W2KKKTT998777664433","2AAKQJT9988665433"}
	--local sspai_map={"AKQJJJT9876543","2AKQTTT9988865544433","W2JJT93"}
	--local sspai_map={"22KQJT988655554443","A","WAKQJJT876665543"}
	--local sspai_map={"2AQJTTTT888865544433","Ww2AQ5","2"}
	--local sspai_map={"WwAATTT99433","Ww2AAJJJJ8775543","AKJT987753"}
	--local sspai_map={"Ww22KKKJJJT997554433","Ww2AAKTT99887766533","J53"}
	--local sspai_map={"AKKKQQTTT98876665","wT96","wKKQQJJJ987664333"}
	--local sspai_map={"KKKQJTT8888777554433","QQQT98766","26554"}
	--local sspai_map={"2JJ86654","w2AAQJT988877665544","9"}
	--local sspai_map={"AKKQQJJJJ99876664","AQT998765","QT953"}
	--local sspai_map={"6667JJ","AQT998765","QT95335624"}
	--local sspai_map={"w22KKJJTT7776665543","AKTT876","AKQQJ998655"}
	--local sspai_map={"2KQQJJJ988887654333","Ww2AAKKQQJJT99876544","9"}
	--local sspai_map={"Ww22AAJT","W2","K"}
	--local sspai_map={"AAKTT7655443","22KJ976643","2222JJJTT98765544433"}
	--local sspai_map={"77745556","22KJ976643","2222JJJTT98765544433"}
	--local sspai_map={"777755","22KJ9976643","2K934"}

	dump(sspai_map)

	local pai_map={}
	for k,v in ipairs(sspai_map) do 
		pai_map[k]= landai_util.cards2pai(landai_util.ss2cards(v))
	end



	local data={
		pai_map=pai_map,
		--last_pai={type=3,data=10},
		last_pai={type=6,pai={3,8}},

		last_seat=2,
		base_info={
			dz_seat=1,
			my_seat=1,
			seat_type={1,0,0},
			seat_count=3
		},
		game_over_cfg={0,0,0}
	}





	--[[
	data.fen_pai={
		[1]={
			[1]={{1}}



		}
	}
	--]]

	cp_algorithm.fenpai_for_all(data)

	--local boyi_map,boyi_list=ddz_tg_assist_lib.get_cp_value_map(data,1,nil)

	dump(data.fen_pai,"fen_pai_data")
	--local pai_info=dz_chupai.dizhu_initiative_cp(data)

	
	--local pai_info=dz_chupai.dizhu_initiative_cp(data)
	local pai_info=dz_chupai.dizhu_chupai(false,data)
	--dump(data.boyi_list)
	dump(pai_info,"pai_info")

end






print(os.time())






