--
-- Author: lyx
-- Date: 2018/10/9
-- Time: 15:14
-- 说明：托管 agent 管理器
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
require"printfunc"
require "tuoguan_service.tuoguan_enum"
local nodefunc = require "nodefunc"
local schedule = require "tuoguan_service.tuoguan_schedule"

local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC

local node_name = skynet.getenv("my_node_name")



local PROTECTED = {}

local function default_Data()
    return 
    {
		-- 托管用户 id 池
		tuoguan_user_pool = nil,
		cooling_user_pool = basefunc.queue.new(),  -- 冷却中： time , user_data

		-- 托管 agent ： player_id => <数据>
		-- <数据> ： {tg_agent_id=,login_id=,grade=,gaming=true/false}
		-- 说明： tg_agent 一定是 和 player_agent 成对的
		-- 		 grade 由 schedule 使用
		tuoguan_agents = {},

		-- 游戏中的托管对象数量
		tuoguan_gaming_count = 0,

		tuoguan_creating_count = 0,

		update_timer = nil,
	}
end

DATA.tg_man_data = DATA.tg_man_data or default_Data()
local D = DATA.tg_man_data

function PUBLIC.recycle_user_data(_user_data)

	if not schedule.recycle_user_data(_user_data) then -- schedule 也许会回收
		print("recycle_user_data manager :",_user_data.id)
		D.tuoguan_user_pool[#D.tuoguan_user_pool + 1] = _user_data
	end
end

function PROTECTED.update(dt)
	while (not D.cooling_user_pool:empty()) and 
		(os.time() - D.cooling_user_pool:front().time) >=2 do
		PUBLIC.recycle_user_data(D.cooling_user_pool:pop_front().user_data)	
	end
end

function PUBLIC.free_tg_agent(_player_id)

	local _tg_data = D.tuoguan_agents[_player_id]
	if not _tg_data then
		print(string.format("tuoguan player '%s' not found!",_player_id))
		return
	end

	-- 回收 托管 资源：经过 池 冷却
	D.cooling_user_pool:push_back({time=os.time(),user_data=_tg_data.user_data})

	print("manager free_tg_agent  :",_tg_data.player_id)

	if _tg_data.gaming then
		D.tuoguan_gaming_count = D.tuoguan_gaming_count - 1
	end
	D.tuoguan_agents[_player_id] = nil

end
local free_tg_agent = PUBLIC.free_tg_agent

-- 托管 agent 退出了（注销登录）
function CMD.tuoguan_agent_kicked(_player_id)
	print("manager tuoguan_agent_kicked  :",_player_id)
	free_tg_agent(_player_id)
end

function CMD.load_tuoguan_id_pool()

	local tuoguan_file = skynet.getcfg "tuoguan_list"
	if not tuoguan_file then
		error("not found tuoguan_file config !")
	end

	local ret = require(tuoguan_file)

	if not ret then
		error("load tuoguan file error : " .. tostring(tuoguan_file))
	end

	return ret
end

-- 重置所有托管数据（托管 agent 已经崩坏）
function CMD.reload_tuoguan_data()
	PROTECTED.init(true)
end

function PROTECTED.init(_reload)

	-- 初始化数据
	if _reload then
		D = default_Data()
		DATA.tg_man_data = D
	end

	local _pool = CMD.load_tuoguan_id_pool()

	local _free_tuoguan_count  = skynet.getcfg("free_tuoguan_count") or 20

	if _free_tuoguan_count == "*" then
		D.tuoguan_user_pool = _pool
	else
		-- 一部分不分级

		D.tuoguan_user_pool = {}
		for i=1,math.min(_free_tuoguan_count,#_pool) do
			D.tuoguan_user_pool[#D.tuoguan_user_pool + 1] = _pool[#_pool]
			_pool[#_pool] = nil
		end

		schedule.init(_pool,_reload)
	end	

	D.update_timer = skynet.timer(1,PROTECTED.update)

	print("tuoguan manager init count:",#D.tuoguan_user_pool)
end

local last_tg_index = 0
function create_tg_agent_id()
	last_tg_index = last_tg_index + 1

	return "tuoguan_agent_" .. last_tg_index
end

function PUBLIC.pop_tuoguan_user_data()
	print("pop_tuoguan_user_data:",#D.tuoguan_user_pool)
	if not D.tuoguan_user_pool[1] then
		print("pop_tuoguan_user_data error,is nil!")
	end
	return basefunc.random_pop(D.tuoguan_user_pool)
end

-- 新建一个 托管 agent
function PUBLIC.create_tuoguan_agent(_user_data)

	-- 取出 login_id
	local _user_data = _user_data or PUBLIC.pop_tuoguan_user_data()

	if not _user_data then
		print("create tuoguan agent error: tuoguan user data use out!")
		return nil
	end
	-- 创建 托管 agent

	local tg_id = create_tg_agent_id()

	local ok,tg_result = skynet.call(DATA.service_config.node_service,"lua","create",nil,
							"tuoguan_service/tuoguan_agent",tg_id,_user_data)
	if not ok then
		print(string.format("create tuoguan agent error: %s!",tostring(tg_result)))
		return nil
	end

	-- 出错
	if not tg_result then
		print(string.format("start tuoguan agent return nil,tg agent id: %s!",tostring(tg_id)))
		return nil
	end

	local _tg_data = {
		user_data = _user_data,
		player_id = tg_result.user_id,
		player_data = tg_result,
		tg_agent_id = tg_id,
		gaming = false,
	}

	D.tuoguan_agents[tg_result.user_id] = _tg_data

	return _tg_data
end
local create_tuoguan_agent = PUBLIC.create_tuoguan_agent

-- 当前活跃的托管玩家数量
function CMD.tuoguan_gaming_count()
	print("D.tuoguan_gaming_count :",D.tuoguan_gaming_count)
	return D.tuoguan_gaming_count
end


local assign_tuoguan_player_start = false


-- 指派指定类型和托管玩家到 给定的服务 
function CMD.assign_tuoguan_player(_count,_game_info)

	if skynet.getcfg("forbid_tuoguan_manager") then
		return
	end

    if not assign_tuoguan_player_start then
        assign_tuoguan_player_start = true
        print("assign_tuoguan_player start...")
	end
	
	local _max_count = skynet.getcfg("tuoguan_max_count") or 100

	if (D.tuoguan_creating_count + D.tuoguan_gaming_count) >= _max_count then
		print("CMD.assign_tuoguan_player,count too much:",D.tuoguan_creating_count , D.tuoguan_gaming_count,_max_count)
		return
	end

	if not TUOGUAN_GAME[_game_info.game_type] then
		print("CMD.assign_tuoguan_player,not support game type:",_game_info.game_type)
		return
	end

	print("CMD.assign_tuoguan_player:",_count)

	skynet.fork(function()

		for i=1,_count do

			if (D.tuoguan_creating_count + D.tuoguan_gaming_count) >= _max_count then
				return
			end

			D.tuoguan_creating_count = D.tuoguan_creating_count + 1
			local _tg_data 

			local ok,msg = xpcall(function()
		
				if skynet.getcfg("free_tuoguan_count") == "*" then
					_tg_data = create_tuoguan_agent()
				else
					_tg_data = schedule.pop_tuoguan_agent(_game_info.match_name,_game_info.game_id) or  create_tuoguan_agent()
				end

				if not _tg_data then
					print("error: cannt assign_tuoguan player ! ",basefunc.tostring(_game_info))
					return
				end
				if _tg_data.tg_agent_id then

					print("assign_tuoguan_player tuoguan :",_tg_data.player_id,D.tuoguan_gaming_count)

					local ret = nodefunc.call(_tg_data.tg_agent_id,"enter_game",_game_info)
					if "CALL_FAIL" == ret then
						print("error: call tuoguan agent fail ! ",_tg_data.tg_agent_id,basefunc.tostring(_game_info))
						free_tg_agent(_tg_data.player_id)
					else
						_tg_data.gaming = true
					end
				end
			end,basefunc.error_handle)
			if not ok then
				print("CMD.assign_tuoguan_player error:",msg)
			end

			if _tg_data and _tg_data.gaming then
				D.tuoguan_gaming_count = D.tuoguan_gaming_count + 1
			end
			D.tuoguan_creating_count = D.tuoguan_creating_count - 1
		end
	end)

end

return PROTECTED
