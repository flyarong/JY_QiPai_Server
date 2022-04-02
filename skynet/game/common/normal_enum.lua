--
-- Author: lyx
-- Date: 2018/4/14
-- Time: 10:31
-- 说明：公用的 枚举变量
--

-- 条件的处理方式
NOR_CONDITION_TYPE =
{
	CONSUME = 1, -- 消费：必须大于等于，并扣除
	EQUAL = 2, -- 等于
	GREATER = 3, -- 大于等于
	LESS	= 4, -- 小于等于
	NOT_EQUAL = 5, --- 不等于
}


-- 玩家财富类型
PLAYER_ASSET_TYPES =
{
	DIAMOND 			= "diamond", 		-- 钻石
	JING_BI 			= "jing_bi",	-- 鲸币
	CASH 				= "cash", 			-- 现金
	SHOP_GOLD_SUM		= "shop_gold_sum",	-- 购物金总数：各面额加起来

	FISH_COIN 			= "fish_coin",	-- 鱼币

	ROOM_CARD 			= "room_card",	-- 房卡

	JIPAIQI 			= "jipaiqi",	-- 记牌器有效期 -- 只作为消息发送

	PROP_JICHA_CASH		= "prop_jicha_cash", 	-- 生财之道的级差现金

	PROP_1              = "prop_1",         -- 竞标赛门票

	PROP_2              = "prop_2",         -- 千元赛门票

	PROP_3              = "prop_3",         -- 万元赛门票

	PROP_5Y            = "prop_5y",       -- 20元竞标赛门票
	PROP_20Y            = "prop_20y",       -- 50元竞标赛门票
	PROP_50Y            = "prop_50y",       -- 20元竞标赛门票
	PROP_100Y            = "prop_100y",       -- 50元竞标赛门票

	PROP_HAMMER_1       = "prop_hammer_1",   -- 1号锤子
	PROP_HAMMER_2       = "prop_hammer_2",
	PROP_HAMMER_3       = "prop_hammer_3",
	PROP_HAMMER_4       = "prop_hammer_4",

	PROP_FISH_LOCK      = "prop_fish_lock",   -- 捕鱼锁定卡
	PROP_FISH_FROZEN    = "prop_fish_frozen", -- 捕鱼冰冻卡


	-- 临时的
	PROP_ZONGZI    		= "prop_zongzi", -- 端午节粽子

}

-- 财富类型转金币的兑换率,一个单位转几个鲸币
PLAYER_ASSET_TRANS_JINGBI = {
  [PLAYER_ASSET_TYPES.DIAMOND]                 = 100,     -- 钻石
  [PLAYER_ASSET_TYPES.JING_BI]                 = 1,       -- 鲸币
  [PLAYER_ASSET_TYPES.FISH_COIN]               = 1,       -- 鲸币
  [PLAYER_ASSET_TYPES.CASH]                    = 100,     -- 现金
  [PLAYER_ASSET_TYPES.SHOP_GOLD_SUM]           = 100,     -- 购物金总数：各面额加起来

  [PLAYER_ASSET_TYPES.ROOM_CARD]               = 2000,  -- 房卡

  [PLAYER_ASSET_TYPES.JIPAIQI]                 = 0,  -- 记牌器有效期 -- 只作为消息发送

  [PLAYER_ASSET_TYPES.PROP_1]                 = 1000, 

  [PLAYER_ASSET_TYPES.PROP_2]                 = 100000,  

  [PLAYER_ASSET_TYPES.PROP_3]                 = 1000000,  

  [PLAYER_ASSET_TYPES.PROP_5Y]                 = 5000,
  [PLAYER_ASSET_TYPES.PROP_20Y]                 = 20000,
  [PLAYER_ASSET_TYPES.PROP_50Y]                 = 50000,
  [PLAYER_ASSET_TYPES.PROP_100Y]                 = 100000,

  [PLAYER_ASSET_TYPES.PROP_HAMMER_1]          = 100,
  [PLAYER_ASSET_TYPES.PROP_HAMMER_2]          = 1000,
  [PLAYER_ASSET_TYPES.PROP_HAMMER_3]          = 10000,
  [PLAYER_ASSET_TYPES.PROP_HAMMER_4]          = 100000,

  [PLAYER_ASSET_TYPES.PROP_ZONGZI]            = 10,  

}

-- 玩家财富类型集合 以及 所有 prop_ 开头的东西
PLAYER_ASSET_TYPES_SET =
{
	["diamond"] 		= "diamond", 		-- 钻石
	["jing_bi"] 		= "jing_bi",		-- 鲸币
	["fish_coin"] 		= "fish_coin", 		-- 钻石
	["cash"] 			= "cash", 			-- 现金
	["shop_gold_sum"] 	= "shop_gold_sum", 	-- 购物金

	["jipaiqi"] 		= "jipaiqi", 		-- 记牌器有效期

	["room_card"] 		= "room_card",		-- 房卡
}

-- 购物金面额映射
SHOP_GOLD_FACEVALUES = 
{
	["shop_gold_10"] = 10,
	["shop_gold_100"] = 100,
	["shop_gold_1000"] = 1000,
	["shop_gold_10000"] = 10000, 
}
-- 购物金类型映射
SHOP_GOLD_PROPTYPES = 
{
	[10] 	= "shop_gold_10", 	
	[100] 	= "shop_gold_100", 	
	[1000] 	= "shop_gold_1000", 
	[10000] = "shop_gold_10000",
}

--财富改变类型
--[[
	
--]]
ASSET_CHANGE_TYPE = {

	BUY = "buy",	 			--玩家充值购买
	BUY_GIFT = "buy_gift",	 	--玩家充值购买 附赠 的东西
	SHOPING = "shoping",		--玩家在线上商城通过购物金买东西
	MERCHANT_BUY = "merchant_buy",	--玩家在线下商家通过购物金买东西
	WITHDRAW = "withdraw",		--玩家现金提现

	SHOPING_REFUND = "shoping_refund",		--退款（玩家在线上商城通过购物金买东西）

	PAY_EXCHANGE_JINGBI = "pay_exchange_jingbi", -- 充值界面中，用钻石购买鲸币
	PAY_EXCHANGE_JIPAIQI = "pay_exchange_jipaiqi", -- 充值界面中，用钻石购买记牌器
	PAY_EXCHANGE_ROOMCARD = "pay_exchange_roomcard", 	-- 充值界面中，用钻石购买房卡

	-- pay_exchange_ .. "type"...

	
	NEW_USER_LOGINED_AWARD = "new_user_logined_award",

	-- 兑物券
	DWQ_CHANGE_1="dwq_change_1", 		--兑物券合成扣除
	DWQ_CHANGE_2="dwq_change_2", 		--兑物券合成增加
	DWQ_CHANGE_3="dwq_change_3", 		--兑物券普通使用扣除
	DWQ_CHANGE_4="dwq_change_4", 		--兑物券被激活码的方式使用
	--购物金
	GWJ_CHANGE_1="gwj_change_1", 		--自己使用兑物券增加


	FREESTYLE_SIGNUP="freestyle_signup", 	--自由场报名
	FREESTYLE_CANCEL_SIGNUP="freestyle_cancel_signup", 	--自由场报名
	FREESTYLE_GAME_SETTLE="freestyle_game_settle", 	--自由场游戏输赢

	--laizi
	LZ_FREESTYLE_SIGNUP="lz_freestyle_signup", 	--自由场报名
	LZ_FREESTYLE_CANCEL_SIGNUP="lz_freestyle_cancel_signup", 	--自由场报名
	LZ_FREESTYLE_AWARD="lz_freestyle_award", 	--自由场获奖
	LZ_FREESTYLE_LOSE="lz_freestyle_lose", 	--自由场输了

	--laizi
	TY_FREESTYLE_SIGNUP="ty_freestyle_signup", 	--自由场报名
	TY_FREESTYLE_CANCEL_SIGNUP="ty_freestyle_cancel_signup", 	--自由场报名
	TY_FREESTYLE_AWARD="ty_freestyle_award", 	--自由场获奖
	TY_FREESTYLE_LOSE="ty_freestyle_lose", 	--自由场输了


	MILLION_SIGNUP="million_signup", 		--百万大奖赛报名
	MILLION_CANCEL_SIGNUP="million_cancel_signup",	--百万大奖赛取消报名
	MILLION_COMFORT_AWARD="million_comfort_award", 	--百万大奖赛安慰奖
	MILLION_AWARD="million_award", 	--百万大奖赛获奖
	MILLION_FUHUO="million_fuhuo", 	--百万大奖赛复活

	-- 麻将自由场
	MAJIANG_FREESTYLE_SIGNUP="majiang_freestyle_signup", 	--自由场报名
	MAJIANG_FREESTYLE_CANCEL_SIGNUP="majiang_freestyle_cancel_signup", 	--自由场报名
	MAJIANG_FREESTYLE_AWARD="majiang_freestyle_award", 	--自由场获奖
	MAJIANG_FREESTYLE_LOSE="majiang_freestyle_lose", 	--自由场输了
	MAJIANG_FREESTYLE_REFUND="majiang_freestyle_refund", 	--退税（杠的钱）


	-- 麻将自由场
	MJXL_MAJIANG_FREESTYLE_SIGNUP="mjxl_majiang_freestyle_signup", 	--自由场报名
	MJXL_MAJIANG_FREESTYLE_CANCEL_SIGNUP="mjxl_majiang_freestyle_cancel_signup", 	--自由场报名
	MJXL_MAJIANG_FREESTYLE_AWARD="mjxl_majiang_freestyle_award", 	--自由场获奖
	MJXL_MAJIANG_FREESTYLE_LOSE="mjxl_majiang_freestyle_lose", 	--自由场输了
	MJXL_MAJIANG_FREESTYLE_REFUND="mjxl_majiang_freestyle_refund", 	--退税（杠的钱）

	MATCH_SIGNUP="match_signup", 		--比赛场报名
	MATCH_CANCEL_SIGNUP="match_cancel_signup",	--比赛场取消报名
	MATCH_AWARD="match_award", 	--自由场获奖
	MATCH_REVIVE="match_revive", 	--自由场复活

	MANUAL_SEND="manual_send", 	--手工发送
	TUOGUAN_ADJUST="tuoguan_adjust", 	--托管 调整

	TUOGUAN_FIT_GAME="tuoguan_fit_game", 	--托管 适配游戏

	ADMIN_DECREASE_ASSET="admin_decrease_asset", 	--管理员进行扣除资产

	EVERYDAY_SHARED_FRIEND="everyday_shared_friend", 	--每日分享朋友奖励
	EVERYDAY_SHARED_TIMELINE="everyday_shared_timeline", 	--每日分享朋友圈奖励
	EVERYDAY_FLAUNT="everyday_flaunt", 	--每日炫耀奖励
	EVERYDAY_SHARED_MATCH="everyday_shared_match", 	--每日分享朋友圈奖励

	XSYD_FINISH_AWARD="xsyd_finish_award", 	--新手引导完成奖励

	FRIENDGAME_RENT = "friendgame_rent", 	--房卡开放费用

	-- 所有礼包
	--"buy_gift_bag_".._order.product_id

	FG_TODAY_HB = "fg_today_hb", 	--自由场每日红包
	FG_WEEK_CASH = "fg_week_cash", 	--自由场每周奖金

	TASK_AWARD = "task_award", 	--任务奖励

	GOLD_PIG2_TASK_AWARD = "gold_pig2_task_award",     --- 金猪2的任务奖励

	GLORY_AWARD = "glory_award", 	--荣耀奖励

	PAY_EXPRESSION_LOTTERY = "pay_expression_lottery", 	--购买表情抽奖

	EXPRESSION_LOTTERY_RESULT = "expression_lottery_result", 	--表情抽奖的结果

	REDEEM_CODE_AWARD = "redeem_code_award", --兑换码奖励

	BROKE_SUBSIDY = "broke_subsidy", --破产补助
	FREE_BROKE_SUBSIDY = "free_broke_subsidy", --破产补助

	EGG_GAME_SPEND = "egg_game_spend",                 -- 砸金蛋消费
	EGG_GAME_AWARD = "egg_game_award",                 -- 砸金蛋 奖励
	EGG_GAME_REPLACE_EGG = "egg_game_replace_egg",     -- 砸金蛋 换蛋


	FREESTYLE_ACTIVITY_AWARD = "freestyle_activity_award",     -- 自由场活动奖励
	
	FISHING_TASK_CHOU_JIANG = "fishing_task_chou_jiang",       -- 捕鱼累积赢金抽奖任务

	FISHING_GAME_SETTLE = "fishing_game_settle",     -- 捕鱼游戏


	--- 金猪礼包2 任务奖励
	GOLD_PIG2_TASK_AWARD = "gold_pig2_task_award",

	--- 捕鱼每日任务 奖励
	BUYU_DAILY_TASK_AWARD = "buyu_daily_task_award",

	--- 发放礼券奖励(绑定上级)
	GRANT_GIFT_COUPON = "grant_gift_coupon",

	-- vip礼包返利
	-- vip_lb_rebate

	-- 活动兑换
	-- activity_exchange_ .. "xxx"

	-- 自由场结算红包兑换
	FREESTYLE_SETTLE_EXCHANGE_HONGBAO = "freestyle_settle_exchange_hongbao",

		---- 消消乐消耗
	XXL_GAME_SPEND = "xxl_game_spend",
	---- 消消乐奖励
	XXL_GAME_AWARD = "xxl_game_award",
	---- 大富豪奖励
	DAFUHAO_GAME_AWARD = "dafuhao_game_award",

	LOTTERY_LUCK_BOX = "lottery_luck_box",

	OPEN_LUCK_BOX = "open_luck_box",
 
}


-- 游戏类型 -> 房间服务
GAME_TYPE_ROOM = 
{
	nor_mj_xzdd = "common_mj_xzdd_room_service/common_mj_xzdd_room_service",
	nor_mj_xzdd_er_7 = "common_mj_xzdd_room_service/common_mj_xzdd_room_service",
	nor_mj_xzdd_er_13 = "common_mj_xzdd_room_service/common_mj_xzdd_room_service",
	nor_ddz_nor = "common_ddz_nor_room_service/common_ddz_nor_room_service",
	nor_ddz_lz = "common_ddz_nor_room_service/common_ddz_nor_room_service",
	--二人斗地主
	nor_ddz_er = "common_ddz_nor_room_service/common_ddz_nor_room_service",

	nor_ddz_boom = "common_ddz_nor_room_service/common_ddz_nor_room_service",
	
	--五子连珠
	nor_gobang_nor = "common_gobang_nor_room_service/common_gobang_nor_room_service",

	--捕鱼游戏
	nor_fishing_nor = "common_fishing_nor_room_service/common_fishing_nor_room_service",
}

-- 游戏类型 -> 玩家代理文件
GAME_TYPE_AGENT = 
{
	nor_mj_xzdd = "player_agent/normal_mj_xzdd_agent",
	nor_mj_xzdd_er_7 = "player_agent/normal_mj_xzdd_agent",
	nor_mj_xzdd_er_13 = "player_agent/normal_mj_xzdd_agent",
	nor_ddz_nor = "player_agent/normal_ddz_nor_agent",
	nor_ddz_lz = "player_agent/normal_ddz_nor_agent",
	nor_ddz_er = "player_agent/normal_ddz_nor_agent",
	nor_gobang_nor = "player_agent/normal_gobang_nor_agent",
	nor_ddz_boom = "player_agent/normal_ddz_nor_agent",
	nor_fishing_nor = "player_agent/fish_agent/normal_fishing_nor_agent",
}

GAME_AGENT_PROTO = 
{
	["player_agent/normal_mj_xzdd_agent"] = "nor_mj_xzdd_status_info",
	["player_agent/normal_ddz_nor_agent"] = "nor_ddz_nor_status_info",
	["player_agent/normal_gobang_nor_agent"] = "nor_gobang_nor_status_info",
}

-- 游戏模式 -> 配置转换文件
GAME_MODEL_CFG_TRANS = 
{
	friendgame = "cfg_trans_friendgame",
}

-- 游戏类型 -> 配置转换文件
GAME_TYPE_CFG_TRANS = 
{
	nor_mj_xzdd = "cfg_trans_nor_mj_xzdd",
	nor_ddz_nor = "cfg_trans_nor_ddz_nor",
	nor_ddz_lz = "cfg_trans_nor_ddz_nor",
	nor_ddz_er = "cfg_trans_nor_ddz_nor",
	nor_ddz_boom = "cfg_trans_nor_ddz_nor",
}

GAME_TYPE_SEAT = 
{
	nor_mj_xzdd = 4,
	nor_mj_xzdd_er_7 = 2,
	nor_mj_xzdd_er_13 = 2,
	nor_ddz_nor = 3,
	nor_ddz_lz = 3,
	nor_ddz_er = 2,
	nor_ddz_boom = 3,
	nor_gobang_nor = 2,
	nor_fishing_nor = 4,
}

GAME_TYPE_PAI_NUM = 
{
	nor_mj_xzdd = 13,
	nor_mj_xzdd_er_7 = 7,
	nor_mj_xzdd_er_13 = 13,
	--[[nor_ddz_nor = 3,
	nor_ddz_lz = 3,
	nor_ddz_er = 2,--]]
}

---- 麻将牌的总数
GAME_TYPE_TOTAL_PAI_NUM = 
{
	nor_mj_xzdd = 108,
	nor_mj_xzdd_er_7 = 72,
	nor_mj_xzdd_er_13 = 72,
	--[[nor_ddz_nor = 3,
	nor_ddz_lz = 3,
	nor_ddz_er = 2,--]]
}


---- 麻将斗地主类型
GAME_TYPE_TO_PLAY_TYPE = 
{
	nor_mj_xzdd = "mj",
	nor_mj_xzdd_er_7 = "mj",
	nor_mj_xzdd_er_13 = "mj",
	nor_ddz_nor = "ddz",
	nor_ddz_lz = "ddz",
	nor_ddz_er = "ddz",
	nor_gobang_nor = "gobang",
	nor_ddz_boom = "ddz",
}



-------------------------- 任务相关
-- 任务类型枚举
TASK_TYPE_ENUM = {
	chuji_duiju_hongbao = "chuji_duiju_hongbao",
	zhongji_duiju_hongbao = "zhongji_duiju_hongbao",
	gaoji_duiju_hongbao = "gaoji_duiju_hongbao",
	jingyu_award_box = "jingyu_award_box",
	vip_duiju_hongbao_task = "vip_duiju_hongbao_task",
	vip_duiju_jingbi_task = "vip_duiju_jingbi_task",
	common_task = "common",
}

--------------------------
GAME_TAG = {
	normal = "normal",
	xsyd = "xsyd",
	vip = "vip",
}

GAME_FORM = {
	freestyle = "freestyle",
	matchstyle = "matchstyle",
}

-- 可以转换的资产类型(商城直接购买金币问题)
ASSETS_CONVERT_TYPE = {
	[PLAYER_ASSET_TYPES.JING_BI] = 1,

}