--
-- Created by wss.
-- User: hare
-- Date: 2018/12/28
-- Time: 19:29
-- 消消乐  agent
--


local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"

local xiaoxiaole_lib = require "player_agent/xiaoxiaole_agent/xiaoxiaole_lib"

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST
local PUBLIC = base.PUBLIC

local return_msg={result=0}

-- 断线后多久自动退出游戏
local disconnect_time_delay = 120
local now_disconnect_timeout = nil

--update 间隔
local dt=1
local update_timer=nil

local game_name = "xiaoxiaole_game"

function PUBLIC.db_exec(_sql , _queue_name)
  skynet.send(DATA.service_config.data_service,"lua","db_exec",_sql , _queue_name)
end

DATA.xxl_kaijiang_verify_vec = {
	500,
	1000,
	2000,
	4000,
	8000,
	16000,
	32000,
	64000,
	128000,
	256000,
	512000,
	1024000,
	2048000,
}


---- 
DATA.xiaoxiaole_game_data = nil
local all_data=nil

PUBLIC.xiaoxiaole_agent_protect = {}
local PROTECT = PUBLIC.xiaoxiaole_agent_protect


function PROTECT.new_game()

	DATA.xiaoxiaole_game_data={}
	all_data=DATA.xiaoxiaole_game_data

	all_data.status = "gaming"
	---- 上一次的奖励的总倍数
	all_data.last_award_rate = 0
	---- 上次获得奖励的总钱数
	all_data.last_award_money = 0

	---- 当前的消除maps
	all_data.kaijiang_maps = nil

	---- 当前的lucky   maps
	all_data.lucky_maps = nil

	update_timer=skynet.timer(dt,PROTECT.update)
	DATA.signal_logout:bind(game_name,PROTECT.player_exit_game)
	DATA.signal_disconnect:bind(game_name,PROTECT.disconnect_deal)
end

function PROTECT.free_game()
	---- 解锁
	PUBLIC.unlock("xiaoxiaole_game","xiaoxiaole_game")

	DATA.xiaoxiaole_game_data = nil
	all_data = nil

	if update_timer then
		update_timer:stop()
		update_timer=nil
	end

	DATA.signal_disconnect:unbind(game_name)
	DATA.signal_logout:unbind(game_name)

end

function PROTECT.player_exit_game()
	print("-----------player_exit_game")
	REQUEST.xxl_quit_game()

end

function PROTECT.disconnect_deal()
	print("-----------disconnect_deal" , now_disconnect_timeout)
	now_disconnect_timeout = os.time() + disconnect_time_delay

end

function PROTECT.update()

	if now_disconnect_timeout then

		if now_disconnect_timeout < os.time() then
			print("-----------player_exit_game  222")
			REQUEST.xxl_quit_game()

			now_disconnect_timeout = nil
		end

	end

end

----all info
function REQUEST.xxl_all_info()
	local ret = {}

	--- 操作限制
	if PUBLIC.get_action_lock("xxl_all_info") then
		ret.result = 1008
		return ret
	end
	PUBLIC.on_action_lock( "xxl_all_info" )

	if not all_data or all_data.status ~= "gaming" then
		ret.result = 1002

		PUBLIC.off_action_lock( "xxl_all_info" )
		return ret
	end

	now_disconnect_timeout = nil

	ret.result = 0
	ret.last_award_rate = all_data.last_award_rate
	ret.last_award_money = all_data.last_award_money
	ret.kaijiang_maps = all_data.kaijiang_maps
	ret.lucky_maps = all_data.lucky_maps

	PUBLIC.off_action_lock( "xxl_all_info" )
	return ret
end

----开奖
function REQUEST.xxl_kaijiang(self)

	local ret = {}
	if not self.bets or type(self.bets) ~= "table" then
		ret.result = 1001
		return ret
	end

	--- 操作限制
	if PUBLIC.get_action_lock("xxl_kaijiang") then
		ret.result = 1008
		return ret
	end
	PUBLIC.on_action_lock( "xxl_kaijiang" )

	if not all_data or all_data.status ~= "gaming" or not all_data.room_id or not all_data.table_id then
		ret.result = 1002
		
		PUBLIC.off_action_lock( "xxl_kaijiang" )
		return ret
	end

	----- 金币消耗验证
	local need_money = 0
	local last_money = nil
	for key,money in pairs(self.bets) do
		need_money = need_money + (money or 0)

		---- 每个值，必须相同
		if last_money then
			if last_money ~= money then
				ret.result = 1001
				PUBLIC.off_action_lock( "xxl_kaijiang" )
				return ret
			end
		end

		last_money = money
	end

	if need_money == 0 then
		ret.result = 1002
		PUBLIC.off_action_lock( "xxl_kaijiang" )
		return ret
	end

	local is_in_verify_vec = false
	for key,value in pairs(DATA.xxl_kaijiang_verify_vec) do
		if need_money == value then
			is_in_verify_vec = true
			break
		end
	end
	if not is_in_verify_vec then
		ret.result = 1001
		PUBLIC.off_action_lock( "xxl_kaijiang" )
		return ret
	end


	local ver_ret = PUBLIC.asset_verify({[1] = {
		asset_type = PLAYER_ASSET_TYPES.JING_BI,
		condi_type = NOR_CONDITION_TYPE.CONSUME,
		value =need_money ,
	} })
	if ver_ret.result ~= 0 then
		PUBLIC.off_action_lock( "xxl_kaijiang" )
		return ver_ret
	end

	
	----- 开奖发到房间
	local kaijiang = nodefunc.call( all_data.room_id , "kaijiang" , all_data.table_id , self.bets , need_money , math.floor(need_money / #self.bets) )

	if kaijiang and type(kaijiang) == "number" then
		ret.result = kaijiang
		PUBLIC.off_action_lock( "xxl_kaijiang" )
		return ret
	end

	--- 扣钱
	CMD.change_asset_multi({[1] = {asset_type = PLAYER_ASSET_TYPES.JING_BI,value = -need_money }}
			,ASSET_CHANGE_TYPE.XXL_GAME_SPEND, 0 )

	----- 处理一下lucky
	local ori_kaijiang_maps = kaijiang.kaijiang_maps
	local kaijiang_maps =  kaijiang.kaijiang_maps
	local lucky_maps = ""
	if kaijiang.xc_map_rate and kaijiang.lucky_data and type(kaijiang.lucky_data) == "table" then
		kaijiang_maps , lucky_maps = xiaoxiaole_lib.create_lucky( kaijiang.kaijiang_maps , math.floor(kaijiang.award_rate+0.5) , kaijiang.lucky_data )
	end

	----- 加 开奖 日志
	local sql_str = string.format([[
						insert into player_xiaoxiaole_log (player_id,total_bet_money,bet_money,kaijiang_beishu,kaijiang_award , orig_xc_str , final_xc_str , lucky_str ) 
						values('%s',%s,%s,%s,%s , '%s' , '%s' , '%s' )
					]] , DATA.my_id , need_money , math.floor(need_money / #self.bets) , kaijiang.real_award_rate or 0 , kaijiang.award_money or 0 , ori_kaijiang_maps , kaijiang_maps , lucky_maps )

	PUBLIC.db_exec(sql_str )

	ret.result = 0 
	ret.kaijiang_maps = kaijiang_maps
	ret.lucky_maps = lucky_maps
	ret.award_rate = kaijiang.award_rate       --- 这个是*10的
	ret.award_money = kaijiang.award_money 

	---- 发出消息
	--DATA.msg_dispatcher:call("xiaoxiaole_award", ret.award_money ) 
	PUBLIC.trigger_msg( {name = "xiaoxiaole_award"} , ret.award_money )

	---- 上一次的奖励的总倍数 * 10 之后的
	all_data.last_award_rate = ret.award_rate
	---- 上次获得奖励的总钱数
	all_data.last_award_money = ret.award_money
	
	all_data.kaijiang_maps = kaijiang_maps
	all_data.lucky_maps = lucky_maps

	------------------------------------------------- test ---------------------------------------------------
	--[[ret.result=0
	ret.kaijiang_maps = "44544453545553534111445315114443131333333266333422244554222225333354453333344552215364423244314234443552054335550543630300136203005362050001400000033000000030000000500000005000"
	ret.lucky_maps = "333334"
	ret.award_money = 6656000
	ret.award_rate = 2600.0

	all_data.last_award_rate = ret.award_rate
	---- 上次获得奖励的总钱数
	all_data.last_award_money = ret.award_money
	
	all_data.kaijiang_maps = kaijiang_maps
	all_data.lucky_maps = lucky_maps--]]

	------------------------------------------------- test ---------------------------------------------------

	PUBLIC.off_action_lock( "xxl_kaijiang" )
	return ret
end

-------- test -------------------------
function PUBLIC.test_rebate()
	REQUEST.xxl_enter_game()

	math.randomseed(os.time())
	local spend = 0
	local award = 0
	for i=1,10000 do

		local base_money = 3200
		local total_bet = base_money * 5
		spend = spend + total_bet

		local bet = { bets = { base_money , base_money , base_money, base_money, base_money } }
		local ret = REQUEST.xxl_kaijiang(bet)
		--dump(ret , "-----------ret:")
		if not ret.award_money then
			dump(ret , "-----------ret:")
		end

		award = award + ret.award_money
		if i % 100 == 0 then
			print("-----------------------------------------------------------test_rebate-------------------------------------------------------i:",i)
		end
	end

	print("test_rebate____spend:",spend)
	print("test_rebate____award:",award)
	print("test_rebate____award / spend: ", award / spend )

end


------ 正常的进入游戏
function REQUEST.xxl_enter_game()
	local ret = {}
	--- 操作限制
	if PUBLIC.get_action_lock("xxl_enter_game") then
		ret.result = 1008
		return ret
	end
	PUBLIC.on_action_lock( "xxl_enter_game" )

	----- 如果有已经锁定了，那么返回错误码
	if DATA.game_lock or (all_data and all_data.room_id) or (all_data and all_data.table_id) then
		dump(all_data , "-----------all_data:")
		dump(DATA.xiaoxiaole_game_data , "-------------DATA.xiaoxiaole_game_data:")
		ret.result=1005
		PUBLIC.off_action_lock( "xxl_enter_game" )
		return ret
	end

	---- 锁定到这个游戏中
	PUBLIC.lock("xiaoxiaole_game","xiaoxiaole_game")

	PROTECT.new_game()

	---- 进入房间
	local ret_code , room_id , table_id = skynet.call( DATA.service_config.xiaoxiaole_manager_service , "lua" , "create_xiaoxiaole_room" , DATA.my_id , DATA.player_data.player_info.name )

	ret.result = ret_code
	all_data.room_id = room_id
	all_data.table_id = table_id

	PUBLIC.off_action_lock( "xxl_enter_game" )

	return ret
end

----- 退出游戏
function REQUEST.xxl_quit_game(self)
	print("----------------------------- xxl_quit_game")
	--- 操作限制
	if PUBLIC.get_action_lock("xxl_quit_game") then
		return_msg.result = 1008
		return return_msg
	end
	PUBLIC.on_action_lock( "xxl_quit_game" )

	if not all_data then
		return_msg.result=0
		PUBLIC.off_action_lock( "xxl_quit_game" )
		return return_msg
	end

	---- 调用退出房间
	local ret_code = skynet.call(DATA.service_config.xiaoxiaole_manager_service,"lua","quit_xiaoxiaole_room",DATA.my_id)

	PROTECT.free_game()
	
	PUBLIC.off_action_lock( "xxl_quit_game" )
	return_msg.result = ret_code
	return return_msg
end

function PROTECT.init()
	--- 测试消消乐，返奖
	-- PUBLIC.test_rebate()
end


return PROTECT