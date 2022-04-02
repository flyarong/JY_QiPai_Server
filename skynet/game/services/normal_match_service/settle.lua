--
-- Author: yy
-- Date: 2018/3/28
-- Time: 
-- 说明：比赛场服务 进行匹配和安排

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "printfunc"
require "ddz_match_enum"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

--rank排序检查频率
local refresh_rank_frequency = 3
local start_refresh_rank_time = 0

--晋级玩家列表
local promoted_players = nil

local update_game_status


--广播结果
local function broad_cast_results()

	local game_name = DATA.match_config.match_data_config.name
	local awards = DATA.match_config.broadcast

	if awards then
		for i,award in ipairs(awards) do
			local player_id = DATA.player_rank_list[i]
			if player_id then

				local name = skynet.call(DATA.service_config.data_service,"lua",
							"get_player_info",player_id,"player_info","name")
				if name then
					name = basefunc.short_player_name(name)
					skynet.send(DATA.service_config.broadcast_center_service,"lua",
								"fixed_broadcast","match_award",name,game_name,award)
				end
				
			end
		end
	end

end

--排序排名
local function sort_rank()

	--排行是脏的才排行
	if not DATA.player_rank_dirty then
		return
	end

	--去除淘汰的人再排序 排序的人比总人数多的时候处理一下
	if #DATA.player_rank_list>PUBLIC.get_match_player_num() then
		local player_rank_list={}
		for rank,player_id in ipairs(DATA.player_rank_list) do
			if DATA.player_infos[player_id].weed_out < 1 then
				player_rank_list[#player_rank_list+1]=player_id
			end
		end
		DATA.player_rank_list=player_rank_list
	end

	table.sort(DATA.player_rank_list,function (a,b)
		local a_grades,b_grades = DATA.player_infos[a].grades,DATA.player_infos[b].grades
		local a_hide_grades = DATA.player_infos[a].hide_grades
		local b_hide_grades = DATA.player_infos[b].hide_grades
		
		if a_grades == b_grades then
			return a_hide_grades > b_hide_grades
		end
		return a_grades > b_grades
	end)

	for rank,player_id in ipairs(DATA.player_rank_list) do
		
		local player_info = DATA.player_infos[player_id]
		--通知所有的客户端排名变化了
		if player_info.rank ~= rank then
			--###test
			nodefunc.send(player_id,DATA.player_msg_name.change_rank_msg,rank)
			player_info.rank = rank
		end

	end

	--###test
	print("sort rank ok , info:"..basefunc.tostring(DATA.player_rank_list,10))

	DATA.player_rank_dirty = false
	DATA.signal_rank_fresh:trigger()
end


--获取排名和奖励奖品
local function get_rank_and_award(player_id)
	
	local player_info = DATA.player_infos[player_id]
	local award_config = DATA.match_config.match_award_config
	
	local rank = player_info.weed_out

	if rank < 1 then
		rank = player_info.rank
	else
		player_info.rank = rank
	end

	local awd = {}

	if award_config and award_config[rank] then
		awd = award_config[rank]
	end

	return rank,awd
end

--比赛最终结束了
local function mathch_final_over()

	if DATA.reported_result_cmd then

		local rd = {}
		for player_id,d in pairs(DATA.player_infos) do
			local rank,aw = get_rank_and_award(player_id)
			rd[rank]={
				rank = rank,
				player_id = player_id,
				award = aw,
				score = d.grades,
				hide_score = d.hide_grades,
				revive_num = d.revive_num,
			}
		end

		--向管理者推送结果
		nodefunc.send(DATA.manager_id,DATA.reported_result_cmd,DATA.my_id,rd)

	end


	--###test
	print("settle final is over , all match game is finish")
	dump(DATA.player_infos,"final rank:")

	broad_cast_results()

	-- 记录数据
	PUBLIC.add_match_log()

	skynet.timeout(500,function ()
		--销毁房间
		for room_id,_ in pairs(DATA.room_infos) do
			nodefunc.send(room_id,"destroy")
		end

		--销毁自己
    	nodefunc.destroy(DATA.my_id)

		skynet.sleep(200)

		skynet.exit()

	end)

end

--通知晋级决赛的分数调整
local function notification_promoted_final_grades()

	local players = DATA.out_table_players
	for id,player_id in ipairs(players) do
		local player_info = DATA.player_infos[player_id]
		print("base grades:",player_info.grades)
		player_info.grades = DATA.match_config.match_data_config.init_final_score
								+math.floor(player_info.grades
									/DATA.match_config.match_data_config.final_factor)

		--发送比赛晋级分数调整
		nodefunc.send(player_id,DATA.player_msg_name.promoted_final_msg,player_info.grades)
		print("final grades:",player_info.grades)
	end

end

--通知等待复活的玩家 不用复活了 已经进入决赛了 直接进入
local function notification_free_revive(_is_wait_result)

	if DATA.revive_data and next(DATA.wait_revive_player) then

		print("notification_free_revive ----",_is_wait_result)

		for _player_id,v in pairs(DATA.wait_revive_player) do
			
			PUBLIC.revive(_player_id,_is_wait_result,true)

			nodefunc.send(_player_id,DATA.player_msg_name.free_revive_msg)

		end

		-- 配置用完了 等待结果后 再立即刷新一次
		if _is_wait_result then
			skynet.fork(function ()
				update_game_status(DATA.current_next_cfg_id)
			end)
		end

	end

end

--晋级决赛
local function promoted_final_match()

	--决赛
	DATA.cur_process_info.final_round = DATA.current_next_round
	DATA.cur_process_info.round_type = 1


	--刚刚达成决赛标志
	if not DATA.in_final_flag then
		DATA.in_final_flag = true

		--向当前所有不在桌子上的人发送晋级决赛消息
		for id,player_id in ipairs(DATA.out_table_players) do
			nodefunc.send(player_id,DATA.player_msg_name.promoted_msg,true,DATA.cur_process_info)
		end

		notification_free_revive()

		dump(DATA.out_table_players,"当前没打比赛的人推送晋级决赛的消息，包括触发标志的兄弟")
	else

		--之前就达成了
		--向才完成的人推送晋级决赛消息

		if promoted_players and #promoted_players>0 then
			for id,player_id in ipairs(promoted_players) do
				nodefunc.send(player_id,DATA.player_msg_name.promoted_msg,true,DATA.cur_process_info)
			end
		end
		dump(promoted_players,"才出来的人得到晋级决赛的消息")
		
	end

	--晋级决赛了，不会再发送普通的晋级初赛消息了
	promoted_players = nil


	--如果所有人都打完了
	local in_table_player_num=PUBLIC.get_in_table_player_num()
	if in_table_player_num < 1 then

		DATA.current_status = 2
		DATA.current_next_cfg_id = DATA.final_min_round

		DATA.in_final_flag = nil
		print("所有玩家都出来了，开始进行决赛匹配")


		--0.5s后通知决赛分数调整
		skynet.timeout(50,notification_promoted_final_grades)

		--1s开始决赛匹配
		PUBLIC.start_rematching(1)

	end

end


--排名通知玩家淘汰
local function notification_departure(_players)
	
	local weed_out_players = _players
	local function weed_out_func(_not_unbind)

		for id,player_id in ipairs(weed_out_players) do
			local info=DATA.player_infos[player_id]
			--###test
			local rank,award=get_rank_and_award(player_id)
			print("notification_departure award：",player_id,rank,award)
			nodefunc.send(player_id,DATA.player_msg_name.gameover_msg,rank,award,DATA.match_id,DATA.cur_process_info)

			-- 记录玩家比赛日志
			PUBLIC.add_match_player_log(player_id,info.grades,rank,award)
		end

		if not _not_unbind then
			DATA.signal_rank_fresh:unbind(weed_out_players)
		end
	end

	if DATA.player_rank_dirty then
		DATA.signal_rank_fresh:bind(weed_out_players,weed_out_func)
	else
		weed_out_func(true)
	end

	-- dump(_players,"notification_departure++++++"..DATA.current_next_round)

end




--通知玩家复活
local function notification_revive(_players)

	local weed_out_players = {}

	if DATA.revive_data and not DATA.in_final_flag then

		for id,player_id in ipairs(_players) do
			
			local t = DATA.player_revive_data[player_id] or 0

			if t < DATA.revive_data.num then

				DATA.wait_revive_player[player_id]=player_id

				-- 取当前进行的下一轮减一(第一轮打完这个值为2)
				local round = DATA.current_next_round
				round = math.max(round,1)
				local revive_assets = DATA.game_config[round].revive_condi

				-- dump(DATA.game_config,"DATA.game_config "..round)
				
				if revive_assets then

					nodefunc.send(player_id,DATA.player_msg_name.wait_revive_msg,
										DATA.revive_data.num,
										DATA.revive_data.time,
										round,
										revive_assets)

				else
					print("revive_assets error !!!!")
					dump(DATA.game_config,"DATA.game_config+++++++++"..round)

					-- 失败了 从 复活队列去除
					DATA.wait_revive_player[player_id] = nil

					weed_out_players[#weed_out_players+1] = player_id
				end

			else

				weed_out_players[#weed_out_players+1] = player_id

			end

		end

	else

		weed_out_players = _players

	end


	if #weed_out_players > 0 then

		for i,player_id in ipairs(weed_out_players) do
			
			local info=DATA.player_infos[player_id]

			local match_player_count=PUBLIC.get_match_player_num()

			DATA.out_match_players[#DATA.out_match_players+1]=player_id

			info.weed_out=match_player_count

		end

		notification_departure(weed_out_players)

	end

end




--通知玩家等待 【等待结果需要 从休息队列清除玩家 否则 玩家不会进行主动休息完成(卡死)】
local function notification_wait_result(_players)
	
	if _players then

		for id,player_id in ipairs(_players) do
			--发送比赛等待结果消息
			nodefunc.send(player_id,DATA.player_msg_name.wait_result_msg,DATA.cur_process_info)
		end

	end

end


--通知玩家普通的晋级
local function notification_promoted()
	
	if promoted_players and #promoted_players>0 then

		if DATA.in_final_flag then

			notification_wait_result(promoted_players)

			--从休息队列清除玩家
			for id,player_id in ipairs(promoted_players) do
				DATA.match_rest_players[player_id]=nil
			end

		else

			for id,player_id in ipairs(promoted_players) do
				--发送比赛晋级消息
				nodefunc.send(player_id,DATA.player_msg_name.promoted_msg,false,DATA.cur_process_info)
			end

		end

	end

	promoted_players = nil

end


--更新游戏进行状态
update_game_status = function (_cfg_id)

	--初赛状态
	if DATA.current_status==1 then

		--获取剩下的参赛人数
		local current_player_count = PUBLIC.get_match_player_num()
		local regular_max_round_config = DATA.game_config[DATA.final_min_round-1]

		local skip_regular = false
		if regular_max_round_config then
			if current_player_count <= regular_max_round_config.rise_num then
				skip_regular = true
			end
		end

		--人数小于等于最后一把的初赛晋级人数则 进入决赛状态
		if skip_regular then

			print("人数达到要求，等待所有人出来进军决赛:",current_player_count,regular_max_round_config.rise_num)
			
			-- 配置用完了，恰好人也达标了
			if DATA.game_limit_flag.config_is_out and not DATA.game_limit_flag.player_num_ok then

				--向当前所有不在桌子上的人发送晋级决赛消息
				promoted_players = {}
				for id,player_id in ipairs(DATA.out_table_players) do
					promoted_players[#promoted_players+1]=player_id
				end

			end

			DATA.game_limit_flag.player_num_ok = true

			promoted_final_match()

			return false

		else

			--当前打的还不是最新的轮配置 --- 直接打这个当前最新的轮配置
			--当前是不是等待晋级决赛状态
			if not DATA.in_final_flag and _cfg_id < DATA.current_next_cfg_id then
				return true
			end

			--接下来还是初赛
			while true do
			
				if DATA.current_next_cfg_id + 1 < DATA.final_min_round then
					DATA.current_next_cfg_id = DATA.current_next_cfg_id + 1
					if current_player_count > DATA.game_config[DATA.current_next_cfg_id].rise_num then
						print("skip_regular -> " .. DATA.current_next_cfg_id)
						break
					end
				else
					
					--初赛都打完了
					--如果所有人都打完了 排名 强制选出晋级和失败的人
					local in_table_player_num=PUBLIC.get_in_table_player_num()
					if in_table_player_num < 1 then
						
						sort_rank()

						local weed_out_players = {}
						promoted_players = {}

						local _players = DATA.out_table_players
						DATA.out_table_players = {}

						for id,player_id in pairs(_players) do
							
							local info=DATA.player_infos[player_id]
							local match_player_count=PUBLIC.get_match_player_num()
							local game_config = DATA.game_config[DATA.current_next_cfg_id]

							if info.rank > game_config.rise_num then
								--淘汰
								DATA.out_match_players[#DATA.out_match_players+1]=player_id
								weed_out_players[#weed_out_players+1]=player_id
								info.weed_out=match_player_count
								DATA.match_rest_players[player_id]=nil
							else
								--晋级等候下一轮
								DATA.out_table_players[#DATA.out_table_players+1]=player_id
								promoted_players[#promoted_players+1]=player_id
							end

						end

						--在刷新排名后通知淘汰的玩家
						if #weed_out_players>0 then
							notification_departure(weed_out_players)
						end

						print("regular match is use out of must to final")

						promoted_final_match()

						return false


					else

						if promoted_players then

							-- 初赛打完了，最终排名之前全部等待结果
							notification_wait_result(promoted_players)

							-- 休息的人不用休息了 开始迎接决赛
							for i,player_id in ipairs(promoted_players) do
								DATA.match_rest_players[player_id]=nil
							end

							promoted_players = nil

						end

					end
					
					notification_free_revive(true)

					DATA.game_limit_flag.config_is_out = true

					DATA.in_final_flag = true
					print("wait other player to rank promoted to final")
					return false

				end

			end

			print("初赛继续:",DATA.current_next_cfg_id)

		end

	elseif DATA.current_status==2 then

		--如果所有人都打完了
		local in_table_player_num=PUBLIC.get_in_table_player_num()
		if in_table_player_num < 1 then
			
			DATA.current_next_cfg_id = DATA.current_next_cfg_id + 1

			--总结算 所有比赛都完成了 下一场的配置ID大于决赛的轮ID
			if DATA.current_next_cfg_id > DATA.final_max_round then

				--当前打的是总决赛 通知剩下的冠军们离场
				notification_departure(DATA.out_table_players)

				DATA.current_status = 3

				mathch_final_over()

				promoted_players = nil

			end

		end

		return false
	end

	return true
end


--常规赛处理
local function settle_regular(_players,_cfg_id)

	local weed_out_players = {}
	promoted_players = {}
	for id,player_id in pairs(_players) do
		
		local info=DATA.player_infos[player_id]
		info.in_table=false
		local match_player_count=PUBLIC.get_match_player_num()
		local game_config = DATA.game_config[_cfg_id]

		--分数小于晋级分数，并且当前比赛人数大于晋级人数则被淘汰
		if info.grades < game_config.rise_score
			and match_player_count>game_config.rise_num then
			--即将淘汰淘汰

			weed_out_players[#weed_out_players+1]=player_id

		else
			--晋级等候下一轮
			DATA.out_table_players[#DATA.out_table_players+1]=player_id
			
			--非决赛就休息一下
			if not DATA.in_final_flag then
				DATA.match_rest_players[player_id]=player_id
			end

			promoted_players[#promoted_players+1]=player_id
		end

	end


	-- 可能淘汰的人太多导致决赛人不够
	local match_player_count=PUBLIC.get_match_player_num()
	local game_config = DATA.game_config[_cfg_id]
	local ds = match_player_count - game_config.rise_num

	if ds < #weed_out_players then
		ds = #weed_out_players - ds

		-- 提拔 分最高的 ds 个人

		-- 分数高的在后面
		table.sort(weed_out_players,function (a,b)
			local a_grades,b_grades = DATA.player_infos[a].grades,DATA.player_infos[b].grades
			local a_hide_grades = DATA.player_infos[a].hide_grades
			local b_hide_grades = DATA.player_infos[b].hide_grades
			
			if a_grades == b_grades then
				return a_hide_grades < b_hide_grades
			end
			return a_grades < b_grades
		end)

		for i=1,ds do

			local player_id = weed_out_players[#weed_out_players]
			--晋级等候下一轮
			DATA.out_table_players[#DATA.out_table_players+1]=player_id

			promoted_players[#promoted_players+1]=player_id

			weed_out_players[#weed_out_players] = nil

		end

	end


	--先通知是否复活
	if #weed_out_players>0 then
		notification_revive(weed_out_players)
	end

	return true
end

--决赛处理
local function settle_final(_players,_cfg_id)
	
	for id,player_id in pairs(_players) do
		--直接离开桌子等待
		DATA.out_table_players[#DATA.out_table_players+1]=player_id
	end

	--如果所有人都打完了，等待排名结算
	local in_table_player_num=PUBLIC.get_in_table_player_num()
	if in_table_player_num < 1 then
		
		--结束了，立刻排序
		sort_rank()

		--计算淘汰玩家列表
		local weed_out_players={}
		promoted_players = {}
		local out_table_players = {}
		for id,player_id in ipairs(DATA.out_table_players) do
			local info=DATA.player_infos[player_id]
			local match_player_count=PUBLIC.get_match_player_num()
			local game_config = DATA.game_config[_cfg_id]
			if game_config.rise_num>0 and game_config.rise_num<info.rank then
				weed_out_players[#weed_out_players+1]=player_id
				DATA.out_match_players[#DATA.out_match_players+1]=player_id
				info.weed_out=info.rank
			else
				out_table_players[#out_table_players+1]=player_id
				promoted_players[#promoted_players+1]=player_id
			end
		end

		--通知淘汰
		notification_departure(weed_out_players)

		DATA.out_table_players=out_table_players

		dump(weed_out_players,"本轮决赛淘汰的玩家")
		dump(DATA.out_table_players,"晋级下轮决赛的玩家")

		print("本轮决赛所有人都打完了:",DATA.current_next_round,DATA.current_next_cfg_id)

		--3s开始决赛匹配
		PUBLIC.start_rematching(1)

		return false

	else
		dump(_players,"通知等待结果*--")
		--通知等待 等待所有人出来排名后的结果
		notification_wait_result(_players)
	end

	print("决赛有人打完了一轮:",_cfg_id)
	return false
end


--复活
function PUBLIC.revive(_player_id,_is_wait_result,_is_free)

	local ok = DATA.wait_revive_player[_player_id]

	if ok then
		DATA.wait_revive_player[_player_id] = nil

		local t = DATA.player_revive_data[_player_id] or 0
		DATA.player_revive_data[_player_id] = t + 1

		DATA.out_table_players[#DATA.out_table_players+1]=_player_id

		-- 不是免费的复活才加分
		if not _is_free then
			local player_info = DATA.player_infos[_player_id]
			local score = DATA.match_config.match_data_config.init_prel_score - player_info.grades
			player_info.revive_num = player_info.revive_num + 1
			nodefunc.send(_player_id,DATA.player_msg_name.score_change_msg,score)
		end

		--发送比赛晋级消息
		if _is_wait_result then
			nodefunc.send(_player_id,DATA.player_msg_name.wait_result_msg,DATA.cur_process_info)
		else
			nodefunc.send(_player_id,DATA.player_msg_name.promoted_msg,false,DATA.cur_process_info)
		end

		PUBLIC.start_rematching(1)

		return true

	end

	return false

end


--放弃复活
function PUBLIC.give_up_revive(_player_id)

	if not DATA.in_final_flag
		and DATA.current_status==1
		and DATA.wait_revive_player[_player_id] then

			DATA.wait_revive_player[_player_id] = nil

			local info=DATA.player_infos[_player_id]

			local match_player_count=PUBLIC.get_match_player_num()

			DATA.out_match_players[#DATA.out_match_players+1]=_player_id

			info.weed_out=match_player_count

			notification_departure({_player_id})

			--更新
			--获取剩下的参赛人数
			local current_player_count = PUBLIC.get_match_player_num()
			local regular_max_round_config = DATA.game_config[DATA.final_min_round-1]

			local skip_regular = false
			if regular_max_round_config then
				if current_player_count <= regular_max_round_config.rise_num then
					skip_regular = true
				end
			end

			--人数小于等于最后一把的初赛晋级人数则 进入决赛状态
			if skip_regular then

				print("有人放弃 导致人数达到进入决赛要求")
				
				DATA.game_limit_flag.player_num_ok = true

				promoted_final_match()

			end

		return true
	end

	return false
end


--结算
function PUBLIC.settle(_players,_cfg_id,_final)

	--是否进行匹配
	local is_rematching = false

	if _final then
		--决赛
		is_rematching = settle_final(_players,_cfg_id)
	else
		--常规赛
		is_rematching = settle_regular(_players,_cfg_id)
	end

	--更新当前状态
	is_rematching = update_game_status(_cfg_id)

	--通知晋级的玩家晋级了
	notification_promoted()

	if is_rematching then
		--剩下的玩家进行新的匹配
		PUBLIC.start_rematching(0)
	end

end


function PUBLIC.refresh_rank_update(dt)

	if start_refresh_rank_time+refresh_rank_frequency<os.time() then
		start_refresh_rank_time=os.time()
	else
		return
	end

	if DATA.player_rank_dirty then
		sort_rank()
	end

end