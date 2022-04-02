--
-- Author: yy
-- Date: 2018/11/7
-- Time: 15:11
-- 说明：require task floder

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST
local PUBLIC = base.PUBLIC

DATA.task_initer_protect = {}
local task_initer = DATA.task_initer_protect

local common_task = require "task.common_task"
local vip_lb_task = require "task.vip_lb_task"
local buyu_daily_task = require "task.buyu_daily_task"

function task_initer.gen_task_obj(config,data)
	if  config.task_enum == TASK_TYPE_ENUM.common_task then
		return common_task.gen_task_obj( config,data )
	elseif config.task_enum == "vip_task" then
		return vip_lb_task.gen_task_obj( config,data )
	elseif config.task_enum == "buyu_daily_task" then
		return buyu_daily_task.gen_task_obj( config,data )
	end

	return nil
end




------------------------------------------------ 一些任务所使用的公共函数 --------------------------------------------
---- 处理重置机制
function PUBLIC.deal_reset_process(obj , pre_callback , callback) 

	obj.reset_task(pre_callback , callback)


end

---- 处理任务进度改变
function PUBLIC.deal_task_progress_change(task_obj)
	if task_obj.config.own_type == "step_task" then
		PUBLIC.step_task_process_change( task_obj.id )
	elseif task_obj.config.own_type == "goldpig" then
		PUBLIC.goldpig_task_process_change( task_obj.id )
	elseif task_obj.config.own_type == "goldpig_new" then
		PUBLIC.goldpig_task_process_change( task_obj.id )
	elseif task_obj.config.own_type == "goldpig_new2" then
		PUBLIC.goldpig_task_process_change( task_obj.id )
	else
		PUBLIC.task_process_change( task_obj.id )
	end
end

---- 处理任务领取
function PUBLIC.deal_get_task_award(task_obj , goldpig_cash_num)
	if task_obj.config.own_type == "step_task" then
		--DATA.msg_dispatcher:call("stepstep_money_task_get_task" , task_obj.id)
		PUBLIC.trigger_msg( {name = "stepstep_money_task_get_task"} , task_obj.id )
	elseif task_obj.config.own_type == "goldpig" then
		--DATA.msg_dispatcher:call("goldpig_task_get_award" , goldpig_cash_num)
		PUBLIC.trigger_msg( {name = "goldpig_task_get_award"} , goldpig_cash_num )
	elseif task_obj.config.own_type == "goldpig_new" then
		--DATA.msg_dispatcher:call("goldpig_task_get_award_new" , goldpig_cash_num)
		PUBLIC.trigger_msg( {name = "goldpig_task_get_award_new"} , goldpig_cash_num )
	elseif task_obj.config.own_type == "goldpig_new2" then
		--DATA.msg_dispatcher:call("goldpig2_task_get_award_new" , goldpig_cash_num)
		PUBLIC.trigger_msg( {name = "goldpig2_task_get_award_new"} , goldpig_cash_num )
	elseif task_obj.config.own_type == "jingbi_zhouka" then
		--DATA.msg_dispatcher:call("jingbi_zhouka_task_get_award" )
		PUBLIC.trigger_msg( {name = "jingbi_zhouka_task_get_award"} )
	elseif task_obj.config.own_type == "qys_zhouka" then
		--DATA.msg_dispatcher:call("qys_zhouka_task_get_award" )
		PUBLIC.trigger_msg( {name = "qys_zhouka_task_get_award"} )
	elseif task_obj.config.own_type == "vip_task1" then
		--DATA.msg_dispatcher:call("vip_lb_task1_get_award" )
		PUBLIC.trigger_msg( {name = "vip_lb_task1_get_award"} )
	elseif task_obj.config.own_type == "vip_task2" then
		--DATA.msg_dispatcher:call("vip_lb_task2_get_award" )
		PUBLIC.trigger_msg( {name = "vip_lb_task2_get_award"} )
	else
		
	end
end

function PUBLIC.get_task_award_change_type(task_obj)
	local change_type = ASSET_CHANGE_TYPE.TASK_AWARD 

	if not task_obj then
		return change_type
	end

	if task_obj.config and task_obj.config.own_type == "goldpig_new2" then
		change_type = ASSET_CHANGE_TYPE.GOLD_PIG2_TASK_AWARD 
	end
			
	if task_obj.id == 101 then
		change_type = ASSET_CHANGE_TYPE.FISHING_TASK_CHOU_JIANG 
	end

	if task_obj.config and task_obj.config.own_type == "buyu_daily_children_task" then
		change_type = ASSET_CHANGE_TYPE.BUYU_DAILY_TASK_AWARD 
	end
	
	 
	return change_type
end


function PUBLIC.deal_msg(obj)
	if obj.config then
		if obj.config.condition_type == "duiju" then
			obj.game_compolete_task_deal()
		elseif obj.config.condition_type == "exchange_by_hongbao" then
			--- 用红包劵兑换
			obj.exchange_by_hongbao_deal()
		elseif obj.config.condition_type == "share_game" then	
			--- 分享游戏
			obj.shared_finish_deal()

		elseif obj.config.condition_type == "charge_any" then	
			--- 任意充值,在sczd中心做的。

		elseif obj.config.condition_type == "zajindan_award" then	
			---- 砸金蛋奖励任务
			obj.zajindan_award_deal()

		elseif obj.config.condition_type == "buyu_award" then	
			---- 捕鱼 奖励任务
			obj.buyu_award_deal()

		elseif obj.config.condition_type == "asset_observe" then	
			---- 资产观察
			obj.asset_change_msg_deal()

		elseif obj.config.condition_type == "children_task" then	
			---- 子任务
			obj.children_task_complete_deal()
		elseif obj.config.condition_type == "buyu_target_yu" then
			---- 打指定 鱼 任务
			obj.buyu_target_yu_deal()
		elseif obj.config.condition_type == "xiaoxiaole_award" then
			---- 消消乐 奖励任务
			obj.xiaoxiaole_award_deal()
		elseif obj.config.condition_type == "bbsc_big_step_complete" then 
			---- bbsc大步骤完成
			obj.bbsc_big_step_complete_deal()
		end
	end
end


return task_initer