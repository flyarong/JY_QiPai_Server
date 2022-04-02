--
-- Author: HEWEI
-- Date: 2018/3/28
-- Time: 
-- 说明：ddz_million_game  缩写 dbwg
local skynet = require "skynet_plus"
local basefunc=require"basefunc"
local nodefunc = require "nodefunc"
require"printfunc"
local normal_ddz = require "normal_ddz_lib"
local base = require "base"
require "normal_enum"
local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC
local REQUEST=base.REQUEST
local PROTECT={}

local game_name="ddz_minilon_game"
--比赛阶段
--[[
	game_stage:
	nil--表示在大厅
	wait_begin  --报名，等待开始{当前报名人数，取消报名倒计时}
	wait_table  --报名结束，等待分配桌子（匹配玩家）
	wait_join   --等待加入房间
	--斗地主阶段
	wait_p：等待人员入座阶段 
	ready： 准备阶段
	fp： 发牌阶段
	jdz： 叫地主阶段
	set_dz： 设置地主
	jiabei： 加倍阶段
	cp： 出牌阶段
	settlement： 结算
	wait_result  --等待比赛结果
	gameover ：游戏结束

--]]

--[[
	DATA.dbwg={
	    match_info={
	    	--游戏名字
	    	name,
	    	--总参与人数
	    	total_players,
	    	--比赛服务ID
	    	match_svr_id,
	    	}
		room_info={
			room_id=_room_id,
			--桌号
			t_num=_t_num,
			seat_num=0,
			--底分
			init_stake=0,
			--底倍
			init_rate=0,
		},
		players_info={
			--玩家信息
			p_info={
				{
					name
					head_link
					seat_num
					sex	
				}
			},
			p_count=0,
		},
		status_info={
			status=nil,
			countdown=0,
			cur_p=0,
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
			--当前报名人数
			signup_num=0,
			grades,
			rank,
			dizhu=0,
			dz_pai=nil,
		},
	}
--]]
--动作标记
local act_flag=false
--超时出牌计数-2次就自动托管
local overtime_count=0
--状态编号（依次增长）
local status_no=0
--报名的服务ID
local signup_svr_id
local match_info
local game_server_id_list=nil
--状态信息
local s_info
local room_info
--players_info
local p_info
--小结算信息
local settlement_info
--最终成绩
local final_result
--我的牌数据
local my_pai_data

--游戏结束后的保留数据
local gameover_all_info_s2c

--复活需要的复活卡数量
local need_fuhuo_ticket=1

--报名使用的财产 同时只会有一个
local signup_assets=nil

--当前报名的游戏信息 同时只会有一个
local cur_play_game_info=nil

local join_room_wait_time=3
local free_game_time=12
--客户端操作缓冲时间
local client_act_buffer_time=2
--托管后自动出牌的时间
local auto_wait_cp_time = 2
local lack_of_ability_for_cp_1=10
local lack_of_ability_for_cp_2=3

--托管数据
local auto_data

--百万大奖赛分享状态
local dbwg_shared_data = {}

--超时回调
local overtime_cb
local update_timer
--update 间隔
local dt=0.5
--返回优化，避免每次返回都创建表
local return_msg={result=0}

local function free_game()
	if update_timer then
		update_timer:stop()
		update_timer=nil
	end
	overtime_cb=nil

	status_no = 0
	match_info = nil
	room_info = nil
	s_info = nil
	p_info = nil
	settlement_info = nil
	my_pai_data = nil

	if DATA.chat_room_id then
		DATA.chat_room_id=nil
	end

	PUBLIC.unlock(game_name)
	PUBLIC.free_agent(game_name)
end

local function add_status_no()
	status_no=status_no+1
end

local function call_room_service(_func_name,...)

	return nodefunc.call(room_info.room_id,_func_name,room_info.t_num,room_info.seat_num,...)

end
local function add_act(_act)
	if _act then 
		if #s_info.act_list==2 then 
			s_info.act_list[1]=s_info.act_list[2]
			s_info.act_list[2]=_act
		else
			s_info.act_list[#s_info.act_list+1]=_act
		end
	end
end
local function set_auto(not_send)
	if s_info.auto_status[room_info.seat_num]==0 then 
		s_info.auto_status[room_info.seat_num]=1
		if not not_send then
			nodefunc.send(room_info.room_id,"auto",room_info.t_num,room_info.seat_num,1)
		end
		if s_info.status=="cp" and s_info.cur_p==s_info.seat_num then
			auto_data={countdown=auto_wait_cp_time}
		end
		return true
	end
	return false
end
local function cancel_auto()
	if s_info.auto_status[room_info.seat_num]==1 and basefunc.chk_player_is_real(DATA.my_id) then
		s_info.auto_status[room_info.seat_num]=0
		overtime_count=0
		auto_data=nil
		nodefunc.send(room_info.room_id,"auto",room_info.t_num,room_info.seat_num,0)
		return true
	end
	return false
end
--自动出牌
local function auto_cp(_is_must,_is_yaobuqi)
	if not _is_yaobuqi then
		overtime_count=overtime_count+1
	end
	if overtime_count>=1 and  s_info.auto_status[room_info.seat_num]==0 then 
		set_auto()
	end
	if _is_must then 
		print("must auto")
	else
		print("auto")
	end
	--必须出牌 
	if _is_must then
		--按最小出牌
		local _type,_pai=normal_ddz.auto_choose_by_order(my_pai_data.hash)
		local _cp_list=normal_ddz.get_cp_list(my_pai_data.pai,_type,_pai)
		call_room_service("chupai",_type,_cp_list)
	else 
		--已经是自动的情况下
		if s_info.auto_status[room_info.seat_num]==1 and not DATA.auto_cp_must_guo then
			print("接牌") 
			--接牌
			local s=#s_info.act_list
			while s>0 do 
				if s_info.act_list[s].type>0 and s_info.act_list[s].type<=14 then 
					break
				end
				s=s-1
			end
			local _type,_pai=normal_ddz.auto_choose_by_type(s_info.act_list[s].type,s_info.act_list[s].pai,my_pai_data.hash)
			local _cp_list=normal_ddz.get_cp_list(my_pai_data.pai,_type,_pai)
			call_room_service("chupai",_type,_cp_list)
		else
			print("过牌")
			--直接过牌
			call_room_service("chupai",0)
		end
	end
end

local function update()
	
	if s_info and s_info.countdown>0 then

		--正常流程的更新
		s_info.countdown=s_info.countdown-dt
		if s_info.countdown<=0 then
			if overtime_cb then 
				overtime_cb()
			end
		end

		--托管的更新 (只是提前调用应有的超时回调罢了)
		if auto_data then
			auto_data.countdown=auto_data.countdown-dt
			if auto_data.countdown<=0 then
				auto_data=nil
				if overtime_cb then 
					overtime_cb()
				end
			end
		end
	end

end

local function new_game(_init_rate,_init_stake,_seat_num,_round,_race)
	s_info.status="wait_p"
	--没有就不要赋值 因为有可能是重新发牌
	if _seat_num then
		room_info.seat_num=_seat_num 
		s_info.seat_num=_seat_num
	end
	--底分
	room_info.init_stake=_init_stake
	room_info.init_rate=_init_rate


	s_info.countdown=0
	s_info.cur_p=0
	--我的牌列表
	s_info.my_pai_list=nil
	--每个人剩余的牌
	s_info.remain_pai_amount=nil
	--记牌器
	s_info.jipaiqi=nil
	--我的倍数
	s_info.my_rate=_init_rate or 0
	--动作序列--保留最近两次的即可
	s_info.act_list={}
	--玩家的托管状态
	s_info.auto_status={0,0,0}
	--当前玩的比赛的轮数
	s_info.round=_round or s_info.round
	--当前玩的比赛的局数
	s_info.race=_race or s_info.race
	s_info.dizhu=0
	s_info.dz_pai=nil

	my_pai_data=nil
	settlement_info=nil	
end
local function join_room(_room_id,_t_num)
	local _data=nodefunc.call(_room_id,"join",_t_num,DATA.my_id,
					{
						id=DATA.my_id,
						name=DATA.player_data.player_info.name,
						head_link=DATA.player_data.player_info.head_image,
						sex=DATA.player_data.player_info.sex,
						-- dressed_head_frame = player_data.dress_data.dressed_head_frame,
						-- glory_score = DATA.player_data.glory_data.score,
						grades=s_info.grades,
					})
	if _data~="CALL_FAIL" and _data.result then
		if _data.p_info then 
			for _,_info in pairs(_data.p_info) do
				p_info.p_info[#p_info.p_info+1]=_info
			end
		end
		p_info.p_count=_data.p_count

		new_game(_data.rate,_data.init_stake,_data.seat_num,_data.round,_data.race)

		print("join succeed :",DATA.my_id,room_info.seat_num)
		return true
	else
		return false	
	end
end

--获得所有数据（格式为s2c）
local function get_all_info_s2c()
	if s_info and my_pai_data then
		s_info.my_pai_list=normal_ddz.get_pai_list_by_map(my_pai_data.pai)
	end
	gameover_all_info_s2c={
							status_no=status_no,
							match_info=match_info,
							room_info=room_info,
							status_info=s_info,
							players_info=p_info,
							settlement_info=settlement_info,
							final_result=final_result,
							}
end

--计算隐藏分(根据牌型)
local function calculate_hide_grades()
	
	if s_info.hide_grades then
		
		local dw = my_pai_data.hash[17] or 0
		local xw = my_pai_data.hash[16] or 0
		local _2 = my_pai_data.hash[15] or 0
		local grade = dw*3+xw*2+_2

		s_info.hide_grades=s_info.hide_grades+grade
	end

end


--请求游戏列表
function REQUEST.dbwg_req_game_list(self)
	if act_flag then
		return_msg.result=1008
		return return_msg
	end
	act_flag=true
	game_server_id_list=skynet.call(DATA.service_config.ddz_million_center_service,"lua","get_match_info")
	
	act_flag=false

	if game_server_id_list then 
		return {result=0,match_list_info=game_server_id_list}
	else
		return_msg.result=1004
		return return_msg
	end
end



--报名
function REQUEST.dbwg_signup(self)
	if act_flag then
		return_msg.result=1008
		return return_msg
	end
	act_flag=true
	
	if not self.id then 
		return_msg.result=1001
		act_flag=false
		return return_msg
	end
	
	
	if not PUBLIC.lock(game_name,game_name) then 
		return_msg.result=1005
		act_flag=false
		return return_msg
	end
	PUBLIC.ref_agent(game_name)

	local asset_lock_info

	--报名id错误
	local server_data = game_server_id_list
	if not server_data or not server_data.mgr_id then
		free_game()
		return_msg.result=1000
		act_flag=false
		return return_msg
	end
	
	local ss = REQUEST.dbwg_query_shared_status()
	if ss.status ~= 1 then
		free_game()
		return_msg.result=2017
		act_flag=false
		return return_msg
	end

	local server_id = server_data.mgr_id

	--请求进入条件
	local _result,_data=nodefunc.call(server_id,"get_enter_condition")
	
	if _result=="CALL_FAIL" then

		free_game()
		return_msg.result=1000
		act_flag=false
		return return_msg

	elseif _result == 0 then

		--锁定所需财务
		asset_lock_info = PUBLIC.asset_lock(_data)
		if asset_lock_info.result == 0 then
			signup_assets=_data

			-- print("asset_lock ok ,key:"..asset_lock_info.lock_id)
		else
			-- print("asset_lock error ,result:"..asset_lock_info.result)
			return_msg.result=asset_lock_info.result
			act_flag=false
			free_game()
			return return_msg
		end

	else
		return_msg.result=_result
		act_flag=false
		free_game()
		return return_msg
	end

	-- print("dbwg_apply  ID:",server_id)
	-- print("dbwg_apply:",DATA.my_id)
	local _result,_match_info=nodefunc.call(server_id,"player_signup",DATA.my_id)
	if _result=="CALL_FAIL" then
		free_game()
	elseif _result and _result==0 then
		
		local ret = PUBLIC.asset_commit(asset_lock_info.lock_id,ASSET_CHANGE_TYPE.MILLION_SIGNUP,0)
		PUBLIC.notify_asset_change_msg()
		
		if ret.result ~= 0 then
			print("asset_commit error ,result:"..ret.result)
		end
		signup_svr_id=server_id
		--初始化状态id
		status_no=0
		gameover_all_info_s2c=nil
		match_info=nil
		s_info=nil
		room_info=nil
		p_info=nil
		my_pai_data=nil
		settlement_info=nil
		final_result=nil

		DATA.dbwg={
					match_info=_match_info,
					status_info={
							status="wait_begin",
							countdown=0,
					},
		}
		s_info=DATA.dbwg.status_info
		match_info=DATA.dbwg.match_info

		cur_play_game_info=self

		update_timer=skynet.timer(dt,update)

		print("dbwg_apply  succeed:",DATA.my_id)
		act_flag=false
		
		return {result=0,match_info=match_info}
	else
		local ret = PUBLIC.asset_unlock(asset_lock_info.lock_id)
		if ret.result == 0 then
			-- print("asset_unlock ok")
		else
			print("asset_unlock error ,result:"..ret.result)
		end

		free_game()
		if _result then
			act_flag=false
			return_msg.result=_result
			return return_msg
		end
	end

	return_msg.result=1000
	act_flag=false
	return return_msg
end
function REQUEST.dbwg_quit_game(self)
	gameover_all_info_s2c=nil
	if s_info and s_info.status=="gameover" then
		free_game()
		print("REQUEST.dbwg_quit_game free_game")
		return_msg.result=0
		return return_msg
	end
	
	--已经自动退出了
	if not s_info then
		return_msg.result=0
		return return_msg
	end

	return_msg.result=2003
	return return_msg
end


--取消报名
function REQUEST.dbwg_cancel_signup(self)
	if act_flag or not s_info or s_info.status~="wait_begin" then 
		return_msg.result=1002
		return return_msg
	end
	act_flag=true
	if s_info.countdown<=0 then 
		local _result=nodefunc.call(signup_svr_id,"cancel_signup",DATA.my_id)
		if _result==0  then 

			--返回资产
			if signup_assets then
				CMD.change_asset_multi(signup_assets,ASSET_CHANGE_TYPE.MILLION_CANCEL_SIGNUP,0)
				signup_assets=nil
			end

			free_game()

		end
		act_flag=false
		return_msg.result=_result
		return return_msg
	end
	act_flag=false
	return_msg.result=1002
	return return_msg 
end

function REQUEST.dbwg_jiabei(self)
	if act_flag or not s_info or s_info.status~="jiabei" then
		return_msg.result=1002
		return return_msg
	end
	if not self.rate or type(self.rate)~="number" or (self.rate~=0 and self.rate~=2) then 
		return_msg.result=1001
		return return_msg
	end
	act_flag=true
	local _result=call_room_service("jiabei",self.rate)
	act_flag=false
	if _result~="CALL_FAIL" then
		return_msg.result=_result 
		return return_msg 
	else
		return_msg.result=1000
		return return_msg	
	end
end
function REQUEST.dbwg_jiao_dizhu(self)
	if act_flag or not s_info or s_info.status~="jdz" or s_info.cur_p~=room_info.seat_num then
		return_msg.result=1002
		return return_msg
	end
	if not self.rate or type(self.rate)~="number" or self.rate<0 or self.rate>3 then 
		return_msg.result=1001
		return return_msg
	end
	act_flag=true
	local _result=call_room_service("jiao_dizhu",self.rate)
	act_flag=false
	if _result~="CALL_FAIL" then

		return_msg.result=_result
		return return_msg 
	else
		return_msg.result=1000
		return return_msg	
	end
end
function REQUEST.dbwg_chupai(self)
	if act_flag or not s_info or s_info.status~="cp" or s_info.cur_p~=room_info.seat_num then
		return_msg.result=1002
		return return_msg
	end
	if not self.type or type(self.type)~="number"then 
		return_msg.result=1001
		return return_msg
	end
	cancel_auto()
	--检查是否有牌
	if self.type~=0 then
		if type(self.cp_list)~="table" then 
			return_msg.result=1001
			return return_msg 
		end
		local _hash={}
		for _,_id in ipairs(self.cp_list) do
			if not my_pai_data.pai[_id] or _hash[_id]  then 
				return_msg.result=1001
				return return_msg  
			end
			_hash[_id]=true
		end 
	end
	act_flag=true
	local _result=call_room_service("chupai",self.type,self.cp_list)
	act_flag=false
	if _result~="CALL_FAIL" then

		return_msg.result=_result 
		return return_msg 
	else
		return_msg.result=1000
		return return_msg	
	end
end


function REQUEST.dbwg_auto(self)
	if act_flag or not s_info or s_info.status~="cp" then
		return_msg.result=1002	
		return return_msg
	end

	if self.operate~=0 and self.operate~=1 then
		return_msg.result=1003	
		return return_msg
	end

	act_flag=true
	if self.operate==1 then 
		set_auto()
	else
		cancel_auto()
	end

	act_flag=false
	return_msg.result=0	
	return return_msg
end


function REQUEST.dbwg_get_round_race(self)

	if not s_info then
		return_msg.result=1002	
		return return_msg
	end

	return {result=0,
			round=s_info.round or 0,
			race=s_info.race or 0,
			}
end



function REQUEST.dbwg_fuhuo_game(self)

	if act_flag or not s_info or s_info.status~="wait_fuhuo" then
		return_msg.result=1002
		return return_msg
	end

	if self.fuhuo ~= 0 and self.fuhuo ~= 1 then
		return_msg.result=1001
		return return_msg
	end


	if self.fuhuo == 0 then

		--执行放弃复活回调
		overtime_cb()

		return_msg.result=0
		return return_msg
	end


	if s_info.fuhuo_status >= s_info.fuhuo_count then
		return_msg.result=2016
		return return_msg
	end


	act_flag=true

	--### test
	local asset = {
		{
			condi_type=NOR_CONDITION_TYPE.CONSUME,
			asset_type=PLAYER_ASSET_TYPES.MILLION_FUHUO_TICKET,
			value=need_fuhuo_ticket,
		},
	}


	local asset_lock_info = PUBLIC.asset_lock(asset)

	if asset_lock_info.result == 0 then
		print("asset_lock ok ,key:"..asset_lock_info.lock_id)
	else
		print("asset_lock error ,result:"..asset_lock_info.result)
		return_msg.result=asset_lock_info.result
		act_flag=false
		return return_msg
	end

	local ret =	nodefunc.call(match_info.match_svr_id,"fuhuo",DATA.my_id)
	if not ret then

		print("fuhuo error")
		PUBLIC.asset_unlock(asset_lock_info.lock_id)

		act_flag=false
		return_msg.result=1002
		return return_msg
	end

	local ret = PUBLIC.asset_commit(asset_lock_info.lock_id,ASSET_CHANGE_TYPE.MILLION_FUHUO,game_server_id_list.issue)
	PUBLIC.notify_asset_change_msg()
	
	if ret.result ~= 0 then
		print("asset_commit error ,result:"..ret.result)

		act_flag=false

		return_msg.result=1002
		return return_msg
	end

	act_flag=false
	
	if s_info.status=="wait_fuhuo" then
		overtime_cb=nil
	end

	s_info.fuhuo_status=s_info.fuhuo_status+1

	return_msg.result=0	
	return return_msg

end


--报名结束游戏开始
function CMD.dbwg_begin_msg(_m_svr_id,_grades,_bonus,_fuhuo_count)

	s_info.status="wait_table"
	--优化传输包体,游戏开始后数据就没用了
	s_info.signup_num=nil

	s_info.countdown=0
	-- 
	
	s_info.grades=_grades

	--隐藏分
	s_info.hide_grades=0

	DATA.dbwg.room_info={
			
			bonus=_bonus,

			room_id=0,
			--桌号
			t_num=0,
			--座位号
			seat_num=0,
		}
	
	DATA.dbwg.players_info={
			--玩家信息
			p_info={},
			p_count=0,
	}	
	room_info=DATA.dbwg.room_info
	p_info=DATA.dbwg.players_info	


	s_info.fuhuo_status = 0
	s_info.fuhuo_count = _fuhuo_count


	add_status_no()
	PUBLIC.request_client("dbwg_begin_msg",{status_no=status_no})

end

function CMD.dbwg_enter_room_msg(_room_id,_t_num,_round_info)
	s_info.status="wait_join"

	room_info.room_id=_room_id
	room_info.t_num=_t_num
	room_info.seat_num=0

	p_info.p_info={}
	p_info.p_count=0

	-- s_info.countdown=join_room_wait_time
	
	-- overtime_cb=function ()
	-- 					print("自动加入房间")
	-- 					overtime_cb=nil
						join_room(room_info.room_id,room_info.t_num)
					-- end

	print("dbwg_enter_room_msg",DATA.my_id)

	PUBLIC.add_game_consume_statistics(signup_assets)

	--通知客户端
	add_status_no()

	-- {
	-- 	round_type=1,
	-- 	rise_num=1,
	-- 	race_count=1,
	-- }
	s_info.round_info = _round_info
	-- {result=0,status_no=status_no,room_info=room_info,players_info=p_info}
	PUBLIC.request_client("dbwg_enter_room_msg",
							{status_no=status_no,
							room_info=room_info,
							round_info=s_info.round_info,
							players_info=p_info})
	
	
end


-- 目前是自动ready
function CMD.dbwg_ready_msg()
	s_info.status="ready"
end
--当前总人数，玩家信息
function CMD.dbwg_join_msg(_p_count,_info,_chat_room_id)
	if _info.id==DATA.my_id then
		if _chat_room_id then
			DATA.chat_room_id=_chat_room_id
			skynet.call(DATA.service_config.chat_service,"lua","join_room", DATA.chat_room_id,DATA.my_id,PUBLIC.get_gate_link())
		end
	else
		p_info.p_count=_p_count
		p_info.p_info[#p_info.p_info+1]=_info
		--通知客户端
		add_status_no()
		PUBLIC.request_client("dbwg_join_msg",{status_no=status_no,player_info=_info})
	end
end
function CMD.dbwg_pai_msg(_my_pai_data,_fp_time)
	print("dbwg_pai_msg! :")
	s_info.status="fp"
	s_info.countdown=_fp_time
	s_info.remain_pai_amount={17,17,17}
	s_info.my_pai_list=normal_ddz.get_pai_list_by_map(_my_pai_data.pai)
	my_pai_data=_my_pai_data
	my_pai_data.hash=normal_ddz.get_pai_typeHash(_my_pai_data.pai)
	
	--机器人自动托管
	if not basefunc.chk_player_is_real(DATA.my_id) then
		set_auto(true)
	end
	--通知客户端
	add_status_no()
	PUBLIC.request_client("dbwg_pai_msg",{status_no=status_no,my_pai_list=s_info.my_pai_list,
		remain_pai_amount=s_info.remain_pai_amount,round=s_info.round,race=s_info.race})
end
--叫地主权限
function CMD.dbwg_jdz_permit(_countdown,_cur_p)
	s_info.status="jdz"
	s_info.cur_p=_cur_p
	s_info.countdown=_countdown
	if room_info.seat_num==_cur_p then
		overtime_cb=function ()
						--
						print("叫地主")
						overtime_cb=nil
						--不叫 
						call_room_service("jiao_dizhu",0)
					end
		if s_info.auto_status[room_info.seat_num]==1 then
			auto_data={countdown=auto_wait_cp_time}
		end
	end
	--通知客户端
	add_status_no()
	PUBLIC.request_client("dbwg_permit_msg",{status_no=status_no,status=s_info.status,countdown=_countdown,cur_p=_cur_p})
end
--叫地主消息
function CMD.dbwg_jdz_msg(_act)
	if _act.p==s_info.seat_num then
		overtime_cb=nil
	end
	add_act(_act)
	--通知客户端
	add_status_no()
	PUBLIC.request_client("dbwg_action_msg",{status_no=status_no,action=_act})
end
function CMD.dbwg_dizhu_msg(_dizhu,_dz_pai,_rate)
	s_info.status="set_dz"
	s_info.countdown=0
	s_info.dizhu=_dizhu
	s_info.remain_pai_amount[_dizhu]=20
	s_info.dz_pai=_dz_pai
	s_info.my_rate=_rate

	if _dizhu==room_info.seat_num then 
		for i=1,3 do 
			my_pai_data.pai[_dz_pai[i]]=true
			s_info.my_pai_list[#s_info.my_pai_list+1]=_dz_pai[i]
		end
		my_pai_data.hash=normal_ddz.get_pai_typeHash(my_pai_data.pai)
	end
	--初始化记牌器
	s_info.jipaiqi=normal_ddz.getAllPaiCount()
	normal_ddz.jipaiqi(s_info.my_pai_list,s_info.jipaiqi)


	--计算一次隐藏分(只可能计算一次)
	calculate_hide_grades()

	--通知客户端
	add_status_no()
	PUBLIC.request_client("dbwg_dizhu_msg",{status_no=status_no,dz_info={dizhu=_dizhu,dz_pai=_dz_pai}})
end
function CMD.dbwg_jiabei_permit(_countdown,_cur_p)
	s_info.status="jiabei"
	s_info.countdown=_countdown
	s_info.cur_p=_cur_p
	if room_info.seat_num==_cur_p or (_cur_p==4 and s_info.dizhu~=room_info.seat_num) then
		overtime_cb=function ()
							print("不加倍！！")
							overtime_cb=nil
							--不加倍
							call_room_service("jiabei",2)
						end
		if s_info.auto_status[room_info.seat_num]==1 then
			auto_data={countdown=auto_wait_cp_time}
		end
	end
	--通知客户端
	add_status_no()
	PUBLIC.request_client("dbwg_permit_msg",{status_no=status_no,status=s_info.status,countdown=_countdown,cur_p=_cur_p})				
end
function CMD.dbwg_my_jiabei_msg(act)
	add_act(act)
end
function CMD.dbwg_jiabei_msg(_acts,_rate)
	s_info.my_rate=_rate
	--先发我自己的  以免bug （客户端可能已经先行显示）
	for _,_act in ipairs(_acts) do
		if _act.p==s_info.seat_num then
			overtime_cb=nil
			--通知客户端
			add_status_no()
			PUBLIC.request_client("dbwg_action_msg",{status_no=status_no,action=_act})	
			break
		end
	end
	local rate=0
	for _,_act in ipairs(_acts) do
		if _act.rate>0 then
			rate=_act.rate
		end
		if _act.p~=s_info.seat_num then
			add_act(_act)
			--通知客户端
			add_status_no()
			PUBLIC.request_client("dbwg_action_msg",{status_no=status_no,action=_act})
		end
	end
	--加倍完成动画
	if rate>0 then
		add_status_no()
		PUBLIC.request_client("dbwg_jiabeifinshani_msg",{status_no=status_no,my_rate=s_info.my_rate})
	end
end
--状态，倒计时，下一个出牌人，当前出牌人，出牌类型，出的牌
function CMD.dbwg_cp_permit(_countdown,_cur_p,_is_must)
	s_info.status="cp"
	s_info.countdown=_countdown
	s_info.cur_p=_cur_p	
	if room_info.seat_num==_cur_p then
		local is_yaobuqi=false
		--根据手里的牌进行倒计时选择 ###_test
		 
		if not _is_must then
			local _s=normal_ddz.check_cp_capacity(s_info.act_list,my_pai_data.hash)
			if _s == 1 then
				s_info.countdown=4
				_countdown=s_info.countdown
				is_yaobuqi=true
			elseif _s==2 then
				s_info.countdown=4
				_countdown=s_info.countdown
				is_yaobuqi=true
			end
		end

		if s_info.auto_status[room_info.seat_num]==1 then
			auto_data={countdown=auto_wait_cp_time}
		end
		
		print("设置自动出牌")
		overtime_cb=function ()
							overtime_cb=nil
							auto_data=nil
							print("超时出牌")
							auto_cp(_is_must,is_yaobuqi)
						end			
	end
	--通知客户端
	add_status_no()
	PUBLIC.request_client("dbwg_permit_msg",{status_no=status_no,status=s_info.status,
							countdown=_countdown,cur_p=_cur_p,other=_is_must})	
end

function CMD.dbwg_cp_msg(_act,_rate)
	add_act(_act)

	if _act.p==room_info.seat_num then 
		overtime_cb=nil
	end

	if _act.type~=0 then
		s_info.remain_pai_amount[_act.p]=s_info.remain_pai_amount[_act.p]-#_act.cp_list
		if _act.p==room_info.seat_num then
			normal_ddz.deduct_pai_by_list(my_pai_data,_act.cp_list)
			s_info.my_rate=_rate
		else
			normal_ddz.jipaiqi(_act.cp_list,s_info.jipaiqi)
		end
	end
	--通知客户端
	add_status_no()
	PUBLIC.request_client("dbwg_action_msg",{status_no=status_no,action=_act})
end
--玩家托管消息
function CMD.dbwg_auto_msg(_p,_type)
	s_info.auto_status[_p]=_type
	PUBLIC.request_client("dbwg_auto_msg",{p=_p,auto_status=_type})
end
--单局结算
function CMD.dbwg_settlement_msg(_settlement_info,_p_remain_pai,p_jiabei,p_jdz,bomb_count,is_chuntian)
	print("dbwg_settlement_msg!!")
	s_info.status="settlement"

	settlement_info=_settlement_info
	settlement_info.remain_pai=_p_remain_pai

	settlement_info.p_jiabei=p_jiabei
	settlement_info.bomb_count=bomb_count
	settlement_info.chuntian=is_chuntian
	settlement_info.p_jdz=p_jdz

	--改变玩家信息的分数
	for seat_num,info in ipairs(p_info.p_info) do
		info.grades = info.grades + settlement_info.p_scores[seat_num]
	end

	CMD.dbwg_change_grades(settlement_info.p_scores[room_info.seat_num])
	--通知客户端
	add_status_no()
	PUBLIC.request_client("dbwg_ddz_settlement_msg",{status_no=status_no,settlement_info=settlement_info})

	-- 统计
	local my_pos,dizhu_win,nongmin_win = 4,false,true
	
	if room_info.seat_num==s_info.dizhu then
		my_pos = 5
		dizhu_win,nongmin_win = true,false
	end
	
	local my_win = _settlement_info.winner==my_pos
	
	--记录输赢
	if my_win then
		PROTECT.add_statistics_player_million_ddz(dizhu_win,nongmin_win,false,false)
	else
		PROTECT.add_statistics_player_million_ddz(false,false,true,false)
	end

end
--_grades:改变量
function CMD.dbwg_change_grades(_grades)
	if s_info then 
		s_info.grades=s_info.grades+_grades
		--通知管理者
		nodefunc.send(match_info.match_svr_id,"change_grades",
						DATA.my_id,s_info.grades,s_info.hide_grades)
		add_status_no()
		--通知客户端
		
		PUBLIC.request_client("dbwg_grades_change_msg",{status_no=status_no,grades=s_info.grades})
	end
end

--当前比赛重新开始
function CMD.dbwg_start_again_msg(_init_rate,_init_stake,_seat_num)
	new_game(_init_rate,_init_stake,_seat_num)
	add_status_no()
	--通知客户端 新的一局
	PUBLIC.request_client("dbwg_start_again_msg",{status_no=status_no,status=s_info.status})	
end
--新的比赛
function CMD.dbwg_new_game_msg(_init_rate,_init_stake,_seat_num,_round,_race)
	new_game(_init_rate,_init_stake,_seat_num,_round,_race)
	add_status_no()

	--通知客户端 新的一局
	PUBLIC.request_client("dbwg_new_game_msg",
							{status_no=status_no,
							round=_round,
							race=_race,
							curr_all_player=s_info.curr_all_player,
							status=s_info.status})
end

--最终结算  ###_test
function CMD.dbwg_gameover_msg(_is_win,_round,_round_count,_reward)
	print("dbwg_gameover_msg!!")
	s_info.status="gameover"

	s_info.countdown=free_game_time
	overtime_cb=function ()
							print("CMD.dbwg_gameover_msg free_game :",DATA.my_id)
							free_game()
						end	

	final_result={
		is_win=_is_win and 1 or 0,
		round=_round,
		round_count=_round_count,
		reward={_reward},
	}
	
	if _is_win then
		--如果我赢了，那么我的排名数据将会改变
		PROTECT.clear_million_rank_data()
		PROTECT.add_statistics_player_million_ddz(false,false,false,true)
	end

	--安慰奖立即增加
	if _reward then
		--增加奖励
		-- PUBLIC.change_asset(_reward.asset_type,_reward.value,
		-- 					ASSET_CHANGE_TYPE.MILLION_AWARD,_round)
		-- PUBLIC.notify_asset_change_msg()
	end

	add_status_no()
	
	get_all_info_s2c()

	PUBLIC.request_client("dbwg_gameover_msg",{
							status_no=status_no,
							final_result=final_result,
						})
	if DATA.chat_room_id then
		--room 会销毁聊天室所以不需要退出
		-- skynet.send(DATA.service_config.chat_service,"lua","exit_room", DATA.chat_room_id,DATA.my_id)
		DATA.chat_room_id=nil
	end

end


--比赛完成了，我已经晋级了，先休息一下，然后发起匹配请求
function CMD.dbwg_promoted_msg()
	print("晋级 "..DATA.my_id)

	s_info.status="promoted"
	s_info.countdown = 3

	add_status_no()
	PUBLIC.request_client("dbwg_promoted_msg",
							{status_no=status_no,
							status=s_info.status,
							countdown=s_info.countdown,
							})
	
	overtime_cb = function ()
		--通知管理者我准备好了
		nodefunc.send(match_info.match_svr_id,"player_ready_matching",DATA.my_id)
		print("我准备好了:",DATA.my_id)
		overtime_cb = nil
	end

end

--游戏结束 等待玩家进行复活
function CMD.dbwg_wait_fuhuo_msg(_countdown,_round,_round_count,_fuhuo_ticket)
	print("准备复活 "..DATA.my_id)

	add_status_no()
	s_info.status="wait_fuhuo"
	s_info.countdown = _countdown
	need_fuhuo_ticket = _fuhuo_ticket

	overtime_cb = function ()
		nodefunc.send(match_info.match_svr_id,"give_up_fuhuo",DATA.my_id)
		print("复活时间已到:",DATA.my_id)
		overtime_cb = nil
	end

	PUBLIC.request_client("dbwg_wait_fuhuo_msg",
							{status_no=status_no,
							status=s_info.status,
							countdown=s_info.countdown,
							round=_round,
							round_count=_round_count,
							fuhuo_status=s_info.fuhuo_status,
							fuhuo_count=s_info.fuhuo_count
							})
end




--游戏结束 等待玩家进行复活
function CMD.dbwg_discard_msg(_player_num,_min_player)

	--返回资产
	if signup_assets then
		CMD.change_asset_multi(signup_assets,ASSET_CHANGE_TYPE.MILLION_CANCEL_SIGNUP,0)
		signup_assets=nil
	end

	PUBLIC.request_client("dbwg_discard_msg",
		{
		player_num=_player_num,
		min_player=_min_player,
		})

	free_game()

end



--客户端请求 ***************

--**send info******
local send_info_func={}	
local function send_all_info()
	if gameover_all_info_s2c then
		PUBLIC.request_client("dbwg_all_info",gameover_all_info_s2c)
		return 0
	end

	if match_info then
		if s_info and my_pai_data then
			s_info.my_pai_list=normal_ddz.get_pai_list_by_map(my_pai_data.pai)
		end
		PUBLIC.request_client("dbwg_all_info", {
												status_no=status_no,
												match_info=match_info,
												room_info=room_info,
												status_info=s_info,
												players_info=p_info,
												settlement_info=settlement_info,
												final_result=final_result,
												})
		return 0
	end
	
	--没有状态时 表示没有在游戏中  返回状态码为 -1 
	PUBLIC.request_client("dbwg_all_info",{status_no=-1})
	return 0
end
send_info_func["all"]=send_all_info

local function send_status_info()
	if s_info then

		if s_info and my_pai_data then
			s_info.my_pai_list=normal_ddz.get_pai_list_by_map(my_pai_data.pai)
		end 

		PUBLIC.request_client("dbwg_status_info",{status_no=status_no,status_info=s_info})
		return 0
	end
	--没有状态时 表示没有在游戏中  返回状态码为 -1 
	PUBLIC.request_client("dbwg_status_info",{status_no=-1})
	return 0
end
send_info_func["status"]=send_status_info


--**send info******
function REQUEST.dbwg_req_info_by_send(self)
	if type(self.type)~= "string" then 
		return_msg.result=1001
		return return_msg
	end
	if send_info_func[self.type] then 
		local _r=send_info_func[self.type]()
		return_msg.result=_r
		return return_msg
	end
	return_msg.result=1004
	return return_msg
end


function REQUEST.dbwg_req_status_info(self)
	if s_info then

		if s_info and my_pai_data then
			s_info.my_pai_list=normal_ddz.get_pai_list_by_map(my_pai_data.pai)
		end

		return {result=0,status_no=status_no,status_info=s_info}
	end
	--没有状态时 表示没有在游戏中  返回状态码为 -1
	return {result=0,status_no=-1}
end

function REQUEST.dbwg_req_all_info(self)
	if m_info then
		if s_info and my_pai_data then
			s_info.my_pai_list=normal_ddz.get_pai_list_by_map(my_pai_data.pai)
		end

		return {	
					result=0,
					status_no=status_no,
					match_info=match_info,
					room_info=room_info,
					status_info=s_info,
					players_info=p_info,
					settlement_info=settlement_info,
					final_result=final_result,

				} 
	end
	return_msg.result=1004
	return return_msg
end


--设置百万大奖赛的奖杯状态
function CMD.dbwg_set_million_cup(_data)

	skynet.send(DATA.service_config.data_service,"lua",
				"set_player_million_cup_status",DATA.my_id,_data)
	
	DATA.player_data.million_cup_status = _data

	PUBLIC.request_client("notify_million_cup_msg",
							{
								million_cup_status=_data
							})

end


local million_rank_data = nil

--清除排名数据
function PROTECT.clear_million_rank_data()
	million_rank_data = nil
end

function REQUEST.dbwg_bonus_rank_list(self)

	if million_rank_data then
		return {result=0,
				rank_list=million_rank_data.rank_list,
				my_rank=million_rank_data.my_rank,
				date=million_rank_data.date,
				issue=million_rank_data.issue,}
	end

	million_rank_data = skynet.call(DATA.service_config.data_service,"lua",
								"query_player_million_bonus_rank",DATA.my_id)

	return {result=0,
			rank_list=million_rank_data.rank_list,
			my_rank=million_rank_data.my_rank,
			date=million_rank_data.date,
			issue=million_rank_data.issue,}
end


--百万大奖赛分享相关 dbwg_shared_data***************

--初始化
function PUBLIC.init_million_shared_data()
	local shared_data=skynet.call(DATA.service_config.data_service,"lua",
									"query_player_million_shared_data",DATA.my_id)
	dbwg_shared_data.time = shared_data.time
end

--分享完成
function REQUEST.dbwg_shared_finish(self)
	dbwg_shared_data.time=os.time()
	skynet.send(DATA.service_config.data_service,"lua",
					"add_player_million_shared_data",DATA.my_id)

	PUBLIC.get_everyday_shared_award()
	
	return {result=0}
end

--查询分享状态
function REQUEST.dbwg_query_shared_status(self)
	local cd = tonumber(os.date("%Y%m%d",os.time()))
	local dd = tonumber(os.date("%Y%m%d",dbwg_shared_data.time))
	local ret = (cd==dd and 1 or 0)

	return {result=0,status=ret}
end



-- 统计相关 ***************
--[[
{
	id = _player_id,
	dizhu_win_count = _dizhu_win,
	nongmin_win_count = _nongmin_win,
	defeated_count = _defeated_count,
	final_win = _final_win,
}
]]
local statistics_player_million_ddz_data=nil

function PUBLIC.init_statistics_million_ddz_data()
	statistics_player_million_ddz_data=skynet.call(DATA.service_config.data_service,"lua",
											"get_statistics_player_million_ddz",DATA.my_id)

end

function PROTECT.add_statistics_player_million_ddz(_dizhu_win,_nongmin_win,_defeated,_final_win)

	if _dizhu_win then
		local num = statistics_player_million_ddz_data.dizhu_win_count+1
		statistics_player_million_ddz_data.dizhu_win_count=num
	elseif _nongmin_win then
		local num = statistics_player_million_ddz_data.nongmin_win_count+1
		statistics_player_million_ddz_data.nongmin_win_count=num
	elseif _defeated then
		local num = statistics_player_million_ddz_data.defeated_count+1
		statistics_player_million_ddz_data.defeated_count=num	
	end

	if _final_win then
		local num = statistics_player_million_ddz_data.final_win+1
		statistics_player_million_ddz_data.final_win=num
	end

	skynet.send(DATA.service_config.data_service,"lua",
				"update_statistics_player_million_ddz",DATA.my_id,
				statistics_player_million_ddz_data.dizhu_win_count,
				statistics_player_million_ddz_data.nongmin_win_count,
				statistics_player_million_ddz_data.defeated_count,
				statistics_player_million_ddz_data.final_win)

end


function REQUEST.get_statistics_player_million_ddz(self)
	return {
			result=0,
			dizhu_win_count = statistics_player_million_ddz_data.dizhu_win_count,
			nongmin_win_count = statistics_player_million_ddz_data.nongmin_win_count,
			defeated_count = statistics_player_million_ddz_data.defeated_count,
			final_win = statistics_player_million_ddz_data.final_win,
			}
end



return PROTECT


