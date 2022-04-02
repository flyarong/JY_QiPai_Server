--人满即开
--auther ：hewei

local basefunc = require "basefunc"
require"printfunc"

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "ddz_match_enum"
require "normal_enum"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA
local PROTECTED = {}

DATA.enter_condition_cache = {}

DATA.enter_info_result_cache = {} 

-- 等待开始比赛的列表
DATA.wait_begin_match_list = {}

local ready_match_num = 20

function PROTECTED.set_ready_match_num(_n)
	ready_match_num = _n
end

-- 初始化 报名 结果数据 缓存
local function init_player_signup_result_cache()
	DATA.player_signup_result_cache = {
		result = 0,
		name = DATA.match_config.match_data_config.name,
		is_cancel_signup = DATA.match_config.signup_data_config.is_cancel_sign,
		cancel_signup_cd = DATA.match_config.signup_data_config.cancel_cd,
		total_players = DATA.match_config.signup_data_config.begin_game_condi,
		total_round = #DATA.match_config.match_game_config,
	}
end

--组织数据结构
local function use_config()

	DATA.enter_condition_cache = {}

	-- 构建 玩家进入条件 缓存 数据
	for i,match_enter_config in ipairs(DATA.match_config.match_enter_config) do

		DATA.enter_condition_cache[i] = {}

		for _condi_id,_condi_data in pairs(match_enter_config) do

			DATA.enter_condition_cache[i][#DATA.enter_condition_cache[i]+1]={
				condi_type = _condi_data.judge_type,
				asset_type = _condi_data.asset_type,
				value = _condi_data.asset_count,
			}

		end

	end

	DATA.enter_info_result_cache = {
		condi_data = DATA.enter_condition_cache,
		game_type = DATA.match_config.game_type,
		match_model = DATA.match_config.match_model,
		begin_type = "renmanjikai",
	}

	init_player_signup_result_cache()

	----
	DATA.game_rule_config = {}
	---- 传入默认开关，番数
	DATA.kaiguan = DATA.match_config.kaiguan_multi and DATA.match_config.kaiguan_multi.kaiguan or nil
	DATA.multi = DATA.match_config.kaiguan_multi and DATA.match_config.kaiguan_multi.multi or nil

	DATA.config_last_change_time = os.time()

	DATA.game_rule_config.kaiguan = DATA.kaiguan
	DATA.game_rule_config.multi = DATA.multi 

end

function CMD.get_kaiguan_cfg_time()
	return DATA.config_last_change_time 
end

function CMD.get_kaiguan_cfg()
	return { kaiguan = DATA.kaiguan , multi = DATA.multi }
end

function PROTECTED.use_new_config()
	use_config()
end

--[[
不能报名的情况

--]]
-- 检查是否状态，是否允许新玩家报名   ###_test
function PROTECTED.check_allow_signup()

	-- 禁用
	if DATA.signup_status == MATCH_STATUS.DISABLE then
		return false,1009
	end

	-- 判断状态
	if DATA.signup_status ~= MATCH_STATUS.SIGNUP then
		--skynet.fail("check_allow_signup: status is not signup!")
		return false,2000
	end

	-- 达到最大并发  暂时不能报名  （服务器繁忙）
	if DATA.cur_running_match+DATA.dispatch_queue:size() >= DATA.match_config.signup_data_config.max_concurrency_game then
		-- 正常情况下不可能  ###_test
		return false,2001
	end

	-- 达到最多的局数 不能再开了
	if (DATA.match_config.signup_data_config.max_round~=-1
		and DATA.cur_running_match+DATA.complete_match+DATA.dispatch_queue:size()
				>=DATA.match_config.signup_data_config.max_round ) then
			DATA.signup_status=MATCH_STATUS.SIGNUP_END
			PROTECTED.all_match_over()
			return false,2000
	end

	return true
end


--检查 报名时间是否结束
function PROTECTED.check_signup_end_time()

	if os.time()>=DATA.match_config.signup_data_config.end_signup_time then
		DATA.signup_status=MATCH_STATUS.SIGNUP_END
		PROTECTED.all_match_over()
	end

end


local function create_service_id()
	DATA.service_id_count = DATA.service_id_count + 1
	-- 用自己的 id 作为前缀
	return DATA.my_id .. "_manager_" .. tostring(DATA.service_id_count)
end

local function get_exit_time()
	DATA.exit_service_time=os.time()+DATA.match_config.signup_data_config.close_time
end

-- 准备下一次 比赛的数据
function PROTECTED.prepare_ready_match_data()

	local create_num = ready_match_num - DATA.signup_match_ready_ids_num

	if create_num < 1 then
		return
	end

	for i=1,create_num do
		
		local signup_match_id = create_service_id()

		DATA.signup_match_ready_ids[signup_match_id] = signup_match_id
		DATA.signup_match_ready_ids_num = DATA.signup_match_ready_ids_num + 1

		DATA.match_services[signup_match_id] = 
		{
			status=MATCH_STATUS.SIGNUP,

			match_my_id=signup_match_id,

			players={},

			player_count=0,

			begin_game_condi=DATA.match_config.signup_data_config.begin_game_condi,
			--需要启动游戏过程管理器的路径
			path=DATA.match_config.matching_path,

			player_signup_result_cache=DATA.player_signup_result_cache,

			enter_condition_cache=DATA.enter_condition_cache,

			data_config = DATA.match_config, -- 必须保存配置，因为 可能被 use_new_config() 替换掉

		}

	end

end

function PROTECTED.dispatch(dt)

	local count = 0
	while count<=DATA.dispatch_limit_second and DATA.dispatch_queue and not DATA.dispatch_queue:empty() do

		local _match_data = DATA.dispatch_queue:pop_front()

		-- 创建服务
		local ok,err = skynet.call("node_service","lua","create",false
											,_match_data.data_config.matching_path,_match_data.match_my_id)
		-- 
		if not ok then
			-- ###_temp 创建服务失败，这里应该退 所有报名玩家报名费？
			skynet.fail("create ".._match_data.data_config.matching_path.." fail,err:" .. tostring(err))
			return
		else
			_match_data.status=MATCH_STATUS.MATCHING
			DATA.cur_running_match=DATA.cur_running_match+1
		end
		
		if PUBLIC.players_start_match then
			PUBLIC.players_start_match(_match_data.players)
		end

		-- 初始化，传递 玩家列表
		nodefunc.call(_match_data.match_my_id,"init_match",DATA.my_id,_match_data.data_config
						,DATA.game_rule_config,DATA.player_msg_name,_match_data.players,
						_match_data.player_count,DATA.receive_result_cmd)
		
		count=count+1
	end
end

--继续判断是否开下一局
function PROTECTED.check_prepare_ready_match()

	if (DATA.match_config.signup_data_config.max_round~=-1
		and DATA.cur_running_match+DATA.complete_match+DATA.dispatch_queue:size()
				>=DATA.match_config.signup_data_config.max_round ) then
		-- 不能再开了

	else
		PROTECTED.prepare_ready_match_data()
	end

end

--检查报名的情况  
function PROTECTED.check_signup_situation(_signup_match_id)
	--达到开赛条件
	local msd = DATA.match_services[_signup_match_id]
	if msd.player_count == msd.begin_game_condi then
		msd.status=MATCH_STATUS.W_DISPATCH
		DATA.dispatch_queue:push_back(DATA.match_services[DATA.signup_match_my_id])

		for i,v in ipairs(DATA.wait_begin_match_list) do
			if _signup_match_id == v then
				table.remove(DATA.wait_begin_match_list,i)
				break
			end
		end

	end
end

--检查所有比赛都结束了，不会再有新的比赛了
function PROTECTED.all_match_over()
	
	if PUBLIC.all_match_over then
		PUBLIC.all_match_over()
	end

end


--游戏完成
function PROTECTED.game_complete(_match_svr_id)
	-- DATA.match_services[_match_svr_id].status="gameover"
	 DATA.match_services[_match_svr_id]=nil
	DATA.complete_match=DATA.complete_match+1
	DATA.cur_running_match=DATA.cur_running_match-1
	if DATA.signup_status==MATCH_STATUS.SIGNUP_END and DATA.cur_running_match==0 and DATA.dispatch_queue:size() then
		DATA.signup_status=MATCH_STATUS.OVER
		get_exit_time()
	end
	--是否在此写入数据库还需要考虑 ###_test

end

-- 得到已报名人数，要求报名人数
-- 返回： {result=错误码,signup_num=已报名人数}   ###_test   要考虑已经加入队列的情况
local _signup_player_count_cache = {result = 0,signup_num=0}
function PROTECTED.get_signup_player_num(_match_svr_id)

	if not _match_svr_id then

		local signup_match_id = next(DATA.signup_match_ready_ids)
		if not signup_match_id then
			return {result=1008}
		end
		
		_match_svr_id = signup_match_id

	end

	local msd = DATA.match_services[_match_svr_id]

	if msd then
		if msd.status==MATCH_STATUS.SIGNUP then
			_signup_player_count_cache.signup_num = msd.player_count
		else
			_signup_player_count_cache.signup_num = msd.enter_condition
		end

		return _signup_player_count_cache
	end

	return {result=2004}
end

-- 撤销报名
function PROTECTED.cancel_signup(_match_svr_id,_my_id)

	local msd = DATA.match_services[_match_svr_id]

	if msd and msd.status==MATCH_STATUS.SIGNUP then

		if msd.players[_my_id] then

			msd.players[_my_id] = nil

			msd.player_count = msd.player_count - 1

			DATA.signup_match_ready_ids[_match_svr_id] = _match_svr_id
			DATA.signup_match_ready_ids_num = DATA.signup_match_ready_ids_num + 1

			for i,v in ipairs(DATA.wait_begin_match_list) do
				if _match_svr_id == v then
					table.remove(DATA.wait_begin_match_list,i)
					break
				end
			end

			DATA.player_last_opt_time = os.time()

			return 0
		end
	end

	return 2004
end

--[[ 请求进入信息---条件和游戏类型
-- 说明：player agent 根据返回的条件，决定 扣除 还是比较 用户的财富值
-- 返回 errcode,数据
-- 如果 errcode 为 0 ，则成功，数据为以下结构：
	{
		{asset_type=PLAYER_ASSET_TYPES.xxx,condi_type=NOR_CONDITION_TYPE.xxx,value=xxx},
		{asset_type=PLAYER_ASSET_TYPES.xxx,condi_type=NOR_CONDITION_TYPE.xxx,value=xxx},
		...
	}
--]]

function PROTECTED.get_enter_info()

	-- 判断条件
	local ok,err = PROTECTED.check_allow_signup()
	if not ok then
		return err
	end

	local signup_match_id = next(DATA.signup_match_ready_ids)
	if not signup_match_id then
		return 2001
	end

	if signup_match_id and DATA.match_services[signup_match_id].enter_condition_cache then
		return 0,DATA.enter_info_result_cache
	end

	return 2002
end
--[[ 报名
-- 返回值：
--{
--	result  , -- 0 或错误
--	name , -- 游戏名字
-- 	is_cancel_signup , -- 是否可以取消报名。 1 可以 取消； 0 不可以
-- 	cancel_signup_cd , -- 允许取消报名的倒计时
-- 	match_svr_id, -- 比赛服务 my_id
--	total_players,-- 总人数
--	signup_num,-- 当前已报名人数
-- }
--]]
function PROTECTED.player_signup(_my_id)
	-- 注意：此函数内 不要call 别的，避免挂起 导致 重入

	-- 判断条件 ###_temp 不能 有因人数 导致的失败
	local ok,err = PROTECTED.check_allow_signup()
	if not ok then
		return {result=err}
	end

	local signup_match_id

	if basefunc.is_real_player(_my_id) then

		signup_match_id = next(DATA.signup_match_ready_ids)
		if not signup_match_id then
			return {result=2001}
		end
		DATA.signup_match_ready_ids[signup_match_id] = nil
		DATA.signup_match_ready_ids_num = DATA.signup_match_ready_ids_num - 1

		DATA.wait_begin_match_list[#DATA.wait_begin_match_list+1] = signup_match_id

		PROTECTED.check_prepare_ready_match()

	else

		signup_match_id = DATA.wait_begin_match_list[1]

	end

	local msd = DATA.match_services[signup_match_id]

	msd.players[_my_id] = _my_id
	msd.player_count = msd.player_count + 1

	local _ret = msd.player_signup_result_cache
	_ret.signup_num = msd.player_count
	_ret.signup_match_id = signup_match_id
	_ret.result = 0

	DATA.player_last_opt_time = os.time()

	-- 检查报名情况
	PROTECTED.check_signup_situation(signup_match_id)
	
	return _ret
end

function PROTECTED.start_sigup()
	local time=os.time()
	if time>=DATA.match_config.signup_data_config.begin_signup_time then
		DATA.signup_status=MATCH_STATUS.SIGNUP
	end 

	if (DATA.complete_match>=DATA.match_config.signup_data_config.max_round 
		and DATA.match_config.signup_data_config.max_round~=-1)
		or time>=DATA.match_config.signup_data_config.end_signup_time then
			DATA.signup_status=MATCH_STATUS.OVER
			get_exit_time()
			PROTECTED.all_match_over()
	end
	if DATA.signup_status==MATCH_STATUS.SIGNUP then
		DATA.dispatch_queue=basefunc.queue.new()
		PROTECTED.use_new_config()
		PROTECTED.prepare_ready_match_data()
	end

end

local dt=1
local function update()
	while DATA.signup_update_run_status do
		if DATA.signup_status==MATCH_STATUS.WAIT_BEGIN then
			PROTECTED.start_sigup()
		end

		PROTECTED.dispatch(dt)

		if DATA.signup_status==MATCH_STATUS.SIGNUP then
			PROTECTED.check_signup_end_time()
		end

		if DATA.signup_status==MATCH_STATUS.OVER then
			if os.time()>=DATA.exit_service_time then
				-- ###_test 退出
				PUBLIC.exit()
			end
		end
		skynet.sleep(dt*100)
	end
end


--[[
	DATA.signup_status   --状态
	DATA.service_id_count --下层服务的ID累计计数
	DATA.signup_match_id --下层服务的ID(准备的可以报名的id)
	DATA.match_services   --下层匹配服务的map（根据具体状态表示是否在进行中）
	DATA.signup_data_config   --报名数据 从配置表中获取的
	DATA.signup_basedata --报名数据记录  从数据库中获取的
--]]
function PROTECTED.init_data()

	DATA.signup_status=MATCH_STATUS.WAIT_BEGIN
	DATA.service_id_count=1
	DATA.signup_match_ready_ids={}
	DATA.signup_match_ready_ids_num=0
	DATA.match_services={}
	DATA.cur_running_match=0
	DATA.complete_match=0
	if DATA.signup_basedata and DATA.signup_basedata.complete_match then
		DATA.complete_match=DATA.signup_basedata.complete_match
	end

	DATA.signup_update_run_status=true
	--每秒分配的比赛限制
	DATA.dispatch_limit_second=DATA.dispatch_limit_second or 100

end 
-- *****报名数据  signup_data_config 
-- type --种类   人满即开  定时开
-- begin_signup_time|开始报名是时间	
-- end_signup_time|结束报名的时间	
-- begin_game_condi|开始条件（满多少人开始）	
-- max_round|最多开多少场	
-- max_concurrency_game|并发数	
-- is_cancel_sign|是否允许取消报名	
-- sign_condi|报名条件	
-- close_time|结束时等待多久彻底关闭（杀死服务）
--*****

-- *****数据库数据  signup_basedata 
--  open_round  --以开场次
function PROTECTED.init()
	
	base.CMD.player_signup =PROTECTED.player_signup
	base.CMD.get_signup_player_num=PROTECTED.get_signup_player_num
	base.CMD.cancel_signup=PROTECTED.cancel_signup
	base.CMD.get_enter_info=PROTECTED.get_enter_info

	PROTECTED.init_data()
	skynet.fork(update)
	
end

return PROTECTED



-- STATUS =
-- {
-- 	DISABLE = -1, -- 禁用（已经被 管理员配置为禁用，不允许再报名）
-- 	WAIT_BEGIN = 0, -- 等待报名开始
-- 	SIGNUP = 2, -- 报名中
-- 	SIGNUP_END = 3, -- 报名结束
-- 	MATCH= 4, -- 正在比赛
-- 	OVER = 7, -- 比赛结束
-- }




