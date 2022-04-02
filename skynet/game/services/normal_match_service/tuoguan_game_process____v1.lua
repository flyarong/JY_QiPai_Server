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

_LOCAL
local tuoguan_cfg = require "tuoguan_match_game_config"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local tuoguan_event_data = {}

local function init_cfg()
	
	for k,d in pairs(tuoguan_cfg) do

		local weight = d.weight

		local wa = 0
		for i,w in ipairs(weight) do
			wa = wa + w
		end	

		d.weight_count = wa

	end

end

-- 包含文件的时候直接初始化
init_cfg()


local function get_multi(_game_type)

	local multi = tuoguan_cfg[_game_type].multi
	local weight = tuoguan_cfg[_game_type].weight
	local weight_count = tuoguan_cfg[_game_type].weight_count

	local r = math.random(1,weight_count)

	local index = 0
	for i,w in ipairs(weight) do
		r = r - w
		if r < 1 then
			index = i
		end
	end

	return multi[index]

end


-- 二人斗地主 (二人麻将通用)
local function ddz_er(_init_stake,_init_rate,_game_type)

	local multi = get_multi(_game_type)
	local s1 = _init_stake*_init_rate*multi
	local s2 = -s1

	local sort_score = tuoguan_cfg[_game_type].sort_score

	if (math.random(0,100) < sort_score) then
		return {s1,s2}
	end

	if math.random(0,100) < 50 then
		return {s1,s2}
	else
		return {s2,s1}
	end

end


-- 普通斗地主
local function ddz_normal(_init_stake,_init_rate,_game_type)

	local multi = get_multi(_game_type)
	local dz = _init_stake*_init_rate*multi
	local nm = -math.floor(dz * 0.5)

	if math.random(0,100) < 50 then
		dz = -dz
		nm = -nm
	end

	local s = {nm,nm,nm}
	local r = math.random(1,3)
	s[r] = dz

	local sort_score = tuoguan_cfg[_game_type].sort_score
	if (math.random(0,100) < sort_score) then
		table.sort( s, function (a,b)
			return a>b
		end )
	end

	return s
end


-- 4人血战麻将
local function mj_xzdd_normal(_init_stake,_init_rate,_game_type)

	local scores = {}
	for i=1,2 do

		local multi = get_multi(_game_type)
		local s = _init_stake*_init_rate*multi
		
		scores[i]=s
		scores[i+2]=-s

	end
	
	-- 全0
	if scores[1]+scores[2]+scores[3]+scores[4] < 1 then
		return scores
	end

	for i=1,3 do

		local s = _init_stake*_init_rate*(2^math.random(0,3))

		local p1 = math.random(1,4)
		local p2 = math.random(1,4)
		scores[p1] = scores[p1] + s
		scores[p2] = scores[p2] - s
		
	end

	local sort_score = tuoguan_cfg[_game_type].sort_score
	if (math.random(0,100) < sort_score) then
		table.sort( scores, function (a,b)
			return a>b
		end )
	end

	return scores
end

local calculate_score_func = 
{
	nor_mj_xzdd = mj_xzdd_normal,
	nor_mj_xzdd_er_7 = ddz_er,
	nor_mj_xzdd_er_13 = ddz_er,
	nor_ddz_nor = ddz_normal,
	nor_ddz_lz = ddz_normal,
	nor_ddz_er = ddz_er,
}


function PUBLIC.tuoguan_matching(_player_ids,_room_id,_table_id,_game_config,_score_change_msg)

	local tp = GAME_TYPE_TO_PLAY_TYPE[DATA.match_config.game_type]

	local init_rate = _game_config.init_rate or 1
	local init_stake = _game_config.init_stake or 1

	local func = calculate_score_func[DATA.match_config.game_type]

	local scores = func(init_stake,init_rate,DATA.match_config.game_type)

	local game_time = tuoguan_cfg[DATA.match_config.game_type]

	local time = os.time() + math.random(game_time.min_time,game_time.max_time)

	table.sort( _player_ids, function (a,b)
		local a_grades,b_grades = DATA.player_infos[a].grades,DATA.player_infos[b].grades
		local a_hide_grades = DATA.player_infos[a].hide_grades
		local b_hide_grades = DATA.player_infos[b].hide_grades
		
		if a_grades == b_grades then
			return a_hide_grades > b_hide_grades
		end
		return a_grades > b_grades
	end )

	local func = function ()

		for i,p in ipairs(_player_ids) do
			nodefunc.send(p,_score_change_msg,scores[i])
		end
		skynet.sleep(10)
		CMD.table_finish(_room_id,_table_id)
	end

	local key = _room_id.._table_id
	tuoguan_event_data[key]=
	{
		time = time,
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