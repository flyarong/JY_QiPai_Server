--- 砸金蛋  房间数据
local skynet = require "skynet_plus"
local base=require "base"
local basefunc = require "basefunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local loadstring = rawget(_G, "loadstring") or load

-- 锤子id
DATA.hammer_enum = {
	wood = 1,
	iron = 2,
	silver = 3,
	gold = 4,
}

-- 
DATA.hammer_map = {
	[1] = "wood",
	[2] = "iron",
	[3] = "silver",
	[4] = "gold",
}

DATA.hammer_num_map = {
	[1] = "wood_hammer_num",
	[2] = "iron_hammer_num",
	[3] = "silver_hammer_num",
	[4] = "gold_hammer_num",
}

DATA.egg_award_type = {
	normal = 0,                                  -- 普通
	open_all = 1,                                -- 一网打尽
	sky_girl_cast_flower = 2,                    -- 天女散花
	big_hammer = 3,                              -- 大锤子
	free = 4,                                    -- 免费
	cs_mode=5,
}

--- 总共的蛋的数量
DATA.total_eggs_num = 12
--- 真实计算概率的蛋的数量
DATA.real_rate_eggs_num = 6
--- 自动切换一批蛋的数量
--DATA.auto_replace_eggs_num = 6

----- 一个房间的桌子数量
DATA.one_room_table_num = 60 --100

---- 限制升级蛋的最大倍数
DATA.limit_upgrade_max_bei = 40

---- 排行榜显示的个数
DATA.rank_show_num = 10
--- 排行榜缓存数据，重置时间
DATA.rank_cache_data_timeout = 3600
DATA.rank_cache_time = nil
--- 排行榜数据
DATA.rank_data = nil

--- 每个蛋最多砸多少下
DATA.max_egg_open_num = 5

-----  某人的砸蛋记录最多显示的条数
DATA.max_zjd_show_num = 1000

--- 显示的空蛋范围
DATA.show_empty_egg_range = {min = 3,max = 4}

--- 显示 金猪 范围
DATA.show_goldpig_egg_range = { min = 0 , max = 1 }

DATA.skill_sky_girl_range = { min = 3 , max = 3 }

DATA.skill_free_range = { min = 2 , max = 2 }

--- 被扣下的奖励缓存,被扣下的回扣将的id , 
DATA.kickback_award_id = nil
--- 被扣下的概率
DATA.kickback_award_rate = 50

-----------------------------------------------------------------------------------------------
DATA.award_data_map = DATA.award_data_map or {}
---- 一网打尽的全部分解方案,key = 要分解的值，value 为 table
DATA.open_all_resolve_award_cache = DATA.open_all_resolve_award_cache or {}

---- 天女散花的全部分解方案,
DATA.sky_girl_resolve_award_cache = DATA.sky_girl_resolve_award_cache or {}

---- 大锤子的全部分解方案,
DATA.big_hammer_resolve_award_cache2 = DATA.big_hammer_resolve_award_cache2 or {}
DATA.big_hammer_resolve_award_cache3 = DATA.big_hammer_resolve_award_cache3 or {}
---- 免费n次的全部分解方案,
DATA.free_resolve_award_cache = DATA.free_resolve_award_cache or {}

function PUBLIC.parse_activity_data(_data)

	local code = "return " .. _data
	local ok, ret = xpcall(function ()
		local data = loadstring(code)()
		if type(data) ~= 'table' then
			data = {}
			print("parse_activity_data error : {}")
		end
		return data
	end
	,function (err)
		print("parse_activity_data error : ".._data)
		print(err)
	end)

	if not ok then
		ret = {}
	end

	return ret or {},ok
end

--- 获得玩家数据
function PUBLIC.get_player_zjd_data(player_id)
	local data = skynet.call( DATA.service_config.data_service , "lua" , "query_one_player_zjd_data" , player_id )

	if data then
		if data.last_game_remain_eggs1 then
			data.last_game_remain_eggs1 = PUBLIC.parse_activity_data(data.last_game_remain_eggs1)
		end
		if data.last_game_remain_eggs2 then
			data.last_game_remain_eggs2 = PUBLIC.parse_activity_data(data.last_game_remain_eggs2)
		end
		if data.last_game_remain_eggs3 then
			data.last_game_remain_eggs3 = PUBLIC.parse_activity_data(data.last_game_remain_eggs3)
		end
		if data.last_game_remain_eggs4 then
			data.last_game_remain_eggs4 = PUBLIC.parse_activity_data(data.last_game_remain_eggs4)
		end
	end

	return data
end

--- 新增or更新 砸金蛋数据
function PUBLIC.add_or_update_zjd_data( player_zjd_data )
	skynet.send( DATA.service_config.data_service , "lua" , "update_or_add_player_zjd_data" 
		, player_zjd_data.player_id
		, player_zjd_data.today_get_award
		, player_zjd_data.today_id
		, player_zjd_data.today_get_biggest_award_num_1
		, player_zjd_data.today_get_biggest_award_num_2
		, player_zjd_data.today_get_biggest_award_num_3
		, player_zjd_data.today_get_biggest_award_num_4 )
end

-- 设置 今日的奖励
function PUBLIC.set_zjd_today_award(player_id , award_value)
	skynet.send( DATA.service_config.data_service , "lua" , "set_zjd_today_award" , player_id , award_value)
end

-- 设置 今日的id
function PUBLIC.set_zjd_today_id(player_id , today_id)
	skynet.send( DATA.service_config.data_service , "lua" , "set_zjd_today_id" , player_id , today_id)
end

-- 设置 今日获得的某个场最大的奖励数量
function PUBLIC.set_zjd_today_biggest_award_num(player_id , key , num)
	skynet.send( DATA.service_config.data_service , "lua" , "set_zjd_today_biggest_award_num" , player_id , key , num)
end

-- 设置 上次游戏剩余的蛋的数据
function PUBLIC.set_zjd_last_game_remain_eggs( player_id , key , data )
	skynet.send( DATA.service_config.data_service , "lua" , "set_zjd_last_game_remain_eggs" , player_id , key , basefunc.safe_serialize(data) )
	
end

-- 增加日志
function PUBLIC.add_zjd_log(player_id , round_id , hammer_id , egg_no , award_id , award_type, award_value , award_data)
	skynet.send( DATA.service_config.data_service , "lua" , "add_player_zajindan_log" , player_id ,round_id , hammer_id , egg_no , award_id , award_type, award_value , award_data)
end


function PUBLIC.get_old_real_egg( old_award_data , award_config , real_egg_num )
	--------- 拿到上一轮的没有开过的真实奖励
	local empty_egg_num = 0
	local max_egg_num = 0

	local old_real_award = {}
	if old_award_data and type(old_award_data) == "table" then
		for i = 1 , real_egg_num do
		 	local old_data = old_award_data[i]
		 	if old_data then
		 		--- 这个奖励没有开过
		 		if not old_data.is_get_award then
		 			--- 如果是普通奖，直接加进去
		 			if old_data.award_type == DATA.egg_award_type.normal then
		 				old_real_award[#old_real_award + 1] = basefunc.deepcopy( old_data ) 

		 				if old_data.id == award_config[#award_config].id then
		 					empty_egg_num = empty_egg_num + 1
		 				elseif old_data.id == award_config[1].id then
		 					max_egg_num = max_egg_num + 1
		 				end

		 				old_data.is_get_award = true
		 			else
		 				---- 找到所有的这个类型没有开的奖励组成一个同等倍率的奖励
		 				local award_type = old_data.award_type 
		 				local total_award = 0
		 				------ 如果不是大锤子类型的奖励
		 				if old_data.award_type ~= DATA.egg_award_type.big_hammer then
			 				for key,data in pairs(old_award_data) do
			 					if data.award_type == award_type and not data.is_get_award then
			 						total_award = total_award + data.award
			 						data.is_get_award = true
			 					end
			 				end
			 			else
			 				for key,data in pairs(old_award_data) do
			 					if data.award_type == award_type and not data.is_get_award then
			 						data.is_get_award = true
			 					end
			 				end

			 				total_award = old_data.award
			 			end

		 				--- 找一个这个奖励倍数的返奖
		 				local is_find = false
		 				for key,data in pairs(award_config) do
		 					if data.award == total_award then
		 						is_find = true
		 						old_real_award[#old_real_award + 1] = { 
									id = data.id
									, award = data.award 
									, name = data.name
									, is_get_award = false                                  -- 这个奖励是否已经获得了
									, award_type = DATA.egg_award_type.normal               -- 奖励类型
								}
		 						break
		 					end
		 				end

		 				

		 				if not is_find then
		 					--error( string.format("error-------------not find award for total_award:%d , %d",old_data.award_type,total_award))
		 					----- 没有找到，找一个小一档的
		 					for i=1,#award_config do
		 						local data = award_config[i]
		 						if data.award <= total_award then
		 							old_real_award[#old_real_award + 1] = { 
										id = data.id
										, award = data.award 
										, name = data.name
										, is_get_award = false                                  -- 这个奖励是否已经获得了
										, award_type = DATA.egg_award_type.normal               -- 奖励类型
									}

									--- 多余的写到缓存中
									if not DATA.kickback_award_id and total_award - data.award > 0 then
										for i=1,#award_config do
											local data = award_config[i]
		 									if data.award == total_award - data.award and data.id > 2 then
		 										DATA.kickback_award_id = data.id
		 										break
		 									end
										end
									end

									break
		 						end
		 					end
		 				end

		 				if #old_real_award == 0 then
		 					error( string.format("error-------------not find award for total_award:%d , %d",old_data.award_type,total_award))
		 				end

		 				--else
		 					if old_real_award[#old_real_award].id == award_config[#award_config].id then
			 					empty_egg_num = empty_egg_num + 1
			 				elseif old_real_award[#old_real_award].id == award_config[1].id then
			 					max_egg_num = max_egg_num + 1
			 				end
		 				--end
		 			end
		 		end
		 	end
		end
	end

	return old_real_award , empty_egg_num , max_egg_num
end

---- 升级一个蛋的奖励
function PUBLIC.upgrade_one_egg_award(hammer_id , award_data , award_config , replace_egg_money)
	if award_data.id > 1 and award_data.id < award_config[#award_config].id then
		--- 找到第一个更大奖励
		local bigger_award_id = award_data.id - 1
		local need_money = 0

		for key = #award_config ,1 ,-1 do
			local data = award_config[key]
			if key <= bigger_award_id and data.award > award_data.award then

				local need_award = award_config[key].award - award_data.award
				---- 不升级小的，
				if need_award >= math.random(6,8) then
					local _need_money = need_award * DATA.config.hammer[hammer_id].base_money
					
					if replace_egg_money * DATA.config.hammer[hammer_id].replace_egg_return_factor / 100 > _need_money then
						bigger_award_id = key
						need_money = _need_money
						break
					end
				end
				
			end
		end

		
		
		print("-------upgrade_one_egg_award:",replace_egg_money , DATA.config.hammer[hammer_id].replace_egg_return_factor , need_money)
		if need_money > 0 and replace_egg_money * DATA.config.hammer[hammer_id].replace_egg_return_factor / 100 > need_money then
			--print("return------award-----",replace_egg_money,need_money , DATA.config.hammer[hammer_id].replace_egg_return_factor / 100)
			replace_egg_money = replace_egg_money - need_money / (DATA.config.hammer[hammer_id].replace_egg_return_factor / 100)

			award_data.id = bigger_award_id
			award_data.award = award_config[bigger_award_id].award
			award_data.name = award_config[bigger_award_id].name

			return  replace_egg_money , true 
		end

	end
	return replace_egg_money , false
end

--- 升级一堆蛋里面的一个蛋的奖励
function PUBLIC.upgrade_egg_awards(hammer_id , egg_awards , replace_egg_money)
	local remain_replace_egg_money = replace_egg_money

	---- 先做一个总共的奖励倍数限制
	local now_bei = 0
	for key,data in pairs(egg_awards) do
		now_bei = now_bei + data.award
	end
	if now_bei >= DATA.limit_upgrade_max_bei then
		return replace_egg_money
	end


	local is_upgrade = false
	print("--------------------------------- upgrade_egg_awards , replace_egg_money:",replace_egg_money)
	dump( egg_awards , "------------egg_awards ---------- upgrade_egg_awards ---- before" )
	
	for key = #egg_awards ,1 , -1 do
		local data = egg_awards[key]

		remain_replace_egg_money , is_upgrade = PUBLIC.upgrade_one_egg_award(hammer_id , data , DATA.config.award , remain_replace_egg_money)
		--- 每次只升级一个
		if is_upgrade then
			dump( egg_awards , "------------egg_awards ---------- upgrade_egg_awards ---- after" )
			break
		end
	end
	print("----------- upgrade_egg_awards ---------- remain_replace_egg_money:",remain_replace_egg_money)
	return remain_replace_egg_money or 0
end


----- 获得初始 奖励数据
function PUBLIC.init_award_data(hammer_id , is_change_egg , old_award_data , replace_egg_money)
	
	assert( DATA.config.award , "init_award_data must have award config !!!" )

	local award_config = DATA.config.award

	local award_data = {}

	--dump(old_award_data , "-------------------old_award_data")
	---- 先拿到老的真实蛋
	--local old_award , empty_num , max_egg_num = {},0,0
	local old_award , empty_num , max_egg_num = PUBLIC.get_old_real_egg( old_award_data , award_config , DATA.real_rate_eggs_num )
	if #old_award > 0 then
		--dump(old_award , "---------------------xxxxx___old_award")
	end
	--- 加到新的里面
	for key,data in ipairs(old_award) do
		award_data[#award_data + 1] = basefunc.deepcopy( data )
	end

	local award_power_cfg = DATA.config[ DATA.config.hammer[hammer_id].award_power ]

	---- 如果换蛋，用另一个概率配置
	if is_change_egg and DATA.config[ DATA.config.hammer[hammer_id].award_power .. "_replace_egg" ] then
		award_power_cfg = DATA.config[ DATA.config.hammer[hammer_id].award_power .. "_replace_egg" ]
		print("-------------------wwwwwww-----------------------------init_award_data , is_change_egg true ")
	end

	--dump(award_power_cfg , string.format("------------------- award_power_cfg , hammer_id:%d ",hammer_id))

	

	--- 总共的权重值
	local total_power = 0
	local total_show_power = 0
	for key,data in pairs(award_config) do
		total_power = total_power + award_power_cfg[key].power  -- data.power
		total_show_power = total_show_power + data.show_power
	end

	---- 奖励概率
	local award_rate = {}
	local total_rate = 0

	local show_rate = {}
	local total_show_rate = 0

	for key,data in ipairs(award_config) do
		local my_rate_range = award_power_cfg[key].power / total_power * 100     -- data.power
		award_rate[#award_rate + 1] = { id = data.id , rate = total_rate + my_rate_range }
		total_rate = total_rate + my_rate_range

		local my_show_rate_range = data.show_power / total_show_power * 100
		show_rate[#show_rate + 1] = { id = data.id , rate = total_show_rate + my_show_rate_range }
		total_show_rate = total_show_rate + my_show_rate_range
	end

	--dump(award_rate , "---------------------- zajindan award_rate")
	
	local have_create_award_num = #old_award
	local empty_egg_num = empty_num
	local biggest_egg_num = max_egg_num

	--- 前 n 个真实开奖的蛋
	for i=#old_award +1 ,DATA.real_rate_eggs_num do
		local random = math.random() * 100
		for key = 1 , #award_rate do
			local is_create = false
			
			repeat

			--- 最高奖，最多有一个
			if key == 1 and biggest_egg_num == 1 then
				break
			end
			--- 如果是空蛋，默认用倒数第二个蛋
			if key == #award_rate and empty_egg_num >= 3 then
				award_data[#award_data + 1] = { 
							id = award_rate[key-1].id 
							, award = award_config[award_rate[key-1].id ].award 
							, name = award_config[award_rate[key-1].id ].name
							, is_get_award = false                                  -- 这个奖励是否已经获得了
							, award_type = DATA.egg_award_type.normal               -- 奖励类型
					}
				
				have_create_award_num = have_create_award_num + 1
				is_create = true
				break
			end
			
			if random < award_rate[key].rate or key == #award_rate then
				local award_value = award_config[award_rate[key].id].award 
				--- 做回扣
				local award_id = award_rate[key].id 
				local is_kickback_award = false
				if key ~= #award_rate and DATA.big_hammer_resolve_award_cache2[award_value] 
					and #DATA.big_hammer_resolve_award_cache2[award_value] > 0 and (not DATA.kickback_award_id or DATA.kickback_award_id == #award_rate) then

					local rand = math.random() * 100
					if rand < DATA.kickback_award_rate then
						local resolve_length = #DATA.big_hammer_resolve_award_cache2[award_value]
						local resolve_vec = DATA.big_hammer_resolve_award_cache2[award_value][math.random(resolve_length)]

						local award_vec = PUBLIC.get_real_award_data(resolve_vec)

						award_id = award_vec[1].id
						DATA.kickback_award_id = award_vec[2].id

					end
				end

				
				award_data[#award_data + 1] = { 
							id = award_id
							, award = award_config[award_id].award 
							, name = award_config[award_id].name
							, is_get_award = false                                  -- 这个奖励是否已经获得了
							, award_type = DATA.egg_award_type.normal               -- 奖励类型
					}
				
				----------------- 奖励是否可以升级 --------------------
				--PUBLIC.upgrade_one_egg_award(hammer_id , award_data[#award_data] , award_config , replace_egg_money)

				--PUBLIC.upgrade_one_egg_award(hammer_id , award_data , award_config , replace_egg_money)

				--PUBLIC.upgrade_egg_awards(hammer_id , egg_awards , replace_egg_money)

				--[[if award_data[#award_data].id > 1 and award_data[#award_data].id < award_config[#award_config].id then
					local bigger_award_id = award_data[#award_data].id - 1
					local need_award = award_config[bigger_award_id].award - award_data[#award_data].award
					local need_money = need_award * DATA.config.hammer[hammer_id].base_money

					if need_money > 0 and replace_egg_money * DATA.config.hammer[hammer_id].replace_egg_return_factor / 100 > need_money then
						--print("return------award-----",replace_egg_money,need_money , DATA.config.hammer[hammer_id].replace_egg_return_factor / 100)
						replace_egg_money = replace_egg_money - need_money / (DATA.config.hammer[hammer_id].replace_egg_return_factor / 100)

						award_data[#award_data].id = bigger_award_id
						award_data[#award_data].award = award_config[bigger_award_id].award
						award_data[#award_data].name = award_config[bigger_award_id].name
					end

				end--]]


				have_create_award_num = have_create_award_num + 1
				if award_id == award_rate[#award_rate].id then
					empty_egg_num = empty_egg_num + 1
				end
				if award_id == 1 then
					biggest_egg_num = biggest_egg_num + 1
				end

				is_create = true
				break
			end


			until true

			if is_create then
				break
			end

		end
	end

	local upgrade_random = math.random() * 100
	if upgrade_random < DATA.config.hammer[hammer_id].replace_egg_upgrade_rate then
		replace_egg_money = PUBLIC.upgrade_egg_awards(hammer_id , award_data , replace_egg_money)
	end
	
	----- 创建技能
	local function create_skill(skill_id , award_index , award_id , award_value )
		--print("--------------- create_skill:",skill_id)
		if skill_id == 1 then
			-- 一网打尽
			local resolve_award_vec = PUBLIC.get_open_all_resolve( award_value ,empty_egg_num  )
			
			if not resolve_award_vec then
				error( "canot resolve_award 1",award_value )
			end
			if #resolve_award_vec == 0 then
				return
			end

			--- 把 真实蛋的 前面的空蛋和后面的奖励蛋对换
			--[[for i=1,award_index-1 do
				if award_data[i].id == award_rate[#award_rate].id then
					for j = DATA.real_rate_eggs_num , award_index + 1 , -1 do
						if award_data[j].id ~= award_rate[#award_rate].id then
							award_data[i],award_data[j] = award_data[j],award_data[i]
						end
					end
				end
			end--]]

			--- 把后面的空蛋也算作一网打尽的蛋
			for i = award_index + 1 , DATA.real_rate_eggs_num do
				if award_data[i].id == award_rate[#award_rate].id then
					award_data[i].award_type = DATA.egg_award_type.open_all
				end
			end

			--- 把后面一个不是空蛋的，用 回扣的蛋 替换
			if DATA.kickback_award_id then
				for i = award_index + 1 , DATA.real_rate_eggs_num do
					if award_data[i].id ~= award_rate[#award_rate].id then
						
						award_data[i].id = DATA.kickback_award_id
						award_data[i].award = award_config[ DATA.kickback_award_id ].award 
						award_data[i].name = award_config[ DATA.kickback_award_id ].name 
						award_data[i].award_type = DATA.egg_award_type.open_all

						break
					end
				end

				DATA.kickback_award_id = nil
			end


			--- 砸的那个蛋变成第一个
			award_data[award_index].id = resolve_award_vec[1].id
			award_data[award_index].award = award_config[ resolve_award_vec[1].id ].award 
			award_data[award_index].name = award_config[ resolve_award_vec[1].id ].name 
			award_data[award_index].award_type = DATA.egg_award_type.open_all

			--- 创建其余的n个蛋
			for i=2,#resolve_award_vec do
				local award_id = resolve_award_vec[i].id 
				award_data[#award_data + 1] = { 
							id = award_id
							, award = award_config[award_id].award 
							, name = award_config[award_id].name
							, is_get_award = false                                    -- 这个奖励是否已经获得了
							, award_type = DATA.egg_award_type.open_all               -- 奖励类型
						}
				have_create_award_num = have_create_award_num + 1
			end

		elseif skill_id == 2 then
			--- 天女散花
			local resolve_award_vec = PUBLIC.get_sky_girl_resolve(award_value)

			if not resolve_award_vec then
				error( "canot resolve_award 2",award_value )
			end
			if #resolve_award_vec == 0 then
				return
			end

			--- 砸的那个蛋变成第一个
			award_data[award_index].id = resolve_award_vec[1].id
			award_data[award_index].award = award_config[ resolve_award_vec[1].id ].award 
			award_data[award_index].name = award_config[ resolve_award_vec[1].id ].name 
			award_data[award_index].award_type = DATA.egg_award_type.sky_girl_cast_flower

			for i=2,#resolve_award_vec do
				local award_id = resolve_award_vec[i].id 
				award_data[#award_data + 1] = { 
							id = award_id
							, award = award_config[award_id].award 
							, name = award_config[award_id].name
							, is_get_award = false                                                -- 这个奖励是否已经获得了
							, award_type = DATA.egg_award_type.sky_girl_cast_flower               -- 奖励类型
						}
				have_create_award_num = have_create_award_num + 1
			end

		elseif skill_id == 3 then
			--- 大锤子
			local resolve_award_2 = PUBLIC.get_big_hammer2_resolve( award_value , empty_egg_num)

			local resolve_award_3 = PUBLIC.get_big_hammer3_resolve( award_value , empty_egg_num )

			if #resolve_award_2 == 0 or #resolve_award_3 == 0 then
				return
			end

			award_data[award_index].award_type = DATA.egg_award_type.big_hammer

			for i=1,#resolve_award_2 do
				local award_id = resolve_award_2[i].id 
				award_data[#award_data + 1] = { 
							id = award_id
							, award = award_config[award_id].award 
							, name = award_config[award_id].name
							, is_get_award = false                                -- 这个奖励是否已经获得了
							, award_type = DATA.egg_award_type.big_hammer               -- 奖励类型
						}
				have_create_award_num = have_create_award_num + 1
			end

			for i=1,#resolve_award_3 do
				local award_id = resolve_award_3[i].id 
				award_data[#award_data + 1] = { 
							id = award_id
							, award = award_config[award_id].award 
							, name = award_config[award_id].name
							, is_get_award = false                                -- 这个奖励是否已经获得了
							, award_type = DATA.egg_award_type.big_hammer               -- 奖励类型
						}
				have_create_award_num = have_create_award_num + 1
			end

		elseif skill_id == 4 then
			--- 免费n次
			local resolve_award_vec = PUBLIC.get_free_resolve( award_value)

			if not resolve_award_vec then
				error( "canot resolve_award 4",award_value )
			end
			if #resolve_award_vec == 0 then
				return
			end

			--- 砸的那个蛋变成第一个
			award_data[award_index].id = resolve_award_vec[1].id
			award_data[award_index].award = award_config[ resolve_award_vec[1].id ].award 
			award_data[award_index].name = award_config[ resolve_award_vec[1].id ].name 
			award_data[award_index].award_type = DATA.egg_award_type.free

			for i=2,#resolve_award_vec do
				local award_id = resolve_award_vec[i].id 
				award_data[#award_data + 1] = { 
							id = award_id
							, award = award_config[award_id].award 
							, name = award_config[award_id].name
							, is_get_award = false                                -- 这个奖励是否已经获得了
							, award_type = DATA.egg_award_type.free               -- 奖励类型
						}
				have_create_award_num = have_create_award_num + 1
			end
		end
	end

	--dump( award_data , "---------------- award_data before_create_skill " )

	----- 计算技能的概率
	local is_create_skill = false
	local can_skill_vec = {}
	local max_award = 0 
	local max_award_key = 0
	local max_award_id = 0
	for key,data in ipairs(award_data) do
		if data.award > max_award then
			max_award = data.award
			max_award_key = key
			max_award_id = data.id
		end
	end

	---- 第一个技能只能是 一网打尽
	if max_award >= DATA.config.skill[1].show_condition then
		can_skill_vec[ 1 ] = can_skill_vec[ 1 ] or {}
		local data_ref = can_skill_vec[ 1 ]
		data_ref[#data_ref + 1] = { award_key = max_award_key , award_id = max_award_id , award_value = max_award , skill_key = 1 , skill_id = DATA.config.skill[1].skill_id }
	else
		for key,data in ipairs(award_data) do
			
			for skill_key,skill_data in pairs(DATA.config.skill) do
				if data.award >= skill_data.show_condition then

					can_skill_vec[ skill_key ] = can_skill_vec[ skill_key ] or {}
					local data_ref = can_skill_vec[ skill_key ]

					data_ref[#data_ref + 1] = { award_key = key , award_id = data.id , award_value = data.award , skill_key = skill_key , skill_id = skill_data.skill_id }

				end
			end
		end
	end
	---- 可以创建的技能的数量
	local can_skill_vec_num = 0
	for key,data in pairs(can_skill_vec) do
		can_skill_vec_num = can_skill_vec_num + 1
	end
	--dump(can_skill_vec ,  "------------------- can_skill_vec_num")
	---- 随机选一种技能
	if can_skill_vec_num > 0 then
		local random_skill_index = math.random( can_skill_vec_num ) 

		local random_skill_vec = nil

		local index = 0
		for key,data in pairs(can_skill_vec) do
			index = index + 1
			if index == random_skill_index then
				random_skill_vec = data
				break
			end
		end
		------ 在这种技能里面在选具体一个
		if random_skill_vec then
			local random_vec = random_skill_vec[math.random( #random_skill_vec )]
			--dump( random_vec , "----------------  random_vec" )
			local random = math.random() * 100
			--print("----------------------------- random ", random)
			if random < DATA.config.skill[ random_vec.skill_key ].show_rate then
				
				create_skill( random_vec.skill_id , random_vec.award_key , random_vec.award_id , random_vec.award_value )

				is_create_skill = true
			end
		end
	end

	
	--- 保证奖励的个数
	local function ensure_award_num( award_id , min_num , max_num )
		local target_award_num = math.random( min_num , max_num )

		--- 已经创建了这个id的蛋的数量
		local now_award_num = 0
		for key,data in ipairs(award_data) do
			if data.id == award_id then
				now_award_num = now_award_num + 1
			end
		end

		if now_award_num < target_award_num then
			local other_award_num = target_award_num - now_award_num
			local can_create_num = DATA.total_eggs_num - have_create_award_num
			can_create_num = math.min( can_create_num , other_award_num )

			for i=1,can_create_num do
				award_data[#award_data + 1] = { 
								id = award_id
								, award = award_config[award_id].award 
								, name = award_config[award_id].name
								, is_get_award = false                                  -- 这个奖励是否已经获得了
								, award_type = DATA.egg_award_type.normal               -- 奖励类型
							}

				have_create_award_num = have_create_award_num + 1
			end
		end
	end

	--- 保证空蛋，最大奖数量
	--if not is_create_skill then
		ensure_award_num( award_rate[#award_rate].id , DATA.show_empty_egg_range.min , DATA.show_empty_egg_range.max )
	--end

	ensure_award_num( award_rate[1].id , DATA.show_goldpig_egg_range.min , DATA.show_goldpig_egg_range.max )

	--- 后n个为了场面的蛋
	for i=1,DATA.total_eggs_num - have_create_award_num do
		local random = math.random() * 100

		for key = 1 , #show_rate do
			if random < show_rate[key].rate or key == #show_rate then
				award_data[#award_data + 1] = { 
								id = show_rate[key].id
								, award = award_config[show_rate[key].id].award 
								, name = award_config[show_rate[key].id].name
								, is_get_award = false                                  -- 这个奖励是否已经获得了
								, award_type = DATA.egg_award_type.normal               -- 奖励类型
							}
				have_create_award_num = have_create_award_num + 1

				break
			end
		end

	end

	if #award_data > 12 then
		dump( award_data , "error!!-----------------------#award_data > 12 " )
		--error("------------------ error , #award_data > 12")
	end

	--dump( award_data , "---------------- init_award_data " )
	return award_data , replace_egg_money
end


--- 获得开奖数据
function PUBLIC.get_award_data( _d , _hammer_id , _egg_no)
	
	local award_config = DATA.config.award

	local award_data = {}

	local game_data = _d.hammer_game_data[_hammer_id]

	--- 获得奖励类型的蛋
	local function get_skill_eggs( award_key , award_type , hit_egg_no )
		local eggs = {}
		local awards = {}
		local good_egg = {}

		--- 大锤子特殊处理
		if award_type == DATA.egg_award_type.big_hammer then
			local left_egg_index = hit_egg_no - 1
			local right_egg_index = hit_egg_no + 1
			if left_egg_index == 0 then
				left_egg_index = DATA.total_eggs_num
			end
			if right_egg_index > DATA.total_eggs_num then
				right_egg_index = 1
			end

			eggs[#eggs+1] = hit_egg_no
			local big_hammer_open_num = 1
			if game_data.eggs_status[left_egg_index] ~= -1 then
				big_hammer_open_num = big_hammer_open_num + 1
				eggs[#eggs+1] = left_egg_index
			end
			if game_data.eggs_status[right_egg_index] ~= -1 then
				big_hammer_open_num = big_hammer_open_num + 1
				eggs[#eggs+1] = right_egg_index
			end

			game_data.award_data[award_key].is_get_award = true

			----- 奖励数据
			if big_hammer_open_num == 1 then
				awards[#awards + 1] =  {award_index = award_key , award_id = game_data.award_data[award_key].id }
			elseif big_hammer_open_num == 2 then
				awards[#awards + 1] = {award_index = DATA.real_rate_eggs_num+1 , award_id = game_data.award_data[DATA.real_rate_eggs_num+1].id }
				awards[#awards + 1] = {award_index = DATA.real_rate_eggs_num+2 , award_id = game_data.award_data[DATA.real_rate_eggs_num+2].id }
			elseif big_hammer_open_num == 3 then
				awards[#awards + 1] = {award_index = DATA.real_rate_eggs_num+3 , award_id = game_data.award_data[DATA.real_rate_eggs_num+3].id }
				awards[#awards + 1] = {award_index = DATA.real_rate_eggs_num+4 , award_id = game_data.award_data[DATA.real_rate_eggs_num+4].id }
				awards[#awards + 1] = {award_index = DATA.real_rate_eggs_num+5 , award_id = game_data.award_data[DATA.real_rate_eggs_num+5].id }
			end

			assert( #eggs == #awards , "-------------- #eggs must == #awards ")

			return eggs , awards
		end

		for key,egg_data in ipairs(game_data.eggs_status) do
			if egg_data ~= -1 then
				good_egg[#good_egg + 1] = key
			end
		end
		--- 有多少个这种类型的奖励
		local award_num = 0
		for key,data in ipairs(game_data.award_data) do
			if not data.is_get_award and data.award_type == award_type then
				award_num = award_num + 1
				awards[#awards + 1] = {award_index = key , award_id = data.id }
			end
		end

		assert( #good_egg >= award_num , " get_skill_eggs , good_egg num must >= award_num  " )

		---- 自己砸的蛋要爆 ,
		local start_index = 1
		if award_type == DATA.egg_award_type.free or award_type == DATA.egg_award_type.open_all then
			eggs[#eggs+1] = hit_egg_no
			start_index = start_index + 1
			for key,egg_no in ipairs(good_egg) do
				if egg_no == hit_egg_no then
					table.remove( good_egg , key )
					break
				end
			end
		end

		for i=start_index ,award_num do
			local random_index = math.random(#good_egg)
			eggs[#eggs + 1] = good_egg[random_index]
			table.remove( good_egg , random_index )
		end

		assert( #eggs == #awards , "-------------- #eggs must == #awards ")
		return eggs,awards
	end


	--- 找到第一个没有开奖的
	for key,data in ipairs(game_data.award_data) do
		if not data.is_get_award then
			local award_type = data.award_type
			--- 总共获得的奖励
			local total_award = 0
			
			--- 不是普通奖，找所有的同种类型的奖励
			if award_type ~= DATA.egg_award_type.normal then
				
				local opened_eggs , awards = get_skill_eggs( key , award_type , _egg_no )
				dump(game_data.award_data , "----------------------get_award_data, game_data.award_data:")
				dump(opened_eggs , "----------------------get_award_data, opened_eggs:")
				dump(awards , "----------------------get_award_data, awards:")

				local award_str = ""
				
				for _key,egg_id in ipairs(opened_eggs) do
					local award_index = awards[_key].award_index     --- 12个奖励的对应的索引
					local award_id = awards[_key].award_id           --- 对应的奖励的id
					local _award_money = award_config[award_id].award  * game_data.base_money
					award_str = award_str .. tostring(game_data.award_data[award_index].award) .. ","
					total_award = total_award + _award_money
					award_data[#award_data+1] = { egg_no = egg_id , award = award_id , award_value = award_config[award_id].award , award_money = _award_money }

					game_data.award_data[award_index].is_get_award = true
					game_data.opened_egg_num = game_data.opened_egg_num + 1
				end
				--- 加log
				PUBLIC.add_zjd_log( _d.player_id , game_data.round_id , _hammer_id, _egg_no , data.id , award_type , total_award , award_str)
			else
				local _award_money = data.award * game_data.base_money
				total_award = total_award + _award_money
				award_data[#award_data+1] = { egg_no = _egg_no , award = data.id , award_value = data.award, award_money = _award_money }

				data.is_get_award = true
				game_data.opened_egg_num = game_data.opened_egg_num + 1

				local award_str = ""
				award_str = award_str .. tostring(data.award)
				--- 加log
				PUBLIC.add_zjd_log( _d.player_id , game_data.round_id , _hammer_id , _egg_no , data.id , award_type , total_award , award_str)
			
				--- 砸出了大蛋往外发一下
				if data.id == 1 and award_type == DATA.egg_award_type.normal then
					---- 次数增加
					local target_key = "today_get_biggest_award_num_".._hammer_id

					----- 因为活动期间每个人只能领一次，所以每日不刷新
					--[[local now_today_id = PUBLIC.get_today_id()
					if now_today_id ~= _d.today_id then
						_d[target_key] = 0
						_d.today_id = now_today_id
						PUBLIC.set_zjd_today_id( _d.player_id , now_today_id)
					end--]]

					_d[target_key] = _d[target_key] or 0
					_d[target_key] = _d[target_key] + 1
					PUBLIC.set_zjd_today_biggest_award_num( _d.player_id , target_key , _d[target_key] )

					--- 每次砸中都要发邮件
					if DATA.service_config.zajindan_activity_service then  --- and _d[target_key] == 1
						skynet.send(DATA.service_config.zajindan_activity_service,"lua","open_biggest_egg" , _d.player_id , _d.player_name , _hammer_id , game_data.base_money , _d[target_key])
					end
				end



			end


			--data.is_get_award = true
			--game_data.opened_egg_num = game_data.opened_egg_num + 1
			--- 开一个蛋，换蛋的钱要减少
			if game_data.opened_egg_num <= DATA.real_rate_eggs_num then
				game_data.replace_money = math.floor((1-game_data.opened_egg_num / DATA.real_rate_eggs_num) * game_data.ori_replace_money)
			else
				game_data.replace_money = 0
			end

			--award_data.status = data.award_type
			--award_data.award = data.id

			--local award_money = data.award * game_data.base_money

			--- 
			award_data.award_type = award_type
			award_data.award_money = total_award

			local now_today_id = PUBLIC.get_today_id()
			if now_today_id ~= _d.today_id then
				_d.today_get_award = 0
				_d.today_id = now_today_id
				print("---------------------- today_id",now_today_id)
				PUBLIC.set_zjd_today_id( _d.player_id , now_today_id)
			end

			_d.today_get_award = _d.today_get_award + total_award
			PUBLIC.set_zjd_today_award(_d.player_id , _d.today_get_award)

			--- 直接加 金币
			skynet.send(DATA.service_config.data_service,"lua","change_asset_and_sendMsg",
                    _d.player_id , PLAYER_ASSET_TYPES.JING_BI ,
                    total_award, ASSET_CHANGE_TYPE.EGG_GAME_AWARD , data.id )

			

			break
		end
	end

	return award_data
end

function PUBLIC.get_resolve_award(award_id ,award_value , resolve_min_num , resolve_max_num )
	local can_resolve_vec = {}

	--- 用来分解的数组,除去最后一个空奖励
	local use_to_resolve = {}
	local last_award_value = 0
	for i=award_id , #DATA.config.award do
		local now_award_value = DATA.config.award[i].award
		if now_award_value ~= last_award_value then
			last_award_value = now_award_value
			--use_to_resolve[#use_to_resolve+1] = { id = DATA.config.award[i].id ,award = DATA.config.award[i].award }

			use_to_resolve[#use_to_resolve+1] = { award = DATA.config.award[i].award }
		end
	end
	--dump( use_to_resolve , "--------------- use_to_resolve" )
	local now_resolve_num = 0
	local now_resolve_index = 0
	local now_resolve_vec = {}
	local empty_num = 0
	local function resolve_award( resolve_index )
		--print("----------resolve_award:",use_to_resolve[resolve_index] and use_to_resolve[resolve_index].award or "nil")
		if not use_to_resolve[resolve_index] then
			return true
		end
		if now_resolve_index >= resolve_max_num then
			return true
		end

		--- 最多三个空蛋
		if empty_num > 2 then
			return true
		end

		now_resolve_index = now_resolve_index + 1
		now_resolve_num = now_resolve_num + use_to_resolve[resolve_index].award
		now_resolve_vec[#now_resolve_vec + 1] = basefunc.deepcopy(use_to_resolve[resolve_index])
			
		if now_resolve_num >= award_value then
			if now_resolve_num == award_value and now_resolve_index >= resolve_min_num and now_resolve_index <= resolve_max_num then
				can_resolve_vec[#can_resolve_vec+1] = basefunc.deepcopy(now_resolve_vec)
			end

			local is_clear = false

			if now_resolve_num == award_value and now_resolve_index < resolve_min_num then
				if use_to_resolve[resolve_index].award == 0 then
					empty_num = empty_num + 1
				end
				local is_canot = resolve_award( resolve_index )
				if is_canot then
					is_clear = true
					now_resolve_index = now_resolve_index - 1
					now_resolve_num = now_resolve_num - use_to_resolve[resolve_index].award
					now_resolve_vec[#now_resolve_vec] = nil
					if use_to_resolve[resolve_index].award == 0 then
						empty_num = empty_num - 1
						return is_canot
					end
				end
				
			end
			if not is_clear then
				now_resolve_vec[#now_resolve_vec] = nil
				now_resolve_index = now_resolve_index - 1
				now_resolve_num = now_resolve_num - use_to_resolve[resolve_index].award
			end
			return resolve_award( resolve_index + 1 )
			
		else
			local is_canot = resolve_award( resolve_index )
			if is_canot then
				now_resolve_index = now_resolve_index - 1
				now_resolve_num = now_resolve_num - use_to_resolve[resolve_index].award
				now_resolve_vec[#now_resolve_vec] = nil

				
				resolve_award( resolve_index + 1 )
				
			end
			return is_canot
		end

			
	end

	resolve_award( 1 )

	--dump(can_resolve_vec , string.format("----------------------- get_resolve_award,can_resolve_vec: %d,%d,%d" ,award_value,resolve_min_num , resolve_max_num))
	--print("------------------------------------------------------------------- get_resolve_award done!! ")


	return can_resolve_vec

end

---- 分解一网打尽
function PUBLIC.resolve_open_all(award_id , award_value )
	return PUBLIC.get_resolve_award(award_id , award_value , DATA.total_eggs_num-DATA.real_rate_eggs_num+1 , DATA.total_eggs_num-DATA.real_rate_eggs_num+1 )
end

--- 分解 天女散花
function PUBLIC.resolve_sky_girl(award_id , award_value )
	return PUBLIC.get_resolve_award(award_id , award_value , DATA.skill_sky_girl_range.min , DATA.skill_sky_girl_range.max)
end

--- 分解 大锤子 2 个分解数
function PUBLIC.resolve_big_hammer2(award_id , award_value )
	return PUBLIC.get_resolve_award(award_id , award_value , 2 , 2 )
end

--- 分解 大锤子 3 个分解数
function PUBLIC.resolve_big_hammer3(award_id , award_value )
	return PUBLIC.get_resolve_award(award_id , award_value , 3 , 3 )
end

--- 分解 免费
function PUBLIC.resolve_free(award_id , award_value )
	return PUBLIC.get_resolve_award(award_id , award_value , DATA.skill_free_range.min , DATA.skill_free_range.max )
end

---------------------------------------------------------------------------------------------------------------------
function PUBLIC.get_real_award_data(resolve_award_vec)
	local award_vec = {}
	for key,data in pairs(resolve_award_vec) do
		local length = #DATA.award_data_map[data.award]
		local award_item = DATA.award_data_map[data.award][ math.random( length ) ]
		award_vec[#award_vec + 1] = { id = award_item.award_id }
	end
	return award_vec
end


--------------------- 获得一组 一网打尽 组合
function PUBLIC.get_open_all_resolve( award_value , empty_egg_num )
	assert( DATA.open_all_resolve_award_cache[award_value] , " get_open_all_resolve , must have cache data ~! " )

	local length = #DATA.open_all_resolve_award_cache[award_value]

	local resolve_award_vec = {}
	if length > 0 then
		---
		local target_vec = {}
		local target_empty_egg_num = math.random( DATA.show_empty_egg_range.min , DATA.show_empty_egg_range.max ) - empty_egg_num
		if target_empty_egg_num > 3 then
			target_empty_egg_num = 3
		end
		if target_empty_egg_num < 0 then
			target_empty_egg_num = 0
		end

		for key ,data in pairs(DATA.open_all_resolve_award_cache[award_value]) do
			local empty_num = 0
			for _key,_data in pairs(data) do
				if _data.award == 0 then
					empty_num = empty_num + 1
				end
			end
			if empty_num == target_empty_egg_num then
				target_vec[#target_vec + 1] = data
			end
		end
		--print("--------------------------------empty_egg_num,target_empty_egg_num",empty_egg_num,target_empty_egg_num)
		--dump(target_vec,"--------------------get_open_all_resolve")
		if target_vec and #target_vec > 0 then
			resolve_award_vec = target_vec[ math.random(#target_vec) ]
		else
			resolve_award_vec = DATA.open_all_resolve_award_cache[award_value][ math.random(length) ]
		end
	end
	local award_vec = PUBLIC.get_real_award_data(resolve_award_vec)

	--- 打乱一下顺序
	for i=1,#award_vec-1 do
		local target_random = math.random(i,#award_vec)
		award_vec[i],award_vec[target_random] = award_vec[target_random],award_vec[i]
	end

	return award_vec
end
--------------------- 获得一组 天女散花 组合
function PUBLIC.get_sky_girl_resolve( award_value)
	assert( DATA.sky_girl_resolve_award_cache[award_value] , " get_sky_girl_resolve , must have cache data ~! " )

	local length = #DATA.sky_girl_resolve_award_cache[award_value]

	local resolve_award_vec = {}
	if length > 0 then
		resolve_award_vec = DATA.sky_girl_resolve_award_cache[award_value][ math.random(length) ]
	end
	local award_vec = PUBLIC.get_real_award_data(resolve_award_vec)

	--- 打乱一下顺序
	for i=1,#award_vec-1 do
		local target_random = math.random(i,#award_vec)
		award_vec[i],award_vec[target_random] = award_vec[target_random],award_vec[i]
	end

	return award_vec
end

--------------------- 获得一组 大锤子2 组合
function PUBLIC.get_big_hammer2_resolve( award_value , empty_egg_num)
	assert( DATA.big_hammer_resolve_award_cache2[award_value] , " get_big_hammer2_resolve , must have cache data ~! " )

	local length = #DATA.big_hammer_resolve_award_cache2[award_value]

	local resolve_award_vec = {}
	if length > 0 then
		--resolve_award_vec = DATA.big_hammer_resolve_award_cache2[award_value][ math.random(length) ]

		local target_vec = {}
		local target_empty_egg_num = math.random( DATA.show_empty_egg_range.min , DATA.show_empty_egg_range.max ) - empty_egg_num
		if target_empty_egg_num > 1 then
			target_empty_egg_num = math.random() >= 0.5 and 1 or 0
		end
		if target_empty_egg_num < 0 then
			target_empty_egg_num = 0
		end

		for key ,data in pairs(DATA.big_hammer_resolve_award_cache2[award_value]) do
			local empty_num = 0
			for _key,_data in pairs(data) do
				if _data.award == 0 then
					empty_num = empty_num + 1
				end
			end
			if empty_num == target_empty_egg_num then
				target_vec[#target_vec + 1] = data
			end
		end
		--print("--------------------------------empty_egg_num,target_empty_egg_num",empty_egg_num,target_empty_egg_num)
		--dump(target_vec,"--------------------get_open_all_resolve")
		if target_vec and #target_vec > 0 then
			resolve_award_vec = target_vec[ math.random(#target_vec) ]
		else
			resolve_award_vec = DATA.big_hammer_resolve_award_cache2[award_value][ math.random(length) ]
		end

	end
	local award_vec = PUBLIC.get_real_award_data(resolve_award_vec)

	--- 打乱一下顺序
	for i=1,#award_vec-1 do
		local target_random = math.random(i,#award_vec)
		award_vec[i],award_vec[target_random] = award_vec[target_random],award_vec[i]
	end

	return award_vec
end
--------------------- 获得一组 大锤子3 组合
function PUBLIC.get_big_hammer3_resolve( award_value , empty_egg_num)
	assert( DATA.big_hammer_resolve_award_cache3[award_value] , " get_big_hammer3_resolve , must have cache data ~! " )

	local length = #DATA.big_hammer_resolve_award_cache3[award_value]

	local resolve_award_vec = {}
	if length > 0 then
		--resolve_award_vec = DATA.big_hammer_resolve_award_cache3[award_value][ math.random(length) ]

		local target_vec = {}
		local target_empty_egg_num = math.random( DATA.show_empty_egg_range.min , DATA.show_empty_egg_range.max ) - empty_egg_num
		if target_empty_egg_num > 1 then
			target_empty_egg_num = math.random() >= 0.5 and 1 or 0
		end
		if target_empty_egg_num < 0 then
			target_empty_egg_num = 0
		end

		for key ,data in pairs(DATA.big_hammer_resolve_award_cache3[award_value]) do
			local empty_num = 0
			for _key,_data in pairs(data) do
				if _data.award == 0 then
					empty_num = empty_num + 1
				end
			end
			if empty_num == target_empty_egg_num then
				target_vec[#target_vec + 1] = data
			end
		end
		--print("--------------------------------empty_egg_num,target_empty_egg_num",empty_egg_num,target_empty_egg_num)
		--dump(target_vec,"--------------------get_open_all_resolve")
		if target_vec and #target_vec > 0 then
			resolve_award_vec = target_vec[ math.random(#target_vec) ]
		else
			resolve_award_vec = DATA.big_hammer_resolve_award_cache3[award_value][ math.random(length) ]
		end

	end
	local award_vec = PUBLIC.get_real_award_data(resolve_award_vec)

	--- 打乱一下顺序
	for i=1,#award_vec-1 do
		local target_random = math.random(i,#award_vec)
		award_vec[i],award_vec[target_random] = award_vec[target_random],award_vec[i]
	end

	return award_vec
end
--------------------- 获得一组 免费 组合
function PUBLIC.get_free_resolve( award_value)
	assert( DATA.free_resolve_award_cache[award_value] , " get_free_resolve , must have cache data ~! " )

	local length = #DATA.free_resolve_award_cache[award_value]

	local resolve_award_vec = {}
	if length > 0 then
		resolve_award_vec = DATA.free_resolve_award_cache[award_value][ math.random(length) ]
	end
	local award_vec = PUBLIC.get_real_award_data(resolve_award_vec)

	--- 打乱一下顺序
	for i=1,#award_vec-1 do
		local target_random = math.random(i,#award_vec)
		award_vec[i],award_vec[target_random] = award_vec[target_random],award_vec[i]
	end

	return award_vec
end

---- 
function PUBLIC.init_resolve_award()

	local award_config = DATA.config.award
	local skill_config = DATA.config.skill

	for award_id , award_data in ipairs(award_config) do
		DATA.award_data_map[award_data.award] = DATA.award_data_map[award_data.award] or {}

		DATA.award_data_map[award_data.award][ #DATA.award_data_map[award_data.award] + 1 ] = { award_id = award_id , award_value = award_data.award }
	end


	for skill_id , skill_data in pairs(skill_config) do
		for award_id , award_data in ipairs(award_config) do
			if award_data.award >= skill_data.show_condition then
				if skill_id == 1 then
					DATA.open_all_resolve_award_cache[ award_data.award ] = PUBLIC.resolve_open_all(award_id , award_data.award )
				elseif skill_id == 2 then
					DATA.sky_girl_resolve_award_cache[ award_data.award ] = PUBLIC.resolve_sky_girl(award_id , award_data.award )
				elseif skill_id == 3 then
					DATA.big_hammer_resolve_award_cache2[ award_data.award ] = PUBLIC.resolve_big_hammer2(award_id , award_data.award )
					DATA.big_hammer_resolve_award_cache3[ award_data.award ] = PUBLIC.resolve_big_hammer3(award_id , award_data.award )
				elseif skill_id == 4 then
					DATA.free_resolve_award_cache[ award_data.award ] = PUBLIC.resolve_free(award_id , award_data.award )
				end
			end
		end
	end

	--[[dump(DATA.open_all_resolve_award_cache , "-------------------- DATA.open_all_resolve_award_cache")
	dump(DATA.sky_girl_resolve_award_cache , "-------------------- DATA.sky_girl_resolve_award_cache")
	dump(DATA.big_hammer_resolve_award_cache2 , "-------------------- DATA.big_hammer_resolve_award_cache2")
	dump(DATA.big_hammer_resolve_award_cache3 , "-------------------- DATA.big_hammer_resolve_award_cache3")
	dump(DATA.free_resolve_award_cache , "-------------------- DATA.free_resolve_award_cache")--]]
end

----------------------------------------------------------------------------------
function PUBLIC.get_one_egg()
	local eggs=math.random(1,10000)
	local config
	for i=1,12 do 
		if eggs<=config[i] then
			return i
		end
		eggs=eggs-config[i]
	end
end

function PUBLIC.get_new_award(_t_num,level)
	local eggs={}
	---先获取6个蛋
	local nor_eggs_num=6
	local eggs_hash={}
	while nor_eggs_num>0 do

		nor_eggs_num=nor_eggs_num-1
	end
end

------------------------------ 测试
function PUBLIC.test_zajindan()
	local function get_skill_eggs( award_data , eggs_status , award_key , award_type , hit_egg_no )
		local eggs = {}
		local awards = {}
		local good_egg = {}

		--- 大锤子特殊处理
		if award_type == DATA.egg_award_type.big_hammer then
			local left_egg_index = hit_egg_no - 1
			local right_egg_index = hit_egg_no + 1
			if left_egg_index == 0 then
				left_egg_index = DATA.total_eggs_num
			end
			if right_egg_index > DATA.total_eggs_num then
				right_egg_index = 1
			end

			eggs[#eggs+1] = hit_egg_no
			local big_hammer_open_num = 1
			if eggs_status[left_egg_index] ~= -1 then
				big_hammer_open_num = big_hammer_open_num + 1
				eggs[#eggs+1] = left_egg_index
			end
			if eggs_status[right_egg_index] ~= -1 then
				big_hammer_open_num = big_hammer_open_num + 1
				eggs[#eggs+1] = right_egg_index
			end

			award_data[award_key].is_get_award = true

			----- 奖励数据
			if big_hammer_open_num == 1 then
				awards[#awards + 1] =  {award_index = award_key , award_id = award_data[award_key].id }
			elseif big_hammer_open_num == 2 then
				awards[#awards + 1] = {award_index = DATA.real_rate_eggs_num+1 , award_id = award_data[DATA.real_rate_eggs_num+1].id }
				awards[#awards + 1] = {award_index = DATA.real_rate_eggs_num+2 , award_id = award_data[DATA.real_rate_eggs_num+2].id }
			elseif big_hammer_open_num == 3 then
				awards[#awards + 1] = {award_index = DATA.real_rate_eggs_num+3 , award_id = award_data[DATA.real_rate_eggs_num+3].id }
				awards[#awards + 1] = {award_index = DATA.real_rate_eggs_num+4 , award_id = award_data[DATA.real_rate_eggs_num+4].id }
				awards[#awards + 1] = {award_index = DATA.real_rate_eggs_num+5 , award_id = award_data[DATA.real_rate_eggs_num+5].id }
			end

			assert( #eggs == #awards , "-------------- #eggs must == #awards ")

			return eggs , awards
		end

		for key,egg_data in ipairs(eggs_status) do
			if egg_data ~= -1 then
				good_egg[#good_egg + 1] = key
			end
		end
		--- 有多少个这种类型的奖励
		local award_num = 0
		for key,data in ipairs(award_data) do
			if not data.is_get_award and data.award_type == award_type then
				award_num = award_num + 1
				awards[#awards + 1] = {award_index = key , award_id = data.id }
			end
		end

		assert( #good_egg >= award_num , " get_skill_eggs , good_egg num must >= award_num  " )

		---- 自己砸的蛋要爆 ,
		local start_index = 1
		if award_type == DATA.egg_award_type.free or award_type == DATA.egg_award_type.open_all then
			eggs[#eggs+1] = hit_egg_no
			start_index = start_index + 1
			for key,egg_no in ipairs(good_egg) do
				if egg_no == hit_egg_no then
					table.remove( good_egg , key )
					break
				end
			end
		end

		for i=start_index ,award_num do
			local random_index = math.random(#good_egg)
			eggs[#eggs + 1] = good_egg[random_index]
			table.remove( good_egg , random_index )
		end

		assert( #eggs == #awards , "-------------- #eggs must == #awards ")
		return eggs,awards
	end

	----- 要测试的锤子的id
	local hammer_id = 1

	----- 是否开启最优换蛋测试
	local is_open_replace_egg_test = true

	local base_money = {
		[1] = DATA.config.hammer[1].base_money ,
		[2] = DATA.config.hammer[2].base_money,
		[3] = DATA.config.hammer[3].base_money,
		[4] = DATA.config.hammer[4].base_money,
	}

	local award_config = DATA.config.award

	
	local spend_money = 0
	local replace_egg_money = 0
	local award_money = 0
	local profit = 0
	local is_replace_egg = false

	local award_vec = {}
	for i=1,100000 do
		if i%1000 == 0 then
			print("-------------------- test_zajindan: ",i)
		end
		award_vec , replace_egg_money = PUBLIC.init_award_data(hammer_id , is_replace_egg , award_vec , replace_egg_money)
		is_replace_egg = false

		local eggs_status = { 0,0,0,0,0,0,0,0,0,0,0,0 }
		local eggs_open_status = {}
		for key=1,12 do
			eggs_open_status[key] = math.random(1,5)
		end

		local opened_egg_num = 0

		for k=1 , #eggs_status do
			local is_break = false
			repeat 

			if eggs_status[k] == -1 then
				break
			end
			
			while true do
				
				if eggs_status[k] == -1 then
					break
				end

				eggs_status[k] = eggs_status[k] + 1

				spend_money = spend_money + base_money[hammer_id]

				local random = math.random() * 100

				--if random < 20 then
				local is_opend = false
				if eggs_status[k] == eggs_open_status[k] then
					--- 找到第一个没有开奖的
					is_opend = true
					for key,data in ipairs(award_vec) do
						if not data.is_get_award then
							local award_type = data.award_type
							--- 不是普通奖，找所有的同种类型的奖励
							if award_type ~= DATA.egg_award_type.normal then
								local opened_eggs , awards = get_skill_eggs( award_vec , eggs_status , key , award_type , k )
								for _key,egg_id in ipairs(opened_eggs) do
									local award_index = awards[_key].award_index     --- 12个奖励的对应的索引
									local award_id = awards[_key].award_id           --- 对应的奖励的id
									local _award_money = award_config[award_id].award  * base_money[hammer_id]
									award_vec[award_index].is_get_award = true
									opened_egg_num = opened_egg_num + 1
									award_money = award_money + _award_money

									eggs_status[_key] = -1
								end

							else
								local _award_money = data.award *  base_money[hammer_id]
								data.is_get_award = true
								opened_egg_num = opened_egg_num + 1
								award_money = award_money + _award_money

								eggs_status[k] = -1
							end


							---- 如果是砸到了一个比较大的奖励，就换蛋
							

							local min_award_id = 99
							for i=1,DATA.real_rate_eggs_num do
								if award_vec[i].id < min_award_id then
									min_award_id = award_vec[i].id
								end
							end

							local replace_award_id = 4
							if is_open_replace_egg_test and opened_egg_num < DATA.real_rate_eggs_num and (award_type ~= DATA.egg_award_type.normal or (data.id == min_award_id) ) then
								local is_replace = false

								--local random = math.random()*100
								--if random < (replace_award_id - data.id)/replace_award_id * 60 + 40 then
									is_replace = true
								--end

								if is_replace then
									local spend = math.floor((1-opened_egg_num / DATA.real_rate_eggs_num) * DATA.config.hammer[hammer_id].replace_money)
									spend_money = spend_money + spend
									replace_egg_money = replace_egg_money + spend

									opened_egg_num = DATA.real_rate_eggs_num
									--print("--------------------------------------------------------------replace_egg")
									is_replace_egg = true
								end
							end

							break
						end
					end

				end

				---- 这个一定在前面
				if opened_egg_num >= DATA.real_rate_eggs_num then
					is_break = true
					break
				end

				if is_opend then
					break
				end

			end


			until true

			if is_break then
				break
			end

		end

	end
	
	profit = award_money - spend_money

	print( "--------- test spend_money:",spend_money )
	print( "--------- test award_money:",award_money )
	print( "--------- test profit:",profit )
	print( "--------- test award_money / spend_money:",award_money / spend_money )

end



---

