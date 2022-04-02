--[[
	--报名就入桌
	--支持换桌功能
	--支持准备
--]]
local base=require "base"
local nodefunc = require "nodefunc"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA
local PROTECTED = {}


local table_min_num = 2

--桌子总数
local table_num = 0

--[[table_id=>
	{
		player_num=1,
		status= "gaming" | 
		player_info={
			[1]=nil,
			[2]=nil,
			[3]=0132456,
		}
		
	}
]]
local table_infos = {}

local recycle_interval = 60
local recycle_time = 0

--空闲的桌子数量
local free_table_num = 0
--空闲的桌子map
local free_table = {}

--空闲的桌子数量
local busy_table_num = 0
--满的的桌子map
local busy_table = {}


local cold_table_num = 0
--冰冻map
local cold_table = {}

-- 多久进入冰冻桌子
local enter_cold_time = 5
local cold_interval = 2
local cold_time = 0


local function dump_test()
	print("===================================//////////=====================")
	dump(table_infos,"table_infos "..table_num)
	dump(busy_table,"busy_table "..busy_table_num)
	dump(free_table,"free_table "..free_table_num)
	dump(cold_table,"cold_table "..cold_table_num)
	print("===================================//////////=====================")
end

local statistic_table_id_count = 0
local function gen_table_id()
	statistic_table_id_count = statistic_table_id_count + 1
	return statistic_table_id_count
end

local function create_new_table()

	local index = gen_table_id()

	table_infos[index]={
		player_num=0,
		player_info={}
	}

	free_table[index]=index

	table_num = table_num + 1
	free_table_num = free_table_num + 1

	return index
end

---- 
local function check_create_table()
	if DATA.all_player_count > table_num * DATA.game_seat_num - table_min_num * DATA.game_seat_num then
		create_new_table()
	end
end

function PROTECTED.init()
	for i=1,table_min_num do

		create_new_table()
		
	end

end



--检测一个桌子是否可以开始游戏
local function chk_table_begin(_table_id)
	local _t_d = table_infos[_table_id]

	if _t_d.player_num >= DATA.game_seat_num then
		for _seat_num,_player_id in pairs(_t_d.player_info) do
			
			if DATA.all_player_info[_player_id].ready ~= 1 then
				return false
			end
		end

		_t_d.status="gaming"

		PUBLIC.distribution_players(_t_d.player_info)

		return true
	end
	return false
end

--更新桌子
local function update_table_status(_table_id)
	local t_d = table_infos[_table_id]

	if not t_d then return end

	-- 转换为忙桌子
	if t_d.player_num >= DATA.game_seat_num then

		if free_table[_table_id] then
			free_table_num=free_table_num-1
			free_table[_table_id] = nil
		end

		if not busy_table[_table_id] then
			busy_table_num = busy_table_num + 1
			busy_table[_table_id] = _table_id
			chk_table_begin(_table_id)
		end

	else

		--游戏中的桌子是不会变成空闲的，即使有空座位
		if t_d.status~="gaming" then
			if not free_table[_table_id] then
				free_table_num=free_table_num+1
				free_table[_table_id] = _table_id
			end

			if busy_table[_table_id] then
				busy_table_num = busy_table_num - 1
				busy_table[_table_id] = nil
			end

			if cold_table[_table_id] then
				cold_table[_table_id] = nil
				cold_table_num = cold_table_num - 1
			end

			--把闲桌子上没有ready的兄弟标记cold_time
			local t_info = table_infos[_table_id]
			if t_info then
				for k,_pid in pairs(t_info.player_info) do
					local p_info = DATA.all_player_info[_pid]
					if p_info.ready ~= 1 then
						p_info.in_cold_time = os.time() + enter_cold_time
					end
				end
			end

		end

	end

	--dump_test( )
end


--把一个玩家加入桌子
local function player_join_table(_table_id,_player_id)

	local info = DATA.all_player_info[_player_id]

	if info.table_id and _table_id==info.table_id then
		return
	elseif info.table_id then
		local t_d = table_infos[info.table_id]
		t_d.player_info[info.seat_num]=nil
		t_d.player_num=t_d.player_num-1
		update_table_status(info.table_id)
	end

	local t_d = table_infos[_table_id]

	if t_d and t_d.player_num < DATA.game_seat_num then

		for _seat_num=1,DATA.game_seat_num do
			
			if not t_d.player_info[_seat_num] then
				t_d.player_info[_seat_num]=_player_id
				t_d.player_num=t_d.player_num+1
				DATA.all_player_info[_player_id].table_id=_table_id
				DATA.all_player_info[_player_id].seat_num=_seat_num
				break
			end
		end
	end

	--检查桌子满了没有
	update_table_status(_table_id)
end

--把一个玩家加入冰冻桌子
local function player_join_cold_table(_player_id)

	local _info = DATA.all_player_info[_player_id]

	if _info.in_cold then
		return
	end

	local t_info = table_infos[_info.table_id]

	
	if t_info then
		
		local other_players = {}
		--通知当前桌的其他人 我离开了
		for _seat_num,_pid in pairs(t_info.player_info) do
			if _pid ~= _player_id then
				nodefunc.send(_pid,"player_leave_msg",_info.seat_num)
				other_players[#other_players+1]=_seat_num
			end
		end

		--通知我其他人离开了
		for i,_seat_num in ipairs(other_players) do
			nodefunc.send(_player_id,"player_leave_msg", _seat_num )
		end

	end

	--桌子清理
	t_info.player_info[_info.seat_num]=nil
	t_info.player_num=t_info.player_num-1
	update_table_status(_info.table_id)


	local _table_id = gen_table_id()

	table_infos[_table_id]={
		player_num=1,
		player_info={
			[_info.seat_num]=_player_id,
		}
	}

	cold_table[_table_id]=_table_id
	cold_table_num = cold_table_num + 1

	table_num = table_num + 1

	_info.table_id = _table_id
	_info.in_cold = true

end

--玩家的冰冻桌子解封为闲桌子
local function cold_table_change_free(_player_id)

	local _info = DATA.all_player_info[_player_id]

	if not _info.in_cold then
		return 
	end

	local t_info = table_infos[_info.table_id]

	cold_table[_info.table_id] = nil
	cold_table_num = cold_table_num - 1

	free_table[_info.table_id] = _info.table_id
	free_table_num = free_table_num + 1
 
 	_info.in_cold = nil

end


--增加一个新玩家到人最多的桌子
local function add_player_to_max(_player_id)
	local max_num = DATA.game_seat_num - 1
	local c1,c2 = -1,-1
	local _t1,_t2 = nil,nil
	for _t_id,_ in pairs(free_table) do
		local player_num = table_infos[_t_id].player_num
		
		if player_num > c1 then
			_t2 = _t1
			c2 = c1

			_t1 = _t_id
			c1 = player_num

		elseif player_num > c2 then
			_t2 = _t_id
			c2 = player_num
		end

	end

	local _table_id = nil
	
	if math.random(1,100) > 50 then
		_table_id = _t1
	else
		_table_id = _t2
	end

	---- 没有找到就加一个
	if not _table_id then
		_table_id = create_new_table()
	end

	player_join_table(_table_id,_player_id)

	return _table_id
end


--随机分配一个玩家
local function change_player_by_random(_player_id)
	local _cur_table_id = DATA.all_player_info[_player_id].table_id

	local r = math.random(1,free_table_num)

	local _table_id = nil

	local i = 0
	for _t_id,_ in pairs(free_table) do

		i = i + 1
		if i >= r then
			if _t_id ~= _cur_table_id then
				_table_id = _t_id
				break
			end
		end

		if i<r then
			_table_id = _t_id
		end
		
	end

	---- 没有找到就加一个
	if not _table_id then
		_table_id = create_new_table()
	end

	player_join_table(_table_id,_player_id)

end




local players_info_table = {}
local function get_players_info(_table_id)
	
	local _t_d = table_infos[_table_id]

	for k,v in pairs(players_info_table) do
		players_info_table[k]=nil
	end

	for _seat_num,_player_id in pairs(_t_d.player_info) do

		local p_info = DATA.all_player_info[_player_id]
		players_info_table[_seat_num]=
		{
			id=_player_id,
			name=p_info.name,
			head_link=p_info.head_link,
			sex=p_info.sex,
			score=p_info.score,
			seat_num=_seat_num,
			ready=p_info.ready,
		}
	end

	return players_info_table
end


--一个桌子的人打完了
function PROTECTED.table_finish(_room_id,_t_num)
	local players = DATA.running_game[_room_id][_t_num]

	local table_id = nil
	for i,_player_id in pairs(players) do
		DATA.all_player_info[_player_id].ready = 0
		table_id = DATA.all_player_info[_player_id].table_id
	end

	table_infos[table_id].status = nil
	update_table_status(table_id)

end



-- 玩家退出了
function CMD.player_exit_game(_player_id)
	DATA.player_last_opt_time = os.time()

	local player_info = DATA.all_player_info[_player_id]
	local table_info = table_infos[player_info.table_id]

	if table_info.status=="gaming" then
		return {result=1002}
	end

	DATA.all_player_count = DATA.all_player_count - 1 
	DATA.real_player_count = DATA.real_player_count - 1

	--通知当前桌的其他人 我离开了
	for k,player_id in pairs(table_info.player_info) do
		if player_id == _player_id then
			table_info.player_info[k] = nil
			table_info.player_num = table_info.player_num - 1
			update_table_status(player_info.table_id)
		else
			nodefunc.send(player_id,"player_leave_msg",player_info.seat_num )
		end
	end
	DATA.all_player_info[_player_id]=nil

	return {result=0}
end


--[[报名
]]
function CMD.player_signup(player_info)
	DATA.player_last_opt_time = os.time()

	local ok,err = PUBLIC.check_allow_signup()
	if not ok then
		return_table.result = err
		return return_table
	end
	
	DATA.all_player_count=DATA.all_player_count +1 
	DATA.all_player_info[player_info.id]=player_info
	DATA.all_player_info[player_info.id].status = DATA.PlayerStatus.waiting

	--报名进行自动准备
	DATA.all_player_info[player_info.id].ready = 1

	DATA.real_player_count = DATA.real_player_count + 1

	--- 检查是否创建桌子
	check_create_table()

	add_player_to_max(player_info.id)
	local addToTableId = player_info.table_id

	--通知新桌的其他人 我进来了
	for k,palyerId in pairs( table_infos[addToTableId].player_info ) do
		if palyerId ~= player_info.id then
			nodefunc.send(palyerId,"player_join_msg",player_info)
		end
	end

	DATA.player_signup_result_cache.players_info=get_players_info(addToTableId)

	return DATA.player_signup_result_cache
end


function CMD.ready(_my_id)

	---- 记录状态
	local playerInfo = DATA.all_player_info[_my_id]
	playerInfo.status = DATA.PlayerStatus.ready
	playerInfo.ready = 1
	playerInfo.in_cold_time = nil

	cold_table_change_free(_my_id)

	--通知其他人 我准备了
	if playerInfo.table_id and table_infos[playerInfo.table_id] and table_infos[playerInfo.table_id].player_info then
		for k,palyerId in pairs( table_infos[playerInfo.table_id].player_info ) do
			if palyerId ~= _my_id then
				nodefunc.send(palyerId,"fg_ready_msg",playerInfo.seat_num)
			end
		end
	end
	
	---- 检查桌子是否可以开始
	chk_table_begin(playerInfo.table_id)

	return {result=0}
end


function CMD.cancel_ready(_my_id)
	---- 记录状态
	--[[local playerInfo = DATA.all_player_info[_my_id]
	playerInfo.status = DATA.PlayerStatus.waiting

	--通知其他人 我取消准备了
	for k,palyerId in pairs(  table_infos[playerInfo.table_id].player_info ) do
		if palyerId ~= _my_id then
			nodefunc.send(palyerId,"fg_ready_msg",k)
		end
	end--]]
	
	return {result=0}
end


--[[ 报名
-- 返回值：
--{
--	result  , -- 0 或错误
	playerinfo
-- }
--]]
function CMD.huanzhuo(_my_id)

	local playerInfo = DATA.all_player_info[_my_id]
	local tableInfo = table_infos[playerInfo.table_id]

	if tableInfo.status=="gaming" then
		return {result=1002}
	end

	--通知当前桌的其他人 我离开了
	if tableInfo then
		for k,palyerId in pairs(tableInfo.player_info) do
			if palyerId ~= _my_id then
				nodefunc.send(palyerId,"player_leave_msg", playerInfo.seat_num )
			end
		end
	end

	--换桌先自动准备 避免未开始比赛
	playerInfo.ready = 1
	playerInfo.in_cold_time = nil
	playerInfo.in_cold = nil

	change_player_by_random(_my_id)
	
	local tableInfo = table_infos[playerInfo.table_id]
	--通知新桌的其他人 我进来了
	for k,palyerId in pairs(tableInfo.player_info) do
		if palyerId ~= _my_id then
			nodefunc.send(palyerId,"player_join_msg", playerInfo )
		end
	end

	local players_info=get_players_info(playerInfo.table_id)

	return {result=0,players_info=players_info}
end





--[[回收
	注意桌子的操作都是无挂起的(没有call的调用)
	因此回收都是安全
]]
local function recycle_update(dt)

	if recycle_time < os.time() then
		recycle_time = os.time() + recycle_interval

		--桌子的数量比较大的时候
		if table_num > table_min_num then

			--大部分都是空桌子的时候
			if free_table_num > table_num * 0.6 then

				local recycle_tables_id = {}

				for id,v in pairs(free_table) do
					if table_infos[id].player_num < 1 then
						recycle_tables_id[#recycle_tables_id+1]=id
					end
				end

				if #recycle_tables_id > table_min_num then
					for i=1,#recycle_tables_id-table_min_num do
						local table_id = recycle_tables_id[i]
						
						table_infos[table_id] = nil
						table_num = table_num - 1

						free_table[table_id] = nil
						free_table_num = free_table_num - 1

						print("recycle_tables_id:"..table_id)
					end
				end

			end

		end
		
	end

end


--[[冰冻检测
	30s 并且桌子不是满的
]]
local function cold_update(dt)
	
	if cold_time < os.time() then

		cold_time = os.time() + cold_interval

		for _player_id,_info in pairs(DATA.all_player_info) do
			if (not _info.in_cold) and _info.in_cold_time and os.time() > _info.in_cold_time then

				player_join_cold_table(_player_id)

			end
		end

	end

end

function PROTECTED.update(dt)
	recycle_update(dt)
	cold_update(dt)
end

return PROTECTED

