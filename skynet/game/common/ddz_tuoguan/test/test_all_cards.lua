local ddz_tg_assist_lib=require "ddz_tuoguan.ddz_tg_assist_lib"
local landai_util=require "ddz_tuoguan.landai_util"
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
	local size=20
	--size=math.random(20)
	local sscards=rand_cards(size)

	--local sscards="wWAKQJTTTT99988"

	--print(sscards)

	local pai=landai_util.cards2pai( landai_util.ss2cards(sscards))

	local pai_map=ddz_tg_assist_lib.get_paiEnum(pai)
	dump(pai_map)
	--print(landai_util.pai2ss(pai_map))
	
end

print(os.time())






