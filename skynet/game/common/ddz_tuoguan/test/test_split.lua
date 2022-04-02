
local landai_util= require "landai.landai_util"
local LysCards=require "landai.lys_cards"
local SplitAnalysis=require "landai.split_analysis"


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
	--local size= math.random(size)
	for i=1,size do 
		table.insert(ret,full_cards[i])
	end

	landai_util.sortscards(ret)
	return table.concat(ret,"")
end



function idle(v)
	return v.."aaa"
end

print(os.time())
for i=1,1000 do 
	local v = rand_cards(20)
	--local v ="w2JT9876AAAKKK33444"
	local v="22KQJT99888777666543"


	local lys_cards=LysCards.new()
	lys_cards:set_fcards(landai_util.ss2cards(v))
	--print(lys_cards:tostring())

	local split_anysis=SplitAnalysis.new()
	split_anysis:lys_cards(lys_cards)
	--print("split_nu is ",#split_anysis:getAllSplit())

	for k,v in ipairs(split_anysis:getAllSplit()) do 
		v:tostring()
		--print(v:tostring())
	end
end

print(os.time())




