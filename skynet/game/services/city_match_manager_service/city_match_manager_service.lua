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

local launch_entity = require "match_renmanjikai"
local winner_list_len=10
DATA.service_config = nil
DATA.my_id = nil
DATA.match_config = nil

DATA.player_msg_name = nil
DATA.game_rule_config = nil
DATA.receive_result_cmd = nil

DATA.hx_lose_player = {}


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



local function init_lose_player()
	local ret = skynet.call(DATA.service_config.data_service,"lua","query_zy_city_match_hx_lose")

	for i,d in ipairs(ret) do
		DATA.hx_lose_player[d.player_id]=d.player_id
	end

end

local function init()

	--啓動配置
	DATA.player_msg_name={
		begin_msg="citymg_begin_msg",
		enter_room_msg="citymg_enter_room_msg",
		change_rank_msg="citymg_change_rank_msg",
		promoted_final_msg="citymg_promoted_final_msg",
		promoted_msg="citymg_promoted_msg",
		gameover_msg="citymg_gameover_hx_msg",
		wait_result_msg="citymg_wait_result_msg",
	}

	DATA.receive_result_cmd = "match_over"

	launch_entity.init()

	PUBLIC.deal_winners_list()

	init_lose_player()

end


local function add_winner(_data)
	local winner = _data[1]
	local name = skynet.call(DATA.service_config.data_service,"lua",
							"get_player_info",winner.player_id,"player_info","name")
	local award = get_award_desc(1)
	PUBLIC.add_winners_to_list(winner.player_id,name,award)	
end

local function update_lose_player(_data)
	
	for i,d in ipairs(_data) do
		
		if i == 1 then
			if DATA.hx_lose_player[d.player_id] then
				DATA.hx_lose_player[d.player_id]=nil
				skynet.send(DATA.service_config.data_service,"lua","delete_zy_city_match_hx_lose"
							,d.player_id)
			end
		else
			if not DATA.hx_lose_player[d.player_id] then
				DATA.hx_lose_player[d.player_id]=d.player_id
				skynet.send(DATA.service_config.data_service,"lua","add_zy_city_match_hx_lose"
							,d.player_id)
			end
		end

	end

end


function PUBLIC.exit()
	print("city_match_manager_service exit!!!")
	skynet.exit()
end


-- 检查是否可以停止服务
function PUBLIC.try_stop_service(_count,_time)

	--立即设置为不可以报名
	DATA.signup_status = MATCH_STATUS.DISABLE

	if DATA.signup_players_count>0 then
		return "wait",string.format(" '%s' is not stopped!",DATA.my_id)
	end

	local num = 1
	for k,ms in pairs(DATA.match_services) do
		if num > 1 then
			return "wait",string.format(" '%s' is not stopped!",DATA.my_id)
		end

		if next(ms.players) then
			return "wait",string.format(" '%s' is not stopped!",DATA.my_id)
		end

		num = num + 1
	end

	return "stop"
end


function CMD.add_virtual_winner(data)
	local award = get_award_desc(1)
	PUBLIC.add_winners_to_list(data.player_id,data.name,award)	
end

function CMD.reload_config(_cfg)

	DATA.match_config = _cfg

	launch_entity.use_new_config()

	return 0
end

function CMD.match_over(_match_svr_id,_data)

	add_winner(_data)

	update_lose_player(_data)

	launch_entity.game_complete(_match_svr_id)
end


--查询比赛状态
function CMD.query_start_time()
	return "CALL_FAIL"
end

--查询比赛总排行
function CMD.query_all_rank()
	return "CALL_FAIL"
end

function CMD.query_match_active_player_num()
	return {result=0,num=0}
end


function CMD.record_players_info(_player_id,_player_name,_head_link)
	
end


function PUBLIC.add_winners_to_list(id,name,award,_not_idb)
	DATA.winners_count=DATA.winners_count+1
	if DATA.winners_count%winner_list_len==1 then
		DATA.winners_list[DATA.winners_count]={}
		DATA.cur_winners_list_point=DATA.winners_count
	end

	local len = #DATA.winners_list[DATA.cur_winners_list_point]+1
	DATA.winners_list[DATA.cur_winners_list_point][len]={id=id,rank=DATA.winners_count,award=award,name=name}
	DATA.winners_hash[id]={id=id,rank=DATA.winners_count,award=award,name=name}

	if not _not_idb then
		skynet.send(DATA.service_config.data_service,"lua","add_zy_city_match_rank_hx"
						,id
						,name
						,award
						,DATA.winners_count)
	end

end

--处理winnersList  从db中读取出来处理
function PUBLIC.deal_winners_list()
	local ret = skynet.call(DATA.service_config.data_service,"lua","query_zy_city_match_rank_hx")
	for i,d in ipairs(ret) do
		d.rank = i
		PUBLIC.add_winners_to_list(d.player_id,d.name,d.award,true)
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


function CMD.get_my_rank(player_id)

	return DATA.winners_hash[player_id]

end


--
function CMD.get_lose_player()

	return DATA.hx_lose_player

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
	--当前list的起点
	DATA.cur_winners_list_point=0

	init()

end

-- 启动服务
base.start_service()
