---- 步步生财 返利配置
local base=require "base"
local DATA=base.DATA

--- 步步生财返奖
DATA.bbsc_rebate_cfg = {
	-------- 测试配置 ---------
	--[[[1]=
	{
		rebate_big_step = 1,
		rebate_value = 100,
	},
	[2]=
	{
		rebate_big_step = 2,
		rebate_value = 200,
	},
	[3]=
	{
		rebate_big_step = 3,
		rebate_value = 300,
	},
	[4]=
	{
		rebate_big_step = 7,
		rebate_value = 400,
	},--]]

	-------- 正式配置 ---------
	--[[[1]=
	{
		rebate_big_step = 7,
		rebate_value = 500,
	},--]]

}

--- 上级没有购买任何推广礼包，下级 完成bbsc 第一天 返利
DATA.no_buy_tglb_xj_award = 100

---
DATA.no_buy_tglb_xj_award2 = 200

--- 上级购买了金猪礼包1 ，下级 完成bbsc 第一天 返利
DATA.tglb1_buy_xj_award = 300

--- 上级购买了金猪礼包2 ，下级 完成bbsc 第一天 返利
DATA.tglb2_buy_xj_award = 500

--- 推广礼包1返奖,单位分
DATA.tglb1_rebate_value = 5000

--- 推广礼包2返奖,单位分
DATA.tglb2_rebate_value = 10000

--- 千元赛返利,单位分
DATA.qys_bisai_rebate_value = 300

--- vip礼包的返利
DATA.vip_lb_rebate_value = 5000

--- 推广礼包1的 商品id
DATA.tglb1_goods_id = 12

--- 玩家奖 完成bbsc第几步可以领奖
DATA.xj_award_bbsc_big_step = 2

