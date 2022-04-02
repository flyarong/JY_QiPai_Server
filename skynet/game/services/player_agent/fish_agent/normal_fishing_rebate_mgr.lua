--- 鱼的返奖控制

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

local buyu_gl_counter_lib = require "player_agent/fish_agent/buyu_gl_counter_lib"

---- 鱼死亡标记,key = 鱼的数据列表id , value = true/false
DATA.fish_dead_tag = {}

local FIP = base.fish_interface_protect

---- 获取所有一网打尽的鱼
function FIP.get_all_ywdj_fish( ywdj_group_id , _fish_data_ptr )
	local fish_vec = {}
	for fish_id , data in pairs(_fish_data_ptr) do
		if data.group_id and data.group_id == ywdj_group_id then
			fish_vec[#fish_vec+1] = fish_id
		end
	end

	return fish_vec
end

---- 判断一个鱼是否携带活动
-- 有的话返回活动id，没有返回nil
function FIP.get_fish_act(use_fish_id)
	if not use_fish_id then
		return nil
	end
	local s_info = DATA.fish_game_data.game_data
	local fish_config = s_info.fish_config

	if fish_config and fish_config.use_fish and fish_config.use_fish[use_fish_id] then
		local use_fish_config = fish_config.use_fish[use_fish_id]

		return use_fish_config.act_id
	end

	return nil
end

--- 找到一个活动类型的数据
function FIP.get_activity_data( _act_type , _seat_num )
	local s_info = DATA.fish_game_data.game_data

	for ai,ad in pairs(s_info.activity_data) do
		if ad.msg_type == _act_type 
			and ad.seat_num == _seat_num then
			
				return ad
		end
	end

	return nil
end


----- 处理打贝壳
function FIP.deal_hit_shell(valid_shell_vec , bullet_data , rate_factor)
	local dead_shell = {}

	--print("xxx-----------------------------deal_hit_shell ！！！")
	--dump(valid_shell_vec , "xxx---------------------------valid_shell_vec:")

	local s_info = DATA.fish_game_data.game_data

	------------------- 处理打贝壳 --------------------------------------
	for key,data in pairs(valid_shell_vec) do
		local shell_bullet_data = basefunc.deepcopy( bullet_data )
		shell_bullet_data.index = data.bullet_index
		shell_bullet_data.stake = s_info.bullet_config[data.bullet_index]

		local real_gailv = 1 / (data.rate * shell_bullet_data.fanbei_factor) * rate_factor
		local hit_data = { gailv = real_gailv  }

		local is_dead = FIP.base_hit_one_fish( shell_bullet_data , hit_data )

		--print("xxx-------------deal_hit_shell___real_gailv:" , real_gailv)
		--print("xxx-------------deal_hit_shell___is_dead:" , is_dead)


		if is_dead then
			local should_award = data.rate * shell_bullet_data.fanbei_factor * shell_bullet_data.stake

			local shell_act_data = FIP.get_activity_data( "shell_lottery" , shell_bullet_data.seat_num )
			--dump(shell_act_data , "xxx-------------deal_hit_shell___shell_act_data:")
			if shell_act_data and shell_act_data.shell_list and shell_act_data.shell_list[data.shell_index] then
				---- 还有几个贝壳存活
				local live_shell_num = 0
				for key,is_live in pairs(shell_act_data.shell_list) do
					if is_live == 1 then
						live_shell_num = live_shell_num + 1
					end
				end

				if shell_act_data.shell_list[data.shell_index] == 1 then

					local extra_rate = 0
					if live_shell_num == 1 then
						extra_rate = shell_act_data.award_value
					else
						--print("----------live_shell_num , shell_act_data.award_value : " , live_shell_num , shell_act_data.award_value )

						local first_range = math.floor( 0.5 * (1/live_shell_num) * shell_act_data.award_value )
						local end_range = math.max(first_range , math.floor( 2 * (1/live_shell_num) * shell_act_data.award_value ) )

						extra_rate = math.random( first_range , end_range)
					end

					should_award = should_award + extra_rate * shell_bullet_data.fanbei_factor * shell_bullet_data.stake

					shell_act_data.award_value = math.max( 0 , shell_act_data.award_value - extra_rate )

					dead_shell[data.shell_index] = dead_shell[data.shell_index] or {}
					dead_shell[data.shell_index].money = should_award
					shell_act_data.shell_list[data.shell_index] = 0

				else
					---- 加入缓存
					FIP.add_yuDie_fj( shell_bullet_data.seat_num , shell_bullet_data.index  , should_award )
				end
			else
				---- 加入缓存
				FIP.add_yuDie_fj( shell_bullet_data.seat_num , shell_bullet_data.index  , should_award )
			end
		end

	end

	return dead_shell
end


---------------------------------------------------------------------------------------------------
---- 处理一颗子弹打中一群鱼
function FIP.deal_one_bullet_hit_fishs_with_rebate(_bullet_data , _fishs , _shells , _bullet_tag)
	local s_info = DATA.fish_game_data.game_data

	---- 拿到有效的鱼的数量
	local valid_fish_num = 0
	local valid_fish_vec = {}
	for key,fish_id in pairs(_fishs) do
		--- 如果有数据，就可以打
		if s_info.fish_data and s_info.fish_data[fish_id] and not s_info.fish_data[fish_id].is_dead then
			valid_fish_vec[fish_id] = s_info.fish_data[fish_id]
			valid_fish_num = valid_fish_num + 1
		end
	end

	---- 拿到有效的贝壳数量
	--local valid_shell_num = 0
	local valid_shell_vec = {}

	if _shells and next(_shells) then
		local shell_act_data = FIP.get_activity_data( "shell_lottery" , _bullet_data.seat_num )
		if shell_act_data then
			for s_key,data in pairs(_shells) do

				for index,is_live in ipairs(shell_act_data.shell_list) do
					if data.shell_id == index then
						if is_live == 1 then
							valid_shell_vec[#valid_shell_vec + 1] = {shell_index = data.shell_id , bullet_index = shell_act_data.bullet_index , rate = shell_act_data.hit_rate }
							valid_fish_num = valid_fish_num + 1
						end
						break
					end
				end
			end
		end 
	end


	---- 如果普通打的空弹加入返奖
	if _bullet_tag == "nor_hit" and valid_fish_num == 0 then
		local bullet_fanbei = 1

		---- 空蛋返奖的时候判断是否是活动子弹
		if _bullet_data.activity_type == "power_bullet" or _bullet_data.activity_type == "crit_bullet" then
			local act_data = FIP.get_activity_data( _bullet_data.activity_type , _bullet_data.seat_num )
			if act_data and act_data.gain_num then
				bullet_fanbei = act_data.gain_num
			end
		end

		----- 空蛋返奖
		FIP.add_kongpao_fj(_bullet_data.seat_num, _bullet_data.index , _bullet_data.stake * bullet_fanbei )
	end

	--- 子弹的数据
	local bullet_data = { fanbei_factor = 1 , resolve_num = valid_fish_num , bullet_tag = _bullet_tag }
	basefunc.merge( _bullet_data , bullet_data )


	--- 鱼的数据
	local fishs_data = {}

	------------------- 各种活动的数据 ---------------------------
	local should_hit_num = 1
	--- 免费时刻... , 免费子弹我不减
	if _bullet_data.activity_type == "free_bullet" then
		local act_data = FIP.get_activity_data( _bullet_data.activity_type , _bullet_data.seat_num )
		if act_data then
			bullet_data.index = act_data.bullet_index
			bullet_data.stake = s_info.bullet_config[act_data.bullet_index]
		end
		-- print("------------------free_bullet")
	end

	--- 暴击子弹 ，一颗子弹打n次
	if _bullet_data.activity_type == "power" then
		local act_data = FIP.get_activity_data( _bullet_data.activity_type , _bullet_data.seat_num )
		if act_data and act_data.total_num and act_data.total_num > 0 and act_data.gain_num then
			bullet_data.index = act_data.bullet_index
			bullet_data.stake = s_info.bullet_config[act_data.bullet_index]

			local add_hit_num = act_data.total_num >= act_data.gain_num - 1 and act_data.gain_num - 1 or act_data.total_num

			should_hit_num = should_hit_num + add_hit_num 

			act_data.total_num = act_data.total_num - add_hit_num
		end
	end

	--- 暴击子弹 ，一颗子弹打n次
	if _bullet_data.activity_type == "power_bullet" then
		local act_data = FIP.get_activity_data( _bullet_data.activity_type , _bullet_data.seat_num )

		act_data.gain_num = act_data.gain_num or 2

		if act_data and act_data.gain_num then
			bullet_data.index = act_data.bullet_index
			bullet_data.stake = s_info.bullet_config[act_data.bullet_index]

			should_hit_num = should_hit_num + act_data.gain_num - 1

			-- print("------------------power_bullet")
		end
	end

	--- 双倍时刻 ，抬高鱼的倍数，使命中率降低，返奖翻倍
	if _bullet_data.activity_type == "crit" then
		local act_data = FIP.get_activity_data( _bullet_data.activity_type , _bullet_data.seat_num )
		if act_data then
			bullet_data.index = act_data.bullet_index
			bullet_data.stake = s_info.bullet_config[act_data.bullet_index]
			
			bullet_data.fanbei_factor = act_data.gain_num

			if act_data.total_num and act_data.total_num > 0 and act_data.gain_num then
				
				local add_hit_num = act_data.total_num >= act_data.gain_num - 1 and act_data.gain_num - 1 or act_data.total_num

				should_hit_num = should_hit_num + add_hit_num 

				act_data.total_num = act_data.total_num - add_hit_num
			end
		end
	end

	--- 双倍时刻 ，一颗子弹打n次
	if _bullet_data.activity_type == "crit_bullet" then
		local act_data = FIP.get_activity_data( _bullet_data.activity_type , _bullet_data.seat_num )

		act_data.gain_num = act_data.gain_num or 2

		if act_data and act_data.gain_num then
			bullet_data.index = act_data.bullet_index
			bullet_data.stake = s_info.bullet_config[act_data.bullet_index]

			bullet_data.fanbei_factor = act_data.gain_num

			should_hit_num = should_hit_num + act_data.gain_num - 1

			-- print("------------------crit_bullet")
		end
	end

	local wave_data = s_info.wave_data[_bullet_data.seat_num][_bullet_data.index]
	local rate_factor = FIP.get_real_gl_and_storeFj(_bullet_data.seat_num , wave_data , _bullet_data.index , s_info)


	
	----- 所有的鱼数据
	for fish_id,data in pairs(valid_fish_vec) do

		local rate = 1
		if s_info.fish_data[fish_id].group_type == 1 then
			rate = s_info.fish_config.use_fish[ s_info.fish_data[fish_id].type].rate
		elseif s_info.fish_data[fish_id].group_type == 2 or s_info.fish_data[fish_id].group_type == 3 then
			rate = s_info.fish_config.group[ s_info.fish_data[fish_id].fish_group_id ].rate
		end
		
		-- {
		-- 	all_times = 10,     --总次数
		-- 	cur_times = 1,      --当前次数
		-- 	store_value = 100,  --被存储下的值
		-- 	is_zheng = 1,    --当前波动是正还是负值
		-- 	bd_factor = 0.1,	--当前的波动系数
		-- }

		
		-- print("xxxxxxx-----------rate zucheng: ", s_info.fish_data[fish_id].fish_group_id ,rate , bullet_data.fanbei_factor , rate_factor)

		local real_gailv = 1 / (rate * bullet_data.fanbei_factor) * rate_factor

		fishs_data[fish_id] = { gailv = real_gailv , fish_group_id = s_info.fish_data[fish_id].fish_group_id }
	end

	------------------- 处理打贝壳 --------------------------------------
	local dead_shell = {}
	if valid_shell_vec and next(valid_shell_vec) then
		for key = 1,should_hit_num do
			local dead_shell_item = FIP.deal_hit_shell(valid_shell_vec , bullet_data , rate_factor)
			basefunc.merge( dead_shell_item , dead_shell )
		end
	end
	------------------- 循环打鱼
	local ret = {
		dead_fish = {},
		dead_shell = dead_shell,
	}
	if next(fishs_data) then
		for key = 1,should_hit_num do
			local ret_item = FIP.one_bullet_hit_fishs_with_rebate( bullet_data , fishs_data , s_info.fish_data , s_info.fish_config , s_info.seat_num )
			
			basefunc.merge( ret_item.dead_fish , ret.dead_fish )

		end
	end
	
	return ret
end

---- 一颗子弹打中一群鱼 并 计算返奖
function FIP.one_bullet_hit_fishs_with_rebate( _bullet_data , _hit_fishs_data , _fish_data_ptr , _fish_config , my_seat_num )

	local ret = 
	{
		dead_fish = {},
	}


	--- 打所有的鱼
	for fish_id,data in pairs(_hit_fishs_data) do

		--- 这条鱼是否死亡
		local is_fish_dead = FIP.base_hit_one_fish( _bullet_data , data )
		
		

		--if is_fish_dead ~= is_real_dead then
		--	print( "------------------- fanjiang_and_huishou__is_real_dead " , _bullet_data.seat_num ,_fish_data_ptr[fish_id].fish_group_id )
		--end 

		--if is_fish_dead then
			--- 如果这条鱼已经死了,,加奖池
			if is_fish_dead and _fish_data_ptr[fish_id] and _fish_data_ptr[fish_id].is_dead then
				---- 只处理玩家的 加奖池
				--if _bullet_data.seat_num == my_seat_num then
					local should_award = FIP.get_fish_dead_should_award_value( _fish_data_ptr[fish_id] , "real" , _bullet_data , _fish_data_ptr , _fish_config )
					---
					FIP.add_yuDie_fj( _bullet_data.seat_num , _bullet_data.index  , should_award )
				--end

			elseif _fish_data_ptr[fish_id] and not _fish_data_ptr[fish_id].is_dead then
				------- 真的打死 ------
				local is_real_dead,act_vec = FIP.fanjiang_and_huishou(_bullet_data.seat_num, _bullet_data , fish_id  , is_fish_dead )
				--- 如果有附加的活动数据
				if is_real_dead and act_vec and next(act_vec) then
					ret.dead_fish[fish_id] = ret.dead_fish[fish_id] or {}

					ret.dead_fish[fish_id].act_data = ret.dead_fish[fish_id].act_data or {}

					local act_data = ret.dead_fish[fish_id].act_data
					for key,act_id in pairs(act_vec) do
						act_data[#act_data + 1] = act_id
					end
				end 


				if is_real_dead then
					FIP.real_hit_dead_fish(fish_id , _bullet_data , _fish_data_ptr , _fish_config , ret)
				end

			end
		--end

	end


	return ret
end

-------------------------------------------------------------------------------

--- 真的打死了一条鱼
function FIP.real_hit_dead_fish(fish_id , _bullet_data , _fish_data_ptr , _fish_config , ret)
	---- 处理渔场数据里面的其他鱼
	local should_dead_fishs = FIP.get_should_dead_fish( _fish_data_ptr[fish_id] , _fish_data_ptr)
	for key , _fish_id in ipairs(should_dead_fishs) do
		-- local old_fish_data = basefunc.deepcopy(_fish_data_ptr[_fish_id])

		local rate = FIP.get_one_fish_rate( _fish_data_ptr[_fish_id] , _fish_config , "base")

		ret.dead_fish = ret.dead_fish or {}
		ret.dead_fish[_fish_id] = ret.dead_fish[_fish_id] or {}
		ret.dead_fish[_fish_id].money = (ret.dead_fish[_fish_id].money or 0) + rate * _bullet_data.fanbei_factor * _bullet_data.stake
		
		FIP.deal_one_fish_dead( _fish_data_ptr[_fish_id] ,_fish_config , ret.dead_fish )


	end
end

---- 获取一条鱼死了之后应该得到的奖励值、
function FIP.get_fish_dead_should_award_value(fish_data , award_type , _bullet_data , _fish_data_ptr , _fish_config )
	local should_dead_fishs = FIP.get_should_dead_fish( fish_data , _fish_data_ptr)
	local award_money = 0
	for key , _fish_id in ipairs(should_dead_fishs) do

		local base_rate = FIP.get_one_fish_rate( _fish_data_ptr[_fish_id] , _fish_config , "base")

		local real_rate = base_rate
		if award_type == "real" then
			real_rate = FIP.get_one_fish_rate( _fish_data_ptr[_fish_id] , _fish_config , "real")
		end

		award_money = award_money + base_rate * _bullet_data.fanbei_factor * _bullet_data.stake + (real_rate - base_rate) * _bullet_data.stake
	end
	return award_money
end

---- 获取应该打死的鱼
function FIP.get_should_dead_fish(fish_data , _fish_data_ptr)
	local ret = {}
	if fish_data.group_type then
		if fish_data.group_type == 1 then
			--- 单鱼
			ret[#ret + 1] = fish_data.id
		elseif fish_data.group_type == 2 then
			--- 敢死队
			ret[#ret + 1] = fish_data.id
		elseif fish_data.group_type == 3 then
			--- 一网打尽
			-- 找到所有的相同组的，处理掉
			local all_fish_vec = FIP.get_all_ywdj_fish( fish_data.group_id , _fish_data_ptr )
			for key,fish_id in ipairs(all_fish_vec) do
				ret[#ret + 1] = fish_id
			end
		end
	end

	return ret
end


---- 获得一条鱼死亡的倍数
function FIP.get_one_fish_rate(fish_data , _fish_config , _rate_type )
	local rate_type = _rate_type or "base"
	local rate = 0
	if not fish_data or not _fish_config then
		return rate
	end

	local function deal_one(use_fish_id)
		local use_fish_cfg = _fish_config.use_fish[ use_fish_id ]
		if use_fish_cfg then
			if rate_type == "real" then
				rate = rate + use_fish_cfg.rate
			elseif rate_type == "base" then
				--- 基础鱼倍数
				local base_fish_cfg = _fish_config.base_fish[ use_fish_cfg.base_id ]
				if base_fish_cfg then
					rate = rate + base_fish_cfg.rate
				end
			end
		end
	end

	if fish_data.type then
		deal_one(fish_data.type )
	elseif fish_data.types then
		for key,id in pairs(fish_data.types) do
			deal_one( id )
		end
	end

	return rate
end

--- 处理一条鱼死亡
function FIP.deal_one_fish_dead(fish_data , _fish_config , dead_fish )
	fish_data.is_dead = true

	---- 加到死亡列表中
	dead_fish[fish_data.id] = dead_fish[fish_data.id] or {}
	dead_fish[fish_data.id].act_data = dead_fish[fish_data.id].act_data or {}
	local dead_fish_data = dead_fish[fish_data.id].act_data

	local function deal_one_use_fish( use_fish_id , dead_fish_data )
		local use_fish_cfg = _fish_config.use_fish[ use_fish_id ]
		if use_fish_cfg then
			if use_fish_cfg.act_id then
				dead_fish_data[#dead_fish_data + 1] = use_fish_cfg.act_id 
			end
		end
	end

	--- 只有一条鱼
	if fish_data.type then
		deal_one_use_fish( fish_data.type , dead_fish_data )
		if #dead_fish_data == 0 then
			dead_fish[fish_data.id].act_data = nil
		end
	---- 有多条鱼
	elseif fish_data.types then
		for key,id in pairs(fish_data.types) do
			deal_one_use_fish( id , dead_fish_data )
		end
		if #dead_fish_data == 0 then
			dead_fish[fish_data.id].act_data = nil
		end

	end

	return rate
end



function FIP.bullet_lv_to_stake(pao_lv)
  local s_info = DATA.fish_game_data.game_data
  local stake = s_info.bullet_config[pao_lv]
  return stake
end

function FIP.bullet_stake_to_lv(_stake)
  local s_info = DATA.fish_game_data.game_data
  for k,v in pairs(s_info.bullet_config) do
    if v == _stake then
      return k
    end
  end
end
------------------------------------------------------------------------- 基础打鱼函数 ----------------------------------------------------------

--------- 打一条鱼
--[[
	bullet_data = { 
		seat_num ,           --- 座位号
		stake = x,           --- 底分
		fanbei_factor = n ,  --- 翻倍系数
		resolve_num = x ,    --- 稀释次数
		bullet_type = ..,    --- 子弹类型( normal,free_bullet , power 暴击 , crit 双倍 )
	}
	fish_data = { 
		fish_group_id = xx
		gailv = xx,
	}
]]
function FIP.base_hit_one_fish( bullet_data , fish_data )
	local s_info = DATA.fish_game_data.game_data
	---- 检查一下
	if not bullet_data.resolve_num then
		print( string.format( "error------------------------ not bullet_data.resolve_num" ) )
		return
	end
	if not fish_data.gailv then
		print(string.format( "error---------------not fish_data.gailv") )
		return
	end

	-- print("xxxx--base_hit_one_fish------------------fish_shoot_gailv:" , fish_data.gailv , bullet_data.resolve_num , bullet_data.bullet_tag , fish_data.fish_group_id)

	local fish_shoot_gailv = fish_data.gailv * 100000
	local real_fish_shoot_gailv = fish_shoot_gailv / bullet_data.resolve_num
	
	-- print("xxxx--base_hit_one_fish------------------real_fish_shoot_gailv:" , real_fish_shoot_gailv)

	local rand = math.random(1,100000)

	if rand <= real_fish_shoot_gailv then
		--- 打死
		return true 
	else
		--- 未打死
		return false
	end

	return false
end

-------------------------------------------------------- 返奖处理 -------------------------------------------------------------------------------------------------
--返奖值处理
--[[
	buyu_fj_data[_seat_num]={
	--按场次记录
		--真实的实际存储奖励
		real_all_fj
		real_laser_bc
		
		--具体的返奖额根据具体的炮等级来记录	
		pao_lv[]
				{
					all_fj--总返奖  = store_fj+xyBuDy_fj
					store_fj	--存储返奖
					xyBuDy_fj  --小鱼补大鱼返奖
					laser_bc_fj  --激光补偿
				}
		--
		dayu_fj[pao_lv]
		act_fj[pao_lv]		
	}
	--捕鱼最近一段时间的获奖情况  用于判断之前的时间是否处于高潮或者低谷
	buyu_huojiang_data[pao_lv]=
	{
		yu_die_list={} 鱼死亡list
		time  --记录时间
		activity_list={}  活动list
		pay_list={}  --付出的list
		get_list={}	--获得的list
		pay_all_value	付出的价值
		get_all_value  获得的价值

	}
--]]


function FIP.get_real_gl_and_storeFj(_seat_num , wave_data ,pao_lv,s_info)
	local gl=buyu_gl_counter_lib.get_real_gl(_seat_num,s_info.fish_config.profit[pao_lv] , false , wave_data , s_info.fish_config.wave[pao_lv],s_info.fish_config.random_wave )

	local storage=s_info.fish_config.profit[pao_lv].storage
	local laser=s_info.fish_config.laser[pao_lv].per_storage
	storage=storage-laser
	local stake=FIP.bullet_lv_to_stake(pao_lv)
	storage=storage* stake
	laser=laser* stake
	FIP.add_store_fj(_seat_num,pao_lv,storage)
	FIP.add_laser_fj(_seat_num,pao_lv,laser,1)

	return gl
end
--添加存储返奖
function FIP.add_store_fj(_seat_num,pao_lv,value)
	FIP.ensure_fj_value_is_safe(_seat_num,pao_lv)
	local s_info=DATA.fish_game_data.game_data
	local data= s_info.buyu_fj_data[_seat_num]
	if value>0 and data.pao_lv[pao_lv].store_fj>FIP.bullet_lv_to_stake(pao_lv)*s_info.by_storefj_max then
		FIP.add_xyBuDy_fj(_seat_num,pao_lv,value)
		return 
	end
	data.real_all_fj=data.real_all_fj+value
	data.pao_lv[pao_lv].all_fj=data.pao_lv[pao_lv].all_fj+value

	data.pao_lv[pao_lv].store_fj=data.pao_lv[pao_lv].store_fj+value

end
--添加小鱼补大鱼返奖
function FIP.add_xyBuDy_fj(_seat_num,pao_lv,value)
	FIP.ensure_fj_value_is_safe(_seat_num,pao_lv)
	local data= DATA.fish_game_data.game_data.buyu_fj_data[_seat_num]

	data.real_all_fj=data.real_all_fj+value
	data.pao_lv[pao_lv].all_fj=data.pao_lv[pao_lv].all_fj+value

	data.pao_lv[pao_lv].xyBuDy_fj=data.pao_lv[pao_lv].xyBuDy_fj+value
end
-- type =1 普通激光存储值  2 激光补偿值
function FIP.add_laser_fj(_seat_num,pao_lv,value,_type)
	local s_info = DATA.fish_game_data.game_data
	FIP.ensure_fj_value_is_safe(_seat_num,pao_lv)
	local data= DATA.fish_game_data.game_data.buyu_fj_data[_seat_num]
	_type=_type or 1
	if _type==1 then
		local s_info = DATA.fish_game_data.game_data
		-- 增加激光进度值
		local old = s_info.laser_data[_seat_num].value
		local stake = s_info.fish_config.gun[pao_lv].level
		local fcl = s_info.fish_config.laser[pao_lv]
		local laser_max_value = (fcl.value*stake)
		if old<laser_max_value then
			local ldv = s_info.laser_data[_seat_num].value + value
			if ldv>laser_max_value then
				local other=ldv-laser_max_value
				FIP.add_store_fj(_seat_num,pao_lv,other)
				ldv=laser_max_value
			end
			s_info.laser_data[_seat_num].value =ldv
			if s_info.laser_data[_seat_num].value ~= old then
				s_info.laser_data[_seat_num].change = true
			end
		else
			FIP.add_store_fj(_seat_num,pao_lv,value)
		end

		return true
	else
		local stake=FIP.bullet_lv_to_stake(pao_lv)
		--激光补偿最多存储*的价值
		if value<0 or data.real_laser_bc+value<=stake*s_info.by_laser_bc_max then
			data.real_laser_bc=data.real_laser_bc+value
			data.pao_lv[pao_lv].laser_bc_fj=data.pao_lv[pao_lv].laser_bc_fj+value
			return true
		end
	end
	return false
end


--鱼死亡等未发放存储
function FIP.add_yuDie_fj(_seat_num,pao_lv,value)
	
	local data= DATA.fish_game_data.game_data.buyu_fj_data[_seat_num]
	local store_v=value*0.4
	local xyBuDy_v=value*0.4
	local laser_bc_v=value-store_v-xyBuDy_v
	if not FIP.add_laser_fj(_seat_num,pao_lv,laser_bc_v,2) then
		local v1=laser_bc_v/2
		local v2=laser_bc_v-v1
		store_v=store_v+v1
		xyBuDy_v=xyBuDy_v+v1
	end

	FIP.add_xyBuDy_fj(_seat_num,pao_lv,xyBuDy_v)
	FIP.add_store_fj(_seat_num,pao_lv,store_v)

end
--活动未使用完奖励
local add_activity_fjcount=0
function FIP.add_activity_fj(_seat_num,pao_lv,value)
	local data= DATA.fish_game_data.game_data.buyu_fj_data[_seat_num]
	local store_v=value*0.8

	local laser_bc_v=value-store_v
	if not FIP.add_laser_fj(_seat_num,pao_lv,laser_bc_v,2) then
		store_v=store_v+laser_bc_v
	end
	FIP.add_store_fj(_seat_num,pao_lv,store_v)
end

--确保返奖价值安全
function FIP.ensure_fj_value_is_safe(_seat_num,pao_lv)

	local data= DATA.fish_game_data.game_data.buyu_fj_data[_seat_num]
	data.real_all_fj=data.real_all_fj or 0
	data.pao_lv = data.pao_lv or {}
	data.pao_lv[pao_lv]=data.pao_lv[pao_lv] or {all_fj=0,
													store_fj=0,
													xyBuDy_fj=0,
													laser_bc_fj=0,
												}
	if data.pao_lv[pao_lv].all_fj>data.real_all_fj then
		data.pao_lv[pao_lv].all_fj=data.real_all_fj
		data.pao_lv[pao_lv].store_fj=data.real_all_fj/2
		data.pao_lv[pao_lv].xyBuDy_fj=data.real_all_fj-data.pao_lv[pao_lv].store_fj
		
	elseif data.pao_lv[pao_lv].all_fj<data.real_all_fj	then
		local tongbu=true
		for i=pao_lv+1,10 do
			if data.pao_lv[i] and data.pao_lv[i].all_fj==data.real_all_fj then
				tongbu=false
				break
			end
		end
		if tongbu then
			data.pao_lv[pao_lv].all_fj=data.real_all_fj
			data.pao_lv[pao_lv].store_fj=data.real_all_fj/2
			data.pao_lv[pao_lv].xyBuDy_fj=data.real_all_fj-data.pao_lv[pao_lv].store_fj

		end
	end
	if data.pao_lv[pao_lv].laser_bc_fj>data.real_laser_bc then
		data.pao_lv[pao_lv].laser_bc_fj=data.real_laser_bc
		
	elseif data.pao_lv[pao_lv].laser_bc_fj<data.real_laser_bc	then
		local tongbu=true
		for i=pao_lv+1,10 do
			if data.pao_lv[i] and data.pao_lv[i].laser_bc_fj==data.real_laser_bc then
				tongbu=false
				break
			end
		end
		if tongbu then
			data.pao_lv[pao_lv].laser_bc_fj=data.real_laser_bc
		end
	end							 

end
--检查返奖是否达到最大值
function FIP.check_fj_ismax(_seat_num,pao_lv)
	local data= DATA.fish_game_data.game_data.buyu_fj_data[_seat_num]
	if data.pao_lv and data.pao_lv[pao_lv] and data.pao_lv[pao_lv].all_fj>= FIP.bullet_lv_to_stake(pao_lv)*300 then
		return true
	end
	return false
end
 
--检查是否需要小鱼补大鱼   传过来的fish_id必须是死了的
--[[
	返回 ：
		是否真的死亡
--]]

local act_fanjiang_count=0
local dayu_fanjiang_count=0
function FIP.check_is_need_xyBuDy(_seat_num,pao_lv,fish_id)
	local s_info = DATA.fish_game_data.game_data
	local fish_data = s_info.fish_data[ fish_id ]
	local fish_rate = FIP.get_one_fish_rate(fish_data , s_info.fish_config , "real")
	if fish_rate <= s_info.by_xyhuishou_rate_limit then
		local gl=skynet.getcfg_2number("by_xyBudy_probability") or 15
		if math.random(1,100)<=gl then
			return true
		end
	end
	return false
end
function FIP.get_act_fanjiang(_seat_num,pao_lv,fish_id)

	

	if skynet.getcfg("by_act_fanjiang_close") then
		return nil
	end

	local test_var = skynet.getcfg_2number("by_act_fanjiang_value") or 63
	-- 鱼本身不能携带活动 并且不能是 敢死队 一网打尽  鱼要大于等于20倍 
	local s_info = DATA.fish_game_data.game_data
	local fish_data = s_info.fish_data[ fish_id ]
	local fish_value= FIP.get_one_fish_rate(fish_data , s_info.fish_config , "base")
	if fish_value>=20 and fish_data.group_type==1 and not FIP.get_fish_act(fish_data.type) then
		FIP.ensure_fj_value_is_safe(_seat_num,pao_lv)
		local data= DATA.fish_game_data.game_data.buyu_fj_data[_seat_num]
		local s_value=data.pao_lv[pao_lv].store_fj
		local stake=FIP.bullet_lv_to_stake(pao_lv)
		
		if s_value>=test_var*stake then
			local act_type = {}
			if math.random(1,100)<100 and not FIP.is_in_activity(_seat_num) then
				act_type[#act_type + 1]=math.random(1,3)
			else
				if math.random(1,100)<70 then
					act_type[#act_type + 1]=8
				else
					act_type[#act_type + 1]=9
				end
			end
			FIP.add_store_fj(_seat_num,pao_lv,-test_var*stake)

			return act_type

		end
	end
	return nil
end
--real_award  这条鱼死后实际的价值
function FIP.get_dayu_fanjiang(_seat_num,pao_lv,fish_id,real_award)
	if skynet.getcfg("by_dayu_fanjiang_close") then
		return nil
	end
	local s_info = DATA.fish_game_data.game_data
	FIP.ensure_fj_value_is_safe(_seat_num,pao_lv)
	local stake=FIP.bullet_lv_to_stake(pao_lv)
	local data= s_info.buyu_fj_data[_seat_num]
	local s_value=data.pao_lv[pao_lv].xyBuDy_fj


	data.dayu_fj=data.dayu_fj or {}
	if not data.dayu_fj[pao_lv] then
		data.dayu_fj[pao_lv]=math.random(6,10)*10
	end
	if s_value>=200*stake then
		data.dayu_fj[pao_lv]=200
	elseif s_value>=140*stake then
		data.dayu_fj[pao_lv]=140
	elseif s_value>=100*stake then
		data.dayu_fj[pao_lv]=100
	end


	local dayufj_value=data.dayu_fj[pao_lv]*stake
	if s_value>dayufj_value then
		if real_award<=dayufj_value and (real_award>=dayufj_value-20*stake or real_award>=80*stake) then
			FIP.add_xyBuDy_fj(_seat_num,pao_lv,-real_award)
			data.dayu_fj[pao_lv]=math.random(6,10)*10
			return true
		end
	end
	return false
end

function FIP.fanjiang_and_huishou(_seat_num,bullet_data,fish_id,is_die )
	local s_info = DATA.fish_game_data.game_data
	--一网打尽的鱼不做处理
	if not s_info.fish_data[ fish_id ] or s_info.fish_data[ fish_id ].group_type==3 or s_info.fish_data[ fish_id ].group_type==2 then
		return is_die
	end

	local is_real_dead = is_die
	local fish_rate = FIP.get_one_fish_rate( s_info.fish_data[ fish_id ] , s_info.fish_config , "real")
	local act
	if is_die and fish_rate <= s_info.by_xyhuishou_rate_limit then
		local is_shouhui = FIP.check_is_need_xyBuDy(_seat_num, bullet_data.index ,fish_id)
		if is_shouhui then
			local should_award_value = FIP.get_fish_dead_should_award_value( s_info.fish_data[ fish_id ] , "real" , bullet_data , s_info.fish_data , s_info.fish_config )
			FIP.add_xyBuDy_fj(_seat_num,bullet_data.index,should_award_value)
			is_real_dead = false
		else
			is_real_dead = true
		end

	elseif is_die then
		act=FIP.get_act_fanjiang(_seat_num,bullet_data.index,fish_id)
	elseif not is_die then
		local should_award_value = FIP.get_fish_dead_should_award_value( s_info.fish_data[ fish_id ] , "real" , bullet_data , s_info.fish_data , s_info.fish_config )
		is_real_dead=FIP.get_dayu_fanjiang(_seat_num, bullet_data.index ,fish_id,should_award_value)
				
	end


	return is_real_dead , act
end


function FIP.add_kongpao_fj(_seat_num,pao_lv,value)
	FIP.add_xyBuDy_fj(_seat_num,pao_lv,value)
end

function FIP.use_jg_bc(_seat_num,pao_lv)
	if skynet.getcfg("by_act_jg_bc_close") then
		return nil
	end
	FIP.ensure_fj_value_is_safe(_seat_num,pao_lv)
	local data= DATA.fish_game_data.game_data.buyu_fj_data[_seat_num]
	local v=data.pao_lv[pao_lv].laser_bc_fj
	local real_v=math.floor(v/FIP.bullet_lv_to_stake(pao_lv))
	v = real_v*FIP.bullet_lv_to_stake(pao_lv)
	FIP.add_laser_fj(_seat_num,pao_lv,-v,2)
	return real_v
end


---test ******************************************
	
---test ******************************************







