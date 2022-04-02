--
-- Created by yy.
-- User: hare
-- Date: 2018/11/6
-- Time: 14:59
-- 管理器
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"

require "normal_enum"

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST
local PUBLIC = base.PUBLIC
local PROTECT = {}
local MSG = {}

local act_lock = nil

local activity_data = nil

local activity_data_list = nil


-- activity_data_list 需要跳过的key
local ad_skip_key = 
{
	service_id = true,
	game_id = true,
	name_tag = true,
	room_id = true,
	table_num = true,
}

-- 更新玩家活动数据
local function update_activity_data_list(_game_id)
	
	activity_data_list[_game_id] = {}
	local adl = activity_data_list[_game_id]
	
	for _service_id,ad in pairs(activity_data) do
		
		if ad.game_id == _game_id then

			for k,v in pairs(ad) do
				if not ad_skip_key[k] then
					adl[#adl+1] = 
					{
						key = k,
						value = v,
					}
				end
			end

		end

	end
	
end

local function init_data()

	local ad = skynet.call(DATA.service_config.freestyle_activity_center_service,"lua","get_activity_data")

	activity_data = {}
	activity_data_list = {}

	for _service_id,d in pairs(ad) do
		
		local ret = nodefunc.call(_service_id,"query_player_activity_data",DATA.my_id)

		activity_data[_service_id] = ret
		update_activity_data_list(d.game_id)

	end

end


function MSG.game_begin_freestyle_activity(_,_game_id , room_id , table_num , seat_num , player_count)
	for _service_id,ad in pairs(activity_data) do
		
		if ad.game_id == _game_id then
			---- 如果是财神活动
			if ad.activity_id == 3 then
				
				--[[local caishen_data , is_have_cs = nodefunc.call(_service_id,"player_game_begin",room_id , table_num , seat_num , player_count ,DATA.my_id )
				
				--- 如果有财神，就发送一下活动消息
				
				activity_data[_service_id] = caishen_data
				update_activity_data_list(_game_id)
				PUBLIC.update_activity_data()--]]
			
			else
				nodefunc.send(_service_id,"update_activity_data",DATA.my_id,_game_id)
			end
		end

	end
	
end

----- 游戏实体开始时
function MSG.game_instance_begin_freestyle_activity(_,_game_id , room_id , table_num , seat_num , player_count)
	--dump(activity_data , "xxxxxxxxxxx------------------game_instance_begin_freestyle_activity")
	for _service_id,ad in pairs(activity_data) do
		
		if ad.game_id == _game_id then
			---- 如果是财神活动
			if ad.activity_id == 3 then
				--print("xxxxxxxxxxx------------------game_instance_begin_freestyle_activity22",room_id , table_num , seat_num , player_count ,DATA.my_id )
				local caishen_data , is_have_cs = nodefunc.call(_service_id,"player_game_begin",room_id , table_num , seat_num , player_count ,DATA.my_id )
				
				--- 如果有财神，就发送一下活动消息
				if caishen_data then
					activity_data[_service_id] = caishen_data
					update_activity_data_list(_game_id)
					PUBLIC.update_activity_data()
					dump(caishen_data , "xxxxxxxxxxx------------------game_instance_begin_freestyle_activity   caishen_data")
				end
			else
				--- 其他的活动在游戏开始时通知一次
				PUBLIC.update_activity_data()
			end
		end

	end
	
end


function MSG.game_compolete_freestyle_activity(_,_game_id,_score , _settle_data_real_scores , seat_num , player_count , players_info)

	for _service_id,ad in pairs(activity_data) do
		
		if ad.game_id == _game_id then

			if ad.activity_id == 3 then
				activity_data[_service_id] = nodefunc.call(_service_id,"player_game_complete",DATA.my_id,_settle_data_real_scores,seat_num,player_count,players_info)
				update_activity_data_list(_game_id)
			else
				activity_data[_service_id] = nodefunc.call(_service_id,"update_activity_data",DATA.my_id,_game_id,_score)
				update_activity_data_list(_game_id)
			end
		end

	end

end


function MSG.game_exit_freestyle_activity(_,_game_id, _seat_num , _room_id , _table_num  )
	
	for _service_id,ad in pairs(activity_data) do
		
		if ad.game_id == _game_id then
			if ad.activity_id == 2 then
				local pad = nodefunc.call(_service_id,"reset_activity_data",DATA.my_id,_game_id)
				activity_data[_service_id] = pad
				update_activity_data_list(_game_id)
			elseif ad.activity_id == 3 then
				local pad = nodefunc.call(_service_id,"player_game_quit",DATA.my_id,_seat_num,_room_id,_table_num)
				activity_data[_service_id] = pad
				update_activity_data_list(_game_id)
			end
		end

	end
	
	-- print(DATA.my_id.."-game_exit-".._game_id.."+++++++++++")

end




-- 获取自由场奖励
function PUBLIC.get_freestyle_activity_award(_game_id)

	for _service_id,ad in pairs(activity_data) do
		
		if ad.game_id == _game_id and ad.activity_id ~= 3 then

			local ret = nodefunc.call(_service_id,"get_activity_award",DATA.my_id)
			if ret.result == 0 and ret.award then
				CMD.change_asset_multi(ret.award,ASSET_CHANGE_TYPE.FREESTYLE_ACTIVITY_AWARD,ad.activity_id.."_".. ret.log_id .."_"..ret.activity_data.round)
				activity_data[_service_id] = ret.activity_data
				update_activity_data_list(_game_id)
			end

			return ret

		end

	end

	return {result=4402}

end


function PUBLIC.get_activity_data_list(_game_id)

	return activity_data_list[_game_id]

end


function CMD.start_freestyle_activity(_data)
	--print("xxxxxxxxxxx------start_freestyle_activity",DATA.my_id)
	activity_data[_data.service_id] = _data
	update_activity_data_list(_data.game_id)
	--dump(activity_data,"xxxxxxxxxxx2222------start_freestyle_activity")
end


function CMD.over_freestyle_activity(_game_id,_activity_id,_index)

	for _service_id,ad in pairs(activity_data) do
		
		if ad.game_id == _game_id and ad.activity_id == _activity_id then

			activity_data[_service_id] = nil
			update_activity_data_list(_game_id)

		end

	end

end


function PROTECT.init()

	init_data()
	
	DATA.msg_dispatcher:register(MSG,MSG)

end



return PROTECT