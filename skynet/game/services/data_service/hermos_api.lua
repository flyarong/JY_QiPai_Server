--
-- Author: lyx
-- Date: 2018/5/30
-- Time: 11:09
-- 说明：俱乐部 ，或者叫：分销系统/牌友圈/推广系统
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
local cjson = require "cjson"
require"printfunc"

require "normal_enum"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA


local PROTECTED = {}

local db_mysql

function PROTECTED.init_hermos_api()
	-- 延迟创建数据库连接
	skynet.timeout(1,function()
		base.PUBLIC.create_db_connect(function (db)
			print("club database connected:",skynet.getenv("mysql_host"),tonumber(skynet.getenv("mysql_port")),skynet.getenv("mysql_dbname"))

			db_mysql = db
		end)	
	end)
end

-- 得到祖先链，出错返回 nil
function PUBLIC.club_get_user_parents( _userId )

	local ret = PUBLIC.db_query_va(db_mysql,"select parent_id,parent_ids from club_info where id='%s'",_userId)
	if ret.errno then
		return nil
	end

	if ret[1] and (ret[1].parent_ids or "") ~= "" then
		return cjson.decode(ret[1].parent_ids)
	else
		return {}
	end
end

-- 设置上级，写入数据库，并返回新的 祖先链
-- 返回 
--	1、上级，nil 表示未设置（出错）
--	2、完整祖先链
function PUBLIC.club_set_user_parent(_userId,_parentId)
	if not _parentId or not CMD.is_player_exists(_parentId) then
		return nil
	end

	local parents = PUBLIC.club_get_user_parents(_parentId)

	if parents and parents[1] then
		table.insert(parents,1,_parentId)
	else
		parents = {_parentId}
	end

	local _parent_str = cjson.encode(parents)

	PUBLIC.db_query_va(db_mysql,[[INSERT INTO club_info(id,parent_id,parent_ids)VALUES('%s','%s','%s') 
		on duplicate key update parent_id='%s',parent_ids='%s';]],
		_userId,_parentId,_parent_str,_parentId,_parent_str)

	return parents
end

function base.CMD.query_one_user(_userId,_weixin_union_id)

	local ret 
	if _userId then
		ret = PUBLIC.db_query_va([[
						SELECT
			pi.id AS userId,
			pr.login_id AS weixinUnionId,
			pr.register_channel,
			"[]" AS parentUserIds,
			pi.`name` AS nickname,
			pa.diamond,
			pa.shop_gold_sum,
			if(pi.head_image is null or '' = pi.head_image,'http://jydown.jyhd919.cn/head_images/icon_128.png',pi.head_image) AS avatarUrl
			FROM
			(select * from player_info where id = '%s') AS pi
			LEFT JOIN player_register AS pr ON pr.id = pi.id
			LEFT JOIN player_asset as pa on pa.id = pi.id
		;]],_userId)
	elseif _weixin_union_id then	
		ret = PUBLIC.db_query_va([[
			SELECT
			pi.id AS userId,
			pr.login_id AS weixinUnionId,
			pr.register_channel,
			"[]" AS parentUserIds,
			pi.`name` AS nickname,
			pa.diamond,
			pa.shop_gold_sum,
			if(pi.head_image is null or '' = pi.head_image,'http://jydown.jyhd919.cn/head_images/icon_128.png',pi.head_image) AS avatarUrl
			FROM
			player_info AS pi
			LEFT JOIN player_register AS pr ON pr.id = pi.id
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

	user_data.shop_gold_sum = base.CMD.get_player_info(user_data.userId,"player_asset","shop_gold_sum")

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

--[[ 通过 微信 uuid 创建 或 关联用户
 如果用户已经有上级了，则不改变
返回：
	{
		result=0,
		userId=,
		gameParentUserIds={id1,id2,...}
	}
--]]
local using_uuid = {}
function base.CMD.wechat_safecreate_user(_uuid,_parentUserId)

	if not _uuid then
		return nil,1001
	end

	if using_uuid[_uuid] then
		return nil,1008
	end
	using_uuid[_uuid] = true

	if _parentUserId and not base.CMD.is_player_exists(_parentUserId) then
		_parentUserId = nil
	end

	local _uid = CMD.userId_from_login_id(_uuid,"wechat")
	if _uid then

		if not _parentUserId then
			using_uuid[_uuid] = nil
			return {userId=_uid,parentUserIds={}}
		end

		local parents = PUBLIC.club_get_user_parents(_uid)
		if not parents then
			using_uuid[_uuid] = nil
			return nil,2402
		end

		-- 没有才设置
		if _uid ~= _parentUserId and not parents[1] then
			parents = PUBLIC.club_set_user_parent(_uid,_parentUserId)
			base.DATA.sql_queue_slow:push_back(
				string.format("update player_info set sync_seq=%d where id='%s';",
					PUBLIC.auto_inc_id("last_player_info_seq"),_uid))
		end
		
		using_uuid[_uuid] = nil
		return {userId=_uid,gameParentUserIds=parents}

	else

		local _userId = skynet.call(DATA.service_config.verify_service,"lua","extend_create_user","wechat",_uuid,_parentUserId,"hermos")

		local parents 

		if _userId == _parentUserId or not _parentUserId then
			parents = {}
		else
			parents = PUBLIC.club_get_user_parents(_parentUserId)
			table.insert(parents,1,_parentUserId)
		end

		using_uuid[_uuid] = nil
		return {userId=_userId,parentUserIds=parents}
	end

	using_uuid[_uuid] = nil
end


return PROTECTED