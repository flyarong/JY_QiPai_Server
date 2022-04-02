--
-- 作者: lyx
-- Date: 2018/3/10
-- Time: 14:48
-- 托管逻辑模块的包装文件
--

local land = require "land.core"
local nor_ddz_base_lib = require "nor_ddz_base_lib"
local basefunc = require "basefunc"
--------------------------------------
-- land.core 中 牌的表示
-- 一个 byte ，高 4 位 为花色，低四位 为 数字
-- 花色(0 ~ 3)： ♦,♣,♥,♠ （方块、梅花、红桃、黑桃）
-- 数字(1 ~ 13)： A,2,3,4,....,K
-- 小王 大王： 0x41,0x42

local PROTECTED = {}

-- 牌数值的映射
local pai_value_to_land = {
	[14]=1, -- A
	[15]=2, -- 2
	[16]=1, -- 小王（不包括高位）
	[17]=2, -- 大王（不包括高位）
}
PROTECTED.pai_value_to_land = pai_value_to_land

-- 牌的 id 和 land 牌值之间的映射
local pai_id_to_land = {
	[53] = 4 << 4 | 1,		-- 小王
	[54] = 4 << 4 | 2,		-- 大王
}
local pai_id_from_land = {}

PROTECTED.pai_id_to_land = pai_id_to_land
PROTECTED.pai_id_from_land = pai_id_from_land

-- 常量定义
INVALID_CHAIR = 255 -- 空椅子号
NULL_DATA = nil	-- 空数组

-- 规则
RULE_3_0			=		1					-- 可以三不带
RULE_4_1			=		2					-- 只能四带二（lyx： 允许四带 两 单）
RULE_No_La			=		4					-- 没有拉踩
RULE_ShuangWang		=		8					-- 双王必抓
RULE_3Zhua			=		1 << 4				-- 三个主必抓
RULE_Max_Time8		=		2 << 4				-- 8倍封顶
RULE_Max_Time16		=		4 << 4				-- 16倍封顶
RULE_Max_Time32		=		8 << 4				-- 32倍封顶
RULE_Max_Time		=		2 << 8				-- 不封顶
RULE_Off			=		1 << 8				-- 全程使用三不带和四带二的开关
RULE_3_2			=		4 << 8				-- 可以三带对
RULE_4_2			=		8 << 8				-- 可以四带对

-- 初始化相关数据
local inited = false
local function init()

	-- 牌数值的映射 pai_value_to_land, pai_value_from_land
	for i=3,13 do
		pai_value_to_land[i] = i
	end

	-- 牌 id 映射： pai_id_to_land 和 pai_id_from_land
	for pai_id=1,54 do
		if pai_id < 53 then
			local pai_value = nor_ddz_base_lib.pai_map[pai_id]
			pai_id_to_land[pai_id] = (pai_id-nor_ddz_base_lib.pai_to_startId_map[pai_value]) << 4 | pai_value_to_land[pai_value]
		end

		pai_id_from_land[pai_id_to_land[pai_id]] = pai_id
	end
end

local function game_logic_meta(_t,_k)

	_t[_k] = function (_self,...)
		return land[_k](rawget(_self,"_game_logic"),...)
	end

	return _t[_k] 
end

-- 牌 map 转换为 land 的数组模式
function PROTECTED.pai_map_to_land(_pai_map)
	local ret = {}

	for _pai,_ in pairs(_pai_map) do
		ret[#ret + 1] = pai_id_to_land[_pai]
	end

	return ret
end

-- 牌 list 转换为 land 的数组模式
function PROTECTED.pai_list_to_land(_pai_list)
	local ret = {}

	for _,_pai in ipairs(_pai_list) do
		ret[#ret + 1] = pai_id_to_land[_pai]
	end

	return ret
end

-- 牌 list 转换为 竟娱模式，出错返回 nil
function PROTECTED.pai_list_from_land(_pai_list)
	local ret = {}

	for _,_pai in ipairs(_pai_list) do

		if not pai_id_from_land[_pai] then 
			return nil
		end

		ret[#ret + 1] = pai_id_from_land[_pai]
	end

	return ret
end


function PROTECTED.seat_to_land(_seat)
	return _seat - 1
end

function PROTECTED.create()

	if not inited then
		init()
		inited =  true
	end

	return setmetatable({_game_logic=land.create()},{__index = game_logic_meta})
end



return PROTECTED