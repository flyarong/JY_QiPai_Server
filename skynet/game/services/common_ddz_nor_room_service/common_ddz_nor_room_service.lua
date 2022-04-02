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
require "common_ddz_nor_room_service/common_ddz_nor_room_record_log"

local nor_ddz_base_lib = require "nor_ddz_base_lib"
local nor_ddz_room_lib = require "nor_ddz_room_lib"

local basefunc = require "basefunc"

--房间ID
DATA.my_id = 0

--上级管理者
DATA.mgr_id = 0

--剩余桌子数量
DATA.table_count = 0

--- 抽水力度
DATA.gain_power = 0
--- 是抽水还是放水
DATA.profit_wave_status = nil

DATA.is_auto_profit_ctrl = false

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
DATA.node_service = nil
--空闲桌子编号列表

DATA.table_list = DATA.table_list or {}
local table_list=DATA.table_list

DATA.game_table = DATA.game_table or {}
local game_table=DATA.game_table
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

DATA.ddz_room_data = DATA.ddz_room_data or 
{
	run=true,

	fp_time=2,
	first_cp_cd=25,
	cp_cd=15,
	jdz_cd=10,
	qdz_cd=10,
	jb_cd=10,
	settle_cd=4,
	mz_cd=10,
	zp_cd=10,
	dao_cd=10,
	la_cd=10,
	
}

local D = DATA.ddz_room_data


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
	local _d=game_table[_t_num]
	if not _d then
		return false
	end
	if not _is_again then 
		_d.cur_race=_d.cur_race+1
	else
		_d.re_fapai_num = _d.re_fapai_num + 1
	end

	_d.time=0
	_d.play_data=nor_ddz_room_lib.new_game()
	--叫地主的
	_d.p_jdz_rate=0
	_d.p_rate={_d.init_rate,_d.init_rate,_d.init_rate}
	_d.p_cp_count={0,0,0}
	--结算信息
	_d.s_info={}
	--炸弹次数
	_d.bomb_count=0

	--nil 还没有进行加倍 0-不加倍 2-加倍
	_d.p_jiabei={}

	--玩家的炸弹次数
	_d.p_bomb_count={0,0,0}

	--春天或者反春  1春天  2 反春
	_d.is_chuntian=0

	--玩家叫地主分的情况
	_d.p_jdz={0,0,0}

	_d.ready={0,0,0}
	_d.p_ready=0


	_d.play_data.special_deal_seat=nil
	

	if _d.game_type=="nor_ddz_er" then
		--让牌数量  （二人斗地主模式）
		_d.rangpai_num=1
		_d.qiang_dz_count=0
	end

	if _d.jdz_type=="mld" then

		--闷抓?
		_d.is_men_zhua = 0

		--nil-无 0-不倒不拉 1-倒拉
		_d.dao_la_data={}

		--nil-无  0-不操作  1-是操作
		_d.men_data={}

		--不抓的次数统计
		_d.no_zhua_count=0

		--nil-无 1-已经看了牌
		_d.p_kan_pai={}

	end

	if _is_again then
		change_status(_t_num,"game_begin")
	else
		if _d.cur_race==1 then
			change_status(_t_num,"wait_p")
		else
			change_status(_t_num,"ready")
		end
	end

	--记录游戏开始日志
	PUBLIC.save_race_start_log(_d,_t_num)

end



local function ready(_t_num,_seat_num)
	local _d = game_table[_t_num]

	if _d.ready[_seat_num]==0 then
		_d.ready[_seat_num]=1

		for _s,_id in pairs(_d.p_seat_number) do
			nodefunc.send(_id,"nor_ddz_nor_ready_msg",_seat_num)
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
		nodefunc.send(_id,"nor_ddz_nor_begin_msg",_d.cur_race,nil , _d.re_fapai_num)
	end
	
	change_status(_t_num,"wait",1,"fp")

end

--- 返回哪个座位发nice牌
local function get_nice_pai_pai(_t_num)

	if skynet.getcfg("forbid_ddz_nice_pai") then
		return 0
	end

	local _d = game_table[_t_num]

	--xsyd
	if _d.game_tag == "xsyd" then
		return 0
	end

	---配置的luck_id
	local lock_id_cfg = {}
	for i=1, skynet.getcfg_2number("lucky_id_num",0) do
		lock_id_cfg[ skynet.getcfg("lucky_id_"..i,"") ] = true
	end
	--dump(lock_id_cfg , "-------------- ddz lock_id_cfg")
	local tuoguan_vec = {}
	local player_vec = {}
	local lock_id_seat = nil
	---- 调整nice牌
	for _seat_num,player_id in pairs(_d.p_seat_number) do
		--- 如果是托管
		if not basefunc.chk_player_is_real(player_id) then
			tuoguan_vec[#tuoguan_vec + 1] = _seat_num
		else
			player_vec[#player_vec + 1] = _seat_num
		end
		if not lock_id_seat and lock_id_cfg[player_id] then
			lock_id_seat = _seat_num
		end
	end

	if lock_id_seat then

		return lock_id_seat , (lock_id_seat) % _d.seat_count + 1 , true
	else
		---- 没有自动控制就直接返回，正常发牌
		if not DATA.is_auto_profit_ctrl then
			return 0
		end

		if #tuoguan_vec > 0 then
			-- local random = math.random() * 100

			-- local real_nice_pai_rate = _d.nice_pai_rate > 0 and _d.nice_pai_rate or -_d.nice_pai_rate
			-- local random_vec = _d.nice_pai_rate > 0 and tuoguan_vec or player_vec

			-- if random <= real_nice_pai_rate and #random_vec > 0 then
			-- 	--- do
			-- 	return #random_vec == 1 and random_vec[1] or random_vec[ math.random(#random_vec) ]
			-- end

			--- 如果是放水阶段 , 可以不用给玩家发好牌
			print("----------------------------,DATA.profit_wave_status",DATA.profit_wave_status , _d.game_id)
			if not DATA.profit_wave_status or (DATA.profit_wave_status and DATA.profit_wave_status == "down") then
				print("----------------------down_wave_not_fa_hao_pai",DATA.profit_wave_status , _d.game_id)
				return 0 
			end

			---- 全部用自动好牌控制
			if #player_vec == 0 then
				return 0
			else
				return tuoguan_vec[ math.random(#tuoguan_vec) ] , player_vec[math.random(#player_vec)]
			end
			--return 0

		end
	end

	return 0
end

local function fapai(_t_num)
	local _d = game_table[_t_num]

	local nice_pai_seat_num , laji_pai_seat_num , is_luck_id = get_nice_pai_pai(_t_num)

	-- by lyx: 给玩家发好牌
	local _player_haopai = skynet.call(DATA.service_config.player_protect_service,"lua",
			"query_protect_haopai_param",{
				game_model=_d.game_model,
				game_type=_d.game_type,
				game_id=_d.game_id,
				gain_power = DATA.gain_power,
				profit_status = DATA.profit_wave_status,
			},_d.p_seat_number)

	local dbg_gufing = skynet.getcfg("dev_debug_gufing_fp")

	if not dbg_gufing and _player_haopai then
		
		print("ddz room fapai protect player haopai:",_d.p_seat_number[_player_haopai.nice_pai_seat_num],basefunc.tostring(_player_haopai))			

		-- by lyx: 给玩家发好牌

		_d.play_data.pai=nor_ddz_room_lib.xipai(_d)

		nor_ddz_room_lib.fa_nice_pai_new(_d , 50 + _player_haopai.power * 10 , "up" , _player_haopai.nice_pai_seat_num , _player_haopai.laji_pai_seat_num,true)

		--随机确定出叫地主顺序
		nor_ddz_room_lib.get_dz_candidate(_d)
		
	elseif not dbg_gufing and nice_pai_seat_num ~= 0 and not skynet.getcfg("dev_debug_gufing_fp") then
		_d.play_data.special_deal_seat=nice_pai_seat_num
		
		--- 叫地主的位置
		if is_luck_id then
			nor_ddz_room_lib.fa_nice_pai(_d , nice_pai_seat_num)

			local dz_rate = skynet.getcfg_2number("lock_id_ddz_dz_rate",60)
			local random = math.random() * 100
			if random < dz_rate then
				_d.play_data.dz_candidate=nice_pai_seat_num
			else
				if nor_ddz_room_lib.game_type=="nor_ddz_er" then 
					_d.play_data.dz_candidate = nice_pai_seat_num == 1 and 2 or 1
				else
					local rand_seat = {}
					rand_seat = nice_pai_seat_num == 1 and {2,3} or (nice_pai_seat_num == 2 and {1,3} or {1,2})
					_d.play_data.dz_candidate= rand_seat[ math.random(1,2) ]
				end
			end

		else
			
			local is_fa_haopai = nor_ddz_room_lib.fa_nice_pai_new(_d , DATA.gain_power , DATA.profit_wave_status , nice_pai_seat_num , laji_pai_seat_num)

			
			--- 如果是最高抽水力度
			if is_fa_haopai and DATA.profit_wave_status == "up" and DATA.gain_power == 100 then
				if math.random(100) < skynet.getcfg_2number("ddz_up_wave_nice_seat_dz_gl" , 80) then
					-- 给好牌位置叫地主
					_d.play_data.dz_candidate = nice_pai_seat_num
				else
					---随机地主
			 		_d.play_data.dz_candidate = math.random(_d.seat_count) 
				end
			else
				---随机地主
			 	_d.play_data.dz_candidate = math.random(_d.seat_count) 
			end
		end

		_d.play_data.cur_p=_d.play_data.dz_candidate

	else
		_d.play_data.pai=nor_ddz_room_lib.xipai(_d)

		nor_ddz_room_lib.fapai(_d,17)

		--随机确定出叫地主顺序
		nor_ddz_room_lib.get_dz_candidate(_d)
	end

	-- 发托管牌 (by lyx)
	for _seat_num,_id in pairs(_d.p_seat_number) do
		if not basefunc.chk_player_is_real(_id) then
			nodefunc.send(_id,"nor_ddz_nor_notify_tuoguan_pai",_d.play_data,DATA.profit_wave_status)
		end
	end
	--mld 先不发牌
	if _d.jdz_type=="mld" then
		for _seat_num,_id in pairs(_d.p_seat_number) do
			nodefunc.send(_id,"nor_ddz_nor_pai_msg",nil,D.fp_time)
		end
		change_status(_t_num,nil,D.fp_time,"mld_men")
	else
		for _seat_num,_id in pairs(_d.p_seat_number) do
			nodefunc.send(_id,"nor_ddz_nor_pai_msg",_d.play_data[_seat_num],D.fp_time)
		end	
		change_status(_t_num,nil,D.fp_time,"jdz")
	end

	

	PUBLIC.save_fapai_log(_d,_t_num)
end



local function jiao_dizhu(_t_num)
	local _d = game_table[_t_num]
	for _seat_num,_id in pairs(_d.p_seat_number) do
		--参数：  状态,时间，下一个叫地主权限拥有者，
		nodefunc.send(_id,"nor_ddz_nor_jdz_permit",D.jdz_cd,_d.play_data.cur_p)
		
	end

	--记录获取权限的时间日志
	PUBLIC.save_ddz_process_get_permit_time(_d,_t_num)
end



local function set_dizhu(_t_num,_dizhu,_men)
	local _d=game_table[_t_num]

	nor_ddz_room_lib.set_dizhu(_d,_dizhu,_d.jdz_type=="mld")

	--农民的座位
	_d.nongmin={}

	local nm1=1
	if nm1==_d.play_data.dizhu then
		nm1=nm1+1
	end
	_d.nongmin[1]=nm1
	if _d.seat_count ==3 then
		local nm2=nm1+1
		if nm2==_d.play_data.dizhu then
			nm2=nm2+1
		end
		_d.nongmin[2]=nm2
	end
	
	if _d.jdz_type == "mld" then
		_d.is_men_zhua = _men
	end

	for _seat_num,_id in pairs(_d.p_seat_number) do
		if _d.game_type=="nor_ddz_er" then
			_d.p_rate[_seat_num]=_d.p_rate[_seat_num]+_d.qiang_dz_count 
		end
		--参数：  状态,地主
		nodefunc.send(_id,"nor_ddz_nor_dizhu_msg",_d.play_data.dizhu,
						_d.play_data.dz_pai,_d.p_rate[_seat_num],_d.rangpai_num,_men)
	end

end

------------------------------------------------------------------------------------------------
-------------------------------------MLD----------------------------------------------------
------------------------------------------------------------------------------------------------

--看自己的牌
local function kan_my_pai(_t_num,_seat_num)
	local _d = game_table[_t_num]
	
	if _d.p_kan_pai[_seat_num] then
		return
	end

	_d.p_kan_pai[_seat_num]=1

	nodefunc.send(_d.p_seat_number[_seat_num],"nor_ddz_mld_kan_my_pai_msg",_d.play_data[_seat_num].pai)

end

--开始出牌
local function start_cp(_t_num)
	local _d = game_table[_t_num]

	kan_my_pai(_t_num,1)
	kan_my_pai(_t_num,2)
	kan_my_pai(_t_num,3)
	
	-- 接把 地主牌 插入到手牌里
	nor_ddz_base_lib.fapai_dizhu(_d.play_data.dz_pai,_d.play_data[_d.play_data.dizhu])

	for _s,_id in pairs(_d.p_seat_number) do

		--发送地主牌
		if (not basefunc.chk_player_is_real(_id)) or _d.is_men_zhua<1 or
			(_d.is_men_zhua>0 and _s==_d.play_data.dizhu) then
			nodefunc.send(_id,"nor_ddz_mld_dizhu_pai_msg",_d.play_data.dz_pai)
		else
			nodefunc.send(_id,"nor_ddz_mld_dizhu_pai_msg")
		end

	end

	_d.play_data.cur_p=_d.play_data.dizhu
	change_status(_t_num,"wait",1,"cp")
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
		type = nor_ddz_base_lib.other_type.mld_men,
		p = _d.play_data.cur_p,
		rate = _d.p_rate[_d.play_data.cur_p],
	}
	_d.play_data.act_list[#_d.play_data.act_list+1] = act

	for _s,_id in pairs(_d.p_seat_number) do
		act.rate = _d.p_rate[_s]
		nodefunc.send(_id,"nor_ddz_mld_men_msg",act)
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
		type = _dao_opt>0 and nor_ddz_base_lib.other_type.mld_dao or nor_ddz_base_lib.other_type.mld_bd,
		p = _seat_num,
		rate = _d.p_rate[_seat_num],
	}
	_d.play_data.act_list[#_d.play_data.act_list+1] = act

	_d.dao_la_data[_seat_num]=_dao_opt

	local dao_num = 0
	local dao_opt = 0

	for _s,_id in pairs(_d.p_seat_number) do
		act.rate = _d.p_rate[_s]
		nodefunc.send(_id,"nor_ddz_mld_dao_msg",act)

		if _d.dao_la_data[_s] then
			dao_num = dao_num + 1
			if _d.dao_la_data[_s] > 0 then
				dao_opt = _d.dao_la_data[_s]
			end
		end

	end

	if dao_num > 1 then

		--有人倒
		if dao_opt > 0 then
			change_status(_t_num,"wait",1,"mld_jb")
		else
			start_cp(_t_num)
		end

	end

	--记录过程数据日志
	PUBLIC.save_process_data_log(_d,_t_num,_seat_num,31-_dao_opt)

	return 0

end

--拉 0-不拉 1-拉
local function la(_t_num,_seat_num,_la_opt)
	local _d = game_table[_t_num]

	if _la_opt>0 then

		if _d.dao_la_data[_d.nongmin[1]]>0 then
			_d.p_rate[_d.nongmin[1]] = _d.p_rate[_d.nongmin[1]] * 2
		end

		if _d.dao_la_data[_d.nongmin[2]]>0 then
			_d.p_rate[_d.nongmin[2]] = _d.p_rate[_d.nongmin[2]] * 2
		end

		_d.p_rate[_d.play_data.dizhu]=_d.p_rate[_d.nongmin[1]]+_d.p_rate[_d.nongmin[2]]

	end

	_d.play_data.act_list[#_d.play_data.act_list+1] = act
	local act = {
		type = _la_opt>0 and nor_ddz_base_lib.other_type.mld_la or nor_ddz_base_lib.other_type.mld_bl,
		p = _seat_num,
		rate = _d.p_rate[_seat_num],
	}
	_d.play_data.act_list[#_d.play_data.act_list+1] = act

	_d.dao_la_data[_seat_num]=_la_opt

	for _s,_id in pairs(_d.p_seat_number) do
		act.rate = _d.p_rate[_s]
		nodefunc.send(_id,"nor_ddz_mld_la_msg",act)
	end

	start_cp(_t_num)

	--记录过程数据日志
	PUBLIC.save_process_data_log(_d,_t_num,_seat_num,33-_la_opt)

	return 0

end


local function mld_men_permit(_t_num)
	local _d = game_table[_t_num]

	if _d.no_zhua_count > 1 then
		
		--必须闷 走正常流程
		-- must_men_zhua(_t_num)
		-- return
		_d.is_must_men = true
	end

	local cd = D.mz_cd
	--闷抓 or 抓牌
	if _d.men_data[_d.play_data.cur_p] then
		cd = D.zp_cd
	end

	for _seat_num,_id in pairs(_d.p_seat_number) do
		--参数：  状态,时间，下一个叫地主权限拥有者，
		nodefunc.send(_id,"nor_ddz_mld_jdz_permit",cd,_d.play_data.cur_p,_d.is_must_men)
	end
	
	--记录获取权限的时间日志
	PUBLIC.save_ddz_process_get_permit_time(_d,_t_num)
end


local function mld_jb_permit(_t_num)
	local _d = game_table[_t_num]

	--没人进行倒和拉 则是农民开始倒
	if not next(_d.dao_la_data) then
		_d.play_data.cur_p = 4
	else
		_d.play_data.cur_p = _d.play_data.dizhu
	end

	local cd = D.dao_cd
	--倒 or 拉
	if _d.play_data.dizhu == _d.play_data.cur_p then
		cd = D.la_cd
	end

	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nor_ddz_mld_jiabei_permit",cd,_d.play_data.cur_p)
	end

	--记录获取权限的时间日志
	PUBLIC.save_ddz_process_get_permit_time(_d,_t_num)
end

------------------------------------------------------------------------------------------------
-----------------------------------------MLD-------------------------------------------------
------------------------------------------------------------------------------------------------


local function er_qiangdizhu(_t_num)
	local _d = game_table[_t_num]
	
	for _seat_num,_id in pairs(_d.p_seat_number) do
		--参数：  状态,时间，下一个叫地主
		nodefunc.send(_id,"nor_ddz_er_qdz_permit",D.qdz_cd,_d.play_data.cur_p)
	end

end
--加倍
local function jiabei_permit(_t_num)
	local _d = game_table[_t_num]
	_d.play_data.cur_p=6
	for _seat_num,_id in pairs(_d.p_seat_number) do
		--参数：  状态,倒计时_d.status
		nodefunc.send(_id,"nor_ddz_nor_jiabei_permit",D.jb_cd,_d.play_data.cur_p)
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
	local _is_must=nor_ddz_base_lib.is_must_chupai(_d.play_data.act_list,_d.play_data.cur_p)
	local _cd = _d.p_cp_count[_d.play_data.cur_p] < 1 and D.first_cp_cd or D.cp_cd
	for _seat_num,_id in pairs(_d.p_seat_number) do
		--参数：  状态，时间，出牌权限拥有人
		nodefunc.send(_id,"nor_ddz_nor_cp_permit",_cd,
						_d.play_data.cur_p,_is_must)
	end

	--记录获取权限的时间日志
	PUBLIC.save_ddz_process_get_permit_time(_d,_t_num)
end

--产生癞子
local function create_lz(_t_num)
	local _d = game_table[_t_num]

	local lz=math.random(3,15)
	_d.laizi=lz
	for _seat_num,_id in pairs(_d.p_seat_number) do
		--参数：  状态,地主
		nodefunc.send(_id,"nor_ddz_nor_laizi_msg",lz)
	end
	ready_chupai(_t_num)
	change_status(_t_num,"wait",3.5,"cp")
end

--根据托管情况判断是否需要包赔
local function check_baopei(_t_num,_winner)
	local _d=game_table[_t_num]
	if (_winner==5 or _winner==4) and _d.game_type~="nor_ddz_er" then
		local nm1=_d.nongmin[1]
		local nm2=_d.nongmin[2]
		--如果其中一个农民有托管  则包赔 如果两个都托管 则正常
		if _d.p_auto[nm1]==1 and (not _d.p_auto[nm2] or _d.p_auto[nm2]==0) then
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
		elseif (not _d.p_auto[nm1] or _d.p_auto[nm1]==0) and _d.p_auto[nm2]==1 then
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

-- 结算 计算倍率和正常的胜负积分
local function settlement(_t_num,_winner)
	print("_winner:", _winner)
	local _d=game_table[_t_num]

	_d.s_info.award={}
	_d.s_info.lose_surplus={0,0,0}
	_d.s_info.p_rate={}
	--都不叫地主 解散房间
	if _winner==0 then
		_d.s_info.winner=0
		for _i=1,_d.seat_count do 
			_d.s_info.award[_i]=0
		end	
	--地主赢了
	elseif _winner==_d.play_data.dizhu then
		_d.s_info.winner=5
		--春天判定
		local _count=_d.p_cp_count[1]+_d.p_cp_count[2]+_d.p_cp_count[3]
		if _count==_d.p_cp_count[_d.play_data.dizhu] then 
			_d.is_chuntian=1 
			for i=1,_d.seat_count do 
				_d.p_rate[i]=_d.p_rate[i]*2
			end
		end

		nor_ddz_room_lib.fix_rate(_d)
		local dz_award = 0
		for _i=1,_d.seat_count do 
			if _i ~= _d.play_data.dizhu then
				_d.s_info.award[_i]=-_d.p_rate[_i]*_d.init_stake
				dz_award = dz_award - _d.s_info.award[_i]
			end
		end
		_d.s_info.award[_d.play_data.dizhu]=dz_award
	--农民赢了
	else
		_d.s_info.winner=4
		--反春判定
		if _d.p_cp_count[_d.play_data.dizhu]==1 then
			_d.is_chuntian=2 
			for _i=1,_d.seat_count do 
				_d.p_rate[_i]=_d.p_rate[_i]*2
			end
		end
		nor_ddz_room_lib.fix_rate(_d)
		local dz_award = 0
		for _i=1,_d.seat_count do 
			if _i ~= _d.play_data.dizhu then
				_d.s_info.award[_i]=_d.p_rate[_i]*_d.init_stake
				dz_award = dz_award - _d.s_info.award[_i]
			end
		end
		_d.s_info.award[_d.play_data.dizhu]=dz_award
	end
	
	if _d.table_config and _d.table_config.game_config and _d.table_config.game_config.baopei==1 then
		--检测包赔情况
		check_baopei(_t_num,_d.s_info.winner)
	end
	--赢封顶
	if _d.table_config and _d.table_config.game_config and _d.table_config.game_config.yingfengding==1 then
		local is_fd=false
		--农民赢了
		if _d.s_info.winner==4 then
			local all_max_win=0
			for k,v in pairs(_d.s_info.award) do
				if v>0 then
					local max_win=nodefunc.call(_d.p_seat_number[k],"nor_ddz_nor_get_yingfengding_score",v)
					if v>max_win then
						_d.s_info.award[k]=max_win
						--用以记录具体多少钱
						_d.s_info.yingfengding_data=_d.s_info.yingfengding_data or {0,0,0}
						_d.s_info.yingfengding_data[k]=max_win
						
					end
					all_max_win=all_max_win+_d.s_info.award[k]
				end
			end
			_d.s_info.award[_d.play_data.dizhu]=-all_max_win
		--地主赢了	
		elseif _d.s_info.winner==5 then
			local all_max_win=0
			local max_win=nodefunc.call(_d.p_seat_number[_d.play_data.dizhu],"nor_ddz_nor_get_yingfengding_score"
											,_d.s_info.award[_d.play_data.dizhu])
			max_win=-max_win
			for k,v in pairs(_d.s_info.award) do
				if v<0 then
					if v<max_win then
						_d.s_info.award[k]=max_win
						--用以记录具体多少钱
						_d.s_info.yingfengding_data=_d.s_info.yingfengding_data or {0,0,0}
						_d.s_info.yingfengding_data[k]=max_win
					end
					all_max_win=all_max_win+_d.s_info.award[k]
				end
			end
			_d.s_info.award[_d.play_data.dizhu]=-all_max_win
		end
	end
	
	--计算剩余的牌 --*******************
	_d.remain_pai={}
	for _i=1,3 do
		local _pai=nor_ddz_base_lib.get_pai_list_by_map(_d.play_data[_i].pai)
		if _pai and #_pai>0 then 
			_d.remain_pai[#_d.remain_pai+1]={p=_i,pai=_pai}
		end
		_d.s_info.p_rate[_i]=_d.p_rate[_i]
	end
	--*******************
	--准备结算，其实已经结算了
	change_status(_t_num,"wait",1.5,"settlement")

end


--真正的扣钱和加钱 （考虑不够赔的情况）
local function calculate_score(_t_num)
	local _d = game_table[_t_num]
	--地主赢了
	if _d.s_info.winner==5 then
		--扣农民的钱 得到实际扣除的钱
		local real_deduct=0
		local lose_surplus=0
		for _,_pos in ipairs(_d.nongmin) do
			if _d.s_info.award[_pos]~=0 then
				local rd = nodefunc.call(_d.p_seat_number[_pos],"nor_ddz_nor_modify_score"
												,_d.s_info.award[_pos])
				_d.s_info.lose_surplus[_pos] = rd - _d.s_info.award[_pos]
				real_deduct=real_deduct+rd
				lose_surplus=lose_surplus+_d.s_info.lose_surplus[_pos]
				_d.s_info.award[_pos]=rd
				if _d.table_config 
					and _d.table_config.game_config 
					and _d.table_config.game_config.yingfengding==1 
					and _d.s_info.yingfengding_data 
					and _d.s_info.yingfengding_data[_pos]~=0 then
						if rd>_d.s_info.yingfengding_data[_pos] then
							_d.s_info.yingfengding_data[_pos]=nil
						end
				end
			end
		end
		_d.s_info.award[_d.play_data.dizhu]=-real_deduct
		_d.s_info.lose_surplus[_d.play_data.dizhu]=-lose_surplus
		nodefunc.call(_d.p_seat_number[_d.play_data.dizhu],"nor_ddz_nor_modify_score"
							,_d.s_info.award[_d.play_data.dizhu])
		if _d.table_config 
			and _d.table_config.game_config 
			and _d.table_config.game_config.yingfengding==1 
			and _d.s_info.yingfengding_data then
				for k,v in pairs(_d.s_info.yingfengding_data) do
					_d.s_info.yingfengding=_d.s_info.yingfengding or {0,0,0}
					_d.s_info.yingfengding[_d.play_data.dizhu]=1
					break
				end
		end
		
	--农民赢了
	elseif _d.s_info.winner==4 then
		--扣地主的钱 得到实际扣除的钱
		local real_deduct=nodefunc.call(_d.p_seat_number[_d.play_data.dizhu],"nor_ddz_nor_modify_score"
											,_d.s_info.award[_d.play_data.dizhu])
		
		_d.s_info.lose_surplus[_d.play_data.dizhu] = real_deduct-_d.s_info.award[_d.play_data.dizhu]
		_d.s_info.award[_d.play_data.dizhu]=real_deduct

		real_deduct=-real_deduct
		if _d.game_type=="nor_ddz_er" then
			_d.s_info.award[_d.nongmin[1]]=real_deduct
		else
			--分配给农民 --如果为奇数 先出完牌的人获得更多
			local fp1=0
			local fp2=0
			--判断是否有人托管 有全部加给没有托管的人
			if _d.s_info.auto_baopei_pos then
				 for _,_pos in ipairs(_d.nongmin) do
				 	if _d.s_info.auto_baopei_pos~=_pos then
				 		_d.s_info.award[_pos]=real_deduct
				 		_d.s_info.lose_surplus[_pos]=-_d.s_info.lose_surplus[_d.play_data.dizhu]
				 		break
				 	end
				 end	
			else

				-- 地主的钱 没有破产
				if real_deduct >= _d.s_info.award[_d.nongmin[1]] + _d.s_info.award[_d.nongmin[2]] then
					_d.s_info.lose_surplus[_d.nongmin[1]]=0
					_d.s_info.lose_surplus[_d.nongmin[2]]=0
				else
					-- 地主的钱 破产

					-- 有赢封顶
					if _d.s_info.yingfengding_data then

						local r1 = _d.s_info.award[_d.nongmin[1]]
						local r2 = _d.s_info.award[_d.nongmin[2]]

						fp1 = math.ceil(real_deduct * (r1/(r1+r2)))
						fp2 = real_deduct - fp1
					
						_d.s_info.award[_d.nongmin[1]]=fp1
						_d.s_info.award[_d.nongmin[2]]=fp2

						local lp = fp1/real_deduct
						_d.s_info.lose_surplus[_d.nongmin[1]]=math.ceil((-_d.s_info.lose_surplus[_d.play_data.dizhu])*lp)
						_d.s_info.lose_surplus[_d.nongmin[2]]=math.ceil((-_d.s_info.lose_surplus[_d.play_data.dizhu])*(1-lp))

					else

						local r1 = _d.s_info.p_rate[_d.nongmin[1]]
						local r2 = _d.s_info.p_rate[_d.nongmin[2]]

						fp1=math.ceil(real_deduct/2)
						fp2=real_deduct-fp1
						if r1 ~= r2 then
							fp1 = math.ceil(real_deduct * (r1/(r1+r2)))
							fp2 = real_deduct - fp1
						end
						_d.s_info.award[_d.nongmin[1]]=fp1
						_d.s_info.award[_d.nongmin[2]]=fp2

						local lp = fp1/real_deduct
						_d.s_info.lose_surplus[_d.nongmin[1]]=math.ceil((-_d.s_info.lose_surplus[_d.play_data.dizhu])*lp)
						_d.s_info.lose_surplus[_d.nongmin[2]]=math.ceil((-_d.s_info.lose_surplus[_d.play_data.dizhu])*(1-lp))

					end

				end

			end
		end

		--加钱
		for _,_pos in ipairs(_d.nongmin) do
			if _d.s_info.award[_pos] and _d.s_info.award[_pos]>0 then

				nodefunc.call(_d.p_seat_number[_pos],"nor_ddz_nor_modify_score",_d.s_info.award[_pos])
				if _d.table_config 
					and _d.table_config.game_config 
					and _d.table_config.game_config.yingfengding==1 
					and _d.s_info.yingfengding_data 
					and _d.s_info.yingfengding_data[_pos]~=0 then
						if _d.s_info.award[_pos]<_d.s_info.yingfengding_data[_pos] then
							_d.s_info.yingfengding_data[_pos]=nil
						else
							_d.s_info.yingfengding=_d.s_info.yingfengding or {0,0,0}
							_d.s_info.yingfengding[_pos]=1
						end
				end
			end
		end
	end
	if _d.s_info then
		_d.s_info.yingfengding_data	=nil
	end
end



local function next_game(_t_num)
	local _d=game_table[_t_num]
	if not _d then
		return false
	end

	if _d.race_count>_d.cur_race and not _d.is_break_game then 

		--重新发牌
		new_game(_t_num)

		--延迟
		skynet.timeout(D.settle_cd*100,function ()

			local _d=game_table[_t_num]
			if not _d then
				return false
			end

			--新的一局
			for _seat_num,_id in pairs(_d.p_seat_number) do
				nodefunc.send(_id,"nor_ddz_nor_next_game_msg",_d.cur_race)
			end

		end)

	else

		change_status(_t_num,nil,D.settle_cd,"gameover")
	end
end




--结算ok 通知给玩家
local function settlement_finish(_t_num)
	
	-- 计算真实的分数	
	calculate_score(_t_num)

	local _d = game_table[_t_num]

	local log_id = PUBLIC.save_race_over_log(_d,_t_num)

	local score_data = {}

	local is_over = false
	if _d.race_count==_d.cur_race or _d.is_break_game then
		is_over = true
	end

	--- 搜集所有的变化信息
	for _seat_num,_id in pairs(_d.p_seat_number) do
		score_data[_seat_num] ={score=_d.s_info.award[_seat_num],lose_surplus=_d.s_info.lose_surplus[_seat_num]}
	end

	-- 给每个人发 变化通知消息
	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nor_ddz_nor_score_change_msg",score_data)
	end

	--通知
	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nor_ddz_nor_settlement_msg",
						_d.s_info,
						_d.remain_pai,
						_d.p_jiabei,
						_d.p_jdz,
						_d.bomb_count,
						_d.p_bomb_count,
						_d.is_chuntian,
						_d.p_rate[_seat_num],
						is_over,
						log_id
						)
		--score_data[_seat_num] =_d.s_info.award[_seat_num]
	end

	-- by lyx: 汇报 玩家 保护数据
	local _protect_data = {}
	for _seat,_pid in pairs(_d.p_seat_number) do
		_protect_data[_pid] = _d.s_info.award[_seat]
	end
	skynet.call(DATA.service_config.player_protect_service,"lua",
			"udpate_protect_data",{
				game_model=_d.game_model,
				game_type=_d.game_type,
				game_id=_d.game_id,
				gain_power = DATA.gain_power,
				profit_status = DATA.profit_wave_status,
			},_protect_data)

	next_game(_t_num)

end

-- ----练习场 award 胜利为1 失败为 0
-- local function settlement_for_lianxichang(_t_num)
-- 	local _d = game_table[_t_num]
-- 	--地主赢了
-- 	if _d.s_info.winner==5 then
-- 		for i=1,_d.seat_count do
-- 			_d.s_info.award[i]=0
-- 		end
-- 		_d.s_info.award[_d.play_data.dizhu]=1
-- 	elseif _d.s_info.winner==4 then
-- 		for i=1,_d.seat_count do
-- 			_d.s_info.award[i]=1
-- 		end
-- 		_d.s_info.award[_d.play_data.dizhu]=0
-- 	else
-- 		for i=1,_d.seat_count do
-- 			_d.s_info.award[i]=0
-- 		end
-- 	end
-- end
--结算中 通知给玩家
local function gameover(_t_num)

	local _d = game_table[_t_num]

	--通知
	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nor_ddz_nor_gameover_msg",{})
	end

	nodefunc.call(DATA.mgr_id,"table_finish",DATA.my_id,_t_num)

	return_table(_t_num)

	nodefunc.send(DATA.mgr_id,"return_table",DATA.my_id,_t_num)

end



-- ###_test0809 取消当前游戏
local function gamecancel(_t_num)
	local _d = game_table[_t_num]

	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nor_ddz_nor_gamecancel_msg")
	end

	-- 取消的时候，不记录，PUBLIC.save_race_over_log(_d,_t_num)

	nodefunc.call(DATA.mgr_id,"table_finish",DATA.my_id,_t_num)

	return_table(_t_num)

	nodefunc.send(DATA.mgr_id,"return_table",DATA.my_id,_t_num)

end



--没有人做地主  ###_test
local function no_dizhu(_t_num)
	local _d=game_table[_t_num]
	if not _d then 
		return  false
	end

	print("no di zhu")
	_d.no_dizhu_count=_d.no_dizhu_count+1

	local fg = _d.model_name == "friendgame"

	--第10次不叫直接结算并解散房间
	if _d.no_dizhu_count>10 and not fg then

		_d.race_count=0
		settlement(_t_num,0)

	else

		--重新发牌
		for _seat_num,_id in pairs(_d.p_seat_number) do
			nodefunc.send(_id,"nor_ddz_nor_start_again_msg",
								_d.init_rate,_d.init_stake,_seat_num)
		end

		--重新发牌
		new_game(_t_num,true)

	end
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
	elseif _status=="fp" then 
		game_table[_t_num].status=_status
		fapai(_t_num)
	elseif _status=="jdz" then
		game_table[_t_num].status=_status
		jiao_dizhu(_t_num)
	elseif _status=="mld_men" then
		game_table[_t_num].status=_status
		mld_men_permit(_t_num)
	elseif _status=="mld_jb" then
		game_table[_t_num].status=_status
		mld_jb_permit(_t_num)
	elseif _status=="jiabei" then
		game_table[_t_num].status=_status
		jiabei_permit(_t_num)
	elseif _status=="er_qiangdizhu" then
		game_table[_t_num].status=_status
		er_qiangdizhu(_t_num)
	elseif _status=="create_lz" then
		game_table[_t_num].status=_status
		create_lz(_t_num)
	elseif _status=="cp" then
		game_table[_t_num].status=_status
		chupai_permit(_t_num)
	elseif _status=="settlement" then
		game_table[_t_num].status=_status
		settlement_finish(_t_num)
	elseif _status=="gameover" then
		game_table[_t_num].status=_status
		gameover(_t_num)
	elseif _status=="gamecancel" then		-- 房间 还未开始就解散，没有大结算消息
		game_table[_t_num].status=_status
		gamecancel(_t_num)
	end 
end

change_status = _impl_change_status


local dt=0.5
local function update()
	while D.run do
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
--		baopei   	1/0 是否包赔
--		jiabei 		1/0 是否加倍
-- 参数 _env ：
--	game_id		 游戏 id ，用于记录日志
--	back_money_cmd	备用的金币访问 cmd ，参数： _userId,_score
function CMD.new_table(_table_config,_env)
	local _t_num=employ_table()
	if not _t_num then 
		return false
	end
	local _d={}

	if DATA.game_type=="nor_ddz_nor" then
		_d.jdz_type="nor"
		if _table_config and _table_config.jdz_type then
			_d.jdz_type=_table_config.jdz_type
		end
	else
		_d.jdz_type="nor"
	end

	_d.table_config=_table_config

	_d.time=0
	_d.play_data={}
	_d.p_info={}
	--玩家进入房间的标记
	_d.players_join_flag={}
	_d.p_seat_number={}
	_d.p_count=0

	--都不叫地主的次数
	_d.no_dizhu_count=0
	--游戏类型  0为 练习场  1为钻石场
	--_d.game_model=_game_config.game_model or 0 

	_d.game_model = DATA.game_model

	_d.init_rate=_table_config.game_config.init_rate or 1
	_d.init_stake=_table_config.game_config.init_stake or 1
	_d.max_rate=_table_config.game_config.feng_ding

	_d.seat_count = GAME_TYPE_SEAT[DATA.game_type] or 3
	--print(_table_config.game_config.seat_count)
	--print("!!!!seat_count seat_count ".._d.seat_count)
	--比赛次数
	_d.race_count=_table_config.game_config.race_count or 1

	_d.game_tag = _table_config.game_tag


	---add by wss 
	--- 重发牌次数
	_d.re_fapai_num = 0

	--候选人类型
	-- _d.candidate_type=_table_config.game_config.candidate_type or 0

	_d.cur_race=0

	_d.model_name = assert(_table_config.model_name)
	_d.game_type = assert(_table_config.game_type)
	_d.game_id = assert(_env.game_id)

	_d.back_money_cmd = _table_config.back_money_cmd

	--- 自己人好牌概率
	_d.nice_pai_rate = _table_config.nice_pai_rate or 0

	_d.p_auto={}

	game_table[_t_num]=_d

	_d.p_rate={_d.init_rate,_d.init_rate,_d.init_rate}

	new_game(_t_num)

	--###_test  目前是默认创建  可以考虑根据条件创建 比如（根据房卡场等来默认创建）
	if DATA.service_config.chat_service then
		_d.chat_room_id = skynet.call(DATA.service_config.chat_service,"lua","create_room")
	end

	return _t_num
end


function CMD.get_free_table_num()
	return #table_list
end


function CMD.destroy()
	--- 注销 信号
	--skynet.send(DATA.service_config.game_profit_manager,"lua", 
	--	"unregister_msg" , DATA.my_id, "on_gain_power_change" )

	----  向新消息通知中心撤销
	skynet.send( DATA.service_config.msg_notification_center_service,"lua", 
			"delete_msg_listener" , "on_gain_power_change" ,  DATA.my_id , false )

	D.run=nil
   	nodefunc.destroy(DATA.my_id)
	skynet.exit()
end


function CMD.join(_t_num,_p_id,_info)

	local _d=game_table[_t_num] 
	if not _d or _d.p_count>2 or _d.status~="wait_p" or _d.players_join_flag[_p_id] then
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
			jdz_type=_d.jdz_type
		}
	--通知其他人 xxx 加入房间
	for _,_value in pairs(_d.p_info) do
		if _value.id~=_p_id then
			nodefunc.send(_value.id,"nor_ddz_nor_join_msg",_info)
		else
			nodefunc.send(_value.id,"nor_ddz_nor_join_msg",nil,my_join_return)
		end
	end

	return 0

end


-- ###_test0809 游戏没开始的时候退出房间
function CMD.player_exit_game(_t_num,_seat_num)
	local _d = game_table[_t_num]
	
	if not _d then 
		return 1002
	end

	-- 向所有玩家 发消息
	for _s,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nor_ddz_nor_player_exit_msg",_seat_num)
	end

	-- 清理自己的数据
	_d.players_join_flag[_d.p_seat_number[_seat_num]] = nil
	_d.ready[_seat_num]=0
	_d.p_ready = _d.p_ready - 1
	_d.p_seat_number[_seat_num] = nil
	_d.p_count = _d.p_count-1

	return 0
end

-- ###_test0809 游戏没开始时，取消当前游戏，不结算
function CMD.cancel_game(_t_num)
	local _d = game_table[_t_num]

	if not _d or "wait_p" ~= _d.status then
		return 1002
	end

	change_status(_t_num,"gamecancel")
	
	return 0
end

-- ###_test0809 游戏进行中，强制结算，结束
function CMD.break_game(_t_num)
	local _d = game_table[_t_num]

	if not _d or "gameover" == _d.status then
		return 1002
	end

	-- 标记为 中途结束
	_d.is_break_game = true

	if "ready" == _d.status then
		change_status(_t_num,"gameover")
	elseif "settlement" ~= _d.status then
		_d.is_break_race = _d.cur_race
		
		settlement(_t_num,0)

	end

	return 0
end

function CMD.force_break_game(_t_num)
  return CMD.break_game(_t_num)
end

-- 超时解散游戏
function CMD.over_time_cancel_game(_t_num)
	local _d = game_table[_t_num]

	if not _d then 
		return 1002
	end

	if "wait_p" == _d.status then
		CMD.cancel_game(_t_num)
	else
		CMD.break_game(_t_num)
	end

end


function CMD.ready(_t_num,_seat_num)
	ready(_t_num,_seat_num)

	return {result=0}
end

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
	local _status=nor_ddz_room_lib.jiao_dizhu(_d,_seat_num,_rate)
	if _status>999 then
		return _status
	end
	for _s,_id in pairs(_d.p_seat_number) do
		--参数：   ，当前操作
		nodefunc.send(_id,"nor_ddz_nor_jdz_msg",_d.play_data.act_list[#_d.play_data.act_list])
	end

	--记录过程数据日志
	PUBLIC.save_process_data_log(_d,_t_num,_seat_num,20,_rate)

	--叫地主失败
	if _status==-1 then 
		no_dizhu(_t_num)
		return 0
	--继续叫	
	else
		--地主产生
		if _status>0 then
			if _d.game_type=="nor_ddz_er" then

				if _d.play_data.cur_p==_d.play_data.dz_candidate then
					local dizhu=1
					if _d.play_data.cur_p==1 then
						dizhu=2
					end
					set_dizhu(_t_num,dizhu)
					--切换到出牌
					change_status(_t_num,"wait",1,"cp")
				else
					change_status(_t_num,"wait",1,"er_qiangdizhu")
				end

			else
				--status就是地主座位号
				set_dizhu(_t_num,_status)
				
				--地主产生了，进行加倍
				if _d.table_config.game_config.jia_bei==1 then
					change_status(_t_num,"wait",1,"jiabei")
				else
					if _d.game_type == "nor_ddz_lz" then
						change_status(_t_num,"wait",1,"create_lz")
					else
						ready_chupai(_t_num)
						change_status(_t_num,"wait",1,"cp")
					end
				end
			end

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
	local _status=nor_ddz_room_lib.jiabei(_d.play_data,_d.p_rate,_seat_num,_rate)

	_d.p_jiabei[_seat_num]=_rate

	nodefunc.send(_d.p_seat_number[_seat_num],"nor_ddz_nor_my_jiabei_msg",_d.play_data.act_list[#_d.play_data.act_list])
	
	--记录过程数据日志
	PUBLIC.save_process_data_log(_d,_t_num,_seat_num,_rate>0 and 21 or 22)

	if _status==4 then
		--通知所有人 加倍结果
		local _acts={}
		for i=2,0,-1 do
			_acts[#_acts+1]=_d.play_data.act_list[#_d.play_data.act_list-i]
		end
		for _s,_id in pairs(_d.p_seat_number) do
			--参数：加倍人，倍数，我的当前总倍数
			nodefunc.send(_id,"nor_ddz_nor_jiabei_msg",_acts,_d.p_rate[_s])
		end

		if _d.game_type == "nor_ddz_lz" then
			change_status(_t_num,"wait",1,"create_lz")		
		else
			--加倍结束 准备出牌了
			ready_chupai(_t_num)
			change_status(_t_num,"wait",1,"cp")
		end

	end

	return 0
end



------------------------------------------------------------------------------------------------
-----------------------------------------MLD-------------------------------------------------
------------------------------------------------------------------------------------------------

function CMD.men(_t_num,_seat_num,_men)
	local _d=game_table[_t_num]
	if not _d or _d.status~="mld_men" or _d.play_data.cur_p~=_seat_num then 
		--状态不合法
		return 1002
	end

	if _d.is_must_men and _men < 1 then
		return 1002
	end

	if _men > 0 then

		for _s,_id in pairs(_d.p_seat_number) do
			if _s == _seat_num then
				_d.p_rate[_s]=_d.p_rate[_s]*4
			else
				_d.p_rate[_s]=_d.p_rate[_s]*2
			end
		end

		_d.men_data[_seat_num]=1

		local act = {
			type = nor_ddz_base_lib.other_type.mld_men,
			p = _seat_num,
			rate = _d.p_rate[_seat_num],
		}

		_d.play_data.act_list[#_d.play_data.act_list+1] = act

		for _s,_id in pairs(_d.p_seat_number) do
			act.rate = _d.p_rate[_s]
			nodefunc.send(_id,"nor_ddz_mld_men_msg",act)
		end

		--记录过程数据日志
		PUBLIC.save_process_data_log(_d,_t_num,_seat_num,26)

		--地主产生了
		set_dizhu(_t_num,_seat_num,1)

		-- 必闷 直接开始游戏
		if _d.is_must_men then
			
			start_cp(_t_num)

			_d.is_must_men = nil

		else

			change_status(_t_num,"wait",1,"mld_jb")

		end

	else

		if _d.men_data[_seat_num] then
			return 1002
		end

		_d.play_data.act_list[#_d.play_data.act_list+1] = {
			type = nor_ddz_base_lib.other_type.mld_kp,
			p = _seat_num,
		}

		for _s,_id in pairs(_d.p_seat_number) do
			nodefunc.send(_id,"nor_ddz_mld_kan_msg",_d.play_data.act_list[#_d.play_data.act_list])
		end

		_d.men_data[_seat_num]=0

		kan_my_pai(_t_num,_seat_num)

		--记录过程数据日志
		PUBLIC.save_process_data_log(_d,_t_num,_seat_num,27)

		change_status(_t_num,"wait",1,"mld_men")

	end

	return 0
end


function CMD.zhua_pai(_t_num,_seat_num,_zhua_opt)
	
	local _d=game_table[_t_num]
	if not _d or _d.status~="mld_men" or _d.play_data.cur_p~=_seat_num then
		return 1002
	end

	if _zhua_opt > 0 then
		_d.p_rate[_seat_num]=_d.p_rate[_seat_num]*2
	end

	local act = {
		type = _zhua_opt>0 and nor_ddz_base_lib.other_type.mld_zhua or nor_ddz_base_lib.other_type.mld_bz,
		p = _seat_num,
		rate = _d.p_rate[_seat_num],
	}

	_d.play_data.act_list[#_d.play_data.act_list+1] = act

	for _s,_id in pairs(_d.p_seat_number) do
		act.rate=_d.p_rate[_s]
		nodefunc.send(_id,"nor_ddz_mld_zp_msg",act)
	end

	if _zhua_opt > 0 then
		
		--地主产生了
		set_dizhu(_t_num,_seat_num,0)

		kan_my_pai(_t_num,1)
		kan_my_pai(_t_num,2)
		kan_my_pai(_t_num,3)

		change_status(_t_num,"wait",1,"mld_jb")

		--记录过程数据日志
		PUBLIC.save_process_data_log(_d,_t_num,_seat_num,28)

	else

		_d.no_zhua_count=_d.no_zhua_count+1

		_d.play_data.cur_p = _d.play_data.cur_p + 1
		if _d.play_data.cur_p > 3 then
			_d.play_data.cur_p = 1
		end

		change_status(_t_num,"wait",1,"mld_men")
		--记录过程数据日志
		PUBLIC.save_process_data_log(_d,_t_num,_seat_num,29)

	end



	return 0

end

function CMD.dao_la(_t_num,_seat_num,_opt)

	local _d=game_table[_t_num]
	if not _d or _d.status~="mld_jb" or _d.dao_la_data[_seat_num] then
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

------------------------------------------------------------------------------------------------
-----------------------------------------MLD-------------------------------------------------
------------------------------------------------------------------------------------------------


function CMD.er_qiang_dizhu(_t_num,_seat_num,_rate)
	local _d=game_table[_t_num]
	if not _d or _d.status~="er_qiangdizhu" then 
		if not _d then
			print("er_qiangdizhu  ",_t_num,_seat_num,_rate)
		end
		--状态不合法
		return 1002
	end
	local status=nor_ddz_room_lib.er_qiang_dizhu(_d,_seat_num,_rate)

	for _s,_id in pairs(_d.p_seat_number) do
		--参数：   ，当前操作
		nodefunc.send(_id,"nor_ddz_er_qdz_msg",_d.play_data.act_list[#_d.play_data.act_list])
	end

	--记录过程数据日志
	PUBLIC.save_process_data_log(_d,_t_num,_seat_num,25,_rate)

	if status>0 then
		set_dizhu(_t_num,status)
		--切换到出牌
		change_status(_t_num,"wait",1,"cp")
	else
		--切换到出牌
		change_status(_t_num,"wait",0.5,"er_qiangdizhu")
	end
	return 0
end

function CMD.chupai(_t_num,_seat_num,_type,_key_pai,act_cp_list,_cp_list,lazi_num)
	local _d=game_table[_t_num]
	if not _d or _d.status~="cp" or _d.play_data.cur_p~=_seat_num then 
		return 1002
	end
	local _status=nor_ddz_room_lib.chupai(_d,_seat_num,_type,_key_pai,act_cp_list,_cp_list,lazi_num)
	if _status==1 or _status==0 then
		--炸弹加倍
		if _type==13 or _type==14 or _type==15 then
			_d.bomb_count=_d.bomb_count+1 
			_d.p_bomb_count[_seat_num]=_d.p_bomb_count[_seat_num]+1
			for i=1,_d.seat_count do 
				_d.p_rate[i]=_d.p_rate[i]*2
			end
		end
		if _type~=0 then
			--出牌次数加1
			_d.p_cp_count[_seat_num]=_d.p_cp_count[_seat_num]+1
		end
		for _s_n,_id in pairs(_d.p_seat_number) do
			nodefunc.send(_id,"nor_ddz_nor_cp_msg",_d.play_data.act_list[#_d.play_data.act_list],_d.p_rate[_seat_num])
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
	local _d=game_table[_t_num]
	_d.p_auto[_seat_num]=_type
	for _s_n,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nor_ddz_nor_auto_msg",_seat_num,_type)
	end

	--记录过程数据日志
	PUBLIC.save_process_data_log(_d,_t_num,_seat_num,_type==1 and 23 or 24)

	return 0
end

function CMD.on_gain_power_change(now_value , now_wave_status)
	print("xxxxxxxxxxxxxxxxxxxxxxxxx ddz CMD.on_gain_power_change:",DATA.game_model,type(DATA.game_model),DATA.game_id,now_value , now_wave_status)
	DATA.gain_power = now_value
	DATA.profit_wave_status = now_wave_status
end

function CMD.start(_id,_ser_cfg,_config)

	-- 房间忽略该配置
	basefunc.tuoguan_v_tuoguan = false

	base.set_hotfix_file("fix_common_ddz_nor_room_service")

	math.randomseed(os.time()*72453) 
	DATA.service_config =_ser_cfg
	DATA.node_service=_ser_cfg.node_service
	DATA.table_count=10
	DATA.my_id=_id
	DATA.mgr_id=_config.mgr_id
	DATA.game_type=_config.game_type
	
	DATA.game_model = _config.game_model
	DATA.match_model = _config.match_model

	DATA.game_id = _config.game_id

	nor_ddz_base_lib.set_game_type(DATA.game_type)
	nor_ddz_room_lib.set_game_type(DATA.game_type)

	--init table
	for i=1,DATA.table_count do 
		table_list[#table_list+1]=i
	end

	skynet.fork(update)

	----- 向场次统计注册信号
	--- 只有自由场 & 比赛场的竞标赛才会被控制
	if DATA.game_model == "freestyle" or (DATA.game_model == "matchstyle" and DATA.match_model == "jbs") then
		DATA.is_auto_profit_ctrl = true
		--[[skynet.send(DATA.service_config.game_profit_manager,"lua", 
			"register_msg" , DATA.my_id
			,{
				node = skynet.getenv("my_node_name"),
				addr = skynet.self(),
				cmd = "on_gain_power_change",
				game_model = _config.game_model or "",
				game_id = _config.game_id or 0,
			}
			, "on_gain_power_change" )--]]

		----  向新消息通知中心注册
		skynet.send(DATA.service_config.msg_notification_center_service,"lua", 
			"add_msg_listener" , "on_gain_power_change"
			,{
				msg_tag = DATA.my_id ,
				node = skynet.getenv("my_node_name"),
				addr = skynet.self(),
				cmd = "on_gain_power_change" ,
				send_filter = { game_id = _config.game_model .. "_" .. _config.game_id } ,
			}
			)
		
		---- 一上来拿到抽水数据
		local now_value,now_wave_status = skynet.call(DATA.service_config.game_profit_manager,"lua", "get_game_profit_power_data" , _config.game_model , _config.game_id )
		DATA.gain_power = now_value
		DATA.profit_wave_status = now_wave_status
		print("xxx--------------------- ddz_room , get_game_profit_power_data:",DATA.gain_power,DATA.profit_wave_status)
	end

	return 0
end

-- 启动服务
base.start_service(default_dispatcher)
