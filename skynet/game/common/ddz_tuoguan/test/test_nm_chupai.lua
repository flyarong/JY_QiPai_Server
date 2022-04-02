local basefunc= require "basefunc"
local dz_chupai=require "ddz_tuoguan.dz_chupai"
local nm_chupai=require "ddz_tuoguan.nm_chupai"
local landai_util=require "ddz_tuoguan.landai_util"
local cp_algorithm=require "ddz_tuoguan.ddz_tuoguan_cp_algorithm"
local ddz_tg_assist_lib= require "ddz_tuoguan.ddz_tg_assist_lib"
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


for i =1,1 do 

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
	--local sspai_map={"6666","AQT998765","QT95335624"}
	--local sspai_map={"22AAKQQJJTTT8886533","2AQJT985443","2AT8665"}
	--local sspai_map={"AAKTT7655443","22KJ976643","2222JJJTT98765544433"}
	--local sspai_map={"w222AKKQ9886544443","7543","Ww"}
	local sspai_map={"48888","9678","55537777"}

	dump(sspai_map)

	local pai_map={}
	for k,v in ipairs(sspai_map) do 
		pai_map[k]= landai_util.cards2pai(landai_util.ss2cards(v))
	end



	local data={
		pai_map=pai_map,
		--last_pai={type=3,data=10},
		last_pai={type=4,pai={6,4}},
		last_seat=2,
		firstplay=false,
		base_info={
			dz_seat=1,
			my_seat=3,
			seat_type={1,0,0},
			seat_count=3
		},
		game_over_cfg={0,0,0}
	}




	cp_algorithm.fenpai_for_all(data)
	data.pai_count=data.query_map.seat_card_nu
	dump(data.fen_pai)

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
	dump(data.boyi_list,"boSSSSSSSSSSSSSSSSSSSS")
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

	local pai_info=nm_chupai.nongmin_chupai(data.firstplay,data)


	dump(pai_info,"pai_info")
	
	if i%100 == 0 then 
		print(i)
	end

end






print(os.time())






