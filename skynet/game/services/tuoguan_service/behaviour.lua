--
-- Author: lyx
-- Date: 2018/10/9
-- Time: 15:14
-- 说明：玩家行为 逻辑
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
require"printfunc"
local nodefunc = require "nodefunc"

local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC

local PROTECTED = {}

local MONITOR = {}

DATA.behaviour_data = DATA.behaviour_data or {
	--[[
		配置： tuoguan_interaction 的内容
	--]]
	tuoguan_interaction = nil,

	-- 查找表：操作分组 => "general"/"good"/"super"
	operation_group_map = nil,

	-- 感情色彩定义 (mood)
	mood = 
	{
		happy = 0, -- 高兴
		angry = 1, -- 生气
		urge = 2, -- 催促
		dis_urge = 3, -- 反催促
		active = 4, -- 主动
		interaction_happy = 5, -- 互动高兴
		interaction_angry = 6, -- 互动生气
	},

	-- 互动短语映射： mood => 短语id数组
	mood2chat_map = nil,

	-- 互动短语映射： 短语id => mood
	chat2mood_map = nil,

	-- 互动短语映射： id => 配置
	chat_map = nil,

	-- 自己的角色： tuoguan_interaction.role 中的一项
	my_role  = nil,

	-- 地主
	cur_dizhu_seat = nil,

	-- 上次互发表情： 玩家id，时间
	last_intera_player_id = nil,
	last_intera_time = 0,

	last_permit_p = nil,
	last_permit_time = nil,
	last_urge_timeout = nil,

	is_init = false,
	update_time = nil,
}

local D = DATA.behaviour_data


local function trans_op_group(_cfg)
	for _name,_data in pairs(_cfg) do
		for _,_v in ipairs(_data) do
			if D.operation_group_map[_v] then
				print(string.format("tuoguan_interaction.lua config error:%s,%s conflict!",tostring(_name),tostring(_v)))
			end
			D.operation_group_map[_v] = _name
		end
	end

	D.tuoguan_interaction = _cfg
end

local function send_chat(_player_id,_id,_t1,_t2)
	skynet.timeout(math.random(_t1 or 100,_t2 or 300),function()
		local _send_data = {
			parm = tostring(_id),
		}
		if D.chat_map and D.chat_map[_id] and D.chat_map[_id].type == 2 then
			_send_data.act_apt_player_id = _player_id
		end

		PUBLIC.send_to_agent("send_player_easy_chat",_send_data)	
	end)
end

local function clear_urge_info()
	D.last_permit_p = nil
end

local function set_urge_info(_p)
	D.last_permit_p = _p
	D.last_permit_time = os.time()
	D.last_urge_timeout = math.random(D.my_role.urge_timeout[1],D.my_role.urge_timeout[2])
end

local function update()

	if D.last_permit_p and (os.time() - D.last_permit_time > D.last_urge_timeout) then

		if math.random(100) <= D.my_role.urge_prob then
			local _id = basefunc.random_select(D.mood2chat_map[D.mood.urge])
			if DATA.players_info and D.last_permit_p and DATA.players_info[D.last_permit_p] then
				send_chat(DATA.players_info[D.last_permit_p].id,_id,0,0)
			else
				print("behaviour send chat error:",DATA.players_info,D.last_permit_p)
			end
		end

		-- 本次概率已经使用 ，清除数据
		clear_urge_info()
	end

end

function PROTECTED.on_destroy()

	if D.update_time then
		D.update_time:stop()
	end

	nodefunc.clear_global_config_cb("tuoguan_interaction")
	nodefunc.clear_global_config_cb("player_Interaction")

	D.is_init = false
end

function PROTECTED.on_load()
end

function PROTECTED.init()
	
	if D.is_init then
		return
	end

	-- 加载 托管 交互配置
	nodefunc.query_global_config("tuoguan_interaction",function(_data)

		D.operation_group_map = {}
		trans_op_group(_data.operation_group)

		D.my_role = basefunc.random_select(_data.role,"count_percent")
		if not D.my_role then
			error("tuoguan_interaction config error: do not select role!")
		end
	end)

	-- 加载交互指令配置
	nodefunc.query_global_config("player_Interaction",function(_data)

		D.chat_map = {}
		D.mood2chat_map = {}
		D.chat2mood_map = {}

		for i,v in pairs(_data.Sheet1) do

			if type(v.mood) == "number" then
				local _moods = D.mood2chat_map[v.mood] or {} 

				D.mood2chat_map[v.mood] = _moods
				_moods[#_moods + 1] = v.item_id
				D.chat2mood_map[v.item_id] = v.mood
			end

			D.chat_map[v.item_id] = v
		end
		
	end)

	update_time = skynet.timer(1,update)
	
	D.is_init = true
end

-- 是否斗地主的 队友
local function ddz_is_teammate(_seat)
	return D.cur_dizhu_seat ~= DATA.room_info.seat_num and D.cur_dizhu_seat ~= _seat
end

-- 斗地主 产生地主
function MONITOR.nor_ddz_nor_dizhu_msg(_data)
	D.cur_dizhu_seat = _data.dz_info.dizhu
end


-- 根据 action 操作，处理 发表情
local function deal_chat_on_action(_op_type,_tar_seat)

	-- 判断牌好坏（general,good,...）
	local _pai_deg = D.operation_group_map[_op_type]
	if not _pai_deg then return end

	-- 发言概率
	local _random = D.my_role.eval_op_prob[_pai_deg]
	if not _random then return end

	if math.random(100) <= _random then
		-- 发言
		local _id = basefunc.random_select(D.mood2chat_map[D.mood.interaction_happy])
		send_chat(DATA.players_info[_tar_seat].id,_id)
	end
end

function MONITOR.nor_ddz_nor_action_msg(_data)

	clear_urge_info()

	-- _data.action.type < 100 为出牌，类型，参见 nor_ddz_algorithm_lib.lua
	if 	DATA.room_info and _data.action.p == DATA.room_info.seat_num or
		_data.action.type >= 100 or 0 == _data.action.type then
			return
	end

	-- 只针对队友 出牌
	if not ddz_is_teammate(_data.action.p) then return end

	deal_chat_on_action(_data.action.type,_data.action.p)
end

function MONITOR.nor_mj_xzdd_action_msg(_data)

	clear_urge_info()

	if DATA.room_info and _data.action.p == DATA.room_info.seat_num then
		return
	end

	deal_chat_on_action(_data.action.type,_data.action.p)
	
end

function MONITOR.nor_ddz_nor_permit_msg(_data)
	if not PUBLIC.ddz_is_my_permit(_data.cur_p) then
		set_urge_info(_data.cur_p)
	end
end

function MONITOR.nor_mj_xzdd_permit_msg(_data)
	if DATA.room_info and _data.cur_p ~= DATA.room_info.seat_num then
		set_urge_info(_data.cur_p)
	end
end

function MONITOR.recv_player_easy_chat(_data)

	-- 和最近的人互动 ，限制时间
	if D.last_intera_time and (os.time() - D.last_intera_time < 6) and _data.player_id == D.last_intera_player_id then
		if math.random(100) < 80 then
			return
		end
	end
	
	if _data.act_apt_player_id == DATA.player_id and math.random(100) <= D.my_role.reply then

		local _chat = D.chat_map[tonumber(_data.parm)]

		if "table" == type(_chat.reply) and _chat.reply[1] then
			D.last_intera_time = os.time()
			D.last_intera_player_id = _data.player_id
			send_chat(_data.player_id,_chat.reply[math.random(#_chat.reply)],260,400)
		end
	end
	
end

function PROTECTED.monitor_msg(_name,_data)

	local f = MONITOR[_name]
	if f then
		f(_data)
	end

	-- 不阻止后续者处理
	return false
end


return PROTECTED
