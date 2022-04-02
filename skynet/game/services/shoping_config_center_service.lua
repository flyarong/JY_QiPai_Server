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

DATA.shoping_config = {}

DATA.version = 0

local return_msg={result=0}


local function load_config(_raw_config)

	DATA.shoping_config = basefunc.deepcopy(_raw_config)
	DATA.version = os.time()

	-- 推送到指定服务
	-- pay_service
	-- data_service

	skynet.send(DATA.service_config.data_service,"lua","update_shoping_config",
						DATA.shoping_config,
						DATA.version)

	skynet.send(DATA.service_config.pay_service,"lua","update_shoping_config",
						DATA.shoping_config,
						DATA.version)

end


-- 
function CMD.get_config(_version)

	if _version == DATA.version then
		return nil
	end

	return DATA.shoping_config,DATA.version

end


function CMD.start(_service_config)

	DATA.service_config = _service_config

	nodefunc.query_global_config("shoping_config",load_config)

end

-- 启动服务
base.start_service()
