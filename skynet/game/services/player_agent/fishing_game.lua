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

-- 鱼的接口数据集合初始化
base.fish_interface_protect={}
local FIP = base.fish_interface_protect

local game_model = "fishing_game"
local game_name = ""

local act_flag = false

local base_info = nil
local room_status = nil

local gameInstance=nil

local all_data=nil


local return_msg={result=0}

local update_timer=nil

local modify_score_data = {}
local modify_score_time = 0
local modify_score_dt = 2

-- 断线后多久清除子弹返回子弹钱
local return_bullet_money_limit_time = 120
local return_bullet_money_time = nil

local asset_change_type = nil

local p_info_map_index = {}

--update 间隔
local dt=1


local function add_p_info(_p_info)

	for i,_info in ipairs(all_data.players_info) do
		if _info.seat_num == _p_info.seat_num then
			all_data.players_info[i] = _p_info
			p_info_map_index[_p_info.seat_num]=i
			return
		end
	end

	all_data.players_info[#all_data.players_info+1]=_p_info
	p_info_map_index[_p_info.seat_num]=#all_data.players_info
end


local function del_p_info(_seat_num)

	local index = p_info_map_index[_seat_num]
	if index then
		table.remove(all_data.players_info,index)
		p_info_map_index[_seat_num] = nil
		for i,_info in ipairs(all_data.players_info) do
			p_info_map_index[_info.seat_num]=i
		end
	end

end


local function get_p_info(_seat_num)
	local index = p_info_map_index[_seat_num]
	if index then
		return all_data.players_info[index]
	end
	return nil
end


local function update_p_info(players_info)

	all_data.players_info = {}

	local _seat_num = 0
	for k,_info in pairs(players_info) do
		all_data.players_info[#all_data.players_info+1]=_info
		if _info.id == DATA.my_id then
			_seat_num = _info.seat_num
		end
		p_info_map_index[_info.seat_num]=#all_data.players_info
	end

	all_data.room_info.seat_num = _seat_num

end

local function update_my_score()
	
	local cur_score = CMD.query_asset_by_type(PLAYER_ASSET_TYPES.JING_BI)
	local cur_fish_coin = CMD.query_asset_by_type(PLAYER_ASSET_TYPES.FISH_COIN)

	local index = p_info_map_index[1]
	if index then
		local p_info = all_data.players_info[index]
		if p_info then
			p_info.score = cur_score
			p_info.fish_coin = cur_fish_coin
		end
	end

end


local function player_exit_game()
	
	REQUEST.fsg_quit_game()

end


local function modify_score_add(_change_type_id,_jing_bi,_fish_coin)

	if _jing_bi == 0 and _fish_coin == 0 then
		return
	end

	local _asset_data = {
							[1]={asset_type=PLAYER_ASSET_TYPES.JING_BI,value=_jing_bi},
							[2]={asset_type=PLAYER_ASSET_TYPES.FISH_COIN,value=_fish_coin},
						}

	local sid = PUBLIC.asset_staging(_asset_data)

	local msd = modify_score_data[_change_type_id] or {}
	modify_score_data[_change_type_id] = msd

	msd[sid] = sid

end


local function modify_score_save(_force)

	if os.time() > modify_score_time or _force then

		modify_score_time = os.time() + modify_score_dt

		for _change_type_id,sids in pairs(modify_score_data) do
			
			PUBLIC.asset_merge_commit(sids,asset_change_type,_change_type_id)

		end

		modify_score_data = {}

	end

end


local function disconnect_deal()
	
	return_bullet_money_time = os.time() + return_bullet_money_limit_time

end


local function disconnect_return_bullet_money()
	
	if return_bullet_money_time then

		if return_bullet_money_time < os.time() then

			gameInstance.return_bullet_money()

			return_bullet_money_time = nil

			REQUEST.fsg_quit_game()

		end

	end

end

local function update()

	if all_data then
		
		modify_score_save()
		
		disconnect_return_bullet_money()

		if FIP and FIP.data_module_update then
			FIP.data_module_update()
		end

	end

end


-- ###_test 初始化数据  config 是报名成功后返回的
local function new_game(game_type,config)

	DATA.fish_game_data={}
	all_data=DATA.fish_game_data

	all_data.gameover_info = nil

	all_data.m_PROTECT=PROTECT

	all_data.game_type=game_type

	all_data.game_level=config.game_level
	
	all_data.room_info=
	{
		game_id = config.game_id,
	}

	asset_change_type = "fish_game_"..config.game_id

	all_data.status="wait_table"

	-- 我已经拥有解锁的的炮台
	all_data.my_barbette_id = {1,2}

	all_data.match_info={}
	all_data.match_info.name=config.name
	all_data.match_info.signup_match_id=config.signup_match_id
	all_data.match_info.signup_service_id=config.signup_service_id
	all_data.match_info.match_model=config.match_model

	modify_score_data = {}

	all_data.base_info={}
	base_info=all_data.base_info
	base_info.player_count = GAME_TYPE_SEAT[game_type]

	all_data.players_info={}

	all_data.gameInstance=PUBLIC.require_game_by_type(all_data.game_type)
	gameInstance=all_data.gameInstance
	if not gameInstance then
		error("gameInstance not exist!!!!!!"..game_type)
	end

	update_timer=skynet.timer(dt,update)

	DATA.signal_logout:bind(game_name,player_exit_game)
	DATA.signal_disconnect:bind(game_name,disconnect_deal)

end


local function free_game()

	if update_timer then
		update_timer:stop()
		update_timer=nil
	end

	if gameInstance then
		gameInstance.free()
		gameInstance=nil
	end

	PUBLIC.unlock(game_name)

	DATA.match_game_data=nil

	DATA.signal_disconnect:unbind(game_name)
	DATA.signal_logout:unbind(game_name)

	act_flag=false
	
end

local function get_signup_service_id(id)
	return "fishing_service_" .. id
end


local function check_assets(_assets)
	local jing_bi = CMD.query_asset_by_type(PLAYER_ASSET_TYPES.JING_BI)
	local fish_coin = CMD.query_asset_by_type(PLAYER_ASSET_TYPES.FISH_COIN)
	
	local my_value = jing_bi + fish_coin
	local error_code = 0
	for i,asset in ipairs(_assets) do

		if asset.asset_type ~= PLAYER_ASSET_TYPES.JING_BI 
			and asset.asset_type ~= PLAYER_ASSET_TYPES.FISH_COIN then
				my_value = CMD.query_asset_by_type(asset.asset_type)
		end

		if asset.condi_type == NOR_CONDITION_TYPE.CONSUME then
			if my_value < asset.value then
				error_code = 1012
				break
			end
		elseif asset.condi_type == NOR_CONDITION_TYPE.EQUAL then
			if my_value ~= asset.value then
				error_code = 1012
				break
			end
		elseif asset.condi_type == NOR_CONDITION_TYPE.GREATER then
			if my_value < asset.value then
				error_code = 1012
				break
			end
		elseif asset.condi_type == NOR_CONDITION_TYPE.LESS then
			if my_value > asset.value then
				error_code = 1012
				break
			end
		else
			skynet.fail("asset.condi_type error " .. tostring(asset.condi_type))
		end

	end

	return error_code
end


function REQUEST.fsg_signup(self)

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

	--请求进入条件
	local _result,_data=nodefunc.call(signup_service_id,"get_enter_info")

	if _result=="CALL_FAIL" then

		free_game()
		return_msg.result=1000
		act_flag=false
		return return_msg

	elseif _result == 0 then

		game_name = game_model .. "_" .. _data.game_type

		if not PUBLIC.lock(game_name,game_model,self.id) then
			return_msg.result=1005
			act_flag=false
			return return_msg
		end

		--验证所需财务
		local ver_result = check_assets(_data.condi_data)

		if ver_result == 0 then
			-- signup_assets=_data.condi_data
		else
			act_flag=false
			free_game()
			return {
				result=ver_result,
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

		_result.signup_service_id = signup_service_id
		_result.game_id=self.id
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


function REQUEST.fsg_quit_game(self)
	print("----------------------------- fishing_game__fsg_quit_game")
	if act_flag then
		return_msg.result=1008
		return return_msg
	end

	if not all_data then
		return_msg.result=0
		return return_msg
	end

	act_flag = true

	if gameInstance and gameInstance.quit_room and all_data.game_data then
		gameInstance.quit_room()
	end

	modify_score_save(true)

	nodefunc.send(all_data.match_info.signup_service_id,"player_exit_game",DATA.my_id)

	act_flag = false
	-- if _result=="CALL_FAIL" then
	-- 	return_msg.result=1000
	-- 	return return_msg
	-- end	

	-- if ret.result ~= 0 then
	-- 	return ret
	-- end

	free_game()
	all_data = nil

	return_msg.result=0
	return return_msg
end


function REQUEST.fsg_all_info_test(self)

	if act_flag then
		return_msg.result=1008
		return return_msg
	end

	if not all_data 
		or (all_data.status ~= "wait_table" and all_data.status ~= "gaming") then
			return_msg.result=1002
			return return_msg
	end
	
	local fishery_data = gameInstance.get_status_info()

	while all_data.status == "wait_table" or not fishery_data do

		skynet.sleep(5)

		fishery_data = gameInstance.get_status_info()

		print("fsg_all_info wait_table ...")

	end

	return_bullet_money_time = nil

	update_my_score()
	
	return {

		result=0,

		game_id = all_data.room_info.game_id,
		name = all_data.match_info.name,
		game_type = all_data.game_type,

		room_info = all_data.room_info,
		players_info = all_data.players_info,
		seat_num = all_data.game_data.seat_num,
		my_barbette_id = all_data.my_barbette_id,
		
		frozen_time_data = all_data.game_data.frozen_time_data,

		fish_map_id = fishery_data.fish_map_id,

		skill_status = fishery_data.skill_status,
		skill_cfg = fishery_data.skill_cfg,

		fishery_barbette_id = fishery_data.barbette_id,
		begin_time = fishery_data.begin_time,
		fishery_data = fishery_data.fishery_data,

	}

end


---- add by wss
----强制从当前渔场 跳至 xx渔场
function REQUEST.fsg_force_change_fishery(self)
	--- 参数检查
	if not self or not self.target_fishery or type(self.target_fishery) ~= "number" then
		return 1001	
	end
	local ret = {}
	ret.result = 0
	--- 操作限制
	if PUBLIC.get_action_lock("fsg_force_change_fishery") then
		ret.result = 1008
		return ret
	end
	PUBLIC.on_action_lock( "fsg_force_change_fishery" )

	local quit_ret = REQUEST.fsg_quit_game(self)
	if quit_ret.result == 0 then
		local sg_ret = REQUEST.fsg_signup({id = self.target_fishery})
		if sg_ret.result ~= 0 then
			ret.result = sg_ret.result
		end
	else
		ret.result = quit_ret.result
	end

	--- 休息xx秒返回
	skynet.sleep(20)

	PUBLIC.off_action_lock( "fsg_force_change_fishery" )
	return ret
end


function CMD.fsg_enter_room_msg(_room_id,_t_num,_seat_num)

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

	all_data.base_info.t_num=_t_num
	all_data.room_info.t_num=_t_num

	all_data.base_info.room_id=_room_id
	gameInstance.init(all_data)

	local score = CMD.query_asset_by_type(PLAYER_ASSET_TYPES.JING_BI)
	local fish_coin = CMD.query_asset_by_type(PLAYER_ASSET_TYPES.FISH_COIN)

	--加入房间
	gameInstance.join_room({
								seat_num=_seat_num,
								id=DATA.my_id,
								name=DATA.player_data.player_info.name,
								head_link=DATA.player_data.player_info.head_image,
								sex=DATA.player_data.player_info.sex,
								dressed_head_frame = DATA.player_data.dress_data.dressed_head_frame,
								glory_score = DATA.player_data.glory_data.score,
								score=score,
								fish_coin=fish_coin,
							})

	all_data.status="gaming"

	print("fsg_enter_room_msg",DATA.my_id)

end


function PROTECT.my_join_return(_data)

	if _data.p_info then
		update_p_info(_data.p_info)
	end

	-- ok 开始
	gameInstance.ready()

	print("my_join_return ready ok")
end
--****************** hw test ###_test
-- local zheng_moeny=0
-- local fu_money=0
--****************** hw test ###_test

--[[分数改变 返回应该变化的分数
	附带改变的原因
	发射子弹 _arg1 = "bullet" _arg2 = 子弹等级(index)
	回收子弹 _arg1 = "return_bullet" _arg2 = 子弹等级(index)
	打死鱼了 _arg1 = "fish_dead" _arg2 = 鱼的类型 _arg3 = 子弹等级(index) _arg4 = 当前可以提升奖励的活动的类型
]]
function PROTECT.modify_score(_data,_arg1,_arg2,_arg3,_arg4)

	local cur_score = CMD.query_asset_by_type(PLAYER_ASSET_TYPES.JING_BI)
	local cur_fish_coin = CMD.query_asset_by_type(PLAYER_ASSET_TYPES.FISH_COIN)

	local jing_bi = 0
	local fish_coin = 0
	
	--****************** hw test ###_test

	-- if _data>0 then
	-- 	zheng_moeny=zheng_moeny+_data
	-- else
	-- 	fu_money=fu_money+_data
	-- end
	--****************

	-- 分数改变统计
	if _arg1 == "bullet" then

		local has_fish_coin = cur_fish_coin
		fish_coin = _data
		jing_bi = 0
		if fish_coin + has_fish_coin < 0 then
			
			fish_coin = -has_fish_coin

			local score = cur_score
			jing_bi = _data - fish_coin

			if jing_bi + score < 0 then
				jing_bi = -score

			end

		end
		
		local change_type_id = "bullet_" .. _arg2
		modify_score_add(change_type_id,jing_bi,fish_coin)

	elseif _arg1 == "return_bullet" then

		jing_bi = _arg3 or 0
		fish_coin = _arg4 or 0

		local change_type_id = "return_bullet_" .. _arg2
		modify_score_add(change_type_id,jing_bi,fish_coin)

	elseif _arg1 == "fish_dead" then

		local score = cur_score
		jing_bi = _data
		if jing_bi + score < 0 then
			jing_bi = -score
		end

		local change_type_id = "fish_dead"

		modify_score_add(change_type_id,jing_bi,0)

		---- 打死鱼奖励消息
		-- DATA.msg_dispatcher:call("buyu_award", jing_bi )
		PUBLIC.trigger_msg( {name = "buyu_award"} , jing_bi )

	else

	end

	update_my_score()

	return jing_bi,fish_coin
end


function PROTECT.modify_skill_prop(_type,_num)

	CMD.change_asset_multi(
						{
							[1]={asset_type=_type,value=_num},
						}
						,asset_change_type,0)

end

function PROTECT.player_join_msg(_info)

	add_p_info(_info)

	--通知客户端
	PUBLIC.request_client("fsg_join_msg",{player_info=_info})
end

function CMD.player_leave_msg(_seat_num)

	if not all_data then return end

	del_p_info(_seat_num)

	-- 托管离开不清除子弹
	gameInstance.delete_bullet(_seat_num)

	PUBLIC.request_client("fsg_leave_msg",{seat_num=_seat_num})
end


function PROTECT.change_p_score(_seat_num,_score)

	local index = p_info_map_index[_seat_num]
	if index then
		local p_info = all_data.players_info[index]
		if p_info then

			if _score > 0 then
				
				p_info.score = p_info.score + _score

			else

				local has_fish_coin = p_info.fish_coin
				local fish_coin = _score
				local jing_bi = 0
				if fish_coin + has_fish_coin < 0 then
					
					fish_coin = -has_fish_coin

					local score = p_info.score
					jing_bi = _score - fish_coin

					if jing_bi + score < 0 then
						jing_bi = -score

					end

				end

				p_info.score = p_info.score + jing_bi
				p_info.fish_coin = p_info.fish_coin + fish_coin

			end

			nodefunc.send(all_data.game_data.room_id,"update_tuoguan_info"
							,all_data.game_data.t_num,all_data.game_data.seat_num,_seat_num,p_info)

		end
	end

end

function PROTECT.get_p_info(_seat_num)
	return get_p_info(_seat_num)
end


function CMD.debug_get_fish_money()
	print("zheng_moeny********* ",zheng_moeny)
	print("fu_money************ ",fu_money)
	dump(DATA.fish_game_data.game_data.buyu_fj_data[1],"xxxxxxxxbuyu_fj_data")

	print("$$$$$$$返奖率:  ",(DATA.fish_game_data.game_data.buyu_fj_data[1].real_all_fj+DATA.fish_game_data.game_data.buyu_fj_data[1].real_laser_bc+zheng_moeny)/(-fu_money))
	
end

return PROTECT
