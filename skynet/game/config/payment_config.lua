--
-- Author: lyx
-- Date: 2018/5/24
-- Time: 15:14
-- 说明：支付相关的配置
--

local skynet = require "skynet_plus"

require "normal_enum"

local payment_config = {}

-- 支持的渠道
payment_config.channel_types =
{
	alipay = true,
	weixin = true,
	wxgzh = true,
	appstore = true,
}

payment_config.appstore_bundleid=
{
	["com.scjyhd.jyjjddz"] = true,
	["com.jyhdjyj.jyjjddz"] = true,
}


return payment_config