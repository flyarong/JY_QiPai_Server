

local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local skynet = require "skynet_plus"
require "normal_enum"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

--- 玩家的 vip 数据
DATA.sczd_vip_lb_data = {}


function PUBLIC.get_data(_player_id)
	if not DATA.sczd_vip_lb_data[_player_id] then
		DATA.sczd_vip_lb_data[_player_id] = {
			player_id = _player_id,
			is_buy_vip_lb = 0,
			now_vip_task_get_num1 = 0,
			now_vip_task_max_num1 = 0,
			now_vip_task_get_num2 = 0,
			now_vip_task_max_num2 = 0,
			now_vip_rebate_xj_num = 0,
			max_vip_rebate_xj_num = DATA.max_vip_rebate_xj_num,
			task_overdue_time = os.time(),
		}
	end

	return DATA.sczd_vip_lb_data[_player_id]
end

----载入所有的 玩家的vip礼包数据
function PUBLIC.load_all_vip_lb_data()
	local data = skynet.call(DATA.service_config.data_service,"lua","query_all_vip_lb_data") 

	if data then
		DATA.sczd_vip_lb_data = data
	end
end

--- 查询一个玩家的 vip礼包数据 数据
function CMD.query_player_vip_lb_data(_player_id)
	local data = DATA.sczd_vip_lb_data[_player_id]
	if not data then
		data = PUBLIC.get_data(_player_id)

		PUBLIC.update_player_data(_player_id)
	end

	return data
end

--- 新增 or 更新 数据
function CMD.add_or_update_vip_lb_data(_player_id , _is_buy_vip_lb , _now_vip_task_get_num1 , _now_vip_task_max_num1 , _now_vip_task_get_num2 , _now_vip_task_max_num2 ,
										_now_vip_rebate_xj_num , _max_vip_rebate_xj_num , _task_overdue_time )
	DATA.sczd_vip_lb_data[_player_id] = PUBLIC.get_data(_player_id)

	DATA.sczd_vip_lb_data[_player_id].player_id = _player_id
	DATA.sczd_vip_lb_data[_player_id].is_buy_vip_lb = _is_buy_vip_lb
	DATA.sczd_vip_lb_data[_player_id].now_vip_task_get_num1 = _now_vip_task_get_num1
	DATA.sczd_vip_lb_data[_player_id].now_vip_task_max_num1 = _now_vip_task_max_num1
	DATA.sczd_vip_lb_data[_player_id].now_vip_task_get_num2 = _now_vip_task_get_num2
	DATA.sczd_vip_lb_data[_player_id].now_vip_task_max_num2 = _now_vip_task_max_num2
	DATA.sczd_vip_lb_data[_player_id].now_vip_rebate_xj_num = _now_vip_rebate_xj_num
	DATA.sczd_vip_lb_data[_player_id].max_vip_rebate_xj_num = _max_vip_rebate_xj_num
	DATA.sczd_vip_lb_data[_player_id].task_overdue_time = _task_overdue_time

	skynet.send(DATA.service_config.data_service,"lua","add_or_update_vip_lb_data",
				_player_id , _is_buy_vip_lb , _now_vip_task_get_num1 , _now_vip_task_max_num1 , _now_vip_task_get_num2 , _now_vip_task_max_num2 ,
										_now_vip_rebate_xj_num , _max_vip_rebate_xj_num , _task_overdue_time)
end

function PUBLIC.update_player_data(_player_id)
	local player_data = PUBLIC.get_data(_player_id)

	CMD.add_or_update_vip_lb_data(player_data.player_id , player_data.is_buy_vip_lb , player_data.now_vip_task_get_num1 , player_data.now_vip_task_max_num1
		, player_data.now_vip_task_get_num2, player_data.now_vip_task_max_num2 , player_data.now_vip_rebate_xj_num , player_data.max_vip_rebate_xj_num , player_data.task_overdue_time )
end

---- 增加返利xj个数
function CMD.add_vip_rebate_xj_num(_player_id)
	print("xxx--------------add_vip_rebate_xj_num")
	local player_data = PUBLIC.get_data(_player_id)
	player_data.now_vip_rebate_xj_num = player_data.now_vip_rebate_xj_num + 1
	if player_data.now_vip_rebate_xj_num > player_data.max_vip_rebate_xj_num then
		player_data.now_vip_rebate_xj_num = player_data.max_vip_rebate_xj_num
	end

	PUBLIC.update_player_data(_player_id)
end

--- 购买vip礼包
function CMD.player_buy_vip_lb(_player_id)
	local player_data = PUBLIC.get_data(_player_id)

	player_data.is_buy_vip_lb = 1
	player_data.now_vip_task_get_num1 = 0
	player_data.now_vip_task_max_num1 = DATA.sczd_vip_task1_max_num
	player_data.now_vip_task_get_num2 = 0
	player_data.now_vip_task_max_num2 = DATA.sczd_vip_task2_max_num

	--player_data.max_vip_rebate_xj_num = DATA.max_vip_rebate_xj_num
	player_data.task_overdue_time = os.time() + DATA.vip_task_overdue_time

	PUBLIC.update_player_data(_player_id)

	--- 通知agent
	nodefunc.call( _player_id , "buy_vip_lb" , DATA.sczd_vip_task1_max_num , DATA.sczd_vip_task2_max_num , player_data.task_overdue_time )

end

------ 动态设置某个人的 贡献上限
function CMD.set_max_vip_rebate_xj_num(_player_id , max_rebate_xj_num)
	local player_data = PUBLIC.get_data(_player_id)
	player_data.max_vip_rebate_xj_num = max_rebate_xj_num
	PUBLIC.update_player_data(_player_id)

	nodefunc.call( _player_id , "set_max_vip_rebate_xj_num" , max_rebate_xj_num )
end


function PUBLIC.init()
	PUBLIC.load_all_vip_lb_data()
end

