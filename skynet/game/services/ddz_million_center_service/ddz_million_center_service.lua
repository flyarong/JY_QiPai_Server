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
local million_config_module = require "ddz_million_center_service.million_config_module"
require "ddz_match_enum"
require "normal_enum"

require "printfunc"
local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

DATA.cmd_signal = basefunc.signal.new()

-- 服务配置
DATA.service_config = nil
--当前已经运行到的match
local cur_match_idx
-- 比赛配置
local million_configs

-- 比赛管理 服务 ： match_info id 
local match_manager_services 

--[[
	
	比赛状态 status  0 没有比赛  1 未开始  2 报名  3 比赛中 4 比赛结束
	
	报名费 ticket

	奖金 bonus

	报名时间 signup_time

	开始时间 begin_time

	游戏管理者ID mgr_id 
--]] 
local match_info

local match_status_data = {}

local id_count=0
local function create_service_id()
	id_count=id_count+1
	return "ddz_million_"..id_count
end

-- 创建游戏服务
local function create_match_services(idx)

	local new_service_id = create_service_id()

	local ok,state = skynet.call("node_service","lua","create",false
								,"ddz_million_service/ddz_million_service",new_service_id,million_configs[idx])
	if ok then
		local _config=million_configs[idx].base_info
		match_manager_services =new_service_id
		match_info={
					status=1,
					ticket=_config.ticket,
					bonus=_config.bonus,
					signup_time=_config.signup_time,
					begin_time=_config.begin_time,
					mgr_id=new_service_id,
					issue=_config.issue,
			}

		--更新排行的期数
		skynet.send(DATA.service_config.data_service,"lua",
					"update_player_million_bonus_rank",{},_config.issue-1)

	else
		skynet.fail(string.format("lauch ddz_million_service error : %s!",tostring(state)))
	end

	
end



local function create_next_match_services()
	local cur_time=os.time()
	for idx=cur_match_idx+1,#million_configs do
		local _config=million_configs[idx].base_info
		if _config.signup_time>cur_time then
			cur_match_idx=idx
			create_match_services(cur_match_idx)
			return
		end
	end 
	print("万人大奖赛 没有接下来的比赛了")
end

function CMD.refresh_match()
	if match_manager_services and match_info then
		--此时比赛已经开始 不能停止比赛
		if match_info.status==DDZM_STATUS.SIGNUP or match_info.status==DDZM_STATUS.MATCH then
			
			return false

		else

			--通知现有的比赛自行了断
			nodefunc.send(match_manager_services,"stop_service")
			
		end
	end

	local cur_time=os.time()
	for idx,_config in ipairs(million_configs) do
		if _config.base_info.signup_time>cur_time then
			cur_match_idx=idx
			create_match_services(cur_match_idx)
			return
		end
	end

	match_info = nil
	
	print("万人大奖赛 没有接下来的比赛了")
end


function CMD.get_match_info()
	return match_info
end


function CMD.change_match_status(status)

	match_info.status=status

	if match_info.status==DDZM_STATUS.FINISHED then
		--比赛已经结束了 比赛服务将自行结束
		match_manager_services = nil
		match_info.mgr_id = nil

		--自动创建下一个比赛
		create_next_match_services()
	end

end


-- 管理指令： 准备关闭，锁定服务器，不允许新场、等待自然结束
--function CMD.control_prepare_close()
--	for id,manager in pairs(match_manager_services) do
--		manager:match_lock()
--	end
--end


-- 重新加载配置， by lyx
-- 失败 返回 错误号
function CMD.reload_config()

	million_config_module.reload_config_info()

	--获取比赛配置
	million_configs = million_config_module.get_match_datas()

	--CMD.refresh_match()

	print("ddz_million_manager config reloaded !")

	return 0
end

function CMD.start(_service_config)

	DATA.service_config=_service_config

	-- 初始化比赛配置
	million_config_module.init_million_config_info()

	--获取比赛配置
	million_configs = million_config_module.get_match_datas()
	CMD.refresh_match()

	nodefunc.register_game("ddz_million_game")

end

-- 启动服务
base.start_service(nil,"dbwg_ctr_ser")

