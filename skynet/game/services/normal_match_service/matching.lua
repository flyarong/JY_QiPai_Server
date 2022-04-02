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


local rematching_waite_time = 5

local mathing_data = nil

local tuoguan_table_id = 0

--对玩家进行匹配 -- 从可用的空桌子表中进行选取
local function matching_players( _players )
	
	local curent_player_num = 0

	while true do

		curent_player_num=curent_player_num+DATA.game_seat_num
		if curent_player_num > #_players then return end

		
		local tuoguan_ids = {}
		local is_tuoguan = true
		for i=curent_player_num-DATA.game_seat_num+1,curent_player_num do
			local player_id = _players[i]
			tuoguan_ids[#tuoguan_ids+1] = player_id
			if basefunc.chk_player_is_real(player_id) then
				is_tuoguan = false
				break
			end
		end

		--可用的桌子没有了 不可能 
		if DATA.available_tables:empty() then
			skynet.fail("matching_players DATA.available_tables is empty !!!")
			return
		end

		local room_id = DATA.available_tables:pop_front()

		--拿取当前的轮配置信息
		local game_config = DATA.game_config[DATA.current_next_cfg_id]
		
		DATA.cur_process_info.rise_num = game_config.rise_num
		DATA.cur_process_info.rise_score = game_config.rise_score
		DATA.cur_process_info.race_count = game_config.race_count
		DATA.cur_process_info.init_rate = game_config.init_rate
		DATA.cur_process_info.init_stake = game_config.init_stake

		if is_tuoguan then

			tuoguan_table_id = tuoguan_table_id + 1
			local table_id = "tuoguan_"..tuoguan_table_id
			local room_info = DATA.room_infos[room_id]
			room_info.table_num=room_info.table_num+1
			room_info[table_id]=
			{
				players=tuoguan_ids,
				round=DATA.current_next_round,
				cfg_id=DATA.current_next_cfg_id,
				final=mathing_data.final,
			}

			for i,p in ipairs(tuoguan_ids) do
				DATA.player_infos[p].in_table=true
			end
			
			-- 托管处理
			PUBLIC.tuoguan_matching(tuoguan_ids,room_id,table_id,game_config,DATA.player_msg_name.score_change_msg)

		else

			local table_id=nodefunc.call(room_id,"new_table",
					{	model_name="match_game",
						game_type=DATA.match_config.game_type,
						rule_config = DATA.game_rule_config,
						game_config = game_config,
						nice_pai_rate = DATA.match_config.nice_pai_rate.rate or 0 ,
					},
					{
						game_id=DATA.match_game_id
					}
				)
			if table_id=="CALL_FAIL" then
				skynet.fail(string.format("matching_players error:call new_table return table_id:%s",tostring(table_id)))
				return
			end
			local room_info = DATA.room_infos[room_id]
			room_info.table_num=room_info.table_num+1
			room_info[table_id]=
			{
				players={},
				round=DATA.current_next_round,
				cfg_id=DATA.current_next_cfg_id,
				final=mathing_data.final,
			}
			
			local players = room_info[table_id].players

			--通知入场
			for i=curent_player_num-DATA.game_seat_num+1,curent_player_num do
				local player_id=_players[i]
				local info=DATA.player_infos[player_id]

				print(string.format("通知玩家入场:%s,%s",player_id,table_id))
				
				nodefunc.send(player_id,DATA.player_msg_name.enter_room_msg,
								room_id,table_id,DATA.cur_process_info,
								PUBLIC.get_match_player_num())

				players[#players+1]=player_id
				info.in_table=true

			end

		end

	end

end

local room_count = 0
--创建房间id
local function create_room_id()
	room_count=room_count+1
	return DATA.my_id.."_room_"..room_count
end

--再匹配 将没有在桌子上的人进行重新安排比赛
--[[
	true - 完全匹配完成没有剩余玩家
	false - 匹配没有完成，还有剩余玩家
]]
local function rematching()

	-- dump(DATA.player_infos,"rematching.....")

	local num = #DATA.out_table_players

	--人数不够等待下一波
	if num < DATA.game_seat_num then
		return false
	end

	local occupy_tuoguan_rematching = {}

	--找出要匹配的玩家
	local rematching_players = {}
	for i,player_id in ipairs(DATA.out_table_players) do
		--选出没有休息的玩家
		if not DATA.match_rest_players[player_id] then
			
			if DATA.occupy_rank_tuoguan[player_id] then
				occupy_tuoguan_rematching[#occupy_tuoguan_rematching+1]=player_id
			else
				rematching_players[#rematching_players+1]=player_id
			end

		end
	end
	
	--托管顺序排
	local otr = #occupy_tuoguan_rematching
	if otr>0 and otr % DATA.game_seat_num == 0 then
		
		for i,player_id in ipairs(occupy_tuoguan_rematching) do
			table.insert(rematching_players,1,player_id)
		end

	else
		otr = 0
	end
	
	num = #rematching_players

	--人数不够等待下一波
	if num < DATA.game_seat_num then
		return false
	end

	local rematching_num = num-num%DATA.game_seat_num
	basefunc.array_shuffle( rematching_players, otr+1)
	dump(rematching_players,"打乱后的队列:"..rematching_num)

	--清空离桌玩家表 准备更新离桌玩家表
	DATA.out_table_players={}

	--将没有多余没有进行匹配的玩家拉回来
	if rematching_num < num then
		for i=rematching_num+1,num do
			DATA.out_table_players[#DATA.out_table_players+1]=rematching_players[i]
		end
	end
	--休息的玩家拉回来
	for player_id,_ in pairs(DATA.match_rest_players) do
		DATA.out_table_players[#DATA.out_table_players+1]=player_id
	end

	matching_players(rematching_players)

	if rematching_num == num then

		print("match all user is ok")

		return true
	else

		-- 决赛时 轮空 发送等待消息
		if DATA.current_status==2 then
			for id,player_id in ipairs(DATA.out_table_players) do
				--发送比赛等待结果消息 -- 一定是休息好了的
				nodefunc.send(player_id,DATA.player_msg_name.wait_result_msg,DATA.cur_process_info)
			end
		end

		print("match has last user :"..basefunc.tostring(DATA.out_table_players,10))

		return false
	end
end


function PUBLIC.rematching_update(dt)
	
	if mathing_data then

		if os.time()>mathing_data.start_time+rematching_waite_time then

			--发现是决赛标志了，但是当前进行的匹配不是决赛那么放弃匹配
			if DATA.in_final_flag then
				print("阻断正在进行的初赛匹配...")
				mathing_data = nil
				return
			end

			local ret = rematching()

			if ret then
				--匹配成功
				mathing_data=nil
			else
				--匹配失败
				mathing_data.start_time = os.time()
			end

			-- 如果是决赛 人数不匹配也判定为匹配完成
			if mathing_data and mathing_data.final then
				mathing_data=nil
			end

		end

	end

end


--获取比赛场所有的人数
--除开淘汰的人包括在桌和离桌的人
function PUBLIC.get_match_player_num()
	local player_count = #DATA.players
	local week_count = #DATA.out_match_players
	return player_count-week_count
end

--获取在桌的玩家数量 即正在桌上打比赛的人
function PUBLIC.get_in_table_player_num()
	local player_count = PUBLIC.get_match_player_num()
	local out_table_count = #DATA.out_table_players
	return player_count-out_table_count
end


--开始匹配
function PUBLIC.start_rematching(_delay)

	_delay = _delay or 0

	--初赛
	if DATA.current_status==1 then

		if not mathing_data then
			--开始进行等待匹配 
			mathing_data={start_time=os.time()+_delay}

		end

		print("初赛匹配... r,c:",DATA.current_next_round,DATA.current_next_cfg_id)

	--决赛状态需要所有人都出来才行,并且排名完成才行
	elseif DATA.current_status==2 then

		mathing_data={start_time=os.time()+_delay,final=true}
		print("所有人到齐了，开始决赛的匹配 r,c:",DATA.current_next_round,DATA.current_next_cfg_id)

	elseif DATA.current_status==3 then
		--结束了不匹配
		mathing_data = nil
		return
	end

end


--初始化匹配
function PUBLIC.init_matching()

	local allot_player_num = 0 --已经分配的玩家数量
	local table_max_num = nil --房间中桌子的最大的数量

	--创建比赛房间
	while true do

		local room_id=create_room_id()
		if room_id then
			--创建房间
			local ret,state = skynet.call(DATA.service_config.node_service,"lua","create",nil,
							DATA.game_room_service_type,
							room_id,
							{
								mgr_id=DATA.my_id,
								game_type=DATA.match_config.game_type,
								game_model = "matchstyle" , 
								game_id = DATA.match_game_id,
								match_model=DATA.match_config.match_model,
							})
			if not ret then
				skynet.fail(string.format("create_matching_entries error:call ddz_match_room_service state:%s",state))
				return
			end
			
			DATA.room_infos[room_id]={}
			local room_info = DATA.room_infos[room_id]
			room_info.table_num = 0
			if not table_max_num then
				local num=nodefunc.call(room_id,"get_free_table_num")
				if num~="CALL_FAIL" then
					table_max_num=num
				else
					skynet.fail(string.format("create_matching_entries error:call get_free_table_num room_id:%s",room_id))
					return
				end
			end
			room_info.table_max_num = table_max_num
			allot_player_num=allot_player_num+table_max_num*DATA.game_seat_num

			--记录空桌子
			for i=1,table_max_num do
				DATA.available_tables:push_back(room_id)
			end
			
			--###test
			-- print("create room ok ,room_id:",room_id,table_max_num)
		end

		if allot_player_num >= #DATA.players then
			--分配完成
			break
		end
	end

	-- print("room service create ok , info:"..basefunc.tostring(DATA.room_infos,10))

	--开始匹配
	PUBLIC.start_rematching()

end


