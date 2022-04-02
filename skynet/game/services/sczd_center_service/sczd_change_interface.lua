---- 对外改变接口



local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local skynet = require "skynet_plus"
require "normal_enum"
require "printfunc"
local task_base_func = require "task.task_base_func"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECT = {}

-- 查询数据，返回结果集，出错则返回 nil
function PUBLIC.query_data(_sql)

	local ret = skynet.call(DATA.service_config.data_service,"lua","db_query",_sql)
	if( ret.errno ) then
		print(string.format("query_data sql error: sql=%s\nerr=%s\n",_sql,basefunc.tostring( ret )))
		return nil
	end
	
	return ret
end

--- 把sql插入队列中
function PUBLIC.db_exec(_sql , _queue_name)
  skynet.send(DATA.service_config.data_service,"lua","db_exec",_sql , _queue_name)
end

--local query_data=PUBLIC.query_data
local db_exec = PUBLIC.db_exec
--- 玩家登录消息
function CMD.player_login_msg( player_id )
	if not DATA.player_details[player_id] or not DATA.player_details[player_id].base_info then
		PUBLIC.load_base_info(player_id)
	end

	if DATA.player_details[player_id] then
		DATA.player_details[player_id].online_num = DATA.player_details[player_id].online_num or 0
		DATA.player_details[player_id].online_num = DATA.player_details[player_id].online_num + 1

		-- DATA.player_details[player_id].name = 
		DATA.player_details[player_id].is_online = true
	end

	if DATA.player_details[player_id] and DATA.player_details[player_id].my_main_info_for_parent then
		--- 更新名字
		DATA.player_details[player_id].my_main_info_for_parent.name = skynet.call(DATA.service_config.data_service,"lua","get_player_info",player_id,"player_info","name")
		---如果没登录过，设置登录状态&上一次登录时间
		if not DATA.player_details[player_id].my_main_info_for_parent.logined or DATA.player_details[player_id].my_main_info_for_parent.logined == 0 then
			DATA.player_details[player_id].my_main_info_for_parent.logined = 1	
		end
		DATA.player_details[player_id].my_main_info_for_parent.last_login_time = os.time()
	end

	print("---------------------------------- sczd_login")
end

--- 玩家登出消息，用于刷新玩家最后一次登录时间
function CMD.player_logout_msg(player_id )
	if DATA.player_details[player_id] and DATA.player_details[player_id].my_main_info_for_parent then
		--- do
		local data_ref = DATA.player_details[player_id].my_main_info_for_parent
		data_ref.last_login_time = os.time()
		if not data_ref.logined or data_ref.logined ~= 1 then
			data_ref.logined = 1
		end

		DATA.player_details[player_id].is_online = false
		print("---------------------------------- sczd_logout")
	end
end

--- 玩家第一次登录
--[[function CMD.player_first_login_msg(player_id)
	if not DATA.player_details[player_id] or not DATA.player_details[player_id].my_main_info_for_parent then
		PUBLIC.load_base_info(player_id)
	end

	if DATA.player_details[player_id] and DATA.player_details[player_id].my_main_info_for_parent then
		DATA.player_details[player_id].my_main_info_for_parent.is_have_login = 1
	end

end--]]

--- 步步生财 大步骤完成 
function PROTECT.bbsc_progress_complete(player_id , compelted_big_step, rebate_value)
	if not DATA.player_relation[player_id] then
		return 
	end

	print("PROTECT.bbsc_progress_complete:",player_id , "bbsc" , compelted_big_step , rebate_value)

	--- 某人某人增加贡献
	PUBLIC.add_palyer_contribute( player_id , "bbsc" , compelted_big_step , rebate_value )

end

--- 步步生财，大步骤完成消息
function CMD.bbsc_progress_msg(player_id , complete_big_step )
	print("xxxx------------------- bbsc_progress_msg 1")
	--- bbsc大步骤完成，通知一下我的邀请人，以便完成任务

	local parent_id = DATA.player_relation[player_id] and DATA.player_relation[player_id].parent_id or nil
	repeat
		print("xxxx------------------- bbsc_progress_msg 2")
	
	if parent_id then
		local parent_bbsc_data = skynet.call(DATA.service_config.data_service,"lua","query_player_stepstep_money" , parent_id ) 

		if parent_bbsc_data then

			local now_big_step = parent_bbsc_data.now_big_step
			local now_little_step = parent_bbsc_data.now_little_step

			----- 过期了，任务不加
			if parent_bbsc_data.over_time then
				local now_time = os.time()
				if now_time > parent_bbsc_data.over_time then
					break
				end
			end

			local config = skynet.call(DATA.service_config.task_center_service,"lua","get_stepstep_money_config")

			local task_config = skynet.call(DATA.service_config.task_center_service,"lua","get_main_config")
			
			local target_task_vec = config.task
			if parent_bbsc_data.bbsc_version == "new" then
				target_task_vec = config.task_new
			end

			
			for key,data in pairs(target_task_vec) do
				--- 父亲节点未到这一步，依旧可以加进度。
				if data.big_step_id > now_big_step or (data.big_step_id == now_big_step and data.little_step_id >= now_little_step) then
					local task_id = data.task_id
					local task_config = task_config[task_id]

					if task_config.condition_type == "invite_play_bbsc" then
						local c_data = task_config.condition_data
						if c_data.complete_bbsc_big_step 
							and basefunc.compare_value( complete_big_step , c_data.complete_bbsc_big_step.condition_value , c_data.complete_bbsc_big_step.judge_type ) then
							--- 加进度
							local task_ob_data = skynet.call(DATA.service_config.task_center_service,"lua","query_player_task_data" , parent_id )
							task_ob_data = task_ob_data and task_ob_data[task_id] or nil

							task_ob_data = task_ob_data or {
								player_id = parent_id,
								task_id = task_id,
								process = 0,
								task_round = 1,
								create_time = os.time(),
								task_award_get_status = 0,
							}

							local max_process = task_base_func.get_max_process(task_config.process_data)

							if task_ob_data.process < max_process then
								task_ob_data.process = task_ob_data.process + 1

								--- 加日志
								--PUBLIC.add_player_task_log(task_ob_data.task_id , 1 , task_ob_data.process)
								skynet.send(DATA.service_config.task_center_service,"lua","add_player_task_log"
									,task_ob_data.player_id
									,task_ob_data.task_id
									, 1
									,task_ob_data.process)

								skynet.send(DATA.service_config.task_center_service,"lua","add_or_update_task_data"
									,task_ob_data.player_id
									,task_ob_data.task_id
									,task_ob_data.process
									,task_ob_data.task_round
									,task_ob_data.create_time
									,task_ob_data.task_award_get_status )


								---- 通知，进度增加
								nodefunc.send(parent_id,"update_step_task_process", task_id , task_ob_data.process , task_ob_data.process == max_process )
							end
						end
					end
				end
			end

		end
	end

	until true

	print("xxxx------------------- bbsc_progress_msg 3")
	if DATA.bbsc_rebate_cfg then
		for key,data in pairs( DATA.bbsc_rebate_cfg ) do
			if data.rebate_big_step == complete_big_step then
				--- 给上级 加奖励
				PROTECT.bbsc_progress_complete(player_id , complete_big_step , data.rebate_value)

				break
			end
		end
	end

	dump(DATA.player_relation[player_id] , "-------DATA.player_relation[player_id]:")

	print("xxxx------------------- bbsc_progress_msg 4" , parent_id)
	----- 下级完成第有效天bbsc, 如果上级收益功能开通， 给上级 返利
	if parent_id then
		if not DATA.player_details[parent_id] or not DATA.player_details[parent_id].base_info then
			PUBLIC.load_base_info(parent_id)
		end
		print("xxxx------------------- bbsc_progress_msg 5")
		if complete_big_step == DATA.xj_award_bbsc_big_step and DATA.player_details[parent_id].base_info.is_activate_xj_profit == 1 then
			-- 父亲是否购买推广礼包
			local parent_gold_info = skynet.call(DATA.service_config.goldpig_center_service,"lua","query_player_goldpig_data" , parent_id)
			print("xxxx------------------- bbsc_progress_msg 6")
			local rebate_value = 0
			if parent_gold_info.is_buy_goldpig2 == 1 then
				rebate_value = DATA.tglb2_buy_xj_award
			elseif parent_gold_info.is_buy_goldpig1 == 1 or parent_gold_info.is_buy_goldpig == 1 then
				rebate_value = DATA.tglb1_buy_xj_award
			else
				rebate_value = DATA.no_buy_tglb_xj_award
			end

			-------------- 判断 父亲的 人数
			local parent_son_count = DATA.player_details[parent_id].base_info.all_son_count
			local should_rebate = 0
			if parent_son_count <= 3 then
				should_rebate = DATA.no_buy_tglb_xj_award
			elseif parent_son_count > 3 and parent_son_count <= 10 then
				should_rebate = DATA.no_buy_tglb_xj_award2
			elseif parent_son_count > 10 and parent_son_count <= 20 then
				should_rebate = DATA.tglb1_buy_xj_award
			elseif parent_son_count > 20 then
				should_rebate = DATA.tglb2_buy_xj_award
			end

			if should_rebate > rebate_value then
				rebate_value = should_rebate
			end

			
			PUBLIC.add_palyer_contribute( player_id , "bbsc" , DATA.xj_award_bbsc_big_step , rebate_value )

			----------------- 如果自己有千元赛缓存，把千元赛缓存给父亲，并清0
			local ret = PUBLIC.query_data( string.format( [[select qys_contribution_cache_for_parent from sczd_activity_info where player_id = '%s';]] , player_id ) )
			if ret and ret[1] then
				local qys_cache = ret[1].qys_contribution_cache_for_parent or 0
				if qys_cache > 0 then
					----- 给上级加奖励
					PUBLIC.add_palyer_contribute( player_id , "qys_bisai" , 150 , qys_cache )
					PUBLIC.query_data( string.format( [[update sczd_activity_info set qys_contribution_cache_for_parent = 0 where player_id = '%s';]] , player_id ) )
				end

			end


		end
	end

end

--- 步步生财大步骤改变消息
function CMD.bbsc_big_step_change_msg(player_id , now_big_step )
	if not DATA.player_details[player_id] or DATA.player_details[player_id].my_deatails_info_for_parent then
		PUBLIC.load_my_deatails_info_for_parent( player_id )
	end

	if DATA.player_details[player_id] and DATA.player_details[player_id].my_deatails_info_for_parent then
		DATA.player_details[player_id].my_deatails_info_for_parent.my_bbsc_progress = now_big_step
	end
end

---- 玩家完成千元赛 消息
function CMD.qys_game_complete( _player_id , _game_id , _rank )
	print("xxxxxx-----------------qys_game_complete:",_player_id , _game_id , _rank)
	local parent_id = DATA.player_relation[_player_id] and DATA.player_relation[_player_id].parent_id or nil
	if parent_id then
		if not DATA.player_details[parent_id] or not DATA.player_details[parent_id].base_info then
			PUBLIC.load_base_info(parent_id)
		end
		print("xxxxxx-----------------qys_game_complete22:")

		--- 如果比赛奖激活
		if DATA.player_details[parent_id].base_info.is_activate_bisai_profit then
			--- 判断这个人之前是否打过千元赛
			local gamed_match_ids = {}
			local sql_str = string.format([[
								select match_id,match_model from naming_match_rank where player_id = '%s';
							]] , _player_id )
			local ret = PUBLIC.query_data( sql_str )
			dump(ret , "xxxxxx---------------------------gamed_match_ids11:")
			if ret then
				gamed_match_ids = ret

				dump(gamed_match_ids , "xxxxxx---------------------------gamed_match_ids22:")
			end

			--local raw_configs = nodefunc.get_global_config("match_server") 

			local is_player_qys = false
			for key,data in pairs(gamed_match_ids) do
				--local is_break = false

				if _game_id ~= data.match_id then
					if data.match_model == "naming_qys" then
						is_player_qys = true
						break
					end
				end

				--[[if _game_id ~= data.match_id then
					for _key,cfg_data in pairs(raw_configs.match_info) do
						if cfg_data.game_id == data.match_id and cfg_data.match_model == "naming_qys" then
							is_player_qys = true
							is_break = true
							break
						end
					end
				end
				if is_break then
					break
				end--]]
			end

			--- 完成的这个人是否是 有效用户
			local is_valid_player = false

			local step_cfg = nodefunc.get_global_config("stepstep_money_server")
			local max_little_step = 0
			if step_cfg then
				for key,data in pairs(step_cfg.task) do
					if data.big_step_id and data.little_step_id and data.big_step_id == DATA.xj_award_bbsc_big_step then
						max_little_step = math.max( max_little_step , data.little_step_id )
						print("xxxxxx-----------------qys_game_complete333:",max_little_step)
					end
				end
			else
				max_little_step = 5
			end

			local step_step_data = skynet.call(DATA.service_config.data_service,"lua","query_player_stepstep_money" , _player_id )
			if step_step_data.now_big_step > DATA.xj_award_bbsc_big_step or 
				(step_step_data.now_big_step == DATA.xj_award_bbsc_big_step and step_step_data.now_little_step > max_little_step ) then
				print("xxxxxx-----------------qys_game_complete5552:")
				is_valid_player = true

			end



			---- 从没有打过千元赛
			if not is_player_qys then

				if not is_valid_player then
					--- 不是有效用户 , 缓存奖励
					PUBLIC.query_data( string.format( [[update sczd_activity_info set qys_contribution_cache_for_parent = %s where player_id = '%s';]] 
						, DATA.qys_bisai_rebate_value , _player_id ))

				else
					PUBLIC.add_palyer_contribute( _player_id , "qys_bisai" , 150 , DATA.qys_bisai_rebate_value )
				end
			end
		end

	end
end


--玩家购买推广礼包 1或2
function CMD.player_buy_tglb_msg(player_id , tglb_type )
	---- 购买推广礼包，增加贡献值，贡献改变原因 101 | 102
	print("--------------------- player_buy_tglb1_msg:",player_id)

	local contribut_type = 101
	if tglb_type == "tglb1" then
		contribut_type = 101
	elseif tglb_type == "tglb2" then
		contribut_type = 102
	end

	local rebate_value = DATA.tglb1_rebate_value
	if tglb_type == "tglb1" then
		rebate_value = DATA.tglb1_rebate_value
	elseif tglb_type == "tglb2" then
		rebate_value = DATA.tglb2_rebate_value
	end

	

	--- 如果没有要载入
	if not DATA.player_details[player_id] or not DATA.player_details[player_id].base_info then
		PUBLIC.load_base_info(player_id)
	end

	---- xj玩家是否是第一次购买，第一次购买才返利
	local player_gold_info = skynet.call(DATA.service_config.goldpig_center_service,"lua","query_player_goldpig_data" , player_id)

	if (tglb_type == "tglb1" and player_gold_info.is_buy_goldpig1 == 0 and player_gold_info.is_buy_goldpig == 0) or 
			(tglb_type == "tglb2" and player_gold_info.is_buy_goldpig2 == 0) then
		PUBLIC.add_palyer_contribute( player_id , tglb_type , contribut_type , rebate_value )
	end

	-- 通知 金猪礼包中心  ,  ---------------- 这个一定放到 query_player_goldpig_data 之后
	if tglb_type == "tglb1" then
		skynet.send(DATA.service_config.goldpig_center_service,"lua","player_buy_goldpig" , player_id)
	elseif tglb_type == "tglb2" then
		skynet.send(DATA.service_config.goldpig_center_service,"lua","player_buy_goldpig2" , player_id)
	end

	--- 如果激活了推广礼包缓存收益，要把我儿子的收益给我
	if DATA.player_details[player_id] and DATA.player_details[player_id].base_info then
		if DATA.player_details[player_id].base_info.is_activate_tglb_cache == 1 then

			--DATA.player_details[player_id].base_info.is_activate_tglb_cache = 1
			--- 金猪礼包缓存奖励清0
			DATA.player_details[player_id].base_info.goldpig_profit_cache = 0
			--- 通知节点，金猪缓存改变
        	nodefunc.send(player_id , "goldpig_profit_cache_change" , DATA.player_details[player_id].base_info.goldpig_profit_cache )

			--- 通知agent 激活tglb收益
			--nodefunc.send(player_id,"activate_tglb_profit" , DATA.player_details[player_id].base_info.is_activate_tglb_profit)


			--- 把我的 儿子买的推广礼包的奖励的缓存发给我
			local sql_str = string.format( [[set @tglb_award_cache = 0;
		                                  
		                                  call sczd_activate_tglb('%s',@tglb_award_cache);

		                                  select @tglb_award_cache;
		                                  ]] , player_id )

			local tglb_award_cache = PUBLIC.query_data( sql_str )
			if tglb_award_cache then
				tglb_award_cache = tglb_award_cache[#tglb_award_cache][1]["@tglb_award_cache"]

				--- 加钱 并 通知
				if tglb_award_cache > 0 then
					--nodefunc.send(player_id,"asset_on_change_msg", PLAYER_ASSET_TYPES.CASH , tglb_award_cache , "tglb_active_get_cache" )
					skynet.send(DATA.service_config.data_service,"lua","change_asset_and_sendMsg",
		                    player_id, PLAYER_ASSET_TYPES.CASH ,
		                    tglb_award_cache, "tglb_cache_rebate" , 0 )
				end
			end
		end
	end

	
	--print( "-------------->>>>>>>>>>> tglb_award_cache:" , tglb_award_cache )
end


--- 玩家购买了vip礼包
function CMD.player_pay_vip_lb_msg(player_id)
	--- 如果没有要载入
	if not DATA.player_details[player_id] or not DATA.player_details[player_id].base_info then
		PUBLIC.load_base_info(player_id)
	end

	---- 通知vip礼包中心 买了礼包
	skynet.send(DATA.service_config.sczd_vip_lb_service,"lua","player_buy_vip_lb" , player_id)

	-------------- 准备给上级返利 ------------------
	--- 如果注册时间是 < '2019-05-14 00:00:00' 的老用户，不可返利
	if DATA.player_details[player_id] and DATA.player_details[player_id].my_main_info_for_parent then
		local register_time = DATA.player_details[player_id].my_main_info_for_parent.register_time
		if register_time then
			if register_time < basefunc.get_time_by_date("2019-05-14 00:00:00") then
				return
			end
		else
			return
		end
	else
		--- 没有数据不返，防止刷
		return
	end

	----- 上级的返利个数限制
	local parent_id = DATA.player_relation[player_id] and DATA.player_relation[player_id].parent_id or nil
	if parent_id then
		if not DATA.player_details[parent_id] or not DATA.player_details[parent_id].base_info then
	      PUBLIC.load_base_info(parent_id)
	    end 

	    local vip_lb_info = skynet.call(DATA.service_config.sczd_vip_lb_service,"lua","query_player_vip_lb_data" , parent_id )
	    if vip_lb_info then
	    	if vip_lb_info.now_vip_rebate_xj_num < vip_lb_info.max_vip_rebate_xj_num then
	    		skynet.send(DATA.service_config.sczd_vip_lb_service,"lua","add_vip_rebate_xj_num" , parent_id )
	    	else
	    		return
	    	end
	    else
	    	return
	    end
	else
		return
	end

	---- 
	PUBLIC.add_palyer_contribute( player_id , "vip_lb" , 103 , DATA.vip_lb_rebate_value )
end


--玩家提现消息
function CMD.player_tixian_msg(player_id, num , src_type , asset_type)
	if player_id and DATA.player_details[player_id] and DATA.player_details[player_id].my_spending_details and src_type == "game" and asset_type == "cash" then
		DATA.player_details[player_id].my_spending_details[#DATA.player_details[player_id].my_spending_details+1]={spending_value= -num,spending_time=os.time()}
	end
end


--[[ 通过 微信 uuid 创建 或 关联用户
 如果用户已经有上级了，则不改变
返回：
	{
		result=0,
		userId=,
		gameParentUserIds={parent_id}
	}
--]]

function base.CMD.wechat_create_player(_uuid)

	local using_uuid = DATA.creating_uuid or {}

	if not _uuid then
		return nil,1001
	end

	if using_uuid[_uuid] then
		return nil,1008
	end
	using_uuid[_uuid] = true


  local _player_id = skynet.call(DATA.service_config.data_service,"lua","userId_from_login_id",_uuid,"wechat")
  if not _player_id then
	
		local code
		_player_id,code = skynet.call(DATA.service_config.verify_service,"lua","extend_create_user","wechat",_uuid,nil,"sczd")
		if not _player_id then
			return nil,code
		end 
  end

  local code = DATA.player_relation[_player_id] and 0 or CMD.try_add_player_relation(_player_id,{
          parent_id = nil,
          is_tgy = 1,
      })

  using_uuid[_uuid] = nil

  if 0 == code then
	  return {userId=_player_id}
  else
	return nil,code
  end
	
end

function base.CMD.init_bind_parent(_player_id,_parent_id)

	if _player_id == _parent_id then
		return 1003
	end

	--print("xxxxxxxxxxxxxxxxx init_bind_parent:",_player_id,_parent_id)

	if not _parent_id then
		return 1001
	end

	local _old_parent = DATA.player_relation[_player_id] and DATA.player_relation[_player_id].parent_id
	if _old_parent then
		if _old_parent == _parent_id then
			return 1051
		else
			return 1055
		end
	end

	local using_id = DATA.binding_player or {}

	if using_id[_player_id] or using_id[_parent_id] then
		return 1008
	end

	using_id[_player_id] = true
	using_id[_parent_id] = true
	
	if not skynet.call(DATA.service_config.data_service,"lua","is_player_exists",_parent_id) then

		using_id[_player_id] = nil
		using_id[_parent_id] = nil
		return 2251
	end
	
	local code = CMD.try_add_player_relation(_player_id,{
		parent_id = _parent_id,
		is_tgy = 1,
	})	

	using_id[_player_id] = nil
	using_id[_parent_id] = nil

	-- 绑定成功 进行检查父亲是否有礼物奖励
	print("sczd bind,try_add_player_relation: ",code,_player_id,_parent_id)
	if code == 0 then
		skynet.send(DATA.service_config.gift_coupon_center_service,"lua","grant_gift_coupon",_player_id,_parent_id)
	end

	return code	
end

--[[
base_info
		real_name --真实姓名
		phone  --电话
		weixin --微信号码
		shengfen --省份
		chengshi --城市
		qu      --区
--必须全部传过来才能修改
--]]
--create_or_delete :create --创建  delete--删除  gjhhr_status --nor 正常  --freeze 冻结
function CMD.change_gjhhr_info(player_id,create_or_delete,gjhhr_status,real_name,phone,weixin,shengfen,chengshi,qu,op_player)
	if player_id and create_or_delete and gjhhr_status then
		local base_info
		if real_name and phone and weixin and shengfen and chengshi and qu then
			base_info={
			real_name=real_name,
			phone=phone,
			weixin=weixin,
			shengfen=shengfen,
			chengshi=chengshi,
			qu=qu,
			}
		end
		local c_or_d_status=nil
		if create_or_delete=="create" then
			c_or_d_status=1
		elseif create_or_delete=="delete" then
			c_or_d_status=0
		elseif create_or_delete=="normal" then
			c_or_d_status="normal"
		end
		if not c_or_d_status then 
			return 4404
		end
		 
		if gjhhr_status~="nor" and gjhhr_status~="freeze" then
			return 4403
		end

		---- add by wss   高级合伙人改变之后，基本信息里面更新一下
		if not DATA.player_details[player_id] or not DATA.player_details[player_id].base_info then
			PUBLIC.load_base_info(player_id)
		end
		if DATA.player_details[player_id] and DATA.player_details[player_id].base_info then
			local base_data = DATA.player_details[player_id].base_info
			if base_data.gjhhr_status ~= gjhhr_status then
				base_data.gjhhr_status = gjhhr_status

				nodefunc.send(player_id,"sczd_activate_change_msg" , base_data.is_activate_xj_profit , base_data.is_activate_tglb_profit , base_data.gjhhr_status , base_data.is_activate_bisai_profit)
			end
		end

		return PUBLIC.change_player_gjhhr_status(player_id,c_or_d_status,gjhhr_status,base_info,op_player)
	end

	return 1001
end



--- 改变上下级关系
function CMD.change_player_relation(player_id,new_parent,op_player)
	--print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx change_player_relation aaaa:",player_id,new_parent,op_player,basefunc.tostring(DATA.player_relation))

	if not player_id or not DATA.player_relation[player_id] or not new_parent then
		return 2159
	end
	if new_parent=="null" then
		new_parent=nil
	end
	if new_parent and not DATA.player_relation[new_parent] then
		return 1004
	end
	if new_parent and new_parent==DATA.player_relation[player_id].parent_id then
		return 0
	end

	if not PUBLIC.check_relation_is_safe(player_id,new_parent) then
		--上下关系不合法
		return 4301
	end

	local old_parent_id =  DATA.player_relation[player_id].parent_id or nil

	if old_parent_id == new_parent then
		return 1001
	end

	local old_parents = CMD.query_all_parents(player_id)

	DATA.player_relation[player_id].parent_id = new_parent

	local new_parents = CMD.query_all_parents(player_id)

	------------------------------------------ 清理缓存 -----------------------------------
	---- 清理自己的
	if DATA.player_details[player_id] then
		if DATA.player_details[player_id].my_main_info_for_parent then
			DATA.player_details[player_id].my_main_info_for_parent.my_all_gx = 0
		end
		if DATA.player_details[player_id].my_deatails_info_for_parent then
			DATA.player_details[player_id].my_deatails_info_for_parent.my_tgli_gx = 0
			DATA.player_details[player_id].my_deatails_info_for_parent.my_bbsc_gx = 0
		end
		DATA.player_details[player_id].my_contribute_details_for_parent = nil
	end
	--- 清理上级
	if old_parent_id then
		if DATA.player_details[old_parent_id] then
			if DATA.player_details[old_parent_id].base_info then
				DATA.player_details[old_parent_id].base_info.all_son_count = DATA.player_details[old_parent_id].base_info.all_son_count - 1
				if DATA.player_details[old_parent_id].base_info.all_son_count < 0 then
					DATA.player_details[old_parent_id].base_info.all_son_count = 0
				end
			end

		end
		-- 清索引
		if DATA.player_all_son_data[old_parent_id] then
			for key,data in pairs(DATA.player_all_son_data[old_parent_id]) do
				if data.id == player_id then
					table.remove( DATA.player_all_son_data[old_parent_id] , key )
					break
				end
			end
		end
	end
	if new_parent then
		--- 新上级
		if not DATA.player_details[new_parent] or not DATA.player_details[new_parent].base_info then
			PUBLIC.load_base_info(new_parent)
		end

		if DATA.player_details[new_parent] then
			if DATA.player_details[new_parent].base_info then
				DATA.player_details[new_parent].base_info.all_son_count = DATA.player_details[new_parent].base_info.all_son_count + 1
			end
			--- 加索引,有父亲的数据，一定要加
			if DATA.player_all_son_data[new_parent] then
				if DATA.player_details[player_id] and DATA.player_details[player_id].my_main_info_for_parent then
					DATA.player_all_son_data[new_parent][#DATA.player_all_son_data[new_parent] + 1] = DATA.player_details[player_id].my_main_info_for_parent
				else
					PUBLIC.load_base_info( player_id )
					--DATA.player_all_son_data[new_parent][#DATA.player_all_son_data[new_parent] + 1] = DATA.player_details[player_id].my_main_info_for_parent
				end
			end
		end
	end

	--改变son_count
	PUBLIC.update_son_count(old_parents,-DATA.player_relation[player_id].son_count)
	PUBLIC.update_son_count(new_parents,DATA.player_relation[player_id].son_count)

	----------------------------------------- 调用 存储过程 --------------------------------- 
	skynet.send(DATA.service_config.data_service,"lua","db_exec",string.format( [[call sczd_change_parent('%s',%s);]] , player_id , PUBLIC.value_to_sql(new_parent) ))

	--dump(DATA.player_relation,"xxxxxxxxxxxxxxxxxxxxxxxxx change_player_relation iii:")
	skynet.send(DATA.service_config.sczd_gjhhr_service,"lua","change_player_relation",player_id,old_parents,new_parents)

	-- ###_test  lyx   new_parent可以为nil
	skynet.send(DATA.service_config.data_service,"lua","record_op_log",op_player,"change relation",player_id,new_parent)

	return 0
end

--- 尝试添加上下级关系 
function CMD.try_add_player_relation(player_id,data)

	if not player_id or not data then
		return 2159
	end

	if player_id == data.parent_id then
		return 1060
	end

	--dump({DATA.player_relation,player_id,data},"xxxxxxxxxxxxxxxxxxxxxxxx try_add_player_relation 1:")

	if not DATA.player_relation[player_id] then
		PUBLIC.add_player_relation(player_id,data)
		--dump(DATA.player_relation,"xxxxxxxxxxxxxxxxxxxxxxxx try_add_player_relation 2:")
		return 0
	elseif DATA.player_relation[player_id] and not DATA.player_relation[player_id].parent_id and data.parent_id and DATA.player_relation[data.parent_id] then
		if not PUBLIC.check_relation_is_safe(player_id,data.parent_id) then
			--上下关系不合法  ###_test
			return 2150
		end
		local ret_code = CMD.change_player_relation(player_id,data.parent_id)
		--dump(DATA.player_relation,"xxxxxxxxxxxxxxxxxxxxxxxx try_add_player_relation 3:")
		return ret_code
	end

	--操作失败  玩家已有关系
	return 1054
end


function CMD.reset_player_son_count()
    for i,v in pairs(DATA.player_relation) do
      v.son_count=1
    end
    for my_id,v in pairs(DATA.player_relation) do
        local ps=CMD.query_all_parents(my_id)
        dump(ps)
        if ps then
          for _,v in ipairs(ps) do
             DATA.player_relation[v].son_count=DATA.player_relation[v].son_count + 1
          end
        end
    end
    -- dump(DATA.player_relation,"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")

    local sqls={}
    for id,v in pairs(DATA.player_relation) do
        sqls[#sqls + 1] = string.format("update sczd_relation_data set son_count=%d where id='%s';",v.son_count,id)
    end
    if next(sqls) then
      skynet.send(DATA.service_config.data_service,"lua","db_exec",table.concat(sqls,"\n"))
      print("reset_player_son_count  okok")
    end
end

-------- 各个收益激活关闭接口

--- 下级bbsc返利
function CMD.set_is_activate_bbsc_profit(player_id , bool)
	if not player_id or not bool or type(player_id) ~= "string" or type(bool) ~= "string" or (bool~="true" and bool~="false") then
		return 1001
	end

	print("-------------------set_is_activate_bbsc_profit",player_id , bool and "true" or "false")
	skynet.send(DATA.service_config.data_service,"lua","db_exec",
		string.format( [[update sczd_player_base_info set is_activate_bbsc_profit = %s where player_id = '%s';]] , PUBLIC.value_to_sql(bool and 1 or 0) , player_id))
	return 0
end

--- 下级玩家奖
function CMD.set_is_activate_xj_profit(player_id , bool)
	if not player_id or not bool or type(player_id) ~= "string" or type(bool) ~= "string" or (bool~="true" and bool~="false") then
		return 1001
	end
	print("-------------------set_is_activate_xj_profit",player_id , bool and "true" or "false")
	skynet.send(DATA.service_config.data_service,"lua","db_exec",
		string.format( [[update sczd_player_base_info set is_activate_xj_profit = %s where player_id = '%s';]] , PUBLIC.value_to_sql(bool and 1 or 0) , player_id))
	return 0
end

--- 下级礼包奖
function CMD.set_is_activate_tglb_profit(player_id , bool)
	if not player_id or not bool or type(player_id) ~= "string" or type(bool) ~= "string" or (bool~="true" and bool~="false") then
		return 1001
	end
	print("-------------------set_is_activate_tglb_profit",player_id , bool and "true" or "false")
	skynet.send(DATA.service_config.data_service,"lua","db_exec",
		string.format( [[update sczd_player_base_info set is_activate_tglb_profit = %s where player_id = '%s';]] , PUBLIC.value_to_sql(bool and 1 or 0) , player_id))
	return 0
end

--- 下级礼包 缓存
function CMD.set_is_activate_tglb_cache(player_id , bool)
	if not player_id or not bool or type(player_id) ~= "string" or type(bool) ~= "string" or (bool~="true" and bool~="false") then
		return 1001
	end
	print("-------------------set_is_activate_tglb_cache",player_id , bool and "true" or "false")
	skynet.send(DATA.service_config.data_service,"lua","db_exec",
		string.format( [[update sczd_player_base_info set is_activate_tglb_cache = %s where player_id = '%s';]] , PUBLIC.value_to_sql(bool and 1 or 0) , player_id))
	return 0
end

--- 设置 sczd的各种开关
function CMD.set_activate_sczd_profit(player_id , tgy_tx_profit , xj_profit , tglb_profit , basai_profit)
	if not player_id or not tgy_tx_profit or not xj_profit or not tglb_profit or not basai_profit
		or type(player_id) ~= "string" or type(tgy_tx_profit) ~= "string" or type(xj_profit) ~= "string" or type(tglb_profit) ~= "string" or type(basai_profit) ~= "string" 
		or (tgy_tx_profit ~= "true" and tgy_tx_profit~="false") or (xj_profit ~= "true" and xj_profit~="false") or (tglb_profit ~= "true" and tglb_profit~="false") or (basai_profit ~= "true" and basai_profit~="false") then
		return 1001
	end

	print("-------------------set_activate_sczd_profit",player_id , tgy_tx_profit , xj_profit , tglb_profit , basai_profit )
	--- 没有的话需要加一下，以免表里面没有
	if not DATA.player_details[player_id] or not DATA.player_details[player_id].base_info then
        --
        PUBLIC.load_base_info(player_id)
    end
    if DATA.player_details[player_id] and DATA.player_details[player_id].base_info then
    	local base_data = DATA.player_details[player_id].base_info
    	local target_xj_profit = xj_profit=="true" and 1 or 0
    	local is_change = false
    	local is_xj_profit_change = false
    	if base_data.is_activate_xj_profit ~= target_xj_profit then
    		base_data.is_activate_xj_profit = target_xj_profit
    		is_change = true
    		is_xj_profit_change = true
    	end

    	local is_tglb_profit_change = false
    	local target_tglb_profit = tglb_profit=="true" and 1 or 0
    	if base_data.is_activate_tglb_profit ~= target_tglb_profit then
    		base_data.is_activate_tglb_profit = target_tglb_profit
    		is_change = true
    		is_tglb_profit_change = true
    	end

    	---- 这个不用发到外部
    	local target_tgy_tx_profit = tgy_tx_profit=="true" and 1 or 0
    	local is_tgy_tx_profit_change = false
    	if base_data.is_activate_tgy_tx_profit ~= target_tgy_tx_profit then
    		base_data.is_activate_tgy_tx_profit = target_tgy_tx_profit
    		is_tgy_tx_profit_change = true
    	end

    	local is_basai_profit_change = false
    	local target_basai_profit = basai_profit=="true" and 1 or 0
    	if base_data.is_activate_bisai_profit ~= target_basai_profit then
    		base_data.is_activate_bisai_profit = target_basai_profit
    		is_change = true
    		is_basai_profit_change = true
    	end

 		if is_change then
 			nodefunc.send(player_id,"sczd_activate_change_msg" , base_data.is_activate_xj_profit , base_data.is_activate_tglb_profit , base_data.gjhhr_status , base_data.is_activate_bisai_profit)
 		end
    end

	skynet.send(DATA.service_config.data_service,"lua","db_exec",
		string.format( [[update sczd_player_base_info set is_activate_tgy_tx_profit = %s,is_activate_xj_profit = %s,is_activate_tglb_profit = %s,is_activate_bisai_profit = %s where player_id = '%s';]] 
			, PUBLIC.value_to_sql(tgy_tx_profit=="true" and 1 or 0) , PUBLIC.value_to_sql(xj_profit=="true" and 1 or 0) 
			, PUBLIC.value_to_sql(tglb_profit=="true" and 1 or 0) , PUBLIC.value_to_sql(basai_profit=="true" and 1 or 0) , player_id))

	--- 加入日志
	skynet.send(DATA.service_config.data_service,"lua","db_exec",
		string.format( [[ 
							insert into sczd_profit_change_log (player_id,is_activate_xj_profit,is_activate_tglb_profit,is_activate_bisai_profit,is_activate_tgy_tx_profit)
							values ('%s',%s,%s,%s,%s)
		 ]] , player_id 
		 , is_xj_profit_change and PUBLIC.value_to_sql(xj_profit=="true" and 1 or 0) or -1
		 , is_tglb_profit_change and PUBLIC.value_to_sql(tglb_profit=="true" and 1 or 0) or -1
		 , is_basai_profit_change and PUBLIC.value_to_sql(basai_profit=="true" and 1 or 0) or -1
		 , is_tgy_tx_profit_change and PUBLIC.value_to_sql(tgy_tx_profit=="true" and 1 or 0) or -1 ) )

	return 0
end


return PROTECT







