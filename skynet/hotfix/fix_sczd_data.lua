--
-- Author: wss
-- Date: 2018/4/11
-- Time: 15:07
-- 说明：
-- 使用方法：
-- call sczd_center_service exe_file "hotfix/fix_sczd_data.lua"
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"
require "normal_enum"


require "printfunc"

local DATA = base.DATA
local CMD = base.CMD
local PUBLIC=base.PUBLIC

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

return function()

	
    return "send ok!!!"

end