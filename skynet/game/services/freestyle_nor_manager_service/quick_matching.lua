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

--随机匹配的玩家最小阀值 可以配置
local free_match_player_min_num_default = 15
local free_match_player_min_num = free_match_player_min_num_default
--匹配的玩家最小阀值的适配游戏的玩家数量
local match_player_fixed_num = 0

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



--[[托管池
	为了保证匹配的总人数不能少于一个阀值
]]
local tuoguan_pool = {}
--池里的人数量
local tuoguan_pool_size = 0

-- 正在请求的托管玩家数量
local req_tuoguan_player_num = 0
-- 请求超时 可以请求托管玩家的时间 - 防止托管进来失败而又无法请求新的托管
local req_tuoguan_overtime = 0


-- 托管刷新时间间隔 会 进行 随机浮动
local tuoguan_update_interval_defult = 4
local tuoguan_update_time = 0

-- 随机浮动值 正负
local tuoguan_update_interval_random_defult = 1

-- 托管匹配消耗的数量
local tuoguan_use_count = 0


-- 最后一次匹配成功的时间 (能够匹配但是没匹配成功,主要是托管不足造成的)
local matching_ok_time = 0

-- 匹配超时 进行强制自由匹配的阀值时间
local matching_over_time_force_matching_time = 2


--[[匹配池
	准备了的人在里面 - 没有在桌子上的普通玩家
]]
local matching_pool = {}
--池里的人数量
local matching_pool_size = 0

--[[--绑定池
	具有绑定关系的池
]]
local binding_pool = {}
--绑定池的大小
local binding_pool_size = 0
--绑定池的玩家数
local binding_pool_player_size = 0

local matching_interval = 0.5
local matching_time = 0

--准备后进入池中的时间
local ready_in_matching_cd = 5

local ready_update_interval = 1
local ready_update_time = 0

local print_time = 0
local function dump_test(_tag)

	if binding_pool_player_size < 1 and matching_pool_size<1 and table_num<1 then
		return
	end

	if print_time < os.time() then
		print_time = os.time() + 5
	else
		return
	end

	print("\n\n\n\n===================================//////////====================="..DATA.my_id)
	print(_tag or "")
	dump(binding_pool,"binding_pool "..binding_pool_size.."|"..binding_pool_player_size)
	dump(matching_pool,"matching_pool "..matching_pool_size)
	dump(table_infos,"table_infos "..table_num)

	dump(tuoguan_pool,"tuoguan_pool "..tuoguan_pool_size)

	print(DATA.my_id.."===================================//////////=====================\n\n\n\n")

end

local function calculate_match_num()
	
	free_match_player_min_num = skynet.getcfg_2number(
					"tuoguan_freestyle_game_free_match_player_min_num_"..DATA.game_config.game_id
					,free_match_player_min_num_default)

	if free_match_player_min_num > 0 then
		-- 凑整
		local mpn = free_match_player_min_num%DATA.game_seat_num
		if mpn > 0 then
			match_player_fixed_num = DATA.game_seat_num - mpn + free_match_player_min_num
		else
			match_player_fixed_num = free_match_player_min_num
		end
	end

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


-- 请求托管来帮忙
local function req_tuoguan_player(_n)

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
		}

		skynet.send(DATA.service_config.tuoguan_service,"lua","assign_tuoguan_player",_n,_game_info)

	end

	-- 如果还有托管在来的路上 先不动
	if req_tuoguan_player_num > 0 then

		-- 时间都到了 托管还没来完 就不管没来的了 重置
		if os.time() > req_tuoguan_overtime then
			print("req_tuoguan_player overtime!!!")
		else
			return
		end

	end

	print("req_tuoguan_player---> ".._n)

	req_tuoguan_player_num = _n
	req_tuoguan_overtime = os.time() + math.min((_n*2),5)
	
	req_tuoguan(req_tuoguan_player_num)
	
	-- for i=1,req_tuoguan_player_num do

	-- 	local t = math.random(1,100)
	-- 	skynet.timeout(t,function ()
	-- 		req_tuoguan(1)
	-- 	end)

	-- end

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

		print("quick matching join_table(addr,tab,seat,pid):",skynet.self(),_table_id,_seat_num,_player_id)

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
		nodefunc.send(palyer_id,"player_leave_msg", player_info.seat_num)
	end

	--桌子上清除玩家信息
	table_info.player_info[player_info.seat_num]=nil
	table_info.player_num=table_info.player_num-1

	--桌子没人了，销毁
	if table_info.player_num < 1 then
		table_infos[player_info.table_id] = nil
		table_num = table_num - 1
	end

	--绑定池处理
	local bp = binding_pool[player_info.table_id]
	if bp then

		if bp.player_info[player_info.seat_num] then
			bp.player_info[player_info.seat_num]=nil
			bp.player_num=bp.player_num-1
			binding_pool_player_size=binding_pool_player_size-1
			if bp.player_num < 1 then
				binding_pool[player_info.table_id]=nil
				binding_pool_size=binding_pool_size-1
			end
		end

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


--一个桌子的人打完了
function PROTECTED.table_finish(_table_id)

	local tif = table_infos[_table_id]
	if tif then
		tif.status = nil
	end

end



-- 玩家退出了
function PROTECTED.player_exit_game(_player_id)

	print("player_exit_game----->".._player_id)

	local player_info = DATA.all_player_info[_player_id]

	if player_info.status=="gaming" then
		return {result=1002}
	end

	player_exit_table(_player_id)


	if tuoguan_pool[_player_id] then
		tuoguan_pool[_player_id] = nil
		tuoguan_pool_size = tuoguan_pool_size - 1
	end

	--匹配池处理
	if matching_pool[_player_id] then
		matching_pool[_player_id] = nil
		matching_pool_size = matching_pool_size - 1
	end

	return {result=0}
end


--[[报名
]]
function PROTECTED.player_signup(_player_id)
	
	print("player_signup----->".._player_id)

	local pif = DATA.all_player_info[_player_id]

	--报名进行自动准备
	pif.status="ready"
	pif.ready = 1

	--入池
	if pif.is_robot then
		tuoguan_pool[_player_id]=_player_id
		tuoguan_pool_size = tuoguan_pool_size + 1
		req_tuoguan_player_num = req_tuoguan_player_num - 1
	else
		matching_pool[_player_id]=_player_id
		matching_pool_size = matching_pool_size + 1	
	end

	return DATA.player_signup_result_cache
end


function PROTECTED.ready(_my_id)

	print("ready----->".._my_id)

	---- 记录状态
	local player_info = DATA.all_player_info[_my_id]

	-- 如果已经准备了或者匹配了
	if player_info.status == "ready" 
		or player_info.status == "matching" 
		or player_info.status == "gaming" then
			return {result=1002}
	end

	player_info.status = "ready"
	player_info.ready = 1
	player_info.ready_in_matching_time = os.time() + ready_in_matching_cd

	--通知其他人 我准备了
	if player_info.table_id and table_infos[player_info.table_id] and table_infos[player_info.table_id].player_info then
		for k,p_id in pairs( table_infos[player_info.table_id].player_info ) do
			nodefunc.send(p_id,"fg_ready_msg",player_info.seat_num)
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

	if all_ready then

		--检测是否开始
		if table_infos[player_info.table_id].player_num >= DATA.game_seat_num then

			for k,p_id in pairs( table_infos[player_info.table_id].player_info ) do
				DATA.all_player_info[p_id].status = "gaming"
				DATA.all_player_info[p_id].ready_in_matching_time = nil
			end

			table_infos[player_info.table_id].status = "gaming"
			PUBLIC.distribution_players(table_infos[player_info.table_id].player_info)

			--绑定的池清除

			local bp = binding_pool[player_info.table_id]
			if bp then
				binding_pool_player_size = binding_pool_player_size - bp.player_num
				binding_pool_size = binding_pool_size - 1
				binding_pool[player_info.table_id] = nil
			end

		else

			--桌子上人不齐 如果都准备了 就不需要倒计时了 全部直接入池找人匹配
			for k,p_id in pairs( table_infos[player_info.table_id].player_info ) do
				if DATA.all_player_info[p_id].ready_in_matching_time then
					DATA.all_player_info[p_id].ready_in_matching_time = 0
				end
			end

		end

	end


	return {result=0}
end


function PROTECTED.cancel_ready(_my_id)
	---- 记录状态
	--[[local playerInfo = DATA.all_player_info[_my_id]
	playerInfo.status = DATA.PlayerStatus.waiting

	--通知其他人 我取消准备了
	for k,palyerId in pairs(  table_infos[playerInfo.table_id].player_info ) do
		if palyerId ~= _my_id then
			nodefunc.send(palyerId,"fg_ready_msg",k)
		end
	end--]]

	return {result=1002}
end


--[[ 报名
--]]
function PROTECTED.huanzhuo(_my_id)

	print("huanzhuo----->".._my_id)

	local player_info = DATA.all_player_info[_my_id]
	local table_info = table_infos[player_info.table_id]

	-- 已经在匹配了
	if player_info.status == "matching" then
		return {result=0}
	end

	if not table_info or table_info.status=="gaming" then
		-- 玩家的状态也不可以退出
		if player_info.status ~= "can_exit_game" then
			return {result=1002}
		end
	end

	player_exit_table(_my_id)

	--换桌先自动准备 避免未开始比赛
	player_info.ready = 1
	player_info.table_id = nil
	player_info.seat_num = nil
	player_info.ready_in_matching_time = nil
	player_info.status = "matching"


	if player_info.is_robot then
		--nil
	else

		matching_pool[_my_id]=_my_id
		matching_pool_size = matching_pool_size + 1

	end

	return {result=0}
end

-- 匹配中的人数
function PUBLIC.get_cur_count()

	local num = matching_pool_size + binding_pool_player_size

	return num

end


--[[随机从池中取一个玩家
	托管池和匹配池随机
--]]
local function get_random_player_from_pool()

	calculate_match_num()

	if matching_pool_size+tuoguan_pool_size < 1 then
		return
	end

	-- 池中的玩家不够多 需要托管 托管如果运气不好先被用完了，那就用真人
	if matching_pool_size<free_match_player_min_num 
		and tuoguan_pool_size>0 
		and (tuoguan_use_count>0 or matching_pool_size<1) then

		--随机计算玩家匹配托管情况
		local r = math.random(1,free_match_player_min_num)

		-- 产生托管
		if r > matching_pool_size then

			r = math.random(1,tuoguan_pool_size)

			for player_id,_ in pairs(tuoguan_pool) do
				r = r - 1
				if r < 1 then
					tuoguan_pool[player_id] = nil
					tuoguan_pool_size = tuoguan_pool_size - 1
					tuoguan_use_count = tuoguan_use_count - 1
					return player_id
				end
			end

		end

	end

	-- 产生一个真实玩家
	local r = math.min(matching_pool_size,20)
	r = math.random(1,r)

	for player_id,_ in pairs(matching_pool) do
		r = r - 1
		if r < 1 then
			matching_pool[player_id] = nil
			matching_pool_size = matching_pool_size - 1
			return player_id
		end
	end

end

--[[匹配
	将匹配池中的玩家进行匹配 考虑绑定的优先匹配关系
]]
local function matching_update(dt)
	
	calculate_match_num()

	matching_time = matching_time + dt
	if matching_time > matching_interval*100 then
		matching_time = 0

		--dump_test("quick_matching ....... ")

		-- 正式玩家 不够凑一桌 不计入托管没来超时
		if matching_pool_size + binding_pool_player_size < DATA.game_seat_num then
			matching_ok_time = os.time()
		end

		local force_free_matching = false
		-- 一直没有匹配成功 可以直接进行强制自由匹配
		if os.time() - matching_ok_time > matching_over_time_force_matching_time then
			force_free_matching = true
			matching_ok_time = os.time()
		end

		-- 托管加一个真人够匹配 就开始 - 需要托管帮忙的模式
		-- 或者玩家数量足够多 直接开
		if (force_free_matching or free_match_player_min_num > 0) and 
			((tuoguan_pool_size+1 >= DATA.game_seat_num and (binding_pool_player_size+matching_pool_size>0))
				or (matching_pool_size >= free_match_player_min_num)
				or (matching_pool_size+tuoguan_pool_size >= free_match_player_min_num)) then

			local bn = (binding_pool_size*DATA.game_seat_num)-binding_pool_player_size

			-- 如果绑定池缺的人扣除后 玩家的数量 大于阀值 就不要托管了
			if matching_pool_size-bn>=free_match_player_min_num then
				tuoguan_use_count = 0
			else
				-- 不够的话 绑定池的时候随便使用
				tuoguan_use_count = 999999
			end

			--优先对绑定的池进行匹配-找人凑
			if (binding_pool_player_size>0)
				and ((matching_pool_size+tuoguan_pool_size+binding_pool_player_size)>=DATA.game_seat_num) then

				for t_id,bp in pairs(binding_pool) do

					if bp.player_num + matching_pool_size + tuoguan_pool_size >= DATA.game_seat_num then

						local all_is_robot = true

						for seat_num,p_id in pairs(bp.player_info) do
							local pif = DATA.all_player_info[p_id]
							if not pif.is_robot then
								all_is_robot = false
								break
							end
						end


						if not all_is_robot or (all_is_robot and matching_pool_size > 0) then

							local ps = {}
							-- 桌子上都是托管了，必须至少要来个真人
							if all_is_robot then

								local rp = next(matching_pool)
								matching_pool[rp] = nil
								matching_pool_size = matching_pool_size - 1

								for i=1,DATA.game_seat_num do
									local player_id = bp.player_info[i]
									if player_id then
										ps[player_id]=player_id
									else
										if rp then
											ps[rp]=rp
											rp = nil
										else
											player_id = get_random_player_from_pool()
											ps[player_id]=player_id
										end
									end
								end

							else

								for i=1,DATA.game_seat_num do
									local player_id = bp.player_info[i] or get_random_player_from_pool()
									ps[player_id]=player_id
								end

							end

							player_join_table(ps)
							binding_pool_size = binding_pool_size - 1
							binding_pool_player_size = binding_pool_player_size-bp.player_num
							binding_pool[t_id] = nil

						end


					end

					--不够了，跳出
					if (binding_pool_player_size<1)
						or(matching_pool_size+tuoguan_pool_size+binding_pool_player_size)<DATA.game_seat_num then

						break
					end

				end

			end

			-- 计算托管应该使用的数量 - 匹配池的时候限定
			tuoguan_use_count = match_player_fixed_num - matching_pool_size

			--单独对池中的人进行匹配
			while (matching_pool_size>0) and matching_pool_size+tuoguan_pool_size>=DATA.game_seat_num do

				local ps = {}

				local p = next(matching_pool)
				matching_pool[p] = nil
				matching_pool_size = matching_pool_size - 1
				ps[p]=p

				for i=2,DATA.game_seat_num do
					local player_id = get_random_player_from_pool()
					ps[player_id]=player_id
				end
				player_join_table(ps)

			end

			matching_ok_time = os.time()

		end

		-- 无托管自由匹配
		if free_match_player_min_num < 1 or force_free_matching then

			--至少有一个游戏需要的人数才开始
			if matching_pool_size + binding_pool_player_size >= DATA.game_seat_num then

				--优先对绑定的池进行匹配-匹配池找人凑
				for t_id,bp in pairs(binding_pool) do

					if bp.player_num + matching_pool_size >= DATA.game_seat_num then

						local all_is_robot = true
						for seat_num,p_id in pairs(bp.player_info) do
							local pif = DATA.all_player_info[p_id]
							if not pif.is_robot then
								all_is_robot = false
								break
							end
						end

						if not all_is_robot or (all_is_robot and matching_pool_size > 0) then

							local ps = {}
							-- 桌子上都是托管了，必须至少要来个真人
							if all_is_robot then

								local rp = next(matching_pool)
								matching_pool[rp] = nil
								matching_pool_size = matching_pool_size - 1

								for i=1,DATA.game_seat_num do
									local player_id = bp.player_info[i]
									if player_id then
										ps[player_id]=player_id
									else
										if rp then
											ps[rp]=rp
											rp = nil
										else
											player_id = get_random_player_from_pool()
											ps[player_id]=player_id
										end
									end
								end

							else

								for i=1,DATA.game_seat_num do
									local player_id = bp.player_info[i] or get_random_player_from_pool()
									ps[player_id]=player_id
								end

							end

							player_join_table(ps)
							binding_pool_size = binding_pool_size - 1
							binding_pool_player_size = binding_pool_player_size-bp.player_num
							binding_pool[t_id] = nil

						end

					end

					--所有桌都不够了，跳出
					if binding_pool_player_size + matching_pool_size < DATA.game_seat_num then
						break
					end

				end

				--单独对池中的人进行匹配
				if matching_pool_size >= DATA.game_seat_num then

					while matching_pool_size >= DATA.game_seat_num do

						--匹配池还有剩余
						local ps = {}
						local p = next(matching_pool)
						matching_pool[p] = nil
						matching_pool_size = matching_pool_size - 1
						ps[p]=p

						for i=2,DATA.game_seat_num do
							local player_id = get_random_player_from_pool()
							ps[player_id]=player_id
						end
						player_join_table(ps)

					end

				elseif binding_pool_player_size >= DATA.game_seat_num then

					local real_player_num = 0

					local robot_tb = {}
					local rt_size = 0
					local rp_size = 0

					local has_real_player_tb = {}
					local hrpt_size = 0
					local hrpp_size = 0

					for t_id,bp in pairs(binding_pool) do

						local all_is_robot = true
						for seat_num,p_id in pairs(bp.player_info) do

							local pif = DATA.all_player_info[p_id]
							if not pif.is_robot then
								real_player_num = real_player_num + 1
								all_is_robot = false
							end

						end

						if all_is_robot then
							robot_tb[t_id] = t_id
							rt_size = rt_size + 1
							rp_size = rp_size + bp.player_num
						else
							has_real_player_tb[t_id] = t_id
							hrpt_size = hrpt_size + 1
							hrpp_size = hrpp_size + bp.player_num
						end

					end

					-- 尽量让有真人的桌子进行匹配,纯托管桌只用来凑数
					while true do

						-- 真人桌用完了
						if hrpt_size < 1 then
							break
						end

						-- 凑桌的人不够了
						if binding_pool_player_size < DATA.game_seat_num then
							break
						end

						-- 拿一组出来
						local ps = {}
						local pn = 0

						local pt_id = next(has_real_player_tb)
						local p_bp = binding_pool[pt_id]

						for seat_num,p_id in pairs(p_bp.player_info) do
							ps[p_id]=p_id
						end
						pn = pn + p_bp.player_num

						binding_pool[pt_id] = nil
						binding_pool_size = binding_pool_size - 1
						binding_pool_player_size = binding_pool_player_size - p_bp.player_num

						has_real_player_tb[pt_id] = nil
						hrpt_size = hrpt_size - 1
						hrpp_size = hrpp_size - p_bp.player_num

						-- 真人桌够凑
						if hrpt_size > 0 then

							for t_id,v in pairs(has_real_player_tb) do

								local bp = binding_pool[t_id]

								for seat_num,p_id in pairs(bp.player_info) do

									if pn < DATA.game_seat_num then

										ps[p_id]=p_id
										bp.player_num = bp.player_num - 1
										bp.player_info[seat_num] = nil
										binding_pool_player_size = binding_pool_player_size - 1

										pn = pn + 1
										
										hrpp_size = hrpp_size - 1

									end

									if pn >= DATA.game_seat_num then 
										break
									end

								end

								if bp.player_num < 1 then
									binding_pool[t_id] = nil
									binding_pool_size = binding_pool_size - 1

									has_real_player_tb[t_id] = nil
									hrpt_size = hrpt_size - 1
								else
									-- 重新划分
									local all_is_robot = true
									for seat_num,p_id in pairs(bp.player_info) do

										local pif = DATA.all_player_info[p_id]
										if not pif.is_robot then
											all_is_robot = false
										end

									end

									if all_is_robot then
										robot_tb[t_id] = t_id
										rt_size = rt_size + 1
										rp_size = rp_size + bp.player_num

										has_real_player_tb[t_id] = nil
										hrpt_size = hrpt_size - 1
										hrpp_size = hrpp_size - p_bp.player_num
									end
								end

								if pn >= DATA.game_seat_num then 
									break
								end

							end

						end

						-- 还是不够 托管来凑
						if pn < DATA.game_seat_num then 

							for t_id,v in pairs(robot_tb) do

								local bp = binding_pool[t_id]

								for seat_num,p_id in pairs(bp.player_info) do

									if pn < DATA.game_seat_num then

										ps[p_id]=p_id
										bp.player_num = bp.player_num - 1
										bp.player_info[seat_num] = nil
										binding_pool_player_size = binding_pool_player_size - 1

										pn = pn + 1
										
										rp_size = rp_size - 1

									end

									if pn >= DATA.game_seat_num then 
										break
									end

								end

								if bp.player_num < 1 then
									binding_pool[t_id] = nil
									binding_pool_size = binding_pool_size - 1

									robot_tb[t_id] = nil
									rt_size = rt_size - 1
								end

								if pn >= DATA.game_seat_num then 
									break
								end

							end

						end

						if pn >= DATA.game_seat_num then 
							player_join_table(ps)
						end

					end

				end

				-- 绑定池的人和匹配池的人数还够一桌的
				-- 此时是单个桌子+匹配池的人不够一桌并且匹配池和绑定池单独也不够一桌
				-- 那么所有桌的人取出来+匹配池的人一定够一桌 有且仅有一桌
				if (matching_pool_size > 0) 
					and matching_pool_size + binding_pool_player_size >= DATA.game_seat_num then

					local ps = {}
					local pn = 0
					for p,v in pairs(matching_pool) do
						
						matching_pool[p] = nil
						matching_pool_size = matching_pool_size - 1

						ps[p]=p
						pn = pn + 1
					end

					for t_id,bp in pairs(binding_pool) do

						if pn < DATA.game_seat_num then

							for seat_num,p_id in pairs(bp.player_info) do

								ps[p_id]=p_id

								bp.player_num = bp.player_num - 1
								bp.player_info[seat_num] = nil
								binding_pool_player_size = binding_pool_player_size - 1

								pn = pn + 1
								if pn >= DATA.game_seat_num then
									break
								end
							end

							if bp.player_num < 1 then
								binding_pool_size = binding_pool_size - 1
								binding_pool[t_id] = nil
							end

							if pn >= DATA.game_seat_num then
								break
							end 

						end

					end

					player_join_table(ps)

				end

			end
			
		end

		--dump_test("quick_finish ....... ")

	end

	--dump_test()

end


--[[准备后的ready检测
	准备后一段时间没开始比赛，进入匹配池
]]
local function ready_update(dt)

	if ready_update_time < os.time() then
		ready_update_time = os.time() + ready_update_interval

		for p_id,p_info in pairs(DATA.all_player_info) do
			if p_info.ready_in_matching_time and os.time()>p_info.ready_in_matching_time then

				--入池
				binding_pool_player_size = binding_pool_player_size + 1
				if not binding_pool[p_info.table_id] then
					binding_pool[p_info.table_id] = {player_info={},player_num=0}
					binding_pool_size = binding_pool_size + 1
				end
				local bp = binding_pool[p_info.table_id]
				bp.player_info[p_info.seat_num] = p_id
				bp.player_num = bp.player_num + 1

				p_info.ready_in_matching_time = nil

			end
		end

	end

end


--[[托管的更新检测
]]
local function tuoguan_update(dt)

	calculate_match_num()

	if free_match_player_min_num < 1 then
		return
	end


	if os.time() > tuoguan_update_time then
		
		local tuoguan_update_interval = skynet.getcfg_2number(
											"freestyle_game_tuoguan_update_interval_"..DATA.game_config.game_id
											,tuoguan_update_interval_defult
											)

		local tuoguan_update_interval_random = skynet.getcfg_2number(
											"tuoguan_update_interval_random_"..DATA.game_config.game_id
											,tuoguan_update_interval_random_defult
											)

		local r = math.random(-tuoguan_update_interval_random,tuoguan_update_interval_random)

		tuoguan_update_time = os.time() + tuoguan_update_interval + r

		local num = 0
		-- 保持 匹配池的玩家和托管池的人 始终够凑整
		if matching_pool_size > 0 and matching_pool_size < free_match_player_min_num then

			local n = (DATA.game_seat_num-1) * matching_pool_size

			n = math.min(n,match_player_fixed_num-matching_pool_size)

			num = num + n
			-- print("+1++++++++: ",n,matching_pool_size)
		elseif matching_pool_size >= free_match_player_min_num then
			local n = matching_pool_size%DATA.game_seat_num
			
			if n > 0 then
				num = num + DATA.game_seat_num - n
			end
			-- print("+2++++++++: ",DATA.game_seat_num - n,matching_pool_size)
		end

		-- 绑定池进行检查 缺的人数
		if binding_pool_player_size > 0 then
			local bn = (binding_pool_size*DATA.game_seat_num)-binding_pool_player_size
			num = num + bn
			-- print("+3++++++++: ",bn,binding_pool_size,binding_pool_player_size)
		end
		
		-- print("++4++++: ",num,tuoguan_pool_size)
		num = num - tuoguan_pool_size

		req_tuoguan_player(num)

	end

end


function PROTECTED.update(dt)
	matching_update(dt)
	ready_update(dt)
	tuoguan_update(dt)
end


function PROTECTED.init()

	calculate_match_num()

	matching_ok_time = os.time()

end


return PROTECTED
