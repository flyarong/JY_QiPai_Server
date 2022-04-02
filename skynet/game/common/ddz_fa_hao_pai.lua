---- add by wss 2019/3/28
--- 斗地主发好牌

local basefunc=require"basefunc"
--local grade_config = require "tuoguan_haopai_ddz_nor_cfg"


local DDZ_FA_HAO_PAI = {}
local C = DDZ_FA_HAO_PAI


--- 手牌数量
C.shoupai_num = 17

local PAI_TYPE = {
	danpai = "danpai",
	duizi = "duizi",
	liandui = "liandui",
	sanzhang = "sanzhang",
	shunzi = "shunzi",
	shuangfei = "shuangfei",
	boom = "boom",
	shuangwang = "shuangwang",
}

local PAI_TYPE_FACTOR = {
	danpai = 1,
	duizi = 2,
	liandui = 2,
	sanzhang = 3,
	shunzi = 1,
	shuangfei = 3,
	boom = 4,
	shuangwang = 2,
}



local GAILV_TYPE = {
		random = 1,               --- 完全随机
		Z_ratio_by_power = 2,     --- 根据控制力度正比例
		F_ratio_by_power = 3,     --- 根据控制力度负比例
		fix_all = 4,              --- 填补
	}




local PAI_TYPE_BASE_LEN = {
	danpai = 1,
	duizi = 1,
	liandui = 3,
	sanzhang = 1,
	shunzi = 5,
	shuangfei = 2,
	boom = 1,
	shuangwang = 1,	
}


function C.get_pai_map()
	--- 所有的牌的id
	local pai_map = {
		[3] = 4,
		[4] = 4,
		[5] = 4,
		[6] = 4,
		[7] = 4,
		[8] = 4,
		[9] = 4,
		[10] = 4,
		[11] = 4,
		[12] = 4,
		[13] = 4,
		[14] = 4,
		[15] = 4,
		[16] = 1,
		[17] = 1,
	}

	return pai_map
end

function C.get_er_pai_map()
	--- 所有的牌的id
	local pai_map = {
		[5] = 4,
		[6] = 4,
		[7] = 4,
		[8] = 4,
		[9] = 4,
		[10] = 4,
		[11] = 4,
		[12] = 4,
		[13] = 4,
		[14] = 4,
		[15] = 4,
		[16] = 1,
		[17] = 1,
	}

	return pai_map
end

function C.get_pai_id_pool()
	local pai_id_map = {
		[3] = {1,2,3,4},
		[4] = {5,6,7,8},
		[5] = {9,10,11,12},
		[6] = {13,14,15,16},
		[7] = {17,18,19,20},
		[8] = {21,22,23,24},
		[9] = {25,26,27,28},
		[10] = {29,30,31,32},
		[11] = {33,34,35,36},     -- J
		[12] = {37,38,39,40},     -- Q
		[13] = {41,42,43,44},     -- K
		[14] = {45,46,47,48},     -- A
		[15] = {49,50,51,52},     -- 2
		[16] = {53},
		[17] = {54},
	}
	return pai_id_map
end

local lj_pai_type_cfg = {
	--- pai_type  生成的牌型；min_num 最小的个数 ; max_num 最大的个数; min_pai 能创建的最小的牌; max_pai 能创建的最大的牌; gailv_type  个数概率类型
	[1] = { pai_type = PAI_TYPE.danpai  , min_num = 0, max_num = 2 , min_pai = 16 , max_pai = 17, gailv_type = GAILV_TYPE.random },
	[2] = { pai_type = PAI_TYPE.danpai  , min_num = 0, max_num = 0 , min_pai = 3 , max_pai = 15, gailv_type = GAILV_TYPE.fix_all },

}

local HAO_PAI_TYPE_GAILV = {
	danpai = 60,
	duizi = 50,
	liandui = 40,
	sanzhang = 40,
	shunzi = 40,
	shuangfei = 40,
	boom = 5,
	shuangwang = 20,
	shuangwang_dan = 80,
}

local use_grade_cfg = {
	laji_pai_create = lj_pai_type_cfg,
	min_boom_num = 0,
	max_boom_num = 2,
	select_boom_type = "min",
	haopai_type_gailv = HAO_PAI_TYPE_GAILV,
	all_pai_map = nil ,
	is_broke_remain_boom = true,
}




function C.add_pai_map(pai_map , pai_type , value)
	pai_map[pai_type] = (pai_map[pai_type] or 0) + value
end

---- 获得一个目标值通过概率类型
function C.get_target_value_by_gailv_type(min , max , gailv_type , ctrl_power)
	if gailv_type == GAILV_TYPE.random then
		return math.random( min , max )
	elseif gailv_type == GAILV_TYPE.Z_ratio_by_power then
		return min + math.floor( (max - min) * ctrl_power / 100 )
	elseif gailv_type == GAILV_TYPE.F_ratio_by_power then
		return max - math.floor( (max - min) * ctrl_power / 100 )
	elseif gailv_type == GAILV_TYPE.fix_all then
		return C.shoupai_num
	end
end

--------------------------------------------------------------------↓↓↓↓↓------------ 获得一个pai_map中的所有的牌类型 --------↓↓↓↓↓-------------------------------------------

function C.get_danpai_vec(pai_map)
	local vec = {}

	--- 先找到顺子
	local shunzi_vec = C.get_shunzi_vec(pai_map)

	for key = 3 , 17 do
		if pai_map[key] == 1 then
			local is_in_shunzi = false
			for i,data in pairs(shunzi_vec) do
				if data.start_pai <= key and key <= data.end_pai then
					is_in_shunzi = true
					break
				end
			end

			if not is_in_shunzi then
				vec[#vec + 1] = { start_pai = key , end_pai = key , len = 1 }
			end
		end
	end

	return vec
end

function C.get_duizi_vec(pai_map)
	local vec = {}

	--- 先找到连对
	local liandui_vec = C.get_liandui_vec(pai_map)

	for key = 3 , 17 do
		if pai_map[key] == 2 then
			local is_in_liandui = false
			for i,data in pairs(liandui_vec) do
				if data.start_pai < key and key < data.end_pai then
					is_in_liandui = true
					break
				end
			end

			if not is_in_liandui then
				vec[#vec + 1] = { start_pai = key , end_pai = key , len = 1 }
			end
		end
	end

	return vec
end

---- 获得一个pai_map中的连对
function C.get_liandui_vec(pai_map)
	local vec = {}

	local duizi_vec = C.get_same_pai_with_num( pai_map , 2 )

	table.sort( duizi_vec, function(a,b) 
		return a.start_pai < b.start_pai
	end)

	local dui_hash = {}
	for key,data in pairs(duizi_vec) do
		dui_hash[data.start_pai] = true
	end

	local deal_vec = {}
	for key = 3 , 13 do
		if not deal_vec[key] and dui_hash[key] then
			deal_vec[key] = true

			local start_pos = key
			local end_pos = key
			for i = key+1,14 do
				if not deal_vec[i] then
					deal_vec[i] = true
					if dui_hash[i] then
						end_pos = i
					else
						break
					end
				end
			end

			if end_pos - start_pos >= 2 then
				vec[#vec+1] = { start_pai = start_pos , end_pai = end_pos , len = end_pos - start_pos + 1 }  
			end

		end
	end

	return vec

end

---- 从一个牌map中拿到顺子的列表
function C.get_shunzi_vec(pai_map , min_length)
	local min_len = min_length or 2

	--- 顺子的数组
	local shunzi_vec = { }

	--- 不能创建顺子的节点
	local shunzi_empty_node = { [1] = {empty_node = 2} , [2] = {empty_node = 15} }

	for key = 3,14 do
		if not pai_map[key] or pai_map[key] <= 0 then
			shunzi_empty_node[#shunzi_empty_node + 1] = {empty_node = key}
		end
	end

	table.sort( shunzi_empty_node, function(a,b)
		return a.empty_node < b.empty_node
	end )

	for key = 1,#shunzi_empty_node - 1 do
		local start_pos = shunzi_empty_node[key].empty_node + 1
		local end_pos = shunzi_empty_node[key+1].empty_node - 1

		local _len = end_pos - start_pos + 1

		if start_pos < end_pos and _len >= min_len then
			shunzi_vec[#shunzi_vec + 1] = { start_pai = start_pos , end_pai = end_pos , len = _len }
		end
	end

	return shunzi_vec
end

function C.get_shunzi5_vec(pai_map)
	return C.get_shunzi_vec(pai_map , 5)
end

--- 获得 单牌，对子，三个，4个
function C.get_same_pai_with_num( pai_map , same_num )
	local vec = {}

	for pai_type , pai_num in pairs(pai_map) do
		if pai_num >= same_num then
			vec[#vec + 1] = {start_pai = pai_type , end_pai = pai_type , len = 1 }
		end
	end

	return vec
end

function C.get_real_same_pai_with_num( pai_map , same_num )
	local vec = {}

	for pai_type , pai_num in pairs(pai_map) do
		if pai_num == same_num then
			vec[#vec + 1] = {start_pai = pai_type , end_pai = pai_type , len = 1 }
		end
	end

	return vec
end

---- 获得炸弹
function C.get_boom_vec(pai_map)
	return C.get_same_pai_with_num( pai_map , 4 )
end

function C.get_sanzhang_vec(pai_map)
	return C.get_same_pai_with_num( pai_map , 3 )
end

------------ 获得一个pai_map中的双飞
function C.get_shuangfei_vec(pai_map)
	local vec = {}

	local sanzhang_vec = C.get_same_pai_with_num( pai_map , 3 )

	table.sort( sanzhang_vec, function(a,b) 
		return a.start_pai < b.start_pai
	end)

	local sanzhang_hash = {}
	for key,data in pairs(sanzhang_vec) do
		sanzhang_hash[data.start_pai] = true
	end

	local deal_vec = {}
	for key = 3 , 13 do
		if not deal_vec[key] and sanzhang_hash[key] then
			deal_vec[key] = true

			local start_pos = key
			local end_pos = key
			for i = key+1,14 do
				if not deal_vec[i] then
					deal_vec[i] = true
					if sanzhang_hash[i] then
						end_pos = i
					else
						break
					end
				end
			end

			if end_pos > start_pos then
				vec[#vec+1] = { start_pai = start_pos , end_pai = end_pos , len = end_pos - start_pos + 1 }  
			end

		end
	end

	return vec
end

C.PAI_TYPE_GET_FUNC = {
	danpai = C.get_danpai_vec,
	duizi = C.get_duizi_vec,
	liandui = C.get_liandui_vec,
	sanzhang = C.get_sanzhang_vec,
	shunzi = C.get_shunzi5_vec ,
	shuangfei = C.get_shuangfei_vec ,
	boom = C.get_boom_vec ,
	-- shuangwang = 2,
}
local PAI_TYPE_GET_FUNC = C.PAI_TYPE_GET_FUNC
--------------------------------------------------------------------↑↑↑↑↑------------ 获得一个pai_map中的所有的牌类型 --------↑↑↑↑↑-------------------------------------------

--- 从一个牌池里面创建顺子
function C.create_shunzi_type( total_pai_map , shunzi_num , min_pai , max_pai )
	local get_pai_map = {}

	--- map中的顺子数组
	local shunzi_vec = C.get_shunzi_vec(total_pai_map)

	--- 最大最小牌限制
	--local delete_vec = {}
	local cond_vec ={}
	for key,data in pairs(shunzi_vec) do
		local new_start = data.start_pai
		local new_end = data.end_pai

		if new_start < min_pai then
			new_start = min_pai
		end
		if new_end > max_pai then
			new_end = max_pai
		end

		if new_start < new_end then
			shunzi_vec[key].start_pai = new_start
			shunzi_vec[key].end_pai = new_end
			shunzi_vec[key].len = new_end - new_start + 1

			cond_vec[#cond_vec + 1] = basefunc.deepcopy( shunzi_vec[key] )
		else
			--delete_vec[#delete_vec + 1] = key
		end
	end
	--[[for key,value in ipairs(delete_vec) do
		table.remove( shunzi_vec , value )
	end--]]

	shunzi_vec = cond_vec


	---- 可以用来创建的
	can_shunzi_vec = {}

	for key , data in ipairs(shunzi_vec) do
		if data.len >= shunzi_num then
			can_shunzi_vec[#can_shunzi_vec + 1] = basefunc.deepcopy( data )
		end
	end

	--- 随机选一个
	local random_vec = nil
	if #can_shunzi_vec >=1 then
		random_vec = can_shunzi_vec[ math.random(#can_shunzi_vec) ]
	end

	if random_vec then
		local start_pai = math.random( random_vec.start_pai , random_vec.end_pai - shunzi_num + 1 )
		local end_pai = start_pai + shunzi_num - 1
		if random_vec.end_pai < end_pai then
			error( string.format("----------- no pai for shunzi,end_pai:%d,end_pos" , end_pai , random_vec.end_pai ) )
		end

		for key = start_pai , end_pai do
			get_pai_map[key] = 1
			---- 总牌池减
			total_pai_map[key] = total_pai_map[key] - 1
		end

	end

	return get_pai_map
end

--- 从一个牌池里面创建 连对
function C.create_liandui_type( total_pai_map , liandui_num , min_pai , max_pai )
	local get_pai_map = {}

	--- map中的顺子数组
	local liandui_vec = C.get_liandui_vec(total_pai_map)

	--- 最大最小牌限制
	--local delete_vec = {}
	local cond_vec ={}
	for key,data in pairs(liandui_vec) do
		local new_start = data.start_pai
		local new_end = data.end_pai

		if new_start < min_pai then
			new_start = min_pai
		end
		if new_end > max_pai then
			new_end = max_pai
		end

		if new_start < new_end then
			liandui_vec[key].start_pai = new_start
			liandui_vec[key].end_pai = new_end
			liandui_vec[key].len = new_end - new_start + 1

			cond_vec[#cond_vec + 1] = basefunc.deepcopy( liandui_vec[key] )
		else
			--delete_vec[#delete_vec + 1] = key
		end
	end
	--[[for key,value in ipairs(delete_vec) do
		table.remove( shunzi_vec , value )
	end--]]

	liandui_vec = cond_vec


	---- 可以用来创建的
	can_liandui_vec = {}

	for key , data in ipairs(liandui_vec) do
		if data.len >= liandui_num then
			can_liandui_vec[#can_liandui_vec + 1] = basefunc.deepcopy( data )
		end
	end

	--- 随机选一个
	local random_vec = nil
	if #can_liandui_vec >=1 then
		random_vec = can_liandui_vec[ math.random(#can_liandui_vec) ]
	end

	if random_vec then
		local start_pai = math.random( random_vec.start_pai , random_vec.end_pai - liandui_num + 1 )
		local end_pai = start_pai + liandui_num - 1
		if random_vec.end_pai < end_pai then
			error( string.format("----------- no pai for shunzi,end_pai:%d,end_pos" , end_pai , random_vec.end_pai ) )
		end

		for key = start_pai , end_pai do
			if total_pai_map[key] >=2 then
				get_pai_map[key] = 2
				---- 总牌池减
				total_pai_map[key] = total_pai_map[key] - 2
			else
				return {}
			end
		end

	end

	return get_pai_map
end

--- 从一个牌池里面创建 双飞
function C.create_shuangfei_type( total_pai_map , shuangfei_num , min_pai , max_pai )
	local get_pai_map = {}

	--- map中的顺子数组
	local shuangfei_vec = C.get_shuangfei_vec(total_pai_map)

	--- 最大最小牌限制
	--local delete_vec = {}
	local cond_vec ={}
	for key,data in pairs(shuangfei_vec) do
		local new_start = data.start_pai
		local new_end = data.end_pai

		if new_start < min_pai then
			new_start = min_pai
		end
		if new_end > max_pai then
			new_end = max_pai
		end

		if new_start < new_end then
			shuangfei_vec[key].start_pai = new_start
			shuangfei_vec[key].end_pai = new_end
			shuangfei_vec[key].len = new_end - new_start + 1

			cond_vec[#cond_vec + 1] = basefunc.deepcopy( shuangfei_vec[key] )
		else
			--delete_vec[#delete_vec + 1] = key
		end
	end
	--[[for key,value in ipairs(delete_vec) do
		table.remove( shunzi_vec , value )
	end--]]

	shuangfei_vec = cond_vec


	---- 可以用来创建的
	can_shuangfei_vec = {}

	for key , data in ipairs(shuangfei_vec) do
		if data.len >= shuangfei_num then
			can_shuangfei_vec[#can_shuangfei_vec + 1] = basefunc.deepcopy( data )
		end
	end

	--- 随机选一个
	local random_vec = nil
	if #can_shuangfei_vec >=1 then
		random_vec = can_shuangfei_vec[ math.random(#can_shuangfei_vec) ]
	end

	if random_vec then
		local start_pai = math.random( random_vec.start_pai , random_vec.end_pai - shuangfei_num + 1 )
		local end_pai = start_pai + shuangfei_num - 1
		if random_vec.end_pai < end_pai then
			error( string.format("----------- no pai for shuangfei,end_pai:%d,end_pos" , end_pai , random_vec.end_pai ) )
		end

		for key = start_pai , end_pai do
			if total_pai_map[key] >=3 then
				get_pai_map[key] = 3
				---- 总牌池减
				total_pai_map[key] = total_pai_map[key] - 3
			else
				return {}
			end
		end

	end

	return get_pai_map
end

--- 创建单牌，对子，三个，4个
function C.create_same_pai_with_num(same_num , total_pai_map , num , min_pai , max_pai)
	local get_pai_map = {}
	
	local can_vec = C.get_same_pai_with_num( total_pai_map , same_num )

	local add_vec = {}
	for key,data in pairs(can_vec) do
		for i=2 , math.floor(total_pai_map[data.start_pai] / same_num) do
			add_vec[#add_vec + 1] = {start_pai = data.start_pai , end_pai = data.start_pai , len = 1 }
		end
	end

	--- 
	for key,data in pairs(add_vec) do
		can_vec[#can_vec + 1] = data
	end

	--- 大小牌限制
	local cond_vec = {}
	for key,data in pairs(can_vec) do
		if data.start_pai >= min_pai and data.start_pai <= max_pai then
			cond_vec[#cond_vec + 1] = basefunc.deepcopy( data )
		end
	end
	can_vec = cond_vec

	--dump( can_vec , string.format("-------create_same_pai_with_num : %d" , same_num) )

	local target_num = math.min( #can_vec , num )

	for key = 1 , target_num do
		local random_index = math.random( #can_vec )
		local target_pai = can_vec[random_index].start_pai
		get_pai_map[ target_pai ] = (get_pai_map[ target_pai ] or 0) + same_num
		--print( "-----------add_pai:",target_pai , same_num )
		
		---- 总牌池减
		total_pai_map[target_pai] = total_pai_map[target_pai] - same_num

		--if total_pai_map[target_pai] < same_num then
			table.remove( can_vec , random_index )
			--dump( can_vec , string.format("-------create_same_pai_with_num delete: %d" , same_num) )
		--end

	end


	return get_pai_map
end






---- 获得一个牌map的数量
function C.get_sp_map_num(pai_map)
	local num = 0
	for key,value in pairs(pai_map) do
		if value and type(value) == "number" then
			num = num + value
		end
	end
	return num
end

------ 处理每个配置项的创建
function C.deal_pai_type_cfg_item(total_pai_map , data , shoupai_map , ctrl_power)
	-- 当前手牌个数
	local now_sp_num = C.get_sp_map_num(shoupai_map)
	-- 
	if now_sp_num >= C.shoupai_num then
		return
	end
	--- 目标个数
	local target_num = C.get_target_value_by_gailv_type(data.min_num , data.max_num , data.gailv_type , ctrl_power)

	if target_num * PAI_TYPE_FACTOR[data.pai_type] + now_sp_num > C.shoupai_num then
		target_num = math.floor( (C.shoupai_num - now_sp_num ) / PAI_TYPE_FACTOR[data.pai_type] )
	end
	-- print("------www-----------deal_pai_type_cfg_item:",data.pai_type,target_num)
	--- 找到的牌行的数据
	local get_pai_map = {}
	if data.pai_type == PAI_TYPE.shunzi then
		get_pai_map = C.create_shunzi_type( total_pai_map , target_num , data.min_pai , data.max_pai )
	elseif data.pai_type == PAI_TYPE.boom then
		get_pai_map = C.create_same_pai_with_num( 4 , total_pai_map , target_num , data.min_pai , data.max_pai )
	elseif data.pai_type == PAI_TYPE.sanzhang then
		get_pai_map = C.create_same_pai_with_num( 3 , total_pai_map , target_num , data.min_pai , data.max_pai )
	elseif data.pai_type == PAI_TYPE.duizi then
		get_pai_map = C.create_same_pai_with_num( 2 , total_pai_map , target_num , data.min_pai , data.max_pai )
	elseif data.pai_type == PAI_TYPE.danpai then
		get_pai_map = C.create_same_pai_with_num( 1 , total_pai_map , target_num , data.min_pai , data.max_pai )
	elseif data.pai_type == PAI_TYPE.liandui then
		--- 暂时不做，会随机生成
		get_pai_map = C.create_liandui_type( total_pai_map , target_num , data.min_pai , data.max_pai )
	elseif data.pai_type == PAI_TYPE.shuangfei then
		--- 暂时不做，会随机生成
		get_pai_map = C.create_shuangfei_type( total_pai_map , target_num , data.min_pai , data.max_pai )
	end

	----- 加到手牌中
	for pai_type , pai_num in pairs(get_pai_map) do
		shoupai_map[pai_type] = (shoupai_map[pai_type] or 0) + pai_num
	end

end

function C.get_pai_id_list( total_id_pool , pai_map )

	local function get_one_random_pai_id(total_id_pool , pai_type)
		if total_id_pool[pai_type] and #total_id_pool[pai_type] > 0 then
			local random_index = math.random( #total_id_pool[pai_type] )
			local random_pai_id = total_id_pool[pai_type][random_index]

			table.remove( total_id_pool[pai_type] , random_index )

			return random_pai_id
		end
	end


	local pai_id_list = {}
	for pai_type , pai_num in pairs(pai_map) do
		if pai_num > 0 then
			for i=1,pai_num do
				pai_id_list[#pai_id_list + 1] = get_one_random_pai_id(total_id_pool , pai_type)
			end
		end
			
	end

	return pai_id_list
end

------ 创建一种类型的牌，并返回id_list
function C.create_type_pai( total_pai_map , cfg )
	local nice_pai_map = C.create_lj_pai(total_pai_map , cfg , 50)
	local total_pai_id_pool = C.get_pai_id_pool()
	local nice_pai_id_list = C.get_pai_id_list( total_pai_id_pool , nice_pai_map )

	--- check
	if #nice_pai_id_list ~= C.shoupai_num then
		error( string.format("------------------create_type_pai : #nice_pai_id_list ~= C.shoupai_num" ,  #nice_pai_id_list , C.shoupai_num ) )
	end

	return nice_pai_id_list
end


--- 创建 最次牌
function C.create_lj_pai(total_pai_map , cfg , ctrl_power)
	--- 牌的类型map ， key  牌类型id , value 个数  
	local shoupai_map = {}

	---- 生成配置中的牌型
	for key,data in ipairs(cfg) do
		C.deal_pai_type_cfg_item( total_pai_map , data , shoupai_map , ctrl_power)
	end

	--- 用单牌补上。
	local now_sp_num = C.get_sp_map_num(shoupai_map)
	if now_sp_num < C.shoupai_num then
		local data = { pai_type = PAI_TYPE.danpai  , min_num = 0, max_num = 0 , min_pai = 3 , max_pai = 17, gailv_type = GAILV_TYPE.fix_all }
		C.deal_pai_type_cfg_item( total_pai_map , data , shoupai_map , ctrl_power)
	end

	---- 判断一下
	if C.get_sp_map_num(shoupai_map) ~= C.shoupai_num then
		error( "------------------- create_lj_pai - shoupai num not right !!" )
	end


	return shoupai_map
end

--- 创建最好的牌
function C.create_best_pai(total_pai_map , laji_pai_map )
	--- 牌的类型map ， key  牌类型id , value 个数  
	local shoupai_map = {}

	C.create_best_pai_item(total_pai_map , laji_pai_map , shoupai_map )

	--- 用单牌补上。
	local now_sp_num = C.get_sp_map_num(shoupai_map)
	--print("-----------now_sp_num:",now_sp_num)
	--dump( shoupai_map , "--wwwwwwww------------shoupai_map" )
	--dump( total_pai_map , "--wwwwwwww------------total_pai_map" )
	if now_sp_num < C.shoupai_num then
		local data = { pai_type = PAI_TYPE.danpai  , min_num = 0, max_num = 0 , min_pai = 3 , max_pai = 17, gailv_type = GAILV_TYPE.fix_all }
		C.deal_pai_type_cfg_item( total_pai_map , data , shoupai_map , ctrl_power)
	end

	---- 判断一下
	if C.get_sp_map_num(shoupai_map) ~= C.shoupai_num then
		dump( shoupai_map , "--------------shoupai_map" )
		dump( laji_pai_map , "--------------laji_pai_map" )
		dump( total_pai_map , "--------------total_pai_map" )
		error( "------------------- create_best_pai - shoupai num not right !!" )
	end

	--dump( shoupai_map , "-xxxxx---------create_best_pai----shoupai_map" )

	return shoupai_map
end

function C.get_total_pai_map_num()
	local total_pai_map_num = 0
	for pai_type,pai_num in pairs(use_grade_cfg.all_pai_map) do
		total_pai_map_num = total_pai_map_num + pai_num
	end
	return total_pai_map_num
end

function C.check_all_hand_pai_map( best_pai_map , remain_pai , laji_pai_map , dizhu_pai_map )
	local end_pai_map = {}
	local end_pai_num = 0

	local total_pai_map_num = C.get_total_pai_map_num()


	local function add_pai_map_to_end(end_pai_map , add_pai_map)
		for pai_type,pai_num in pairs(add_pai_map) do
			end_pai_map[pai_type] = (end_pai_map[pai_type] or 0) + pai_num
			end_pai_num = end_pai_num + pai_num
		end
	end

	add_pai_map_to_end(end_pai_map , best_pai_map)
	add_pai_map_to_end(end_pai_map , remain_pai)
	add_pai_map_to_end(end_pai_map , laji_pai_map)
	add_pai_map_to_end(end_pai_map , dizhu_pai_map)

	--
	if end_pai_num ~= total_pai_map_num then
		error( string.format( "----------end pai num not equal %d !!!", total_pai_map_num ))
	end
	for pai_type , pai_num in pairs(end_pai_map) do
		if pai_type < 16 and pai_num ~= 4 then
			dump( best_pai_map , "--------------best_pai_map" )
			dump( remain_pai , "--------------remain_pai" )
			dump( laji_pai_map , "--------------laji_pai_map" )
			dump( dizhu_pai_map , "--------------dizhu_pai_map" )
			dump( end_pai_map , "--------------end_pai_map" )
			error( string.format( "--------pai_type:%d not equal 4 , is %d" , pai_type , pai_num ) )
		elseif (pai_type == 16 or pai_type == 17) and pai_num~= 1 then
			error( string.format( "--------pai_type:%d not equal 1 , is %d" , pai_type , pai_num ) )
		end
	end
end

function C.check_all_hand_pai_id_list( best_pai_id_list , remain_pai_id_list , lj_pai_id_list , dizhu_pai_id_list )
	local total_pai_map_num = C.get_total_pai_map_num()

	if #best_pai_id_list ~= C.shoupai_num then
		--dump(best_pai_map , "--------------best_pai_map")
		dump(best_pai_id_list , "--------------best_pai_map"  )
		error("-----------end , #best_pai_id_list ~= C.shoupai_num")
	end
	if #lj_pai_id_list ~= C.shoupai_num then
		error("-----------end , #lj_pai_id_list ~= C.shoupai_num")
	end
	if #remain_pai_id_list ~= total_pai_map_num - 3 - 2 * C.shoupai_num then
		error("-----------end , #remain_pai_id_list ~= C.shoupai_num")
	end
	if #dizhu_pai_id_list ~= 3 then
		error("-----------end , #dizhu_pai_id_list ~= 3")
	end

	if #best_pai_id_list + #lj_pai_id_list + #remain_pai_id_list + #dizhu_pai_id_list ~= total_pai_map_num then
		dump(best_pai_id_list , "++++++ best_pai_id_list")
		dump(lj_pai_id_list , "++++++ lj_pai_id_list")
		dump(remain_pai_id_list , "++++++ remain_pai_id_list")
		dump(dizhu_pai_id_list , "++++++ dizhu_pai_id_list")
		error( string.format("----------end pai_id_list num not equal %d !!! %d" , total_pai_map_num , #best_pai_id_list + #lj_pai_id_list + #remain_pai_id_list + #dizhu_pai_id_list ) )
	end
	local end_pai_id_list = {}
	for key,pai_id in pairs(best_pai_id_list) do
		end_pai_id_list[pai_id] = true
	end
	for key,pai_id in pairs(lj_pai_id_list) do
		end_pai_id_list[pai_id] = true
	end
	for key,pai_id in pairs(remain_pai_id_list) do
		end_pai_id_list[pai_id] = true
	end
	for key,pai_id in pairs(dizhu_pai_id_list) do
		end_pai_id_list[pai_id] = true
	end
	local end_total_num = 0
	for key,value in pairs(end_pai_id_list) do
		end_total_num = end_total_num + 1
	end

	if end_total_num ~= total_pai_map_num then
		error( string.format("----------end pai_id_list2 num not equal %d , now:%d !!!" , total_pai_map_num , end_total_num) )
	end
end

---- 获得随机地主牌
function C.get_random_dizhu_pai( total_pai_map )
	local dizhu_pai_map = {}
	local total_pai_type = {}
	for pai_type,pai_num in pairs(total_pai_map) do
		if pai_num > 0 then
			for i=1,pai_num do
				total_pai_type[#total_pai_type + 1] = pai_type
			end
		end
	end

	for i=1,3 do
		local rand_index = math.random( #total_pai_type )
		local rand_pai_type = total_pai_type[rand_index]

		dizhu_pai_map[rand_pai_type] = (dizhu_pai_map[rand_pai_type] or 0) + 1
		total_pai_map[rand_pai_type] = total_pai_map[rand_pai_type] - 1
		table.remove( total_pai_type , rand_index)
	end

	return dizhu_pai_map
end

---- 获得和一个pai_map相益的地主牌
function C.get_friendly_dizhu_pai( target_pai_map , total_pai_map )
	local dizhu_pai_map = {}
	local dizhu_pai_num = 0

	-- 已经处理过的牌的类型
	local dealed_pai_type_vec = {}

	---- 单牌转成对子
	local danpai_vec = C.get_danpai_vec( target_pai_map )

	for key,data in pairs(danpai_vec) do
		if dizhu_pai_num < 3 and data.start_pai and not dealed_pai_type_vec[data.start_pai] and total_pai_map[data.start_pai] and total_pai_map[data.start_pai] > 0 then
			dizhu_pai_map[data.start_pai] = (dizhu_pai_map[data.start_pai] or 0) + 1
			total_pai_map[data.start_pai] = total_pai_map[data.start_pai] - 1

			dizhu_pai_num = dizhu_pai_num + 1
			dealed_pai_type_vec[data.start_pai] = true
		end
	end

	----- 对子转三张
	local duizi_vec = C.get_duizi_vec(target_pai_map)

	for key,data in pairs(duizi_vec) do
		if dizhu_pai_num < 3 and data.start_pai and not dealed_pai_type_vec[data.start_pai] and total_pai_map[data.start_pai] and total_pai_map[data.start_pai] > 0 then
			dizhu_pai_map[data.start_pai] = (dizhu_pai_map[data.start_pai] or 0) + 1
			total_pai_map[data.start_pai] = total_pai_map[data.start_pai] - 1

			dizhu_pai_num = dizhu_pai_num + 1
			dealed_pai_type_vec[data.start_pai] = true
		end
	end

	----- 三张转炸弹
	local sanzhang_vec = C.get_sanzhang_vec(target_pai_map)

	for key,data in pairs(sanzhang_vec) do
		if dizhu_pai_num < 3 and data.start_pai and not dealed_pai_type_vec[data.start_pai] and total_pai_map[data.start_pai] and total_pai_map[data.start_pai] > 0 then
			dizhu_pai_map[data.start_pai] = (dizhu_pai_map[data.start_pai] or 0) + 1
			total_pai_map[data.start_pai] = total_pai_map[data.start_pai] - 1

			dizhu_pai_num = dizhu_pai_num + 1
			dealed_pai_type_vec[data.start_pai] = true
		end
	end


	----- 最后再补齐3张
	if dizhu_pai_num < 3 then
		local total_pai_type = {}
		for pai_type,pai_num in pairs(total_pai_map) do
			if pai_num > 0 then
				for i=1,pai_num do
					total_pai_type[#total_pai_type + 1] = pai_type
				end
			end
		end
		local start_num = dizhu_pai_num

		for key = start_num , 3 - 1 do
			
			local rand_index = math.random( #total_pai_type )
			local rand_pai_type = total_pai_type[rand_index]

			dizhu_pai_map[rand_pai_type] = (dizhu_pai_map[rand_pai_type] or 0) + 1
			total_pai_map[rand_pai_type] = total_pai_map[rand_pai_type] - 1
			dizhu_pai_num = dizhu_pai_num + 1
			table.remove( total_pai_type , rand_index)
		end
	end

	if dizhu_pai_num ~= 3 then
		error("------   dizhu_pai_num ~= 3 ")
	end

	return dizhu_pai_map
end

---------------------------- 
function C.create_all_hand_card_item(total_pai_map , lj_pai_type_cfg , ctrl_power)
	local total_pai_map_num = C.get_total_pai_map_num()

	--- 最次的牌
	local laji_pai_map = C.create_lj_pai(total_pai_map , lj_pai_type_cfg, ctrl_power)

	--- 最好牌
	local best_pai_map = C.create_best_pai(total_pai_map , laji_pai_map)

	----- 验证
	local remain_pai_num = C.get_sp_map_num( total_pai_map )

	if remain_pai_num ~= total_pai_map_num - 2*C.shoupai_num then
		dump( best_pai_map , "--------------best_pai_map" )
		dump( laji_pai_map , "--------------laji_pai_map" )
		dump( total_pai_map , "--------------total_pai_map" )
		error( string.format("-------------- remain_pai not equal %d ! %d " , total_pai_map_num - 2*C.shoupai_num , remain_pai_num) )
	end

	--- 地主牌 , 
	local dizhu_pai_map = nil
	if ctrl_power == 100 then
		--- 友好地主牌
		dizhu_pai_map = C.get_friendly_dizhu_pai( best_pai_map , total_pai_map )

		--dump(best_pai_map , "---------for dizhu_pai , best_pai_map")
		--dump(dizhu_pai_map , "---------for dizhu_pai , dizhu_pai_map")
	else
		-- 随机地主牌
		dizhu_pai_map = C.get_random_dizhu_pai( total_pai_map )
	end
	
	if not dizhu_pai_map then
		dizhu_pai_map = C.get_random_dizhu_pai( total_pai_map )
	end
	

	--- 剩余牌
	local remain_pai = total_pai_map

	--------------------------------- 验证 pai_map -------------------
	C.check_all_hand_pai_map( best_pai_map , remain_pai , laji_pai_map , dizhu_pai_map )


	-------------
	local total_pai_id_pool = C.get_pai_id_pool()
	local best_pai_id_list = C.get_pai_id_list( total_pai_id_pool , best_pai_map ) 
	local lj_pai_id_list = C.get_pai_id_list( total_pai_id_pool , laji_pai_map ) 
	local remain_pai_id_list = C.get_pai_id_list( total_pai_id_pool , remain_pai ) 
	local dizhu_pai_id_list = C.get_pai_id_list( total_pai_id_pool , dizhu_pai_map ) 

	-------------------------------------------------------- 验证一下 pai_id_list -----------------------------------------
	C.check_all_hand_pai_id_list( best_pai_id_list , remain_pai_id_list , lj_pai_id_list , dizhu_pai_id_list )

	---- 获得所有炸弹的个数
	local best_boom_vec = C.get_boom_vec( best_pai_map )
	local lj_boom_vec = C.get_boom_vec( laji_pai_map )
	local remain_boom_vec = C.get_boom_vec( remain_pai )
	local shuangwang = (best_pai_map[16]== 1 and best_pai_map[17]== 1) or (laji_pai_map[16]== 1 and laji_pai_map[17]== 1) or 
						(remain_pai[16]== 1 and remain_pai[17]== 1)

	local total_boom_num = #best_boom_vec + #lj_boom_vec + #remain_boom_vec + (shuangwang and 1 or 0)

	return { best_pai_id_list , remain_pai_id_list , lj_pai_id_list , dizhu_pai_id_list } , total_boom_num
	--return { best_pai_map , remain_pai , laji_pai_map , dizhu_pai_map }
end

---- 创建3家的手牌，返回列表，第一个为好牌，最后一个为垃圾牌
--[[
	参数:控制力度 , 范围：0~100 。 
	PS：从自动水池过来的值,需要转换成这里的值，0~50是亏钱，50~100是赚钱，赚钱用返回的列表中的第一个，亏钱用最后一个
	自动水池的0和100都对应这里的参数的100

	思路：先按照牌型生成垃圾牌，然后在生成好牌，好牌就是围堵垃圾牌，剩下的就是一般的牌

--]]
function C.create_all_hand_card( all_pai_map , grade_config , ctrl_power )
	if grade_config then
		use_grade_cfg = grade_config
	end

	use_grade_cfg.all_pai_map = all_pai_map or C.get_pai_map()	

	if use_grade_cfg.laji_pai_create then
		lj_pai_type_cfg = use_grade_cfg.laji_pai_create 
	end
	if use_grade_cfg.haopai_type_gailv then
		HAO_PAI_TYPE_GAILV = use_grade_cfg.haopai_type_gailv
	end

    -----------------------------------------------------------------------------------------------
	local ret_list = nil

	local create_vec = {}
	local max_create_num = 10
	local now_create_num = 0
	local is_create_best = false
	for i=1,10 do
		
		local total_pai_map = basefunc.deepcopy( use_grade_cfg.all_pai_map )
		local list , boom_num = C.create_all_hand_card_item( total_pai_map , use_grade_cfg.laji_pai_create ,ctrl_power)

		if boom_num <= use_grade_cfg.max_boom_num and boom_num >= use_grade_cfg.min_boom_num then
			ret_list = list
			is_create_best = true
			break
		else
			create_vec[#create_vec + 1] = { create_list = list , boom_num = boom_num }
		end

		now_create_num = now_create_num + 1
	end

	if not is_create_best and now_create_num > 1 and now_create_num == max_create_num and create_vec and #create_vec > 1 then
		
		if use_grade_cfg.select_boom_type == "min" then
			table.sort( create_vec , function(a,b) 
				return a.boom_num < b.boom_num
			end)
		elseif use_grade_cfg.select_boom_type == "max" then
			table.sort( create_vec , function(a,b) 
				return a.boom_num > b.boom_num
			end)
		end

		ret_list = create_vec[1].create_list
	end


	return ret_list
end


------------------------------ 创建比垃圾牌要好的牌 ---------------------------------
function C.create_best_pai_item( total_pai_map , laji_pai_map , shoupai_map )
	C.create_best_pai_boom( total_pai_map , laji_pai_map , shoupai_map  )

	---- 好牌 按一定概率   随机选一张大王，小王
	local _rand = math.random() * 100
	if _rand <= HAO_PAI_TYPE_GAILV.shuangwang_dan then

		local random = math.random()
		if random<0.5 then
			local data = { pai_type = PAI_TYPE.danpai  , min_num = 1, max_num = 1 , min_pai = 16 , max_pai = 16, gailv_type = GAILV_TYPE.random }
			C.deal_pai_type_cfg_item( total_pai_map , data , shoupai_map , 0)
		else
			local data = { pai_type = PAI_TYPE.danpai  , min_num = 1, max_num = 1 , min_pai = 17 , max_pai = 17, gailv_type = GAILV_TYPE.random }
			C.deal_pai_type_cfg_item( total_pai_map , data , shoupai_map , 0)
		end

	end

	---- 压制双飞，容易产生炸弹
	--C.create_best_pai_shuangfei( total_pai_map , laji_pai_map , shoupai_map  )

	---- 连对，顺子，三张，压制得随机一点
	local random = math.random()
	if random <= 1 then
		C.create_best_pai_liandui( total_pai_map , laji_pai_map , shoupai_map  )
		C.create_best_pai_shunzi( total_pai_map , laji_pai_map , shoupai_map  )
		C.create_best_pai_sanzhang( total_pai_map , laji_pai_map , shoupai_map  )
	elseif random < 0.8 then
		C.create_best_pai_shunzi( total_pai_map , laji_pai_map , shoupai_map  )
		C.create_best_pai_liandui( total_pai_map , laji_pai_map , shoupai_map  )
		C.create_best_pai_sanzhang( total_pai_map , laji_pai_map , shoupai_map  )
	elseif random < 0.6 then
		C.create_best_pai_sanzhang( total_pai_map , laji_pai_map , shoupai_map  )
		C.create_best_pai_liandui( total_pai_map , laji_pai_map , shoupai_map  )
		C.create_best_pai_shunzi( total_pai_map , laji_pai_map , shoupai_map  )
	elseif random < 0.4 then
		C.create_best_pai_liandui( total_pai_map , laji_pai_map , shoupai_map  )
		C.create_best_pai_sanzhang( total_pai_map , laji_pai_map , shoupai_map  )
		C.create_best_pai_shunzi( total_pai_map , laji_pai_map , shoupai_map  )
	elseif random < 0.2 then
		C.create_best_pai_shunzi( total_pai_map , laji_pai_map , shoupai_map  )
		C.create_best_pai_sanzhang( total_pai_map , laji_pai_map , shoupai_map  )
		C.create_best_pai_liandui( total_pai_map , laji_pai_map , shoupai_map  )
	end



	C.create_best_pai_duizi( total_pai_map , laji_pai_map , shoupai_map  )
	C.create_best_pai_danpai( total_pai_map , laji_pai_map , shoupai_map  )

	---

end

---- 创建更好的炸弹
function C.create_best_pai_boom( total_pai_map , laji_pai_map , shoupai_map  )
	--- 垃圾牌中的炸弹数组
	local laji_boom_vec = C.get_same_pai_with_num( laji_pai_map , 4 )

	if #laji_boom_vec <= 0 then	
		return
	end

	table.sort( laji_boom_vec , function(a,b) 
		return a.start_pai > b.start_pai
	end )

	local now_sp_num = C.get_sp_map_num(shoupai_map)
	local remain_num = C.shoupai_num - now_sp_num

	--- 先看双王是否还在
	local shuangwang = total_pai_map[16] == 1 and total_pai_map[17] == 1

	--- 还有的炸弹数
	local boom_vec = C.get_same_pai_with_num( total_pai_map , 4 )

	table.sort( boom_vec , function(a,b) 
		return a.start_pai > b.start_pai
	end )

	local laji_boom_vec_len = #laji_boom_vec
	--- 垃圾牌的双王，炸弹长度要+1
	if laji_pai_map[16] == 1 and laji_pai_map[17] == 1 then
		laji_boom_vec_len = laji_boom_vec_len + 1
	end

	--- 新增一个炸弹，根据配置
	if use_grade_cfg and use_grade_cfg.extra_boom_num and type(use_grade_cfg.extra_boom_num) == "number" then
		laji_boom_vec_len = laji_boom_vec_len + use_grade_cfg.extra_boom_num
	end

	--- 目标数量
	local target_num = math.min( laji_boom_vec_len , math.floor( remain_num / PAI_TYPE_FACTOR.boom ) )

	--- 从最大的炸弹选
	local create_num = 0

	
	local shuangwang_boom = 0
	for i=1,target_num do
		repeat

			if shuangwang then
				shoupai_map[16] = 1
				shoupai_map[17] = 1

				total_pai_map[16] = 0
				total_pai_map[17] = 0

				shuangwang = false
				create_num = create_num + 1
				shuangwang_boom = 1
				break
			end

			--- 最好就是一个炸弹对应一个更大的
			local target_index = i - shuangwang_boom

			--if boom_vec[target_index] and boom_vec[target_index].start_pai > laji_boom_vec[target_index].start_pai then
			if boom_vec[target_index] then
				shoupai_map[ boom_vec[target_index].start_pai ] = 4
				total_pai_map[ boom_vec[target_index].start_pai ] = 0

				create_num = create_num + 1
			end

		until true
	end

	--- 从最小的找，补上，且多一个
	--[[if target_num > create_num then
		for key=1,target_num - create_num + 1 do
			for i=#boom_vec , 1 do
				if not shoupai_map[ boom_vec[i].start_pai ] or shoupai_map[ boom_vec[i].start_pai ] == 0 then
					shoupai_map[ boom_vec[i].start_pai ] = 4
					total_pai_map[ boom_vec[i].start_pai ] = 0

					break
				end
			end
		end
	end--]]

	----- 如果最后没有炸弹，随机补上一个
	if target_num == 0 then

		---- 随机补双王
		local is_create_boom = false
		if total_pai_map[16] == 1 and total_pai_map[17] == 1 then
			local random = math.random() * 100
			if random < HAO_PAI_TYPE_GAILV.shuangwang then
				shoupai_map[16] = 1
				shoupai_map[17] = 1

				total_pai_map[16] = 0
				total_pai_map[17] = 0

				is_create_boom = true
			end
		end

		if not is_create_boom then
			C.create_one_biggest_rand_pai_type( total_pai_map , laji_pai_map , shoupai_map , PAI_TYPE.boom )
		end

	end

end

---- 创建更好的 双飞
function C.create_best_pai_shuangfei( total_pai_map , laji_pai_map , shoupai_map  )
	--------------
	local is_create_best = C.create_one_biggest_for_pai_type( total_pai_map , laji_pai_map , shoupai_map , PAI_TYPE.shuangfei )

	if is_create_best then
		return
	end

	--C.create_one_biggest_rand_pai_type( total_pai_map , laji_pai_map , shoupai_map , PAI_TYPE.shuangfei )
end

---- 创建更好的连对
function C.create_best_pai_liandui( total_pai_map , laji_pai_map , shoupai_map  )
	local is_create_best = C.create_one_biggest_for_pai_type( total_pai_map , laji_pai_map , shoupai_map , PAI_TYPE.liandui )

	if is_create_best then
		return
	end

	--- 
	C.create_one_biggest_rand_pai_type( total_pai_map , laji_pai_map , shoupai_map , PAI_TYPE.liandui )


end

----创建更好的 顺子
function C.create_best_pai_shunzi( total_pai_map , laji_pai_map , shoupai_map  )
	local is_create_best = C.create_one_biggest_for_pai_type( total_pai_map , laji_pai_map , shoupai_map , PAI_TYPE.shunzi )

	if is_create_best then
		return
	end

	--- 
	C.create_one_biggest_rand_pai_type( total_pai_map , laji_pai_map , shoupai_map , PAI_TYPE.shunzi )
end


----创建更好的 三张
function C.create_best_pai_sanzhang( total_pai_map , laji_pai_map , shoupai_map  )
	local is_create_best = C.create_one_biggest_for_pai_type( total_pai_map , laji_pai_map , shoupai_map , PAI_TYPE.sanzhang )

	if is_create_best then
		return
	end

	------------
	C.create_one_biggest_rand_pai_type( total_pai_map , laji_pai_map , shoupai_map , PAI_TYPE.sanzhang )


end

----创建更好的 对子
function C.create_best_pai_duizi( total_pai_map , laji_pai_map , shoupai_map  )
	C.create_all_biggest_for_pai_type(total_pai_map , laji_pai_map , shoupai_map , PAI_TYPE.duizi)

	C.create_one_biggest_rand_pai_type( total_pai_map , laji_pai_map , shoupai_map , PAI_TYPE.duizi )

end

----创建更好的 单牌
function C.create_best_pai_danpai( total_pai_map , laji_pai_map , shoupai_map  )
	--C.create_all_biggest_for_pai_type(total_pai_map , laji_pai_map , shoupai_map , PAI_TYPE.danpai)

	-------------------------------------------------- 先打破列 剩余牌中的炸弹牌 --------------------------------------------------
	if use_grade_cfg.is_broke_remain_boom then

		local zhadan_vec = C.get_boom_vec( total_pai_map )

		local target_num = #zhadan_vec 

		local now_sp_num = C.get_sp_map_num(shoupai_map)
		local remain_num = C.shoupai_num - now_sp_num
		
		if remain_num < target_num * PAI_TYPE_FACTOR[PAI_TYPE.danpai] then
			target_num = math.floor(remain_num / PAI_TYPE_FACTOR[PAI_TYPE.danpai])
		end

		for i=1,target_num do
			shoupai_map[ zhadan_vec[i].start_pai ] = (shoupai_map[ zhadan_vec[i].start_pai ] or 0) + PAI_TYPE_FACTOR[PAI_TYPE.danpai]
			total_pai_map[ zhadan_vec[i].start_pai ] = total_pai_map[ zhadan_vec[i].start_pai ] - PAI_TYPE_FACTOR[PAI_TYPE.danpai]
		end
	end

	 -------------------------------------------------------------------
	---- 最后用较大的单牌补齐
	if C.get_sp_map_num( shoupai_map ) < C.shoupai_num then
		local data = { pai_type = PAI_TYPE.danpai  , min_num = 0, max_num = 0 , min_pai = 9 , max_pai = 17, gailv_type = GAILV_TYPE.fix_all }
		C.deal_pai_type_cfg_item( total_pai_map , data , shoupai_map , 0)
	end
	---- 如果还不齐就再补齐
	if C.get_sp_map_num( shoupai_map ) < C.shoupai_num then
		local data = { pai_type = PAI_TYPE.danpai  , min_num = 0, max_num = 0 , min_pai = 3 , max_pai = 17, gailv_type = GAILV_TYPE.fix_all }
		C.deal_pai_type_cfg_item( total_pai_map , data , shoupai_map , 0)
	end

	---------------------------- 单牌最后调整一下，避免单牌过多 ------------------------------------
	---- 总体思路：消减  3张or对子 来把单牌凑成顺子，or对子or3张 ; 但是要避免又把剩余的牌的炸弹搞多了
	local danpai_vec = C.get_danpai_vec( shoupai_map )

	--- 除掉大小王
	local cond_vec = {}
	for key,data in pairs(danpai_vec) do
		if data.start_pai ~= 15 and data.start_pai ~= 16 and data.start_pai ~= 17 then
			cond_vec[#cond_vec + 1] = basefunc.deepcopy( data )
		end
	end
	danpai_vec = cond_vec

	if #danpai_vec > 1 then
		
		C.adjust_shunzi( shoupai_map , danpai_vec , total_pai_map )
		C.adjust_sanzhang( shoupai_map , danpai_vec , total_pai_map )
		C.adjust_duizi( shoupai_map , danpai_vec , total_pai_map )

	end

end

function C.adjust_shunzi( shoupai_map , danpai_vec , total_pai_map )

	--- 判断vec中是否已经有某种牌
	local function check_is_have_pai( danpai_vec , pai_type )
		for key, data in pairs(danpai_vec) do
			if data.start_pai == pai_type then
				return true
			end
		end
		return false
	end

	if #danpai_vec >= 5 then
		for i=1,#danpai_vec do
			local is_adjust = false
			local danpai_n_vec = {}

			for key =1,#danpai_vec do
				if key == 1 then
					danpai_n_vec[key] = danpai_vec[i].start_pai
				else
					danpai_n_vec[key] = danpai_vec[ (i + key - 2) % #danpai_vec + 1 ].start_pai
				end
			end

			--[[local danpai_1 = danpai_vec[i].start_pai
			local danpai_2 = danpai_vec[ (i)%5 + 1 ].start_pai
			local danpai_3 = danpai_vec[ (i+1)%5 + 1 ].start_pai
			local danpai_4 = danpai_vec[ (i+2)%5 + 1 ].start_pai
			local danpai_5 = danpai_vec[ (i+3)%5 + 1 ].start_pai--]]

			local start_pai = danpai_n_vec[1]
			if start_pai <= 10 then
					
				--- 需要替换的找到
				local need_replace = {}

				for key=2,#danpai_n_vec do
					if danpai_n_vec[key] < start_pai or danpai_n_vec[key] >= start_pai + 5 then
						need_replace[#need_replace + 1] = danpai_n_vec[key]
					end
				end
				---------------
				--- 已经有了的
				local haved_vec = {}
				for key = 1, 4 do
					if check_is_have_pai( danpai_vec , start_pai + key ) then
						haved_vec[ start_pai + key ] = true
					end
				end

				local replace_index = 2
				local is_success = true
				local can_replace_pai = {}
				for key = 1,4 do
					local is_break = false

					repeat
						--- 已经有了，不管了
						if haved_vec[start_pai + key] then
							break
						end
						--- 池子里面都没有这个就直接跳过了
						if not total_pai_map[start_pai + key] or total_pai_map[start_pai + key] <= 0 then
							is_break = true
							is_success = false
							break
						end
						---- 从可以替换的里面依次找
						local is_find = false
						for r_k = replace_index , #need_replace do
							---- 还回去不是炸弹
							if total_pai_map[ need_replace[r_k] ] and total_pai_map[ need_replace[r_k] ] ~= 3 then
								can_replace_pai[ #can_replace_pai + 1 ] = { new_pai = start_pai + key , replace_pai = need_replace[r_k] }
								is_find = true
								replace_index = r_k + 1
								break
							end
						end

						if not is_find then
							is_success = false
						end

					until true

					if is_break then
						break
					end
				end

				if is_success then
					is_adjust = true
					--dump(danpai_vec , "8888888888-------------danpai_vec")
					--dump(can_replace_pai , "8888888888-------------can_replace_pai")
					--	dump(total_pai_map , "8888888888-------------total_pai_map")
					--	dump(shoupai_map , "8888888888-------------shoupai_map")

					for key,data in pairs(can_replace_pai) do
						if total_pai_map[data.new_pai] and total_pai_map[data.new_pai] > 0 and total_pai_map[data.replace_pai] ~= 3 
							and shoupai_map[data.replace_pai] and shoupai_map[data.replace_pai] > 0 then
								
							print("----------------- replace_pai:",data.replace_pai)
							print("----------------- new_pai:",data.new_pai)

							shoupai_map[data.replace_pai] = shoupai_map[data.replace_pai] - 1
							total_pai_map[data.replace_pai] = total_pai_map[data.replace_pai] + 1

							shoupai_map[data.new_pai] = (shoupai_map[data.new_pai] or 0) + 1
							total_pai_map[data.new_pai] = total_pai_map[data.new_pai] - 1

							---- 
							local cond_vec = {}
							for _key,_data in pairs(danpai_vec) do 
								if _data.start_pai ~= data.replace_pai then
									cond_vec[#cond_vec + 1] = basefunc.deepcopy(_data)
									--table.remove(danpai_vec , key)
								end
							end
							danpai_vec = cond_vec

						end
					end


				end

			end

			if is_adjust then
				break
			end

		end
	end
end

function C.adjust_sanzhang( shoupai_map , danpai_vec , total_pai_map )
	if #danpai_vec >= 3 then
		for key = 1 , math.floor( #danpai_vec / 3 ) do

			for i = 1 , 3 do
				local danpai_1 = danpai_vec[i].start_pai
				local danpai_2 = danpai_vec[ (i)%3 + 1 ].start_pai
				local danpai_3 = danpai_vec[ (i+1)%3 + 1 ].start_pai

				---- 如果一个单牌可升级& 另外两个 还回去之后不是炸弹
				if total_pai_map[danpai_1] >=2 and total_pai_map[ danpai_2 ] ~= 3 and total_pai_map[ danpai_3 ] ~= 3 then
					shoupai_map[ danpai_1 ] = shoupai_map[ danpai_1 ] + 2
					total_pai_map[ danpai_1 ] = total_pai_map[ danpai_1 ] - 2

					shoupai_map[ danpai_2 ] = shoupai_map[ danpai_2 ] - 1
					total_pai_map[ danpai_2 ] = total_pai_map[ danpai_2 ] + 1

					shoupai_map[ danpai_3 ] = shoupai_map[ danpai_3 ] - 1
					total_pai_map[ danpai_3 ] = total_pai_map[ danpai_3 ] + 1

					table.remove(danpai_vec , 1)
					table.remove(danpai_vec , 1)
					table.remove(danpai_vec , 1)
					break
				end

			end

		end
	end
end

function C.adjust_duizi(shoupai_map , danpai_vec , total_pai_map )
	if #danpai_vec >= 2 then
		for key = 1 , math.floor( #danpai_vec / 2 ) do

			for i = 1 , 2 do
				local danpai_1 = danpai_vec[i].start_pai
				local danpai_2 = danpai_vec[ (i)%2 + 1 ].start_pai

				---- 如果一个单牌可升级& 另外 1 个 还回去之后不是炸弹
				if total_pai_map[danpai_1] >=1 and total_pai_map[ danpai_2 ] ~= 3 then
					shoupai_map[ danpai_1 ] = shoupai_map[ danpai_1 ] + 1
					total_pai_map[ danpai_1 ] = total_pai_map[ danpai_1 ] - 1

					shoupai_map[ danpai_2 ] = shoupai_map[ danpai_2 ] - 1
					total_pai_map[ danpai_2 ] = total_pai_map[ danpai_2 ] + 1

					table.remove(danpai_vec , 1)
					table.remove(danpai_vec , 1)
					break
				end

			end

		end
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------
------ 创建一个牌类型的1个占牌
--- 返回 是否不需要再创建
function C.create_one_biggest_for_pai_type( total_pai_map , laji_pai_map , shoupai_map , pai_style )
	if not PAI_TYPE_GET_FUNC[pai_style] then
		dump(PAI_TYPE_GET_FUNC , "--------------- PAI_TYPE_GET_FUNC")
		error("----error ---- no PAI_TYPE_GET_FUNC for pai_style " , pai_style)
		return false
	end
	
	--dump(total_pai_map , string.format("-^-^-^-^-^--total_pai_map: %s" , pai_style))
	--dump(laji_pai_map , string.format("-^-^-^-^-^-- laji_pai_map: %s", pai_style) )
	--dump(shoupai_map , string.format("-^-^-^-^-^-- shoupai_map: %s", pai_style) )

	--- 垃圾牌中的牌型
	local lj_vec = PAI_TYPE_GET_FUNC[pai_style]( laji_pai_map )
	table.sort(lj_vec , function(a,b)
		return a.start_pai < b.start_pai
	end)
	--- 好牌的牌型
	local haopai_vec = PAI_TYPE_GET_FUNC[pai_style]( shoupai_map )
	table.sort(haopai_vec , function(a,b)
		return a.start_pai < b.start_pai
	end)

	if #lj_vec <=0 then
		return
	end

	--- 被针对的数据
	local target_lj_data = lj_vec[#lj_vec]


	if #haopai_vec > 0 and haopai_vec[#haopai_vec].len >= target_lj_data.len and
		haopai_vec[#haopai_vec].start_pai > target_lj_data.start_pai then
		return true
	end

	--- 
	local total_vec = PAI_TYPE_GET_FUNC[pai_style]( total_pai_map )
	table.sort(total_vec , function(a,b)
		return a.start_pai > b.start_pai
	end)

	----- 手牌个数限制
	local now_sp_num = C.get_sp_map_num(shoupai_map)
	local remain_num = C.shoupai_num - now_sp_num

	--dump(lj_vec , string.format("--------------create_one_biggest_for_pai_type --- lj_vec , %s" , pai_style) )
	--dump(haopai_vec , string.format("--------------create_one_biggest_for_pai_type --- haopai_vec , %s", pai_style) )
	--dump(total_vec , string.format("--------------create_one_biggest_for_pai_type --- total_vec , %s", pai_style) )
	--print("^^^^^^^ create_one_biggest_for_pai_type - now_sp_num:",pai_style,now_sp_num)
	--print("^^^^^^^ create_one_biggest_for_pai_type - remain_num:",pai_style,remain_num)

	if remain_num < target_lj_data.len * PAI_TYPE_FACTOR[pai_style] then
		return true
	end

	---- 从牌池中找一个大的
	for key,data in ipairs(total_vec) do
		local is_create = false
		if data.len >= target_lj_data.len and data.end_pai >= target_lj_data.end_pai then
			is_create = true

			--- 随机一下，也找大的，但不一定找最大的
			local min_rand = math.min( data.end_pai - target_lj_data.end_pai , data.len - target_lj_data.len )
			local target_end_pai = data.end_pai - ( math.random( min_rand + 1 ) - 1 )

			for i=1,target_lj_data.len do
				local target_pai_type = target_end_pai - (i - 1)

				shoupai_map[ target_pai_type ] = (shoupai_map[ target_pai_type ] or 0) + PAI_TYPE_FACTOR[pai_style]
				total_pai_map[ target_pai_type ] = total_pai_map[ target_pai_type ] - PAI_TYPE_FACTOR[pai_style]
				
			end
		end

		if is_create then
			return true
		end
	end

	return false
end


------ 随机创建一个类型的大牌
function C.create_one_biggest_rand_pai_type(total_pai_map , laji_pai_map , shoupai_map , pai_style)
	local total_vec = PAI_TYPE_GET_FUNC[pai_style]( total_pai_map )
	table.sort(total_vec , function(a,b)
		return a.start_pai > b.start_pai
	end)

	--local target_len =  PAI_TYPE_BASE_LEN[pai_style] 

	local cond_vec = {}
	for key,data in pairs(total_vec) do
		if data.len >= PAI_TYPE_BASE_LEN[pai_style] then
			cond_vec[#cond_vec + 1] = basefunc.deepcopy( data )
		end
	end
	total_vec = cond_vec

	--dump(laji_pai_map , string.format("-^-^-^-^-^--laji_pai_map: %s" , pai_style) )
	--dump(total_vec , string.format("-^-^-^-^-^--total_vec: %s" , pai_style))
	----- 手牌个数限制
	local now_sp_num = C.get_sp_map_num(shoupai_map)
	local remain_num = C.shoupai_num - now_sp_num
	--print("--------now_sp_num:",pai_style,now_sp_num)
	--print("--------remain_num:",pai_style,remain_num)
	if remain_num < PAI_TYPE_BASE_LEN[pai_style] * PAI_TYPE_FACTOR[pai_style] then
		return true
	end

	---- 如果没有创建，则按随机选一个大的。
	local random = math.random() * 100
	if random < HAO_PAI_TYPE_GAILV[pai_style] then
		if total_vec and #total_vec > 0 then
			for i=1,PAI_TYPE_BASE_LEN[pai_style] do

				shoupai_map[ total_vec[1].start_pai + i - 1 ] = (shoupai_map[ total_vec[1].start_pai + i - 1 ] or 0) + PAI_TYPE_FACTOR[pai_style]
				total_pai_map[ total_vec[1].start_pai + i - 1 ] = total_pai_map[ total_vec[1].start_pai + i - 1 ] - PAI_TYPE_FACTOR[pai_style]
			
				--dump(total_pai_map , string.format("-------create_one_biggest_rand_pai_type ------------ %s" , pai_style) )
			end

		end
	end
end

-----
---------- 创建 相同牌型 对应的个数 的牌
function C.create_all_biggest_for_pai_type(total_pai_map , laji_pai_map , shoupai_map , pai_style)
	if not PAI_TYPE_GET_FUNC[pai_style] then
		dump(PAI_TYPE_GET_FUNC , "--------------- PAI_TYPE_GET_FUNC")
		error("----error ---- no PAI_TYPE_GET_FUNC for pai_style " , pai_style)
		return false
	end

	--- 垃圾牌中的牌型
	local lj_vec = PAI_TYPE_GET_FUNC[pai_style]( laji_pai_map )
	table.sort(lj_vec , function(a,b)
		return a.start_pai < b.start_pai
	end)

	--- 好牌的牌型
	local haopai_vec = PAI_TYPE_GET_FUNC[pai_style]( shoupai_map )
	table.sort(haopai_vec , function(a,b)
		return a.start_pai < b.start_pai
	end)

	if #lj_vec <=0 then
		return
	end

	local target_num = #lj_vec

	---- 找到已经大于的个数
	local have_bigger_num = 0
	if #haopai_vec > 0 then
		local deal_index = 1
		for hao_key,hao_data in ipairs(haopai_vec) do
			for i = deal_index,#lj_vec do
				if hao_data.start_pai > lj_vec[i].start_pai then
					have_bigger_num = have_bigger_num + 1
					deal_index = i + 1
					break
				end
			end
		end
	end

	target_num = target_num - have_bigger_num
	if target_num > 0 then
		local total_vec = PAI_TYPE_GET_FUNC[pai_style]( total_pai_map )
		table.sort(total_vec , function(a,b)
			return a.start_pai > b.start_pai
		end)

		----- 手牌个数限制
		local now_sp_num = C.get_sp_map_num(shoupai_map)
		local remain_num = C.shoupai_num - now_sp_num

		if remain_num < target_num * PAI_TYPE_FACTOR[pai_style] then
			target_num = math.floor(remain_num / PAI_TYPE_FACTOR[pai_style])
		end

		target_num = math.min( target_num , #total_vec )

		for i = 1, target_num do
			shoupai_map[ total_vec[i].start_pai ] = (shoupai_map[ total_vec[i].start_pai ] or 0) + PAI_TYPE_FACTOR[pai_style]
			total_pai_map[ total_vec[i].start_pai ] = total_pai_map[ total_vec[i].start_pai ] - PAI_TYPE_FACTOR[pai_style]

		end

	end

end

---- 从大到小 创建一个类型的牌
function C:create_fix_biggest_for_pai_type(total_pai_map , laji_pai_map , shoupai_map , pai_style)
	if not PAI_TYPE_GET_FUNC[pai_style] then
		dump(PAI_TYPE_GET_FUNC , "--------------- PAI_TYPE_GET_FUNC")
		error("----error ---- no PAI_TYPE_GET_FUNC for pai_style " , pai_style)
		return false
	end

	--- 垃圾牌中的牌型
	local lj_vec = PAI_TYPE_GET_FUNC[pai_style]( laji_pai_map )
	table.sort(lj_vec , function(a,b)
		return a.start_pai < b.start_pai
	end)

	--- 好牌的牌型
	local haopai_vec = PAI_TYPE_GET_FUNC[pai_style]( shoupai_map )
	table.sort(haopai_vec , function(a,b)
		return a.start_pai < b.start_pai
	end)

	local total_vec = PAI_TYPE_GET_FUNC[pai_style]( total_pai_map )
	table.sort(total_vec , function(a,b)
		return a.start_pai > b.start_pai
	end)


	local target_num = C.shoupai_num

	----- 手牌个数限制
	local now_sp_num = C.get_sp_map_num(shoupai_map)
	local remain_num = C.shoupai_num - now_sp_num

	if remain_num < target_num * PAI_TYPE_FACTOR[pai_style] then
		target_num = math.floor(remain_num / PAI_TYPE_FACTOR[pai_style])
	end

	target_num = math.min( target_num , #total_vec )
	--print("----------------------create_fix_biggest_for_pai_type---target_num,",target_num)
	--dump(total_pai_map , "--------------------create_fix_biggest_for_pai_type-----total_pai_map")
	if target_num > 0 then
		
		for i = 1, target_num do
			shoupai_map[ total_vec[i].start_pai ] = (shoupai_map[ total_vec[i].start_pai ] or 0) + PAI_TYPE_FACTOR[pai_style]
			total_pai_map[ total_vec[i].start_pai ] = total_pai_map[ total_vec[i].start_pai ] - PAI_TYPE_FACTOR[pai_style]

		end

	end

end


return C