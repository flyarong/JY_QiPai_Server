--
-- Author: hw
-- Date: 2018/5/8
-- Time: 
-- 说明：兑物券激活码管理中心服务
-- dwq_cdkey_mgr_center_service

local skynet = require "skynet_plus"
require "skynet.manager"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local ascii={'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',}

--兑换码列表
local dwq_cdkey_map

--参赛
--function CMD.get_dwq_cdkey(_asset_type,_player_id)
--	while true do
--		local _cdkey=""
--		for i=1,16 then
--			local _c=math.random(1,#ascii)
--			_cdkey=_cdkey.._c
--		end
--		if not dwq_cdkey_map[_cdkey] then
--			dwq_cdkey_map[_cdkey]={asset_type=_asset_type,player_id=_player_id,time=os.time(),cdkey=_cdkey}
--			--写入数据库
--			skynet.send(DATA.service_config.data_service,"lua","add_cdkey",dwq_cdkey_map[_cdkey])
--			return _cdkey
--		end
--	end
--end
function CMD.use_dwq_cdkey(_cdkey,_use_id,_type)
	if not _cdkey or not _use_id then
		return 1001
	end
	_type=_type or 1 
	if dwq_cdkey_map[_cdkey] then
		local _data=dwq_cdkey_map[_cdkey]
		dwq_cdkey_map[_cdkey]=nil
		skynet.send(DATA.service_config.data_service,"lua","use_cdkey",_data.cdkey,_use_id,os.time(),_type)
		return 0
	end
	--激活码错误 
	--###_test
	return 1001
end
local reset_randomseed=0
--超时检测（超过一个小时不使用则释放）
function PUBLIC.overtime_check()
	local _time=os.time()
	for _,_v in pairs(dwq_cdkey_map) do
		if _time-_v.time>3600 then
			CMD.use_dwq_cdkey(_v.cdkey,_v.player_id,2)
		end
	end
	reset_randomseed=reset_randomseed+1
	if reset_randomseed>2 then
		math.randomseed(os.time()*68457)
		reset_randomseed=0
	end
end

local function init_data()
	dwq_cdkey_map=skynet.call(DATA.service_config.data_service,"lua","query_all_cdkey")
end

function CMD.start(_service_config)

	math.randomseed(os.time()*53731)

	DATA.service_config=_service_config

	DATA.my_id="dwq_cdkey_mgr_center_service"

	init_data()

	skynet.timer(3600,PUBLIC.overtime_check)

end


-- 启动服务
base.start_service()