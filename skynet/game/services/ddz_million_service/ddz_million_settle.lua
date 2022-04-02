--
-- Author: yy
-- Date: 2018/3/28
-- Time: 
-- 说明：比赛场服务 进行匹配和安排

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "printfunc"
require "normal_enum"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local wait_fuhuo_player_data={player_hash={},num=0}
local win_players = {}

local chk_is_final_over

local timeout_cbk={}
local function set_timeout_cbk(_delay,_func,_tag)
	timeout_cbk[_tag]={countdown=_delay,func=_func}
end

function PUBLIC.try_stop_service(_count,_time)
	return "wait","match game is running !"
end

--比赛最终结束了
local function mathch_final_over()
	
	--###test
	print("settle final is over , all bw match game is finish")
	-- dump(DATA.player_infos,"final rank:")


	-- dump(win_players,"win_players")

	local win_count = #win_players
	if win_count > 0 then
		local issue = DATA.match_config.base_info.issue
		local min_winner = DATA.match_config.base_info.min_winner
		local bonus = DATA.match_config.base_info.bonus
		bonus = math.floor(math.min(bonus/win_count,bonus/min_winner))
		
		----发奖通知
		local email = {
			type = "sys_million_award",
			title = "恭喜您在第"..issue.."期百万大奖赛登顶",
			receiver = "user_id",
			sender = "系统",
			data={bonus=bonus,issue=issue
					,asset_change_data={change_type=ASSET_CHANGE_TYPE.MILLION_AWARD,change_id=issue}}
		}
		local asset_data={{asset_type=PLAYER_ASSET_TYPES.CASH,value=bonus},}
		local bonus_data={}
		for i,player_id in ipairs(win_players) do
			email.receiver = player_id
			bonus_data[#bonus_data+1]={player_id=player_id,bonus=bonus}
			--向数据库进行修改，并且向玩家发送消息
			skynet.send(DATA.service_config.data_service,"lua","multi_change_asset_and_sendMsg",
							player_id,asset_data,ASSET_CHANGE_TYPE.MILLION_AWARD,issue)
			skynet.send(DATA.service_config.email_service,"lua","send_email",email)

			nodefunc.send(player_id,"dbwg_set_million_cup",{issue=issue,bonus=DATA.match_config.base_info.bonus})

			local player_info = DATA.player_infos[player_id]
			PUBLIC.add_match_player_log(player_id,player_info.grades,
										player_info.round,1,asset_data)
		end

		skynet.send(DATA.service_config.data_service,"lua",
									"update_player_million_bonus_rank",bonus_data,issue)

		--广播结果
		skynet.send(DATA.service_config.broadcast_center_service,"lua",
							"fixed_broadcast","million_award",
							win_count)
	end

	-- 记录开始日志
	PUBLIC.end_match_log()
	
	PUBLIC.game_final_finish()

end

--通知玩家复活
local function notification_fuhuo(_players)

	for id,player_id in ipairs(_players) do
		local info=DATA.player_infos[player_id]
		nodefunc.send(player_id,"dbwg_wait_fuhuo_msg",
			DATA.match_config.base_info.fuhuo_countdown,
			info.round,
			DATA.max_round,
			DATA.match_config.process[info.round].fuhuo_ticket
			)

		wait_fuhuo_player_data.player_hash[player_id]=player_id
		wait_fuhuo_player_data.num = wait_fuhuo_player_data.num + 1
	end

end

--通知登顶
local function notification_win(_players,_is_final)
	
	for id,player_id in ipairs(_players) do
		local info=DATA.player_infos[player_id]
		nodefunc.send(player_id,"dbwg_gameover_msg",
			true,
			info.round,
			DATA.max_round,
			nil
			)

		win_players[#win_players+1]=player_id

		--去掉信息
		DATA.out_table_player_data.player_hash[player_id]=nil
		DATA.out_table_player_data.num=DATA.out_table_player_data.num-1

		print("我登顶了"..player_id)

	end

	if not _is_final then
		chk_is_final_over()
	end

end


--检测是否比赛结束了
chk_is_final_over = function()

	--还有人等待复活呢
	if wait_fuhuo_player_data.num > 0 then
		return
	end

	local num = 0
	local players = {}
	for i=1,DATA.max_round do
		num = num + DATA.round_players[i].num
		if num > 2 then
			return
		end
		if num > 0 then
			for player_id,_ in pairs(DATA.round_players[i].player_hash) do
				players[#players+1]=player_id
			end
		end
	end

	if num>0 and num < 3 then

		--清空
		for i,data in pairs(DATA.round_players) do
			DATA.round_players[i].player_hash={}
			DATA.round_players[i].num = 0
		end

		notification_win(players,true)

		DATA.current_status = 3
		mathch_final_over()

	end

	if num < 1 then
		--没有残留的人了
		print("没有残留的人了")
		mathch_final_over()
	end

end


--通知玩家失败
local function notification_departure(_player_id)

	local info=DATA.player_infos[_player_id]

	local award = nil

	local cfg = DATA.match_config.process[info.round]
	if cfg and cfg.award then
		award = 
		{
			asset_type=PLAYER_ASSET_TYPES.DIAMOND,
			value=cfg.award,
		}
	end

	nodefunc.send(_player_id,"dbwg_gameover_msg",
		false,
		info.round,
		DATA.max_round,
		award
		)

	wait_fuhuo_player_data.player_hash[_player_id]=nil
	wait_fuhuo_player_data.num = wait_fuhuo_player_data.num - 1

	PUBLIC.add_match_player_log(_player_id,info.grades,
								info.round,0,award)

	print("我失败了".._player_id)

	chk_is_final_over()

end


--有桌子完成时进行一次检测
local function update_residual_player()
	
	--将低轮的少于3人的人向上轮提
	for i=1,DATA.max_round-1 do
		local num = DATA.round_players[i].num
		if num>0 and num < 3 then
			for player_id,_ in pairs(DATA.round_players[i].player_hash) do

				DATA.round_players[i+1].player_hash[player_id]=player_id
				DATA.round_players[i+1].num=DATA.round_players[i+1].num+1

				DATA.player_infos[player_id].round = i+1

			end
			DATA.round_players[i].player_hash={}
			DATA.round_players[i].num=0
		elseif num > 2 then
			break
		end
	end

end


--通知玩家晋级下轮 查看在所在轮之前的轮还有没有人能和我匹配了，没有就再晋级下一轮
local function notification_promoted(promoted_players,_round)
	
	if _round > DATA.max_round then
		--轮数打完了 - 完成了所有轮
		notification_win(promoted_players)
		-- dump(promoted_players,"在晋级的时候登顶的玩家")
		return
	end

	-- dump(promoted_players,"晋级的玩家")

	for id,player_id in ipairs(promoted_players) do
		--发送比赛晋级消息
		nodefunc.send(player_id,"dbwg_promoted_msg")
	end

	-- dump(DATA.round_players,"DATA.round_players -- 低轮整理之前")

	--更新剩余低轮人数，我们刚晋级的玩家也有可能是低轮
	update_residual_player()

	-- dump(DATA.round_players,"DATA.round_players -- 低轮整理之后")

	--3秒后进行匹配
	set_timeout_cbk(3,PUBLIC.start_rematching,promoted_players)

	chk_is_final_over()

end


--常规赛处理
local function settle_regular(_players,_round)

	local weed_out_players = {}
	local promoted_players = {}

	for id,player_id in pairs(_players) do
		
		local info=DATA.player_infos[player_id]
		info.in_table=false
		local match_player_count=PUBLIC.get_match_player_num()
		local game_config = DATA.game_config[_round]

		--分数小于晋级分数 则被淘汰
		if info.grades < game_config.rise_grades then
			--淘汰
			DATA.out_match_player_data.player_hash[player_id]=player_id
			DATA.out_match_player_data.num=DATA.out_match_player_data.num+1
			weed_out_players[#weed_out_players+1]=player_id
			info.weed_out=match_player_count
		else
			--晋级等候下一轮
			DATA.out_table_player_data.player_hash[player_id]=player_id
			DATA.out_table_player_data.num=DATA.out_table_player_data.num+1

			DATA.match_rest_players[player_id]=player_id

			promoted_players[#promoted_players+1]=player_id
		end
		
		--原来的轮数中清除玩家
		DATA.round_players[_round].player_hash[player_id]=nil
		DATA.round_players[_round].num=DATA.round_players[_round].num-1
	end

	--通知淘汰的玩家复活
	if #weed_out_players>0 then
		notification_fuhuo(weed_out_players)
	end
	
	-- dump(weed_out_players,"淘汰的玩家准备复活")

	local next_round = _round + 1 
	if next_round > DATA.max_round then
		--轮数打完了 - 完成了所有轮
		notification_win(promoted_players)
	else

		--轮数增加
		for i,player_id in ipairs(promoted_players) do
			DATA.round_players[next_round].player_hash[player_id]=player_id
			DATA.round_players[next_round].num=DATA.round_players[next_round].num+1
			DATA.player_infos[player_id].round=next_round
		end


		--通知晋级的玩家晋级了
		notification_promoted(promoted_players,next_round)

	end

end

--复活
function PUBLIC.fuhuo(_player_id)
	local info=DATA.player_infos[_player_id]
	if info.weed_out > 0 then

		info.weed_out = 0
		
		DATA.out_table_player_data.player_hash[_player_id]=_player_id
		DATA.out_table_player_data.num=DATA.out_table_player_data.num+1

		DATA.out_match_player_data.player_hash[_player_id]=nil
		DATA.out_match_player_data.num=DATA.out_match_player_data.num-1

		wait_fuhuo_player_data.player_hash[_player_id]=nil
		wait_fuhuo_player_data.num = wait_fuhuo_player_data.num-1

		local next_round = info.round + 1 
		info.round = next_round
		if next_round > DATA.max_round then
			--轮数打完了 - 完成了所有轮
			notification_win({_player_id})
			print("我复活登顶了".._player_id)
		else

			DATA.round_players[next_round].player_hash[_player_id]=_player_id
			DATA.round_players[next_round].num=DATA.round_players[next_round].num+1
		
			-- dump(DATA.round_players,"DATA.round_players -- 复活之后")

			--通知晋级的玩家晋级了
			notification_promoted({_player_id},next_round)
			DATA.match_rest_players[_player_id]=_player_id

			print(_player_id.."我复活了")
			--3秒后进行匹配
			set_timeout_cbk(3,PUBLIC.start_rematching,_player_id)

		end

		return true
	end
	return false
end

--放弃复活
function PUBLIC.give_up_fuhuo(_player_id)
	notification_departure(_player_id)
end

--结算
function PUBLIC.settle(_players,_round)

	settle_regular(_players,_round)

end


function PUBLIC.settle_update(dt)

	for tag,data in pairs(timeout_cbk) do
		data.countdown=data.countdown-dt
		if data.countdown<=0 then
			if data.func then
				data.func()
			end
			timeout_cbk[tag]=nil
		end
	end

end