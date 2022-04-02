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
local normal_majiang=require "normal_majiang_lib"
require "printfunc"
--require "normal_mjxl_match_enum"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA


--操作列表 room_id.."_"..table_id=>{time,func}
local opt_list = {}

local function update(dt)
	
	for key,opt in pairs(opt_list) do
		if opt.time < os.time() then
			opt.func()
			opt_list[key]=nil
		end
	end

end

--添加一个延迟操作
local function add_opt(key,func,delay_time)
	opt_list[key]=
	{
		time=os.time()+delay_time,
		func=func,
	}
end

--对玩家进行匹配 -- 从可用的空桌子表中进行选取
function PUBLIC.matching_players( _players )

	local curent_player_num = 0

	while true do

		curent_player_num=curent_player_num+4
		if curent_player_num > #_players then return end

		--可用的桌子没有了 不可能 
		if DATA.available_tables:empty() then
			skynet.fail("matching_players DATA.available_tables is empty !!!")
			return
		end

		local room_id = DATA.available_tables:pop_front()

		DATA.game_num=DATA.game_num+1

		local table_id=nodefunc.call(room_id,"new_table",
										{
										game_id = DATA.game_config.game_id,
										name = DATA.game_config.name,
										game_model = DATA.game_config.game_model,
										base_score = DATA.game_config.base_score,
										})

		if table_id=="CALL_FAIL" then
			skynet.fail(string.format("matching_players error:call new_table return table_id:%s",tostring(table_id)))
			return
		end
		local room_info = DATA.room_infos[room_id]
		room_info.table_num=room_info.table_num+1
		room_info[table_id]=
		{
			players={},
		}
		
		local players = room_info[table_id].players

		--通知入场
		for i=curent_player_num-3,curent_player_num do
			local player_id=_players[i]
			DATA.player_infos[player_id].status=1
			DATA.player_infos[player_id].room_id=room_id
			DATA.player_infos[player_id].table_id=table_id
			--###test
			-- add_opt(player_id,function ()
				nodefunc.send(player_id,"nmjxlfg_enter_room_msg",room_id,table_id)
				--###test
				print(string.format("mjxl freestyle player:%s join table:%s",player_id,table_id))
			-- end,2)

			players[#players+1]=player_id

		end

	end

end


local room_count = 0
--创建房间id
local function create_room_id()
	room_count=room_count+1
	return DATA.my_id.."_"..room_count
end


--创建比赛房间和桌子
--最后一个房间可能会少几桌
local room_table_max_num = nil
local function create_room_entries(room_num)
	
	for i=1,room_num do

		local room_id=create_room_id()
		if room_id then
			--创建房间
			--###test
			local ret,state = skynet.call(DATA.service_config.node_service,"lua","create",nil,
								"normal_mjxl_freestyle_room_service/normal_mjxl_freestyle_room_service",
								room_id,{mgr_id=DATA.my_id})
			if not ret then
				skynet.fail(string.format("create_room_entries error:call normal_mjxl_freestyle_room_service state:%s",state))
				return
			end
			
			DATA.room_infos[room_id]={}
			local room_info = DATA.room_infos[room_id]
			if not room_table_max_num then
				local num=nodefunc.call(room_id,"get_free_table_num")
				if num~="CALL_FAIL" then
					room_table_max_num=num
				else
					skynet.fail(string.format("create_room_entries error:call get_free_table_num room_id:%s",room_id))
					return
				end
			end
			
			room_info.table_num = 0
			room_info.table_max_num = room_table_max_num

			--记录空桌子
			for i=1,room_table_max_num do
				DATA.available_tables:push_back(room_id)
			end
			
			--###test
			-- print("create room ok ,room_id:",room_id,room_table_max_num)
		end

	end

	--###test
	-- print("room service create ok , info:"..basefunc.tostring(DATA.room_infos,10))

end



function PUBLIC.update_room_remain()

	--小于10张桌子就加桌子
	if DATA.available_tables:size() < room_table_max_num then
		create_room_entries(1)
	end

end



--初始化匹配
function PUBLIC.init_matching()

	--开始就预先创建10个房间
	create_room_entries(10)

	--update
	skynet.timer(1,update)
end



-- 一桌打完了打完了一轮
function CMD.table_finish(_room_id,_table_id)

	--###test
	print("freestyle table finish , info:",_room_id,_table_id)

	local room_info = DATA.room_infos[_room_id]
	
	if room_info then
		local table_info = room_info[_table_id]
		if table_info then
			
			--清除玩家信息
			for i,player_id in ipairs(table_info.players) do
				DATA.player_infos[player_id] = nil
				DATA.player_count = DATA.player_count - 1
				if basefunc.chk_player_is_real(player_id)then
					DATA.real_player_count = DATA.real_player_count - 1
				end
			end

			DATA.player_last_opt_time = os.time()
			
			--更新table表
			room_info[_table_id]=nil
			room_info.table_num=room_info.table_num-1
			--记录空桌子
			DATA.available_tables:push_back(_room_id)
		end

	end

end


local match_list = {}
local function matching()

	while #match_list > 0 do

		local ml = match_list[#match_list]
		match_list[#match_list] = nil
		PUBLIC.matching_players( ml )

		--检查桌子的余量
		PUBLIC.update_room_remain()

		skynet.sleep(1)

	end

end


--开始比赛
function PUBLIC.start_match()

	if #DATA.wait_players == normal_majiang.SEAT_COUNT then

		match_list[#match_list+1]=DATA.wait_players
		DATA.wait_players={}

		if #match_list == 1 then
			skynet.fork(matching)
		end

	end

end
