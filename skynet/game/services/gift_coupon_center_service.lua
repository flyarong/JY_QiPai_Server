-- gift_coupon_center_service

local skynet = require "skynet_plus"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"

local cjson = require "cjson"
cjson.encode_sparse_array(true,1,0)

require "data_func"

require "normal_enum"

require "printfunc"

local DATA = base.DATA
local CMD = base.CMD
local PUBLIC=base.PUBLIC

DATA.service_config = nil

DATA.enable_gift_coupon = true

-- 已发放奖励表（ player_gift_coupon_log），如果存在，则表示已经发放奖励
-- player_id => true
DATA.player_gift_coupon_data = {}

-- 奖品表，定义各类型的奖品
-- tppe => data
DATA.gift_coupon_data = {}

-- 商家支持的奖品
-- player_id => data
DATA.gift_coupon_player = {}

--- 把sql插入队列中
function PUBLIC.db_exec(_sql , _queue_name)
	skynet.send(DATA.service_config.data_service,"lua","db_exec",_sql , _queue_name)
end
function PUBLIC.db_query(_sql)
	return skynet.call(DATA.service_config.data_service,"lua","db_query",_sql)
end  


function PUBLIC.load_data()

	-- player_gift_coupon_data

	local d = skynet.call(DATA.service_config.data_service,"lua","query_gift_coupon_data")
	
	for i,v in ipairs(d) do
		DATA.player_gift_coupon_data[v.player_id] = true
	end

	-- gift_coupon_data

	local sql = "select type,assets from gift_coupon_data"
	local ret = PUBLIC.db_query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
	end
	for _,d in ipairs(ret) do
		d.assets = cjson.decode(d.assets) -- json 解码
		DATA.gift_coupon_data[d.type] = d
	end

	-- gift_coupon_player
	sql = "select player_id,type from gift_coupon_player"
	ret = PUBLIC.db_query(sql)
	if( ret.errno ) then
		skynet.fail(string.format("sql error: sql=%s\nerr=%s\n",sql,basefunc.tostring( ret )))
	end
	for _,d in ipairs(ret) do
		DATA.gift_coupon_player[d.player_id] = d
	end

end

function CMD.set_enable(_is)
	DATA.enable_gift_coupon = _is
end


-- 发放奖励
function CMD.grant_gift_coupon(_player_id,_parent_id)

	if not DATA.enable_gift_coupon then
		return
	end

	if DATA.player_gift_coupon_data[_player_id] then
		print("grant_gift_coupon error,has gift:",_player_id,_parent_id)
		return
	end

	local pgc = DATA.gift_coupon_player[_parent_id]
	if not pgc then
		print("grant_gift_coupon error,no parent coupon :",_player_id,_parent_id)
		return
	end

	local gcc = DATA.gift_coupon_data[pgc.type]

	if not gcc then
		print("grant_gift_coupon error,no type:",pgc.type,_player_id,_parent_id)
		return
	end

	--从来没有登录过才行(判断新用户) [ 老用户也行 ]
	-- local sql = string.format("select * from player_login_stat where id = '%s'",_player_id or "")
	-- local login_stat_log = skynet.call(DATA.service_config.data_service,"lua","db_query",sql)
	-- if login_stat_log and next(login_stat_log) then
	-- 	return
	-- end

	DATA.player_gift_coupon_data[_player_id] = true

	local _assets_data = {}
	for _name,_value in pairs(gcc.assets) do
		_assets_data[#_assets_data + 1] = {
			asset_type = _name,
			value = _value,
		}
	end

	skynet.send(DATA.service_config.data_service,"lua","multi_change_asset_and_sendMsg",
							_player_id,_assets_data,ASSET_CHANGE_TYPE.GRANT_GIFT_COUPON,_parent_id)


	skynet.send(DATA.service_config.data_service,"lua","add_gift_coupon_log",
							_player_id,_parent_id,cjson.encode(gcc.assets))

end


----------------------------------------------
-- web 管理接口

--[[ 增加奖励类型
	{
		type=,
		assets = {jing_bi=,cash=,...},
		comment=,
	}
--]]
function CMD.addGiftCouponData(_data_json)
    local data = cjson.decode(_data_json)
    if not data then
        print("web manage addGiftCouponData 1001.1 error:",_data_json)
        return 1001
    end
	
	-- 已经存在
	if DATA.gift_coupon_data[data.type] then
		print("web manage addGiftCouponData 2414.1 error:",_data_json)
		return 2414
	end

	PUBLIC.db_exec(PUBLIC.format_sql("insert into gift_coupon_data(type,assets,comment) values(%s,%s,%s);",
	data.type,cjson.encode(data.assets),data.comment))

	DATA.gift_coupon_data[data.type] = data

	return 0
end

--[[ 修改奖励类型
	{
		type=,
		assets = {jing_bi=,cash=,...},
		comment=,
	}
--]]
function CMD.updateGiftCouponData(_data_json)
    local data = cjson.decode(_data_json)
    if not data then
        print("web manage updateGiftCouponData 1001.1 error:",_data_json)
        return 1001
    end
    
	if not DATA.gift_coupon_data[data.type] then
		print("web manage updateGiftCouponData 2415.1 error:",_data_json)
		return 2415
	end

	PUBLIC.db_exec(PUBLIC.format_sql("update gift_coupon_data set assets=%s,comment=%s where type=%s;",
	cjson.encode(data.assets),data.comment,data.type))

	DATA.gift_coupon_data[data.type] = data
	return 0
end

--[[ 为商家增加（设置）奖励类型
	{
		type=,
		playerIds = {player_id1,playe_id2,...},
		create_time=时间戳,
	}
--]]
function CMD.addGiftCouponPlayer(_data_json)
    local data = cjson.decode(_data_json)
    if not data then
        print("web manage addGiftCouponPlayer 1001.1 error:",_data_json)
        return 1001
    end
	
	-- 检查玩家
	for _,pid in ipairs(data.playerIds) do

		if not skynet.call(DATA.service_config.data_service,"lua","is_player_exists",pid) then
			print("web manage addGiftCouponPlayer 2159.1 error:",_data_json)
			return 2159
		end

		if DATA.gift_coupon_player[pid] then
			print("web manage addGiftCouponPlayer 2414.1 error:",_data_json)
			return 2414
		end
	end

	for _,pid in ipairs(data.playerIds) do
		PUBLIC.db_exec(PUBLIC.format_sql([[insert into gift_coupon_player(player_id,type,create_time,update_time) 
			values(%s,%s,FROM_UNIXTIME(%s),FROM_UNIXTIME(%s));]],
			pid,data.type,data.create_time,data.create_time))

		DATA.gift_coupon_player[pid] = {type=data.type}
	end

	return 0
end

--[[ 修改商家 奖励类型
	{
		type=,
		playerId = ,
		update_time=时间戳,
	}
--]]
function CMD.updateGiftCouponPlayer(_data_json)
    local data = cjson.decode(_data_json)
    if not data then
        print("web manage updateGiftCouponPlayer 1001.1 error:",_data_json)
        return 1001
	end
	
	if not skynet.call(DATA.service_config.data_service,"lua","is_player_exists",data.playerId) then
		print("web manage updateGiftCouponPlayer 2159.1 error:",_data_json)
		return 2159
	end
	
	-- 检查玩家
	if not DATA.gift_coupon_player[data.playerId] then
		print("web manage updateGiftCouponPlayer 2415.1 error:",_data_json)
		return 2415
	end

	PUBLIC.db_exec(PUBLIC.format_sql([[update gift_coupon_player set type=%s, update_time=FROM_UNIXTIME(%s)
		where player_id=%s;]],
		data.type,data.update_time,data.playerId))

	DATA.gift_coupon_player[data.playerId] = {type=data.type}

	return 0
end


--[[ 删除商家 奖励类型
	{
		playerId = ,
	}
--]]
function CMD.deleteGiftCouponPlayer(_data_json)
    local data = cjson.decode(_data_json)
    if not data then
        print("web manage deleteGiftCouponPlayer 1001.1 error:",_data_json)
        return 1001
    end
	
	if not skynet.call(DATA.service_config.data_service,"lua","is_player_exists",data.playerId) then
		print("web manage deleteGiftCouponPlayer 2159.1 error:",_data_json)
		return 2159
	end
	
	-- 检查玩家
	if not DATA.gift_coupon_player[data.playerId] then
		print("web manage deleteGiftCouponPlayer 2415.1 error:",_data_json)
		return 2415
	end

	PUBLIC.db_exec(PUBLIC.format_sql([[delete from gift_coupon_player where player_id=%s;]],data.playerId))

	DATA.gift_coupon_player[data.playerId] = nil

	return 0
end

function CMD.start(_service_config)

	DATA.service_config = _service_config

	PUBLIC.load_data()
end

-- 启动服务
base.start_service()
