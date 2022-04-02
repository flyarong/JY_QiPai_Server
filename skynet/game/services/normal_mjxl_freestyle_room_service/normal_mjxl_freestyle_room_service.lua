--
-- Author: lyx
-- Time: 
-- 说明：自由场麻将桌子服务
--normal_mjxl_freestyle_room_service
local skynet = require "skynet_plus"
require "skynet.manager"
require"printfunc"
local nodefunc = require "nodefunc"
local base=require "base"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

require "normal_mjxl_freestyle_room_service.normal_mjxl_freestyle_room_record_log"
require "normal_enum"

local nor_mj_algorithm = require "nor_mj_algorithm_lib"
local nor_mj_room_lib = require "nor_mj_room_lib"
local nor_mj_base_lib = require "nor_mj_base_lib"


local basefunc = require "basefunc"

local fmod = math.fmod
local random = math.random
local floor = math.floor
local abs = math.abs
local max = math.max

--房间ID
DATA.my_id = 0

--上级管理者
DATA.mgr_id = 0

--剩余桌子数量
DATA.table_count = 0

-- 桌子座位数
local SEAT_COUNT = 4

-- 杠收的钱（番数）
local GANG_TYPES =
{
	zg = 1,
	wg = 0,
	ag = 1,
}

--[[游戏状态表
	玩家位置代号：1，2，3，4
	status :
	wait_p ：等待人员入座阶段 
	ding_que： 定缺阶段
	ready_cp:准备出牌阶段
	playing： 打牌阶段： 定缺完成后，摸牌、出牌，本局完成之前
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
--###_test
local run=true

local normal_zy_mj_kaiguan={
	qing_yi_se 		= true,
	da_dui_zi 		= true,
	qi_dui			= true,
	long_qi_dui		= true,
	--将对
	jiang_dui       = true,
	men_qing		= true,
	zhong_zhang		= true,
	jin_gou_diao    = true,
	yao_jiu	 		= true, 


	-- 其它：和胡牌方式相关的
	hai_di_ly 		= true, -- 海底捞月 最后一张牌胡牌（自摸）
	hai_di_pao 		= true, -- 海底炮  最后一张牌胡牌（被人点炮）
	tian_hu 		= false, -- 天胡：庄家，第一次发完牌既胡牌,change by wss 血流不能天胡
	di_hu	 		= true, -- 地胡：非庄家第一次发完牌 既自摸或 被别人点炮
	gang_shang_hua  = true, -- 杠上花：自己杠后补杠自摸
	gang_shang_pao  = true, -- 杠上炮：别人杠后补杠点炮
	zimo            = true, -- 自摸
	qiangganghu     = true, -- 抢杠胡 
	zimo_jiafan     = true, -- 自摸加翻 
	zimo_jiadian    = nil, -- 自摸加点
	zimo_bujiadian  = nil,  --自摸不加
 	max_fan         = nil,   --封顶番数	
}

local normal_zy_mj_multi={
	-- 牌型
	qing_yi_se 		= 2,
	da_dui_zi 		= 1,
	qi_dui			= 2,
	long_qi_dui		= 3,

	dai_geng 		= 1,
	
	jiang_dui       = 3, --将对
	men_qing		= 1, --门清
	zhong_zhang		= 1, --中章
	jin_gou_diao    = 1, --金钩钓
	yao_jiu	 		= 2, --幺九

	-- 其它：和胡牌方式相关的
	hai_di_ly 		= 1, -- 海底捞月 最后一张牌胡牌（自摸）
	hai_di_pao 		= 1, -- 海底炮  最后一张牌胡牌（被人点炮）
	tian_hu 		= 5, -- 天胡：庄家，第一次发完牌既胡牌
	di_hu	 		= 5, -- 地胡：非庄家第一次发完牌 既自摸或 被别人点炮
	gang_shang_hua  = 1, -- 杠上花：自己杠后补杠自摸
	gang_shang_pao  = 1, -- 杠上炮：别人杠后补杠点炮
	zimo            = 1, -- 自摸
	qiangganghu     = 1, -- 抢杠胡 
}


-- 等待时间定义
local fapai_time=2	-- 发牌动画
local chu_pai_time=2 -- 出牌动画
local pg_pai_time=0 -- 碰杠动画
local tou_sezi_time = 5 -- 投色子动画
local chupai_cd=16 -- 出牌 倒计时
local dingque_cd=16 -- 定缺 倒计时
local peng_gang_hu_cd = 10 -- 碰杠胡选择 倒计时

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

-- 转换番数为倍数
local function trans_mul_total(_mul)
	return floor(2 ^ _mul + 0.5)
end

local function next_oper_seat(_d,_cur_seat)
	return fmod(_cur_seat,SEAT_COUNT) + 1
	-- for i=1,SEAT_COUNT do
	-- 	_cur_seat = fmod(_cur_seat,SEAT_COUNT) + 1

	-- 	-- 未胡牌的 才有发言权
	-- 	if not _play_data[_cur_seat].hu_order then
	-- 		return _cur_seat
	-- 	end
	-- end

	-- return nil
end

local function new_game(_t_num)
	local _d=game_table[_t_num]
	if not _d then
		return false
	end

	nor_mj_room_lib.dev_debug = skynet.getcfg("dev_debug")

	local print_str = "======== player seats ===============\n"
	for _seat_num,_id in pairs(_d.p_seat_number) do
		print_str = print_str .. "  user id:" .. tostring(_id) .. ",seat:" .. tostring(_seat_num) .. "\n"
	end
	print(print_str)

	_d.on_line_player=basefunc.deepcopy(_d.p_seat_number)

	_d.cur_race_num=_d.cur_race_num+1

	-- 已胡牌的人数
	_d.hu_num = 0

	_d.time=0
	_d.play_data=nor_mj_room_lib.new_game()

	--[[
	每个玩家的结算数据（数组）
	{
		-- 结算类型： "hu" 胡牌，"ting" 听牌（已听牌，但没胡），"wujiao" 无叫，"hz" 花猪（未打缺）
		settle_type = "hu"
		
		-- 胡牌数据： 多次胡牌的数组
		hu_datas = {
			{
				-- 胡牌类型："zimo" 自摸, "pao" 点炮， "qghu" 抢杠胡
				hu_type = "zimo"

				-- 胡牌 收哪些人的钱：点炮 或 被自摸的人
				hu_others = {seat1,seat2}

				-- 牌的番型： MULTI_TYPES
				pai_multi = {}

				-- 完整的胡牌 数据
				hu_all_data = nil

				-- 总番数
				sum_multi = 0

				-- 总倍数
				total = 0
			},
			...
		}

		-- 听牌 map ：首次胡牌后固定听牌信息；
		ting_pai_map = nil

		-- 分数
		score = 0

		-- 总番数
		sum_multi = 0

		-- 杠的加减分数据，数组： {gang_type="zg"/"ag",pai=,mul=番数,others={seat1,seat2}}
		-- 注意：弯杠(wg) 不产生金额改变，所以不记录
		gang_score = {}
	}
	--]]
	_d.s_info={}
	nor_mj_room_lib.reset_seat_data(_d.s_info,{sum_multi=0,gang_score={},hu_datas={},score=0})

    --[[ 玩家权限信息，数组
        数据： {
        cp=true,ag=true,zg=true,wg=true,peng=true,
        hu=get_peng_gang_hu 返回的值,
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
	-- 这个貌似没用了 _d.cur_chupai={p=nil,pai=nil}

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
	-- 杠上花，杠上炮 标志：记录最近杠牌的人，出牌/摸牌 未胡牌 后清除
	_d.last_gang_seat = nil

	-- ###_test
	change_status(_t_num,"wait",1,"tou_sezi")

	--记录游戏开始日志
	PUBLIC.save_race_start_log(_d,_t_num)

end

-- 投色子 定庄家
local function status_tou_sezi(_t_num)
	local _d = game_table[_t_num]

	local _sezi1 = random(1,6)
	local _sezi2 = random(1,6)

	_d.play_data.zhuang_seat = fmod(_sezi1+_sezi2,SEAT_COUNT) + 1
	
	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nmjxlfg_tou_sezi_msg",_sezi1,_sezi2,_d.play_data.zhuang_seat,tou_sezi_time)
	end

end

local function status_fapai(_t_num)
	local _d = game_table[_t_num]

	local _fapai_num = 4
	
	nor_mj_room_lib.fapai(_d.play_data,_d.play_data.zhuang_seat,_fapai_num)

	local remain_card = nor_mj_room_lib.pai_count(_d.play_data)

	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nmjxlfg_pai_msg",_d.play_data[_seat_num].pai,remain_card)
	end

	change_status(_t_num,"wait",fapai_time,"ding_que")

end


local function get_pgh(_d,_seat_num,_pai)

	local hu=_d.mj_algo:get_hupai_all_info(_d.play_data[_seat_num].pai,
												_d.play_data[_seat_num].pg_type,
												_d.play_data.p_ding_que[_seat_num],
												_d.action_list,
												_seat_num,
												_d.zhuang_seat,
												_d.p_mopai_count[_seat_num],
												_d.p_cp_count[_seat_num],
												nor_mj_room_lib.pai_count(_d.play_data))


	local pai_count = _d.play_data[_seat_num].pai[_pai] or 0
	-- dump({pai=_d.play_data[_seat_num].pai,
	-- 	pg_type=_d.play_data[_seat_num].pg_type,
	-- 	ding_que=_d.play_data.p_ding_que[_seat_num],
	-- 	seat=_seat_num,cur_pai=_pai,pai_count = pai_count,
	-- 	hu_result=hu},"get_hupai_all_info ##### result")
	--print(_pai,pai_count,"_pai***---pai_count")
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
		if pai_count > 2 and nor_mj_room_lib.pai_count(_d.play_data) > 0 then
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
		for i=1,SEAT_COUNT do
			_d.play_data.wait_pengganghu_data[i] = nil
			_d.play_data.wait_hu_data[i] = nil
		end
	else
		_d.play_data.wait_pengganghu_data[_seat_num] = nil
		_d.play_data.wait_hu_data[_seat_num] = nil
	end
end


-- 处理加分和扣分
-- 参数 _mul ： 番数
local function deal_change_score(_d,_seat_num,_total,_others)
	local _score = _total * _d.game_config.base_score

	local _grades_change = {}

	-- 别人减钱
	local _score_sum = 0
	for _,_loser in ipairs(_others) do

		local deduct = nodefunc.call(_d.p_seat_number[_loser],"normal_mjxl_deduct_lose",-_score)

		if deduct == 0 then
			print("deal_change_score deduct warning: is zero!")
		end

		_d.s_info[_loser].score = _d.s_info[_loser].score + deduct

		print("deal_change_score deduct : seat_num,score,other,deduct,cur_score:",_seat_num,_score,_loser,deduct,_d.s_info[_loser].score)

		_grades_change[#_grades_change+1] = {cur_p=_loser,grades=deduct}
		_score_sum = _score_sum + deduct
	end

	-- 自己加钱
	_score_sum = floor(abs(_score_sum) + 0.5)
	_d.s_info[_seat_num].score = _d.s_info[_seat_num].score + _score_sum

	-- 加钱的可能不在了（退税）
	if _d.play_data[_seat_num].is_quit then
		--###_temp ： 日志 id 应该获得 对局日志 id
		print("deal_change_score add_win(to data_service) : seat_num,score_sum,cur_score:",_seat_num,_score_sum,_d.s_info[_seat_num].score)
		skynet.send(DATA.service_config.data_service,"lua","change_asset_and_sendMsg",
			_d.p_seat_number[_seat_num],PLAYER_ASSET_TYPES.DIAMOND,_score_sum,ASSET_CHANGE_TYPE.MAJIANG_FREESTYLE_REFUND,_d.game_id)
	else
		print("deal_change_score add_win(to player_agent) : seat_num,score_sum,cur_score:",_seat_num,_score_sum,_d.s_info[_seat_num].score)
		nodefunc.send(_d.p_seat_number[_seat_num],"normal_mjxl_add_win",_score_sum)
	end

	_grades_change[#_grades_change+1] = {cur_p=_seat_num,grades=_score_sum}

	-- 给每个人发 钱变化
	for _s,_id in pairs(_d.on_line_player) do
		nodefunc.send(_id,"normal_mjxl_grades_change_msg",_grades_change)
	end
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


-- 结算 收集 信息
local function settle_gen_datas(_d, _settle_datas,_ting_settles,_wujiao_settles )

	-- 按座位循环
	for _seat = 1,SEAT_COUNT do
		local _p_data = _d.play_data[_seat]
		local _s_info = _d.s_info[_seat]
		local _settle = {
			seat_num = _seat,
			settle_data = {},
			shou_pai = nor_mj_base_lib.get_pai_list_by_map(_p_data.pai),
			pg_pai = settle_get_pg_pai(_s_info,_p_data),
		}

		if _p_data.hu_order then
			_settle.settle_type = "hu"
			_settle.settle_data = {}
			for _,_hu_data in ipairs(_s_info.hu_datas) do
				_settle.settle_data[#_settle.settle_data + 1] = {
					hu_type = _hu_data.hu_type,
					hu_pai = _hu_data.hu_all_data.hu_pai,
					multi = _hu_data.pai_multi,
					sum_multi = _hu_data.hu_all_data.mul,
					sum = _hu_data.hu_all_data.total,
				}
			end

			_settle.sum_multi = _s_info.sum_multi
			_settle.sum = _s_info.total
		else
			local _ting_info = _d.mj_algo:get_max_ting_all_info(
				_p_data.pai,_p_data.pg_pai,
				_d.play_data.p_ding_que[_seat])
			if _ting_info then

				_settle.settle_type = "ting"
				_settle.settle_data = {}

				_settle.settle_data[1] = {
					hu_pai = _ting_info.hu_pai,
					multi = _ting_info.hu_type_info,
					sum_multi = _ting_info.mul,
					sum = _ting_info.total,
				}
				_settle.sum_multi = _ting_info.mul

				_s_info.pai_multi = _ting_info.hu_type_info
				_s_info.total = _ting_info.total

				_ting_settles[#_ting_settles + 1] = _settle

			else
				-- 花猪
				if (_p_data.pai[_d.play_data.p_ding_que[_seat]] or 0) > 0 then
					_settle.settle_type = "hz"
				else
					-- 无叫
					_settle.settle_type = "wujiao"
				end

				_wujiao_settles[#_wujiao_settles + 1] = _settle
			end

			_s_info.settle_type = _settle.settle_type
		end

		_p_data.settle_type=_settle.settle_type
		
		_settle_datas[#_settle_datas + 1] = _settle
	end	
end

-- 查叫：计算查叫输赢的 钱
local function settle_cha_jiao(_d, _ting_settles,_wujiao_settles )

	-- 查叫，两个 以上的人未胡牌
	if _d.hu_num < (SEAT_COUNT - 1) then

		for _,_wujiao in ipairs(_wujiao_settles) do

			-- 赔有叫的
			for _,_ting in ipairs(_ting_settles) do
				local _total = assert(_d.s_info[_ting.seat_num].total)

				-- 如果是花猪，则至少赔 16 倍（4番）
				if _wujiao.settle_type == "hz" and _total < 16 then
					_total = 16
				end

				deal_change_score(_d,_ting.seat_num,_total,{_wujiao.seat_num})
			end

			-- 花猪賠不是花猪的，直接賠 16 倍
			if _wujiao.settle_type == "hz" then
				for _,_wujiao2 in ipairs(_wujiao_settles) do
					if _wujiao2.settle_type ~= "hz" then
						deal_change_score(_d,_wujiao2.seat_num,16,{_wujiao.seat_num})
					end
				end
			end
		end

		-- -- 无叫的赔有叫的
		-- if _ting_settles[1] and _wujiao_settles[1] then
		-- 	for _,_ting in ipairs(_ting_settles) do
		-- 		for _,_wujiao in ipairs(_wujiao_settles) do

		-- 			local _total = assert(_d.s_info[_ting.seat_num].total)

		-- 			-- 如果是花猪，则至少赔 16 倍（4番）
		-- 			if _wujiao.settle_type == "hz" and _total < 16 then
		-- 				_total = 16
		-- 			end

		-- 			deal_change_score(_d,_ting.seat_num,_total,{_wujiao.seat_num})
		-- 		end
		-- 	end
		-- end

		-- 无叫的退杠的 钱  {gang_type="zg"/"ag",pai=,mul=番数,others={seat1,seat2}}
		for _,_settle in ipairs(_wujiao_settles) do
			for _,gang in ipairs(_d.s_info[_settle.seat_num].gang_score) do
				if gang.others and next(gang.others) then
					for _,other in ipairs(gang.others) do
						deal_change_score(_d,other,trans_mul_total(gang.mul),{_settle.seat_num})
					end
				else
					-- dump(_d.s_info[_settle.seat_num],"settle chajiao error:")
				end
			end
		end
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
	settle_cha_jiao(_d,_ting_settles,_wujiao_settles)

	-- 总分
	for _,_settle in pairs(settle_datas) do
		_settle.score = _d.s_info[_settle.seat_num].score
	end

	-- 按胡牌顺序排序
	table.sort(settle_datas,function(_v1,_v2)
		return (_d.play_data[_v1.seat_num].hu_order or 100)  < (_d.play_data[_v2.seat_num].hu_order or 100)
	end)

	-- dump(settle_datas,"status_settlement --------------- msg:")

	-- 发送结算消息
	for _seat_num,_id in pairs(_d.on_line_player) do
		if not _d.play_data[_seat_num].is_quit then
			nodefunc.send(_id,"nmjxlfg_gameover_msg",settle_datas)
		end
	end

	PUBLIC.save_race_over_log(_d,_t_num)
	
	change_status(_t_num,"gameover")
	

	nodefunc.send(DATA.mgr_id,"table_finish",DATA.my_id,_t_num)

	return_table(_t_num)

end



-- ###_test
function CMD.new_table(_game_config)
	local _t_num=employ_table()
	if not _t_num then 
		return false
	end
	local _d={}
	_d.game_config=_game_config

	_d.time=0
	_d.play_data=nor_mj_room_lib.new_game()

	_d.p_info={}
	--玩家进入房间的标记
	_d.players_join_flag={}
	_d.p_seat_number={}  -- 座位号为下标，玩家 id 为值
	_d.p_count=0
	_d.p_ready=0

	--游戏类型  0为 练习场  1为钻石场
	_d.game_model=_game_config.game_model or 0 

	_d.init_rate=_game_config.init_rate or 1
	_d.init_stake=_game_config.base_score or 1
	--比赛次数
	_d.race_count=_game_config.race_count or 1
	_d.cur_race_num=0

	--比赛id
	_d.game_id=_game_config.game_id or 0

	-- 游戏算法对象
	_d.mj_algo = nor_mj_algorithm.new(normal_zy_mj_kaiguan,normal_zy_mj_multi)

	_d.p_auto={}

	game_table[_t_num]=_d

	if DATA.service_config.chat_service then
		_d.chat_room_id = skynet.call(DATA.service_config.chat_service,"lua","create_room")
	end

	print("new table ,base_score,game_model,init_rate:",_d.game_config.base_score,_d.game_model,_d.init_rate)

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

function CMD.quit_room(_t_num,_seat_num)
	local _d = game_table[_t_num]
	if not _d then
		--房间已经没有了
		return 0
	end
	_d.play_data[_seat_num].is_quit = true
	_d.on_line_player[_seat_num]=nil
end

-- 准备
local function ready(_t_num)
	local _d = game_table[_t_num]
	_d.p_ready=_d.p_ready+1
	if _d.p_ready==SEAT_COUNT then
		new_game(_t_num)
	end
end

function CMD.join(_t_num,_p_id,_info)
	local _d=game_table[_t_num] 
	if not _d or _d.p_count>SEAT_COUNT-1 or _d.status~="wait_p" or _d.players_join_flag[_p_id] then
		return {result=1002}
	end

	for _seat_num=1,SEAT_COUNT do
		if not _d.p_seat_number[_seat_num] then
			_d.players_join_flag[_p_id]=true 
			_d.p_seat_number[_seat_num]=_p_id
			_d.p_count=_d.p_count+1
			_d.p_info[_seat_num]=_info
			_d.p_info[_seat_num].seat_num=_seat_num

			print("join room. room,table,user id,seat:",DATA.my_id,_t_num,_p_id,_seat_num)

			--通知其他人 xxx 加入房间
			for _,_value in pairs(_d.p_info) do
				nodefunc.send(_value.id,"nmjxlfg_join_msg",_d.p_count,_info,_d.chat_room_id)
			end

			--自动准备
			ready(_t_num)

			return {result=0,seat_num=_seat_num,p_info=_d.p_info,p_count=_d.p_count,
					rate=_d.init_rate,race_count=_d.race_count,race=_d.cur_race_num,init_stake=_d.init_stake}
		end
	end

	return {result=1001}
end


local function status_ding_que(_t_num)
	local _d = game_table[_t_num]

	PUBLIC.save_normal_mjxl_process_get_permit_time(_d,_t_num)

	_d.p_action_done={true,true,true,true}
	-- 发送权限：每个人同时定缺，所以不传当前用户
	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nmjxlfg_dingque_permit",dingque_cd)
	end
end

local function status_ding_que_finish(_t_num)
	local _d = game_table[_t_num]

	-- dump(_d.play_data.p_ding_que,"//////////********---ding_que----")

	for _s,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nmjxlfg_ding_que_msg",_d.play_data.p_ding_que)
	end

	change_status(_t_num,"wait",1,"start")
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

	-- 如果每个人都定缺完成
	if nor_mj_room_lib.is_ding_que_finished(_d.play_data.p_ding_que) then
		
		change_status(_t_num,"wait",0.5,"ding_que_finish")
	end

	return 0
end

local function status_chu_pai(_t_num)
	local _d = game_table[_t_num]

	PUBLIC.save_normal_mjxl_process_get_permit_time(_d,_t_num)

	_d.play_data.cur_chupai = nil

	_d.p_action_done[_d.play_data.cur_p]=true
	_d.p_permit[_d.play_data.cur_p]={cp=true}

	-- 发送 出牌权限
	for _seat_num,_id in pairs(_d.on_line_player) do
		--if not _d.play_data[_seat_num].hu_order then
			nodefunc.send(_id,"nmjxlfg_chupai_permit",_d.play_data.cur_p,chupai_cd)
		--end
	end

end

-- 庄家开始出牌
local function start_cp(_t_num)
	local _d = game_table[_t_num]

	PUBLIC.save_normal_mjxl_process_get_permit_time(_d,_t_num)

	local _p=_d.play_data.zhuang_seat
	_d.play_data.cur_p =_p

	local is_hu = false

	--动作标记
    _d.p_action_done[_p] =true
	_d.p_permit[_p]={cp=true,hu=res}
	-- 发送 权限
	for _seat_num,_id in pairs(_d.p_seat_number) do
		nodefunc.send(_id,"nmjxlfg_start_permit",_p,is_hu,chupai_cd)
	end

end


local function status_mo_pai(_t_num)
	local _d = game_table[_t_num]

	-- 牌摸完，进入结算
	if _d.play_data.pai_empty then
		change_status(_t_num,"settlement")
		return
	end

	--（血流直到 最后一张牌）胡的人达到3个了 进入结算  
	-- if _d.hu_num and _d.hu_num > 2 then
	-- 	change_status(_t_num,"settlement")
	-- 	return
	-- end

	PUBLIC.save_normal_mjxl_process_get_permit_time(_d,_t_num)

	local _cur_data = _d.play_data[_d.play_data.cur_p]

	-- 过手胡
	_d.p_ignore_hu[_d.play_data.cur_p] = nil

	-- 得到一张牌
	_cur_data.mo_pai = nor_mj_room_lib.pop_pai(_d.play_data)
	_cur_data.pai[_cur_data.mo_pai] = (_cur_data.pai[_cur_data.mo_pai] or 0) + 1
	
	--摸牌此时加1
	local mo_pai_num = _d.p_mopai_count[_d.play_data.cur_p]+1
	_d.p_mopai_count[_d.play_data.cur_p]=mo_pai_num

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

	local remain_card = nor_mj_room_lib.pai_count(_d.play_data)

	_d.p_action_done[_d.play_data.cur_p]=true
	_d.p_permit[_d.play_data.cur_p]={cp=true,hu=hu_data}

	-- 发送 摸牌权限
	for _seat_num,_id in pairs(_d.on_line_player) do
		local _pai = 0
		if _seat_num==_d.play_data.cur_p then
			_pai = _cur_data.mo_pai
		end
		nodefunc.send(_id,"nmjxlfg_mopai_permit",_d.play_data.cur_p,_pai,is_hu,chupai_cd,remain_card)
	end

end



local function deal_guo(_t_num)
	local _d = game_table[_t_num]
	local act = _d.action_list[#_d.action_list]
	local _seat_num = act.p
	
	_d.p_permit[act.p]={}

	print("deal_guo****-----",_t_num)

	while true do
		_seat_num = _seat_num + 1
		if _seat_num > 4 then _seat_num = 1 end

		--if not _d.play_data[_seat_num].hu_order then

			_d.play_data.cur_p = _seat_num
			
			change_status(_t_num,"mo_pai")

			print("deal_guo****--mp---",_seat_num)

			break
		--end

	end

end

local function deal_chu_pai(_t_num,_seat_num,_pai)
	local _d = game_table[_t_num]
	_d.p_permit_pgh_count = 0
	_d.p_permit_h_count = 0

	-- 计算其他人 对此牌的碰杠胡权限进行记录
	for _s,_id in pairs(_d.on_line_player) do

		-- 血流胡牌后不能直杠
		if _seat_num ~= _s then

			local _pgh = get_pgh(_d,_s,_pai)

			-- dump(_pgh,"_pgh***--------".._id)

			-- 过手胡
			if _pgh and _pgh.hu and _d.p_ignore_hu[_s] and _d.p_ignore_hu[_s].pai == _pai and 
				_pgh.hu.mul <= _d.p_ignore_hu[_s].mul then
				
				_pgh.hu = nil

				if not next(_pgh) then
					_pgh = nil
				end
			end

			-- 已经胡牌，不能再直杠
			if _pgh and _d.play_data[_s].hu_order then
				_pgh.gang = nil
				_pgh.peng = nil
			end

			if _pgh and next(_pgh) then

				_d.p_action_done[_s]=true
				_d.p_permit[_s]=_pgh

				--附加过权限
				_d.p_permit[_s].guo=true
				
				_d.p_permit_pgh_count=_d.p_permit_pgh_count+1

				if _pgh.hu then
					_d.p_permit_h_count = _d.p_permit_h_count + 1
				end

				--分发权限消息
				nodefunc.send(_id,"nmjxlfg_peng_gang_hu_permit",
								_pai,
								_pgh,
								peng_gang_hu_cd)
			end
			

		end

	end


	PUBLIC.save_normal_mjxl_process_get_permit_time(_d,_t_num)

	if _d.p_permit_pgh_count < 1 then
		deal_guo(_t_num)
	else
		_d.status = "peng_gang_hu"
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

	-- 发送出牌 action 通知
	for _s,_id in pairs(_d.on_line_player) do
		nodefunc.send(_id,"nmjxlfg_chu_pai_msg",act)
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

	PUBLIC.save_process_data_log(_d,_t_num,act.p,4,_pai)

	-- 发送碰牌通知
	for _s,_id in pairs(_d.on_line_player) do
		nodefunc.send(_id,"nmjxlfg_peng_msg",act)
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
    	_seat_num = next_oper_seat(_d,_action1.hu_data.dianpao_p)
    else
    	_seat_num = _action1.p
    end

    -- print("deal_hu:",debug.traceback())
    -- dump(_actions,"deal_hu actions:")

    for i=1,SEAT_COUNT do

        local _act = _actions[_seat_num]
        if _act then

            local _play_data = _d.play_data[_seat_num]

            -- 首次胡牌的 顺序
            if not _play_data.hu_order then
	            _d.hu_num = _d.hu_num + 1
	            _play_data.hu_order = _d.hu_num
	        end

            local _s_hu_data = {}

            if _act.hu_data.hu_type == "zimo" then
                _s_hu_data.hu_others = {}

                for _seat=1,SEAT_COUNT do
                    if _seat ~= _seat_num then
                        _s_hu_data.hu_others[#_s_hu_data.hu_others+1] = _seat
                    end
                end

                -- 把牌取出来
                if _act.hu_data.pai then
					_play_data.pai[_act.hu_data.pai] = _play_data.pai[_act.hu_data.pai] - 1
				end

            elseif _act.hu_data.hu_type == "pao" then
                _s_hu_data.hu_others = {_act.hu_data.dianpao_p}

            elseif _act.hu_data.hu_type == "qghu" then  
                _s_hu_data.hu_others = {_act.hu_data.dianpao_p}
            end

            _s_hu_data.pai_multi = _act.hu_all_data.hu_type_info
            _s_hu_data.sum_multi = _act.hu_all_data.mul
            _s_hu_data.total = _act.hu_all_data.total
            deal_change_score(_d,_seat_num,_act.hu_all_data.total,_s_hu_data.hu_others)

            _s_hu_data.hu_type = _act.hu_data.hu_type
            _s_hu_data.hu_all_data = _act.hu_all_data
           
            local _s_data = _d.s_info[_seat_num]

            -- 得到听牌信息
            if not _s_data.ting_pai_map then
            	_s_data.ting_pai_map = _d.mj_algo:get_ting_map_info(
            		_play_data.pai,_play_data.pg_pai,
            		_d.play_data.p_ding_que[_seat_num])
            end

            _s_data.sum_multi = _s_data.sum_multi + _act.hu_all_data.mul

            table.insert(_s_data.hu_datas,_s_hu_data)

            _d.action_list[#_d.action_list+1]=_act

            -- 发送胡牌信息
            _act.hu_all_data = nil
            for _,_id in pairs(_d.on_line_player) do
                nodefunc.send(_id,"nmjxlfg_hu_msg",_act)
            end
            _act.hu_all_data = _s_hu_data.hu_all_data
        end

        -- 下一个
        _seat_num = next_oper_seat(_d,_seat_num)
    end

    PUBLIC.save_process_data_log(_d,_t_num,_action1.p,6,_action1.hu_data.pai)

    deal_guo(_t_num)
end


-- 记录杠的分数
local function record_gang_score(_d,_seat_num,_type,_pai,_mul,_others)

	if not _others or not next(_others) then
		dump({s_info=_d.s_info[_seat_num],_seat_num=_seat_num,_type=_type,_pai=_pai,_mul=_mul,_others=_others},"record_gang_score error:")
		return
	end

	local _gang_data = _d.s_info[_seat_num].gang_score
	_gang_data[#_gang_data + 1] = {gang_type=_type,pai=_pai,mul=_mul,others=_others }

	-- 加钱 扣钱
	return deal_change_score(_d,_seat_num,trans_mul_total(_mul),_others)
end

local function get_seat_others(_d,_seat_num)

	local _others = {}
	for i=1,SEAT_COUNT do
		-- 排除自己和 已经胡牌的
		--if i ~= _seat_num and not _d.play_data[i].hu_order then
		if i ~= _seat_num then
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
		nodefunc.send(_id,"nmjxlfg_gang_msg",act)
	end

	PUBLIC.save_process_data_log(_d,_t_num,act.p,5,act.pai)

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
		nodefunc.send(_id,"nmjxlfg_gang_msg",act)
	end
	
	_d.qgh_permit_count=0
	--查看是否有人可以抢杠胡
	for _s,_id in pairs(_d.on_line_player) do
		--if not _d.play_data[_s].hu_order and _s~=_t_num then
		if _s~=_t_num then
			local res=_d.mj_algo:get_hupai_all_info(_d.play_data[_s].pai,
												_d.play_data[_s].pg_type,
												_d.play_data.p_ding_que[_s],
												_d.action_list,
												_s,
												_d.play_data.zhuang_seat,
												_d.p_mopai_count[_s],
                        						_d.p_cp_count[_s],
												nor_mj_room_lib.pai_count(_d.play_data))
			if res then
				_d.p_permit[_s]={guo=true,hu=res}
				_d.qgh_permit_count=_d.qgh_permit_count+1
				_d.p_action_done[_s]=true
				--分发权限消息
				nodefunc.send(_id,"nmjxlfg_peng_gang_hu_permit",
								act.pai,
								{hu=true},
								peng_gang_hu_cd)
			end
		end
	end

	PUBLIC.save_normal_mjxl_process_get_permit_time(_d,_t_num)

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
            deal_hu(_t_num,_d.pgh_manager.wait_hu_actions)print("*111***********----------")
        elseif _d.pgh_manager.wait_pg_action then
            if "peng" == _d.pgh_manager.wait_pg_action.type then
                deal_peng_pai(_t_num,_d.pgh_manager.wait_pg_action)print("*222***********----------")
            else
                deal_gang(_t_num,_d.pgh_manager.wait_pg_action)print("*333***********----------")
            end
        else
            deal_guo(_t_num)print("*444***********----------")
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

	return 0
end


function CMD.gang_pai(_t_num,_seat_num,_gang_type,_pai)
	local _d = game_table[_t_num]
	if not _d.p_action_done[_seat_num] then
		return 1002
	end

	
	if _d.s_info[_seat_num].ting_pai_map then
		local status=_d.mj_algo:check_xueliu_hu_gang(_d.play_data[_seat_num].pai,
														_d.play_data[_seat_num].pg_type,
														_d.play_data.p_ding_que[_seat_num],
														_pai,
														_d.s_info[_seat_num].ting_pai_map)
		if not status then
			return 1002
		end
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
	return 0
end


function CMD.hu_pai(_t_num,_seat_num)
	local _d = game_table[_t_num]

	if not _d.p_action_done[_seat_num] then
		return 1002
	end
	_d.p_action_done[_seat_num]=nil	

	local hu_info=_d.p_permit[_seat_num].hu
	local hu_type
	if not hu_info.dianpao_p then
		hu_type="zimo"
	elseif hu_info.hu_type_info.qiangganghu then
		hu_type="qghu"
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
	print("CMD.hu_pai ----- :",hu_type,_t_num,_seat_num)
	if hu_type=="zimo" then
		deal_hu(_t_num,{[_seat_num]=act})
	elseif hu_type=="qghu" then
		qiang_gang_hu_manager(_t_num,act)
	else
		peng_gang_hu_manager(_t_num,act)
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
		nodefunc.send(_id,"nmjxlfg_auto_msg",_seat_num,_type)
	end

	print("room CMD.auto ",_t_num,_seat_num,_type)

	--记录过程数据日志
	-- PUBLIC.save_process_data_log(_d,_t_num,_seat_num,_type==1 and 7 or 8)

	return 0
end

local dt=0.5
local function update()
	while run do

		for _t_num,_value in pairs(game_table) do
			local _d = game_table[_t_num]
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

local function _change_status_impl(_t_num,_status,_time,_next_status)
	assert(game_table[_t_num])
	print("change_status  : ",_t_num,_status,DATA.my_id,_time,_next_status)
	if _status=="wait_p" then
		game_table[_t_num].status=_status
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
	elseif _status=="ding_que" then
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
	end
end

change_status = _change_status_impl
-- change_status = function (...)

-- 	local ok,ret_data = xpcall(_change_status_impl,function(_err_msg)
-- 		print(debug.traceback(_err_msg))
-- 	end,...)

-- 	if not ok then
-- 		print("change_status:",ret_data)
-- 	end

-- end

function CMD.start(_id,_ser_cfg,_config)
	math.randomseed(os.time()*86579)
	DATA.service_config =_ser_cfg
	node_service=_ser_cfg.node_service
	DATA.table_count=10
	DATA.my_id=_id
	DATA.mgr_id=_config.mgr_id

	--dump(DATA,"mjxl room started:")

	--init table
	for i=1,DATA.table_count do 
		table_list[#table_list+1]=i
	end

	skynet.fork(update)
	return 0
end

-- 启动服务
base.start_service()






