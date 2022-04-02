
local skynet = require "skynet_plus"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"

require "normal_enum"

require "printfunc"

local DATA = base.DATA
local CMD = base.CMD
local PUBLIC=base.PUBLIC

DATA.service_config = nil

local glory_config = {}


local function load_config(_raw_config)

	local raw_config = basefunc.deepcopy(_raw_config)
	
	glory_config = {}

	glory_config.glory_data={}
	for i,d in ipairs(raw_config.glory_data) do
		glory_config.glory_data[d.level] = d
	end

	local aws = {}
	for i,ad in ipairs(raw_config.award_data) do
		
		aws[ad.level] = aws[ad.level] or {}
		local len = #aws[ad.level]+1
		aws[ad.level][len] = {
			asset_type = ad.asset_type,
			value = ad.asset_count,
		}
	end

	glory_config.award_data = aws

	local dress_data = {}
	for i,d in ipairs(raw_config.dress_data) do
		dress_data[d.level]=d
	end
	glory_config.dress_data = dress_data

	local score_k = {}
	for i,d in ipairs(raw_config.score_k) do
		score_k[d.game_id]={add=d.add,dec=d.dec}
	end
	glory_config.score_k = score_k

	-- print("glory_config-------*-*-*-*-*:",basefunc.tostring(glory_config,10))
end


-- 不缓存 从数据库缓存拿
function CMD.query_player_glory_data(_player_id)

	return skynet.call(DATA.service_config.data_service,"lua","query_player_glory_data",_player_id)

end


-- 
function CMD.get_config()

	return glory_config

end


function CMD.start(_service_config)

	DATA.service_config = _service_config

	nodefunc.query_global_config("glory_server",load_config)

end

-- 启动服务
base.start_service()
