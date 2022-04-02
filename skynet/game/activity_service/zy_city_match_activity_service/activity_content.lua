--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：登录服务
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local zy_cup_activity_cfg = require "zy_cup_activity_cfg"
local virtual_winner = require "virtual_winner_hx"
require "printfunc"

local DATA = base.DATA
local CMD = base.CMD

local PROTECTED = {} 

local is_init = false
local send_email_data = {}

--赛前海选门票
local function send_pre_hx_email()

	local data={
		email={
			type = "native",
			title = "资阳城市杯大师邀请函",
			sender = "系统",
			valid_time = 1636657298,
			data = "{content='亲爱的朋友，第一届鲸鱼杯公益斗地主大赛将于9月26日12:00开启，官方诚邀您的加入。参赛就有奖，更有超级现金大奖等你来拿！',zy_city_match_ticket_hx=1}",
		},
	}

	--全局邮件
	local errcode = skynet.call(DATA.service_config.email_service,"lua",
										"external_send_email",
										data,
										"系统",
										"资阳城市杯赛前海选门票")

	if errcode then
		print("city activity send_email error : " .. errcode)
	end

end


--海选结束给没入围的发送安慰奖励
local function send_hx_lose_email()

	local players = nodefunc.call("match_service_"..zy_cup_activity_cfg.hx_game_id,"get_lose_player")

	if not players or not next(players) then
		return
	end

	local player_list = {}
	for player_id,v in pairs(players) do
		player_list[#player_list+1]=player_id
	end

	local data={
		players=player_list,
		email={
			type = "native",
			title = "海选赛参与奖励",
			sender = "系统",
			valid_time = 1636657298,
			data = "{content='很遗憾您在海选赛被淘汰，感谢您的参与，这是给与您的鼓励奖，希望下次比赛能取得好成绩。',jing_bi=2000,room_card=2}",
		},
	}

	--全局邮件
	local errcode = skynet.call(DATA.service_config.email_service,"lua",
										"external_send_email",
										data,
										"系统",
										"海选赛参与奖励")

	if errcode then
		print("city activity send_email error : " .. errcode)
	end

end


local function send_hx_begin_msg()

	skynet.send(DATA.service_config.third_agent_service,"lua","push_notify",
   		"broadcast"
   		,"第一届鲸鱼杯公益斗地主大赛"
   		,""
   		,"海选赛还有10分钟开赛，请做好准备。参赛即有奖，更有现金实物大奖等你来拿！")

end



local function send_fs_begin_msg()

	skynet.send(DATA.service_config.third_agent_service,"lua","push_notify"
   		,"broadcast"
   		,"第一届鲸鱼杯公益斗地主大赛"
   		,""
   		,"复赛还有10分钟开启报名，请做好准备。参赛即有奖，更有现金实物大奖等你来拿！")

end


local function send_js_begin_msg()

	local players = nodefunc.call("match_service_"..zy_cup_activity_cfg.js_game_id,"get_win_player")

	for player_id,d in pairs(players) do

		local phone = skynet.call(DATA.service_config.data_service,"lua","query_bind_phone_number",
						player_id)

		if phone then
			local msg = string.format("恭喜您在复赛夺得第%s名并获得了决赛资格。鲸鱼斗地主诚邀您参加第一届鲸鱼杯公益斗地主大赛资阳站决赛，现金大奖等你来拿，到场就有实物和现金奖励。10月1日10:00~12:00开启报名（过期不候），14:00开启决赛。地点在四川资阳西南电商城。祝您取得好成绩，现金大奖抱回家！",
										d.rank)

			skynet.send(base.DATA.service_config.third_agent_service,"lua"
				,"send_phone_sms"
				,phone
				,msg)
		end

	end

end


local add_t = 0
local add_virtual_hx_winner_idx = 0
local function add_virtual_hx_winner()

	add_virtual_hx_winner_idx = add_virtual_hx_winner_idx + 1
	local name = virtual_winner[add_virtual_hx_winner_idx]

	if not name then
		return
	end

	nodefunc.send("match_service_"..zy_cup_activity_cfg.hx_game_id,"add_virtual_winner",
	{
		player_id = "virtual_"..add_virtual_hx_winner_idx,
		name = name,
	})

end


--执行具体活动的内容
function PROTECTED.update()

	local cur_time = os.time()

	--[[
	]]

	local cur_time = os.time()
	local cur_h = tonumber(os.date("%H",cur_time))
	local cur_m = tonumber(os.date("%M",cur_time))
	local cur_s = tonumber(os.date("%S",cur_time))
	local cur_date = tonumber(os.date("%Y%m%d",cur_time))

	--海选赛开始前几天发送海选门票
	if cur_time>zy_cup_activity_cfg.hx_mp-1 and cur_time<zy_cup_activity_cfg.hx_mp+2 then
		if not send_email_data["pre_hx"] then
			send_email_data["pre_hx"] = true
			send_pre_hx_email()
		end
	end


	--海选比赛即将开始的推送
	if cur_time>zy_cup_activity_cfg.hx_ts-1 and cur_time<zy_cup_activity_cfg.hx_ts+2 then
		if not send_email_data["hx_ts"] then
			send_email_data["hx_ts"] = true
			send_hx_begin_msg()
		end
	end


	--海选赛结束后发送海选参与奖励
	if cur_time>zy_cup_activity_cfg.hx_jl-1 and cur_time<zy_cup_activity_cfg.hx_jl+2 then
		if not send_email_data["hx_lose"] then
			send_email_data["hx_lose"] = true
			send_hx_lose_email()
		end
	end


	--复赛比赛即将开始的推送
	if cur_time>zy_cup_activity_cfg.fs_ts-1 and cur_time<zy_cup_activity_cfg.fs_ts+2 then
		if not send_email_data["fs_ts"] then
			send_email_data["fs_ts"] = true
			send_fs_begin_msg()
		end
	end


	--决赛比赛即将开始的短信
	if cur_time>zy_cup_activity_cfg.js_dx-1 and cur_time<zy_cup_activity_cfg.js_dx+2 then
		if not send_email_data["js_msg"] then
			send_email_data["js_msg"] = true
			send_js_begin_msg()
		end
	end


	--添加海选虚拟胜利玩家
	if cur_time>zy_cup_activity_cfg.hx_av_s and cur_time<zy_cup_activity_cfg.hx_av_e then

		if add_t < 1 then
			add_t = os.time() + math.random(1*3600,2*3600)
		end

		if add_t < os.time() then
			add_virtual_hx_winner()
			add_t = os.time() + math.random(10*60,20*60)
		end

	end

end


return PROTECTED