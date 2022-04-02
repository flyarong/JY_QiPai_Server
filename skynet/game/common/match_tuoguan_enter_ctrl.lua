--比赛场托管进入控制
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

local return_cache={result = 0,signup_num=0}
DATA.tuoguan_enter_ctrl_data = {}

local my_data=DATA.tuoguan_enter_ctrl_data
--托管减少的概率
local tuguan_reduce_probability=10
--托管保持不变的概率
local tuguan_balance_probability=0

local tuoguan_enter_speed_ctrl_kaiguan=true

local tuoguan_enter_speed_ctrl_count=0
local tuoguan_enter_speed_ctrl_limit=100
--[[
	launch_entity
	
	tuoguan_enter_time_min
	tuoguan_enter_time_max	

	cur_tuoguan_count  --当前虚拟报名托管计数
	tuoguan_limit  --托管限制

	all_need_num  --总需要人数
	cur_all_count --当前报名总数（含虚拟）
	cur_real_count  --当前真人	
	last_real_count --上个时段记录的真人
	
	cur_signup_tuoguan_count 	--已经真实报名报名的托管
	

	cur_signup_all_count --当前真实报名的人数
	

	--无人的情况下计数  用于托管清空
	no_real_count
	no_real_clear_limit
	
	--托管进入延时控制  太久没有进入  代表托管进入失败   重新请求
	tuoguan_enter_delayed 
	tuoguan_enter_delayed_limit
	


	is_run
--]]


function PROTECTED.get_signup_player_num()
	return_cache.signup_num=PROTECTED.get_signup_num_client()
	return return_cache
end
function PROTECTED.player_signup(_my_id)

	local res=my_data.launch_entity.player_signup(_my_id)
	if res.result==0 then
		PROTECTED.change_signup_player_num(1,_my_id)
		res.signup_num=PROTECTED.get_signup_num_client()
	end

	return res
end
function PROTECTED.cancel_signup(_match_svr_id,_my_id)
	local res=my_data.launch_entity.cancel_signup(_match_svr_id,_my_id)
	if res==0 then
		PROTECTED.change_signup_player_num(-1,_my_id)
	end
	return res
end



local function update()
	while my_data.is_run do
		
		local min_time = math.max(0,math.floor(my_data.tuoguan_enter_time_min*100))
		local max_time = math.max(min_time,math.floor(my_data.tuoguan_enter_time_max*100))
		
		skynet.sleep(math.random(min_time,max_time))
		PROTECTED.deal_tuoguan()

		tuoguan_enter_speed_ctrl_count=tuoguan_enter_speed_ctrl_count+1
		if tuoguan_enter_speed_ctrl_count>=tuoguan_enter_speed_ctrl_limit then
			PROTECTED.tuoguan_enter_speed_ctrl()
			tuoguan_enter_speed_ctrl_count=0
		end


	end
end

--客户端永远显示不满  给托管进入留时间
function PROTECTED.get_signup_num_client()
	if my_data.cur_all_count==my_data.all_need_num and my_data.cur_all_count>1 then
		return my_data.cur_all_count-1
	end
	return my_data.cur_all_count
end
function PROTECTED.check_begin()
	if my_data.cur_signup_all_count==my_data.all_need_num then
		PROTECTED.check_new_config()
		PROTECTED.reset_data()
	end
end
function PROTECTED.change_signup_player_num(num,_player_id)
	--判断是否为托管
	local is_real=basefunc.chk_player_is_real(_player_id)
	
	my_data.cur_signup_all_count=my_data.cur_signup_all_count+num

	if is_real then
		my_data.cur_real_count=my_data.cur_real_count+num
		if num==1 then
			PROTECTED.change_tuoguan(-1)
		end
		PROTECTED.change_all_count(num)
	else
		my_data.cur_signup_tuoguan_count=my_data.cur_signup_tuoguan_count+num
		if num==1 and my_data.cur_signup_all_count+my_data.cur_tuoguan_count>my_data.cur_all_count then
			PROTECTED.change_all_count(1)
		elseif num==-1 then	
			PROTECTED.change_all_count(-1)
		end

	end

	if num==1 then
		PROTECTED.check_begin()
	end
	

end

function PROTECTED.change_tuoguan(num)

	if num + my_data.cur_tuoguan_count < 0 then
		num = -my_data.cur_tuoguan_count
	end
	if num~=0 then
		my_data.cur_tuoguan_count = my_data.cur_tuoguan_count + num
		PROTECTED.change_all_count(num)
	end

end

function PROTECTED.change_all_count(num)
	my_data.cur_all_count=my_data.cur_all_count+num
	if my_data.cur_all_count<0 then
		my_data.cur_all_count=0
	end
	if my_data.cur_all_count>my_data.all_need_num then
		my_data.cur_all_count=my_data.all_need_num
	end
	
	if my_data.cur_all_count==my_data.all_need_num then
		
		if my_data.cur_tuoguan_count>0 then 
			--呼叫托管进入  
			local _game_info = 
			{
				game_id = DATA.match_config.game_id,
				game_type = DATA.match_config.game_type,
				service_id = DATA.my_id,
				match_name = "match_game",
			}
			skynet.send(DATA.service_config.tuoguan_service,"lua","assign_tuoguan_player",my_data.cur_tuoguan_count,_game_info)
			my_data.cur_tuoguan_count=0
		end
	end
end

function PROTECTED.tuoguan_enter_speed_ctrl()
	if tuoguan_enter_speed_ctrl_kaiguan then
		local hour=os.date("*t").hour
		if (hour>=0 and hour<=1) or (hour>=5 and hour<=6) then
			tuguan_balance_probability=30
		elseif (hour>1 and hour<5) then
			tuguan_balance_probability=70
		else
			tuguan_balance_probability=0
		end
	else
		tuguan_balance_probability =0
	end
end

function PROTECTED.calculate_tuoguan()
	--根据时间减少匹配
	local v=math.random(1,100)
	if v<tuguan_balance_probability then
		return 
	end
	v=v-tuguan_balance_probability

	if v<tuguan_reduce_probability then
		PROTECTED.change_tuoguan(-1)
		return 
	end
	PROTECTED.change_tuoguan(1)

end

function PROTECTED.deal_tuoguan()
	if my_data.tuoguan_limit>0 then

		--不超过限制并且真实的人不增加 则 进行托管调度
		if my_data.cur_tuoguan_count+my_data.cur_signup_tuoguan_count<my_data.tuoguan_limit 
			and my_data.last_real_count>=my_data.cur_real_count 
			and my_data.cur_all_count<my_data.all_need_num then
				PROTECTED.calculate_tuoguan()
		end

		if my_data.cur_real_count==0 then
			my_data.no_real_count=my_data.no_real_count+1
		else
			my_data.no_real_count=0
		end

		--长时间没有人来 则清零
		if my_data.no_real_count>my_data.no_real_clear_limit then
			PROTECTED.change_tuoguan(-my_data.cur_tuoguan_count)
			my_data.no_real_count=0
		end
		my_data.last_real_count=my_data.cur_real_count


		if my_data.cur_all_count==my_data.all_need_num  and  my_data.cur_signup_all_count<my_data.all_need_num then
			my_data.tuoguan_enter_delayed=my_data.tuoguan_enter_delayed+1
		else
			my_data.tuoguan_enter_delayed=0
		end

		if my_data.tuoguan_enter_delayed>0 and my_data.tuoguan_enter_delayed>my_data.tuoguan_enter_delayed_limit then
			--从新请求  
			local num=my_data.all_need_num-my_data.cur_signup_all_count
			
			local _game_info = 
			{
				game_id = DATA.match_config.game_id,
				game_type = DATA.match_config.game_type,
				service_id = DATA.my_id,
				match_name = "match_game",
			}
			skynet.send(DATA.service_config.tuoguan_service,"lua","assign_tuoguan_player",num,_game_info)

			my_data.tuoguan_enter_delayed=0
		end
	end


end

function PROTECTED.reset_data()

	my_data.cur_tuoguan_count=0  --当前虚拟报名托管计数

	my_data.cur_all_count=0 --当前报名总数（含虚拟）
	my_data.cur_real_count=0  --当前真人	
	my_data.last_real_count=0 --上个时段记录的真人
	
	my_data.cur_signup_tuoguan_count=0 	--已经真实报名报名的托管
	
	my_data.cur_signup_all_count=0 --当前真实报名的人数
	
	--无人的情况下计数  用于托管清空
	my_data.no_real_count=0
	
	--托管进入延时控制  太久没有进入  代表托管进入失败   重新请求
	my_data.tuoguan_enter_delayed=0 

end

--[[

tuoguan_enter_time_min    --托管进入的最小间隔
tuoguan_enter_time_max	--托管进入的最大间隔
tuoguan_limit       --拖管的限制人数
all_need_num 	  --总共需要的人	

--]]
function PROTECTED.delay_reload_config(cfg,_launch_entity)
	my_data.new_cfg=cfg
	my_data.new_launch_entity=_launch_entity
	
	
end
function PROTECTED.reload_config(cfg,_launch_entity)
	my_data.new_cfg=cfg
	my_data.new_launch_entity=_launch_entity
	PROTECTED.check_new_config()
end

function PROTECTED.check_new_config()
	if my_data.new_cfg then
		PROTECTED.set_config(my_data.new_cfg,my_data.new_launch_entity)
		my_data.new_cfg=nil
		my_data.new_launch_entity=nil
	end
end
function PROTECTED.set_config(cfg,_launch_entity)

	my_data.launch_entity=_launch_entity

	if not cfg or cfg.tuoguan_limit==0 then
		PROTECTED.reset_data()
		my_data.tuoguan_limit=0
		if my_data.is_init and _launch_entity then
			base.CMD.get_signup_player_num=_launch_entity.get_signup_player_num
			base.CMD.player_signup=_launch_entity.player_signup
			base.CMD.cancel_signup=_launch_entity.cancel_signup
		end
	else
		base.CMD.get_signup_player_num=PROTECTED.get_signup_player_num
		base.CMD.player_signup=PROTECTED.player_signup
		base.CMD.cancel_signup=PROTECTED.cancel_signup
		if not my_data.is_init then
			my_data.is_init=true
			PROTECTED.reset_data()
			skynet.fork(update)
		end
		my_data.is_run=true
		my_data.tuoguan_enter_time_min=cfg.tuoguan_enter_time_min
		my_data.tuoguan_enter_time_max=cfg.tuoguan_enter_time_max
		my_data.tuoguan_limit=cfg.tuoguan_limit  --托管限制
		my_data.all_need_num=cfg.all_need_num


		my_data.no_real_clear_limit=cfg.tuoguan_limit/4
		--5个周期内还未进入 则再次请求
		my_data.tuoguan_enter_delayed_limit=5
	end
	
end

function PROTECTED.init(cfg,_launch_entity)
	PROTECTED.reload_config(cfg,_launch_entity)
end


return PROTECTED



