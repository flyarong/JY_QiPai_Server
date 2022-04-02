-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:13
-- 说明：玩家代理服务

require"printfunc"
local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local mc = require "skynet.multicast.core"
local base = require "base"
require "player_agent.behavior_mgr"
local heartbeat = require "player_agent.heartbeat"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"
require "normal_enum"
require "player_agent.normal_match_game"
require "player_agent.tyddz_freestyle_game"
require "player_agent.normal_mjxl_freestyle_game"
require "player_agent.ddz_million_game"
require "player_agent.asset_manage"
require "player_agent.personal_info"
require "player_agent.email_mgr"
require "player_agent.multicast_mgr"
require "player_agent.payment"
require "player_agent.shoping"
require "player_agent.friendgame_agent"
require "player_agent.city_match_game"
require "player_agent.freestyle_game"
require "player_agent.fishing_game"

local sczd_mgr = require "player_agent.sczd_mgr"

local task_msg_center = require "task.task_msg_center"
local task_mgr = require "player_agent.task_mgr"
local glory_mgr = require "player_agent.glory_mgr"
local dress_mgr = require "player_agent.dress_mgr"
local activity_exchange_mgr = require "player_agent.activity_exchange_mgr"

local freestyle_activity_mgr = require "player_agent.freestyle_activity_mgr"


local stepstep_money_mgr = require "player_agent.stepstep_money_mgr"

--
local zajindan_agent = require "player_agent.zajindan_agent"

local goldpig_agent = require "player_agent.goldpig_agent"

local zhouka_agent = require "player_agent.zhouka_agent"
-- local vip_agent = require "player_agent.vip_agent"
local vip_lb_agent = require "player_agent.vip_lb_agent"

local xiaoxiaole_agent = require "player_agent.xiaoxiaole_agent.xiaoxiaole_agent"

local dafuhao_agent = require "player_agent.dafuhao_agent"

local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC
local REQUEST=base.REQUEST

local my_agent_link =
{
	node = skynet.getenv("my_node_name"),
	addr = skynet.self(),
}

--排他锁
DATA.game_lock=nil
DATA.location=nil
DATA.game_id=nil

-- 玩家所在 gate 的信息
local gate_link

-- Id
DATA.my_id = nil  
-- 服务配置
DATA.service_config = nil

DATA.player_data = nil

DATA.login_msg = nil

DATA.extend_data = nil

local act_lock = nil

local return_msg={result=0}

DATA.signal_restart = basefunc.signal.new()
DATA.signal_disconnect = basefunc.signal.new()
DATA.signal_logout = basefunc.signal.new()

---- 信号消息分发器
DATA.msg_dispatcher = basefunc.dispatcher.new()


-- by lyx ###_temp 机器人用的 出牌倒计时； nil 表示不是机器人
DATA.robot_cd = nil

-- agent 引用表：以名字为键（也可以是其他，能唯一标识自己即可），同一名字多次引用 等同一次
local agent_reference = {}

-- 引用 agent
function PUBLIC.ref_agent(name)
	agent_reference[name] = true
end

-- 释放对 agent 的引用
function PUBLIC.free_agent(name)

	agent_reference[name] = nil

	-- 没有对象引用，则登出整个 agent
	if not next(agent_reference) then
		PUBLIC.logout()
	end
end

function PUBLIC.is_ref(name)
	return agent_reference[name]
end

-- 踢用户下线
function CMD.kick()

	heartbeat.stop_hearbeat()
	
end

-- 错误报警 将用户强制下线
function CMD.error_warning()
	print(" error_warning "..DATA.my_id)
	PUBLIC.logout()
end

-- 客户端主动请求登出
function REQUEST.player_quit()

	--游戏中不能登出
	if DATA.game_lock then
		return {result=1040}
	end


	CMD.kick()

	return {result=0}
end

function PUBLIC.get_gate_link()
	return gate_link
end


-- 登出事件
function PUBLIC.logout()

	--正在退出
	DATA.exiting=true

	--- 给 生财之道 发送登出消息
	if basefunc.chk_player_is_real(DATA.my_id) then
		if DATA.service_config.sczd_center_service then
			skynet.send(DATA.service_config.sczd_center_service,"lua","player_logout_msg",DATA.my_id)
		end
	end

	DATA.signal_logout:trigger()

	--- 砸金蛋的 玩家退出消息 
	if PUBLIC.zajindan_player_logout then

		local ok,err = xpcall(PUBLIC.zajindan_player_logout,basefunc.error_handle)
		if not ok then
			print("call zajindan_player_logout error:",DATA.my_id,err)
		end
	end


	-- 告诉 node service ，自己销毁了
	nodefunc.destroy(DATA.my_id)

	-- 登出日志
	skynet.send(DATA.service_config.data_service,"lua","player_logout",DATA.my_id)

	local ok,err = xpcall(skynet.call,basefunc.error_handle,DATA.service_config.login_service,"lua","client_outline",DATA.my_id,gate_link,"logout")
	if not ok then
		print("call login_service client_outline error:",DATA.my_id,err)
	end
	
	print("player agent exit:",DATA.my_id)

	skynet.exit()
end


local nptrclog = {
	multicast_msg = true,
	-- nor_fishing_nor_frame_data_test = true,
	-- nor_mj_xzdd_notify_tuoguan_pai = true,
	-- nor_ddz_nor_notify_tuoguan_pai = true,
}

-- 向客户端发送 请求
function PUBLIC.request_client(_name,_data,...)
	if gate_link then

	 	if skynet.getcfg("client_message_log") then
	 		if not nptrclog[_name] then
	 			print("PUBLIC.request_client:" .. _name,basefunc.tostring(_data))
	 			-- print("PUBLIC.request_client:" .. _name)
	 		end
		end
		
		if not basefunc.is_real_player(DATA.my_id) then
			_data.msg_time = os.time()
		end
		cluster.send(gate_link.node,gate_link.addr,"request_client",gate_link.client_id,_name,_data,...)
		return true
	else
		return false
	end
end



function PUBLIC.xsyd_finish()

	DATA.player_data.xsyd_status = 1
	skynet.send(DATA.service_config.data_service,"lua","player_xsyd_finish",DATA.my_id)

end

--加载玩家信息
function PUBLIC.load_player_info()
	
	DATA.player_data = skynet.call(DATA.service_config.data_service,"lua","get_player_info",DATA.my_id)
	if not DATA.player_data then
		error("asset data is nil !!! user id :"..DATA.my_id)
	end

	DATA.player_data.xsyd_status = skynet.call(DATA.service_config.data_service,"lua","query_player_xsyd",DATA.my_id)

	DATA.player_data.million_cup_status = skynet.call(DATA.service_config.data_service,"lua","query_player_million_cup_status",DATA.my_id)

	PUBLIC.load_asset()

	DATA.player_data.gift_bag_data = PUBLIC.query_all_gift_bag_status()

	PUBLIC.init_real_name_authentication()

	PUBLIC.init_statistics_match_data()

	PUBLIC.init_statistics_freestyle_tyddz_data()
	
	PUBLIC.init_statistics_million_ddz_data()
	PUBLIC.init_million_shared_data()

	PUBLIC.init_everyday_shared_award()

	--拿取最新的资产信息
	DATA.player_data.player_asset = PUBLIC.query_asset()
	DATA.player_data.player_prop = nil

	--vip初始化,这个一定在task_mgr之前
	-- vip_agent.init()

	--荣耀管理器初始化
	glory_mgr.init()

	--荣耀管理器初始化
	dress_mgr.init()

    -- 托管的情况
    if not basefunc.chk_player_is_real(DATA.my_id) then

		DATA.auto_cp_must_guo=false

	else

		-- 真实玩家

		task_msg_center.init()

		DATA.auto_cp_must_guo=true

		goldpig_agent.init()

		zhouka_agent.init()

		vip_lb_agent.init()

		xiaoxiaole_agent.init()

		dafuhao_agent.init()

		-- 自由场活动管理器
		freestyle_activity_mgr.init()

		activity_exchange_mgr.init()

		--任务管理器初始化
		if skynet.getcfg("task_system_is_open") then
			task_mgr.init()
		else
			task_mgr = nil
		end

		if skynet.getcfg("stepstep_money_is_open") then
			stepstep_money_mgr.init()
		else
			stepstep_money_mgr = nil
		end

		if skynet.getcfg("zajindan_is_open") then
			zajindan_agent.init()
		else
			zajindan_agent = nil
		end

	end


end

-- 绑定 agent 的 重登陆 事件
local _last_bind_restart_id = 0
function CMD.bind_restart_signal(_cmd_link,...)
	local param = table.pack(...)
	_last_bind_restart_id = _last_bind_restart_id + 1
	DATA.signal_restart:bind(_last_bind_restart_id,function()
		nodefunc.send_cmd(_cmd_link,DATA.my_id,gate_link,table.unpack(param))
		
	end)

	return _last_bind_restart_id
end
function CMD.unbind_restart_signal(_bind_id)
	DATA.signal_restart:unbind(_bind_id)
end

-- 绑定 agent 的 断线 事件
local _last_bind_disconnect_id = 0
function CMD.bind_disconnect_signal(_cmd_link,...)
	local param = table.pack(...)
	_last_bind_disconnect_id = _last_bind_disconnect_id + 1
	DATA.signal_disconnect:bind(_last_bind_disconnect_id,function()
		nodefunc.send_cmd(_cmd_link,DATA.my_id,table.unpack(param))
		
	end)

	return _last_bind_disconnect_id
end
function CMD.unbind_disconnect_signal(_bind_id)
	DATA.signal_disconnect:unbind(_bind_id)
end

-- 重登录
function CMD.restart(_my_id,_gate_link,_login_msg,_extend_data)
	if DATA.exiting then
		return {result=1064}
	end

	print(string.format("restart player servie new: %s , old:%s",tostring(_my_id),tostring(DATA.my_id)))

	gate_link = _gate_link

	DATA.login_msg = _login_msg

	DATA.extend_data.ip = _extend_data.ip
	DATA.extend_data.player_level = _extend_data.player_level

	-- 开始心跳检测
	heartbeat.start_heartbeat()

	--拿取最新的资产信息
	DATA.player_data.player_asset = PUBLIC.query_asset()
	
	--拿最新的状态来
	DATA.player_data.gift_bag_data = PUBLIC.query_all_gift_bag_status()

	skynet.timeout(0,function() DATA.signal_restart:trigger() end)
	return {
				result=0,
				agent_link=my_agent_link,
				location = DATA.location,
				vice_location = DATA.vice_location,
				game_id = DATA.game_id,
				player_data = DATA.player_data,
			}
end

local _max_deal_request_time = 0
local max = math.max

-- function CMD.start(		_my_id,
-- 						_service_config,
-- 						_gate_agent_id,
-- 						_client_id,
-- 						_addr,
-- 						_login_msg,
-- 						_extend_data
-- 						)
function CMD.start(_my_id,_service_config,_gate_link,_login_msg,_extend_data)

	base.set_hotfix_file("fix_player_agent")

	skynet.timer(5,function ()
		if _max_deal_request_time ~= 0 then
			-- print("max deal request time:",_max_deal_request_time)
			_max_deal_request_time = 0
		end
	end)

	print(string.format("start player servie : %s",_my_id))

	DATA.service_config = _service_config
	DATA.my_id =_my_id

	-- ###_temp 机器人，则 cd 设为 1
	if not basefunc.chk_player_is_real(_my_id) then
		DATA.robot_cd = skynet.getcfg_2number("player_agent_robot_cd") or 15
	end

	gate_link = _gate_link

	DATA.login_msg = _login_msg

	DATA.extend_data = _extend_data

	PUBLIC.load_player_info()
	
	--print("player agent created:",agent_id)

	-- 开始心跳检测
	heartbeat.start_heartbeat()

	-- 登录日志
	skynet.call(DATA.service_config.data_service,"lua","player_login",_my_id,_extend_data.ip,_login_msg.device_os)

	--监听广播
	PUBLIC.init_multicast_msg()
	--信息用户首次登录处理
	if DATA.player_data.player_info.logined ~= 1 then
		skynet.call(DATA.service_config.data_service,"lua","modify_player_info",DATA.my_id,"player_info",{logined=1})
		PUBLIC.dispose_new_user()
	end

	--登录后即处理
	PUBLIC.dispose_logined()


	-- ###_test   hw  test
	-- if basefunc.chk_player_is_real(_my_id) then
	-- 	skynet.timeout(100,function () 
	-- 		print("fsg_signupfsg_signupfsg_signupfsg_signup")
	-- 		dump(REQUEST.fsg_signup({id=3}))
	-- 		skynet.sleep(100)
	-- 		print("debug_test_create_fishdebug_test_create_fish")
	-- 		-- dump(CMD)
	-- 		CMD.debug_test_create_fish(100000)
	-- 		print("*****************create fish compelet!!!!")
	-- 		CMD.debug_test_shoot_fish(500000)
	-- 		print("*****************shoot fish compelet!!!!")
	-- 		dump(CMD.query_asset_by_type("jing_bi"),"jinbi**********")
	-- 		CMD.debug_get_fish_money()
	-- 		error(true)
	-- 	end)
	-- end

	return {
		agent_link=my_agent_link,
		player_data=DATA.player_data,
	}
end

-- 玩家断开网关
function CMD.disconnected(_gate_link)

	-- 判断是否当前正在使用 gate 信息，否则可能是旧的
	if gate_link and nodefunc.equal_gate_link(gate_link,_gate_link) then

		DATA.signal_disconnect:trigger()

		gate_link = nil

		heartbeat.net_error()

		print("disconnected :",DATA.my_id,_gate_link.addr,_gate_link.client_id)

	end
end


local function dispatch_request(name ,data,responeId)
	
	if skynet.getcfg("client_message_log") then
		if name == "heartbeat" then
			--print("heartbeat") 
		else
			if not nptrclog[name] then
				print("my id:" .. tostring(DATA.my_id) .. ",client to server request :" .. tostring(name) .. " resp id:" .. tostring(responeId),basefunc.tostring(data))
			end
			-- print("my id:" .. tostring(DATA.my_id) .. ",client to server request :" .. tostring(name) .. " resp id:" .. responeId)
		end
	end

	-- 只对管理员加载，避免频繁 读取 文件
	if "gm_command" == name and not REQUEST[name] then
		base.import("./game/services/player_agent/gm_tools.lua")
	end

	local f = REQUEST[name]
	if f then

		local ttt1 = skynet.time()
		local resp = f(data)
		local ttt2 = skynet.time()
		_max_deal_request_time = max(ttt2-ttt1,_max_deal_request_time)
		if ttt2 - ttt1 > 2 then
			print("request time warning,time,name,data:",ttt2 - ttt1,name,basefunc.tostring(data))
		end

		if skynet.getcfg("client_message_log") then
			if name ~= "heartbeat" then
				print("respone data :" .. tostring(name) .. " resp id:" .. tostring(responeId),basefunc.tostring(resp))
				-- print("respone data :" .. tostring(name) .. " resp id:" .. responeId)
			end
		end

		if responeId then
			if gate_link then
				cluster.send(gate_link.node,gate_link.addr,"response_client",gate_link.client_id,responeId,resp)
			end
		end
	else
		print("error : message name invalid:" .. tostring(name))
		if responeId then
			if gate_link then
				-- 需要 response ，则回送错误消息
				if gate_link then
					cluster.send(gate_link.node,gate_link.addr,"response_client",gate_link.client_id,responeId,{result = -1})
				end
			end
		end
	end
end


--新用户处理
function PUBLIC.dispose_new_user()

	--系统欢迎邮件
	skynet.timeout(200,function()
		
		local email = {
			type = "sys_welcome",
			title = "欢迎来到我们的游戏",
			sender = "系统",
			receiver = DATA.my_id,
		}
		skynet.send(DATA.service_config.email_service,"lua","send_email",email)

	end)


	--系统欢迎邮件
	-- skynet.timeout(300,function()
		
	-- 	local email = {
	-- 		type = "sys_inner_test_award",
	-- 		title = "【内测奖励】",
	-- 		sender = "系统",
	-- 		receiver = DATA.my_id,
	-- 		data={diamond=5000},
	-- 	}
	-- 	skynet.send(DATA.service_config.email_service,"lua","send_email",email)

	-- end)


	skynet.timeout(100,function ()
			local _asset_data={
				{asset_type=PLAYER_ASSET_TYPES.JING_BI,value=6000},
				{asset_type="jipaiqi",value=1},

				-- {asset_type=PLAYER_ASSET_TYPES.FISH_COIN,value=100000},
				-- {asset_type="prop_fish_frozen",value=2},
				-- {asset_type="prop_fish_lock",value=2},
			}
			CMD.change_asset_multi(_asset_data,ASSET_CHANGE_TYPE.NEW_USER_LOGINED_AWARD,0)
	end)



	-- skynet.sleep(200)
	-- local bcmsg = {
	-- 	type=1,
	-- 	format_type=1,
	-- 	content="欢迎<color=#00ff00>"..DATA.player_data.player_info.name.."</color>来到竟娱游戏",
	-- }
	-- skynet.send(DATA.service_config.broadcast_svr,"lua",
	-- 				"broadcast",1,bcmsg)





end

--登录后 首次处理
function PUBLIC.dispose_logined()

	-- skynet.timeout(2200,function ()
	-- 		local _asset_data={
	-- 			{asset_type=PLAYER_ASSET_TYPES.ZY_CITY_MATCH_TICKET_HX,value=100},
	-- 		}
	-- 		CMD.change_asset_multi(_asset_data,2,0)


	-- 	dump(REQUEST.get_freestyle_activity_award(),"xxxxx+++++++"..DATA.my_id)
	-- end)

	-- 登录 事件
	--DATA.msg_dispatcher:call("logined")
	PUBLIC.trigger_msg( {name = "logined"} )

	--- 给 生财之道 发送登录消息
	if basefunc.chk_player_is_real(DATA.my_id) then
		if DATA.service_config.sczd_center_service then
			skynet.send(DATA.service_config.sczd_center_service,"lua","player_login_msg",DATA.my_id)
		end
	end

	--- 砸金蛋的 玩家登录消息 
	if PUBLIC.zajindan_player_login then
		PUBLIC.zajindan_player_login()
	end

	

end


--*********************************************客户端请求 *****************************************


--客户端确认了奖杯
function REQUEST.confirm_million_cup(self)

	skynet.send(DATA.service_config.data_service,"lua",
				"set_player_million_cup_status",DATA.my_id)
	
	DATA.player_data.million_cup_status = nil

	return {result=0}
end


function REQUEST.change_clientStatus(self)
	if self.status == 1 then		-- 切换到后台
		heartbeat.net_error()
	else							-- 切换到正常
		heartbeat.heartbeat()
	end

	return {result=0}
end


local query_win_rate_data = {time=0,data=nil}
function REQUEST.query_win_rate(self)
	
	if query_win_rate_data.time < os.time() then
		query_win_rate_data.time = os.time() + 60
		query_win_rate_data.data = nil
	end

	if query_win_rate_data.data then
		return query_win_rate_data.data 
	end

	local win_count = 0
	local all_count = 0

	local ddz_win_data = skynet.call(DATA.service_config.data_service,"lua","get_statistics_player_ddz_win_data",DATA.my_id)
	win_count = win_count + ddz_win_data.dizhu_win_count+ddz_win_data.nongmin_win_count

	local mj_win_data = skynet.call(DATA.service_config.data_service,"lua","get_statistics_player_mj_win_data",DATA.my_id)
	win_count = win_count + mj_win_data.win_count


	all_count = all_count+win_count
					+ddz_win_data.defeated_count
					+mj_win_data.defeated_count

	query_win_rate_data.data = {
		result=0,
		win_count=win_count,
		all_count=all_count,
	}

	return query_win_rate_data.data
end

-- 使用激活码
function REQUEST.use_redeem_code(self)

	if not self or type(self.code) ~= "string" 
		or string.len(self.code) < 1 
		or string.len(self.code) > 512 then
		return_msg.result = 1001
		return return_msg 
	end

	if act_lock then
		return_msg.result = 1008
		return return_msg
	end

	act_lock = true

	local ret = skynet.call(DATA.service_config.redeem_code_center_service,"lua","use_key_code",DATA.my_id,self.code)

	act_lock = false

	return ret

end

--加载与获得游戏
function PUBLIC.require_game_by_type(_type)

	local path=GAME_TYPE_AGENT[_type]
	dump(path)
	if path then
		return require(path)
	end
	return nil
end

--[[ voice

]]
function REQUEST.send_voice_chat(self)
	
	if not self then
		return false
	end
		
	if not self.data or type(self.data)~="string" then
		return false
	end

	if self.data and DATA.chat_room_id then
		skynet.call(DATA.service_config.chat_service,"lua","chat", DATA.chat_room_id,DATA.my_id,self.data)
	end
end

function REQUEST.send_player_easy_chat(self)

	if not self then
		return_msg.result = 1001
		return return_msg
	end

	if not self.parm or type(self.parm)~="string" then
		return_msg.result = 1001
		return return_msg
	end

	if self.act_apt_player_id and type(self.act_apt_player_id)~="string" then
		return_msg.result = 1001
		return return_msg
	end

	--检测装扮是否可用
	local ret = PUBLIC.use_dress(tonumber(self.parm))
	if ret ~= 0 then
		return_msg.result = ret
		return return_msg
	end

	
	if self.parm and DATA.chat_room_id then
	
		skynet.send(DATA.service_config.chat_service,"lua","easy_chat", DATA.chat_room_id,DATA.my_id,self.act_apt_player_id,self.parm)
	else
		return_msg.result = 1001
		return return_msg
	end

	return_msg.result = 0
	return return_msg

end

----- 获取玩家的游戏数据
function CMD.get_player_game_info()
	local ret = {}

	ret.gaming_name = ""
	ret.manager_service = ""
	ret.status = ""
	ret.game_status = ""
	ret.room_id = ""
	ret.table_id = ""
	ret.player_name = ""
	ret.game_begin_time = ""

	local match_game_data = DATA.match_game_data
	if match_game_data and type(match_game_data) == "table" then
		if match_game_data.match_info then
			---- 在哪个游戏中
			ret.gaming_name = match_game_data.match_info.name or ""
			---- 管理者
			ret.manager_service = match_game_data.match_info.signup_match_id or ""
		end
		---- 场次状态
		ret.status = match_game_data.status or ""
		if match_game_data.game_data and type(match_game_data.game_data) == "table" then
			--- 游戏状态
			ret.game_status = match_game_data.game_data.status or ""
		end
		if match_game_data.base_info and type(match_game_data.base_info) == "table" then
			--- 房间号
			ret.room_id = match_game_data.base_info.room_id or ""
			--- 桌号
			ret.table_id = match_game_data.base_info.t_num or ""
		end
	elseif DATA.fish_game_data and type(DATA.fish_game_data) == "table" then
		--- 房间号
		ret.room_id = DATA.fish_game_data.game_data.room_id or ""
		--- 桌号
		ret.table_id = DATA.fish_game_data.game_data.t_num or ""
	end

	---- 玩家的名字
	ret.player_name = DATA.player_data.player_info.name

	---- 一个游戏开始的时间
	ret.game_begin_time = DATA.one_game_begin_time 


	return ret
end

---- 获得千元赛下一个开赛日  是第几天 今天有就返回0
function PUBLIC.get_qys_next_start_day( is_not_card_today )
	local raw_configs = nodefunc.get_global_config("match_server") 

	local now_time = os.time()
	local now_time_day = basefunc.get_today_id( now_time )
	local next_day = 5

	for key,data in pairs(raw_configs.match_info) do
		local is_break = false

		if data.match_model == "naming_qys" then
			for _key,_data in pairs(raw_configs.dingshikai) do
				if _data.game_id == data.game_id then
					local begin_time_day = basefunc.get_today_id( _data.begin_signup_time )
					if not is_not_card_today then
						if begin_time_day >= now_time_day then
							next_day = math.min( next_day , begin_time_day - now_time_day )
						end
					end
					if is_not_card_today then
						if begin_time_day > now_time_day then
							next_day = math.min( next_day , begin_time_day - now_time_day )
						end
					end
				end
			end
		end
		if is_break then
			break
		end
	end

	return next_day
end


skynet.start(function()

	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)

			if "request" == cmd then	-- 客户端请求
				dispatch_request(subcmd,...)
			else						-- 服务器之间调用

				-- 调用 默认的消息分发函数 进行处理
				base.default_dispatcher(session, source, cmd, subcmd, ...)
			end
	end)

	--广播协议
	skynet.register_protocol {
		name = "multicast",
		id = skynet.PTYPE_MULTICAST,
		unpack = mc.unpack,
		dispatch = function(_channel, _source, _pack, _msg, _sz)
			local msg = skynet.unpack(_msg, _sz)

			PUBLIC.multicast_msg(_channel,msg)

			mc.close(_pack)
		end,
	}
end)

