-- Author: cl
-- Date: 2019/3/12
-- Time: 10:49
-- 说明：牌型开关

local landai_enum=require "ddz_tuoguan.landai_enum"
local basefunc=require "basefunc"


local TypeSwitcher=basefunc.class()

function TypeSwitcher:ctor()
	self:clear()
end

function TypeSwitcher:clear()
	self._typeinfo={
		[landai_enum.s2cardtype.ST]={ enabled=true, min_serial=2, max_serial=6 },
		[landai_enum.s2cardtype.SP]={ enabled=true, min_serial=3, max_serial=10 },
		[landai_enum.s2cardtype.SS]={ enabled=true, min_serial=5, max_serial=12 },
		[landai_enum.s2cardtype.BOMB]={ enabled=true},
		[landai_enum.s2cardtype.ROCKET]={ enabled=true},
		[landai_enum.s2cardtype.THREE]={ enabled=true},
		[landai_enum.s2cardtype.PAIR]={ enabled=true},
		[landai_enum.s2cardtype.SINGLE]={ enabled=true}
	}
end

function TypeSwitcher:has_typeFace(t,serial_nu,f)
	local type_info=self._typeinfo[t]

	if not type_info then 
		return false
	end

	if not type_info.enabled then 
		return false
	end

	if serial_nu ==nil then 
		return true
	end


	if type_info.min_serial <= serial_nu and serial_nu <=type_info.max_serial then 
		return true
	end
	return false 

end


function TypeSwitcher:set_typeFaceInfo(ftype,enabled,min_serial,max_serial)
	self._typeinfo[ftype]={
		enabled=enabled,
		min_serial=min_serial,
		max_serial=max_serial
	}
end

return TypeSwitcher
