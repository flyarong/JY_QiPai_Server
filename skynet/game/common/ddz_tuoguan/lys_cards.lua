-- Author: cl
-- Date: 2019/3/11
-- Time: 13:45
-- 说明：分析牌集的基本类

local basefunc= require "basefunc"
local landai_enum= require "ddz_tuoguan.landai_enum"
local landai_util= require "ddz_tuoguan.landai_util"


local LysCards=basefunc.class()

--[[ attribute 

	_face_nu[]:integer  每个牌面的数量
	_card_nu:integer 牌的数量
	_lz_face:integer 癞子的面值

--]]


function LysCards:ctor()
	self:clear()
end


function LysCards:copy()
	local ret=LysCards.new()
	for k,v in pairs(self._face_nu) do 
		ret._face_nu[k]=v
	end

	ret._card_nu=self._card_nu
	ret._lz_face=self._lz_face
	return ret
end

function LysCards:add_face(f)
	self._face_nu[f]=self._face_nu+1
	self._card_nu=self._card_nu+1

end


function LysCards:set_fcards(cards)
	for k,v in pairs(cards) do 
		self._face_nu[v]=self._face_nu[v] +1 
		self._card_nu=self._card_nu+1
	end
end

function LysCards:set_fcards2(cards)
	self:clear()
	self:add_fcards2(cards)
end



function LysCards:add_fcards2(cards)
	for k,v in pairs(cards) do 
		self._face_nu[k]=self._face_nu[k] +v 
		self._card_nu=self._card_nu+v
	end
end


function LysCards:set_cards(cards)

	for k,v in pairs(cards) do 
		local face,suit=landai_util.v2fu(k)
		local old_nu=self._face_nu[face] or 0 
		self._face_nu[face]=old_nu+1 
		self._card_nu=self._card_nu+1
	end
end



function LysCards:get_faceNu(face) 
	return self._face_nu[face] or 0 
end

function LysCards:get_biggerFaceNu(value)

	local ret=0 

	for k,v in pairs(self._face_nu) do 
		if v > value then 
			ret=ret+1 
		end
	end

	return ret

end



function LysCards:clear()
	self._face_nu={}

	for k,v in ipairs(landai_enum.faces) do 
		self._face_nu[v]=0
	end

	self._card_nu=0
	self._lz_face=-1
end

function LysCards:merge(lys_cards)

	for k,v in ipairs(landai_enum.faces) do 
		self._face_nu[v] = self._face_nu[v]+lys_cards._face_nu[v]
	end

end



function LysCards:remove_typeFace(card_type,serial_nu,face)

	if card_type == landai_enum.s2cardtype.ROCKET then 
		self:remove_rocketType()
		return 
	end

	if serial_nu == nil then 
		self:remove_noSerialTypeFace(card_type,face)
	else 
		self:remove_serialTypeFace(card_type,serial_nu,face)
	end


end



function LysCards:remove_serialTypeFace(card_type,serial_nu,face)

	if card_type==landai_enum.s2cardtype.ST then 
		self:remove_serial(face,serial_nu,3)
	elseif card_type == landai_enum.s2cardtype.SP then 
		self:remove_serial(face,serial_nu,2)
	elseif card_type == landai_enum.s2cardtype.SS then 
		self:remove_serial(face,serial_nu,1)
	else 
		error("serial type not find(" .. card_type..")" )
	end

end



function LysCards:remove_noSerialTypeFace(card_type,face)

	local value =0

	if card_type==landai_enum.s2cardtype.BOMB then 
		value =4 
	elseif card_type==landai_enum.s2cardtype.THREE then 
		value =3 
	elseif card_type== landai_enum.s2cardtype.PAIR then 
		value =2 
	
	elseif card_type==landai_enum.s2cardtype.SINGLE then 
		value =1 
	end


	local old_face=self._face_nu[face] or 0 

	assert(old_face>=value,"facenu error("..old_face..","..value..")")

	self._face_nu[face]=old_face-value
	self._card_nu=self._card_nu-value

end


function LysCards:remove_serial(face,serial_nu,value)
	for i=0,serial_nu-1 do 
		local old_face=self._face_nu[face-i] 
		assert(old_face>=value,"facenu error("..old_face..","..value..")")
		self._face_nu[face-i]=old_face-value
		self._card_nu=self._card_nu-value
	end

end




function LysCards:getCardNu()
	return self._card_nu
end



function LysCards:get_typeFaceNu(card_type,serial_nu,face)
	if card_type == landai_enum.s2cardtype.ROCKET then 
		return self:get_rocketTypeNu()
	end

	if serial_nu == nil then 

		return self:get_noSerialTypeFaceNu(card_type,face)
	else 

		return self:get_serialTypeFaceNu(card_type,serial_nu,face)
	end

end


function LysCards:get_serialTypeFaceNu(card_type,serial_nu,face)
	if card_type==landai_enum.s2cardtype.ST then 
		return self:get_serialThreeTypeFaceNu(serial_nu,face)
	elseif card_type == landai_enum.s2cardtype.SP then 
		return self:get_serialPairTypeFaceNu(serial_nu,face)
	elseif card_type == landai_enum.s2cardtype.SS then 
		return self:get_serialSingleTypeFaceNu(serial_nu,face)
	else 
		error("serial type not find(" .. card_type..")" )
	end
end

function LysCards:get_serialSingleTypeFaceNu(serial_nu,face)
	if self._card_nu < serial_nu then 
		return 0
	end

	if (face>landai_enum.s2face["A"]) or face-serial_nu +1 < landai_enum.s2face["3"] then 
		return 0
	end

	local max_nu=4 

	for i = 0,serial_nu-1 do 
		local f_nu=self._face_nu[face-i] 
		if f_nu==0 then 
			return 0
		end

		if f_nu<max_nu then 
			max_nu=f_nu
		end
	end
	return max_nu
end

function LysCards:get_serialPairTypeFaceNu(serial_nu,face)

	if self._card_nu < serial_nu*2 then 
		return 0
	end

	if (face>landai_enum.s2face["A"]) or face-serial_nu +1 < landai_enum.s2face["3"] then 
		return 0
	end

	local max_nu=4 
	for i=0,serial_nu-1 do 
		local f_nu=self._face_nu[face-i]
		if f_nu < 2 then 
			return 0
		end

		if f_nu< max_nu then 
			max_nu=f_nu
		end
	end

	if max_nu == 4 then 
		return 2 
	end

	return 1 
end

function LysCards:get_serialThreeTypeFaceNu(serial_nu,face)

	if self._card_nu < serial_nu*3 then 
		return 0
	end

	if (face>landai_enum.s2face["A"]) or face-serial_nu +1 < landai_enum.s2face["3"] then 
		return 0
	end

	for i=0,serial_nu-1 do 
		local f_nu=self._face_nu[face-i]
		if f_nu < 3 then 
			return 0
		end
	end

	return 1
end





function LysCards:get_noSerialTypeFaceNu(card_type,face)
	if card_type==landai_enum.s2cardtype.BOMB then 
		return self:get_bombTypeFaceNu(face)
	elseif card_type==landai_enum.s2cardtype.THREE then 
		return self:get_threeTypeFaceNu(face)
	elseif card_type==landai_enum.s2cardtype.PAIR then 
		return self:get_pairTypeFaceNu(face)
	elseif card_type==landai_enum.s2cardtype.SINGLE then 
		return self:get_singleTypeFaceNu(face)
	else 
		error("no serial type not find(" .. card_type..")" )
	end
end


function LysCards:get_rocketTypeNu()
	if self._face_nu[landai_enum.s2face["w"]] >=1 and 
		self._face_nu[landai_enum.s2face["W"]]>=1 then 
		return 1 
	end
	return 0
end

function LysCards:get_bombTypeFaceNu(face)
	if self._face_nu[face]==4 then 
		return 1 
	end

	return 0
end


function LysCards:get_threeTypeFaceNu(face)
	if self._face_nu[face]>=3 then 
		return 1 
	end
	return 0
end



function LysCards:get_pairTypeFaceNu(face)
	local f_nu=self._face_nu[face] 
	if f_nu == 4 then 
		return 2 
	end

	if f_nu <2 then 
		return 0
	end

	return 1 
end


function LysCards:get_maxSerialNu(value)

	local s_min=landai_enum.s2face["3"]
	local s_max=landai_enum.s2face["A"]
	local max_serial=0
	local now_serial=0

	for i=s_min,s_max do 
		if self._face_nu[i]>=value then 
			now_serial=now_serial+1
		else 
			now_serial=0
		end

		if now_serial> max_serial then 
			max_serial= now_serial
		end
	end
	return max_serial 

end


function LysCards:to_paimap()
	local pai_map={}
	for k,v in ipairs(landai_enum.faces) do 
		pai_map[v]=self._face_nu[v]
	end
	return pai_map
end





function LysCards:get_singleTypeFaceNu(face)
	return self._face_nu[face]
end

function LysCards:tostring()
	local ret={}

	for k,v in ipairs(landai_enum.faces) do 
		local f_nu= self._face_nu[v]
		for i=1,f_nu do 
			table.insert(ret,landai_enum.face2s[v])
		end
	end

	landai_util.sortscards(ret)

	return "{"..table.concat(ret,",").."}"
end


return LysCards



