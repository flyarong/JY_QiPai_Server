---- 对外查询接口



local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local skynet = require "skynet_plus"
require "normal_enum"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECT = {}


function PROTECT.check_is_can_query()
	if DATA.now_query_num < DATA.query_num_limit then
		return true
	else
		return false
	end
end

--- 获得玩家邀请的son的main数据  
function CMD.get_player_all_son_data(player_id)

	if not DATA.player_all_son_data[player_id] then
		if not PROTECT.check_is_can_query() then
			return 1008
		end

		DATA.now_query_num = DATA.now_query_num + 1
		PUBLIC.load_player_all_son_data(player_id)
		DATA.now_query_num = DATA.now_query_num - 1

	end

	if not DATA.player_all_son_data[player_id] then
		return 1004
	end

	return DATA.player_all_son_data[player_id] 
end

--- 获取一个玩家的基本信息
function CMD.get_base_info(player_id)
	if not DATA.player_details[player_id] or not DATA.player_details[player_id].base_info then
		PUBLIC.load_base_info(player_id)
	end

	if not DATA.player_details[player_id] or not DATA.player_details[player_id].base_info then
		return 1004
	end

	return DATA.player_details[player_id].base_info
end

--- 获得我的收入明细
function CMD.get_my_income_details(player_id)
	if not DATA.player_details[player_id] or not DATA.player_details[player_id].my_income_details then
		if not PROTECT.check_is_can_query() then
			return 1008
		end

		DATA.now_query_num = DATA.now_query_num + 1
		PUBLIC.load_income_details(player_id)
		DATA.now_query_num = DATA.now_query_num - 1
	end

	if not DATA.player_details[player_id] or not DATA.player_details[player_id].my_income_details then
		return 1004
	end

	return DATA.player_details[player_id].my_income_details
end
--- 获得我的提现明细
function CMD.get_my_spending_details(player_id)
	if not DATA.player_details[player_id] or not DATA.player_details[player_id].my_spending_details then
		if not PROTECT.check_is_can_query() then
			return 1008
		end

		DATA.now_query_num = DATA.now_query_num + 1
		PUBLIC.load_spending_details(player_id)
		DATA.now_query_num = DATA.now_query_num - 1
	end

	if not DATA.player_details[player_id] or not DATA.player_details[player_id].my_spending_details then
		return 1004
	end

	return DATA.player_details[player_id].my_spending_details

end

--- 获得我的某个son的基本贡献详情
function CMD.get_son_details(player_id)
	if not DATA.player_details[player_id] or not DATA.player_details[player_id].my_deatails_info_for_parent then
		PUBLIC.load_my_deatails_info_for_parent( player_id )
	end

	if not DATA.player_details[player_id] or not DATA.player_details[player_id].my_deatails_info_for_parent then
		return 1004
	end

	return DATA.player_details[player_id].my_deatails_info_for_parent
end
--- 获得我的某个son的具体贡献详情
function CMD.get_son_contribute_details(player_id)
	if not DATA.player_details[player_id] or not DATA.player_details[player_id].my_contribute_details_for_parent then
		if not PROTECT.check_is_can_query() then
			return 1008
		end

		DATA.now_query_num = DATA.now_query_num + 1
		PUBLIC.load_my_contribute_details_for_parent( player_id )
		DATA.now_query_num = DATA.now_query_num - 1
	end
	if not DATA.player_details[player_id] or not DATA.player_details[player_id].my_contribute_details_for_parent then
		return 1004
	end
	return DATA.player_details[player_id].my_contribute_details_for_parent
end

--- 获得 生财之道的 cash 奖励
--[[function CMD.get_sczd_cash(player_id , cash_value)
	if PUBLIC.get_action_lock( "get_sczd_cash" , player_id ) then
		return 1008
	end
	PUBLIC.on_action_lock( "get_sczd_cash" , player_id )


	--- 加缓存
	PUBLIC.add_spending_details(player_id,{
		spending_value = cash_value,
		spending_time = os.time()
	})


	PUBLIC.off_action_lock( "get_sczd_cash" , player_id )
end--]]


--查询我的上级高级合伙人
function CMD.query_frist_gjhhr(player_id,is_include_self)
	--包含自己
	if is_include_self==1 then
		return PUBLIC.query_frist_gjhhr(player_id)
	else
		return PUBLIC.query_frist_gjhhr(DATA.player_relation[player_id].parent_id)
	end
end
--查询我的上级高级合伙人
function CMD.query_frist_gjhhr_by_group(player_id_map,is_include_self)

	for k,v in pairs(player_id_map) do
		--包含自己
		if is_include_self==1 then
			player_id_map[k]=PUBLIC.query_frist_gjhhr(player_id)
		elseif DATA.player_relation[player_id] then
			player_id_map[k]=PUBLIC.query_frist_gjhhr(DATA.player_relation[player_id].parent_id)
		end
	end
	return player_id_map
end
--查询我的上级高级合伙人 和自己的parent 
function CMD.query_frist_gjhhr_and_parent_by_group(player_id_map,is_include_self)

	for k,v in pairs(player_id_map) do
		--print("xxxxxxxxxxxxxxxxx query_frist_gjhhr_and_parent_by_group:",k,basefunc.tostring(v))
		--包含自己
		if is_include_self==1 then
			player_id_map[k]={parent_gjhhr=PUBLIC.query_frist_gjhhr(k),parent=DATA.player_relation[k].parent_id}
		else
			player_id_map[k]={parent_gjhhr=PUBLIC.query_frist_gjhhr(DATA.player_relation[k].parent_id),parent=DATA.player_relation[k].parent_id}
		end
	end
	return player_id_map
end
function CMD.query_all_parents(player_id)
	if player_id and DATA.player_relation[player_id] then

		local parents={}
		local p_id
		if DATA.player_relation[player_id] then
			p_id=DATA.player_relation[player_id].parent_id
		end
		while p_id and DATA.player_relation[p_id] do
			parents[#parents+1]=p_id
			p_id=DATA.player_relation[p_id].parent_id
		end
		return parents[1] and parents or nil
	end
	return nil
end


function CMD.query_tgy_son_count(player_id_map)
	if player_id_map then
		for id,v in pairs(player_id_map) do
			player_id_map[id]=DATA.player_relation[id].son_count
		end
		return player_id_map
	end
	return nil
end


----- 给telnet 调用，
--- 获取当前的缓存数量
function CMD.get_sczc_cache_data_num()
	local cache_num = 0
	for key,data in pairs(DATA.player_details) do
		cache_num = cache_num + 1
	end
	return cache_num
end
function CMD.get_all_relation_data()
	local data={}
	for id,_ in pairs(DATA.player_relation) do
		data[id]=true
	end
	return data
end

return PROTECT




