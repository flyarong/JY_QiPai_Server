local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local task_base_func = require "task.task_base_func"
local common_task = require "task.common_task"

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST
local PUBLIC = base.PUBLIC

DATA.vip_lb_task_protect = {}
local task = DATA.vip_lb_task_protect

function task.gen_task_obj(config,data)
	local obj = common_task.gen_task_obj(config,data)

	---------------------------- 重写部分代码 ----------------------------------
	obj.init = function (is_refresh_cfg)

		PUBLIC.deal_msg(obj)

		--- 监听消息
		DATA.msg_dispatcher:register( obj , obj.msg )

		if obj.reset_timecancler then
			obj.reset_timecancler()
		end

		obj.max_process , obj.max_task_round = task_base_func.get_max_process(obj.config.process_data) 

		obj.lv = 1
		obj.process_index = 1

		obj.get_lv_info() 

		--- 处理是否重置进程
		if obj.config.is_reset == 1 then
			PUBLIC.deal_reset_process( obj , function() 
				obj.auto_get_task_award()
			end)
		end

	end

	------ 
	obj.auto_get_task_award = function()
		print("-----------------auto get task_award 11", obj.task_award_get_status , obj.now_lv_process , obj.now_lv_need_process , obj.lv )
		--- 如果没有领取已经完成的奖励
		if obj.task_award_get_status == 0 and obj.now_lv_process == obj.now_lv_need_process and obj.lv == 1 then
			--- 自动领
			print("-----------------auto get task_award 22")
			local task_award = obj.get_award(award_progress_lv)

			if task_award and type(task_award) == "table" then
				print("-----------------auto get task_award 33")
				local change_type = ASSET_CHANGE_TYPE.TASK_AWARD 

				CMD.change_asset_multi(task_award, change_type ,obj.id)

				---- 自动领的邮件凭证
				local time_date = os.date("*t",os.time())
				local email = {
					type = "vip_lb_task_auto_get_award",
					receiver = DATA.my_id,
					sender = "系统",
					data={time=string.format( "%s/%s/%s %02d:%02d:%02d",time_date.year , time_date.month , time_date.day , time_date.hour , time_date.min , time_date.sec )}
				}

				skynet.send(DATA.service_config.email_service,"lua","send_email",email)

			end

		end
	end

	return obj
end


return task