--
-- Author: hw
-- Date: 2018/3/28
-- Time: 
-- 说明：比赛场游戏服务
-- ddz_match_service
local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "printfunc"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA
local cjson = require "cjson"
cjson.encode_sparse_array(true,1,0)

DATA.switch = {
	broadcast = 1,
	req_tuoguan = 1,
	notify_rank = 1,
}

-- 额外托管的数量
local extra_tuoguan_num = 150

DATA.match_obj = {}

DATA.UPDATE_INTERVAL = 5

local function broadcast(_start_time)

	if DATA.switch.broadcast == 0 then
		return
	end

	local start_time_clock = os.date("%H",_start_time)

	local start_tips = string.format("千元大奖赛开始报名了，%s点准时开赛，1000元现金等您拿！",start_time_clock)

	for i=0,2 do

		skynet.timeout((i*60)*100,function ( ... )
			
			skynet.send(DATA.service_config.broadcast_center_service,"lua",
						"broadcast",
						1,
						{
							type=2,
							format_type=1,
							content=start_tips
						})

		end)

	end


	local lt = _start_time - os.time()

	for i=5,3,-1 do
			
		skynet.timeout((lt-i*60)*100,function ( ... )
			
			skynet.send(DATA.service_config.broadcast_center_service,"lua",
						"broadcast",
						1,
						{
							type=2,
							format_type=1,
							content=string.format("千元大奖赛距离开赛还有%s分钟，还没报名的小伙伴抓紧时间，%s点准时开赛！"
								,i
								,start_time_clock)
						})

		end)

	end


end


local function req_tuoguan(_match_id,_game_type,_need_num,_tuoguan_num,_start_time,_obj)
	
	if DATA.switch.req_tuoguan == 0 then
		return
	end
	
	local service_id = "match_service_".._match_id
	local ret = nodefunc.call(service_id,"get_signup_player_num")
	local has_num = ret.signup_num
	if not has_num then
		return
	end

	_tuoguan_num = math.max(_tuoguan_num or 1,1)

	local need_tuoguan = _tuoguan_num

	local lt = _start_time - os.time()

	if lt < 5*60 then
		need_tuoguan = math.max(_tuoguan_num,_need_num-has_num)
	end

	local _n = 1
	if lt < 20 then
		
		if has_num < _need_num then
			_n = _need_num - has_num + math.random(2,10)
		else
			return
		end

	else

		-- 最后五分钟的时候
		if lt < 5*60 then

			if has_num < _need_num then
				-- 不达标 积极一点

				local t =  (lt) / 5
				local tn = need_tuoguan/t
				tn = math.ceil(tn * 10000)

				_n = math.random(tn-10000,tn+30000)

				_n = math.ceil(_n/10000)

				if _n < 1 then
					return
				end
				
			else

				_n = 0

				local detn = extra_tuoguan_num - _obj.extra_tuoguan_num
				if detn > 0 then
					_n = _n + math.random(5,10)
					_obj.extra_tuoguan_num = _obj.extra_tuoguan_num + _n
				end

				-- 已达标 猥琐一点
				local e = has_num - _need_num

				if e < _need_num then
					_n = _n + math.random(1,4)
				else
					local r = math.random(1,100)
					if r > 40 then
						_n = _n + 1
					end
				end

				if _n < 1 then
					return
				end

			end 

		else
			return
		end
		
	end

	local _game_info = 
	{
		game_id = _match_id,
		game_type = _game_type,
		service_id = service_id,
		match_name = "match_game",
	}

	-- print(_match_id.."++++++++++++++++++req_tuoguan ".._n)
	skynet.send(DATA.service_config.tuoguan_service,"lua","assign_tuoguan_player",_n,_game_info)

end


local function notify_rank(_match_id)
	
	if DATA.switch.notify_rank == 0 then
		return
	end

	if not skynet.getcfg "naming_match_notify_rank"  then
		return
	end

	local sql = 
	string.format("SELECT player_id,player_name,rank FROM naming_match_rank WHERE match_id = %s AND rank < 4;",
					tonumber(_match_id) or 0
					)


	local func = function ()
		
		local d = skynet.call(DATA.service_config.data_service,"lua","db_query",sql)
		if d and next(d) then

			-- 名字中的空格会导致邮件不全 这里替换为一个近似空格的字符
			for i,v in ipairs(d) do
				local ns = string.gsub(v.player_name," ","")
				v.player_name = ns
			end

			local cur_date = tonumber(os.date("%Y%m%d"))
			local s = (cjson.encode(d))
			s = string.gsub(s,"},{","},<br>{")
			local _title = "\"千元赛排名结果通知\""
			local _text = "\"<p><b>" .. cur_date .. "</b><br><br>" .. s .. "<br><br>（玩家id中如果含有 robot 请忽略）</p>\""

			local _email = "1505399301@qq.com,897106850@qq.com"

			skynet.call(DATA.service_config.third_agent_service,"lua","send_email",
			"\"" .. _email .. "\"",
			_title,_text)

			return true
		end

		return false
	end

	skynet.fork(function ()
		
		while true do

			--10分钟检测一次
			skynet.sleep(600*100)

			if DATA.switch.notify_rank == 0 then
				return
			end

			if func() then
				return
			end

		end
		
	end)

end


local function query_match()

	local games = skynet.call(DATA.service_config.match_center_service,"lua","get_game_map")

	if games and type(games)=="table" then

		for _match_id,d in pairs(games) do
			
			if string.sub(d.match_model,1,6) == "naming" then
				local ei = nodefunc.call(d.service_id,"get_enter_info")
				if ei == 0 then
					if not DATA.match_obj[_match_id] then
						local cfg = nodefunc.call(d.service_id,"query_cfg")
						if cfg and type(cfg)=="table" then
							
							if cfg.signup_data_config then

								if not cfg.tuoguan_enter_config then
									cfg.tuoguan_enter_config = {
										tuoguan_limit = 1,
									}
								end

								DATA.match_obj[_match_id]={
									match_id = _match_id,
									game_type = d.game_type,
									broadcast = false,
									start_time = cfg.signup_data_config.begin_signup_time+cfg.signup_data_config.signup_dur,
									need_num = cfg.signup_data_config.begin_game_condi,
									tuoguan_num = cfg.tuoguan_enter_config.tuoguan_limit,
									extra_tuoguan_num = 0,
								}

							end

						end
					end
				end
			end

		end

	end

end


local function exec()
	
	for id,o in pairs(DATA.match_obj) do
		
		if not o.broadcast then
			broadcast(o.start_time)
			o.broadcast = true
		end

		req_tuoguan(o.match_id,o.game_type,o.need_num,o.tuoguan_num,o.start_time,o)

		if o.start_time < os.time() then

			notify_rank(o.match_id)

			DATA.match_obj[id] = nil
		end

	end

end



local function update()
	
	while true do

		skynet.sleep(100*DATA.UPDATE_INTERVAL)

		query_match()
		
		exec()

	end

end



-- 停止广播
function CMD.set_switch_broadcast(_s)
	DATA.switch["broadcast"] = tonumber(_s)
end

-- 停止tuoguan
function CMD.set_switch_req_tuoguan(_s)
	DATA.switch["req_tuoguan"] = tonumber(_s)
end

-- 停止广播邮件
function CMD.set_switch_notify_rank(_s)
	DATA.switch["notify_rank"] = tonumber(_s)
end


-- 设置额外托管的数量(一般托管会逼近开赛的数量+预设(20))
function CMD.set_extra_tuoguan_num(_s)
	extra_tuoguan_num = tonumber(_s)
end


function CMD.start(_service_config)

	DATA.service_config=_service_config

	-- 延迟等待一下
	skynet.timeout(500,function ()
		skynet.fork(update)
	end)

end

-- 启动服务
base.start_service()

