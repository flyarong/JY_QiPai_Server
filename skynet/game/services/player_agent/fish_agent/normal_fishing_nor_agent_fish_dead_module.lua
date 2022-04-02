-- normal_fishing_nor_agent_fish_dead_module
require "normal_enum"
local skynet = require "skynet_plus"
local basefunc=require"basefunc"
local nodefunc = require "nodefunc"
require"printfunc"
local base = require "base"
local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC
local REQUEST=base.REQUEST
local PROTECT={}
local fish_lib = require "fish_lib"


local FIP = base.fish_interface_protect

--[[

	帧数据处理顺序:
		--发射子弹处理
		--碰撞处理
		--携带东西的鱼处理
		--加上新产生的鱼和鱼组
		--新产生的事件
		--技能数据
		--活动数据
		--特殊激光能量值变化(一定要放到技能处理之后)


	帧数据里面的每个子弹的碰撞计算:
		所有子弹可能集中多只鱼，鱼死后仅标记死亡，下一颗子弹又命中时将奖励记录奖池，所有子弹碰撞完成后才真正清除死鱼。

	鱼携带的炸弹爆炸了的多颗子弹的碰撞计算:
		每颗子弹集中所有鱼，鱼死后仅标记死亡，下一颗子弹又命中时将奖励记录奖池，所有子弹碰撞完成后才真正清除死鱼，计激光值，不抽水。

	鱼携带的电击计算:
		直接从鱼群中筛选出倍数和最接近目标值的多条鱼，剩余的值记录奖池。

	激光技能的多颗子弹的碰撞计算:
		每颗子弹集中所有鱼，鱼死后立刻死亡清除数据，下一颗子弹对剩下的鱼进行碰撞，如剩下子弹记录奖池，不累积激光值，不抽水。

]]



--[[一帧的碰撞数据 处理 哪个子弹打死哪些鱼
	[1]={
		id 子弹id
		fish_ids   子弹击中的鱼的列表
		shell_ids  击中的贝壳的索引
	},...

	(stake,type)
]] 

function FIP.bullets_shoot_fishs(_data)
	local s_info = DATA.fish_game_data.game_data

	local ret_vec = {}

	for i,_d in ipairs(_data) do

		local bullet_data = s_info.bullet_data and s_info.bullet_data[_d.id] or nil

		if bullet_data then
			--- 有效鱼
			--[[local real_fish_ids = {}
			local valid_fish_num = 0
			for key,fish_id in pairs(_d.fish_ids) do
				if s_info.fish_data and s_info.fish_data[fish_id] and not s_info.fish_data[fish_id].is_dead then
					real_fish_ids[#real_fish_ids+1] = fish_id
					valid_fish_num = valid_fish_num + 1
				end
			end

			----- 打的空弹，加入奖池
			if valid_fish_num == 0 then
				FIP.add_kongpao_fj(bullet_data.seat_num, bullet_data.index , bullet_data.stake )
				ret_vec[_d.id] = {
					dead_fish = {},
				}
			else   --]]
				local ret = FIP.deal_one_bullet_hit_fishs_with_rebate( bullet_data , _d.fish_ids , _d.shell_ids , "nor_hit" )
				ret_vec[_d.id] = ret
			--end
		end

	end

	return ret_vec
end


--[[炸弹炸死鱼
	rate       炸弹倍数(子弹个数)
	seat_num   座位号
	gun_index  炮台的索引
	stake      子弹底分
	fish_ids   鱼的候选列表
]]
function FIP.boom_shoot_fishs(_data)
	local s_info = DATA.fish_game_data.game_data

	local ret = {
		dead_fish = {},
	}

	for key = 1, _data.rate do
		--- 判断是否有鱼存活
		local is_have_fish_alive = false
		for key,fish_id in pairs(_data.fish_ids) do
			local fish_data = s_info.fish_data[fish_id]
			if fish_data and not fish_data.is_dead then
				is_have_fish_alive = true
				break
			end
		end

		if is_have_fish_alive then

			local bullet_data = { seat_num = _data.seat_num , stake = _data.stake , activity_type = "normal" , index = _data.gun_index }


			local ret_item = FIP.deal_one_bullet_hit_fishs_with_rebate( bullet_data , _data.fish_ids , {} , "boom_hit")
			-- print("-------------------------------- boom_shoot_fishs:",ret_item.money)
			basefunc.merge( ret_item.dead_fish , ret.dead_fish )
		else
			---- 剩余的 加入奖池
			FIP.add_activity_fj(_data.seat_num,_data.gun_index, (_data.rate - key)*_data.stake )
			break
		end

	end

	return ret
end

--[[电死最接近倍数的鱼
	stake  底分
	gun_index
	seat_num
	rate  电击目标倍数
	fish_ids  候选鱼列表
]]
function FIP.electric_shoot_fishs(_data)
	local s_info = DATA.fish_game_data.game_data
	local ret = 
	{
		dead_fish = {},
	}

	local rate_sum = 0
	local select_hash = {}
	local cur_rate = _data.rate

	while true do

		local max_rate = 0
		local select_id = 0
		for i,fid in ipairs(_data.fish_ids) do
			
			if s_info.fish_data[fid] and s_info.fish_data[fid].group_type==1 then

				local rate = FIP.get_one_fish_rate(s_info.fish_data[fid],s_info.fish_config,"real")

				if rate <= (cur_rate-rate_sum) and not select_hash[fid] then
					
					if rate > max_rate then
						max_rate = rate
						select_id = fid
					end

				end

			end

		end

		if max_rate > 0 then
			rate_sum = rate_sum + max_rate
			select_hash[select_id] = true

			--[[ret.dead_fish[#ret.dead_fish+1] = select_id
			ret.dead_fish_data[#ret.dead_fish_data+1] = 0
			ret.money = ret.money + 0--]]
		
			FIP.real_hit_dead_fish(select_id , { fanbei_factor = 1 , stake = _data.stake } , s_info.fish_data , s_info.fish_config , ret)

		else
			break
		end

	end

	-- 多余的值记录奖池
	local dr = _data.rate - rate_sum
	if dr > 0 then
		FIP.add_activity_fj(_data.seat_num,_data.gun_index, dr*_data.stake )
	end
	
	return ret

end



--[[激光打死鱼
	num         子弹个数
	seat_num    座位号
	gun_index   炮台的索引
	stake       子弹底分
	fish_ids    鱼的候选列表
]]
function FIP.laser_shoot_fishs(_data)

	local s_info = DATA.fish_game_data.game_data

	local ret = {
		dead_fish = {},
	}

	for key = 1, _data.num do
		--- 判断是否有鱼存活
		local is_have_fish_alive = false
		for key,fish_id in pairs(_data.fish_ids) do
			local fish_data = s_info.fish_data[fish_id]
			if fish_data and not fish_data.is_dead then
				is_have_fish_alive = true
				break
			end
		end

		if is_have_fish_alive then
			local bullet_data = { seat_num = _data.seat_num , stake = _data.stake , activity_type = "normal" , index = _data.gun_index }


			local ret_item = FIP.deal_one_bullet_hit_fishs_with_rebate( bullet_data , _data.fish_ids , {} , "laser_hit")

			basefunc.merge( ret_item.dead_fish , ret.dead_fish )
		else
			---- 剩余的 加入奖池
			FIP.add_activity_fj(_data.seat_num,_data.gun_index, (_data.num - key)*_data.stake )
			break
		end

	end

	return ret

end






