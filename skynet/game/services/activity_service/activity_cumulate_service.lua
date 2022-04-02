--- 累胜 活动 服务

local skynet = require "skynet_plus"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "normal_enum"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

DATA.my_id = nil

DATA.game_id = nil

--- 活动的起始时间
DATA.start_time = nil

--- 活动的结束时间
DATA.end_time = nil

--- 活动配置
DATA.activity_config = nil

--- 活动数据,key = player_id
DATA.activity_data = {}

--- 玩家数据
DATA.player_data = {}

--- 载入所有玩家数据
local function load_all_player_data()
	local data = skynet.call( DATA.service_config.data_service , "lua" , "query_all_player_activity_cumulate_data" )
	
	local delete_vec = {}
	---启动的时候去掉不在这个时间段的数据
	for player_id,player_data in pairs(data) do
		if player_data.time < DATA.start_time or player_data.time > DATA.end_time then
			delete_vec[#delete_vec + 1] = player_id
		end
	end

	for key,player_id in pairs(delete_vec) do
		data[player_id] = nil
	end

	DATA.player_data = data
end

--- 
local function add_or_update_data(player_id)
	assert(DATA.player_data[_player_id] , "must have DATA.player_data[_player_id]")
	skynet.call( DATA.service_config.data_service , "lua" , "add_or_update_activity_cumulate_data"
		,DATA.player_data[_player_id].player_id
		,DATA.player_data[_player_id].game_id
		,DATA.player_data[_player_id].progress
		,DATA.player_data[_player_id].time
		)
end

--- 请求一个玩家的活动数据
function CMD.query_player_data(_player_id)
	local data = DATA.player_data[_player_id]
	if not data then
		DATA.player_data[_player_id] = { player_id = _player_id , game_id = DATA.game_id , progress = 0 , time = os.time() }
		data = DATA.player_data[_player_id]

		add_or_update_data(_player_id)
	end

	
	return data
end

--- 处理关闭
function PUBLIC.deal_close_service()

end

function CMD.start(_id,_ser_cfg , game_id , _start_time , _end_time ,_config )
	math.randomseed(os.time()*72453) 
	DATA.service_config =_ser_cfg
	
	DATA.my_id = _id

	DATA.game_id = game_id
	
	DATA.start_time = _start_time

	DATA.end_time = _end_time

	DATA.activity_config = _config

	load_all_player_data()

	--- 延迟 时间 结束
	skynet.timeout( (DATA.end_time - DATA.start_time) * 100, function()
		PUBLIC.deal_close_service()
	end)

	return 0
end





-- 启动服务
base.start_service()
