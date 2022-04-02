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


--[[
		nil
		wait_begin  --等待开始

		gameover
--]]


local game_model = "freestyle_game"
local game_name = ""

local act_flag = false

local base_info = nil
local room_status = nil

local gameInstance=nil
local gameConfig=nil
local all_data=nil

local overtime_cb=nil

local return_msg={result=0}

local update_timer=nil

local kaiguan_cfg_update_dt = 5
local kaiguan_cfg_updater = nil

local auto_quit_game_cd = 5*60
local auto_quit_game_time = nil

--特别的新手引导状态
local special_xsyd = nil

--- 开关配置的刷新缓存
DATA.kaiguan_cfg_cache = nil

-- 初始化活动
local init_activity_data_func = nil
local activity_game_complete = nil

--- 当前
local now_game_num = 0

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

local function add_p_info(_p_info)

	for i,_info in ipairs(all_data.players_info) do
		if _info.seat_num == _p_info.seat_num then
			all_data.players_info[i] = _p_info
			return
		end
	end

	all_data.players_info[#all_data.players_info+1]=_p_info
end

local function del_p_info(_seat_num)

	for i,_info in ipairs(all_data.players_info) do
		if _info.seat_num == _seat_num then
			table.remove(all_data.players_info,i)
			return
		end
	end

end

local function ready_p_info(_seat_num,ready)

	for i,_info in ipairs(all_data.players_info) do
		if _info.seat_num == _seat_num then
			_info.ready = ready
			break
		end
	end

end

local function update_p_info(players_info)

	all_data.players_info = {}

	local _seat_num = 0
	for k,_info in pairs(players_info) do
		all_data.players_info[#all_data.players_info+1]=_info
		if _info.id == DATA.my_id then
			_seat_num = _info.seat_num
		end
	end

	all_data.room_info.seat_num = _seat_num

end


local function on_agent_restart()
	-- if chat_room_id then
	-- 	skynet.call(DATA.service_config.chat_service,"lua","join_room",chat_room_id,DATA.my_id,PUBLIC.get_gate_link())
	-- end
end

--获取别人的ready状态
local function get_ready_status(_seat_num)
	for i,_info in ipairs(all_data.players_info) do
		if _info.seat_num == _seat_num then
			return _info.ready
		end
	end
end

function check_auto_quit_game()

	if all_data then

		if auto_quit_game_time and os.time() > auto_quit_game_time then

			local ret = REQUEST.fg_quit_game()
			if ret.result == 0 then

				PUBLIC.request_client("fg_auto_quit_game_msg",{status=0})

			end

		end

	end

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

		if init_activity_data_func then
			init_activity_data_func()
			init_activity_data_func = nil
		end

		check_auto_quit_game()

	end

end

local function refresh_kaiguan_cfg(kaiguan_cfg)
	all_data.game_kaiguan = kaiguan_cfg and kaiguan_cfg.kaiguan or nil
	if all_data.game_kaiguan then
		-- dump( all_data.game_kaiguan , "kaiguan---------- before encode -----------" )
		all_data.game_kaiguan = basefunc.encode_kaiguan(all_data.game_type , all_data.game_kaiguan)
		-- dump( all_data.game_kaiguan , "kaiguan---------- after encode -----------" )
	end

	all_data.game_multi = kaiguan_cfg and kaiguan_cfg.multi or nil
	if all_data.game_multi then
		-- dump( all_data.game_multi , "multi ---------- before encode -----------" )
		all_data.game_multi = basefunc.encode_multi(all_data.game_type , all_data.game_multi)
		-- print( all_data.game_multi , "multi ---------- after encode -----------" )
	end
end

--[[local last_kaiguan_time = 0
local function kaiguan_update()

	local cfg_time = nodefunc.call( all_data.match_info.signup_service_id ,"get_kaiguan_cfg_time") 
	if last_kaiguan_time == cfg_time then
		return
	end
	last_kaiguan_time = cfg_time

	--- 刷新,,保存一个缓存，在一局结束之后再刷新
	DATA.kaiguan_cfg_cache = nodefunc.call( all_data.match_info.signup_service_id ,"get_kaiguan_cfg") 
	

end--]]

--[[

--]]
-- ###_test 初始化数据  config 是报名成功后返回的
local function new_game(game_type,config)

	DATA.match_game_data={}
	all_data=DATA.match_game_data

	all_data.gameover_info = nil

	all_data.m_PROTECT=PROTECT

	all_data.game_type=game_type
	all_data.jdz_type=config.jdz_type or "nor"

	all_data.game_level=config.game_level
	
	all_data.can_exit_game = false

	all_data.room_info=
	{
		game_id = config.game_id,
		init_stake = config.init_stake,
		init_rate = config.init_rate,
	}

	all_data.status="wait_table"

	all_data.status_no=0

	all_data.score = CMD.query_asset_by_type(PLAYER_ASSET_TYPES.JING_BI)

	all_data.match_info={}
	all_data.match_info.name=config.name
	all_data.match_info.signup_match_id=config.signup_match_id
	all_data.match_info.signup_service_id=config.signup_service_id
	all_data.match_info.is_cancel_signup=config.is_cancel_signup
	all_data.match_info.match_model=config.match_model

	all_data.countdown=config.cancel_signup_cd

	auto_quit_game_time = os.time() + auto_quit_game_cd

	all_data.signup_assets=config.signup_assets

	all_data.deduct_assets = basefunc.deepcopy(config.signup_assets)
	for k,v in pairs(all_data.deduct_assets) do
		v.value = -v.value
	end

	all_data.base_info={}
	base_info=all_data.base_info
	base_info.player_count = GAME_TYPE_SEAT[game_type]

	all_data.players_info={}

	all_data.config={
		agent_cfg={
			overtime_auto_action_cfg = 1,
		},
	}
	all_data.room_rent=config.room_rent

	all_data.gameInstance=PUBLIC.require_game_by_type(all_data.game_type)
	gameInstance=all_data.gameInstance
	if not gameInstance then
		error("gameInstance not exist!!!!!!"..game_type)
	end

	update_timer=skynet.timer(dt,update)

	-- 
	refresh_kaiguan_cfg(config.kaiguan_multi)

	-- 报名消息后再发送活动数据
	--[[init_activity_data_func = function()
		PUBLIC.update_activity_data()
	end
    --]]
    
	---- 开始游戏后，隔几秒检查开关配置是否改变
	--kaiguan_cfg_updater = skynet.timer(kaiguan_cfg_update_dt, kaiguan_update)

end


local function free_game()

	if update_timer then
		update_timer:stop()
		update_timer=nil
	end

	if kaiguan_cfg_updater then
		kaiguan_cfg_updater:stop()
		kaiguan_cfg_updater=nil
	end

	PUBLIC.unlock(game_name)
	PUBLIC.free_agent(game_name)

	if gameInstance then
		gameInstance.free()
		gameInstance=nil
	end

	DATA.match_game_data=nil

	act_flag=false

end

local function get_signup_service_id(id)
	return "freestyle_service_" .. id
end


function REQUEST.fg_signup(self)
	

	if self.xsyd == 1 then

		-- 必须打初级场 否则判定为 正常的匹配场 并且消耗掉这次xsyd机会
		if (self.id == 1 or self.id == 17) then
			
			return PUBLIC.fg_xsyd_signup(self)

		else

			special_xsyd = true

		end

	end

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

	if DATA.game_lock then
		return_msg.result=1005
		act_flag=false
		return return_msg
	end

	local signup_service_id=get_signup_service_id(self.id)

	local signup_assets

	--请求进入条件
	local _result,_data=nodefunc.call(signup_service_id,"get_enter_info")

	if _result=="CALL_FAIL" then

		free_game()
		return_msg.result=1000
		act_flag=false
		return return_msg

	elseif _result == 0 then

		game_name = game_model .. "_" .. _data.game_type

		if not PUBLIC.lock(game_name,game_name,self.id) then
			return_msg.result=1005
			act_flag=false
			return return_msg
		end

		PUBLIC.ref_agent(game_name)

		--验证所需财务
		local ver_ret = PUBLIC.asset_verify(_data.condi_data)
		if ver_ret.result == 0 then
			signup_assets=_data.condi_data
		else
			act_flag=false
			free_game()
			return {
				result=ver_ret.result,
				game_id=self.id
			}
		end

	else
		return_msg.result=_result
		act_flag=false
		free_game()
		return return_msg
	end

	_data.game_tag = GAME_TAG.normal
	--- 发送报名消息 方式
	--DATA.msg_dispatcher:call("fg_signup" , _data )
	---- check 方式
	if PUBLIC.check_is_vip_duiju_game then
		local is_gaming_vip_duiju = PUBLIC.check_is_vip_duiju_game( "freestyle" , _data.game_type , _data.game_level )
		if is_gaming_vip_duiju then
			_data.game_tag = GAME_TAG.vip
		end
	end

	local is_robot=nil
	if not basefunc.chk_player_is_real(DATA.my_id) then
		is_robot=true
	end

	local _result=nodefunc.call(signup_service_id,"player_signup"
											,{
												id=DATA.my_id,
												name=DATA.player_data.player_info.name,
												head_link=DATA.player_data.player_info.head_image,
												sex=DATA.player_data.player_info.sex,
												score=CMD.query_asset_by_type(PLAYER_ASSET_TYPES.JING_BI),
												dressed_head_frame = DATA.player_data.dress_data.dressed_head_frame,
												glory_score = DATA.player_data.glory_data.score,
												is_robot=is_robot,
												game_tag = _data.game_tag,
											})
	if _result=="CALL_FAIL" then
		free_game()
	elseif _result and _result.result==0 then

		_result.game_type = _data.game_type
		_result.game_level = _data.game_level
		_result.jdz_type = _data.jdz_type

		_result.signup_service_id = signup_service_id
		_result.signup_assets=signup_assets
		_result.game_id=self.id
		_result.kaiguan_multi = nodefunc.call( signup_service_id ,"get_kaiguan_cfg") 
		new_game(_result.game_type,_result)

		act_flag=false
		return _result
	else

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

--xsyd
function PUBLIC.fg_xsyd_signup(self)
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

	if DATA.game_lock then
		return_msg.result=1005
		act_flag=false
		return return_msg
	end

	local is_robot=nil
	if not basefunc.chk_player_is_real(DATA.my_id) then
		is_robot=true
	end

	--判断进入条件 --如果不是robot  必须没进入过
	if not is_robot and DATA.player_data.xsyd_status==1 then

		do
			act_flag=false
			self.xsyd = nil
			return REQUEST.fg_signup(self)
		end

		--已经完成了新手引导 
		free_game()
		return_msg.result=1002
		act_flag=false
		return return_msg

	end

	local signup_service_id=get_signup_service_id(self.id)

	local signup_assets

	--请求进入条件
	local _result,_data=nodefunc.call(signup_service_id,"get_enter_info")

	if _result=="CALL_FAIL" then

		free_game()
		return_msg.result=1000
		act_flag=false
		return return_msg

	elseif _result == 0 then

		game_name = game_model .. "_" .. _data.game_type

		if not PUBLIC.lock(game_name,game_name,self.id) then
			return_msg.result=1005
			act_flag=false
			return return_msg
		end

		PUBLIC.ref_agent(game_name)

		--验证所需财务
		local ver_ret = PUBLIC.asset_verify(_data.condi_data)
		if ver_ret.result == 0 then
			signup_assets=_data.condi_data
		else
			act_flag=false
			free_game()
			return {
				result=ver_ret.result,
				game_id=self.id
			}
		end

	else
		return_msg.result=_result
		act_flag=false
		free_game()
		return return_msg
	end

	_data.game_tag = GAME_TAG.xsyd

	local _result=nodefunc.call(signup_service_id,"player_signup"
											,{
												id=DATA.my_id,
												name=DATA.player_data.player_info.name,
												head_link=DATA.player_data.player_info.head_image,
												sex=DATA.player_data.player_info.sex,
												score=CMD.query_asset_by_type(PLAYER_ASSET_TYPES.JING_BI),
												dressed_head_frame = DATA.player_data.dress_data.dressed_head_frame,
												glory_score = DATA.player_data.glory_data.score,
												is_robot=is_robot,
												game_tag = _data.game_tag,
											})
	if _result=="CALL_FAIL" then
		free_game()
	elseif _result and _result.result==0 then

		_result.game_type = _data.game_type
		_result.game_level = _data.game_level
		_result.jdz_type = _data.jdz_type

		_result.match_model = "xsyd"

		_result.signup_service_id = signup_service_id
		_result.signup_assets=signup_assets
		_result.game_id=self.id
		_result.kaiguan_multi = nodefunc.call( signup_service_id ,"get_kaiguan_cfg") 
		new_game(_result.game_type,_result)

		act_flag=false
		return _result
	else

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


--准备
function REQUEST.fg_ready()

	if act_flag then
		return_msg.result=1008
		return return_msg
	end

	if not all_data
		or (all_data.status~="gameover") then
		return_msg.result=1002
		return return_msg
	end

	--xsyd
	if all_data.match_info.match_model=="xsyd" then
		local game_id = all_data.room_info.game_id
		return REQUEST.fg_switch_game({id=game_id})
	end

	act_flag = true

	---- 强制换桌
	now_game_num = now_game_num + 1
	if now_game_num >= skynet.getcfg_2number("must_huan_zhuo_game_num" , 5) then
		act_flag = false
		
		now_game_num = 0
		--return_msg.result = 0
		return REQUEST.fg_huanzhuo()
	end

	local ret = PUBLIC.asset_verify(all_data.signup_assets)

	if ret.result == 0 then
		ret = nodefunc.call(all_data.match_info.signup_service_id,"ready",DATA.my_id)
		
	end

	act_flag = false

	return ret
end


--取消准备
function REQUEST.fg_cancel_ready()
end


--换桌
function REQUEST.fg_huanzhuo()

	if act_flag then
		return_msg.result=1008
		return return_msg
	end

	if not all_data then
		return_msg.result=1002
		return return_msg
	end

	if (not all_data.can_exit_game)
		and (all_data.status~="wait_begin"
		and all_data.status~="wait_table"
		and all_data.status~="gameover") then
		return_msg.result=1002
		return return_msg
	end


	--xsyd
	if all_data.match_info.match_model=="xsyd" then
		local game_id = all_data.room_info.game_id
		return REQUEST.fg_switch_game({id=game_id})
	end

	local ver_ret = PUBLIC.asset_verify(all_data.signup_assets)
	if ver_ret.result ~= 0 then
		return ver_ret
	end

	act_flag = true

	if gameInstance and gameInstance.quit_room and all_data.game_data then
		local ret = gameInstance.quit_room()
		if ret and ret.score and ret.lose_surplus then
			PROTECT.deal_settlement(ret.score , ret.lose_surplus)
		end
	end

	local ret = nodefunc.call(all_data.match_info.signup_service_id,"huanzhuo",DATA.my_id)

	if ret.result ~= 0 then
		act_flag = false
		return_msg.result=ret.result
		return return_msg
	end

	all_data.status="wait_table"
	all_data.settlement_players_info=nil
	all_data.game_data = nil

	all_data.players_info = {}

	act_flag = false
	return {result=0}
end

--取消报名
-- function REQUEST.fg_player_exit_game(self,is_force)

-- 	if act_flag or not all_data or all_data.status~="wait_begin" then
-- 		return_msg.result=1002
-- 		return return_msg
-- 	end
-- 	act_flag=true

-- 	if (all_data.match_info.is_cancel_signup==1 or is_force) and all_data.countdown and all_data.countdown<=0 then
-- 		local _result=nodefunc.call(all_data.match_info.signup_service_id,"player_exit_game",DATA.my_id)
-- 		if _result==0 then
-- 			free_game()
-- 			all_data.status=nil
-- 		end
-- 		act_flag=false
-- 		return_msg.result=_result
-- 		return return_msg
-- 	end
-- 	act_flag=false
-- 	return_msg.result=1002
-- 	return return_msg
-- end

--匹配超时，自动取消
-- function PROTECT.fg_auto_cancel_signup()

-- 	if all_data.status=="wait_begin"
-- 		and auto_cancel_signup_bt+auto_cancel_signup_time < os.time() then

-- 		local ret = REQUEST.fg_cancel_signup(nil,true)
-- 		if ret.result == 0 then
-- 			PUBLIC.request_client("fg_auto_cancel_signup_msg",{result=0})
-- 			print("overtime auto_cancel_signup")
-- 		end
-- 	end
-- end



function REQUEST.fg_quit_game(self)

	if act_flag then
		return_msg.result=1008
		return return_msg
	end

	if not all_data then
		return_msg.result=0
		return return_msg
	end


	if all_data.countdown > 0 then
		return_msg.result=1002
		return return_msg
	end

	--xsyd
	if all_data.status=="wait_table" and all_data.match_info.match_model=="xsyd" then
		return_msg.result=1002
		return return_msg
	end

	-- 可以退出游戏
	if (not all_data.can_exit_game)
		and (all_data.status~="wait_begin"
		and all_data.status~="wait_table"
		and all_data.status~="gameover") then
		return_msg.result=1002
		return return_msg
	end

	act_flag = true


	if gameInstance and gameInstance.quit_room and all_data.game_data then
		local ret = gameInstance.quit_room()
		if ret and ret.score and ret.lose_surplus then
			PROTECT.deal_settlement(ret.score , ret.lose_surplus)
		end
	end

	local ret = nodefunc.call(all_data.match_info.signup_service_id,"player_exit_game",DATA.my_id)

	act_flag = false
	if _result=="CALL_FAIL" then
		return_msg.result=1000
		return return_msg
	end	

	if ret.result ~= 0 then
		return ret
	end

	-- print("fg_quit_game"..all_data.room_info.game_id.."++++++++++++++++++")
	--DATA.msg_dispatcher:call("game_exit_freestyle_activity"
	--							,all_data.room_info.game_id
	--							,all_data.room_info.seat_num
	--							,all_data.base_info.room_id
	--							,all_data.room_info.t_num)

	PUBLIC.trigger_msg( {name = "game_exit_freestyle_activity"} ,all_data.room_info.game_id 
																,all_data.room_info.seat_num 
																,all_data.base_info.room_id 
																,all_data.room_info.t_num )


	free_game()
	all_data = nil

	return_msg.result=0
	return return_msg
end


-- 切换游戏 换个场打
function REQUEST.fg_switch_game(self)

	local ret = REQUEST.fg_quit_game()

	if ret.result ~= 0 then
		return ret
	end

	local ret = REQUEST.fg_signup(self)

	-- 换场立刻清除取消的cd
	all_data.countdown = 0

	return ret
end



-- 切换游戏 换个场打
function REQUEST.fg_get_settlement_players_info(self)

	local data = {result = 0}

	if all_data then

		data.settlement_players_info = all_data.settlement_players_info

	end
	
	return data

end




-- function REQUEST.fg_replay_game(self)

-- 	--如果是在游戏中先退出
-- 	if all_data and all_data.status=="gameover" then
-- 		all_data = nil
-- 		free_game()
-- 	end

-- 	return REQUEST.fg_signup(self)

-- end



function CMD.fg_ready_msg(_seat_num)
	if not all_data then
		print("error : all_data is nil (time,pid,source):",os.time(),DATA.my_id,CUR_CMD.source)
		return
	end
	ready_p_info(_seat_num,1)

	if all_data.room_info.seat_num==_seat_num then
		all_data.status="wait_begin"
		all_data.settlement_players_info=nil
		all_data.game_data = nil
	end
	add_status_no()
	PUBLIC.request_client("fg_ready_msg",
							{
								status_no=all_data.status_no,
								seat_num=_seat_num,
							})
end


function CMD.fg_enter_room_msg(_room_id,_t_num,_seat_num , is_reload_cfg)

	-- 如果数据还没好 等一下
	if not all_data or not all_data.match_info or not all_data.base_info then 

		while true do

			if not all_data or not all_data.match_info or not all_data.base_info then 
				skynet.sleep(1)
			else
				break
			end

		end

	end

	if is_reload_cfg then
		local kaiguan_cfg_cache = nodefunc.call( all_data.match_info.signup_service_id ,"get_kaiguan_cfg") 
		refresh_kaiguan_cfg(kaiguan_cfg_cache)
		---- 给客户端发送一个消息
		PUBLIC.request_client("kaiguan_multi_change_msg",
							{
								game_kaiguan=all_data.game_kaiguan,
								game_multi=all_data.game_multi,
							})
	end

	all_data.base_info.t_num=_t_num
	all_data.room_info.t_num=_t_num

	all_data.base_info.room_id=_room_id
	gameInstance.init(all_data)

	all_data.can_exit_game = false

	all_data.race_score = 0
	activity_game_complete = nil

	--扣房费
	CMD.change_asset_multi(all_data.deduct_assets,ASSET_CHANGE_TYPE.FREESTYLE_SIGNUP,all_data.room_info.game_id)

	PUBLIC.add_game_consume_statistics(all_data.signup_assets)

	--分数刷新
	all_data.score = CMD.query_asset_by_type(PLAYER_ASSET_TYPES.JING_BI)

	--加入房间
	gameInstance.join_room({
								seat_num=_seat_num,
								id=DATA.my_id,
								name=DATA.player_data.player_info.name,
								head_link=DATA.player_data.player_info.head_image,
								sex=DATA.player_data.player_info.sex,
								dressed_head_frame = DATA.player_data.dress_data.dressed_head_frame,
								glory_score = DATA.player_data.glory_data.score,
								score=all_data.score,
							})


	print("fg_enter_room_msg",DATA.my_id)

	auto_quit_game_time = nil

	all_data.exchange_hongbao = nil

	--DATA.msg_dispatcher:call("game_begin_freestyle_activity"
	--							,all_data.room_info.game_id ,_room_id ,_t_num , _seat_num , all_data.game_data.player_count )

	PUBLIC.trigger_msg( {name = "game_begin_freestyle_activity"} ,all_data.room_info.game_id 
																, _room_id
																, _t_num
																, _seat_num
																, all_data.game_data.player_count )

end

---- 收到nor_mj_xzdd_begin_msg/nor_ddz_nor_begin_msg 时
function PROTECT.begin_msg(_cur_race,_again , re_fapai_num)
	print("xxxxxxxxxxx freestyle_game--begin_msg,------time:",os.time() , DATA.my_id , all_data.room_info.game_id)
	if not re_fapai_num or re_fapai_num == 0 then
		--DATA.msg_dispatcher:call("game_instance_begin_freestyle_activity"
		--						,all_data.room_info.game_id , all_data.base_info.room_id , all_data.base_info.t_num , all_data.game_data.seat_num , all_data.game_data.player_count )
	
		PUBLIC.trigger_msg( {name = "game_instance_begin_freestyle_activity"} ,all_data.room_info.game_id 
																, all_data.base_info.room_id
																, all_data.base_info.t_num
																, all_data.game_data.seat_num
																, all_data.game_data.player_count )

	end
end

function CMD.fg_gameover_msg( is_reload_cfg )
	print("fg_gameover_msg!!")

	all_data.status="gameover"

	--将新手引导关闭
	if all_data.match_info.match_model=="xsyd" or special_xsyd then
		PUBLIC.xsyd_finish()
		special_xsyd = nil
	end

	add_status_no()

	--所有人都变为未准备状态
	for i,_info in ipairs(all_data.players_info) do
		ready_p_info(_info.seat_num,0)
	end

	auto_quit_game_time = os.time() + auto_quit_game_cd

	PUBLIC.request_client("fg_gameover_msg",
							{
								status_no=all_data.status_no,
								glory_score_count = all_data.glory_score_count,
								glory_score_change = all_data.glory_score_change,
								exchange_hongbao = all_data.exchange_hongbao,
							})

end


function PROTECT.game_settlement_msg(_settle_data,_is_over,_lose_surplus,_log_id )
	--匹配场中有可能此时有玩家换桌了，将导致玩家信息丢失，这里备份一下 

	all_data.settlement_players_info=basefunc.deepcopy(all_data.players_info)

	local score = _settle_data.scores[all_data.room_info.seat_num]
	local lose_surplus = _lose_surplus[all_data.room_info.seat_num]

	local cgs = DATA.player_data.glory_data.score

	PROTECT.deal_settlement(score , lose_surplus , _settle_data.scores)
	
	
	all_data.glory_score_change = DATA.player_data.glory_data.score - cgs
	all_data.glory_score_count = DATA.player_data.glory_data.score

	-- print("------------game_settlement_msg,",all_data.game_type, all_data.game_level )
end

---- 处理结算，玩家胡了牌退出时就直接调这个
--[[
	_real_score 是真实输赢的钱数
]]
function PROTECT.deal_settlement(_real_score , _lose_surplus , _settle_data_real_scores)
	-- 向管理者 通知我的分数 进行统计和记录日志等
	local signup_service_id=get_signup_service_id(all_data.room_info.game_id)

	--- 应该变化的钱数
	local score = _real_score - _lose_surplus

	nodefunc.send(signup_service_id,"update_player_score",DATA.my_id,score,_real_score,all_data.score)

	-- print("------------deal_settlement,",all_data.game_type, all_data.game_level )
	--- 发一个游戏完成信号
	--DATA.msg_dispatcher:call("game_compolete_task", "freestyle" 
	--							, all_data.game_level 
	--							, _real_score
	--							, ""
	--							, 0)

	PUBLIC.trigger_msg( {name = "game_compolete_task"} , "freestyle"  
								, all_data.room_info.game_id
														, all_data.game_type
														, all_data.game_level
														, _real_score
														, ""
														, 0 )

	--DATA.msg_dispatcher:call("game_compolete_glory"
	--							,all_data.room_info.game_id
	--							,score
	--							,all_data.room_info.init_stake)

	PUBLIC.trigger_msg( {name = "game_compolete_glory"} , all_data.room_info.game_id
														, score
														, all_data.room_info.init_stake )


	local exchange_bl = skynet.getcfg_2number("freestyle_game_settle_exchange_hongbao",0)
	if _real_score > 0 and exchange_bl > 0 then

		local hb = math.floor(_real_score*exchange_bl)
		if hb > 0 then
			all_data.exchange_hongbao = 
			{
				jing_bi = _real_score,
				hong_bao = hb,
				is_exchanged = 0,
			}
		end
	end

	if not activity_game_complete then
		activity_game_complete = true

		--DATA.msg_dispatcher:call("game_compolete_freestyle_activity"
		--							,all_data.room_info.game_id
		--							,score 
		--							,_settle_data_real_scores 
		--							,all_data.game_data.seat_num 
		--							,all_data.game_data.player_count
		--							,all_data.players_info)

		PUBLIC.trigger_msg( {name = "game_compolete_freestyle_activity"}, all_data.room_info.game_id
																		, score
																		, _settle_data_real_scores
																		,all_data.game_data.seat_num
																		,all_data.game_data.player_count
																		,all_data.players_info
																		 )

	end


	PUBLIC.update_activity_data()

end




-- 结算的钱兑换红包
function REQUEST.fg_settle_exchange_hongbao(self)

	if act_flag then
		return_msg.result=1008
		return return_msg
	end
	act_flag = true

	if all_data.exchange_hongbao and all_data.exchange_hongbao.is_exchanged ~= 1 then
		
		local asset_lock_info = PUBLIC.asset_lock({[1]={
			condi_type = NOR_CONDITION_TYPE.CONSUME,
			asset_type = PLAYER_ASSET_TYPES.JING_BI,
			value = all_data.exchange_hongbao.jing_bi,
		}})
		if asset_lock_info.result ~= 0 then
			act_flag = false
			return ver_ret
		end

		PUBLIC.asset_commit(asset_lock_info.lock_id,ASSET_CHANGE_TYPE.FREESTYLE_SETTLE_EXCHANGE_HONGBAO
								,all_data.room_info.game_id)


		CMD.change_asset_multi({[1]={
			asset_type = PLAYER_ASSET_TYPES.SHOP_GOLD_SUM,
			value = all_data.exchange_hongbao.hong_bao,
		}},ASSET_CHANGE_TYPE.FREESTYLE_SETTLE_EXCHANGE_HONGBAO,all_data.room_info.game_id)

		all_data.exchange_hongbao.is_exchanged = 1
		return_msg.result=0
		act_flag = false
		return return_msg
	end

	return_msg.result=1002
	act_flag = false
	return return_msg
end



-- 发送给玩家
function PROTECT.my_join_return(_data)

	all_data.status="gaming"

	if _data.p_info then
		update_p_info(_data.p_info)
	end

	--通知客户端
	add_status_no()
	PUBLIC.request_client("fg_enter_room_msg",
							{status_no=all_data.status_no,
							seat_num=all_data.game_data.seat_num,
							players_info=all_data.players_info,
							room_info=all_data.room_info})

	--自动ready
	gameInstance.ready()
end


function PROTECT.player_join_msg(_info)

	add_p_info(_info)

	--通知客户端
	add_status_no()
	PUBLIC.request_client("fg_join_msg",{status_no=all_data.status_no,player_info=_info})
end

function CMD.player_leave_msg(_seat_num)

	if not all_data then return end -- by lyx 2018-11-15

	del_p_info(_seat_num)

	--通知客户端
	add_status_no()
	PUBLIC.request_client("fg_leave_msg",{status_no=all_data.status_no,seat_num=_seat_num})
end


-- 分数改变 返回应该扣的分数
function PROTECT.modify_score(_data)

	local score = CMD.query_asset_by_type(PLAYER_ASSET_TYPES.JING_BI)
	local real_num = _data
	if real_num + score < 0 then
		real_num = -score
	end

	CMD.change_asset_multi({[1]={asset_type=PLAYER_ASSET_TYPES.JING_BI,value=real_num}}
						,ASSET_CHANGE_TYPE.FREESTYLE_GAME_SETTLE,all_data.room_info.game_id)

	all_data.score = real_num + score
	
	all_data.race_score = all_data.race_score + real_num

	PUBLIC.request_client("fg_score_change_msg",{status_no=status_no,score=all_data.score})

	return real_num
end

function PROTECT.get_fengding_score()
	return  CMD.query_asset_by_type(PLAYER_ASSET_TYPES.JING_BI)
end

-- 所有人的分数变化
function PROTECT.score_change_msg(_score_data)

	for i,_info in ipairs(all_data.players_info) do
    	if _score_data[_info.seat_num] then
      		_info.score = _info.score + _score_data[_info.seat_num].score
    	end
  	end

	--分数改变后进行备份
	--匹配场中有可能此时有玩家换桌了，将导致玩家信息丢失，这里备份一下
	--all_data.settlement_players_info=basefunc.deepcopy(all_data.players_info)

end


-- 结算前 提前计算结算分数
function PROTECT.get_race_score()

	if all_data and all_data.race_score then

		-- 提前退出的活动处理 当查询这个分数的时候才计算
		skynet.fork(PROTECT.ahead_activity_game_complete)

		return {result=0,race_score=all_data.race_score}
	end

	return_msg.result=1002
	return 1002

end

-- 结算前 提前计算活动结算内容
function PROTECT.ahead_activity_game_complete()

	-- 提前退出的活动处理
	if all_data and all_data.can_exit_game and not activity_game_complete then

		if all_data.race_score then
			activity_game_complete = true
			local score = all_data.race_score
			--DATA.msg_dispatcher:call("game_compolete_freestyle_activity"
			--							,all_data.room_info.game_id
			--							,score 
			--							,nil 
			--							,all_data.game_data.seat_num 
			--							,all_data.game_data.player_count
			--							,all_data.players_info)

			PUBLIC.trigger_msg( {name = "game_compolete_freestyle_activity"}, all_data.room_info.game_id
																		, score
																		, nil
																		, all_data.game_data.seat_num
																		, all_data.game_data.player_count
																		, all_data.players_info
																		 )

		end

	end

end


-- 游戏可以退出了，我可以离开这个游戏了
function PROTECT.set_game_status(_can_exit_game)

	_can_exit_game = _can_exit_game or true
	if all_data then
		all_data.can_exit_game = _can_exit_game
	end

	-- 通知管理者
	nodefunc.send(all_data.match_info.signup_service_id,"set_player_game_status",DATA.my_id,_can_exit_game)

end



local function get_game_status_info(_data)
	if all_data and _data then
		if gameInstance then
			gameInstance.get_status_info()
		end
		local gta = GAME_TYPE_AGENT[all_data.game_type]
		local gap = GAME_AGENT_PROTO[gta]
		_data[gap]=all_data.game_data
	end
end


local send_info_func={}

local function send_all_info()

	if all_data then
		--dump( all_data.settlement_players_info , "send_all_info , -------------- settlement_players_info: " )
		local data={
					status_no=all_data.status_no,
					status=all_data.status,
					game_type=all_data.game_type,
					jdz_type=all_data.jdz_type,
					game_kaiguan = all_data.game_kaiguan,
					game_multi = all_data.game_multi,
					match_info=all_data.match_info,
					room_info=all_data.room_info,
					room_rent=all_data.room_rent,
					countdown=all_data.countdown,
					players_info=all_data.players_info,
					settlement_players_info=all_data.settlement_players_info,
					gameover_info=all_data.gameover_info,
					activity_data=all_data.activity_data,
					exchange_hongbao = all_data.exchange_hongbao,

					glory_score_change = all_data.glory_score_change,
					glory_score_count = all_data.glory_score_count,

					}

		get_game_status_info(data)

		PUBLIC.request_client("fg_all_info",data)
		return 0
	end
	--没有状态时 表示没有在游戏中  返回状态码为 -1
	PUBLIC.request_client("fg_all_info",{status_no=-1})
	return 0
end

send_info_func["all"]=send_all_info

function REQUEST.fg_req_info_by_send(self)
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






-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------activity---------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------


function REQUEST.fg_get_activity_award()
	
	if not basefunc.chk_player_is_real(DATA.my_id) then
		return_msg.result = 4503
		return return_msg
	end

	if all_data and all_data.room_info and all_data.room_info.game_id then

		local ret = PUBLIC.get_freestyle_activity_award(all_data.room_info.game_id)

		if ret.result == 0 then
			PUBLIC.update_activity_data()
		end

		return ret

	end

	return_msg.result = 4503
	return return_msg

end


-- 主动推送 状态信息变化的数据
function PUBLIC.update_activity_data()

	if not basefunc.chk_player_is_real(DATA.my_id) then
		return
	end

	if all_data and all_data.room_info and all_data.room_info.game_id then

		local data = PUBLIC.get_activity_data_list(all_data.room_info.game_id)
		
		if data then
			if next(data) then
				PUBLIC.request_client("fg_activity_data_msg",{activity_data=data})
			end

			all_data.activity_data = data
		end

	end
	
end



-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------activity---------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------









return PROTECT
