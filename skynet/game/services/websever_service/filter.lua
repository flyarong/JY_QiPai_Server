--
-- Created by lyx.
-- User: hare
-- Date: 2018/6/4
-- Time: 1:47
-- 过滤器
--

local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

-- 处理器定义
local handles = 
{
    test = "game/services/websever_service/test/api_test.lua",
    sczd = "game/services/websever_service/sczd/handle.lua",
    manage = "game/services/websever_service/manage/handle.lua",
}

-- 处理器 缓存 ： name => {handle=,load_time=}
local handles_cache = {}

local PROTECTED = {}

-- 处理请求
-- 返回 handled + code + 内容
-- handled 为 true 表示已 处理
function PROTECTED.handle(path,host,request,web_filereader)

    local dir_names = basefunc.string.split(path,"/")
    while dir_names[1] == "" do
        table.remove(dir_names,1)
    end

    local _name = dir_names[1]

    if not _name then
        return false
    end

    local _cache = handles_cache[_name] or {}
    handles_cache[_name] = _cache
    if not _cache.handle or os.time() - _cache.load_time > 5 then -- 5 秒过期
        if handles[_name] then
            _cache.handle = basefunc.path.reload_lua(handles[_name])
            _cache.load_time = os.time()
        else
            return false
        end
    end

    return _cache.handle(dir_names,path,host,request,web_filereader)
end

return PROTECTED