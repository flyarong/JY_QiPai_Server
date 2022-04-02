--
-- Created by wss.
-- User: hare
-- Date: 2018/12/28
-- Time: 19:29
-- 砸金蛋  agent
--


local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST
local PUBLIC = base.PUBLIC

local PROTECT = {}

--- 当前在玩的锤子id
DATA.gaming_hammer_id = 1

--- 锤子 游戏数据，key = 锤子id,vlaue = {}
DATA.hammer_game_data = {}

--- 对应的房间，table
DATA.my_zjd_room = nil
DATA.my_zjd_table = nil

--- 是否在游戏中
DATA.is_gaming_zjd = false

---- 可以打开的蛋的数量
DATA.can_open_egg_num = 0

---- 排行榜，缓存清理时间,单位 秒
DATA.cache_data_clear_time = 3600
--- 上次获取的时间
DATA.cache_rank_data_time = nil
--- 排行榜数据
DATA.rank_data = nil

DATA.log_data = nil

--- 日志，一页显示的个数
DATA.log_page_num = 20


---- 获得砸金蛋游戏状态,
function REQUEST.zjd_get_game_status()
	local result_code = 0
	if not DATA.is_gaming_zjd then
		--- 没有在游戏中的话，或者是agent重新登录，要获取一下信息

		local room_id,table_id = skynet.call( DATA.service_config.zajindan_manager_service , "lua" , "get_or_create_zjd_room" , DATA.my_id , DATA.player_data.player_info.name )
		DATA.my_zjd_room = room_id
		DATA.my_zjd_table = table_id

		DATA.is_gaming_zjd = true
		--- 获得游戏数据
		local game_status = nodefunc.call( DATA.my_zjd_room , "get_game_status" , DATA.my_zjd_table )

		result_code = game_status.result
		DATA.gaming_hammer_id = game_status.gaming_hammer_id
		DATA.hammer_game_data = game_status.hammer_game_data

		--- 获得能砸几个
		DATA.can_open_egg_num = nodefunc.call( DATA.my_zjd_room , "get_can_open_egg_num" )

	end

	-- PUBLIC.lock("zajindan","zajindan")
	
	local game_status = {}
	for key,data in pairs(DATA.hammer_game_data) do

		local award_list = {}
		for _key,_data in pairs(data.award_data) do
			award_list[#award_list + 1] = _data.id
		end

			game_status[#game_status+1] = {
				level = data.level,
				-- hammer_num = data.hammer_num,
				base_money = data.base_money,
				eggs_status = data.eggs_status,
				award_list = award_list,
				replace_money = data.replace_money,
			}
	end

	return {
		result = result_code,
		status = {
			now_level = DATA.gaming_hammer_id,
			status = game_status,
		}
	}
end
function PROTECT.zjd_deduct_money(level,count)
	local hammer="prop_hammer_"..level
	local base_money=DATA.hammer_game_data[level].base_money

	
	local hammer_num = CMD.query_asset_by_type(hammer)
	hammer_num= hammer_num or 0

	--- 如果锤子不足，可以用金币支付
	if hammer_num>=count then
		hammer_num=count
		count=0
	else
		count=count-hammer_num
	end
	local need_money=base_money*count

	if need_money>0 then
		local ver_ret = PUBLIC.asset_verify({[1] = {
			asset_type = PLAYER_ASSET_TYPES.JING_BI,
			condi_type = NOR_CONDITION_TYPE.CONSUME,
			value =need_money ,
		} })
		if ver_ret.result ~= 0 then
			PUBLIC.off_action_lock( "zjd_kaijiang" )
			return ver_ret.result
		end
	end
	
	if hammer_num>0 then
		--- 扣锤子
		CMD.change_asset_multi({[1] = {asset_type = hammer , value = -hammer_num }}
			,ASSET_CHANGE_TYPE.EGG_GAME_SPEND, level )
	end
	if need_money>0 then
		--- 扣钱
		CMD.change_asset_multi({[1] = {asset_type = PLAYER_ASSET_TYPES.JING_BI,value = -need_money }}
			,ASSET_CHANGE_TYPE.EGG_GAME_SPEND, level )
	end


	--使用的财物类型  0 金币 1 锤子  2 金币加锤子 
	local use_type=0
	if need_money>0 and hammer_num>0 then
		use_type=2
	elseif need_money>0 then
		use_type=0
	elseif hammer_num>0 then
		use_type=1
	end

	return 0,use_type,need_money,hammer_num
end
function PROTECT.zjd_caishen_deduct_money(level)
	
	local base_money={100,1000,10000,20000,40000,80000}
	local need_money=base_money[level]*19
	local hammer_num={} 
	for i=1,4 do
		hammer_num[i]=CMD.query_asset_by_type("prop_hammer_"..i)
	end
	dump(hammer_num,"现有的锤子")
	--抵扣的钱
	local dikou_money=0
	local dikou_hammer={}

	--算出抵扣的钱和使用的锤子 ###_test
	local hammer_price = {100,1000,10000,100000}
	local _shenxia = need_money
	for i=4,1,-1 do
		local hcount = math.min(math.floor(_shenxia / hammer_price[i]),hammer_num[i] or 0)
		if hcount > 0 then

			dikou_hammer[i] = hcount

			local _dk = math.floor(hcount * hammer_price[i] + 0.5)
			dikou_money = dikou_money + _dk

			_shenxia = _shenxia - _dk
		end
	end

	--- 如果锤子不足，可以用金币支付
	need_money=need_money-dikou_money

	if need_money>0 then
		local ver_ret = PUBLIC.asset_verify({[1] = {
			asset_type = PLAYER_ASSET_TYPES.JING_BI,
			condi_type = NOR_CONDITION_TYPE.CONSUME,
			value =need_money ,
		} })
		if ver_ret.result ~= 0 then
			PUBLIC.off_action_lock( "zjd_kaijiang" )
			return ver_ret.result
		end
	end
	
	for k,v in pairs(dikou_hammer) do
		--- 扣锤子
		if v>0 then
			print("抵扣的锤子",k,v)
			CMD.change_asset_multi({[1] = {asset_type = "prop_hammer_"..k , value = -v  }}
				,ASSET_CHANGE_TYPE.EGG_GAME_SPEND, level )
		end
	end
	if need_money>0 then
		--- 扣钱
		CMD.change_asset_multi({[1] = {asset_type = PLAYER_ASSET_TYPES.JING_BI,value = -need_money }}
			,ASSET_CHANGE_TYPE.EGG_GAME_SPEND, level )
	end

	print("使用的钱  ",need_money,dikou_money)
	--使用的财物类型  0 金币 1 锤子  2 金币加锤子 
	local use_type=0
	if need_money>0 and dikou_money>0 then
		use_type=2
	elseif need_money>0 then
		use_type=0
	elseif dikou_money>0 then
		use_type=1
	end

	return 0,use_type,need_money,dikou_money
end
--砸金蛋财神模式开奖
function PROTECT.zjd_caishen_model_kaijiang(self)
	local ret={}
	--- 操作限制
	if PUBLIC.get_action_lock("zjd_kaijiang") then
		ret.result = 1008
		return ret
	end
	PUBLIC.on_action_lock( "zjd_kaijiang" )

	--为了方便客户端  按eggno来计算真正的level
	local real_level=1
	if self.egg_no==101 or self.egg_no==102 then
		real_level=1
	elseif self.egg_no==103 or self.egg_no==104 then
		real_level=2
	elseif self.egg_no==105 or self.egg_no==106 then
		real_level=3
	elseif self.egg_no==107 or self.egg_no==108 then
		real_level=4
	elseif self.egg_no==109 or self.egg_no==110 then
		real_level=5
	elseif self.egg_no==111 or self.egg_no==112 then
		real_level=6
	end


	-- 
	local kouqian_res,use_type,use_money,dikou_money=PROTECT.zjd_caishen_deduct_money(real_level)
	if kouqian_res~=0 then
		ret.result = kouqian_res
		return ret
	end
	

	local kaijiang_res = nodefunc.call( DATA.my_zjd_room , "zjd_caishen_mode" , DATA.my_zjd_table , real_level, self.egg_no )
	if type(kaijiang_res) == "number" or kaijiang_res=="CALL_FAIL" then
		if kaijiang_res=="CALL_FAIL" then
			ret.result=1000
		else
			ret.result = kaijiang_res
		end
		PUBLIC.off_action_lock( "zjd_kaijiang")
		return ret
	end

	dump(kaijiang_res.kaijiang , "xxxx--------------------------kaijiang_res.kaijiang:" )

	local now_time = os.time()
	if kaijiang_res.kaijiang and DATA.log_data then
		table.insert( DATA.log_data , 1 , { player_id = DATA.my_id , award_type = kaijiang_res.kaijiang.award_type ,award_value = kaijiang_res.kaijiang.award_money, time = now_time })
	end

	ret.result=0
	ret.level = self.level
	ret.egg_no = self.egg_no
	ret.egg_status =-1  
	ret.replace_money = 0
	ret.status = 0
	ret.is_spend_hammer =use_type
	ret.use_money=use_money
	ret.dikou_money =dikou_money

	ret.kaijiang = {}

	if kaijiang_res.kaijiang then
		for key,data in ipairs(kaijiang_res.kaijiang) do
			ret.kaijiang[#ret.kaijiang+1] = { egg_no = data.egg_no , award = data.award , award_value = data.award_value }
		
			--*********************砸金蛋财神模式连胜活动 目前是临时实现 等活动及任务系统调整完毕后修改  by hewei  ###_test
				local s_time=skynet.getcfg_2number("zjd_cs_lisnsheng_start")
				local e_time=skynet.getcfg_2number("zjd_cs_lisnsheng_end")
				if s_time and e_time then
					local cur_time=os.time()
					if cur_time>s_time and cur_time<e_time then
						local send_level=real_level
						if real_level>3 then
							send_level=3
						end
						skynet.send(DATA.service_config.zjd_cs_liansheng_act_service,"lua","zjd_cs_kaijiang_res",DATA.my_id,send_level,data.award_value)
					end
				end
			--*********************砸金蛋财神模式连胜活动 目前是临时实现 等活动及任务系统调整完毕后修改  by hewei   ###_test
		end


		--- 发出砸金蛋奖励信号
		--DATA.msg_dispatcher:call("zajindan_award", kaijiang_res.kaijiang.award_money or 0 )
		PUBLIC.trigger_msg( {name = "zajindan_award"} , kaijiang_res.kaijiang.award_money or 0 )
	end




	PUBLIC.off_action_lock( "zjd_kaijiang" )


	return ret

end
--*********************砸金蛋财神模式连胜活动 目前是临时实现 等活动及任务系统调整完毕后修改  by hewei  ###_test
function REQUEST.get_zjd_cs_ls_act_cur_ls(self)
	if not self or not self.level or type(self.level)~="number" then
		return {result=1003}
	end
	local s_time=skynet.getcfg_2number("zjd_cs_lisnsheng_start")
	local e_time=skynet.getcfg_2number("zjd_cs_lisnsheng_end")
	if s_time and e_time then
		local cur_time=os.time()
		if cur_time>s_time and cur_time<e_time then
			local cur_ls=skynet.call(DATA.service_config.zjd_cs_liansheng_act_service,"lua","get_cur_ls",DATA.my_id,self.level)
			if cur_ls=="CALL_FAIL" then
				return {result=1000}
			end
			if not cur_ls then
				return {result=4602}
			end
			return {result=0,cur_ls=cur_ls}
		end
	end
	return {result=4602}

end
--*********************砸金蛋财神模式连胜活动 目前是临时实现 等活动及任务系统调整完毕后修改  by hewei  ###_test

----- 砸金蛋，开奖
function REQUEST.zjd_kaijiang(self)
	-- dump(self)
	local ret = {}
	ret.result = 0

	--- 判断参数
	if not self.level or not self.egg_no or type(self.level) ~= "number" or type(self.egg_no) ~= "number" or self.level ~= DATA.gaming_hammer_id then
		ret.result = 1001
		return ret
	end
	--财神模式
	if skynet.getcfg("zjd_caishen_model")  and (self.egg_no>100 and self.egg_no<113) then
		local res=PROTECT.zjd_caishen_model_kaijiang(self)
		dump(res,"!!!!!!!!!!!!!")
		return res
	end

	--- 判断其他
	if not DATA.hammer_game_data[self.level] 
		or not DATA.hammer_game_data[self.level].eggs_status[self.egg_no] 
		or DATA.hammer_game_data[self.level].eggs_status[self.egg_no] == -1
		or DATA.hammer_game_data[self.level].opened_egg_num >= DATA.can_open_egg_num then
		dump(DATA.hammer_game_data , "zjd anget kaijiang 1003")
		print("------------------------------------ zjd anget kaijiang 1003")
		ret.result = 1003
		return ret
	end

	--- 操作限制
	if PUBLIC.get_action_lock("zjd_kaijiang") then
		ret.result = 1008
		return ret
	end
	PUBLIC.on_action_lock( "zjd_kaijiang" )

	---- 如果条件达成
	local is_cod_do , gift_bag_id = PROTECT.zajindan_activity_condtion( self.level , CMD.query_asset_by_type("jing_bi") , CMD.query_asset_by_type("prop_hammer_"..self.level) )
	local is_gift_show = 0
	if is_cod_do then
		--- 发送,这个用call阻塞一下
		is_gift_show = skynet.call(base.DATA.service_config.pay_service,"lua","player_trigger_condition", DATA.my_id , gift_bag_id )
	end

	local kouqian_res,use_type=PROTECT.zjd_deduct_money(self.level,1)
	if kouqian_res~=0 then
		ret.result = kouqian_res
		--- 如果礼包显示，返回一个特殊码
		if is_gift_show == 1 then
			ret.result = 4601
		end
		return ret
	end

	local za_dan_data = nodefunc.call( DATA.my_zjd_room , "za_jin_dan" , DATA.my_zjd_table , self.level, self.egg_no , is_hammer_num_enough )
	if type(za_dan_data) == "number" then
		ret.result = za_dan_data

		PUBLIC.off_action_lock( "zjd_kaijiang" )
		return ret
	end

	local now_time = os.time()

	if za_dan_data.kaijiang and DATA.log_data then
		table.insert( DATA.log_data , 1 , { player_id = DATA.my_id , award_type = za_dan_data.kaijiang.award_type ,award_value = za_dan_data.kaijiang.award_money, time = now_time })
	end

	ret.level = self.level
	ret.egg_no = self.egg_no
	--ret.hammer_num = za_dan_data.game_data.hammer_num
	ret.replace_money = za_dan_data.game_data.replace_money

	ret.egg_status = za_dan_data.game_data.eggs_status[self.egg_no]
	-- ret.kaijiang = za_dan_data.kaijiang
	ret.kaijiang = {}

	if za_dan_data.kaijiang then
		for key,data in ipairs(za_dan_data.kaijiang) do
			ret.kaijiang[#ret.kaijiang+1] = { egg_no = data.egg_no , award = data.award , award_value = data.award_value }
		end

		--- 发出砸金蛋奖励信号
		--DATA.msg_dispatcher:call("zajindan_award", za_dan_data.kaijiang.award_money or 0 )
		PUBLIC.trigger_msg( {name = "zajindan_award"} , za_dan_data.kaijiang.award_money or 0 )
	end

	ret.status = za_dan_data.kaijiang and za_dan_data.kaijiang.award_type or 0
	ret.is_spend_hammer = use_type

	--- 更新agent数据
	DATA.hammer_game_data[self.level] = za_dan_data.game_data

	--- 如果礼包显示，返回一个特殊码
	if is_gift_show == 1 then
		ret.result = 4600
	end

	PUBLIC.off_action_lock( "zjd_kaijiang" )


	return ret
end

---- 换一拨蛋
function REQUEST.zjd_replace_eggs(self)
	local ret = {}
	ret.result = 0

	--- 判断参数
	if not self.level or type(self.level) ~= "number" or self.level ~= DATA.gaming_hammer_id then
		ret.result = 1001
		return ret
	end

	--- 操作限制
	if PUBLIC.get_action_lock("zjd_replace_eggs") then
		ret.result = 1008
		return ret
	end
	PUBLIC.on_action_lock( "zjd_replace_eggs" )

	------- 

	---- 如果有蛋的话才能换蛋扣钱
	local is_spend_money = false
	dump(DATA.hammer_game_data[self.level].eggs_status , "--------------------- zjd_replace_eggs , eggs_status ")
	if DATA.hammer_game_data[self.level].eggs_status then
		---- 换蛋的资产验证
		local ver_ret = PUBLIC.asset_verify({[1] = {
			asset_type = PLAYER_ASSET_TYPES.JING_BI,
			condi_type = NOR_CONDITION_TYPE.CONSUME,
			value = DATA.hammer_game_data[self.level].replace_money,
		} })
		if ver_ret.result ~= 0 then
			ret.result = ver_ret.result

			PUBLIC.off_action_lock( "zjd_replace_eggs" )
			return ret
		end

		if DATA.hammer_game_data[self.level].replace_money > 0 then
			is_spend_money = true
		end

		--- 扣钱
		CMD.change_asset_multi({[1] = {asset_type = PLAYER_ASSET_TYPES.JING_BI,value = -DATA.hammer_game_data[self.level].replace_money }}
				,ASSET_CHANGE_TYPE.EGG_GAME_REPLACE_EGG, 0 )


	end

	--- 换 蛋
	local data = nodefunc.call( DATA.my_zjd_room , "replace_eggs" , DATA.my_zjd_table , self.level, self.egg_no , is_spend_money )

	if type(data) == "number" then
		ret.result = data

		PUBLIC.off_action_lock( "zjd_replace_eggs" )
		return ret
	end

	ret.level = self.level
	ret.award_list = data.award_list

	DATA.hammer_game_data[self.level] = data.game_data

	ret.replace_money = data.game_data.replace_money

	PUBLIC.off_action_lock( "zjd_replace_eggs" )
	return ret
end


----  换锤子
function REQUEST.zjd_replace_hammer(self)
	local ret = {}
	ret.result = 0
	dump(self,"------------zjd_replace_hammer")
	--- 判断参数
	if not self.level or type(self.level) ~= "number" or self.level > 4 then
		ret.result = 1001
		return ret
	end

	--- 操作限制
	if PUBLIC.get_action_lock("zjd_replace_hammer") then
		ret.result = 1008
		return ret
	end
	PUBLIC.on_action_lock( "zjd_replace_hammer" )

	------- 

	local data = nodefunc.call( DATA.my_zjd_room , "zjd_replace_hammer" , DATA.my_zjd_table , self.level)

	if type(data) == "number" then
		ret.result = data

		PUBLIC.off_action_lock( "zjd_replace_hammer" )
		return ret
	end

	ret.level = data.gaming_hammer_id

	DATA.gaming_hammer_id = data.gaming_hammer_id

	PUBLIC.off_action_lock( "zjd_replace_hammer" )
	return ret
end


--- 获得排行榜
function REQUEST.get_zjd_rank(self)
	local now_time = os.time()

	if not DATA.rank_data or not DATA.cache_rank_data_time then
		DATA.rank_data = nodefunc.call( DATA.my_zjd_room , "get_today_rank" )
		DATA.cache_rank_data_time = now_time
	else
		if now_time - DATA.cache_rank_data_time > DATA.cache_data_clear_time then
			DATA.rank_data = nodefunc.call( DATA.my_zjd_room , "get_today_rank" )
			DATA.cache_rank_data_time = now_time
		end
	end

	
	--- 排行榜数据
	local ret = {}
	ret.result = 0
	ret.rank_data = {}

	for key,data in pairs(DATA.rank_data) do
		ret.rank_data[#ret.rank_data + 1] = { player_id = data.player_id , today_award = data.today_get_award }
	end

	return ret
end

function REQUEST.get_zjd_log(self)
	local ret = {}
	ret.result = 0

	local now_time = os.time()

	if not self.page_index or type(self.page_index) ~= "number" then
		ret.result = 1001
		return ret
	end

	if not DATA.log_data then
		DATA.log_data = nodefunc.call( DATA.my_zjd_room , "get_zajindan_log" , DATA.my_id )
	end

	ret.log_data = {}

	local start_index = self.page_index * DATA.log_page_num
	local end_index = (self.page_index+1) * DATA.log_page_num
	if start_index > #DATA.log_data then
		start_index = #DATA.log_data+1
	end
	if end_index > #DATA.log_data then
		end_index = #DATA.log_data
	end

	for i = start_indexm, end_index do
		ret.log_data[#ret.log_data + 1] = {
			award = DATA.log_data[i].award_value,
			time = DATA.log_data[i].time,
		}
	end

end


---- 砸金蛋的玩家退出
function PUBLIC.zajindan_player_login()
	--- 给管理器发送
	skynet.send( DATA.service_config.zajindan_manager_service , "lua" , "player_login" , DATA.my_id )

end

---- 砸金蛋的玩家退出
function PUBLIC.zajindan_player_logout()
	--- 给管理器发送，我已经退出来
	skynet.send( DATA.service_config.zajindan_manager_service , "lua" , "player_logout" , DATA.my_id )

	-- PUBLIC.unlock("zajindan","zajindan")

end

function PROTECT.init()
	
end

------- 砸金蛋 限时特惠  条件是否达成
function PROTECT.zajindan_activity_condtion( hammer_id , remain_jing_bi , now_hammer_num )
	local gift_bag_id = nil
	local gift_data = nil

	local shoping_config = PUBLIC.get_shoping_config()

	--dump( shoping_config , "---------------- shoping_config")

	if hammer_id == 3 then
		gift_bag_id = 36
		gift_data = shoping_config.gift_bag[gift_bag_id]
	elseif hammer_id == 4 then
		gift_bag_id = 37
		gift_data = shoping_config.gift_bag[gift_bag_id]
	end

	print("--------------- zajindan_activity",hammer_id , remain_jing_bi , now_hammer_num )

	if gift_bag_id and gift_data and gift_data.condition and gift_data.condition.condition_group and gift_data.condition.condition_group[1] then
		local condition_data = gift_data.condition.condition_group[1]

		if hammer_id == condition_data.hammer_ground and remain_jing_bi < condition_data.max_jing_bi and now_hammer_num <= condition_data.prop_hammer then
			print("----------------zajindan_activity --- send msg")
			return true , gift_bag_id
		end
	end

	return false , gift_bag_id
end

------- 砸金蛋 限时特惠  活动发出的消息
function PROTECT.zajindan_activity( hammer_id , remain_jing_bi , now_hammer_num )
	
	local condition_do , gift_bag_id = PROTECT.zajindan_activity_condtion( hammer_id , remain_jing_bi , now_hammer_num )
	if condition_do then
		skynet.send(base.DATA.service_config.pay_service,"lua","player_trigger_condition", DATA.my_id , gift_bag_id )
	end

end


return PROTECT