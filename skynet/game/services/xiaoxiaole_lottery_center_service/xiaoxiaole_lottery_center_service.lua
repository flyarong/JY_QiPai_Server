---- 消消乐 开奖中心 服务，

local skynet = require "skynet_plus"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "normal_enum"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

DATA.service_config = nil

---- 上次开奖的消除样式
DATA.last_xc_map_data = {}

---- 开奖消除配置
DATA.lottery_xc_map = nil

---- 概率配置
DATA.gl_config = nil

function PUBLIC.load_gl_config(raw_config)
	DATA.gl_config = raw_config

	for key,data in pairs(DATA.gl_config.base) do
		data.power = math.floor( data.power * 1000000 )
	end

	if DATA.gl_config.fanjiang_1 then
		for key,data in pairs(DATA.gl_config.fanjiang_1) do
			data.power =math.floor(  data.power * 1000000 )
		end
	end

	if DATA.gl_config.fanjiang_2 then
		for key,data in pairs(DATA.gl_config.fanjiang_2) do
			data.power = math.floor( data.power * 1000000)
		end
	end

	if DATA.gl_config.fanjiang_3 then
		for key,data in pairs(DATA.gl_config.fanjiang_3) do
			data.power = math.floor( data.power * 1000000)
		end
	end

	if DATA.gl_config.fanjiang_4 then
		for key,data in pairs(DATA.gl_config.fanjiang_4) do
			data.power = math.floor( data.power * 1000000 )
		end
	end

	if DATA.gl_config.fanjiang_5 then
		for key,data in pairs(DATA.gl_config.fanjiang_5) do
			data.power = math.floor( data.power * 1000000 )
		end
	end

end




----- 获得配置
function PUBLIC.get_gl()

	----
	local get_random_gl_data = function(gl_data)
		local total_power = 0
		for key,data in pairs(gl_data) do
			total_power = total_power + data.power
		end
		local rand = math.random(total_power)
		local now_rand = 0
		for key,data in pairs(gl_data) do
			if rand <= now_rand + data.power then
				return data.no,data
			end
			now_rand = now_rand + data.power
		end
		return 0 , nil
	end

	if DATA.gl_config then
		local target_key = 0

		target_key = get_random_gl_data(DATA.gl_config.base)

		if DATA.gl_config["fanjiang_" .. target_key] then
			local gl_config = DATA.gl_config["fanjiang_" .. target_key]
			local gl_key,gl_data = get_random_gl_data(gl_config)
			if gl_data and gl_data.rate then
				if gl_data.rate == 0 then
					--print("----------------xxxxx----- gl_data.rate == 0")
				end
				--print("----------------xxxxx----- gl_data.rate:",gl_data.rate , target_key , gl_key)
				return gl_data.rate
			else
				return 0
			end
		else
			return 0
		end
	else
		return 0
	end
	return 0
end


----- 获取4连5连的数据
function PUBLIC.deal_lian4_lian5(real_award_rate)
	local lian_data = {}
	if DATA.gl_config and DATA.gl_config.lucky_rate then
		for key,data in pairs(DATA.gl_config.lucky_rate) do
			if real_award_rate >= data.lian4_min and real_award_rate <= data.lian4_max then
				lian_data[#lian_data + 1] = { lian_type = "lian4" , locky_item = key , lian_rate = math.min( data.lian4 , data.lian4_min ) , power = data.lian4_power }
			end
			if real_award_rate >= data.lian5_min and real_award_rate <= data.lian5_max then
				lian_data[#lian_data + 1] = { lian_type = "lian5" , locky_item = key , lian_rate = math.min( data.lian5 , data.lian5_min )  , power = data.lian5_power }
			end
		end
	end

	------ 从所有满足的当中选一个
	if next(lian_data) and #lian_data > 0 then
		local random_index = math.random(#lian_data)
		local random_data = lian_data[random_index]

		---- 再按照概率计算
		local lian_random = math.random(100)
		if lian_random <= random_data.power then
			return random_data
		end

	end

	return nil
end

----- 获得一个xc_map
function PUBLIC.get_xc_map( rate )
	local award_rate = rate * 10    -- math.random(1,500)

	local xc_map_vec = nil
	local xc_map_string = nil

	if not DATA.lottery_xc_map then
		return xc_map_string,award_rate / 10
	end

	

	------ 开奖，如果没有找到先去找小一个等级的，如果实在找不到就找打一个等级的
	if not DATA.lottery_xc_map[award_rate] then
		print("xxx-------------not_lottery_xc_map:",award_rate)
		local while_dir = -1
		---- 先找更小的，找到0 再去找更大的

		local while_num = 0
		local max_while_num = 10000
		local now_key = award_rate
		while true do
			while_num = while_num + 1
			if while_num > max_while_num then 
				break
			end
			now_key = now_key + while_dir
			if DATA.lottery_xc_map[now_key] then
				xc_map_vec =  DATA.lottery_xc_map[now_key] 

				award_rate = now_key
				break
			end
			if now_key <= 0 then
				now_key = award_rate
				while_dir = 1
			end
		end
	else
		xc_map_vec =  DATA.lottery_xc_map[award_rate] 
	end

	----- 避免同一个奖励等级里面，拿到相同的消除样式
	if xc_map_vec and type(xc_map_vec) == "table" and #xc_map_vec > 0 then
		
		----- 选一个随机key
		local random_key = math.random( #xc_map_vec )

		xc_map_string = xc_map_vec[random_key]


	end

	return xc_map_string , award_rate / 10
end


----- 开奖
function CMD.lottery_kaijiang()

	local real_award_rate = PUBLIC.get_gl()

	local xc_map_str = nil      --- 最终的消除map  str
	local xc_map_rate = 0       --- 消除map对应的倍数
	local lian_locky_type = nil       --- 连消的类型
	local lian_locky_award_rate = 0   --- 连消奖励的倍数
	local locky_item = nil            --- locky要变成的元素
	---- 判断是否能达成4连or5连
	local lian45_data = PUBLIC.deal_lian4_lian5(real_award_rate)

	if lian45_data then
		local base_award_rate = math.max( 0 , real_award_rate - lian45_data.lian_rate)

		----- 获取基础的消除map
		xc_map_str , xc_map_rate = PUBLIC.get_xc_map( base_award_rate )
		if xc_map_str then
			base_award_rate = xc_map_rate
			lian_locky_award_rate = math.max( 0 , real_award_rate - base_award_rate )
			lian_locky_type = lian45_data.lian_type
			locky_item = lian45_data.locky_item
		else
			--- 没有获取到 , 就用真实开奖来获取xc_map
			xc_map_str, xc_map_rate = PUBLIC.get_xc_map( real_award_rate )
			lian_locky_type = "lian3"
		end

	else
		---- 处理3连
		xc_map_str, xc_map_rate = PUBLIC.get_xc_map( real_award_rate )

		lian_locky_type = "lian3"

	end

	local lucky_data = PUBLIC.deal_base_xc_map(xc_map_str , lian_locky_type , locky_item )	
	

	return { xc_map = xc_map_str , real_award_rate = real_award_rate , award_rate = (xc_map_rate + lian_locky_award_rate)*10
				, xc_map_rate = xc_map_rate , lian_locky_award_rate = lian_locky_award_rate , lucky_data = lucky_data }

end

------- 进一步处理获得的基础的消除map
function PUBLIC.deal_base_xc_map(xc_map_str , lian_type , locky_item )	
	------
	local lucky_data = {}

	---- 每行8个
	local hang_item_num = 8
	---- 总共多少行
	local hang_num = math.floor(#xc_map_str / hang_item_num)
	---- locky总个数
	local min_locky = math.floor(hang_num* DATA.lucky_base.max_lucky_num_min)
	local max_locky = math.floor(hang_num* DATA.lucky_base.max_lucky_num_max)
	local total_locky = math.random( min_locky , max_locky )

	if total_locky > DATA.lucky_base.max_lucky_num then
		total_locky = DATA.lucky_base.max_lucky_num
	end

	local get_lian3_lucky = function(cfg)
		local lian_num = 0

		local total_power = 0
		for key,data in pairs(cfg) do
			total_power = total_power + data.weight
		end
		local rand_power = math.random(total_power)
		local now_power = 0
		for key,data in pairs(cfg) do
			if rand_power <= now_power + data.weight then
				lian_num = data.lian_num
				break
			end
			now_power = now_power + data.weight
		end

		return lian_num
	end


	if lian_type == "lian3" then
		---- 处理三连
		local lian3_num = 0
		local true_rate = 0

		local total_power = 0
		for key,data in pairs(DATA.lian3_lucky) do
			total_power = total_power + data.weight
		end
		local rand_power = math.random(total_power)
		local now_power = 0
		for key,data in pairs(DATA.lian3_lucky) do
			if rand_power <= now_power + data.weight then
				lian3_num = data.lian3_num
				true_rate = data.true_rate
				break
			end
			now_power = now_power + data.weight
		end

		for key = 1,lian3_num do
			local is_real = math.random(100) < true_rate
			if is_real then
				--- 真三连
				local lian_num = get_lian3_lucky(DATA.lian3_real_lucky)
				lian_num = math.min( total_locky , lian_num )

				if lian_num >= 3 then
					---- do
					lucky_data[#lucky_data + 1] = { lian_type = "lian3" , real_lian_num = 3 , lian_num = lian_num }
				end
				total_locky = math.max(0, total_locky - lian_num)

			else
				--- 假三连
				local lian_num = get_lian3_lucky(DATA.lian3_fake_lucky)
				lian_num = math.min( total_locky , lian_num )

				if lian_num >= 3 then
					---- do
					lucky_data[#lucky_data + 1] = { lian_type = "lian3" , real_lian_num = 0 , lian_num = lian_num }
				elseif lian_num == 2 then
					lucky_data[#lucky_data + 1] = { lian_type = "lian2" , real_lian_num = 0 , lian_num = lian_num }
				end
				total_locky = math.max(0, total_locky - lian_num )

			end

		end


	elseif (lian_type == "lian4" or lian_type == "lian5") and locky_item then
		local lian_num = 4
		if lian_type == "lian4" then
			---- 4连也可能有5个的
			if math.random(100) < DATA.lian4_5lian_gl then
				lian_num = 5
			end
			lucky_data[#lucky_data + 1] = { lian_type = "lian4" , real_lian_num = 4 , lian_num = lian_num , lucky_item = locky_item }

		elseif lian_type == "lian5" then
			lian_num = 5
			lucky_data[#lucky_data + 1] = { lian_type = "lian5" , real_lian_num = 5 , lian_num = lian_num , lucky_item = locky_item }
		end
		total_locky = math.max(0, total_locky - lian_num )


	end

	----- 剩余的填充locky
	for key = 1 , total_locky do
		lucky_data[#lucky_data + 1] = { lian_type = "lian1" , real_lian_num = 0 , lian_num = 1 }
	end

	return lucky_data
end



function CMD.start(_service_config)
	DATA.service_config = _service_config

	base.import("game/services/xiaoxiaole_lottery_center_service/xiaoxiaole_lottery_config.lua")

	----- 载入开奖配置
	skynet.fork(function()
		DATA.lottery_xc_map = base.import("game/services/xiaoxiaole_lottery_center_service/xxl_xc_map.lua")
		print("------------------------DATA.lottery_xc_map ~ ok !!!")
	
		--[[for i = 1,1000000 do
			CMD.lottery_kaijiang()
			if i % 10 == 0 then
				print("-------------lottery_kaijiang:",i)
			end
		end--]]
	end)

	---- 动态加载配置
	nodefunc.query_global_config( "xiaoxiaole_power_cfg",PUBLIC.load_gl_config )


end


-- 启动服务
base.start_service()
