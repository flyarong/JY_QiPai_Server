local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local skynet = require "skynet_plus"

print("x------------ interface:",base,base.DATA)

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

--- 把sql插入队列中
function PUBLIC.db_exec(_sql , _queue_name)
  skynet.send(DATA.service_config.data_service,"lua","db_exec",_sql , _queue_name)
end

--房间ID
DATA.my_id = 0

--上级管理者
DATA.mgr_id = 0

--剩余桌子数量
DATA.table_count = 0



local run=true

-- 空闲桌子编号列表
DATA.table_list = {}
local table_list = DATA.table_list
-- 游戏中的桌子
DATA.game_table = {}
local game_table = DATA.game_table

--- 使用，雇用一个空的桌子
local function employ_table()
	local _t_number=table_list[#table_list]
	table_list[#table_list]=nil
	if _t_number then 
		DATA.table_count=DATA.table_count-1
	end
	return _t_number
end

--- 回收一个桌子
local function return_table(_t_number)

	local _d=game_table[_t_number]
	
	game_table[_t_number]=nil
	table_list[#table_list+1]=_t_number
	DATA.table_count=DATA.table_count+1
end

---- 回收桌子
function CMD.return_table(table_id)
	return_table(table_id)
end


function PUBLIC.update()
	while run do

		skynet.sleep(DATA.dt*100)
	end
end

function PUBLIC.new_game(_t_num)
	local _d = game_table[_t_num]

	---- 一些其他数据


end

function CMD.new_table(_game_config)
	local _t_num=employ_table()
	if not _t_num then 
		return false
	end

	local _d={}
	--------------- 通用游戏数据 -----------------
	-- 玩家id
	_d.player_id = _game_config.player_id
	_d.player_name = _game_config.player_name

	game_table[_t_num]=_d

	PUBLIC.new_game(_t_num)

	return _t_num

end


----------- 开奖
function CMD.kaijiang(table_id , bets , total_bet_money , bet_money)
	local ret = {}
	--- 操作限制
	if PUBLIC.get_action_lock("kaijiang" , table_id) then
		return 1008
	end
	PUBLIC.on_action_lock( "kaijiang" , table_id)

	-------- 没有数据
	local _d = game_table[table_id]
	if not _d then
		PUBLIC.off_action_lock( "kaijiang" , table_id)
		return 1003
	end

	if not bets or type(bets) ~= "table" or not next(bets) then
		PUBLIC.off_action_lock( "kaijiang" , table_id)
		return 1003
	end

	---
	

	----- 向消消乐开奖中心要数据
	local kaijiang_result = skynet.call( DATA.service_config.xiaoxiaole_lottery_center_service , "lua" , "lottery_kaijiang"  )

	if type(kaijiang_result) == "number" then
		PUBLIC.off_action_lock( "kaijiang" , table_id)
		return kaijiang_result
	end

	if type(kaijiang_result) == "table" then
		ret.kaijiang_maps = kaijiang_result.xc_map
		ret.award_rate = kaijiang_result.award_rate
		ret.real_award_rate = kaijiang_result.real_award_rate
		ret.xc_map_rate = kaijiang_result.xc_map_rate
		ret.lian_locky_award_rate = kaijiang_result.lian_locky_award_rate
		ret.lucky_data = kaijiang_result.lucky_data
	end
	
	print("xxx----------------------room_kaijiang:",ret.real_award_rate , bet_money)
	ret.award_money = math.floor( (ret.real_award_rate or 0) * bet_money + 0.5 )

	----- 加钱
	skynet.send(DATA.service_config.data_service,"lua","change_asset_and_sendMsg",
                    _d.player_id , PLAYER_ASSET_TYPES.JING_BI ,
                    ret.award_money, ASSET_CHANGE_TYPE.XXL_GAME_AWARD , (ret.award_rate or 0) )

	----- 加日志
	--local sql_str = string.format([[
	--					insert into player_xiaoxiaole_log (player_id,total_bet_money,bet_money,kaijiang_beishu,kaijiang_award , orig_xc_str , final_xc_str , lucky_str ) 
	--					values('%s',%s,%s,%s,%s)
	--				]] , _d.player_id , total_bet_money , bet_money , ret.real_award_rate or 0 , ret.award_money or 0 ,  )

	--PUBLIC.db_exec(sql_str )


	PUBLIC.off_action_lock( "kaijiang" , table_id)
	return ret
end

-- 获得空闲的桌子数量
function CMD.get_free_table_num()
	return #table_list
end

function CMD.destroy()
	run=nil
	nodefunc.destroy(DATA.my_id)
	skynet.exit()
end

function PUBLIC.init(_id,_ser_cfg,_config)
	math.randomseed(os.time()*1271)

	
	DATA.table_count= DATA.one_room_table_num
	DATA.my_id=_id
	

	--init table
	for i=1,DATA.table_count do 
		table_list[#table_list+1] = i
	end


	skynet.fork(PUBLIC.update)
end
