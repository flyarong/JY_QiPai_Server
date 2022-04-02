
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local skynet = require "skynet_plus"
require "normal_enum"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

--- 玩家的周卡数据
DATA.player_zhouka_data = {}


local function get_data(_player_id)
	if not DATA.player_zhouka_data[_player_id] then
		DATA.player_zhouka_data[_player_id] = {
			player_id = _player_id,
			is_buy_jingbi_zhouka = 0,
			jingbi_zhouka_remain = 0,
			is_buy_qys_zhouka = 0,
			qys_zhouka_remain = 0,
		}
	end


	return DATA.player_zhouka_data[_player_id] 
end

----载入所有的 玩家的周卡数据
function PUBLIC.load_all_zhouka_data()
	local data = skynet.call(DATA.service_config.data_service,"lua","query_all_zhouka_data") 

	if data then
		DATA.player_zhouka_data = data
	end
end

--- 查询一个玩家的周卡数据
function CMD.query_player_zhouka_data(_player_id)
	local data = DATA.player_zhouka_data[_player_id]
	if not data then
		data = get_data(_player_id)

		PUBLIC.update_player_data(_player_id)
	end

	return data
end

--- 新增 or 更新 周卡数据
function CMD.add_or_update_zhouka_data(_player_id , _is_buy_jingbi_zhouka , _jingbi_zhouka_remain , _is_buy_qys_zhouka , _qys_zhouka_remain )
	DATA.player_zhouka_data[_player_id] = get_data(_player_id)

	DATA.player_zhouka_data[_player_id].player_id = _player_id
	DATA.player_zhouka_data[_player_id].is_buy_jingbi_zhouka = _is_buy_jingbi_zhouka
	DATA.player_zhouka_data[_player_id].jingbi_zhouka_remain = _jingbi_zhouka_remain
	DATA.player_zhouka_data[_player_id].is_buy_qys_zhouka = _is_buy_qys_zhouka
	DATA.player_zhouka_data[_player_id].qys_zhouka_remain = _qys_zhouka_remain

	skynet.send(DATA.service_config.data_service,"lua","add_or_update_zhouka_data",
				_player_id , _is_buy_jingbi_zhouka , _jingbi_zhouka_remain , _is_buy_qys_zhouka , _qys_zhouka_remain)
end

function PUBLIC.update_player_data(_player_id)
	local player_data = get_data(_player_id)

	CMD.add_or_update_zhouka_data(player_data.player_id , player_data.is_buy_jingbi_zhouka , player_data.jingbi_zhouka_remain
		, player_data.is_buy_qys_zhouka, player_data.qys_zhouka_remain)
end

----- 购买金币 周卡
function CMD.player_buy_jingbi_zhouka(_player_id)
	DATA.player_zhouka_data[_player_id] = get_data(_player_id)
	local zhouka_data = DATA.player_zhouka_data[_player_id] 

	zhouka_data.is_buy_jingbi_zhouka = 1
	zhouka_data.jingbi_zhouka_remain = DATA.jingbi_zhouka_award_num

	PUBLIC.update_player_data(_player_id)

	--- 通知agent
	nodefunc.call( _player_id , "buy_jingbi_zhouka" , DATA.jingbi_zhouka_award_num )
end

----- 购买千元赛门票 周卡
function CMD.player_buy_qys_zhouka(_player_id)
	DATA.player_zhouka_data[_player_id] = get_data(_player_id)
	local zhouka_data = DATA.player_zhouka_data[_player_id] 

	zhouka_data.is_buy_qys_zhouka = 1
	zhouka_data.qys_zhouka_remain = DATA.qys_zhouka_award_num

	PUBLIC.update_player_data(_player_id)

	--- 通知agent
	nodefunc.call( _player_id , "buy_qys_zhouka" , DATA.qys_zhouka_award_num )
end


--玩家充值
function CMD.player_pay_msg(_player_id,_produce_id,_num,_channel_type)
	
	if _player_id and _num and _produce_id then
		--玩家购买了 金猪礼包1
		if _produce_id == DATA.jingbi_libao_id then
			CMD.player_buy_jingbi_zhouka(_player_id)
		elseif _produce_id == DATA.qys_libao_id then
			CMD.player_buy_qys_zhouka(_player_id)
		end
	end
end


---- 查询玩家是否能购买周卡，给公众号使用
function CMD.query_zhouka_can_buy(_player_id , _gift_bag_id)
	if not _player_id or not _gift_bag_id or type(_player_id) ~= "string" or type(_gift_bag_id) ~= "number" or
		 (_gift_bag_id ~= 41 and _gift_bag_id ~= 42) then
		 return nil
	end

	local zhouka_data = get_data(_player_id)

	if _gift_bag_id == 41 then
		if zhouka_data.is_buy_jingbi_zhouka == 0 or (zhouka_data.is_buy_jingbi_zhouka == 1 and zhouka_data.jingbi_zhouka_remain <= 0) then
			return true
		end
		return false
	elseif _gift_bag_id == 42 then
		if zhouka_data.is_buy_qys_zhouka == 0 or (zhouka_data.is_buy_qys_zhouka == 1 and zhouka_data.qys_zhouka_remain <= 0) then
			return true
		end
		return false
	end
	return nil
end


---
function PUBLIC.init()
	PUBLIC.load_all_zhouka_data()
end

