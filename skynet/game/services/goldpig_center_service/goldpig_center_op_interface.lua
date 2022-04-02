local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local skynet = require "skynet_plus"
require "normal_enum"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECT = {}

--- 金猪任务能 领取的次数
DATA.total_remain_num = 40 -- 30

--- 金猪任务2 能 领取的次数
DATA.total_remain_num2 = 30 --25

DATA.player_goldpig_data = {}

local function get_data(_player_id)
	return DATA.player_goldpig_data[_player_id] or {
			player_id = _player_id,
			is_buy_goldpig = 0,
			remain_task_num = 0,
			is_buy_goldpig1 = 0,
			remain_task_num1 = 0,
			is_buy_goldpig2 = 0,
			remain_task_num2 = 0,
			today_get_task_num2 = 0,
		}
end

----载入所有的 玩家的金猪数据
function PUBLIC.load_all_goldpig_data()
	local data = skynet.call(DATA.service_config.data_service,"lua","query_all_goldpig_data") 

	if data then
		DATA.player_goldpig_data = data

		for player_id , data in pairs(DATA.player_goldpig_data) do
			data.is_buy_goldpig1 = data.is_buy_goldpig1 or 0
			data.remain_task_num1 = data.remain_task_num1 or 0
			data.is_buy_goldpig2 = data.is_buy_goldpig2 or 0
			data.remain_task_num2 = data.remain_task_num2 or 0
			data.today_get_task_num2 = data.today_get_task_num2 or 0
		end
	end
end

--- 查询一个玩家的金猪数据
function CMD.query_player_goldpig_data(_player_id)
	local data = DATA.player_goldpig_data[_player_id]
	if not data then
		data = get_data(_player_id)

		skynet.send(DATA.service_config.data_service,"lua","add_or_update_goldpig_data", 
			data.player_id ,
			data.is_buy_goldpig , 
			data.remain_task_num ,
			data.is_buy_goldpig1 ,
			data.remain_task_num1 ,
			data.is_buy_goldpig2 ,
			data.remain_task_num2 ,
			data.today_get_task_num2 )
	end

	return data
end

--- 新增 or 更新 金猪数据1
function CMD.add_or_update_goldpig_data(_player_id , _is_buy_goldpig , _remain_task_num , _is_buy_goldpig1 , _remain_task_num1 , _is_buy_goldpig2 , _remain_task_num2 , _today_get_task_num2 )
	DATA.player_goldpig_data[_player_id] = get_data(_player_id)

	DATA.player_goldpig_data[_player_id].player_id = _player_id
	DATA.player_goldpig_data[_player_id].is_buy_goldpig = _is_buy_goldpig
	DATA.player_goldpig_data[_player_id].remain_task_num = _remain_task_num
	DATA.player_goldpig_data[_player_id].is_buy_goldpig1 = _is_buy_goldpig1
	DATA.player_goldpig_data[_player_id].remain_task_num1 = _remain_task_num1
	DATA.player_goldpig_data[_player_id].is_buy_goldpig2 = _is_buy_goldpig2
	DATA.player_goldpig_data[_player_id].remain_task_num2 = _remain_task_num2
	DATA.player_goldpig_data[_player_id].today_get_task_num2 = _today_get_task_num2

	skynet.send(DATA.service_config.data_service,"lua","add_or_update_goldpig_data",
				 _player_id , _is_buy_goldpig , _remain_task_num , _is_buy_goldpig1 , _remain_task_num1 , _is_buy_goldpig2 , _remain_task_num2 , _today_get_task_num2)
end


--- 玩家买了金猪礼包1   (只适用新版购买)
function CMD.player_buy_goldpig(_player_id)
	print("----------------------- player_buy_goldpig ",_player_id)
	DATA.player_goldpig_data[_player_id] = get_data(_player_id)
	local goldpig_data = DATA.player_goldpig_data[_player_id] 

	local old_is_buy_goldpig1 = goldpig_data.is_buy_goldpig1
	goldpig_data.is_buy_goldpig1 = 1
	goldpig_data.remain_task_num1 = DATA.total_remain_num

	skynet.send(DATA.service_config.data_service,"lua","add_or_update_goldpig_data", 
		goldpig_data.player_id ,
		goldpig_data.is_buy_goldpig , 
		goldpig_data.remain_task_num ,
		goldpig_data.is_buy_goldpig1 ,
		goldpig_data.remain_task_num1 ,
		goldpig_data.is_buy_goldpig2 ,
		goldpig_data.remain_task_num2 ,
		goldpig_data.today_get_task_num2 )

	--- 通知agent
	nodefunc.call( _player_id , "buy_goldpig" , DATA.total_remain_num )

	---- 发广播

	local name = skynet.call(DATA.service_config.data_service,"lua",
									"get_player_info",_player_id,"player_info","name")
	if name then
		local broadcast_name = "buy_goldpig_1_1"
		if goldpig_data.is_buy_goldpig ==1 or old_is_buy_goldpig1 == 1 then
			broadcast_name = "buy_goldpig_1_2"
		end

		skynet.send(DATA.service_config.broadcast_center_service,"lua",
											"fixed_broadcast", broadcast_name , name )
	end
end

--- 玩家买了金猪礼包2   
function CMD.player_buy_goldpig2(_player_id)
	print("----------------------- player_buy_goldpig2 ",_player_id)
	DATA.player_goldpig_data[_player_id] = get_data(_player_id)
	local goldpig_data = DATA.player_goldpig_data[_player_id] 

	local old_is_buy_goldpig2 = goldpig_data.is_buy_goldpig2
	goldpig_data.is_buy_goldpig2 = 1
	goldpig_data.remain_task_num2 = DATA.total_remain_num2
	goldpig_data.today_get_task_num2 = 0

	skynet.send(DATA.service_config.data_service,"lua","add_or_update_goldpig_data", 
		goldpig_data.player_id ,
		goldpig_data.is_buy_goldpig , 
		goldpig_data.remain_task_num ,
		goldpig_data.is_buy_goldpig1 ,
		goldpig_data.remain_task_num1 ,
		goldpig_data.is_buy_goldpig2 ,
		goldpig_data.remain_task_num2 ,
		goldpig_data.today_get_task_num2 )

	--- 通知agent
	nodefunc.call( _player_id , "buy_goldpig2" , DATA.total_remain_num2 )

	local name = skynet.call(DATA.service_config.data_service,"lua",
									"get_player_info",_player_id,"player_info","name")
	if name then
		local broadcast_name = "buy_goldpig_2_1"
		if old_is_buy_goldpig2 == 1 then
			broadcast_name = "buy_goldpig_2_2"
		end

		skynet.send(DATA.service_config.broadcast_center_service,"lua",
											"fixed_broadcast", broadcast_name , name )
	end

end


---- 查询,金猪礼包1是否购买
function CMD.query_goldpig_gift_can_buy( player_id , goods_id )
	if not player_id or not goods_id or type(player_id) ~= "string" or type(goods_id) ~= "number" or
		 (goods_id ~= 30 and goods_id ~= 31 and goods_id ~= 32 and goods_id ~= 33) then
		 
		 return nil
	end

	local goldpig_data = get_data(player_id)

	if goods_id == 30 then
		if goldpig_data.is_buy_goldpig == 0 and goldpig_data.is_buy_goldpig1 == 0 then
			return true
		end
		return false
	elseif goods_id == 31 then
		-- 金猪1续航 ， 不复购
		--if (goldpig_data.is_buy_goldpig == 1 or goldpig_data.is_buy_goldpig1 == 1) and (goldpig_data.remain_task_num <= 0 and goldpig_data.remain_task_num1 <= 0) then
		--	return true
		--end
		return false
	elseif goods_id == 32 then
		--- 新旧 金猪礼包1 都没有购买，不能显示金猪 2
		if (goldpig_data.is_buy_goldpig == 0 and goldpig_data.is_buy_goldpig1 == 0)  then
			return false
		end

		if goldpig_data.is_buy_goldpig2 == 0 then
			return true
		end
		return false

	elseif goods_id == 33 then
		if goldpig_data.is_buy_goldpig2 == 1 and goldpig_data.remain_task_num2 <= 0 then
			return true
		end
		return false
	end
	return nil
end


------ 设置一个玩家的金猪礼包1礼包剩余次数(测试用)
function CMD.set_goldpig1_remain(_player_id , _num)
	local goldpig_data = DATA.player_goldpig_data[_player_id]
	if goldpig_data then
		goldpig_data.remain_task_num1 = _num

		CMD.add_or_update_goldpig_data(goldpig_data.player_id   , goldpig_data.is_buy_goldpig , goldpig_data.remain_task_num , goldpig_data.is_buy_goldpig1 
			, goldpig_data.remain_task_num1 , goldpig_data.is_buy_goldpig2 , goldpig_data.remain_task_num2 , goldpig_data.today_get_task_num2 )

		nodefunc.send( _player_id, "set_goldpig1_remain" , _num )

	end
end

function CMD.set_goldpig2_remain(_player_id , _num)
	local goldpig_data = DATA.player_goldpig_data[_player_id]
	if goldpig_data then
		goldpig_data.remain_task_num2 = _num

		CMD.add_or_update_goldpig_data(goldpig_data.player_id   , goldpig_data.is_buy_goldpig , goldpig_data.remain_task_num , goldpig_data.is_buy_goldpig1 
			, goldpig_data.remain_task_num1 , goldpig_data.is_buy_goldpig2 , goldpig_data.remain_task_num2 , goldpig_data.today_get_task_num2 )

		nodefunc.send( _player_id, "set_goldpig2_remain" , _num )
	end
end


return PROTECT