--[[
	--报名就入桌
	--支持换桌功能
	--支持准备
--]]

local skynet = require "skynet_plus"
local base=require "base"
local nodefunc = require "nodefunc"
require "normal_enum"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA
local PROTECTED = {}

--[[table_id=>
	{
		player_num=1,
		status= "gaming" | 
		player_info={
			[1]=nil,
			[2]=nil,
			[3]=0132456,
		}
		
	}
]]
local table_infos = {}
--桌子总数
local table_num = 0


--[[匹配池
	准备了的人在里面 - 没有在桌子上的普通玩家
]]
local player_pool = {}
--池里的人数量
local player_pool_size = 0

local tuoguan_pool = {}
--池里的人数量
local tuoguan_pool_size = 0

local matching_interval = 0.5
local matching_time = 0

-- 正在请求的托管玩家数量
local req_tuoguan_player_num = 0
-- 请求超时 可以请求托管玩家的时间 - 防止托管进来失败而又无法请求新的托管
local req_tuoguan_overtime = 0

local print_time = 0
local function dump_test()

	if player_pool_size < 1 and tuoguan_pool_size<1 and table_num<1 then
		return
	end

	if print_time < os.time() then
		print_time = os.time() + 5
	else
		return
	end

	print("\n\n\n\n===================================//////////====================="..DATA.my_id)
	dump(player_pool,"player_pool "..player_pool_size)
	dump(tuoguan_pool,"tuoguan_pool "..tuoguan_pool_size)
	dump(table_infos,"table_infos "..table_num)
	print(DATA.my_id.."===================================//////////=====================\n\n\n\n")

end



local statistic_table_id_count = 0
local function gen_table_id()
	statistic_table_id_count = statistic_table_id_count + 1
	return statistic_table_id_count
end

local function create_new_table()

	local index = gen_table_id()

	table_infos[index]={
		player_num=0,
		player_info={}
	}

	table_num = table_num + 1

	return index
end

function PROTECTED.init()

end



--把一组玩家加入桌子进行比赛
local function player_join_table(_player_hash)

	--创建一个新桌子
	local _table_id = create_new_table()

	for _player_id,_ in pairs(_player_hash) do
		
		local p_info = DATA.all_player_info[_player_id]
		if p_info.table_id and table_infos[p_info.table_id] then
			local t_info = table_infos[p_info.table_id]

			for _seat_num,_p_id in pairs(t_info.player_info) do

				-- 通知其他的人 我离开了
				if not _player_hash[_p_id] then
					nodefunc.send(_p_id,"player_leave_msg", p_info.seat_num )
				end

			end

			t_info.player_info[p_info.seat_num]=nil
			t_info.player_num = t_info.player_num - 1

			--桌子没人了，销毁
			if t_info.player_num < 1 then
				table_infos[p_info.table_id] = nil
				table_num = table_num - 1
			end

		end

		local tpi = table_infos[_table_id].player_info
		local tpn = table_infos[_table_id].player_num
		p_info.table_id = _table_id
		local _seat_num = #tpi+1
		tpi[_seat_num] = _player_id
		p_info.seat_num = _seat_num
		table_infos[_table_id].player_num = tpn + 1

		p_info.status = "gaming"

	end

	table_infos[_table_id].status = "gaming"
	
	PUBLIC.distribution_players(table_infos[_table_id].player_info)

end

--玩家离开桌子
local function player_exit_table(_player_id)
	
	local player_info = DATA.all_player_info[_player_id]
	local table_info = table_infos[player_info.table_id]

	if not table_info then
		return
	end

	--通知当前桌的其他人 我离开了
	for k,palyer_id in pairs(table_info.player_info) do
		if palyer_id ~= _player_id then
			nodefunc.send(palyer_id,"player_leave_msg", player_info.seat_num )
		end
	end

	--桌子上清除玩家信息
	table_info.player_info[player_info.seat_num]=nil
	table_info.player_num=table_info.player_num-1

	--桌子没人了，销毁
	if table_info.player_num < 1 then
		table_infos[player_info.table_id] = nil
		table_num = table_num - 1
	end

end

local players_info_table = {}
local function get_players_info(_table_id)
	
	local _t_d = table_infos[_table_id]

	for k,v in pairs(players_info_table) do
		players_info_table[k]=nil
	end

	for _seat_num,_player_id in pairs(_t_d.player_info) do

		local p_info = DATA.all_player_info[_player_id]
		players_info_table[_seat_num]=
		{
			id=_player_id,
			name=p_info.name,
			head_link=p_info.head_link,
			sex=p_info.sex,
			score=p_info.score,
			seat_num=_seat_num,
			ready=p_info.ready,
		}
	end

	return players_info_table
end

-- 请求托管来帮忙
local function request_tuoguan_player(_n)

	if _n < 1 then
		return
	end

	local function req_tuoguan(_n)

		local _game_info = 
		{
			game_id = DATA.game_config.game_id,
			game_type = DATA.game_config.game_type,
			service_id = DATA.my_id,
			match_name = "freestyle_game",
			game_tag = "xsyd",
		}

		skynet.send(DATA.service_config.tuoguan_service,"lua","assign_tuoguan_player",_n,_game_info)

	end

	-- 如果还有托管在来的路上 先不动
	if req_tuoguan_player_num > 0 then

		-- 时间都到了 托管还没来完 就不管没来的了 重置
		if os.time() > req_tuoguan_overtime then
			req_tuoguan_player_num = 0
			req_tuoguan_overtime = 0
		end

		return
	end

	print("req_tuoguan_player---> ".._n)

	req_tuoguan_player_num = _n
	req_tuoguan_overtime = os.time() + _n * 2

	for i=1,req_tuoguan_player_num do

		local t = math.random(1,100)
		skynet.timeout(t,function ()
			req_tuoguan(1)
		end)

	end

end


--一个桌子的人打完了
function PROTECTED.table_finish(_table_id)

	local tif = table_infos[_table_id]
	if tif then
		tif.status = nil
	end

end



-- 玩家退出了
function PROTECTED.player_exit_game(_player_id)

	local player_info = DATA.all_player_info[_player_id]

	if player_info.status=="gaming" then
		return {result=1002}
	end

	player_exit_table(_player_id)

	if player_pool[_player_id] then
		player_pool[_player_id] = nil
		player_pool_size = player_pool_size - 1
	end

	if tuoguan_pool[_player_id] then
		tuoguan_pool[_player_id] = nil
		tuoguan_pool_size = tuoguan_pool_size - 1
	end

	DATA.all_player_info[_player_id]=nil

	return {result=0}
end


--[[报名
]]
function PROTECTED.player_signup(_player_id)
	
	local pd = DATA.all_player_info[_player_id]

	--报名进行自动准备
	pd.status="ready"
	pd.ready = 1

	--入池
	if pd.is_robot then

		tuoguan_pool[_player_id] = _player_id
		tuoguan_pool_size = tuoguan_pool_size + 1

		req_tuoguan_player_num = req_tuoguan_player_num - 1
		
	else

		player_pool[_player_id] = _player_id
		player_pool_size = player_pool_size + 1

	end

	return DATA.player_signup_result_cache
end


function PROTECTED.ready(_player_id)

	---- 记录状态
	local player_info = DATA.all_player_info[_player_id]
	player_info.status = "ready"
	player_info.ready = 1

	--通知其他人 我准备了
	if player_info.table_id and table_infos[player_info.table_id] and table_infos[player_info.table_id].player_info then
		for k,p_id in pairs( table_infos[player_info.table_id].player_info ) do
			if p_id ~= _my_id then
				nodefunc.send(p_id,"fg_ready_msg",player_info.seat_num)
			end
		end
	end

	--是否都准备了
	local all_ready = true
	for k,p_id in pairs( table_infos[player_info.table_id].player_info ) do
		if DATA.all_player_info[p_id].ready ~= 1 then
			all_ready = false
			break
		end
	end

	--检测是否开始
	if table_infos[player_info.table_id].player_num >= DATA.game_seat_num then
		
		if all_ready then

			for k,p_id in pairs( table_infos[player_info.table_id].player_info ) do
				DATA.all_player_info[p_id].status = "gaming"
			end

			table_infos[player_info.table_id].status = "gaming"
			PUBLIC.distribution_players(table_infos[player_info.table_id].player_info)

		end

	end

	return {result=0}
end


function PROTECTED.cancel_ready(_player_id)

	return {result=0}
end


--[[换桌
--]]
function PROTECTED.huanzhuo(_player_id)

	local player_info = DATA.all_player_info[_player_id]
	local table_info = table_infos[player_info.table_id]

	if not table_info or table_info.status=="gaming" then
		return {result=1002}
	end

	player_exit_table(_player_id)

	--换桌先自动准备 避免未开始比赛
	player_info.ready = 1
	player_info.table_id = nil
	player_info.seat_num = nil
	player_info.status = "ready"

	--入池
	if player_info.is_robot then

		tuoguan_pool[_player_id] = _player_id
		tuoguan_pool_size = tuoguan_pool_size + 1

	else

		player_pool[_player_id] = _player_id
		player_pool_size = player_pool_size + 1

	end

	return {result=0}
end


--随机从匹配池中取一个玩家
local function get_random_player_from_tuoguan_pool()

	if tuoguan_pool_size < 1 then
		return
	end

	local sz = math.min(tuoguan_pool_size,5)
	local r = math.random(1,sz)
	for player_id,_ in pairs(tuoguan_pool) do
		r = r - 1
		if r < 1 then
			tuoguan_pool[player_id] = nil
			tuoguan_pool_size = tuoguan_pool_size - 1
			return player_id
		end
	end

end

--[[匹配
	将匹配池中的玩家进行匹配 考虑绑定的优先匹配关系
]]
local function matching_update(dt)


	matching_time = matching_time + dt
	if matching_time > matching_interval*100 then
		matching_time = 0

		local need_tuoguan_num = 0

		--至少有一个游戏需要的人数才开始
		if player_pool_size > 0 and tuoguan_pool_size + 1 >= DATA.game_seat_num then
			
			--托管 和 玩家 池中匹配
			for p_id,bp in pairs(player_pool) do
				
				-- 托管人还足够
				if tuoguan_pool_size + 1 >= DATA.game_seat_num then

					local ps = {}
					ps[p_id]=p_id

					player_pool_size = player_pool_size - 1
					player_pool[p_id] = nil


					for i=2,DATA.game_seat_num do
						local player_id = get_random_player_from_tuoguan_pool()
						ps[player_id]=player_id
					end

					player_join_table(ps)

				else
					break
				end

			end

		end

		-- 桌子上准备了的托管玩家 找人匹配
		for ti,td in pairs(table_infos) do

			local tn = DATA.game_seat_num - td.player_num
			if tn == 1 and player_pool_size > 0 then

				local ps = {}
				local ok = true
				for i=1,DATA.game_seat_num do
					local pi = td.player_info[i]
					if pi then
						if DATA.all_player_info[pi].is_robot then
							ps[pi]=pi
						else
							ok = false
						end
					end
				end

				if ok then
					
					local p_id = next(player_pool)

					player_pool_size = player_pool_size - 1
					player_pool[p_id] = nil

					ps[p_id]=p_id

					player_join_table(ps)

				end

			end

		end

		need_tuoguan_num = need_tuoguan_num + player_pool_size*(DATA.game_seat_num-1)


		need_tuoguan_num = need_tuoguan_num - tuoguan_pool_size

		request_tuoguan_player(need_tuoguan_num)

	end
	
	--dump_test()

end


function PROTECTED.update(dt)
	matching_update(dt)

end

return PROTECTED

