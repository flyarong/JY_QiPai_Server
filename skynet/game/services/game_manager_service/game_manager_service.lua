--
-- Author: lyx
-- Date: 2018/7/9
-- Time: 
-- 说明：游戏中心服务器，处理需要统一管理的数据，例如 重新加载配置
--

local skynet = require "skynet_plus"
require "skynet.manager"
local cluster = require "skynet.cluster"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

-- 服务配置
DATA.service_config = nil

-- 每款游戏的中心服务集合
DATA.game_center_sevices = {}

function CMD.register_game(_name,_service_name)
	print("game manager register:",_name,_service_name)
	DATA.game_center_sevices[_name] = {name=_name,service_name=_service_name}
end

function PUBLIC.try_stop_service(_count,_time)
	return "free"
end


function CMD.start(_service_config)
	
	DATA.service_config=_service_config
end

-- 得到游戏中心的集合
function CMD.get_game_center_services()
	return DATA.game_center_sevices
end

-- 返回一个表： service name=>错误号
function CMD.reload_config()

	local services_ret = {}

	for _name,_data in pairs(DATA.game_center_sevices) do
		
		local ok,ret = pcall(function()
			return skynet.call(DATA.service_config[_data.service_name],"lua","reload_config")
		end)

		if ok then
			if 0 == ret then
				services_ret[_name] = 0
			else
				if tonumber(ret) then
					services_ret[_name] = tonumber(ret)
					print(string.format("game '%s' reload config fail,code:%s !",_name,tostring(ret)))
				else
					services_ret[_name] = 2402
					print(string.format("game '%s' reload config error:%s!",_name,ret))
				end
			end
		else
			services_ret[_name] = 2402
			print(string.format("game '%s' reload config error:%s!",_name,ret))
		end


	end

	return services_ret
end

-- 启动服务
base.start_service()