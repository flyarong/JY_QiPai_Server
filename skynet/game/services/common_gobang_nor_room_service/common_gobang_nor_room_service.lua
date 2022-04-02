--
-- Author: hw
-- Time: 
-- 说明：自由场斗地主桌子服务
--ddz_freestyle_room_service

require "normal_enum"
local skynet = require "skynet_plus"
require "skynet.manager"
require"printfunc"
local nodefunc = require "nodefunc"
local base=require "base"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA
require "common_gobang_nor_room_service/common_gobang_nor_room_record_log"
local gobang_algorithm = require "gobang_algorithm"
local gobang_robot_ai = require "gobang_robot_ai"
local basefunc = require "basefunc"

--房间ID
DATA.my_id = 0

--上级管理者
DATA.mgr_id = 0

--剩余桌子数量
DATA.table_count = 0

--[[
	叫地主方式
	jdz_type
		:  nor --  3人和2人斗地主的普通叫法   三人： 竞技二打一   二人：抢地主  
		:  mld   3人斗地主：闷拉倒方式
--]]

--[[游戏状态表
	玩家位置代号：1，2，3，
	农民代号：4，
	地主代号 5，
	全部 6 
	status :
	wait_p ：等待人员入座阶段 
	ready ： 准备就绪阶段
	fp： 发牌阶段
	jdz： 叫地主阶段
	set_dz： 设置地主
	jiabei： 加倍阶段
	ready_cp:准备出牌阶段
	cp： 出牌阶段
	settlement： 结算
	report： 上报战果
--]]
DATA.service_config = nil

--空闲桌子编号列表
local table_list={}
local game_table={}
--[[
	key=桌子ID  
	value={
				game_config={
					--本局游戏的ID
					id,
				}


				--游戏状态（或者叫游戏阶段）
				staus,
				--游戏数据
				play_data,
				--玩家信息
				p_info,
				--玩家座位号
				p_seat_number,
				--当前玩家人数
				p_count,
				--ready的人数
				p_ready,
				--玩家叫地主的分数
				p_jdz_rate,
				--当前游戏各玩家的倍数
				--玩家托管状态
				p_auto={},
				p_rate={},
				--玩家出牌次数
				p_cp_count={},
				--都不叫地主的次数
				no_dizhu_count=0,
				--炸弹次数
				bomb_count=0,
				--底倍
				init_rate,
				--底分
				init_stake,
				--春天或者反春  1春天  2 反春
				is_chuntian,
				--比赛次数
				race_count,

				}
--]]

--[[

 状态转换示意图

 普通： game_begin -> fp -> jdz -> jiabei -> cp 循环 -> settlement
 无加倍：   game_begin -> fp -> jdz -> cp 循环 -> settlement
--]]

local chessW, chessH = 15, 15
-- 对局总时长
local race_time_count = 360
-- 每次操作时间
local oper_time_count = 30

local run=true


local change_status
local function employ_table()
	local _t_number=table_list[#table_list]
	table_list[#table_list]=nil
	if _t_number then 
		DATA.table_count=DATA.table_count-1
	end
	return _t_number
end
local function return_table(_t_number)
	local _d=game_table[_t_number]
	if DATA.service_config.chat_service and _d and _d.chat_room_id then
		skynet.send(DATA.service_config.chat_service,"lua","destroy_room",_d.chat_room_id)
	end

	game_table[_t_number]=nil
	table_list[#table_list+1]=_t_number
	DATA.table_count=DATA.table_count+1
end


local function new_game(_t_num)
	local _d=game_table[_t_num]
	if not _d then
		return false
	end

	_d.time=0

	_d.cur_race = _d.cur_race + 1

	-- 黑子玩家
	_d.first_seat=0

	--结算信息
	_d.s_info={}
	_d.settlement_info = {}

	_d.ready={0,0}
	_d.p_ready=0
	_d.cur_p = 0

	_d.p_rate=_d.init_rate

	_d.p_race_times = {race_time_count, race_time_count}

	-- 棋盘
	_d.chessboard = {}
	for i = 1, chessW do
		local data = {}
		_d.chessboard[i] = data
		for j = 1, chessH do
			data[j] = 0
		end
	end
	-- 操作队列
	_d.oper_list = {}
	_d.oper_time = {0, 0}

	change_status(_t_num,"wait_p")


	--记录游戏开始日志
	-- PUBLIC.save_race_start_log(_d,_t_num)

end

-- 加减 一个 人的钱
local function change_one_player_score(_d,_seat_num,_score)
	if _d.p_seat_number[_seat_num] then
		return nodefunc.call(_d.p_seat_number[_seat_num],"nor_gobang_nor_modify_score",_score)
	else
		if _d.back_money_cmd then
			local s = nodefunc.call(DATA.mgr_id,_d.back_money_cmd,_d.p_seat_number[_seat_num],_score)
			if type(s) == "number" then
				return s
			else
				return _score
			end
		else
			-- 当前不管 直接吃掉
			-- 玩家中途不可以退出 | 中途可以的退出情况，管理者没有对应的逻辑
			-- print("error !!! : common_mj_xzdd_room_service change_one_player_score back_money_cmd is nil")
			return _score
		end
	end
end


local function ready(_t_num,_seat_num)
	local _d = game_table[_t_num]

	if _d.ready[_seat_num]==0 then
		_d.ready[_seat_num]=1

		for _s,_id in pairs(_d.p_seat_number) do
			nodefunc.send(_id,"nor_gobang_nor_ready_msg",_seat_num)
		end

		_d.p_ready=_d.p_ready+1
		if _d.p_ready==_d.seat_count then 
			change_status(_t_num,"game_begin")
		end

	end

end


local function game_begin(_t_num)

	local _d = game_table[_t_num]

	-- 向 player agent 发送消息
	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nor_gobang_nor_begin_msg",_d.cur_race)
	end
	
	change_status(_t_num,"wait",1,"xhz")

	PUBLIC.save_race_start_log(_d,_t_num)

end

local function select_black(_t_num)
	local _d = game_table[_t_num]
	local r = math.random(1, _d.seat_count)
	_d.first_seat = r
	-- 向 player agent 发送消息
	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nor_gobang_nor_xhz_msg", r)
	end
	change_status(_t_num,"wait",1,"xq")
end

local function xiaqi_permit(_t_num)
	local _d = game_table[_t_num]
	if _d.cur_p == 0 then
		_d.cur_p = _d.first_seat
	else
		_d.cur_p = _d.cur_p + 1
		if _d.cur_p > _d.seat_count then
			_d.cur_p = 1
		end
	end
	local _d = game_table[_t_num]

	_d.oper_begin_time = os.time()
	local tt = math.min(_d.p_race_times[_d.cur_p], oper_time_count)
	_d.cur_max_oper_time = tt
	-- 向 player agent 发送消息
	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nor_gobang_nor_xq_permit", _d.cur_p, tt)
	end

	PUBLIC.save_gobang_process_get_permit_time(_d,_t_num)

end

local function settlement(_t_num)
	local _d = game_table[_t_num]
	local ss
	if _d.settlement_info.type == "timeout_ju" then
		_d.p_rate = _d.init_rate * 1
		ss = _d.init_stake * _d.init_rate
	elseif _d.settlement_info.type == "timeout_bu" then
		_d.p_rate = _d.init_rate * 1
		ss = _d.init_stake * _d.init_rate
	elseif _d.settlement_info.type == "renshu" then
		_d.p_rate = _d.init_rate * 1
		ss = _d.init_stake * _d.init_rate
	elseif _d.settlement_info.type == "qi_pan_xia_man" then
		_d.p_rate = _d.init_rate * 0
		ss = 0
	elseif _d.settlement_info.type == "nor" then
		_d.p_rate = _d.init_rate * 1
		ss = _d.init_stake *_d.p_rate
	else
		print("错误的结算类型")
		ss = 0
	end

	---
	local _score_change = {}
	_d.settlement_info.award = {}
	_d.settlement_info.score = {}
	local lose_surplus = {0,0}

	local _score_sum = 0
	for i=1, _d.seat_count do
		if _d.settlement_info.win_seat == i then

		else
			_d.settlement_info.score[i] = ss
			
			--- 资产改变
			local deduct = change_one_player_score(_d,i, -_d.settlement_info.score[i])   --- -100
			local ls = _d.settlement_info.score[i] + deduct                              --- 100

			lose_surplus[i] = lose_surplus[i] + ls                                       --- 100

			_d.settlement_info.award[i] = deduct

			_score_change[i] =  { score = deduct , lose_surplus = lose_surplus[i] }
			_score_sum = _score_sum + deduct
		end

		
	end


	--- 资产改变
	local win_seat = _d.settlement_info.win_seat
	_score_sum = math.floor(math.abs(_score_sum) + 0.5)
	local deduct = change_one_player_score(_d, win_seat , _score_sum)   
	--local ls = _d.settlement_info.score[win_seat] + deduct                              
	lose_surplus[win_seat] = 0                                      
	_d.settlement_info.award[win_seat] = deduct
	_score_change[win_seat] = { score = _d.settlement_info.award[win_seat] , lose_surplus = lose_surplus[win_seat] }

	_d.settlement_info.p_rate = _d.p_rate
	local is_over = _d.race_count<=_d.cur_race
	
	_d.settlement_info.lose_surplus = lose_surplus
	for _seat_num,_id in pairs(_d.p_seat_number) do
		--参数：  状态,倒计时_d.status
		nodefunc.send(_id,"nor_gobang_nor_settlement_msg", _d.settlement_info, is_over)
	end

	PUBLIC.save_race_over_log(_d,_t_num)

	change_status(_t_num,"wait",1,"next_game")


	-- 给每个人发 钱变化通知消息
	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nor_gobang_nor_score_change_msg",_score_change)
	end

end

local function next_game(_t_num)
	local _d=game_table[_t_num]
	if not _d then
		return false
	end

	if _d.race_count>_d.cur_race then 
		--重新发牌 todo 以前没有延迟1秒执行
		new_game(_t_num)

		local _d=game_table[_t_num]
		if not _d then
			return false
		end

		--新的一局
		for _seat_num,_id in pairs(_d.p_seat_number) do
			nodefunc.send(_id,"nor_gobang_nor_next_game_msg",_d.cur_race)
		end
	else
		change_status(_t_num, "gameover")
	end
end


--结算中 通知给玩家
local function gameover(_t_num)

	local _d = game_table[_t_num]

	--通知
	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nor_gobang_nor_gameover_msg",{})
	end

	nodefunc.call(DATA.mgr_id,"table_finish",DATA.my_id,_t_num)

	return_table(_t_num)

	nodefunc.send(DATA.mgr_id,"return_table",DATA.my_id,_t_num)

end

local function _impl_change_status(_t_num,_status,_time,_next_status)
	assert(game_table[_t_num])
	print("change_status  : ",_status,DATA.my_id,_t_num)

	game_table[_t_num].time=_time

	-- 等待指定的时间 改变状态
	if not _status then 
		game_table[_t_num].next_status=_next_status
		return 
	end			

	if _status=="wait_p" then
		game_table[_t_num].status=_status
	elseif _status=="ready" then				-- 游戏准备中
		game_table[_t_num].status=_status
	elseif _status=="game_begin" then				-- 游戏开始
		game_table[_t_num].status=_status
		game_begin(_t_num)
	elseif _status=="wait" then
		game_table[_t_num].status=_status
		game_table[_t_num].next_status=_next_status
	elseif _status=="xhz" then 
		game_table[_t_num].status=_status
		select_black(_t_num)
	elseif _status=="next_game" then
		game_table[_t_num].status=_status
		next_game(_t_num)
	elseif _status=="xq" then
		game_table[_t_num].status=_status
		xiaqi_permit(_t_num)
	elseif _status=="settlement" then
		game_table[_t_num].status=_status
		settlement(_t_num)
	elseif _status=="gameover" then
		game_table[_t_num].status=_status
		gameover(_t_num)
	end 
end

change_status = _impl_change_status


local dt=0.5
local function update()
	while run do
		for _t_num,_value in pairs(game_table) do

			if _value.time then
				_value.time = _value.time-dt 
				if _value.time<=0 then
					_value.time = nil
					change_status(_t_num,_value.next_status)
				end	
			end

		end

		skynet.sleep(dt*100)
	end
end

-- 参数 _table_config ：
--	model_name   游戏模式名字，比如： "friendgame"，用于 game_begin 时回传给 player agent
--  rule_config	 玩法规则配置： 和 
--		kaiguan 开关
--		multi 番数
--	game_config  游戏配置
--		init_stake   底分
--		init_rate 	 底倍
--		race_count 	 一共几把
-- 参数 _env ：
--	game_id		 游戏 id ，用于记录日志
--	back_money_cmd	备用的金币访问 cmd ，参数： _userId,_score
function CMD.new_table(_table_config,_env)
	local _t_num=employ_table()
	if not _t_num then 
		return false
	end
	local _d={}

	_d.table_config=_table_config

	_d.time=0
	_d.p_info={}
	--玩家进入房间的标记
	_d.players_join_flag={}
	_d.p_seat_number={}
	_d.p_count=0

	--游戏类型  0为 练习场  1为钻石场
	--_d.game_model=_game_config.game_model or 0 

	_d.init_rate=_table_config.game_config.init_rate or 1
	_d.init_stake=_table_config.game_config.init_stake or 1

	_d.seat_count = GAME_TYPE_SEAT[DATA.game_type] or 2

	--比赛次数
	_d.race_count=_table_config.game_config.race_count or 1

	_d.game_tag = _table_config.game_tag

	_d.cur_race=0

	_d.model_name = _table_config.model_name
	_d.game_type = _table_config.game_type
	_d.game_id = _env.game_id

	_d.back_money_cmd = _table_config.back_money_cmd

	-- _d.p_auto={}

	game_table[_t_num]=_d

	--###_test  目前是默认创建  可以考虑根据条件创建 比如（根据房卡场等来默认创建）
	if DATA.service_config.chat_service then
		_d.chat_room_id = skynet.call(DATA.service_config.chat_service,"lua","create_room")
	end

	new_game(_t_num)

	return _t_num
end


function CMD.get_free_table_num()
	return #table_list
end


function CMD.destroy()
	run=nil
   	nodefunc.destroy(DATA.my_id)
	skynet.exit()
end


function CMD.join(_t_num,_p_id,_info)
	local _d=game_table[_t_num]

	if not _d or _d.p_count>_d.seat_count or _d.status~="wait_p" or _d.players_join_flag[_p_id] then
		return 1002
	end

	local _seat_num = _info.seat_num
	
	if not _seat_num then
		for sn=1,_d.seat_count do
			if not _d.p_seat_number[sn] then
				_seat_num = sn
				break
			end
		end
	end

	if not _seat_num then
		return 1000
	end

	_d.players_join_flag[_p_id]=true 
	_d.p_seat_number[_seat_num]=_p_id
	_d.p_count=_d.p_count+1
	_d.p_info[_seat_num]=_info
	_d.p_info[_seat_num].seat_num=_seat_num

	local my_join_return={
			seat_num=_seat_num,
			p_info=_d.p_info,
			p_count=_d.p_count,
			ready=_d.ready,
			init_rate=_d.init_rate,
			race_count=_d.race_count,
			cur_race=_d.cur_race,
			init_stake=_d.init_stake,
			mgr_id = DATA.mgr_id,
			rule_config=_d.table_config.rule_config,
			seat_count=_d.seat_count,
			chat_room_id=_d.chat_room_id,
		}
	--通知其他人 xxx 加入房间
	for _,_value in pairs(_d.p_info) do
		if _value.id~=_p_id then
			nodefunc.send(_value.id,"nor_gobang_nor_join_msg",_info)
		else
			nodefunc.send(_value.id,"nor_gobang_nor_join_msg",nil,my_join_return)
		end
	end

	return 0

end

function CMD.ready(_t_num,_seat_num)
	ready(_t_num,_seat_num)

	return {result=0}
end
function CMD.xiaqi_renshu(_t_num,_seat_num)
	local _d=game_table[_t_num]
	_d.settlement_info.type = "renshu"
	local win_seat = _seat_num + 1
	if win_seat > _d.seat_count then
		win_seat = 1
	end
	_d.settlement_info.win_seat = win_seat
	change_status(_t_num,"settlement")
end


---[[
function CMD.xiaqi_timeout(_t_num,_seat_num)
	local _d=game_table[_t_num]
	_d.p_race_times[_seat_num] = _d.p_race_times[_seat_num] - _d.cur_max_oper_time
	if _d.p_race_times[_seat_num] < 1 then
		_d.settlement_info.type = "timeout_ju"
	else
		_d.settlement_info.type = "timeout_bu"
	end

	local win_seat = _seat_num + 1
	if win_seat > _d.seat_count then
		win_seat = 1
	end
	_d.settlement_info.win_seat = win_seat
	change_status(_t_num,"settlement")
end
--]]

--[[

-- 托管状态自动下棋
local function auto_xiaqi(_t_num,_seat_num, pos)
	local _d=game_table[_t_num]
	if _d.status ~= "xq" or _d.cur_p ~= _seat_num then
		return 1002
	end
	local dd = gobang_algorithm.parse_pos(pos)
	local x = dd.x
	local y = dd.y
	if x < 1 or x > chessW or y < 1 or y > chessH then
		return 1001
	end
	if _d.chessboard[x][y] ~= 0 then
		return 1001
	end

	local c = _d.first_seat == _seat_num and 1 or 2
	_d.chessboard[x][y] = c
	_d.oper_list[#_d.oper_list+1] = pos

	_d.p_race_times[_seat_num] = _d.p_race_times[_seat_num] - (os.time() - _d.oper_begin_time)

	for _s,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nor_gobang_nor_xiaqi_msg",_seat_num, pos, _d.p_race_times[_seat_num])
	end

	if gobang_algorithm.check_win(x, y, _d.chessboard) then
		_d.settlement_info.type = "nor"
		_d.settlement_info.win_seat = _seat_num
		change_status(_t_num,"wait",1,"settlement")
	else
		if #_d.oper_list == chessH * chessW then
			_d.settlement_info.win_seat = 0
			_d.settlement_info.type = "qi_pan_xia_man"
			change_status(_t_num,"wait",1,"settlement")
		else
			change_status(_t_num,"wait",1,"xq")
		end
	end

	return 0
end
function CMD.xiaqi_timeout(_t_num,_seat_num)
	local _d=game_table[_t_num]
	local _rt = _d.p_race_times[_seat_num] - _d.cur_max_oper_time
	if _rt < 1 then
		_d.settlement_info.type = "timeout_ju"
		local win_seat = _seat_num + 1
		if win_seat > _d.seat_count then
			win_seat = 1
		end
		_d.settlement_info.win_seat = win_seat
		change_status(_t_num,"settlement")
		return
	end

	local c = 2
	if _seat_num == _d.first_seat then
		c = 1
	end
	local x,y = gobang_robot_ai.runAI(_d.chessboard, chessW, chessH, c)
	local pos = gobang_algorithm.pack_pos({x=x,y=y,c=c})
	auto_xiaqi(_t_num,_seat_num, pos)
end
--]]

function CMD.xiaqi(_t_num,_seat_num, pos)
	local _d=game_table[_t_num]
	if _d.status ~= "xq" or _d.cur_p ~= _seat_num then
		return 1002
	end
	local dd = gobang_algorithm.parse_pos(pos)
	local x = dd.x
	local y = dd.y
	if x < 1 or x > chessW or y < 1 or y > chessH then
		return 1001
	end
	if _d.chessboard[x][y] ~= 0 then
		return 1001
	end

	local c = _d.first_seat == _seat_num and 1 or 2
	_d.chessboard[x][y] = c
	_d.oper_list[#_d.oper_list+1] = pos

	_d.p_race_times[_seat_num] = _d.p_race_times[_seat_num] - (os.time() - _d.oper_begin_time)

	for _s,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nor_gobang_nor_xiaqi_msg",_seat_num, pos, _d.p_race_times[_seat_num])
	end

	if gobang_algorithm.check_win(x, y, _d.chessboard) then
		_d.settlement_info.type = "nor"
		_d.settlement_info.win_seat = _seat_num
		change_status(_t_num,"wait",1,"settlement")
	else
		if #_d.oper_list == chessH * chessW then
			_d.settlement_info.win_seat = 0
			_d.settlement_info.type = "qi_pan_xia_man"
			change_status(_t_num,"wait",1,"settlement")
		else
			change_status(_t_num,"wait",1,"xq")
		end
	end

	PUBLIC.save_process_data_log(_d,_t_num,_seat_num,1,{x,y})
	
	return 0
end

function CMD.start(_id,_ser_cfg,_config)
	math.randomseed(os.time()*72453) 
	DATA.service_config =_ser_cfg
	DATA.table_count=10
	DATA.my_id=_id
	DATA.mgr_id=_config.mgr_id
	DATA.game_type=_config.game_type

	--init table
	for i=1,DATA.table_count do 
		table_list[#table_list+1]=i
	end

	skynet.fork(update)

	return 0
end

-- 启动服务
base.start_service()
