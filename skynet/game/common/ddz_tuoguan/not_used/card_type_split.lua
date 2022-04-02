local landai_enum=require "ddz_tuoguan.landai_enum"
local basefunc = require "basefunc"
local SplitTypeItem=require "ddz_tuoguan.split_type_item"

local CardTypeSplit=basefunc.class()


function CardTypeSplit:ctor()
	self:clear()
end

function CardTypeSplit:clear()
	self._split_item={}
end

function CardTypeSplit:add_splitItem(types,serial,f)
	table.insert(self._split_item,SplitTypeItem.new(types,serial,f))
end


function CardTypeSplit:get_allSplitItem()
	return self._split_item
end


function CardTypeSplit:tostring()
	local ret={}

	for k,v in ipairs(self._split_item) do 
		table.insert(ret,v:tostring())
	end

	return "{"..table.concat(ret,",").."}"

end



return CardTypeSplit 

