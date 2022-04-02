--
-- Author: hw
-- Date: 2018/3/23
-- Time: 
-- 说明：比赛场斗地主桌子服务
--ddz_million_room_service
local skynet = require "skynet_plus"
require "skynet.manager"
require"printfunc"
local nodefunc = require "nodefunc"
local base=require "base"
require"ddz_million_room_service.ddz_million_room_record_log"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA
local normal_ddz=require "normal_ddz_lib"


--房间ID
DATA.my_id = 0

--上级管理者
DATA.mgr_id = 0

--剩余桌子数量
DATA.table_count = 0

--[[游戏状态表
	玩家位置代号：1，2，3，
	农民代号：4，
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
					--轮次
					race_count,
					--游戏起始倍数
					init_rate,
					--底注
					stake,
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
				--当前比赛数
				cur_race_num,

				}
--]]
--###_test
local run=true
--发牌需要的时间
-- local fp_time=2
-- local cp_cd=16
-- local jdz_cd=16
-- local jb_cd=16

local fp_time=2
local first_cp_cd=25
local cp_cd=15
local jdz_cd=10
local jb_cd=10


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
	_data.play_data=normal_ddz.new_game()
	--叫地主的
	_data.p_jdz_rate=0
	_data.p_rate={_data.init_rate,_data.init_rate,_data.init_rate}
	_data.p_cp_count={0,0,0}
	--结算信息
	_data.s_info={}
	--炸弹次数
	_data.bomb_count=0

	--玩家的炸弹次数
	_data.p_bomb_count={0,0,0}

	--春天或者反春  1春天  2 反春
	_data.is_chuntian=0

	--玩家加倍的情况
	_data.p_jiabei={0,0,0}

	--玩家叫地主分的情况
	_data.p_jdz={0,0,0}

	-- ###_test
	change_status(_t_num,"wait",2,"fp")
	-- for _seat_num,_id in pairs(game_table[_t_num].p_seat_number) do
	-- 	skynet.send(node_service,"lua","send",_id,"dbwg_ready_msg",game_table[_t_num].status)
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
	_d.play_data.pai=normal_ddz.xipai()
	normal_ddz.fapai(_d.play_data.pai,_d.play_data,9)

	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"dbwg_pai_msg",_d.play_data[_seat_num],fp_time)
	end	

	--随机确定出叫地主顺序
	normal_ddz.get_dz_candidate(_d.play_data)

end


local function jiao_dizhu(_t_num)
	local _d = game_table[_t_num]
	for _seat_num,_id in pairs(_d.p_seat_number) do
		--参数：  状态,时间，下一个叫地主权限拥有者，
		nodefunc.send(_id,"dbwg_jdz_permit",jdz_cd,_d.play_data.cur_p)
	end

	-- --记录获取权限的时间日志
	PUBLIC.save_ddz_process_get_permit_time(_d,_t_num)

end
local function set_dizhu(_t_num,_dizhu)
	local _d=game_table[_t_num]
	normal_ddz.set_dizhu(_d,_dizhu)
	for _seat_num,_id in pairs(_d.p_seat_number) do
		--参数：  状态,地主
		nodefunc.send(_id,"dbwg_dizhu_msg",_d.play_data.dizhu,_d.play_data.dz_pai,_d.p_rate[_seat_num])
	end
end


--加倍
local function jiabei_permit(_t_num)
	local _d = game_table[_t_num]
	_d.play_data.cur_p=6
	for _seat_num,_id in pairs(_d.p_seat_number) do
		--参数：  状态,倒计时_d.status
		nodefunc.send(_id,"dbwg_jiabei_permit",jb_cd,_d.play_data.cur_p)
	end
	--记录获取权限的时间日志
	PUBLIC.save_ddz_process_get_permit_time(_d,_t_num)
end


--准备出牌，对第一次出牌进行一次初始化
local function ready_chupai(_t_num)
	local _d = game_table[_t_num]
	--设置第一次出牌的人肯定是地主
	_d.play_data.cur_p=_d.play_data.dizhu
end

local function chupai_permit(_t_num)
	local _d = game_table[_t_num]
	local _is_must=normal_ddz.is_must_chupai(_d.play_data.act_list,_d.play_data.cur_p)
	local _cd = _d.p_cp_count[_d.play_data.cur_p] < 1 and first_cp_cd or cp_cd
	for _seat_num,_id in pairs(_d.p_seat_number) do
		--参数：  状态，时间，出牌权限拥有人
		nodefunc.send(_id,"dbwg_cp_permit",_cd,
						_d.play_data.cur_p,_is_must)
	end

	-- --记录获取权限的时间日志
	PUBLIC.save_ddz_process_get_permit_time(_d,_t_num)
end

local function settlement(_t_num,_winner)
	print("_winner:", _winner)
	local _d=game_table[_t_num]
	_d.s_info.p_scores={}
	--都不叫地主 解散房间
	if _winner==0 then
		_d.s_info.winner=0
		for _i=1,3 do 
			_d.s_info.p_scores[_i]=-_d.init_stake
		end
	--地主赢了
	elseif _winner==_d.play_data.dizhu then
		_d.s_info.winner=5
		--春天判定
		local _count=_d.p_cp_count[1]+_d.p_cp_count[2]+_d.p_cp_count[3]
		if _count==_d.p_cp_count[_d.play_data.dizhu] then 
			for i=1,3 do
				_d.is_chuntian=1  
				_d.p_rate[i]=_d.p_rate[i]*2
			end
		end
		
		local dz_award = 0
		for _i=1,3 do
			if _i ~= _d.play_data.dizhu then
				_d.s_info.p_scores[_i]=-_d.p_rate[_i]*_d.init_stake
				dz_award = dz_award - _d.s_info.p_scores[_i]
			end
		end
		_d.s_info.p_scores[_d.play_data.dizhu]=dz_award
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

		local dz_award = 0
		for _i=1,3 do
			if _i ~= _d.play_data.dizhu then
				_d.s_info.p_scores[_i]=_d.p_rate[_i]*_d.init_stake
				dz_award = dz_award - _d.s_info.p_scores[_i]
			end
		end
		_d.s_info.p_scores[_d.play_data.dizhu]=dz_award
	end
	_d.remain_pai={}
	for _i=1,3 do
		local _pai=normal_ddz.get_pai_list_by_map(_d.play_data[_i].pai)
		if _pai and #_pai>0 then 
			_d.remain_pai[#_d.remain_pai+1]={p=_i,pai=_pai}
		end
	end

	--准备结算，其实已经结算了
	change_status(_t_num,"wait",1.5,"settlement")

	--记录一局结束的日志
	PUBLIC.save_race_over_log(_d,_t_num)
	-- print("记录过程数据日志",_t_num,_winner,DATA.my_id)

end


--结算中 通知给玩家
local function settlementing(_t_num)
	
	local _d = game_table[_t_num]
	--通知
	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"dbwg_settlement_msg",
						_d.s_info,_d.remain_pai,_d.p_jiabei,_d.p_jdz,
						_d.bomb_count,_d.is_chuntian)

		_d.p_info[_seat_num].grades=_d.p_info[_seat_num].grades+_d.s_info.p_scores[_seat_num]
	end

end

--没有人做地主  ###_test
local function no_dizhu(_t_num)
	local _d=game_table[_t_num]
	if not _d  then 
		return  false
	end
	_d.no_dizhu_count=_d.no_dizhu_count+1

	--第三次不叫直接结算并解散房间
	if _d.no_dizhu_count>=3 then
		_d.race_count=0
		settlement(_t_num,0)
	else
		--重新发牌
		for _seat_num,_id in pairs(_d.p_seat_number) do
			-- _init_rate,_init_stake,_seat_num
			nodefunc.send(_id,"dbwg_start_again_msg",_d.init_rate,_d.init_stake,_seat_num)
		end
		print("no di zhu")
		--重新发牌
		new_game(_t_num,true)
	end
end
local function gameover(_t_num)
	print("one round gameover")
end
local function report_and_exit(_t_num)
	print("report")
	if not game_table[_t_num] then
		return false
	end
	change_status(_t_num,"gameover")
	return_table(_t_num)
	nodefunc.send(DATA.mgr_id,"table_finish",DATA.my_id,_t_num)
end

local function next_game(_t_num)
	local _d=game_table[_t_num]
	if not _d then
		return false
	end
	if _d.race_count>_d.cur_race_num then 

		--重新发牌
		new_game(_t_num)

		--新的一局
		for _seat_num,_id in pairs(_d.p_seat_number) do
			--参数：  状态,倒计时
			-- _init_rate,_init_stake,_seat_num
			nodefunc.send(_id,"dbwg_new_game_msg",_d.init_rate,_d.init_stake,
						_seat_num,_d.game_config.round,_d.cur_race_num)
		end

	else
		report_and_exit(_t_num)	
	end
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
		jiao_dizhu(_t_num)
	elseif _status=="jiabei" then
		game_table[_t_num].status=_status
		jiabei_permit(_t_num)
	elseif _status=="cp" then
		game_table[_t_num].status=_status
		chupai_permit(_t_num)
	elseif _status=="settlement" then
		game_table[_t_num].status=_status
		game_table[_t_num].time=gen_settlement_time(_t_num)
		settlementing(_t_num)
	elseif _status=="gameover" then
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
			elseif _value.status=="settlement" then
				_value.time=_value.time-dt 
				if _value.time<=0 then 
					next_game(_t_num)
				end
			end 
		end
		skynet.sleep(dt*100)
	end
end

-- ###_test
function CMD.new_table(_game_config)
	local _t_num=employ_table()
	if not _t_num then 
		return false
	end
	local _data={}
	_data.game_config=_game_config

	_data.time=0
	_data.play_data=normal_ddz.new_game()
	_data.p_info={}
	--玩家进入房间的标记
	_data.players_join_flag={}
	_data.p_seat_number={}
	_data.p_count=0
	_data.p_ready=0

	--都不叫地主的次数
	_data.no_dizhu_count=0

	_data.init_rate=_game_config.init_rate or 1
	_data.init_stake=_game_config.init_stake or 1
	--比赛次数
	_data.race_count=_game_config.race_count or 1
	_data.issue=_game_config.issue

	_data.cur_race_num=0

	game_table[_t_num]=_data

	_data.p_rate={_data.init_rate,_data.init_rate,_data.init_rate}

	change_status(_t_num,"wait_p")

	if DATA.service_config.chat_service then
		_data.chat_room_id = skynet.call(DATA.service_config.chat_service,"lua","create_room")
	end

	return _t_num
end
function CMD.get_free_table_num()
	return #table_list
end

function CMD.destroy()
	run=nil
	skynet.call(node_service,"lua","destroy",base.DATA.my_id)

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
				nodefunc.send(_value.id,"dbwg_join_msg",_data.p_count,_info,_data.chat_room_id)
			end

			--自动准备
			ready(_t_num)

			--此时游戏还没开始 _data.cur_race_num == 0 将会导致错误
			return {result=0,seat_num=_seat_num,p_info=_data.p_info,p_count=_data.p_count,
					rate=_data.init_rate,init_stake=_data.init_stake,
					round=_data.game_config.round,race=1}
		end
	end
	return {result=1000}
end
--###_test 暂时是自动ready
-- function CMD.ready()

-- end
--叫地主
function CMD.jiao_dizhu(_t_num,_seat_num,_rate)
	local _d=game_table[_t_num]
	if not _d or _d.status~="jdz" then 
		if not _d then
			print("jiao_dizhu  ",_t_num,_seat_num,_rate)
		end
		--状态不合法
		return 1002
	end 
	local _status=normal_ddz.jiao_dizhu(_d.play_data,_seat_num,_rate)
	_d.p_jdz[_seat_num]=_rate
	if _status<1000 then
		if _rate>_d.p_jdz_rate then 
			_d.p_jdz_rate=_rate
		end
	else
		return _status
	end
	for _s,_id in pairs(_d.p_seat_number) do
		--参数：   ，当前操作
		nodefunc.send(_id,"dbwg_jdz_msg",_d.play_data.act_list[#_d.play_data.act_list])
	end

	--记录过程数据日志
	PUBLIC.save_process_data_log(_d,_t_num,_seat_num,20,_rate)

	--叫地主失败
	if  _status==-1 then 
		no_dizhu(_t_num)
		return 0
	--继续叫	
	else
		--地主产生
		if _status>0 then
			--status就是地主座位号
			set_dizhu(_t_num,_status)

			-- 准备出牌了
			ready_chupai(_t_num)
			change_status(_t_num,"wait",1,"cp")

			-- change_status(_t_num,"wait",5,"jiabei_nm")

			return 0
		else

			--叫地主中，接下来会转移叫地主权限
			change_status(_t_num,"wait",0.5,"jdz")

		end
	end
	return _status
end


function CMD.jiabei(_t_num,_seat_num,_rate)

	local _d=game_table[_t_num]
	if not _d or _d.status~="jiabei" then
		if not _d then
			print("jiabei ",_t_num,_seat_num,_rate)
		end 	
		return 1002
	end

	--加过倍了
	if _d.p_jiabei[_seat_num] then
		return 1002
	end

	--所有人都加倍
	local _status=normal_ddz.jiabei(_d.play_data,_d.p_rate,_seat_num,_rate)

	_d.p_jiabei[_seat_num]=_rate

	nodefunc.send(_d.p_seat_number[_seat_num],"dbwg_my_jiabei_msg",_d.play_data.act_list[#_d.play_data.act_list])
	--记录过程数据日志
	PUBLIC.save_process_data_log(_d,_seat_num,_rate>0 and 21 or 22)

	if _status==4 then
		--通知所有人 加倍结果
		local _acts={}
		for i=2,0,-1 do
			_acts[#_acts+1]=_d.play_data.act_list[#_d.play_data.act_list-i]
		end
		for _s,_id in pairs(_d.p_seat_number) do
			--参数：加倍人，倍数，我的当前总倍数
			nodefunc.send(_id,"dbwg_jiabei_msg",_acts,_d.p_rate[_s])
		end

		--加倍结束 准备出牌了
		ready_chupai(_t_num)
		change_status(_t_num,"wait",1,"cp")

	end

	return 0

end



function CMD.chupai(_t_num,_seat_num,_type,_cp_list)
	local _d=game_table[_t_num]
	if not _d or _d.status~="cp" or _d.play_data.cur_p~=_seat_num then 
		if not _d then
			print("chupai  ",_t_num,_seat_num)
		end 
		return 1002
	end
	local _status=normal_ddz.chupai(_d.play_data,_seat_num,_type,_cp_list)
	if _status==1 or _status==0 then
		--炸弹加倍
		if _type==13 or _type==14 then
			_d.bomb_count=_d.bomb_count+1 
			_d.p_bomb_count[_seat_num]=_d.p_bomb_count[_seat_num]+1
			for i=1,3 do 
				_d.p_rate[i]=_d.p_rate[i]*2
			end
		end
		if _type~=0 then
			--出牌次数加1
			_d.p_cp_count[_seat_num]=_d.p_cp_count[_seat_num]+1
		end
		for _s_n,_id in pairs(_d.p_seat_number) do
				--参数：act,玩家剩余的牌
			nodefunc.send(_id,"dbwg_cp_msg",_d.play_data.act_list[#_d.play_data.act_list],_d.p_rate[_seat_num])
		end

		--记录过程数据日志
		PUBLIC.save_process_data_log(_d,_t_num,_seat_num,_type,_cp_list)

		if _status==1 then
			settlement(_t_num,_seat_num)
		else
			--出牌中，接下来将转移出牌权限到下一个人
			change_status(_t_num,"wait",gen_pai_act_time(_type),"cp")
		end

		return 0
	end
	return _status
end

function CMD.auto(_t_num,_seat_num,_type)
	local _d=game_table[_t_num]
	if not _d then 
		print("_d  ",_t_num,_seat_num)
		return 1002
	end
	for _s_n,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"dbwg_auto_msg",_seat_num,_type)
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






