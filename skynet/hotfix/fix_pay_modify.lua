--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：发公告
-- 使用方法：
-- call data_service exe_file "hotfix/fix_pay_order.lua"
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require"printfunc"

local monitor_lib = require "monitor_lib"

local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC
local REQUEST=base.REQUEST


require "normal_enum"

local payment_config = require "payment_config"

local LL = DATA.payment_info_data

local order_status={
	create=true,
	error=true,
	fail=true,
	complete=true,
}

local function complete_shop_order(_order,_detail)

	if _order.convert then

		local cc = LL.shoping_config[_order.convert]

		if cc then

			local d
			for gi,_goods in pairs(cc) do
				if _order.convert_id == _goods.id then
					d = _goods
				end
			end
			
			local _detail_convert = {}

			local num = d.num
			base.CMD.change_asset(_order.player_id,_order.convert,num,ASSET_CHANGE_TYPE.BUY,_order.order_id)

			_detail_convert[#_detail_convert+1]=
			{
				asset_type = _order.convert,
				asset_count = num,
			}

			for i,v in ipairs(d.gift_asset_type) do
				base.CMD.change_asset(_order.player_id,v,d.gift_asset_count[i],ASSET_CHANGE_TYPE.BUY_GIFT,_order.order_id)
				_detail_convert[#_detail_convert+1]=
				{
					asset_type = v,
					asset_count = d.gift_asset_count[i],
				}
			end

			-- 推送玩家消息
			nodefunc.send(_order.player_id,"notify_pay_order_asset_change_msg",_detail_convert,ASSET_CHANGE_TYPE.BUY,_order.order_id)

			return
		end

		print(" complete_shop_order convert error: ".._order.convert)
	end


	for _,_asset in ipairs(_detail) do
		if basefunc.is_asset(_asset.asset_type) then
			if _asset.goods_type == "buy" then
				base.CMD.change_asset(_order.player_id,_asset.asset_type,_asset.asset_count,ASSET_CHANGE_TYPE.BUY,_order.order_id)
			else
				base.CMD.change_asset(_order.player_id,_asset.asset_type,_asset.asset_count,ASSET_CHANGE_TYPE.BUY_GIFT,_order.order_id)
			end
		end
	end

	-- 推送玩家消息
	nodefunc.send(_order.player_id,"notify_pay_order_asset_change_msg",_detail,ASSET_CHANGE_TYPE.BUY,_order.order_id)

end


local function complete_gift_bag_order(_order,_detail)

	local assets = {}

	for _,_asset in ipairs(_detail) do
		assets[#assets+1]={
			asset_type = _asset.asset_type,
			value = _asset.asset_count,
		}
	end

	base.CMD.multi_change_asset_and_sendMsg(_order.player_id,assets,"buy_gift_bag_".._order.product_id,_order.order_id)

	skynet.call(base.DATA.service_config.pay_service,"lua","player_buy_gift_bag",_order.player_id,_order.product_id,1)

end

-- 完成订单
local function do_complete(_order_id)
	local order = LL.payment_info[_order_id]
	if not order then
        return "not found order :" .. tostring(_order_id)
    end

	local procid = tonumber(order.product_id)
	if not procid then
		--print("modify_pay_order 1001 error!",_order_id,order.product_id,tonumber(order.product_id),basefunc.tostring(order))
		return "product_id error!!"
    end
    
    local detail = LL.payment_info_detail[_order_id]

    local goods = LL.shoping_goods_config[procid]

    if goods.shop_type == "shop" then

        complete_shop_order(order,detail)

    elseif goods.shop_type == "gift_bag" then
        
        complete_gift_bag_order(order,detail)

    else

        return string.format("shop_type '%s' is incorrect!",tostring(goods.shop_type))
	end
	
	order.order_status = "complete"

    base.CMD.add_consume_statistics(order.player_id,"pay",order.money)
    nodefunc.send(order.player_id,"notify_pay_order_status",0,nil,_order_id,order.product_id,detail)

	local sql = string.format([[update player_pay_order set order_status='complete',channel_account_id='fix_by_shougong' where order_id='%s';]],_order_id)

    -- 成功订单统计
    sql = sql .. string.format(
        [[insert into player_pay_order_stat(player_id,first_complete_time,first_order_id,last_complete_time,last_order_id,sum_money) 
        values('%s',FROM_UNIXTIME(%u),'%s',FROM_UNIXTIME(%u),'%s',%d) 
        on duplicate key update last_complete_time=FROM_UNIXTIME(%u),last_order_id='%s',sum_money=sum_money+%d;]],
        order.player_id,os.time(),_order_id,os.time(),_order_id,order.money * order.product_count,
        os.time(),_order_id,order.money * order.product_count) ..

        -- 增长更新序号
		string.format("update player_info set sync_seq=%d where id='%s';",base.PUBLIC.auto_inc_id("last_player_info_seq"),order.player_id)
		
	base.DATA.sql_queue_fast:push_back(sql)		

    monitor_lib.add_data("pay",order.money)

    --- 支付成功消息 --关键打印不能去掉
    dump(order,"fix normal pay_order on_pay_success trigger !!!!!!!!!!!")
    --- 支付成功消息
	--base.DATA.events.on_pay_success:trigger(order.player_id,procid,order.money,order.channel_type)
	
	--- 向通知中心触发消息
	skynet.send( base.DATA.service_config.msg_notification_center_service , "lua" , "trigger_msg" 
																				, {name = "on_pay_success"} 
																				, order.player_id,procid,order.money,order.channel_type )

    return "ok"
end

-- 第一批 。。 后来手工补了 sql
-- local fix_orders = {
-- 	"201905140000205LAUJu",
-- 	"201905140000211mAFJh",
-- 	"201905140000216QRq7E",
-- 	"201905140000217GQgrF",
-- 	"201905140000222Med8A",
-- 	"201905140000226Eyy2j",
-- 	"201905140000232L4qud",
-- 	"201905140000234q4dUn",
-- 	"201905140000236kKerr",
-- 	"201905140000257g7quY",
-- 	"201905140000259UN3h3",
-- 	"201905140000266H23nd",
-- 	"201905140000267aryBt",
-- 	"201905140000271yr387",
-- 	"20190514000028392YL4",
-- 	"201905140000288jbrit",
-- 	"201905140000311AterQ",
-- 	"2019051400003232tUfa",
-- 	"201905140000340DydAL",
-- 	"201905140000343DtgU8",
-- 	"201905140000345j424t",
-- 	"2019051400003469FmTH",
-- 	"201905140000347LiUnE",
-- 	"201905140000354UU6fr",
-- 	"20190514000035567qha",
-- 	"201905140000356K9nmQ",
-- 	"201905140000380GrhfK",
-- 	"201905140000381kk98A",
-- 	"201905140000410FtdUH",
-- 	"201905140000399DR7ry",
-- 	"201905140000392H3irF",
-- 	"2019051400003887Mkjh",
-- 	"201905140000383uyUyH",
-- 	"201905140000385YmjQR",
-- 	"201905140000375LDDaT",
-- 	"201905140000342EDmLD",
-- 	"201905140000338Bn26J",
-- 	"201905140000331mLDLb",
-- 	"201905140000328taakR",
-- 	"2019051400003279fbq9",
-- 	"2019051400003054Ay8B",	
-- }

-- 第二批
-- local fix_orders = {
-- 	"201905140000418mrDaB",
-- 	"201905140000416EdMFu",
-- 	"201905140000412qAQ2g",
-- 	"201905140000411NLqqY",
-- 	"201905140000408hJGmg",
-- 	"20190514000040776Mu8",
-- 	"201905140000394d6NJr",
-- 	"2019051400003933jraJ",
-- 	"201905140000382eDH6B",
-- 	"201905140000379bi3f8",
-- 	"201905140000376M93Rg",
-- 	"201905140000374LueFq",
-- 	"201905140000373BryBH",
-- 	"2019051400003702huLM",
-- 	"201905140000369MYQ2d",
-- 	"2019051400003629dLUA",
-- 	"201905140000365uFB3a",
-- 	"201905140000363kmdGk",
-- 	"201905140000361L3BEQ",
-- 	"2019051400003532UrFM",
-- 	"201905140000339aLEYb",
-- 	"201905140000341uUmmq",
-- 	"201905140000335k7tjF",
-- 	"201905140000332Ghk2L",
-- 	"201905140000329HJYE2",
-- 	"201905140000319ua8na",
-- 	"201905140000318bdUM8",
-- 	"201905140000317jhDDf",
-- 	"201905140000314HAmM6",
-- 	"201905140000308MUrmf",
-- 	"201905140000307JKQjY",
-- 	"2019051400003066QM7F",
-- 	"201905140000304EkJEh",
-- 	"201905140000302eyBqj",
-- 	"201905140000419HiYTH",
-- 	"201905140000406qG4q2",
-- 	"201905140000391YM3A7",
-- 	"201905140000390jGuke",
-- 	"201905140000387AEHEi",
-- 	"2019051400003864b9gY",
-- }

-- 第三批
local fix_orders = {
	"201905100000720jfFaR",
	"201905100000725L47Ky",
	"201905100000728LTDJQ",
	"201905100000739tkLf4",
	"201905100000753QHAn7",
	"201905100000775YEG2A",
	"201905100000776en2yF"
}


-- 仅修改内存状态
local fix_mem_status = {

	"201905140000205LAUJu",
	"201905140000211mAFJh",
	"201905140000216QRq7E",
	"201905140000217GQgrF",
	"201905140000222Med8A",
	"201905140000226Eyy2j",
	"201905140000232L4qud",
	"201905140000234q4dUn",
	"201905140000236kKerr",
	"201905140000257g7quY",
	"201905140000259UN3h3",
	"201905140000266H23nd",
	"201905140000267aryBt",
	"201905140000271yr387",
	"20190514000028392YL4",
	"201905140000288jbrit",
	"201905140000311AterQ",
	"2019051400003232tUfa",
	"201905140000340DydAL",
	"201905140000343DtgU8",
	"201905140000345j424t",
	"2019051400003469FmTH",
	"201905140000347LiUnE",
	"201905140000354UU6fr",
	"20190514000035567qha",
	"201905140000356K9nmQ",
	"201905140000380GrhfK",
	"201905140000381kk98A",
	"201905140000410FtdUH",
	"201905140000399DR7ry",
	"201905140000392H3irF",
	"2019051400003887Mkjh",
	"201905140000383uyUyH",
	"201905140000385YmjQR",
	"201905140000375LDDaT",
	"201905140000342EDmLD",
	"201905140000338Bn26J",
	"201905140000331mLDLb",
	"201905140000328taakR",
	"2019051400003279fbq9",
	"2019051400003054Ay8B",	

	"201905140000418mrDaB",
	"201905140000416EdMFu",
	"201905140000412qAQ2g",
	"201905140000411NLqqY",
	"201905140000408hJGmg",
	"20190514000040776Mu8",
	"201905140000394d6NJr",
	"2019051400003933jraJ",
	"201905140000382eDH6B",
	"201905140000379bi3f8",
	"201905140000376M93Rg",
	"201905140000374LueFq",
	"201905140000373BryBH",
	"2019051400003702huLM",
	"201905140000369MYQ2d",
	"2019051400003629dLUA",
	"201905140000365uFB3a",
	"201905140000363kmdGk",
	"201905140000361L3BEQ",
	"2019051400003532UrFM",
	"201905140000339aLEYb",
	"201905140000341uUmmq",
	"201905140000335k7tjF",
	"201905140000332Ghk2L",
	"201905140000329HJYE2",
	"201905140000319ua8na",
	"201905140000318bdUM8",
	"201905140000317jhDDf",
	"201905140000314HAmM6",
	"201905140000308MUrmf",
	"201905140000307JKQjY",
	"2019051400003066QM7F",
	"201905140000304EkJEh",
	"201905140000302eyBqj",
	"201905140000419HiYTH",
	"201905140000406qG4q2",
	"201905140000391YM3A7",
	"201905140000390jGuke",
	"201905140000387AEHEi",
	"2019051400003864b9gY",
	
	"201905100000720jfFaR",
	"201905100000725L47Ky",
	"201905100000728LTDJQ",
	"201905100000739tkLf4",
	"201905100000753QHAn7",
	"201905100000775YEG2A",
	"201905100000776en2yF"
}



local function deduct_duplicate_order(_player_id,_order_id,_asset_type,_money)

	skynet.send(DATA.service_config.data_service,"lua","change_asset_and_sendMsg",
		_player_id , _asset_type ,-_money, "deduct_duplicate_order" , _order_id )

	return	{_player_id , _asset_type ,-_money, "deduct_duplicate_order" , _order_id}
end
local duplicate_order = 
{
	{"102075673","201905140000376M93Rg","jing_bi",10000},
	-- ok {"102075673","201905140000376M93Rg","shop_gold_sum",50},
	{"105755","201905140000379bi3f8","jing_bi",60000},
	{"10670851","201905140000380GrhfK","jing_bi",10000},
	{"10670851","201905140000380GrhfK","shop_gold_sum",50},
	{"102567076","201905140000383uyUyH","jing_bi",1000000},
	{"102284457","201905140000385YmjQR","jing_bi",10000},
	{"102284457","201905140000385YmjQR","shop_gold_sum",50},
	{"102391417","2019051400003864b9gY","jing_bi",10000},
	{"102391417","2019051400003864b9gY","shop_gold_sum",50},
	{"10795214","201905140000387AEHEi","jing_bi",10000},
	{"10795214","201905140000387AEHEi","shop_gold_sum",50},
	{"105801","2019051400003887Mkjh","jing_bi",60000},
	{"10109078","201905140000391YM3A7","jing_bi",10000},
	{"10109078","201905140000391YM3A7","shop_gold_sum",50},
	{"102651828","201905140000394d6NJr","jing_bi",10000},
	{"102651828","201905140000394d6NJr","shop_gold_sum",50},
	{"102529962","201905140000406qG4q2","jing_bi",10000},
	{"102529962","201905140000406qG4q2","shop_gold_sum",50},
	{"102768255","20190514000040776Mu8","jing_bi",10000},
	{"102768255","20190514000040776Mu8","shop_gold_sum",50},
	{"102759529","201905140000408hJGmg","jing_bi",10000},
	{"102759529","201905140000408hJGmg","shop_gold_sum",50},
	{"102532081","201905140000410FtdUH","jing_bi",10000},
	{"102532081","201905140000410FtdUH","shop_gold_sum",50},
	{"102805430","201905140000411NLqqY","jing_bi",10000},
	{"102805430","201905140000411NLqqY","shop_gold_sum",50},
	{"102783258","201905140000412qAQ2g","jing_bi",10000},
	{"102783258","201905140000412qAQ2g","shop_gold_sum",50},
	{"102792925","201905140000416EdMFu","jing_bi",10000},
	{"102792925","201905140000416EdMFu","shop_gold_sum",50},
	{"102709539","201905140000418mrDaB","jing_bi",150000},
	{"102761091","201905140000419HiYTH","jing_bi",10000},
	{"102761091","201905140000419HiYTH","shop_gold_sum",50},
}

return function()

    --[[
	local order = LL.payment_info["201905140000382eDH6B"]

	local goods = LL.shoping_goods_config[tonumber(order.product_id)]
    return goods
	-- ]]
	
	-- return do_complete('201905140000382eDH6B')


	-- 执行 完成账单
	-- local _fails = {}
	
	-- for i,order_id in ipairs(fix_orders) do
	-- 	skynet.sleep(1)
	-- 	local ret = do_complete(order_id)
	-- 	if ret ~= "ok" then
	-- 		_fails[#_fails + 1] = {order_id,ret}
	-- 	end
	-- end

	-- if not _fails[1] then
	-- 	return "all ok!2"
	-- else
	-- 	return _fails
	-- end

	-- 仅修改内存状态
	-- local _deals = {}
	-- for i,order_id in ipairs(fix_mem_status) do
	-- 	if LL.payment_info[order_id].order_status ~= "complete" then
	-- 		LL.payment_info[order_id].order_status = "complete"
	-- 		_deals[#_deals + 1] =order_id
	-- 	end
	-- end

	-- 加钱：补救 刚试验时 多扣的
	-- skynet.send(DATA.service_config.data_service,"lua","change_asset_and_sendMsg",
	-- 	"102075673" , "shop_gold_sum" ,50, "deduct_duplicate_order duo kou le !!" , "201905140000376M93Rg" )
	
	-- 扣除重复 加钱的
	-- local _deals = {}
	-- for i,_param in ipairs(duplicate_order) do
	-- 	deduct_duplicate_order(_param[1],_param[2],_param[3],_param[4])
	-- 	_deals[#_deals + 1] =_param[2]
	-- end
	--return _deals

end