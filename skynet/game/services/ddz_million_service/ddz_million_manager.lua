--
-- Author: lyx
-- Date: 2018/4/14
-- Time: 16:36
-- 说明：比赛场次管理 模块
--

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "printfunc"
require "ddz_million_service/ddz_million_matching"
require "ddz_million_service/ddz_million_settle"
require "ddz_million_service/ddz_million_record_log"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local begin_match_queue = basefunc.queue.new()

local PROTECTED = {}



--[[简单的当前状态
	0-准备中
	1-初赛
	3-结束
]]
DATA.current_status = nil


--游戏过程轮的配置数据 round => cfg
DATA.game_config = nil

--最大轮数
DATA.max_round = 0

-- 当前可承载人数 | 初始值
DATA.bearing_player_num = 100

-- 玩家的 id 数组（即 agent id）
DATA.players={}

--[[玩家的信息 player_id => info
	{
	round=1,--正在打的轮数
	grades=1254501,	--分数
	hide_grades=2,	--隐藏分数
	weed_out=0,	--淘汰名次 0-还没被淘汰
	in_table=false,	--是否在桌子上
	}
]]
DATA.player_infos={}

-- 在房间里的玩家 即还没上桌的玩家 数据
DATA.out_table_player_data = {player_hash={},num=0}

-- 不参与比赛的玩家，目前就是淘汰的玩家 数据
DATA.out_match_player_data = {player_hash={},num=0}

--已经晋级在休息中，准备比赛的玩家(暂时不参与匹配)
DATA.match_rest_players = {}


--按轮数分组玩家数据 round => player_hash
--此中的玩家一定是没有淘汰的玩家
DATA.round_players = {}

-- 房间集合：room_id => tables[table_id => info]
DATA.room_infos={}

--可用的空桌子队列 {room_id}
DATA.available_tables = basefunc.queue.new()

local function update(dt)
	
	--准备中或者结束就不需要更新了
	if DATA.current_status==0 
		or DATA.current_status==3 then
		return
	end

	PUBLIC.rematching_update(dt)

	PUBLIC.settle_update(dt)

end

--初始化相关数据
local function init_data()
	
	DATA.game_config = {}

	--初始化游戏轮的配置数据
	for id,config in ipairs(DATA.match_config.process) do
		DATA.game_config[id]=config
		DATA.game_config[id].issue=DATA.match_config.base_info.issue

		DATA.round_players[id]={player_hash={},num=0}

		--最后一个决赛的轮数
		if id > DATA.max_round then
			DATA.max_round = id
		end
		
	end

	--比赛配置为空
	if not next(DATA.game_config) then
		error("error: match no any match !!!")
	end

	if DATA.max_round ~= #DATA.game_config then
		error("error: match config error !!!")
	end

end

--开始游戏
local function start_game()
	
	--初赛底分
	local init_grades=DATA.match_config.base_info.init_score
	-- init_grades = 100

	for k,player_id in pairs(DATA.signup_players_map) do

		DATA.players[#DATA.players+1]=player_id
		DATA.out_table_player_data.player_hash[player_id]=player_id
		DATA.out_table_player_data.num=DATA.out_table_player_data.num+1

		DATA.player_infos[player_id]={
			grades=init_grades,
			hide_grades=0,
			weed_out=0,
			in_table=false,
			round=1,
		}

		nodefunc.send(player_id,"dbwg_begin_msg",
			DATA.my_id,
			init_grades,
			DATA.match_config.base_info.bonus,
			DATA.match_config.base_info.fuhuo_count
			)
	end

	DATA.round_players[1].player_hash=DATA.out_table_player_data.player_hash
	DATA.round_players[1].num=#DATA.players

	--###test
	print("sended begin msg for all user")

	-- 记录开始日志
	PUBLIC.start_match_log()

	PUBLIC.start_rematching()
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

function CMD.fuhuo(_player_id)
	return PUBLIC.fuhuo(_player_id)
end

function CMD.give_up_fuhuo(_player_id)
	PUBLIC.give_up_fuhuo(_player_id)
end

-- 一桌打完了打完了一轮
function CMD.table_finish(_room_id,_table_id)

	--###test
	print("table finish , info:",_room_id,_table_id)

	local room_info = DATA.room_infos[_room_id]

	if room_info then
		local table_info = room_info[_table_id]
		if table_info then

			--一轮的小结算进行判分淘汰
			PUBLIC.settle(table_info.players,table_info.round)

			--更新table表
			room_info[_table_id]=nil
			room_info.table_num=room_info.table_num-1
			--记录空桌子
			DATA.available_tables:push_back(_room_id)
		end

	end

end


function PROTECTED.game_begin()
	
	if DATA.current_status == 0 then
		
		DATA.current_status = 1

		--准备开始
		while true do
			--检查 桌子准备好了没有
			if DATA.available_tables:size()*3 < DATA.signup_players_count then
				skynet.sleep(100)
			else
				break
			end
		end

		-- 创建 update 时钟
		skynet.timer(1,update)

		init_data()

		start_game()

	end

end



-- 刷新人数 检测是否需要调整房间数量
function PROTECTED.refresh_players_num()

	local num = DATA.signup_players_count - DATA.bearing_player_num

	if num >= 0 then

		DATA.bearing_player_num=DATA.bearing_player_num+30
		PUBLIC.allot_room()

	end

end



-- 初始化 场次管理模块
function PROTECTED.init()

	math.randomseed(os.time()*78415)
	
	DATA.current_status = 0

	--初始化匹配 准备房间
	PUBLIC.allot_room()

end


return PROTECTED