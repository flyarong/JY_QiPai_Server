local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local skynet = require "skynet_plus"
require "normal_enum"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

DATA.task_center_op_interface_protect = {}
local PROTECT = DATA.task_center_op_interface_protect


----- 载入任务服务配置
function PROTECT.load_task_server_cfg(raw_config)
	--local raw_config = base.reload_config("task_server")

	--DATA.task_main_config = {}  
	local main_config = {}  

	local aws = {}
	for i,ad in ipairs(raw_config.award_data) do
		
		aws[ad.award_id] = aws[ad.award_id] or {}
		local len = #aws[ad.award_id]+1

		local target_asset_type = ad.asset_type
		---- 处理限时道具
		local str_split_vec = basefunc.string.split(ad.asset_type, "_")

		local obj_lifetime = nil
		if str_split_vec and type(str_split_vec) == "table" and next(str_split_vec) then
			if str_split_vec[1] == "obj" then
				obj_lifetime = 86400
				if tonumber(str_split_vec[#str_split_vec]) then
					target_asset_type = ""
					for i=1,#str_split_vec - 1 do
						target_asset_type = target_asset_type .. str_split_vec[i]
						if i ~= #str_split_vec - 1 then
							target_asset_type = target_asset_type .. "_"
						end
					end

					obj_lifetime = tonumber( str_split_vec[#str_split_vec] )
				end
			end
		end

		aws[ad.award_id][len] = {
			asset_type = target_asset_type,
			value = ad.asset_count,
			weight = ad.get_weight or 1,
			broadcast_content = ad.broadcast_content,
		}

		if obj_lifetime then
			aws[ad.award_id][len].value = nil
			aws[ad.award_id][len].lifetime = obj_lifetime
		end

	end

	----- 条件表
	local condition = {}
	for id,data in pairs(raw_config.condition) do
		condition[ data.condition_id ] = condition[ data.condition_id ] or {}
		local cond = condition[ data.condition_id ]
		cond[data.condition_name] = { condition_value = data.condition_value , judge_type = data.judge_type }
	end


	for id,td in pairs(raw_config.task) do

		main_config[id]=td

		for i,cd in ipairs(raw_config.process_data) do
			if td.process_id == cd.process_id then
				if type(cd.process) == "number" then
					cd.process = { cd.process }
				end

				main_config[id].condition_type = cd.condition_type
				main_config[id].condition_data = basefunc.deepcopy( condition[ cd.condition_id ] or {} )
				main_config[id].get_award_type = cd.get_award_type or "nor"
				main_config[id].process_data=cd.process
				main_config[id].award_data={}

				---- 如果是一个数字就转成数组
				if not cd.awards then
					cd.awards = {}
				elseif type(cd.awards) == "number" then
					cd.awards = { cd.awards }
				end
				for i,ai in ipairs(cd.awards) do
					main_config[id].award_data[i] = basefunc.deepcopy( aws[ai] )
				end

			end
		end

		main_config[id].process_id=nil

	end

	return main_config
end

---- 发给所有在线玩家，任务更新
function PROTECT.send_players_task_config_refresh()
	local num = 10

	skynet.fork(function ()
		
		local player_status_list = skynet.call(DATA.service_config.data_service,"lua","get_player_status_list")

		local sn = 0

		--发在线的玩家
		for player_id,data in pairs(player_status_list) do
			if data.status == "on" and basefunc.chk_player_is_real(player_id) then
				
				--发送活动状态数据
				nodefunc.send(player_id,"distribute_task")

				sn = sn + 1
				if sn > num then
					skynet.sleep(1)
					sn = 0
				end

			end
		end

	end)
end


function PROTECT.refresh_config()

	nodefunc.query_global_config("task_server", function(config)
		DATA.task_main_config = PROTECT.load_task_server_cfg(config)
		
		PROTECT.send_players_task_config_refresh()
	end)

	nodefunc.query_global_config("task_zajindan_server", function(config)
		DATA.task_zajindan_server = PROTECT.load_task_server_cfg(config)

		PROTECT.send_players_task_config_refresh()
	end)

	nodefunc.query_global_config("task_buyu_daily_server", function(config)
		DATA.task_buyu_daily_server = PROTECT.load_task_server_cfg(config)

		PROTECT.send_players_task_config_refresh()
	end)

	nodefunc.query_global_config("duiju_hongbao",function (duiju_hongbao_cfg)
		DATA.hongbao_task_config = duiju_hongbao_cfg.main[1]
	end)

	nodefunc.query_global_config("vip_duiju_hongbao_server",function (vip_duiju_hongbao_cfg)
		DATA.vip_duiju_hongbao_task_config = vip_duiju_hongbao_cfg.main[1]
	end)

	nodefunc.query_global_config("jingyu_award_box",function (jingyu_award_box_cfg)
		DATA.jingyu_award_box_task_config = jingyu_award_box_cfg.main[1]
	end)

	nodefunc.query_global_config("stepstep_money_server",function (stepstep_money_cfg)
		DATA.stepstep_money_config = stepstep_money_cfg
	end)

end

function PROTECT.clear_refresh_config()
	nodefunc.clear_global_config_cb("task_server")
	nodefunc.clear_global_config_cb("task_zajindan_server")
	nodefunc.clear_global_config_cb("duiju_hongbao")
	nodefunc.clear_global_config_cb("vip_duiju_hongbao_server")
	nodefunc.clear_global_config_cb("jingyu_award_box")
	nodefunc.clear_global_config_cb("stepstep_money_server")
end

-- 载入所有玩家数据
function PUBLIC.load_all_player_task_data()
	local task_data = skynet.call(DATA.service_config.data_service,"lua","query_all_player_task_data")
	if task_data then
		DATA.player_task_data = task_data
	end
end

-- 获取某个玩家的任务数据， 缓存 拿
function CMD.query_player_task_data(_player_id)
	return DATA.player_task_data[_player_id]
end

function CMD.query_player_one_task_data(_player_id , _task_id)
	DATA.player_task_data[_player_id] = DATA.player_task_data[_player_id] or {}
	return DATA.player_task_data[_player_id][_task_id]
end

function CMD.update_player_task_other_data(_player_id , _task_id , _other_data)
	if DATA.player_task_data[_player_id] and DATA.player_task_data[_player_id][_task_id] then
		local task_data = DATA.player_task_data[_player_id][_task_id]

		task_data.other_data = _other_data

		skynet.send(DATA.service_config.data_service,"lua","update_player_task_other_data"
					,_player_id
					,_task_id
					,_other_data
					)

	end
end

-- 更新or新增 玩家数据
function CMD.add_or_update_task_data(_player_id , _task_id , _process , _task_round , _create_time , _task_award_get_status)
	if _task_id == 201 then
		print("xxxxxxxxxxxxx------------update_data3:",201)
	end

	local is_no_data = false
	if not DATA.player_task_data[_player_id] or not DATA.player_task_data[_player_id][_task_id] then
		is_no_data = true
	end


	DATA.player_task_data[_player_id] = DATA.player_task_data[_player_id] or {}
	DATA.player_task_data[_player_id][_task_id] = DATA.player_task_data[_player_id][_task_id] or {}

	local task_data = DATA.player_task_data[_player_id][_task_id]


	task_data.player_id = _player_id
	task_data.task_id = _task_id
	task_data.process = _process
	task_data.task_round = _task_round
	task_data.create_time = _create_time
	task_data.task_award_get_status = _task_award_get_status

	---- 数据库更新
	skynet.send(DATA.service_config.data_service,"lua","update_player_task"
					,_player_id
					,_task_id
					,_process
					,_task_round
					,_create_time
					,_task_award_get_status)
end

--- 删掉一个任务
function CMD.delete_player_task(_player_id , _task_id)
	if DATA.player_task_data[_player_id] and DATA.player_task_data[_player_id][_task_id] then
		DATA.player_task_data[_player_id][_task_id] = nil

		skynet.send(DATA.service_config.data_service,"lua","delete_player_task" , _player_id , _task_id )
	end
end

--- 增加任务日志
function CMD.add_player_task_log( _player_id , _task_id , _process_change , _now_progress )
	if _process_change ~= 0 then
		skynet.send(DATA.service_config.data_service,"lua","add_player_task_log" ,_player_id , _task_id , _process_change , _now_progress )
	end
end

function CMD.add_player_task_award_log( _player_id , _task_id , _award_progress_lv , _asset_type , _asset_value )
	skynet.send(DATA.service_config.data_service,"lua","add_player_task_award_log" , _player_id , _task_id , _award_progress_lv , _asset_type , _asset_value )
end

-- 总配置
function CMD.get_main_config()

	local main_config_tem = basefunc.deepcopy(DATA.task_main_config) or {}
	local zajindan_config_tem = basefunc.deepcopy(DATA.task_zajindan_server) or {}
	local buyu_daily_config_tem = basefunc.deepcopy(DATA.task_buyu_daily_server) or {}

	---- main_config_tem 是不常改任务，以它的任务优先级最高

	local ret = basefunc.merge( main_config_tem , zajindan_config_tem )
	ret = basefunc.merge( ret , buyu_daily_config_tem )

	-- dump( main_config_tem , "--------------------main_config_tem:" )
	-- dump( zajindan_config_tem , "--------------------zajindan_config_tem:" )

	return ret

end


function CMD.get_hongbao_task_config()

	return DATA.hongbao_task_config

end


function CMD.get_vip_duiju_hongbao_task_config()

	return DATA.vip_duiju_hongbao_task_config

end


function CMD.get_jingyu_award_box_task_config()

	return DATA.jingyu_award_box_task_config

end

function CMD.get_stepstep_money_config()
	return DATA.stepstep_money_config
end

function PROTECT.on_destroy()
	PROTECT.clear_refresh_config()
end

function PROTECT.on_load()
	PROTECT.refresh_config()
end

--- 开启 七天 bbsc 权限
function CMD.open_bbsc_day_permit(player_id,day_num)
	local bbsc_data = skynet.call(DATA.service_config.data_service,"lua","query_player_stepstep_money" , player_id )

	DATA.stepstep_money_over_day_num = 15
	--- 没有要新增
	if not bbsc_data then
		bbsc_data = {}
		bbsc_data.player_id = player_id
		bbsc_data.now_big_step = 1
		bbsc_data.now_little_step = 1
		bbsc_data.last_op_time = os.time()
		bbsc_data.can_do_big_step = 1
		bbsc_data.bbsc_version = "new"
		bbsc_data.over_time = os.time() + DATA.stepstep_money_over_day_num * 86400
	end

	bbsc_data.can_do_big_step = day_num

	skynet.send(DATA.service_config.data_service,"lua","update_player_stepstep_money" 
		, bbsc_data.player_id 
		, bbsc_data.now_big_step
		, bbsc_data.now_little_step
		, bbsc_data.last_op_time
		, bbsc_data.can_do_big_step
		, bbsc_data.bbsc_version
		, bbsc_data.over_time
		)

	nodefunc.send( player_id , "set_bbsc_can_day" , day_num )
end

function CMD.add_task_progress( _player_id , _task_id , _add_value)
	if DATA.player_task_data[_player_id] and DATA.player_task_data[_player_id][_task_id] then
		local task_data = DATA.player_task_data[_player_id][_task_id]
		task_data.process = task_data.process + _add_value

		CMD.add_or_update_task_data( _player_id , _task_id , task_data.process , task_data.task_round , task_data.create_time , task_data.task_award_get_status )
		nodefunc.send( _player_id , "add_task_progress" , _task_id , _add_value )
	end
end

local function query_data(_sql)

	local ret = skynet.call(DATA.service_config.data_service,"lua","db_query",_sql)
	if( ret.errno ) then
		print(string.format("query_data sql error: sql=%s\nerr=%s\n",_sql,basefunc.tostring( ret )))
		return nil
  	end
  
	
	return ret
end

---- add by wss 
function CMD.fix_zajindan_task_date()
	local all_real_player = {}

	for player_id , data in pairs(all_player_info) do
		if basefunc.chk_player_is_real(player_id) then
			all_real_player[#all_real_player + 1] = player_id
		end
	end
	dump(all_real_player , "------------------all real_player :")

	for key , player_id in pairs(all_real_player) do
		---总进度
		local total_process = query_data( string.format( [[select ifnull(sum(progress_change),0) total_process from player_task_log
					 where player_id = '%s' and task_id = '50';]], player_id) )

		print("------------player_id , total_process:",player_id , total_process)
		--dump(total_process , "---------total_process:")
		if total_process and total_process[1] and total_process[1].total_process then
			total_process = total_process[1].total_process
		end

		if total_process then
			if total_process > 380000000 then
				total_process = 380000000
			end

			query_data( string.format( [[update player_task set process = %s where player_id = '%s' and task_id = '50';]] , total_process , player_id))
		end

		----- 3-15的领奖次数
		local last_get_award_num = query_data( string.format( [[select count(*) get_num from player_asset_log
					 where id = '%s' and change_type = 'task_award' and change_id = '50' and date > '2019-03-15 09:00:00' and date < '2019-03-16 06:00:00';]], player_id) )
		--dump(last_get_award_num , "---------last_get_award_num:")
		if last_get_award_num and last_get_award_num[1] and last_get_award_num[1].get_num then
			last_get_award_num = last_get_award_num[1].get_num
		end

		----- 3-16的领奖次数
		local last_get_award_num2 = query_data( string.format( [[select count(*) get_num from player_asset_log
					 where id = '%s' and change_type = 'task_award' and change_id = '50' and date > '2019-03-16 06:00:00' and date < '2019-03-17 06:00:00';]], player_id) )
		--dump(last_get_award_num2 , "---------last_get_award_num2:")
		if last_get_award_num2[1] and last_get_award_num2[1].get_num then
			last_get_award_num2 = last_get_award_num2[1].get_num
		end

		local award_num = math.max(last_get_award_num,last_get_award_num2)

		if award_num then
			query_data( string.format( [[update player_task set task_round = %s where player_id = '%s' and task_id = '50';]] , award_num + 1 , player_id))
		end


	end
end


return PROTECT