---  通用任务

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local task_base_func = require "task.task_base_func"

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST
local PUBLIC = base.PUBLIC

DATA.common_task_protect = {}
local task = DATA.common_task_protect


function task.gen_task_obj(config,data)
	--local other_config = skynet.call(DATA.service_config.task_center_service,"lua","get_vip_duiju_hongbao_task_config")
	local obj = {
		-- 所有配置
		config = config,
		-- 任务id
		id = config.id,
		-- 任务进度
		process = data.process,
		-- 当前要领的奖励等级
		task_round = data.task_round,

		-- 这个任务的创建时间
		create_time = data.create_time,
		-- 进度等级
		lv = nil,
		-- 当前阶段的进度
		now_lv_process = nil,
		-- 当前阶段还需要多少进度
		now_lv_need_process = nil,

		task_award_get_status = data.task_award_get_status or 0,

		process_index = nil,
		msg = {},

		--- 设置是否启用
		is_open = true,
	}

	---- 刷新配置
	obj.refresh_config = function(config)
		obj.config = config
		obj.init(true)
	end

	---- 初始化
	obj.init = function ( is_refresh_cfg )

		PUBLIC.deal_msg(obj)

		--- 监听消息
		DATA.msg_dispatcher:register( obj , obj.msg )

		if obj.reset_timecancler then
			obj.reset_timecancler()
		end

		obj.max_process , obj.max_task_round = task_base_func.get_max_process(obj.config.process_data) 

		obj.lv = 1
		obj.process_index = 1

		obj.get_lv_info() 

		--- 处理是否重置进程
		if obj.config.is_reset == 1 then
			PUBLIC.deal_reset_process( obj )   
		end

	end

	--- 重置任务
	obj.reset_task = function(pre_callback , callback)
		----------------------------
		local now_time = os.time()
		--- 任务开始的时间
		local start_valid_time = obj.config.start_valid_time or 0
		--- 当前时间距离开始时间的时间
		local dif_time = now_time - start_valid_time
		--- 距离开始时间已经过了多少天
		local dif_day = math.floor( dif_time / 86400 )
		--- 到下一个刷新点还需要的时间
		local next_refresh_time = (obj.config.reset_delay - (dif_day % obj.config.reset_delay))*86400 - dif_time % 86400

		-------------
		local create_dif_time = obj.create_time - start_valid_time
		local create_dif_day = math.floor( create_dif_time / 86400 )

		local is_same_round = true

		if math.floor(dif_day / obj.config.reset_delay) ~= math.floor(create_dif_day / obj.config.reset_delay) then
			is_same_round = false
		end


		if not is_same_round then
			if pre_callback then
				pre_callback()
			end

			obj.create_time = now_time
			obj.process = 0
			obj.lv = 1
			obj.process_index = 1
			obj.task_round = 1
			obj.task_award_get_status = 0
		    obj.get_lv_info() 	

			obj.update_data()

			if callback then
				callback()
			end
			--- 通知进度改变
			PUBLIC.deal_task_progress_change(obj)
			
			--- 触发一下，资产观察
			skynet.timeout(200 , function() 
				PUBLIC.asset_observe()
			end)
		end

		---- 下一天的timeout
		obj.reset_timecancler = basefunc.cancelable_timeout( next_refresh_time * 100 , function ()
			obj.reset_task( pre_callback , callback )
		end)
	end

	---- 设置是否启用
	obj.set_is_open = function(bool)
		--print("-----------------set_is_open:",obj.id , bool and "true" or "false")
		obj.is_open = bool
		if not bool then
			DATA.msg_dispatcher:unregister( obj )
			obj.msg = {}
		else
			PUBLIC.deal_msg(obj)
			DATA.msg_dispatcher:register( obj , obj.msg )
		end
	end

	obj.get_is_open = function()
		return obj.is_open
	end

	-- 设置不接受消息
	obj.not_accept_msg = function()
		--print("-----------------not_accept_msg:",obj.id)
		DATA.msg_dispatcher:unregister( obj )
		obj.msg = {}
	end

	---- 销毁
	obj.destory = function ()
		
		DATA.msg_dispatcher:unregister( obj )
	end

	obj.complete = function ()
	end

	obj.update_data = function() 
		if obj.id == 201 then
			print("xxxxxxxxxxxxx------------update_data:",201)
		end

		PUBLIC.update_task( obj.id , obj.process , obj.task_round , obj.create_time , obj.task_award_get_status )
	end

	--- 获得当前所处的lv等级,只适用于不能累积任务进度类型的
	obj.get_lv_info = function() 
		local now_process = obj.process - task_base_func.get_grade_total_process(obj.config.process_data , obj.lv)  
		local process_index = obj.process_index
		local now_lv_need_process = obj.config.process_data[process_index]
		assert( now_lv_need_process ~= -1 , "error now_lv_need_process ~= -1" )
		local lv = obj.lv
		while true do 
			if now_process > now_lv_need_process then
				now_process = now_process - now_lv_need_process
				lv = lv + 1
				process_index = process_index + 1
				now_lv_need_process = obj.config.process_data[process_index]

				if not now_lv_need_process then
					now_lv_need_process = 0
					break
				elseif now_lv_need_process == -1 then
					process_index = process_index - 1
					now_lv_need_process = obj.config.process_data[process_index]
				end
			else
				break
			end
		end


		obj.lv = lv
		obj.now_lv_process = now_process
		obj.now_lv_need_process = now_lv_need_process
		obj.process_index = process_index
	end

	---- 获取一个等级的具体的奖励数据
	obj.get_lv_award_data = function(award_lv)
		local award_data = {}
		if obj.config.award_data[award_lv] then
			award_data = obj.config.award_data[award_lv]
		else
			if obj.config.process_data[#obj.config.process_data] == -1 then
				award_data = obj.config.award_data[#obj.config.award_data]
			end
		end

		if award_data then

			----- 目标奖励
			if obj.config.get_award_type == "random" then
				local target_award = {}
				local total_weight = 0
				for key,data in pairs(award_data) do
					total_weight = total_weight + (data.weight or 1)
				end
				local random = math.random(total_weight)
				local now_weight = 0
				for key,data in pairs(award_data) do
					if random <= now_weight + (data.weight or 1) then
							
						target_award[#target_award + 1] = basefunc.deepcopy( data )
						break
					end
					now_weight = now_weight + (data.weight or 1)
				end

				award_data = target_award
			end


			------- 处理限时道具 -------------
			for key,data in pairs(award_data) do
				if data.lifetime then
					data.attribute = {valid_time= os.time() + data.lifetime }

					data.lifetime = nil
				end
			end
		end

		return award_data
	end

	----- 获得奖励
	obj.get_award = function (_award_progress_lv)
		----- 限制任务的有效期，非有效期可以领已经能领的，
		--[[local now_time = os.time()
		if obj.config.start_valid_time and obj.config.end_valid_time then
			if now_time < obj.config.start_valid_time or now_time > obj.config.end_valid_time then
				return 3808
			end
		end--]]
		local award_progress_lv = _award_progress_lv or obj.task_round

		---- 做验证
		if award_progress_lv > obj.lv then
			return 1003
		end
		local award_status_vec = basefunc.decode_task_award_status( obj.task_award_get_status )
		if award_status_vec[award_progress_lv] then
			return 1003
		end

		--if award_progress_lv > obj.task_round or (award_progress_lv == obj.task_round and obj.now_lv_process == obj.now_lv_need_process) then
			
			--[[local award_data = {}
			if obj.config.award_data[award_progress_lv] then
				award_data = obj.config.award_data[award_progress_lv]
			else
				if obj.config.process_data[#obj.config.process_data] == -1 then
					award_data = obj.config.award_data[#obj.config.award_data]
				end
			end--]]

			local award_data = obj.get_lv_award_data(award_progress_lv)

			if award_data then

				----- 目标奖励
				--[[if obj.config.get_award_type == "random" then
					local target_award = {}
					local total_weight = 0
					for key,data in pairs(award_data) do
						total_weight = total_weight + (data.weight or 1)
					end
					local random = math.random(total_weight)
					local now_weight = 0
					for key,data in pairs(award_data) do
						if random <= now_weight + (data.weight or 1) then
							
							target_award[#target_award + 1] = basefunc.deepcopy( data )
							break
						end
						now_weight = now_weight + (data.weight or 1)
					end

					award_data = target_award
				end


				------- 处理限时道具 -------------
				for key,data in pairs(award_data) do
					if data.lifetime then
						data.attribute = {valid_time= os.time() + data.lifetime }

						data.lifetime = nil
					end
				end--]]

				--- 找到对局红包卷奖励
				if obj.config.own_type == "step_task" then
					for key,data in pairs(award_data) do
						if data.asset_type == PLAYER_ASSET_TYPES.SHOP_GOLD_SUM then
							if DATA.now_step_get_hongbao_num >= DATA.total_step_hongbao_num then
								return 3802
							end

							DATA.now_step_get_hongbao_num = DATA.now_step_get_hongbao_num + data.value
						end
					end
				end

				local goldpig_cash_num = 0
				if obj.config.own_type == "goldpig" or obj.config.own_type == "goldpig_new" then
					for key,data in pairs(award_data) do
						if data.asset_type == PLAYER_ASSET_TYPES.CASH then
							goldpig_cash_num = goldpig_cash_num + data.value
						end
					end
				end

				obj.task_round = obj.task_round + 1

				---- 任务领奖状态更新
				
				award_status_vec[award_progress_lv] = true
				obj.task_award_get_status = basefunc.encode_task_award_status( award_status_vec )

				dump(award_status_vec , string.format("xxxx--------------------------award_status_vec: player_id:%d , task_id:%d , task_award_get_status:%d", DATA.my_id , obj.id , obj.task_award_get_status)   )

				----- 记录任务奖励日志
				for key,data in pairs(award_data) do
					PUBLIC.add_player_task_award_log( obj.id , award_progress_lv , data.asset_type , data.value or 0 )
				end

				----------- 处理发广播 -------------
				for key,data in pairs(award_data) do
					if data.broadcast_content then
						skynet.fork(function()
							skynet.timeout(300,function()
								local name = DATA.player_data.player_info.name
								if name then
									name = basefunc.short_player_name(name)
									skynet.send(DATA.service_config.broadcast_center_service,"lua",
												"fixed_broadcast","buyu_task_get_award"
												,name , obj.config.name , data.broadcast_content or "大奖")
								end
							end)
						end)
					end
				end


				obj.update_data()

				------------------ 通知客户端，状态改变 --------------------
				PUBLIC.deal_task_progress_change(obj)

				PUBLIC.deal_get_task_award(obj , goldpig_cash_num)

				---- 任务完成发出一个消息出去
				if obj.process == obj.max_process then
					--DATA.msg_dispatcher:call("task_complete", obj.id )
					PUBLIC.trigger_msg( {name = "task_complete"} , obj.id )
				end

				return award_data
			end
		--end

		return false
	end

	----- 增加进度,返回进度是否改变
	obj.add_process = function (exp)
		if obj.process == obj.max_process then
			return false
		end

		----- 限制任务的有效期
		local now_time = os.time()
		if obj.config.start_valid_time and obj.config.end_valid_time then
			if now_time < obj.config.start_valid_time or now_time > obj.config.end_valid_time then
				return false
			end
		end
		
		obj.process = obj.process + exp
		if obj.process > obj.max_process then
			exp = exp - (obj.process - obj.max_process )
			obj.process = obj.max_process
		end
		
		if obj.process == obj.max_process then
			if obj.config.own_type == "step_task" then
				--DATA.msg_dispatcher:call("stepstep_money_task_complete")
				PUBLIC.trigger_msg( {name = "stepstep_money_task_complete"} )
			end
		end

		--- 加日志
		PUBLIC.add_player_task_log(obj.id , exp , obj.process)

		obj.get_lv_info() 
		
		obj.update_data()

		------------------ 通知客户端，状态改变 --------------------
		PUBLIC.deal_task_progress_change(obj)

		--------------- 如果是金猪礼包2的金币保障任务，自动领奖。
		if obj.config.own_type == "goldpig_new2" then
			PUBLIC.get_task_award(obj.id)
		end

		return true
	end

	----- 获取这个任务应该能领的任务奖励
	obj.get_should_get_awards = function( is_change_award_status )
		local should_award = {}
		local award_status_vec = basefunc.decode_task_award_status( obj.task_award_get_status )
		for key = 1 , obj.lv do
			--- 如果这个等级没有领
			if not award_status_vec[key] then
				if key == obj.lv then
					if obj.now_lv_process < obj.now_lv_need_process then
						break
					end
				end

				local award_data = obj.get_lv_award_data(key)

				if is_change_award_status then
					award_status_vec[key] = true
					obj.task_round = obj.task_round + 1
				end

				for _,data in pairs(award_data) do
					should_award[#should_award + 1] = basefunc.deepcopy(data)
				end
			end
		end

		if is_change_award_status then
			obj.task_award_get_status = basefunc.encode_task_award_status( award_status_vec )
			obj.update_data()
		end

		return should_award
	end

	--- 直接刷新进度
	obj.update_process = function(now_process)
		obj.process = now_process
		obj.get_lv_info()
	end

	--- 获得当前进度，分子
	obj.get_now_process = function()
		local now_lv_process = obj.now_lv_process
		---- 充值类型的任务的进度为了方便客户端，返回/100的
		if obj.config.condition_type == "charge_any" then
			now_lv_process = math.ceil(now_lv_process / 100)
		end

		return now_lv_process
	end

	--- 获得当前等级需要的进度，分母
	obj.get_need_process = function()
		local now_lv_need_process = obj.now_lv_need_process
		---- 充值类型的任务的进度为了方便客户端，返回/100的
		if obj.config.condition_type == "charge_any" then
			now_lv_need_process = math.ceil(now_lv_need_process / 100)
		end

		return now_lv_need_process
	end

	--- 获得奖励领取状态
	obj.get_award_status = function()
		if not obj.is_open then
			return DATA.award_status.not_open
		end

		--- 该领取的等级大于最大领取等级，
		if obj.task_round > obj.max_task_round then
			return DATA.award_status.complete
		end

		--# 0-不能领取 | 1-可领取 | 2-已完成
		if obj.lv == obj.task_round then
			if obj.now_lv_process == obj.now_lv_need_process then
				return DATA.award_status.can_get
			end
			return DATA.award_status.not_can_get
		elseif obj.lv > obj.task_round then
			return DATA.award_status.can_get
		elseif obj.lv < obj.task_round then
			if obj.process == obj.max_process then
				return DATA.award_status.complete
			else
				return DATA.award_status.not_can_get
			end
		end
		return DATA.award_status.not_can_get
	end


	---------------------------------------------------------------------------- ↓↓ 处理任务关心的消息 ↓↓ ------------------------------------------------------------
	--- 对局任务处理
	obj.game_compolete_task_deal = function()
		obj.msg.game_compolete_task = function(_, game_module , game_id , game_type , game_level , real_change_score , match_model , rank)
				-- dump( obj, "=------------- deal_msg,obj:" )
			if obj.config.condition_data then
				local c_data = obj.config.condition_data 
					
				if (not c_data.game_module or basefunc.compare_value( game_module , c_data.game_module.condition_value , c_data.game_module.judge_type ) )
					and (not c_data.game_id or basefunc.compare_value( game_id , c_data.game_id.condition_value , c_data.game_id.judge_type ) )
					and (not c_data.game_type or basefunc.compare_value( game_type , c_data.game_type.condition_value , c_data.game_type.judge_type ) )
				 		and (not c_data.game_level or basefunc.compare_value( game_level , c_data.game_level.condition_value , c_data.game_level.judge_type ) )
				 			and (not c_data.match_model or basefunc.compare_value( match_model , c_data.match_model.condition_value , c_data.match_model.judge_type ) )
				 				and (not c_data.rank or basefunc.compare_value( rank , c_data.rank.condition_value , c_data.rank.judge_type ) ) then
						
					 local is_attain_condition = true

					 if c_data.game_success then
					 	if (real_change_score > 0 and c_data.game_success.condition_value == 1) or (real_change_score < 0 and c_data.game_success.condition_value == 0) then

					 	else
					 		is_attain_condition = false
					 	end
					 end

					 if is_attain_condition then
						local is_add_process = obj.add_process(1)
							
					end

				end

			end
		end
	end
	--- 兑换红包处理
	obj.exchange_by_hongbao_deal = function()
		obj.msg.exchange_by_hongbao = function(_)
			local is_add_process = obj.add_process(1)
		end
	end
	--- 分享游戏处理
	obj.shared_finish_deal = function()
		obj.msg.shared_finish = function(_,share_type)
			if obj.config.condition_data then
				local c_data = obj.config.condition_data 
				if c_data.share_type then
					if c_data.share_type.condition_value == "game" then
						if share_type == "shared_friend" or share_type == "shared_timeline" then
							local is_add_process = obj.add_process(1)
								
						end
					else
						if share_type == c_data.share_type.condition_value then
							local is_add_process = obj.add_process(1)

						end
					end

				end
			end
				
		end
	end
	--- 砸金蛋累积奖励任务处理
	obj.zajindan_award_deal = function()
		obj.msg.zajindan_award = function(_, award_value )
			local is_add_process = obj.add_process(award_value)
		end
	end
	--- 捕鱼奖励任务
	obj.buyu_award_deal = function()
		obj.msg.buyu_award = function(_, award_value )
			local is_add_process = obj.add_process(award_value)

		end
	end
	--- 资产观察处理
	obj.asset_change_msg_deal = function()
		obj.msg.asset_change_msg = function(_, asset_type , change_value , now_value )
			if obj.config.condition_data then
				local c_data = obj.config.condition_data 
						
				if (not c_data.asset_type or basefunc.compare_value( asset_type , c_data.asset_type.condition_value , c_data.asset_type.judge_type ) )
					and (not c_data.change_value or basefunc.compare_value( change_value , c_data.change_value.condition_value , c_data.change_value.judge_type ) )
					 	and (not c_data.now_value or basefunc.compare_value( now_value , c_data.now_value.condition_value , c_data.now_value.judge_type ) ) then

					 ---- 条件达成
					 local is_add_process = obj.add_process(1)


				end

			end
		end
	end
	---  捕指定鱼
	obj.buyu_target_yu_deal = function()
		obj.msg.buyu_fish_dead = function(_ , fish_game_id , gun_index , use_fish_data )
			dump(use_fish_data , "xxxxxx--------------------use_fish_data:")
			dump(obj.config.condition_data , "xxxxx------------obj.config.condition_data:")
			print("xxxxxxxxxxx---------------obj.msg.buyu_fish_dead:" , fish_game_id )
			if use_fish_data and obj.config.condition_data then
				local c_data = obj.config.condition_data 
				if (not c_data.base_fish_id or basefunc.compare_value( use_fish_data.base_id , c_data.base_fish_id.condition_value , c_data.base_fish_id.judge_type ))
				    and (not c_data.fish_game_id or basefunc.compare_value( fish_game_id , c_data.fish_game_id.condition_value , c_data.fish_game_id.judge_type))
				    	and (not c_data.gun_index or basefunc.compare_value( gun_index , c_data.gun_index.condition_value , c_data.gun_index.judge_type)) then
					
					local is_add_process = obj.add_process(1)
				end

			end
		end
	end
	--- 消消乐 奖励任务
	obj.xiaoxiaole_award_deal = function()
		obj.msg.xiaoxiaole_award = function(_, award_value )
			local is_add_process = obj.add_process(award_value)

		end
	end
	--- bbsc 大步骤完成
	obj.bbsc_big_step_complete_deal = function()
		obj.msg.bbsc_big_step_complete = function(_ )
			local is_add_process = obj.add_process(1)

		end
	end

	---------------------------------------------------------------------------- ↑↑ 处理任务关心的消息 ↑↑ ---------------------------------------------------------
	return obj
end

return task