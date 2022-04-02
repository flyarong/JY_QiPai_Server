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

DATA.tuoguan_signup_num = 0

-- 初始化 报名 结果数据 缓存
local function init_player_signup_result_cache()
	DATA.player_signup_result_cache = {
		result = 0,
		name = DATA.match_config.match_data_config.name,
		is_cancel_signup = DATA.match_config.signup_data_config.is_cancel_sign,
		cancel_signup_cd = DATA.match_config.signup_data_config.cancel_cd,
		total_round = #DATA.match_config.match_game_config,
	}
end

--组织数据结构
local function use_config()

	DATA.enter_condition_cache = {}

		-- 构建 玩家进入条件 缓存 数据
	for _condi_id,_condi_data in pairs(DATA.match_config.match_enter_config) do

		DATA.enter_condition_cache[#DATA.enter_condition_cache+1]={}
		local ecc = DATA.enter_condition_cache[#DATA.enter_condition_cache]
		for i,cd in ipairs(_condi_data) do
			ecc[#ecc+1]={
				condi_type = cd.judge_type,
				asset_type = cd.asset_type,
				value = cd.asset_count,
			}
		end

	end

	DATA.enter_info_result_cache = {
		condi_data = DATA.enter_condition_cache,
		game_type = DATA.match_config.game_type,
		match_model = DATA.match_config.match_model,
		begin_type = "dingshikai",
	}

	init_player_signup_result_cache()

	--------
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

	return true
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
function PROTECTED.prepare_next_match_data()

		DATA.signup_match_my_id = create_service_id()

		DATA.signup_players = {}
		DATA.signup_players_count=0

		DATA.match_services[DATA.signup_match_my_id] = {
			status=MATCH_STATUS.SIGNUP,

			match_my_id=DATA.signup_match_my_id,

			players=DATA.signup_players,

			player_count=0,

			begin_game_condi=DATA.begin_game_condi,
			--需要启动游戏过程管理器的路径
			path=DATA.match_config.matching_path,

			player_signup_result_cache=DATA.player_signup_result_cache,

			enter_condition_cache=DATA.enter_condition_cache,

			data_config = DATA.match_config, -- 必须保存配置，因为 可能被 use_new_config() 替换掉
		}
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
		
		-- 初始化，传递 玩家列表
		nodefunc.call(_match_data.match_my_id,"init_match",DATA.my_id,_match_data.data_config
						,DATA.game_rule_config,DATA.player_msg_name,_match_data.players
						,_match_data.player_count,DATA.receive_result_cmd)
		
		count=count+1
	end
end
--继续接受报名或结束报名
function PROTECTED.next_or_end()

	DATA.signup_status=MATCH_STATUS.SIGNUP_END

	-- body
end

--检查报名的情况  
function PROTECTED.check_signup_situation()
	--达到开赛条件
	if DATA.signup_players_count>=DATA.match_services[DATA.signup_match_my_id].data_config.signup_data_config.begin_game_condi then
		DATA.match_services[DATA.signup_match_my_id].status=MATCH_STATUS.W_DISPATCH
		DATA.match_services[DATA.signup_match_my_id].player_count = DATA.signup_players_count
		DATA.dispatch_queue:push_back(DATA.match_services[DATA.signup_match_my_id])
		PROTECTED.next_or_end()
	else
		--人数不够 直接结束
		DATA.signup_status=MATCH_STATUS.OVER
		get_exit_time()
		print(DATA.my_id.."--人数不够 直接结束")
		
		if PUBLIC.match_discard then
			PUBLIC.match_discard()
		end

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

	_match_svr_id = _match_svr_id or DATA.signup_match_my_id

	if DATA.match_services[_match_svr_id] then
		if DATA.match_services[_match_svr_id].status==MATCH_STATUS.SIGNUP then
			_signup_player_count_cache.signup_num = DATA.signup_players_count
		else
			_signup_player_count_cache.signup_num = DATA.match_services[_match_svr_id].enter_condition
		end
		return _signup_player_count_cache
	end
	return {result=2004}
end

-- 撤销报名
function PROTECTED.cancel_signup(_match_svr_id,_my_id)

	if DATA.signup_status == MATCH_STATUS.SIGNUP then
		if _match_svr_id == DATA.signup_match_my_id then
			if DATA.signup_players[_my_id] then
				DATA.signup_players[_my_id]=nil
				DATA.signup_players_count=DATA.signup_players_count-1

				if not basefunc.chk_player_is_real(_my_id) then
					DATA.tuoguan_signup_num = DATA.tuoguan_signup_num - 1
				end

				return 0
			end
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

	if DATA.signup_match_my_id and DATA.match_services[DATA.signup_match_my_id].enter_condition_cache then
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

	-- 加入到已报名列表
	DATA.signup_players[_my_id] = _my_id
	DATA.signup_players_count=DATA.signup_players_count+1
	print("player signup id:",_my_id)

	if not basefunc.chk_player_is_real(_my_id) then
		DATA.tuoguan_signup_num = DATA.tuoguan_signup_num + 1
	end

	local _ret =DATA.match_services[DATA.signup_match_my_id].player_signup_result_cache
	_ret.signup_num = DATA.signup_players_count
	_ret.signup_match_id = DATA.signup_match_my_id
	_ret.result = 0

	return _ret
end

function PROTECTED.start_sigup()
	local time=os.time()
	if time>=DATA.match_config.signup_data_config.begin_signup_time then
		DATA.signup_status=MATCH_STATUS.SIGNUP
	end 

	DATA.signup_end_time=DATA.match_config.signup_data_config.begin_signup_time
							+DATA.match_config.signup_data_config.signup_dur
							
	if time>=DATA.signup_end_time then
		DATA.signup_status=MATCH_STATUS.OVER
		get_exit_time()
		print(DATA.my_id.."--此比赛已经过期了")
	end

	if DATA.signup_status==MATCH_STATUS.SIGNUP then
		DATA.dispatch_queue=basefunc.queue.new()
		PROTECTED.use_new_config()
		PROTECTED.prepare_next_match_data()
	end

end

local dt=1
local function update()
	while DATA.signup_update_run_status do
		if DATA.signup_status==MATCH_STATUS.WAIT_BEGIN then
			PROTECTED.start_sigup()
		end

		PROTECTED.dispatch(dt)

		if DATA.signup_status==MATCH_STATUS.OVER then
			if os.time()>=DATA.exit_service_time then
				-- ###_test 退出
				PUBLIC.exit()
			end
		end
		if DATA.signup_status==MATCH_STATUS.SIGNUP then 
		-- print("match_begin:",DATA.signup_end_time-os.time())
			if os.time()>DATA.signup_end_time then
				PROTECTED.check_signup_situation()
			end
		end
		skynet.sleep(dt*100)
	end
end


--[[
	DATA.signup_status   --状态
	DATA.service_id_count --下层服务的ID累计计数
	DATA.signup_match_my_id --下层服务的ID
	DATA.signup_players     --已报名的玩家的map
	DATA.signup_players_count --已报名的玩家计数
	DATA.match_services   --下层匹配服务的map（根据具体状态表示是否在进行中）
	DATA.signup_data_config   --报名数据 从配置表中获取的
	DATA.signup_basedata --报名数据记录  从数据库中获取的
--]]
function PROTECTED.init_data()

	DATA.signup_status=MATCH_STATUS.WAIT_BEGIN
	DATA.service_id_count=1
	DATA.signup_match_my_id=nil
	DATA.signup_players=nil
	DATA.signup_players_count=0
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
























