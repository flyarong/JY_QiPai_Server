--
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

local mj_core = require "majiang.core"
local nor_mj_base_lib=require "nor_mj_base_lib"
local nor_mj_algorithm = require "nor_mj_algorithm_lib"

require"printfunc"

local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC

local PROTECTED = {}
local MSG = {}

DATA.xzdd_nor_data = DATA.xzdd_nor_data or {
	--[[ 玩家信息，按座位索引
		pai_map 自己的牌 map
		pg_map 碰杠的牌
		ding_que 定缺的牌
	--]]
	p_info = nil,

	--[[ 游戏信息
		cur_race 当前轮
		zj_seat 庄家座位
		pai_pool 牌池
		pai_pool_count 牌池的 牌数量，注意：不一定等于 #pai_pool ，因为由 托管预留的摸牌
		chu_pai 出了的牌（所有人）
		ishu 已胡牌
	--]]
	g_info = nil,


	-- 算法对象
	mj_algo = nil,

	-- 是否支持换三张
	is_huan_san_zhang = false,

	-- 游戏参数
	game_param = nil,
}

local D = DATA.xzdd_nor_data

local function reset_game_data()

	-- 初始化用户信息
	D.p_info = {}
	for i=1,DATA.seat_count do
		D.p_info[i] = {}
	end

	D.g_info = {}
end

-- 移除 map 中的牌
local function remove_pai(_pai_map,_pai,_count)

	if not _pai or not _pai_map[_pai] then return end

	_pai_map[_pai] = _pai_map[_pai] - (_count or 1)
	if _pai_map[_pai] == 0 then
		_pai_map[_pai] = nil
	end
end

-- 增加牌到 map 中
local function append_pai(_pai_map,_pai,_count)
	_pai_map[_pai] = (_pai_map[_pai] or 0) + (_count or 1)
end

function MSG.nor_mj_xzdd_ready_msg(_data)

	if PUBLIC.on_game_ready_msg then
		PUBLIC.on_game_ready_msg(_data.seat_num,_data.cur_race)
	end

end

function MSG.nor_mj_xzdd_begin_msg(_data)

	D.g_info.cur_race = _data.cur_race

	if PUBLIC.on_begin_msg then
		PUBLIC.on_begin_msg(_data.cur_race)
	end

end


-- 投骰子
function MSG.nor_mj_xzdd_tou_sezi_msg(_data)

	D.g_info.zj_seat = _data.zj_seat

end

function MSG.nor_mj_xzdd_notify_tuoguan_pai(_pai_data)
	
	for _seat_num,_pai in pairs(_pai_data.playrs_pai) do
		D.p_info[_seat_num].pai_map = _pai
		D.p_info[_seat_num].pg_map = {}
		D.p_info[_seat_num].ishu = nil
	end
	D.p_info[DATA.room_info.seat_num].my_pai_list=nor_mj_base_lib.get_pai_list_by_map(D.p_info[DATA.room_info.seat_num].pai_map)
	
	D.g_info.pai_pool = _pai_data.pai_pool
	D.g_info.chu_pai = {}
	D.g_info.gang_count=0
	D.g_info.pai_pool_count = _pai_data.pai_pool_count

	D.g_info.special_deal_data=_pai_data.special_deal_data

end

-- 发牌
function MSG.nor_mj_xzdd_pai_msg(_data)

	-- 二人麻将 固定 缺 万
	if DATA.game_info.game_type == "nor_mj_xzdd_er_7" or DATA.game_info.game_type == "nor_mj_xzdd_er_13" then
		for i=1,DATA.seat_count do
			D.p_info[i].ding_que = 3
		end
	end
	
end

-- 为 碰杠 移动牌到 pg_pai
-- _count ： 3 碰； 4 杠
local function move_pai_for_pg(_seat_num,_pai,_type)
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

	remove_pai(D.p_info[_seat_num].pai_map,_pai,count)

	-- 从已出牌里面移除
	remove_pai(D.g_info.chu_pai,_pai)

	D.p_info[_seat_num].pg_map[_pai] = _type

end

local pgh_names = {peng=true,zg=true,ag=true,wg=true}

-- 玩家动作通知
function MSG.nor_mj_xzdd_action_msg(_data)

	if _data.action.type == "dq" then
		D.p_info[_data.action.p].ding_que = _data.action.pai
	elseif _data.action.type == "cp" then

		-- 移除手上的牌
		remove_pai(D.p_info[_data.action.p].pai_map,_data.action.pai)

		-- 加入到已出牌
		append_pai(D.g_info.chu_pai,_data.action.pai)

	elseif pgh_names[_data.action.type]then
		if _data.action.p==DATA.room_info.seat_num and _data.action.type~="peng" then
			D.g_info.gang_count=D.g_info.gang_count+1
		end
		move_pai_for_pg(_data.action.p,_data.action.pai,_data.action.type)

	elseif _data.action.type == "hu" then
		D.p_info[_data.action.p].ishu = true
		if "zimo" ~= _data.action.hu_data.hu_type and _data.action.hu_data.pai then
			append_pai(D.p_info[_data.action.p].pai_map,_data.action.hu_data.pai)

		end
	end
end

function MSG.nor_mj_xzdd_dingque_result_msg(_data)

	for _seat,_que in pairs(_data.result) do

		D.p_info[_seat].ding_que = _que
	end

end

-- 查看有 定缺的牌，则出 一张应该缺的牌
local function find_chupai_ding_que(_seat)
	local _que = D.p_info[_seat].ding_que
	for _pai,_count in pairs(D.p_info[_seat].pai_map) do
		if nor_mj_base_lib.flower(_pai) == _que and _count > 0 then
			return _pai
		end
	end

	return nil
end

-- 转换数据的座位顺序： 自己始终是 1
local function trans_seat_data(_datas)
	local ret = {}
	for i=1,DATA.seat_count do
		ret[i] = _datas[(DATA.room_info.seat_num + i - 2) % DATA.seat_count + 1]
	end

	return ret
end

-- 把 0 转换为 nil
local function trans_zero_nil(_data)
	for _k,_v in pairs(_data) do
		if _v == 0 then
			_data[_k] = nil
		end
	end
end

-- 在摸牌后，出牌，且不破坏听牌。
local function mopai_chu_pai_ting(_mo_pai)

	for k,v in pairs(D.p_info) do
		trans_zero_nil(v.pai_map)
	end
	
	-- print("==== get chu pai input >>> ",basefunc.tostring({trans_seat_data(D.p_info),D.g_info.pai_pool,D.g_info.chu_pai,2}))
	local chupai = mj_core.get_chupai(trans_seat_data(D.p_info),D.g_info.pai_pool,D.g_info.chu_pai,2)

	if _mo_pai and _mo_pai ~= chupai and D.g_info.pai_pool_count < skynet.getcfg("guoguan_mj_ting_pai_pool_count") then 
		local _pdata = D.p_info[DATA.room_info.seat_num]
		local _pai_map2 = basefunc.deepcopy(_pdata.pai_map)
		remove_pai(_pai_map2,_mo_pai)
		if D.mj_algo:get_ting_info(_pai_map2,_pdata.pg_map,_pdata.ding_que) then -- 出牌前 是否听牌
			append_pai(_pai_map2,_mo_pai)
			remove_pai(_pai_map2,chupai)
			if not D.mj_algo:get_ting_info(_pai_map2,_pdata.pg_map,_pdata.ding_que) then -- 出牌后 是否听牌
				dump({_pdata.pai_map,_mo_pai,chupai},"xxxxxxxxxxxxxxxxxxxxxxxxxxxx mopai_chu_pai_ting:")
				chupai = _mo_pai		-- 要破坏听牌，出 摸的牌
			end
		end
	end

	-- print("==== chu pai>>> ",chupai)
	local ret = PUBLIC.request_agent("nor_mj_xzdd_operator",{type="cp",pai=chupai})
	if ret.result ~= 0 then
		print("chu pai oper error:",tostring(ret.result),basefunc.tostring(D.p_info))
	end

end

local function chu_pai()

	for k,v in pairs(D.p_info) do
		trans_zero_nil(v.pai_map)
	end

	-- print("==== get chu pai input >>> ",basefunc.tostring({trans_seat_data(D.p_info),D.g_info.pai_pool,D.g_info.chu_pai,2}))
	local chupai = mj_core.get_chupai(trans_seat_data(D.p_info),D.g_info.pai_pool,D.g_info.chu_pai,2)
	-- print("==== chu pai>>> ",chupai)
	local ret = PUBLIC.request_agent("nor_mj_xzdd_operator",{type="cp",pai=chupai})
	if ret.result ~= 0 then
		print("chu pai oper error:",tostring(ret.result),basefunc.tostring(D.p_info))
	end
end


local function chu_pai_by_special_deal_data(_data)
	--print("==== get chu pai input >>> ",basefunc.tostring({trans_seat_data(D.p_info),D.g_info.pai_pool,D.g_info.chu_pai,2}))

	local _que_pai = find_chupai_ding_que(DATA.room_info.seat_num)
	local _que_type = D.p_info[DATA.room_info.seat_num].ding_que

	if _data.mopai_src == "dian_pao" then
		if not _que_pai or _que_type == nor_mj_base_lib.flower(_data.pai) then -- 要么已打缺，要么 是 打出 缺门花色
			local ret = PUBLIC.request_agent("nor_mj_xzdd_operator",{type="cp",pai=_data.pai})
			if ret.result ~= 0 then
				print("chu pai oper error:",tostring(ret.result),basefunc.tostring(D.p_info))
			end
		end
	elseif D.g_info.special_deal_data and next(D.g_info.special_deal_data.cp_list) then
		local cp_list=D.g_info.special_deal_data.cp_list
		local chupai = cp_list[#cp_list]
		
		if not _que_pai or _que_type == nor_mj_base_lib.flower(chupai) then -- 要么已打缺，要么 是 打出 缺门花色
			local ret = PUBLIC.request_agent("nor_mj_xzdd_operator",{type="cp",pai=chupai})
			if ret.result ~= 0 then
				print("chu pai oper error:",tostring(ret.result))
			else
				cp_list[#cp_list] = nil
			end
		end
	elseif _data.status == "mo_pai" then
		if not _que_pai or _que_type == nor_mj_base_lib.flower(_data.pai) then -- 要么已打缺，要么 是 打出 缺门花色
			local ret = PUBLIC.request_agent("nor_mj_xzdd_operator",{type="cp",pai=_data.pai})
			if ret.result ~= 0 then
				print("chu pai oper error:",tostring(ret.result),basefunc.tostring(D.p_info))
			end
		end
	end

	chu_pai()
		
end

-- 胡牌
local function hu_pai()
	local ret = PUBLIC.request_agent("nor_mj_xzdd_operator",{type="hu"})
	if ret.result ~= 0 then
		print("start hu pai oper error:",tostring(ret.result))
	end
end

local function peng_gang_hu_by_special_deal_data(_data)
	local _op = {pai=_data.pai}

	if _data.allow_opt.hu then
		hu_pai()
		return
	end

	if _data.allow_opt.gang then
		_op.type = "guo"
		if D.g_info.special_deal_data.gang_map[_data.pai] then
			_op.type = "gang"
		end
	elseif _data.allow_opt.peng then
		_op.type = "guo"
		if D.g_info.special_deal_data.peng_map[_data.pai] then
			_op.type = "peng"
		end
	end

	local ret = PUBLIC.request_agent("nor_mj_xzdd_operator",_op)
	if ret.result ~= 0 then
		print(_op.type .. "  peng_gang_hu_by_special_deal_data  pai oper error:",tostring(ret.result))
	end
end

-- 查找 可能的 碰 、 杠：返回 {pai=,pg="peng"/"gang"} 数组
-- 注意：假定 _cur_pai 已经在 _pai_map 中，所以只能用于 摸牌 和 庄家首次发牌！
local function find_peng_gang(_pai_map,_cur_pai,_ding_que,_pg_map)

	if _cur_pai then

		if _cur_pai == _ding_que then
			return nil
		end

		if _pai_map[_cur_pai] and _pai_map[_cur_pai] == 4 then
			return {{pai=_cur_pai,pg="gang"},{pai=_cur_pai,pg="peng"}}
		end
		if _pg_map and _pg_map[_cur_pai]=="peng" then
			return {{pai=_cur_pai,pg="gang"}}
		end
	end

	local ret = {}
	for _pai,_count in pairs(_pai_map) do
		if _pai ~= _ding_que then
			if _count == 4 then
				ret[#ret + 1] = {pai=_pai,pg="gang"}
				ret[#ret + 1] = {pai=_pai,pg="peng"}
			elseif _count == 3 then
				ret[#ret + 1] = {pai=_pai,pg="peng"}
			end
		end
	end

	return ret
end

-- 权限
function MSG.nor_mj_xzdd_permit_msg(_data)

	local _delay = math.random(tonumber(skynet.getcfg("tuoguan_mj_delay_1")) or 100,tonumber(skynet.getcfg("tuoguan_mj_delay_2")) or 150)

	if "da_piao" == _data.status then

		skynet.sleep(_delay)

		-- 随机 打漂
		if math.random(100) < tonumber(skynet.getcfg("tuoguan_er_mj_dapiao_gailv")) then
			PUBLIC.request_agent("nor_mj_xzdd_dapiao",{piaoNum=1})
		else
			PUBLIC.request_agent("nor_mj_xzdd_dapiao",{piaoNum=0})
		end

		return
	end

	-- 摸牌 要处理每个人
	if "mo_pai" == _data.status then
		D.g_info.pai_pool_count = D.g_info.pai_pool_count - 1
		append_pai(D.p_info[_data.cur_p].pai_map,_data.pai)
			if not _data.mopai_src then
				-- ###_temp 从牌池中删除可能有问题！！！：房间中可能不是取的最后 一张，导致 不一致
				for i=#D.g_info.pai_pool,1,-1 do
					if D.g_info.pai_pool[i] == _data.pai then
						table.remove(D.g_info.pai_pool,i)
						break
					end
				end
			end
	end

	skynet.sleep(_delay)

	-- 换三张
	if "huan_san_zhang" == _data.status then
		D.is_huan_san_zhang = true
		local _msg
		if D.g_info.special_deal_data then
			_msg = {paiVec={}}
		else
			_msg = {
				paiVec = D.mj_algo:get_default_huansanzhang_pai(D.p_info[DATA.room_info.seat_num].pai_map)
			}
		end

		local ret = PUBLIC.request_agent("nor_mj_xzdd_huansanzhang",_msg)
		if ret.result ~= 0 then
			print("nor_mj_xzdd_huansanzhang error:",tostring(ret.result))
		end
	end

	-- 只处理 自己的
	if _data.cur_p ~= DATA.room_info.seat_num and _data.cur_p ~= 0 then
		return
	end

	local _my_data = D.p_info[DATA.room_info.seat_num]

	--特殊位置走特殊的方法
	if D.g_info and D.g_info.special_deal_data then
		if "ding_que" == _data.status then
			local _que = D.g_info.special_deal_data.dq_color
			_my_data.ding_que = _que -- 自己的定缺，先赋值

			local ret = PUBLIC.request_agent("nor_mj_xzdd_operator",{type="dq",pai=_que})
			if ret.result ~= 0 then
				print("ding que oper error:",tostring(ret.result))
			end

		elseif "mo_pai" == _data.status or "start" == _data.status then

			-- 判断胡牌
			local hu_info = D.mj_algo:get_hupai_info(_my_data.pai_map,_my_data.pg_map,_my_data.ding_que)
			if hu_info then
				hu_pai()
				return
			end

			-- 判断碰杠
			local peng_gang = find_peng_gang(_my_data.pai_map,"mo_pai" == _data.status and _data.pai or nil,_my_data.ding_que,_my_data.pg_map)
			if peng_gang then
				for _,_pg in ipairs(peng_gang) do
					if _pg.pg == "gang" and D.g_info.special_deal_data.gang_map[_pg.pai] then
						local ret = PUBLIC.request_agent("nor_mj_xzdd_operator",{pai=_pg.pai,type="gang"})
						if ret.result ~= 0 then
							print("--> gang pai oper error:",tostring(ret.result))
						end
						return
					end
				end
			end

			-- 出牌
			chu_pai_by_special_deal_data(_data)
		elseif "cp" == _data.status then
			chu_pai_by_special_deal_data(_data)
		elseif "peng_gang_hu" == _data.status then
			peng_gang_hu_by_special_deal_data(_data)
		end
	--普通处理
	else
		if "ding_que" == _data.status then
			local _que = nor_mj_base_lib.get_ding_que_color(_my_data.my_pai_list)
			_my_data.ding_que = _que -- 自己的定缺，先赋值
			
			local ret = PUBLIC.request_agent("nor_mj_xzdd_operator",{type="dq",pai=_que})
			if ret.result ~= 0 then
				print("ding que oper error:",tostring(ret.result))
			end

		elseif "mo_pai" == _data.status or "start" == _data.status then

			-- 判断胡牌
			local hu_info = D.mj_algo:get_hupai_info(_my_data.pai_map,_my_data.pg_map,_my_data.ding_que)
			if hu_info then
				hu_pai()
				return
			end

			-- 判断碰杠
			local peng_gang = find_peng_gang(_my_data.pai_map,"mo_pai" == _data.status and _data.pai or nil,_my_data.ding_que,_my_data.pg_map)
			if peng_gang then
				for _,_pg in ipairs(peng_gang) do
					if _pg.pg == "gang" then
						--if 0 ~= mj_core.can_gang(trans_seat_data(D.p_info),D.g_info.pai_pool,D.g_info.chu_pai,_pg.pai) then
							local ret = PUBLIC.request_agent("nor_mj_xzdd_operator",{pai=_pg.pai,type="gang"})
							if ret.result ~= 0 then
								print("--> gang pai oper error:",tostring(ret.result))
							end
							return
						--end
					end
				end

				-- 出牌
				chu_pai()
			else

				-- 出牌，且不能破坏听
				mopai_chu_pai_ting(_data.pai)
			end

		elseif "cp" == _data.status then
			chu_pai()
		elseif "peng_gang_hu" == _data.status then

			local _op = {pai=_data.pai}

			if _data.allow_opt.hu then
				_op.type = "hu"
			elseif _data.allow_opt.gang then

				local ret = mj_core.can_gang(trans_seat_data(D.p_info),D.g_info.pai_pool,D.g_info.chu_pai,_data.pai)
				if ret == 0 then
					_op.type = "guo"
				else
					_op.type = "gang"
				end
			else
				local ok,msg = xpcall(function()
					local ret = mj_core.can_peng(trans_seat_data(D.p_info),D.g_info.pai_pool,D.g_info.chu_pai,_data.pai)
					if ret == 0 then
						_op.type = "guo"
					else
						_op.type = "peng"
					end
				end,basefunc.error_handle)

				if not ok then
					dump({D.p_info,D.game_param},"game xzdd can_peng error:")
					_op.type = "guo"
				end
			end

			local ret = PUBLIC.request_agent("nor_mj_xzdd_operator",_op)
			if ret.result ~= 0 then
				dump(_my_data,"oper error !!!!")
				print(_op.type .. " pai oper error:",tostring(ret.result))
			end

		end
	end	
end

-- 换三张 结果
function MSG.nor_mj_xzdd_huan_pai_finish_msg(_data)
	-- pull_pai_from_room()
end

function MSG.nor_mj_xzdd_settlement_msg(_data)
	reset_game_data()
end

function MSG.nor_mj_xzdd_notify_tuoguan_param(_game_param)

	D.game_param = _game_param

	D.mj_algo = nor_mj_algorithm.new(D.game_param.kaiguan,D.game_param.multi_types,D.game_param.game_type)
	D.mj_algo.baseShouPaiNum = D.game_param.baseShouPaiNum
	D.mj_algo.maxShouPaiNum = D.game_param.maxShouPaiNum
	
end

-- 游戏开始
function PROTECTED.start_game()


	reset_game_data()	

end


function PROTECTED.on_load()


end

function PROTECTED.on_destroy()
	
end

function PROTECTED.on_join_room( _data)
	--nodefunc.call(DATA.player_id,"nor_mj_xzdd_set_as_tuoguan")

	--D.game_param = nodefunc.call(DATA.player_id,"nor_mj_xzdd_tuoguan_get_game_param")

	-- D.mj_algo = nor_mj_algorithm.new(D.game_param.kaiguan,D.game_param.multi_types,D.game_param.game_type)
	-- D.mj_algo.baseShouPaiNum = D.game_param.baseShouPaiNum
	-- D.mj_algo.maxShouPaiNum = D.game_param.maxShouPaiNum

end

function PROTECTED.destroy()


end

function PROTECTED.dispatch_msg(_name,_data,...)


	local f = MSG[_name]
	if f then
		f(_data,...)
		return true
	else
		return false
	end
end

return PROTECTED
