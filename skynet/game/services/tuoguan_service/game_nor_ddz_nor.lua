-- Author: lyx
-- Date: 2018/10/10
-- Time: 10:52
-- 说明：斗地主的托管逻辑
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"

local nor_ddz_base_lib = require "nor_ddz_base_lib"
local nor_ddz_algorithm_lib = require "nor_ddz_algorithm_lib"
local tuoguan_enum = require "tuoguan_service.tuoguan_enum"


require"printfunc"

local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC

local PROTECTED = {}
local MSG = {}

DATA.ddz_nor_data = DATA.ddz_nor_data or {

	-- 当前打牌的信息
	play_data=nil,

	-- 算法库实例
	nor_ddz_algorithm = nil,

	-- 自己手上的牌
	--my_card_land_list = nil,

	-- 自己牌的值映射： 值 => 张数
	my_card_value_map = nil,

	-- 抢地主次数（二人 斗地主）
	qdz_count = 0,

	-- 状态信息
	s_info = nil,

	-- 特殊处理座位
	special_deal_seat_is_me = nil,

	-- 水池控制状态
	profit_wave_status = nil,

	-- 每个玩家的出牌次数
	p_out_counts = {},
}

local D = DATA.ddz_nor_data

local ddz_tuoguan=require "ddz_tuoguan.ddz_tuoguan"

local function reset_s_info()
	D.s_info = {

		jdz_info = nil, -- 最近一次的叫地主 信息 {p=seat,rate=}

		dizhu = nil, -- 地主

		-- 焖拉倒 数据
		is_men_zhua=nil,
		dao_la_data={-1,-1,-1},
		men_data={0,0,0}, --0-nil  1-不操作  2-是操作
		zhua_data={0,0,0},	--is_must = nil,	-- 是否必须出（首位出牌者）
	}
end

-- 是否叫地主（三人）
-- local function get_jiaodizhu(pai_map)
-- 	local boom = 0
-- 	local zhu = 0
-- 	for i = 1, 14 do
-- 		if pai_map[i] and pai_map[i] == 4 then
-- 			boom = boom + 1
-- 		end
-- 	end
-- 	for i = 15, 17 do
-- 		if pai_map[i] then
-- 			zhu = zhu + pai_map[i]
-- 		end
-- 	end

-- 	if zhu + boom > 2 or boom > 1 then
-- 		return true
-- 	end

-- 	if pai_map[16] and pai_map[17] and pai_map[16] == 1 and pai_map[17] == 1 then
-- 		return true
-- 	end

-- 	return false
-- end

function PUBLIC.get_last_jdz_rate()
	if D.s_info.jdz_info then
		return D.s_info.jdz_info.rate or 0
	else
		return 0
	end
end


function PUBLIC.reset_playing_data()

	D.my_card_value_map = nil
	--D.my_card_land_list = nil

	reset_s_info()
	
	D.nor_ddz_algorithm = nor_ddz_algorithm_lib.new(nil,DATA.game_info.game_type)

	for i=1,DATA.seat_count do
		D.p_out_counts[i] = 0
	end

	D.play_data=ddz_tuoguan.TPlayData:new()

	D.play_data:set_is_eren(DATA.game_info.game_type == "nor_ddz_er")


end

-- nor_ddz_mld_dizhu_pai_msg
function MSG.nor_ddz_nor_ready_msg(_data)

	if PUBLIC.on_game_ready_msg then
		PUBLIC.on_game_ready_msg(_data.seat_num,_data.cur_race)
	end

end

-- 产生地主
function MSG.nor_ddz_nor_dizhu_msg(_data)

	D.s_info.dizhu = _data.dz_info.dizhu
	D.play_data:set_dzseatid(_data.dz_info.dizhu,_data.dz_info.rangpai_num)

	if _data.dz_info.dz_pai then 
		D.play_data:add_seatcards(_data.dz_info.dizhu,_data.dz_info.dz_pai)
	else 
		dump(DATA.ddz_nor_data)
		error("no dizhi pai")
	end

end

-- 玩家的动作通知
function MSG.nor_ddz_nor_action_msg(_data)

	-- 出牌
	if _data.action.type < 100 then

		if 0 ~= _data.action.type then
			D.play_data:do_playcards(_data.action.p,_data.action.cp_list.nor)
		end
		-- 叫地主
	elseif _data.action.type == nor_ddz_base_lib.other_type.jdz then
		D.s_info.jdz_info = _data.action

		-- 加倍
		--elseif _data.action.type == nor_ddz_base_lib.other_type.jiabei then

	elseif _data.action.type == nor_ddz_base_lib.other_type.mld_men then
		D.s_info.men_data[_data.action.p] = 2
	elseif _data.action.type == nor_ddz_base_lib.other_type.mld_kp then
		D.s_info.men_data[_data.action.p] = 1
	end
end

-- 计算是否抓牌
-- 返回 1 / 0
function PUBLIC.get_mld_zhua_pai_opt(_data)
	-- 必须抓
	if _data.other then
		return 1
	end

	-- 不能抓： 两个 托管，自己不是 发好牌的 那个！
	if (not D.special_deal_seat_is_me) and D.special_deal_seat then
		return 0
	end

	-- 评估牌 分数
	if ddz_tuoguan.get_nor_ddz_xiaojiao_score(true, D.play_data,D.profit_wave_status) > 2 then
		return 1
	end

	return 0
end

-- 计算 地主 叫分
-- 不叫 返回 0
function PUBLIC.get_dizhu_level(_data)

	if D.special_deal_seat_is_me then
		return 3
	end

	-- 不能叫： 两个 托管，自己不是 发好牌的 那个！
	if (not D.special_deal_seat_is_me) and D.special_deal_seat then
		return 0
	end
	
	local v
	if DATA.game_info.game_type=="nor_ddz_boom" then
		v=ddz_tuoguan.get_zhadan_ddz_xiaojiao_score(true, D.play_data,D.profit_wave_status)
	else
		v=ddz_tuoguan.get_nor_ddz_xiaojiao_score(true, D.play_data,D.profit_wave_status)
	end
	if DATA.game_info.game_type == "nor_ddz_er" then
		if v==1 then
			if math.random(1,100)<80 then
				v=0
			end
		elseif v==2 then
			if math.random(1,100)<50 then
				v=0
			end
		end
	end
	return v
end

-- 权限
function MSG.nor_ddz_nor_permit_msg(_data)

	local _msg_time = _data.msg_time or 0
	local _recv_time = os.time()

	if PUBLIC.ddz_is_my_permit(_data.cur_p) then

		local _delay = math.random(skynet.getcfg_2number("tuoguan_ddz_delay_1") or 100,skynet.getcfg_2number("tuoguan_ddz_delay_2") or 200)
		skynet.sleep(_delay)

		-- 叫地主
		if "jdz" == _data.status then

			-- 焖拉倒
			if DATA.game_info.jdz_type == "mld" then
				if 0 == D.s_info.men_data[DATA.room_info.seat_num] then
					local _opt = 0
					if _data.other or math.random(100) < tonumber(skynet.getcfg("tuoguan_ddz_men_zhua_prop") or 5) then
						_opt = 1
					end

					local ret = PUBLIC.request_agent("nor_ddz_mld_men_zhua",{opt=_opt})
					if ret.result ~= 0 then
						print(string.format("call nor_ddz_mld_men_zhua error:%s !",tostring(ret.result)))
						return
					end
				else
					local ret = PUBLIC.request_agent("nor_ddz_mld_zhua_pai",{opt=PUBLIC.get_mld_zhua_pai_opt(_data)})
					if ret.result ~= 0 then
						print(string.format("call nor_ddz_mld_zhua_pai error:%s !",tostring(ret.result)))
						return
					end
				end

				return
			end

			local _level = PUBLIC.get_dizhu_level(_data)
			if _level <= PUBLIC.get_last_jdz_rate() then
				_level = 0 -- 叫分 不大于 上家，则 不叫
			end
			local ret = PUBLIC.request_agent("nor_ddz_nor_jiao_dizhu",{rate=_level})
			if ret.result ~= 0 then
				print(string.format("call nor_ddz_nor_jiao_dizhu error:%s !",tostring(ret.result),_level))
				return
			end

			-- 加倍
		elseif "jiabei" == _data.status then

			-- 焖拉倒
			if DATA.game_info.jdz_type == "mld" then
				local _now = os.time()
				local ret = PUBLIC.request_agent("nor_ddz_mld_dao_la",{opt=PUBLIC.get_mld_zhua_pai_opt(_data)})
				if ret.result ~= 0 then
					print(string.format("call nor_ddz_mld_dao_la error:%s !",tostring(ret.result)),_now - _msg_time,_now - _recv_time)
					return
				end

				return
			end

			local _now = os.time()

			if PUBLIC.get_dizhu_level(_data) > 1 then
				local ret = PUBLIC.request_agent("nor_ddz_nor_jiabei",{rate=2})
				if ret.result ~= 0 then
					print(string.format("nor_ddz_nor_jiabei error:%s !",tostring(ret.result)),_now - _msg_time,_now - _recv_time)
				end
			else
				local ret = PUBLIC.request_agent("nor_ddz_nor_jiabei",{rate=0})
				if ret.result ~= 0 then
					print(string.format("give up jiao jaibei error:%s !",tostring(ret.result)),_now - _msg_time,_now - _recv_time)
				end
			end

			-- 出牌
		elseif "cp" == _data.status then
			local cp_type,cp_list
			if _data.other==1 then 
				cp_type,cp_list,delay_time=ddz_tuoguan.playcards(true, D.play_data)
			else 
				cp_type,cp_list,delay_time=ddz_tuoguan.playcards(false, D.play_data)
			end
			dump({cp_type,cp_list},"xxxxxxxxxxxxxxxxxxxxx play_cards")
			skynet.sleep(delay_time)
			if cp_type then 

				local ret = PUBLIC.request_agent("nor_ddz_nor_chupai",{type=cp_type,cp_list = cp_list})
				if ret.result ~= 0 then
					print(string.format("nor_ddz_nor_chupai error:%s !",tostring(ret.result),basefunc.tostring({type=type,cp_list = {nor=cp_list}})))
				end
			else 
				local ret = PUBLIC.request_agent("nor_ddz_nor_chupai",{type=0})
				if ret.result ~= 0 then
					print(string.format("give up jiao chupai error:%s !",tostring(ret.result)))
				end
			end

			-- 抢地主
		elseif "q_dizhu" == _data.status then
			if D.qdz_count > 0 then
				D.qdz_count = D.qdz_count - 1
				local ret = PUBLIC.request_agent("nor_ddz_er_q_dizhu",{rate=1})
				if ret.result ~= 0 then
					print(string.format("nor_ddz_er_q_dizhu rate=1 error:%s !",tostring(ret.result)))
				end
			else
				local ret = PUBLIC.request_agent("nor_ddz_er_q_dizhu",{rate=0})
				if ret.result ~= 0 then
					print(string.format("nor_ddz_er_q_dizhu rate=0 error:%s !",tostring(ret.result)))
				end
			end
		end

	end
end

-- 托管牌信息
function MSG.nor_ddz_nor_notify_tuoguan_pai(_play_data,_profit_wave_status)

	PUBLIC.reset_playing_data()

	D.profit_wave_status = _profit_wave_status

	-- add for new ai begin -- 
	for _seat=1,DATA.seat_count do
		D.play_data:set_seatcards(_seat,_play_data[_seat].pai)
	end
	D.play_data:set_left3cards(_play_data.dz_pai)
	D.play_data:set_myseatid(DATA.room_info.seat_num)
	if DATA.game_info.jdz_type == "mld" then
		D.play_data:set_istfddz(true)
	end

	--add for new ai end ---

	-- 设置规则选项
	if DATA.game_info.jdz_type == "mld" then
		ddz_tuoguan.set_game_type("mld")
	else
		ddz_tuoguan.set_game_type("nor")
	end

	for _seat=1,DATA.seat_count do
		local _p_data = _play_data[_seat]

		-- 自己，则设置地主牌
		if DATA.room_info.seat_num == _seat then
			D.my_card_value_map = nor_ddz_base_lib.get_pai_typeHash(_p_data.pai)
		end
	end

	--  设置特殊座位
	D.special_deal_seat = _play_data.special_deal_seat
	if _play_data.special_deal_seat == DATA.room_info.seat_num then
		D.special_deal_seat_is_me = true
	else
		D.special_deal_seat_is_me = nil
	end

	D.qdz_count = ddz_tuoguan.get_nor_ddz_qiangdizhu_count(true,D.play_data,D.profit_wave_status)
end

-- 发牌
function MSG.nor_ddz_nor_pai_msg(_data)

end

function MSG.nor_ddz_nor_begin_msg(_data)
	if PUBLIC.on_begin_msg then
		PUBLIC.on_begin_msg(_data.cur_race)
	end
end

-- 游戏开始
function PROTECTED.start_game()

	PUBLIC.reset_playing_data()

end

function PROTECTED.on_join_room( _data)

end

function PROTECTED.destroy()

end


function PROTECTED.dispatch_msg(_name,_data,...)
	-- dump(_data,_name)

	local f = MSG[_name]
	if f then
		f(_data,...)
		return true
	else
		return false
	end
end

return PROTECTED
