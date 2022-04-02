--- add by wss
---  大富豪活动服务


local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local skynet = require "skynet_plus"
require "normal_enum"
require "printfunc"

local tuoguan_names_boy = require "robot_names_boy"
local tuoguan_names_girl = require "robot_names_girl"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

DATA.player_dafuhao_data = {}

--- 大富豪总共的步数
DATA.total_step_num = 36
--- 摇多少次骰子走完
DATA.total_game_num = 10

--- 开始结束时间、
DATA.act_begin_time = 0
DATA.act_end_time = 0

--- 游戏累积赢金每多少金币加1积分
DATA.game_profit_trans_need = 10000
DATA.game_profit_trans_been = 1

--- 充值积分转换
DATA.charge_trans_need = 1000
DATA.charge_trans_been = 20

DATA.msg_tag = "dafuhao_game"

----- 不加积分的商品id
DATA.not_add_credits_gift_ids = { 43,33,32,31,30 }


--- 把sql插入队列中
function PUBLIC.db_exec(_sql , _queue_name)
  skynet.send(DATA.service_config.data_service,"lua","db_exec",_sql , _queue_name)
end

DATA.config = nil
function PUBLIC.load_config(raw_config)
	DATA.config = raw_config

	if DATA.config.main and DATA.config.main[1] then
		DATA.act_begin_time = DATA.config.main[1].begin_time
		DATA.act_end_time = DATA.config.main[1].end_time
		DATA.game_profit_trans_need = DATA.config.main[1].game_profit_trans_need
		DATA.game_profit_trans_been = DATA.config.main[1].game_profit_trans_been
		DATA.charge_trans_need = DATA.config.main[1].charge_trans_need
		DATA.charge_trans_been = DATA.config.main[1].charge_trans_been
	end

	local awards = {}

	if DATA.config.awards then
		for key,data in pairs(DATA.config.awards) do
			awards[data.award_id] = awards[data.award_id] or {}
			local per = awards[data.award_id]
			per[#per + 1] = data 
		end
	end

	DATA.config.awards = awards

	local is_in_act = PUBLIC.check_is_in_act()

	--- 在活动时间内才注册监听消息
	if is_in_act then
		PUBLIC.register_msg()
	else
		PUBLIC.unregister_msg()
	end

end

--- 是否在活动内检测，true就是在活动内
function PUBLIC.check_is_in_act()
	local now_time = os.time()
	if now_time < DATA.act_begin_time or now_time > DATA.act_end_time then
		return false
	end
	return true
end

---- 拿到某个人的数据
function PUBLIC.get_one_player_dafuhao_data(player_id)
	return skynet.call( DATA.service_config.data_service , "lua" , "query_one_player_dafuhao_data" , player_id )
end


function PUBLIC.get_player_data(player_id)

	if not DATA.player_dafuhao_data[player_id] then
		--- 没有就先从数据库拿
		local player_data = PUBLIC.get_one_player_dafuhao_data(player_id)
		--- 数据库没有就创建
		if not player_data then
			DATA.player_dafuhao_data[player_id] = {
				player_id = player_id,
				now_game_profit_acc = 0,
				now_charge_profit_acc = 0,
				now_credits = 0,
				now_game_num = 0,
				have_get_award_num = 0,
			}
			---- 
			PUBLIC.update_data( player_id )
		else
			DATA.player_dafuhao_data[player_id] = player_data
		end

	end

	---- 如果没有 这个等级需要的积分，就更新一下
	if not DATA.player_dafuhao_data[player_id].need_credits then
		DATA.player_dafuhao_data[player_id].need_credits = PUBLIC.get_game_need_credits( DATA.player_dafuhao_data[player_id].now_game_num )
	end


	return DATA.player_dafuhao_data[player_id]
end

---- 根据游戏次数获得需要的积分数量
function PUBLIC.get_game_need_credits( now_game_num )
	local need_credits = 99999
	if DATA.config and DATA.config.kaijiang and now_game_num and type(now_game_num) == "number" then
		local max_lottery_round = #DATA.config.kaijiang
		local lottery_round = now_game_num + 1
		if lottery_round > max_lottery_round then
			lottery_round = max_lottery_round
		end

		local kaijiang_data = DATA.config.kaijiang[ lottery_round ]
		if kaijiang_data then
			need_credits = kaijiang_data.need_credits
		end
	end

	return need_credits
end

---- 获得一个游戏轮次的奖励
function PUBLIC.get_game_award( now_game_num , have_get_award_num )
	local award = {}

	if DATA.config and DATA.config.kaijiang and now_game_num and type(now_game_num) == "number" then
		local max_lottery_round = #DATA.config.kaijiang
		local lottery_round = now_game_num + 1
		if lottery_round > max_lottery_round then
			lottery_round = max_lottery_round
		end

		local have_get_award_ids = basefunc.decode_task_award_status(have_get_award_num)

		local kaijiang_data = DATA.config.kaijiang[ lottery_round ]
		if kaijiang_data then
			local award_id = kaijiang_data.award_id
			local award_type = kaijiang_data.award_type
			local award_data = basefunc.deepcopy( DATA.config.awards[award_id] )

			
			if award_data and type(award_data) == "table" and next(award_data) then
				if award_type == "nor" then
					award = award_data[1] 
				else
					----- 剔除已经领的奖励
					local codit_vec = {}
					for key,data in pairs(award_data) do
						if not have_get_award_ids[data.id] then 
							codit_vec[#codit_vec + 1] = data
						end
					end


					if #codit_vec > 0 then
						local random_index = math.random( #codit_vec )

						award = codit_vec[random_index]
					end 
				end
			end

			
		end

	end

	return award
end


function CMD.query_one_player_data(player_id)
	return PUBLIC.get_player_data(player_id)
end

--- 更新一个数据
function PUBLIC.update_data( player_id )
	local data = PUBLIC.get_player_data(player_id)
	skynet.send( DATA.service_config.data_service , "lua" , "add_or_update_dafuhao_data" 
														,data.player_id
														,data.now_game_profit_acc
														,data.now_charge_profit_acc
														,data.now_credits
														,data.now_game_num
														,data.have_get_award_num
														 )
end

---- 游戏累积
function CMD.game_profit_acc( player_id , profit )
	print("xx------------------game_profit_acc :",player_id , profit )
	--- 不在活动内，不做计算
	local is_in_act = PUBLIC.check_is_in_act()
	if not is_in_act then
		return
	end

	local player_data = PUBLIC.get_player_data(player_id)

	player_data.now_game_profit_acc = player_data.now_game_profit_acc + profit

	while true do
		if player_data.now_game_profit_acc >= DATA.game_profit_trans_need then
			player_data.now_game_profit_acc = player_data.now_game_profit_acc - DATA.game_profit_trans_need
			player_data.now_credits = player_data.now_credits + DATA.game_profit_trans_been
		else
			break
		end
	end

	PUBLIC.update_data( player_id )
end

---- 充值累积
function CMD.player_pay_msg(player_id, produce_id, num, _channel_type)
	--- 不在活动内，不做计算
	local is_in_act = PUBLIC.check_is_in_act()
	if not is_in_act then
		return
	end

	---- 排除不加积分的礼包
	for key , gift_id in pairs(DATA.not_add_credits_gift_ids) do
		if produce_id == gift_id then
			return
		end
	end

	local player_data = PUBLIC.get_player_data(player_id)

	player_data.now_charge_profit_acc = player_data.now_charge_profit_acc + num

	while true do
		if player_data.now_charge_profit_acc >= DATA.charge_trans_need then
			player_data.now_charge_profit_acc = player_data.now_charge_profit_acc - DATA.charge_trans_need
			player_data.now_credits = player_data.now_credits + DATA.charge_trans_been
		else
			break
		end
	end

	PUBLIC.update_data( player_id )
end

---- 自由场赢金
function CMD.freestyle_game_gain(player_id , game_module , game_id , game_type , game_level , real_change_score , match_model , rank )
	local player_data = PUBLIC.get_player_data(player_id)

	if real_change_score and real_change_score > 0 then
		CMD.game_profit_acc( player_id , real_change_score )
	end
end

------ 开奖
function CMD.dafuhao_kaijiang(player_id , player_name)
	local ret = {}
	--- 操作限制
	if PUBLIC.get_action_lock("dafuhao_kaijiang" , player_id) then
		
		return 1008
	end
	PUBLIC.on_action_lock( "dafuhao_kaijiang" , player_id)

	local player_data = PUBLIC.get_player_data(player_id)

	if not player_data or not player_data.need_credits then
		
		PUBLIC.off_action_lock( "dafuhao_kaijiang" , player_id )
		return 1004
	end

	------ 验证积分
	if player_data.now_credits < player_data.need_credits then
		PUBLIC.off_action_lock( "dafuhao_kaijiang" , player_id )
		print("-----------------return 1003 1",player_data.now_credits , player_data.need_credits)
		return 1003
	end

	local award_data = PUBLIC.get_game_award( player_data.now_game_num , player_data.have_get_award_num ) 


	if award_data and type(award_data) == "table" and next(award_data) then
		if award_data.id then
			local have_get_award_ids = basefunc.decode_task_award_status(player_data.have_get_award_num)
			have_get_award_ids[award_data.id] = true
			player_data.have_get_award_num = basefunc.encode_task_award_status( have_get_award_ids )
		end

		if award_data.asset_type and award_data.value then
			----- 资产改变
			skynet.send(DATA.service_config.data_service,"lua","change_asset_and_sendMsg",
                    player_id , award_data.asset_type ,
                    award_data.value , ASSET_CHANGE_TYPE.DAFUHAO_GAME_AWARD , award_data.id )
		end

		---- 减积分
		player_data.now_credits = player_data.now_credits - player_data.need_credits
		---- 加游戏次数
		player_data.now_game_num = player_data.now_game_num + 1
		---- 改需要的积分数
		player_data.need_credits = PUBLIC.get_game_need_credits( player_data.now_game_num )

		---- 写日志
		local sql_str = string.format([[
						insert into player_da_fu_hao_award_log (player_id,game_num,award_id,award_name) 
						values('%s',%s,%s,'%s')
					]] , player_id , player_data.now_game_num , award_data.id , award_data.name )

		PUBLIC.db_exec(sql_str )

		
		PUBLIC.update_data( player_id )

		ret.result = 0
		ret.award_id = award_data.id
		ret.now_game_num = player_data.now_game_num
		ret.need_credits = player_data.need_credits
		ret.now_credits = player_data.now_credits
	else
		PUBLIC.off_action_lock( "dafuhao_kaijiang" , player_id )
		print("-----------------return 1003 2")
		return 1003
	end


	PUBLIC.off_action_lock( "dafuhao_kaijiang" , player_id )
	return ret
end

---- 请求一个开奖广播
function CMD.get_one_kaijiang_broadcast()

	---- 随机搞一个
	local random_name_vec = math.random() < 0.5 and tuoguan_names_boy or tuoguan_names_girl
	local random_name = random_name_vec[ math.random(#random_name_vec) ]
	local random_award_id = math.random(10)

	return { player_name = random_name , award_id = random_award_id }
end

function PUBLIC.register_msg()
	---- 注册需要处理的消息
	skynet.send( DATA.service_config.msg_notification_center_service , "lua" , "add_msg_listener" , "game_compolete_task" , {
			msg_tag = DATA.msg_tag ,
			node = skynet.getenv("my_node_name"),
			addr = skynet.self(),
			cmd = "freestyle_game_gain"
		} )

	skynet.send( DATA.service_config.msg_notification_center_service , "lua" , "add_msg_listener" , "zajindan_award" , {
			msg_tag = DATA.msg_tag ,
			node = skynet.getenv("my_node_name"),
			addr = skynet.self(),
			cmd = "game_profit_acc"
		} )

	skynet.send( DATA.service_config.msg_notification_center_service , "lua" , "add_msg_listener" , "buyu_award" , {
			msg_tag = DATA.msg_tag ,
			node = skynet.getenv("my_node_name"),
			addr = skynet.self(),
			cmd = "game_profit_acc"
		} )

	skynet.send( DATA.service_config.msg_notification_center_service , "lua" , "add_msg_listener" , "xiaoxiaole_award" , {
			msg_tag = DATA.msg_tag ,
			node = skynet.getenv("my_node_name"),
			addr = skynet.self(),
			cmd = "game_profit_acc"
		} )

	----- 充值消息
	skynet.send( DATA.service_config.msg_notification_center_service , "lua" , "add_msg_listener" , "on_pay_success" , {
			msg_tag = DATA.msg_tag ,
			node = skynet.getenv("my_node_name"),
			addr = skynet.self(),
			cmd = "player_pay_msg"
		} )
end

function PUBLIC.unregister_msg()
	skynet.send( DATA.service_config.msg_notification_center_service , "lua" , "delete_msg_listener" , "game_compolete_task" ,  DATA.msg_tag )

	skynet.send( DATA.service_config.msg_notification_center_service , "lua" , "delete_msg_listener" , "zajindan_award" ,  DATA.msg_tag )

	skynet.send( DATA.service_config.msg_notification_center_service , "lua" , "delete_msg_listener" , "buyu_award" ,  DATA.msg_tag )

	skynet.send( DATA.service_config.msg_notification_center_service , "lua" , "delete_msg_listener" , "xiaoxiaole_award" ,  DATA.msg_tag )

	skynet.send( DATA.service_config.msg_notification_center_service , "lua" , "delete_msg_listener" , "on_pay_success" ,  DATA.msg_tag )

end

function PUBLIC.init()

	---- 动态加载配置
	nodefunc.query_global_config( "da_fu_hao_server", PUBLIC.load_config )


	local is_in_act = PUBLIC.check_is_in_act()

	--- 在活动时间内才注册监听消息
	if is_in_act then
		PUBLIC.register_msg()
	else
		PUBLIC.unregister_msg()
	end

	


end

-------
--- for test 加积分给某人
function CMD.add_dafuhao_credits(player_id , add)
	local player_data = PUBLIC.get_player_data(player_id)

	player_data.now_credits = player_data.now_credits + add

	PUBLIC.update_data( player_id )
end



function CMD.start(_service_config)
	DATA.service_config = _service_config

	PUBLIC.init()

end

-- 启动服务
base.start_service()