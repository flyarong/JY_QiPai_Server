--
-- Author: hw
-- Date: 2018/3/28
-- Time: 
-- 说明：比赛场服务 进行匹配和安排

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "normal_enum"
require "printfunc"

local trans_friend_cfg = require "cfg_trans_friendgame"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA
local PROTECT={}

DATA.service_config = nil
DATA.my_id = nil

--投票倒计时
local vote_countdown=15

--游戏信息 room_no 。 房卡号(room_no) => 房卡房间信息
local game_info = {}

-- 可用的房间桌子
local available_tables = {}		-- game_type => 房间服务id数组（room_id）
local room_info = {}  			-- game_type => {room_id => {max_table_num,cur_num}}
local table_info = {}			-- room_id => {table_id => 房卡号(room_no)}

local room_rent_cfg = {}


--房间的gps信息
local room_gps_info = {}
local room_gps_ori_data = {}

local ROOM_VALID_TIME = 3*3600
local VALID_TIME_INTERVAL = 3*60

local room_count = 0
--创建房间id
local function create_room_id()
	room_count=room_count+1
	return DATA.my_id.."_room_"..room_count
end


local create_room_thread_data={
	lock = false,
	threads = {}
}

local function thread_start(_thread_data)
	if _thread_data.lock then
		local cid = coroutine.running()
		_thread_data.threads[#_thread_data.threads+1] = cid
		skynet.wait(cid)
	end
	_thread_data.lock = true
end

local function thread_over(_thread_data)

	_thread_data.lock = false
	if #_thread_data.threads > 0 then
		skynet.wakeup(_thread_data.threads[1])
		table.remove(_thread_data.threads,1)
	end
end

local function load_room_card_rent_cfg()

	local cfg = base.reload_config("room_card_server")

	room_rent_cfg = {}
	for id,d in ipairs(cfg.card_price) do
		room_rent_cfg[d.game_type] = room_rent_cfg[d.game_type] or {}
		local game = room_rent_cfg[d.game_type]
		game[d.race_count] = d.price
	end

end

local function get_room_card_rent(game_type,race_count)
	if room_rent_cfg[game_type] and room_rent_cfg[game_type][race_count] then
		local rent = room_rent_cfg[game_type][race_count]
		return rent
	end
end


-- 创建游戏房间
function CMD.create_game_room(player_id,room_no,_game_type,_cfg,_room_card,max_player)

	local tables = available_tables[_game_type] or {}
	available_tables[_game_type] = tables

	local trans_cfg = require(GAME_TYPE_CFG_TRANS[_game_type])

	local rule_config = trans_cfg.translate(_cfg)
	local game_config = trans_friend_cfg.translate_game(_cfg)

	local rent = get_room_card_rent(_game_type,game_config.race_count)
	if not rent then
		return {result=1001}
	end

	print(_game_type,game_config.race_count,"type,rount*********************---------->>>")
	print(rent,_room_card,"need,has*************---------------->>>")
	if rent > _room_card then
		skynet.send(DATA.service_config.friendgame_center_service,"lua","clear_room_no",room_no)
		return {result=1026}
	end

	thread_start(create_room_thread_data)

	if #tables<1 then
		--创建房间
		local room_id = create_room_id()
		local ret,state = skynet.call(DATA.service_config.node_service,"lua","create",nil,
						GAME_TYPE_ROOM[_game_type],
						room_id,{mgr_id=DATA.my_id})
		if not ret then
			thread_over(create_room_thread_data)
			print(string.format("friendgame error:call create_game_room state:%s",state))
			return {result=state}
		end

		table_info[room_id]={}

		local num=nodefunc.call(room_id,"get_free_table_num")
		if num=="CALL_FAIL" then
			thread_over(create_room_thread_data)
			skynet.fail(string.format("friendgame create_game_room error:call get_free_table_num room_id:%s",room_id))
			return {result=1000}
		end

		local game_room = room_info[_game_type] or {}
		room_info[_game_type] = game_room
		game_room[room_id]={
			max_table_num = num,
			cur_num = num,
		}
		for i=1,num do
			tables[#tables+1]=room_id
		end
	end

	local room_id = tables[#tables]
	local table_id=nodefunc.call(room_id,"new_table",
		{	model_name="friendgame",
			game_type=_game_type,
			rule_config = rule_config,
			game_config = game_config,
		},
		{
			game_id=room_no
		}
	)

	if table_id=="CALL_FAIL" then
		thread_over(create_room_thread_data)
		skynet.fail(string.format("matching_players error:call new_table return table_id:%s",tostring(table_id)))
		return {result=1000}
	end

	table_info[room_id][table_id] = room_no

	room_info[_game_type][room_id].cur_num = room_info[_game_type][room_id].cur_num - 1
	tables[#tables] = nil

	local players={}
	players[player_id]=player_id

	local room_base_cfg = {
		init_stake = game_config.init_stake,
		init_rate = game_config.init_rate,
		race_count = game_config.race_count,
		player_count = max_player,
		rule_config = rule_config,
		game_config = game_config,
	}

	-- 如果启动了 聊天室服务，则创建聊天室
	local _chat_room_id
	if DATA.service_config.chat_service then
		_chat_room_id = skynet.call(DATA.service_config.chat_service,"lua","create_room")
	end

	game_info[room_no]=
	{
		game_type=_game_type,
		room_id=room_id,
		t_num=table_id,
		game_cfg=_cfg,
		player_num=1,
		max_player=max_player,
		room_owner=player_id,
		players=players,
		lock_join=false,	-- 锁定，不允许加入
		room_base_cfg=room_base_cfg,
		room_rent = rent,
		chat_room_id = _chat_room_id,
		valid_time = os.time() + ROOM_VALID_TIME,
	}


	room_gps_info[room_no]={}
	room_gps_ori_data[room_no]={}
	for i=1,max_player do
		room_gps_info[room_no][i]={}
		room_gps_ori_data[room_no][i]={}
	end

	thread_over(create_room_thread_data)
	return {
			result=0,
			room_id=room_id,
			t_num=table_id,
			room_base_cfg=room_base_cfg,
			room_rent = rent,
			chat_room_id=_chat_room_id,
			}
end

-- ###_test0809 用户退出
function CMD.exit_friend_room(player_id,room_no,seat_num)

	-- 调用游戏房间的退出
	local ginfo = game_info[room_no]
	if not ginfo then
		return 1002
	end
	local ret = nodefunc.call(ginfo.room_id,"player_exit_game",ginfo.t_num,seat_num)
	if ret ~= 0 then
		return ret
	end

	ginfo.players[player_id] = nil
	ginfo.player_num = ginfo.player_num - 1
	return 0
end

-- ###_test0809 发起投票解散房间
function CMD.begin_vote_cancel_room(room_no,player_id)
	if room_no and game_info[room_no] then
		local info=game_info[room_no]
		if not info.is_vote then
			local time=os.time()
			if not info.last_vote_time or time-info.last_vote_time>10 then
				info.is_vote=true
				info.vote_count=0
				info.vote_agree_count=0
				info.vote_disagree_count=0
				info.vote_player_flag={}
				--通知大家进行投票

				for _,id in pairs(info.players) do
					nodefunc.send(id,"friendgame_begin_vote_cancel_room_msg",player_id,vote_countdown)
				end
				--房主自动投票
				CMD.player_vote_cancel_room(room_no,player_id,1)

				return {result=0}
			end
			-- ###_test 临时错误码  ： 操作过于频繁，请等待几秒后尝试
			return {result=2409}
		end
		-- ###_test 临时错误码  ： 正在投票中
		return {result=2410}
	end
	-- ###_test 临时错误码  ： 无法进行此操作
	return {result=2411}
end

-- ###_test0809 解散房间
function CMD.cancel_friend_room(room_no)

	-- 调用游戏房间的退出
	local ginfo = game_info[room_no]
	if not ginfo then
		return 1002
	end
	ginfo.lock_join = true

	local ret = nodefunc.call(ginfo.room_id,"cancel_game",ginfo.t_num)
	if ret ~= 0 then
		ginfo.lock_join = false
		return ret
	end

	ginfo.lock_join = true
	
	return 0
end


-- 重载配置
function CMD.reload_config()
	
	load_room_card_rent_cfg()
	
	return 0
end



--结束 投票 result 0 成功  1 失败 2 取消
function PROTECT.over_the_vote(info,result)

	info.last_vote_time=os.time()
	info.is_vote=nil
	--通知结果
	for _,id in pairs(info.players) do
		nodefunc.send(id,"friendgame_over_vote_cancel_room_msg",result)
	end

	if result==0 then
		-- 终止房间
		if 0 == nodefunc.call(info.room_id,"break_game",info.t_num) then
			info.lock_join = true
		end
	end

end


local function check_vote_is_over(info)
	if info.max_player>2 then
		if info.vote_disagree_count>1 then
			PROTECT.over_the_vote(info,1)
		elseif info.vote_agree_count>=info.max_player-1 then
			PROTECT.over_the_vote(info,0)
		end
	elseif info.max_player==2 then
		if info.vote_disagree_count>0 then
			PROTECT.over_the_vote(info,1)
		elseif info.vote_agree_count==info.max_player then
			PROTECT.over_the_vote(info,0)
		end
	end
end
-- options==1 同意 0不同意
function CMD.player_vote_cancel_room(room_no,player_id,options)
	if room_no and game_info[room_no]  then
		local info=game_info[room_no]
		if info.is_vote and not info.vote_player_flag[player_id] then
			info.vote_player_flag[player_id]=options
			info.vote_count=info.vote_count+1
			if options==1 then
				info.vote_agree_count=info.vote_agree_count+1
			else
				info.vote_disagree_count=info.vote_disagree_count+1
			end
			
			for _,id in pairs(info.players) do
				nodefunc.send(id,"friendgame_player_vote_cancel_room_msg",player_id,options)
			end

			if game_info[room_no] then -- 可能已经 table_finish，再判断一次 by lyx
				check_vote_is_over(info)
			end

			return {result=0}
		end
		-- ###_test 临时错误码  ： 没在投票 或 玩家已投票
		return {result=1002}
	end
	-- ###_test 临时错误码  ： 房卡号不存在
	return {result=2412}
end

function CMD.join_friend_room(player_id,room_no,_room_card)

	local info = game_info[room_no]
	if info and not info.players[player_id] then
		if info.player_num<info.max_player then
			-- ###_test 其他检测条件  如 黑名单

			print(info.room_rent,_room_card,"need,has****join*********---------------->>>")
			if info.room_rent > _room_card then
				return 1026
			end

			if info.lock_join then
				return 1002
			end

			info.player_num=info.player_num+1
			info.players[player_id]=player_id
			return info
		end
		
		return 3202
	end

	return 3201
end

function CMD.table_finish(_room_id,_table_id)

	if not table_info[_room_id] or not table_info[_room_id][_table_id] then
		print("error:friendgame table finish not found, perhaps finished!",m_id,_table_id)
		return
	end

	local _room_no = table_info[_room_id][_table_id]

	local info = game_info[_room_no]

	-- 回收gps数据
	room_gps_ori_data[_room_no] = nil
	room_gps_info[_room_no] = nil

	-- 回收桌子
	local tables = available_tables[info.game_type]
	if tables then 
		tables[#tables] = nil
	end

	-- 回收聊天室
	if info.chat_room_id then
		skynet.send(DATA.service_config.chat_service,"lua","destroy_room",info.chat_room_id)
	end

	-- 回收数量
	room_info[info.game_type][_room_id].cur_num = room_info[info.game_type][_room_id].cur_num + 1

	table_info[_room_id][_table_id] = nil
	game_info[_room_no] = nil
	

	-- 通知 center 销毁房卡编号
	skynet.call(DATA.service_config.friendgame_center_service,"lua","clear_room_no",_room_no)
end



--[[gps

]]


local function rad(d)
	return d * (3.1415926 / 180)
end

local function calc_gps_distance(la1,lo1,la2,lo2)
	local rla1 = rad(la1)
    local rla2 = rad(la2)
    local a = rla1 - rla2
    local b = rad(lo1) - rad(lo2)
	local sa = math.sin(a/2)
	local sb = math.sin(b/2)
    local s = 2*6378137*math.asin(math.sqrt(sa*sa+math.cos(rla1)*math.cos(rla2)*sb*sb))
    return math.floor(s)
end

function update_gps_distance(room_no)
	-- dump(room_gps_ori_data,"room_gps_ori_data")
	for a_no,a_info in ipairs(room_gps_ori_data[room_no]) do

		if a_info.latitude and a_info.latitude~=0 and a_info.longitude and a_info.longitude~=0 then

			for b_no,b_info in ipairs(room_gps_ori_data[room_no]) do

				if b_info.latitude
					and b_info.latitude~=0 
					and b_info.longitude
					and b_info.longitude~=0 
					and a_no~=b_no then

					if a_info.ip == b_info.ip then
						room_gps_info[room_no][a_no].distance[b_no]=0
					else

						room_gps_info[room_no][a_no].distance[b_no]=calc_gps_distance(
																	a_info.latitude,
																	a_info.longitude,
																	b_info.latitude,
																	b_info.longitude
																	)
					end

				else
					room_gps_info[room_no][a_no].distance[b_no]=-1
				end

			end

		end

	end

end

--添加gps信息
--[[
	{
		player_id
		room_no
		seat_num
		ip
		locations
		latitude
		longitude
	}
]]
function CMD.append_gps_data(_data)
	
	if not room_gps_ori_data[_data.room_no] then
		return
	end

	room_gps_ori_data[_data.room_no][_data.seat_num]=_data
	
	room_gps_info[_data.room_no][_data.seat_num].ip=_data.ip
	room_gps_info[_data.room_no][_data.seat_num].locations=_data.locations
	room_gps_info[_data.room_no][_data.seat_num].player_id=_data.player_id
	room_gps_info[_data.room_no][_data.seat_num].distance={}

	update_gps_distance(_data.room_no)
end

function CMD.clear_gps_data(_data)
	room_gps_ori_data[_data.room_no][_data.seat_num]=_data
	room_gps_info[_data.room_no][_data.seat_num]={}
	update_gps_distance(_data.room_no)
end

function CMD.query_gps_info(room_no)
	return room_gps_info[room_no]
end


function CMD.add_race_id_log(_race_id,_room_id,_t_num)
	-- no do anything
end

local function update(dt)
	
	local t = os.time()
	for room_id,info in pairs(game_info) do
		if info.valid_time < t then

			nodefunc.send(info.room_id,"over_time_cancel_game",info.t_num)
			info.lock_join = true
		
		end
		skynet.sleep(100)
	end

end


function CMD.start(_my_id,_service_config)

	math.randomseed(os.time()*78415)

	DATA.service_config=_service_config
	DATA.my_id = _my_id

	load_room_card_rent_cfg()


	-- 开始更新函数
	skynet.timer(VALID_TIME_INTERVAL,update)

end


-- 启动服务
base.start_service()





