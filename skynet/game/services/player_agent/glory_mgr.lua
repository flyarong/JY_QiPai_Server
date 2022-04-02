--
-- Created by lyx.
-- User: hare
-- Date: 2018/11/6
-- Time: 14:59
-- 任务进程管理器
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local task_initer = require "task.init"

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST
local PUBLIC = base.PUBLIC
local PROTECT = {}
local MSG = {}

local act_lock = nil

local function load_data()
	
	DATA.player_data.glory_data = skynet.call(DATA.service_config.glory_center_service,"lua","query_player_glory_data",DATA.my_id)

	-- 托管随机一下荣耀分
	if not basefunc.chk_player_is_real(DATA.my_id) then

		if DATA.player_data.glory_data.score < 1 then

			local glory_config = skynet.call(DATA.service_config.glory_center_service,"lua","get_config")

			local max_level = glory_config.glory_data[#glory_config.glory_data].level

			local ml = math.floor(max_level*0.5)-1
			ml = math.max(2,ml)
			local lv = math.random(2,ml)
			DATA.player_data.glory_data.level = lv
			DATA.player_data.glory_data.score = glory_config.glory_data[lv].score - math.random(10,1000)

			skynet.send(DATA.service_config.data_service,"lua","update_player_glory_data"
							,DATA.my_id
							,DATA.player_data.glory_data.level
							,DATA.player_data.glory_data.score
							)
		end

	end

end

local function first_promoted(_cfg)
	
	local rs = DATA.player_data.glory_data.score
	local rl = DATA.player_data.glory_data.level

	--发放晋级奖励
	local awd = _cfg.award_data[rl]
	if awd then
		CMD.change_asset_multi(awd,ASSET_CHANGE_TYPE.GLORY_AWARD,rl)
	end

	PUBLIC.request_client("notify_glory_promoted_msg",
							{
							level = rl,
							score = rs,
							})

	--装扮解锁
	local dd = _cfg.dress_data[rl]
	
	if dd then
		--DATA.msg_dispatcher:call("glory_promoted_dress"
		--						,dd.head_frame
		--						,dd.expression
		--						,dd.phrase)

		PUBLIC.trigger_msg( {name = "glory_promoted_dress"} , dd.head_frame
															, dd.expression
															, dd.phrase
															 )

	end

end

function PUBLIC.get_duiju_hongbao_upper_limit()

	return 0
end


function MSG.game_compolete_glory(_,_game_id,_jing_bi,_base_stake)
	
	local glory_config = skynet.call(DATA.service_config.glory_center_service,"lua","get_config")

	local max_level = glory_config.glory_data[#glory_config.glory_data].level
	if DATA.player_data.glory_data.level >= max_level then
		return
	end

	if not _base_stake or _base_stake < 1 then
		return
	end

	local score = (_jing_bi*100/_base_stake)
	local kd = glory_config.score_k[_game_id] or {add=1,dec=1}
	if _jing_bi > 0 then
		score = score*kd.add
	else
		score = score*kd.dec
	end

	score = math.floor(score)

	if score<=0 then
		return 
	end

	DATA.player_data.glory_data.score = DATA.player_data.glory_data.score + score
	
	--晋级
	local rl = DATA.player_data.glory_data.level
	local rs = DATA.player_data.glory_data.score
	
	if score>0 and rl < max_level then
		local promoted_score = glory_config.glory_data[rl].score
		if rs >= promoted_score then
			
			for i=rl,max_level-1 do
				local pd = glory_config.glory_data[i].score
				if rs >= pd then
					DATA.player_data.glory_data.level=DATA.player_data.glory_data.level+1

					first_promoted(glory_config)

				else
					break
				end
			end

		end
	end
	
	skynet.send(DATA.service_config.data_service,"lua","update_player_glory_data"
					,DATA.my_id
					,DATA.player_data.glory_data.level
					,DATA.player_data.glory_data.score
					)

end



function PROTECT.init()

	load_data()
	
	DATA.msg_dispatcher:register(MSG,MSG)

end



return PROTECT