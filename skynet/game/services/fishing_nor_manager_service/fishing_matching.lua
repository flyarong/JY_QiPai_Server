--人满分配
--auther ：hewei

local basefunc = require "basefunc"
require"printfunc"

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "ddz_match_enum"
require "normal_enum"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA
local PROTECTED = {}

DATA.local_distribution_queue=basefunc.queue.new()
local distribution_queue=DATA.local_distribution_queue

DATA.fish_matching_data = DATA.fish_matching_data or 
{
	min_table_num = 3,

	once_max_distribution=30,
	destroyRoomCountDown=0,
	destroyRoomCountDownIn=300,

	room_count_id=0,
	max_table_num=nil,
}
local LL = DATA.fish_matching_data

--创建房间id
function PUBLIC.create_room_id()
	LL.room_count_id=LL.room_count_id+1
	return DATA.my_id.."_room_" .. LL.room_count_id
end

function PUBLIC.new_room()
	local room_id=PUBLIC.create_room_id()
	if room_id then
		--创建房间
		local ret,state = skynet.call(DATA.service_config.node_service,"lua","create",nil,
						DATA.game_room_service_type,
						room_id,
						{
							mgr_id = DATA.my_id,
							game_type = DATA.game_type,
							game_id = DATA.game_config.game_id,
							fish_config = DATA.game_config.game_rule.fish_config,
							gun_id_config = DATA.game_config.game_rule.gun_id,
							gun_rate_config = DATA.game_config.game_rule.gun_rate,
						})
		if not ret then
			print(string.format("freestyle_matching error:call  state:%s",state))
			return
		end
		if not LL.max_table_num then
			local num=nodefunc.call(room_id,"get_free_table_num")
			if num=="CALL_FAIL" then
				print(string.format("freestyle_matching error:call get_free_table_num room_id:%s",room_id))
				return
			else
				LL.max_table_num=num
			end
		end
		DATA.free_table_room_map[room_id]=LL.max_table_num
		DATA.all_table_count=DATA.all_table_count+LL.max_table_num
	end
	-- body
end
function PUBLIC.new_table()
	local room_id
	for id,v in pairs(DATA.free_table_room_map) do
		room_id=id
		break
	end

	---- 没有房间就先创建
	if not room_id then
		PUBLIC.new_room()
		for id,v in pairs(DATA.free_table_room_map) do
			room_id=id
			break
		end
	end
	if room_id then
		DATA.free_table_room_map[room_id]=DATA.free_table_room_map[room_id]-1
		DATA.all_table_count=DATA.all_table_count-1
		if DATA.free_table_room_map[room_id]==0 then
			DATA.busy_table_room_map[room_id]=DATA.free_table_room_map[room_id]
			DATA.free_table_room_map[room_id]=nil
		end
		if DATA.all_table_count < LL.min_table_num then
			PUBLIC.new_room()
		end

		--创建桌子
		local t_num=nodefunc.call(room_id,"new_table",
									{	model_name = DATA.game_config.game_model,
										game_type = DATA.game_type,
										game_config = DATA.game_config.game_rule,
									},
									{
										game_id=DATA.game_config.game_id
									})
		if t_num=="CALL_FAIL" then
			print(string.format("freestyle_matching error:call new_table room_id:%s",room_id))
			return nil
		end
		return room_id,t_num
	end
	return nil
end

function PUBLIC.distribution()
	local count=LL.once_max_distribution
	while count>0 do
		if distribution_queue:empty() then
			break
		end
	
		local players = distribution_queue:pop_front()
		local _player_id = players[1]
		

		local room_id,t_num=PUBLIC.new_table()

		if room_id and t_num then

			DATA.running_game[room_id]=DATA.running_game[room_id] or {}
			DATA.running_game[room_id][t_num]=players

			-- dump(players,"xxxxxxxxdistributionxxxxxxxxx")

			DATA.all_player_info[_player_id].status="gaming"
			DATA.all_player_info[_player_id].room=room_id
			DATA.all_player_info[_player_id].table=t_num

		
			nodefunc.send(_player_id,"fsg_enter_room_msg",room_id,t_num,seat_num)
		
		end

		
		count=count-1
		-- PUBLIC.start_match_log(room_id,t_num)

	end
end


function PUBLIC.destroyRoom()
	local player_num=distribution_queue:size() or 0
	if LL.max_table_num and DATA.all_table_count-player_num>LL.max_table_num*2 then
		for id,v in pairs(DATA.free_table_room_map) do
			if v==LL.max_table_num then
				DATA.free_table_room_map[id]=nil
				DATA.all_table_count=DATA.all_table_count-LL.max_table_num
				nodefunc.send(id,"destroy")
				if DATA.all_table_count-player_num<=LL.max_table_num*2 then
					break
				end
			end
		end
	end
end


function PUBLIC.distribution_players(_players)
	distribution_queue:push_back(_players)
end


function PUBLIC.table_finish(_room_id,_t_num )

	---清理
	if _room_id and _t_num and DATA.running_game[_room_id] and DATA.running_game[_room_id][_t_num] then
		local players = DATA.running_game[_room_id][_t_num]

		-- PUBLIC.add_match_log(_room_id,_t_num)
		DATA.running_game[_room_id][_t_num] = nil
	end

end


-- 归还桌子
function PUBLIC.return_table(_room_id,_t_num )

	DATA.all_table_count=DATA.all_table_count+1

	if DATA.free_table_room_map[_room_id] then
		DATA.free_table_room_map[_room_id]=DATA.free_table_room_map[_room_id]+1
	elseif DATA.busy_table_room_map[_room_id] then
		DATA.busy_table_room_map[_room_id]=DATA.busy_table_room_map[_room_id]+1
		DATA.free_table_room_map[_room_id]=DATA.busy_table_room_map[_room_id]
		DATA.busy_table_room_map[_room_id]=nil
	else
		skynet.fail(string.format("freestyle_matching table_finish error:room_id not exist room_id:%s",_room_id))
		return 
	end

end




function PUBLIC.matching_update(dt)
	PUBLIC.distribution()
	LL.destroyRoomCountDown=LL.destroyRoomCountDown+dt
	if LL.destroyRoomCountDown>=LL.destroyRoomCountDownIn then
		LL.destroyRoomCountDown=0
		PUBLIC.destroyRoom()
	end


end

function PUBLIC.init()
	DATA.free_table_room_map={}
	DATA.busy_table_room_map={}
	DATA.running_game={}
	DATA.all_table_count=0
	
end


return PROTECTED









