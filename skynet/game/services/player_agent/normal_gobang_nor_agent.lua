--
-- Author: HEWEI
-- Date: 2018/3/28
-- Time: 
require "normal_enum"
local skynet = require "skynet_plus"
local basefunc=require"basefunc"
local nodefunc = require "nodefunc"
require"printfunc"
local base = require "base"
local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC
local REQUEST=base.REQUEST
local PROTECT={}


--比赛阶段
--[[

	ready： 准备阶段
	begin: 开始阶段
	jdz： 叫地主阶段
			set_dz： 设置地主   or     q_dizhu  抢地主阶段
			jiabei： 加倍阶段  
	cp： 出牌阶段
	settlement： 结算
	gameover ：游戏结束

--]]

--[[
	status_info={
			status=nil,
			countdown=0,
			cur_p=0,

			--当前是第几把
			cur_race=0,
			--一共几把
			race_count=0,
			--基础分数（低分）
			init_stake=1,
			--基础倍数（低倍）
			init_rate=1,

			--总玩家数
			player_count=0,

			room_id=_room_id,
			--桌号
			t_num=_t_num,


			--我的牌列表
			my_pai_list=nil,
			--每个人剩余的牌
			remain_pai_amount=nil,
			--我的倍数
			my_rate=0,
			--动作序列--保留最近两次的即可
			act_list={},
			--玩家的托管状态
			auto_status={0,0,0},
			dizhu=0,
			dz_pai=nil,
		},
	}
--]]

local my_game_name="nor_gobang_nor"
local kaiguan
--上层  model的数据
local all_data

local jdz_type


--动作标记
local act_flag=false

--状态信息
local s_info

local settlement_info

local overtime_cb = nil

-- 对局总时长
local race_time_count = 360
-- 每次操作时间
local oper_time_count = 30

local update_timer
--update 间隔
local dt=0.5
--返回优化，避免每次返回都创建表
local return_msg={result=0}


local function add_status_no()
	all_data.status_no=all_data.status_no+1
end

local function set_overtime_cb(func)
	overtime_cb=func
end

local function call_room_service(_func_name,...)

	return nodefunc.call(s_info.room_id,_func_name,s_info.t_num,s_info.seat_num,...)

end

local function send_room_service(_func_name,...)

	nodefunc.send(s_info.room_id,_func_name,s_info.t_num,s_info.seat_num,...)

end


local function update()
	
	if s_info and s_info.countdown and s_info.countdown>0 then

		--正常流程的更新
		s_info.countdown=s_info.countdown-dt
		if s_info.countdown<=0 then
			if overtime_cb then 
				overtime_cb()
			end
		end
	end
end

local function new_game()
	--一把游戏开始的时间
	DATA.one_game_begin_time=os.time()

	s_info.countdown=0
	s_info.countdown_max=oper_time_count
	s_info.p_race_time_max=race_time_count
	s_info.cur_p=0

	--动作序列
	s_info.act_list={}

	s_info.settlement_info=nil
	s_info.first_seat = 0

	s_info.p_race_times = {race_time_count, race_time_count}

end


local function init_game()
	s_info.status="wait_join"
	s_info.cur_race=1
	s_info.next_race=1
end

function PROTECT.join_room(_data)
	--加入房间
	_data.is_robot = s_info.is_robot
	local return_data=nodefunc.call(s_info.room_id,"join",s_info.t_num,DATA.my_id,_data)
	if return_data=="CALL_FAIL" or return_data ~= 0 then
		dump(return_data)
		skynet.fail(string.format("join_game_room error:call return %s",tostring(return_data)))
		return false
	end
	return true
end

function PROTECT.ready(_data)

	if act_flag
		or not s_info
		or not s_info.ready
		or not s_info.seat_num
		or s_info.ready[s_info.seat_num]~=0
		or s_info.is_over == 1
		then
		return_msg.result=1008
		return return_msg
	end
 
 	act_flag = true

	local ret = call_room_service("ready")
	return_msg.result = ret.result

	--[[if return_msg.result == 0 then
		s_info.status="ready"
		s_info.cur_race=s_info.next_race
	end--]]
	act_flag = false

	return return_msg
end



function REQUEST.nor_gobang_nor_renshu(self)
	if act_flag 
		or not s_info 
		or s_info.status~="xq" then
			return_msg.result=1002
			return return_msg
	end
end

function REQUEST.nor_gobang_nor_xiaqi(self)
	if act_flag 
		or not s_info 
		or s_info.status~="xq" then
			return_msg.result=1002
			return return_msg
	end

	act_flag = true

	if tonumber(self.pos) and tonumber(self.pos) > 0 then
		return_msg.result = call_room_service("xiaqi", self.pos)
	else
		return_msg.result = 1001
	end

	act_flag = false
	return return_msg
end


function CMD.nor_gobang_nor_join_msg(_info,_my_join_return)

	if _info and _info.id~=DATA.my_id then
		if all_data.m_PROTECT and all_data.m_PROTECT.player_join_msg then
			all_data.m_PROTECT.player_join_msg(_info)
		end
	else

		s_info.status="ready"
		s_info.ready=_my_join_return.ready
		s_info.seat_num=_my_join_return.seat_num

		s_info.init_rate=_my_join_return.init_rate
		s_info.init_stake=_my_join_return.init_stake
		s_info.race_count=_my_join_return.race_count
		
		s_info.cur_race=_my_join_return.cur_race
		s_info.player_count=_my_join_return.seat_count

		if all_data.m_PROTECT and all_data.m_PROTECT.my_join_return then
			all_data.m_PROTECT.my_join_return(_my_join_return)
		end
		if _my_join_return.chat_room_id then
			DATA.chat_room_id=_my_join_return.chat_room_id
			skynet.call(DATA.service_config.chat_service,"lua","join_room", DATA.chat_room_id,DATA.my_id,PUBLIC.get_gate_link())
		end

	end
end

function CMD.nor_gobang_nor_ready_msg(_seat_num)
	s_info.ready[_seat_num]=1
	
	if _seat_num == s_info.seat_num then
		new_game()
		s_info.status="ready"
		s_info.cur_race=s_info.next_race
	end

	add_status_no()
	PUBLIC.request_client("nor_gobang_nor_ready_msg",
		{
		status_no = all_data.status_no,
		seat_num = _seat_num,
		cur_race = s_info.cur_race,
		})
end

-- by lyx 改变钱
function CMD.nor_gobang_nor_modify_score(_score)
	if all_data.m_PROTECT and all_data.m_PROTECT.modify_score then
		return all_data.m_PROTECT.modify_score(_score)
	else
		return _score
	end
end

function CMD.nor_gobang_nor_begin_msg(_cur_race,_again)
	add_status_no()
	s_info.status="begin"
	if _again then
		new_game()
	end
	s_info.ready=nil
	PUBLIC.request_client("nor_gobang_nor_begin_msg",
												{
												status_no=all_data.status_no,
												cur_race=s_info.cur_race,
												p_race_times=s_info.p_race_times,
												countdown_max=s_info.countdown_max,
												p_race_time_max=s_info.p_race_time_max,
												})

	if all_data.m_PROTECT and all_data.m_PROTECT.begin_msg then
		all_data.m_PROTECT.begin_msg(_cur_race,_again)
	end	
end

--下棋权限
function CMD.nor_gobang_nor_xq_permit(_cur_p, tt)
	s_info.status="xq"
	s_info.cur_p=_cur_p

	s_info.countdown = tt
	
	if s_info.seat_num==_cur_p then
		s_info.oper_begin_time = os.time()
		local _overtime_cb=function ()

						overtime_cb=nil

						call_room_service("xiaqi_timeout")
					end
		set_overtime_cb(_overtime_cb)
	end
	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_gobang_nor_permit_msg",{status_no=all_data.status_no,status=s_info.status,countdown=s_info.countdown,cur_p=_cur_p})
end

--下棋
function CMD.nor_gobang_nor_xiaqi_msg(_cur_p, pos, race_time)

	if s_info.seat_num==_cur_p then
		set_overtime_cb(nil)
	end

	--通知客户端
	local action = {}
	action.type = "xq"
	action.p = _cur_p
	action.pos = pos
	action.race_time = race_time
	s_info.p_race_times[_cur_p] = race_time

	s_info.act_list[#s_info.act_list+1]=action

	add_status_no()
	PUBLIC.request_client("nor_gobang_nor_action_msg",{status_no=all_data.status_no,action=action})
end


--下棋
function CMD.nor_gobang_nor_xhz_msg(first_seat)
	--通知客户端
	s_info.first_seat = first_seat

	add_status_no()
	PUBLIC.request_client("nor_gobang_nor_xhz_msg",{status_no=all_data.status_no,first_seat=first_seat})
end

-- by lyx 改变钱
function CMD.nor_gobang_nor_modify_score(_score)
	if all_data.m_PROTECT and all_data.m_PROTECT.modify_score then
		return all_data.m_PROTECT.modify_score(_score)
	else
		return _score
	end
end

-- by lyx 分数改变
function CMD.nor_gobang_nor_score_change_msg(_data)
	-- 斗地主不需要发  因为中途不会改变
	local send_data={}
	if _data then
		for p,s in pairs(_data) do
			send_data[#send_data+1]={cur_p=p,score=s.score}
		end
	end

	-- add_status_no()
	PUBLIC.request_client("nor_gobang_nor_score_change_msg",{status_no=all_data.status_no,data=send_data})
	
	if all_data.m_PROTECT and all_data.m_PROTECT.score_change_msg then 
		all_data.m_PROTECT.score_change_msg(_data)
	end

end

--单局结算
function CMD.nor_gobang_nor_settlement_msg(_settlement_info,is_over,_log_id)
	s_info.status="settlement"

	settlement_info=_settlement_info

	s_info.settlement_info=settlement_info

	if not is_over then
		s_info.ready={0,0,0}
		s_info.next_race=s_info.cur_race + 1
	end

	s_info.is_over = is_over and 1 or 0
	local settle_data = {}
	settle_data.scores = {}
	for k,v in ipairs(settlement_info.award) do
		settle_data.scores[k] = v
	end
	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_gobang_nor_settlement_msg",
								{status_no=all_data.status_no,
								settlement_info=settlement_info,
								is_over = s_info.is_over,
								})

	-- skynet.send(DATA.service_config.data_service,"lua","update_statistics_player_gobang_win_data",DATA.my_id,t)

	local lose_surplus = settlement_info.lose_surplus
	if all_data.m_PROTECT and all_data.m_PROTECT.game_settlement_msg then
		all_data.m_PROTECT.game_settlement_msg(settle_data,is_over,lose_surplus,_log_id)
	end 
end


function CMD.nor_gobang_nor_gameover_msg(_data)
	--游戏结束就清除
	DATA.one_game_begin_time=nil

	s_info.status = "gameover"


	if all_data and all_data.m_PROTECT and all_data.m_PROTECT.game_gameover_msg then
		all_data.m_PROTECT.game_gameover_msg(_data)
	end

	if  DATA.chat_room_id then
		skynet.send(DATA.service_config.chat_service,"lua","exit_room", DATA.chat_room_id,DATA.my_id)
		DATA.chat_room_id = nil
	end 
end



function CMD.nor_gobang_nor_next_game_msg(_data)

	add_status_no()

	PUBLIC.request_client("nor_gobang_nor_new_game_msg",
							{
							status_no=all_data.status_no,
							status=s_info.status,
							cur_race=_data,
							})


	if all_data.m_PROTECT and all_data.m_PROTECT.game_next_game_msg then
		all_data.m_PROTECT.game_next_game_msg(_data)
	end
	
end



function PROTECT.get_status_info()
	return s_info
end



--[[

	游戏配置_config: 

	seat_num
	init_stake
	init_rate
	cur_race
	race_count
	player_count


	--配置
	--超时出牌计数N次就自动托管cfg
	auto_count_cfg
	--托管后自动出牌的时间cfg
	auto_wait_cp_time_cfg
	--超时后是否需要自动操作 1 需要 0 不需要
	overtime_auto_action_cfg


	--房间信息
	room_id
	--桌子号
	t_num

--]]

function PROTECT.init_agent_cfg(_config)
end

function PROTECT.init_base_info(_config)

	s_info.room_id=_config.room_id
	s_info.t_num=_config.t_num

	--底分
	s_info.init_stake=_config.init_stake or 1
	s_info.init_rate=_config.init_rate or 1
	s_info.race_count=_config.race_count or 1


	-- 第一个玩家刚进来的时候没有数据 这里提前进行初始化

	s_info.countdown=0
	s_info.cur_p=0
	--我的倍数
	s_info.my_rate=all_data.config.init_rate or 1
	--动作序列--保留最近两次的即可
	s_info.act_list={}
	--玩家的托管状态
	s_info.auto_status={0,0,0}
	s_info.dizhu=0
	--癞子牌的牌类型
	s_info.laizi=0
	--我的癞子牌数量
	s_info.laizi_num=0
	--加倍
	s_info.jiabei=0	

	--有时候座位号已经存在了
	if all_data.room_info 
		and all_data.room_info.seat_num then
		s_info.seat_num = all_data.room_info.seat_num
	end

	--总玩家数
	s_info.player_count=_config.player_count or 3

	s_info.status="ready"
end

function PROTECT.free()
	if update_timer then
		update_timer:stop()
		update_timer=nil
	end
	all_data=nil
	act_flag=false
	overtime_count=0
	s_info=nil
	auto_data=nil
	overtime_cb=nil
end

function PROTECT.init(_all_data)
	PROTECT.free()
	
	all_data=_all_data

	all_data.game_data={}

	s_info=all_data.game_data

	if not basefunc.chk_player_is_real(DATA.my_id) then
		s_info.is_robot=true
	end

	init_game()

	PROTECT.init_agent_cfg(all_data.config.agent_cfg)

	PROTECT.init_base_info(all_data.base_info)

	update_timer=skynet.timer(dt,update)

	my_game_name=_all_data.game_type


end





return PROTECT


