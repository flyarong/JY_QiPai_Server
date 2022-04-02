--- 砸金蛋 房间 服务

local skynet = require "skynet_plus"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "normal_enum"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

--房间ID
DATA.my_id = 0

--上级管理者
DATA.mgr_id = 0

--剩余桌子数量
DATA.table_count = 0
-- 服务配置
DATA.service_config = nil


--- 今天id表示对应的起始时间 , 2018.0.0 00:00:00
DATA.zjd_start_time = 1514736000

local run=true

-- 空闲桌子编号列表
local table_list={}
-- 游戏中的桌子
local game_table={}

-- 获得今日的id
function PUBLIC.get_today_id()
	local now_time = os.time()

	return math.floor( (now_time - DATA.zjd_start_time) / 86400)
end

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
	
	--- 保存上次游戏的剩余的蛋
	for key,value in pairs(DATA.hammer_enum) do
		
		if _d.hammer_game_data[value].award_data then
			local award_id_vec = {}
			local real_old_egg = PUBLIC.get_old_real_egg( _d.hammer_game_data[value].award_data , DATA.config.award , DATA.real_rate_eggs_num )
			for key,data in ipairs(real_old_egg) do
				award_id_vec[#award_id_vec + 1] = data.id
			end

			PUBLIC.set_zjd_last_game_remain_eggs( _d.player_id , "last_game_remain_eggs"..value , award_id_vec )
		end

	end

	game_table[_t_number]=nil
	table_list[#table_list+1]=_t_number
	DATA.table_count=DATA.table_count+1



end

-- 创建新游戏需要的数据
local function new_game(_t_num , hammer_id , player_zjd_data , is_replace_egg )
	local _d = game_table[_t_num]
	local hammer_config = DATA.config.hammer[hammer_id]
	print("--------------------- hammer_id:",hammer_id)
	dump(DATA.config.hammer , "--------------- DATA.config.hammer:")
	if not hammer_config then
		error("------------------- no hammer config for hammer !!!")
	end

	_d.hammer_game_data[hammer_id] = _d.hammer_game_data[hammer_id] or {}

	local data_ref = _d.hammer_game_data[hammer_id]

	--- 对应的锥子等级
	data_ref.level = hammer_id
	--- 对应的锤子id
	data_ref.hammer_id = hammer_id                    
	-- 底分
	data_ref.base_money = hammer_config.base_money
	-- 换一批需要的钱
	data_ref.ori_replace_money = hammer_config.replace_money
	data_ref.replace_money = hammer_config.replace_money
	-- 蛋碎率
	data_ref.egg_open_rate = hammer_config.egg_open_rate
	-- 已经开的蛋的数量
	data_ref.opened_egg_num = 0
	-- 轮数id
	data_ref.round_id = 0

	--- 换蛋的消耗的钱数
	data_ref.replace_egg_spend = data_ref.replace_egg_spend or 0

	--- 这个锤子 的 数量,请求数据库
	--data_ref.hammer_num = player_zjd_data and player_zjd_data[ DATA.hammer_num_map[hammer_id] ] or (data_ref.hammer_num or 0)

	data_ref.award_data = data_ref.award_data or {}

	--- 如果有上次游戏里面有剩余的蛋，那么要给现在 
	if player_zjd_data then
		local last_game_remain_eggs = player_zjd_data[ "last_game_remain_eggs" .. hammer_id ]
		if last_game_remain_eggs then
			dump(last_game_remain_eggs , string.format("-----------last_game_remain_eggs:%d" , hammer_id))
			if type( last_game_remain_eggs ) == "table" then
				for key , award_id in ipairs(last_game_remain_eggs) do
					data_ref.award_data[#data_ref.award_data + 1] = {
						id = award_id
						, award = DATA.config.award[award_id].award 
						, name = DATA.config.award[award_id].name
						, is_get_award = false                                  -- 这个奖励是否已经获得了
						, award_type = DATA.egg_award_type.normal               -- 奖励类型
					}
				end

			end
			dump(data_ref.award_data , string.format("-after----------last_game_remain_eggs:%d" , hammer_id))
			player_zjd_data[ "last_game_remain_eggs" .. hammer_id ] = nil

			PUBLIC.set_zjd_last_game_remain_eggs( _d.player_id , "last_game_remain_eggs" .. hammer_id , {} )
		end
	end

	--- 所有蛋的状态,
	data_ref.eggs_status = nil
	--- 第几下开蛋表
	data_ref.eggs_open_status = nil

	--- 所有的奖励
	print("--------------- game_table[_t_num].player_id:",game_table[_t_num].player_id)
	data_ref.award_data , data_ref.replace_egg_spend = PUBLIC.init_award_data(hammer_id , is_replace_egg , data_ref.award_data , data_ref.replace_egg_spend)

end


local dt=0.5
local function update()
	while run do

		skynet.sleep(dt*100)
	end
end

function CMD.new_table(_game_config)
	local _t_num=employ_table()
	if not _t_num then 
		return false
	end

	

	local _d={}
	--------------- 通用游戏数据 -----------------
	-- 游戏进行了的时间
	_d.time = 0
	-- 锤子游戏数据
	_d.hammer_game_data = {}
	-- 玩家id
	_d.player_id = _game_config.player_id
	_d.player_name = _game_config.player_name
	-- 当前玩的是哪个锤子
	_d.gaming_hammer_id = DATA.hammer_enum.wood


	game_table[_t_num]=_d

	---- 所有的锤子对应的游戏数据初始化
	local player_zjd_data = PUBLIC.get_player_zjd_data(_d.player_id)
	if not player_zjd_data then
		player_zjd_data = {
			player_id = _d.player_id,
			today_get_award = 0,
			today_id = PUBLIC.get_today_id(),
			today_get_biggest_award_num_1 = 0,
			today_get_biggest_award_num_2 = 0,
			today_get_biggest_award_num_3 = 0,
			today_get_biggest_award_num_4 = 0,
		}
		PUBLIC.add_or_update_zjd_data( player_zjd_data )
	end
	dump(player_zjd_data , "xxxxxxxxxxxxxplayer_zjd_data")
	_d.today_get_biggest_award_num_1 = player_zjd_data.today_get_biggest_award_num_1
	_d.today_get_biggest_award_num_2 = player_zjd_data.today_get_biggest_award_num_2
	_d.today_get_biggest_award_num_3 = player_zjd_data.today_get_biggest_award_num_3
	_d.today_get_biggest_award_num_4 = player_zjd_data.today_get_biggest_award_num_4

	--- 今日获得的奖励
	_d.today_get_award = player_zjd_data.today_get_award
	--- 今天的id
	_d.today_id = player_zjd_data.today_id

	for i=1 , #DATA.hammer_map do
		new_game(_t_num , DATA.hammer_enum[ DATA.hammer_map[i] ] , player_zjd_data )
	end

	return _t_num
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

function CMD.get_can_open_egg_num()
	return DATA.real_rate_eggs_num
end

---- 获得游戏状态数据
function CMD.get_game_status( table_id )
	local ret= {}
	ret.result = 0

	local _d=game_table[table_id]

	if not _d then
		ret.result = 1004
	else
		ret.gaming_hammer_id = _d.gaming_hammer_id
		ret.hammer_game_data = _d.hammer_game_data
	end

	return ret
end
--财神模式
function CMD.zjd_caishen_mode( table_id , hammer_id , egg_no)
	local _d = game_table[table_id]
	local zjd_csmode_zj_power=skynet.getcfg_2number("zjd_csmode_zj_power") or 95
	local gl=zjd_csmode_zj_power*50   --被放大到10000
	local res={kaijiang={}}
	local award_cfg=DATA.config.award
	local base_money={100,1000,10000,20000,40000,80000}
	local kj_res
	if math.random(1,10000)<=gl then
		kj_res=1
	else
		kj_res=13
	end

	local total_award=award_cfg[kj_res].award*base_money[hammer_id]
	res.kaijiang[#res.kaijiang+1]={ egg_no = egg_no , award = kj_res , award_value = award_cfg[kj_res].award, award_money = total_award }
	--写入数据库日志  
	local award_str=tostring(award_cfg[kj_res].award)..","
	PUBLIC.add_zjd_log( _d.player_id , 0 , hammer_id, egg_no , kj_res , base.DATA.egg_award_type.cs_mode , total_award ,award_str )
	--- 直接加 金币
	skynet.send(DATA.service_config.data_service,"lua","change_asset_and_sendMsg",
                _d.player_id , PLAYER_ASSET_TYPES.JING_BI ,
                total_award, ASSET_CHANGE_TYPE.EGG_GAME_AWARD , kj_res)

	---- add by wss
	res.kaijiang.award_type = base.DATA.egg_award_type.cs_mode
	res.kaijiang.award_money = total_award

	return res

end

---- 砸蛋
function CMD.za_jin_dan( table_id , hammer_id , egg_no , is_spend_hammer )
	--- 操作限制
	if PUBLIC.get_action_lock("za_jin_dan" , table_id) then
		return 1008
	end
	PUBLIC.on_action_lock( "za_jin_dan" , table_id)

	local _d = game_table[table_id]

	local gaming_hammer_data = _d.hammer_game_data[_d.gaming_hammer_id]

	--- 检查
	if not _d or not gaming_hammer_data.eggs_status[egg_no]
		or gaming_hammer_data.eggs_status[egg_no] == -1 or hammer_id ~= _d.gaming_hammer_id then
		
		PUBLIC.off_action_lock( "za_jin_dan" , table_id)
		print("za_jin_dan 1003") 
		return 1003
	end


	local ret = {}

	gaming_hammer_data.eggs_status[egg_no] = gaming_hammer_data.eggs_status[egg_no] + 1

	--local kaijiang_random = math.random() * 100
	--if kaijiang_random <= gaming_hammer_data.egg_open_rate or gaming_hammer_data.eggs_status[egg_no] == DATA.max_egg_open_num then
	if gaming_hammer_data.eggs_status[egg_no] >= gaming_hammer_data.eggs_open_status[egg_no] then
		--- 开奖了
		ret.kaijiang = PUBLIC.get_award_data( _d , _d.gaming_hammer_id , egg_no)

		--- 是否自己爆了
		local is_self_open = false
		for key,data in ipairs(ret.kaijiang) do
			gaming_hammer_data.eggs_status[data.egg_no] = -1
			if data.egg_no == egg_no then
				is_self_open = true
			end
		end
		if not is_self_open then
			--- 小偏差一点
			gaming_hammer_data.eggs_open_status[egg_no] = gaming_hammer_data.eggs_open_status[egg_no] + (math.random()<=0.33 and 1 or (math.random()>0.5 and 0 or -1)) 
			if gaming_hammer_data.eggs_open_status[egg_no] > DATA.max_egg_open_num then
				gaming_hammer_data.eggs_open_status[egg_no] = DATA.max_egg_open_num
			end

			gaming_hammer_data.eggs_open_status[egg_no] = gaming_hammer_data.eggs_open_status[egg_no] + gaming_hammer_data.eggs_status[egg_no]
		end
	end

	-- if is_spend_hammer then
		--gaming_hammer_data.hammer_num = gaming_hammer_data.hammer_num - 1
		--- 更新锤子数量
		--PUBLIC.set_zjd_hammer_num( _d.player_id , DATA.hammer_num_map[gaming_hammer_data.hammer_id] , gaming_hammer_data.hammer_num )
	-- end

	ret.game_data = gaming_hammer_data

	PUBLIC.off_action_lock( "za_jin_dan" , table_id)

	return ret
end

--- 换一波蛋
function CMD.replace_eggs(table_id , hammer_id , egg_no , is_spend_money)
	--- 操作限制
	if PUBLIC.get_action_lock("replace_eggs" , table_id) then
		return 1008
	end
	PUBLIC.on_action_lock( "replace_eggs" , table_id)

	local _d = game_table[table_id]

	--- 检查
	if not _d or hammer_id ~= _d.gaming_hammer_id then
		PUBLIC.off_action_lock( "replace_eggs" , table_id)
		return 1003
	end

	--- 换蛋的钱累积
	if is_spend_money then
		_d.hammer_game_data[hammer_id].replace_egg_spend = _d.hammer_game_data[hammer_id].replace_egg_spend + _d.hammer_game_data[hammer_id].replace_money
	end

	new_game( table_id , hammer_id , nil , is_spend_money )

	_d.hammer_game_data[hammer_id].eggs_status = {}
	_d.hammer_game_data[hammer_id].eggs_open_status = {}
	for i=1,DATA.total_eggs_num do
		_d.hammer_game_data[hammer_id].eggs_status[i] = 0

		_d.hammer_game_data[hammer_id].eggs_open_status[i] = math.random(1,DATA.max_egg_open_num)
	end

	local award_str = ""
	local ret = {}
	ret.award_list = {}
	for key,data in pairs(_d.hammer_game_data[hammer_id].award_data) do
		ret.award_list[#ret.award_list + 1] = data.id
		award_str = award_str .. data.award .. ","
	end

	--- 加轮数日志
	local now_round = skynet.call( DATA.service_config.data_service , "lua" , "add_player_zajindan_round_log" , _d.player_id , hammer_id , award_str)
	_d.hammer_game_data[hammer_id].round_id = now_round

	ret.game_data = _d.hammer_game_data[hammer_id]

	PUBLIC.off_action_lock( "replace_eggs" , table_id)
	return ret
end

--- 换锤子
function CMD.zjd_replace_hammer( table_id , new_hammer_id )
	--- 操作限制
	if PUBLIC.get_action_lock("zjd_replace_hammer" , table_id) then
		return 1008
	end
	PUBLIC.on_action_lock( "zjd_replace_hammer" , table_id)

	local _d = game_table[table_id]

	--- 检查
	if not _d or not _d.hammer_game_data[new_hammer_id] then
		PUBLIC.off_action_lock( "zjd_replace_hammer" , table_id)
		return 1003
	end

	_d.gaming_hammer_id = new_hammer_id

	local ret = {}
	ret.gaming_hammer_id = new_hammer_id

	PUBLIC.off_action_lock( "zjd_replace_hammer" , table_id)
	return ret

end

---- 回收桌子
function CMD.return_table(table_id)
	return_table(table_id)
end

--- 获取今日排行榜,所有人的排行榜都是一样的
function CMD.get_today_rank()
	local now_time = os.time()

	local today_id = PUBLIC.get_today_id()

	if not DATA.rank_data or not DATA.rank_cache_time then
		DATA.rank_data = skynet.call( DATA.service_config.data_service , "lua" , "get_zajindan_rank" , today_id , DATA.rank_show_num)
		DATA.rank_cache_time = now_time
	else
		if now_time - DATA.rank_cache_time > DATA.rank_cache_data_timeout then
			DATA.rank_data = skynet.call( DATA.service_config.data_service , "lua" , "get_zajindan_rank" , today_id , DATA.rank_show_num)
			DATA.rank_cache_time = now_time
		end
	end

	return DATA.rank_data 
end

--- 获取某人的日志
function CMD.get_zajindan_log(player_id)
	return skynet.call( DATA.service_config.data_service , "lua" , "get_zajindan_log" , player_id , DATA.max_zjd_show_num )
end

function CMD.start(_id,_ser_cfg,_config)
	math.randomseed(os.time()*1271)

	skynet.timer(18000, function()
		math.randomseed(os.time()*3271)
	end)

	DATA.service_config =_ser_cfg
	
	base.import("game/services/zajindan_room_service/zajindan_room_data.lua")

	DATA.table_count= DATA.one_room_table_num
	DATA.my_id=_id
	

	--init table
	for i=1,DATA.table_count do 
		table_list[#table_list+1] = i
	end

	--- 获得配置
	nodefunc.query_global_config("zajindan_service",function(config) 
		DATA.config = config
		--dump( DATA.config , "----------- zajindan_service,config:")
	end)

	---- 初始化 分解列表
	PUBLIC.init_resolve_award()

	---- 测试砸金蛋
	--[[skynet.timeout( 10*100 , function() 
		PUBLIC.test_zajindan()
	end )--]]
	

	skynet.fork(update)
	return 0
end















-- 启动服务
base.start_service()
