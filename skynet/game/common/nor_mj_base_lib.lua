

local basefunc = require "basefunc"
require"printfunc"

local nor_mj_base_lib={}


function nor_mj_base_lib.get_geng_num(pai_map,pg_map)
	local num=0
	if pai_map then
		for id,v in pairs(pai_map) do
			if v==4 then
				num=num+1
			elseif v==1 and pg_map and (pg_map[id]=="peng" or pg_map[id]==3) then
				num=num+1
			end
		end
	end
	if pg_map then
		for _,v in pairs(pg_map) do
			if v=="wg" or v=="zg" or v=="ag" or v==4 then
				num=num+1
			end
		end
	end
	return num
end
function nor_mj_base_lib.tongji_pai_info(pai_map,huaSe)
	local count=0
	huaSe=huaSe or {0,0,0}
	if pai_map then
		for id,v in pairs(pai_map) do
			if v>0 then
				local c=math.floor(id/10)
				huaSe[c]=1
				count=count+v
			end
		end
	end
	return count
end
function nor_mj_base_lib.tongji_penggang_info(pg_map,huaSe)
	local count=0
	huaSe=huaSe or {0,0,0}
	if pg_map then
		for id,v in pairs(pg_map) do
			local c=math.floor(id/10)
			huaSe[c]=1
			count=count+3
		end
	end
	return count
end

-- 得到牌的花色
function nor_mj_base_lib.flower(_pai)
	return math.floor(_pai/10)
end

-- map 的牌集合 转换为 list
function nor_mj_base_lib.get_pai_list_by_map(_pai_map)
	if _pai_map then
		local list={}
		for _pai_id,_count in pairs(_pai_map) do
			for i=1,_count do
				list[#list+1]=_pai_id
			end
		end
		return list
	end

	return nil
end

-- list 牌的集合 转换为 map
function nor_mj_base_lib.get_pai_map_by_list(_pai_list)
	if _pai_list then
		local map = {}
		for _,_pai in ipairs(_pai_list) do
			map[_pai] = (map[_pai] or 0) + 1
		end

		return map
	end

	return nil
end


-- 转换 pai 的 list 为string，支持多个，每个之间用 | 隔开
function nor_mj_base_lib.pai_list_tostring(...)
	local _lists = {...}
	local _lss = {}
	for _,_list in ipairs(_lists) do
		local strs = {}
		for _,_pai in ipairs(_list) do
			strs[#strs + 1] = tostring(_pai)
		end

		_lss[#_lss + 1] = table.concat(strs,",")
	end

	return table.concat(_lss,"|")
end



-- 排序
-- 参数：
--	_pai_list 牌的列表
--	_que_pai （可选）打缺的花色，会排在最后
function nor_mj_base_lib.sort_pai(_pai_list,_que_flower)
	local _pai_order=function (_pai,_que_flower)
		if nor_mj_base_lib.flower(_pai) == _que_flower then
			return _pai + 99999
		else
			return _pai
		end
	end

	table.sort(_pai_list,function(_p1,_p2)
		return _pai_order(_p1,_que_flower)  <  _pai_order(_p2,_que_flower)
	end)
end

-- 自动出牌
function nor_mj_base_lib.auto_chupai(_mo_pai,_pai_map,_que_pai)

	--摸的牌恰好是缺直接打
	if _mo_pai and nor_mj_base_lib.flower(_mo_pai) == _que_pai then
		return _mo_pai
	end

	local ret = _mo_pai

	-- 找一张缺牌没有就其他牌
	for _pai,_num in pairs(_pai_map) do

		if _num > 0 then
			if nor_mj_base_lib.flower(_pai) == _que_pai then
				return _pai
			end
			if not ret then
				ret = _pai
			end
		end

	end

	return ret
end

-- 根据手上的牌，找一个最合适的花色定缺
-- 参数 _pai_list ： 牌的数组
function nor_mj_base_lib.get_ding_que_color(_pai_list)

	local _flower = {}

	for _,_pai in ipairs(_pai_list) do
		local f = nor_mj_base_lib.flower(_pai)
		_flower[f] = (_flower[f] or 0) + 1
	end

	if (_flower[1] or 0) > (_flower[2] or 0) then
		return (_flower[2] or 0) > (_flower[3] or 0) and 3 or 2
	else
		return (_flower[1] or 0) > (_flower[3] or 0) and 3 or 1
	end
end


function nor_mj_base_lib.get_init_jipaiqi()
	local jipaiqi={}
	for i=1,27 do
		jipaiqi[i]=4
	end
	return jipaiqi
end

function nor_mj_base_lib.jipaiqi_kick_pai(pai,jipaiqi,num)
	if pai  then
		pai=pai%10+math.floor(pai/10-1)*9
		if jipaiqi[pai] then
			num=num or 1
			jipaiqi[pai]=jipaiqi[pai]-num
			if jipaiqi[pai]<0 then
				print("记牌器 减牌变成负数")
				jipaiqi[pai]=0
			end
			if jipaiqi[pai]>4 then
				print("记牌器 加牌变成大于4")
				jipaiqi[pai]=4
			end
		end
	end
end

---- 检查是否能换牌
function nor_mj_base_lib.check_huan_pai(pai_map , old_pai_vec)
	if type(old_pai_vec)~="table" or #old_pai_vec > 3 then
		return false
	end

	local pai_num_vec = {}
	for k,v in pairs(old_pai_vec) do
		pai_num_vec[v] = pai_num_vec[v] or 0
		pai_num_vec[v] = pai_num_vec[v] + 1
	end

	for k,v in pairs(pai_num_vec) do
		if not pai_map[k] then
			return false
		elseif pai_map[k] < v then
			return false
		end
	end

	return true
end


return nor_mj_base_lib

















