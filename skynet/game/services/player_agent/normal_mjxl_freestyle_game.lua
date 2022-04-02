--
-- Author: HEWEI
-- Date: 2018/3/28
-- Time: 
-- 说明：normal_mjxl_freestyle_game  缩写 dfg
require "normal_enum"
local skynet = require "skynet_plus"
local basefunc=require"basefunc"
local nodefunc = require "nodefunc"
require"printfunc"
local normal_majiang=require "normal_majiang_lib"
local base = require "base"
local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC
local REQUEST=base.REQUEST
local PROTECT={}

local game_name="normal_mjxl_freestyle_game"

--比赛阶段（状态）
--[[
	-- 在哪个界面
	nil			--表示在大厅
	wait_begin  --报名，等待开始{当前报名人数，取消报名倒计时}
	wait_table  --报名结束，等待分配桌子（匹配玩家）
	wait_join   --等待加入房间

	--麻将阶段
	wait_p：等待人员入座阶段 
	ready： 准备阶段
	fp： 发牌阶段
	dingque： 定缺阶段
	cp： 出牌阶段
	settlement： 结算
	gameover ：游戏结束

--]]

-- 配置信息
--[[
	DATA.mjfg={
	    match_info={
	    	--游戏名字
	    	name,
	    	}
		room_info={
			room_id=_room_id,
			--桌号
			t_num=_t_num,
			seat_num=0,
			--底分
			init_stake=0,
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

			cur_mopai=0 11-n  

			cur_chupai ={seat_num=2,pai=12}

			cur_pgh_card=23
			
			--我的牌列表
			my_pai_list=nil,
			pg_pai=
			{
				[1]={
					pg_pai_list={
						type=1,
						pai=16,
					},
					...
				},
				...
			}
			chu_pai={
				[1]={pai_list={11,12,13}},
				[2]={pai_list={11,12,13}},
				...
			}

			--玩家的托管状态
			auto_status={0,0,0,0},

			--定缺的花色 -2 -1 0 1-3 具体的花色
			dingque_pai = {2,3,2,1},

			--当前动作
			action = {
				type = "cp",
				p=2,
				pai=15,
			}

			--骰子
			sezi_data={
				sezi=3,
				zhuang=1,
			}

			hu_data={
				[1]={
					type= zm 自摸, h 别人点炮
					pai = 14
					seat_num =1
				},
				...
			}

			player_remain_card = {14,14,14,15}

			remain_card = 12

		},
	}
--]]
--动作标记
local act_flag=false
--超时出牌计数-2次就自动托管
local overtime_count=0
--状态编号（依次增长）
local status_no=0
local game_server_id_map = {}
--报名的服务ID
local signup_svr_id
local match_info
--状态信息
local s_info
local room_info
--players_info
local p_info
--总结算信息
local settlement_info
--我的牌数据
local my_pai_data
--我的碰杠hash
local my_pg_map

local gameover_all_info_s2c=nil

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
	my_pg_map = nil

	PUBLIC.unlock(game_name)
	PUBLIC.free_agent(game_name)
end

local function add_status_no()
	status_no=status_no+1
end

local function call_room_service(_func_name,...)

	--print("call_room_service",room_info.room_id,_func_name,room_info.t_num,room_info.seat_num,...)
	return nodefunc.call(room_info.room_id,_func_name,room_info.t_num,room_info.seat_num,...)

end

local function set_auto(not_send)
	if s_info.auto_status[room_info.seat_num]==0 then 
		if ((s_info.status=="cp"
			or s_info.status=="peng_gang_hu"
			or s_info.status=="mo_pai"
			)
			and s_info.cur_p==s_info.seat_num ) or not_send then

			s_info.auto_status[room_info.seat_num]=1
			if not not_send then
				nodefunc.send(room_info.room_id,"auto",room_info.t_num,room_info.seat_num,1)
			end
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

--移除最后的出牌
local function remove_last_chupai()
	local data=s_info.cur_chupai
	if data and data.seat_num and data.seat_num>0 then
		local list=s_info.chu_pai[data.seat_num].pai_list
		list[#list]=nil
		data.seat_num=nil
		data.pai=nil
	end
end
--玩家碰杠操作牌
local function player_pg_pai(_seat_num,_pai,_type)
	
	local count = 0
	if _type == "peng" then
		count = 2
		--移除别人出的牌
		remove_last_chupai()
	elseif _type == "ag" then
		count = 4
	elseif _type == "zg" then
		count = 3
		--移除别人出的牌
		remove_last_chupai()
	elseif _type == "wg" then
		count = 1
	end

	s_info.player_remain_card[_seat_num]=s_info.player_remain_card[_seat_num]-count
	--自己
	if _seat_num == room_info.seat_num then
		my_pai_data[_pai]=my_pai_data[_pai]-count
		my_pg_map[_pai]=_type
	else
		--记牌器**********
		normal_majiang.jipaiqi_kick_pai(_pai,s_info.jipaiqi,count)
	end
	local pglist = s_info.pg_pai[_seat_num].pg_pai_list
	if _type ~= "wg" then
		pglist[#pglist+1]={
			type=_type,
			pai=_pai,
		}
	else
		for i,v in ipairs(pglist) do
			if v.pai==_pai then
				v.type="wg"
			end
		end
	end
	return true
end


--检测是否开始托管
local function chk_auto()
	
	overtime_count = overtime_count + 1

	if overtime_count>0 then
		set_auto()
	end
end


--自动出牌
local function auto_chupai()
	overtime_cb=nil
	auto_data=nil

	chk_auto()

	local _chu_pai = normal_majiang.auto_chupai(s_info.cur_mopai,my_pai_data,
							s_info.dingque_pai[room_info.seat_num])

	local ret = call_room_service("chu_pai",_chu_pai)

	if ret ~= 0 then
		-- dump(my_pai_data,"auto_chupai ****----")
	end

	print(DATA.my_id,"我出牌了:",_chu_pai,ret)

end

local function get_pai_list_by_map(pai_map)
	local pai_list = {}
	for pai,count in pairs(pai_map) do
		for i=1,count do
			pai_list[#pai_list+1]=pai
		end
	end

	return pai_list
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

	PROTECT.nmjxlfg_auto_cancel_signup()

end

local function new_game(_init_rate,_init_stake,_seat_num,_race,_race_count)
	s_info.status="wait_p"
	--没有就不要赋值 因为有可能是重新发牌
	if _seat_num then
		room_info.seat_num=_seat_num 
		s_info.seat_num=_seat_num
	end
	--底分
	room_info.init_stake=_init_stake
	room_info.init_rate=_init_rate

	-- s_info.win_count=PROTECT.get_ddzfree_drivingrange_today_win()
	s_info.countdown=0
	s_info.cur_p=0

	--每个人剩余的牌
	s_info.remain_pai_amount=nil
	--记牌器
	s_info.jipaiqi=nil
	--我的倍数
	s_info.my_rate=_init_rate or 1
	--动作序列--保留最近两次的即可
	s_info.act_list={}
	--玩家的托管状态
	s_info.auto_status={0,0,0,0}
	--当前玩的比赛的局数
	s_info.race=_race or s_info.race

	s_info.race_count=_race_count or s_info.race_count

	s_info.cur_mopai=nil

	s_info.cur_race=1

	s_info.cur_pgh_card=nil

	s_info.player_remain_card={0,0,0,0}
	
	s_info.cur_chupai={seat_num=nil,pai=nil}

	s_info.cur_pgh_allow_opt = nil

	-- 有出牌权限时的过情况 
	s_info.is_guo=nil

	my_pai_data=nil
	my_pg_map=nil
	
	s_info.remain_card = 0

	s_info.hu_data={
		{hu_data={}},
		{hu_data={}},
		{hu_data={}},
		{hu_data={}},
	}

	s_info.my_is_hu=false

	s_info.chu_pai={
		{pai_list={}},
		{pai_list={}},
		{pai_list={}},
		{pai_list={}},
	}

	s_info.dingque_pai={
		-2,-2,-2,-2
	}

	s_info.pg_pai={
		{pg_pai_list={}},
		{pg_pai_list={}},
		{pg_pai_list={}},
		{pg_pai_list={}},
	}

	settlement_info=nil	
	--}
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
						jing_bi=PUBLIC.query_game_coin(game_name),
					})
	if _data~="CALL_FAIL" and _data.result then
		if _data.p_info then 
			for _,_info in pairs(_data.p_info) do
				p_info.p_info[#p_info.p_info+1]=_info
			end
		end
		p_info.p_count=_data.p_count

		new_game(_data.rate,_data.init_stake,_data.seat_num,_data.race,_data.race_count)

		print("join succeed :",DATA.my_id,room_info.seat_num)
		return true
	else
		return false	
	end
end


--获得所有数据（格式为s2c）
local function get_all_info_s2c()

	if s_info and my_pai_data then
		s_info.my_pai_list=get_pai_list_by_map(my_pai_data)
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
function REQUEST.nmjxlfg_req_game_list(self)
	if act_flag then
		return_msg.result=1008
		return return_msg
	end
	act_flag=true
	local game_server_id_list
	print("nmjxlfg_req_game_list 1",DATA.service_config.normal_mjxl_freestyle_center_service)
	-- dump(DATA.service_config,"nmjxlfg_req_game_list 2")
	game_server_id_list,game_server_id_map=skynet.call(DATA.service_config.normal_mjxl_freestyle_center_service,"lua","get_game_list")
	act_flag=false

	if game_server_id_list then
		return {result=0,nmjxlfg_match_list=game_server_id_list}
	else
		game_server_id_map = {}
		return_msg.result=1004
		return return_msg
	end
end

--报名
function REQUEST.nmjxlfg_signup(self,_is_replay)

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

	local asset_lock_info

	local server_data = game_server_id_map[self.id]
	if not server_data or not server_data.signup_service_id then
		free_game()
		return_msg.result=1000
		act_flag=false
		return return_msg
	end
	local server_id=server_data.signup_service_id

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

	print("nmjxlfg_apply:",DATA.my_id)
	local _result=nodefunc.call(server_id,"player_signup",DATA.my_id)
	if _result=="CALL_FAIL" then
		free_game()
	elseif _result and _result.result==0 then
		
		local ret = PUBLIC.asset_commit(asset_lock_info.lock_id,ASSET_CHANGE_TYPE.MAJIANG_FREESTYLE_SIGNUP,self.id)
		PUBLIC.notify_asset_change_msg()

		if ret.result ~= 0 then
			print("asset_commit error ,result:"..ret.result)
		end

		signup_svr_id=server_id

		status_no=0

		DATA.mjfg={
					match_info=
					{
						name=_result.name,
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
		gameover_all_info_s2c=nil
		s_info=DATA.mjfg.status_info
		match_info=DATA.mjfg.match_info
		room_info=DATA.mjfg.room_info
		p_info=DATA.mjfg.players_info

		cur_play_game_info=self

		if not _is_replay then
			PUBLIC.free_game_coin(game_name)
		end

		PUBLIC.replenish_game_coin(game_name,_result.min_coin,_result.max_coin)

		update_timer=skynet.timer(dt,update)

		print("nmjxlfg_apply  succeed:",DATA.my_id)
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

function REQUEST.nmjxlfg_quit_game(self)

	gameover_all_info_s2c=nil

	if (s_info and s_info.status=="gameover") or has_hu then

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

	return_msg.result=1002
	return return_msg
end

--取消报名
function REQUEST.nmjxlfg_cancel_signup(self)
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
				CMD.change_asset_multi(signup_assets,ASSET_CHANGE_TYPE.MAJIANG_FREESTYLE_CANCEL_SIGNUP,cur_play_game_info.id)
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
function PROTECT.nmjxlfg_auto_cancel_signup()
	if s_info 
		and s_info.status=="wait_table" 
		and auto_cancel_signup_bt+auto_cancel_signup_time <= os.time() then

		local ret = REQUEST.nmjxlfg_cancel_signup()
		if ret.result == 0 then
			PUBLIC.request_client("nmjxlfg_auto_cancel_signup_msg",{result=0})
			print("overtime mj auto_cancel_signup")
		end
	end
end


--再来一局
function REQUEST.nmjxlfg_replay_game(self)

	--游戏结束了
	if (s_info and s_info.status=="gameover")  then
		gameover_all_info_s2c=nil
		free_game()
	end

	--如果信息还没有清除 就进行重玩
	if cur_play_game_info then
		return REQUEST.nmjxlfg_signup(cur_play_game_info,true)
	else
		cur_play_game_info = self
		local gl = REQUEST.nmjxlfg_req_game_list()
		if gl.result == 0 then
			return REQUEST.nmjxlfg_signup(cur_play_game_info,true)
		end
	end

	return_msg.result=2003
	return return_msg

end

function REQUEST.nmjxlfg_auto(self)
	if act_flag 
		or not s_info then
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


function CMD.nmjxlfg_enter_room_msg(_room_id,_t_num)

	s_info.status="wait_join"

	room_info.room_id=_room_id
	room_info.t_num=_t_num
	room_info.seat_num=0
	room_info.race_count=1

	p_info.p_info={}
	p_info.p_count=0

	-- s_info.countdown=join_room_wait_time
	
	-- overtime_cb=function ()
	-- 					print("自动加入房间")
	-- 					overtime_cb=nil
						join_room(room_info.room_id,room_info.t_num)
					-- end

	print("nmjxlfg_enter_room_msg",DATA.my_id)

	PUBLIC.add_game_consume_statistics(signup_assets)

	--通知客户端
	add_status_no()
	-- {result=0,status_no=status_no,room_info=room_info,players_info=p_info}
	PUBLIC.request_client("nmjxlfg_enter_room_msg",{status_no=status_no,room_info=room_info,players_info=p_info,win_count=s_info.win_count})
	
	
end
-- ###_test 目前是自动ready
function CMD.nmjxlfg_ready_msg()
	s_info.status="ready"
end
--当前总人数，玩家信息
function CMD.nmjxlfg_join_msg(_p_count,_info,_chat_room_id)

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
		PUBLIC.request_client("nmjxlfg_join_msg",{status_no=status_no,player_info=_info})
	end
end


--投骰子
function CMD.nmjxlfg_tou_sezi_msg(_sezi1,_sezi2,_zhuang,cd)
	print("nmjxlfg_tou_sezi_msg !")
	s_info.status="tou_sezi"
	s_info.countdown=cd

	s_info.sezi_data=
	{
		sezi_value1=_sezi1,
		sezi_value2=_sezi2,
		zj_seat=_zhuang,
	}

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nmjxlfg_tou_sezi_msg",{
		status_no=status_no,
		sezi_value1=_sezi1,
		sezi_value2=_sezi2,
		zj_seat=_zhuang,
		})

	print(DATA.my_id,"投骰子:",_sezi1,_sezi2,_zhuang,cd)
end


--发牌
function CMD.nmjxlfg_pai_msg(_pai,_remain_card)
	print("nmjxlfg_pai_msg! :")
	-- lyx_yy
	s_info.status="fp"

	s_info.remain_card = _remain_card

	s_info.player_remain_card={13,13,13,13}
	s_info.player_remain_card[s_info.sezi_data.zj_seat]=14

	my_pai_data=_pai
	my_pg_map={}

	local my_pai_list=get_pai_list_by_map(my_pai_data)

	--记牌器**********
	s_info.jipaiqi=normal_majiang.get_init_jipaiqi()
	for pai,v in pairs(my_pai_data) do
		normal_majiang.jipaiqi_kick_pai(pai,s_info.jipaiqi,v)
	end

	--机器人自动托管
	if not basefunc.chk_player_is_real(DATA.my_id) then
		set_auto(true)
	end
	--通知客户端
	add_status_no()
	PUBLIC.request_client("nmjxlfg_pai_msg",
		{
		status_no=status_no,
		my_pai_list=my_pai_list,
		race=s_info.cur_race,
		remain_card=_remain_card,
		})

	print(DATA.my_id,"发牌:")
end

local req_operator_funcs = {}

function req_operator_funcs.dq(_data)

	if _data.pai ~= 1 and _data.pai ~= 2 and _data.pai ~= 3 then
		print("ding que error ,seat,flower: ",room_info.seat_num,_data.pai)
		return_msg.result=1008
		return return_msg
	end

	if act_flag 
		or s_info.status~="ding_que"
		or s_info.dingque_pai[room_info.seat_num] > -1
		then

		return_msg.result=1008
		return return_msg
	end

	act_flag = true

	return_msg.result = call_room_service("ding_que",_data.pai)

	if return_msg.result == 0 then
		s_info.dingque_pai[room_info.seat_num]=0
		overtime_cb=nil
		cancel_auto()
	end
	
	act_flag = false

	print(DATA.my_id,"定缺:",_data.pai)

	return return_msg
end

function req_operator_funcs.cp(_data)

	--检查数据合法性
	if type(_data.pai) ~= "number" then
		return_msg.result=1008
		return return_msg
	end

	if act_flag 
		or (s_info.status~="cp" 
			and s_info.status~="mo_pai" 
			and s_info.status~="start") 
		or s_info.cur_p~=room_info.seat_num
		then
			return_msg.result=1008
			return return_msg
	end

	if not my_pai_data[_data.pai] or my_pai_data[_data.pai]<1 then
		return_msg.result=1008
		return return_msg
	end

	if s_info.my_is_hu and _data.pai~=s_info.cur_mopai then
		return_msg.result=1008
		return return_msg
	end

	act_flag = true

	return_msg.result = call_room_service("chu_pai",_data.pai)

	act_flag = false

	cancel_auto()
	print(DATA.my_id,"出牌:",_data.pai)

	return return_msg
end

function req_operator_funcs.peng(_data)

	if act_flag or s_info.status~="peng_gang_hu" then
		return_msg.result=1008
		return return_msg
	end
	local pai=s_info.cur_pgh_card
	if not pai or not my_pai_data[pai] or my_pai_data[pai]<2 then
		return_msg.result=1008
		return return_msg
	end
	act_flag = true

	return_msg.result = call_room_service("peng_pai",pai)

	act_flag = false

	cancel_auto()
	print(DATA.my_id,"碰:")

	return return_msg
end

function req_operator_funcs.gang(_data)
	--检查数据合法性
	if type(_data.pai) ~= "number" then
		return_msg.result=1008
		return return_msg
	end

	if act_flag 
		or (s_info.status~="peng_gang_hu" 
			and s_info.status~="mo_pai"
			and s_info.status~="start"
			and s_info.status~="cp")
		or not my_pai_data[_data.pai]
		or my_pai_data[_data.pai] < 1
		or normal_majiang.flower(_data.pai)==s_info.dingque_pai[room_info.seat_num]
		or s_info.remain_card < 1
		then
			return_msg.result=1008
			return return_msg
	end


	local gangType
	--判断杠类型
	if s_info.status=="peng_gang_hu" then
		--胡了牌之后不能zg
		if my_pai_data[_data.pai]==3 and _data.pai==s_info.cur_pgh_card  and not s_info.my_is_hu then
			gangType="zg"
		end
	elseif s_info.status=="mo_pai" and s_info.cur_p==room_info.seat_num then
		if my_pai_data[_data.pai]==4 then
			gangType="ag"
		elseif my_pai_data[_data.pai]==1 and my_pg_map[_data.pai]=="peng"  then
			--只能是摸的牌才扣钱  
			if _data.pai==s_info.cur_mopai then
				gangType="wg"
			else
				gangType="jwg"
			end
		end
	elseif s_info.status=="cp" or s_info.status=="start" then
		if my_pai_data[_data.pai]==4 then
			gangType="ag"
		end
	end
	if not gangType then
		return_msg.result=1008
		return return_msg
	end

	act_flag = true

	return_msg.result = call_room_service("gang_pai",gangType,_data.pai)

	act_flag = false

	cancel_auto()
	print(DATA.my_id,"杠:",_data.pai)


	return return_msg
end

function req_operator_funcs.guo(_data)

	if act_flag or s_info.status~="peng_gang_hu" then
		
		s_info.is_guo=1

		return_msg.result=1008
		return return_msg
	end
	act_flag = true

	return_msg.result = call_room_service("guo_pai")

	if return_msg.result == 0 then
		overtime_cb=nil
		cancel_auto()
		s_info.cur_pgh_allow_opt = nil
	end
	act_flag = false

	print(DATA.my_id,"过:")

	return return_msg
end

function req_operator_funcs.hu(_data)

	if act_flag 
		or (s_info.status~="peng_gang_hu" 
			and s_info.status~="mo_pai" 
			and s_info.status~="start")
		then
		return_msg.result=1008
		return return_msg
	end

	if s_info.status=="peng_gang_hu" 
		and (
				not s_info.cur_pgh_allow_opt or
				not s_info.cur_pgh_allow_opt.hu
			) then
		return_msg.result=1002
		return return_msg

	end

	if s_info.status~="peng_gang_hu" and not s_info.is_hu then
		return_msg.result=1002
		return return_msg
	end
 
 	act_flag = true

	return_msg.result = call_room_service("hu_pai")

	act_flag = false

	cancel_auto()
	print(DATA.my_id,"胡了:")

	return return_msg
end

function REQUEST.nmjxlfg_operator(_data)

	if not _data 
		or type(_data.type) ~= "string" then

		return_msg.result = 1008
		return return_msg
	
	end

	local func = req_operator_funcs[_data.type]
	if not func then
		return_msg.result = 1001
		return return_msg
	end

	return func(_data)
end


function CMD.nmjxlfg_dingque_permit(_cd)
	print("nmjxlfg_dingque_permit! :")
	s_info.status="ding_que"
	s_info.countdown=_cd

	s_info.dingque_pai={
		-1,-1,-1,-1
	}

	if s_info.auto_status[room_info.seat_num]==1 then
		auto_data={countdown=auto_wait_cp_time}
	end

	overtime_cb=function ()
					overtime_cb=nil
					auto_data=nil

					-- 随机定缺
					local my_pai_list=get_pai_list_by_map(my_pai_data)
					if 0 == call_room_service("ding_que",normal_majiang.ding_que(my_pai_list)) then
						s_info.dingque_pai[room_info.seat_num] = 0
					end
					
				end

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nmjxlfg_permit_msg",
							{status_no=status_no,
							status="ding_que",
							countdown=_cd,
							cur_p = 0,
						})


	print(DATA.my_id,"可以定缺了:")

end

function CMD.nmjxlfg_peng_gang_hu_permit(_pai,_pgh,_cd)
	print("nmjxlfg_peng_gang_hu_permit! :")
	s_info.status="peng_gang_hu"
	s_info.countdown=_cd
	s_info.is_hu=nil
	if s_info.auto_status[room_info.seat_num]==1 then
		auto_data={countdown=auto_wait_cp_time}
	end

	s_info.cur_p = room_info.seat_num

	s_info.cur_pgh_card = _pai
	s_info.cur_pgh_allow_opt = {
			peng=_pgh.peng and 1 or nil,
			gang=_pgh.gang and 1 or nil,
			hu=_pgh.hu and 1 or nil,
		}

	overtime_cb=function ()
					overtime_cb=nil
					auto_data=nil
					s_info.cur_pgh_allow_opt = nil

					if _pgh and _pgh.hu then
						call_room_service("hu_pai")
					else
						call_room_service("guo_pai")
						chk_auto()
					end
				end

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nmjxlfg_permit_msg",
	{
		status_no=status_no,
		status="peng_gang_hu",
		allow_opt=s_info.cur_pgh_allow_opt,
		countdown=_cd,
		pai=_pai,
		cur_p = room_info.seat_num,
	})

	print(DATA.my_id,"可以碰杠胡了:",_pai)

end


-- 可以 天胡 或者 出牌

function CMD.nmjxlfg_start_permit(_cur_p,_is_hu,_cd)
	print("CMD.nmjxlfg_start_permit",_cur_p,_is_hu,_cd)
	s_info.status="start"
	s_info.countdown =_cd
	s_info.cur_p = _cur_p
	s_info.is_hu=nil
	if _cur_p == room_info.seat_num then
		
		s_info.is_guo=nil

		s_info.is_hu = _is_hu

		overtime_cb=function ()
						overtime_cb=nil
						auto_data=nil
						s_info.is_hu = nil

						if _is_hu then
							call_room_service("hu_pai")
						else
							auto_chupai()
						end
					end
		if s_info.auto_status[room_info.seat_num]==1 then
			auto_data={countdown=auto_wait_cp_time}
		end			
	end


	--通知客户端
	add_status_no()
	PUBLIC.request_client("nmjxlfg_permit_msg",
	{
		status_no=status_no,
		status="start",
		countdown=_cd,
		cur_p = _cur_p,
	})
	
end


-- ###_xiugai : 
function CMD.nmjxlfg_chupai_permit(_cur_p,_cd)
	print("nmjxlfg_chupai_permit! :",_cur_p,_cd)
	s_info.status="cp" -- 出牌状态
	s_info.countdown=_cd
	s_info.cur_p = _cur_p
	s_info.is_hu=nil
	if _cur_p == room_info.seat_num then
		
		s_info.is_guo=nil

		if s_info.auto_status[room_info.seat_num]==1 then
			auto_data={countdown=auto_wait_cp_time}
		end

		overtime_cb=auto_chupai

	end

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nmjxlfg_permit_msg",{status_no=status_no,
		status="cp",
		countdown=_cd,
		cur_p = _cur_p
	})

	print(DATA.my_id,"可以出牌了:",_cur_p)
end

function CMD.nmjxlfg_mopai_permit(_cur_p,_pai,_is_hu,_cd,_remain_card)
	print("nmjxlfg_mopai_permit. seat,_cur_p,_pai,_is_hu,_cd :",room_info.seat_num,_cur_p,_pai,_is_hu,_cd)

	s_info.status="mo_pai"
	s_info.countdown=_cd
	s_info.cur_p = _cur_p
	s_info.cur_mopai=_pai

	
	s_info.remain_card = _remain_card
	s_info.player_remain_card[_cur_p]=s_info.player_remain_card[_cur_p]+1

	s_info.is_hu=nil
	
	if _cur_p == room_info.seat_num then
		
		s_info.is_guo=nil
		
		--记牌器**********
		normal_majiang.jipaiqi_kick_pai(_pai,s_info.jipaiqi,1)

		my_pai_data[_pai]=(my_pai_data[_pai] or 0) + 1
		s_info.is_hu = _is_hu

		if s_info.auto_status[room_info.seat_num]==1 then
			auto_data={countdown=auto_wait_cp_time}
		end

		overtime_cb = function ()
				overtime_cb = nil
				auto_data=nil
				s_info.is_hu = nil
				if _is_hu then
					call_room_service("hu_pai")
				else
					auto_chupai()
				end
		end

	end

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nmjxlfg_permit_msg",
	{
		status_no=status_no,
		status="mo_pai",
		countdown=_cd,
		pai=_pai,
		cur_p = _cur_p
	})

	print(DATA.my_id,"摸牌:",_cur_p,_pai)
end

--定缺完成
function CMD.nmjxlfg_ding_que_msg(_ding_que_datas)

	s_info.dingque_pai=_ding_que_datas

	-- dump(s_info.dingque_pai,"CMD.nmjxlfg_ding_que_msg ",tostring(room_info.seat_num))

	--处理：每个玩家的 定缺 
	add_status_no()
	PUBLIC.request_client("nmjxlfg_dingque_result_msg",
		{
		status_no=status_no,
		result=s_info.dingque_pai
		}
		)

	-- dump(_ding_que_datas,DATA.my_id.."所有人定缺完成了:")

end


--玩家出牌
function CMD.nmjxlfg_chu_pai_msg(_act)

	s_info.action=_act

	s_info.cur_mopai = nil
	s_info.cur_chupai.seat_num=_act.p
	s_info.cur_chupai.pai=_act.pai

	s_info.player_remain_card[_act.p]=s_info.player_remain_card[_act.p]-1

	local len = #s_info.chu_pai[_act.p].pai_list+1
	s_info.chu_pai[_act.p].pai_list[len]=_act.pai

	if _act.p == room_info.seat_num then
        overtime_cb=nil
		my_pai_data[_act.pai] = my_pai_data[_act.pai] - 1
	else
		--记牌器**********
		normal_majiang.jipaiqi_kick_pai(_act.pai,s_info.jipaiqi,1)
	end

	add_status_no()
	PUBLIC.request_client("nmjxlfg_action_msg",
		{
		status_no=status_no,
		action=s_info.action
		})


	print(DATA.my_id,"出了牌:",_act.p,_act.pai)

end

--碰牌完成
function CMD.nmjxlfg_peng_msg(act)

    if act.p == room_info.seat_num then
        overtime_cb=nil
        s_info.cur_pgh_allow_opt = nil
    end

	s_info.action=act

	player_pg_pai(act.p,act.pai,"peng")

	add_status_no()
	PUBLIC.request_client("nmjxlfg_action_msg",
		{
		status_no=status_no,
		action=s_info.action
		})

	print(DATA.my_id,"碰了牌:",act.p,act.pai)
end

--杠牌完成
function CMD.nmjxlfg_gang_msg(act)

	if act.p == room_info.seat_num then
        overtime_cb=nil
        s_info.cur_pgh_allow_opt = nil
    end

	s_info.action=act

	player_pg_pai(act.p,act.pai,act.type)


	add_status_no()
	PUBLIC.request_client("nmjxlfg_action_msg",
		{
		status_no=status_no,
		action=s_info.action,
		})

	print(DATA.my_id,"杠了牌:",act.p,act.pai,act.type)

end

--胡牌完成
-- 参数 _type ： "zimo" 自摸， "pao" 别人点炮， "qghu" 抢杠胡（抢别人的弯杠）
function CMD.nmjxlfg_hu_msg(_action)

	--s_info.hu_data[_action.p][#s_info.hu_data[_action.p]]=_action.hu_data
	table.insert(s_info.hu_data[_action.p].hu_data,_action.hu_data)

	s_info.action = _action

	local _seat_num = _action.p
	local _pai = _action.hu_data.pai
	local _pao_seat = _action.hu_data.dianpao_p
	local _type = _action.hu_data.hu_type

	if _seat_num==room_info.seat_num then
        overtime_cb=nil
        s_info.cur_pgh_allow_opt = nil
        s_info.is_hu = nil
		s_info.my_is_hu=true 
	end
	
	if "pao" == _type then
		
		remove_last_chupai()

	elseif "qghu" == _type then
		--把这个杠的排变成碰
		for i,pg in pairs(s_info.pg_pai[_pao_seat].pg_pai_list) do
			if pg.pai == _pai then
				s_info.pg_pai[_pao_seat].pg_pai_list[i].type = "peng"
			end
		end
	elseif "zimo"==_type then
		--将摸的牌扣除
		s_info.player_remain_card[_seat_num]=s_info.player_remain_card[_seat_num]-1
		if _seat_num == room_info.seat_num then
			my_pai_data[_pai]=my_pai_data[_pai] - 1
		else
			--记牌器**********
			normal_majiang.jipaiqi_kick_pai(_pai,s_info.jipaiqi,1)
		end
	end


	add_status_no()
	PUBLIC.request_client("nmjxlfg_action_msg",
		{
		status_no=status_no,
		action=s_info.action,
		})

	
	print(DATA.my_id,"胡了牌:",_seat_num,_pao_seat,_pai,_type)

end


--胡牌完成
-- 参数 _settle_data ：参见协议 .nmjxlfg_settlement_info
function CMD.nmjxlfg_gameover_msg(_settle_data)

	-- print("========= game over ============\n",basefunc.tostring(_settle_data))
	
	s_info.status = "gameover"

	s_info.countdown=free_game_time
	overtime_cb=function ()
						print("CMD.nmjxlfg_gameover_msg free_game :",DATA.my_id)
						free_game()
					end
					
	settlement_info = {settlement_items={}}

	local my_order = 0
	for i,data in ipairs(_settle_data) do

		settlement_info.settlement_items[i] = data

		if data.seat_num == room_info.seat_num then
			my_order = i
		end
	end

	-- print("========= settlement_info ============\n",basefunc.tostring(settlement_info,10))
	
	settlement_info.room_rent=game_server_id_map[cur_play_game_info.id].room_rent
	
	add_status_no()
	
	get_all_info_s2c()

	PUBLIC.request_client("nmjxlfg_gameover_msg",
		{
		status_no=status_no,
		settlement_info = settlement_info,
		})

	if _settle_data[my_order].score < 0 then
		PROTECT.add_statistics_player_freestyle_mjxl(false,true)
	else
		PROTECT.add_statistics_player_freestyle_mjxl(true,false)
	end
	
	if DATA.chat_room_id then
		--room 会销毁聊天室所以不需要退出
		-- skynet.send(DATA.service_config.chat_service,"lua","exit_room", DATA.chat_room_id,DATA.my_id)
		DATA.chat_room_id=nil
	end
end

--玩家托管消息
function CMD.nmjxlfg_auto_msg(_p,_type)
	s_info.auto_status[_p]=_type
	PUBLIC.request_client("nmjxlfg_auto_msg",{p=_p,auto_status=_type})
	print("托管",_p,_type)
end
--当前比赛重新开始
function CMD.nmjxlfg_start_again_msg(_init_rate,_init_stake,_seat_num)
	new_game(_init_rate,_init_stake,_seat_num)
	add_status_no()
	--通知客户端 新的一局
	PUBLIC.request_client("nmjxlfg_start_again_msg",{status_no=status_no,status=s_info.status})	
end


--晋级决赛 - 调整分数
function CMD.normal_mjxl_grades_change_msg(_grades)
		
	for i,d in ipairs(_grades) do
		p_info.p_info[d.cur_p].jing_bi = p_info.p_info[d.cur_p].jing_bi + d.grades
	end

	PUBLIC.request_client("nmjxlfg_grades_change_msg",{status_no=status_no,data=_grades})
end

--扣除输掉的财物 如果财物不够则扣到零 返回实际成功扣除的值
function CMD.normal_mjxl_deduct_lose(_num)
	return PUBLIC.change_game_coin(game_name,_num,ASSET_CHANGE_TYPE.MJXL_MAJIANG_FREESTYLE_LOSE)
end

function CMD.normal_mjxl_add_win(_num)
	PUBLIC.change_game_coin(game_name,_num,ASSET_CHANGE_TYPE.MJXL_MAJIANG_FREESTYLE_AWARD)
end

--客户端请求 ***************

--**send info******
local send_info_func={}	
local function send_all_info()
	if gameover_all_info_s2c then
		PUBLIC.request_client("nmjxlfg_all_info",gameover_all_info_s2c)
		return 0
	end
	if match_info then
		if s_info and my_pai_data then
			s_info.my_pai_list=get_pai_list_by_map(my_pai_data)
		end 
		PUBLIC.request_client("nmjxlfg_all_info", {
												status_no=status_no,
												match_info=match_info,
												room_info=room_info,
												status_info=s_info,
												players_info=p_info,
												settlement_info=settlement_info,
												})
		return 0
	end
	--没有状态时 表示没有在游戏中  返回状态码为 -1 
	PUBLIC.request_client("nmjxlfg_all_info",{status_no=-1})
	return 0
end
send_info_func["all"]=send_all_info

local function send_status_info()
	if s_info then

		if s_info and my_pai_data then
			s_info.my_pai_list=get_pai_list_by_map(my_pai_data)
		end 

		PUBLIC.request_client("nmjxlfg_status_info",{status_no=status_no,status_info=s_info})
		return 0
	end
	--没有状态时 表示没有在游戏中  返回状态码为 -1 
	PUBLIC.request_client("nmjxlfg_status_info",{status_no=-1})
	return 0
end
send_info_func["status"]=send_status_info


--**send info******
function REQUEST.nmjxlfg_req_info_by_send(self)
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

function REQUEST.nmjxlfg_all_info(self)
	if s_info then
		if s_info and my_pai_data then
			s_info.my_pai_list=get_pai_list_by_map(my_pai_data)
		end 
		
		return
		{
			result=0,
			status_no=status_no,
			match_info=match_info,
			room_info=room_info,
			status_info=s_info,
			players_info=p_info,
			settlement_info=settlement_info,
		}
	end

	return_msg.result=1004
	return return_msg
end
--客户端请求 ***************





-- 统计相关 ***************
--[[
{
	id --玩家id
	win_count
	defeated_count
}
]]
local statistics_player_freestyle_mjxl_data=nil

function PUBLIC.init_statistics_freestyle_mjxl_data()
	statistics_player_freestyle_mjxl_data=skynet.call(DATA.service_config.data_service,"lua",
											"get_statistics_player_freestyle_mjxl",DATA.my_id)
end

function PROTECT.add_statistics_player_freestyle_mjxl(_win,_defeated)

	if _win then
		local num = statistics_player_freestyle_mjxl_data.win_count+1
		statistics_player_freestyle_mjxl_data.win_count=num
	elseif _defeated then
		local num = statistics_player_freestyle_mjxl_data.defeated_count+1
		statistics_player_freestyle_mjxl_data.defeated_count=num
	end

	skynet.send(DATA.service_config.data_service,"lua",
				"update_statistics_player_freestyle_mjxl",DATA.my_id,
					statistics_player_freestyle_mjxl_data)

end

function REQUEST.get_statistics_player_freestyle_mjxl(self)
	return {
			result=0,
			win_count = statistics_player_freestyle_mjxl_data.win_count,
			defeated_count = statistics_player_freestyle_mjxl_data.defeated_count,
			}
end

--统计数据问题 ***************



return PROTECT


