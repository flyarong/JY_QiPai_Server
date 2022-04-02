--
-- Author: wss
-- Date: 2018/12/6
-- Time: 
-- 说明：游戏 盈亏统计 管理器，比赛场 & 自由场

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require"printfunc"
require "normal_enum"
local monitor_lib = require "monitor_lib"


local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

--- 配置
DATA.config = {}

---- 周期统计数据 key = game_model , value = { [game_id] = {} }
DATA.cycle_statistics_data = {}

local last_change_time = 0
DATA.refresh_config_dt = 10


---- 记录间隔,秒数
DATA.record_delay = 600   -- 10  -- test

---- 下次能报警的时间
DATA.next_warning_time = os.time()

---- 每次报警间隔
DATA.warning_time_gap = 600

---- 比赛场&自由场 ，总共的我方的收益&付出
DATA.total_profit_data = { profit = 0 , loss = 0 , profit_loss = 0 }
local total_profit_data = DATA.total_profit_data
---- 分游戏id的总共的我方的收益&付出
--key = game_id 
--value = { profit = x , loss = n , profit_loss = m , last_record_time = 0 , month_profit = 0,month_loss = 0 , month_profit_loss = 0}
DATA.game_profit_data = {}
local game_profit_data = DATA.game_profit_data


--- 每个场次对应的 当前应用的 统计波形配置 , key = game_model .. "_" .. game_id   ; value = data
DATA.now_running_wave_data = {}

local wave_status = {
	up = "up",
	down = "down",
}

DATA.up_wave_start_power = 60
DATA.down_wave_start_power = 40

DATA.is_stop_trigger_out = {}

---- 信号消息分发器
DATA.events = {
	on_gain_power_change = basefunc.signal.new(),
}

local function get_game_id(game_model , game_id)
	return game_model .. "_" .. game_id
end

local function get_game_profit_data(game_id)
	game_profit_data[game_id] = game_profit_data[game_id] or { profit = 0 , loss = 0 , profit_loss = 0 , last_record_time = os.time() , 
																month_profit = 0, month_loss = 0 , month_profit_loss = 0 ,
																cycle_game_num = 0 , cycle_profit_loss = 0 , cycle_player_num = 0 , total_cycle_profit_loss = 0 , total_cycle_player_num = 0 , gain_money_power = 0}


	return game_profit_data[game_id]
end

----- 设置抽水力度，并触发信号
local function set_gain_power_and_single(game_id , now_value)
	game_profit_data[game_id] = get_game_profit_data(game_id)
	game_profit_data[game_id].gain_money_power = now_value
	if not DATA.is_stop_trigger_out or not DATA.is_stop_trigger_out[game_id] then
		print("-------------set_gain_power_and_single" ,game_id , now_value)
		local now_wave_data = DATA.now_running_wave_data[game_id]
		-- base.DATA.events.on_gain_power_change:trigger( game_id , now_value , now_wave_data and now_wave_data.wave_status or nil )

		--- 向通知中心触发消息
		skynet.send( DATA.service_config.msg_notification_center_service , "lua" , "trigger_msg" 
																				, {name = "on_gain_power_change" , send_filter = { game_id = game_id } } 
																				, now_value , now_wave_data and now_wave_data.wave_status or nil )


	end
end

local function add_or_update_data(game_id)

	skynet.send(DATA.service_config.data_service,"lua","update_or_add_game_profit" 
		,game_id
		,game_profit_data[game_id].profit
		,game_profit_data[game_id].loss
		,game_profit_data[game_id].profit_loss
		,game_profit_data[game_id].last_record_time
		,game_profit_data[game_id].month_profit
		,game_profit_data[game_id].month_loss
		,game_profit_data[game_id].month_profit_loss
		,game_profit_data[game_id].cycle_game_num
		,game_profit_data[game_id].cycle_profit_loss
		,game_profit_data[game_id].cycle_player_num
		,game_profit_data[game_id].total_cycle_profit_loss
		,game_profit_data[game_id].total_cycle_player_num
		,game_profit_data[game_id].gain_money_power
		) 

end

local function add_game_profit_statistics(game_id , last_record_time)
	local now_time = os.time()
	local last_now_time_date = os.date("*t" , last_record_time)

	game_profit_data[game_id].last_record_time = now_time
	--dump(game_profit_data[game_id] , "------------------- add_game_profit_statistics ----------------------")
	skynet.send(DATA.service_config.data_service,"lua","add_game_profit_statistics" 
				,game_id
				,game_profit_data[game_id].month_profit
				,game_profit_data[game_id].month_loss
				,game_profit_data[game_id].month_profit_loss
				,now_time
				,last_now_time_date.year
				,last_now_time_date.month
				) 
end



--- 加载配置
local function load_config(_config)
	print("--------------game_profit_manager,load_config")
	DATA.config = {}

	local is_deal_wave = {}

	if _config and _config.main then
		
		for key , data in pairs(_config.main) do
			local game_id = get_game_id(data.game_model , data.game_id)

			DATA.config[game_id] = DATA.config[game_id] or {}
			
			-- DATA.config[game_id].statistics_cycle = data.statistics_cycle
			-- DATA.config[game_id].expect_gain_jingbi = data.expect_gain_jingbi

			DATA.config[game_id].profit_statistics_percent = data.profit_statistics_percent
			DATA.config[game_id].loss_statistics_percent = data.loss_statistics_percent

			if data.wave_id and _config[data.wave_id] then
				---deal 
				if not is_deal_wave[data.wave_id] then
					is_deal_wave[data.wave_id] = true
					for key,data in pairs(_config[data.wave_id]) do
						data.loss_value = data.loss_value / 100 * data.gain_value
						data.start_gain_power = data.start_gain_power*10
						data.start_loss_power = data.start_loss_power*10
					end
				end


				DATA.config[game_id].wave_cfg = basefunc.deepcopy( _config[data.wave_id] )

				local max_up_line = 0
				local min_down_line = 999999999
				for key , data in pairs( DATA.config[game_id].wave_cfg ) do
					if data.gain_value > max_up_line then
						max_up_line = data.gain_value
					end
					if data.loss_value < min_down_line then
						min_down_line = data.loss_value
					end
				end
				------ 这个配置组中波形的 安全上下线
				-- 上下线偏移百分比
				local offset_percent = 5 
				DATA.config[game_id].safe_up_line = max_up_line + offset_percent / 100 * max_up_line
				DATA.config[game_id].safe_down_line = min_down_line + offset_percent / 100 * min_down_line
				-- 警报线
				local warning_offset_percent = 20
				DATA.config[game_id].warning_up_line = max_up_line + warning_offset_percent / 100 * max_up_line
				DATA.config[game_id].warning_down_line = min_down_line + warning_offset_percent / 100 * min_down_line
			end


		end



	end

end




---- 获得一个游戏场次的新的 波形数据 , offset 上一个波形对其开始盈亏的偏移值
local function get_game_wave(game_id )
	local offset = _offset or 0
	local data = DATA.config[game_id]
	if data then
		game_profit_data[game_id] = get_game_profit_data(game_id)
		if data.wave_cfg and type(data.wave_cfg) == "table" then
			DATA.now_running_wave_data[game_id] = basefunc.deepcopy( data.wave_cfg[ math.random( #data.wave_cfg ) ] )
			local wave_data = DATA.now_running_wave_data[game_id]

			if game_profit_data[game_id].total_cycle_profit_loss < wave_data.gain_value then
				wave_data.wave_status = wave_status.up
				wave_data.start_point = game_profit_data[game_id].total_cycle_profit_loss
				wave_data.end_point = wave_data.gain_value

				if wave_data.end_point == wave_data.start_point then
					wave_data.end_point = end_point + 1
				end

				local should_add_value = wave_data.gain_value / wave_data.gain_race_num 

				wave_data.gain_race_num = (wave_data.end_point - wave_data.start_point)/should_add_value
				wave_data.gain_race_num = math.ceil(wave_data.gain_race_num)

				--game_profit_data[game_id].gain_money_power = DATA.up_wave_start_power
				set_gain_power_and_single(game_id , wave_data.start_gain_power )
			else
				wave_data.wave_status = wave_status.down
				wave_data.start_point = game_profit_data[game_id].total_cycle_profit_loss
				wave_data.end_point = wave_data.loss_value
				wave_data.loss_race_num = wave_data.loss_race_num + wave_data.gain_race_num
				--game_profit_data[game_id].gain_money_power = DATA.down_wave_start_power
				set_gain_power_and_single(game_id , wave_data.start_loss_power )
			end
			
			----- 上升or下降 -- 统计的局数
			wave_data.statis_race_num = 0

		else
			--game_profit_data[game_id].gain_money_power = 0
			set_gain_power_and_single(game_id , 0)
			print( "error ! -------game_profit_manager --- no wave_cfg for game_id:"..game_id )
		end
	end
end

----- 初始每个场次的当前的波形已经 调整力度
local function init_game_wave_data()
	for game_id,data in pairs(DATA.config) do
		get_game_wave(game_id)
	end
end


local function init_data()
	local now_time = os.time()
	local ob_data = skynet.call(DATA.service_config.data_service,"lua","query_all_game_profit" ) 

	for game_id , data in pairs(ob_data) do
		total_profit_data.profit = total_profit_data.profit + data.total_profit
		total_profit_data.loss = total_profit_data.loss + data.total_loss
		total_profit_data.profit_loss = total_profit_data.profit_loss + data.total_profit_loss

		---- 上一次写月统计的时间
		local last_record_time = data.last_record_time

		game_profit_data[game_id] = get_game_profit_data(game_id)

		game_profit_data[game_id].profit = data.total_profit or 0
		game_profit_data[game_id].loss = data.total_loss or 0
		game_profit_data[game_id].profit_loss = data.total_profit_loss or 0
		game_profit_data[game_id].month_profit = data.month_profit or 0
		game_profit_data[game_id].month_loss = data.month_loss or 0
		game_profit_data[game_id].month_profit_loss = data.month_profit_loss or 0

		game_profit_data[game_id].last_record_time = last_record_time or now_time

		--- 周期统计的数据
		game_profit_data[game_id].cycle_game_num = data.cycle_game_num or 0
		game_profit_data[game_id].cycle_profit_loss = data.cycle_profit_loss or 0
		game_profit_data[game_id].cycle_player_num = data.cycle_player_num or 0
		game_profit_data[game_id].total_cycle_profit_loss = data.total_cycle_profit_loss or 0
		game_profit_data[game_id].total_cycle_player_num = data.total_cycle_player_num or 0
		game_profit_data[game_id].gain_money_power = data.gain_money_power or 0

		if basefunc.is_same_month( last_record_time , now_time ) then
			game_profit_data[game_id].month_profit = data.month_profit or 0
			game_profit_data[game_id].month_loss = data.month_loss or 0
			game_profit_data[game_id].month_profit_loss = data.month_profit_loss or 0
		else
			add_game_profit_statistics(game_id , last_record_time)

			game_profit_data[game_id].last_record_time = now_time
			game_profit_data[game_id].month_profit = 0
			game_profit_data[game_id].month_loss = 0
			game_profit_data[game_id].month_profit_loss = 0

			--- 立刻刷一次
			add_or_update_data(game_id)
		end

	end

end

local function deal_record()
	local now_time = os.time()
	--local now_time_date = os.date("*t",now_time)

	--- 记录
	for game_id , data in pairs(game_profit_data) do
		if not basefunc.is_same_month( data.last_record_time , now_time ) then
			add_game_profit_statistics(game_id , data.last_record_time)

			data.month_profit = 0
			data.month_loss = 0
			data.month_profit_loss = 0
			
			--- 立刻刷一次
			-- add_or_update_data(game_id)
		end

		data.last_record_time = now_time

		add_or_update_data(game_id)
	end
	
end

local function deal_record_update()
	deal_record()
	skynet.timeout( DATA.record_delay*100 ,deal_record_update )
end

---- 停机时调用
function CMD.deal_stop_service()
	deal_record()
end

---- 获取一个游戏场次的抽成力度
--[[
	game_model  游戏类型 "freestyle" | "matchstyle"
	game_id     对应游戏id
--]]
function CMD.get_game_gain_money_power(game_model , game_id)
	local game_id = get_game_id(game_model , game_id)

	----
	game_profit_data[game_id] = get_game_profit_data(game_id)

	return game_profit_data[game_id].gain_money_power
end

--- 增加 消息注册
function CMD.register_msg(_key, _target_link , _msg_name )
	local game_id = get_game_id(_target_link.game_model , _target_link.game_id)

	---- 如果没有配置，就不注册
	if not DATA.config[game_id] then
		return
	end

	DATA.events[_msg_name]:bind(_key,function( game_id ,...)
		local _game_model = _target_link.game_model
		local _game_id = _target_link.game_id
		if get_game_id(_game_model , _game_id) == game_id then
			cluster.send(_target_link.node,_target_link.addr,_target_link.cmd,...)
		end
	end)

	---- 一来注册，发送当前的力度
	local now_wave_data = DATA.now_running_wave_data[game_id]
	game_profit_data[game_id] = get_game_profit_data( game_id )
	cluster.send(_target_link.node,_target_link.addr,_target_link.cmd, game_profit_data[game_id].gain_money_power , now_wave_data and now_wave_data.wave_status or nil )
	print("----------------- game_profit_manager register_msg")

end
--- 断开 消息注册
function CMD.unregister_msg(_key, _msg_name )
	if DATA.events[_msg_name] then
		DATA.events[_msg_name]:unbind(_key)
	end
end

---- 获得一个game_id的抽水力度&抽水状态
function CMD.get_game_profit_power_data( _game_model , _game_id )
	local game_id = get_game_id( _game_model , _game_id)

	local now_wave_data = DATA.now_running_wave_data[game_id]
	game_profit_data[game_id] = get_game_profit_data( game_id )

	return game_profit_data[game_id] and game_profit_data[game_id].gain_money_power , now_wave_data and now_wave_data.wave_status or nil
end


----- 上报盈亏,profit_loss 我方的盈亏
function CMD.submit_match_profit_loss( game_form , _game_id , profit , loss , real_player_num )
	if (game_form ~= GAME_FORM.matchstyle and game_form ~= GAME_FORM.freestyle) then
		return
	end

	--
	local game_id = get_game_id(game_form , _game_id)
	
	local profit_loss = profit + loss
	
	--- 对应比赛总共的
	game_profit_data[game_id] = get_game_profit_data(game_id)
	
	---- 比赛场总共的
	if profit_loss >= 0 then
		total_profit_data.profit = total_profit_data.profit + profit_loss
		game_profit_data[game_id].profit = game_profit_data[game_id].profit + profit_loss
		game_profit_data[game_id].month_profit = game_profit_data[game_id].month_profit + profit_loss

	else
		total_profit_data.loss = total_profit_data.loss + profit_loss
		game_profit_data[game_id].loss = game_profit_data[game_id].loss + profit_loss
		game_profit_data[game_id].month_loss = game_profit_data[game_id].month_loss + profit_loss

	end
	total_profit_data.profit_loss = total_profit_data.profit_loss + profit_loss
	game_profit_data[game_id].profit_loss = game_profit_data[game_id].profit_loss + profit_loss
	game_profit_data[game_id].month_profit_loss = game_profit_data[game_id].month_profit_loss + profit_loss
	
	--------------------------------------------------------------------- 周期统计 -------------------------------------------------------------------------------
	--print("--------------------submit_match_profit_loss1:",game_form , _game_id , profit , loss , real_player_num)
	---- 比赛场的赢的钱的统计需要做处理
	if game_form == GAME_FORM.matchstyle then
		dump(DATA.config[game_id] , "----------------DATA.config[game_id]:")
		if DATA.config[game_id] and DATA.config[game_id].profit_statistics_percent and DATA.config[game_id].loss_statistics_percent then
			profit = profit * DATA.config[game_id].profit_statistics_percent / 100
			loss = loss * DATA.config[game_id].loss_statistics_percent / 100
		end
	end
	profit_loss = profit + loss


	if DATA.config and DATA.config[game_id] then

		local cycle_config = DATA.config[game_id]

		--- 统计的游戏局数+1
		game_profit_data[game_id].cycle_game_num = game_profit_data[game_id].cycle_game_num + 1
		--- 本周期的盈亏增加
		game_profit_data[game_id].cycle_profit_loss = game_profit_data[game_id].cycle_profit_loss + profit_loss
		--- 本周期的人次增加
		game_profit_data[game_id].cycle_player_num = game_profit_data[game_id].cycle_player_num + real_player_num
		--- 总共的历史盈亏增加
		game_profit_data[game_id].total_cycle_profit_loss = game_profit_data[game_id].total_cycle_profit_loss + profit_loss
		--- 总共的人次增加
		game_profit_data[game_id].total_cycle_player_num = game_profit_data[game_id].total_cycle_player_num + real_player_num

		------------------------------------------ 每局统计都要检查是否达到 波形 上下线 --------------------------------------------
		local now_wave_data = DATA.now_running_wave_data[game_id]

		local old_gain_money_power = game_profit_data[game_id].gain_money_power
		local old_wave_status = now_wave_data.wave_status

		if now_wave_data then
			now_wave_data.statis_race_num = now_wave_data.statis_race_num + 1

			local is_pass_line = false
			if now_wave_data.wave_status == wave_status.up and game_profit_data[game_id].total_cycle_profit_loss > now_wave_data.gain_value then
				--game_profit_data[game_id].gain_money_power = DATA.down_wave_start_power
				now_wave_data.wave_status = wave_status.down

				set_gain_power_and_single( game_id , now_wave_data.start_loss_power )

				now_wave_data.statis_race_num = 0
				now_wave_data.end_point = now_wave_data.loss_value
				now_wave_data.start_point = game_profit_data[game_id].total_cycle_profit_loss

				is_pass_line = true

			end

			if now_wave_data.wave_status == wave_status.down and game_profit_data[game_id].total_cycle_profit_loss < now_wave_data.loss_value then
				---- 获得新的波形
				get_game_wave(game_id)
				is_pass_line = true
			end

			--- 如果超过上下波线，就要记录并且清空
			if is_pass_line then
				---- 统计log ------
				skynet.send(DATA.service_config.data_service,"lua","add_game_profit_cycle_log" 
					,game_id
					,game_profit_data[game_id].cycle_game_num
					,game_profit_data[game_id].cycle_player_num
					,game_profit_data[game_id].cycle_profit_loss
					,game_profit_data[game_id].total_cycle_player_num
					,game_profit_data[game_id].total_cycle_profit_loss
					, game_profit_data[game_id].cycle_profit_loss / game_profit_data[game_id].cycle_player_num
					, old_wave_status or "nil"
					,old_gain_money_power
					) 
				---------------- 清空数据 ---------------------
				game_profit_data[game_id].cycle_game_num = 0
				game_profit_data[game_id].cycle_profit_loss = 0
				game_profit_data[game_id].cycle_player_num = 0
			end

			----------- 是否超过警报线 ------------------
			monitor_lib.add_data("game_profit_pass_up_line", 
				game_profit_data[game_id].total_cycle_profit_loss - DATA.config[game_id].warning_up_line ,
				game_id, warning_line , game_profit_data[game_id].total_cycle_profit_loss)
			monitor_lib.add_data("game_profit_pass_down_line",
				DATA.config[game_id].warning_down_line - game_profit_data[game_id].total_cycle_profit_loss,
				game_id, warning_line , game_profit_data[game_id].total_cycle_profit_loss )

			----------- 是否长时间未调整过来 ------------------
			if now_wave_data.wave_status == wave_status.up then
				monitor_lib.add_data("game_profit_long_time_out_ctrl", 
					now_wave_data.statis_race_num - 2*now_wave_data.gain_race_num ,
					game_id , now_wave_data.gain_race_num , now_wave_data.statis_race_num)
			elseif now_wave_data.wave_status == wave_status.down then
				monitor_lib.add_data("game_profit_long_time_out_ctrl",
					now_wave_data.statis_race_num - 2*now_wave_data.loss_race_num,
					game_id , now_wave_data.loss_race_num , now_wave_data.statis_race_num )
			end

		else
			get_game_wave(game_id)
		end

		-------------------------------------------- 如果达到统计时间 ------------------------------------------
		if now_wave_data and game_profit_data[game_id].cycle_game_num >= now_wave_data.gain_collect_gap then
			
			--- 这个小统计点应该要增长的值
			local race_num = (now_wave_data.wave_status == wave_status.up) and now_wave_data.gain_race_num or now_wave_data.loss_race_num
			---- 目标增量
			local target_add_value = (now_wave_data.end_point - now_wave_data.start_point) / (race_num/now_wave_data.gain_collect_gap)
			---- 当前增量
			local now_add_value = game_profit_data[game_id].cycle_profit_loss


			local E = game_profit_data[game_id].gain_money_power
			local factor = (now_wave_data.wave_status == wave_status.up) and 1 or -1
			local add_offset = - factor * (now_add_value - target_add_value)/target_add_value * 10

			----- 限制调整幅度
			if add_offset > 20 then
				add_offset = 20
			end
			if add_offset < -20 then
				add_offset = -20
			end

			-------------- 检查上升or下降的总进度是否达到 -----------------
			if (now_wave_data.wave_status == wave_status.up and add_offset < 0) or (now_wave_data.wave_status == wave_status.down and add_offset > 0) then
				local should_value = now_wave_data.start_point + now_wave_data.statis_race_num/now_wave_data.gain_collect_gap * target_add_value

				if (now_wave_data.wave_status == wave_status.up and game_profit_data[game_id].total_cycle_profit_loss < should_value) or
					(now_wave_data.wave_status == wave_status.down and game_profit_data[game_id].total_cycle_profit_loss > should_value) then
					add_offset = 0
				end
			end

			game_profit_data[game_id].gain_money_power = E + add_offset
			
			
			if game_profit_data[game_id].gain_money_power > 100 then
				game_profit_data[game_id].gain_money_power = 100
			end
			if game_profit_data[game_id].gain_money_power < 0 then
				game_profit_data[game_id].gain_money_power = 0
			end
			

			set_gain_power_and_single( game_id , game_profit_data[game_id].gain_money_power )

			---- 统计log ------
			skynet.send(DATA.service_config.data_service,"lua","add_game_profit_cycle_log" 
				,game_id
				,game_profit_data[game_id].cycle_game_num
				,game_profit_data[game_id].cycle_player_num
				,game_profit_data[game_id].cycle_profit_loss
				,game_profit_data[game_id].total_cycle_player_num
				,game_profit_data[game_id].total_cycle_profit_loss
				, game_profit_data[game_id].cycle_profit_loss / game_profit_data[game_id].cycle_player_num
				, old_wave_status or "nil"
				,old_gain_money_power
				) 
			---------------- 清空数据 ---------------------
			game_profit_data[game_id].cycle_game_num = 0
			game_profit_data[game_id].cycle_profit_loss = 0
			game_profit_data[game_id].cycle_player_num = 0

		end
	else
		print( string.format("------------------- error ! no game_profit config for cycle statistics! game_model:%s , game_id:%s" , game_form , _game_id) )
	end

end

---- 清空场次的盈亏,不传值的话全部清
function CMD.clear_total_profit_loss(_game_id)
	if _game_id then
		for game_id,data in pairs(game_profit_data) do
			if _game_id == game_id then
				game_profit_data[game_id].total_cycle_profit_loss = 0
			end
		end
	else
		for game_id,data in pairs(game_profit_data) do
			--game_profit_data[game_id].total_cycle_profit_loss = 0

			CMD.clear_total_profit_loss(game_id)
		end
	end
end

---- 强行设置一个场次的调整力度
function CMD.fix_set_gain_power(_game_id , value)
	if _game_id and value and game_profit_data[_game_id] then
		set_gain_power_and_single( _game_id , value )
	end
end

---- 设置一个场，重新开始调整，_game_id不传的话清空全部的
function CMD.reset_auto_ctrl(_game_id)
	if _game_id then
		game_profit_data[_game_id] = get_game_profit_data(_game_id)

		CMD.clear_total_profit_loss(_game_id)

		---------------- 清空数据 ---------------------
		game_profit_data[_game_id].cycle_game_num = 0
		game_profit_data[_game_id].cycle_profit_loss = 0
		game_profit_data[_game_id].cycle_player_num = 0

		get_game_wave(_game_id)

		add_or_update_data(game_id)
	else
		for game_id,data in pairs(game_profit_data) do
			CMD.reset_auto_ctrl(game_id)
		end
	end

end


---- 设置一个场的信号统计是否停止发出（true就是不发出） ,_game_id不传设置全部
function CMD.set_stop_game_profit_signal_out(_bool,_game_id)
	if _game_id then
		DATA.is_stop_trigger_out[_game_id] = _bool
	else
		for game_id,data in pairs(game_profit_data) do
			--DATA.is_stop_trigger_out[game_id] = _bool
			CMD.set_stop_game_profit_signal_out(_bool,game_id)
		end
	end
end

function PUBLIC.refresh_configs()
	-- 自动加载
	local config,change_time = nodefunc.get_global_config("game_profit_server")
	if change_time ~= last_change_time then
		last_change_time = change_time

		load_config(config)

	end

end

local function init()
	-- 加载配置
	--nodefunc.query_global_config("game_profit_server",load_config)

	skynet.timer( DATA.refresh_config_dt , PUBLIC.refresh_configs )
	PUBLIC.refresh_configs()
	
	init_data()

	init_game_wave_data()

	skynet.timeout( DATA.record_delay*100 ,deal_record_update )
end



function CMD.start(_service_config)
	DATA.service_config=_service_config

	base.import("game/services/game_profit_manager_service/game_profit_config.lua")

	init()
end


-- 启动服务
base.start_service()
