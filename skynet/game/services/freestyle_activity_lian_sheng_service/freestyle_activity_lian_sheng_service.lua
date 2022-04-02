--
-- Author: yy
-- Date: 2018/3/28
-- Time: 
-- 说明：连胜服务

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

local player_activity_data = nil

local player_activity_data_tmp = nil

local activity_config = nil

-- 玩家游戏进行数据 记录和判定 是否在活动时间内的数据
local player_activity_game_data = {}

local log = {}
local player_log = {}

local return_tbl = {result=0}

local return_aw_tbl = {result=0,award={}}


local function get_pad_db_data(_pad)
	return {
		cur_process = _pad.cur_process,
		round = _pad.round,
	}
end

local function get_pad_log_data(_pad)
	return cjson.encode({
		cur_process = _pad.cur_process,
		round = _pad.round,
	})
end

local function get_player_activity_award(_player_id,_broadcast)
	local pad = CMD.query_player_activity_data(_player_id)
	if pad and pad.cur_process>0 and pad.round<activity_config.max_round then
		
		local ai = math.min(pad.cur_process,activity_config.max_process)
		return_aw_tbl.award = activity_config.award[ai]

		if _broadcast and return_aw_tbl.award then

			local name = skynet.call(DATA.service_config.data_service,"lua",
						"get_player_info",_player_id,"player_info","name")
			if name then
				name = basefunc.short_player_name(name)
				skynet.send(DATA.service_config.broadcast_center_service,"lua",
							"fixed_broadcast","freestyle_activity_lshd_award"
							,name,DATA.base_config.game_name,pad.cur_process,activity_config.broadcast[ai] or "大奖")
			end
				
		end


		if return_aw_tbl.award then
			pad.round = pad.round + 1
			pad.cur_process = 0

			return_aw_tbl.activity_data = pad

			skynet.send(DATA.service_config.freestyle_activity_center_service,"lua"
							,"update_freestyle_activity_player_data"
							,_player_id
							,DATA.base_config.game_id
							,DATA.base_config.activity_id
							,DATA.base_config.index
							,get_pad_db_data(pad))

			return return_aw_tbl
		end
	end

	return_tbl.result = 4401
	return return_tbl
end

-- 活动已经启动
local function start_activity()
	-- 通知所有玩家活动启动了

	local num = math.floor(send_everyone_limit / 100)

	skynet.fork(function ()
		
		local player_status_list = skynet.call(DATA.service_config.data_service,"lua","get_player_status_list")

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

	-- skynet.send(DATA.service_config.broadcast_center_service,"lua",
	-- 				"fixed_broadcast","freestyle_activity_lshd_begin")

end


local function end_activity()

	log.end_time = os.time()

end


local function over_activity()
	
	-- 强行发放奖励
	local player_status_list = skynet.call(DATA.service_config.data_service,"lua","get_player_status_list")

	local sn = 0
	local num = math.floor(send_everyone_limit / 100)

	local email = 
	{
		type = "freestyle_activity_award",
		title = "匹配场活动奖励",
		sender = "系统",
		data = {},
	}

	--发给所有玩家
	for player_id,data in pairs(player_status_list) do
		if basefunc.chk_player_is_real(player_id) then
			
			local pad = player_activity_data[player_id]
			local pad_json = nil

			if pad and (pad.cur_process>0 or pad.round>0) then
				log.player_num = log.player_num + 1

				pad_json = get_pad_log_data(pad)

			end

			-- print("over_check_awd"..player_id.."++++++")
			local paa = get_player_activity_award(player_id)

			if paa.award then
				
				log.finish_num = log.finish_num + 1

				player_log.player_id = player_id
				player_log.time = os.time()
				player_log.activity_data = pad_json
				player_log.award = cjson.encode(paa.award)
				skynet.send(DATA.service_config.data_service,"lua","insert_freestyle_activity_player_log",player_log)

				--发送活动奖励
				email.receiver = player_id
				email.data = 
				{
					game_id = DATA.base_config.game_id,
					activity_id = DATA.base_config.activity_id,
					asset_change_data = {
						change_type = ASSET_CHANGE_TYPE.FREESTYLE_ACTIVITY_AWARD,
						change_id = activity_config.name_tag.."_"..pad.round,
					}
				}
				for i,aw in ipairs(paa.award) do
					email.data[aw.asset_type] = aw.value
				end

				-- dump(email,"email+++++++++")

				skynet.send(DATA.service_config.email_service,"lua","send_email",email)

			end

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
	log.activity_data = basefunc.safe_serialize({ player_num = log.player_num , finish_num = log.finish_num })
	dump(log.activity_data , "--------------liansheng, log.activity_data:")

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

	if not cfg then
		print("error : load_activity_config  config is not found ")
		skynet.fail("error : load_activity_config config is not found ===> game_id : ".. DATA.base_config.game_id)
	end

	activity_config.max_round = cfg.max_round
	activity_config.name_tag = cfg.name_tag
	activity_config.max_process = #cfg.process_award

	local broadcast = {}
	for i,b in ipairs(raw_config.boardcast) do
		broadcast[b.id]=b.content
	end

	local award = {}
	for i,a in ipairs(raw_config.award) do
		local aw = award[a.id] or {}
		award[a.id] = aw
		aw[#aw+1] = a
		a.id = nil
		a.no = nil
	end

	activity_config.award = {}
	activity_config.broadcast = {}
	for i,ai in ipairs(cfg.process_award) do
		activity_config.award[i] = award[ai]
		activity_config.broadcast[i] = broadcast[ai]
	end

	-- dump(activity_config,"activity_config+++++++++++++")
end

-- 初始化数据
local function init_data()

	-- 应当启动服务的第一时间就去请求数据 过一会儿可能就被清空了
	player_activity_data = skynet.call(DATA.service_config.freestyle_activity_center_service,"lua"
										,"query_freestyle_activity_player_data"
										,DATA.base_config.game_id
										,DATA.base_config.activity_id
										,DATA.base_config.index)

	player_activity_data = player_activity_data or {}
	
	for k,d in pairs(player_activity_data) do
		d.service_id = DATA.my_id
		d.game_id = DATA.base_config.game_id
		d.activity_id = DATA.base_config.activity_id
		d.name_tag = activity_config.name_tag
		d.max_process = activity_config.max_process
		d.max_round = activity_config.max_round
	end


	player_activity_data_tmp = {
		service_id = DATA.my_id,
		game_id = DATA.base_config.game_id,
		activity_id = DATA.base_config.activity_id,
		name_tag = activity_config.name_tag,
		cur_process = 0,
		max_process = activity_config.max_process,
		round = 0,
		max_round = activity_config.max_round,
	}

	log.id = skynet.call(DATA.service_config.data_service,"lua","get_freestyle_activity_log_id")
	log.game_id = DATA.base_config.game_id
	log.activity_id = DATA.base_config.activity_id
	log.name = DATA.base_config.name
	log.begin_time = 0
	log.end_time = 0
	log.start_time = os.time()
	log.player_num = 0
	log.finish_num = 0

	refresh_data()
	
	player_log.game_id = DATA.base_config.game_id
	player_log.activity_id = DATA.base_config.activity_id
	player_log.name = DATA.base_config.name

end

local function update(dt)
	
	update_status()

end


function CMD.reload_config(_cfg)
	
	DATA.base_config = _cfg

	refresh_data()

	return 0
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
						cur_process = 0,
						max_process = activity_config.max_process,
						round = 0,
						max_round = activity_config.max_round,
					}

	player_activity_data[_player_id] = pad

	-- dump(pad,_player_id.."query-pad++++++++++")

	return pad

end


--[[ 游戏 开始 和 完成 时 调用
	进行 刷新一下数据
	开始的时候不穿 score 
	结束的时候传入 score
]]
function CMD.update_activity_data(_player_id,_game_id,_score)
	local pad = CMD.query_player_activity_data(_player_id)

	if pad.round < activity_config.max_round then

		if not _score then

			if DATA.status == "begin" then
				
				player_activity_game_data[_player_id] = 1

			end

		else

			if player_activity_game_data[_player_id] == 1 then

				if _score > 0 then
					pad.cur_process = pad.cur_process + 1
				elseif _score < 0 then
					pad.cur_process = 0
				end

				if _score ~= 0 then
					skynet.send(DATA.service_config.freestyle_activity_center_service,"lua"
								,"update_freestyle_activity_player_data"
								,_player_id
								,DATA.base_config.game_id
								,DATA.base_config.activity_id
								,DATA.base_config.index
								,get_pad_db_data(pad))
				end

			end
			
			player_activity_game_data[_player_id] = nil

		end

	end
	
	-- dump(pad,_player_id.."-pad++++++++++",_score)

	return pad
end


--[[ 清除数据
]]
function CMD.reset_activity_data(_player_id,_game_id)
	local pad = CMD.query_player_activity_data(_player_id)

	-- 活动进行中才清除
	if DATA.status == "begin" then

		pad.cur_process = 0

		skynet.send(DATA.service_config.freestyle_activity_center_service,"lua"
					,"update_freestyle_activity_player_data"
					,_player_id
					,DATA.base_config.game_id
					,DATA.base_config.activity_id
					,DATA.base_config.index
					,get_pad_db_data(pad))

	end
	
	-- dump(pad,_player_id.."-reset+++++++++++++")
	return pad
end


function CMD.get_activity_award(_player_id)

	local pad = CMD.query_player_activity_data(_player_id)
	local pad_json = get_pad_log_data(pad)
	local ret = get_player_activity_award(_player_id,true)

	if ret.result==0 then
		log.finish_num = log.finish_num + 1
		
		player_log.player_id = _player_id
		player_log.time = os.time()
		player_log.activity_data = pad_json
		player_log.award = cjson.encode(ret.award)
		ret.log_id = log.id

		skynet.send(DATA.service_config.data_service,"lua","insert_freestyle_activity_player_log",player_log)
	end

	return ret
end


--------------------------------------------------------------------------------------------------
--------------------------------------------CMD---------------------------------------------------


function CMD.start(_id,_service_config,_base_config)

	math.randomseed(os.time()*728415)

	DATA.service_config = _service_config
	DATA.my_id = _id
	DATA.base_config = _base_config

	nodefunc.query_global_config(DATA.base_config.config_name,load_activity_config)

	init_data()

	skynet.timer(UPDATE_INTERVAL,update)

end

-- 启动服务
base.start_service()
