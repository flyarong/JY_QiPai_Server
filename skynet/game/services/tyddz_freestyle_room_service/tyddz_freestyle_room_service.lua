--
-- Author: hw
-- Time: 
-- 说明：癞子自由场斗地主桌子服务
--tyddz_freestyle_room_service
local skynet = require "skynet_plus"
require "skynet.manager"
require"printfunc"
local nodefunc = require "nodefunc"
local base=require "base"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA
local tyDdzFunc=require "ty_ddz_lib"
require "tyddz_freestyle_room_service/tyddz_freestyle_room_record_log"

--房间ID
DATA.my_id = 0

--上级管理者
DATA.mgr_id = 0

--剩余桌子数量
DATA.table_count = 0

--[[游戏状态表
	玩家位置代号：1，2，3，
	农民代号：4，
	地主代号 5，
	全部 6 
	status :
	wait_p ：等待人员入座阶段 
	ready ： 准备就绪阶段
	fp : 发牌阶段
	jdz : 叫地主
	-set_dz： 设置地主
	jb : 加倍
	cp： 出牌阶段
	settlement： 结算
	report： 上报战果
--]]
DATA.service_config = nil
local node_service
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
--###_test
local run=true

local fp_time=2
local first_cp_cd=25
local cp_cd=15
local mz_cd=10
local zp_cd=10
local dao_cd=10
local la_cd=10
local jb_cd=10

-- local fp_time=2
-- local cp_cd=10
-- local mz_cd=3
-- local zp_cd=3
-- local dao_cd=3
-- local la_cd=3
-- local jb_cd=3

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

--获取打牌动画的时间
local function gen_pai_act_time(_type)
	if  _type ==14 then
		return 3
	elseif _type ==13 or _type ==15 then
		return 2
	elseif _type ==10 or _type ==11 or _type ==12 then
		return 2
	elseif _type ==6 or _type ==7 then
		return 1
	end

	return 0.5
end
local function gen_settlement_time(_t_num)
	local _d=game_table[_t_num]
	if _d.is_chuntian then
		return 3
	end
	return 1.5
end

--_is_again 重新发牌 不计算比赛次数
local function new_game(_t_num,_is_again)
	local _data=game_table[_t_num]
	if not _data then
		return false
	end
	if not _is_again then 
		_data.cur_race_num=_data.cur_race_num+1
	end
	_data.time=0
	_data.play_data=tyDdzFunc.new_game()
	_data.p_rate={_data.init_rate,_data.init_rate,_data.init_rate}
	_data.p_cp_count={0,0,0}
	--结算信息
	_data.s_info={}
	--炸弹次数
	_data.bomb_count=0

	--闷抓?
	_data.is_men_zhua = 0

	--nil-无 0-不倒不拉 1-倒拉
	_data.p_dao_la={}

	--nil-无  0-不操作  1-是操作
	_data.men_data={}

	--不抓的次数统计
	_data.no_zhua_count=0

	--nil-无 1-已经看了牌
	_data.p_kan_pai={}

	--玩家的炸弹次数
	_data.p_bomb_count={0,0,0}

	--春天或者反春  1春天  2 反春
	_data.is_chuntian=0

	-- ###_test
	change_status(_t_num,"wait",1,"fp")

	-- for _seat_num,_id in pairs(game_table[_t_num].p_seat_number) do
	-- 	nodefunc.send(_id,"tydfg_ready_msg",game_table[_t_num].status)
	-- end

	--记录游戏开始日志
	PUBLIC.save_race_start_log(_data,_t_num)

end



local function ready(_t_num)
	game_table[_t_num].p_ready=game_table[_t_num].p_ready+1
	if game_table[_t_num].p_ready==3 then 
		new_game(_t_num)
	end
end

local function fapai(_t_num)
	local _d = game_table[_t_num]
	
	_d.play_data.pai=tyDdzFunc.xipai()
	
	tyDdzFunc.fapai(_d.play_data.pai,_d.play_data,17)

	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"tydfg_pai_msg",17,fp_time)
	end	

	--随机确定出叫地主顺序
	tyDdzFunc.get_dz_candidate(_d.play_data)

end


--看自己的牌
local function kan_my_pai(_t_num,_seat_num)
	local _d = game_table[_t_num]
	
	if _d.p_kan_pai[_seat_num] then
		return
	end

	_d.p_kan_pai[_seat_num]=1
	nodefunc.send(_d.p_seat_number[_seat_num],"tydfg_kan_my_pai_msg",_d.play_data[_seat_num].pai)

end

--开始出牌
local function start_cp(_t_num)
	local _d = game_table[_t_num]

	kan_my_pai(_t_num,1)
	kan_my_pai(_t_num,2)
	kan_my_pai(_t_num,3)

	tyDdzFunc.fapai_dizhu(_d.play_data.dz_pai,_d.play_data[_d.play_data.dizhu])

	for _s,_id in pairs(_d.p_seat_number) do

		--发送地主牌
		if _d.is_men_zhua<1 or
			(_d.is_men_zhua>0 and _s==_d.play_data.dizhu) then
			nodefunc.send(_id,"tydfg_dizhu_pai_msg",_d.play_data.dz_pai)
		else
			nodefunc.send(_id,"tydfg_dizhu_pai_msg")
		end

	end

	_d.play_data.cur_p=_d.play_data.dizhu
	change_status(_t_num,"wait",1,"cp")
end

--_men 1-yes  0-no
local function set_dizhu(_t_num,_dizhu,_men)
	local _d=game_table[_t_num]

	_d.play_data.dizhu=_dizhu
	_d.play_data.cur_p=_dizhu

	--农民的座位
	local nm1=1
	if nm1==_d.play_data.dizhu then
		nm1=nm1+1
	end
	local nm2=nm1+1
	if nm2==_d.play_data.dizhu then
		nm2=nm2+1
	end
	_d.nongmin={}
	_d.nongmin[1]=nm1
	_d.nongmin[2]=nm2

	_d.is_men_zhua = _men

	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"tydfg_dizhu_msg",_dizhu,_men)
	end
end

--必须闷
local function must_men_zhua(_t_num)
	local _d = game_table[_t_num]

	set_dizhu(_t_num,_d.play_data.cur_p,1)

	for _s,_id in pairs(_d.p_seat_number) do
		if _s == _d.play_data.cur_p then
			_d.p_rate[_s]=_d.p_rate[_s]*4
		else
			_d.p_rate[_s]=_d.p_rate[_s]*2
		end
	end

	local act = {
		type = tyDdzFunc.act_type.men,
		p = _d.play_data.cur_p,
		rate = _d.p_rate[_d.play_data.cur_p],
	}
	_d.play_data.act_list[#_d.play_data.act_list+1] = act

	for _s,_id in pairs(_d.p_seat_number) do
		act.rate = _d.p_rate[_s]
		nodefunc.send(_id,"tydfg_men_msg",act)
	end

	start_cp(_t_num)

end


--倒 0-不倒  1-倒
local function dao(_t_num,_seat_num,_dao_opt)
	local _d = game_table[_t_num]

	if _d.men_data[_seat_num] and _dao_opt==1 then
		print("自己看了牌 不能倒")
		return 1002
	end

	if _dao_opt>0 then
		_d.p_rate[_seat_num]=_d.p_rate[_seat_num]*2
		_d.p_rate[_d.play_data.dizhu]=_d.p_rate[_d.nongmin[1]]+_d.p_rate[_d.nongmin[2]]
	end

	local act = {
		type = _dao_opt>0 and tyDdzFunc.act_type.dao or tyDdzFunc.act_type.bd,
		p = _seat_num,
		rate = _d.p_rate[_seat_num],
	}
	_d.play_data.act_list[#_d.play_data.act_list+1] = act

	_d.p_dao_la[_seat_num]=_dao_opt

	local dao_num = 0
	local dao_opt = 0

	for _s,_id in pairs(_d.p_seat_number) do
		act.rate = _d.p_rate[_s]
		nodefunc.send(_id,"tydfg_dao_msg",act)

		if _d.p_dao_la[_s] then
			dao_num = dao_num + 1
			if _d.p_dao_la[_s] > 0 then
				dao_opt = _d.p_dao_la[_s]
			end
		end

	end

	if dao_num > 1 then

		--有人倒
		if dao_opt > 0 then
			change_status(_t_num,"wait",1,"jb")
		else
			start_cp(_t_num)
		end

	end

	--记录过程数据日志
	PUBLIC.save_process_data_log(_d,_t_num,_seat_num,30-_dao_opt)

	return 0

end

--拉 0-不拉 1-拉
local function la(_t_num,_seat_num,_la_opt)
	local _d = game_table[_t_num]

	if _la_opt>0 then

		if _d.p_dao_la[_d.nongmin[1]]>0 then
			_d.p_rate[_d.nongmin[1]] = _d.p_rate[_d.nongmin[1]] * 2
		end

		if _d.p_dao_la[_d.nongmin[2]]>0 then
			_d.p_rate[_d.nongmin[2]] = _d.p_rate[_d.nongmin[2]] * 2
		end

		_d.p_rate[_d.play_data.dizhu]=_d.p_rate[_d.nongmin[1]]+_d.p_rate[_d.nongmin[2]]

	end

	_d.play_data.act_list[#_d.play_data.act_list+1] = act
	local act = {
		type = _la_opt>0 and tyDdzFunc.act_type.la or tyDdzFunc.act_type.bl,
		p = _seat_num,
		rate = _d.p_rate[_seat_num],
	}
	_d.play_data.act_list[#_d.play_data.act_list+1] = act

	_d.p_dao_la[_seat_num]=_la_opt

	for _s,_id in pairs(_d.p_seat_number) do
		act.rate = _d.p_rate[_s]
		nodefunc.send(_id,"tydfg_la_msg",act)
	end

	start_cp(_t_num)

	--记录过程数据日志
	PUBLIC.save_process_data_log(_d,_t_num,_seat_num,32-_la_opt)

	return 0

end



local function jdz_permit(_t_num)
	local _d = game_table[_t_num]

	if _d.no_zhua_count > 1 then
		--必须闷
		must_men_zhua(_t_num)
		return
	end

	local cd = mz_cd
	--闷抓 or 抓牌
	if _d.men_data[_d.play_data.cur_p] then
		cd = zp_cd
	end

	for _seat_num,_id in pairs(_d.p_seat_number) do
		--参数：  状态,时间，下一个叫地主权限拥有者，
		nodefunc.send(_id,"tydfg_jdz_permit",cd,_d.play_data.cur_p)
	end
	
	--记录获取权限的时间日志
	PUBLIC.save_ddz_process_get_permit_time(_d,_t_num)
end


local function jb_permit(_t_num)
	local _d = game_table[_t_num]

	local cd = dao_cd
	--倒 or 拉
	if _d.play_data.dizhu == _d.play_data.cur_p then
		cd = la_cd
	end

	--没人进行倒和拉 则是农民开始倒
	if not next(_d.p_dao_la) then
		_d.play_data.cur_p = 4
	else
		_d.play_data.cur_p = _d.play_data.dizhu
	end

	for _seat_num,_id in pairs(_d.p_seat_number) do
		--参数：  状态,时间，下一个叫地主权限拥有者，
		nodefunc.send(_id,"tydfg_jiabei_permit",cd,_d.play_data.cur_p)
	end

	--记录获取权限的时间日志
	PUBLIC.save_ddz_process_get_permit_time(_d,_t_num)
end




local function chupai_permit(_t_num)
	local _d = game_table[_t_num]
	local _is_must=tyDdzFunc.is_must_chupai(_d.play_data.act_list,_d.play_data.cur_p)
	local _cd = _d.p_cp_count[_d.play_data.cur_p] < 1 and first_cp_cd or cp_cd
	for _seat_num,_id in pairs(_d.p_seat_number) do
		--参数：  状态，时间，出牌权限拥有人
		nodefunc.send(_id,"tydfg_cp_permit",_cd,
						_d.play_data.cur_p,_is_must)
	end

	--记录获取权限的时间日志
	PUBLIC.save_ddz_process_get_permit_time(_d,_t_num)
end

--根据托管情况判断是否需要包赔
local function check_baopei(_t_num,_winner)
	if _winner==5 or _winner==4 then
		local _d=game_table[_t_num]
		local nm1=_d.nongmin[1]
		local nm2=_d.nongmin[2]

		--如果其中一个农民有托管  则包赔 如果两个都托管 则正常
		if _d.p_auto[nm1]==1 and _d.p_auto[nm2]==0 then
			--托管人（包赔玩家）
			_d.s_info.auto_baopei_pos=nm1
			--地主赢了
			if  _winner==5 then
				_d.s_info.award[nm1]=_d.s_info.award[nm1]*2
				_d.s_info.award[nm2]=0
			--农民赢了
			else
				_d.s_info.award[nm1]=0
				_d.s_info.award[nm2]=_d.s_info.award[nm2]*2
			end
		elseif _d.p_auto[nm1]==0 and _d.p_auto[nm2]==1 then
			_d.s_info.auto_baopei_pos=nm2
			--地主赢了
			if  _winner==5 then
				_d.s_info.award[nm2]=_d.s_info.award[nm2]*2
				_d.s_info.award[nm1]=0
			--农民赢了
			else
				_d.s_info.award[nm2]=0
				_d.s_info.award[nm1]=_d.s_info.award[nm1]*2
			end
		end
	end
end
local function settlement(_t_num,_winner,inval_time)
	print("_winner:", _winner)
	local _d=game_table[_t_num]
	_d.s_info.award={}
	_d.s_info.p_rate={}
	--先出完牌的人的位置
	_d.winner_pos=_winner
	--都不叫地主 解散房间
	if _winner==0 then
		_d.s_info.winner=0
		for _i=1,3 do 
			_d.s_info.award[_i]=0
		end	
	--地主赢了
	elseif _winner==_d.play_data.dizhu then
		_d.s_info.winner=5
		--春天判定
		local _count=_d.p_cp_count[1]+_d.p_cp_count[2]+_d.p_cp_count[3]
		if _count==_d.p_cp_count[_d.play_data.dizhu] then 
			_d.is_chuntian=1 
			for i=1,3 do 
				_d.p_rate[i]=_d.p_rate[i]*2
			end
		end
		for _i=1,3 do 
			_d.s_info.award[_i]=-_d.p_rate[_i]*_d.init_stake
		end
		--  地主的分已经是农民和地主和起来的了   所以不能乘以2
		_d.s_info.award[_d.play_data.dizhu]=_d.p_rate[_d.play_data.dizhu]*_d.init_stake
	--农民赢了
	else
		_d.s_info.winner=4
		--反春判定
		if _d.p_cp_count[_d.play_data.dizhu]==1 then
			_d.is_chuntian=2 
			for _i=1,3 do 
				_d.p_rate[_i]=_d.p_rate[_i]*2
			end
		end
		for _i=1,3 do 
			_d.s_info.award[_i]=_d.p_rate[_i]*_d.init_stake
		end
		--  地主的分已经是农民和地主和起来的了   所以不能乘以2
		_d.s_info.award[_d.play_data.dizhu]=-(_d.p_rate[_d.play_data.dizhu]*_d.init_stake)
	end

	if _d.game_model==1 then
		--检测包赔情况
		check_baopei(_t_num,_winner)
	end
	
	_d.remain_pai={}
	for _i=1,3 do
		local _pai=tyDdzFunc.get_pai_list_by_map(_d.play_data[_i].pai)
		if _pai and #_pai>0 then 
			_d.remain_pai[#_d.remain_pai+1]={p=_i,pai=_pai}
		end
		_d.s_info.p_rate[_i]=_d.p_rate[_i]
	end

	--准备结算，其实已经结算了
	inval_time=inval_time or 1.5
	change_status(_t_num,"wait",inval_time,"settlement")

	--记录一局结束的日志
	PUBLIC.save_race_over_log(_d,_t_num)

end
--真正的扣钱和加钱 （考虑不够赔的情况）
local function settlement_with_score(_t_num)
	local _d = game_table[_t_num]
	--地主赢了
	if _d.s_info.winner==5 then
		--扣农民的钱 得到实际扣除的钱
		local real_deduct=0
		
		for _,_pos in ipairs(_d.nongmin) do
			if _d.s_info.award[_pos]~=0 then
				local rd = nodefunc.call(_d.p_seat_number[_pos],"tydfg_deduct_lose",_d.s_info.award[_pos])
				real_deduct=real_deduct+rd
				_d.s_info.award[_pos]=rd
			end
		end
		_d.s_info.award[_d.play_data.dizhu]=-real_deduct
		nodefunc.send(_d.p_seat_number[_d.play_data.dizhu],"tydfg_add_win",_d.s_info.award[_d.play_data.dizhu])
	--农民赢了
	elseif _d.s_info.winner==4 then
		--扣地主的钱 得到实际扣除的钱
		local real_deduct=nodefunc.call(_d.p_seat_number[_d.play_data.dizhu],"tydfg_deduct_lose",_d.s_info.award[_d.play_data.dizhu])
		--如果实际扣的钱和应扣的相等
		if real_deduct~=_d.s_info.award[_d.play_data.dizhu] then
			_d.s_info.award[_d.play_data.dizhu]=real_deduct
			--分配给农民 --如果为奇数 先出完牌的人获得更多
			local fp1=0
			local fp2=0
			real_deduct=-real_deduct
			--判断是否有人托管 有全部加给没有托管的人
			if _d.s_info.auto_baopei_pos then
				 for _,_pos in ipairs(_d.nongmin) do
				 	if _d.s_info.auto_baopei_pos~=_pos then
				 		_d.s_info.award[_pos]=real_deduct
				 		break
				 	end
				 end	
			else
				if real_deduct%2==0 then
					fp1=real_deduct/2
					fp2=fp1
				else
					fp1=(real_deduct-1)+1
					fp2=fp1-1
				end
				for _,_pos in ipairs(_d.nongmin) do
				 	if _d.winner_pos==_pos then
				 		_d.s_info.award[_pos]=fp1
				 	else
				 		_d.s_info.award[_pos]=fp2
				 	end
				 end
			end
		end
		--加钱
		for _,_pos in ipairs(_d.nongmin) do
			if _d.s_info.award[_pos]>0 then
				nodefunc.send(_d.p_seat_number[_pos],"tydfg_add_win",_d.s_info.award[_pos])
			end
		end
	end
end
----练习场 award 胜利为1 失败为 0
local function settlement_for_lianxichang(_t_num)
	local _d = game_table[_t_num]
	--地主赢了
	if _d.s_info.winner==5 then
		for i=1,3 do
			_d.s_info.award[i]=0
		end
		_d.s_info.award[_d.play_data.dizhu]=1
	elseif _d.s_info.winner==4 then
		for i=1,3 do
			_d.s_info.award[i]=1
		end
		_d.s_info.award[_d.play_data.dizhu]=0
	else
		for i=1,3 do
			_d.s_info.award[i]=0
		end
	end
end
--结算中 通知给玩家
local function gameover(_t_num)
	local _d = game_table[_t_num]
	if _d.game_model==1 then
		settlement_with_score(_t_num)
	else
		--练习场 award 胜利为1 失败为 0 
		 settlement_for_lianxichang(_t_num)
	end
	--通知
	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"tydfg_gameover_msg",
						_d.s_info,
						_d.remain_pai,
						_d.bomb_count,
						_d.is_chuntian)
	end

	change_status(_t_num,"gameover")
	return_table(_t_num)

	nodefunc.send(DATA.mgr_id,"table_finish",DATA.my_id,_t_num)

end



change_status=function (_t_num,_status,_time,_next_status)
	assert(game_table[_t_num])
	print("change_status  : ",_status,DATA.my_id,_t_num)
	if _status=="wait_p" then
		game_table[_t_num].status=_status
	elseif _status=="wait" then
		game_table[_t_num].status=_status
		game_table[_t_num].time=_time
		game_table[_t_num].next_status=_next_status
	elseif _status=="fp" then 
		game_table[_t_num].status=_status
		game_table[_t_num].time=fp_time
		fapai(_t_num)
	elseif _status=="jdz" then
		game_table[_t_num].status=_status
		jdz_permit(_t_num)
	elseif _status=="jb" then
		game_table[_t_num].status=_status
		jb_permit(_t_num)
	elseif _status=="cp" then
		game_table[_t_num].status=_status
		chupai_permit(_t_num)
	elseif _status=="settlement" then
		game_table[_t_num].status=_status
		gameover(_t_num)
	end 
end
local dt=0.5
local function update()
	while run do
		for _t_num,_value in pairs(game_table) do
			if _value.status=="wait" then
				_value.time=_value.time-dt 
				if _value.time<=0 then
					change_status(_t_num,_value.next_status)
				end	
			elseif _value.status=="fp" then
				_value.time=_value.time-dt 
				if _value.time<=0 then 
					change_status(_t_num,"jdz")
				end
			end 
		end
		skynet.sleep(dt*100)
	end
end

function CMD.new_table(_game_config)
	local _t_num=employ_table()
	if not _t_num then 
		return false
	end
	local _data={}
	_data.game_config=_game_config

	_data.time=0
	_data.play_data=tyDdzFunc.new_game()
	_data.p_info={}
	--玩家进入房间的标记
	_data.players_join_flag={}
	_data.p_seat_number={}
	_data.p_count=0
	_data.p_ready=0

	--都不叫地主的次数
	_data.no_dizhu_count=0
	--游戏类型  0为 练习场  1为钻石场
	_data.game_model=_game_config.game_model or 0 

	_data.init_rate=_game_config.base_rate or 1
	_data.init_stake=_game_config.base_score or 1
	--比赛次数
	_data.race_count=_game_config.race_count or 1
	_data.cur_race_num=0

	--比赛id
	_data.game_id=_game_config.game_id

	_data.p_auto={}

	game_table[_t_num]=_data

	_data.p_rate={_data.init_rate,_data.init_rate,_data.init_rate}

	if DATA.service_config.chat_service then
		_data.chat_room_id = skynet.call(DATA.service_config.chat_service,"lua","create_room")
	end

	change_status(_t_num,"wait_p")

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
	local _data=game_table[_t_num] 
	if not _data or _data.p_count>2 or _data.status~="wait_p" or _data.players_join_flag[_p_id] then
		return {result=1002}
	end
	for _seat_num=1,3 do 
		if not _data.p_seat_number[_seat_num] then
			_data.players_join_flag[_p_id]=true 
			_data.p_seat_number[_seat_num]=_p_id
			_data.p_count=_data.p_count+1
			_data.p_info[_seat_num]=_info
			_data.p_info[_seat_num].seat_num=_seat_num

			--通知其他人 xxx 加入房间
			for _,_value in pairs(_data.p_info) do
				nodefunc.send(_value.id,"tydfg_join_msg",_data.p_count,_info,_data.chat_room_id)
			end

			--自动准备
			ready(_t_num)

			return {result=0,seat_num=_seat_num,p_info=_data.p_info,p_count=_data.p_count,
					rate=_data.init_rate,init_stake=_data.init_stake}
		end
	end
	return {result=1000}
end
--###_test 暂时是自动ready
-- function CMD.ready()
-- end


--闷
function CMD.men(_t_num,_seat_num)
	local _d=game_table[_t_num]
	if not _d or _d.status~="jdz" or _d.play_data.cur_p~=_seat_num then 
		--状态不合法
		return 1002
	end

	for _s,_id in pairs(_d.p_seat_number) do
		if _s == _seat_num then
			_d.p_rate[_s]=_d.p_rate[_s]*4
		else
			_d.p_rate[_s]=_d.p_rate[_s]*2
		end
	end

	_d.men_data[_seat_num]=1

	local act = {
		type = tyDdzFunc.act_type.men,
		p = _seat_num,
		rate = _d.p_rate[_seat_num],
	}

	_d.play_data.act_list[#_d.play_data.act_list+1] = act

	for _s,_id in pairs(_d.p_seat_number) do
		act.rate = _d.p_rate[_s]
		nodefunc.send(_id,"tydfg_men_msg",act)
	end

	--记录过程数据日志
	PUBLIC.save_process_data_log(_d,_t_num,_seat_num,25)

	--地主产生了
	set_dizhu(_t_num,_seat_num,1)
	change_status(_t_num,"wait",1,"jb")

	return 0
end

--看牌
function CMD.kan(_t_num,_seat_num)
	
	local _d=game_table[_t_num]
	if not _d or _d.status~="jdz" 
		or _d.play_data.cur_p~=_seat_num 
		or _d.men_data[_seat_num] then
		return 1002
	end

	_d.play_data.act_list[#_d.play_data.act_list+1] = {
		type = tyDdzFunc.act_type.kp,
		p = _seat_num,
	}

	for _s,_id in pairs(_d.p_seat_number) do
		--参数：   ，当前操作
		nodefunc.send(_id,"tydfg_kan_msg",_d.play_data.act_list[#_d.play_data.act_list])
	end

	_d.men_data[_seat_num]=0

	kan_my_pai(_t_num,_seat_num)

	change_status(_t_num,"wait",1,"jdz")

	--记录过程数据日志
	PUBLIC.save_process_data_log(_d,_t_num,_seat_num,26)

	return 0

end

--抓牌 0-不抓  1-抓
function CMD.zhua_pai(_t_num,_seat_num,_zhua_opt)
	
	local _d=game_table[_t_num]
	if not _d or _d.status~="jdz" or _d.play_data.cur_p~=_seat_num then
		return 1002
	end

	if _zhua_opt > 0 then
		_d.p_rate[_seat_num]=_d.p_rate[_seat_num]*2
	end

	local act = {
		type = _zhua_opt>0 and tyDdzFunc.act_type.zp or tyDdzFunc.act_type.bz,
		p = _seat_num,
		rate = _d.p_rate[_seat_num],
	}

	_d.play_data.act_list[#_d.play_data.act_list+1] = act

	for _s,_id in pairs(_d.p_seat_number) do
		act.rate=_d.p_rate[_s]
		nodefunc.send(_id,"tydfg_zp_msg",act)
	end

	if _zhua_opt > 0 then
		
		--地主产生了
		set_dizhu(_t_num,_seat_num,0)

		kan_my_pai(_t_num,1)
		kan_my_pai(_t_num,2)
		kan_my_pai(_t_num,3)

		change_status(_t_num,"wait",1,"jb")

		--记录过程数据日志
		PUBLIC.save_process_data_log(_d,_t_num,_seat_num,27)

	else

		_d.no_zhua_count=_d.no_zhua_count+1

		_d.play_data.cur_p = _d.play_data.cur_p + 1
		if _d.play_data.cur_p > 3 then
			_d.play_data.cur_p = 1
		end

		change_status(_t_num,"wait",1,"jdz")
		--记录过程数据日志
		PUBLIC.save_process_data_log(_d,_t_num,_seat_num,28)

	end



	return 0

end


function CMD.jiabei(_t_num,_seat_num,_opt)

	local _d=game_table[_t_num]
	if not _d or _d.status~="jb" or _d.p_dao_la[_seat_num] then
		return 1002
	end

	if (_d.play_data.cur_p == 4
		and _seat_num==_d.play_data.dizhu)
		or(_d.play_data.cur_p==_d.play_data.dizhu 
			and _seat_num~=_d.play_data.dizhu) then
		return 1002
	end

	if _d.play_data.cur_p==_d.play_data.dizhu then
		return la(_t_num,_seat_num,_opt)
	else
		return dao(_t_num,_seat_num,_opt)
	end

end




function CMD.chupai(_t_num,_seat_num,_type,act_cp_list,_cp_list,lazi_num)
	local _d=game_table[_t_num]
	if not _d or _d.status~="cp" or _d.play_data.cur_p~=_seat_num then 
		return 1002
	end
	local _status=tyDdzFunc.chupai(_d,_seat_num,_type,act_cp_list,_cp_list,lazi_num)
	
	if _status==1 or _status==0 then
		--炸弹加倍
		if _type>12 and _type<19 then
			_d.bomb_count=_d.bomb_count+1 
			_d.p_bomb_count[_seat_num]=_d.p_bomb_count[_seat_num]+1

			local rate=2
			if _type==17 or _type==18 then
				rate=4
			end
			for i=1,3 do 
				_d.p_rate[i]=_d.p_rate[i]*rate
			end

		end
		if _type~=0 then
			--出牌次数加1
			_d.p_cp_count[_seat_num]=_d.p_cp_count[_seat_num]+1
		end
		for _s_n,_id in pairs(_d.p_seat_number) do
			nodefunc.send(_id,"tydfg_cp_msg",_d.play_data.act_list[#_d.play_data.act_list],_d.p_rate[_seat_num])
		end

		--记录过程数据日志
		PUBLIC.save_process_data_log(_d,_t_num,_seat_num,_type,_cp_list)
		
		if _status==1 then
			settlement(_t_num,_seat_num,gen_pai_act_time(_type))
		else
			--出牌中，接下来将转移出牌权限到下一个人
			change_status(_t_num,"wait",gen_pai_act_time(_type),"cp")
		end


		return 0
	else
		print("CMD.chupai ",_status,lazi_num,_type)
		dump(act_cp_list)
		dump(_cp_list)
	end
	return _status
end

function CMD.auto(_t_num,_seat_num,_type)
	local _d=game_table[_t_num]
	if not _d then 
		print("_d  ",_t_num,_seat_num)
		return 1002
	end
	local _d=game_table[_t_num]
	_d.p_auto[_seat_num]=_type
	for _s_n,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"tydfg_auto_msg",_seat_num,_type)
	end

	--记录过程数据日志
	PUBLIC.save_process_data_log(_d,_t_num,_seat_num,_type==1 and 23 or 24)

	return 0
end

function CMD.start(_id,_ser_cfg,_config)
	math.randomseed(os.time()*72453) 
	DATA.service_config =_ser_cfg
	node_service=_ser_cfg.node_service
	DATA.table_count=10
	DATA.my_id=_id
	DATA.mgr_id=_config.mgr_id

	--init table
	for i=1,DATA.table_count do 
		table_list[#table_list+1]=i
	end

	skynet.fork(update)
	return 0
end

-- 启动服务
base.start_service()






