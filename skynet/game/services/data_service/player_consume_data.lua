--
-- Author: YY
-- Date: 2018/5/10
-- Time: 
-- 说明: 玩家的消费数据统计
local skynet = require "skynet_plus"
local basefunc=require"basefunc"
require"printfunc"
local base = require "base"
local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC
local REQUEST=base.REQUEST
local PROTECT={}

local LOCAL_FUNC = {}

function PROTECT.init_data()
	-- 直接对数据库进行操作 不做缓存
end


--[[添加一笔消费统计
	_type：
		pay 			-- 	所有的充值
		cost_jing_bi 	--	所有的报名费、服务费等（输赢不算）
		cost_shop_gold 	--	买了东西的
]]
function base.CMD.add_consume_statistics(_player_id,_type,_value)

	local data = 
	{
		id = _player_id,
		pay = 0,
		cost_jing_bi = 0,
		cost_shop_gold = 0,
	}

	data[_type]=_value

	local sql = string.format([[
				SET @_id = '%s';
				SET @_pay = %d;
				SET @_cost_jing_bi = %d;
				SET @_cost_shop_gold = %d;
				insert into player_consume_statistics
				(id,pay,cost_jing_bi,cost_shop_gold)
				values(@_id,@_pay,@_cost_jing_bi,@_cost_shop_gold)
				on duplicate key update
				id = @_id,
				pay = pay + @_pay,
				cost_jing_bi = cost_jing_bi + @_cost_jing_bi,
				cost_shop_gold = cost_shop_gold + @_cost_shop_gold;
			]],
				data.id,
				data.pay,
				data.cost_jing_bi,
				data.cost_shop_gold)
	
	base.DATA.sql_queue_slow:push_back(sql)

	return 0
end



--[[查询一个玩家消费数据
	主要用于外部查询使用
	有频次限制 10/s
]]
local query_player_consume_statistics_clock = {}
function base.CMD.query_player_consume_statistics(_player_id)

	if type(_player_id)~="string" or string.len(_player_id)<1 then
		return nil,1001
	end

	local key = os.time()
	local num = query_player_consume_statistics_clock[key]
	if not num then
		num = 0
		query_player_consume_statistics_clock={}
	end
	query_player_consume_statistics_clock[key] = num + 1

	if num > 10 then
		return nil,1000
	end


	local sql = string.format("SELECT * FROM player_consume_statistics where id='%s';",_player_id)
	local ret = base.DATA.db_mysql:query(sql)

	if( ret.errno ) then
		print(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
		return nil,1001
	end

	if not ret[1] then
		return {}
	end

	return ret[1]

end



return PROTECT

