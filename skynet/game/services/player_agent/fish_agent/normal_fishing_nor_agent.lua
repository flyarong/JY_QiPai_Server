--
-- Author: HEWEI
-- Date: 2018/3/28
-- Time: 
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

local fish_dead_module = require "player_agent/fish_agent/normal_fishing_nor_agent_fish_dead_module"

require "player_agent/fish_agent/normal_fishing_data_module"
require "player_agent/fish_agent/normal_fishing_rebate_mgr"

local my_game_name="nor_fishing_nor"

local FIP = base.fish_interface_protect

--上层  model的数据
local all_data

--动作标记
local act_flag=false

--状态信息
local s_info

-- 帧数据时间间隔 *0.01 s
local frame_data_time_dt = 3

local update_timer
--update 间隔
local dt=0.5
--返回优化，避免每次返回都创建表
local return_msg={result=0}

local bullet_free_num = 0

local bullet_data_num = 0

local fish_group_id = 0

-- 活动id
local activity_id = 0

local player_focus_dt = 2
local player_focus_time = 0
local player_focus_status = 1

local has_broke = false

local function call_room_service(_func_name,...)

	return nodefunc.call(s_info.room_id,_func_name,s_info.t_num,s_info.seat_num,...)

end

local function send_room_service(_func_name,...)

	nodefunc.send(s_info.room_id,_func_name,s_info.t_num,s_info.seat_num,...)

end


-- 初始化 房间传来的配置
local function init_config()
	
	s_info.bullet_config = {}
	s_info.fishery_barbette_id = s_info.gun_id_config

	for id,v in pairs(s_info.fish_config.gun) do
		s_info.bullet_config[id] = v.level
	end

	s_info.skill_cfg = s_info.fish_config.skill

	s_info.use_skill_cfg = {}

	for i,v in ipairs(s_info.skill_cfg) do
		s_info.use_skill_cfg[v.skill] = v
	end

end

-- 检测破产
local function check_broke()
	
	-- 托管的破产检测
	for i=2,4 do
		
		local info = all_data.m_PROTECT.get_p_info(i)
		if info then
			local coin = info.score + info.fish_coin
			local min_stake = s_info.bullet_config[1]
			if coin < min_stake then

				-- 托管的最后几发免费子弹可能因为 delete_bullet 永远无法结束活动

				-- local t = FIP.is_in_activity(i)
				-- if t ~= "free_bullet" then
				-- 	dump(info,"+++++++tuoguan_broke+++++++++"..i)
					send_room_service("tuoguan_broke",i)
				-- else
				-- 	print("free_bullet+++++++tuoguan_broke+++++++++")
				-- end
			end 
		end
	end
	

	-- 玩家破产 的 限时特惠
	if has_broke then
		return
	end

	local gift_bag_id = 0
	if DATA.fish_game_data.room_info.game_id == 2 then
		gift_bag_id = 39
	elseif DATA.fish_game_data.room_info.game_id == 3 then
		gift_bag_id = 40
	else
		return
	end

	local cur_score = CMD.query_asset_by_type(PLAYER_ASSET_TYPES.JING_BI)
	local cur_fish_coin = CMD.query_asset_by_type(PLAYER_ASSET_TYPES.FISH_COIN)

	local coin = cur_score + cur_fish_coin
	local min_stake = s_info.bullet_config[1]
	if coin < min_stake then

		local t = FIP.is_in_activity(1)

		if t ~= "free_bullet" then

			has_broke = true

			skynet.send(base.DATA.service_config.pay_service,"lua","player_trigger_condition"
								,DATA.my_id,gift_bag_id)

		end

	end

end


local function change_tuoguan_score(_seat_num,_score)
	
	all_data.m_PROTECT.change_p_score(_seat_num,_score)

end


local function notify_fish_dead(_fish_ids)

	if not _fish_ids or not next(_fish_ids) then
		return
	end

	for i,v in ipairs(_fish_ids) do
		s_info.fish_data[v] = nil
	end

	send_room_service("fish_dead",_fish_ids)

	-- dump(_fish_ids,"+++++++++notify_fish_dead++++++++")
end


--[[ 活动 累积 奖励 处理 ]]

-- 暴击时刻活动 处理 和 累积奖励
local function crit_activity_deal(_seat_num,_aw)

	for ai,ad in pairs(s_info.activity_data) do
		if ad.msg_type == "crit" 
			and ad.seat_num == _seat_num
			and os.time() < ad.begin_time+ad.time+math.floor(s_info.fishery_begin_time*0.1) then
				ad.score = ad.score + _aw
			break
		end
	end

end

-- 威力增强活动 处理 和 累积奖励
local function power_activity_deal(_seat_num,_aw)

	for ai,ad in pairs(s_info.activity_data) do
		if ad.msg_type == "power" 
			and ad.seat_num == _seat_num
			and os.time() < ad.begin_time+ad.time+math.floor(s_info.fishery_begin_time*0.1) then
				ad.score = ad.score + _aw
			break
		end
	end

end

-- 子弹活动 处理 和 累积奖励
local function bullet_activity_deal(_bullet_activity_id,_aw)

	-- 免费子弹活动处理
	local fbad = nil
	if _bullet_activity_id then
		fbad = s_info.activity_data[_bullet_activity_id]
		if fbad and (
			fbad.msg_type == "free_bullet" 
			or fbad.msg_type == "power_bullet" 
			or fbad.msg_type == "crit_bullet" )then
			
			fbad.boom_num = fbad.boom_num - 1
		else
			fbad = nil
		end
	end

	-- 免费子弹活动处理
	if fbad and _aw > 0 then
		fbad.score = fbad.score + _aw
	end

end



local function add_fish_group(_fishs)
	
	for i,f in pairs(_fishs) do

		s_info.fish_data[f.id] = f
		s_info.new_fish_data[f.id] = f

		if f.group_type == 3 then

			if f.group_id then
				local gp = f.group_id
				yd = s_info.ywdj_data[gp] or {}
				s_info.ywdj_data[gp] = yd
				yd[#yd+1] = f
			end

		end

	end

end


-- 核弹掉落
local function missile_drop_out(_ed,_seat_num)

	if math.random(1,100) > 30 then
		--碎片

		local v = s_info.missile_data[_seat_num].value
		local n = s_info.missile_data[_seat_num].num

		if n > 3 then
			return
		end

		local missile_fragment = math.random(1,2)

		_ed.data = {2,1,missile_fragment}

		s_info.missile_data[_seat_num].value = math.floor(v + missile_fragment * 10^n)
		s_info.missile_data[_seat_num].num = n + 1

	end

end



local function gen_activity(_seat_num,_bullet_index,_acti_type,_data,_value)
	
	-- 没这个座位的人 不管
	if not all_data.m_PROTECT.get_p_info(_seat_num) then
		return false
	end

	if FIP.is_in_activity(_seat_num) then
		-- 已经有活动了
		FIP.add_activity_fj(_seat_num,_bullet_index,_value*(s_info.bullet_config[_bullet_index]))

		------
		print("xxxx-------------------------------------------------------------------------------- gen_activity____  is_in_activity !")
		return false
	end

	activity_id = activity_id + 1
	
	if activity_id > 5000 then
		activity_id = 1
	end


	--免费子弹 
	if _acti_type == 1 then

		s_info.activity_data[activity_id]=
		{
			activity_id = activity_id,
			msg_type = "free_bullet",
			begin_time = os.time() - math.floor(s_info.fishery_begin_time*0.1),
			seat_num = _seat_num,
			bullet_index = _bullet_index,
			num = _value,
			boom_num = _value,
			score = 0,
			status = 0,
		}

	-- 威力提升
	elseif _acti_type == 2 then

		-- s_info.activity_data[activity_id]=
		-- {
		-- 	activity_id = activity_id,
		-- 	msg_type = "power",
		-- 	begin_time = os.time() - math.floor(s_info.fishery_begin_time*0.1),
		-- 	end_time = os.time()+math.floor(_data[1]*0.1),
		-- 	time = math.floor(_data[1]*0.1),
		-- 	pro = _data[2],
		-- 	seat_num = _seat_num,
		-- 	score = 0,
		-- 	bullet_index = _bullet_index,
		-- 	--- add by wss
		-- 	total_num = _value,    --- 总价值
		-- 	gain_num = _data[2],      --- 提升命中率
		-- }

		s_info.activity_data[activity_id]=
		{
			activity_id = activity_id,
			msg_type = "power_bullet",
			begin_time = os.time() - math.floor(s_info.fishery_begin_time*0.1),
			seat_num = _seat_num,
			bullet_index = _bullet_index,
			num = _value,
			boom_num = _value,
			pro = _data[2] or 2,
			gain_num = _data[2] or 2,      --- 提升倍数
			score = 0,
			status = 0,
		}

	--  暴击时刻
	elseif _acti_type == 3 then

		-- s_info.activity_data[activity_id]=
		-- {
		-- 	activity_id = activity_id,
		-- 	msg_type = "crit",
		-- 	begin_time = os.time() - math.floor(s_info.fishery_begin_time*0.1),
		-- 	end_time = os.time()+math.floor(_data[1]*0.1),
		-- 	time = math.floor(_data[1]*0.1),
		-- 	seat_num = _seat_num,
		-- 	rate = _data[2],
		-- 	score = 0,
		-- 	bullet_index = _bullet_index,
		-- 	--- add by wss
		-- 	total_num = _value,    --- 总价值
		-- 	gain_num = _data[2],      --- 提升倍数
		-- }

		s_info.activity_data[activity_id]=
		{
			activity_id = activity_id,
			msg_type = "crit_bullet",
			begin_time = os.time() - math.floor(s_info.fishery_begin_time*0.1),
			seat_num = _seat_num,
			bullet_index = _bullet_index,
			num = _value,
			boom_num = _value,
			rate = _data[2] or 2,
			gain_num = _data[2] or 2,      --- 提升倍数
			score = 0,
			status = 0,
		}

	--- 贝壳抽奖
	elseif _acti_type == 10 then
		s_info.activity_data[activity_id]=
		{
			activity_id = activity_id,
			msg_type = "shell_lottery",
			begin_time = os.time() - math.floor(s_info.fishery_begin_time*0.1),
			end_time = os.time() + math.floor( _data[1] / 10 + 0.5 ) ,
			time = math.floor( _data[1] / 10 + 0.5 ) ,
			hit_rate = _data[2],
			seat_num = _seat_num,
			bullet_index = _bullet_index,
			award_value = _value,
			shell_list = { 1,1,1,1 },
			score = 0,
			status = 0,
		}
	end

	s_info.activity_data_cache[#s_info.activity_data_cache+1]=s_info.activity_data[activity_id]

	return true
end

local function get_fish_prop(_acti_type,_value)
	--掉落 红包 锁定卡 冰冻卡

	if _acti_type == 6 then

	elseif _acti_type == 7 then

		all_data.m_PROTECT.modify_skill_prop("prop_fish_lock",1)

	elseif _acti_type == 8 then

		all_data.m_PROTECT.modify_skill_prop("prop_fish_frozen",1)


	elseif _acti_type == 9 then

		all_data.m_PROTECT.modify_skill_prop("prop_zongzi",_value)

	end

end


local function check_activity_is_over()
	
	for activity_id,ad in pairs(s_info.activity_data) do
		
		if ad.msg_type == "crit" then

			if os.time() > ad.end_time then
				-- 结束了

				s_info.activity_data_cache[#s_info.activity_data_cache+1]=ad
				ad.begin_time = nil
				ad.time = nil

				if ad.total_num > 0 then
					FIP.add_activity_fj(ad.seat_num,ad.bullet_index, (ad.total_num)*(s_info.bullet_config[ad.bullet_index]))
				end

				s_info.activity_data[ad.activity_id] = nil
			end


		elseif ad.msg_type == "power" then

			if os.time() > ad.end_time then
				-- 结束了

				if ad.total_num > 0 then
					FIP.add_activity_fj(ad.seat_num,ad.bullet_index, (ad.total_num)*(s_info.bullet_config[ad.bullet_index]))
				end

				s_info.activity_data_cache[#s_info.activity_data_cache+1]=ad
				ad.begin_time = nil
				ad.time = nil

				s_info.activity_data[ad.activity_id] = nil
			end

		elseif ad.msg_type == "free_bullet"
				or ad.msg_type == "power_bullet" 
				or ad.msg_type == "crit_bullet" then

			if ad.boom_num < 1 then
				-- 结束了

				-- 不可能
				-- if ad.num > 0 then
				-- 	FIP.add_activity_fj(ad.seat_num,ad.bullet_index, (ad.num)*(s_info.bullet_config[ad.bullet_index]))
				-- end

				s_info.activity_data_cache[#s_info.activity_data_cache+1]=ad
				ad.num = nil
				ad.status = 2

				s_info.activity_data[ad.activity_id] = nil
			end

		---- 贝壳抽奖的结束
		elseif ad.msg_type == "shell_lottery" then
			local is_deal = false
			if os.time() > ad.end_time then
				
				s_info.activity_data_cache[#s_info.activity_data_cache+1]=ad
				ad.begin_time = nil
				ad.award_value = nil
				ad.hit_rate = nil
				ad.status = 2

				s_info.activity_data[ad.activity_id] = nil
				is_deal = true
			end

			if not is_deal and ad and ad.shell_list and type(ad.shell_list) == "table" and next(ad.shell_list) then
				local is_alive_shell = false
				for key,is_alive in pairs(ad.shell_list) do
					if is_alive == 1 then
						is_alive_shell = true
						break
					end
				end
				if not is_alive_shell then
					s_info.activity_data_cache[#s_info.activity_data_cache+1]=ad
					ad.begin_time = nil
					ad.award_value = nil
					ad.hit_rate = nil
					ad.status = 2

					s_info.activity_data[ad.activity_id] = nil
				end
			end


		else

		end

	end

end

-- 未完成活动强制返奖
local function activity_force_reward()
	
	if s_info then
		for activity_id,ad in pairs(s_info.activity_data) do
			
			if ad.msg_type == "crit" or ad.msg_type == "power" then

				if ad.total_num > 0 then
					FIP.add_activity_fj(ad.seat_num,ad.bullet_index, (ad.total_num)*(s_info.bullet_config[ad.bullet_index]))
				end

			elseif ad.msg_type == "free_bullet"
				or ad.msg_type == "crit_bullet" 
				or ad.msg_type == "power_bullet" then

					local rate = 1
					if ad.num > 0 then

						local stake = s_info.bullet_config[ad.bullet_index]

						if ad.gain_num then
							rate = ad.gain_num
						end

						FIP.add_activity_fj(ad.seat_num,ad.bullet_index, (ad.num)*stake*rate)

					end

			elseif ad.msg_type == "shell_lottery" then
				local stake = s_info.bullet_config[ad.bullet_index]

				FIP.add_activity_fj(ad.seat_num,ad.bullet_index, (ad.award_value)*stake )
			else

			end

		end
	end

end


local function special_fish_force_reward()
	
	-- s_info.special_fish_award_data[fid] = 
	-- {
	-- 	bullet_stake = s_info.bullet_config[_bd.index],
	-- 	fish_rate = actd.value,
	-- 	seat_num = _bd.seat_num,
	-- 	bullet_index = _bd.index,
	-- 	type = actd.acti_type,
	-- }

	if not s_info then
		return
	end

	for fid,sfad in pairs(s_info.special_fish_award_data) do
		FIP.add_activity_fj(sfad.seat_num,sfad.bullet_index,(sfad.fish_rate)*(s_info.bullet_config[sfad.bullet_index]))
	end

end

-- 特殊活动鱼死了 记录 活动 数据
local function deal_special_fish(_fd,_bd,_data)

	if _fd and next(_fd) then

		for fid,dfd in pairs(_fd) do
			
			local ad = dfd.act_data

			if ad then

				local dc = {}
				for i,ai in ipairs(ad) do
					
					local actd = s_info.fish_config.activity[ai]

					-- 炸弹 和 闪电
					if actd.acti_type == 4 or actd.acti_type == 5 then

						if actd.acti_type == 5 then
							dc = {actd.acti_type,actd.value}
						else
							dc = {actd.acti_type}
						end

						s_info.special_fish_award_data[fid] = 
						{
							bullet_stake = s_info.bullet_config[_bd.index],
							fish_rate = actd.value,
							seat_num = _bd.seat_num,
							bullet_index = _bd.index,
							type = actd.acti_type,
						}

					--免费子弹 威力提升 暴击时刻
					elseif actd.acti_type>=1 and actd.acti_type <=3 then
						
						gen_activity(_bd.seat_num,_bd.index,actd.acti_type,actd.num,actd.value)

						dc = {0}

					--- 贝壳抽奖
					elseif actd.acti_type==10 then
						
						local is_create_act = gen_activity(_bd.seat_num,_bd.index,actd.acti_type,actd.num,actd.value)

						if is_create_act then
							dc = {actd.acti_type}
						else
							dc = {0}
						end

					--掉落 红包 锁定卡 冰冻卡
					elseif actd.acti_type>=6 and actd.acti_type <=8 then
						
						if _bd.seat_num == 1 then
							get_fish_prop(actd.acti_type,actd.value)
						end

						dc = {actd.acti_type,actd.num[1]}

					--粽子
					elseif actd.acti_type == 9 then
					
						local bullet_stake = s_info.bullet_config[_bd.index]
						local n = math.floor(actd.num[1]*bullet_stake)
						
						if n > 0 then
							if _bd.seat_num == 1 then
								get_fish_prop(actd.acti_type,n)
							end

							dc = {actd.acti_type,n}
						end

					end

				end

				for i,v in ipairs(dc) do
					_data[#_data+1] = v
				end

			else
				_data[#_data+1] = 0
			end

		end

	end
end




local function fish_data_to_frame_data(_fish_data,_frame_data)
	
	local fish_groups = _frame_data.fish_group or {}
	_frame_data.fish_group = fish_groups

	local fish_teams = _frame_data.fish_team or {}
	_frame_data.fish_team = fish_teams

	local fish_groups_key_hash = {}
	--
	for fid,nfd in pairs(_fish_data) do
		
		if nfd.fish_crowd_id then
			local kh = fish_groups_key_hash[nfd.fish_crowd_id] or (#fish_groups+1)
			fish_groups_key_hash[nfd.fish_crowd_id] = kh

			local fgs = fish_groups[kh] or basefunc.copy(nfd)
			fish_groups[kh] = fgs

			local types = fgs.types or {}
			fgs.types = types
			types[#types+1] = nfd.type

			local ids = fgs.ids or {}
			fgs.ids = ids
			ids[#ids+1] = fid
		
		elseif nfd.types then
			fish_teams[#fish_teams+1] = nfd
		else
			print("error single fish to group!!!")
		end

	end

end


function deal_activity_start_frame_data(_frame_data)

	if _frame_data and _frame_data.activity and #_frame_data.activity>0 then

		for i,ad in ipairs(_frame_data.activity) do
			local mad = s_info.activity_data[ad.activity_id]
			if mad and ad.status == 1 and mad.status == 0 then
				mad.status = 1
				s_info.activity_data_cache[#s_info.activity_data_cache+1] = mad

				if mad.msg_type == "shell_lottery" then
					mad.begin_time = os.time() - math.floor(s_info.fishery_begin_time*0.1)
					mad.end_time = os.time() + mad.time 
				end

			end


		end

	end

end


local bullet_type_map =
{
	free_bullet = 1,
	power_bullet = 2,
	crit_bullet = 3,
}

local function deal_bullet_frame_data(_fd)

	if not _fd.shoot then
		return
	end

	for i,_bd in ipairs(_fd.shoot) do

		repeat

			-- 没这个座位的人 不管
			if not all_data.m_PROTECT.get_p_info(_bd.seat_num) then
				_bd.id = -998
				print("seat_num is error !!!")
				break
			end

			local bullet_id = 0
			for k,_ in pairs(s_info.bullet_free_ids) do
				bullet_id = k
				break
			end

			if bullet_id == 0 then
				dump(bullet_free_ids,"bullet_free_ids++++/*-"..bullet_free_num)
				dump(bullet_data,"bullet_data++++/*-"..bullet_data_num)
			end

			_bd.id = bullet_id
			_bd.time = os.time() - math.floor(s_info.fishery_begin_time*0.1)

			if _bd.index then

				local stake = s_info.bullet_config[_bd.index]

				if stake then

					_bd.activity_type = "normal"
					_bd.stake = stake
					_bd.type = 0

					for ai,ad in pairs(s_info.activity_data) do
						if ad.msg_type == "free_bullet" 
							or ad.msg_type == "crit_bullet" 
							or ad.msg_type == "power_bullet" then

							if ad.status==1 and ad.seat_num==_bd.seat_num and ad.num>0 then
								ad.num = ad.num - 1

								_bd.activity_id = ai
								_bd.activity_type = ad.msg_type
								_bd.type = bullet_type_map[ad.msg_type]

							end
						
						elseif ad.msg_type == "crit" then

							if ad.seat_num==_bd.seat_num then

								_bd.activity_id = ai
								_bd.activity_type = ad.msg_type
								_bd.type = 3

							end

						elseif ad.msg_type == "power" then
							
							if ad.seat_num==_bd.seat_num then

								_bd.activity_id = ai
								_bd.activity_type = ad.msg_type
								_bd.type = 2

							end

						end

					end

					if _bd.seat_num == 1 then
					
						local money = stake
						if _bd.activity_type == "free_bullet" then
							money = 0
						end

						local cur_score = CMD.query_asset_by_type(PLAYER_ASSET_TYPES.JING_BI)
						local cur_fish_coin = CMD.query_asset_by_type(PLAYER_ASSET_TYPES.FISH_COIN)
						
						if money <= (cur_score + cur_fish_coin) then

							s_info.bullet_data[bullet_id] = _bd
							bullet_data_num = bullet_data_num + 1
							s_info.bullet_free_ids[bullet_id] = nil
							bullet_free_num = bullet_free_num - 1
							local jing_bi,fish_coin = all_data.m_PROTECT.modify_score(-money,"bullet",_bd.index)
							_bd.jing_bi = -jing_bi
							_bd.fish_coin = -fish_coin

							FIP.statistics_fish_assets_data("bullet",stake,_bd.jing_bi
															,_bd.fish_coin,_bd.activity_type)

							if _bd.activity_type == "free_bullet" then
								_bd.jing_bi = stake
							end

						else

							_bd.id = -999
							print("money is error !!!")

						end

					else
						
						if _bd.activity_type == "free_bullet" then
							stake = 0
						end

						s_info.bullet_data[bullet_id] = _bd
						bullet_data_num = bullet_data_num + 1
						s_info.bullet_free_ids[bullet_id] = nil
						bullet_free_num = bullet_free_num - 1
						change_tuoguan_score(_bd.seat_num,-stake)

					end

				else

					_bd.id = -997
					print("bullet_index is error !!!")

				end

			end

		until true

	end

	-- dump(s_info.bullet_data,"s_info.bullet_data+++++/*-/--")

end


-- 将死鱼倍数固定的数值累积筛选出来
local function deal_fish_explode_frame_data(_fd)

	if not _fd.fish_explode then
		return
	end

	for i,_fe in ipairs(_fd.fish_explode) do

		local sfad = s_info.special_fish_award_data[_fe.id]
		if sfad then
			
			-- 炸弹鱼(相当于免费子弹)
			if sfad.type == 4 then

				-- 裁剪数量
				for i,v in ipairs(_fe.fish_ids) do
					if i > 8 then
						_fe.fish_ids[i] = nil
					end
				end

				local ret = FIP.boom_shoot_fishs({
					seat_num = sfad.seat_num,
					gun_index = sfad.bullet_index,
					stake = s_info.bullet_config[sfad.bullet_index],
					rate = sfad.fish_rate,
					fish_ids = _fe.fish_ids,
				})
				

				_fe.fish_ids = {}
				_fe.moneys = {}
				local money_sum = 0
				for fish_id,dfd in pairs(ret.dead_fish) do
					_fe.fish_ids[#_fe.fish_ids+1] = fish_id
					_fe.moneys[#_fe.moneys+1] = dfd.money
					money_sum = money_sum + dfd.money
				end

				_fe.data = {}
				sfad.index = sfad.bullet_index
				deal_special_fish(ret.dead_fish,sfad,_fe.data)

				if sfad.seat_num == 1 then
					all_data.m_PROTECT.modify_score(money_sum,"fish_dead")
					FIP.statistics_fish_assets_data("fish_dead",s_info.bullet_config[sfad.bullet_index]
													,_fe.fish_ids,money_sum,"boom" , sfad.bullet_index)
				else
					change_tuoguan_score(sfad.seat_num,money_sum)
				end

				notify_fish_dead(_fe.fish_ids)

				s_info.special_fish_award_data[_fe.id] = nil

			-- 电击鱼
			elseif sfad.type == 5 then

				-- 裁剪数量
				for i,v in ipairs(_fe.fish_ids) do
					if i > 10 then
						_fe.fish_ids[i] = nil
					end
				end

				local ret = FIP.electric_shoot_fishs({
					stake = s_info.bullet_config[sfad.bullet_index],
					gun_index = sfad.bullet_index,
					seat_num = sfad.seat_num,
					rate = sfad.fish_rate,
					fish_ids = _fe.fish_ids,
				})

				_fe.fish_ids = {}
				_fe.moneys = {}
				local money_sum = 0
				for fish_id,dfd in pairs(ret.dead_fish) do
					_fe.fish_ids[#_fe.fish_ids+1] = fish_id
					_fe.moneys[#_fe.moneys+1] = dfd.money
					money_sum = money_sum + dfd.money
				end

				_fe.data = {}
				sfad.index = sfad.bullet_index
				deal_special_fish(ret.dead_fish,sfad,_fe.data)

				if sfad.seat_num == 1 then
					all_data.m_PROTECT.modify_score(money_sum,"fish_dead")
					FIP.statistics_fish_assets_data("fish_dead",s_info.bullet_config[sfad.bullet_index]
													,_fe.fish_ids,money_sum,"electric" , sfad.bullet_index)
				else
					change_tuoguan_score(sfad.seat_num,money_sum)
				end
				
				notify_fish_dead(_fe.fish_ids)

				s_info.special_fish_award_data[_fe.id] = nil

			else
				_fe.fish_ids=nil
			end

		else
			_fe.fish_ids=nil
		end

	end

end


local function deal_boom_frame_data(_fd)

	if not _fd.boom then
		return
	end

	--裁剪 子弹打的鱼最多3条
	for bi,_ed in ipairs(_fd.boom) do
		for i,v in ipairs(_ed.fish_ids) do
			if i > 3 then
				_ed.fish_ids[i]=nil
			end
		end
	end

	local _data = basefunc.deepcopy(_fd.boom)
	local ret = FIP.bullets_shoot_fishs(_data)
	for i,_ed in ipairs(_fd.boom) do

		local bd = s_info.bullet_data[_ed.id]

		if bd then

			_ed.fish_ids = {}
			_ed.moneys = {}
			_ed.shell_ids = {}

			local d = ret[_ed.id]
			if d and next(d.dead_fish) then
				
				local money_sum = 0
				for fish_id,dfd in pairs(d.dead_fish) do
					_ed.fish_ids[#_ed.fish_ids+1] = fish_id
					_ed.moneys[#_ed.moneys+1] = dfd.money
					money_sum = money_sum + dfd.money
				end

				_ed.data = _ed.data or {}
				deal_special_fish(d.dead_fish,bd,_ed.data)

				if bd.seat_num == 1 then
					all_data.m_PROTECT.modify_score(money_sum,"fish_dead")
					FIP.statistics_fish_assets_data("fish_dead",bd.stake
													,_ed.fish_ids,money_sum,bd.activity_type , bd.index)
				else
					change_tuoguan_score(bd.seat_num,money_sum)
				end

				notify_fish_dead(_ed.fish_ids)

				-- 子弹活动处理
				bullet_activity_deal(bd.activity_id,money_sum)

				--威力增强活动 处理 和 累积奖励
				-- power_activity_deal(bd.seat_num,money_sum)

				-- 暴击时刻活动处理
				-- crit_activity_deal(bd.seat_num,money_sum)
			
			------ 处理贝壳死亡
			elseif d and next(d.dead_shell) then
				
				local money_sum = 0
				for shell_id,data in pairs(d.dead_shell) do
					_ed.shell_ids[#_ed.shell_ids+1] = {shell_id = shell_id , money = data.money }
					_ed.moneys[#_ed.moneys+1] = data.money
					money_sum = money_sum + data.money
				end

				if bd.seat_num == 1 then
					all_data.m_PROTECT.modify_score(money_sum,"fish_dead")
					FIP.statistics_fish_assets_data("shell_dead",bd.stake
													,_ed.shell_ids,money_sum,bd.activity_type , bd.index)
				else
					change_tuoguan_score(bd.seat_num,money_sum)
				end


			else

				-- 即使没有打死鱼 子弹活动任然处理
				bullet_activity_deal(bd.activity_id,0)

			end

			s_info.bullet_free_ids[_ed.id] = true
			bullet_free_num = bullet_free_num + 1

			s_info.bullet_data[_ed.id] = nil
			bullet_data_num = bullet_data_num - 1

		else

			_ed.fish_ids = {}
			print("bullet_id is error !!!")

		end

	end

end


---------------------- skill ------------------------------

local function deal_skill_frozen(_sd)
	
	if s_info.skill_data.frozen then
		return
	end

	local prop_num = CMD.query_asset_by_type("prop_fish_frozen")
	if _sd.seat_num==1 and prop_num < 1 then
		return
	end

	local ss = s_info.skill_status[_sd.seat_num] or {}
	s_info.skill_status[_sd.seat_num] = ss

	local sd = ss[_sd.msg_type] or {}
	ss[_sd.msg_type] = sd


	local cd = s_info.use_skill_cfg["frozen"].cd_time

	if sd.cd and sd.cd > os.time() then
		return
	else
		sd.cd = os.time() + cd
	end

	_sd.time = s_info.use_skill_cfg["frozen"].time
	sd.cd = sd.cd + _sd.time

	s_info.skill_data[#s_info.skill_data+1] = 
	{
		skill = "frozen",
		time = os.time() + _sd.time,
		seat_num = _sd.seat_num,
	}

	s_info.frozen_time_data = s_info.frozen_time_data or {}
	s_info.frozen_time_data[#s_info.frozen_time_data+1] = os.time() - math.floor(s_info.fishery_begin_time*0.1)

	-- 记录全局技能 便于直接查询
	s_info.skill_data.frozen = s_info.skill_data[#s_info.skill_data]

	send_room_service("player_use_skill",_sd.seat_num,_sd.msg_type,sd.cd,_sd.time)

	if _sd.seat_num==1 then
		all_data.m_PROTECT.modify_skill_prop("prop_fish_frozen",-1)
	end
end


local function deal_skill_lock(_sd)

	local prop_num = CMD.query_asset_by_type("prop_fish_lock")
	if _sd.seat_num==1 and prop_num < 1 then
		return
	end

	local ss = s_info.skill_status[_sd.seat_num] or {}
	s_info.skill_status[_sd.seat_num] = ss

	local sd = ss[_sd.msg_type] or {}
	ss[_sd.msg_type] = sd

	local cd = s_info.use_skill_cfg["lock"].cd_time

	if sd.cd and sd.cd > os.time() then
		return
	else
		sd.cd = os.time() + cd
	end

	_sd.time = s_info.use_skill_cfg["lock"].time
	sd.cd = sd.cd + _sd.time

	s_info.skill_data[#s_info.skill_data+1] = 
	{
		skill = "lock",
		time = os.time() + _sd.time,
		seat_num = _sd.seat_num,
	}

	send_room_service("player_use_skill",_sd.seat_num,_sd.msg_type,sd.cd)

	if _sd.seat_num==1 then
		all_data.m_PROTECT.modify_skill_prop("prop_fish_lock",-1)
	end
	
end


local function deal_skill_laser(_sd)
	local d = s_info.laser_data[_sd.seat_num]

	if not _sd.index then
		return
	end

	local stake = s_info.fish_config.gun[_sd.index].level
	local fcl = s_info.fish_config.laser[_sd.index]
	local laser_max_value = (fcl.value*stake)

	local consume_value = math.ceil(laser_max_value) or 999999999
	if d.value < consume_value then
		_sd.fish_ids = nil
		return 
	end

	-- 裁剪数量
	for i,v in ipairs(_sd.fish_ids) do
		if i > 10 then
			_sd.fish_ids[i] = nil
		end
	end

	d.value = d.value - consume_value
	d.change = true
	local laser_bullet_num = s_info.fish_config.laser[_sd.index].value 
								+ FIP.use_jg_bc(_sd.seat_num,_sd.index)

	local ret = FIP.laser_shoot_fishs({
		num = laser_bullet_num,
		seat_num = _sd.seat_num,
		gun_index = _sd.index,
		stake = s_info.bullet_config[_sd.index],
		fish_ids = _sd.fish_ids,
	})
	
	_sd.fish_ids = {}
	_sd.moneys = {}
	local money_sum = 0
	for fish_id,dfd in pairs(ret.dead_fish) do
		_sd.fish_ids[#_sd.fish_ids+1] = fish_id
		_sd.moneys[#_sd.moneys+1] = dfd.money
		money_sum = money_sum + dfd.money
	end

	_sd.data = {}
	deal_special_fish(ret.dead_fish,_sd,_sd.data)

	if _sd.seat_num == 1 then
		all_data.m_PROTECT.modify_score(money_sum,"fish_dead")
		FIP.statistics_fish_assets_data("fish_dead",s_info.bullet_config[_sd.index]
												,_sd.fish_ids,money_sum,"laser" , _sd.index)
	else
		change_tuoguan_score(_sd.seat_num,money_sum)
	end

	notify_fish_dead(_sd.fish_ids)

end


local function deal_skill_missile(_sd)
	local d = s_info.missile_data[_sd.seat_num]

	if d.num < 4 then
		return
	end

	local stake = d.value

	d.num = 0
	d.value = 0
	_sd.value = 0

	local dead_fish = {}
	-- for i,fid in ipairs(_sd.fish_ids) do
		
	-- 	local fd = fish_data[fid]
	-- 	if fd then
	-- 		local fc
	-- 		if fd.types then
	-- 			fc = s_info.fish_config[fd.types[1]]
	-- 		else
	-- 			fc = s_info.fish_config[fd.type]
	-- 		end
			
	-- 		if math.random(1,10000) < fc.shoot*10000*100 then

	-- 			local aw = fc.rate * stake
				
	-- 			fish_data[fid] = nil
	-- 			dead_fish[#dead_fish+1] = fid

	-- 			send_room_service("fish_dead",fid)

	-- 			if _sd.seat_num == 1 then
	-- 				all_data.m_PROTECT.modify_score(aw,"fish_dead",fd.type,0,2)
	-- 			else
	-- 				change_tuoguan_score(_sd.seat_num,aw)
	-- 			end

	-- 		end

	-- 	end

	-- end

	_sd.fish_ids = dead_fish
	_sd.money = money

end


local function skill_record(_sd)

	local info = all_data.m_PROTECT.get_p_info(_sd.seat_num)
	if not info then
		return
	end

	if _sd.msg_type == "frozen" then
		deal_skill_frozen(_sd)
	elseif _sd.msg_type == "lock" then
		deal_skill_lock(_sd)
	elseif _sd.msg_type == "laser" then
		deal_skill_laser(_sd)
	elseif _sd.msg_type == "missile" then
		deal_skill_missile(_sd)
	else
		return
	end

end


---------------------- skill ------------------------------



local function deal_fish_frame_data(_frame_data)

	if s_info.new_fish_data and next(s_info.new_fish_data) then

		fish_data_to_frame_data(s_info.new_fish_data,_frame_data)

		s_info.new_fish_data = {}

	end

end


local function deal_event_frame_data(_frame_data)
	
	if s_info.event_data and next(s_info.event_data) then

		_frame_data.event = {}
		for i,ev in ipairs(s_info.event_data) do
			_frame_data.event[#_frame_data.event+1] = ev
		end

		s_info.event_data = {}

	end

end


local function deal_activity_frame_data(_frame_data)

	-- 检测活动完成
	check_activity_is_over()

	-- 检测新的活动开始
	if #s_info.activity_data_cache > 0 then

		_frame_data.activity = {}

		for i,d in pairs(s_info.activity_data_cache) do
			_frame_data.activity[#_frame_data.activity+1]=d
		end

		s_info.activity_data_cache = {}

	end

end


local function deal_activity_all_info(_frame_data)

	-- 检测活动完成
	check_activity_is_over()

	_frame_data.activity = {}

	for i,d in pairs(s_info.activity_data) do
		_frame_data.activity[#_frame_data.activity+1]=d
	end

	s_info.activity_data_cache = {}

end



local function deal_skill_frame_data(_frame_data)
	
	if _frame_data.skill and next(_frame_data.skill) then

		for i,d in ipairs(_frame_data.skill) do
			skill_record(d)
		end

	end

	for i,sd in pairs(s_info.skill_data) do
		if sd.time <= os.time() then
			-- 时间过了 标记一下
			s_info.skill_data[i] = nil
		end
	end

end


local function deal_laser_frame_data(_frame_data)

	local sh = {}
	if _frame_data.skill and next(_frame_data.skill) then
		for i,s in ipairs(_frame_data.skill) do
			if s.msg_type == "laser" then
				sh[s.seat_num] = i
			end
		end
	end

	_frame_data.skill = _frame_data.skill or {}

	for i=1,4 do
		
		if s_info.laser_data[i].change then
			s_info.laser_data[i].change = false
			
			local si = sh[i]

			if si then
				_frame_data.skill[si].time = math.floor(s_info.laser_data[i].value)
			else
				_frame_data.skill[#_frame_data.skill+1]=
				{
					msg_type = "laser",
		            time = math.floor(s_info.laser_data[i].value),
		            seat_num = i,
				}
			end

		end
	end

end


local function deal_fish_out_pool_frame_data( _frame_data )
	
	if _frame_data.fish_out_pool then

		notify_fish_dead(_frame_data.fish_out_pool)

	end

end

local function deal_assets_frame_data(_fd)

	local cur_score = CMD.query_asset_by_type(PLAYER_ASSET_TYPES.JING_BI)
	local cur_fish_coin = CMD.query_asset_by_type(PLAYER_ASSET_TYPES.FISH_COIN)

	_fd.assets = 
	{
		{
			asset_type = PLAYER_ASSET_TYPES.JING_BI,
			value = cur_score,
		},

		{
			asset_type = PLAYER_ASSET_TYPES.FISH_COIN,
			value = cur_fish_coin,
		},

	}

end


local function deal_frame_data(_fd)

	--发射子弹处理
	deal_bullet_frame_data(_fd)

	--碰撞处理
	deal_boom_frame_data(_fd)

	--携带东西的鱼处理
	deal_fish_explode_frame_data(_fd)

	-- 加上新产生的鱼和鱼组
	deal_fish_frame_data(_fd)

	-- 新产生的事件
	deal_event_frame_data(_fd)

	--技能数据
	deal_skill_frame_data(_fd)

	--活动数据
	deal_activity_frame_data(_fd)

	-- 特殊 激光能量值变化(一定要放到技能处理之后)
	deal_laser_frame_data(_fd)


	-- 特殊 激光能量值变化(一定要放到技能处理之后)
	deal_fish_out_pool_frame_data(_fd)

	-- 同步服务器时间戳
	_fd.time = os.time()

	-- 活动时间记录
	player_focus_time = _fd.time

	check_broke()

	--活动开始处理 最后处理 (下一帧才开始管活动的子弹)
	deal_activity_start_frame_data(_fd)

	-- 当前钱的绝对量
	deal_assets_frame_data(_fd)

end


local function update()
	
	if s_info then
		PROTECT.update_player_focus_change()
	end

end




local function new_game()
	s_info.fish_data = {}
	s_info.new_fish_data = {}
	s_info.event_data = {}
	s_info.activity_data = {}
	s_info.activity_data_cache = {}
	s_info.bullet_data = {}
	s_info.skill_data = {}

	s_info.special_fish_award_data = {}

	s_info.bullet_free_ids = {}
	s_info.ywdj_data = {}

	s_info.fishery_begin_time = 0

	has_broke = false

	FIP.load_fish_game_data()

	bullet_free_num = 255
	-- 空闲的子弹
	for i=1,bullet_free_num do
		s_info.bullet_free_ids[i] = true
	end

end


local function init_game()
	s_info.status="wait_ready"

end

function PROTECT.join_room(_data)
	--加入房间
	_data.is_robot = s_info.is_robot

	local return_data = nodefunc.call(s_info.room_id,"join",s_info.t_num,DATA.my_id,_data)
	if return_data=="CALL_FAIL" or return_data ~= 0 then
		skynet.fail(string.format("join_game_room error:call return %s",tostring(return_data)))
		return false
	end
	return true
end

function PROTECT.ready(_data)

	new_game()

	send_room_service("ready")

	player_focus_time = os.time()

end


local next_frame_data_time = 0
local function frame_data_time_limit()
	
	if next_frame_data_time > skynet.now() then
		return 1008
	end

	next_frame_data_time = next_frame_data_time + frame_data_time_dt

	return 0
end

function REQUEST.nor_fishing_nor_frame_data_test(self)

	local ret = frame_data_time_limit()

	if ret ~= 0 then
		return_msg.result=ret
		return return_msg
	end

	if act_flag or not s_info or s_info.status~="gaming" then
		return_msg.result=1002
		return return_msg
	end

	-- if not self.data or type(self.data)~="string" then
	-- 	return_msg.result=1001
	-- 	return return_msg
	-- end

	local frame_data = fish_lib.frame_data_unpack(self.data)

	if not frame_data then
		return_msg.result=1001
		return return_msg
	end

	deal_frame_data(frame_data)

	local ret_data = fish_lib.frame_data_pack(frame_data)

	return {
		result = 0,
		data = ret_data,
	}
end


-- 玩家是否正在活动中
function FIP.is_in_activity(_seat_num)
	
	for k,v in pairs(s_info.activity_data) do
		if v.seat_num == _seat_num then
			return v.msg_type
		end
	end

	return false

end


function CMD.nor_fishing_nor_join_msg(_info,_my_join_return)

	if _info and _info.id~=DATA.my_id then
		if all_data.m_PROTECT and all_data.m_PROTECT.player_join_msg then
			all_data.m_PROTECT.player_join_msg(_info)
		end
	else

		s_info.seat_num=_my_join_return.seat_num

		s_info.skill_status = _my_join_return.skill_status or {}
		s_info.frozen_time_data = _my_join_return.frozen_time_data

		s_info.gun_id_config = _my_join_return.gun_id_config
		s_info.gun_rate_config = _my_join_return.gun_rate_config

		s_info.fish_config = _my_join_return.fish_config

		init_config()

		if all_data.m_PROTECT and all_data.m_PROTECT.my_join_return then
			all_data.m_PROTECT.my_join_return(_my_join_return)
		end

		if _my_join_return.chat_room_id then
			DATA.chat_room_id=_my_join_return.chat_room_id
			skynet.call(DATA.service_config.chat_service,"lua","join_room", DATA.chat_room_id,DATA.my_id,PUBLIC.get_gate_link())
		end

	end
end


-- 鱼组
function CMD.nor_fishing_nor_fish_group_come_msg(_data)

	if not s_info then
		return
	end
	
	add_fish_group(_data)

end


-- 清场
function CMD.nor_fishing_nor_fish_boom_come_msg(_data)

	if not s_info then
		return
	end

	s_info.fish_data = {}
	s_info.new_fish_data = {}

	local et = os.time() - math.floor(s_info.fishery_begin_time*0.1)

	s_info.fishery_begin_time = _data.begin_time
	s_info.fish_map_id = _data.fish_map_id
	s_info.frozen_time_data = {}

	for id,bd in pairs(s_info.bullet_data) do
		bd.time = bd.time - et
	end

	s_info.event_data[#s_info.event_data+1] = {
		msg_type = "fish_boom",
		value = s_info.fish_map_id,
	}

end


-- 鱼死了
function CMD.nor_fishing_nor_fish_dead_msg(_dead_fish)
	
	if not s_info then
		return
	end
	
	for i,_fish_id in ipairs(_dead_fish) do
		s_info.fish_data[_fish_id] = nil
		s_info.new_fish_data[_fish_id] = nil
	end

end


function CMD.nor_fishing_nor_game_begin_msg(_data)
	
	s_info.status = "gaming"

	s_info.fishery_begin_time = _data.begin_time
	s_info.fish_map_id = _data.fish_map_id

	add_fish_group(_data.fish_data)

end


-- 退钱
function PROTECT.return_bullet_money()
	
	for id,bd in pairs(s_info.bullet_data) do
		if bd.seat_num == 1 then
			local stake = s_info.bullet_config[bd.index]
			
			all_data.m_PROTECT.modify_score(0,"return_bullet",bd.index,bd.jing_bi,bd.fish_coin)
			FIP.statistics_fish_assets_data("return_bullet",stake,bd.jing_bi,bd.fish_coin)

			s_info.bullet_data[id] = nil
			bullet_data_num = bullet_data_num - 1
			s_info.bullet_free_ids[id] = true
			bullet_free_num = bullet_free_num + 1
		end
	end

end

-- 删除某个座位的子弹
function PROTECT.delete_bullet(seat_num)

	for id,bd in pairs(s_info.bullet_data) do
		if bd.seat_num == seat_num then
			s_info.bullet_data[id] = nil
			bullet_data_num = bullet_data_num - 1
			s_info.bullet_free_ids[id] = true
			bullet_free_num = bullet_free_num + 1
		end
	end

end


function PROTECT.quit_room()
	
	PROTECT.return_bullet_money()

	call_room_service("player_leave",s_info.seat_num)

end

function PROTECT.get_status_info()

	if s_info and s_info.status == "gaming" then

		local fishery_data = {}

		-- 子弹
		local shoot = {}
		local cur_time = os.time()
		for id,d in pairs(s_info.bullet_data) do
			if cur_time - math.floor(s_info.fishery_begin_time*0.1) - d.time > 1000 then

				s_info.bullet_free_ids[id] = true
				bullet_free_num = bullet_free_num + 1

				s_info.bullet_data[id] = nil
				bullet_data_num = bullet_data_num - 1

				local rate = 1
				if d.activity_id then
					bullet_activity_deal(d.activity_id,0)
					local ad = s_info.activity_data[d.activity_id]
					if ad and ad.gain_num then
						rate = ad.gain_num
					end
				end

				FIP.add_kongpao_fj(d.seat_num,d.index,d.stake*rate)

			else
				shoot[#shoot+1] = d
			end
		end
		
		fish_data_to_frame_data(s_info.fish_data,fishery_data)
		s_info.new_fish_data = {}

		-- 事件清空
		s_info.event_data = {}

		-- 活动
		deal_activity_all_info(fishery_data)

		deal_assets_frame_data(fishery_data)
		
		fishery_data.shoot = shoot

		fishery_data.time = os.time()
		
		local pfd = fish_lib.frame_data_pack(fishery_data)
		
		ss = {}
		for seat_num,skill_status in pairs(s_info.skill_status) do
			for skill,sd in pairs(skill_status) do
				local dcd = sd.cd - os.time()
				if dcd > 0 then
					ss[#ss+1] = 
					{
						skill = skill,
						seat_num = seat_num,
						time = dcd,
					}
				end
			end
		end

		-- 特殊技能 激光加入
		for i=1,4 do
			
			ss[#ss+1] = 
			{
				skill = "laser",
				seat_num = i,
				time = math.floor(s_info.laser_data[i].value),
			}

		end

		-- 特殊技能 核弹加入
		for i=1,4 do
			
			ss[#ss+1] = 
			{
				skill = "missile",
				seat_num = i,
				time = math.floor(s_info.missile_data[i].value),
			}

		end

		return {
			barbette_id = s_info.fishery_barbette_id,
			begin_time = math.floor(s_info.fishery_begin_time*0.1),
			fishery_data = pfd,
			skill_status = ss,
			fish_map_id = s_info.fish_map_id,
			skill_cfg = s_info.skill_cfg,
		}

	end

	return nil
end



-- 判断玩家是否正在玩游戏 后台和断线不算
function PROTECT.update_player_focus_change()

	if player_focus_time > 0 then

		local dt = os.time() - player_focus_time

		if dt > player_focus_dt then

			if player_focus_status == 1 then
				send_room_service("player_update_focus",0)
			end
			
			player_focus_status = 0


		else

			if player_focus_status == 0 then
				send_room_service("player_update_focus",1)
			end
			
			player_focus_status = 1

		end

	end

end




function PROTECT.init_base_info(_config)

	s_info.room_id=_config.room_id
	s_info.t_num=_config.t_num

	--总玩家数
	s_info.player_count=_config.player_count or 4

	-- 返奖池
	s_info.player_reward_pool = {0,0,0,0}

end

function PROTECT.free()
	if update_timer then
		update_timer:stop()
		update_timer=nil
	end

	activity_force_reward()
	
	special_fish_force_reward()

	FIP.save_fish_game_data()

	all_data=nil
	act_flag=false
	s_info=nil

end

function PROTECT.init(_all_data)
	PROTECT.free()
	
	all_data=_all_data

	all_data.game_data={}

	s_info=all_data.game_data

	if not basefunc.chk_player_is_real(DATA.my_id) then
		s_info.is_robot=true
	end

	init_game()

	PROTECT.init_base_info(all_data.base_info)

	update_timer=skynet.timer(dt,update)

	my_game_name=_all_data.game_type

end



function CMD.debug_test_create_fish(c_count)
    local nor_fish={
    	{1	,	1,},
		{2	,	1,},
		{3	,	2,},
		{4	,	2,},
		{5	,	3,},
		{6	,	3,},
		{7	,	1,},
		{8	,	1,},
		{9	,	2,},
		{10	,	2,},
		{11	,	3,},
		{12	,	4,},
		{13	,	5,},
		{14	,	6,},
		{15	,	7,},
		{16	,	8,},
		{17	,	9,},
		{18	,	4,},
		{19	,	5,},
		{20	,	6,},
		{21	,	7,},
		{22	,	8,},
		{23	,	9,},
		{24	,	10,},
		{25	,	11,},
		{26	,	12,},
		{27	,	90,},
		{28	,	14,},
		{29	,	15,},
		{30	,	16,},
		{31	,	17,},
		{32	,	18,},
		{33	,	19,},
		{34	,	20,},
		{35	,	21,},
		{36	,	22,},
		{37	,	23,},
		{38	,	24,},
		{39	,	25,},
		{40	,	26,},
		{41	,	27,},
		{42	,	28,},
		{43	,	29,},
		{44	,	30,},
		{45	,	31,},
		{46	,	32,},
		{47	,	33,},
		{48	,	34,},
		{49	,	35,},
		{50	,	36,},
		{51	,	37,},
		{52	,	38,},
		{53	,	39,},
		{54	,	40,},
		{55	,	41,},
		{56	,	42,},
		{57	,	43,},
		{58	,	44,},
		{59	,	45,},
		{60	,	46,},
		{61	,	47,},
		{62	,	48,},
		{63	,	49,},
		{64	,	50,},
		{65	,	51,},
		{66	,	52,},
		{67	,	53,},
		{68	,	54,},
		{69	,	55,},
		{70	,	56,},
		{71	,	57,},
		{72	,	58,},
		{73	,	59,},
		{74	,	60,},
		{75	,	61,},
		{76	,	62,},
		{77	,	63,},
		{78	,	64,},
		{79	,	65,},
		{80	,	66,},
		{81	,	67,},
		{82	,	68,},
		{83	,	69,},
		{84	,	70,},
		{85	,	71,},
		{86	,	72,},
		{87	,	73,},
		{88	,	74,},
		{89	,	75,},
		{90	,	76,},
		{91	,	77,},
		{92	,	78,},
		{93	,	79,},
		{94	,	80,},
		{95	,	81,},
		{96	,	82,},
		{97	,	83,},
		{98	,	84,},
		{99	,	85,},
		{100	,	86,},
		{101	,	87,},
		{102	,	88,},
		{103	,	89,},
		{104	,	90,},
		{105	,	91,},
		{106	,	92,},
		{107	,	93,},
		{108	,	94,},
		{109	,	95,},
		{110	,	96,},
		{111	,	97,},
		{112	,	98,},
		{113	,	99,},
		{114	,	100,},
		{115	,	101,},
	}


	-- local paichu=
 --  	{
	-- 	[21	]=true,
	-- 	[22	]=true,
	-- 	[23	]=true,
	-- 	[24	]=true,
	-- 	[25	]=true,
	-- 	[26	]=true,
	-- 	[27	]=true,
	-- 	[28	]=true,
	-- 	[29	]=true,
	-- 	[30	]=true,
	-- 	[31	]=true,
	-- 	[32	]=true,
	-- 	[33	]=true,
	-- 	[34	]=true,
	-- 	[35	]=true,
	-- 	[36	]=true,
	-- 	[37	]=true,
	-- 	[38	]=true,
	-- 	[39	]=true,
	-- 	[40	]=true,
	-- 	[41	]=true,
	-- 	[42	]=true,
	-- 	[43	]=true,
	-- 	[44	]=true,
	-- 	[45	]=true,
	-- 	[46	]=true,
	-- 	[47	]=true,
	-- 	[48	]=true,
	-- 	[49	]=true,
	-- 	[50	]=true,
	-- 	[51	]=true,
	-- 	[52	]=true,
	-- 	[53	]=true,
	-- 	[54	]=true,
	-- 	[55	]=true,
	-- 	[56	]=true,
	-- 	[57	]=true,
	-- 	[58	]=true,
	-- 	[59	]=true,
	-- 	[60	]=true,
	-- 	[61	]=true,
	-- 	[62	]=true,
	-- 	[63	]=true,
	-- 	[64	]=true,
	-- 	[65	]=true,
	-- 	[66	]=true,
	-- 	[67	]=true,
	-- 	[68	]=true,
	-- 	[69	]=true,
	-- 	[70	]=true,
	-- 	[71	]=true,
	-- 	[72	]=true,
	-- 	[73	]=true,
	-- 	[74	]=true,
	-- 	[75	]=true,
	-- 	[76	]=true,
	-- 	[77	]=true,
	-- 	[78	]=true,
	-- 	[79	]=true,
	-- 	[80	]=true,
	-- 	[81	]=true,
	-- 	[82	]=true,
	-- 	[83	]=true,
	-- 	[84	]=true,
	-- 	[85	]=true,
	-- 	[86	]=true,
	-- 	[87	]=true,
	-- 	[88	]=true,
	-- 	[89	]=true,
	-- 	[90	]=true,
	-- 	[91	]=true,
	-- 	[92	]=true,
	-- 	[93	]=true,
	-- 	[94	]=true,
	-- 	[95	]=true,
	-- 	[96	]=true,
	-- 	[97	]=true,
	-- 	[98	]=true,
	-- 	[99	]=true,
	-- 	[100	]=true,
	-- 	[101	]=true,
	-- }
	-- local paichu_shandian=
	-- {
	-- 	[43	]=true,
	-- 	[44	]=true,
	-- 	[45	]=true,
	-- 	[46	]=true,
	-- 	[47	]=true,
	-- 	[48	]=true,
	-- 	[49	]=true,
	-- 	[50	]=true,
	-- 	[51	]=true,
	-- 	[52	]=true,
	-- 	[53	]=true,
	-- 	[54	]=true,
	-- 	[55	]=true,
	-- 	[56	]=true,
	-- 	[57	]=true,
	-- 	[58	]=true,
	-- 	[59	]=true,
	-- 	[60	]=true,
	-- 	[61	]=true,
	-- 	[62	]=true,
	-- 	[63	]=true,
	-- 	[64	]=true,
	-- 	[65	]=true,
	-- 	[66	]=true,
	-- 	[67	]=true,
	-- 	[68	]=true,
	-- 	[69	]=true,
	-- 	[70	]=true,
	-- 	[71	]=true,
	-- 	[72	]=true,
	-- 	[73	]=true,
	-- 	[74	]=true,
	-- 	[75	]=true,
	-- 	[76	]=true,
	-- 	[77	]=true,
	-- 	[78	]=true,
	-- 	[79	]=true,
	-- 	[80	]=true,
	-- 	[81	]=true,
	-- 	[82	]=true,
	-- 	[83	]=true,
	-- 	[84	]=true,
	-- 	[85	]=true,
	-- 	[86	]=true,
	-- 	[87	]=true,
	-- 	[88	]=true,
	-- 	[89	]=true,
	-- 	[90	]=true,
	-- 	[91	]=true,
	-- 	[92	]=true,
	-- 	[93	]=true,
	-- 	[94	]=true,
	-- 	[95	]=true,
	-- 	[96	]=true,
	-- 	[97	]=true,
	-- 	[98	]=true,
	-- 	[99	]=true,
	-- 	[100]=true,
	-- 	[101]=true,
	-- }

	-- local new_nor_fish={}
	-- for i=1,#nor_fish do
	-- 	if  paichu[nor_fish[i][2]] and  paichu_shandian[nor_fish[i][2]] then
	-- 	-- if paichu_shandian[nor_fish[i][2]] then
	-- 		new_nor_fish[#new_nor_fish+1]=nor_fish[i]
	-- 	end
	-- end
	-- nor_fish=new_nor_fish


	-- local nor_fish={
 --    	{1	,	1,},
	-- 	{2	,	1,},
	-- 	{3	,	2,},
	-- 	{4	,	2,},
	-- 	{5	,	3,},
	-- 	{6	,	3,},
	-- 	{7	,	1,},
	-- 	{8	,	1,},
	-- 	{9	,	2,},
	-- 	{10	,	2,},
	-- 	{11	,	3,},
	-- 	{12	,	4,},
	-- 	{13	,	5,},
	-- 	{14	,	6,},
	-- }
	-- local big_fish={
	-- 	{24	,	10,},
	-- 	{25	,	11,},
	-- 	{26	,	12,},
	-- 	{27	,	90,},
	-- 	{28	,	14,},
	-- 	{29	,	15,},
	-- 	{30	,	16,},
	-- }
	local gansidui_fish=
	{
		{116	,	4,9,4,},
		{117	,	5,8,5,},
		{118	,	6,7,6,},
		{119	,	7,8,7,},
		{120	,	8,10,8,},
		{121	,	4,8,4,},
	}
	local ywdj_fish=
	{
		{122	,	5,8,11},
		{123	,	6,9,10},
		{124	,	7,10,8},
		{125	,	8,10,7},
		{126	,	4,5,9},
		{127	,	4,5,8,10},
		{128	,	4,5,10,8},
	}

	local now_time=os.time()
	local fish_id=1
	local fish_crowd_id=1
	local group_id=1
	local create_fish=function (create_type)
		local _data={}

		if 	create_type==1 then
			local pos =math.random(1,#nor_fish)
			_data[1]={
					id = fish_id,
					fish_group_id = nor_fish[pos][1],
					group_type = create_type,
					fish_crowd_id = fish_crowd_id,
					type = nor_fish[pos][2],
					path = 1,
					time = now_time,
					lifetime = 10000000,
					speed =50,
				}
			fish_crowd_id=fish_crowd_id+1
			fish_id=fish_id+1
		-- if 	create_type==1 then
		-- 	if math.random(1,100)<88 then
		-- 		local pos =math.random(1,#nor_fish)
		-- 		_data[1]={
		-- 				id = fish_id,
		-- 				fish_group_id = nor_fish[pos][1],
		-- 				group_type = create_type,
		-- 				fish_crowd_id = fish_crowd_id,
		-- 				type = nor_fish[pos][2],
		-- 				path = 1,
		-- 				time = now_time,
		-- 				lifetime = 10000000,
		-- 				speed =50,
		-- 			}
		-- 	else
		-- 		local pos =math.random(1,#big_fish)
		-- 		_data[1]={
		-- 				id = fish_id,
		-- 				fish_group_id = big_fish[pos][1],
		-- 				group_type = create_type,
		-- 				fish_crowd_id = fish_crowd_id,
		-- 				type = big_fish[pos][2],
		-- 				path = 1,
		-- 				time = now_time,
		-- 				lifetime = 10000000,
		-- 				speed =50,
		-- 			}
		-- 	end
		-- 	fish_crowd_id=fish_crowd_id+1
		-- 	fish_id=fish_id+1
		elseif create_type==2 then
			local pos =math.random(1,#gansidui_fish)
			
			local types = {}
			for i=2,#gansidui_fish[pos] do
				types[#types+1] = gansidui_fish[pos][i]
			end
			_data[#_data+1]={
						id = fish_id,
						fish_group_id = gansidui_fish[pos][1],
						group_type = create_type,
						fish_crowd_id = fish_crowd_id,
						types = types,
						path = 1,
						time = now_time,
						lifetime = 10000000,
						speed =50,
					}
				fish_crowd_id=fish_crowd_id+1
				fish_id=fish_id+1


		elseif create_type==3 then
			local pos =math.random(1,#ywdj_fish)
			for i=2,#ywdj_fish[pos] do
				_data[#_data+1]={
						id = fish_id,
						fish_group_id = ywdj_fish[pos][1],
						group_type = create_type,
						fish_crowd_id = fish_crowd_id,
						type = ywdj_fish[pos][i],
						group_id=group_id,
						path = 1,
						time = now_time,
						lifetime = 10000000,
						speed =50,
					}
				fish_crowd_id=fish_crowd_id+1
				fish_id=fish_id+1
			end
			group_id=group_id+1
		end
		CMD.nor_fishing_nor_fish_group_come_msg(_data)
	end


	local fish_crowd_id=0
	fish_crowd_id = fish_crowd_id + 1
	 for i=1,c_count do
	 	local create_type=1
	 	local gl=math.random(1,100)
	 	if gl<10 then
	 		create_type=2
	 	elseif gl<20 then
	 		create_type=3
	 	end
		create_fish(create_type)
	end
	dump(#all_data.game_data.fish_data,"xxxxxxxxtest fish_data")
	
	return 0

end
    --发射子弹
    -- shoot = 
    -- {
    --     [1]={
    --         id = 212,       1 ~ 255
    --         index = 3,      1 ~ 255
    --         seat_num = 1,   1 ~ 4
    --         x = 152,        1 ~ 65535
    --         y = 622,        1 ~ 65535
    --         time = 123,     1 ~ 65535
    --     },
    -- }

    -- --子弹碰撞
    -- boom = 
    -- {
    --     [1]={
    --         id = 211,               1 ~ 255
    --         fish_ids = {23,542},   1 ~ 65535
    --         data = {1,48}         特殊鱼死后引起其他鱼的总倍数
    --         money = 652314,     这波鱼的奖励总和
    --     },
    -- }
function CMD.debug_test_shoot_fish(c_count)
	local len=#s_info.fish_data
	local function get_fish_pos(not_hash)
		local pos=math.random(1,len)
		if not s_info.fish_data[pos] or (not_hash and not_hash[pos]) then
			for _pos=pos+1,len do
				-- print("xxxxx")
				if s_info.fish_data[_pos] and (not not_hash or not not_hash[_pos]) then
					return _pos
				end
			end
			for _pos=1,pos do
				if s_info.fish_data[_pos] and (not not_hash or not not_hash[_pos]) then
					return _pos
				end
			end
			dump(s_info.fish_data)
			CMD.debug_get_fish_money()
			error("get_fish_pos not have fish!!!!!!!!!!")
		end
		return pos



		-- for pos,v in pairs(s_info.fish_data) do
		-- 	if not not_hash or not not_hash[pos] then
		-- 		return pos
		-- 	end
		-- end
		
	end
	local function get_shoot_fish(list,count)
		local hash={}
		while count>0 do
			local pos=get_fish_pos(hash)
			list[#list+1]=pos
			hash[pos]=true
			count=count-1
		end
	end

	local function deal_other_data(_data)
			if _data and _data.data then
				local o_data=_data.data
				-- if next(o_data) then
				-- 	dump(o_data,"special****")
				-- end
				local pos=1
				local fish_pos=1
				while pos<=#o_data do
					if o_data[pos]==4 or o_data[pos]==5 then
						local boom_data={}
						boom_data.id=_data.fish_ids[fish_pos]
						boom_data.fish_ids={}
						local count=math.random(1,3)
						get_shoot_fish(boom_data.fish_ids,count)
						local data={}
						data.fish_explode={boom_data}
						deal_fish_explode_frame_data(data)
						for key,value in pairs(data.fish_explode) do
							deal_other_data(value)
						end
					end
					if o_data[pos]==5 or o_data[pos]==7 or o_data[pos]==8 then
						pos=pos+2
					else
						pos=pos+1 
					end
					fish_pos=fish_pos+1
				end

			end
			-- body
		end

	local all_clock=0
	local t2=os.clock()	
	for i=1,c_count do
		if i%10000==0 then
			print("shuliang  ",i)
		end
		local data={}
		data.shoot={
			{
				   id = 0,     
	               index = 1, 
	               seat_num = 1,
		            x = 1,       
		            y = 6,       
	            	time = 1,
	        }
		}
		deal_bullet_frame_data(data)
		data.boom={
				{
				   id = data.shoot[1].id,  
				   fish_ids={},
	        }
		}
		local count=math.random(1,3)
		
		get_shoot_fish(data.boom[1].fish_ids,count)
		-- dump(data.boom[1].fish_ids,"xuanyu********")
		-- local t1=os.clock()
		deal_boom_frame_data(data)
		-- all_clock=all_clock+os.clock()-t1
		for key,value in pairs(data.boom) do
			deal_other_data(value)
		end

		deal_activity_frame_data(data)
		

	end
	dump(s_info.special_fish_award_data,"xxxxxxxxx")
	local die_count=0
	for i=1,len do
		if not s_info.fish_data[i] then
			die_count=die_count+1
		end
	end
	print("*******die_count  ",die_count,all_clock,os.clock()-t2)

end


return PROTECT















