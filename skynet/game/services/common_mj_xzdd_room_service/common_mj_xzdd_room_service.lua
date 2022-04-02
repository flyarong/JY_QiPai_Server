--
-- Author: lyx
-- Time: 
-- 说明：自由场麻将桌子服务
--majiang_freestyle_room_service
local skynet = require "skynet_plus"
require "skynet.manager"
require"printfunc"
local nodefunc = require "nodefunc"
local base=require "base"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA
require "common_mj_xzdd_room_service.common_mj_xzdd_room_record_log"
require "normal_enum"

local nor_mj_algorithm = require "nor_mj_algorithm_lib"
local nor_mj_room_lib = require "nor_mj_room_lib"
local nor_mj_base_lib = require "nor_mj_base_lib"

require "common_mj_xzdd_room_service.common_mj_xzdd_tuoguan"

local basefunc = require "basefunc"

local fmod = math.fmod
local random = math.random
local floor = math.floor
local abs = math.abs
local max = math.max
local min = math.min

--房间ID
DATA.my_id = 0

--上级管理者
DATA.mgr_id = 0

--剩余桌子数量
DATA.table_count = 0

DATA.game_type = nil

DATA.service_config = nil
local node_service

--空闲桌子编号列表
DATA.table_list = DATA.table_list or {}
local table_list=DATA.table_list

--- 抽水力度
DATA.gain_power = 0
--- 是抽水还是放水
DATA.profit_wave_status = nil
--- 是否 水池 自动控制
DATA.is_auto_profit_ctrl = false

--[[

	游戏状态表
	玩家位置代号：1，2，3，4
	status :
	wait_p ：等待人员入座阶段 
	ding_que： 定缺阶段
	ready_cp:准备出牌阶段
	playing： 打牌阶段： 定缺完成后，摸牌、出牌，本局完成之前
	settlement： 结算
	report： 上报战果

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

				--玩家信息集合，数组
				p_info,

				--玩家id座位集合，数组
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

				--底分
				init_stake,

				--比赛次数
				race_count,

				}
--]]
DATA.game_table = DATA.game_table or {}
local game_table=DATA.game_table

--[[

 状态转换示意图

 普通血战： game_begin -> tou_sezi -> fapai -> ding_que -> ding_que_finish -> start -> [ 出牌 <=> 摸牌 => 结束 ]
 换三张：   game_begin -> tou_sezi -> fapai -> huan_pai -> ding_que -> ...
--]]

--###_test
local run=true

-- 等待时间定义
local fapai_time=2	-- 发牌动画
local chu_pai_time=2 -- 出牌动画
local pg_pai_time=2 -- 碰杠动画
local tou_sezi_time = 5 -- 投色子动画
local chupai_cd=16 -- 出牌 倒计时
local dingque_cd=16 -- 定缺 倒计时
local peng_gang_hu_cd = 10 -- 碰杠胡选择 倒计时
local settle_time = 2 -- 游戏结算状态停留的时间
local huan_san_zhang_cd = 15 --10     -- 换三张的持续时间
local da_piao_cd = 15                 -- 打漂的持续时间

local change_status


-- 杠收的钱（番数）
local GANG_TYPES =
{
	zg = 1,
	wg = 0,
	ag = 1,
}


-- 初始化时间
local function init_game_time()

	-- 冠名赛 调整时间
	if type(DATA.match_model)=="string" and string.sub(DATA.match_model,1,6) == "naming" then

		fapai_time=2  -- 发牌动画
		chu_pai_time=2 -- 出牌动画
		pg_pai_time=2 -- 碰杠动画
		tou_sezi_time = 5 -- 投色子动画
		chupai_cd=10 -- 出牌 倒计时
		dingque_cd=8 -- 定缺 倒计时
		peng_gang_hu_cd = 10 -- 碰杠胡选择 倒计时
		settle_time = 2 -- 游戏结算状态停留的时间
		huan_san_zhang_cd = 10     -- 换三张的持续时间
		da_piao_cd = 10                 -- 打漂的持续时间

	end

end

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

-- 转换番数为倍数
local function trans_mul_total(_mul)
	return floor(2 ^ _mul + 0.5)
end

local function player_can_hu(_d,_pai,_seat_num)

	local _pai_map = basefunc.deepcopy(_d.play_data[_seat_num].pai)
	_pai_map[_pai] = (_pai_map[_pai] or 0) + 1

	return _d.mj_algo:get_hupai_all_info(_pai_map,
											_d.play_data[_seat_num].pg_type,
											_d.play_data.p_ding_que[_seat_num],
											_d.action_list,
											_seat_num,
											_d.play_data.zhuang_seat,
											_d.p_mopai_count[_seat_num],
											_d.p_cp_count[_seat_num],
											nor_mj_room_lib.pai_count(_d))
end


local function new_game(_t_num)
	local _d=game_table[_t_num]
	if not _d then
		return false
	end

	_d.t_num = _t_num

	nor_mj_room_lib.dev_debug = skynet.getcfg("dev_debug")

	local print_str = "======== player seats ===============\n"
	for _seat_num,_id in pairs(_d.p_seat_number) do
		print_str = print_str .. "  user id:" .. tostring(_id) .. ",seat:" .. tostring(_seat_num) .. "\n"
	end
	print(print_str)

	-- 已胡牌的人数
	_d.hu_num = 0

	_d.time=0
	_d.play_data=nor_mj_room_lib.new_game(GAME_TYPE_SEAT[DATA.game_type],DATA.game_type)

	---- 二人麻将发7张，其他的发13张
	--if DATA.game_type == "nor_mj_xzdd_er" then
		nor_mj_room_lib.fapai_num = GAME_TYPE_PAI_NUM[DATA.game_type] or 13
	--else
	--	nor_mj_room_lib.fapai_num = 13
	--end
	

	--[[
	每个玩家的结算数据，以座位号为 key
	{
		-- 结算类型： "hu" 胡牌，"ting" 听牌（已听牌，但没胡），"wujiao" 无叫，"hz" 花猪（未打缺）
		settle_type = "hu"

		-- 胡牌类型："zimo" 自摸, "pao" 点炮， "qghu" 抢杠胡
		hu_type = "zimo"

		-- 胡牌 收哪些人的钱：点炮 或 被自摸的人
		hu_others = {seat1,seat2}

		-- 牌的番型： 参见　nor_mj_room_lib.MULTI_TYPES
		pai_multi = {}

		-- 分数
		score = 0

		-- 总番数
		sum_multi = 0

		-- 总倍数
		total = 0

		-- 完整的胡牌/听牌 数据
		hu_all_data = nil

		-- 杠的加减分数据，数组： {gang_type="zg"/"ag",pai=,mul=番数,others={seat1,seat2}}
		-- 注意：弯杠(wg) 不产生金额改变，所以不记录
		gang_score = {}
	}
	--]]
	_d.s_info={}
	nor_mj_room_lib.reset_seat_data(_d.s_info,{gang_score={},total=0,score=0 , lose_surplus = 0})

    --[[ 玩家权限信息，数组
        数据： {
        cp=true,ag=true,zg=true,wg=true,peng=true,
        hu=nor_mj_room_lib.get_peng_gang_hu 返回的值,
        guo=true}
    --]]
    _d.p_permit = {}
    _d.p_permit_pgh_count = 0
    _d.p_permit_h_count = 0

    -- 忽略的胡牌标记（过手胡）
    _d.p_ignore_hu = {}

    --动作标记
    _d.p_action_done = {}
    
	-- 当前出牌
	-- 这个貌似没用了
	--_d.cur_chupai={p=nil,pai=nil}

    -- 当前弯杠
    _d.cur_wan_gang=nil

    -- 动作列表
    _d.action_list={}

    -- 摸牌次数
    _d.p_mopai_count = {0,0,0,0}
	-- 玩家出牌次数： nil 为 0
	_d.p_cp_count={0,0,0,0}

	_d.no_paohu_pai = {}

    --mb-- 碰杠胡管理器数据
    _d.pgh_manager = {
        wait_hu_actions = {}, -- 等待的胡 action：多个
        wait_pg_action = nil, -- 等待的碰杠 action
    }

     -- 抢杠胡管理器数据
    _d.qgh_manager_wait_hu={}
	-- 杠上花，杠上炮 标志：记录最近杠牌的人，出牌/摸牌 ,抢杠胡 未胡牌 后清除
	_d.last_gang_seat = nil

	-- 转雨座位
	_d.zhuan_yu_seat = nil


	_d.ready={0,0,0,0}
	_d.p_ready=0

	-- 游戏破产状态
	_d.game_bankrupt={0,0,0,0}

	-- 玩家的点炮次数
	_d.dianpao_count={0,0,0,0}

	_d.cha_da_jiao_count={0,0,0,0}

	if _d.cur_race==1 then
		change_status(_t_num,"wait_p")
		_d.on_line_player={}
	else
		change_status(_t_num,"ready")
	end
	--特殊处理数据
	-- 	seat --座位
	--  fapai_list
	--  mopai_list 
	--  cp_list
	--  hupai
	--  dq_color
	--  gang_map
	--  peng_map
	--  dianpao={}	 --map key=要给谁点炮 
	--  hu_pao={} -- map key=谁给我点炮
	_d.special_deal_data={}

	--记录游戏开始日志
	PUBLIC.save_race_start_log(_d,_t_num)

end

--- 获取幸运号座位
local function get_lucky_seat_num(_d)
	local luck_id_seat = nil
	---配置的luck_id
	local luck_id_cfg = {}
	for i=1, skynet.getcfg_2number("lucky_id_num",0) do
		luck_id_cfg[ skynet.getcfg("lucky_id_"..i,"") ] = true
	end
	for _seat_num,player_id in pairs(_d.p_seat_number) do
		
		if not luck_id_seat and luck_id_cfg[player_id] then
			luck_id_seat = _seat_num
			break
		end
	end
	return luck_id_seat
end

-- 得到强化托管的 特殊信息
local function get_tuoguan_pai_data(_d)
	local _tuoguan_pai
	_tuoguan_pai = {
		pai_pool = _d.play_data.pai_pool,

		-- 发牌之后的 牌数量
		pai_pool_count = GAME_TYPE_TOTAL_PAI_NUM[DATA.game_type] - 
			GAME_TYPE_SEAT[DATA.game_type] * GAME_TYPE_PAI_NUM[DATA.game_type] - 1,
		playrs_pai = {},
	  }

	for _snum,_id in pairs(_d.p_seat_number) do
		_tuoguan_pai.playrs_pai[_snum] = _d.play_data[_snum].pai
	end
	return _tuoguan_pai
end
-- 发送强化托管牌的特殊信息
local function send_tuoguan_pai_data(_d)
	local _tuoguan_pai
	for _seat_num,_id in pairs(_d.p_seat_number) do
	  	if not _d.real_player[_seat_num] then
			_tuoguan_pai = _tuoguan_pai or get_tuoguan_pai_data(_d)
			_tuoguan_pai.special_deal_data = _d.special_deal_data[_seat_num]
		  	nodefunc.send(_id,"nor_mj_xzdd_notify_tuoguan_pai",_tuoguan_pai)
	  	end
	end
end
local function status_game_begin(_t_num)
	
	local _d = game_table[_t_num]

	-- 处理托管： 幸运号
	if not nor_mj_room_lib.dev_debug and DATA.is_auto_profit_ctrl and not get_lucky_seat_num(_d) and _d.game_tag ~= "xsyd" then
	--if not get_lucky_seat_num(_d) then
		_d.play_data.tuoguan_ctrl = PUBLIC.prepare_tuoguan_data(_d)
		--print("--------------- status_game_begin , tuoguan_ctrl",_d.game_tag)
		-- 再次洗牌
		if _d.play_data.tuoguan_ctrl then
			nor_mj_room_lib.random_list(_d.play_data.pai_pool)
		end
	end
	-- 向 player agent 发送消息
	for _seat_num,_id in pairs(_d.on_line_player) do
		nodefunc.send(_id,"nor_mj_xzdd_begin_msg",_d.cur_race)
	end
	
	change_status(_t_num,"wait",1,"tou_sezi")

end


-- 投色子 定庄家
local function status_tou_sezi(_t_num)
	local _d = game_table[_t_num]

	local _sezi1 = random(1,6)
	local _sezi2 = random(1,6)

	_d.play_data.zhuang_seat = fmod(_sezi1+_sezi2,_d.seat_count) + 1

	--- test , 选第一个真实玩家做庄
	-- if skynet.getcfg("dev_debug") then
	-- 	for _seat_num,player_id in pairs(_d.p_seat_number) do
	-- 		--- 如果是玩家
	-- 		if _d.real_player[_seat_num] then
	-- 			_d.play_data.zhuang_seat = _seat_num
	-- 			break
	-- 		end
	-- 	end
	-- end

	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nor_mj_xzdd_tou_sezi_msg",_sezi1,_sezi2,_d.play_data.zhuang_seat,tou_sezi_time)
	end

end

local function status_huan_pai_finish(_t_num,is_not_send)
	local _d = game_table[_t_num]

	print("//////////********---huan_pai finish----")

	if not is_not_send then
		-- 托管牌消息（用于 强化托管）
		send_tuoguan_pai_data(_d)
		for _s,_id in pairs(_d.p_seat_number) do
			nodefunc.send(_id,"nor_mj_xzdd_huan_pai_finish_msg")
		end
	end

	if DATA.game_type == "nor_mj_xzdd_er_7" or DATA.game_type == "nor_mj_xzdd_er_13" then
		for _seat_num,_id in pairs(_d.p_seat_number) do
			_d.play_data.p_ding_que[_seat_num] = 3
		end

		change_status(_t_num,"wait",1,"start")
		return
	end

	change_status(_t_num,"wait",1,"ding_que")

end


local function status_da_piao_finish(_t_num,is_not_send)
	local _d = game_table[_t_num]

	print("//////////********---da_piao finish----")

	if not is_not_send then
		for _s,_id in pairs(_d.p_seat_number) do
			nodefunc.send(_id,"nor_mj_xzdd_da_piao_finish_msg")
		end
	end

	local delay_time = 2.3
	---- 如果做了打漂，就只隔一点时间
	if not is_not_send then
		delay_time = 0.3
	end

	if _d.huan_san_zhang then
		change_status(_t_num,"wait",delay_time,"huan_pai")
		return
	else
		status_huan_pai_finish(_t_num , true)
	end
	
end

local function status_fapai(_t_num)

	local _d = game_table[_t_num]

	local _luck_seat = get_lucky_seat_num(_d)
	if _luck_seat and not _d.play_data.tuoguan_ctrl then
		_d.lucky_seat_num = _luck_seat
		--_d.special_deal_data[_luck_seat] = { is_tuoguan = false }
	end

	nor_mj_room_lib.fapai(_d,_d.play_data.zhuang_seat,4)

	local remain_card = nor_mj_room_lib.pai_count(_d)

	-- 托管牌消息（用于 强化托管）
	send_tuoguan_pai_data(_d)

	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nor_mj_xzdd_pai_msg",_d.play_data[_seat_num].pai,remain_card)
	end

	if _d.da_piao then
		change_status(_t_num,"wait",fapai_time,"da_piao")
		return
	else
		status_da_piao_finish(_t_num,true)
	end

	PUBLIC.save_fapai_log(_d,_t_num)
end

local function get_pgh(_d,_seat_num,_pai)

	local hu=_d.mj_algo:get_hupai_all_info(_d.play_data[_seat_num].pai,
												_d.play_data[_seat_num].pg_type,
												_d.play_data.p_ding_que[_seat_num],
												_d.action_list,
												_seat_num,
												_d.play_data.zhuang_seat,
												_d.p_mopai_count[_seat_num],
												_d.p_cp_count[_seat_num],
												nor_mj_room_lib.pai_count(_d))


	local pai_count = _d.play_data[_seat_num].pai[_pai] or 0

	local peng
	local gang

	local flower = nor_mj_base_lib.flower(_pai)
	if _pai and flower~=_d.play_data.p_ding_que[_seat_num] then
		local pai_count = _d.play_data[_seat_num].pai[_pai] or 0

		--print(_pai,pai_count,"_pai***---pai_count")

		if pai_count > 1 then
			peng=true
		end

		-- 杠牌 要保证 能补杠
		if pai_count > 2 and nor_mj_room_lib.pai_count(_d) > 0 then
			gang=true
		end
	end

	if hu or peng or gang then
		return {hu=hu,peng=peng,gang=gang}
	end
	--dump(_d.play_data[_seat_num].pai,"get_pgh***---pai**----")
	return nil
end




local function clear_peng_gang_hu(_d,_seat_num)
	if not _seat_num then
		for i=1,_d.seat_count do
			_d.play_data.wait_pengganghu_data[i] = nil
			_d.play_data.wait_hu_data[i] = nil
		end
	else
		_d.play_data.wait_pengganghu_data[_seat_num] = nil
		_d.play_data.wait_hu_data[_seat_num] = nil
	end
end

-- 加减 一个 人的钱
local function change_one_player_score(_d,_seat_num,_score)
	if _d.on_line_player[_seat_num] then
		return nodefunc.call(_d.on_line_player[_seat_num],"nor_mj_xzdd_modify_score",_score)
	else
		if _d.back_money_cmd then
			local s = nodefunc.call(DATA.mgr_id,_d.back_money_cmd,_d.on_line_player[_seat_num],_score)
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



-- 处理加分和扣分
-- 参数 _mul ： 番数
local function deal_change_score(_d,_seat_num,_total,_others,_type)

	local _score = math.floor( _total * _d.init_stake )

	local _score_change = {}

	--- 是否打漂
	local isPiao = _d.da_piao
	local myPiaoNum = _d.play_data[_seat_num].piaoNum
	local da_piao_player_num = CMD.get_da_piao_player_num(_d) 


	---- 如果是胡牌类型，且有赢封顶，
	local is_yingfengding = false
	local yingfengding_max = 0
	if _type == "zimo" or _type == "tian_hu" or _type == "pao" or _type == "qghu" then
		if _d.table_config and _d.table_config.game_config and _d.table_config.game_config.yingfengding==1 then
			is_yingfengding = true
			--- 玩家赢封顶的钱数
			yingfengding_max = nodefunc.call(_d.p_seat_number[_seat_num],"nor_mj_get_yingfengding_score",_d.p_info[_seat_num].score)

		end
	end

	-- 别人减钱
	local _score_sum = 0
	local all_lose_surplus = 0
	local has_yingfengding = false
	for _,_loser in ipairs(_others) do
		--- 如果打漂，那么减的钱就得是减去 乘以 两者打漂的和
		if isPiao then
			local loserPiaoNum = _d.play_data[_loser].piaoNum

			if myPiaoNum > 5 or loserPiaoNum > 5 then
				error("piaoNum is TOO big !",myPiaoNum,loserPiaoNum)
				return
			end


			if da_piao_player_num == 1 then
				_score = _score * 2
			elseif da_piao_player_num >= 2 then
				_score = _score * 4
			end

			--[[if myPiaoNum > 0 or loserPiaoNum > 0 then
				_score = _score * 2
			end--]]

			--_score = _score + _d.init_stake * ( myPiaoNum + loserPiaoNum )
		end

		if is_yingfengding then
			if _score > yingfengding_max then
				_score = yingfengding_max
				_d.s_info.yingfengding=_d.s_info.yingfengding or {0,0,0,0}
				_d.s_info.yingfengding[_seat_num]=1
			end
		end

		local deduct = change_one_player_score(_d,_loser,-_score)

		local ls = _score + deduct

		if ls > 0 and is_yingfengding then
			_d.s_info.yingfengding=_d.s_info.yingfengding or {0,0,0,0}
			
			if not has_yingfengding then
				_d.s_info.yingfengding[_seat_num]=0
			end

		end

		-- 标记已经赢封顶了
		if _d.s_info.yingfengding and _d.s_info.yingfengding[_seat_num]==1 then
			has_yingfengding = true
		end

		local lose_surplus = _d.s_info[_loser].lose_surplus
		_d.s_info[_loser].lose_surplus = lose_surplus + ls
		
		all_lose_surplus = all_lose_surplus + ls

		if deduct == 0 then
			print("deal_change_score deduct warning: is zero!")
		end

		_d.s_info[_loser].score = _d.s_info[_loser].score + deduct

		print("deal_change_score deduct : seat_num,score,other,deduct,cur_score:"
											,_seat_num,_score,_loser,deduct,_d.s_info[_loser].score)

		_score_change[_loser] = {score=deduct,lose_surplus=ls}
		_score_sum = _score_sum + deduct
	end

	-- 自己加钱
	_score_sum = floor(abs(_score_sum) + 0.5)
	_d.s_info[_seat_num].score = _d.s_info[_seat_num].score + _score_sum
	_d.s_info[_seat_num].lose_surplus = _d.s_info[_seat_num].lose_surplus - all_lose_surplus

	print("deal_change_score add_win(to player_agent) : seat_num,score_sum,cur_score:"
													,_seat_num,_score_sum,_d.s_info[_seat_num].score)
	change_one_player_score(_d,_seat_num,_score_sum)

	_score_change[_seat_num] = {score=_score_sum,lose_surplus=-all_lose_surplus}

	-- 给每个人发 钱变化通知消息
	for _s,_id in pairs(_d.on_line_player) do
		nodefunc.send(_id,"nor_mj_xzdd_score_change_msg",_score_change,_type)
	end

	--- add by wss
	return _score_sum,all_lose_surplus
end

---- add by wss 用真实的分数改变
local function deal_change_score_by_score(_d,_seat_num,_score,_others,_type)
	deal_change_score(_d,_seat_num,_score / _d.init_stake,_others,_type)
end

local function settle_find_gang_pai( _s_info ,_pai)
	for _,_ginfo in ipairs(_s_info.gang_score) do
		if _pai == _ginfo.pai then
			return _ginfo
		end
	end

	return nil
end

local function settle_get_pg_pai(_s_info,_p_data)

	local ret = {}
	for _,_pg in ipairs(_p_data.pg_vec) do

		local _rd = {pai=_pg,pg_type=_p_data.pg_type[_pg]}

		if _rd.pg_type == "peng" or _rd.pg_type == "wg" then
			_rd.sum = 0
		else 
			local _ginfo = assert(settle_find_gang_pai(_s_info,_pg))
			_rd.sum = trans_mul_total(_ginfo.mul) * #_ginfo.others
		end

		ret[#ret + 1] = _rd
	end

	return ret
end

local function is_hua_zhu(_pai_map,_que_flower)
	for _pai,_count in pairs(_pai_map) do
		if math.floor(_pai/10) == _que_flower and _count > 0 then
			return true
		end
	end

	return false
end

-- 结算 收集 信息
local function settle_gen_datas(_d, _settle_datas,_ting_settles,_wujiao_settles )

	-- 按座位循环
	for _seat = 1,_d.seat_count do
		local _p_data = _d.play_data[_seat]
		local _s_info = _d.s_info[_seat]
		local _settle = {
			seat_num = _seat,
			settle_data = {},
			shou_pai = nor_mj_base_lib.get_pai_list_by_map(_p_data.pai),
			pg_pai = settle_get_pg_pai(_s_info,_p_data),
		}

		if _p_data.hu_order then
			if _p_data.hu_order > 0 then
				_settle.settle_data.settle_type = "hu"
				_settle.settle_data.hu_type = _s_info.hu_type
				_settle.settle_data.multi = _s_info.pai_multi
				_settle.settle_data.hu_pai = _s_info.hu_all_data.hu_pai
				_settle.settle_data.sum_multi = _s_info.sum_multi
				_settle.settle_data.sum = _s_info.total
			else

			end
		else
			local _ting_info = _d.mj_algo:get_max_ting_all_info(_p_data.pai,_p_data.pg_type,_d.play_data.p_ding_que[_seat])
			if _ting_info then
				if not _ting_info.mul then
					dump(_ting_info,"common xzdd settle_gen_datas ting error -----------")
				end

				_settle.settle_data.settle_type = "ting"
				_settle.settle_data.multi = _ting_info.hu_type_info
				_settle.settle_data.hu_pai = _ting_info.hu_pai
				_settle.settle_data.sum_multi = _ting_info.mul
				_settle.settle_data.sum = _ting_info.total

				_s_info.pai_multi = _ting_info.hu_type_info
				_s_info.total = _ting_info.total
				_s_info.hu_all_data = _ting_info

				_ting_settles[#_ting_settles + 1] = _settle

			else
				-- 花猪
				if is_hua_zhu(_p_data.pai,_d.play_data.p_ding_que[_seat]) then
					_settle.settle_data.settle_type = "hz"
				else
					-- 无叫
					_settle.settle_data.settle_type = "wujiao"
				end

				_wujiao_settles[#_wujiao_settles + 1] = _settle
			end

			_s_info.settle_type = _settle.settle_data.settle_type
		end

		_p_data.settle_type=_settle.settle_data.settle_type
		
		_settle_datas[#_settle_datas + 1] = _settle
	end	
end

-- 查叫：计算查叫输赢的 钱
local function settle_cha_jiao(_d, _ting_settles,_wujiao_settles )
	--- 破产人数
	local bankrupt_num = 0
	for key,value in pairs(_d.game_bankrupt) do
		if value == 1 then
			bankrupt_num = bankrupt_num + 1
		end
	end
	
	
	-- 查叫，两个 以上的人未胡牌
	if _d.hu_num + bankrupt_num < (_d.seat_count - 1) then

		local _max_mul = 2 ^ (_d.max_rate or 10)
		
		for _,_wujiao in ipairs(_wujiao_settles) do

			-- 赔有叫的
			for _,_ting in ipairs(_ting_settles) do
				local _total = assert(_d.s_info[_ting.seat_num].total)

				-- 如果是花猪，则至少赔 16 倍（4番）
				local cj_type = "cj"
				if _wujiao.settle_data.settle_type == "hz" and _total < 16 then
					_total = 16
					cj_type = "chz"
				end

				deal_change_score(_d,_ting.seat_num,min(_total,_max_mul),{_wujiao.seat_num},cj_type)
			end

			-- 花猪賠不是花猪的，直接賠 16 倍
			if _wujiao.settle_data.settle_type == "hz" then
				for _,_wujiao2 in ipairs(_wujiao_settles) do
					if _wujiao2.settle_data.settle_type ~= "hz" then
						deal_change_score(_d,_wujiao2.seat_num,min(16,_max_mul),{_wujiao.seat_num},"chz")
					end
				end
			end

		end

		-- 无叫的退杠的 钱  {gang_type="zg"/"ag",pai=,mul=番数,others={seat1,seat2}}
		for _,_settle in ipairs(_wujiao_settles) do
			for _,gang in ipairs(_d.s_info[_settle.seat_num].gang_score) do
				if gang.others and next(gang.others) then
					local ts_seat = _settle.seat_num

					if gang.zhuan_yu_to_seat and type(gang.zhuan_yu_to_seat) == "number" then
						---退的钱由拿转雨钱的人出
						ts_seat = gang.zhuan_yu_to_seat
					end

					for _,other in ipairs(gang.others) do
						deal_change_score(_d,other,trans_mul_total(gang.mul),{ts_seat},"ts")
					end
				else
					dump(_d.s_info[_settle.seat_num],"settle chajiao error:")
				end
			end
		end
	end
end

local function next_game(_t_num)
	local _d = game_table[_t_num]

	if _d.is_break_game or _d.cur_race >= _d.race_count then
		
		change_status(_t_num,"wait",settle_time,"gameover")

	else

		_d.cur_race=_d.cur_race+1
		new_game(_t_num)

		--延迟
		skynet.timeout(settle_time*100,function ()
			
			local _d = game_table[_t_num]
			for _seat_num,_id in pairs(_d.p_seat_number) do
				nodefunc.send(_id,"nor_mj_xzdd_next_game_msg",_d.cur_race)
			end

		end)

	end
end

--结算中 通知给玩家
local function status_settlement(_t_num)
	local _d = game_table[_t_num]

	-- dump(_d.s_info,"status_settlement --------------- s_info:")

	local settle_datas = {}

	-- 查叫数据
	local _ting_settles = {}
	local _wujiao_settles = {}

	-- 收集结算信息，并计算有叫无叫
	settle_gen_datas(_d,settle_datas,_ting_settles,_wujiao_settles)

	-- 查叫：计算查叫输赢的 钱
	if not _d.is_break_game then
		settle_cha_jiao(_d,_ting_settles,_wujiao_settles)
	end

	local is_have_bankrupt = false
	-- 总分
	for _,_settle in pairs(settle_datas) do
		-- if _d.is_break_game then
		-- 	_settle.settle_data.score = 0
		-- else
			_settle.settle_data.score = _d.s_info[_settle.seat_num].score
			_settle.settle_data.lose_surplus = _d.s_info[_settle.seat_num].lose_surplus

			if _settle.settle_data.lose_surplus and _settle.settle_data.lose_surplus > 0 then
				if _d.game_bankrupt[_settle.seat_num] ~= 1 then
					is_have_bankrupt = true
				end
				_d.game_bankrupt[_settle.seat_num] = 1
			end

		-- end
	end

	-- 告诉所有人
	if is_have_bankrupt then
		for _,_id in pairs(_d.on_line_player) do
	        nodefunc.send(_id,"nor_mj_xzdd_game_bankrupt_msg",_d.game_bankrupt)
	    end
	end

	-- 按胡牌顺序排序
	table.sort(settle_datas,function(_v1,_v2)
		return (_d.play_data[_v1.seat_num].hu_order or 100)  < (_d.play_data[_v2.seat_num].hu_order or 100)
	end)

	local log_id = PUBLIC.save_race_over_log(_d,_t_num)

	settle_datas.dian_pao_count = _d.dianpao_count
	settle_datas.cha_da_jiao_count = _d.cha_da_jiao_count

	settle_datas.yingfengding = _d.s_info.yingfengding

	-- dump(settle_datas,"status_settlement --------------- msg:")

	local is_over = false
	if _d.race_count==_d.cur_race or _d.is_break_game then
		is_over = true
	end

	-- 发送结算消息
	for _seat_num,_id in pairs(_d.on_line_player) do
		if not _d.play_data[_seat_num].is_quit then
			nodefunc.send(_id,"nor_mj_xzdd_settlement_msg",settle_datas,is_over,log_id)
		end
	end

	next_game(_t_num)

end

local function status_gameover(_t_num)
	local _d = game_table[_t_num]

	for _seat_num,_id in pairs(_d.on_line_player) do
		if not _d.play_data[_seat_num].is_quit then
			nodefunc.send(_id,"nor_mj_xzdd_gameover_msg",{})
		end
	end
	
	print("room call table_finish",DATA.my_id,_t_num)

	nodefunc.call(DATA.mgr_id,"table_finish",DATA.my_id,_t_num)

	return_table(_t_num)

	nodefunc.send(DATA.mgr_id,"return_table",DATA.my_id,_t_num)


end

-- ###_test0809 取消当前游戏
local function status_gamecancel(_t_num)
	local _d = game_table[_t_num]

	for _seat_num,_id in pairs(_d.on_line_player) do
		if not _d.play_data[_seat_num].is_quit then
			nodefunc.send(_id,"nor_mj_xzdd_gamecancel_msg")
		end
	end

	-- 取消的时候，不记录，PUBLIC.save_race_over_log(_d,_t_num)

	nodefunc.call(DATA.mgr_id,"table_finish",DATA.my_id,_t_num)

	return_table(_t_num)

	nodefunc.send(DATA.mgr_id,"return_table",DATA.my_id,_t_num)
end

local function refresh_table_kaiguan(_d)
	local kaiguanTem = _d.mj_algo:get_self_kaiguan()
	if kaiguanTem then
		-- 打漂功能
		_d.da_piao = kaiguanTem.da_piao
		print("----------------- _d.da_piao: ",_d.da_piao)
		--- 换三张功能
		_d.huan_san_zhang = kaiguanTem.huan_san_zhang

		--- 转雨功能
		_d.zhuan_yu = kaiguanTem.zhuan_yu
	end
end

-- 参数 _table_config ：
--	model_name   游戏模式名字，比如： "friendgame"，用于 status_game_begin 时回传给 player agent
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

	_d.time=0

	_d.game_tag = _table_config.game_tag

	_d.play_data=nor_mj_room_lib.new_game(GAME_TYPE_SEAT[DATA.game_type],DATA.game_type)

	_d.table_config = _table_config

	-- 是否玩家，否则为托管
	_d.real_player = {}


	_d.p_info={}
	--玩家进入房间的标记
	_d.players_join_flag={}
	_d.p_seat_number={}  -- 座位号为下标，玩家 id 为值
	_d.p_count=0

	_d.init_rate=_table_config.game_config.init_rate or 1
	_d.init_stake=_table_config.game_config.init_stake or 1
	
	_d.seat_count = GAME_TYPE_SEAT[DATA.game_type] or 4

	--比赛次数
	_d.race_count=_table_config.game_config.race_count or 1

	_d.model_name = assert(_table_config.model_name)
	_d.game_id = assert(_env.game_id)
	_d.game_type = assert(_table_config.game_type)

	_d.back_money_cmd = _table_config.back_money_cmd

	--- 自己人好牌概率
	_d.nice_pai_rate = _table_config.nice_pai_rate or 0

	-- 游戏算法对象
	local kaiguan = nil
	local multi = nil
	if _table_config.rule_config then
		kaiguan = _table_config.rule_config.kaiguan
		multi = _table_config.rule_config.multi
	end
	_d.max_rate = _table_config.game_config.feng_ding
	_d.mj_algo = nor_mj_algorithm.new(kaiguan,multi , DATA.game_type , _table_config.game_config.feng_ding)

	refresh_table_kaiguan(_d)

	---- 设置算法的基础手牌数量&最大手牌数量
	_d.mj_algo.baseShouPaiNum = GAME_TYPE_PAI_NUM[DATA.game_type] or 13
	_d.mj_algo.maxShouPaiNum = _d.mj_algo.baseShouPaiNum + 1

	_d.cur_race=1

	_d.p_auto={}

	game_table[_t_num]=_d

	-- print("new table ,base_score,init_rate:",_table_config.game_config.base_score,_d.init_rate)

	new_game(_t_num)

	--###_test  目前是默认创建  可以考虑根据条件创建 比如（根据房卡场等来默认创建）
	if DATA.service_config.chat_service then
		_d.chat_room_id = skynet.call(DATA.service_config.chat_service,"lua","create_room")
	end

	return _t_num
end

function CMD.refresh_kaiguan_multi(_t_num , kaiguan , multi)
	local _d = game_table[_t_num]

	if _d then
		_d.mj_algo:set_kaiguan(kaiguan)
		_d.mj_algo:set_multi(multi)
	end

	refresh_table_kaiguan(_d)
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

	run=nil
	nodefunc.destroy(DATA.my_id)
	skynet.exit()
end

function CMD.quit_room(_t_num,_seat_num)
	local ret = {}
	
	local _d = game_table[_t_num]
	if not _d then
		--房间已经没有了
		return ret
	end
	
	if _d.play_data 
		and _d.play_data[_seat_num]
		and _d.play_data[_seat_num].hu_order then

		local score = _d.s_info[_seat_num].score
		local lose_surplus = _d.s_info[_seat_num].lose_surplus
		
		ret.score = score
		ret.lose_surplus = lose_surplus
		
		_d.play_data[_seat_num].is_quit = true
		_d.on_line_player[_seat_num]=nil

	end

	return ret
end

-- 准备
local function ready(_t_num)
	local _d = game_table[_t_num]
	_d.p_ready=_d.p_ready+1
	if _d.p_ready==_d.seat_count then
		change_status(_t_num,"game_begin")
	end
end

function CMD.ready(_t_num,_seat_num)
	local _d = game_table[_t_num]

	if not _d then 
		return {result=1002}
	end

	if _d.ready[_seat_num]==0 then
		_d.ready[_seat_num]=1

		for _s,_id in pairs(_d.on_line_player) do
			nodefunc.send(_id,"nor_mj_xzdd_ready_msg",_seat_num)
		end

		ready(_t_num)
	end
	
	return {result=0}
end

function CMD.join(_t_num,_p_id,_info)
	local _d=game_table[_t_num]
	if not _d or _d.p_count>_d.seat_count-1 or _d.status~="wait_p" or _d.players_join_flag[_p_id] then
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
	_d.on_line_player[_seat_num]=_p_id
	_d.p_count=_d.p_count+1
	_d.p_info[_seat_num]=_info
	_d.p_info[_seat_num].seat_num=_seat_num
	_d.real_player[_seat_num] = basefunc.chk_player_is_real(_p_id) and _p_id or nil

	print("join room. room,table,user id,seat:",DATA.my_id,_t_num,_p_id,_seat_num)

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
	for _seat_num,_value in pairs(_d.p_info) do
		if _value.id~=_p_id then
			nodefunc.send(_value.id,"nor_mj_xzdd_join_msg",_info)
		else
			-- 给托管 发消息
			if not _d.real_player[_seat_num] then
				nodefunc.send(_value.id,"nor_mj_xzdd_notify_tuoguan_param",{
					game_type = _d.mj_algo.gameType,
					kaiguan = _d.mj_algo.kaiguan,
					multi_types = _d.mj_algo.multi_types,
					baseShouPaiNum = _d.mj_algo.baseShouPaiNum,
					maxShouPaiNum = _d.mj_algo.maxShouPaiNum,
				})
			end
			nodefunc.send(_value.id,"nor_mj_xzdd_join_msg",nil,my_join_return)
		end
	end

	_d.play_data[_seat_num].is_quit = nil

	return 0
end

-- ###_test0809 游戏没开始的时候退出房间
function CMD.player_exit_game(_t_num,_seat_num)
	local _d = game_table[_t_num]
	
	if not _d then 
		return 1002
	end

	-- 向所有玩家 发消息
	for _s,_id in pairs(_d.on_line_player) do
		if not _d.play_data[_s].is_quit then
			nodefunc.send(_id,"nor_mj_xzdd_player_exit_msg",_seat_num)
		end
	end

	-- 清理自己的数据
	_d.players_join_flag[_d.p_seat_number[_seat_num]] = nil
	_d.ready[_seat_num]=0
	_d.p_ready = _d.p_ready - 1
	_d.p_seat_number[_seat_num] = nil
	_d.on_line_player[_seat_num] = nil
	_d.p_count = _d.p_count-1
	_d.play_data[_seat_num].is_quit = true

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
		change_status(_t_num,"settlement")
	end

	return 0
end
-- 强制退出游戏
function CMD.force_break_game(_t_num)
  local _d = game_table[_t_num]

  if not _d then
    return 1002
  end

  -- 标记为 中途结束
  _d.is_break_game = true

  local log_id = PUBLIC.save_race_over_log(_d,_t_num)

  local settle_datas = {
    dian_pao_count = 0,
    cha_da_jiao_count = 0,
  }

  for i=1,_d.seat_count do
    settle_datas[i]=
    {
      settle_data=
      {
        score = 0,
        lose_surplus = 0,
        settle_type = "wujiao",
      },
      seat_num = i,
      pg_pai = {},
      shou_pai = {},
    }
  end

  -- 发送结算消息
  for _seat_num,_id in pairs(_d.on_line_player) do
    if not _d.play_data[_seat_num].is_quit then
      nodefunc.send(_id,"nor_mj_xzdd_settlement_msg",settle_datas,true,log_id)
    end
  end
  change_status(_t_num,"wait",2,"gameover")

  return 0
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


local function status_ding_que(_t_num)
	local _d = game_table[_t_num]

	PUBLIC.save_majiang_process_get_permit_time(_d,_t_num)

	_d.p_action_done={true,true,true,true}
	-- 发送权限：每个人同时定缺，所以不传当前用户
	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nor_mj_xzdd_dingque_permit",dingque_cd)
	end
end

local function status_ding_que_finish(_t_num)
	local _d = game_table[_t_num]
	
	print("//////////********---ding_que----")

	for _s,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nor_mj_xzdd_ding_que_msg",_d.play_data.p_ding_que)
	end

	change_status(_t_num,"wait",1,"start")
end

---- 换三张
local function status_huan_pai(_t_num)
	local _d = game_table[_t_num]

	PUBLIC.save_majiang_process_get_permit_time(_d,_t_num)

	-- 执行换牌操作，然后 切换到定缺状态
	--assert(false,"not suport!")

	 _d.p_action_done={true,true,true,true}
	-- 发送权限：每个人同时定缺，所以不传当前用户
	for _seat_num,_id in pairs(_d.p_seat_number) do
	 	nodefunc.send(_id,"nor_mj_xzdd_huansanzhang_permit",huan_san_zhang_cd)
	end

	--change_status(_t_num,"wait",huan_san_zhang_cd,"huan_pai_finish")
end



---- 打漂状态
local function status_da_piao(_t_num)
	local _d = game_table[_t_num]

	PUBLIC.save_majiang_process_get_permit_time(_d,_t_num)

	-- 执行换牌操作，然后 切换到定缺状态
	--assert(false,"not suport!")

	 _d.p_action_done={true,true,true,true}
	-- 发送权限：每个人同时定缺，所以不传当前用户
	for _seat_num,_id in pairs(_d.p_seat_number) do
	 	nodefunc.send(_id,"nor_mj_xzdd_dapiao_permit",da_piao_cd)
	end

end



function CMD.da_piao( _t_num,_seat_num, piaoNum )
	
	local _d = game_table[_t_num]
	
	print("CMD.da_piao",_t_num,_seat_num,piaoNum)

	if not _d or _d.status~="da_piao" then
		print("da_piao error: ",_d,_d.status,_t_num,_seat_num)
		return 1002
	end

	if not _d.p_action_done[_seat_num] then
		print(_d.p_action_done[_seat_num],"CMD.da_piao********-------")
		return 1002
	end
	_d.p_action_done[_seat_num]=nil


	--- 做一下检查
	if piaoNum ~= 0 and piaoNum ~= 1 and piaoNum ~= 3 and piaoNum ~= 5 then
		print("da_piao error piaoNum is not right : ",_d,_t_num,_seat_num,piaoNum)
		return 1002
	end

	if _d.play_data[_seat_num].piaoNum ~= -1 then
		print("da_piao error piaoNum is set value : ",_d,_t_num,_seat_num,_d.play_data[_seat_num].piaoNum ,piaoNum)
		return 1002
	end

	-- 
	if _d.play_data[_seat_num].piaoNum == -1 then
		_d.play_data[_seat_num].piaoNum = piaoNum
	end

	--[[local da_piao_player_num = CMD.get_da_piao_player_num(_d) 
	if da_piao_player_num == 1 then
		--- 突破封翻
		_d.mj_algo:max_fan_add_one()
	elseif da_piao_player_num >= 2 then
		--- 还原封翻
		_d.mj_algo:max_fan_orig()
	end--]]

	--[[if piaoNum == 1 or piaoNum == 3 or piaoNum == 5 then
		--- 突破封翻
		_d.mj_algo:max_fan_add_one()
	end--]]

	---- 写日志
	PUBLIC.save_process_data_log(_d,_t_num,_seat_num, 10, piaoNum )

	--- 一个人打漂了，立刻给所有人发
	for seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send( _d.p_seat_number[seat_num],"nor_mj_xzdd_dapiao_msg", _seat_num , piaoNum )
	end

	-- 如果每个人都打漂完成
	if nor_mj_room_lib.is_da_piao_finish(_d.play_data) then
		
		change_status(_t_num,"wait",0.5,"da_piao_finish")
	end

	return 0
end

function CMD.get_da_piao_player_num(_d)
	local num = 0
	if _d then
		for seat_num,_id in pairs(_d.p_seat_number) do
			if _d.play_data and _d.play_data[seat_num] and _d.play_data[seat_num].piaoNum ~= -1 and _d.play_data[seat_num].piaoNum > 0 then
				num = num + 1
			end
		end
	end
	return num
end


function CMD.ding_que(_t_num,_seat_num,_flower)
	local _d = game_table[_t_num]
	
	print("CMD.ding_que",_t_num,_seat_num,_flower)

	if not _d or _d.status~="ding_que" then
		print("ding_que error: ",_d,_t_num,_seat_num,_flower)
		return 1002
	end
	if not _d.p_action_done[_seat_num] then
		print(_d.p_action_done[_seat_num],"CMD.ding_que********-------")
		return 1002
	end
	_d.p_action_done[_seat_num]=nil

	_d.play_data.p_ding_que[_seat_num] = _flower



	PUBLIC.save_process_data_log(_d,_t_num,_seat_num,1,_flower)


	nodefunc.send( _d.p_seat_number[_seat_num],"nor_mj_xzdd_my_dingque_msg",_seat_num,_flower)

	-- print(nor_mj_room_lib.is_ding_que_finished(_d.play_data.p_ding_que),"////*-*-/-*/*-/-*/-*-/)")
	-- 如果每个人都定缺完成
	if nor_mj_room_lib.is_ding_que_finished(_d.play_data.p_ding_que) then
		
		change_status(_t_num,"wait",0.5,"ding_que_finish")
	end

	return 0
end

function CMD.huan_san_zhang(_t_num,_seat_num,data , is_time_out)
	local _d = game_table[_t_num]
	
	-- print("CMD.huan_san_zhang",_t_num,_seat_num)
	-- dump(data , "huan_san_zhang paiVec")

	if not _d or _d.status~="huan_pai" then
		print("huan_san_zhang error: ",_d,_d.status,_t_num,_seat_num)
		return 1002
	end

	---- 操作检查，最后做
	if not _d.p_action_done[_seat_num] then
		print(_d.p_action_done[_seat_num],"CMD.huan_san_zhang********-------")
		return 1002
	end

	_d.p_action_done[_seat_num]=nil

	_d.play_data[_seat_num].huan_pai_old = data

	_d.play_data[_seat_num].huan_pai_new = nor_mj_room_lib.huan_pai( _d , _seat_num , data )

	---- 写日志
	PUBLIC.save_process_data_log(_d,_t_num,_seat_num, 9, _d.play_data[_seat_num].huan_pai_old )
	---- 写日志
	PUBLIC.save_process_data_log(_d,_t_num,_seat_num, 9, _d.play_data[_seat_num].huan_pai_new )

	_d.play_data[_seat_num].is_huan_pai = 1

	-- dump(_d.play_data[_seat_num].huan_pai_new , "//// **** huan_san_zhang NEW paiVec")
	-- dump(_d.play_data[_seat_num].pai , "//// **** huan_san_zhang NEW paiVec")
	nodefunc.send( _d.p_seat_number[_seat_num],"nor_mj_xzdd_huansanzhang_new",data,_d.play_data[_seat_num].huan_pai_new , _d.play_data[_seat_num].pai , is_time_out)

	-- 如果每个人都换牌完成。
	if nor_mj_room_lib.is_huan_pai_finished(_d.play_data) then
		
		change_status(_t_num,"wait",0.5,"huan_pai_finish")
	end

	return 0
end

local function status_chu_pai(_t_num)
	local _d = game_table[_t_num]

	PUBLIC.save_majiang_process_get_permit_time(_d,_t_num)

	_d.play_data.cur_chupai = nil

	_d.p_action_done[_d.play_data.cur_p]=true
	_d.p_permit[_d.play_data.cur_p]={cp=true}

	-- 发送 出牌权限
	for _seat_num,_id in pairs(_d.on_line_player) do
		if not _d.play_data[_seat_num].hu_order then
			nodefunc.send(_id,"nor_mj_xzdd_chupai_permit",_d.play_data.cur_p,chupai_cd)
		end
	end

end

-- 庄家开始出牌
local function start_cp(_t_num)
	local _d = game_table[_t_num]

	PUBLIC.save_majiang_process_get_permit_time(_d,_t_num)

	local _p=_d.play_data.zhuang_seat
	_d.play_data.cur_p =_p

	local is_hu = false
	local res=_d.mj_algo:get_hupai_all_info(_d.play_data[_p].pai,
												_d.play_data[_p].pg_type,
												_d.play_data.p_ding_que[_p],
												_d.action_list,
												_p,
												_p,
												0,
												0,
												nor_mj_room_lib.pai_count(_d))
	if res then
		is_hu=true
	end
	--动作标记
    _d.p_action_done[_p] =true
	_d.p_permit[_p]={cp=true,hu=res}
	-- 发送 权限
	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nor_mj_xzdd_start_permit",_p,is_hu,chupai_cd)
	end

end

local function status_mo_pai(_t_num)
	local _d = game_table[_t_num]

	-- 牌摸完，进入结算
	if _d.play_data.pai_empty then
		change_status(_t_num,"settlement")
		return
	end

	--- 破产人数
	local bankrupt_num = 0
	for key,value in pairs(_d.game_bankrupt) do
		if value == 1 then
			bankrupt_num = bankrupt_num + 1
		end
	end
	

	--没胡的人只有1个了 进入结算
	if _d.hu_num and (_d.seat_count - _d.hu_num - bankrupt_num) <= 1 then
		change_status(_t_num,"settlement")
		return
	end

	PUBLIC.save_majiang_process_get_permit_time(_d,_t_num)

	local _cur_data = _d.play_data[_d.play_data.cur_p]

	-- 过手胡
	_d.p_ignore_hu[_d.play_data.cur_p] = nil

	-- 得到一张牌
	local _mopai_src
	if _d.play_data.tuoguan_ctrl then
		_cur_data.mo_pai,_mopai_src=nor_mj_room_lib.special_pop_pai(_d,_d.play_data.cur_p)	
	else
		_cur_data.mo_pai = nor_mj_room_lib.pop_pai(_d)
	end

	--- add by wss
	if _d.last_gang_seat ~= _d.play_data.cur_p then
		_d.last_gang_seat = nil
	end

	if not _cur_data.mo_pai then
		change_status(_t_num,"settlement")
		return
	end
	
	_cur_data.pai[_cur_data.mo_pai] = (_cur_data.pai[_cur_data.mo_pai] or 0) + 1
	
	--摸牌此时加1
	local mo_pai_num = _d.p_mopai_count[_d.play_data.cur_p]+1
	_d.p_mopai_count[_d.play_data.cur_p]=mo_pai_num

	local remain_card = nor_mj_room_lib.pai_count(_d)
	--print("/////////////////////////*****--->>>>>>s>>>>>"..remain_card)

	local act = {
		type="mo_pai",
		pai=_cur_data.mo_pai,
		p=_d.play_data.cur_p,
	}
	_d.action_list[#_d.action_list+1]=act

	local is_hu = false
	local hu_data
	local pgh = get_pgh(_d,_d.play_data.cur_p,_cur_data.mo_pai)
	-- dump({pgh=pgh,cur_p=_d.play_data.cur_p},"status_mo_pai ---------------ddd")
	if pgh and pgh.hu then
		is_hu = true
		hu_data = pgh.hu
	end

	PUBLIC.save_process_data_log(_d,_t_num,_d.play_data.cur_p,12,_cur_data.mo_pai)

	PUBLIC.save_majiang_process_get_permit_time(_d,_t_num)
	
	_d.p_action_done[_d.play_data.cur_p]=true
	_d.p_permit[_d.play_data.cur_p]={cp=true,hu=hu_data}

	-- 发送 摸牌权限
	for _seat_num,_id in pairs(_d.on_line_player) do
		local _pai = 0
		
		if not _d.real_player[_seat_num] or _seat_num==_d.play_data.cur_p then
			_pai = _cur_data.mo_pai
		end
		nodefunc.send(_id,"nor_mj_xzdd_mopai_permit",_d.play_data.cur_p,_pai,is_hu,chupai_cd,remain_card,_mopai_src)
	end

end


-- 处理游戏过程破产
local function deal_game_bankrupt(_t_num)
	local _d = game_table[_t_num]

	if not _d.table_config or not _d.table_config.game_config or _d.table_config.game_config.break_exit~=1 then
		return 0
	end

	local bankrupt_num = 0
	local is_have_bankrupt = false
	for _seat,_id in pairs(_d.on_line_player) do

		if _d.p_info[_seat].score + _d.s_info[_seat].score < 1 then
			if _d.game_bankrupt[_seat] ~= 1 then
				is_have_bankrupt = true
			end
			bankrupt_num = bankrupt_num + 1
			_d.game_bankrupt[_seat] = 1
			_d.play_data[_seat].hu_order = 0
			PUBLIC.save_process_data_log(_d,_t_num,_seat,11)

		end

	end

	-- 告诉所有人
	if is_have_bankrupt then
		for _,_id in pairs(_d.on_line_player) do
	        nodefunc.send(_id,"nor_mj_xzdd_game_bankrupt_msg",_d.game_bankrupt)
	    end
	end

	return bankrupt_num
end

local function deal_guo(_t_num)
	local _d = game_table[_t_num]
	local act = _d.action_list[#_d.action_list]
	local _seat_num = act.p
	
	_d.p_permit[act.p]={}

	while true do
		_seat_num = _seat_num + 1
		if _seat_num > _d.seat_count then _seat_num = 1 end

		if not _d.play_data[_seat_num].hu_order then

			_d.play_data.cur_p = _seat_num
			
			change_status(_t_num,"mo_pai")

			break
		end

	end

end

local function deal_chu_pai(_t_num,_seat_num,_pai)
	local _d = game_table[_t_num]
	_d.p_permit_pgh_count = 0
	_d.p_permit_h_count = 0

	-- 计算其他人 对此牌的碰杠胡权限进行记录
	for _s,_id in pairs(_d.on_line_player) do

		if _seat_num ~= _s and not _d.play_data[_s].hu_order then

			local _pgh = get_pgh(_d,_s,_pai)

			-- 过手胡
			if _pgh then
				
				if _pgh.hu and _d.p_ignore_hu[_s] and _d.p_ignore_hu[_s].pai == _pai and _pgh.hu.mul <= _d.p_ignore_hu[_s].mul then
					_pgh.hu = nil
				end

				if not next(_pgh) then
					_pgh = nil
				end
			end

			if _pgh then

				_d.p_action_done[_s]=true
				_d.p_permit[_s]=_pgh

				--附加过权限
				_d.p_permit[_s].guo=true
				
				_d.p_permit_pgh_count=_d.p_permit_pgh_count+1

				if _pgh.hu then
					_d.p_permit_h_count = _d.p_permit_h_count + 1
				end

				_d.status = "peng_gang_hu"
				
				--分发权限消息
				nodefunc.send(_id,"nor_mj_xzdd_peng_gang_hu_permit",
								_pai,
								_pgh,
								peng_gang_hu_cd)
			end
			

		end

	end

	--- add by wss 是否杠上炮，点一家
	if _d.last_gang_seat and _d.last_gang_seat == _seat_num and _d.p_permit_h_count == 1 then
		_d.zhuan_yu_seat = _seat_num
	else
		_d.zhuan_yu_seat = nil
	end

	PUBLIC.save_majiang_process_get_permit_time(_d,_t_num)

	if _d.p_permit_pgh_count < 1 then
		deal_guo(_t_num)
	end

end


local function status_chu_pai_finish(_t_num)
	local _d = game_table[_t_num]
	deal_chu_pai(_t_num,
		_d.play_data.cur_chupai.p,
		_d.play_data.cur_chupai.pai)
end

function CMD.chu_pai(_t_num,_seat_num,_pai)
	local _d = game_table[_t_num]
	
	if not _d 
		or (_d.status~="start"
			and _d.status~="cp"
			and _d.status~="mo_pai") then
		return 1002
	end

	if not _d.p_action_done[_seat_num] then
		return 1002
	end
	_d.p_action_done[_seat_num]=nil


	local _pdata = _d.play_data[_seat_num]

	PUBLIC.save_process_data_log(_d,_t_num,_seat_num,2,_pai)

	if _d.last_gang_seat ~= _seat_num then
		_d.last_gang_seat = nil
	end

	_d.play_data.cur_chupai = {p=_seat_num,pai=_pai}

	-- 删除
	_pdata.pai[_pai] = _pdata.pai[_pai] - 1
	_d.p_cp_count[_seat_num] = (_d.p_cp_count[_seat_num] or 0) + 1

	--
	local act = {
		type = "cp",
		p=_seat_num,
		pai=_pai,
	}
	_d.action_list[#_d.action_list+1]=act

	-- 记录听牌信息
	_pdata.ting_info = _d.mj_algo:get_ting_info(_pdata.pai,_pdata.pg_pai,_d.play_data.p_ding_que[_seat_num])			

	-- 发送出牌 action 通知
	for _s,_id in pairs(_d.on_line_player) do
		nodefunc.send(_id,"nor_mj_xzdd_chu_pai_msg",act)
	end

	change_status(_t_num,"cp_finish")

	return 0
end

-- 为 碰杠 移动牌到 pg_pai
-- _count ： 3 碰； 4 杠
local function move_pai_for_pg(_seat_play_data,_pai,_type)
	local count = 0
	if _type == "peng" then
		count = 2
	elseif _type == "ag" then
		count = 4
	elseif _type == "zg" then
		count = 3
	elseif _type == "wg" then
		count = 1
	end
	_seat_play_data.pai[_pai]=_seat_play_data.pai[_pai]-count
	_seat_play_data.pg_type[_pai]=_type
	if _type == "peng" then
		_seat_play_data.pg_pai[_pai] = 3
	else
		_seat_play_data.pg_pai[_pai] = 4
	end

	-- 弯杠 采用之前 碰的位置，所以 不加入
	if _type ~= "wg" then	
		table.insert(_seat_play_data.pg_vec,_pai)
	end

end


local function deal_peng_pai(_t_num,act)
	local _d = game_table[_t_num]

	move_pai_for_pg(_d.play_data[act.p],act.pai,"peng")

	PUBLIC.save_process_data_log(_d,_t_num,act.p,4,act.pai)

	-- 发送碰牌通知
	for _s,_id in pairs(_d.on_line_player) do
		nodefunc.send(_id,"nor_mj_xzdd_peng_msg",act)
	end
	
	_d.p_permit[act.p]={}

	_d.action_list[#_d.action_list+1]=act

	-- 切换状态
	_d.play_data.cur_p = act.p
	change_status(_t_num,"cp")
end


-- 执行胡牌
local function deal_hu(_t_num,_actions)

    local _d = game_table[_t_num]

    local _,_action1 = next(_actions)

    local _seat_num
    if _action1.hu_data.dianpao_p then
    	_seat_num = nor_mj_room_lib.next_oper_seat(_d.play_data,_action1.hu_data.dianpao_p)
    else
    	_seat_num = _action1.p
    end


    for i=1,_d.seat_count do

        local _act = _actions[_seat_num]
        if _act then

            _d.hu_num = _d.hu_num + 1
            _d.play_data[_seat_num].hu_order = _d.hu_num

            local _s_data = _d.s_info[_seat_num]

            if _act.hu_data.hu_type == "zimo" or _act.hu_data.hu_type == "tian_hu" then
                _s_data.hu_others = {}

                for _seat=1,_d.seat_count do
                    if _seat ~= _seat_num and not _d.play_data[_seat].hu_order then
                        _s_data.hu_others[#_s_data.hu_others+1] = _seat
                    end
                end

            elseif _act.hu_data.hu_type == "pao" then
            	_d.play_data[_seat_num].pai[_act.hu_data.pai] 
            		= (_d.play_data[_seat_num].pai[_act.hu_data.pai] or 0) + 1
            	
                _s_data.hu_others = {_act.hu_data.dianpao_p}

            elseif _act.hu_data.hu_type == "qghu" then  
            	_d.play_data[_seat_num].pai[_act.hu_data.pai] 
            		= (_d.play_data[_seat_num].pai[_act.hu_data.pai] or 0) + 1
                _s_data.hu_others = {_act.hu_data.dianpao_p}
            end

            _s_data.pai_multi = _act.hu_all_data.hu_type_info
            _s_data.sum_multi = _act.hu_all_data.mul
            _s_data.total = _act.hu_all_data.total
            deal_change_score(_d,_seat_num,_s_data.total,_s_data.hu_others,_act.hu_data.hu_type)

            _s_data.hu_type = _act.hu_data.hu_type
            _s_data.hu_all_data = _act.hu_all_data
            _act.hu_all_data = nil

            _d.action_list[#_d.action_list+1]=_act

            -- 发送胡牌信息
            for _,_id in pairs(_d.on_line_player) do
                nodefunc.send(_id,"nor_mj_xzdd_hu_msg",_act,_d.s_info[_seat_num].score)
            end
        end

        -- 下一个
        _seat_num = nor_mj_room_lib.next_oper_seat(_d.play_data,_seat_num)
    end

    PUBLIC.save_process_data_log(_d,_t_num,_action1.p,6,_action1.hu_data.pai)

    local bankrupt_num = deal_game_bankrupt(_t_num)

    ----
	if _d.hu_num and (_d.seat_count - _d.hu_num - bankrupt_num) <= 1 then
		change_status(_t_num,"settlement")
		return
	end


    deal_guo(_t_num)
end




-- 记录杠的分数
local function record_gang_score(_d,_seat_num,_type,_pai,_mul,_others)

	if not _others or not next(_others) then
		dump({s_info=_d.s_info[_seat_num],_seat_num=_seat_num,_type=_type,_pai=_pai,_mul=_mul,_others=_others},"record_gang_score error:")
		return
	end

	local _gang_data = _d.s_info[_seat_num].gang_score
	
	-- 加钱 扣钱
	local total_score,total_lose_surplus = deal_change_score(_d,_seat_num,trans_mul_total(_mul),_others,_type)
	--- 把杠赢的钱记录到结算信息里面
	_gang_data[#_gang_data + 1] = {gang_type=_type,pai=_pai,mul=_mul,others=_others , score = total_score , lose_surplus = total_lose_surplus }

	return total_score,total_lose_surplus
end

local function get_seat_others(_d,_seat_num)

	local _others = {}
	for i=1,_d.seat_count do
		-- 排除自己和 已经胡牌的
		if i ~= _seat_num and not _d.play_data[i].hu_order then
			_others[#_others + 1] = i
		end
	end

	return _others
end

local function deal_gang(_t_num,act)

	local _d = game_table[_t_num]
	if act.type=="zg" then
		record_gang_score(_d,act.p,act.type,act.pai,GANG_TYPES[act.type],{_d.play_data.cur_chupai.p})
	else
		record_gang_score(_d,act.p,act.type,act.pai,GANG_TYPES[act.type],get_seat_others(_d,act.p))
	end	
	move_pai_for_pg(_d.play_data[act.p],act.pai,act.type)
	--加入 action_list
	_d.action_list[#_d.action_list+1]=act

	_d.p_permit={}

	-- 发送杠通知
	for _s,_id in pairs(_d.on_line_player) do
		nodefunc.send(_id,"nor_mj_xzdd_gang_msg",act)
	end

	PUBLIC.save_process_data_log(_d,_t_num,act.p,5,act.pai)

	deal_game_bankrupt(_t_num)

	_d.play_data.cur_p=act.p
	change_status(_t_num,"mo_pai")
end
local function deal_w_gang_finish(_t_num,act)
	local _d = game_table[_t_num]

	--扣钱
	if not act.jwg then
		record_gang_score(_d,act.p,act.type,act.pai,GANG_TYPES[act.type],get_seat_others(_d,act.p))
	end
	
	_d.play_data.cur_p=act.p
	change_status(_t_num,"mo_pai")
end
local function deal_w_gang(_t_num,act)
	local _d = game_table[_t_num]

	move_pai_for_pg(_d.play_data[act.p],act.pai,act.type)
	--加入 action_list
	_d.action_list[#_d.action_list+1]=act

	_d.p_permit={}

	-- 发送杠通知
	for _s,_id in pairs(_d.on_line_player) do
		nodefunc.send(_id,"nor_mj_xzdd_gang_msg",act)
	end
	
	_d.qgh_permit_count=0
	--查看是否有人可以抢杠胡
	for _s,_id in pairs(_d.on_line_player) do
		if not _d.play_data[_s].hu_order and _s~=_t_num then
			local res=_d.mj_algo:get_hupai_all_info(_d.play_data[_s].pai,
												_d.play_data[_s].pg_type,
												_d.play_data.p_ding_que[_s],
												_d.action_list,
												_s,
												_d.play_data.zhuang_seat,
												_d.p_mopai_count[_s],
                        						_d.p_cp_count[_s],
												nor_mj_room_lib.pai_count(_d))
			if res then
				_d.p_permit[_s]={guo=true,hu=res}
				_d.qgh_permit_count=_d.qgh_permit_count+1
				_d.p_action_done[_s]=true
				--分发权限消息
				nodefunc.send(_id,"nor_mj_xzdd_peng_gang_hu_permit",
								act.pai,
								{hu=true},
								peng_gang_hu_cd)
			end
		end
	end

	 PUBLIC.save_majiang_process_get_permit_time(_d,_t_num)

	if _d.qgh_permit_count<1 then
		deal_w_gang_finish(_t_num,act)			
	else
		_d.cur_wan_gang=act
		--切换为PGH状态
		_d.status = "qiang_gang_hu"
	end
end
local function qiang_gang_hu_manager(_t_num,act)
	--等人 完成
    --guo 
    --hu  --hu 

    local _d = game_table[_t_num]
    local _permit = _d.p_permit[act.p]

    -- if not _permit or not _permit[act.type] then
    --     return 1002
    -- end

    _d.qgh_permit_count = _d.qgh_permit_count - 1

    if "hu" == act.type then
        _d.qgh_manager_wait_hu[act.p] = act
    end

    if 0 == _d.qgh_permit_count then
        -- 处理胡
        if next(_d.qgh_manager_wait_hu) then
        	--将wg 变为碰 *************
        	local _pai=_d.cur_wan_gang.pai
        	local _p=_d.cur_wan_gang.p
        	_d.play_data[_p].pg_type[_pai]="peng"
        	_d.play_data[_p].pg_pai[_pai]=3
        	_d.cur_wan_gang.type="peng"
        	--将wg 变为碰 ************* 
            deal_hu(_t_num,_d.qgh_manager_wait_hu)
        else
            --加钱
             deal_w_gang_finish(_t_num,_d.cur_wan_gang)
        end
        _d.cur_wan_gang=nil
        _d.qgh_manager_wait_hu = {}
        return 0
    end
end

local function peng_gang_hu_manager(_t_num,action)
    --等 核心人 完成
    --guo  --mb
    --peng  --cp
    --gang --mobei
    --hu  --hu 

    -- 逻辑说明：
    --  碰杠 -> 如果有 别人的胡 等待，则 存入 wait_pg_action
    --  胡 -> 存起来 ，并清除 所有 碰杠信息；等待所有的胡到达则执行； 如果没有其他的胡 权限，则 转入下家摸牌
    --  过 -> 如果没有 其他 碰杠胡，则 处理等待的碰杠，没有 则转入 下家摸牌；


    local _d = game_table[_t_num]
    local _permit = _d.p_permit[action.p]
	
	--dump(action,"peng_gang_hu_manager**----------")
	--dump(_permit,"peng_gang_hu_manager**------_permit----")

    -- if not _permit or not _permit[action.type] then
    --     return 1002
    -- end

    _d.p_permit_pgh_count = _d.p_permit_pgh_count - 1

    if "hu" == action.type then
        _d.pgh_manager.wait_hu_actions[action.p] = action
        
        _d.p_permit_h_count = _d.p_permit_h_count - 1

        if _d.p_permit_h_count == 0 then
        	_d.p_permit_pgh_count = 0
        end 

    elseif "guo" ~= action.type then
        _d.pgh_manager.wait_pg_action = action
    end

    print(_d.p_permit_pgh_count,"_d.p_permit_pgh_count")

    if 0 == _d.p_permit_pgh_count then
        -- 处理胡
        if next(_d.pgh_manager.wait_hu_actions) then
            deal_hu(_t_num,_d.pgh_manager.wait_hu_actions)
        elseif _d.pgh_manager.wait_pg_action then
            if "peng" == _d.pgh_manager.wait_pg_action.type then
                deal_peng_pai(_t_num,_d.pgh_manager.wait_pg_action)
            else
                deal_gang(_t_num,_d.pgh_manager.wait_pg_action)
            end
        else
            deal_guo(_t_num)
        end

        _d.pgh_manager.wait_hu_actions = {}
        _d.pgh_manager.wait_pg_action = nil
        return 0
    end

    return 0
end


-- 过：不 碰杠胡
function CMD.guo_pai(_t_num,_seat_num)
	local _d = game_table[_t_num]
	
	if not _d or (_d.status~="peng_gang_hu" and _d.status~="qiang_gang_hu") then
		return 1002
	end

	if not _d.p_action_done[_seat_num] then
		return 1002
	end
	_d.p_action_done[_seat_num]=nil
	
	PUBLIC.save_process_data_log(_d,_t_num,_seat_num,3)

	-- 过手胡 
	local hu_info=_d.p_permit[_seat_num].hu
	if hu_info and hu_info.dianpao_p and not hu_info.hu_type_info.qiangganghu then
		_d.p_ignore_hu[_seat_num] = {
			pai=hu_info.hu_pai,
			mul=hu_info.mul,
		}
	end

	--通知自己 过 ok 了
	local _id = _d.on_line_player[_seat_num]
	nodefunc.send(_id,"nor_mj_xzdd_guo_msg")

	local act={
			type="guo",
			p=_seat_num,
		}
	if _d.status == "qiang_gang_hu" then
		qiang_gang_hu_manager(_t_num,act)
	else
		peng_gang_hu_manager(_t_num,act)
	end

	return 0
end

function CMD.peng_pai(_t_num,_seat_num,_pai)

	local _d = game_table[_t_num]

	if not _d or _d.status~="peng_gang_hu" then
		return 1002
	end

	if not _d.p_action_done[_seat_num] then
		return 1002
	end
	_d.p_action_done[_seat_num]=nil

	-- 过手胡
	_d.p_ignore_hu[_seat_num] = nil

	print("CMD.peng_pai ----- :",_t_num,_seat_num,_pai)

	local act={
			type="peng",
			p=_seat_num,
			pai=_pai
			}
	
	peng_gang_hu_manager(_t_num,act)

	-- 托管： 碰牌之后，如果 mopai_list 还有，则还给牌池
	local _spec_data = _d.special_deal_data[_seat_num]
	if _spec_data and not _spec_data.gang_map[_pai] then
		local _mplist = _spec_data.mopai_list
		for i,_pai2 in ipairs(_mplist) do
			if _pai2 == _pai then
				table.remove( _mplist,i )
				table.insert(_d.play_data.pai_pool,math.random(#_d.play_data.pai_pool+1), _pai )
				break
			end
		end
	end

	return 0
end


function CMD.gang_pai(_t_num,_seat_num,_gang_type,_pai)
	local _d = game_table[_t_num]

	if not _d 
		or (_d.status~="peng_gang_hu" 
		and _d.status~="mo_pai"
		and _d.status~="start"
		and _d.status~="cp") then
		return 1002
	end

	if not _d.p_action_done[_seat_num] then
		return 1002
	end
	_d.p_action_done[_seat_num]=nil
	local act
	if _gang_type=="jwg" then
		_gang_type="wg"
		act={
				type="wg",
				p=_seat_num,
				pai=_pai,
				jwg=true
				}
	else
		act={
				type=_gang_type,
				p=_seat_num,
				pai=_pai
				}
	end

	print("CMD.gang_pai ---------:",_gang_type,_t_num,_seat_num,_gang_type,_pai)

	-- 过手胡
	_d.p_ignore_hu[_seat_num] = nil

	if _gang_type=="ag" then
		deal_gang(_t_num,act)
	elseif _gang_type=="zg" then
		peng_gang_hu_manager(_t_num,act)		
	elseif _gang_type=="wg" then
		deal_w_gang(_t_num,act)		
	end

	--- add by wss 上一个杠的位置
	_d.last_gang_seat = _seat_num

	return 0
end


function CMD.hu_pai(_t_num,_seat_num)
	local _d = game_table[_t_num]

	if not _d 
		or (_d.status~="peng_gang_hu"
		and _d.status~="qiang_gang_hu"
		and _d.status~="mo_pai"
		and _d.status~="start") then
		return 1002
	end

	if not _d.p_action_done[_seat_num] then
		return 1002
	end
	_d.p_action_done[_seat_num]=nil	

	local hu_info=_d.p_permit[_seat_num].hu
	local hu_type
	if not hu_info.dianpao_p then
		hu_type="zimo"
		-- add by wss , 如果是天胡
		if hu_info.hu_type_info.tian_hu then       
			hu_type="tian_hu"
		end
	elseif hu_info.hu_type_info.qiangganghu then
		hu_type="qghu"
		---- add by wss 如果是抢杠胡了，那么要把上一个杠的位置给清掉; 为了杠上炮转雨
		_d.last_gang_seat = nil

	else
		hu_type="pao"
	end
	local act={
			type="hu",
			p=_seat_num,
			hu_data={
					seat_num =_seat_num,
					hu_type=hu_type,
					pai =hu_info.hu_pai,
					dianpao_p=hu_info.dianpao_p,
			},
			hu_all_data=hu_info
	}

	if hu_info.dianpao_p then
		_d.dianpao_count[hu_info.dianpao_p] = _d.dianpao_count[hu_info.dianpao_p] + 1
	end

	print("CMD.hu_pai ----- :",hu_type,_t_num,_seat_num)
	if hu_type=="zimo" or hu_type=="tian_hu" then
		deal_hu(_t_num,{[_seat_num]=act})
	elseif hu_type=="qghu" then
		qiang_gang_hu_manager(_t_num,act)
	else
		peng_gang_hu_manager(_t_num,act)
	end

	--- add by wss  转雨 
	if _d.zhuan_yu_seat and _d.zhuan_yu then
		--- 把这个人最近一次的杠钱给我，
		local _gang_data = _d.s_info[_d.zhuan_yu_seat].gang_score
		if _gang_data and next(_gang_data) then
			local gang_score = _gang_data[#_gang_data].score

			--- 雨钱转给谁了
			_gang_data[#_gang_data].zhuan_yu_to_seat = _seat_num
			
			deal_change_score_by_score(_d,_seat_num, gang_score ,{ _d.zhuan_yu_seat }, "zhuan_yu" )

			---- 发给客户端
			local _gang_data = _d.s_info[_d.zhuan_yu_seat].gang_score
			if _gang_data and next(_gang_data) then
				for _,_id in pairs(_d.on_line_player) do
					nodefunc.send(_id,"nor_mj_xzdd_zhuan_yu_msg",{ type = "zhuan_yu" , p = _seat_num , pai = _gang_data[#_gang_data].pai , other = tostring(_d.zhuan_yu_seat) })
				end
			end

		end

	end


	-- 托管： 胡牌后，将所有 未使用的牌 还给  牌池
	local _spdata = _d.special_deal_data[_seat_num]
	if _spdata then
		for i,_pai2 in ipairs(_spdata.mopai_list) do
			table.insert(_d.play_data.pai_pool,math.random(#_d.play_data.pai_pool+1), _pai2 )
		end
		_spdata.mopai_list = {}

		if _spdata.hupai then
			table.insert(_d.play_data.pai_pool,math.random(#_d.play_data.pai_pool+1), _spdata.hupai )
			_spdata.hupai = nil
		end
	end

	return 0

end


function CMD.auto(_t_num,_seat_num,_type)
	local _d=game_table[_t_num]

	if not _d then
		return 1002
	end
	
	_d.p_auto[_seat_num]=_type
	for _s_n,_id in pairs(_d.on_line_player) do
		nodefunc.send(_id,"nor_mj_xzdd_auto_msg",_seat_num,_type)
	end

	print("room CMD.auto ",_t_num,_seat_num,_type)

	 PUBLIC.save_process_data_log(_d,_t_num,_seat_num,_type==1 and 7 or 8)

	return 0
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
			elseif _value.status=="tou_sezi" then
				_value.time=_value.time-dt
				if _value.time<=0 then
					change_status(_t_num,"fapai")
				end
			end
		end
		skynet.sleep(dt*100)
	end
end


function PUBLIC.change_status_impl(_t_num,_status,_time,_next_status)
	assert(game_table[_t_num])
	print("change_status  : ",_t_num,_status,DATA.my_id,_time,_next_status)
	if _status=="wait_p" then
		game_table[_t_num].status=_status
	elseif _status=="ready" then				-- 游戏准备中
		game_table[_t_num].status=_status
	elseif _status=="game_begin" then				-- 游戏开始
		game_table[_t_num].status=_status
		status_game_begin(_t_num)
	elseif _status=="wait" then
		game_table[_t_num].status=_status
		game_table[_t_num].time=_time
		game_table[_t_num].next_status=_next_status
	elseif _status=="tou_sezi" then 			-- 投色子
		game_table[_t_num].status=_status
		game_table[_t_num].time=tou_sezi_time
		status_tou_sezi(_t_num)
	elseif _status=="fapai" then
		game_table[_t_num].status=_status
		game_table[_t_num].time=fapai_time
		status_fapai(_t_num)
	elseif _status=="huan_pai" then				-- 换三张：换牌
		game_table[_t_num].status=_status
		status_huan_pai(_t_num)
	elseif _status == "huan_pai_finish" then    -- 换牌完成
		game_table[_t_num].status=_status
		status_huan_pai_finish(_t_num)
	elseif _status=="da_piao" then				-- 打漂
		game_table[_t_num].status=_status
		status_da_piao(_t_num)
	elseif _status=="da_piao_finish" then				-- 打漂完成
		game_table[_t_num].status=_status
		status_da_piao_finish(_t_num)
	elseif _status=="ding_que" then              -- 定缺
		game_table[_t_num].status=_status
		status_ding_que(_t_num)
	elseif _status=="ding_que_finish" then
		game_table[_t_num].status=_status
		status_ding_que_finish(_t_num)
	elseif _status=="cp" then
		game_table[_t_num].status=_status
		status_chu_pai(_t_num)
	elseif _status=="cp_finish" then
		game_table[_t_num].status=_status
		status_chu_pai_finish(_t_num)
	elseif _status=="start" then
		game_table[_t_num].status=_status
		start_cp(_t_num)
	elseif _status=="mo_pai" then
		game_table[_t_num].status=_status
		status_mo_pai(_t_num)
	elseif _status=="settlement" then
		game_table[_t_num].status=_status
		status_settlement(_t_num)
	elseif _status=="gameover" then
		game_table[_t_num].status=_status
		status_gameover(_t_num)
	elseif _status=="gamecancel" then		-- 房间 还未开始就解散，没有大结算消息
		game_table[_t_num].status=_status
		status_gamecancel(_t_num)
	end
end

change_status = function(_t_num,_status,_time,_next_status)
	PUBLIC.change_status_impl(_t_num,_status,_time,_next_status)	
end

function CMD.on_gain_power_change(now_value , now_wave_status)
	print("xxxxxxxxxxxxxxxxxxxxxxxxx mj CMD.on_gain_power_change:",DATA.game_model,type(DATA.game_model),DATA.game_id,now_value , now_wave_status )

	DATA.gain_power = now_value
	DATA.profit_wave_status = now_wave_status
end



function CMD.start(_id,_ser_cfg,_config)
	
	-- 房间忽略该配置
	basefunc.tuoguan_v_tuoguan = false
	
	base.set_hotfix_file("fix_common_mj_xzdd_room_service")

	math.randomseed(os.time()*86579)
	DATA.service_config =_ser_cfg
	node_service=_ser_cfg.node_service
	DATA.table_count=10
	DATA.my_id=_id

	DATA.game_model = _config.game_model
	DATA.game_id = _config.game_id

	DATA.mgr_id=_config.mgr_id
	DATA.game_type=_config.game_type
	DATA.match_model = _config.match_model

	init_game_time()

	--init table
	for i=1,DATA.table_count do 
		table_list[#table_list+1]=i
	end

	skynet.fork(update)

	----- 向场次统计注册信号
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
		print("xxx--------------------- mj_room , get_game_profit_power_data:",DATA.gain_power,DATA.profit_wave_status)

	end

	return 0
end

-- 启动服务
base.start_service()






