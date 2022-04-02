--
-- Author: HEWEI
-- Date: 2018/3/28
-- Time: 
-- 说明：tyddz_free_game  缩写 tydfg
require "normal_enum"
local skynet = require "skynet_plus"
local basefunc=require"basefunc"
local nodefunc = require "nodefunc"
require"printfunc"
local tyDdzFunc= require "ty_ddz_lib"
local base = require "base"
local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC
local REQUEST=base.REQUEST
local PROTECT={}

local game_name="tyddz_freestyle_game"
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
	jdz : 叫地主
	-set_dz： 设置地主
	jb : 加倍
	cp： 出牌阶段
	settlement： 结算
	gameover ：游戏结束

--]]

--[[
	DATA.dfg={
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
--状态信息
local s_info
local room_info
--players_info
local p_info
--小结算信息
local settlement_info
--我的牌数据
local my_pai_data

local gameover_all_info_s2c 

local game_server_id_map={}

--报名使用的财产 同时只会有一个
local signup_assets=nil

--当前报名的游戏信息 同时只会有一个
local cur_play_game_info=nil

local join_room_wait_time=3
local free_game_time=12
local client_act_buffer_time=2
--托管后自动出牌的时间
local auto_wait_cp_time = 2
local lack_of_ability_for_cp_1=10
local lack_of_ability_for_cp_2=3

local auto_cancel_signup_time = 60*3
local auto_cancel_signup_bt = 0

--托管数据
local auto_data

local empty_pai_list = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,}

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
		local cp=tyDdzFunc.cp_hint(nil,nil,my_pai_data.pai,s_info.ty_pai_num,s_info.remain_pai_amount[room_info.seat_num])
		print("顺序走") 
		-- dump(cp)
		call_room_service("chupai",cp.type,cp.cp_list,cp.merge_cp_list,cp.lazi_num)
	else 
		--已经是自动的情况下
		if s_info.auto_status[room_info.seat_num]==1 and not DATA.auto_cp_must_guo then
			--接牌
			local data=s_info.act_list[tyDdzFunc.get_real_chupai_pos_by_act(s_info.act_list)]
			local cp=tyDdzFunc.cp_hint(data.type,data.pai,my_pai_data.pai,s_info.ty_pai_num,s_info.remain_pai_amount[room_info.seat_num])
			print("接牌") 
			-- dump(cp)
			call_room_service("chupai",cp.type,cp.cp_list,cp.merge_cp_list,cp.lazi_num)
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

	PROTECT.tydfg_auto_cancel_signup()

end

local function new_game(_init_rate,_init_stake,_seat_num,_race)
	s_info.status="wait_p"
	--没有就不要赋值 因为有可能是重新发牌
	if _seat_num then
		room_info.seat_num=_seat_num 
		s_info.seat_num=_seat_num
	end
	--底分
	room_info.init_stake=_init_stake
	room_info.init_rate=_init_rate

	-- s_info.win_count=PROTECT.get_tyddzfree_all_win()
	s_info.countdown=0
	s_info.cur_p=0
	--我的牌列表
	s_info.my_pai_list=nil
	--每个人剩余的牌
	s_info.remain_pai_amount=nil
	--记牌器
	s_info.jipaiqi=nil
	--我的倍数
	s_info.my_rate=_init_rate or 1
	--动作序列--保留最近两次的即可
	s_info.act_list={}
	--玩家的托管状态
	s_info.auto_status={0,0,0}
	--当前玩的比赛的局数
	s_info.race=_race or s_info.race
	s_info.dizhu=0
	s_info.is_men_zhua=nil
	s_info.p_dao_la={-1,-1,-1}
	s_info.dz_pai=nil

	my_pai_data=nil
	settlement_info=nil

	--0-nil  1-不操作  2-是操作
	s_info.men_data={0,0,0}
	s_info.zhua_data={0,0,0}

end

local function join_room(_room_id,_t_num)
	local _data=nodefunc.call(_room_id,"join",_t_num,DATA.my_id,
					{
						id=DATA.my_id,
						name=DATA.player_data.player_info.name,
						head_link=DATA.player_data.player_info.head_image,
						sex=DATA.player_data.player_info.sex,
						-- dressed_head_frame = player_data.dress_data.dressed_head_frame,
						jing_bi=PUBLIC.query_game_coin(game_name),
					})
	if _data~="CALL_FAIL" and _data.result then
		if _data.p_info then 
			for _,_info in pairs(_data.p_info) do
				p_info.p_info[#p_info.p_info+1]=_info
			end
		end
		p_info.p_count=_data.p_count

		new_game(_data.rate,_data.init_stake,_data.seat_num,_data.race)

		print("join succeed :",DATA.my_id,room_info.seat_num)
		return true
	else
		return false	
	end
end

--获得所有数据（格式为s2c）
local function get_all_info_s2c()

	if s_info and my_pai_data then
		s_info.my_pai_list=tyDdzFunc.get_pai_list_by_map(my_pai_data.pai)
	else
		s_info.my_pai_list=my_pai_tmp_list
	end

	gameover_all_info_s2c={
							status_no=status_no,
							match_info=match_info,
							room_info=room_info,
							status_info=s_info,
							players_info=p_info,
							settlement_info=settlement_info,
							}

end


--请求游戏列表 ###_test
function REQUEST.tydfg_req_game_list(self)
	if act_flag then
		return_msg.result=1008
		return return_msg
	end
	act_flag=true
	local game_server_id_list
	game_server_id_list,game_server_id_map=skynet.call(DATA.service_config.tyddz_freestyle_center_service,"lua","get_game_list")
	act_flag=false

	if game_server_id_list then
		return {result=0,tydfg_match_list=game_server_id_list}
	else
		game_server_id_map = {}
		return_msg.result=1004
		return return_msg
	end
end
--报名
function REQUEST.tydfg_signup(self,_is_replay)
	if act_flag then
		return_msg.result=1008
		return return_msg
	end
	act_flag=true
	
	--###_test - 进入条件套餐选择（nil 代表默认）
	--self.enter_config_id

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

	local server_data = game_server_id_map[self.id]
	if not server_data or not server_data.signup_service_id then

		free_game()
		return_msg.result=1000
		act_flag=false
		return return_msg

	end
	local server_id = server_data.signup_service_id

	local asset_lock_info
	--请求进入条件
	local _result,_data=nodefunc.call(server_id,"get_enter_condition",self.enter_config_id,_is_replay)

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

			print("asset_lock ok ,key:"..asset_lock_info.lock_id)
		else
			print("asset_lock error ,result:"..asset_lock_info.result)
			return_msg.result=asset_lock_info.result
			act_flag=false
			free_game()
			return return_msg
		end

	else
		free_game()
		return_msg.result=_result
		act_flag=false
		return return_msg
	end

	print("dfg_apply  ID:",server_id)
	print("dfg_apply:",DATA.my_id)
	local _result=nodefunc.call(server_id,"player_signup",DATA.my_id)
	if _result=="CALL_FAIL" then
		free_game()
	elseif _result and _result.result==0 then
		
		local ret = PUBLIC.asset_commit(asset_lock_info.lock_id,ASSET_CHANGE_TYPE.TY_FREESTYLE_SIGNUP,self.id)
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

		DATA.dfg={
					match_info=
					{
						name=_result.name,
						match_svr_id=_result.match_svr_id,
						game_model=_result.game_model,
					},
					status_info=
					{
						status="wait_table",
						countdown=_result.cancel_signup_cd,
					},
					room_info={
						room_id=0,
						--桌号
						t_num=0,
						--座位号
						seat_num=0,

						game_id = self.id,
					},
					players_info={
							--玩家信息
							p_info={},
							p_count=0,
					},	
		}
		auto_cancel_signup_bt = os.time()
		s_info=DATA.dfg.status_info
		match_info=DATA.dfg.match_info
		room_info=DATA.dfg.room_info
		p_info=DATA.dfg.players_info
		
		if not _is_replay then
			PUBLIC.free_game_coin(game_name)
		end

		PUBLIC.replenish_game_coin(game_name,_result.min_coin,_result.max_coin)

		cur_play_game_info=self

		update_timer=skynet.timer(dt,update)

		print("dfg_apply  succeed:",DATA.my_id)
		act_flag=false

		_result.countdown=_result.cancel_signup_cd
		return _result
	else
		local ret = PUBLIC.asset_unlock(asset_lock_info.lock_id)
		if ret.result == 0 then
			print("asset_unlock ok")
		else
			print("asset_unlock error ,result:"..ret.result)
		end

		free_game()
		if _result then
			act_flag=false
			return _result 
		end
	end

	return_msg.result=1000
	act_flag=false
	return return_msg
end
function REQUEST.tydfg_quit_game(self)
	
	gameover_all_info_s2c=nil

	if s_info and s_info.status=="gameover" then
		print("REQUEST.dfg_quit_game free_game")
		PUBLIC.free_game_coin(game_name)
		free_game()
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
function REQUEST.tydfg_cancel_signup(self)
	if act_flag or not s_info or s_info.status~="wait_table" then 
		return_msg.result=1002
		return return_msg
	end
	act_flag=true
	if  s_info.countdown<=0 then 
		local _result=nodefunc.call(signup_svr_id,"cancel_signup",DATA.my_id)
		if _result==0  then 
			--返回资产
			if signup_assets then
				CMD.change_asset_multi(signup_assets,ASSET_CHANGE_TYPE.TY_FREESTYLE_CANCEL_SIGNUP,cur_play_game_info.id)
				signup_assets=nil
			end

			PUBLIC.free_game_coin(game_name)
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


--匹配超时，自动取消
function PROTECT.tydfg_auto_cancel_signup()
	if s_info 
		and s_info.status=="wait_table" 
		and auto_cancel_signup_bt+auto_cancel_signup_time < os.time() then

		local ret = REQUEST.tydfg_cancel_signup()
		if ret.result == 0 then
			PUBLIC.request_client("tydfg_auto_cancel_signup_msg",{result=0})
			print("overtime ty auto_cancel_signup")
		end
	end
end


--再来一局
function REQUEST.tydfg_replay_game(self)

	if s_info and s_info.status=="gameover" then
		gameover_all_info_s2c=nil
		free_game()
	end

	--如果信息还没有清除 就进行重玩
	if cur_play_game_info then
		return REQUEST.tydfg_signup(cur_play_game_info,true)
	else
		cur_play_game_info = self
		local gl = REQUEST.tydfg_req_game_list()
		if gl.result == 0 then
			return REQUEST.tydfg_signup(cur_play_game_info,true)
		end
	end

	return_msg.result=2003
	return return_msg

end

--men
function REQUEST.tydfg_men_zhua(self)
	if act_flag 
		or not s_info 
		or s_info.status~="jdz"
		or s_info.cur_p~=room_info.seat_num then
			return_msg.result=1002
			return return_msg
	end
	print("tydfg_men_zhua//**--")
	act_flag=true
	local _result=call_room_service("men")
	act_flag=false
	if _result~="CALL_FAIL" then

		return_msg.result=_result 
		return return_msg 
	else
		return_msg.result=1000
		return return_msg	
	end
end

--kan
function REQUEST.tydfg_kan_pai(self)
	if act_flag 
		or not s_info 
		or s_info.status~="jdz"
		or s_info.cur_p~=room_info.seat_num then
			return_msg.result=1002
			return return_msg
	end
	print("tydfg_kan_pai//**--")
	act_flag=true
	local _result=call_room_service("kan")
	act_flag=false
	if _result~="CALL_FAIL" then
		
		return_msg.result=_result 
		return return_msg 
	else
		return_msg.result=1000
		return return_msg	
	end
end

function REQUEST.tydfg_zhua_pai(self)
	if act_flag 
		or not s_info 
		or s_info.status~="jdz"
		or s_info.cur_p~=room_info.seat_num then
			return_msg.result=1002
			return return_msg
	end
	if not self.opt 
		or type(self.opt)~="number" 
		or (self.opt~=0 and self.opt~=1)then 
			return_msg.result=1001
			return return_msg
	end

	if self.opt==0 and s_info.is_must_zhua then
		return_msg.result=1002
		return return_msg
	end

	act_flag=true
	local _result=call_room_service("zhua_pai",self.opt)
	act_flag=false
	if _result~="CALL_FAIL" then
		
		return_msg.result=_result 
		return return_msg 
	else
		return_msg.result=1000
		return return_msg	
	end
end

function REQUEST.tydfg_jiabei(self)
	if act_flag 
		or not s_info 
		or s_info.status~="jiabei" then
			return_msg.result=1002
			return return_msg
	end

	if not self.opt 
		or type(self.opt)~="number" 
		or (self.opt~=0 and self.opt~=1)then 
			return_msg.result=1001
			return return_msg
	end

	if (s_info.cur_p==4 and s_info.dizhu==room_info.seat_num)
		or (s_info.cur_p<4 and s_info.dizhu~=room_info.seat_num) then
		print("还没有轮到你进行操作 加倍操作".. DATA.my_id)
		return_msg.result=1002
		return return_msg
	end


	if s_info.is_must_dao and self.opt==0 then
		return_msg.result=1002
		return return_msg
	end


	act_flag=true
	
	local _result=call_room_service("jiabei",self.opt)
	
	act_flag=false
	if _result~="CALL_FAIL" then
		if _result==0 then
			s_info.is_must_dao=nil
		end
		
		return_msg.result=_result 
		return return_msg 
	else
		return_msg.result=1000
		return return_msg	
	end

end


function REQUEST.tydfg_chupai(self)
	if act_flag or not s_info or s_info.status~="cp" or s_info.cur_p~=room_info.seat_num then
		return_msg.result=1002
		return return_msg
	end
	if not self.type or type(self.type)~="number"then 
		return_msg.result=1001
		return return_msg
	end
	cancel_auto()
	local lazi_num=0
	--检查是否有牌
	if self.type~=0 then
		if type(self.cp_list)~="table" then
			return_msg.result=1001
			return return_msg 
		end
		if type(self.cp_list.nor)=="table" then
			local _hash={}
			for _,_id in ipairs(self.cp_list.nor) do
				if not my_pai_data.pai[_id] or _hash[_id] or 18==tyDdzFunc.pai_map[_id] then 
					return_msg.result=1001
					return return_msg  
				end
				_hash[_id]=true
			end 
		end
		if type(self.cp_list.lz)=="table" then
			lazi_num=#self.cp_list.lz
			if s_info.ty_pai_num<lazi_num then
				return_msg.result=1001
				return return_msg  
			end
		end
	end
	if tyDdzFunc.check_is_only_ty(self.cp_list,s_info.remain_pai_amount[room_info.seat_num],s_info.ty_pai_num) then
		return_msg.result=1001
		return return_msg   
	end

	local cp_list=tyDdzFunc.merge_nor_and_lz(self.cp_list)
	if not cp_list then
		return_msg.result=1001
		return return_msg 
	end
	act_flag=true
	local _result=call_room_service("chupai",self.type,self.cp_list,cp_list,lazi_num)
	act_flag=false
	if _result~="CALL_FAIL" then

		return_msg.result=_result 
		return return_msg 
	else
		return_msg.result=1000
		return return_msg	
	end
end




function REQUEST.tydfg_auto(self)
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


function CMD.tydfg_enter_room_msg(_room_id,_t_num)
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

	print("tydfg_enter_room_msg",DATA.my_id)

	PUBLIC.add_game_consume_statistics(signup_assets)

	--通知客户端
	add_status_no()
	-- {result=0,status_no=status_no,room_info=room_info,players_info=p_info}
	PUBLIC.request_client("tydfg_enter_room_msg",{status_no=status_no,
												room_info=room_info,
												players_info=p_info,
												win_count=s_info.win_count})
	
end

-- ###_test 目前是自动ready
function CMD.tydfg_ready_msg()
	s_info.status="ready"
end

--当前总人数，玩家信息
function CMD.tydfg_join_msg(_p_count,_info,_chat_room_id)
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
		PUBLIC.request_client("tydfg_join_msg",{status_no=status_no,player_info=_info})
	end

end

function CMD.tydfg_pai_msg(_fp_time)
	print("tydfg_pai_msg! :")
	s_info.status="fp"
	s_info.countdown=_fp_time
	s_info.remain_pai_amount={17,17,17}

	--17个0
	s_info.my_pai_list=empty_pai_list

	--机器人自动托管
	if not basefunc.chk_player_is_real(DATA.my_id) then
		set_auto(true)
	end
	--通知客户端
	add_status_no()
	PUBLIC.request_client("tydfg_pai_msg",{status_no=status_no,
										remain_pai_amount=s_info.remain_pai_amount,
										race=s_info.race})
end


--闷消息
function CMD.tydfg_men_msg(_act)

    if _act.p==s_info.seat_num then
		overtime_cb=nil
		s_info.men_data[room_info.seat_num]=2
    end

	add_act(_act)
	add_status_no()

	s_info.my_rate=_act.rate
	
	s_info.men_data[_act.p]=2

	PUBLIC.request_client("tydfg_action_msg",{status_no=status_no,action=_act})
end

--kan消息
function CMD.tydfg_kan_msg(_act)

    if _act.p==s_info.seat_num then
        overtime_cb=nil
        s_info.men_data[room_info.seat_num]=1
    end

	--看不计入操作队列
	-- add_act(_act)
	add_status_no()
	s_info.men_data[_act.p]=1
	PUBLIC.request_client("tydfg_action_msg",{status_no=status_no,action=_act})
end

--看我自己的手牌消息
function CMD.tydfg_kan_my_pai_msg(_pai)
	s_info.my_pai_list=tyDdzFunc.get_pai_list_by_map(_pai)
	my_pai_data={pai=_pai}
	my_pai_data.hash=tyDdzFunc.get_pai_typeHash(_pai)

	--通知客户端
	add_status_no()
	PUBLIC.request_client("tydfg_kan_my_pai_msg",{status_no=status_no,my_pai_list=s_info.my_pai_list})
end

function CMD.tydfg_jdz_permit(_countdown,_cur_p)
	s_info.status="jdz"
	s_info.countdown=_countdown
	s_info.cur_p=_cur_p

	if room_info.seat_num==_cur_p then
		if s_info.men_data[room_info.seat_num]==0 then
			overtime_cb=function ()
				overtime_cb=nil
				s_info.men_data[room_info.seat_num]=1
				call_room_service("kan")
			end
		else
			local zhua=0
			if tyDdzFunc.is_must_zhua(my_pai_data.hash) then
				zhua=1
				s_info.is_must_zhua=1
			end
			overtime_cb=function ()
				overtime_cb=nil
				s_info.is_must_zhua=nil
				s_info.zhua_data[room_info.seat_num]=zhua+1
				call_room_service("zhua_pai",zhua)
			end
		end
		if s_info.auto_status[room_info.seat_num]==1 then
			auto_data={countdown=auto_wait_cp_time}
		end
	end
	--通知客户端
	add_status_no()
	PUBLIC.request_client("tydfg_permit_msg",{status_no=status_no,status=s_info.status,countdown=_countdown,cur_p=_cur_p})
end

function CMD.tydfg_jiabei_permit(_countdown,_cur_p)
	s_info.status="jiabei"
	s_info.countdown=_countdown
	s_info.cur_p=_cur_p
	if room_info.seat_num==_cur_p or (_cur_p==4 or s_info.dizhu~=room_info.seat_num ) then
		if room_info.seat_num==_cur_p then
			--la
			overtime_cb=function ()
				overtime_cb=nil
				call_room_service("jiabei",0)
			end
		else

			--dao
			local jiabei=0
			if my_pai_data and tyDdzFunc.is_must_dao(my_pai_data.hash) then
				jiabei=1
				s_info.is_must_dao=1
			end

			--我闷牌放弃则不能倒
			if s_info.men_data[room_info.seat_num]==1 then
				jiabei=0
				s_info.countdown=1
			end

			overtime_cb=function ()
				overtime_cb=nil
				s_info.is_must_dao=nil
				call_room_service("jiabei",jiabei)
			end
			
		end
		if s_info.auto_status[room_info.seat_num]==1 then
			auto_data={countdown=auto_wait_cp_time}
		end 
	end


	--通知客户端
	add_status_no()
	PUBLIC.request_client("tydfg_permit_msg",{status_no=status_no,status=s_info.status,countdown=_countdown,cur_p=_cur_p})
end

--zp消息
function CMD.tydfg_zp_msg(_act)

    if _act.p==s_info.seat_num then
        overtime_cb=nil
        s_info.is_must_zhua=nil
    end

	s_info.my_rate=_act.rate
	s_info.zhua_data[_act.p]=_act.type==tyDdzFunc.act_type.zp and 2 or 1
	add_act(_act)
	add_status_no()
	PUBLIC.request_client("tydfg_action_msg",{status_no=status_no,action=_act})
end

--dao消息
function CMD.tydfg_dao_msg(_act)

    if _act.p==s_info.seat_num then
        overtime_cb=nil
    end

	s_info.my_rate=_act.rate
	s_info.p_dao_la[_act.p]=_act.type>tyDdzFunc.act_type.dao and 1 or 0
	add_act(_act)
	add_status_no()
	PUBLIC.request_client("tydfg_action_msg",{status_no=status_no,action=_act})
end

--la消息
function CMD.tydfg_la_msg(_act)

    if _act.p==s_info.seat_num then
        overtime_cb=nil
    end

	s_info.my_rate=_act.rate
	s_info.p_dao_la[_act.p]=_act.type==tyDdzFunc.act_type.la and 1 or 0
	--拉不计入操作队列
	-- add_act(_act)
	add_status_no()
	PUBLIC.request_client("tydfg_action_msg",{status_no=status_no,action=_act})
end

function CMD.tydfg_dizhu_msg(_dizhu,_men)
	s_info.status="set_dz"
	s_info.countdown=0
	s_info.dizhu=_dizhu
	s_info.is_men_zhua=_men
	s_info.remain_pai_amount[_dizhu]=21
	

	--通知客户端
	add_status_no()
	PUBLIC.request_client("tydfg_dizhu_msg",{status_no=status_no,dizhu=_dizhu})
end

function CMD.tydfg_dizhu_pai_msg(_dz_pai)
	
	s_info.dz_pai = _dz_pai or {0,0,0,0}

	if s_info.dizhu==room_info.seat_num then 
		for i=1,4 do 
			my_pai_data.pai[s_info.dz_pai[i]]=true
			s_info.my_pai_list[#s_info.my_pai_list+1]=s_info.dz_pai[i]
		end
		my_pai_data.hash=tyDdzFunc.get_pai_typeHash(my_pai_data.pai)
	end

	--初始化记牌器
	s_info.jipaiqi=tyDdzFunc.getAllPaiCount()
	tyDdzFunc.jipaiqi({nor=s_info.my_pai_list},s_info.jipaiqi)
	s_info.ty_pai_num=my_pai_data.hash[18] or 0

	add_status_no()
	PUBLIC.request_client("tydfg_dizhu_pai_msg",{status_no=status_no,dz_pai=s_info.dz_pai})

end


--状态，倒计时，下一个出牌人，当前出牌人，出牌类型，出的牌
function CMD.tydfg_cp_permit(_countdown,_cur_p,_is_must)
	s_info.status="cp"
	s_info.countdown=_countdown
	s_info.cur_p=_cur_p	
	if room_info.seat_num==_cur_p then
		local is_yaobuqi=false
		--根据手里的牌进行倒计时选择
		if not _is_must then
			local _s=tyDdzFunc.check_cp_capacity(s_info.act_list,my_pai_data.pai,s_info.ty_pai_num,s_info.remain_pai_amount[room_info.seat_num])
			if _s == 1 then
				s_info.countdown=5
				_countdown=s_info.countdown
				is_yaobuqi=true
			elseif _s==2 then
				s_info.countdown=5
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
	if _is_must then
		_is_must=1
	else
		_is_must=nil
	end
	PUBLIC.request_client("tydfg_permit_msg",{status_no=status_no,status=s_info.status,countdown=_countdown,cur_p=_cur_p,other=_is_must})	
end

function CMD.tydfg_cp_msg(_act,_rate)
	add_act(_act)

	if _act.p==room_info.seat_num then 
		overtime_cb=nil
	end

	if _act.type~=0 then
		s_info.remain_pai_amount[_act.p]=s_info.remain_pai_amount[_act.p]-#_act.merge_cp_list
		if _act.p==room_info.seat_num then
			tyDdzFunc.deduct_pai_by_cp_list(my_pai_data,_act.cp_list)
			s_info.my_rate=_rate
			s_info.ty_pai_num=s_info.ty_pai_num-_act.lazi_num
		else
			tyDdzFunc.jipaiqi(_act.cp_list,s_info.jipaiqi)
		end
	end
	--通知客户端
	add_status_no()
	PUBLIC.request_client("tydfg_action_msg",{status_no=status_no,action=_act})
end
--玩家托管消息
function CMD.tydfg_auto_msg(_p,_type)
	s_info.auto_status[_p]=_type
	PUBLIC.request_client("tydfg_auto_msg",{p=_p,auto_status=_type})
end
--当前比赛重新开始
function CMD.tydfg_start_again_msg(_init_rate,_init_stake,_seat_num)
	new_game(_init_rate,_init_stake,_seat_num)
	add_status_no()
	--通知客户端 新的一局
	PUBLIC.request_client("tydfg_start_again_msg",{status_no=status_no,status=s_info.status})	
end


--最终结算  ###_test
function CMD.tydfg_gameover_msg(_st_info,_remain_pai,_bomb_count,_is_chuntian)
	print("tydfg_gameover_msg!!")
	s_info.status="gameover"

	s_info.countdown=free_game_time
	overtime_cb=function ()
							print("CMD.tydfg_gameover_msg free_game :",DATA.my_id)
							free_game()
						end	
						
	settlement_info=_st_info
	settlement_info.remain_pai=_remain_pai
	add_status_no()
	
	-- 统计 数据落地
	local my_pos,dizhu_win,nongmin_win = 4,false,true
	local rate = s_info.my_rate

	if room_info.seat_num==s_info.dizhu then
		my_pos = 5
		dizhu_win,nongmin_win = true,false
	end
	
	local my_win = _st_info.winner==my_pos
	
	--记录输赢
	if my_win then
		PROTECT.add_statistics_player_freestyle_tyddz(dizhu_win,nongmin_win,false)
	else
		PROTECT.add_statistics_player_freestyle_tyddz(false,false,true)
	end

	settlement_info.room_rent=game_server_id_map[cur_play_game_info.id].room_rent

	--结算信息
	settlement_info.bomb_count = _bomb_count
	settlement_info.chuntian = _is_chuntian

	-- dump(settlement_info,"s_info.settlement_info")
	get_all_info_s2c()

	PUBLIC.request_client("tydfg_gameover_msg",
							{status_no=status_no,
							settlement_info=settlement_info})
	if DATA.chat_room_id then
		--room 会销毁聊天室所以不需要退出
		-- skynet.send(DATA.service_config.chat_service,"lua","exit_room", DATA.chat_room_id,DATA.my_id)
		DATA.chat_room_id=nil
	end

end

--扣除输掉的财物 如果财物不够则扣到零 返回实际成功扣除的值
function CMD.tydfg_deduct_lose(_num)
	return PUBLIC.change_game_coin(game_name,_num,ASSET_CHANGE_TYPE.TY_FREESTYLE_LOSE)
end

function CMD.tydfg_add_win(_num)
	PUBLIC.change_game_coin(game_name,_num,ASSET_CHANGE_TYPE.TY_FREESTYLE_AWARD)
end

--客户端请求 ***************

--**send info******
local my_pai_tmp_list = {-1,-2,-3,-4,-5,-6,-7,-8,-9,-10,-11,-12,-13,-14,-15,-16,-17,}

local send_info_func={}	
local function send_all_info()
	if gameover_all_info_s2c then
		PUBLIC.request_client("tydfg_all_info",gameover_all_info_s2c)
		return 0
	end
	if match_info then
		if s_info and my_pai_data then
			s_info.my_pai_list=tyDdzFunc.get_pai_list_by_map(my_pai_data.pai)
		else
			s_info.my_pai_list=my_pai_tmp_list
		end

		PUBLIC.request_client("tydfg_all_info", {
												status_no=status_no,
												match_info=match_info,
												room_info=room_info,
												status_info=s_info,
												players_info=p_info,
												settlement_info=settlement_info,
												})
		-- dump(s_info,"status_info")
		return 0
	end
	--没有状态时 表示没有在游戏中  返回状态码为 -1 
	PUBLIC.request_client("tydfg_all_info",{status_no=-1})
	return 0
end
send_info_func["all"]=send_all_info

local function send_status_info()
	if s_info then

		if s_info and my_pai_data then
			s_info.my_pai_list=tyDdzFunc.get_pai_list_by_map(my_pai_data.pai)
		else
			s_info.my_pai_list=my_pai_tmp_list
		end

		PUBLIC.request_client("tydfg_status_info",{status_no=status_no,status_info=s_info})
		-- dump(s_info,"status_info")
		return 0
	end
	--没有状态时 表示没有在游戏中  返回状态码为 -1 
	PUBLIC.request_client("tydfg_status_info",{status_no=-1})
	return 0
end
send_info_func["status"]=send_status_info


--**send info******
function REQUEST.tydfg_req_info_by_send(self)
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
--客户端请求 ***************







-- 统计相关 ***************
--[[
{
	id --玩家id

	钻石场
	dizhu_win_count
	nongmin_win_count
	defeated_count
}
]]
local statistics_player_freestyle_tyddz_data=nil

function PUBLIC.init_statistics_freestyle_tyddz_data()
	statistics_player_freestyle_tyddz_data=skynet.call(DATA.service_config.data_service,"lua",
											"get_statistics_player_freestyle_tyddz",DATA.my_id)
end

function PROTECT.add_statistics_player_freestyle_tyddz(_dizhu_win,_nongmin_win,_defeated,_game_model)

	if _dizhu_win then
		local num = statistics_player_freestyle_tyddz_data.dizhu_win_count+1
		statistics_player_freestyle_tyddz_data.dizhu_win_count=num
	elseif _nongmin_win then
		local num = statistics_player_freestyle_tyddz_data.nongmin_win_count+1
		statistics_player_freestyle_tyddz_data.nongmin_win_count=num
	elseif _defeated then
		local num = statistics_player_freestyle_tyddz_data.defeated_count+1
		statistics_player_freestyle_tyddz_data.defeated_count=num
	end


	skynet.send(DATA.service_config.data_service,"lua",
				"update_statistics_player_freestyle_tyddz",DATA.my_id,
					statistics_player_freestyle_tyddz_data)

end

function REQUEST.get_statistics_player_freestyle_tyddz(self)
	return {
			result=0,
			dizhu_win_count = statistics_player_freestyle_tyddz_data.dizhu_win_count,
			nongmin_win_count = statistics_player_freestyle_tyddz_data.nongmin_win_count,
			defeated_count = statistics_player_freestyle_tyddz_data.defeated_count,
			}
end


--自由场统计数据和奖励问题 ***************


return PROTECT


