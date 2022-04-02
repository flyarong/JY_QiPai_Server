local landai_util= require "landai.landai_util"
local LysCards=require "landai.lys_cards"

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

function rand_cards()
	shuffle(full_cards)
	local ret={}
	local size= math.random(#full_cards) 
	for i=1,size do 
		table.insert(ret,full_cards[i])
	end

	return ret

end



for i=1,10000 do 
	local v = rand_cards()
	local lys_cards=LysCards.new()
	lys_cards:set_fcards(landai_util.s2cards(v))

	local raw_str="{"..table.concat(landai_util.sortscards(v),",").."}"
	local conv_ret=lys_cards:tostring()

	if raw_str== conv_ret then 
		print(raw_str,"---test_ok")
	else 
		print(raw_str,conv_ret,"----test failed")
		error("test failed")
	end
end






