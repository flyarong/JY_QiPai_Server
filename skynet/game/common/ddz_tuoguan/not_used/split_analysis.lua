-- Author: cl
-- Date: 2019/3/11
-- Time: 13:45
-- 说明：分牌算法

local landai_enum=require "ddz_tuoguan.landai_enum"
local TypeSwitcher=require "ddz_tuoguan.type_switcher"
local CardTypeSplit=require "ddz_tuoguan.card_type_split"

local basefunc=require "basefunc"

local SplitAnalysis=basefunc.class()


function SplitAnalysis:ctor(switcher)

	if switcher then 
		self._switcher=switcher 
	else 
		self._switcher=TypeSwitcher.new()
	end

	self:clear()
	self._all_card_type=nil

end




function SplitAnalysis:clear()
	self._splits={}
end


function SplitAnalysis:getAllSplit()
	return self._splits
end



function SplitAnalysis:getSplitNu()
	return #self._splits

end



function SplitAnalysis:lys_cards(cards)

	self._splits= self:gen_allCardTypeSplit(landai_enum.allcardtypes.all_serial,1, cards)
end


function SplitAnalysis:getNoSerialSplit(cards)
	local split=CardTypeSplit.new()

	for _,f in ipairs(landai_enum.faces_now) do 
		local f_nu=cards:get_faceNu(f)
		if f_nu ==4 then 
			split:add_splitItem(landai_enum.s2cardtype.BOMB,nil,f)

		elseif f_nu ==3 then 
			split:add_splitItem(landai_enum.s2cardtype.THREE,nil,f)

		elseif f_nu == 2 then 
			split:add_splitItem(landai_enum.s2cardtype.PAIR,nil,f)

		elseif f_nu ==1 then 
			split:add_splitItem(landai_enum.s2cardtype.SINGLE,nil,f)
		end
	end

	if cards:get_faceNu(landai_enum.s2face["w"]) ==1 and 
		cards:get_faceNu(landai_enum.s2face["W"])==1 then 
		split:add_splitItem(landai_enum.s2cardtype.ROCKET)
	else 
		if cards:get_faceNu(landai_enum.s2face["w"]) ==1 then 
			split:add_splitItem(landai_enum.s2cardtype.SINGLE,nil,landai_enum.s2face["w"])

		elseif  cards:get_faceNu(landai_enum.s2face["W"]) ==1 then 
			split:add_splitItem(landai_enum.s2cardtype.SINGLE,nil,landai_enum.s2face["W"])
		end

	end
	return {split}
end


function SplitAnalysis:gen_allCardTypeSplit(types,pos,cards)

	if pos > #types then 
		return self:getNoSerialSplit(cards)
	end
	local type_info=types[pos]

	local type_nu=cards:get_typeFaceNu(type_info.t,type_info.s,type_info.f)


	if type_nu == 0 or not self._switcher:has_typeFace(type_info.t,type_info.s,type_info.f) then 
		return self:gen_allCardTypeSplit(types,pos+1,cards)
	end

	local next_card=cards:copy()
	next_card:remove_typeFace(type_info.t,type_info.s,type_info.f)

	local use_analys=self:gen_allCardTypeSplit(types,pos,next_card)
	for k,v in  ipairs(use_analys) do 
		v:add_splitItem(type_info.t,type_info.s,type_info.f)
	end

	local no_use_analys=self:gen_allCardTypeSplit(types,pos+1,cards)

	for k,v in ipairs(no_use_analys) do 
		table.insert(use_analys,v)
	end
	return use_analys
end






return SplitAnalysis 







