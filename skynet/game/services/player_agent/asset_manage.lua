--
-- Author: yy
-- Date: 2018/4/14
-- Time: 15:14
-- 说明：资产管理
--

local skynet = require "skynet_plus"
local base = require "base"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "normal_enum"
require"printfunc"

require "player_agent.broke_subside"


local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC
local REQUEST=base.REQUEST

local return_msg={result=0}

DATA.asset_manage_data = DATA.asset_manage_data or {

	service_zero_time = 6,

	shoping_config = {},
	shoping_config_version = 0,

	--用户的所有资产hash
	asset_datas = {},

	player_object_id = {},

	--[[道具的数量
		在lock的时候会提前扣减数量，因此可能会和道具里面的内容不符
		需要每次道具变化的时候进行更新
	]] 
	player_object_num = {},

	--用户的所有卡券信息
	-- del by lyx
	-- player_tickets = {}
	-- player_tickets_list = {}
	-- player_tickets_game = {}

	--兑物券激活码
	-- del by lyx
	-- dwq_cdkey={}

	--资产锁定的数据
	--lock_id => data
	asset_locked_datas = {},
	asset_locked_datas_count = 0,

	asset_staging_data = {},
	asset_staging_data_count = 0,

	act_lock = false,

	return_lock_msg={result=0,lock_id=0},

	asset_type_error_enum_map=
	{
		[PLAYER_ASSET_TYPES.DIAMOND] = 1011, 		--钻石
		[PLAYER_ASSET_TYPES.CASH] = 1013, 			--现金
		[PLAYER_ASSET_TYPES.JING_BI] = 1023, --鲸币
		[PLAYER_ASSET_TYPES.SHOP_GOLD_SUM] = 1024, --红包券
		[PLAYER_ASSET_TYPES.ROOM_CARD] = 1026, --红包券
	},
}
local D = DATA.asset_manage_data

--进行资产验证 返回资源不足的错误编号
local function asset_verify(_asset_data)

	local error_code = 0
	local deduct_asset = {}
	for i,asset in ipairs(_asset_data) do
		local my_value = D.asset_datas[asset.asset_type] or D.player_object_num[asset.asset_type]
		my_value = my_value or 0
		assert(asset.asset_type~="jipaiqi","jipaiqi not to verify")
		if asset.condi_type == NOR_CONDITION_TYPE.CONSUME then
			if my_value < asset.value then
				error_code = D.asset_type_error_enum_map[asset.asset_type] or 1012
				break
			end
		elseif asset.condi_type == NOR_CONDITION_TYPE.EQUAL then
			if my_value ~= asset.value then
				error_code = D.asset_type_error_enum_map[asset.asset_type] or 1012
				break
			end
		elseif asset.condi_type == NOR_CONDITION_TYPE.GREATER then
			if my_value < asset.value then
				error_code = D.asset_type_error_enum_map[asset.asset_type] or 1012
				break
			end
		elseif asset.condi_type == NOR_CONDITION_TYPE.LESS then
			if my_value > asset.value then
				error_code = D.asset_type_error_enum_map[asset.asset_type] or 1012
				break
			end
		else
			skynet.fail("asset.condi_type error " .. tostring(asset.condi_type))
		end
	end

	return error_code
end

--进行资产验证和消耗 返回资源不足的错误编号
local function asset_verify_consume(_asset_data)

	local error_code = 0
	local deduct_asset = {}
	for i,asset in ipairs(_asset_data) do
		local my_value = D.asset_datas[asset.asset_type] or D.player_object_num[asset.asset_type]
		my_value = my_value or 0
		assert(asset.asset_type~="jipaiqi","jipaiqi not to verify_consume")
		if asset.condi_type == NOR_CONDITION_TYPE.CONSUME then
			if my_value < asset.value then
				error_code = D.asset_type_error_enum_map[asset.asset_type] or 1012
				break
			else
				if basefunc.is_object_asset(asset.asset_type) then
					D.player_object_num[asset.asset_type] = D.player_object_num[asset.asset_type] - asset.value
				else
					D.asset_datas[asset.asset_type] = my_value-asset.value
					deduct_asset[asset.asset_type] = (deduct_asset[asset.asset_type] or 0) + asset.value
				end
			end
		elseif asset.condi_type == NOR_CONDITION_TYPE.EQUAL then
			if my_value ~= asset.value then
				error_code = D.asset_type_error_enum_map[asset.asset_type] or 1012
				break
			end
		elseif asset.condi_type == NOR_CONDITION_TYPE.GREATER then
			if my_value < asset.value then
				error_code = D.asset_type_error_enum_map[asset.asset_type] or 1012
				break
			end
		elseif asset.condi_type == NOR_CONDITION_TYPE.LESS then
			if my_value > asset.value then
				error_code = D.asset_type_error_enum_map[asset.asset_type] or 1012
				break
			end
		else
			skynet.fail("asset.condi_type error " .. tostring(asset.condi_type))
		end
	end

	if error_code ~= 0 then
		for asset_type,value in pairs(deduct_asset) do

			if basefunc.is_object_asset(asset_type) then
				D.player_object_num[asset_type] = D.player_object_num[asset_type] + value
			else
				D.asset_datas[asset_type] = (D.asset_datas[asset_type] or 0 )+value
				PUBLIC.change_asset_and_msg( asset_type ,value ,D.asset_datas[asset_type])
			end
			
		end
	end

	return error_code
end


local function create_lock_id()
	return (os.time()%1524130583)+D.asset_locked_datas_count
end


--[[加载资产从数据库
]]
function PUBLIC.load_asset()

	local is_pay_test = skynet.getcfg("is_pay_test")

	--###test
	--DATA.my_id = "user_10_757928"

	local ori_data = DATA.player_data

	-- by lyx
	if not ori_data then
		skynet.fail(string.format("load_asset error:user '%s' base data is nil!",DATA.my_id))
		return
	elseif not ori_data.player_asset then
		skynet.fail(string.format("load_asset error:user '%s' asset data is nil!",DATA.my_id))
		return
	elseif not ori_data.player_prop then
		skynet.fail(string.format("load_asset error:user '%s' prop data is nil!",DATA.my_id))
		return
	elseif not ori_data.object_data then
		skynet.fail(string.format("load_asset error:user '%s' object_data is nil!",DATA.my_id))
		return	
	end

	--dump(ori_data,"ori_data")
	for asset_type,value in pairs(ori_data.player_asset) do
		D.asset_datas[asset_type]=value
	end
	-- dump(ori_data.player_prop,"/////*-*-/*/-----*-------")
	for prop_type,prop in pairs(ori_data.player_prop) do
		D.asset_datas[prop_type]=prop.prop_count
	end

	PUBLIC.init_object_data()

	D.asset_datas["id"] = nil

	--dump(D.asset_datas,"my D.asset_datas:")

	local _is_robot = not basefunc.chk_player_is_real(DATA.my_id)

	--###test
	if  not _is_robot then
		if is_pay_test then

			-- 测试环境加钱
			if D.asset_datas[PLAYER_ASSET_TYPES.JING_BI] < 10000 then
				skynet.timeout(10,function ()
						local _asset_data={

							-- {asset_type=PLAYER_ASSET_TYPES.DIAMOND,value=1000000},
							{asset_type=PLAYER_ASSET_TYPES.JING_BI,value=100000},

							-- {asset_type="prop_2",value=2},
							
							-- {asset_type=PLAYER_ASSET_TYPES.CASH,value=21000},
							-- {asset_type=PLAYER_ASSET_TYPES.SHOP_GOLD_SUM,value=500},

							-- {asset_type=PLAYER_ASSET_TYPES.ROOM_CARD,value=100},

						}
						CMD.change_asset_multi(_asset_data,"init_test",0)
				end)
			end
		end
	end

end


-- 初始化购物配置
local function init_shoping_config()

	--礼包的数据
	local gift_bag = {}
	local gb_cfg = D.shoping_config.gift_bag
	local gb_condi_cfg = D.shoping_config.gift_bag_condition
	for i,d in ipairs(gb_cfg) do
		if d.condition then
			d.condition = gb_condi_cfg[d.condition]
		end
		gift_bag[d.id] = d
	end
	D.shoping_config.gift_bag_condition = nil

	-- id 有重复 先行处理
	for k,d in pairs(D.shoping_config.item) do
		local dt = D.shoping_config[d.type] or {}
		D.shoping_config[d.type] = dt
		dt[#dt+1] = d
	end
	D.shoping_config.item = nil
	
	-- id 映射
	local tmp = {}
	for k,v in pairs(D.shoping_config) do
		tmp[k]={}
		for i,d in ipairs(D.shoping_config[k]) do
			tmp[k][d.id]=d
		end
	end

	tmp.gift_bag = gift_bag

	D.shoping_config = tmp

end

function PUBLIC.get_shoping_config()
	
	PUBLIC.update_shoping_config()

	return D.shoping_config
end

-- 检查更新商城配置
function PUBLIC.update_shoping_config()
	
	local c,v = skynet.call(DATA.service_config.shoping_config_center_service,"lua"
												,"get_config",D.shoping_config_version)

	if c then
		D.shoping_config = c
		D.shoping_config_version = v
		init_shoping_config()
	end

	--dump(D.shoping_config,"++++++/*-/*-")
end

--- add by wss  改变资产&发出消息
function PUBLIC.change_asset_and_msg( asset_type , change_value , final_value)

	--DATA.msg_dispatcher:call("asset_change_msg", asset_type
	--							, change_value
	--							, final_value )

	PUBLIC.trigger_msg( {name = "asset_change_msg"} , asset_type , change_value , final_value )

end


--- 把全部的资产类型发一个改变0的消息出去
function PUBLIC.asset_observe()
	for key , asset_type in pairs(PLAYER_ASSET_TYPES) do
		if D.asset_datas[asset_type] then
			--DATA.msg_dispatcher:call("asset_change_msg", asset_type
			--					, 0
			--					, D.asset_datas[asset_type] )

			PUBLIC.trigger_msg( {name = "asset_change_msg"} , asset_type , 0 , D.asset_datas[asset_type] )
		end
	end
end


-- 获取类型中最快失效的n个道具
function PUBLIC.get_lately_object_data(_object_type,_n)
	
	-- 如果就没有这个道具类型 直接返回
	if not D.player_object_id[_object_type] then
		return nil
	end

	local ods = {}

	local now = os.time()

	for object_id,d in pairs(DATA.player_data.object_data) do

		if d.object_type == _object_type then
			
			-- 可能在提前扣减数量的时候先检查过了时间，然后突然过期了
			-- local valid_time = tonumber(d.attribute.valid_time) or 2053509902

			-- if valid_time>now then

				ods[#ods+1] = 
				{
					object_type = _object_type,
					object_id = object_id,
				}

			-- end

		end

	end

	if #ods > _n then

		table.sort( ods, function(a,b)
			local av = DATA.player_data.object_data[a.object_id].attribute.valid_time or 0
			local bv = DATA.player_data.object_data[b.object_id].attribute.valid_time or 0
			return tonumber(av) < tonumber(bv)
		end)

		ods[_n+1] = nil

	end

	return ods

end

--[[
{
	object_id = xx21s2aw,
	object_type = _type, --新增时需要
	attribute = _data, -- nil 代表删除此物品
}
]]
local function change_obj(_obj_data,_log_type,_change_id,_save_db,_is_not_change_num)
	
	--dump(_obj_data,"change_obj++++"..DATA.my_id)

	local obj = DATA.player_data.object_data[_obj_data.object_id]
	if obj then
		if _obj_data.attribute then

			if type(_obj_data.attribute)~="table" 
				or not next(_obj_data.attribute) then

					print("update object error attribute is error or empty ")
					return
			end

			if _save_db then
				PUBLIC.update_object(_obj_data.object_id,_obj_data.attribute,_log_type,_change_id)
			end

			DATA.player_data.object_data[_obj_data.object_id].attribute = _obj_data.attribute

			return "update"
		else

			if _save_db then
				PUBLIC.delete_object(_obj_data.object_id,_log_type,_change_id)
			end

			DATA.player_data.object_data[_obj_data.object_id] = nil

			if not _is_not_change_num then
				D.player_object_num[_obj_data.object_type] = D.player_object_num[_obj_data.object_type] - 1
			end

			return "delete"
		end
	else

		if not _obj_data.attribute 
			or not _obj_data.object_type 
			or type(_obj_data.attribute)~="table" 
			or not next(_obj_data.attribute) then

				print("add object error attribute is nil or empty 2 ",debug.traceback())
				return
		end

		if _save_db then
			_obj_data.object_id = PUBLIC.add_object(_obj_data.object_type,_obj_data.attribute,_log_type,_change_id)
		end

		if not _is_not_change_num then
			D.player_object_num[_obj_data.object_type] = (D.player_object_num[_obj_data.object_type]or 0) + 1
		end

		DATA.player_data.object_data[_obj_data.object_id] = _obj_data

		D.player_object_id[_obj_data.object_type] = _obj_data.object_id

		return "add"
		
	end

	return nil
end


--[[增减资产

	_asset_data={
		{asset_type=jing_bi,value=100},
		{asset_type=object_tick,value=o20125a1d21s,attribute={valid_time=123},num=2(>0 or nil)},
	}

	是否同步到数据库 如果是下面的参数需要传递
	_log_type - 财物改变类型
	_change_id - 改变原因id  没有为0

	特别的 condi_type 条件类型

	value 可能为道具的 object_id
	attribute 为不可叠加道具属性 
]]
local function change_asset_multi(_asset_data,_log_type,_change_id,_not_notify,_save_db)
	
	--dump(_asset_data,"//////*-*-*--"..DATA.my_id)

	local _change_asset_data = {}

	for i,asset in ipairs(_asset_data) do

		if not asset.condi_type
			or asset.condi_type == NOR_CONDITION_TYPE.CONSUME then

			if tonumber(asset.value)then

				if asset.value ~= 0 then

					if basefunc.is_dress_asset(asset.asset_type) then
						
						local _t,_i = basefunc.parse_dress_asset(asset.asset_type)

						-- 目前只有数量和时间
						local num,time=nil,nil
						num=asset.value

						--DATA.msg_dispatcher:call("buy_dress"
						--						,_t
						--						,_i
						--						,num
						--						,time
						--						,_log_type)

						---

						PUBLIC.trigger_msg( {name = "buy_dress"} , _t , _i , num , time , _log_type )

					elseif asset.asset_type == "jipaiqi" then
						-- 记牌器单独处理

						local day = asset.value
						local time = 0
						if not D.player_object_id.jipaiqi then
						-- 没有这个物品 直接用时间
							time = os.time() + math.floor(day*3600*24)
						else
							-- 有的话叠加时间 更新道具属性
							local d = DATA.player_data.object_data[D.player_object_id.jipaiqi]
							if d then
								time = tonumber(d.attribute.valid_time)
							end
							if time < os.time() then
								time = os.time() + math.floor(day*3600*24)
							else
								time = time + math.floor(day*3600*24)
							end
						end

						change_obj(
							{
								object_type = "jipaiqi",
								object_id = D.player_object_id.jipaiqi or asset.object_id,
								attribute = {valid_time = time},
							}
							,_log_type
							,_change_id
							,_save_db)
						
						_change_asset_data[#_change_asset_data+1]=asset

					else

						D.asset_datas[asset.asset_type]=(D.asset_datas[asset.asset_type]or 0)+asset.value
						
						PUBLIC.change_asset_and_msg(asset.asset_type,asset.value,D.asset_datas[asset.asset_type])

						_change_asset_data[#_change_asset_data+1]=asset

						----- 在商城兑换红包后，发出一个兑换红包消息出来。
						if asset.asset_type == PLAYER_ASSET_TYPES.SHOP_GOLD_SUM and _log_type == ASSET_CHANGE_TYPE.SHOPING then
							--DATA.msg_dispatcher:call("exchange_by_hongbao")
							PUBLIC.trigger_msg( {name = "exchange_by_hongbao"} )
						end

						if _save_db then
							skynet.send(DATA.service_config.data_service,"lua","change_asset",
												DATA.my_id,asset.asset_type,
												asset.value,_log_type,_change_id)
						end
					
					end

				end

			else
				
				-- 道具数量(只支持增加的时候)
				-- 删除的时候必须多次单独删除，因为需要提供object_id
				asset.num = tonumber(asset.num) or 1

				local asset_num = asset.num
				if not asset.attribute then
					-- 没有写属性那么就是删除道具
					asset_num = -asset_num
				end 

				-- 记牌器单独处理 时间变为天数
				if asset.asset_type == "jipaiqi" then
					error("error add jipaiqi error")
				end

				-- 道具处理
				for i=1,asset.num do
					change_obj(
							{
								object_type = asset.asset_type,
								object_id = asset.value,
								attribute = asset.attribute,
							}
							,_log_type
							,_change_id
							,_save_db)
				end

				if asset_num>0 then
					-- 不可叠加道具直接转化为普通的可叠加资产的改变，因为只是作为显示
					_change_asset_data[#_change_asset_data+1]=
					{
						asset_type = asset.asset_type,
						value = asset_num,
					}
				end

			end

		end

	end

	if not _not_notify then
		PUBLIC.notify_asset_change_msg(_log_type,_change_asset_data)
	end
end


--[[增加加资产
	这里只做增加资产，不可以填写负数，也就是不可以进行扣除资产
	-- 记牌器还是普通资产一样调用 按数量计算一天的时间多个的时候进行累加
	
	_asset_data={
		{asset_type=jing_bi,value=100},
		{asset_type=object_tick,value=o20125a1d21s,attribute={valid_time=123},num=2},
	}

	是否同步到数据库 如果是下面的参数需要传递
	_log_type - 财物改变类型
	_change_id - 改变原因id  没有为0

	特别的 condi_type 条件类型
]]
function CMD.change_asset_multi(_asset_data,_log_type,_change_id,_not_notify)
	change_asset_multi(_asset_data,_log_type,_change_id,_not_notify,true)
end


--------------------------------------------------------------------------------------------
--数据库通知 刷新 multi_asset
function CMD.multi_asset_on_change_msg(_asset_datas,_log_type)
	change_asset_multi(_asset_datas,_log_type,nil,false,false)
end


--------------------------------------------------------------------------------------------


--[[检测资产可行性 数组
	--这里value不用写成负数
	_asset_data={
		{condi_type,asset_type,value},
		{condi_type,asset_type,value},
	}
]]
function PUBLIC.asset_verify(_asset_data)

	return_msg.result = asset_verify(_asset_data)
	return return_msg
end

--[[资产锁定 数组
	--这里只处理扣除资源操作，即value不用写成负数，本身就是扣除这个值
	_asset_data={
		{condi_type,asset_type,value},
		{condi_type,asset_type,value},
	}
]]
function PUBLIC.asset_lock(_asset_data)

	--检测资产可行性 锁定 并消耗
	local ret = asset_verify_consume(_asset_data)
	if ret > 0  then
		D.return_lock_msg.result = ret
		D.return_lock_msg.lock_id = 0
		return D.return_lock_msg
	end

	local lock_id = create_lock_id()
	D.asset_locked_datas[lock_id] = _asset_data
	D.asset_locked_datas_count = D.asset_locked_datas_count + 1

	D.return_lock_msg.result = 0
	D.return_lock_msg.lock_id = lock_id
	return D.return_lock_msg
end

--[[资产提交
	_lock_id = 锁的id
	_log_type = 修改财产日志类型
]]
function PUBLIC.asset_commit(_lock_id,_log_type,_change_id)
	local data = D.asset_locked_datas[_lock_id]
	if data then

		local obj_list = nil

		--提交数据库
		for i,asset in ipairs(data) do
			if asset.condi_type == NOR_CONDITION_TYPE.CONSUME then

				if basefunc.is_object_asset(asset.asset_type) then
					obj_list = {}
					local ods = PUBLIC.get_lately_object_data(asset.asset_type,asset.value)
					for i,od in ipairs(ods) do
						obj_list[#obj_list+1]=DATA.player_data.object_data[od.object_id]
						change_obj(od,_log_type,_change_id,true,true)
					end
				else
					
					if asset.value ~= 0 then
						skynet.send(DATA.service_config.data_service,"lua","change_asset",
											DATA.my_id,asset.asset_type,
											-asset.value,_log_type,_change_id)
					end

				end

			end

		end

		D.asset_locked_datas[_lock_id] = nil
		D.asset_locked_datas_count = D.asset_locked_datas_count - 1

		return 
		{
			result = 0,
			obj_list=obj_list,
		}
	else
		D.return_lock_msg.result = 2100
		D.return_lock_msg.lock_id = _lock_id
		return D.return_lock_msg
	end
end

--[[资产解锁
]]
function PUBLIC.asset_unlock(_lock_id)
	local data = D.asset_locked_datas[_lock_id]
	if data then

		--返还
		for i,asset in ipairs(data) do
			if asset.condi_type == NOR_CONDITION_TYPE.CONSUME then
				D.asset_datas[asset.asset_type]=(D.asset_datas[asset.asset_type]or 0)+asset.value
			end
		end

		D.asset_locked_datas[_lock_id] = nil
		D.asset_locked_datas_count = D.asset_locked_datas_count - 1

		D.return_lock_msg.result = 0
		D.return_lock_msg.lock_id = _lock_id
		return D.return_lock_msg
	else
		D.return_lock_msg.result = 2101
		D.return_lock_msg.lock_id = _lock_id
		return D.return_lock_msg
	end
end


--[[资产暂存 立刻改变 但是不写数据库
	不支持 特殊独立道具
]]
function PUBLIC.asset_staging(_asset_data)
	
	D.asset_staging_data_count = D.asset_staging_data_count + 1
	local lock_id = D.asset_staging_data_count

	for i,asset in ipairs(_asset_data) do
		D.asset_datas[asset.asset_type]=(D.asset_datas[asset.asset_type]or 0)+asset.value
	end

	D.asset_staging_data[lock_id] = _asset_data

	return lock_id

end

--[[批量合并提交 暂存资产  写数据库
]]
function PUBLIC.asset_merge_commit(_lock_ids,_log_type,_change_id)

	local assets = {}

	for k,lock_id in pairs(_lock_ids) do
			
		local data = D.asset_staging_data[lock_id]
		if data then

			for i,asset in ipairs(data) do
				assets[asset.asset_type]=(assets[asset.asset_type]or 0)+asset.value
			end

			D.asset_staging_data[lock_id] = nil
		end

	end

	--提交数据库
	for asset_type,value in pairs(assets) do

		if value ~= 0 then
			skynet.send(DATA.service_config.data_service,"lua","change_asset"
								,DATA.my_id
								,asset_type
								,value
								,_log_type
								,_change_id)
		end

	end

	PUBLIC.notify_asset_change_msg(_log_type)

end


--[[记录一笔游戏消费
	支付房费，服务费 jing_bi
]]
function PUBLIC.add_game_consume_statistics(_asset_datas)
	--
	for i,asset in ipairs(_asset_datas) do
		if asset.condi_type == NOR_CONDITION_TYPE.CONSUME
			and asset.asset_type == PLAYER_ASSET_TYPES.JING_BI then

			if asset.value ~= 0 then
				skynet.send(DATA.service_config.data_service,"lua","add_consume_statistics",
										DATA.my_id,"cost_jing_bi",asset.value)
			end

		end
	end
end

-------------------------------------------------appstore check--------------------------------------------
-------------------------------------------------appstore check--------------------------------------------

function REQUEST.req_appstorepay_check(self)
	if type(self.product_id)~="string" or string.len(self.product_id)<3
		or type(self.receipt)~="string" or string.len(self.receipt)<3
		or type(self.is_sandbox)~="number" or (self.is_sandbox~=0 and self.is_sandbox~=1)
		or type(self.transaction_id)~="string" or string.len(self.transaction_id)<3
		or (self.convert and not ASSETS_CONVERT_TYPE[self.convert] )
		or type(self.definition_id)~="string"
			 then
				
		return_msg.result=1001
		return return_msg
	end

	skynet.send(DATA.service_config.pay_service,"lua","verify_appstore_pay"
					,DATA.my_id
					,self.product_id
					,self.receipt
					,self.transaction_id
					,self.is_sandbox
					,self.convert
					,self.definition_id)

	return_msg.result=0
	return return_msg
end




-------------------------------------------------appstore check--------------------------------------------
-------------------------------------------------appstore check--------------------------------------------







-------------------------------------------------代币--------------------------------------------
-------------------------------------------------代币--------------------------------------------
--[[并非真正意义上的代币
	代币只是象征着您的货币数量
	购买代币并不会扣除你的鲸币
	有且只有代币的变化才会对您的鲸币进行同步加减
]]
--补充某种游戏的代币 都是 鲸币 1:1
-- function PUBLIC.replenish_game_coin(game,min_num,max_num)
-- 	local coin_type = game.."_coin"
-- 	if max_num == 0 then
-- 		return 0
-- 	end

-- 	--如果我的代币数量比我本身的钱还多(房费问题)，需要更新
-- 	if (D.asset_datas[coin_type] or 0) > D.asset_datas[PLAYER_ASSET_TYPES.JING_BI] then
-- 		D.asset_datas[coin_type] = D.asset_datas[PLAYER_ASSET_TYPES.JING_BI]
-- 	end

-- 	--我的代币比最小限度大则不需要补充
-- 	if (D.asset_datas[coin_type] or 0) > min_num then
-- 		return 0
-- 	end

-- 	if max_num < 0 then
-- 		max_num = D.asset_datas[PLAYER_ASSET_TYPES.JING_BI]
-- 	end

-- 	local need_num = max_num-(D.asset_datas[coin_type] or 0)
-- 	local my_num = D.asset_datas[PLAYER_ASSET_TYPES.JING_BI]


-- 	D.asset_datas[coin_type] = (D.asset_datas[coin_type] or 0)+math.min(need_num,my_num)

-- 	return 0
-- end

-- --返还游戏代币 -- 退出游戏后会折返代币
-- function PUBLIC.free_game_coin(game)

-- 	local coin_type = game.."_coin"

-- 	D.asset_datas[coin_type]=nil

-- end
-- function PUBLIC.change_game_coin(game,num,change_type)
-- 	local coin_type = game.."_coin"
-- 	local game_coin = D.asset_datas[coin_type] or 0
-- 	local real_num = num

-- 	if num + game_coin < 0 then
-- 		real_num = -game_coin
-- 	end

-- 	D.asset_datas[coin_type] = game_coin + real_num

-- 	PUBLIC.change_asset(PLAYER_ASSET_TYPES.JING_BI,
-- 							real_num,
-- 							change_type,0)
-- 	return real_num

-- end

-- --查询游戏代币的数量
-- function PUBLIC.query_game_coin(game)
-- 	local coin_type = game.."_coin"
-- 	return D.asset_datas[coin_type] or 0
-- end


-------------------------------------------------代币-------------------------------------------
-------------------------------------------------代币-------------------------------------------


function PUBLIC.query_asset()

	local assets_list = {}
	for k,v in pairs(D.asset_datas) do
		assets_list[#assets_list+1]={asset_type=k,asset_value=v}
	end

	for object_id,d in pairs(DATA.player_data.object_data) do
		local attribute = {}
		for k,v in pairs(d.attribute) do
			attribute[#attribute+1] = {name=k,value=v}
		end
		assets_list[#assets_list+1]={asset_type=d.object_type,asset_value=object_id,attribute=attribute}
	end
	
	return assets_list
end


function CMD.query_asset_by_type(type)

	local n = D.asset_datas[type]

	if not n then

		if D.player_object_id[type] then

			n = D.player_object_num[type] or 0

		end

	end

	return n or 0
end


--[[向客户端推送资产变化信息
	直接推送所有资产数量（不包含道具）
]]
function PUBLIC.notify_asset_change_msg(_type,_asset_datas)
	
	local assets_list = PUBLIC.query_asset()

	local change_asset_list = nil
	
	if _asset_datas then

		change_asset_list = {}
		
		for k,v in pairs(_asset_datas) do

			if v.value>0 then

				change_asset_list[#change_asset_list+1]={asset_type=v.asset_type,asset_value=v.value}

			end

		end

	end

	PUBLIC.request_client("notify_asset_change_msg",{player_asset=assets_list,change_asset=change_asset_list,type=_type})
end


----------------------------------------------分享奖励-------------------------------------------------

--DATA.everyday_shared_award_status
local everyday_shared_award_status = nil

function PUBLIC.init_everyday_shared_award()

	DATA.everyday_shared_award_status = skynet.call(DATA.service_config.data_service,"lua","query_shared_award_status",DATA.my_id)
	everyday_shared_award_status = DATA.everyday_shared_award_status
	--dump(everyday_shared_award_status,"everyday_shared_award_status "..DATA.my_id)
end


local function query_everyday_award(_type)

	local status = 0
	local cur_date = os.time()
	local last_date = 0

	local config = skynet.call(DATA.service_config.shared_game_center_service,"lua","get_config")

	local cfg = config[_type]

	if cfg then

		if everyday_shared_award_status[_type] then
			last_date = everyday_shared_award_status[_type].time
		else
			everyday_shared_award_status[_type] =
			{
				status = 0,
				time = 0,
			}
		end

		--日期已经重置
		if not basefunc.chk_same_date(last_date,cur_date,D.service_zero_time) then
			
			everyday_shared_award_status[_type].status = 0

		end

		if everyday_shared_award_status[_type].status < cfg.shared_num then
			status = cfg.shared_num - everyday_shared_award_status[_type].status
		end

	else
		status = 1001
	end

	return {result=0,status = status,config = cfg}
end

local function query_wys_shared_award()

	local _type = "wys_shared"

	local status = 0
	local cur_date = os.time()
	local last_date = 0

	local config = skynet.call(DATA.service_config.shared_game_center_service,"lua","get_config")

	local cfg = config[_type]

	if cfg then

		if everyday_shared_award_status[_type] then
			last_date = everyday_shared_award_status[_type].time
		else
			local n = #cfg
			everyday_shared_award_status[_type] =
			{
				status = 0,
				time = 0,
			}
		end

		--日期已经重置
		if not basefunc.chk_same_date(last_date,cur_date,D.service_zero_time) then
			
			status = 1

		end

	else
		status = 1001
	end

	-- 活动范围内才行
	if cur_date < 1558400400 or cur_date > 1559232000 then
		cfg = nil
		status = 1002
	end

	return {
			result=0,
			status = status,
			config = cfg,
			arg = everyday_shared_award_status[_type].status,
			}
end


-- 千元赛 玩过没有
local qys_gamed = nil
local qys_gamed_time = 0
local function query_qys_shared_award()

	local _type = "qys_shared"

	local status = 0
	local cur_date = os.time()
	local last_date = 0

	local config = skynet.call(DATA.service_config.shared_game_center_service,"lua","get_config")

	local cfg = config[_type]

	if cfg then

		if everyday_shared_award_status[_type] then
			if everyday_shared_award_status[_type].status > 0 then
				status = 0
			else
				status = 1
			end
		else
			everyday_shared_award_status[_type] =
			{
				status = 0,
				time = 0,
			}
			status = 1
		end

		if qys_gamed_time < os.time() then
			qys_gamed = nil
		end

		if not qys_gamed then

			local sql = string.format("SELECT COUNT(*) num FROM naming_match_rank WHERE player_id = '%s' AND match_model = 'naming_qys';",DATA.my_id)

			local d = skynet.call(DATA.service_config.data_service,"lua","db_query",sql)

			qys_gamed = 1

			if d and next(d) then
				if d[1] and d[1].num then
					qys_gamed = d[1].num
				end
			end

			qys_gamed_time = os.time() + 60
		end

		if qys_gamed > 0 then
			status = 0
		end

	else
		status = 1001
	end

	return {
			result=0,
			status = status,
			config = cfg,
			}
end


function REQUEST.query_everyday_shared_award(self)

	if D.act_lock then
		return_msg.result=1008
		return return_msg
	end
	D.act_lock = true

	if self and self.type then
		local ret
		if self.type == "wys_shared" then
			ret = query_wys_shared_award()
		elseif self.type == "qys_shared" then
			ret = query_qys_shared_award()
		else
			ret = query_everyday_award(self.type)
		end

		D.act_lock = false

		return ret
	end

	D.act_lock = false

	return_msg.result=1001
	return return_msg

end



--获取每日分享奖励 每日只会获取一次
local function get_everyday_shared_award(_type)

	local ret = query_everyday_award(_type)

	if ret.status > 0 and ret.config then

		local cn = everyday_shared_award_status[_type].status
		everyday_shared_award_status[_type].status = cn + 1

		everyday_shared_award_status[_type].time = os.time()

		skynet.send(DATA.service_config.data_service,"lua","set_shared_award_status"
						,DATA.my_id,_type,os.time(),everyday_shared_award_status[_type].status)

		local cur_date = os.time()
		CMD.change_asset_multi({[1]={asset_type=ret.config.assets_type,value=ret.config.assets_num}}
								,"everyday_".._type,cur_date)

	end

end


local can_city_shared_award_time = 0
--获取城市杯海选门票
local function get_city_shared_award()

	if can_city_shared_award_time > os.time() then
		return
	end
	can_city_shared_award_time = os.time() + 10

	-- local email = {
	-- 	type = "native",
	-- 	title = "分享朋友圈拿门票",
	-- 	receiver = DATA.my_id,
	-- 	sender = "系统",
	-- 	data={
	-- 		content="恭喜您通过分享获得海选门票一张，祝您取得好成绩。"
	-- 		,zy_city_match_ticket_hx=1
	-- 		,asset_change_data={change_type="city_shared",change_id=0}
	-- 		}
	-- }

	-- skynet.send(DATA.service_config.email_service,"lua","send_email",email)

	-- PUBLIC.change_asset(PLAYER_ASSET_TYPES.ZY_CITY_MATCH_TICKET_HX,1,"city_shared",0)

end


local function get_wys_shared_award( _arg )
	
	_type = "wys_shared"

	local ret = query_wys_shared_award()

	if ret.status > 0 and ret.config and ret.config[_arg] then

		local s = everyday_shared_award_status[_type].status

		local t = basefunc.bit_get_place_value(s,_arg)
		if t > 0 then
			return
		end

		s = basefunc.bit_set_place_value(s,_arg,1)

		everyday_shared_award_status[_type].status = s
		everyday_shared_award_status[_type].time = os.time()

		skynet.send(DATA.service_config.data_service,"lua","set_shared_award_status"
						,DATA.my_id
						,_type
						,everyday_shared_award_status[_type].time
						,everyday_shared_award_status[_type].status)

		local cur_date = os.time()
		CMD.change_asset_multi({[1]={asset_type=ret.config[_arg].assets_type,value=ret.config[_arg].assets_num}}
								,"everyday_".._type,cur_date)

	end

end


--获取每日分享奖励 每日只会获取一次
local function get_qys_shared_award()
	
	_type = "qys_shared"

	local ret = query_qys_shared_award()
	
	if ret.status > 0 and ret.config then

		local cn = everyday_shared_award_status[_type].status
		everyday_shared_award_status[_type].status = cn + 1

		everyday_shared_award_status[_type].time = os.time()

		skynet.send(DATA.service_config.data_service,"lua","set_shared_award_status"
						,DATA.my_id,_type,os.time(),everyday_shared_award_status[_type].status)

		local cur_date = os.time()
		CMD.change_asset_multi({[1]={asset_type=ret.config.assets_type,value=ret.config.assets_num}}
								,"everyday_".._type,cur_date)

	end

end

--客户端确认了分享完成
function REQUEST.shared_finish(self)

	if D.act_lock then
		return_msg.result=1008
		return return_msg
	end

	if type(self.type) ~= "string" then
		return_msg.result=1001
		return return_msg
	end

	D.act_lock = true


	--DATA.msg_dispatcher:call("shared_finish", self.type )
	PUBLIC.trigger_msg( {name = "shared_finish"} , self.type )

	if self.type == "city" then
		get_city_shared_award()
	elseif self.type == "wys_shared" then
		get_wys_shared_award(self.arg)
	elseif self.type == "qys_shared" then
		get_qys_shared_award()
	else
		get_everyday_shared_award(self.type)
	end
	D.act_lock = false
	return_msg.result=0
	return return_msg
end



----------------------------------------------撕毁道具-------------------------------------------------


function REQUEST.destroy_asset(self)

	if not self 
		or type(self.asset_type)~="string" 
		or type(self.asset_value)~="number" 
		or self.asset_value<0 then

		return_msg.result=1001
		return return_msg

	end

	local num = D.asset_datas[self.asset_type] or 0
	if num < self.asset_value then
		return_msg.result=1012
		return return_msg
	end


	return_msg.result=0
	return return_msg
end

----------------------------------------------撕毁道具-------------------------------------------------



----------------------------------------------客户端请求-------------------------------------------------



function REQUEST.query_asset(self)

	local assets_list = {}
	for k,v in pairs(D.asset_datas) do
		assets_list[#assets_list+1]={asset_type=k,asset_value=v}
	end

	return {result=0,player_asset=assets_list}
end

function CMD.query_asset(self)
	return D.asset_datas
end



--充1块钱的新手引导话费
function REQUEST.pay_1_tariffe(self)
	if type(self.phone_no)~="string"
		or not tonumber(self.phone_no)
		or string.len(self.phone_no)~=11 then
		return_msg.result=1001
		return return_msg
	end

	if D.act_lock then
		return_msg.result=1008
		return return_msg
	end
	D.act_lock = true

	local phone_no = REQUEST.query_bind_phone()
	if not phone_no.phone_no then
		phone_no = self.phone_no

		local status = skynet.call(DATA.service_config.data_service,"lua","query_bind_phone_number_is_exist",
						phone_no)
		if status > 0 then
			D.act_lock = false
			return_msg.result=2603
			return return_msg
		end
	else
		phone_no = phone_no.phone_no
	end

	local ret = skynet.call(DATA.service_config.data_service,"lua","player_xsyd_pay_finish",DATA.my_id)

	if ret == 0 then
		PUBLIC.force_bind_phone(phone_no)

		local pay_ret = skynet.call(base.DATA.service_config.third_agent_service,"lua"
												,"pay_phone_tariffe",DATA.my_id,phone_no)
		if pay_ret ~= 0 then
			-- D.act_lock = false
			-- return {result=pay_ret}
			print("error : pay_phone_tariffe " .. pay_ret)
		end

	end

	D.act_lock = false
	return_msg.result=ret
	return return_msg
end


-- 在充值界面中购买物品：消耗钻石，购买 鲸币/记牌器
function REQUEST.pay_exchange_goods(self)

	-- 产生一个唯一 id 作为订单号（日志用）
	local _log_id = skynet.generate_uuid()
	local _log_type
	local _cfg_row
	local _asset_change = {}

	if D.act_lock then
		return_msg.result=1008
		return return_msg
	end

	D.act_lock = true

	PUBLIC.update_shoping_config()

	D.act_lock = false

	if type(self.goods_type) ~= "string" or not tonumber(self.goods_id) then
		return_msg.result=1001
		return return_msg 
	end

	local gt = D.shoping_config[self.goods_type]

	if not gt then
		return_msg.result=1001
		return return_msg 
	end

	_cfg_row = gt[self.goods_id]
	if not _cfg_row then
		return_msg.result=1001
		return return_msg
	end


	if (D.asset_datas[_cfg_row.use_type] or 0) < _cfg_row.use_count then
		return_msg.result=D.asset_type_error_enum_map[_cfg_row.use_type] or 2401
		return return_msg
	end

	_log_type = "pay_exchange_" .. self.goods_type

	if basefunc.is_asset(self.goods_type) then

		_asset_change[#_asset_change + 1] = {
			asset_type = self.goods_type,
			value = _cfg_row.num,
		}

	else

		return_msg.result=1001
		return return_msg

	end

	_asset_change[#_asset_change + 1] = {
		asset_type=_cfg_row.use_type,
		value=-_cfg_row.use_count
	}

	-- 处理赠送 都走邮件
	if _cfg_row.gift_asset_type then
		for i,_asset_type in ipairs(_cfg_row.gift_asset_type) do
			if not basefunc.is_asset(_asset_type) then
				-- return_msg.result=2401
				-- return return_msg
				print("REQUEST.pay_exchange_goods _cfg_row.gift_asset_type error:",_asset_type)
			else

				_asset_change[#_asset_change + 1] = {
					asset_type=_asset_type,
					value=_cfg_row.gift_asset_count[i]
				}

			end
		end
	end

	-- 修改财务
	CMD.change_asset_multi(_asset_change,_log_type,_log_id)

	return_msg.result=0
	return return_msg
end


-- 购买表情 抽宝箱
function REQUEST.pay_lottery(self)

	if self.type~="expression_666" and self.type~="expression_shuitong" then
		return_msg.result=1001
		return return_msg
	end

	if type(self.time)~="number" then
		return_msg.result=1001
		return return_msg
	end

	if D.act_lock then 
		return_msg.result=1008
		return return_msg
	end

	D.act_lock = true

	PUBLIC.update_shoping_config()

	local _cfg_row = nil
	--支付费用
	local _asset_type
	local _change_value
	if self.type=="expression_666" then

		for _good_id,d in pairs(D.shoping_config.expression) do
			if d.group == "expression_666" and d.num == self.time then
				_asset_type = d.use_type
				_change_value = d.use_count
				_cfg_row = d
				break
			end
		end
	
	elseif self.type=="expression_shuitong" then

		for _good_id,d in pairs(D.shoping_config.expression) do
			if d.group == "expression_shuitong" and d.num == self.time then
				_asset_type = d.use_type
				_change_value = d.use_count
				_cfg_row = d
				break
			end
		end

	end

	if not _asset_type or not _change_value then
		D.act_lock = false
		return_msg.result=1002
		return return_msg
	end

	-- 钱不够
	if (D.asset_datas[_asset_type] or 0) < _change_value then
		D.act_lock = false
		return_msg.result=D.asset_type_error_enum_map[_asset_type] or 2401
		return return_msg
	end

	-- 数量限制 (不限制 达到这个条件后 不增加表情了即可)
	local expression_max_num = 9999999
	local dd = PUBLIC.get_dress_data("expression",_cfg_row.item_id)
	if dd and tonumber(dd.num) then
		-- D.act_lock = false
		-- return_msg.result=3905
		-- return return_msg
		expression_max_num = _cfg_row.max - tonumber(dd.num)
	end

	-- 起购限制
	local status = skynet.call(DATA.service_config.lottery_center_service,"lua","check_lottery_status"
											,DATA.my_id
											,self.time
											,CMD.query_asset_by_type(PLAYER_ASSET_TYPES.JING_BI))

	if status ~= 0 then
		D.act_lock = false
		return_msg.result=status
		return return_msg
	end


	CMD.change_asset_multi({[1]={asset_type=_asset_type,value=-_change_value}}
							,ASSET_CHANGE_TYPE.PAY_EXPRESSION_LOTTERY,self.type.."_"..self.time)

	local lottery_data
	if self.type=="expression_666" then
		lottery_data = skynet.call(DATA.service_config.lottery_center_service,"lua","lottery_expression_666"
												,DATA.my_id
												,self.time)

	elseif self.type=="expression_shuitong" then
		lottery_data = skynet.call(DATA.service_config.lottery_center_service,"lua","lottery_expression_shuitong"
												,DATA.my_id
												,self.time)

	end

	local buy_data = {
		dress_data = {
			expression={
				{
					id = _cfg_row.item_id,
					num = self.time,
				}
			}
		},
	}


	--增加资产
	CMD.change_asset_multi(lottery_data.asset_data,ASSET_CHANGE_TYPE.EXPRESSION_LOTTERY_RESULT,self.type.."_"..self.time)

	-- 确实买的装扮
	for i,d in ipairs(buy_data.dress_data.expression) do

		local n = expression_max_num
		if expression_max_num > d.num then
			n = d.num
		else
			if n < 1 then
				break
			end
		end

		--DATA.msg_dispatcher:call("buy_dress"
		--						,"expression"
		--						,d.id
		--						,n
		--						,nil
		--						,"buy")

		PUBLIC.trigger_msg( {name = "buy_dress"} , "expression" , d.id , n , nil , "buy" )

		expression_max_num = expression_max_num - n

	end

	-- 抽奖中的
	for i,d in ipairs(lottery_data.dress_data.expression) do

		local n = expression_max_num
		if expression_max_num > d.num then
			n = d.num
		else
			if n < 1 then
				break
			end
		end

		--DATA.msg_dispatcher:call("buy_dress"
		--						,"expression"
		--						,d.id
		--						,n
		--						,nil
		--						,"lottery")

		PUBLIC.trigger_msg( {name = "buy_dress"} , "expression" , d.id , n , nil , "lottery" )

		expression_max_num = expression_max_num - n

	end

	D.act_lock = false

	return {
		result=0,
		tag = self.tag,
		buy_data = buy_data,
		lottery_data = lottery_data,
	}
end


-- 查询幸运宝箱是否可以抽取
function REQUEST.query_luck_box_lottery_status(self)

	if D.act_lock then 
		return_msg.result=1008
		return return_msg
	end

	D.act_lock = true

	local status = skynet.call(DATA.service_config.lottery_center_service,"lua","query_luck_box_lottery_status"
											,DATA.my_id)

	D.act_lock = false

	return_msg.result=status
	return return_msg

end
-- 查询幸运宝箱数据
function REQUEST.query_luck_box_lottery_data(self)

	if D.act_lock then 
		return_msg.result=1008
		return return_msg
	end
	
	D.act_lock = true

	local pd = skynet.call(DATA.service_config.lottery_center_service,"lua","query_luck_box_lottery_data"
											,DATA.my_id)

	D.act_lock = false

	local nums = {}
	local boxs = {}
	for i,v in ipairs(pd) do
		nums[i] = v.lottery_num
		boxs[i] = v.box
	end

	return {result=0,nums=nums,boxs=boxs}

end
-- 抽幸运宝箱
function REQUEST.pay_lottery_luck_box(self)

	if D.act_lock then 
		return_msg.result=1008
		return return_msg
	end
	
	if type(self.id) ~= "number" then
		return_msg.result=1001
		return return_msg
	end

	D.act_lock = true
	
	local ret = skynet.call(DATA.service_config.lottery_center_service,"lua","lottery_luck_box"
											,DATA.my_id
											,self.id
											,CMD.query_asset_by_type(PLAYER_ASSET_TYPES.JING_BI))
	D.act_lock = false

	if type(ret) == "number" then
		return_msg.result=ret
		return return_msg
	end

	local my_jing_bi = CMD.query_asset_by_type(PLAYER_ASSET_TYPES.JING_BI)

	if my_jing_bi < ret.consume then
		return_msg.result=1023
		return return_msg
	end

	local assets = {}

	assets[#assets + 1] = {
		asset_type = PLAYER_ASSET_TYPES.JING_BI,
		value = -ret.consume
	}

	assets[#assets + 1] = ret.assets
	
	CMD.change_asset_multi(assets,ASSET_CHANGE_TYPE.LOTTERY_LUCK_BOX,self.id)

	return 
	{
		index = ret.index,
		result = 0,
	}

end


-- 开启幸运宝箱
function REQUEST.open_luck_box(self)

	if D.act_lock then 
		return_msg.result=1008
		return return_msg
	end

	if type(self.id) ~= "number" then
		return_msg.result=1001
		return return_msg
	end

	D.act_lock = true

	local ret = skynet.call(DATA.service_config.lottery_center_service,"lua","open_luck_box"
											,DATA.my_id
											,self.id)

	D.act_lock = false

	local status = 1001
	
	if type(ret) == "table" then

		CMD.change_asset_multi(ret,ASSET_CHANGE_TYPE.OPEN_LUCK_BOX,self.id)
		status = 0

	else

		status = ret

	end

	return_msg.result=status
	return return_msg

end

function REQUEST.query_withdraw_cash_status()
	
	local ret = skynet.call(DATA.service_config.asset_service,"lua","query_player_withdraw_cash_status",DATA.my_id,0)
	ret.result = 0
	return ret
end

-- 提现 cash
local withdraw_cash_lock = nil
function REQUEST.withdraw_cash(self)

	if type(self.cash_type) ~= "number" then
		return_msg.result=1001
		return return_msg
	end

	if self.cash_type ~= 1 then
		return_msg.result=1001
		return return_msg
	end

	if withdraw_cash_lock then
		return_msg.result=1008
		return return_msg
	end
	withdraw_cash_lock = true

	local money = math.floor(D.asset_datas[PLAYER_ASSET_TYPES.CASH])

	local ret = skynet.call(DATA.service_config.asset_service,"lua","query_player_withdraw_cash_status",DATA.my_id,money)
	if ret.status ~= 0 then
		withdraw_cash_lock = nil
		return {result=ret.status,value=money}
	end

	-- 使用可以提现的额度进行提现 - 适配到最大能提现的额度
	money = ret.can_withdraw_money

	local ret = PUBLIC.withdraw_money(money,"assets_withdraw_cash")

	if ret.result == 0 then

		-- 先扣钱；如果提现失败 后续要做检查、返还、找客服！
		CMD.change_asset_multi({[1]={asset_type=PLAYER_ASSET_TYPES.CASH,value=-money}}
								,ASSET_CHANGE_TYPE.WITHDRAW,ret.order_id)
		
		skynet.call(DATA.service_config.asset_service,"lua","player_withdraw_cash",DATA.my_id,money)

	end

	withdraw_cash_lock = nil
	return {result=ret.result,value=money}
end


local withdraw_money_lock = nil
-- 提现 现金
function PUBLIC.withdraw_money(_money,_comment)

	if skynet.getcfg("forbid_withdraw_cash") then
		return_msg.result=2403
		return return_msg
	end

	local withdraw_url = skynet.getcfg("withdraw_url")

	if not withdraw_url then
		return_msg.result=2405
		return return_msg
	end

	if withdraw_money_lock then
		return_msg.result=1008
		return return_msg
	end
	withdraw_money_lock = true

	if _money < 100 then
		withdraw_money_lock = nil
		return_msg.result=2264
		return return_msg
	end

	local verify_data = skynet.call(DATA.service_config.data_service,"lua","get_player_verify_data",
											DATA.extend_data.login_id,DATA.login_msg.channel_type)

	if not verify_data or not verify_data.extend_1 then
		withdraw_money_lock = nil
		return_msg.result=2265
		return return_msg
	end

	local openid = verify_data.extend_1
	local order_id,ret = skynet.call(DATA.service_config.data_service,"lua","create_withdraw_id",
											DATA.my_id,"weixin","game",PLAYER_ASSET_TYPES.CASH,openid,_money,_comment)

	if not order_id then
		withdraw_money_lock = nil
		return_msg.result=ret
		return return_msg
	end

	local _url = basefunc.repl_str_var(withdraw_url,{
											withdrawId=order_id
										})

	local ok,content = skynet.call(base.DATA.service_config.webclient_service,"lua",
									"request",_url)
	if not ok then
		withdraw_money_lock = nil
		return_msg.result=2406
		return return_msg
	end

	print(string.format("call withdraw web '%s' result:",DATA.my_id,tostring(_url)),basefunc.tostring(content))

	withdraw_money_lock = nil
	return {result=0,money=_money,order_id=order_id}
end



----------------------------------------------特殊独立道具操作-------------------------------------------------
--[[
	不可折叠，每个道具有独立的属性
	... 跟 change_type change_id change_way change_way_id
]]

function PUBLIC.add_object(_type,_data,...)
	local d = {
		object_type = _type,
		attribute = _data,
	}

	local _obj_data = skynet.call(DATA.service_config.data_service,"lua","change_object",DATA.my_id,d,true,...)

	return _obj_data.object_id
end


function PUBLIC.update_object(_object_id,_data,...)

	local od = DATA.player_data.object_data[_object_id]

	if not od then
		return 1001
	end

	local d = {
		object_id = _object_id,
		object_type = od.object_type,
		attribute = _data,
	}

	skynet.send(DATA.service_config.data_service,"lua","change_object",DATA.my_id,d,true,...)

end

function PUBLIC.delete_object(_object_id,...)

	local od = DATA.player_data.object_data[_object_id]

	if not od then
		return 1001
	end

	local d = {
		object_id = _object_id,
		object_type = od.object_type,
	}

	skynet.send(DATA.service_config.data_service,"lua","change_object",DATA.my_id,d,true,...)

end

----------------------------------------------特殊独立道具操作-------------------------------------------------

function PUBLIC.init_object_data()

	-- 如果道具的有效期过了，就删除道具
	
	for object_id,d in pairs(DATA.player_data.object_data) do
		
		if d.attribute 
			and tonumber(d.attribute.valid_time)
			and tonumber(d.attribute.valid_time) < os.time() then

				PUBLIC.delete_object(object_id,"overdue")
				DATA.player_data.object_data[object_id] = nil
		else

			D.player_object_id[d.object_type] = object_id
			D.player_object_num[d.object_type] = (D.player_object_num[d.object_type] or 0) + 1
		end

	end

end
