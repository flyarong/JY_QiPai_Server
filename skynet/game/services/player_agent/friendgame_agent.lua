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

local friendgame_trans = require "cfg_trans_friendgame"

--[[
		wait_join
		wait_begin
		gaming
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
	nor_mj_xzdd = "麻将-血战到底",
	nor_ddz_nor = "经典斗地主",
	nor_ddz_lz = "赖子斗地主",
}

--config**********



local game_name = ""
local act_lock = false
--
local game_model="friendgame"

local play_type = nil

local base_info = nil

local gameInstance=nil
local gameConfig=nil
local all_data=nil

local gameover_info

--状态数据信息
local s_info=nil
--玩家信息
local p_info=nil

local return_msg={result=0}

local update_timer=nil
local vote_callback=nil

local room_card_rent = nil



local player_score_count
local room_data_log

local gps_data


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

--扣除房卡
local function deduct_room_card_rent()
	if room_card_rent and all_data.room_dissolve ~= 1 then
		CMD.change_asset_multi({[1]={asset_type=PLAYER_ASSET_TYPES.ROOM_CARD,value=-room_card_rent}}
							,ASSET_CHANGE_TYPE.FRIENDGAME_RENT,all_data.fg_room_no)

		room_card_rent = nil
	end
end

local function add_status_no()
	all_data.status_no=all_data.status_no+1
end


-- 心跳状态变化
local function on_hearbet_status_change(_is_good)
	
	for _,_info in ipairs(p_info) do
		if _info.id ~= DATA.my_id then
			nodefunc.send(_info.id,"friendgame_net_quality_msg",base_info.seat_num,_is_good)
		end
	end

end

local function update()
	
	if all_data then
		if all_data.vote_data and all_data.vote_data.countdown>0  then
			all_data.vote_data.countdown=all_data.vote_data.countdown-1
			if all_data.vote_data.countdown<1 and vote_callback then
				vote_callback()
			end
		end
	end

	-- PROTECT.mjfg_auto_cancel_signup()

end
--[[
	DATA.friendgame_data:
		--房卡场房间号
		fg_room_no=result.room_no
		--管理服务ID
		manager_id=result.manager_id
		--玩法类型
		game_type=self.game_type
		--客户端转过来的配置
		ori_game_cfg=self.game_cfg

		player_info={}

--]]

-- ###_test 初始化数据
local function new_game(manager_id,game_type,fg_room_no,ori_game_cfg,room_owner,room_id,t_num,room_base_cfg)

	DATA.friendgame_data={}
	all_data=DATA.friendgame_data

	gameover_info = {}
	all_data.m_PROTECT=PROTECT

	player_score_count = {0,0,0,0}

	all_data.fg_room_no=fg_room_no
	all_data.manager_id=manager_id
	all_data.game_type=game_type
	all_data.ori_game_cfg=ori_game_cfg
	all_data.room_owner=room_owner

	DATA.friendgame_data.player_info={}
	p_info=DATA.friendgame_data.player_info

	all_data.status="wait_join"

	all_data.status_no=0
	
	all_data.model_name="friendgame"

	all_data.room_rent = room_card_rent

	all_data.room_dissolve = 0

	play_type = GAME_TYPE_TO_PLAY_TYPE[game_type]

	-- ###_test 根据客户端配置确定
	all_data.base_info={
			room_id = room_id,
			t_num = t_num,
			init_stake = room_base_cfg.init_stake,
			init_rate = room_base_cfg.init_rate,
			race_count = room_base_cfg.race_count,
			cur_race = 1,
			player_count = room_base_cfg.player_count,
		}

	base_info=all_data.base_info
		
	all_data.config={
		game_cfg={room_base_cfg.game_config},
		rule_cfg={room_base_cfg.rule_config},
		agent_cfg={
			overtime_auto_action_cfg = 0,
		},
	}

	--获得agent
	all_data.gameInstance=PUBLIC.require_game_by_type(game_type)
	gameInstance=all_data.gameInstance
	if not gameInstance then
		error("join_game_room gameInstance not exist!!!!!!"..game_type)
	end

	gameInstance.init(all_data)

	--加入房间
	gameInstance.join_room({
								id=DATA.my_id,
								name=DATA.player_data.player_info.name,
								head_link=DATA.player_data.player_info.head_image,
								sex=DATA.player_data.player_info.sex,
								dressed_head_frame = DATA.player_data.dress_data.dressed_head_frame,
								glory_score = DATA.player_data.glory_data.score,
								score=0,
								net_quality=1,
							})


	update_timer=skynet.timer(dt,update)

	base.DATA.hearbeat_status_change:bind(game_model,on_hearbet_status_change)

end

local function find_p_info(_seat_num)
	for i,_info in ipairs(p_info) do
		if _info.seat_num == _seat_num then
			return i
		end
	end

	return nil
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

-- 房卡场 的 agent 配置
local _agent_config = 
{
	overtime_auto_action_cfg = 0,
}

local function free_game()

	base.DATA.hearbeat_status_change:unbind(game_model)

	if update_timer then
		update_timer:stop()
		update_timer=nil
	end
	
	PUBLIC.unlock(game_name)
	PUBLIC.free_agent(game_name)
	gameInstance.free()
	gameInstance=nil
	gps_data=nil
	DATA.friendgame_data=nil
	act_lock=false
end


function PROTECT.my_join_return(_data)

	if _data.p_info then 
		for _,_info in pairs(_data.p_info) do
			p_info[#p_info+1]=_info
		end
	end

	all_data.status="wait_begin"
	base_info.seat_num = _data.seat_num
	--不是房主  自动准备
	if all_data.room_owner~=DATA.my_id then
		local ret = gameInstance.ready()
	end
end

function PROTECT.player_join_msg(_info)

	add_p_info(_info)
	
	--通知客户端
	add_status_no()
	PUBLIC.request_client("friendgame_join_msg",{status_no=all_data.status_no,player_info=_info})
end


function PROTECT.begin_msg(_cur_race,_again)

	if _cur_race == 1 then
		all_data.status="gaming"
	end
	
end

function PROTECT.player_exit_msg(_seat_num)
	
	local i = find_p_info(_seat_num)
	if i then
		table.remove(p_info,i)
	end

	--通知客户端
	add_status_no()
	PUBLIC.request_client("friendgame_quit_msg",{status_no=all_data.status_no,seat_num=_seat_num})

	if _seat_num==base_info.seat_num then
		PUBLIC.clear_gps_info()
		free_game()
	end

end


function PROTECT.gamecancel_msg()

	--通知客户端
	add_status_no()
	
	PUBLIC.request_client("friendgame_gamecancel_msg",{status_no=all_data.status_no})
	
	all_data.room_dissolve = 1 -- 房间已解散

	free_game()
end


function PROTECT.game_settlement_msg(_data,_is_over,_lose_surplus,_log_id)
	
	local settlement_data={}
	for seat_num,score in ipairs(_data.scores) do
		player_score_count[seat_num]=player_score_count[seat_num]+score
	end

	gameover_info[#gameover_info+1]={
		grades=_data.scores,
		ddz_nor_statistics=_data.ddz_nor_statistics,
		mj_xzdd_statistics=_data.mj_xzdd_statistics,
	}


	deduct_room_card_rent()
	

	PROTECT.room_race_over_log(_log_id)

end


function PROTECT.game_next_game_msg(_data)
	base_info.cur_race=base_info.cur_race+1
end


function PROTECT.game_gameover_msg(_data)
	all_data.status="gameover"
	all_data.gameover_info=gameover_info
	add_status_no()
	PUBLIC.request_client("friendgame_gameover_msg",{status_no=all_data.status_no,gameover_info=gameover_info})

	PROTECT.add_settlement_record_log()
	PROTECT.room_over_log()

	free_game()
end


-- 分数改变
function PROTECT.score_change_msg(_data)

	for _seat_num,_sd in pairs(_data) do
		local i = find_p_info(_seat_num)
		p_info[i].score = p_info[i].score + _sd.score
	end
	-- dump(p_info)
end



--###_test 信息未保留以及信息保留方式不对
--[[

--]]
function REQUEST.friendgame_create_room(self)

	if not self.game_type or not support_game_type[self.game_type] or  not GAME_TYPE_AGENT[self.game_type] then
		return {result=1001}
	end

	if not self.game_cfg or type(self.game_cfg)~="table" then
		return {result=1001}
	end

	if act_lock then
		return {result=1008}
	end
	act_lock = true


	-- 检查客户端传来的参数 --检查是否合法  要求：客户端与服务器通用
	local _code = friendgame_trans.check(self.game_cfg,self.game_type)
	if 0 ~= _code then
		act_lock=false
		return {result=_code}
	end

	game_name = "friendgame_" .. self.game_type
	if not PUBLIC.lock(game_name,game_name) then
		act_lock = false
		return {result=1005}
	end

	PUBLIC.ref_agent(game_name)

	local result = skynet.call(DATA.service_config.friendgame_center_service,"lua","gen_game_manager_info",self.game_type)
	if type(result)=="table" and result.result==0 then

		local room_card = CMD.query_asset_by_type(PLAYER_ASSET_TYPES.ROOM_CARD)

		local room_info=nodefunc.call(result.manager_id,"create_game_room",
										DATA.my_id,result.room_no,self.game_type,self.game_cfg,room_card,
										room_max_player[self.game_type])

		if room_info.result~=0 then
			PUBLIC.unlock(game_name)
			PUBLIC.free_agent(game_name)
			act_lock = false
			return {result=room_info.result}
		end
		room_card_rent = room_info.room_rent
		new_game(result.manager_id,self.game_type,result.room_no
				,self.game_cfg,DATA.my_id,room_info.room_id,room_info.t_num
				,room_info.room_base_cfg)

		PROTECT.create_room_start_log(self.game_type,result.room_no,DATA.my_id,room_card_rent,self.game_cfg)


		act_lock = false
		return {result=0}
	end

	
	PUBLIC.unlock(game_name)
	PUBLIC.free_agent(game_name)
	act_lock = false
	return {result=result}

end

--###_test 信息未保留以及信息保留方式不对   逻辑不对
function REQUEST.friendgame_join_room(self)
	
	if not self.room_no 
		or type(self.room_no)~="string" 
		or string.len(self.room_no)<1
		or string.len(self.room_no)>9 then
		return {result=1001}
	end

	--###_test 要判断 是否已经在房间中

	if act_lock then
		return {result=1008}
	end
	act_lock = true

	local room_info = skynet.call(DATA.service_config.friendgame_center_service,"lua","query_manager_info",self.room_no)

	if room_info then

		game_name = "friendgame_" .. room_info.game_type
		if not PUBLIC.lock(game_name,game_name) then
			act_lock = false
			return {result=1005}
		end

		PUBLIC.ref_agent(game_name)

		local room_card = CMD.query_asset_by_type(PLAYER_ASSET_TYPES.ROOM_CARD)
		local info=nodefunc.call(room_info.manager_id,"join_friend_room",DATA.my_id,self.room_no,room_card)

		if type(info)=="table" then

			room_card_rent = info.room_rent
			new_game(room_info.manager_id,info.game_type,self.room_no,info.game_cfg
					,info.room_owner,info.room_id,info.t_num
					,info.room_base_cfg)

			act_lock = false

			local ret = {
						result=0,
						game_type = info.game_type,
					}
			return ret

		else
			PUBLIC.unlock(game_name)
			PUBLIC.free_agent(game_name)
			act_lock = false
			return {result=info}
		end

	end
	act_lock = false
	return {result=3201}
end

function REQUEST.friendgame_begin_game()

	if not all_data or act_lock then
		return {result=1008}
	end
	act_lock=true

	if all_data.status=="wait_begin"
			and all_data.game_data 
			and all_data.room_owner 
			and all_data.room_owner==DATA.my_id then
			
			local r_data=all_data.game_data.ready

			if r_data then
				local count=0
				for _,v in ipairs(r_data) do
					if v==1 then
						count=count+1
					end
				end
				--房主不能准备 所以是  base_info.player_count-1
				if count ==base_info.player_count-1 then
					local return_msg = gameInstance.ready()

					if return_msg and return_msg.result==0 then
						act_lock=false
						return {result=0}
					end
				end
			end
	end
	act_lock=false
	return {result=1008}
end

function REQUEST.begin_vote_cancel_room(self)

	if act_lock or not all_data then
		return {result=1008}
	end

	act_lock=true
	if all_data.status=="gaming"  then
		
		local result=nodefunc.call(all_data.manager_id,"begin_vote_cancel_room",all_data.fg_room_no,DATA.my_id)
		act_lock=false
		return result
	end

	act_lock=false
	return {result=1008}
end


function REQUEST.player_vote_cancel_room(self)
	if act_lock or not all_data or not self.opt or (self.opt~=0 and self.opt~=1 ) then
		return {result=1008}
	end
	act_lock=true

	if all_data.vote_data and not all_data.vote_data.my_vote then
		local result=nodefunc.call(all_data.manager_id,"player_vote_cancel_room",all_data.fg_room_no,DATA.my_id,self.opt)
		act_lock=false
		return result
	end
	act_lock=false
	return {result=1008}
end


function REQUEST.friendgame_exit_room(self)
	
	if (not all_data) 
		or(all_data.status ~= "wait_begin") then
		return {result=1002}
	end

	if act_lock then
		return {result=1008}
	end
	act_lock = true

	-- ★ 如果是房主，则解散：
	if DATA.my_id == all_data.room_owner then

		local ret = nodefunc.call(all_data.manager_id,"cancel_friend_room",all_data.fg_room_no)
		if ret ~= 0 then
			act_lock = false
			return {result=ret}
		end
		
		room_data_log = nil

	-- ★ 如果不是房主：
	else
	
		local ret = nodefunc.call(all_data.manager_id,"exit_friend_room",DATA.my_id,all_data.fg_room_no,all_data.base_info.seat_num)
		if ret ~= 0 then
			act_lock = false
			return {result=ret}
		end

	end


	act_lock = false
	return {result=0}
end

function REQUEST.friendgame_get_history_record_ids(self)
	if act_lock then
		return {result=1008}
	end
	act_lock = true

	local ids = skynet.call(DATA.service_config.data_service,"lua","query_friendgame_record_ids",DATA.my_id)

	act_lock = false

	return {result=0,list=ids}
end

function REQUEST.friendgame_get_history_record(self)
	if act_lock then
		return {result=1008}
	end

	if not self.id or type(self.id)~="number" then
		return {result=1001}
	end

	act_lock = true

	local data = skynet.call(DATA.service_config.data_service,"lua","query_friendgame_history_record",DATA.my_id,self.id)

	act_lock = false

	return {result=0,record=data}
end


function REQUEST.friendgame_get_all_history_record(self)
	if act_lock then
		return {result=1008}
	end
	act_lock = true

	local data = skynet.call(DATA.service_config.data_service,"lua","query_friendgame_history_record",DATA.my_id)

	act_lock = false

	return {result=0,records=data}
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
-- ###_test  未完成版
local function send_all_info()
	
	if all_data then
		
		local data={
					status_no=all_data.status_no,
					status=all_data.status,
					game_type=all_data.game_type,
					friendgame_room_no=all_data.fg_room_no,
					ori_game_cfg=all_data.ori_game_cfg,
					player_info=all_data.player_info,
					room_owner=all_data.room_owner,
					gameover_info=all_data.gameover_info,
					player_count=all_data.base_info.player_count,
					vote_data=all_data.vote_data,
					room_dissolve=all_data.room_dissolve,
					room_rent = all_data.room_rent,
					}
		

		get_game_status_info(data)
		
		PUBLIC.request_client("friendgame_all_info",data)
		return 0
	end
	--没有状态时 表示没有在游戏中  返回状态码为 -1 
	PUBLIC.request_client("friendgame_all_info",{status_no=-1})
	return 0
end

send_info_func["all"]=send_all_info

function REQUEST.friendgame_req_info_by_send(self)
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

function CMD.friendgame_net_quality_msg(_seat_num,_is_good)

	local i = find_p_info(_seat_num)
	
	if i then

		p_info[i].net_quality = _is_good and 1 or 0
		
		add_status_no()

		PUBLIC.request_client("friendgame_net_quality"
								,{status_no=all_data.status_no
								,seat_num=_seat_num
								,net_quality=p_info[i].net_quality})

	end

end

function CMD.friendgame_begin_vote_cancel_room_msg(player_id,vote_countdown)
	all_data.vote_data={agree_count=0,disagree_count=0,my_vote=nil,begin_player_id=player_id,countdown=vote_countdown}
	--房主不需要
	if player_id~=DATA.my_id then
		vote_callback=function ()
							vote_callback=nil
							nodefunc.send(all_data.manager_id,"player_vote_cancel_room",all_data.fg_room_no,DATA.my_id,1)
						end
	end
	
	add_status_no()
	--通知客户端
	PUBLIC.request_client("friendgame_begin_vote_cancel_room_msg",{status_no=all_data.status_no,player_id=player_id,countdown=vote_countdown})

end
function CMD.friendgame_over_vote_cancel_room_msg(result)

	local vote_data_log = ""
	if all_data.vote_data then
		vote_data_log = all_data.vote_data.agree_count .. "-" .. all_data.vote_data.disagree_count
	end

	all_data.vote_data=nil

	PROTECT.add_settlement_record_log()

	if result == 0 then
		all_data.room_dissolve = 1 -- 房间已解散
		PROTECT.room_over_log("vote_cancel_room:"..vote_data_log)
	end

	--通知客户端
	add_status_no()
	PUBLIC.request_client("friendgame_over_vote_cancel_room_msg",{status_no=all_data.status_no,vote_result=result})
end
function CMD.friendgame_player_vote_cancel_room_msg(p_id,opt)
	if opt==1 then
		all_data.vote_data.agree_count=all_data.vote_data.agree_count+1
	else
		all_data.vote_data.disagree_count=all_data.vote_data.disagree_count+1
	end
	if p_id==DATA.my_id then
		all_data.vote_data.my_vote=opt
		vote_callback = nil
	end
	add_status_no()
	PUBLIC.request_client("friendgame_player_vote_cancel_room_msg",{status_no=all_data.status_no,player_id=p_id,opt=opt})
end



--[[ gps

]]
function send_gps_info_msg()
	skynet.fork(function ()
		local ret = REQUEST.query_gps_info()
		if ret.result==0 then
			for i,d in ipairs(ret.data) do
				nodefunc.send(d.player_id,"gps_info_msg",ret.data)
			end
		end
	end)
end

function REQUEST.send_gps_info(self)
	
	if not base_info 
		or not base_info.seat_num 
		or base_info.seat_num < 1 then
		return {result=0}
	end

	if type(self.locations)~="string" then
		return {result=1008}
	end
	self.latitude = tonumber(self.latitude)
	if not self.latitude then
		return {result=1008}
	end
	self.longitude = tonumber(self.longitude)
	if not self.longitude then
		return {result=1008}
	end

	--数据已经存在了
	if gps_data then
		return {result=0}
	end

	local ip = DATA.extend_data.ip

	ip = string.gsub(ip,"^(.*):.*$","%1")

	gps_data=
	{
		player_id = DATA.my_id,
		room_no = all_data.fg_room_no,
		seat_num = base_info.seat_num,
		ip = ip,
		locations = self.locations,
		latitude = self.latitude,
		longitude = self.longitude,
	}

	nodefunc.call(all_data.manager_id,"append_gps_data",gps_data)
	send_gps_info_msg()

	return {result=0}
end

function REQUEST.query_gps_info(self)

	local d = nodefunc.call(all_data.manager_id,"query_gps_info",all_data.fg_room_no)

	if not d then
		return {result=1004}
	end

	-- dump(d,"gps_d/////****------")
	return {
		result=0,
		data=d,
	}
end

function CMD.gps_info_msg(data)
	PUBLIC.request_client("gps_info_msg",{data=data})
end

function PUBLIC.clear_gps_info()
	local data =
	{
		room_no = all_data.fg_room_no,
		seat_num = base_info.seat_num,
	}
	nodefunc.call(all_data.manager_id,"clear_gps_data",data)

	send_gps_info_msg()
end




--[[ log 

]]
function PROTECT.create_room_start_log(game_type,room_no,room_owner,room_rent,room_options)
	room_data_log = {
		game_type = game_type,
		room_no = room_no,
		room_owner = room_owner,
		room_rent = room_rent,
		room_options = cjson.encode(room_options),
		begin_time = os.time(),
		race_ids = {},
	}

end


function PROTECT.room_race_over_log(race_id)
	if room_data_log then
		local len = #room_data_log.race_ids
		room_data_log.race_ids[len+1] = race_id
	end

end


function PROTECT.room_over_log(reason)
	if room_data_log then
		reason = reason or "finish"
		
		room_data_log.end_time = os.time()
		room_data_log.over_reason = reason

		skynet.send(DATA.service_config.data_service,"lua","add_friendgame_room_record_log"
					,room_data_log.game_type
					,room_data_log.room_no
					,room_data_log.room_owner
					,room_data_log.room_rent
					,room_data_log.room_options
					,room_data_log.begin_time
					,room_data_log.end_time
					,room_data_log.over_reason
					,room_data_log.race_ids
					)
		
		room_data_log = nil
	end

end


function PROTECT.add_settlement_record_log()

	if room_data_log then

		local data_log = {
			game_name = game_name_map[room_data_log.game_type],
			time = os.time(),
			room_no = room_data_log.room_no,
			player_infos={}
		}
		
		for i,_info in ipairs(p_info) do

			data_log.player_infos[_info.seat_num]={
				id = _info.id,
				name = _info.name,
				head_img_url = _info.head_link,
				score = player_score_count[i],
			}

		end

		skynet.send(DATA.service_config.data_service,"lua","add_friendgame_history_record"
						,data_log
						)
	end


	print("add_settlement_record_log")
end



return PROTECT


