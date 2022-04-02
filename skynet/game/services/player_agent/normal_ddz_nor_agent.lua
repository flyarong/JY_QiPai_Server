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

local nor_ddz_base_lib = require "nor_ddz_base_lib"
local nor_ddz_algorithm_lib = require "nor_ddz_algorithm_lib"
local nor_ddz_algorithm


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

local my_game_name="nor_ddz_nor"
local kaiguan
--上层  model的数据
local all_data

local jdz_type

--配置
--超时出牌计数N次就自动托管cfg
local auto_count_cfg=0
--托管后自动出牌的时间cfg
local auto_wait_cp_time_cfg = 2
--超时后是否需要自动操作 1 需要 0 不需要
local overtime_auto_action_cfg=1


--动作标记
local act_flag=false
--超时出牌计数N次就自动托管
local overtime_count=0
--状态信息
local s_info
--我的牌数据
local my_pai_data
local settlement_info

--托管数据
local auto_data
--超时回调
local overtime_cb

local update_timer
--update 间隔
local dt=0.5
--返回优化，避免每次返回都创建表
local return_msg={result=0}

--客户端操作缓冲时间
local client_act_buffer_time=2
--托管后自动出牌的时间
local auto_wait_cp_time = 2
local lack_of_ability_for_cp_1=10
local lack_of_ability_for_cp_2=3


local function add_status_no()
	all_data.status_no=all_data.status_no+1
end
local function set_overtime_cb(func)
	if overtime_auto_action_cfg==1 then
		overtime_cb=func
		if s_info and  s_info.auto_status and s_info.auto_status[s_info.seat_num]==1 then
			auto_data={countdown=auto_wait_cp_time}
		end
	end
end

local function call_room_service(_func_name,...)

	return nodefunc.call(s_info.room_id,_func_name,s_info.t_num,s_info.seat_num,...)

end

local function send_room_service(_func_name,...)

	nodefunc.send(s_info.room_id,_func_name,s_info.t_num,s_info.seat_num,...)

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
local function set_auto()
	if s_info.auto_status[s_info.seat_num]==0 then 
		s_info.auto_status[s_info.seat_num]=1
		if basefunc.chk_player_is_real(DATA.my_id) then
			send_room_service("auto",1)
		end
		if s_info.status=="cp" and s_info.cur_p==s_info.seat_num then
			auto_data={countdown=auto_wait_cp_time}
		end
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
--自动出牌
local function auto_cp(_is_must,_is_yaobuqi)
	if not _is_yaobuqi then
		overtime_count=overtime_count+1
	end
	if overtime_count>=1 and  s_info.auto_status[s_info.seat_num]==0 then 
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
		local cp=nor_ddz_algorithm:cp_hint(nil,nil,my_pai_data.pai,s_info.laizi_num,s_info.laizi)
		print("顺序走") 
		dump(cp)
		call_room_service("chupai",cp.type,cp.pai,cp.cp_list,cp.merge_cp_list,cp.lazi_num)
	else 
		--已经是自动的情况下
		if s_info.auto_status[s_info.seat_num]==1 and not DATA.auto_cp_must_guo  then
			--接牌
			local data=s_info.act_list[nor_ddz_base_lib.get_real_chupai_pos_by_act(s_info.act_list)]
			local cp=nor_ddz_algorithm:cp_hint(data.type,data.pai,my_pai_data.pai,s_info.laizi_num,s_info.laizi)
			print("接牌") 
			-- dump(cp)
			call_room_service("chupai",cp.type,cp.pai,cp.cp_list,cp.merge_cp_list,cp.lazi_num)
		else
			print("过牌")
			--直接过牌
			call_room_service("chupai",0)
		end
	end
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
end

local function new_game()
	--一把游戏开始的时间
	DATA.one_game_begin_time=os.time()

	s_info.countdown=0
	s_info.cur_p=0
	--我的牌列表
	s_info.my_pai_list=nil
	--每个人剩余的牌
	s_info.remain_pai_amount=nil
	--记牌器
	s_info.jipaiqi=nil
	--我的倍数
	s_info.my_rate=all_data.config.init_rate or 1
	--动作序列--保留最近两次的即可
	s_info.act_list={}
	--玩家的托管状态
	s_info.auto_status={0,0,0}
	auto_data=nil


	s_info.dizhu=0
	s_info.dz_pai=nil
	s_info.settlement_info=nil

	--癞子牌的牌类型
	s_info.laizi=0
	--我的癞子牌数量
	s_info.laizi_num=0

	--加倍
	s_info.jiabei=0	

	if my_game_name=="nor_ddz_er" then
		--让牌数量
		s_info.rangpai_num=0
		s_info.er_qiang_dizhu_count=0
	end

	if s_info.jdz_type=="mld" then
		s_info.is_men_zhua=nil
		s_info.dao_la_data={-1,-1,-1}
		
		--0-nil  1-不操作  2-是操作
		s_info.men_data={0,0,0}
		s_info.zhua_data={0,0,0}

	end

	my_pai_data=nil
end

--初始化基础函数
local function init_base_func()

	if all_data.match_info and all_data.match_info.match_model == "xsyd" then
		CMD.nor_ddz_nor_jdz_permit = CMD.nor_ddz_nor_jdz_permit_nor
		CMD.nor_ddz_nor_cp_permit = CMD.nor_ddz_nor_cp_permit_nor
	else
		CMD.nor_ddz_nor_jdz_permit = CMD.nor_ddz_nor_jdz_permit_nor
		CMD.nor_ddz_nor_cp_permit = CMD.nor_ddz_nor_cp_permit_nor
	end
	
end

local function init_game()
	s_info.status="wait_join"
	s_info.cur_race=1
	s_info.next_race=1
	init_base_func()
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


function REQUEST.nor_ddz_nor_ready(self)
	return PROTECT.ready(self)
end

function REQUEST.nor_ddz_nor_jiabei(self)
	if act_flag 
		or not s_info 
		or s_info.status~="jiabei"
		or s_info.jiabei==1 then
			return_msg.result=1002
			return return_msg
	end
	if not self.rate 
		or type(self.rate)~="number" 
		or (self.rate~=0 and self.rate~=2)then 
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

function REQUEST.nor_ddz_nor_jiao_dizhu(self)
	if act_flag or not s_info or s_info.status~="jdz" or s_info.cur_p~=s_info.seat_num then
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

function REQUEST.nor_ddz_nor_chupai(self)
	dump(self,"xxxxxxxxxxxxxxxxxxxxx nor_ddz_nor_chupai " .. tostring(DATA.my_id) .. ":" )
	if act_flag or not s_info or s_info.status~="cp" or s_info.cur_p~=s_info.seat_num then
		return_msg.result=1002
		return return_msg
	end
	if not self.type or type(self.type)~="number"then 
		print("REQUEST.nor_ddz_nor_chupai 1001.1 error:",type(self.type))
		return_msg.result=1001
		return return_msg
	end
	cancel_auto()
	if not kaiguan[self.type] then
		--最后三张牌也可以出
		if not (self.type==3 and s_info.remain_pai_amount[s_info.seat_num]==3) then
			print("REQUEST.nor_ddz_nor_chupai 1003.2 error:",self.type,s_info.remain_pai_amount[s_info.seat_num])
			return_msg.result=1003
			return return_msg
		end
	end
	
	local lazi_num=0

	-- dump(self.cp_list)
	--检查是否有牌
	if self.type~=0 then
		if type(self.cp_list)~="table" then
			print("REQUEST.nor_ddz_nor_chupai 1001.3 error:",type(self.cp_list))
			return_msg.result=1001
			return return_msg 
		end
		if type(self.cp_list.nor)=="table" then
			local _hash={}
			for _,_id in ipairs(self.cp_list.nor) do
				--nor里面不能有癞子
				if not my_pai_data.pai[_id] or _hash[_id] or s_info.laizi==nor_ddz_base_lib.pai_map[_id] then 
					print("REQUEST.nor_ddz_nor_chupai 1001.4 error.")
					return_msg.result=1001
					return return_msg  
				end
				_hash[_id]=true
			end 
		end
		if type(self.cp_list.lz)=="table" then

			if my_game_name=="nor_ddz_nor" then
				print("REQUEST.nor_ddz_nor_chupai 1001.5 error.")
				return_msg.result=1001
				return return_msg
			end
			
			lazi_num=#self.cp_list.lz
			if s_info.laizi_num<lazi_num then
				print("REQUEST.nor_ddz_nor_chupai 1001.6 error:",s_info.laizi_num,lazi_num)
				return_msg.result=1001
				return return_msg  
			end
		end
	end

	local cp_list=nor_ddz_base_lib.merge_nor_and_lz(self.cp_list)
	if not cp_list then
		print("REQUEST.nor_ddz_nor_chupai 1001.7 error:",basefunc.tostring(self.cp_list))
		return_msg.result=1001
		return return_msg 
	end
	-- dump(cp_list)
	act_flag=true
	local _cp_type=nor_ddz_algorithm:get_pai_type(cp_list,lazi_num)
	if not _cp_type or _cp_type.type~=self.type then 
		print("REQUEST.nor_ddz_nor_chupai 1003.8 error:",basefunc.tostring(_cp_type),self.type)
		return_msg.result=1003
		return return_msg 
	end

	local _result=call_room_service("chupai",self.type,_cp_type.pai,self.cp_list,cp_list,lazi_num)
	act_flag=false
	if _result~="CALL_FAIL" then

		return_msg.result=_result 
		return return_msg 
	else
		print("REQUEST.nor_ddz_nor_chupai 1000.9 error:",basefunc.tostring(_result))
		return_msg.result=1000
		return return_msg	
	end
end

function REQUEST.nor_ddz_nor_auto(self)
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

function REQUEST.nor_ddz_er_q_dizhu(self)
	if act_flag or not s_info or s_info.status~="q_dizhu" or s_info.cur_p~=s_info.seat_num then
		return_msg.result=1002	
		return return_msg
	end
	if not self.rate or type(self.rate)~="number" or self.rate<0 or self.rate>1 then 
		return_msg.result=1001
		return return_msg
	end
	act_flag=true
	local _result=call_room_service("er_qiang_dizhu",self.rate)
	act_flag=false
	if _result~="CALL_FAIL" then

		return_msg.result=_result
		return return_msg 
	else
		return_msg.result=1000
		return return_msg	
	end
end




------------------------------------------------------------------------------------------------
-----------------------------------------MLD-------------------------------------------------
------------------------------------------------------------------------------------------------

function REQUEST.nor_ddz_mld_men_zhua(self)
	if act_flag 
		or not s_info 
		or s_info.status~="jdz"
		or s_info.cur_p~=s_info.seat_num then
			return_msg.result=1002
			return return_msg
	end

	if self.opt ~= 0 and self.opt ~= 1 then
		return_msg.result=1001
		return return_msg
	end

	-- 必须闷
	if s_info.is_must_mld_opt and self.opt ~= 1 then
		return_msg.result=1002
		return return_msg
	end

	print("tydfg_men_//**--")
	act_flag=true
	local _result=call_room_service("men",self.opt)
	act_flag=false
	if _result~="CALL_FAIL" then

		return_msg.result=_result 
		return return_msg 
	else
		return_msg.result=1000
		return return_msg	
	end
end


function REQUEST.nor_ddz_mld_zhua_pai(self)
	if act_flag 
		or not s_info 
		or s_info.status~="jdz"
		or s_info.cur_p~=s_info.seat_num then
			return_msg.result=1002
			return return_msg
	end
	if not self.opt 
		or type(self.opt)~="number" 
		or (self.opt~=0 and self.opt~=1)then 
			return_msg.result=1001
			return return_msg
	end

	if self.opt==0 and s_info.is_must_mld_opt then
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

function REQUEST.nor_ddz_mld_dao_la(self)
	if act_flag 
		or not s_info 
		or s_info.status~="jiabei" then
			print("nor_ddz_mld_dao_la 1002.1 error:",DATA.my_id,act_flag,s_info,s_info and s_info.status)
			return_msg.result=1002
			return return_msg
	end

	if not self.opt 
		or type(self.opt)~="number" 
		or (self.opt~=0 and self.opt~=1)then 
			return_msg.result=1001
			return return_msg
	end

	if (s_info.cur_p==4 and s_info.dizhu==s_info.seat_num)
		or (s_info.cur_p<4 and s_info.dizhu~=s_info.seat_num) then
		print("nor_ddz_mld_dao_la 1002.2 还没有轮到你进行操作 加倍操作".. DATA.my_id)
		return_msg.result=1002
		return return_msg
	end


	if s_info.is_must_mld_opt and self.opt==0 then
		print("nor_ddz_mld_dao_la 1002.3 error:",DATA.my_id,s_info.is_must_mld_opt,self.opt)
		return_msg.result=1002
		return return_msg
	end


	act_flag=true
	
	local _result=call_room_service("dao_la",self.opt)
	
	act_flag=false
	if _result~="CALL_FAIL" then
		if _result==0 then
			s_info.is_must_mld_opt=nil
		end
		
		return_msg.result=_result 
		return return_msg 
	else
		return_msg.result=1000
		return return_msg	
	end

end

------------------------------------------------------------------------------------------------
-----------------------------------------MLD-------------------------------------------------
------------------------------------------------------------------------------------------------



function CMD.nor_ddz_nor_join_msg(_info,_my_join_return)

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

		s_info.jdz_type=_my_join_return.jdz_type

		if all_data.m_PROTECT and all_data.m_PROTECT.my_join_return then
			all_data.m_PROTECT.my_join_return(_my_join_return)
		end
		if _my_join_return.chat_room_id then
			DATA.chat_room_id=_my_join_return.chat_room_id
			skynet.call(DATA.service_config.chat_service,"lua","join_room", DATA.chat_room_id,DATA.my_id,PUBLIC.get_gate_link())
		end

	end
end

function CMD.nor_ddz_nor_ready_msg(_seat_num)
	s_info.ready[_seat_num]=1
	
	if _seat_num == s_info.seat_num then
		new_game()
		s_info.status="ready"
		s_info.cur_race=s_info.next_race
	end

	add_status_no()
	PUBLIC.request_client("nor_ddz_nor_ready_msg",
		{
		status_no = all_data.status_no,
		seat_num = _seat_num,
		cur_race = s_info.cur_race,
		})
end

function CMD.nor_ddz_nor_notify_tuoguan_pai(_play_data,_profit_wave_status)
	PUBLIC.request_client("nor_ddz_nor_notify_tuoguan_pai",_play_data,_profit_wave_status)	
end

function CMD.nor_ddz_nor_begin_msg(_cur_race,_again , re_fapai_num)
	add_status_no()
	s_info.status="begin"
	if _again then
		new_game()
	end
	s_info.ready=nil
	PUBLIC.request_client("nor_ddz_nor_begin_msg",
												{
												status_no=all_data.status_no,
												cur_race=s_info.cur_race,
												})

	if all_data.m_PROTECT and all_data.m_PROTECT.begin_msg then
		all_data.m_PROTECT.begin_msg(_cur_race,_again,re_fapai_num)
	end	
end

function CMD.nor_ddz_nor_pai_msg(_my_pai_data,_fp_time)
	s_info.status="fp"
	s_info.countdown=_fp_time
	if my_game_name=="nor_ddz_er" then
		s_info.remain_pai_amount={17,17,9}
	else
		s_info.remain_pai_amount={17,17,17}
	end

	s_info.my_pai_list=nil

	if _my_pai_data then
		s_info.my_pai_list=nor_ddz_base_lib.get_pai_list_by_map(_my_pai_data.pai)
		my_pai_data=_my_pai_data
		my_pai_data.hash=nor_ddz_base_lib.get_pai_typeHash(_my_pai_data.pai)
	end
	
	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_ddz_nor_pai_msg",{status_no=all_data.status_no,my_pai_list=s_info.my_pai_list,
		remain_pai_amount=s_info.remain_pai_amount,round=s_info.round,cur_race=s_info.cur_race})
end

--叫地主权限
function CMD.nor_ddz_nor_jdz_permit_nor(_countdown,_cur_p)
	s_info.status="jdz"
	s_info.cur_p=_cur_p
	s_info.countdown=_countdown
	if s_info.seat_num==_cur_p then
		
		local _overtime_cb=function ()

						overtime_cb=nil

						call_room_service("jiao_dizhu",0)
					end
		set_overtime_cb(_overtime_cb)

		if s_info.auto_status[s_info.seat_num]==1 then
			auto_data={countdown=auto_wait_cp_time}
		end

	end
	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_ddz_nor_permit_msg",{status_no=all_data.status_no,status=s_info.status,countdown=_countdown,cur_p=_cur_p})
end


--叫地主消息
function CMD.nor_ddz_nor_jdz_msg(_act)

	if _act.p==s_info.seat_num then
		overtime_cb=nil
	end

	add_act(_act)
	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_ddz_nor_action_msg",{status_no=all_data.status_no,action=_act})
end

--二人斗地主抢地主权限
function CMD.nor_ddz_er_qdz_permit(_countdown,_cur_p)
	s_info.status="q_dizhu"
	s_info.cur_p=_cur_p
	s_info.countdown=_countdown
	if s_info.seat_num==_cur_p then

		local _overtime_cb=function ()

						overtime_cb=nil
						call_room_service("er_qiang_dizhu",0)
						
					end
		set_overtime_cb(_overtime_cb)

	end
	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_ddz_nor_permit_msg",{status_no=all_data.status_no,status=s_info.status,countdown=_countdown,cur_p=_cur_p})
end
--二人斗地主抢地主消息
function CMD.nor_ddz_er_qdz_msg(_act)

	if _act.p==s_info.seat_num then
		overtime_cb=nil
	end
	if _act.rate==1 then
		s_info.er_qiang_dizhu_count=s_info.er_qiang_dizhu_count+1
	end

	add_act(_act)
	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_ddz_nor_action_msg",{status_no=all_data.status_no,action=_act})
end


------------------------------------------------------------------------------------------------
-----------------------------------------MLD-------------------------------------------------
------------------------------------------------------------------------------------------------


--闷消息
function CMD.nor_ddz_mld_men_msg(_act)

    if _act.p==s_info.seat_num then
		overtime_cb=nil
		s_info.men_data[s_info.seat_num]=2
		s_info.is_must_mld_opt = nil
    end

	add_act(_act)
	add_status_no()

	s_info.my_rate=_act.rate
	
	s_info.men_data[_act.p]=2

	PUBLIC.request_client("nor_ddz_nor_action_msg",{status_no=all_data.status_no,action=_act})
end

--kan消息
function CMD.nor_ddz_mld_kan_msg(_act)

    if _act.p==s_info.seat_num then
        overtime_cb=nil
        s_info.men_data[s_info.seat_num]=1
    end

	--看不计入操作队列
	-- add_act(_act)
	add_status_no()
	s_info.men_data[_act.p]=1
	PUBLIC.request_client("nor_ddz_nor_action_msg",{status_no=all_data.status_no,action=_act})
end

--看我自己的手牌消息
function CMD.nor_ddz_mld_kan_my_pai_msg(_pai)

	s_info.my_pai_list=nor_ddz_base_lib.get_pai_list_by_map(_pai)
	my_pai_data={pai=_pai}
	my_pai_data.hash=nor_ddz_base_lib.get_pai_typeHash(_pai)

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_ddz_mld_kan_my_pai_msg",{status_no=all_data.status_no,my_pai_list=s_info.my_pai_list})
end



function CMD.nor_ddz_mld_jdz_permit(_countdown,_cur_p,_is_must_men)
	s_info.status="jdz"
	s_info.countdown=DATA.robot_cd or _countdown
	s_info.cur_p=_cur_p

	local overtime_cb
	if s_info.seat_num==_cur_p then

		if s_info.men_data[s_info.seat_num]==0 then
			overtime_cb=function ()
				overtime_cb=nil
				s_info.men_data[s_info.seat_num]=1
				s_info.is_must_mld_opt = nil
				call_room_service("men",_is_must_men and 1 or 0)
			end
			
			s_info.is_must_mld_opt = _is_must_men and 1 or nil

		else
			local zhua=0
			if nor_ddz_base_lib.is_must_zhua(my_pai_data.hash) then
				zhua=1
				s_info.is_must_mld_opt=1
			end
			overtime_cb=function ()
				overtime_cb=nil
				s_info.is_must_mld_opt=nil
				s_info.zhua_data[s_info.seat_num]=zhua+1
				call_room_service("zhua_pai",zhua)
			end
		end

		set_overtime_cb(overtime_cb)

	end

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_ddz_nor_permit_msg",
				{
					status_no=all_data.status_no,
					status=s_info.status,
					countdown=_countdown,
					cur_p=_cur_p,
					other=s_info.is_must_mld_opt,
				})
end

function CMD.nor_ddz_mld_jiabei_permit(_countdown,_cur_p)
	s_info.status="jiabei"
	s_info.countdown=DATA.robot_cd or _countdown
	s_info.cur_p=_cur_p

	local is_must_dao = nil

	if s_info.seat_num==_cur_p or (_cur_p==4 or s_info.dizhu~=s_info.seat_num ) then
		
		local overtime_cb

		if s_info.seat_num==_cur_p then
			--la
			overtime_cb=function ()
				overtime_cb=nil
				call_room_service("dao_la",0)
			end
		else

			--dao
			local jiabei=0

			--我闷牌放弃则不能倒
			if s_info.men_data[s_info.seat_num]==1 then
				jiabei=0
				s_info.countdown=1
				is_must_dao = 0
			end

			overtime_cb=function ()
				overtime_cb=nil
				s_info.is_must_mld_opt=nil
				call_room_service("dao_la",jiabei)
			end
			
		end

		set_overtime_cb(overtime_cb)

	end

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_ddz_nor_permit_msg",{
			status_no=all_data.status_no,
			status=s_info.status,
			countdown=_countdown,
			cur_p=_cur_p,
			other=is_must_dao,
		})
end



--zp消息
function CMD.nor_ddz_mld_zp_msg(_act)

    if _act.p==s_info.seat_num then
        overtime_cb=nil
        s_info.is_must_mld_opt=nil
    end

	s_info.my_rate=_act.rate
	s_info.zhua_data[_act.p]=_act.type==nor_ddz_base_lib.other_type.mld_zhua and 2 or 1
	add_act(_act)
	add_status_no()
	PUBLIC.request_client("nor_ddz_nor_action_msg",{status_no=all_data.status_no,action=_act})
end

--dao消息
function CMD.nor_ddz_mld_dao_msg(_act)

    if _act.p==s_info.seat_num then
        overtime_cb=nil
        s_info.is_must_mld_opt=nil
    end

	s_info.my_rate=_act.rate
	s_info.dao_la_data[_act.p]=_act.type==nor_ddz_base_lib.other_type.mld_dao and 1 or 0
	add_act(_act)
	add_status_no()
	PUBLIC.request_client("nor_ddz_nor_action_msg",{status_no=all_data.status_no,action=_act})
end

--la消息
function CMD.nor_ddz_mld_la_msg(_act)

    if _act.p==s_info.seat_num then
        overtime_cb=nil
    end

	s_info.my_rate=_act.rate
	s_info.dao_la_data[_act.p]=_act.type==nor_ddz_base_lib.other_type.mld_la and 1 or 0
	
	add_act(_act)
	add_status_no()
	PUBLIC.request_client("nor_ddz_nor_action_msg",{status_no=all_data.status_no,action=_act})
end


function CMD.nor_ddz_mld_dizhu_pai_msg(_dz_pai)
	
	s_info.dz_pai = _dz_pai or {0,0,0}

	if s_info.dizhu==s_info.seat_num then 
		for i=1,3 do 
			my_pai_data.pai[s_info.dz_pai[i]]=true
			s_info.my_pai_list[#s_info.my_pai_list+1]=s_info.dz_pai[i]
		end
		my_pai_data.hash=nor_ddz_base_lib.get_pai_typeHash(my_pai_data.pai)
	end

	s_info.remain_pai_amount[s_info.dizhu]=20

	--初始化记牌器
	s_info.jipaiqi=nor_ddz_base_lib.getAllPaiCount()
	nor_ddz_base_lib.jipaiqi({nor=s_info.my_pai_list},s_info.jipaiqi)

	add_status_no()
	PUBLIC.request_client("nor_ddz_mld_dizhu_pai_msg",{status_no=all_data.status_no,dz_pai=s_info.dz_pai})

end

------------------------------------------------------------------------------------------------
-----------------------------------------MLD-------------------------------------------------
------------------------------------------------------------------------------------------------



function CMD.nor_ddz_nor_dizhu_msg(_dizhu,_dz_pai,_rate,_rangpai_num,_men)

	local _dz_pai_client = _dz_pai
	
	if s_info.jdz_type == "mld" then
		_dz_pai = nil
		if basefunc.is_real_player(DATA.my_id) then
			_dz_pai_client = nil
		end
	else
		s_info.remain_pai_amount[_dizhu]=20
	end

	s_info.status="set_dz"
	s_info.countdown=0
	s_info.dizhu=_dizhu
	s_info.dz_pai=_dz_pai
	s_info.my_rate=_rate
	
	--二人斗地主 
	s_info.rangpai_num=_rangpai_num

	--mld
	s_info.is_men_zhua=_men
	
	if _dz_pai and _dizhu==s_info.seat_num then 
		for i=1,3 do 
			my_pai_data.pai[_dz_pai[i]]=true
			s_info.my_pai_list[#s_info.my_pai_list+1]=_dz_pai[i]
		end
		my_pai_data.hash=nor_ddz_base_lib.get_pai_typeHash(my_pai_data.pai)
	end

	--初始化记牌器
	if s_info.jdz_type ~= "mld" then
		s_info.jipaiqi=nor_ddz_base_lib.getAllPaiCount()
		nor_ddz_base_lib.jipaiqi({nor=s_info.my_pai_list},s_info.jipaiqi)
	end

	--比赛场需要
	if all_data.m_PROTECT and all_data.m_PROTECT.ddz_dizhu_msg then
		all_data.m_PROTECT.ddz_dizhu_msg(my_pai_data)
	end

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_ddz_nor_dizhu_msg",{
			status_no=all_data.status_no,
			dz_info=
			{
				dizhu=_dizhu,
				dz_pai=  _dz_pai_client,
				rangpai_num=_rangpai_num,
			}
		})
end


function CMD.nor_ddz_nor_jiabei_permit(_countdown,_cur_p)
	s_info.status="jiabei"
	s_info.countdown=DATA.robot_cd or _countdown
	s_info.cur_p=_cur_p
	if s_info.seat_num==_cur_p or (_cur_p==4 and s_info.dizhu~=s_info.seat_num) then

		local _overtime_cb=function ()
							overtime_cb=nil
							--不加倍
							call_room_service("jiabei",0)
							s_info.jiabei=1
						end
		set_overtime_cb(_overtime_cb)

		if s_info.auto_status[s_info.seat_num]==1 then
			auto_data={countdown=auto_wait_cp_time}
		end

	end
	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_ddz_nor_permit_msg",{status_no=all_data.status_no,status=s_info.status,countdown=_countdown,cur_p=_cur_p})
end


function CMD.nor_ddz_nor_laizi_msg(_lz)
	s_info.status="set_dz"
	s_info.countdown=0
	s_info.laizi=_lz
	s_info.laizi_num=my_pai_data.hash[_lz] or 0
	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_ddz_nor_laizi_msg",{status_no=all_data.status_no,laizi=_lz})
end
function CMD.nor_ddz_nor_my_jiabei_msg(act)
	overtime_cb=nil
	add_act(act)
	s_info.jiabei=1
end

function CMD.nor_ddz_nor_jiabei_msg(_acts,_rate)

	s_info.my_rate=_rate
	--先发我自己的  以免bug （客户端可能已经先行显示）
	for _,_act in ipairs(_acts) do
		if _act.p==s_info.seat_num then
			--通知客户端
			add_status_no()
			PUBLIC.request_client("nor_ddz_nor_action_msg",{status_no=all_data.status_no,action=_act})	
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
			PUBLIC.request_client("nor_ddz_nor_action_msg",{status_no=all_data.status_no,action=_act})
		end
	end
	--加倍完成动画
	if rate>0 then
		add_status_no()
		PUBLIC.request_client("nor_ddz_nor_jiabeifinshani_msg",{status_no=all_data.status_no,my_rate=s_info.my_rate})
	end
end

function CMD.nor_ddz_nor_cp_permit_nor(_countdown,_cur_p,_is_must)
	s_info.status="cp"
	s_info.countdown=_countdown
	s_info.cur_p=_cur_p	
	if s_info.seat_num==_cur_p then
		local is_yaobuqi=false
		--根据手里的牌进行倒计时选择
		if not _is_must then
			local _s=nor_ddz_algorithm:check_cp_capacity(s_info.act_list,my_pai_data.pai,s_info.laizi_num,s_info.laizi)
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

		
		
		local _overtime_cb=function ()
							overtime_cb=nil
							auto_data=nil
							print("超时出牌")
							auto_cp(_is_must,is_yaobuqi)
						end	

		set_overtime_cb(_overtime_cb)			
	end
	--通知客户端
	add_status_no()
	if _is_must then
		_is_must=1
	else
		_is_must=nil
	end
	PUBLIC.request_client("nor_ddz_nor_permit_msg",{status_no=all_data.status_no,status=s_info.status,countdown=_countdown,cur_p=_cur_p,other=_is_must})	
end



function CMD.nor_ddz_nor_cp_msg(_act,_rate)

	add_act(_act)

	if _act.p==s_info.seat_num then 
		overtime_cb=nil
	end

	if _act.type~=0 then
		s_info.remain_pai_amount[_act.p]=s_info.remain_pai_amount[_act.p]-#_act.merge_cp_list
		if _act.p==s_info.seat_num then
			nor_ddz_base_lib.deduct_pai_by_cp_list(my_pai_data,_act.cp_list,s_info.laizi)
			s_info.my_rate=_rate
			if _act.lazi_num then
				s_info.laizi_num=s_info.laizi_num-_act.lazi_num
			end
		else
			nor_ddz_base_lib.jipaiqi(_act.cp_list,s_info.jipaiqi,s_info.laizi)
		end
	end
	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_ddz_nor_action_msg",{status_no=all_data.status_no,action=_act})
end
--玩家托管消息
function CMD.nor_ddz_nor_auto_msg(_p,_type)
	s_info.auto_status[_p]=_type
	PUBLIC.request_client("nor_ddz_nor_auto_msg",{p=_p,auto_status=_type})
end

-- by lyx 改变钱
function CMD.nor_ddz_nor_modify_score(_score)
	if all_data.m_PROTECT and all_data.m_PROTECT.modify_score then
		return all_data.m_PROTECT.modify_score(_score)
	else
		return _score
	end
end
function CMD.nor_ddz_nor_get_yingfengding_score(_score)
	if all_data.m_PROTECT and all_data.m_PROTECT.get_fengding_score then
		return all_data.m_PROTECT.get_fengding_score()
	else
		return _score
	end
end

-- by lyx 分数改变
function CMD.nor_ddz_nor_score_change_msg(_data)
	-- 斗地主不需要发  因为中途不会改变
	-- local send_data={}
	-- if _data then
	-- for p,s in pairs(_data) do
	-- 	send_data[#send_data+1]={cur_p=p,score=s}
	-- end
	--end

	-- add_status_no()
	-- PUBLIC.request_client("nor_ddz_nor_score_change_msg",{status_no=all_data.status_no,data=send_data})
	
	if all_data.m_PROTECT and all_data.m_PROTECT.score_change_msg then 
		all_data.m_PROTECT.score_change_msg(_data)
	end

end

-- by lyx 玩家退出房间
function CMD.nor_ddz_nor_player_exit_msg(_seat_num)
	
	if s_info.seat_num ==_seat_num and DATA.chat_room_id then
		skynet.send(DATA.service_config.chat_service,"lua","exit_room", DATA.chat_room_id,DATA.my_id)
		DATA.chat_room_id = nil
	end

	s_info.ready[_seat_num] = 0
	if all_data.m_PROTECT and all_data.m_PROTECT.player_exit_msg then 
		all_data.m_PROTECT.player_exit_msg(_seat_num)
	end

end

-- 重新发牌
function CMD.nor_ddz_nor_start_again_msg()

	add_status_no()

	PUBLIC.request_client("nor_ddz_nor_start_again_msg",{status_no=all_data.status_no,status=s_info.status})	

	new_game()

end


-- by lyx 游戏开始前通知解散房间（无结算）
function CMD.nor_ddz_nor_gamecancel_msg()

	if all_data.m_PROTECT and all_data.m_PROTECT.gamecancel_msg then 
		all_data.m_PROTECT.gamecancel_msg()
	end

end

--单局结算  ###_test
function CMD.nor_ddz_nor_settlement_msg(_settlement_info,_p_remain_pai,p_jiabei,p_jdz,bomb_count,p_bomb_count,is_chuntian,_rate,is_over,_log_id)
	s_info.status="settlement"

	settlement_info=_settlement_info
	settlement_info.remain_pai=_p_remain_pai

	settlement_info.p_jiabei=p_jiabei
	settlement_info.bomb_count=bomb_count
	settlement_info.chuntian=is_chuntian
	settlement_info.p_jdz=p_jdz
	settlement_info.er_qiang_dizhu_count=s_info.er_qiang_dizhu_count

	s_info.settlement_info=settlement_info

	s_info.my_rate = _rate

	local dz_data = {0,0,0}
	dz_data[s_info.dizhu]=1

	local ct_data = {0,0,0}
	if is_chuntian==1 then
		ct_data[s_info.dizhu]=1
	elseif is_chuntian==2 then
		ct_data = {1,1,1}
		ct_data[s_info.dizhu]=0
	end

	local settle_data = {
		scores=_settlement_info.award,
		ddz_nor_statistics={
			bomb_count = p_bomb_count,
			dizhu_count = dz_data,
			chuntian_count = ct_data,
		}
	}

	if not is_over then
		s_info.ready={0,0,0}
		s_info.next_race=s_info.cur_race + 1
	end

	s_info.is_over = is_over and 1 or 0

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_ddz_nor_settlement_msg",
								{status_no=all_data.status_no,
								settlement_info=settlement_info,
								is_over = s_info.is_over,
								})

	-- -- 统计 数据落地
	local my_pos = 4
	local t = 1

	if s_info.seat_num==s_info.dizhu then
		my_pos = 5
		t = 2
	end
	
	if settlement_info.winner ~= my_pos then
		t = 0
	end

	skynet.send(DATA.service_config.data_service,"lua","update_statistics_player_ddz_win_data",DATA.my_id,t)

	local lose_surplus = settlement_info.lose_surplus
	if all_data.m_PROTECT and all_data.m_PROTECT.game_settlement_msg then
		all_data.m_PROTECT.game_settlement_msg(settle_data,is_over,lose_surplus,_log_id)
	end 
end


function CMD.nor_ddz_nor_gameover_msg(_data)
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



function CMD.nor_ddz_nor_next_game_msg(_data)

	add_status_no()

	PUBLIC.request_client("nor_ddz_nor_new_game_msg",
							{
							status_no=all_data.status_no,
							status=s_info.status,
							cur_race=_data,
							})


	if all_data.m_PROTECT and all_data.m_PROTECT.game_next_game_msg then
		all_data.m_PROTECT.game_next_game_msg(_data)
	end
	
end



local my_pai_tmp_list = {-1,-2,-3,-4,-5,-6,-7,-8,-9,-10,-11,-12,-13,-14,-15,-16,-17,}

function PROTECT.get_status_info()

	if s_info then

		if my_pai_data then
			local my_pai_list=nor_ddz_base_lib.get_pai_list_by_map(my_pai_data.pai)
			s_info.my_pai_list=my_pai_list
		else
			if jdz_type == "mld" then
				s_info.my_pai_list=my_pai_tmp_list
			end
		end

	end

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
	_config = _config or {}
	auto_count_cfg=_config.auto_count_cfg or auto_count_cfg
	if not basefunc.chk_player_is_real(DATA.my_id) then
		auto_count_cfg=auto_count_cfg+1
	end
	auto_wait_cp_time_cfg=_config.auto_wait_cp_time_cfg or auto_wait_cp_time_cfg
	overtime_auto_action_cfg=_config.overtime_auto_action_cfg or overtime_auto_action_cfg
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
	my_pai_data=nil
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

	jdz_type = _all_data.jdz_type

	--
	nor_ddz_base_lib.set_game_type(my_game_name)

	if _all_data.config.rule_cfg 
		and _all_data.config.rule_cfg[1] 
		and _all_data.config.rule_cfg[1].kaiguan then
		kaiguan = _all_data.config.rule_cfg[1].kaiguan
	else
		
		if jdz_type == "mld" then
			kaiguan = nor_ddz_base_lib.KAIGUAN_MLD
		else
			kaiguan = nor_ddz_base_lib.KAIGUAN
		end
		
	end
	
	nor_ddz_algorithm=nor_ddz_algorithm_lib.new(kaiguan,my_game_name)
end





return PROTECT


