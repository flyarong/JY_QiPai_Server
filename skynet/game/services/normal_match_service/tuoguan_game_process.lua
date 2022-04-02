--
-- Author: yy
-- Date: 2018/3/28
-- Time: 
-- 说明：比赛场服务 进行匹配和安排

local skynet = require "skynet_plus"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "printfunc"
require "normal_enum"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECT = {}

local tuoguan_event_data = {}

local tuoguan_cfg = {}

local function init_cfg(_raw_config)
	
	local _cfg = basefunc.deepcopy(_raw_config.config)

	tuoguan_cfg = {}

	local t_id = DATA.match_game_id
	if string.sub(DATA.match_config.match_model,1,6) == "naming" then
		t_id = "gms_ddz"
		if GAME_TYPE_TO_PLAY_TYPE[DATA.match_config.game_type] == "mj" then
			t_id = "gms_mj"
		end
	end

	for i,d in ipairs(_cfg) do

		if d.game_id == t_id then
			tuoguan_cfg = d

			local wa = 0
			for i,w in ipairs(tuoguan_cfg.multi_weight) do
				wa = wa + w
			end	
			tuoguan_cfg.multi_weight_count=wa

			wa = 0
			for i,w in ipairs(tuoguan_cfg.win_num_weight) do
				wa = wa + w
			end	
			tuoguan_cfg.win_num_weight_count=wa

		end
	end

	-- 如果没有配置 用一个默认的
	if not next(tuoguan_cfg) then
		tuoguan_cfg = {
			multi = {2,4,8},
			multi_weight = {1,1,4},
			multi_weight_count = 6,
			win_num = {1,2},
			win_num_weight = {1,1},
			win_num_weight_count = 2,
			win_same = 1,
			lose_discount = 100,
			optimal = 50,
			game_time = {50,70},
		}
	end

end


local function get_multi()

	local weight = tuoguan_cfg.multi_weight
	local weight_count = tuoguan_cfg.multi_weight_count

	local r = math.random(1,weight_count)

	local index = 0
	for i,w in ipairs(weight) do
		r = r - w
		if r < 1 then
			index = i
			break
		end
	end

	local multi = tuoguan_cfg.multi[index]

	if GAME_TYPE_TO_PLAY_TYPE[DATA.match_config.game_type] == "mj" then
		multi = 2^multi
	end

	return multi

end


local function get_win_num()

	local weight = tuoguan_cfg.win_num_weight
	local weight_count = tuoguan_cfg.win_num_weight_count

	local r = math.random(1,weight_count)

	local index = 0
	for i,w in ipairs(weight) do
		r = r - w
		if r < 1 then
			index = i
			break
		end
	end

	return tuoguan_cfg.win_num[index]

end


local function calculate_score(_stake,_rate)
	local scores = {}
	local sc = 0
	local wn = get_win_num()

	local sr = get_multi()*_stake*_rate
	for i=1,wn do
		
		if tuoguan_cfg.win_same ~= 1 and i>1 then
			sr = get_multi()*_stake*_rate
		end

		scores[i]=sr

		sc = sc + sr

	end

	local ln = DATA.game_seat_num - wn

	local ls = math.ceil((sc/ln)*tuoguan_cfg.lose_discount*0.01)

	for i=wn+1,DATA.game_seat_num do
		
		--对底分取整
		local s = ls-(ls%_stake)

		scores[i]=-s

	end

	if math.random(1,100) > tuoguan_cfg.optimal then
		basefunc.array_shuffle( scores )
	end

	-- dump(scores,"tuoguan calculate_score *****------")

	return scores

end


function PUBLIC.tuoguan_matching(_player_ids,_room_id,_table_id,_game_config,_score_change_msg)
	-- dump(_player_ids,"tuoguan_matching_player_ids")

	_game_config = _game_config or {}

	local init_rate = _game_config.init_rate or 1
	local init_stake = _game_config.init_stake or 1

	local round = _game_config.race_count or 1

	local ts = 0
	for i=1,round do
		
		local time = math.random(tuoguan_cfg.game_time[1],tuoguan_cfg.game_time[2])
		
		ts = ts + time

		local func = function ()

			local scores = calculate_score(init_stake,init_rate)

			table.sort( _player_ids, function (a,b)
				local a_grades,b_grades = DATA.player_infos[a].grades,DATA.player_infos[b].grades
				local a_hide_grades = DATA.player_infos[a].hide_grades
				local b_hide_grades = DATA.player_infos[b].hide_grades
				
				if a_grades == b_grades then
					return a_hide_grades > b_hide_grades
				end
				return a_grades > b_grades
			end )

			for i,p in ipairs(_player_ids) do
				nodefunc.send(p,_score_change_msg,scores[i])
			end

		end

		local key = _room_id.._table_id..i
		tuoguan_event_data[key]=
		{
			time = os.time() + ts,
			func = func,
		}

	end

	local func = function ()
		CMD.table_finish(_room_id,_table_id)
	end

	local key = _room_id.._table_id.."_finish"
	tuoguan_event_data[key]=
	{
		time = os.time() + ts + 1,
		func = func,
	}

end


-- 托管游戏过程的更新
function PUBLIC.tuoguan_process_update(dt)

	for k,e in pairs(tuoguan_event_data) do
		if e.time < os.time() then
			e.func()
			tuoguan_event_data[k] = nil
		end
	end
	
end



function PROTECT.init()

	nodefunc.query_global_config("tuoguan_match_process_config",init_cfg)

end

return PROTECT