--
-- Author: hw
-- Date: 2018/3/28
-- Time: 
-- 说明：比赛场管理服务

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "ddz_match_enum"
require "normal_enum"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local launch_entity = require "match_dingshikai"
local winner_list_len=10
DATA.service_config = nil
DATA.my_id = nil
DATA.match_config = nil

DATA.player_msg_name = nil
DATA.game_rule_config = nil
DATA.receive_result_cmd = nil

DATA.fs_lose_player = nil


local zy_cup_activity_cfg = require "zy_cup_activity_cfg"


local asset_type_desc = {
	jing_bi = "鲸币x",
	room_card = "房卡x",
	zy_city_match_ticket_fs = "鲸鱼杯复赛门票x",
	zy_city_match_ticket_js = "鲸鱼杯决赛门票x",
	shop_gold_sum = "红包券x",
}
local function get_award_desc(rank)
	local desc = ""

	local aw = DATA.match_config.match_award_config[rank]

	if aw then
		for i,d in ipairs(aw) do

			local v = d.value
			if d.asset_type == "shop_gold_sum" then
				if d.value%100 == 0 then
					v = math.floor(d.value/100)
				else
					v = d.value/100
				end
			end

			local des = asset_type_desc[d.asset_type] .. v

			if i == 1 then
				desc = desc .. des
			else
				desc = desc .."\n".. des
			end
		end
	end

	return desc
end


local function init()

	--啓動配置
	DATA.player_msg_name={
		begin_msg="citymg_begin_msg",
		enter_room_msg="citymg_enter_room_msg",
		change_rank_msg="citymg_change_rank_msg",
		promoted_final_msg="citymg_promoted_final_msg",
		promoted_msg="citymg_promoted_msg",
		gameover_msg="citymg_gameover_fs_msg",
		wait_result_msg="citymg_wait_result_msg",
	}

	DATA.receive_result_cmd = "match_over"

	launch_entity.init()

	PUBLIC.init_winners_list()

end

local function add_virtual_winner(_data)
	local cfg = require "virtual_winner_hx"

	for i,name in ipairs(cfg) do
		local r = #_data+1
		_data[r]={
				id = "virtual_"..i,
				rank = r,
				name = name,
				award = get_award_desc(r),
			}
		PUBLIC.add_winners_to_list(_data[r].id,_data[r].name,_data[r].award)
	end
end

local function add_winner(_data)
	
	local data = {}

	for i,winner in ipairs(_data) do

		local name = skynet.call(DATA.service_config.data_service,"lua",
								"get_player_info",winner.player_id,"player_info","name")
		local award = get_award_desc(i)

		data[#data+1]={
			id = winner.player_id,
			name = name,
			award = award,
			rank = i,
		}
		PUBLIC.add_winners_to_list(winner.player_id,name,award)

	end
	
	add_virtual_winner(data)
	

	skynet.send(DATA.service_config.data_service,"lua","add_zy_city_match_rank_fs",data)

end

local function add_lose_player(_data)
	
	for i,d in ipairs(_data) do
		
		if i > zy_cup_activity_cfg.fs_promoted_num then

			DATA.fs_lose_player[d.player_id]={player_id=d.player_id,rank=i}

		end

	end

	skynet.send(DATA.service_config.data_service,"lua","add_zy_city_match_fs_lose",DATA.fs_lose_player)

end


function PUBLIC.exit()
	print("city_match_manager_fs_service exit!!!")
	skynet.exit()
end


-- 检查是否可以停止服务
function PUBLIC.try_stop_service(_count,_time)

	return "wait",string.format(" '%s' is not stopped!",DATA.my_id)

end


function CMD.reload_config(_cfg)

	DATA.match_config = _cfg

	launch_entity.use_new_config()

	return 0
end

function CMD.match_over(_match_svr_id,_data)

	add_winner(_data)

	add_lose_player(_data)

	launch_entity.game_complete(_match_svr_id)
end

function PUBLIC.add_winners_to_list(id,name,award)
	DATA.winners_count=DATA.winners_count+1
	if DATA.winners_count%winner_list_len==1 then
		DATA.winners_list[DATA.winners_count]={}
		DATA.cur_winners_list_point=DATA.winners_count
	end

	local len = #DATA.winners_list[DATA.cur_winners_list_point]+1
	DATA.winners_list[DATA.cur_winners_list_point][len]={id=id,rank=DATA.winners_count,award=award,name=name}
	DATA.winners_hash[id]={id=id,rank=DATA.winners_count,award=award,name=name}

end


function PUBLIC.init_winners_list()
	local ret = skynet.call(DATA.service_config.data_service,"lua","query_zy_city_match_rank_fs")
	for i,d in ipairs(ret) do
		d.rank = i
		PUBLIC.add_winners_to_list(d.player_id,d.name,d.award)
	end
end


--ranking  每次返回30个名额(winner_list_len) ranking为起点
--没有ranking则返回全部
function CMD.get_winners_list(ranking)
	if DATA.winners_list then
		if ranking  then
			return DATA.winners_list[ranking]
		end
		return DATA.winners_list
	end
	-- 还未产生没有获奖名单 
	return nil
end


--没有ranking则返回全部
function CMD.get_my_rank(player_id)

	return DATA.winners_hash[player_id]

end


function CMD.query_match_active_player_num()
	return {result=0,num=0}
end



--
function CMD.get_lose_player()

	return DATA.fs_lose_player

end


--查询比赛状态
function CMD.query_start_time()
	return "CALL_FAIL"
end

--查询比赛总排行
function CMD.query_all_rank()
	return "CALL_FAIL"
end

function CMD.record_players_info(_player_id,_player_name,_head_link)
	
end



--获取赢了的玩家--即进入决赛的玩家
local win_player = nil
function CMD.get_win_player()

	if not win_player then
		win_player = {}
		for k,d in pairs(DATA.winners_hash) do
			if d.rank <= zy_cup_activity_cfg.fs_promoted_num then
				win_player[k]=d
			end
		end
	end

	return win_player
end

function CMD.get_signup_config()
	return DATA.match_config.signup_data_config
end


function CMD.start(_id,_service_config,_match_config)

	math.randomseed(os.time()*78415)

	DATA.service_config=_service_config
	DATA.my_id=_id
	DATA.match_config = _match_config

	--获奖名单
	DATA.winners_list={}
	DATA.winners_count=0
	DATA.winners_hash={}

	DATA.fs_lose_player = {}

	--当前list的起点
	DATA.cur_winners_list_point=0

	init()
	
end

-- 启动服务
base.start_service()
