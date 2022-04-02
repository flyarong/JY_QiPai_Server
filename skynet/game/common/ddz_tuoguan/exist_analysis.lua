-- Author: cl
-- Date: 2019/3/11
-- Time: 13:45
-- 说明：牌集中是否包含某种类型的牌
local landai_enum=require "ddz_tuoguan.landai_enum"
local landai_util=require "ddz_tuoguan.landai_util"

local basefunc= require "basefunc"

local ExistAnalysis=basefunc.class()
local LysCards=require "ddz_tuoguan.lys_cards"

--[[ attribute 

	_serial_threes[][]:integer 飞机的数量
	_serial_pairs[][]: integer 连子的数量
	_serial_singles[][]:integer 顺子的数量

	_bombs[]:integer  炸弹的数量
	_threes[]:integer 三张的数量
	_pairs[]:integer 对子的数量
	_singles[]:integer 单张的数量

	_rocket_nu:integer 王炸的数量

	_all_types:table 

--]]


local CardType_Cast_Map={
	[1]=1,
	[2]=2,
	[3]=3,
	[4]=3,
	[5]=3,
	[6]=6,
	[7]=7,
	[8]=13,
	[9]=13,
	[10]=12,
	[11]=12,
	[12]=12,
	[13]=13,
	[14]=14,
	[15]=15
}



function ExistAnalysis:ctor()
	self:clear()
end






function ExistAnalysis:merge(table_info)
	local serial_type={landai_enum.s2cardtype.ST, landai_enum.s2cardtype.SP, landai_enum.s2cardtype.SS}

	for _,stype in ipairs(serial_type) do 
		local my_stype=self._all_types[stype]
		local o_stype=table_info._all_types[stype]
		local serial_info=landai_enum.serial_info[stype]
		for i= serial_info.min,serial_info.max do 
			local old_serial=o_stype[i] 
			if old_serial then 

				if not my_stype[i] then 
					my_stype[i]={}
				end
				for k,v in pairs(old_serial) do 
					local my_nu = my_stype[i][k] or 0 
					my_stype[i][k]= my_nu+ v 
				end

			end
		end
	end

	local no_serial_type={ landai_enum.s2cardtype.BOMB, landai_enum.s2cardtype.THREE, landai_enum.s2cardtype.PAIR, landai_enum.s2cardtype.SINGLE} 

	for _,stype in ipairs(no_serial_type) do 
		local my_stype=self._all_types[stype]
		local o_stype=table_info._all_types[stype]
		for k,v in pairs(o_stype)  do 
			local my_nu =my_stype[k] or 0 
			my_stype[k]=my_nu+v 
		end
	end

	self._rocket_nu = table_info._rocket_nu+self._rocket_nu

	if not self._lys_cards then 
		self._lys_cards=LysCards.new()
	end

	self._lys_cards:merge(table_info._lys_cards)



end



function ExistAnalysis:set_card(lys_cards)
	for k,v in ipairs(landai_enum.allcardtypes.all) do 

		local type_nu=lys_cards:get_typeFaceNu(v.t,v.s,v.f)
		--print(v.t,v.s,v.f,type_nu)
		self:set_typeFaceNu(v.t,v.s,v.f,type_nu)
	end

	self._lys_cards=lys_cards
end



function ExistAnalysis:clear()

	local sthree_info=landai_enum.serial_info[landai_enum.s2cardtype.ST]
	local spair_info=landai_enum.serial_info[landai_enum.s2cardtype.SP]
	local ssingle_info=landai_enum.serial_info[landai_enum.s2cardtype.SS]

	self._serial_threes={}
	for i= sthree_info.min,sthree_info.max do 
		self._serial_threes[i]={}
	end

	self._serial_pairs={}
	for i= spair_info.min,sthree_info.max do 
		self._serial_pairs[i]={}
	end

	self._serial_singles={}
	for i= ssingle_info.min,sthree_info.max do 
		self._serial_singles[i]={}
	end




	self._bombs={}
	self._threes={}
	self._pairs={}
	self._singles={}


	self._rocket_nu=0

	self._all_types={
		[landai_enum.s2cardtype.ST]=self._serial_threes,
		[landai_enum.s2cardtype.SP]=self._serial_pairs,
		[landai_enum.s2cardtype.SS]=self._serial_singles,

		[landai_enum.s2cardtype.BOMB]=self._bombs,
		[landai_enum.s2cardtype.THREE]=self._threes,
		[landai_enum.s2cardtype.PAIR]=self._pairs,
		[landai_enum.s2cardtype.SINGLE]=self._singles,
	}

	self._bigger_dirty=true

	self._lys_cards=LysCards.new()

end


function ExistAnalysis:get_biggerEqCardNu(card_type,serial,face)
	return self:get_biggerCardNu(card_type,serial,face) +self:get_typeFaceNu(card_type,serial,face)
end

function ExistAnalysis:get_biggerCardNu(ocard_type,serial,face)
	local card_type = ocard_type 

	if card_type == landai_enum.s2cardtype.ROCKET then 
		return 0
	end

	--三带1 
	if card_type == 4 then 
		if self._lys_cards:get_biggerFaceNu(0) <2 then 
			return 0
		end
	end


	--三带一对
	if card_type == 5 then 
		if self._lys_cards:get_biggerFaceNu(1) <2 then 
			return 0
		end
	end

	-- 飞机带单牌
	if card_type==10 then 
		if self._lys_cards:get_biggerFaceNu(0)< serial*2 then 
			return 0
		end
	end

	--飞机带对 --
	if card_type==11 then 
		if self._lys_cards:get_biggerFaceNu(1) < serial* 2 then 
			return 0
		end
	end

	-- 四带单
	if card_type == 8 then 
		if self._lys_cards:get_biggerFaceNu(0)< 3 then 
			return 0
		end
	end

	if card_type == 9 then 
		if self._lys_cards:get_biggerFaceNu(1) < 3 then 
			return 0
		end
	end



	card_type=CardType_Cast_Map[card_type]



	local  type_info=self._all_types[card_type]

	local bigger_nu=0

	if serial then 
		local max_face=landai_enum.s2face["A"]
		type_info=type_info[serial]
		if not type_info then 
			return 0
		end

		for i=face+1,max_face do 
			local type_nu = type_info[i] or 0 

			if type_nu>0 then 
				bigger_nu=bigger_nu+1
			end
		end
		local face_nu=type_info[face] 
		return bigger_nu

	end



	local max_face=landai_enum.s2face["W"] 
	for i=face+1,max_face do 
		local type_nu= type_info[i] or 0 
		if type_nu >0 then 
			bigger_nu=bigger_nu+1
		end
	end

	if card_type == landai_enum.s2cardtype.BOMB then 
		if self._rocket_nu > 0 then 
			bigger_nu=bigger_nu+1
		end
	end

	--print("bigger_nu",bigger_nu)
	return bigger_nu
end







function ExistAnalysis:set_serialThreeFaceNu(serial,face,value)
	self:set_serialTypeFaceNu(landai_enum.s2cardtype.ST,serial,face,value)
end
function ExistAnalysis:get_serialThreeFaceNu(serial,face)
	return self:get_serialTypeFaceNu(landai_enum.s2cardtype.ST,serial,face)
end


function ExistAnalysis:set_serialPairFaceNu(serial,face,value)
	self:set_serialTypeFaceNu(landai_enum.s2cardtype.SP,serial,face,value)
end
function ExistAnalysis:get_serialPairFaceNu(serial,face)
	return self:get_serialTypeFaceNu(landai_enum.s2cardtype.SP,serial,face)
end

function ExistAnalysis:set_serialSingleFaceNu(serial,face,value)
	self:set_serialTypeFaceNu(landai_enum.s2cardtype.SS,serial,face,value)
end

function ExistAnalysis:get_serialSingleFaceNu(seriarl,face)
	return self:get_serialTypeFaceNu(landai_enum,s2cardtype.SS,serial,face)
end


function ExistAnalysis:set_bombFaceNu(face,value)
	self:set_noSerialTypeFaceNu(landai_enum.s2cardtype.BOMB,face,value)
end

function ExistAnalysis:get_bombFaceNu(face)
	return self:get_noSerialTypeFaceNu(landai_enum.s2cardtype.BOMB,face)
end

function ExistAnalysis:set_threeFaceNu(face,value)
	self:set_noSerialTypeFaceNu(landai_enum.s2cardtype.THREE,face,value)
end

function ExistAnalysis:get_threeFaceNu(face)
	return self:get_noSerialTypeFaceNu(landai_enum.s2cardtype.THREE,face)
end

function ExistAnalysis:set_pairFaceNu(face,value)
	self:set_noSerialTypeFaceNu(landai_enum.s2cardtype.PAIR,face,value)
end

function ExistAnalysis:get_pairFaceNu(face)
	return self:get_noSerialTypeFaceNu(landai_enum.s2cardtype.PAIR,face)
end

function ExistAnalysis:set_singleFaceNu(face,value)
	return self:set_noSerialTypeFaceNu(landai_enum.s2cardtype.SINGLE,face)
end


function ExistAnalysis:get_singleFaceNu(face)
	return self:get_noSerialTypeFaceNu(landai_enum.s2cardtype.SINGLE)
end



function ExistAnalysis:set_rocketNu(value)
	self._rocket_nu=value
end


function ExistAnalysis:get_rocketNu()
	return self._rocket_nu
end


function ExistAnalysis:set_serialTypeFaceNu(card_type,serial,face,value)

	if not self._all_types[card_type][serial] then
		self._all_types[card_type][serial]={}
	end

	self._all_types[card_type][serial][face]=value

end


function ExistAnalysis:get_serialTypeFaceNu(card_type,serial,face)
	local type_info=self._all_types[card_type]

	if not type_info[serial]  then 
		return 0
	end

	if not type_info[serial][face] then 
		return 0 
	end

	return type_info[serial][face]
end


function ExistAnalysis:set_noSerialTypeFaceNu(card_type,face,value)
	self._all_types[card_type][face]=value
end


function ExistAnalysis:get_noSerialTypeFaceNu(card_type,face)
	--print(card_type)

	local type_info=self._all_types[card_type]
	if not type_info[face] then 
		return 0
	end
	return type_info[face]
end



function ExistAnalysis:set_typeFaceNu(card_type,serial,face,value)
	if serial == nil then 
		if card_type ==landai_enum.s2cardtype.ROCKET then 
			self:set_rocketNu(value)
		else 
			self:set_noSerialTypeFaceNu(card_type,face,value)
		end
	else 
		self:set_serialTypeFaceNu(card_type,serial,face,value)
	end

end

function ExistAnalysis:get_typeFaceNu(card_type,serial,face)


	--三带1 
	if card_type == 4 then 
		if self._lys_cards:get_biggerFaceNu(0) <2 then 
			return 0
		end
	end


	--三带一对
	if card_type == 5 then 
		if self._lys_cards:get_biggerFaceNu(1) <2 then 
			return 0
		end
	end

	-- 飞机带单牌
	if card_type==10 then 
		if self._lys_cards:get_biggerFaceNu(0)< serial*2 then 
			return 0
		end
	end

	--飞机带对 --
	if card_type==11 then 
		if self._lys_cards:get_biggerFaceNu(1) < serial* 2 then 
			return 0
		end
	end

	-- 四带单
	if card_type == 8 then 
		if self._lys_cards:get_biggerFaceNu(0)< 3 then 
			return 0
		end
	end

	if card_type == 9 then 
		if self._lys_cards:get_biggerFaceNu(1) < 3 then 
			return 0
		end
	end


	local card_type= CardType_Cast_Map[card_type]

	if serial == nil then 
		if card_type== landai_enum.s2cardtype.ROCKET then 
			return self:get_rocketNu()
		else 
			return self:get_noSerialTypeFaceNu(card_type,face)
		end
	else 
		return self:get_serialTypeFaceNu(card_type,serial,face)
	end
end

function ExistAnalysis:tostring()
	local ret=""
	local fv_value=function(k,v)
		return {f=k,v=v}
	end


	local face_valuemap=function(k,v)
		if v == 0 then 
			return  landai_enum.face2s[k],nil
		end
		return landai_enum.face2s[k],v
	end
	local face_v_tostring=function(k,v)
		return k,tostring(landai_enum.face2s[v.f]).."*"..tostring(v.v)
	end


	local comp=function(l,r)
		return l.f>r.f
	end

	for k,v in pairs(self._all_types) do 
		if k==landai_enum.s2cardtype.ST or k==landai_enum.s2cardtype.SP or k==landai_enum.s2cardtype.SS then 
			for sk,sv in pairs(v) do 
				ret=ret..landai_enum.cardtype2s[k]..sk..":"

				local face=landai_util.tablefv(sv,fv_value)
				table.sort(face,comp)

				local seq_face=landai_util.map(face,face_v_tostring)

				ret=ret.."["..table.concat(seq_face,",").."]\n"
			end
		else 
			ret=ret..landai_enum.cardtype2s[k]..":"

			local face=landai_util.tablefv(v,fv_value)
			table.sort(face,comp)

			local seq_face=landai_util.map(face,face_v_tostring)
			ret=ret.."["..table.concat(seq_face,",").."]\n"

		end
	end

	ret=ret.."ROCKET:"..tostring(self._rocket_nu).."\n"


	return ret

end











return ExistAnalysis




