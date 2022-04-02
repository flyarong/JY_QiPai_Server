--
-- Created by lyx.
-- User: hare
-- Date: 2018/7/5
-- Time: 16:21
-- 数据采集命令
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

function base.CMD.update_agent_role( _userId,_is_agent )

	return 1002 -- 已废弃

end

-- 批量查询用户的充值订单
function base.CMD.query_payment_order_list(_recharge_time_start)
	
	local sql = string.format( [[
		select end_time recharge_time,product_id, player_id user_id,order_id id from player_pay_order where order_status='complete' and end_time >= '%s'
		union
		select end_time recharge_time,product_id, player_id user_id,order_id id from player_pay_order_log where order_status='complete' and end_time >= '%s'		
		order by recharge_time;]]
		,_recharge_time_start,_recharge_time_start)
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

-- 得到用户信息
function base.CMD.query_user(_userId,_weixin_union_id)


	local ret 
	if _userId then
		ret = PUBLIC.db_query_va([[
						SELECT
			pi.id AS userId,
			pr.login_id AS weixinUnionId,
			pr.register_channel,
			ci.parent_ids AS parentUserIds,
			pi.`name` AS nickname,
			pa.diamond,
			pa.shop_gold_sum,
			if(pi.head_image is null or '' = pi.head_image,'http://jydown.jyhd919.cn/head_images/icon_128.png',pi.head_image) AS avatarUrl
			FROM
			(select * from player_info where id = '%s') AS pi
			LEFT JOIN player_register AS pr ON pr.id = pi.id
			LEFT JOIN club_info AS ci ON ci.id = pi.id
			LEFT JOIN player_asset as pa on pa.id = pi.id
		;]],_userId)
	elseif _weixin_union_id then	
		ret = PUBLIC.db_query_va([[
			SELECT
			pi.id AS userId,
			pr.login_id AS weixinUnionId,
			pr.register_channel,
			ci.parent_ids AS parentUserIds,
			pi.`name` AS nickname,
			pa.diamond,
			pa.shop_gold_sum,
			if(pi.head_image is null or '' = pi.head_image,'http://jydown.jyhd919.cn/head_images/icon_128.png',pi.head_image) AS avatarUrl
			FROM
			player_info AS pi
			LEFT JOIN player_register AS pr ON pr.id = pi.id
			LEFT JOIN club_info AS ci ON ci.id = pi.id
			LEFT JOIN player_asset as pa on pa.id = pi.id
			WHERE pr.login_id = '%s'
		;]],_weixin_union_id)
	else
		return nil,1001
	end

	if ret.errno then
		return nil,2402
	end

	local user_data = ret[1]

	if not user_data then
		return nil,1004
	end

	if user_data.parentUserIds and user_data.parentUserIds ~= "" then
		user_data.parentUserIds = cjson.decode(user_data.parentUserIds)
	else
		user_data.parentUserIds = nil
	end

	local prop_ret = PUBLIC.db_query_va([[
			SELECT
			pp.prop_type,
			pp.prop_count,
			pt.value
			FROM
			(select * from prop_type where prop_group='shop_gold') AS pt
			INNER JOIN (select * from player_prop where id='%s') AS pp ON pp.prop_type = pt.prop_type
		;]],_userId)

	if prop_ret.errno then
		return nil,2402
	end

	user_data.shop_golds = {}

	for _,_row in ipairs(prop_ret) do
		user_data.shop_golds[tostring(_row.value)] = _row.prop_count
	end

	return user_data
end

-- 收集用户
function base.CMD.collect_user_after_seq(_seq_start,_count)

	local ss = tonumber(_seq_start)
	if not ss then
		return nil,1001
	end

	local ret = PUBLIC.db_query_va([[
		SELECT
			p.id AS userId,
			p.sync_seq AS collectSeq,
			p.`name` AS nickname,
			club_info.parent_ids AS parentUserIds,
			pr.login_id AS weixinUnionId,
			if(p.head_image is null or '' = p.head_image,'http://jydown.jyhd919.cn/head_images/icon_128.png',p.head_image) AS avatarUrl,
			pr.register_channel,
			pls.first_login_time AS firstLoginedTime,
			ppos.sum_money AS rechargedAmount
		FROM
			(select * from player_info where sync_seq > %d) AS p 
		LEFT JOIN club_info ON p.id = club_info.id 
		INNER JOIN (select * from player_register where register_channel = 'wechat' ) AS pr ON pr.id = p.id 
		LEFT JOIN player_login_stat AS pls ON pls.id = p.id 
		LEFT JOIN player_pay_order_stat AS ppos ON ppos.player_id = p.id 
		order by p.sync_seq limit %d;
	]],ss,_count or 20)

	if ret.errno then
		return nil,2402
	end

	local consumptions = {}
	for _i,_row in ipairs(ret) do
		if (_row.parentUserIds or "") ~= "" then
			_row.parentUserIds = cjson.decode(_row.parentUserIds)
		else
			_row.parentUserIds = nil
		end

		_row.rechargedAmount = _row.rechargedAmount or 0

		consumptions[_i] = _row
	end

	return consumptions
end

local function get_db_variant(_name)
	local ret = PUBLIC.db_query_va("select `value` from system_variant where `name` = 'last_asset_safe_seq';")
	if ret.errno then
		return nil
	end

	return ret[1] and ret[1].value or nil
end

-- 收集消费信息
-- 说明：只收集 鲸币 和 钻石
-- 汇率： 10000 鲸币=1￥ ， 100钻石 = 1￥
function base.CMD.collect_consumption_after_seq(_seq_start,_count)

	local ss = tonumber(_seq_start)
	if not ss then
		return nil,1001
	end

	local prop_safe_seq = get_db_variant('last_prop_safe_seq') or "0"
	local asset_safe_seq = get_db_variant('last_asset_safe_seq') or "0"

	ret = PUBLIC.db_query_va([[
		SELECT
		ppl.change_id AS consumptionId,
		ppl.prop_type AS currency,
		ppl.change_type as type,
		ppl.change_value,
		ppl.id AS userId,
		ci.parent_ids AS parentUserIds,
		ppl.sync_seq AS collectSeq,
		ppl.date AS time
		FROM
		(
			SELECT a.change_id,a.prop_type,a.change_type,a.change_value,a.id,a.shop_gold_sync_seq sync_seq,a.`date`
			FROM player_prop_log AS a
			LEFT JOIN player_asset_refund AS b ON b.log_id = a.log_id
			LEFT JOIN player_asset_refund AS c ON c.log_id_refund = a.log_id
			where b.log_id is null and c.log_id_refund is null and shop_gold_sync_seq > %d and shop_gold_sync_seq <= %s
				UNION
			SELECT a.change_id,a.asset_type prop_type,a.change_type,a.change_value,a.id,a.sync_seq,a.`date`
			FROM player_asset_log AS a
			LEFT JOIN player_asset_refund AS b ON b.log_id = a.log_id
			LEFT JOIN player_asset_refund AS c ON c.log_id_refund = a.log_id
			where b.log_id is null and c.log_id_refund is null and a.sync_seq > %d and a.sync_seq <= %s
            
		) AS ppl
		LEFT JOIN club_info AS ci ON ci.id = ppl.id
		INNER JOIN (select * from player_register where register_channel = 'wechat' ) AS pr ON pr.id = ppl.id 
		order by ppl.sync_seq limit %d;]],ss,prop_safe_seq,ss,asset_safe_seq,_count or 20)

	if ret.errno then
		return nil,2402
	end

	local users = {}
	for _i,_row in ipairs(ret) do
		if (_row.parentUserIds or "") ~= "" then
			_row.parentUserIds = cjson.decode(_row.parentUserIds)
		else
			_row.parentUserIds = nil
		end
		users[_i] = _row
	end

	return users
end




-- 查询一个玩家在一个时间段内打了几把游戏
function base.CMD.query_user_game_count(_user_id,_gametype,_start_time,_end_time)
	
	_start_time = tonumber(_start_time) or 0 
	_end_time = tonumber(_end_time) or 0 

	if not _user_id or type(_user_id)~= "string" or string.len(_user_id) < 1 then
		return nil,1001
	end

	local ret

	if _gametype == "freestyle" then

		ret = PUBLIC.db_query_va([[
			SELECT COUNT(*)
			FROM 
			freestyle_race_log
			INNER JOIN freestyle_race_player_log ON freestyle_race_player_log.match_id = freestyle_race_log.id
			WHERE freestyle_race_player_log.player_id = %s
			AND UNIX_TIMESTAMP(freestyle_race_log.begin_time) >= %s 
			AND UNIX_TIMESTAMP(freestyle_race_log.end_time) <= %s;
		]]
		,_user_id,_start_time,_end_time)

	else

		ret = PUBLIC.db_query_va([[
			SELECT COUNT(*)
			FROM 
			match_nor_log
			INNER JOIN match_nor_player_log ON match_nor_player_log.match_id = match_nor_log.id
			WHERE match_nor_player_log.player_id = %s
			AND UNIX_TIMESTAMP(match_nor_log.begin_time) >= %s 
			AND UNIX_TIMESTAMP(match_nor_log.end_time) <= %s;
		]]
		,_user_id,_start_time,_end_time)

	end
	
	local game_count = ret[1]["COUNT(*)"]

	return {game_count=game_count,result=0}
end



-- 查询一个玩家在一个时间段内打了几把游戏
function base.CMD.query_user_specific_game_count(_user_id,_gametype,_game_id,_start_time,_end_time)
	
	_start_time = tonumber(_start_time) or 0 
	_end_time = tonumber(_end_time) or 0 

	if not _user_id or type(_user_id)~= "string" or string.len(_user_id) < 1 then
		return nil,1001
	end

	local ret

	if _gametype == "freestyle" then

		ret = PUBLIC.db_query_va([[
			SELECT COUNT(*)
			FROM 
			freestyle_race_log
			INNER JOIN freestyle_race_player_log ON freestyle_race_player_log.match_id = freestyle_race_log.id
			WHERE freestyle_race_player_log.player_id = %s
			AND freestyle_race_log.game_id = %s
			AND UNIX_TIMESTAMP(freestyle_race_log.begin_time) >= %s 
			AND UNIX_TIMESTAMP(freestyle_race_log.end_time) <= %s;
		]]
		,_user_id,_game_id,_start_time,_end_time)

	else

		ret = PUBLIC.db_query_va([[
			SELECT COUNT(*)
			FROM 
			match_nor_log
			INNER JOIN match_nor_player_log ON match_nor_player_log.match_id = match_nor_log.id
			WHERE match_nor_player_log.player_id = %s
			AND match_nor_log.game_id = %s
			AND UNIX_TIMESTAMP(match_nor_log.begin_time) >= %s 
			AND UNIX_TIMESTAMP(match_nor_log.end_time) <= %s;
		]]
		,_user_id,_game_id,_start_time,_end_time)

	end

	local game_count = ret[1]["COUNT(*)"]


	return {game_count=game_count,result=0}
end



-- 查询一个玩家在一个时间段内打了几把游戏
function base.CMD.query_user_specific_games_count(_data)
	
	local ok, arg = xpcall(function ()
			return cjson.decode(_data)
		end,
		function (error)
			print(error)
		end)
	
	if not ok then
		return nil,1001
	end

	local _user_id = arg.user_id
	local _gametype = arg.gametype
	local _game_ids = arg.game_ids
	local _start_time = arg.start_time
	local _end_time = arg.end_time

	_start_time = tonumber(_start_time) or 0 
	_end_time = tonumber(_end_time) or 0 

	if not _user_id or type(_user_id)~= "string" or string.len(_user_id) < 1 then
		return nil,1001
	end

	if type(_game_ids)~="table" or #_game_ids < 1 then
		return nil,1001
	end

	for i,v in ipairs(_game_ids) do
		_game_ids[i] = string.format("%d",math.floor( (tonumber(v)or 0) +0.1))
	end

	local game_ids_str = table.concat( _game_ids, ",")

	local ret

	if _gametype == "freestyle" then

		ret = PUBLIC.db_query_va([[
			SELECT COUNT(*)
			FROM 
			freestyle_race_log
			INNER JOIN freestyle_race_player_log ON freestyle_race_player_log.match_id = freestyle_race_log.id
			WHERE freestyle_race_player_log.player_id = %s
			AND freestyle_race_log.game_id IN (%s)
			AND UNIX_TIMESTAMP(freestyle_race_log.begin_time) >= %s 
			AND UNIX_TIMESTAMP(freestyle_race_log.end_time) <= %s;
		]]
		,_user_id,game_ids_str,_start_time,_end_time)

	else

		ret = PUBLIC.db_query_va([[
			SELECT COUNT(*)
			FROM 
			match_nor_log
			INNER JOIN match_nor_player_log ON match_nor_player_log.match_id = match_nor_log.id
			WHERE match_nor_player_log.player_id = %s
			AND match_nor_log.game_id IN (%s)
			AND UNIX_TIMESTAMP(match_nor_log.begin_time) >= %s 
			AND UNIX_TIMESTAMP(match_nor_log.end_time) <= %s;
		]]
		,_user_id,game_ids_str,_start_time,_end_time)

	end

	local game_count = ret[1]["COUNT(*)"]


	return {game_count=game_count,result=0}
end
