--
-- Author: hw
-- Date: 2018/3/28
-- Time: 
-- 说明：比赛场服务 进行匹配和安排

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "printfunc"
require "normal_match_service.matching"
require "normal_match_service.settle"
local tuoguan_game_process = require "normal_match_service.tuoguan_game_process"
require "normal_match_service.match_record_log"

require "normal_enum"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA


--[[简单的当前状态
	0-准备中
	1-初赛
	2-决赛
	3-结束
]]
DATA.current_status = nil


DATA.service_config = nil
DATA.my_id = nil
DATA.manager_id = nil

--向上汇报结果的命令
DATA.reported_result_cmd = nil

DATA.match_id = nil

-- 数据库 match_ddz_game 的主键
DATA.match_game_id = nil

--配置数据：配置表
DATA.match_config = nil

--游戏过程轮的配置数据 round => cfg
DATA.game_config = nil

-- 玩家复活数据
DATA.player_revive_data = {}
DATA.revive_data = {}

-- 等待复活的玩家
DATA.wait_revive_player = {}


--进行到白热化阶段---达到决赛标志
DATA.in_final_flag = false

--游戏极限状态(初赛)
DATA.game_limit_flag = {
	config_is_out = nil,
	player_num_ok = nil,
}

--游戏玩家座位数量
DATA.game_seat_num = 0

--游戏房间服务类型
DATA.game_room_service_type = ""

--当前应该进行下一轮的轮数
DATA.current_next_round = 0

--当前应该进行的下一轮配置ID
DATA.current_next_cfg_id = 0

--初赛的起始轮数
DATA.prel_min_round = 0

--初赛的最大轮数
DATA.prel_max_round = 0

--总决赛的起始轮数
DATA.final_min_round = 0

--总决赛的最大轮数
DATA.final_max_round = 0

--当前游戏进程信息
DATA.cur_process_info = {}

-- 玩家的 id 数组（即 agent id）
DATA.players={}

--玩家排名排序需要更新
DATA.player_rank_dirty = false

--排名状态更新信号
DATA.signal_rank_fresh = basefunc.signal.new()

--占据排名的挂名托管
DATA.occupy_rank_tuoguan = {}

DATA.occupy_rank_tuoguan_num = 0


-- 玩家rank顺序表
DATA.player_rank_list={}


--[[玩家的信息 player_id => info
	{
	grades=1254501,	--分数
	rank=2,	--分数排名
	weed_out=0,	--淘汰名次 0-还没被淘汰
	in_table=false,	--是否在桌子上
	}
]]
DATA.player_infos={}

-- 在房间里的玩家 数组 即还没上桌的玩家
DATA.out_table_players = {}

-- 不参与比赛的玩家，目前就是淘汰的玩家 数组
DATA.out_match_players = {}

--已经晋级在休息中，准备比赛的玩家(暂时不参与匹配)
DATA.match_rest_players = {}

-- 房间集合：room_id => tables[table_id => info]
DATA.room_infos={}


--可用的空桌子队列 {room_id}
DATA.available_tables = basefunc.queue.new()


--玩家接受消息的名字
DATA.player_msg_name={
	begin_msg="", 			    --比赛开始消息(服务id,初始积分,初始排名)
	enter_room_msg="", 			--通知进入房间消息(房间id,桌子id,游戏配置,比赛剩余人数)
	change_rank_msg="", 		--排行刷新消息(排名)
	promoted_final_msg="", 		--晋级决赛分数调整消息(调整后的分数)
	promoted_msg="", 			--晋级消息(是否是晋级决赛)
	gameover_msg="", 			--比赛结束消息(排名,奖励)
	wait_result_msg="", 		--比赛等待结果消息
	score_change_msg="", 		--分数改变消息
	wait_revive_msg="", 		--等待复活消息
	free_revive_msg="", 		--免费复活消息
}

local function update(dt)
	
	--准备中或者结束就不需要更新了
	if DATA.current_status==0 
		or DATA.current_status==3 then
		return
	end


	PUBLIC.rematching_update(dt)

	PUBLIC.refresh_rank_update(dt)

	PUBLIC.tuoguan_process_update(dt)
	
end

--初始化相关数据
local function init_data()
	
	DATA.game_config = {}

	local game_type = DATA.match_config.game_type
	DATA.game_seat_num = GAME_TYPE_SEAT[game_type]
	DATA.game_room_service_type = GAME_TYPE_ROOM[game_type]

	--初始化游戏轮的配置数据
	for id,config in ipairs(DATA.match_config.match_game_config) do
		DATA.game_config[config.round]=config
		DATA.game_config[config.round].match_id = DATA.match_id

		--第一个初赛的轮数
		if DATA.prel_min_round == 0 and config.round_type == 0 then
			DATA.prel_min_round = config.round
		end

		--最后一个初赛的轮数
		if config.round >= DATA.prel_max_round and config.round_type == 0 then
			DATA.prel_max_round = config.round
		end

		--第一个决赛的轮数
		if DATA.final_min_round == 0 and config.round_type == 1 then
			DATA.final_min_round = config.round
		end

		--最后一个决赛的轮数
		if config.round >= DATA.final_max_round and config.round_type == 1  then
			DATA.final_max_round = config.round
		end
		
	end
	
	DATA.cur_process_info = {
		final_round = nil, 	--当前第几轮是决赛轮未知
		round = 0, 	--当前轮数
		round_type = 0, 	-- 0-初赛  1-决赛 

		rise_num = 0,
		rise_score = 0,
		race_count = 0,
		init_rate = 0,
		init_stake = 0,
	}

	-- 正常开始为初赛
	DATA.current_status = 1

	--比赛配置为空
	if not next(DATA.game_config) then
		error("error: match no any match !!!")
	end

	--比赛中没有决赛
	if DATA.final_max_round < 1 then
		error("error: match no any final match !!!")
	end

	--只有决赛
	if DATA.final_min_round == 1 then
		DATA.current_status = 2
		
		DATA.cur_process_info.final_round = 1
		DATA.cur_process_info.round_type = 1

		DATA.revive_data = nil
		print("revive_data is invalid "..DATA.my_id)

		print("warn: match only final match !!!")
	end

	DATA.current_next_round = 1

	DATA.cur_process_info.round = DATA.current_next_round

	local game_config = DATA.game_config[DATA.cur_process_info.round]
	DATA.cur_process_info.rise_num = game_config.rise_num
	DATA.cur_process_info.rise_score = game_config.rise_score
	DATA.cur_process_info.race_count = game_config.race_count
	DATA.cur_process_info.init_rate = game_config.init_rate
	DATA.cur_process_info.init_stake = game_config.init_stake

	DATA.current_next_cfg_id = 1

	print("match info:",DATA.final_min_round,DATA.final_max_round)

end

--开始游戏
local function start_game()
	
	--初赛底分
	local init_grades=DATA.match_config.match_data_config.init_prel_score

	if DATA.revive_data then
		DATA.revive_data.num = DATA.match_config.match_data_config.revive_num
		DATA.revive_data.time = DATA.match_config.match_data_config.revive_time

		if DATA.revive_data.num 
			and DATA.revive_data.num > 0
			and DATA.revive_data.time
			and DATA.revive_data.time > 0 then
				dump(DATA.revive_data,"revive_data "..DATA.my_id)
		else
			DATA.revive_data = nil
			print("revive_data is nil "..DATA.my_id)
		end
	end
	
	local ps = {}
	--通知所有玩家进入比赛准备匹配开赛了
	local rank = 1
	for player_id,v in pairs(DATA.players) do
		
		local score = init_grades
		if DATA.occupy_rank_tuoguan[player_id] then
			score = 99999999
		end
		
		nodefunc.send(player_id,DATA.player_msg_name.begin_msg,DATA.my_id,score,rank,DATA.player_count)
		DATA.player_infos[player_id]={
			grades=score,
			hide_grades=0,
			rank=rank,
			weed_out=0,
			in_table=false,
			revive_num=0,
		}

		DATA.player_rank_list[rank]=player_id

		--所有人都是离桌状态
		DATA.out_table_players[rank]=player_id
		
		ps[rank]=player_id

		rank = rank + 1
	end

	DATA.players = ps

	--###test
	print("sended begin msg for all user")

	-- 记录开始日志 产生 match_id
	PUBLIC.start_match_log()
end

--
local function set_tuoguan_occupy_rank()
	
	local tor = DATA.match_config.tuoguan_occupy_rank
	if not tor then
		return
	end

	local tn = #tor.occupy_rank
	local rn = tor.occupy_rank[tn]
	for i,d in ipairs(tor.total_player) do
		if DATA.player_count <= d then
			rn = tor.occupy_rank[i]
			break
		end
	end

	if rn < 1 then
		return
	end

	for player_id,d in pairs(DATA.players) do

		if not basefunc.chk_player_is_real(player_id) then
			DATA.occupy_rank_tuoguan[player_id]=player_id
			DATA.occupy_rank_tuoguan_num = DATA.occupy_rank_tuoguan_num + 1
			rn = rn - 1
		end

		if rn < 1 then
			break
		end

	end

	if rn > 0 then

		print(string.format("set_tuoguan_occupy_rank error tuoguan is not enough ([%s/%s]|seat:%s)"
				,rn,rn+DATA.occupy_rank_tuoguan_num,DATA.game_seat_num))

		-- 减少 以 凑一桌
		local ls = DATA.occupy_rank_tuoguan_num % DATA.game_seat_num

		if ls > 0 then
			for k,v in pairs(DATA.occupy_rank_tuoguan) do
				DATA.occupy_rank_tuoguan[k]=nil
				DATA.occupy_rank_tuoguan_num = DATA.occupy_rank_tuoguan_num - 1
				ls = ls - 1
				if ls < 1 then
					break
				end
			end
		end

	end

	dump(DATA.occupy_rank_tuoguan,"@@@occupy_rank_tuoguan@@@")
end


function CMD.revive(_player_id)
	return PUBLIC.revive(_player_id)
end


function CMD.give_up_revive(_player_id)
	return PUBLIC.give_up_revive(_player_id)
end

--获取当前剩余玩家的数量
local match_player_num_data = {match_player_num=0,in_table_player_num=0}
function CMD.get_match_player_num()

	match_player_num_data.match_player_num = PUBLIC.get_match_player_num()
	match_player_num_data.in_table_player_num = PUBLIC.get_in_table_player_num()

	return match_player_num_data

end


--正在休息的晋级玩家准备完成，可以开始进行匹配了
function CMD.player_ready_matching(_player_id)
	local info = DATA.match_rest_players[_player_id]
	if info then
		DATA.match_rest_players[_player_id] = nil
		
		print("我休息好了",_player_id)
		return true
	end
	print("我早就休息好了",_player_id)
	return false
end

--玩家成绩改变
function CMD.change_grades(_player_id,_grades,_hide_grades)

	local player_info = DATA.player_infos[_player_id]

	if player_info then
		
		player_info.grades=_grades
		player_info.hide_grades=_hide_grades
		DATA.player_rank_dirty = true

		--###test
		print("change grades ok , info:",_player_id,_grades)
	end

end

-- 一桌打完了打完了一轮
function CMD.table_finish(_room_id,_table_id)

	--###test
	print("table finish , info:",_room_id,_table_id)

	local room_info = DATA.room_infos[_room_id]

	if room_info then
		local table_info = room_info[_table_id]
		if table_info then

			--更新当前应该进行的下一轮的轮数 按最大的轮数
			if table_info.round + 1 > DATA.current_next_round then
				DATA.current_next_round = table_info.round + 1
				
				DATA.cur_process_info.round = DATA.current_next_round

			end

			dump(table_info,"table_info****-----")
			
			--一轮的小结算进行判分淘汰
			PUBLIC.settle(table_info.players,table_info.cfg_id,table_info.final)

			--更新table表
			room_info[_table_id]=nil
			room_info.table_num=room_info.table_num-1
			--记录空桌子
			DATA.available_tables:push_back(_room_id)
		end

	end

end

function CMD.return_table(_room_id,_table_id)
	
end

function CMD.init_match(_manager_id,_match_data_config,_game_rule_config,_player_msg_name,_player_ids,_player_count,_reported_result_cmd)

	DATA.manager_id=_manager_id
	DATA.match_config=_match_data_config
	DATA.players=_player_ids
	DATA.player_count=_player_count
	DATA.match_game_id = _match_data_config.game_id
	DATA.current_status = 0 --准备中
	DATA.player_msg_name = _player_msg_name
	DATA.game_rule_config = _game_rule_config --游戏的规则配置
	DATA.reported_result_cmd = _reported_result_cmd

	init_data()

	set_tuoguan_occupy_rank()

	start_game()

	tuoguan_game_process.init()

	--匹配开始
	PUBLIC.init_matching()
	
end



function PUBLIC.try_stop_service(_count,_time)
	return "wait","match game is running !"
end


function CMD.start(_id,_service_config)

	math.randomseed(os.time()*78415)

	DATA.service_config=_service_config
	
	DATA.my_id=_id

	-- 创建 update 时钟
	skynet.timer(1,update)

end


-- 启动服务
base.start_service()