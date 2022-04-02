--
-- Author: yy
-- Date: 2018/3/28
-- Time: 
-- 说明：天降财神服务

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "ddz_match_enum"
require "normal_enum"
require "printfunc"

local cjson = require "cjson"

--启用数组稀疏后自动转换为字符串索引
cjson.encode_sparse_array(true,1,0)


local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

-- 每秒发送限制
local send_everyone_limit = 1000

local UPDATE_INTERVAL = 1

local player_activity_data = {}

local player_activity_data_tmp = nil

local activity_config = nil

-- 游戏
local manager_service_id = nil

-- 广播时间
local broadcast_time = 10
-- 广播列表
local broadcast_data = {}

-- 玩家游戏进行数据 记录和判定 是否在活动时间内的数据
DATA.player_activity_game_data = {}

--- 房间财神数据
DATA.room_caishen_data = {}

-- 房间座位的数据 位置上的人走没有
DATA.room_seat_data = {}

DATA.target_caishen_award = {}

---- 财神赢的特殊奖励
DATA.caishen_win_award = {}

--- 是否下一次创建财神
DATA.next_caishen_data = nil

local log = {}
local player_log = {}
local player_activity_data_log = {}

local return_tbl = {result=0}

local return_aw_tbl = {result=0,award={}}

local game_count = 0
local cai_shen_num = 0


-- 活动已经启动
local function start_activity()
	-- 通知所有玩家活动启动了

	local num = math.floor(send_everyone_limit / 100)

	skynet.fork(function ()
		
		local player_status_list = skynet.call(DATA.service_config.data_service,"lua","get_real_player_status_list")
		dump(player_status_list , "xxxxxxxxxxx----------- tianjiangcaisheng_start")
		local sn = 0

		--发在线的玩家
		for player_id,data in pairs(player_status_list) do
			if data.status == "on" and basefunc.chk_player_is_real(player_id) then
				
				--发送活动状态数据
				nodefunc.send(player_id,"start_freestyle_activity",player_activity_data[player_id] or player_activity_data_tmp)

				sn = sn + 1
				if sn > num then
					skynet.sleep(1)
					sn = 0
				end

			end
		end

	end)

end

local function begin_activity()

	log.begin_time = os.time()


end


local function end_activity()

	log.end_time = os.time()

	
end


local function over_activity()
	
	-- 强行发放奖励
	local player_status_list = skynet.call(DATA.service_config.data_service,"lua","get_player_status_list")

	local sn = 0
	local num = math.floor(send_everyone_limit / 100)

	--发给所有玩家
	for player_id,data in pairs(player_status_list) do
		if basefunc.chk_player_is_real(player_id) then
			
			if data.status == "on" then
				
				--发送活动销毁了
				nodefunc.send(player_id,"over_freestyle_activity"
									,DATA.base_config.game_id
									,DATA.base_config.activity_id
									,DATA.base_config.index)

			end

			sn = sn + 1
			if sn > num then
				skynet.sleep(1)
				sn = 0
			end

		end
	end

	-- 通知结束
	skynet.send(DATA.service_config.freestyle_activity_center_service,"lua"
						,"activity_service_destory"
						,DATA.my_id)



	-- 记录日志
	log.over_time = os.time()
	local activity_data_table = { caishen_show_num = log.caishen_show_num }
	for key,asset_type in pairs(PLAYER_ASSET_TYPES) do
		if log[asset_type] then
			activity_data_table[asset_type] = log[asset_type]
		end
	end

	log.activity_data = basefunc.safe_serialize(activity_data_table)
	dump(log.activity_data , "--------------caishen, log.activity_data:")

	skynet.send(DATA.service_config.data_service,"lua","insert_freestyle_activity_log",log)

	skynet.sleep(200)

	nodefunc.destroy(DATA.my_id)

	skynet.sleep(200)

	skynet.exit()

end


local function update_status()
	
	local time = os.time()

	if time < DATA.begin_activity_time then
		
		if DATA.status ~= "wait" then
			DATA.status = "wait"
			-- 活动启动
			start_activity()
		end

	elseif time >= DATA.begin_activity_time and time < DATA.end_activity_time then
		
		if DATA.status ~= "begin" then
			DATA.status = "begin"
			begin_activity()
		end

	elseif time >= DATA.end_activity_time and time < DATA.over_activity_time then
		
		if DATA.status ~= "end" then
			DATA.status = "end"
			end_activity()
		end

	else

		if DATA.status ~= "over" then
			DATA.status = "over"
			over_activity()
		end

	end

end


local function refresh_data()

	local wet = basefunc.get_week_elapse_time()
	local time = os.time()
	-- 活动开始
	DATA.begin_activity_time = time + DATA.base_config.begin_time - wet

	-- 活动结束
	DATA.end_activity_time = time + DATA.base_config.end_time - wet

	-- 活动完全销毁
	DATA.over_activity_time = time + DATA.base_config.over_time - wet

	update_status()
	
end

local function load_activity_config(_raw_config)
	local raw_config = basefunc.deepcopy(_raw_config)
	activity_config = {}

	local cfg = nil
	for i,c in ipairs(raw_config.main) do
		if c.game_id == DATA.base_config.game_id then
			cfg = c
			break
		end
	end

	--- 财神赢了的特殊奖励的配置
	local caishen_win_random_award = {}
	if raw_config.caishen_win_random_award then
		for key , data in pairs(raw_config.caishen_win_random_award) do
			caishen_win_random_award[data.id] = data
		end
	end

	if not cfg then
		print("error : load_activity_config  config is not found ")
		skynet.fail("error : load_activity_config config is not found ===> game_id : ".. DATA.base_config.game_id)
	end

	activity_config.round = cfg.round
	activity_config.name_tag = cfg.name_tag

	local award = {}
	for i,a in ipairs(raw_config.award) do
		local aw = award[a.id] or {}
		award[a.id] = aw
		aw[#aw+1] = a
		a.id = nil
		a.no = nil
	end

	activity_config.award = basefunc.deepcopy( award[cfg.award] )
	if cfg.win_award and type(cfg.win_award) == "number" and caishen_win_random_award[cfg.win_award] then
		activity_config.caishen_win_random_award = basefunc.deepcopy( caishen_win_random_award[cfg.win_award] )
	else
		activity_config.caishen_win_random_award = nil
	end


	dump(activity_config.award,"activity_config.award+++++++++++++")
end

-- 初始化数据
local function init_data()

	local game_map = skynet.call(DATA.service_config.freestyle_game_center_service,"lua","get_game_map")
	manager_service_id = game_map[DATA.base_config.game_id].service_id

	player_activity_data_tmp = {
		service_id = DATA.my_id,
		game_id = DATA.base_config.game_id,
		activity_id = DATA.base_config.activity_id,
		name_tag = activity_config.name_tag,
		room_id = 0,
		table_num = 0,
		--cs_seat = 0,
		--cs_player_id = 0,
		--cs_is_win = 0,
	}

	log.id = skynet.call(DATA.service_config.data_service,"lua","get_freestyle_activity_log_id")
	log.game_id = DATA.base_config.game_id
	log.activity_id = DATA.base_config.activity_id
	log.name = DATA.base_config.name
	log.begin_time = 0
	log.end_time = 0
	log.start_time = os.time()
	log.caishen_show_num = 0    --- 财神出现的次数
	--- log[asset_type] = 0     --- 财神奖励的资产类型
	

	refresh_data()
	
	player_log.game_id = DATA.base_config.game_id
	player_log.activity_id = DATA.base_config.activity_id
	player_log.name = DATA.base_config.name

end

local function broadcast_update()
	
	local t = os.time()
	for k,d in pairs(broadcast_data) do
		
		if d.time < t then
			d.func()
			broadcast_data[k] = nil
		end

	end

end


local function update(dt)
	
	update_status()

	broadcast_update()

end


function CMD.reload_config(_cfg)

	DATA.base_config = _cfg

	refresh_data()

	return 0
end


--------------------------------------------------------------------------------------------------
--------------------------------------------CMD---------------------------------------------------

-- 产生财神座位号
local function create_cai_shen(_seat_count)
	log.caishen_show_num = log.caishen_show_num + 1

	if cai_shen_num > 0 then
		cai_shen_num = cai_shen_num - 1
		return math.random(1,_seat_count)
	end

	return 0

end

-- 游戏开始
function CMD.player_game_begin( _room_id , _table_num , _seat_num , _player_count , _player_id)
	--print("xxxxxxxxx----player_game_begin", DATA.status ,_room_id , _table_num , _seat_num , _player_count , _player_id)
	if DATA.status == "begin" then	
		DATA.player_activity_game_data[_player_id] = 1
	else
		return
	end

	player_activity_data[_player_id] = nil
	local pad = CMD.query_player_activity_data(_player_id)

	----- 开局数增加
	if not DATA.room_caishen_data[ _room_id.."_".._table_num ] then
		DATA.room_caishen_data[ _room_id.."_".._table_num ] = {}
		-- game_count = game_count + 1
	end
	
	--dump(DATA.next_caishen_data,"xxxxxxxxxx------DATA.next_caishen_data")
	-------------------
	local k = _room_id.."_".._table_num

	if DATA.next_caishen_data 
		and (not DATA.next_caishen_data.condition_do
				or DATA.next_caishen_data.condition_do ~= _room_id.."_".._table_num
			)then
		--print("xxxxxxxxxxx----------------- create_cai_shen")
		DATA.room_caishen_data[ _room_id.."_".._table_num ] = { 
			caishen_seat = create_cai_shen(_player_count),
			player_count = _player_count,
		}

		
		DATA.room_seat_data[k] = {}

		local rsd = DATA.room_seat_data[k]
		-- DATA.room_seat_data[k] = rsd
		for i=1,_player_count do
			rsd["seat_"..i] = 1
		end
		

		DATA.next_caishen_data = nil

		---- 根据权重确定发的是哪一个奖励
		local target_award = nil
		local total_power = 0
		for key,award_data in pairs(activity_config.award) do
			total_power = total_power + award_data.rate
		end
		local random = math.random()*total_power
		local now_power = 0
		for key,award_data in pairs(activity_config.award) do
			now_power = now_power + award_data.rate
			if random <= now_power then
				target_award = award_data
				break
			end
		end
		DATA.target_caishen_award[ _room_id.."_".._table_num ] = target_award


		----财神赢了随机一下特殊奖励。
		if activity_config.caishen_win_random_award and activity_config.caishen_win_random_award.get_rate then

			local random = math.random() * 100
			if random < activity_config.caishen_win_random_award.get_rate then
				DATA.caishen_win_award[ _room_id.."_".._table_num ] = { asset_type = activity_config.caishen_win_random_award.asset_type , value = activity_config.caishen_win_random_award.value }
			else
				DATA.caishen_win_award[ _room_id.."_".._table_num ] = nil
			end

		else
			DATA.caishen_win_award[ _room_id.."_".._table_num ] = nil
		end
		dump(DATA.caishen_win_award , "------------------DATA.caishen_win_award")
	end
	--------------- 如果有 在房间在位数据，给每个来这个桌上的人同步数据
	local rsd = DATA.room_seat_data[k]
	if rsd then
		rsd.player_num = (rsd.player_num or 0) + 1
		for key,data in pairs(rsd) do
			if key ~= "player_num" then
				pad[key] = data
			end
		end
	end

	local room_cs_data = DATA.room_caishen_data[ _room_id.."_".._table_num ]
	local caishen_seat = nil
	
	pad.room_id = _room_id
	pad.table_num = _table_num

	local is_have_cs = false
	
	if room_cs_data and room_cs_data.caishen_seat then
		is_have_cs = true
		
		pad.cs_seat = room_cs_data.caishen_seat
		--pad.cs_player_id = room_cs_data.caishen_player_id
		--room_cs_data.player_count = room_cs_data.player_count - 1

		caishen_seat = room_cs_data.caishen_seat

		--if room_cs_data.player_count <= 0 then
		--	DATA.room_caishen_data[ _room_id.."_".._table_num ] = nil
		--end
	end


	--- 每个真人来都加1
	game_count = game_count + 1
	
	--print("xxxxxxxxx----game_count:",game_count,activity_config.round)

	if game_count >= activity_config.round then
		
		game_count = 0

		cai_shen_num = cai_shen_num + 1

		--DATA.room_caishen_data[ _room_id.."_".._table_num ] = { caishen_seat = create_cai_shen(_player_count) , player_count = _player_count }
		
		DATA.next_caishen_data = {condition_do = _room_id.."_".._table_num} -- true -- {  caishen_seat = create_cai_shen(_player_count) }
		
	end


	return pad , is_have_cs

end

-------------


---- 玩家对局结束
function CMD.player_game_complete(_player_id, _settle_data_real_scores , _seat_num , _player_count,_players_info)
	local pad = CMD.query_player_activity_data(_player_id)

	local target_award = DATA.target_caishen_award[ pad.room_id.."_"..pad.table_num ]

	if DATA.room_caishen_data[ pad.room_id.."_"..pad.table_num ] then
		--DATA.room_seat_data[k] = nil

		DATA.room_caishen_data[ pad.room_id.."_"..pad.table_num ] = nil
	end


	------------------------------------------------------ 每离开一个人清空其在位数据
	local k = pad.room_id.."_"..pad.table_num
	local rsd = DATA.room_seat_data[k]
	if rsd then
		if not _settle_data_real_scores then
			rsd["seat_".._seat_num] = 0
		end

		rsd.player_num = (rsd.player_num or 0) - 1

		---- 同步 请求人 的pad数据
		for key,data in pairs(rsd) do
			if key ~= "player_num" then
				pad[key] = data
			end
		end

		if rsd.player_num == 0 then
			DATA.room_seat_data[k] = nil
		end
	end

	--dump(DATA.next_caishen_data,"xxxxxxxxxx------player_game_complete,,DATA.next_caishen_data")
	--print("xxxxxxxxxx------pad.room_id_pad.table_num",pad.room_id.."_"..pad.table_num)

	if DATA.next_caishen_data 
		and DATA.next_caishen_data.condition_do == pad.room_id.."_"..pad.table_num then
			DATA.next_caishen_data.condition_do = nil
	end
	
	---- 玩家提前离桌，不能领到奖励
	if _settle_data_real_scores and DATA.player_activity_game_data[_player_id] == 1 and target_award then
		
		local cs_score = false
		if _settle_data_real_scores and type(_settle_data_real_scores) == "table" then
			cs_score = pad.cs_seat and _settle_data_real_scores[pad.cs_seat] or 0
		end

		if cs_score and pad.cs_seat then
			if cs_score > 0 then
				pad.cs_is_win = 1 

				
				pad[target_award.asset_type] = target_award.value

				--- 如果有财神赢了的特殊奖励,给每个人同步数据
				local caishen_win_data = DATA.caishen_win_award[ pad.room_id.."_"..pad.table_num ] 
				if caishen_win_data then
					pad["spec_award_" .. caishen_win_data.asset_type] = caishen_win_data.value
				end

				dump(_players_info , "-----------------------tianjiangcaisheng_players_info")
				--- 发特殊奖的广播准备
				if caishen_win_data 
					and pad["spec_award_" .. caishen_win_data.asset_type]
					and type(_players_info) == "table"
					and not broadcast_data[pad.room_id.."_"..pad.table_num] then

					local cs_name = nil
					for i,d in ipairs(_players_info) do
						if d.seat_num == pad.cs_seat then
							cs_name = d.name
						end
					end

					--if cs_name then

						--- 广播
						--local name = skynet.call(DATA.service_config.data_service,"lua",
						--			"get_player_info",cs_id,"player_info","name")
						if cs_name then
							cs_name = basefunc.short_player_name(cs_name)
							print("------------------cs_name:",cs_name)
							local broadcast_award_name = activity_config.caishen_win_random_award.broadcast and (activity_config.caishen_win_random_award.broadcast.."*"..caishen_win_data.value) or "大奖"
							
							local broadcast_func = function ()
								skynet.send(DATA.service_config.broadcast_center_service,"lua",
										"fixed_broadcast","freestyle_activity_tjcs_win_award", cs_name
										,DATA.base_config.game_name, broadcast_award_name )
							end

							broadcast_data[pad.room_id.."_"..pad.table_num] = {
								time = os.time() + broadcast_time,
								func = broadcast_func,
							}

						end

					--end

				end

				---- 资产改变
				if pad.cs_seat == _seat_num then
					--- 日志数据 ， 只有发奖的人才会记日志
					log[target_award.asset_type] = log[target_award.asset_type] or 0
					log[target_award.asset_type] = log[target_award.asset_type] + pad[target_award.asset_type]

					--- 发特殊奖
					if caishen_win_data and pad["spec_award_" .. caishen_win_data.asset_type] then --pad["caishen_win_asset_type"] and pad["caishen_win_asset_value"] then
						---- 记日志
						local caishen_win_asset_type = caishen_win_data.asset_type

						log["caishen_win_"..caishen_win_asset_type] = log["caishen_win_"..caishen_win_asset_type] or 0
						log["caishen_win_"..caishen_win_asset_type] = log["caishen_win_"..caishen_win_asset_type] 
																		+ pad["spec_award_" .. caishen_win_data.asset_type]
						--- 资产改变
						nodefunc.send(_player_id,"change_asset_multi" , 
										{[1] = caishen_win_data} 
										, ASSET_CHANGE_TYPE.FREESTYLE_ACTIVITY_AWARD 
										, DATA.base_config.activity_id .."_"..log.id )
						--
					end

					nodefunc.send(_player_id,"change_asset_multi" , {[1] = target_award} , ASSET_CHANGE_TYPE.FREESTYLE_ACTIVITY_AWARD , DATA.base_config.activity_id .."_"..log.id )

					player_activity_data_log.cs_is_win = pad.cs_is_win
					player_activity_data_log.cs_seat = pad.cs_seat
					player_activity_data_log.my_seat = _seat_num

					player_log.player_id = _player_id
					player_log.time = os.time()
					player_log.activity_data = cjson.encode(player_activity_data_log)
					player_log.award = cjson.encode( {[1] = target_award} )

					skynet.send(DATA.service_config.data_service,"lua","insert_freestyle_activity_player_log",player_log)

				end

			else
				---- 奖励平分
				pad.cs_is_win = 0

				local new_award_data = {}
				--[[for key,award_data in pairs(activity_config.award) do
					pad[award_data.asset_type] = math.floor(award_data.value / _player_count)
					new_award_data[#new_award_data + 1] = { asset_type = award_data.asset_type , value = pad[award_data.asset_type] }

					--- 日志数据
					log[award_data.asset_type] = log[award_data.asset_type] or 0
					log[award_data.asset_type] = log[award_data.asset_type] + pad[award_data.asset_type]
				end--]]

				pad[target_award.asset_type] = math.floor(target_award.value / _player_count)
				new_award_data[#new_award_data + 1] = { asset_type = target_award.asset_type , value = pad[target_award.asset_type] }

				--- 日志数据
				log[target_award.asset_type] = log[target_award.asset_type] or 0
				log[target_award.asset_type] = log[target_award.asset_type] + pad[target_award.asset_type]

				---- 资产改变
				nodefunc.send(_player_id,"change_asset_multi" , 
					new_award_data ,
					ASSET_CHANGE_TYPE.FREESTYLE_ACTIVITY_AWARD , DATA.base_config.activity_id .."_"..log.id )

				player_activity_data_log.cs_is_win = pad.cs_is_win
				player_activity_data_log.cs_seat = pad.cs_seat
				player_activity_data_log.my_seat = _seat_num

				player_log.player_id = _player_id
				player_log.time = os.time()
				player_log.activity_data = cjson.encode(player_activity_data_log)
				player_log.award = cjson.encode({[1] = new_award_data})

				skynet.send(DATA.service_config.data_service,"lua","insert_freestyle_activity_player_log",player_log)

			end
		end
	end

	DATA.player_activity_game_data[_player_id] = nil

	dump(pad , "xxxxxxxxxxx------------------player_game_complete   pad")

	return pad
end

------- 退出游戏
function CMD.player_game_quit(_player_id,_seat_num,_room_id,_table_num)

	player_activity_data[_player_id] = nil

	local pad = CMD.query_player_activity_data(_player_id)
	return pad
end


--------------------------------------------------------------------------------------------------
--------------------------------------------CMD---------------------------------------------------
function CMD.query_player_activity_data(_player_id)
	local pad = player_activity_data[_player_id] or
					{
						service_id = DATA.my_id,
						game_id = DATA.base_config.game_id,
						activity_id = DATA.base_config.activity_id,
						name_tag = activity_config.name_tag,
						room_id = 0,
						table_num = 0,
						--cs_seat = 0,
						--cs_player_id = 0,
						--cs_is_win = 0,
					}

	player_activity_data[_player_id] = pad

	return pad

end

function CMD.start(_id,_service_config,_base_config)

	math.randomseed(os.time()*7528415)

	DATA.service_config = _service_config
	DATA.my_id = _id
	DATA.base_config = _base_config

	nodefunc.query_global_config(DATA.base_config.config_name,load_activity_config)

	init_data()

	skynet.timer(UPDATE_INTERVAL,update)

	print("xxxxxxxxxxxxx----------------------------- tianjiangcaisheng_start ")

end

-- 启动服务
base.start_service()
