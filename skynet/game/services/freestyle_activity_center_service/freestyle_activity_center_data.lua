
local skynet = require "skynet_plus"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"

require "normal_enum"
require "printfunc"

local loadstring = rawget(_G, "loadstring") or load

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA


local PROTECT = {}

local activity_player_data = {}

local req_activity_player_data_his = {}


local function get_data_key(_game_id,_activity_id,_index)
	return _game_id.."_".._activity_id.."_".._index
end

--解析邮件数据
local function parse_activity_data(_data)

	local code = "return " .. _data
	local ok, ret = xpcall(function ()
		local data = loadstring(code)()
		if type(data) ~= 'table' then
			data = {}
			print("parse_activity_data error : {}")
		end
		return data
	end
	,function (err)
		print("parse_activity_data error : ".._data)
		print(err)
	end)

	if not ok then
		ret = {}
	end

	return ret or {},ok
end



function PROTECT.init()

	local data = skynet.call(DATA.service_config.data_service,"lua","query_freestyle_activity_all_player_data")
	for i,d in ipairs(data) do
		
		local gpd = activity_player_data[d.game_id] or {}
		activity_player_data[d.game_id] = gpd

		local gpad = gpd[d.activity_id] or {}
		gpd[d.activity_id] = gpad

		local gpadi = gpad[d.index] or {}
		gpad[d.index] = gpadi

		gpadi[d.player_id] = parse_activity_data(d.data)

		req_activity_player_data_his[get_data_key(d.game_id,d.activity_id,d.index)]={
			game_id = d.game_id,
			activity_id = d.activity_id,
			index = d.index,
		}

	end

end


--[[所有服务都已经请求完数据了 开始清理本服务上的缓存 和 清理没用的数据
	(其他子服务查询以后自己保存这个数据,避免多处存储同一个数据)
]] 
function PROTECT.release_cache()

	skynet.timeout(10000,function ()
			
		activity_player_data = nil

		if req_activity_player_data_his then
			for k,d in pairs(req_activity_player_data_his) do
				PROTECT.delete_data(d.game_id,d.activity_id,d.index)
			end
			req_activity_player_data_his = nil
		end

	end)

end

-- 删除数据
function PROTECT.delete_data(_game_id,_activity_id,_index)

	skynet.send(DATA.service_config.data_service,"lua","delete_freestyle_activity_player_data",{
		game_id = _game_id,
		activity_id = _activity_id,
		index = _index,
		})

end

-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------


function CMD.query_freestyle_activity_player_data(_game_id,_activity_id,_index)
	
	if req_activity_player_data_his then
		req_activity_player_data_his[get_data_key(_game_id,_activity_id,_index)]=nil
	end

	if activity_player_data then
		local gpd = activity_player_data[_game_id]
		if gpd then
			local gpad = gpd[_activity_id]
			if gpad then
				return gpad[_index]
			end
		end
	end

end


function CMD.update_freestyle_activity_player_data(_player_id,_game_id,_activity_id,_index,_data)

	skynet.send(DATA.service_config.data_service,"lua","update_freestyle_activity_player_data",{
		player_id = _player_id,
		game_id = _game_id,
		activity_id = _activity_id,
		index = _index,
		data = basefunc.safe_serialize(_data),
		})

end


-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------




return PROTECT