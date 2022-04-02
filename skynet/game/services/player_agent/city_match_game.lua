-- friendgame_agent

local skynet = require "skynet_plus"
local basefunc=require"basefunc"
require"printfunc"
require "normal_enum"
local nodefunc = require "nodefunc"
local base = require "base"
local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC
local REQUEST=base.REQUEST
local PROTECT={}
local cjson = require "cjson"
cjson.encode_sparse_array(true,1,0)

local zy_cup_activity_cfg = require "zy_cup_activity_cfg"

--[[
		nil
		wait_begin  --等待开始
		wait_table	--等待分配桌子
		
		gameover
--]]

--config**********
--房卡场支持的游戏类型
local support_game_type={
	nor_mj_xzdd=true,
	nor_ddz_nor=true,
	nor_ddz_lz=true,
}
local room_max_player={
	nor_mj_xzdd = 4,
	nor_ddz_nor = 3,
	nor_ddz_lz = 3,
}
local game_name_map = {
	nor_ddz_nor = "经典斗地主",
	nor_ddz_lz = "赖子斗地主",
}

--config**********



local game_name = "cityMatchGame"
local act_flag = false
--
local game_model="cityMatchGame"

local play_type = nil

local base_info = nil
local room_status = nil

local gameInstance=nil
local gameConfig=nil
local all_data=nil

--玩家信息
local p_info=nil

local return_msg={result=0}

local update_timer=nil


--update 间隔
local dt=1
--[[
	制定协议

	运算出配置（独特）  room   游戏过程配置  游戏规则配置  agent配置

	创建房间               加入游戏（得到游戏配置）
	生成具体的代理			生成具体的代理
	加入具体的游戏房间		  加入具体的游戏房间

		游戏过程

	计算
	结束游戏

	强制结束			

--]]

local function add_status_no()
	all_data.status_no=all_data.status_no+1
end

local function on_agent_restart()
	-- if chat_room_id then
	-- 	skynet.call(DATA.service_config.chat_service,"lua","join_room",chat_room_id,DATA.my_id,PUBLIC.get_gate_link())
	-- end
end

local function update()
	
	if all_data then

		if all_data.countdown and all_data.countdown>0 then
			all_data.countdown = all_data.countdown - 1
		end

		if all_data.countdown < 1 then
			if overtime_cb then
				overtime_cb()
				overtime_cb = nil
			end
		end

	end

	-- PROTECT.mjfg_auto_cancel_signup()

end

--[[
	
--]]
-- ###_test 初始化数据  config 是报名成功后返回的
local function new_game(manager_id,game_type,config)

	DATA.city_match_game_data={}
	all_data=DATA.city_match_game_data

	all_data.gameover_info = nil

	all_data.m_PROTECT=PROTECT


	all_data.manager_id=manager_id
	all_data.game_type=game_type

	all_data.match_type=config.match_type

	all_data.status="wait_begin"

	all_data.status_no=0

	all_data.score = 0
	
	all_data.model_name="citymatchgame"

	all_data.match_info={}
	all_data.match_info.name=config.name
	all_data.match_info.total_players=config.total_players
	all_data.match_info.is_cancel_signup=config.is_cancel_signup
	all_data.match_info.total_round=config.total_round
	all_data.match_info.signup_match_id=config.signup_match_id
	all_data.match_info.signup_service_id=config.signup_service_id
	all_data.countdown=config.cancel_signup_cd
	all_data.signup_num=config.signup_num

	all_data.signup_assets=config.signup_assets

	all_data.base_info={}
	base_info=all_data.base_info
	base_info.cur_race = 1

	all_data.config={
		agent_cfg={
			overtime_auto_action_cfg = 1,
		},
	}

	update_timer=skynet.timer(dt,update)
end


local function free_game()

	if update_timer then
		update_timer:stop()
		update_timer=nil
	end
	
	PUBLIC.unlock(game_name)
	PUBLIC.free_agent(game_name)
	
	if gameInstance then
		gameInstance.free()
		gameInstance=nil
	end

	DATA.city_match_game_data=nil

	act_flag=false
	
	-- chat_room_id = nil
end

--###_test
local function get_signup_service_id(id)
	if id == 1 then
		return "match_service_"..zy_cup_activity_cfg.hx_game_id
	elseif id == 2 then
		return "match_service_"..zy_cup_activity_cfg.fs_game_id
	end
end

--报名 ###_test  id    
function REQUEST.citymg_signup(self)
	if act_flag then
		return_msg.result=1008
		return return_msg
	end

	act_flag=true
	
	if not self or not self.id or type(self.id)~="number" then 
		return_msg.result=1001
		act_flag=false
		return return_msg
	end

	if self.id ~= 1 and self.id ~= 2 then
		return_msg.result=1001
		act_flag=false
		return return_msg
	end

	local signup_service_id=get_signup_service_id(self.id)

	if self.id == 1 then
		--检测是否已经获取了复赛资格
		local d = PROTECT.get_my_rank_hx()
		if d.result==0 and d.rank then
			act_flag=false
			return {
				result=3301,
				match_type=self.id
			}
		elseif d.result~=0 then
			act_flag=false
			d.match_type=self.id
			return d
		end

	elseif self.id == 2 then
		--检测是否实名认证和绑定手机号了
		
	end

	if not PUBLIC.lock(game_name,game_name,self.id) then 
		return_msg.result=1005
		act_flag=false
		return return_msg
	end

	PUBLIC.ref_agent(game_name)

	local asset_lock_info
	local signup_assets

	--请求进入条件
	local _result,_data=nodefunc.call(signup_service_id,"get_enter_info")

	if _result=="CALL_FAIL" then

		free_game()
		return_msg.result=1000
		act_flag=false
		return return_msg

	elseif _result == 0 then
		--锁定所需财务
		asset_lock_info = PUBLIC.asset_lock(_data)
		if asset_lock_info.result == 0 then
			signup_assets=_data
			print("asset_lock ok ,key:"..asset_lock_info.lock_id)
		else
			print("asset_lock error ,result:"..asset_lock_info.result)
			act_flag=false
			free_game()
			return {
				result=asset_lock_info.result,
				match_type=self.id
			}
		end

	else
		return_msg.result=_result
		act_flag=false
		free_game()
		return return_msg
	end

	local _result=nodefunc.call(signup_service_id,"player_signup",DATA.my_id)
	if _result=="CALL_FAIL" then
		free_game()
	elseif _result and _result.result==0 then
		
		local ret = PUBLIC.asset_commit(asset_lock_info.lock_id,ASSET_CHANGE_TYPE.MATCH_SIGNUP,self.id)
		PUBLIC.notify_asset_change_msg()
		
		if ret.result ~= 0 then
			print("asset_commit error ,result:"..ret.result)
		end
		_result.game_type = "nor_ddz_nor"
		_result.signup_service_id = signup_service_id
		_result.signup_assets=signup_assets
		_result.match_type=self.id
		play_type = GAME_TYPE_TO_PLAY_TYPE[_result.game_type]
		new_game(server_id,_result.game_type,_result)

		act_flag=false
		return _result
	else
		local ret = PUBLIC.asset_unlock(asset_lock_info.lock_id)
		if ret.result == 0 then
			print("asset_unlock ok")
		else
			print("asset_unlock error ,result:"..ret.result)
		end

		free_game()
		if _result then
			act_flag=false
			return _result 
		end
	end

	return_msg.result=1000
	act_flag=false
	return return_msg
end

--取消报名
function REQUEST.citymg_cancel_signup(self,is_force)
	if act_flag or not all_data or all_data.status~="wait_begin" then 
		return_msg.result=1002
		return return_msg
	end
	act_flag=true

	if (all_data.match_info.is_cancel_signup==1 or is_force) and all_data.countdown and all_data.countdown<=0 then 
		local _result=nodefunc.call(all_data.match_info.signup_service_id,"cancel_signup"
										,all_data.match_info.signup_match_id,DATA.my_id)
		if _result==0 then 
			--返回资产  ###_test
			if all_data.signup_assets then
				CMD.change_asset_multi(all_data.signup_assets,ASSET_CHANGE_TYPE.MATCH_CANCEL_SIGNUP,all_data.match_info.signup_service_id)
				all_data.signup_assets=nil
			end

			free_game()
			all_data.status=nil
			
		end
		act_flag=false
		return_msg.result=_result
		return return_msg
	end
	act_flag=false
	return_msg.result=1002
	return return_msg 
end

--匹配超时，自动取消
function PROTECT.citymg_auto_cancel_signup()
	if all_data 
		and all_data.status=="wait_begin" 
		and auto_cancel_signup_bt+auto_cancel_signup_time < os.time() then

		local ret = REQUEST.citymg_cancel_signup(nil,true)
		if ret.result == 0 then
			PUBLIC.request_client("citymg_auto_cancel_signup_msg",{result=0})
			print("overtime citymg auto_cancel_signup")
		end
	end
end

function REQUEST.citymg_req_cur_signup_num(self)

	if act_flag or not all_data or all_data.status~="wait_begin" then 
		return_msg.result=1002
		return return_msg
	end

	act_flag=true
	local _result=nodefunc.call(all_data.match_info.signup_service_id,"get_signup_player_num"
									,all_data.match_info.signup_match_id)
	act_flag=false

	if _result~="CALL_FAIL" then
		if _result.signup_num then
			all_data.signup_num=_result.signup_num
		end 
		return _result
	end
	return_msg.result=1000
	return return_msg 
end

function REQUEST.citymg_quit_game(self)

	if not all_data then
		return_msg.result=0
		return return_msg
	end

	if all_data.status~="gameover" then 
		return_msg.result=1002
		return return_msg
	end

	free_game()
	all_data = nil
end

--海选赛的rank
function REQUEST.citymg_get_rank_hx_list(self)
	
	local rank_point = self.rank_point
	if not rank_point or type(rank_point)~="number" or rank_point<1 then
		return_msg.result=1001
		return return_msg  
	end

	if act_flag then
		return_msg.result=1008
		return return_msg
	end

	act_flag=true

	local signup_service_id=get_signup_service_id(1)
	local ret = nodefunc.call(signup_service_id,"get_winners_list",rank_point)

	act_flag=false

	if ret == "CALL_FAIL" then
		return_msg.result=1004
		return return_msg  
	end

	return {
		result = 0,
		rank_list = ret,
	}

end

function PROTECT.get_my_rank_hx()
	
	local signup_service_id=get_signup_service_id(1)
	local ret = nodefunc.call(signup_service_id,"get_my_rank",DATA.my_id)
	if ret == "CALL_FAIL" then
		return_msg.result=1004
		return return_msg
	else
		return {
			result = 0,
			rank = ret
		}
	end

end

--海选赛的rank
function REQUEST.citymg_get_my_rank_hx(self)
	
	if act_flag then
		return_msg.result=1008
		return return_msg
	end

	act_flag=true
	
	local ret = PROTECT.get_my_rank_hx()

	act_flag=false

	return ret

end


--复赛的rank
function REQUEST.citymg_get_rank_fs_list(self)
	
	local rank_point = self.rank_point
	if not rank_point or type(rank_point)~="number" or rank_point<1 then
		return_msg.result=1001
		return return_msg  
	end

	if act_flag then
		return_msg.result=1008
		return return_msg
	end

	act_flag=true

	local signup_service_id=get_signup_service_id(2)
	local ret = nodefunc.call(signup_service_id,"get_winners_list",rank_point)
	
	act_flag=false

	if ret == "CALL_FAIL" then
		return_msg.result=1004
		return return_msg  
	end

	return {
		result = 0,
		rank_list = ret,
	}

end

--复赛的rank
function REQUEST.citymg_get_my_rank_fs(self)
	
	if act_flag then
		return_msg.result=1008
		return return_msg
	end

	act_flag=true

	local signup_service_id=get_signup_service_id(2)
	local ret = nodefunc.call(signup_service_id,"get_my_rank",DATA.my_id)
	
	act_flag=false

	if ret == "CALL_FAIL" then
		return_msg.result=1004
		return return_msg  
	end

	return {
		result = 0,
		rank = ret,
	}

end


--[[比赛状态
	status - wait | signuping | gaming | over
	stage - hx | fs | js
	time - 13562
]]
local show_ui_time = nil
--结束以后等待下一阶段的等待时间
local fs_wait_next_time = nil
local hx_cfg = nil
local fs_cfg = nil
local js_cfg = nil
function REQUEST.citymg_get_match_status(self)
	
	show_ui_time = zy_cup_activity_cfg.show_ui
	fs_wait_next_time = zy_cup_activity_cfg.fs_gaming
	js_cfg = {
		begin_signup_time = zy_cup_activity_cfg.js_begin,
		end_signup_time = zy_cup_activity_cfg.js_end,
	}

	if act_flag then
		return_msg.result=1008
		return return_msg
	end

	act_flag=true

	hx_cfg = hx_cfg or nodefunc.call(get_signup_service_id(1),"get_signup_config")
	fs_cfg = fs_cfg or nodefunc.call(get_signup_service_id(2),"get_signup_config")

	act_flag=false

	if hx_cfg and type(hx_cfg)=="table" 
		and fs_cfg and type(fs_cfg)=="table" then
		-- print("比赛正常")
	else
		return {result = 3302}
	end

	if os.time() < show_ui_time then
		return {result = 0,time = show_ui_time-os.time()}
	end

	if hx_cfg then

		local status = nil
		local time = 0

		if os.time() <= hx_cfg.begin_signup_time then
			status = "wait"
			time = hx_cfg.begin_signup_time - os.time()
		elseif os.time() > hx_cfg.begin_signup_time and os.time() < hx_cfg.end_signup_time then
			status = "gaming"
			time = hx_cfg.end_signup_time - os.time()
		end

		if status then
			return {
				result = 0,
				status = status,
				stage = "hx",
				time = time,
			}
		end

	end

	if fs_cfg then

		local status = nil
		local time = 0

		if os.time() <= fs_cfg.begin_signup_time then
			status = "wait"
			time = fs_cfg.begin_signup_time - os.time()
		elseif os.time() > fs_cfg.begin_signup_time and os.time() <= fs_cfg.begin_signup_time+fs_cfg.signup_dur then
			status = "signuping"
			time = fs_cfg.begin_signup_time+fs_cfg.signup_dur - os.time()
		elseif os.time() > fs_cfg.begin_signup_time+fs_cfg.signup_dur 
				and os.time() < fs_cfg.begin_signup_time+fs_cfg.signup_dur+fs_wait_next_time then
			status = "gaming"
			time = fs_cfg.begin_signup_time+fs_cfg.signup_dur+fs_wait_next_time - os.time()
		end

		if status then
			return {
				result = 0,
				status = status,
				stage = "fs",
				time = time,
			}
		end

	end

	if js_cfg then

		local status = nil
		local time = 0

		if os.time() <= js_cfg.begin_signup_time then
			status = "wait"
			time = js_cfg.begin_signup_time - os.time()
		elseif os.time() > js_cfg.begin_signup_time and os.time() < js_cfg.end_signup_time then
			status = "gaming"
			time = js_cfg.end_signup_time - os.time()
		elseif os.time() >= js_cfg.end_signup_time then
			status = "over"
			time = -1
		end

		if status then
			return {
				result = 0,
				status = status,
				stage = "js",
				time = time,
			}
		end

	end

	return {
		result = 1004,
	}

end


--报名结束游戏开始
function CMD.citymg_begin_msg(_m_svr_id,_socre,_rank,_player_count)
	print("@@@ CMD.citymg_begin_msg",_m_svr_id,_socre,_rank)

	all_data.status="wait_table"
	--优化传输包体,游戏开始后数据就没用了
	all_data.signup_num=nil

	all_data.countdown=0
	-- 
	all_data.score=_socre
	--隐藏分
	all_data.hide_score=0
	all_data.rank=_rank
	all_data.match_info.match_svr_id = _m_svr_id
	all_data.match_info.total_players = _player_count

	-- 获得玩法agent
	all_data.gameInstance=PUBLIC.require_game_by_type(all_data.game_type)
	gameInstance=all_data.gameInstance
	if not gameInstance then
		error("gameInstance not exist!!!!!!"..game_type)
	end

	add_status_no()
	PUBLIC.request_client("citymg_begin_msg",{status_no=all_data.status_no,rank=_rank
												,score=_socre,total_players=_player_count})
end

function CMD.citymg_enter_room_msg(_room_id,_t_num,_round_info)

	all_data.base_info.room_id=_room_id
	all_data.base_info.t_num=_t_num

	all_data.round_info=_round_info

	all_data.player_info={}
	p_info=all_data.player_info

	gameInstance.init(all_data)

	--加入房间
	gameInstance.join_room({
								id=DATA.my_id,
								name=DATA.player_data.player_info.name,
								head_link=DATA.player_data.player_info.head_image,
								sex=DATA.player_data.player_info.sex,
								dressed_head_frame = DATA.player_data.dress_data.dressed_head_frame,
								glory_score = DATA.player_data.glory_data.score,
								score=all_data.score,
							})
					

	print("cmg_enter_room_msg",DATA.my_id)

end

--晋级决赛 - 调整分数  ###_test
function CMD.citymg_promoted_final_msg(_score)
	all_data.score=_score
	add_status_no()
	PUBLIC.request_client("citymg_score_change_msg",{status_no=all_data.status_no,score=all_data.score})
end

function CMD.citymg_change_rank_msg(_rank)
	if all_data then
		if _rank~=all_data.rank then 
			all_data.rank=_rank
			add_status_no()
			--通知客户端
			PUBLIC.request_client("citymg_rank_msg",{status_no=all_data.status_no,rank=_rank})
		end
	end 
end



--比赛完成了，需要等待比赛结果
function CMD.citymg_wait_result_msg()
	print("gameover cmg_wait_result_msg")
	add_status_no()
	all_data.status="wait_result"
	PUBLIC.request_client("citymg_wait_result_msg",{status_no=all_data.status_no,
												status=all_data.status})
end

--比赛完成了，我已经晋级了，先休息一下，然后发起匹配请求
function CMD.citymg_promoted_msg(is_promoted_final)
	print("gameover cmg_promoted_msg")

	all_data.status="promoted"
	all_data.countdown = 3
	all_data.promoted_type = is_promoted_final and 1 or 0

	add_status_no()
	PUBLIC.request_client("citymg_promoted_msg",
							{status_no=all_data.status_no,
							status=all_data.status,
							countdown=all_data.countdown,
							promoted_type=all_data.promoted_type})
	
	overtime_cb = function ()
		--通知管理者我准备好了
		nodefunc.send(all_data.match_info.match_svr_id,"player_ready_matching",DATA.my_id)
		print("我准备好了:",DATA.my_id)
		overtime_cb = nil
	end

end


local function citymg_gameover_msg(_rank,_reward,_type)
	print("cmg_gameover_msg!!")

	all_data.status="gameover"

	all_data.gameover_info={
							rank=_rank,
							reward=_reward,
							match_type=all_data.match_type,
						}
	
	--奖励以邮件形式发送
	local email = {
		type = "native",
		receiver = DATA.my_id,
		sender = "系统",
		data={asset_change_data={change_type="city_match",change_id=0}}
	}


	if _type == "hx" then

		if _rank <= 1 then
			email.title="第一届鲸鱼杯公益斗地主大赛海选赛"
			email.data.content="恭喜您在海选赛晋级，这是您的奖励。另外通过您的努力表现夺得了复选赛的资格，祝您在复选赛取得佳绩，大奖抱回家！"
			
			for i,asset in ipairs(_reward) do
				email.data[asset.asset_type] = asset.value
			end

		else
			-- CMD.change_asset_multi(_reward,"city_match_hx_lose",_rank)

			email.title="第一届鲸鱼杯公益斗地主大赛海选赛"
			email.data.content="很遗憾您在海选赛被淘汰，感谢您的参与，这是给与您的鼓励奖，希望下次比赛能取得好成绩。"
			
			for i,asset in ipairs(_reward) do
				email.data[asset.asset_type] = asset.value
			end

		end

	elseif _type == "fs" then

		if _rank <= zy_cup_activity_cfg.fs_promoted_num then
			email.title="第一届鲸鱼杯公益斗地主大赛复赛"
			email.data.content="恭喜您在复赛夺得".._rank.."名，这是您的排名奖励。另外通过您的努力表现夺得了决赛的资格，祝您在复选赛取得佳绩，大奖抱回家！"
			
			for i,asset in ipairs(_reward) do
				email.data[asset.asset_type] = asset.value
			end
		else
			
			email.title="第一届鲸鱼杯公益斗地主大赛复赛"
			email.data.content="很遗憾您在复赛被淘汰，感谢您的参与，这是给与您的鼓励奖，希望下次比赛能取得好成绩。"
			for i,asset in ipairs(_reward) do
				email.data[asset.asset_type] = asset.value
			end

		end
	end

	if email.title then
		skynet.send(DATA.service_config.email_service,"lua","send_email",email)
	end

	add_status_no()
	
	PUBLIC.request_client("citymg_gameover_msg",{status_no=all_data.status_no,final_result=all_data.gameover_info})

	free_game()
end

--最终结算  ###_test
function CMD.citymg_gameover_hx_msg(_rank,_reward)
	citymg_gameover_msg(_rank,_reward,"hx")
end


function CMD.citymg_gameover_fs_msg(_rank,_reward)
	citymg_gameover_msg(_rank,_reward,"fs")
end



--###_test 发送给玩家
function PROTECT.my_join_return(_data)

	all_data.status="gaming"
	if _data.p_info then
		for _,_info in pairs(_data.p_info) do
			p_info[#p_info+1]=_info
		end
	end
	--###_test 发送给玩家
		--通知客户端
	add_status_no()
	PUBLIC.request_client("citymg_enter_room_msg",
							{status_no=all_data.status_no,
							seat_num=all_data.game_data.seat_num,
							round_info=all_data.round_info,
							players_info=p_info})

	--自动ready
	gameInstance.ready()
end

local function add_p_info(_in_info)

	for i,_info in ipairs(p_info) do
		if _info.seat_num == _in_info.seat_num then
			p_info[i] = _in_info
			return
		end
	end

	p_info[#p_info+1]=_in_info
end
local function find_p_info(_seat_num)
	if p_info then
		if p_info[_seat_num] and  p_info[_seat_num].seat_num==_seat_num then
			return _seat_num
		end
		for i,_info in ipairs(p_info) do
			if _info.seat_num == _seat_num then
				return i
			end
		end
	end

	return nil
end
function PROTECT.player_join_msg(_info)

	add_p_info(_info)
	
	--通知客户端
	add_status_no()
	PUBLIC.request_client("citymg_join_msg",{status_no=all_data.status_no,player_info=_info})
end


--计算隐藏分(根据牌型)
local function calculate_ddz_hide_socre(my_pai_data)
	
	if all_data.hide_score then
		
		local dw = my_pai_data.hash[17] or 0
		local xw = my_pai_data.hash[16] or 0
		local _2 = my_pai_data.hash[15] or 0
		local socre = dw*3+xw*2+_2

		all_data.hide_score=all_data.hide_score+socre
	end

end
--如果是斗地主则需要计算隐藏分
function PROTECT.ddz_dizhu_msg(my_pai_data)
	calculate_ddz_hide_socre(my_pai_data)
end


function PROTECT.game_next_game_msg(_data)
	base_info.cur_race=base_info.cur_race+1

	--自动ready
	gameInstance.ready()
end


-- 分数改变
function PROTECT.score_change_msg(_data)

	for _seat_num,_sd in pairs(_data) do
		local i = find_p_info(_seat_num)
		p_info[i].score = p_info[i].score + _sd.score

		if _seat_num==all_data.game_data.seat_num then
			all_data.score=all_data.score + _sd.score
		end
	end

	--通知管理者
	nodefunc.send(all_data.match_info.match_svr_id,"change_grades",
						DATA.my_id,all_data.score,all_data.hide_score)

	PUBLIC.request_client("citymg_score_change_msg",{status_no=status_no,score=all_data.score})

end


local function get_game_status_info(_data)
	if all_data and _data then
		if gameInstance then
			gameInstance.get_status_info()
		end

		_data[all_data.game_type .. "_status_info"]=all_data.game_data
	end
end
local send_info_func={}	
-- ###_test  未完成版
local function send_all_info()
	
	if all_data then
		
		local data={
					status_no=all_data.status_no,
					status=all_data.status,
					game_type=all_data.game_type,
					match_info=all_data.match_info,
					round_info=all_data.round_info,
					match_type=all_data.match_type,
					signup_num=all_data.signup_num,
					promoted_type=all_data.promoted_type,
					players_info=all_data.player_info,
					rank=all_data.rank,
					gameover_info=all_data.gameover_info,
					}

		get_game_status_info(data)
		
		PUBLIC.request_client("citymg_all_info",data)
		return 0
	end
	--没有状态时 表示没有在游戏中  返回状态码为 -1 
	PUBLIC.request_client("citymg_all_info",{status_no=-1})
	return 0
end

send_info_func["all"]=send_all_info

function REQUEST.citymg_req_info_by_send(self)
	if type(self.type)~= "string" then 
		return_msg.result=1001
		return return_msg
	end
	if send_info_func[self.type] then 
		local _r=send_info_func[self.type]()
		return_msg.result=_r
		return return_msg
	end
	return_msg.result=1004
	return return_msg
end




return PROTECT


