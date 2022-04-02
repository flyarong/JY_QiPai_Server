---- add by wss 2019/5/29
--- 麻将 发好牌

local basefunc=require"basefunc"

local MJ_FA_HAO_PAI = {}
local C = MJ_FA_HAO_PAI

local PAI_TYPE = {
	danpai = "danpai",
	duizi = "duizi",
	liandui = "liandui",
	sanzhang = "sanzhang",
	shunzi = "shunzi",
}

local PAI_TYPE_FACTOR = {
	danpai = 1,
	duizi = 2,
	liandui = 2,
	sanzhang = 3,
	shunzi = 1,
}

---- 默认手牌数量
C.shoupai_num = 13

function C.get_pai_pool_map()
	return {
		[11] = 4,
		[12] = 4,
		[13] = 4,
		[14] = 4,
		[15] = 4,
		[16] = 4,
		[17] = 4,
		[18] = 4,
		[19] = 4,
		[21] = 4,
		[22] = 4,
		[23] = 4,
		[24] = 4,
		[25] = 4,
		[26] = 4,
		[27] = 4,
		[28] = 4,
		[29] = 4,
		[31] = 4,
		[32] = 4,
		[33] = 4,
		[34] = 4,
		[35] = 4,
		[36] = 4,
		[37] = 4,
		[38] = 4,
		[39] = 4,
	}
end

function C.get_er_pai_pool_map()
	return {
		[11] = 4,
		[12] = 4,
		[13] = 4,
		[14] = 4,
		[15] = 4,
		[16] = 4,
		[17] = 4,
		[18] = 4,
		[19] = 4,
		[21] = 4,
		[22] = 4,
		[23] = 4,
		[24] = 4,
		[25] = 4,
		[26] = 4,
		[27] = 4,
		[28] = 4,
		[29] = 4,
	}
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

---- 获得一个目标值通过概率类型
function C.get_target_value_by_gailv_type(min , max , gailv_type )
	if gailv_type == GAILV_TYPE.random then
		return math.random( min , max )
	elseif gailv_type == GAILV_TYPE.fix_all then
		return C.shoupai_num
	end
	return C.shoupai_num
end


--------------------------------------------------------------------↓↓↓↓↓------------ 获得一个pai_map中的所有的牌类型 --------↓↓↓↓↓-------------------------------------------

function C.get_danpai_vec(pai_map)
	local vec = {}

	--- 先找到顺子
	local shunzi_vec = C.get_shunzi_vec(pai_map)

	for key = 11 , 39 do
		if pai_map[key] and pai_map[key] == 1 then
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

	for key = 11 , 39 do
		if pai_map[key] and pai_map[key] == 2 then
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
	for key = 11 , 39 do
		if not deal_vec[key] and dui_hash[key] then
			deal_vec[key] = true

			local start_pos = key
			local end_pos = key
			for i = key+1,key+10 do
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
	local shunzi_empty_node = { [1] = {empty_node = 10} , [2] = {empty_node = 20} , [3] = {empty_node = 30} , [4] = {empty_node = 40} }

	for key = 11,39 do
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



------ 处理每个配置项的创建
function C.deal_pai_type_cfg_item(total_pai_map , data , shoupai_map )
	-- 当前手牌个数
	local now_sp_num = C.get_sp_map_num(shoupai_map)
	-- 
	if now_sp_num >= C.shoupai_num then
		return
	end
	--- 目标个数
	local target_num = C.get_target_value_by_gailv_type(data.min_num , data.max_num , data.gailv_type )

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
	end

	----- 加到手牌中
	for pai_type , pai_num in pairs(get_pai_map) do
		shoupai_map[pai_type] = (shoupai_map[pai_type] or 0) + pai_num
	end

end


-------- 根据配置，发指定类型的牌
function C.create_type_pai( total_pai_map , fapai_config , shoupai_num )
	local orig_
	local shoupai_map = {}

	C.shoupai_num = shoupai_num
	
	for key,data in ipairs(fapai_config) do
		C.deal_pai_type_cfg_item( total_pai_map , data , shoupai_map )
	end

	--- 用单牌补上。
	local now_sp_num = C.get_sp_map_num(shoupai_map)
	if now_sp_num < C.shoupai_num then
		local data = { pai_type = PAI_TYPE.danpai  , min_num = 0, max_num = 0 , min_pai = 3 , max_pai = 17, gailv_type = GAILV_TYPE.fix_all }
		C.deal_pai_type_cfg_item( total_pai_map , data , shoupai_map )
	end

	---- 判断一下
	if C.get_sp_map_num(shoupai_map) ~= C.shoupai_num then
		error( "------------------- create_lj_pai - shoupai num not right !!" )
	end

	for pai_type , num in pairs(shoupai_map) do
		if num > 4 then
			error( string.format("--------------shoupai_num one > 4 !!!! %d" , pai_type) )
		end
	end

	----- 最后验证一下


	return shoupai_map
end




return C