--
-- Author: hw
-- Time: 
-- 说明：自由场斗地主桌子服务
--ddz_freestyle_room_service

require "normal_enum"
local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"
require"printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECTED = {}

local robot_names_boy = require "robot_names_boy"
local robot_names_girl = require "robot_names_girl"
local robot_images_boy = require "robot_images_boy"
local robot_images_girl = require "robot_images_girl"


local tuoguan_data_clear_time = 2*60

local tuoguan_enter_config = 
{
	time=
	{--人数对应改变的时间范围
		[1] = {10,40},
		[2] = {2*60,3*60},
		[3] = {5*60,8*60},
		[4] = {60,2*60},
	},

	-- 转换到目标人数的权重概率
	[1] = {n={1,2},pro={0,1}},
	[2] = {n={1,2,3},pro={1,2,7}},
	[3] = {n={2,3,4},pro={1,3,1}},
	[4] = {n={3,4},pro={5,3}},
}

local tuoguan_info_name = {}

local tuoguan_info_head = {}

local tuoguan_data = {}


local function get_tuoguan_info(_seat_num,_game_id)
	
	local n = math.min(#tuoguan_info_name,#tuoguan_info_head)

	n = math.random(1,n)

	local name = tuoguan_info_name[n]
	local head = tuoguan_info_head[n]

	local fish_coin = 0

	if math.random(1,100) > 80 then
		fish_coin = math.random(1000,50000)
	end

	local score = math.random(20000,80000)

	if _game_id == 1 then
		score = math.random(1000,990000)
	elseif _game_id == 2 then
		score = math.random(10000,10000000)
	elseif _game_id == 3 then
		score = math.random(100000,50000000)
	elseif _game_id == 4 then
		score = math.random(300,15000)
	end

	return {
		id="tg_"..math.random(1,80000),
		name=name,
		head_link=head,
		sex=1,
		seat_num=_seat_num,
		score=score,
		fish_coin = fish_coin,
		glory_score = math.random(2000,10000),		
	}

end


-- 托管 破产了
function PROTECTED.tuoguan_broke(_t_num,_seat_num)

	local td = tuoguan_data[_t_num]

	if td then

		if td.tuoguan_info[_seat_num] and not td.tuoguan_exit_time[_seat_num] then

			td.tuoguan_exit_time[_seat_num] = os.time() + math.random(2,10)

		end

	end
	
end


function PROTECTED.update()

	for _t_num,td in pairs(tuoguan_data) do
		
		if td.clear_time and os.time()>td.clear_time then

			tuoguan_data[_t_num] = nil

		else

			local is_change = false
			for s,t in pairs(td.tuoguan_exit_time) do
				if os.time() > t then
					if td.tuoguan_info[s] then
						td.tuoguan_info[s] = nil
						td.tuoguan_num = td.tuoguan_num - 1
						td.exit_cbk(s)
						td.tuoguan_exit_time[s] = nil
						is_change = true
					end
				end
			end

			if is_change then
				-- 有改变 则直接重置改变时间
				local t = tuoguan_enter_config.time[td.tuoguan_num+1]
				td.change_time = os.time() + math.random(t[1],t[2])

			end

			if td.change_time < os.time() then

				local cfg = tuoguan_enter_config[td.tuoguan_num+1]

				local weight_sum = 0

				for i,d in ipairs(cfg.pro) do
					weight_sum = weight_sum + d
				end

				local r = math.random(1,weight_sum)

				local index = 0
				for i,w in ipairs(cfg.pro) do
					r = r - w
					if r < 1 then
						index = i
						break
					end
				end

				local n = cfg.n[index]
				local st = math.random(1,4)

				if n > td.tuoguan_num then
					--找一个空位

					for i=st,999 do
						local s = (i%4)
						if s < 1 then
							s = 4
						end
						if not td.tuoguan_info[s] and s ~= 1 then

							local _info = get_tuoguan_info(s,td.game_id)
							td.tuoguan_info[s] = _info
							td.tuoguan_num = td.tuoguan_num + 1
							td.join_cbk(_info)
							break
						end
					end

				elseif n < td.tuoguan_num then
					--找一个有人的位置

					for i=st,999 do
						local s = (i%4)
						if s < 1 then
							s = 4
						end
						if td.tuoguan_info[s] and s ~= 1 then

							td.tuoguan_info[s] = nil
							td.tuoguan_num = td.tuoguan_num - 1
							td.exit_cbk(s)
							break
						end
					end

				else
				end

				local t = tuoguan_enter_config.time[td.tuoguan_num+1]
				td.change_time = os.time() + math.random(t[1],t[2])

			end

		end

	end

end


-- 托管 信息调整 目前只能修改分数
function PROTECTED.update_tuoguan_info(_t_num,_seat_num,_info)

	local td = tuoguan_data[_t_num]

	if td then

		local ti = td.tuoguan_info[_seat_num]
		if ti then
			
			ti.score = _info.score
			ti.fish_coin = _info.fish_coin


			----- add by wss
			if td.game_id == 4 and ti.score + ti.fish_coin > 20000 then
				td.tuoguan_exit_time[_seat_num] = os.time()

			end

		end

	end

end


-- 真实玩家退出了 准备回收桌子的托管
function PROTECTED.ready_recycle_table(_t_num)

	local td = tuoguan_data[_t_num]

	td.clear_time = os.time() + tuoguan_data_clear_time

end


-- 真实玩家退出了 回收桌子的托管
function PROTECTED.return_table(_t_num)

	tuoguan_data[_t_num] = nil

end



-- 1号位 被占了，剩下 234号位是可入托管的位置
function PROTECTED.init_table(_t_num,_join_cbk,_exit_cbk,_game_id)
	
	local td = tuoguan_data[_t_num]

	if not td then
		
		tuoguan_data[_t_num] = {}
		td = tuoguan_data[_t_num]

		td.join_cbk = _join_cbk
		td.exit_cbk = _exit_cbk
		td.game_id = _game_id
		td.tuoguan_info = {}
		td.tuoguan_exit_time = {}
		td.tuoguan_num = 0
		td.change_time = 0

		for i=2,4 do

			if math.random(1,100) > 30 then

				local _info = get_tuoguan_info(i,td.game_id)
				td.tuoguan_info[i] = _info
				td.tuoguan_num = td.tuoguan_num + 1
				
			end

		end

		local t = tuoguan_enter_config.time[td.tuoguan_num+1]
		td.change_time = os.time() + math.random(t[1],t[2])

	end
	
	td.clear_time = nil

	return td.tuoguan_info

end


function PROTECTED.init()


	local robot_names_boy = basefunc.deepcopy(require "robot_names_boy")
	local robot_names_girl = basefunc.deepcopy(require "robot_names_girl")
	local robot_images_boy = basefunc.deepcopy(require "robot_images_boy")
	local robot_images_girl = basefunc.deepcopy(require "robot_images_girl")

	tuoguan_info_name = robot_names_boy

	for i,v in ipairs(robot_names_girl) do
		tuoguan_info_name[#tuoguan_info_name+1] = v
	end

	for i,v in ipairs(robot_images_boy) do
		tuoguan_info_head[#tuoguan_info_head+1] = "http://jydown.jyhd919.cn/head_images3/" .. v
	end

	for i,v in ipairs(robot_images_girl) do
		tuoguan_info_head[#tuoguan_info_head+1] = "http://jydown.jyhd919.cn/head_images3/" .. v
	end

end


return PROTECTED