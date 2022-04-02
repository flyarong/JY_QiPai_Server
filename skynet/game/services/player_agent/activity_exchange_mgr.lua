-- 活动兑换 agent
-- 
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
require "normal_enum"
require"printfunc"

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST
local PUBLIC = base.PUBLIC

local PROTECT = {}

local return_msg={result=0}
local act_lock = nil

DATA.activity_exchange_mgr_email_cfg = 
{
	duanwujie_fishgame_zongzi = 
	{
		title="端午节活动奖励",
		content = "恭喜您消耗%s粽子，成功兑换实物奖励，请联系微信客服JYDDZ01领取奖励。",
	},

}



DATA.activity_exchange_mgr_cfg = 
{
	duanwujie_fishgame_zongzi = 
	{
		start_time = 1559610000, -- 2019/6/4 9:0:0
		end_time = 1560268800, -- 2019/6/12 0:0:0
		content = 
		{
			[1] = 
			{
				condi = 
				{
					{
						asset_type = "prop_zongzi",
						condi_type = NOR_CONDITION_TYPE.CONSUME,
						value = 5,
					}
				},

				goods = 
				{
					{
						asset_type = PLAYER_ASSET_TYPES.JING_BI,
						value = 2500,
					}
				},

			},

			[2] = 
			{
				condi = 
				{
					{
						asset_type = "prop_zongzi",
						condi_type = NOR_CONDITION_TYPE.CONSUME,
						value = 50,
					}
				},

				goods = 
				{
					{
						asset_type = PLAYER_ASSET_TYPES.FISH_COIN,
						value = 40000,
					}
				},

			},

			[3] = 
			{
				condi = 
				{
					{
						asset_type = "prop_zongzi",
						condi_type = NOR_CONDITION_TYPE.CONSUME,
						value = 100,
					}
				},

				goods = 
				{
					{
						asset_type = "prop_fish_lock",
						value = 10,
					}
				},

			},

			[4] = 
			{
				condi = 
				{
					{
						asset_type = "prop_zongzi",
						condi_type = NOR_CONDITION_TYPE.CONSUME,
						value = 150,
					}
				},

				goods = 
				{
					{
						asset_type = PLAYER_ASSET_TYPES.SHOP_GOLD_SUM,
						value = 1000,
					}
				},

			},

			[5] = 
			{
				condi = 
				{
					{
						asset_type = "prop_zongzi",
						condi_type = NOR_CONDITION_TYPE.CONSUME,
						value = 600,
					}
				},

				email_arg = 
				{
					"600",
				}

			},

			[6] = 
			{
				condi = 
				{
					{
						asset_type = "prop_zongzi",
						condi_type = NOR_CONDITION_TYPE.CONSUME,
						value = 1800,
					}
				},

				
				email_arg = 
				{
					"1800",
				}

			},
			
		},
	}
}






---- 请求兑换
function REQUEST.activity_exchange(self)

	if type(self.type) ~= "string" then
		return_msg.result=1001
		return return_msg
	end

	if type(self.id) ~= "number" then
		return_msg.result=1001
		return return_msg
	end

	if act_lock then
		return_msg.result=1008
		return return_msg
	end

	act_lock = true

	local cfg = DATA.activity_exchange_mgr_cfg[self.type]
	if not cfg then
		return_msg.result=4700
		act_lock = nil
		return return_msg
	end

	-- 如果有系统配置就用
	local st = skynet.getcfg_2number("activity_exchange_zongzi_start_time")
	local et = skynet.getcfg_2number("activity_exchange_zongzi_end_time")
	if st and et then
		cfg.start_time = st
		cfg.end_time = et
	end

	local ct = os.time()
	if ct < cfg.start_time or ct > cfg.end_time then
		return_msg.result=4701
		act_lock = nil
		return return_msg
	end

	local item = cfg.content[self.id]
	if not item then
		return_msg.result=4702
		act_lock = nil
		return return_msg
	end

	if item.condi then

		local asset_lock_info = PUBLIC.asset_lock(item.condi)

		if asset_lock_info.result ~= 0 then
			return_msg.result=4703
			act_lock = nil
			return return_msg
		end

		--扣费
		PUBLIC.asset_commit(asset_lock_info.lock_id,"activity_exchange_"..self.type,self.id)
		PUBLIC.notify_asset_change_msg()

		if item.goods then

			CMD.change_asset_multi(item.goods,"activity_exchange_"..self.type,self.id)

		elseif item.email_arg then
			
			local ec = DATA.activity_exchange_mgr_email_cfg[self.type]

			local email = 
			{
				type="native",
				title=ec.title,
				sender="系统",
				receiver=DATA.my_id,
				data={content=string.format(ec.content,item.email_arg[1],item.email_arg[2],item.email_arg[3])},
			}
			skynet.send(DATA.service_config.email_service,"lua","send_email",email)

		end

	end

	act_lock = nil
	
	return_msg.result=0
	return return_msg

end



function PROTECT.init()

end


return PROTECT