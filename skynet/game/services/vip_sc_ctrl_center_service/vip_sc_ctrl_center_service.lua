--
-- Author: hw
-- Time:
-- 说明：vip 调度服务

local skynet = require "skynet_plus"
require "skynet.manager"
require"printfunc"
local nodefunc = require "nodefunc"
local base=require "base"
local vip_sc_man = require "vip_sc_ctrl_center_service.vip_sc_manager"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local vip_sc_cfg

--房间ID
DATA.my_id = 0

--[[
vip_data:
	key:player_id
	value:
	    data{

				remain_vip_count  -- 剩余vip次数  一次10天（暂定）

				vipfanjiang_debt  -- vipfanjiang 剩下的vip总和  分期还账
				presented_debt   -- 剩余的presented债务 剩下的vip总和  分期还账

				status -- 当前状态："init" 初始状态, "run" 执行中， "done" 完成

				cur_vip_start_time  -- 当前vip开始时间

				cur_debt --本期的债务
				cur_giveback_debt --本期已还的债务



				cur_day_index -- 当前是第几天

				-- 当前 vip 周期的每天数据
				cur_days =
				{
					{
						today_debt 	-- 今天总债务
						done_debt 	-- 债务完成量

						game_count  --今天已经进行的游戏次数

						qhtg_vd  --当前强化托管的输赢情况
						cur_game_is_qhtg --当前游戏是否是强化托管

						today_lucky -- 今天总红包量
						done_luck 	-- 已完成红包

					},
					...
				}

			}

--]]
local vip_data = {}
DATA.vip_data = vip_data

-- function CMD.player_game_data()
--
-- end

function PUBLIC.new_day_data()
	return
	{
		today_debt = 0,
		done_debt = 0,

		game_count = 0,

		qhtg_vd = 0,
		cur_game_is_qhtg = 0,

		today_lucky = 0,
		done_luck = 0,
	}
end

-- 在 一个周期中控制分派 A B C
-- 返回 数组，例如： {"A","A","B","C" , ...}
function PUBLIC.dispatch_period_control(_data)

	-- 首次 开启 vip 不同
	if _data.status == "init" then
		local xxx
	else
		local xxx
	end
end

-- 处理空的周期：在这段周期内，一天都没来过（没分账）
function PUBLIC.deal_empty_period(_data,_period_count)
	
	-- ###_temp ： 目前 仅仅 扣除 vip 次数，不改变债务
	_data.remain_vip_count = _data.remain_vip_count - _period_count
end

-- 收集已开始的周期中，未完成的 数据
-- 返回值： {debt=,lucky=}
function PUBLIC.collect_undone_data(_data,_day_index1,_day_index2)

	assert("run" == _data.status)

	local ret = {debt=0,lucky=0}

	for i=_day_index1,_day_index2 do
		ret.debt = ret.debt + _data.cur_days[i].today_debt - _data.cur_days[i].done_debt
		ret.lucky = ret.lucky + _data.cur_days[i].today_lucky - _data.cur_days[i].done_luck
	end

	return ret
end

-- 结算当天：未参与游戏过的日期 不会调用；不用处理债务转接，仅需要处理 返奖！
function PUBLIC.settle_today(_data,_day_index)
	
	local _day = _data.cur_days[_day_index]

	-- 完成局数，返奖
	if _day.game_count >= vip_sc_cfg.game_count then
		PUBLIC.give_award(_data,_day_index)
	end

end

-- 返奖
function PUBLIC.give_award(_data,_day_index)
	
	-- ###_temp ：执行 返现

end

-- 结算当期，未开始的周期 不会结算
--function PUBLIC.settle_

--随机调整  value 被调整的中间值  sum被调整的的数量   value*sum=总量   min最小值  max最大值百分比
function PUBLIC.random_adjust(value,sum,min,max)
	local result={}
	--当前比例标记
	local middle=math.floor(sum/2)

	for i=1,middle do
		result[i]=result[i] or value
		local r=math.floor((math.random(min,max)-100)/100*value)
		result[i]=result[i]+r
		result[i+middle]=result[i+middle] or value
		result[i+middle]=result[i+middle] - r
	end

	return result
end


--算出本期红包分布
function PUBLIC.cur_period_lucky_dispatch(_all_lucky,_count)
	local average=math.floor(_all_lucky/_count)
	local cur_day_lucky=random_adjust(average,_count,table.unpack(vip_sc_cfg.lucky_range))
	return cur_day_lucky
end

--算出本期债务分布  还债流程   算出每天还多少债务
function PUBLIC.cur_period_debt_dispatch(all_debt,days)
	local average=math.floor(all_debt/days)
	local cur_day_debt=random_adjust(average,days,table.unpack(vip_sc_cfg.day_debt_range))
	return cur_day_debt
end

function PUBLIC.reduce_today_debt(player_id,debt)
	if vip_data[player_id] and vip_data[player_id].cur_days and  vip_data[player_id].cur_days.today_debt then
		vip_data[player_id].cur_days.today_debt=vip_data[player_id].cur_days.today_debt-debt
		vip_data[player_id].cur_days.done_debt=vip_data[player_id].cur_days.done_debt or 0
		vip_data[player_id].cur_days.done_debt=vip_data[player_id].cur_days.done_debt+debt
		return 0
	end
	return nil
end
--获得本局的债务
--[[
cur_day_debt 今天的剩余债务
cur_game   --今天第几次游戏
all_game_times --今天总游戏次数
cur_do_debt --今天已经还过几次债
--]]
local game_debt_min=2
local game_debt_max=4
local debt_min_limit=5000
local init_stake=5000
function PUBLIC.get_game_debt(player_id)
	if vip_data[player_id] and vip_data[player_id].cur_days and  vip_data[player_id].cur_days.today_debt  then
		local cur_day_debt=vip_data[player_id].cur_days.today_debt
		local cur_game=vip_data[player_id].cur_days.game_count
		--###_test
		local all_game_times=0
		if cur_day_debt>debt_min_limit then
			local times=cur_day_debt/(init_stake*2^((game_debt_max+game_debt_min)/2))

			if times<1 then
				times=1
			end

			local gl=times/(all_game_times-cur_game+1)
			if math.random(0,1)<=gl then
				return math.random(game_debt_min,game_debt_max)
			end
		end
	end
	return 0
end
--未完成债务滚入下一期，多余债务加入下一期的红包
--[[
function PUBLIC.settle_today_debt()
	local fanshu=PUBLIC.get_game_debt(player_id)

end
--]]

function PUBLIC.create_game_data(player_id)

	-- {
	-- 	hp_type
	-- 	hp_pai_step_num
	-- 	hupai
	-- }
end

local function get_game_pos_info(fan,player_info)
	if fan<=0 then
		return nil
	end

	local data={}

	for pos,v in ipairs(player_info) do
		if v.player_type=="普通用户" then
			data[pos]=-1
		else
			data[pos]=fan
		end
	end

	return data
end
--[[
player_info:
	数组
	key=位子
	{

		player_id 玩家id
		player_type 玩家类型

	}
--]]
function CMD.get_game_run_data(game_type,tag,player_info)
	local player_id=nil

	for pos,v in ipairs(player_info) do
		if v.player_type=="普通用户" then
			player_id=v.player_id
			break
		end
	end

	local fan=PUBLIC.get_game_debt(player_id)
	if fan<=0 then
		return nil
	end

	local pos_info=get_game_pos_info(fan,player_info)

	return er_mj_hupai_ctrl_lib.get_er_7_hupai_data(pos_info)

end





function CMD.complete_one_game(player_id,data)

end
function CMD.start(_id,_ser_cfg,_config)
	math.randomseed(os.time()*841577)

	vip_sc_cfg = nodefunc.get_global_config("vip_sc_config")
	vip_sc_man.init()
end

-- 启动服务
base.start_service()
