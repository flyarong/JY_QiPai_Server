local base=require "base"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA
local PROTECTED = {}

--人满匹配



-- 撤销报名
function CMD.cancel_signup(_my_id)
	DATA.player_last_opt_time = os.time()
	
	if DATA.wait_player[_my_id] then
		DATA.wait_player[_my_id]=nil
		DATA.all_player_info[_my_id]=nil
			DATA.all_player_count=DATA.all_player_count-1
			DATA.wait_player_count=DATA.wait_player_count-1
			DATA.real_player_count = DATA.real_player_count - 1
		return 0
	end

	return 2004
end


--[[ 报名
-- 返回值：
--{
--	result  , -- 0 或错误
-- }
--]]
function CMD.player_signup(_my_id)
	DATA.player_last_opt_time = os.time()
	-- 注意：此函数内 不要call 别的，避免挂起 导致 重入

	-- 判断条件 ###_temp 不能 有因人数 导致的失败
	local ok,err = PROTECTED.check_allow_signup()
	if not ok then
		return_table.result = err
		return return_table
	end

	DATA.wait_player[_my_id]={status="waiting",id=_my_id}
	DATA.wait_player_count=DATA.wait_player_count+1
	DATA.all_player_count=DATA.all_player_count +1 
	DATA.all_player_info[_my_id]=DATA.wait_player[_my_id]
	DATA.real_player_count = DATA.real_player_count + 1

	return DATA.player_signup_result_cache
end


--选足够多的人数匹配就行   -- ###_test   按照今天所说的写即可
local function normal_matching()
	local players={}
	for id,v in pairs(DATA.wait_player) do
		local nextIndex = #players+1 
		players[nextIndex]=id
		if #players >= DATA.game_seat_num then
			break
		end
	end
	--加入分配队列
	if #players >= DATA.game_seat_num then
		-- 将要加入分配队列的数组
		local table={}

		--[[--- 处理一下等待的玩家数据,暂为 ，随机打乱
		for i=1 , #players do
			local changeIndex = math.random(1,#players)
			players[i],players[changeIndex] = players[changeIndex],players[i]
		end--]]
		for i=1,DATA.game_seat_num do
			table[#table + 1] = players[i]
		end

		distribution_queue:push_back(table)

		for k,v in ipairs(table) do
			DATA.wait_player[v]=nil
			DATA.wait_player_count=DATA.wait_player_count-1
		end

	end
end

local function matching()
	normal_matching()
	
end


