--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：发公告
-- 使用方法：
-- call collect_service exe_file "hotfix/fix_collect.lua"
--


local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local cjson = require "cjson"
require"printfunc"

cjson.encode_sparse_array(true,1,0)

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

-- 查询未完成订单
function base.CMD.query_undone_payment_order()

	local sql = [[select order_id,channel_type from player_pay_order where order_status='SYSTEMERROR' order by create_time desc;]]
	local ret = PUBLIC.db_query(sql)
	if ret.errno then
		return nil,2402
	end

	local list = {}
	for i,_row in ipairs(ret) do
		list[i] = _row
	end

	return list
end

return function()

    return "send ok!!!"

end