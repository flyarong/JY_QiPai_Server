--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：麻将 房间热更新
-- 使用方法： 
--      hf_inc_ver fix_player_agent
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"
require "normal_enum"

local xiaoxiaole_lib = require "player_agent/xiaoxiaole_agent/xiaoxiaole_lib"

require "printfunc"

local DATA = base.DATA
local CMD = base.CMD
local PUBLIC=base.PUBLIC
local REQUEST = base.REQUEST

local this = {}

function REQUEST.xxl_kaijiang(self)
	--local all_data = DATA.xiaoxiaole_game_data

	local verify_vec = {
		500,
		1000,
		2000,
		4000,
		8000,
		16000,
		32000,
		64000,
		128000,
		256000,
		512000,
		--1024000,
		--2048000,
	}

	local ret = {}
	if not self.bets or type(self.bets) ~= "table" then
		ret.result = 1001
		return ret
	end

	--- 操作限制
	if PUBLIC.get_action_lock("xxl_kaijiang") then
		ret.result = 1008
		return ret
	end
	PUBLIC.on_action_lock( "xxl_kaijiang" )

	dump(DATA.xiaoxiaole_game_data , "-----xxl_kaijiang____all_data")
	
	if not DATA.xiaoxiaole_game_data or DATA.xiaoxiaole_game_data.status ~= "gaming" or not DATA.xiaoxiaole_game_data.room_id or not DATA.xiaoxiaole_game_data.table_id then
		ret.result = 1002
		dump(DATA.xiaoxiaole_game_data , "-----error 1002 1")
		PUBLIC.off_action_lock( "xxl_kaijiang" )
		return ret
	end

	----- 金币消耗验证
	local need_money = 0
	local last_money = nil
	for key,money in pairs(self.bets) do
		need_money = need_money + (money or 0)

		---- 每个值，必须相同
		if last_money then
			if last_money ~= money then
				ret.result = 1001
				PUBLIC.off_action_lock( "xxl_kaijiang" )
				return ret
			end
		end

		last_money = money
	end

	if need_money == 0 then
		ret.result = 1002
		print("-----error 1002 2")
		PUBLIC.off_action_lock( "xxl_kaijiang" )
		return ret
	end

	local is_in_verify_vec = false
	for key,value in pairs(verify_vec) do
		if need_money == value then
			is_in_verify_vec = true
			break
		end
	end
	if not is_in_verify_vec then
		ret.result = 1001
		PUBLIC.off_action_lock( "xxl_kaijiang" )
		return ret
	end


	local ver_ret = PUBLIC.asset_verify({[1] = {
		asset_type = PLAYER_ASSET_TYPES.JING_BI,
		condi_type = NOR_CONDITION_TYPE.CONSUME,
		value =need_money ,
	} })
	if ver_ret.result ~= 0 then
		PUBLIC.off_action_lock( "xxl_kaijiang" )
		return ver_ret
	end

	
	----- 开奖发到房间
	local kaijiang = nodefunc.call( DATA.xiaoxiaole_game_data.room_id , "kaijiang" , DATA.xiaoxiaole_game_data.table_id , self.bets , need_money , math.floor(need_money / #self.bets) )

	if kaijiang and type(kaijiang) == "number" then
		ret.result = kaijiang
		PUBLIC.off_action_lock( "xxl_kaijiang" )
		return ret
	end

	--- 扣钱
	CMD.change_asset_multi({[1] = {asset_type = PLAYER_ASSET_TYPES.JING_BI,value = -need_money }}
			,ASSET_CHANGE_TYPE.XXL_GAME_SPEND, 0 )

	----- 处理一下lucky
	local kaijiang_maps =  kaijiang.kaijiang_maps
	local lucky_maps = ""
	if kaijiang.xc_map_rate and kaijiang.lucky_data and type(kaijiang.lucky_data) == "table" then
		kaijiang_maps , lucky_maps = xiaoxiaole_lib.create_lucky( kaijiang.kaijiang_maps , math.floor(kaijiang.award_rate+0.5) , kaijiang.lucky_data )
	end

	ret.result = 0 
	ret.kaijiang_maps = kaijiang_maps
	ret.lucky_maps = lucky_maps
	ret.award_rate = kaijiang.award_rate       --- 这个是*10的
	ret.award_money = kaijiang.award_money 

	---- 发出消息
	-- DATA.msg_dispatcher:call("xiaoxiaole_award", ret.award_money ) 
	PUBLIC.trigger_msg( {name = "xiaoxiaole_award"} , ret.award_money )

	---- 上一次的奖励的总倍数 * 10 之后的
	DATA.xiaoxiaole_game_data.last_award_rate = ret.award_rate
	---- 上次获得奖励的总钱数
	DATA.xiaoxiaole_game_data.last_award_money = ret.award_money
	
	DATA.xiaoxiaole_game_data.kaijiang_maps = kaijiang_maps
	DATA.xiaoxiaole_game_data.lucky_maps = lucky_maps

	PUBLIC.off_action_lock( "xxl_kaijiang" )
	return ret
end

function this.on_load()
    return "player agent fix on loaded! xxxxx"
end

return this