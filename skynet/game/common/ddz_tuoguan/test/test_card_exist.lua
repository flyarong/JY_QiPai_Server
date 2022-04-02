local landai_enum=require "landai.landai_enum"
local landai_util= require "landai.landai_util"
local LysCards=require "landai.lys_cards"
local ExistAnalysis= require "landai.exist_analysis"
require "printfunc"


local test_cards={
	{  "2","2","2","2"},
	--{ "W", "w", "2","2","2","2", "A","A","A","A", "K","K","K","K", "Q","Q","Q","Q", "J","J","J","J", "T","T","T","T", "9","9","9","9", "8","8","8","8", "7","7","7","7", "6","6","6","6", "5","5","5","5", "4","4","4","4", "3","3","3","3" }
	

	

}


for k,v in ipairs(test_cards) do 
	local lys_cards=LysCards.new()
	lys_cards:set_fcards(landai_util.s2cards(v))
	local exist_lys=ExistAnalysis.new()
	exist_lys:set_card(lys_cards)
	print(exist_lys:tostring())

	for k,v in ipairs(landai_enum.allcardtypes.all) do 
		local bigger_nu=exist_lys:get_biggerCardNu(v.t,v.s,v.f)
		print(string.format("[%s,%d,%s]-%d", landai_enum.cardtype2s[v.t], v.s or 1 , landai_enum.face2s[v.f], bigger_nu) )
	end

end





print("test merge")

local m1=	{ "W", "2","2", "K","K","K", "Q","Q", "J", "T","T","T","T", "9","9","9","9", "8","8","8","8", "7","7","7","7", "6","6","6","6", "5","5","5","5", "4","4","4","4", "3","3","3","3" }


local m2={"w", "2","2", "A","A","A","A", "T","T", "9", "8","8","8", "7","7", "6", "5","5", "4","4","4","4", "3","3","3","3" }



local lys_cards_m1=LysCards.new()
lys_cards_m1:set_fcards(landai_util.s2cards(m1))
local exist_lys1=ExistAnalysis.new()
exist_lys1:set_card(lys_cards_m1)

print("m1111111111111111")
print(exist_lys1:tostring())


local lys_cards_m2=LysCards.new()
lys_cards_m2:set_fcards(landai_util.s2cards(m2))
local exist_lys2=ExistAnalysis.new()
exist_lys2:set_card(lys_cards_m2)

print("m2222222222222222")
print(exist_lys2:tostring())

local exist_merge=ExistAnalysis.new()
exist_merge:merge(exist_lys1) 
exist_merge:merge(exist_lys2)

print("merage -------")
print(exist_merge:tostring())






















