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

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local rematching_waite_time = 5

local mathing_data = nil

local allot_player_num = 0 --已经分配的玩家数量

--对玩家进行匹配 -- 从可用的空桌子表中进行选取
local function matching_players( _players , _round)
	
	local curent_player_num = 0

	--拿取当前的轮配置信息
	local game_config = DATA.game_config[_round]
	game_config.round = _round

	while true do

		curent_player_num=curent_player_num+3
		if curent_player_num > #_players then return end

		--可用的桌子没有了 不可能 
		if DATA.available_tables:empty() then
			skynet.fail("matching_players DATA.available_tables is empty !!!")
			return
		end

		local room_id = DATA.available_tables:pop_front()

		local table_id=nodefunc.call(room_id,"new_table",game_config)
		if table_id=="CALL_FAIL" then
			skynet.fail(string.format("matching_players error:call new_table return table_id:%s",tostring(table_id)))
			return
		end

		local room_info = DATA.room_infos[room_id]
		room_info.table_num=room_info.table_num+1
		room_info[table_id]=
		{
			players={},
			round=_round,
		}
		
		local players = room_info[table_id].players

		--通知入场
		for i=curent_player_num-2,curent_player_num do
			local player_id=_players[i]
			local info=DATA.player_infos[player_id]

			print(string.format("通知玩家入场:%s",player_id,table_id))

			nodefunc.send(player_id,"dbwg_enter_room_msg",
							room_id,table_id,game_config,
							PUBLIC.get_match_player_num())

			players[#players+1]=player_id
			info.in_table=true

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

	local num = DATA.out_table_player_data.num
	
	print("匹配ing ".. num)

	--根本没有人 不要匹配了
	if num < 1 then
		return true
	elseif num < 3 then
	--人数不够等待下一波
		return false
	end

	local rematching_list={}

	for player_id,_ in pairs(DATA.out_table_player_data.player_hash) do
		--选出没有休息的玩家
		if not DATA.match_rest_players[player_id] then
			local player_info = DATA.player_infos[player_id]

			rematching_list[player_info.round]=rematching_list[player_info.round] or {}
			local players = rematching_list[player_info.round]
			players[#players+1]=player_id

		end
	end
	
	-- dump(rematching_list,"分组后的rematching_list")

	--人数不够等待下一波
	if not next(rematching_list) then
		return false
	end

	DATA.out_table_player_data.player_hash={}
	DATA.out_table_player_data.num=0

	for round,players in pairs(rematching_list) do
		
		local num = #players

		if num < 3 then
			--匹配失败 所有人拉回
			for i,player_id in ipairs(players) do
				DATA.out_table_player_data.player_hash[player_id]=player_id
				DATA.out_table_player_data.num=DATA.out_table_player_data.num+1
			end
		else

			local rematching_num = num-num%3
			basefunc.array_shuffle( players, 1, rematching_num )
			-- dump(players,"打乱后的队列:"..rematching_num)

			--将没有进行匹配的玩家拉回来
			if rematching_num < num then
				for i=rematching_num+1,num do
					local player_id=players[i]
					DATA.out_table_player_data.player_hash[player_id]=player_id
					DATA.out_table_player_data.num=DATA.out_table_player_data.num+1
				end
			end

			matching_players(players,round)

		end

	end

	--休息的玩家拉回来
	for player_id,_ in pairs(DATA.match_rest_players) do
		DATA.out_table_player_data.player_hash[player_id]=player_id
		DATA.out_table_player_data.num=DATA.out_table_player_data.num+1
	end

	-- dump(DATA.out_table_player_data,"匹配后的离桌的人")
	-- dump(DATA.match_rest_players,"休息的人")

	--继续匹配
	return false
end


function PUBLIC.rematching_update(dt)
	
	if mathing_data then

		if os.time()>mathing_data.start_time+rematching_waite_time then

			local ret = rematching()

			if ret then
				--匹配成功
				mathing_data=nil
			else
				--匹配失败
				mathing_data.start_time = os.time()
			end
		end

	end

end


--获取比赛场所有的人数
--除开淘汰的人包括在桌和离桌的人
function PUBLIC.get_match_player_num()
	local player_count = #DATA.players
	local week_count = DATA.out_match_player_data.num
	return player_count-week_count
end

--获取在桌的玩家数量 即正在桌上打比赛的人
function PUBLIC.get_in_table_player_num()
	local player_count = PUBLIC.get_match_player_num()
	local out_table_count = #DATA.out_table_player_data.num
	return player_count-out_table_count
end


--开始匹配
function PUBLIC.start_rematching()

	if DATA.current_status==1 then

		if not mathing_data then
			--开始进行等待匹配 
			mathing_data={start_time=os.time()}

		end

		print("匹配... ")

	elseif DATA.current_status==3 then
		--结束了不匹配
		mathing_data = nil
		return
	end

end

local is_allot_rooming = false
local function allot_rooming()

	is_allot_rooming = true
	local table_max_num = nil --房间中桌子的最大的数量

	--创建比赛房间
	while true do

		local room_id=create_room_id()
		if room_id then
			--创建房间
			local ret,state = skynet.call(DATA.service_config.node_service,"lua","create",nil,
							"ddz_million_room_service/ddz_million_room_service",
							room_id,{mgr_id=DATA.my_id})
			if not ret then
				skynet.fail(string.format("create_matching_entries error:call ddz_million_room_service state:%s",state))
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
			allot_player_num=allot_player_num+table_max_num*3

			--记录空桌子
			for i=1,table_max_num do
				DATA.available_tables:push_back(room_id)
			end
			
		end

		if allot_player_num >= DATA.bearing_player_num then
			--分配完成
			is_allot_rooming = false
			break
		end

		skynet.sleep(1)
	end

	-- print("room service create ok , info:"..basefunc.tostring(DATA.room_infos,10))

end


--分配房间
function PUBLIC.allot_room()
	
	if not is_allot_rooming then
		skynet.fork(allot_rooming)
	end

end


