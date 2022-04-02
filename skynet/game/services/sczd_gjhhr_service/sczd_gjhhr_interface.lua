

local skynet = require "skynet_plus"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "normal_enum"
require "printfunc"
local cjson = require "cjson"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local PROTECT = {}

--- 推广礼包1的 商品id  (旧版)  金猪礼包1
DATA.tglb1_goods_id = 12

--- 新版礼包1的 商品id  
DATA.tglb1_goods_id_new = 30   

--- 新版礼包1的 打折包 商品id 
DATA.tglb1_goods_id_new_discount = 31  

--- 新版礼包1的 商品id  
DATA.tglb2_goods_id_new = 32   

--- 新版礼包1的 打折包 商品id 
DATA.tglb2_goods_id_new_discount = 33   

--- vip 礼包的商品id
DATA.vip_lb_goods_id = 43

--玩家充值
function CMD.player_pay_msg(player_id,produce_id,num,_channel_type)
	--关键打印 不可去掉
	print("xxxxxxxxxxxxxxxx player_pay_msg 0: ",player_id,produce_id,num,_channel_type)
	if player_id and num and produce_id then
		--玩家购买了 金猪礼包1
		if produce_id== DATA.tglb1_goods_id or produce_id== DATA.tglb1_goods_id_new or produce_id== DATA.tglb1_goods_id_new_discount then
			--通知 sczd_center_service
			--关键打印 不可去掉
			print("xxxxxxxxxxxxxxxx player_pay_msg 1: zjlb  ",player_id)
			skynet.send(DATA.service_config.sczd_center_service,"lua","player_buy_tglb_msg" , player_id , "tglb1")
		elseif produce_id== DATA.tglb2_goods_id_new or produce_id== DATA.tglb2_goods_id_new_discount then
			-- 玩家购买了 金猪礼包2
			print("xxxxxxxxxxxxxxxx player_pay_msg 1: zjlb2  ",player_id)
			skynet.send(DATA.service_config.sczd_center_service,"lua","player_buy_tglb_msg" , player_id , "tglb2")

		elseif produce_id == DATA.vip_lb_goods_id then
			-- 玩家购买了 vip 礼包
			print("xxxxxxxxxxxxxxxx player_pay_msg 1: vip_lb  ",player_id)
			skynet.send(DATA.service_config.sczd_center_service,"lua","player_pay_vip_lb_msg" , player_id )
		end
		print("xxxxxxxxxxxxxxxx player_pay_msg 2: add_player_achievements  ",player_id,num)
		PUBLIC.add_player_achievements(player_id,num)
	end
end
--玩家退款 order_create_time--订单完成时间  根据此时间来确定是否算入高级合伙人的退款 
function CMD.player_refund_msg(player_id,num)
	if player_id and num then
		num=tonumber(num)
		PUBLIC.add_player_refund(player_id,num)
		return 0
	end
	return 1001
end

--高级合伙人状态改变消息  freeze冻结  nor 正常
function CMD.change_gjhhr_status_msg(player_id, status,op_player)
	if status ~= "nor" and status ~= "freeze" or not player_id then
		return 1001
	end

	if DATA.gjhhr_data[player_id] then
		--解冻
		if status=="nor" and DATA.gjhhr_data[player_id].status=="freeze" then
			DATA.gjhhr_data[player_id].status="nor"
			--插入表 sczd_gjhhr_info  
			skynet.send(DATA.service_config.data_service,"lua","op_change_gjhhr_status",op_player,player_id,DATA.gjhhr_data[player_id].status)

		--冻结 
		elseif status=="freeze" and DATA.gjhhr_data[player_id].status=="nor" then
			DATA.gjhhr_data[player_id].status="freeze"
			--插入表 sczd_gjhhr_info  
			skynet.send(DATA.service_config.data_service,"lua","op_change_gjhhr_status",op_player,player_id,DATA.gjhhr_data[player_id].status)
		end

		return 0
	end

	return 2159
end


function CMD.get_gjhhr_achievements_data(player_id)
	-- dump({DATA.gjhhr_data,player_id},"xxxxxxxxxxxxxxxxxxxxxxxxxxx get_gjhhr_achievements_data:")
	if DATA.gjhhr_data[player_id] then
		local v=DATA.gjhhr_query_data[player_id]
		if skynet.getcfg("debug") or not v or not v.query_data_create_time or os.time()-v.query_data_create_time>DATA.refresh_query_data_time then
			PUBLIC.create_gjhhr_query_data(player_id)
		end

		v=DATA.gjhhr_query_data[player_id]
		if v then
			if v.query_data then
				return v.query_data
			else
				return nil,1061
			end
		else
			return nil,1053
		end
	end
	return nil,1057
end

function CMD.change_ticheng_config(cfg)
	if cfg then
		local json_cfg = cjson.decode(cfg)
		if json_cfg and type(json_cfg)=="table" and json_cfg[1] then
			DATA.ticheng_config=json_cfg
			PUBLIC.record_ticheng_config()
			return 0
		end
	end
	return 1001
end

function CMD.verify_gjhhr_info(player_id,weixinUnionId)
	if not player_id then
		player_id = skynet.call(DATA.service_config.data_service,"lua","userId_from_login_id",weixinUnionId,"wechat")
	end

	if not player_id then
		return nil,1001
	end

	if DATA.gjhhr_data[player_id] then
		return CMD.get_gjhhr_achievements_data(player_id)
	else
		return nil,1052
	end
end


function CMD.get_all_gjhhr_base_data()
	for id,v in pairs(DATA.gjhhr_data) do
		local data=PUBLIC.get_gjhhr_query_data(id)
		if not data then
			print("get_all_gjhhr_base_data error  id: ",id)
		end
		v.all_achievements=data.all_achievements
		v.all_income=data.all_income
		v.my_achievements=data.my_achievements
		v.son_tgy_count=data.son_tgy_count
	end
	-- dump(DATA.gjhhr_data,"%%%^^^&&&&%%%^^^")
	return DATA.gjhhr_data

end


--****************对内接口

--插入表 sczd_gjhhr_info  ###_test	skynet.send(DATA.service_config.data_service,"lua","op_new_gjhhr",op_player,player_id)
function CMD.set_new_gjhhr_msg(player_id,parent_gjhhr,parent,op_player)

	--print("xxxxxxxxxxxxxxxxxxxxxxx gjhhr set_new_gjhhr_msg:",player_id,parent_gjhhr,parent,op_player,skynet.self())
	if not DATA.gjhhr_data[player_id] then
		DATA.gjhhr_data[player_id]={}
		DATA.gjhhr_data[player_id].parent_gjhhr=parent_gjhhr
		DATA.gjhhr_data[player_id].become_time=os.time()
		DATA.gjhhr_data[player_id].status="nor"
		DATA.gjhhr_data[player_id].name=skynet.call(DATA.service_config.data_service,"lua","get_player_info",player_id,"player_info","name")
		DATA.gjhhr_data[player_id].parent=parent
		DATA.gjhhr_data[player_id].son_gjhhr={}
		DATA.gjhhr_data[player_id].son_gjhhr_count=0


		if parent_gjhhr  then
			--查询他的儿子的新的信息
			if DATA.gjhhr_data[parent_gjhhr].son_gjhhr then
				local son_data=DATA.gjhhr_data[parent_gjhhr].son_gjhhr
				
				DATA.gjhhr_data[parent_gjhhr].son_gjhhr={}
				DATA.gjhhr_data[parent_gjhhr].son_gjhhr_count=0

				PUBLIC.set_gjhhr_parent_and_superior_gjhhr(son_data)
			end
			PUBLIC.add_son_gjhhr(parent_gjhhr,player_id)
			
		else
			--查询所有没有上级gjhhr的人的详细信息
			local no_superior_gjhhr=PUBLIC.get_no_superior_gjhhr()
			PUBLIC.set_gjhhr_parent_and_superior_gjhhr(no_superior_gjhhr)
		end

		--插入表 sczd_gjhhr_info 
		skynet.send(DATA.service_config.data_service,"lua","op_new_gjhhr",op_player,DATA.gjhhr_data[player_id].become_time,DATA.gjhhr_data[player_id].status,player_id)

		--dump(DATA.gjhhr_data,"xxxxxxxxxxxxxxxxxxxxxxxxxxx set_new_gjhhr_msg gjhhr_data 1 :")
		return 0
	end

	--dump(DATA.gjhhr_data,"xxxxxxxxxxxxxxxxxxxxxxxxxxx set_new_gjhhr_msg gjhhr_data 2:")
	return 4406
end
function CMD.delete_gjhhr_msg(player_id,parent_gjhhr,op_player)
	if DATA.gjhhr_data[player_id] then
		local v=DATA.gjhhr_data[player_id]
		if v.parent_gjhhr then
			PUBLIC.remove_son_gjhhr(v.parent_gjhhr,player_id)
		end
		if v.son_gjhhr then
			PUBLIC.set_gjhhr_parent_and_superior_gjhhr(v.son_gjhhr)
		end
		--删除对应的数据
		DATA.gjhhr_data[player_id]=nil
		--删除数据库sczd_gjhhr_achievements中对应的数据
		skynet.send(DATA.service_config.data_service,"lua","op_delete_gjhhr",op_player,player_id)

		return 0
	end

	return 4405
end

local function change_day_achievement_log(player_id,new_parents,old_parents)

	local sqls = {
		"start TRANSACTION;", -- 开始事物
		-- 本月开始： 1 号的 凌晨 23 点算起
		"set @month_start = date_add(date_add(curdate(),interval -day(curdate())+1 day),interval 82800 second);"
	}

	-- 处理 new_parents
	if new_parents then
		for _,_pid in ipairs(new_parents) do
			sqls[#sqls + 1] = string.format("call change_1_parent_day_achievement_log('%s','%s',@month_start,1);",player_id,_pid)
		end
	end
	
	-- 处理 old_parents
	if old_parents then
		for _,_pid in ipairs(old_parents) do
			sqls[#sqls + 1] = string.format("call change_1_parent_day_achievement_log('%s','%s',@month_start,-1);",player_id,_pid)
		end
	end

	sqls[#sqls + 1] = "COMMIT ;"

	skynet.send(DATA.service_config.data_service,"lua","db_exec",table.concat(sqls,"\n"))
end

function CMD.change_player_relation(player_id,old_parents,new_parents)
	
	if not DATA.player_achievements[player_id] then
        PUBLIC.load_player_achievements(player_id)
    end
    local old_p=nil
    local new_p=nil
	local my_achievements=DATA.player_achievements[player_id].all_achievements 
	local my_tuikuan=DATA.player_achievements[player_id].tuikuan 
	if old_parents and old_parents[1] then
		old_p=old_parents[1]
		local old_parents_2={}
		for i=2,#old_parents do
			old_parents_2[#old_parents_2+1]=old_parents[i]
		end
		PUBLIC.add_player_achievements(old_p,-my_achievements,old_parents_2)
		PUBLIC.add_player_refund(old_p,-my_tuikuan,old_parents_2)
	end

	if new_parents and new_parents[1] then
		new_p=new_parents[1]
		local new_parents_2={}
		for i=2,#new_parents do
			new_parents_2[#new_parents_2+1]=new_parents[i]
		end
		PUBLIC.add_player_achievements(new_p,my_achievements,new_parents_2)
		PUBLIC.add_player_refund(new_p,my_tuikuan,new_parents_2)
	end


	local is_have_p_fjhhr=false
	if old_parents and old_parents[1] then
		for i=1,#old_parents do
			if DATA.gjhhr_data[old_parents[i]] then
				is_have_p_fjhhr=true
				local son=DATA.gjhhr_data[old_parents[i]].son_gjhhr
				DATA.gjhhr_data[old_parents[i]].son_gjhhr={}
				DATA.gjhhr_data[old_parents[i]].son_gjhhr_count=0
				PUBLIC.set_gjhhr_parent_and_superior_gjhhr(son)
				break
			end
		end
	end
	if not is_have_p_fjhhr then
		--查询所有没有上级gjhhr的人的详细信息
		local no_superior_gjhhr=PUBLIC.get_no_superior_gjhhr()
		PUBLIC.set_gjhhr_parent_and_superior_gjhhr(no_superior_gjhhr)
	end

	--写入log
	--sczd_change_parent_log   
	skynet.call(DATA.service_config.data_service,"lua","db_exec",PUBLIC.format_sql("insert into sczd_change_parent_log(player_id,old_parent,new_parent,achievements,tuikuan) values(%s,%s,%s,%s,%s)",player_id,old_p,new_p,my_achievements,my_tuikuan))

	return 0
end

local player_withdraw_lock = {}

-- 高级合伙人提现
function CMD.withdraw_gjhhr(_player_id,_channel_type,_channel_receiver_id,_money)
	local day=os.date("%d")
	if (day=='01' or skynet.getcfg("wait_jicha_settle")) and not skynet.getcfg("gjhhr_tx_force_agree") then
	  return nil,4408  
	end
	
	if player_withdraw_lock[_player_id] then
		return nil,1063
	end

	_money = tonumber(_money)

	if (_money or 0) == 0 then
		return nil,1001
	end

	if skynet.getcfg("forbid_withdraw_cash") then
		return nil,2403
	end

	local withdraw_url = skynet.getcfg("withdraw_url")

	if not withdraw_url then
		return nil,2405
	end

	local _data,code = CMD.get_gjhhr_achievements_data(_player_id)	
	if not _data then
		return nil,code
	end

	if _data.gjhhr_status ~= "nor" then
		return nil,1056
	end

	local _real_money = math.min(_data.jicha_cash or 0,_money)

	local ret = skynet.call(DATA.service_config.asset_service,"lua","query_player_withdraw_cash_gjhhr_status",_player_id,_real_money)
	if ret.status ~= 0 then
		return nil,ret.status
	end
	
	local withdraw_id,errcode
	player_withdraw_lock[_player_id] = true

	xpcall(function()
		withdraw_id,errcode = skynet.call(DATA.service_config.data_service,"lua","create_withdraw_id",
		_player_id,_channel_type,"gjhhr_ht","prop_jicha_cash",_channel_receiver_id,ret.can_withdraw_money)
	end,basefunc.error_handle)

	if not withdraw_id then
		player_withdraw_lock[_player_id] = false
		return nil,errcode
	end

	-- 先直接扣款 ,后续 要做检查、返还、找客服！
	skynet.send(DATA.service_config.data_service,"lua","change_asset",
			_player_id,PLAYER_ASSET_TYPES.PROP_JICHA_CASH,
						-ret.can_withdraw_money,"gjhhr_withdraw",withdraw_id)

	local _url = basefunc.repl_str_var(withdraw_url,{withdrawId=withdraw_id})

	local ok,content
	xpcall(function()
		ok,content = skynet.call(base.DATA.service_config.webclient_service,"lua","request",_url)
	end,basefunc.error_handle)

	print("gjhhr call withdraw url result:",basefunc.tostring({_url,ok,content}))

	player_withdraw_lock[_player_id] = false

	if not ok then
		return nil,2406
	end

	local ok,wddata = xpcall(cjson.decode,basefunc.error_handle,content)

	-- 支付宝 马上就知道结果
	if "alipay" == _channel_type then

		-- result = 0 成功      9011(失败，不扣，加回来)   9012（系统繁忙，等通知确定）9123（代码错，不管，必须改对）
		local _result = tonumber(wddata and wddata.result)

		if 9011 == _result then -- 立即就能确定错误
			skynet.call(DATA.service_config.data_service,"lua","change_withdraw_status",withdraw_id,"fail",nil,content)
		end
	end

	return {
		money=ret.can_withdraw_money,
		order_id=withdraw_id,
		result=wddata and wddata.result or (ok and 0 or 1059),
	}
end


function CMD.query_jicha_cash(player_id)
	local jicha_cash=skynet.call(DATA.service_config.data_service,"lua","query_asset",player_id,"prop_jicha_cash")
	if type(jicha_cash)=="number" then
		return {jicha_cash=jicha_cash}
	end
	return nil,1008
end






