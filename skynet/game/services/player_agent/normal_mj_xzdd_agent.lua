--
-- Author: HEWEI
-- Date: 2018/3/28
-- Time: 
require "normal_enum"
local skynet = require "skynet_plus"
local basefunc=require"basefunc"
local nodefunc = require "nodefunc"
require"printfunc"
local nor_mj_base_lib=require "nor_mj_base_lib"
local base = require "base"
local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC
local REQUEST=base.REQUEST
local PROTECT={}



--配置
--超时出牌计数N次就自动托管cfg
local auto_count_cfg=0
--托管后自动出牌的时间cfg
local auto_wait_cp_time_cfg = 2
--超时后是否需要自动操作 1 需要 0 不需要
local overtime_auto_action_cfg=1



--比赛阶段（状态）
--[[
	--麻将阶段
	ready： 准备阶段
	begin: 开始阶段
	fp： 发牌阶段
	dingzhuang 定庄
	dingque： 定缺阶段
	cp： 出牌阶段
	settlement ： 结算
	gameover ：游戏结束
--]]

--[[
	local myGameName="xzdd"
    --游戏信息
	PROECT.game_info={
		modelName="friendgame" ,"macth","freestyle"
		config={}  --具体游戏模式下的配置   
	}
	
	PROECT.status_info={

			status=nil
			--当前是第几把
			cur_race=0,
			--一共几把
			race_count=0,
			--基础分数（低分）
			init_stake=1,
			--基础倍数（低倍）
			init_rate=1,

			room_id=_room_id,
			--桌号
			t_num=_t_num,

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
			

			hu_data={
				[1]={
					type= zm 自摸, h 别人点炮
					pai = 14
					seat_num =1
				},
				...
			}
			
			player_remain_card = {14,14,14,15},

			remain_card = 12,
			--记牌器
			jipaiqi=nil,
			--当前pgh状态允许的操作
			cur_pgh_allow_opt=nil,
			--在出牌权限下点了过
			is_guo=nil,
			--我的牌数据
			my_pai_data=nil,
			--我的碰杠牌数据
			my_pg_map=nil,

			
		    --骰子
			sezi_value1=0,
			sezi_value2=0,
	        --庄座位号
			zj_seat=0,

			--总玩家数
			player_count=0,

		},
	}
--]]
local myGameName="nor_mj_xzdd"
--上层  model的数据
local all_data



--动作标记
local act_flag=false
--超时出牌计数N次就自动托管
local overtime_count=0
--状态信息
local s_info
--我的牌数据
local my_pai_data
--我的碰杠hash
local my_pg_map


--托管数据
local auto_data
--超时回调
local overtime_cb

local update_timer
--update 间隔
local dt=0.5
--返回优化，避免每次返回都创建表
local return_msg={result=0}

local function add_status_no()
	all_data.status_no=all_data.status_no+1
end
local function set_overtime_cb(func)
	if overtime_auto_action_cfg==1 then
		overtime_cb=func
		if s_info and  s_info.auto_status and s_info.auto_status[s_info.seat_num]==1 then
			auto_data={countdown=auto_wait_cp_time_cfg}
		end
	end
end

local function call_room_service(_func_name,...)

	return nodefunc.call(s_info.room_id,_func_name,s_info.t_num,s_info.seat_num,...)

end
local function send_room_service(_func_name,...)

	nodefunc.send(s_info.room_id,_func_name,s_info.t_num,s_info.seat_num,...)

end

local function set_auto()
	if s_info.auto_status[s_info.seat_num]==0 then 
		s_info.auto_status[s_info.seat_num]=1
		if basefunc.chk_player_is_real(DATA.my_id) then
			send_room_service("auto",1)
		end
		auto_data={countdown=auto_wait_cp_time_cfg}
		return true
	end

	return false
end

local function cancel_auto()
	if s_info.auto_status[s_info.seat_num]==1 then
		s_info.auto_status[s_info.seat_num]=0
		overtime_count=0
		auto_data=nil
		if basefunc.chk_player_is_real(DATA.my_id) then
			send_room_service("auto",0)
		end

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
	if _seat_num == s_info.seat_num then
		my_pai_data[_pai]=my_pai_data[_pai]-count
		my_pg_map[_pai]=_type
	else
		--记牌器**********
		nor_mj_base_lib.jipaiqi_kick_pai(_pai,s_info.jipaiqi,count)
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

	if overtime_count>auto_count_cfg then
		set_auto()
	end
end


--自动出牌
local function auto_chupai()
	overtime_cb=nil
	auto_data=nil

	chk_auto()

	local _chu_pai = nor_mj_base_lib.auto_chupai(s_info.cur_mopai,my_pai_data,
							s_info.dingque_pai[s_info.seat_num])

	print("mj auto cp ******** ",_chu_pai)
	local ret = call_room_service("chu_pai",_chu_pai) 

	if ret ~= 0 then
		dump(my_pai_data,"auto_chupai ****----")
	end

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
	
	if s_info and s_info.countdown and s_info.countdown>0 then
		
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

	-- PROTECT.mjfg_auto_cancel_signup()

end


local function new_game()
	--一把游戏开始的时间
	DATA.one_game_begin_time=os.time()

	s_info.countdown=0
	s_info.cur_p=nil
	--每个人剩余的牌
	s_info.remain_pai_amount=nil
	--记牌器
	s_info.jipaiqi=nil
	--我的倍数
	s_info.my_rate=all_data.config.init_rate or 1
	--动作序列--保留最近两次的即可
	s_info.act_list={}
	--玩家的托管状态
	s_info.auto_status={0,0,0,0}
	auto_data=nil

	s_info.cur_mopai=nil

	s_info.cur_pgh_card=nil

	s_info.my_pai_list={}

	s_info.player_remain_card={0,0,0,0}
	
	s_info.cur_chupai={seat_num=nil,pai=nil}

	s_info.cur_pgh_allow_opt = nil
	-- 有出牌权限时的过情况 
	s_info.is_guo=nil

	my_pai_data=nil
	my_pg_map=nil
	
	s_info.remain_card = GAME_TYPE_TOTAL_PAI_NUM[all_data.game_type] or 108

	s_info.hu_data={}

	s_info.game_bankrupt={0,0,0,0}

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

	--骰子
	s_info.sezi_data={}
	s_info.sezi_data.sezi_value1=0
	s_info.sezi_data.sezi_value2=0

	s_info.score_change_list = {}

	--庄座位号
	s_info.sezi_data.zj_seat=0

	s_info.settlement_info=nil

	-- 用来换三张的牌
	s_info.huan_san_zhang_old = nil
	-- 最终换成的三张牌
	s_info.huan_san_zhang_new = nil

	s_info.is_huan_pai = 0

	s_info.da_piao_nums = {
		-1,-1,-1,-1
	}

	--- add by wss 转雨
	s_info.zhuan_yu_data = {}


end


local function init_game()
	s_info.status="wait_join"
	s_info.cur_race=1
	s_info.next_race=1
	new_game()
end

function PROTECT.join_room(_data)
	--加入房间
	local return_data=nodefunc.call(s_info.room_id,"join",s_info.t_num,DATA.my_id,_data)
	if return_data=="CALL_FAIL" or return_data ~= 0 then
		dump(return_data)
		skynet.fail(string.format("join_game_room error:call return %s",tostring(return_data)))
		return false
	end
	return true
end

function PROTECT.dq(_data)

	if act_flag 
		or s_info.status~="ding_que"
		or s_info.dingque_pai[s_info.seat_num] ~= -1
		then

		return_msg.result=1002
		return return_msg
	end
	if _data.pai ~= 1 and _data.pai ~= 2 and _data.pai ~= 3 then
		print("ding que error ,seat,flower: ",s_info.seat_num,_data.pai)
		return_msg.result=1008
		return return_msg
	end
	act_flag = true

	return_msg.result = call_room_service("ding_que",_data.pai)
	
    cancel_auto()
	
	act_flag = false

	print(DATA.my_id,"定缺:",_data.pai)

	return return_msg
end

function PROTECT.cp(_data)

	--检查数据合法性
	if type(_data.pai) ~= "number" then
		print("cpxxxxxxxx  not number",_data.pai)
		return_msg.result=1003
		return return_msg
	end

	if act_flag or not s_info
	or (s_info.status~="cp" 
			and s_info.status~="mo_pai" 
			and s_info.status~="start") 
		or s_info.cur_p~=s_info.seat_num
		then
			print("cpxxxxxxxx 1002",_data.pai)
			return_msg.result=1002
			return return_msg
	end

	if not my_pai_data[_data.pai] or my_pai_data[_data.pai]<1 then
		dump(my_pai_data,"cp xxxxxxxx my_pai_data")
		print("cpxxxxxxxx my_pai_data not 1008",_data.pai)
		return_msg.result=1008
		return return_msg
	end

	-- 检查 打缺
	local _que_type = s_info.dingque_pai[s_info.seat_num]
	if nor_mj_base_lib.flower(_data.pai) ~= _que_type then
		for _pai,_count in pairs(my_pai_data) do
			if nor_mj_base_lib.flower(_pai) == _que_type and _count > 0 then

				-- 还未打缺
				print("chu pai , que pai error:",_data.pai,_pai,_que_type)
				return_msg.result=1003
				return return_msg
			end
		end
	end
	

	act_flag = true

	return_msg.result = call_room_service("chu_pai",_data.pai)

	act_flag = false

	cancel_auto()

	print(DATA.my_id,"出牌:",_data.pai)

	return return_msg
end

function PROTECT.peng(_data)

	if act_flag or not s_info or s_info.status~="peng_gang_hu" then
		return_msg.result=1002
		return return_msg
	end
	local pai=s_info.cur_pgh_card
	if not pai or not my_pai_data[pai] or my_pai_data[pai]<2 then
		dump(my_pai_data,"cp xxxxxxxx peng my_pai_data")
		print("cpxxxxxxxx peng my_pai_data not 1008",pai)
		return_msg.result=1003
		return return_msg
	end
	act_flag = true

	return_msg.result = call_room_service("peng_pai",pai)

	act_flag = false

    cancel_auto()

	print(DATA.my_id,"碰:",pai)

	return return_msg
end

function PROTECT.gang(_data)
	--检查数据合法性
	if type(_data.pai) ~= "number" then
		print("cpxxxxxxxx gang xx not 1003",_data.pai)
		return_msg.result=1003
		return return_msg
	end

	if act_flag 
		or (s_info.status~="peng_gang_hu" 
			and s_info.status~="mo_pai"
			and s_info.status~="start"
			and s_info.status~="cp")
		or not my_pai_data[_data.pai]
		or my_pai_data[_data.pai] < 1
		or nor_mj_base_lib.flower(_data.pai)==s_info.dingque_pai[s_info.seat_num]
		or s_info.remain_card < 1
		then
			print("cpxxxxxxxx gang xx not 1002",_data.pai)
			return_msg.result=1002
			return return_msg
	end


	local gangType
	--判断杠类型
	if s_info.status=="peng_gang_hu" then
		if my_pai_data[_data.pai]==3 and _data.pai==s_info.cur_pgh_card then
			gangType="zg"
		end
	elseif s_info.status=="mo_pai" and s_info.cur_p==s_info.seat_num then
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
		print("cpxxxxxxxx not gangType xx not 1004")
		return_msg.result=1004
		return return_msg
	end

	act_flag = true

	return_msg.result = call_room_service("gang_pai",gangType,_data.pai)

	act_flag = false

	cancel_auto()

	print(DATA.my_id,"杠:",_data.pai)


	return return_msg
end

function PROTECT.guo(_data)

	if act_flag or s_info.status~="peng_gang_hu" then
		--特殊的过  自己出牌的时候  过杠等
		s_info.is_guo=1

		return_msg.result=1008
		return return_msg
	end
	act_flag = true

	return_msg.result = call_room_service("guo_pai")

	--我自己操作了 则取消托管
	cancel_auto()

	act_flag = false

	print(DATA.my_id,"过:")

	return return_msg
end

function PROTECT.hu(_data)

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

	act_flag = false

	return return_msg
end

function REQUEST.nor_mj_xzdd_operator(_data)

	if not _data 
		or type(_data.type) ~= "string" 
		or not s_info 
		or (_data.type~="cp" 
			and _data.type~="peng" 
			and _data.type~="gang" 
			and _data.type~="guo" 
			and _data.type~="hu" 
			and _data.type~="ready"
			and _data.type~="dq") then

		print("---- _data.type:",_data.type)
		------ add by wss -- test
		if not _data then
			print("nor_mj_xzdd_operator----- not _data")
		elseif not s_info  then
			print("nor_mj_xzdd_operator----- not s_info")
		end

		return_msg.result = 1008
		return return_msg
	
	end

	local func = PROTECT[_data.type]
	if not func then
		return_msg.result = 1001
		return return_msg
	end

	return func(_data)
end

function REQUEST.nor_mj_xzdd_auto(_data)
	if act_flag 
		or not s_info then
			return_msg.result=1002
			return return_msg
	end

	if _data.operate~=0 and _data.operate~=1 then
		return_msg.result=1003	
		return return_msg
	end

	act_flag=true
	if _data.operate==1 then 
		set_auto()
	else
		cancel_auto()
	end

	act_flag=false
	return_msg.result=0	
	return return_msg
end

function REQUEST.nor_mj_xzdd_huansanzhang(_data)
	if act_flag 
		or not s_info or s_info.status~="huan_san_zhang" or s_info.huan_san_zhang_new then
			return_msg.result=1002
			return return_msg
	end
	print(DATA.my_id, "换三张：",basefunc.tostring(_data.paiVec,nil,""))
	_data.paiVec = _data.paiVec or {}

	--- 做检查
	local is_can_change = nor_mj_base_lib.check_huan_pai(my_pai_data , _data.paiVec )
	if not is_can_change then
		print("huan_san_zhang is_can_change false: ")
		return 1002
	end
	act_flag=true

	---- 调用房间的换三张函数
	return_msg.result = call_room_service("huan_san_zhang" , _data.paiVec)

	act_flag=false
	
	return return_msg
end

function REQUEST.nor_mj_xzdd_dapiao(_data)

	if act_flag 
		or not s_info or s_info.status~="da_piao" or s_info.da_piao_nums[s_info.seat_num]~=-1 then
			return_msg.result=1002
			return return_msg
	end

	print(DATA.my_id, "打漂：",_data.piaoNum)

	act_flag=true

	--s_info.da_piao_num = _data.piaoNum

	---- 调用房间的打漂
	return_msg.result = call_room_service("da_piao" , _data.piaoNum)

	act_flag=false
	
	return return_msg
end

function REQUEST.nor_mj_xzdd_get_race_score()
	
	if all_data and all_data.m_PROTECT.get_race_score then
		return all_data.m_PROTECT.get_race_score()
	end

	return {result=1002}
end



-- 过只有我自己能看见
function CMD.nor_mj_xzdd_guo_msg(_data)

	-- 碰杠胡权限中，我自己选择了过
	if s_info.status=="peng_gang_hu" then

		overtime_cb=nil
		s_info.cur_pgh_allow_opt = nil

	end
end

function CMD.nor_mj_xzdd_notify_tuoguan_param(_game_param)
	-- 发托管需要的参数
	PUBLIC.request_client("nor_mj_xzdd_notify_tuoguan_param",_game_param)	
end
function CMD.nor_mj_xzdd_join_msg(_info,_my_join_return)
	
	if _info and _info.id~=DATA.my_id then
		if all_data.m_PROTECT and all_data.m_PROTECT.player_join_msg then
			all_data.m_PROTECT.player_join_msg(_info)
		end
		s_info.game_players_info[_info.seat_num]=_info
	else
		s_info.status="ready"
		
		s_info.ready=_my_join_return.ready
		s_info.seat_num=_my_join_return.seat_num

		s_info.game_players_info=_my_join_return.p_info

		s_info.init_rate=_my_join_return.init_rate
		s_info.race_count=_my_join_return.race_count
		s_info.cur_race=_my_join_return.cur_race
		s_info.init_stake=_my_join_return.init_stake
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

function CMD.nor_mj_xzdd_ready_msg(_seat_num)

	s_info.ready[_seat_num]=1
	
	if _seat_num == s_info.seat_num then
		new_game()
		s_info.status="ready"
		s_info.cur_race=s_info.next_race
	end

	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_ready_msg",
		{
		status_no = all_data.status_no,
		seat_num = _seat_num,
		cur_race = s_info.cur_race,
		})

end
function CMD.nor_mj_xzdd_notify_tuoguan_pai(_pai_data)
	PUBLIC.request_client("nor_mj_xzdd_notify_tuoguan_pai",_pai_data)	
end

function CMD.nor_mj_xzdd_begin_msg(_cur_race,_again)
	print("xxxxxxxxxxx nor_mj_xzdd_begin_msg,--- majiang ---time:",os.time() , DATA.my_id)
	add_status_no()
	s_info.status="begin"
	if _again then
		new_game()
	end
	s_info.ready=nil
	PUBLIC.request_client("nor_mj_xzdd_begin_msg",
												{
												status_no=all_data.status_no,
												cur_race =s_info.cur_race,
												})

	if all_data.m_PROTECT and all_data.m_PROTECT.begin_msg then
		all_data.m_PROTECT.begin_msg(_cur_race,_again)
	end	
end

--投骰子
function CMD.nor_mj_xzdd_tou_sezi_msg(_sezi1,_sezi2,_zhuang,_cd)
	s_info.status="tou_sezi"
	s_info.countdown=DATA.robot_cd or _cd

	s_info.sezi_data.sezi_value1=_sezi1
	s_info.sezi_data.sezi_value2=_sezi2
	s_info.sezi_data.zj_seat=_zhuang

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_tou_sezi_msg",{
		status_no=all_data.status_no,
		sezi_value1=_sezi1,
		sezi_value2=_sezi2,
		zj_seat=_zhuang,
		})


	--比赛场需要
	if all_data.m_PROTECT and all_data.m_PROTECT.tou_sezi_msg then
		all_data.m_PROTECT.tou_sezi_msg(_zhuang)
	end
	
end


function CMD.nor_mj_xzdd_auto_msg(_seat_num,_type)

	s_info.auto_status[_seat_num]=_type
	PUBLIC.request_client("nor_mj_xzdd_auto_msg",{p=_seat_num,auto_status=_type})

end


-- function CMD.nor_mj_xzdd_zhuang_msg(_zhuang)
-- 	s_info.zj_seat=_zhuang
-- end


--发牌
function CMD.nor_mj_xzdd_pai_msg(_pai,_remain_card)
	s_info.status="fp"

	s_info.remain_card = _remain_card

	local shouPaiNum = GAME_TYPE_PAI_NUM[all_data.game_type] or 13

	s_info.player_remain_card={shouPaiNum,shouPaiNum,shouPaiNum,shouPaiNum}
	s_info.player_remain_card[s_info.sezi_data.zj_seat]=shouPaiNum + 1

	my_pai_data=_pai
	my_pg_map={}

	local my_pai_list=get_pai_list_by_map(my_pai_data)

	--记牌器**********  ###_test
	s_info.jipaiqi=nor_mj_base_lib.get_init_jipaiqi()

	for pai,v in pairs(my_pai_data) do
		nor_mj_base_lib.jipaiqi_kick_pai(pai,s_info.jipaiqi,v)
	end

	if all_data.game_type == "nor_mj_xzdd_er_7" or all_data.game_type == "nor_mj_xzdd_er_13" then
		s_info.dingque_pai = {3,3,3,3}
	end

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_pai_msg",
		{
		status_no=all_data.status_no,
		my_pai_list=my_pai_list,
		remain_card=_remain_card,
		})
end

function CMD.nor_mj_xzdd_dingque_permit(_cd)
	s_info.status="ding_que"
	s_info.countdown=DATA.robot_cd or _cd

	s_info.dingque_pai={
		-1,-1,-1,-1
	}

	local overtime_callback=function ()
					overtime_cb=nil
					auto_data=nil
					-- 随机定缺
					local my_pai_list=get_pai_list_by_map(my_pai_data)
					local que = nor_mj_base_lib.get_ding_que_color(my_pai_list)
					call_room_service("ding_que",que)
				end

	set_overtime_cb(overtime_callback)
	

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_permit_msg",
							{status_no=all_data.status_no,
							status="ding_que",
							countdown=_cd,
							cur_p = 0,
						})

end

function CMD.nor_mj_xzdd_huansanzhang_permit(_cd)
	s_info.status="huan_san_zhang"
	s_info.countdown=DATA.robot_cd or _cd

	local overtime_callback=function ()
					overtime_cb=nil
					auto_data=nil

					call_room_service("huan_san_zhang", {} , true)
				end

	set_overtime_cb(overtime_callback)

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_permit_msg",
							{status_no=all_data.status_no,
							status="huan_san_zhang",
							countdown=_cd,
						})

end

function CMD.nor_mj_xzdd_huan_pai_finish_msg()
	s_info.status="huan_san_zhang_finish"
	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_huan_pai_finish_msg",
							{status_no=all_data.status_no,
						})

end



function CMD.nor_mj_xzdd_huansanzhang_new(_old_huan_pai,_new_huan_pai , pai_map , is_time_out)
	overtime_cb=nil
	s_info.huan_san_zhang_old=_old_huan_pai
	s_info.huan_san_zhang_new = _new_huan_pai
	
	local pai_list = get_pai_list_by_map(pai_map)
	s_info.is_huan_pai = 1

	my_pai_data = pai_map

	---- 记牌器 修改为 新的
	s_info.jipaiqi=nor_mj_base_lib.get_init_jipaiqi()

	for pai,v in pairs(my_pai_data) do
		nor_mj_base_lib.jipaiqi_kick_pai(pai,s_info.jipaiqi,v)
	end

	--dump( my_pai_data, "--------------------- nor_mj_xzdd_huansanzhang_new 1" )
	--dump( s_info.jipaiqi, "--------------------- nor_mj_xzdd_huansanzhang_new 2" )

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_huansanzhang_msg",
							{status_no=all_data.status_no,
							pai_vec=_new_huan_pai,
							pai_list = pai_list,
							jipaiqi = s_info.jipaiqi,
							is_time_out = is_time_out == true and 1 or 0
						})
end

--- 打漂
function CMD.nor_mj_xzdd_dapiao_permit(_cd)
	s_info.status="da_piao"
	s_info.countdown=DATA.robot_cd or _cd

	local overtime_callback=function ()
					overtime_cb=nil
					auto_data=nil
					call_room_service("da_piao", 0 )
				end

	set_overtime_cb(overtime_callback)

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_permit_msg",
							{status_no=all_data.status_no,
							status="da_piao",
							countdown=_cd,
						})
end

function CMD.nor_mj_xzdd_da_piao_finish_msg()
	s_info.status="da_piao_finish"
	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_da_piao_finish_msg",
							{status_no=all_data.status_no,
						})
end

function CMD.nor_mj_xzdd_dapiao_msg(_seat_num , piaoNum)
	if _seat_num== s_info.seat_num then
		overtime_cb=nil 
	end
	s_info.da_piao_nums[_seat_num] = piaoNum
	--[[if s_info.seat_num == _seat_num then
		s_info.da_piao_num = piaoNum
	end--]]

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_da_piao_msg",
							{status_no=all_data.status_no,
							seat_num = _seat_num,
							piao_num = piaoNum,
						})

end


function CMD.nor_mj_xzdd_peng_gang_hu_permit(_pai,_pgh,_cd)
	s_info.status="peng_gang_hu"
	s_info.countdown=DATA.robot_cd or _cd
	s_info.is_hu=nil

	s_info.cur_p = s_info.seat_num
	s_info.cur_pgh_card = _pai
	s_info.cur_pgh_allow_opt = {
			peng=_pgh.peng and 1 or nil,
			gang=_pgh.gang and 1 or nil,
			hu=_pgh.hu and 1 or nil,
		}

	local overtime_callback=function ()
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
	set_overtime_cb(overtime_callback)

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_permit_msg",
	{
		status_no=all_data.status_no,
		status="peng_gang_hu",
		allow_opt=s_info.cur_pgh_allow_opt,
		countdown=_cd,
		pai=_pai,
		cur_p = s_info.seat_num,
	})

end


-- 可以 天胡 或者 出牌
function CMD.nor_mj_xzdd_start_permit(_cur_p,_is_hu,_cd)
	s_info.status="start"
	s_info.countdown =DATA.robot_cd or _cd
	s_info.cur_p = _cur_p
	s_info.is_hu=nil
	if _cur_p == s_info.seat_num then

		s_info.is_guo=nil

		s_info.is_hu = _is_hu

		local overtime_callback=function ()
						overtime_cb=nil
						auto_data=nil
						s_info.is_hu = nil

						if _is_hu then
							call_room_service("hu_pai")
						else
							auto_chupai()
						end
					end
		set_overtime_cb(overtime_callback)
	end


	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_permit_msg",
	{
		status_no=all_data.status_no,
		status="start",
		countdown=_cd,
		cur_p = _cur_p,
	})
	
end

--
function CMD.nor_mj_xzdd_chupai_permit(_cur_p,_cd)
	s_info.status="cp" -- 出牌状态
	s_info.countdown=DATA.robot_cd or _cd
	s_info.cur_p = _cur_p
	s_info.is_hu=nil
	if _cur_p == s_info.seat_num then

		s_info.is_guo=nil

		set_overtime_cb(auto_chupai)

	end

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_permit_msg",{
		status_no=all_data.status_no,
		status="cp",
		countdown=_cd,
		cur_p = _cur_p
	})
end

function CMD.nor_mj_xzdd_mopai_permit(_cur_p,_pai,_is_hu,_cd,_remain_card,_mopai_src)

	s_info.status="mo_pai"
	s_info.countdown=DATA.robot_cd or _cd
	s_info.cur_p = _cur_p
	s_info.cur_mopai=_pai

	s_info.remain_card = _remain_card
	s_info.player_remain_card[_cur_p]=s_info.player_remain_card[_cur_p]+1
	--print("/////////////////////////*****--->>>>>>>>>>>"..s_info.remain_card)
	s_info.is_hu=nil
	
	if _cur_p == s_info.seat_num then

		print(DATA.my_id,_cur_p,"摸牌：",_pai)
		
		s_info.is_guo=nil

		--记牌器**********
		nor_mj_base_lib.jipaiqi_kick_pai(_pai,s_info.jipaiqi,1)

		my_pai_data[_pai]=(my_pai_data[_pai] or 0) + 1
		s_info.is_hu = _is_hu

		local overtime_callback = function ()
				overtime_cb = nil
				auto_data=nil
				s_info.is_hu = nil
				if _is_hu then
					call_room_service("hu_pai")
				else
					auto_chupai()
				end
		end
		set_overtime_cb(overtime_callback)

	end

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_permit_msg",
	{
		status_no=all_data.status_no,
		status="mo_pai",
		countdown=_cd,
		pai=_pai,
		cur_p = _cur_p,
		mopai_src=_mopai_src,
	})
end

function CMD.nor_mj_xzdd_my_dingque_msg(_seat_num,_flower)
	overtime_cb=nil
	-- _flower  s_info.dingque_pai[_seat_num]=0 是已定缺
	s_info.dingque_pai[_seat_num]=0
end
--定缺完成
function CMD.nor_mj_xzdd_ding_que_msg(_ding_que_datas)

	s_info.dingque_pai=_ding_que_datas

	--处理：每个玩家的 定缺 
	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_dingque_result_msg",
		{
		status_no=all_data.status_no,
		result=s_info.dingque_pai
		}
		)

	-- dump(_ding_que_datas,DATA.my_id.."所有人定缺完成了:")

end


--玩家出牌
function CMD.nor_mj_xzdd_chu_pai_msg(_act)

	s_info.action=_act

	s_info.cur_mopai = nil
	s_info.cur_chupai.seat_num=_act.p
	s_info.cur_chupai.pai=_act.pai

	s_info.player_remain_card[_act.p]=s_info.player_remain_card[_act.p]-1

	local len = #s_info.chu_pai[_act.p].pai_list+1
	s_info.chu_pai[_act.p].pai_list[len]=_act.pai

	if _act.p == s_info.seat_num then
        overtime_cb=nil
		my_pai_data[_act.pai] = my_pai_data[_act.pai] - 1
	else
		--记牌器**********
		nor_mj_base_lib.jipaiqi_kick_pai(_act.pai,s_info.jipaiqi,1)
	end

	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_action_msg",
		{
		status_no=all_data.status_no,
		action=s_info.action
		})


end

--碰牌完成
function CMD.nor_mj_xzdd_peng_msg(act)

	if act.p == s_info.seat_num then
        overtime_cb=nil
        s_info.cur_pgh_allow_opt = nil
	end

	s_info.action=act

	player_pg_pai(act.p,act.pai,"peng")

	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_action_msg",
		{
		status_no=all_data.status_no,
		action=s_info.action
		})
end

--杠牌完成
function CMD.nor_mj_xzdd_gang_msg(act)

	if act.p == s_info.seat_num then
        overtime_cb=nil
        s_info.cur_pgh_allow_opt = nil
	end

	s_info.action=act

	player_pg_pai(act.p,act.pai,act.type)


	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_action_msg",
		{
		status_no=all_data.status_no,
		action=s_info.action,
		})


end

--- 转雨
function CMD.nor_mj_xzdd_zhuan_yu_msg(act)

	s_info.zhuan_yu_data[#s_info.zhuan_yu_data + 1] = { gang_seat = tonumber(act.other) , hu_seat = act.p , pai = act.pai }

	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_action_msg",
		{
		status_no=all_data.status_no,
		action=act,
		})
end


-- 游戏破产
function CMD.nor_mj_xzdd_game_bankrupt_msg(_game_bankrupt)

	-- s_info.hu_data[#s_info.hu_data+1]=_action.hu_data

	s_info.game_bankrupt = _game_bankrupt

	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_game_bankrupt_msg",
		{
		status_no=all_data.status_no,
		game_bankrupt=_game_bankrupt,
		})

	for s,d in ipairs(_game_bankrupt) do

		-- 自己游戏破产 可以离开游戏了
		if s==s_info.seat_num then
			if all_data.m_PROTECT and all_data.m_PROTECT.set_game_status then
				all_data.m_PROTECT.set_game_status(true)
			end
		end

	end

end


--胡牌完成
-- 参数 _type ： "zimo" 自摸， "pao" 别人点炮， "qghu" 抢杠胡（抢别人的弯杠）
function CMD.nor_mj_xzdd_hu_msg(_action,_score)

	s_info.hu_data[#s_info.hu_data+1]=_action.hu_data

	s_info.action = _action

	local _seat_num = _action.p
	local _pai = _action.hu_data.pai
	local _pao_seat = _action.hu_data.dianpao_p
	local _type = _action.hu_data.hu_type

	if "pao" == _type then
		
		remove_last_chupai()
		if _seat_num==s_info.seat_num then
			my_pai_data[_pai] = (my_pai_data[_pai] or 0) + 1
		end

	elseif "qghu" == _type then
		--把这个杠的排变成碰
		for i,pg in pairs(s_info.pg_pai[_pao_seat].pg_pai_list) do
			if pg.pai == _pai then
				s_info.pg_pai[_pao_seat].pg_pai_list[i].type = "peng"
			end
		end
		if _seat_num==s_info.seat_num then
			my_pai_data[_pai] = (my_pai_data[_pai] or 0) + 1
		end
	elseif "zimo"==_type then
		--- add by wss , 自摸的时候胡去掉摸牌数据
		s_info.cur_mopai = nil
		--记牌器**********
		if _seat_num~=s_info.seat_num then 
			nor_mj_base_lib.jipaiqi_kick_pai(_pai,s_info.jipaiqi,1)
		end
	end


	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_action_msg",
		{
		status_no=all_data.status_no,
		action=s_info.action,
		})

	if _seat_num==s_info.seat_num then
        overtime_cb=nil
        s_info.cur_pgh_allow_opt = nil
        s_info.is_hu = nil
	end

	-- 自己胡了 可以离开游戏了
	if _seat_num==s_info.seat_num then
		if all_data.m_PROTECT and all_data.m_PROTECT.set_game_status then
			all_data.m_PROTECT.set_game_status(true)
		end
	end

end

-- by lyx 改变钱
function CMD.nor_mj_xzdd_modify_score(_score)

	if all_data.m_PROTECT and all_data.m_PROTECT.modify_score then
		return all_data.m_PROTECT.modify_score(_score)
	else
		return _score
	end
end



---- 获得赢封顶的分数
function CMD.nor_mj_get_yingfengding_score(_score)
	if all_data.m_PROTECT and all_data.m_PROTECT.get_fengding_score then
		---
		local now_score = all_data.m_PROTECT.get_fengding_score()

		return math.max(now_score , _score)
	else
		return _score
	end
end

---- 获得当前的分数
function CMD.nor_mj_get_now_score()
	if all_data.m_PROTECT and all_data.m_PROTECT.get_fengding_score then
		---
		return all_data.m_PROTECT.get_fengding_score()
	else
		return 0
	end
end

-- by lyx 玩家退出房间
function CMD.nor_mj_xzdd_player_exit_msg(_seat_num)
	
	if s_info.seat_num ==_seat_num and DATA.chat_room_id then
		skynet.send(DATA.service_config.chat_service,"lua","exit_room", DATA.chat_room_id,DATA.my_id)
		DATA.chat_room_id = nil
	end

	s_info.ready[_seat_num] = 0
	if all_data.m_PROTECT and all_data.m_PROTECT.player_exit_msg then 
		all_data.m_PROTECT.player_exit_msg(_seat_num)
	end

end

-- by lyx 游戏开始前通知解散房间（无结算）
function CMD.nor_mj_xzdd_gamecancel_msg()

	if all_data.m_PROTECT and all_data.m_PROTECT.gamecancel_msg then 
		all_data.m_PROTECT.gamecancel_msg()
	end

end

-- by lyx 分数改变
function CMD.nor_mj_xzdd_score_change_msg(_data,_type)

	local send_data={}
	if _data then
		for p,d in pairs(_data) do
			send_data[#send_data+1]={cur_p=p,score=d.score,lose_surplus=d.lose_surplus}
		end
	end
	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_score_change_msg",{status_no=all_data.status_no,data=send_data,type=_type})
	
	s_info.score_change_list[1+#s_info.score_change_list]={data=send_data,type=_type}

	if all_data.m_PROTECT and all_data.m_PROTECT.score_change_msg then 
		all_data.m_PROTECT.score_change_msg(_data)
	end

end

function CMD.nor_mj_xzdd_settlement_msg(_settle_data,is_over,_log_id )
	
	s_info.status = "settlement"				
	s_info.settlement_info = {settlement_items={}}

	s_info.settlement_info.yingfengding = _settle_data.yingfengding

	local zm_data={0,0,0,0}
	local jp_data={0,0,0,0}

	local ag_data={0,0,0,0}
	local mg_data={0,0,0,0}

	local lose_surplus = {}

	local settle_data = {scores={}}
	for i,data in ipairs(_settle_data) do
		s_info.settlement_info.settlement_items[i]=data
		settle_data.scores[data.seat_num]=data.settle_data.score
		lose_surplus[data.seat_num]=data.settle_data.lose_surplus

		if data.settle_data.hu_type=="zimo" then
			zm_data[data.seat_num]=1
		end

		if data.settle_data.hu_type=="pao" then
			jp_data[data.seat_num]=1
		end

		for pi,pgd in ipairs(data.pg_pai) do
			if pgd.pg_type == "ag" then
				ag_data[data.seat_num] = ag_data[data.seat_num] + 1
			elseif pgd.pg_type == "zg" 
					or pgd.pg_type == "wg" then
				mg_data[data.seat_num] = mg_data[data.seat_num] + 1
			end
		end

	end


	settle_data.mj_xzdd_statistics={
		zi_mo_count = zm_data,
		jie_pao_count = jp_data,
		dian_pao_count = _settle_data.dian_pao_count,
		an_gang_count = ag_data,
		ming_gang_count = mg_data,
		cha_da_jiao_count = _settle_data.cha_da_jiao_count,
	}

	if not is_over then
		s_info.ready={0,0,0,0}
		s_info.next_race=s_info.cur_race + 1
	end

	s_info.is_over = is_over and 1 or 0
	
	add_status_no()
	PUBLIC.request_client("nor_mj_xzdd_settlement_msg",
		{
		status_no=all_data.status_no,
		settlement_info = s_info.settlement_info,
		game_players_info = s_info.game_players_info,
		is_over = s_info.is_over,
		score_change_list = s_info.score_change_list,
		})

	--tj s>0 win
	local t = 0
	if settle_data.scores[s_info.seat_num]>0 then
		t = 1
	end
	skynet.send(DATA.service_config.data_service,"lua","update_statistics_player_mj_win_data",DATA.my_id,t)

	if all_data.m_PROTECT and all_data.m_PROTECT.game_settlement_msg then
		all_data.m_PROTECT.game_settlement_msg(settle_data,is_over,lose_surplus,_log_id)
	end 
end


function CMD.nor_mj_xzdd_gameover_msg(_data)
	---游戏结束
	DATA.one_game_begin_time=nil

	s_info.status = "gameover"

	--保存一次我的牌的数据
	if my_pai_data then
		local my_pai_list=get_pai_list_by_map(my_pai_data)
		s_info.my_pai_list=my_pai_list
	end

	if all_data.m_PROTECT and all_data.m_PROTECT.game_gameover_msg then
		all_data.m_PROTECT.game_gameover_msg(_data)
	end

	if DATA.chat_room_id then
		skynet.send(DATA.service_config.chat_service,"lua","exit_room", DATA.chat_room_id,DATA.my_id)
		DATA.chat_room_id = nil
	end


end


function CMD.nor_mj_xzdd_next_game_msg(_data)

	add_status_no()

	PUBLIC.request_client("nor_mj_xzdd_next_game_msg",
							{
							status_no=all_data.status_no,
							cur_race=_data,
							})

	if all_data.m_PROTECT and all_data.m_PROTECT.game_next_game_msg then
		all_data.m_PROTECT.game_next_game_msg(_data)
	end

end

function PROTECT.get_status_info()
	if my_pai_data then
		local my_pai_list=get_pai_list_by_map(my_pai_data)
		s_info.my_pai_list=my_pai_list
	end
	return s_info
end

-- 胡牌了 退出游戏房间
function PROTECT.quit_room()
	
	if s_info and s_info.room_id and s_info.t_num then

		return call_room_service("quit_room")

	end

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
	if _config then
		auto_count_cfg=_config.auto_count_cfg or auto_count_cfg
		if not basefunc.chk_player_is_real(DATA.my_id) then
			auto_count_cfg=auto_count_cfg+1
		end
		auto_wait_cp_time_cfg=_config.auto_wait_cp_time_cfg or auto_wait_cp_time_cfg
		overtime_auto_action_cfg=_config.overtime_auto_action_cfg or overtime_auto_action_cfg
	end
end

function PROTECT.init_base_info(_config)

	if _config then
		s_info.room_id=_config.room_id
		s_info.t_num=_config.t_num

		--底分
		s_info.init_stake=_config.init_stake or 1
		s_info.init_rate=_config.init_rate or 1
		s_info.race_count=_config.race_count or 1

		--总玩家数
		s_info.player_count=_config.player_count or 4
	end
	
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
	my_pai_data=nil
	my_pg_map=nil
	auto_data=nil
	overtime_cb=nil
end

function PROTECT.init(_all_data)
	PROTECT.free()
	
	all_data=_all_data

	all_data.game_data={}

	s_info=all_data.game_data

	init_game()

	PROTECT.init_agent_cfg(all_data.config.agent_cfg)

	PROTECT.init_base_info(all_data.base_info)

	update_timer=skynet.timer(dt,update)

end





-- --胡牌完成
-- -- 参数 _settle_data ：参见协议 .mjfg_settlement_info
-- function CMD.mjfg_gameover_msg(_settle_data)

-- 	-- print("========= game over ============\n",basefunc.tostring(_settle_data))
	
-- 	s_info.status = "gameover"

-- 	s_info.countdown=free_game_time
-- 	overtime_cb=function ()
-- 							print("CMD.mjfg_gameover_msg free_game :",DATA.my_id)
-- 							PUBLIC.free_game_coin(game_name)
-- 							free_game()
-- 						end	
						
-- 	settlement_info = {settlement_items={}}

-- 	local my_order = 0
-- 	for i,data in ipairs(_settle_data) do
-- 		settlement_info.settlement_items[i]=data
-- 		if data.seat_num == room_info.seat_num then
-- 			my_order = i
-- 		end
-- 	end

-- 	-- print("========= settlement_info ============\n",basefunc.tostring(settlement_info,10))
	
-- 	settlement_info.room_rent=game_server_id_map[cur_play_game_info.id].room_rent
	
-- 	add_status_no()

-- 	get_all_info_s2c()

-- 	PUBLIC.request_client("mjfg_gameover_msg",
-- 		{
-- 		status_no=status_no,
-- 		settlement_info = settlement_info,
-- 		})

-- 	--没胡牌则统计 --胡牌的人在胡的时候就统计了
-- 	if _settle_data[my_order].settle_data.settle_type~="hu" then
-- 		if _settle_data[my_order].settle_data.score < 0 then
-- 			PROTECT.add_statistics_player_freestyle_mjxz(false,true)
-- 		else
-- 			PROTECT.add_statistics_player_freestyle_mjxz(true,false)
-- 		end
-- 	end
	
-- end

-- --玩家托管消息
-- function CMD.mjfg_auto_msg(_p,_type)
-- 	s_info.auto_status[_p]=_type
-- 	PUBLIC.request_client("mjfg_auto_msg",{p=_p,auto_status=_type})
-- 	print("托管",_p,_type)
-- end
-- --当前比赛重新开始
-- function CMD.mjfg_start_again_msg(_init_rate,_init_stake,_seat_num)
-- 	new_game(_init_rate,_init_stake,_seat_num)
-- 	add_status_no()
-- 	--通知客户端 新的一局
-- 	PUBLIC.request_client("mjfg_start_again_msg",{status_no=status_no,status=s_info.status})	
-- end


-- --晋级决赛 - 调整分数
-- function CMD.majiang_grades_change_msg(_grades)
	
-- 	for i,d in ipairs(_grades) do
-- 		p_info.p_info[d.cur_p].jing_bi = p_info.p_info[d.cur_p].jing_bi + d.grades
-- 	end

-- 	PUBLIC.request_client("mjfg_grades_change_msg",{status_no=status_no,data=_grades})
-- end









return PROTECT



