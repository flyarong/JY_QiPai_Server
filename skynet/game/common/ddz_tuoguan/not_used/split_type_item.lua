local landai_enum=require "ddz_tuoguan.landai_enum"
local basefunc = require "basefunc"

local SplitTypeItem=basefunc.class()


function SplitTypeItem:ctor(types,serial,f)
	self._card_type=types
	self._serial_nu=serial
	self._face=f
end

function SplitTypeItem:tostring() 
	local ret=""

	ret=ret..landai_enum.cardtype2short[self._card_type]
	if self._serial_nu == nil then 
		if self._face then 
			ret=ret.."-"..landai_enum.face2s[self._face]
		end
	else 
		ret=ret..tostring(self._serial_nu) 

		local max_face=self._face 
		local min_face=self._face-self._serial_nu +1 
		ret=ret.."["..landai_enum.face2s[max_face].."-"..landai_enum.face2s[min_face].."]"
	end

	return ret
end



return SplitTypeItem


