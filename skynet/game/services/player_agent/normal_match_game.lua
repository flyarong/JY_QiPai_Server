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
		wait_table	--等待分配桌子
		
		gameover
--]]


local game_model = "normal_match_game"
local game_name = ""

local act_flag = false

local base_info = nil
local room_status = nil

local gameInstance=nil
local gameConfig=nil
local all_data=nil

local overtime_cb=nil

local kaiguan_cfg_update_dt = 10
local kaiguan_cfg_updater = nil

local auto_cancel_signup_bt = 0
local auto_cancel_signup_time = 5*60

--玩家信息
local p_info=nil

local return_msg={result=0}

local update_timer=nil

local free_match_signup_num = 0
local free_match_sn_fresh_time = 0


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
		
		PROTECT.nor_mg_auto_cancel_signup()

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

----- 比赛场就做一个简单的更新开关，
local last_kaiguan_time = 0
local function kaiguan_update()

	local cfg_time = nodefunc.call( all_data.match_info.signup_service_id ,"get_kaiguan_cfg_time") 
	if last_kaiguan_time == cfg_time then
		return
	end
	last_kaiguan_time = cfg_time

	--- 刷新
	local kaiguan_cfg = nodefunc.call( all_data.match_info.signup_service_id ,"get_kaiguan_cfg") 
	refresh_kaiguan_cfg(kaiguan_cfg)

	---- 给客户端发送一个消息
	PUBLIC.request_client("kaiguan_multi_change_msg",
							{
								game_kaiguan=all_data.game_kaiguan,
								game_multi=all_data.game_multi,
							})

end

--[[
	
--]]
-- ###_test 初始化数据  config 是报名成功后返回的
local function new_game(game_type,config)

	DATA.match_game_data={}
	all_data=DATA.match_game_data

	all_data.gameover_info = nil

	all_data.m_PROTECT=PROTECT

	all_data.game_type=game_type

	all_data.room_info={game_id=config.game_id}

	all_data.status="wait_begin"

	all_data.status_no=0

	all_data.score = 0
	
	all_data.model_name="ddz_match_game"

	all_data.match_info={}
	all_data.match_info.name=config.name
	all_data.match_info.total_players=config.total_players
	all_data.match_info.is_cancel_signup=config.is_cancel_signup
	all_data.match_info.total_round=config.total_round
	all_data.match_info.signup_match_id=config.signup_match_id
	all_data.match_info.signup_service_id=config.signup_service_id
	all_data.match_info.begin_type=config.begin_type

	all_data.cur_player_num = total_players

	all_data.match_info.match_model=config.match_model

	all_data.countdown=config.cancel_signup_cd
	all_data.signup_num=config.signup_num

	all_data.enter_condi_data = config.enter_condi_data

	all_data.signup_assets=config.signup_assets

	-- 报名使用的特殊物品列表
	all_data.signup_obj_list=config.signup_obj_list

	all_data.deduct_assets = basefunc.deepcopy(config.signup_assets)
	for k,v in pairs(all_data.deduct_assets) do
		v.value = -v.value
	end

	all_data.base_info={}
	base_info=all_data.base_info
	base_info.cur_race = 1
	base_info.player_count = GAME_TYPE_SEAT[game_type]

	all_data.config={
		agent_cfg={
			overtime_auto_action_cfg = 1,
		},
	}

	update_timer=skynet.timer(dt,update)

	refresh_kaiguan_cfg(config.kaiguan_multi)

	---- 开始游戏后，隔几秒检查开关配置是否改变 ， ！！比赛场开始游戏后不能刷新开关配置，必须要重开一局才行
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
	return "match_service_" .. id
end


function REQUEST.nor_mg_signup(self)
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

	--新手引导请选另外一个接口
	if self.id == 1 then 
		return_msg.result=1002
		act_flag=false
		return return_msg
	end

	if DATA.game_lock then
		return_msg.result=1005
		act_flag=false
		return return_msg
	end

	local signup_service_id=get_signup_service_id(self.id)
	local asset_lock_info
	local signup_assets = {}

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

		-- 托管不要钱
		if not basefunc.chk_player_is_real(DATA.my_id) then
			_data.condi_data = {}
		end

		-- 按顺序检测
		for i,cd in ipairs(_data.condi_data) do
			signup_assets = cd
			local ver_ret = PUBLIC.asset_verify(signup_assets)
			if ver_ret.result == 0 then
				break
			end
		end

		--锁定所需财务
		asset_lock_info = PUBLIC.asset_lock(signup_assets)
		if asset_lock_info.result == 0 then
			-- print("asset_lock ok ,key:"..asset_lock_info.lock_id)
		else
			-- print("asset_lock error ,result:"..asset_lock_info.result)
			act_flag=false
			free_game()
			return {
				result=asset_lock_info.result,
				game_id=self.id
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
			-- print("asset_commit error ,result:"..ret.result)
		end
		auto_cancel_signup_bt = os.time()
		_result.game_type = _data.game_type
		_result.begin_type = _data.begin_type
		_result.signup_service_id = signup_service_id
		_result.signup_assets=signup_assets
		_result.match_model = _data.match_model
		_result.enter_condi_data=_data.condi_data
		_result.signup_obj_list=ret.obj_list
		_result.game_id=self.id
		_result.kaiguan_multi = nodefunc.call( signup_service_id ,"get_kaiguan_cfg")
		nodefunc.send(signup_service_id,"record_players_info",DATA.my_id
							,DATA.player_data.player_info.name
							,DATA.player_data.player_info.head_image)
		new_game(_result.game_type,_result)

		act_flag=false
		return _result
	else
		local ret = PUBLIC.asset_unlock(asset_lock_info.lock_id)
		if ret.result == 0 then
			-- print("asset_unlock ok")
		else
			-- print("asset_unlock error ,result:"..ret.result)
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


function REQUEST.nor_mg_xsyd_signup()
	if act_flag then
		return_msg.result=1008
		return return_msg
	end

	act_flag=true
	
	--xsyd
	local self = {id = 1}

	if not self or not self.id or type(self.id)~="number" then 
		return_msg.result=1001
		act_flag=false
		return return_msg
	end

	local signup_service_id=get_signup_service_id(self.id)

	local game_type = "nor_ddz_nor_xsyd"

	game_name = game_model .. "_" .. game_type

	if not PUBLIC.lock(game_name,game_name) then 
		return_msg.result=1005
		act_flag=false
		return return_msg
	end

	PUBLIC.ref_agent(game_name)

	--xsyd
	local is_robot=nil
	if not basefunc.chk_player_is_real(DATA.my_id) then
		is_robot=true
	end

	--判断进入条件 --如果不是robot  必须没进入过
	if not is_robot and DATA.player_data.xsyd_status==1 then
		--已经完成了新手引导 
		free_game()
		return_msg.result=1002
		act_flag=false
		return return_msg 
	end
	
	local _result=nodefunc.call(signup_service_id,"player_signup",DATA.my_id,is_robot)
	if _result=="CALL_FAIL" then
		free_game()
	elseif _result and _result.result==0 then
		
		_result.game_type = game_type
		_result.signup_service_id = signup_service_id
		_result.signup_assets={}
		_result.game_id=self.id
		_result.match_model = "xsyd"
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


--取消报名
function REQUEST.nor_mg_cancel_signup(self,is_force)

	if not all_data or not all_data.match_info or all_data.match_info.match_model=="xsyd" then
		return_msg.result=1002
		return return_msg
	end

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

				-- 普通资产直接返回，特殊道具资产需要重建结构
				if all_data.signup_obj_list then

					-- 去除特殊资产
					for k,v in pairs(all_data.signup_assets) do
						if basefunc.is_object_asset(v.asset_type) 
							and (not v.condi_type 
									or v.condi_type == NOR_CONDITION_TYPE.CONSUME) then
							all_data.signup_assets[k]=nil
						end
					end

					-- 重建特殊资产结构
					for k,v in pairs(all_data.signup_obj_list) do
						all_data.signup_assets[#all_data.signup_assets+1]=
						{
							asset_type = v.object_type,
							attribute = v.attribute,
						}
					end

				end

				CMD.change_asset_multi(all_data.signup_assets,ASSET_CHANGE_TYPE.MATCH_CANCEL_SIGNUP
										,all_data.room_info.game_id)
				
				all_data.signup_assets=nil
				all_data.signup_obj_list=nil
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
function PROTECT.nor_mg_auto_cancel_signup()
	
	if all_data.status=="wait_begin" 
		and auto_cancel_signup_bt+auto_cancel_signup_time < os.time() then

		-- 定时开 不需要自动退出
		if all_data.match_info and all_data.match_info.begin_type == "dingshikai" then
			return
		end

		local ret = REQUEST.nor_mg_cancel_signup(nil,true)
		if ret.result == 0 then
			PUBLIC.request_client("nor_mg_auto_cancel_signup_msg",{result=0})
			-- print("overtime auto_cancel_signup")
		end

	end
end

function REQUEST.nor_mg_req_cur_signup_num(self)

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

function REQUEST.nor_mg_quit_game(self)

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

	return_msg.result=0
	return return_msg 
end


function REQUEST.nor_mg_replay_game(self)

	if all_data and 
		all_data.match_info and
		all_data.match_info.match_model=="xsyd" then
		return_msg.result=1002
		return return_msg
	end

	--如果是在游戏中先退出
	if all_data and all_data.status=="gameover" then
		all_data = nil
		free_game()
	end


	return REQUEST.nor_mg_signup(self)

end

function REQUEST.nor_mg_req_specified_signup_num(self)

	if not self or not self.id or type(self.id)~="number" then 
		return_msg.result=1001
		return return_msg
	end

	if act_flag then 
		return_msg.result=1008
		return return_msg
	end

	local _result

	act_flag=true

	_result=nodefunc.call(get_signup_service_id(self.id),"get_signup_player_num")

	act_flag=false


	if _result~="CALL_FAIL" then
		_result.result=0
		_result.id=self.id
		return _result
	end
	return_msg.result=1000
	return return_msg 
end


function REQUEST.nor_mg_query_match_active_player_num(self)

	if not self or not self.id or type(self.id)~="number" then 
		return_msg.result=1001
		return return_msg
	end

	if act_flag then 
		return_msg.result=1008
		return return_msg
	end

	act_flag=true

	local _result=nodefunc.call(get_signup_service_id(self.id),"query_match_active_player_num")

	act_flag=false


	if _result~="CALL_FAIL" then
		_result.id=self.id
		return _result
	end
	return_msg.result=1000
	return return_msg 
end

-- 请求当前剩余玩家的数量
function REQUEST.nor_mg_req_cur_player_num(self)

	if act_flag then 
		return_msg.result=1008
		return return_msg
	end

	if not all_data 
		or not all_data.match_info
		or not all_data.match_info.match_svr_id then
		
		return_msg.result=1002
		return return_msg

	end

	act_flag=true

	local _data = nodefunc.call(all_data.match_info.match_svr_id,"get_match_player_num")

	act_flag=false


	if _data ~= "CALL_FAIL" then
		_data.result = 0
		return _data
	end
	return_msg.result=1000
	return return_msg 
end


-- 复活
function REQUEST.nor_mg_revive(self)
	if act_flag then
		return_msg.result=1008
		return return_msg
	end

	if not all_data or
		all_data.status~="wait_revive" then
			return_msg.result=1002
			return return_msg
	end

	if type(self.opt)~="number" then
		return_msg.result=1001
		return return_msg
	end

	act_flag = true

	local ret
	if self.opt > 0 then

		local signup_assets = nil

		if all_data.real_revive_assets and all_data.real_revive_assets[self.opt] then
			
			signup_assets = all_data.real_revive_assets[self.opt]

			dump(signup_assets,"signup_assets++++++++++nor_mg_revive")
		else

			act_flag = false
			return_msg.result=1001
			return return_msg

		end

		--锁定所需财务 提前消耗数量 但是没扣减
		local asset_lock_info = PUBLIC.asset_lock(signup_assets)
		if asset_lock_info.result == 0 then
			-- print("asset_lock ok ,key:"..asset_lock_info.lock_id)
		end

		ret = nodefunc.call(all_data.match_info.match_svr_id,"revive",DATA.my_id)

		if ret then
			--扣费
			PUBLIC.asset_commit(asset_lock_info.lock_id,ASSET_CHANGE_TYPE.MATCH_REVIVE
												,all_data.room_info.game_id)
			PUBLIC.notify_asset_change_msg()

		else

			PUBLIC.asset_unlock(asset_lock_info.lock_id)

		end

	else
		
		all_data.revive_assets = nil
		all_data.real_revive_assets = nil
		all_data.revive_num = nil
		all_data.revive_round = nil

		ret = nodefunc.call(all_data.match_info.match_svr_id,"give_up_revive",DATA.my_id)

	end

	if ret and ret~="CALL_FAIL" then
		
		all_data.status="reviveing"
		overtime_cb = nil

		ret = 0
	else
		ret = 1002
	end
	
	act_flag = false

	return_msg.result=ret
	return return_msg

end


-----------------------------------------------------------------------------

function REQUEST.nor_mg_get_match_status(self)

	if not self or not self.id or type(self.id)~="number" then 
		return_msg.result=1001
		return return_msg
	end
	
	local ret = nodefunc.call(get_signup_service_id(self.id),"query_start_time")

	if ret=="CALL_FAIL" then
		return_msg.result=1000
		return return_msg
	end

	ret.start_time = ret.start_time - os.time()
	ret.start_time = math.max(ret.start_time,0)

	return ret

end

function REQUEST.nor_mg_query_all_rank(self)
	if act_flag then
		return_msg.result=1008
		return return_msg
	end

	if type(self.id) ~= "number" or type(self.index) ~= "number" then
		return_msg.result=1001
		return return_msg
	end

	act_flag = true

	local ret = nodefunc.call(get_signup_service_id(self.id),"query_all_rank")

	act_flag = false

	if ret=="CALL_FAIL" then
		return_msg.result=1000
		return return_msg
	end

	
	if ret.rank_list then
		local rl = {}
		local s = math.floor(100*(self.index-1)) + 1
		local e = math.floor(100*(self.index))

		if e < s then
			return_msg.result=1001
			return return_msg
		end

		for i=s,e do
			
			if ret.rank_list[i] then
				rl[#rl+1] = ret.rank_list[i]
			else
				break
			end

		end

		ret.rank_list = rl

	end

	return ret

end



--比赛被放弃
function CMD.nor_mg_match_discard_msg()

	if not all_data or not all_data.match_info then
		return
	end

	--返回资产  ###_test
	if all_data.signup_assets then
		CMD.change_asset_multi(all_data.signup_assets,ASSET_CHANGE_TYPE.MATCH_CANCEL_SIGNUP,all_data.room_info.game_id)
		all_data.signup_assets=nil
	end
	
	PUBLIC.request_client("nor_mg_match_discard_msg",{game_id=all_data.room_info.game_id})

	free_game()
	all_data.status=nil

end


-----------------------------------------------------------------------------



--报名结束游戏开始
function CMD.nor_mg_begin_msg(_m_svr_id,_socre,_rank,_player_count)
	-- print("@@@ CMD.nor_mg_begin_msg",_m_svr_id,_socre,_rank)

	-- if not all_data then
	-- 	print("error !!! is too quick new_game is not call finish")
	-- 	return 
	-- end

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
	PUBLIC.request_client("nor_mg_begin_msg",{status_no=all_data.status_no,rank=_rank
												,score=_socre,total_players=_player_count})
end

function CMD.nor_mg_enter_room_msg(_room_id,_t_num,_round_info,_cur_player_num)

	all_data.base_info.room_id=_room_id
	all_data.base_info.t_num=_t_num

	if _round_info then
		all_data.round_info=_round_info
	end

	all_data.cur_player_num = _cur_player_num

	all_data.player_info={}
	p_info=all_data.player_info

	all_data.room_info.t_num = _t_num

	gameInstance.init(all_data)

	PUBLIC.add_game_consume_statistics(all_data.signup_assets)
	
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
					

	print("nor_mg__enter_room_msg",DATA.my_id)

end

--晋级决赛 - 调整分数  ###_test
function CMD.nor_mg_promoted_final_msg(_score)
	all_data.score=_score
	add_status_no()
	PUBLIC.request_client("nor_mg_score_change_msg",{status_no=all_data.status_no,score=all_data.score})
end

function CMD.nor_mg_change_rank_msg(_rank)
	if all_data then
		if _rank~=all_data.rank then 
			all_data.rank=_rank
			add_status_no()
			--通知客户端
			PUBLIC.request_client("nor_mg_rank_msg",{status_no=all_data.status_no,rank=_rank})
		end
	end 
end



--比赛完成了，需要等待比赛结果
function CMD.nor_mg_wait_result_msg(_round_info)
	-- print("gameover nor_mg__wait_result_msg")
	
	if _round_info then
		all_data.round_info=_round_info
	end

	add_status_no()
	all_data.status="wait_result"
	PUBLIC.request_client("nor_mg_wait_result_msg",{status_no=all_data.status_no,
												round_info=all_data.round_info,
												status=all_data.status})
end

--比赛完成了，我已经晋级了，先休息一下，然后发起匹配请求
function CMD.nor_mg_promoted_msg(is_promoted_final,_round_info)
	-- print("gameover nor_mg__promoted_msg")

	all_data.status="promoted"
	all_data.countdown = 3
	all_data.promoted_type = is_promoted_final and 1 or 0
	
	if _round_info then
		all_data.round_info=_round_info
	end

	add_status_no()
	PUBLIC.request_client("nor_mg_promoted_msg",
							{status_no=all_data.status_no,
							status=all_data.status,
							countdown=all_data.countdown,
							round_info=all_data.round_info,
							promoted_type=all_data.promoted_type})
	
	overtime_cb = function ()
		--通知管理者我准备好了
		nodefunc.send(all_data.match_info.match_svr_id,"player_ready_matching",DATA.my_id)
		-- print("我准备好了:",DATA.my_id)
		overtime_cb = nil
	end

end


-- 你已经失败 需要复活
function CMD.nor_mg_wait_revive_msg(_num,_time,_round,_assets)
	all_data.status="wait_revive"

	all_data.countdown = _time

	all_data.revive_round = _round
	all_data.revive_assets = {}
	all_data.real_revive_assets = {}

	all_data.revive_num = _num

	for i,as in ipairs(_assets) do

		local a = as[1]

		all_data.revive_assets[i] = 
		{
			condi_type = a.judge_type,
			asset_type = a.asset_type,
			value = a.asset_count,
		}
		
		all_data.real_revive_assets[i]={all_data.revive_assets[i]}

	end

	overtime_cb = function ()
		
		all_data.status="give_up_reviveing"
		all_data.revive_assets = nil
		all_data.real_revive_assets = nil
		all_data.revive_num = nil
		all_data.revive_round = nil

		--通知管理者我放弃复活
		nodefunc.send(all_data.match_info.match_svr_id,"give_up_revive",DATA.my_id)
		
		overtime_cb = nil
	end

	add_status_no()
	PUBLIC.request_client("nor_mg_wait_revive_msg",
							{
								status_no=all_data.status_no,
								num=_num,
								time=_time,
								round=_round,
								assets=all_data.revive_assets,
							})
end

-- 条件已经满足 免费复活
function CMD.nor_mg_free_revive_msg()

	-- 马上就会收到 晋级的消息
	if all_data.status=="wait_revive" then
		overtime_cb = nil
	end

	add_status_no()
	PUBLIC.request_client("nor_mg_free_revive_msg",
							{status_no=all_data.status_no})

end

function CMD.nor_mg_gameover_msg(_rank,_reward,_match_id,_round_info)
	-- print("nor_mg_gameover_msg!!")

	all_data.status="gameover"
	
	if _round_info then
		all_data.round_info=_round_info
	end

	all_data.gameover_info={
							rank=_rank,
							reward=_reward,
							game_id=all_data.room_info.game_id,
						}
	
	--tj
	if _rank > 0 and _rank < 4 then	
		PUBLIC.add_statistics_player_match(_rank)
	end

	--将新手引导关闭
	if all_data.match_info.match_model=="xsyd" then
		PUBLIC.xsyd_finish()
	end

	local is_weed_out = 1

	if all_data.round_info and (all_data.match_info.total_round <= all_data.round_info.round) then
		is_weed_out = 0
	end

	--增加奖励
	CMD.change_asset_multi(_reward,ASSET_CHANGE_TYPE.MATCH_AWARD,all_data.room_info.game_id)

	add_status_no()
	
	PUBLIC.request_client("nor_mg_gameover_msg",{
			status_no=all_data.status_no,
			is_weed_out = is_weed_out,
			final_result=all_data.gameover_info,
			round_info=all_data.round_info,
		})

	--- 发一个游戏完成信号
	--DATA.msg_dispatcher:call("game_compolete_task", "matchstyle" 
	--							, all_data.game_type 
	--							, 0
	--							, 0
	--							, _rank)

	PUBLIC.trigger_msg( {name = "game_compolete_task"} , "matchstyle" 
								, all_data.room_info.game_id
													   , all_data.game_type
													   , 0
													   , 0
													   , all_data.match_info.match_model
													   , _rank
														)

	---- 如果是千元赛往 生财之道 发送一个消息
	if all_data.match_info.match_model == "naming_qys" and basefunc.chk_player_is_real(DATA.my_id) then
		skynet.send( DATA.service_config.sczd_center_service , "lua" , "qys_game_complete" , DATA.my_id , all_data.room_info.game_id , _rank )
	end


	free_game()

end


function PROTECT.game_settlement_msg(_settle_data,_is_over,_lose_surplus,_log_id)
	--all_data.settlement_players_info=basefunc.deepcopy(all_data.players_info)

	local score = _settle_data.scores[all_data.room_info.seat_num]
	local lose_surplus = _lose_surplus[all_data.room_info.seat_num]

end



--###_test 发送给玩家
function PROTECT.my_join_return(_data)

	all_data.status="gaming"
	if _data.p_info then
		for _,_info in pairs(_data.p_info) do
			p_info[#p_info+1]=_info
		end
	end

	all_data.room_info.seat_num = all_data.game_data.seat_num
	

	--通知客户端
	add_status_no()
	PUBLIC.request_client("nor_mg_enter_room_msg",
							{status_no=all_data.status_no,
							seat_num=all_data.game_data.seat_num,
							round_info=all_data.round_info,
							players_info=p_info,
							room_info=all_data.room_info})

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
	PUBLIC.request_client("nor_mg_join_msg",{status_no=all_data.status_no,player_info=_info})
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


--计算隐藏分(根据方位)
local function calculate_mj_hide_socre(_zhuang)
	
	if all_data.hide_score then

		local ds = all_data.room_info.seat_num - _zhuang
		if ds < 0 then
			ds = ds + 4
		end
		local socre = 4 - ds

		all_data.hide_score=all_data.hide_score+socre
	end

end


--如果是斗地主则需要计算隐藏分
function PROTECT.ddz_dizhu_msg(my_pai_data)
	calculate_ddz_hide_socre(my_pai_data)
end

--如果是麻将则需要计算隐藏分
function PROTECT.tou_sezi_msg(_zhuang)
	calculate_mj_hide_socre(_zhuang)
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

	local server_id = all_data.match_info.match_svr_id
	--新手引导的管理者就是报名点
	if all_data.match_info.match_model=="xsyd" then
		server_id = all_data.match_info.signup_service_id
	end

	--通知管理者
	nodefunc.send(server_id,"change_grades",
						DATA.my_id,all_data.score,all_data.hide_score)

	PUBLIC.request_client("nor_mg_score_change_msg",{status_no=status_no,score=all_data.score})

end

-- 由外部直接调用 调整自己的分数 同 PROTECT.score_change_msg 方法
-- 主要用于托管不打直接进行分数改变
function CMD.nor_mg_score_change_msg(_score)
	
	all_data.score=all_data.score+_score

	local server_id = all_data.match_info.match_svr_id

	--通知管理者
	nodefunc.send(server_id,"change_grades",
						DATA.my_id,all_data.score,all_data.hide_score)

	PUBLIC.request_client("nor_mg_score_change_msg",{status_no=status_no,score=all_data.score})

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
		
		local data={
					status_no=all_data.status_no,
					status=all_data.status,
					game_type=all_data.game_type,
					game_kaiguan = all_data.game_kaiguan,
					game_multi = all_data.game_multi,
					match_info=all_data.match_info,
					round_info=all_data.round_info,
					room_info=all_data.room_info,
					signup_num=all_data.signup_num,
					countdown=all_data.countdown,
					promoted_type=all_data.promoted_type,
					players_info=all_data.player_info,
					rank=all_data.rank,
					gameover_info=all_data.gameover_info,
					revive_assets=all_data.revive_assets,
					revive_num = all_data.revive_num,
					revive_round = all_data.revive_round,
					revive_assets = all_data.revive_assets,
					}

		get_game_status_info(data)
		
		PUBLIC.request_client("nor_mg_all_info",data)
		return 0
	end
	--没有状态时 表示没有在游戏中  返回状态码为 -1 
	PUBLIC.request_client("nor_mg_all_info",{status_no=-1})
	return 0
end

send_info_func["all"]=send_all_info

function REQUEST.nor_mg_req_info_by_send(self)
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




-- 统计相关 ***************
--[[
{
	id = _player_id,
	dizhu_win_count = _dizhu_win,
	nongmin_win_count = _nongmin_win,
	first = _first,
	second = _second,
	third = _third,
}
]]
local statistics_player_match_rank_data=nil


function PUBLIC.init_statistics_match_data()
	statistics_player_match_rank_data=skynet.call(DATA.service_config.data_service,"lua",
											"get_statistics_player_match_rank",DATA.my_id)

end


function PUBLIC.add_statistics_player_match(_rank)

	if _rank==1 then
		local num = statistics_player_match_rank_data.first+1
		statistics_player_match_rank_data.first=num
	elseif _rank==2 then
		local num = statistics_player_match_rank_data.second+1
		statistics_player_match_rank_data.second=num
	elseif _rank==3 then
		local num = statistics_player_match_rank_data.third+1
		statistics_player_match_rank_data.third=num
	end

	skynet.send(DATA.service_config.data_service,"lua",
				"update_statistics_player_match_rank",DATA.my_id,_rank)

end


function REQUEST.get_statistics_player_match(self)
	return {
			result=0,
			first = statistics_player_match_rank_data.first,
			second = statistics_player_match_rank_data.second,
			third = statistics_player_match_rank_data.third,
			}
end






return PROTECT


