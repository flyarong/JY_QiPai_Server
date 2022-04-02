--
-- Created by lyx.
-- User: hare
-- Date: 2018/6/4
-- Time: 1:47
-- test 过滤器
--

local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

-- 返回 code
local function encode_code(code)
    return string.format("{\"result\":\"%s\"}",tostring(code))
end
-- 返回 value 或 nil,code
local function encode_value_code(value,code)
    if value then
        return cjson.encode({value=value,result = "0"})
    else
        return string.format("{\"result\":\"%s\"}",tostring(code))
    end    
end
-- 返回 table 或 nil,code
local function encode_data_code(data,code)
    if data then
        data.result = data.result or "0" -- 如果 有，则保持原样
        return cjson.encode(data)
    else
        return string.format("{\"result\":\"%s\"}",tostring(code))
    end    
end

-----------------------------------------------------------
-- 处理器函数

local handles = 
{
    -- 添加高级合伙人测试数据
    gjhhr_test_data = require("websever_service.test.gjhhr_test_data"),

    
}

-- 测试登录
function handles.test_weixin_login(host,get,post,request)

	-- 按 robot 方式登录（以后 可以增加 或改成 专门的登录方式，例如 "tuoguan"）
	local login_data = {
        wechat_test=true, -- 测试登录
		channel_type="wechat",
        login_id=get.union_id,
        nickname = get.nickname or "测试用户",
        headimgurl = get.headimgurl,
        sex=get.sex,
		channel_args=nil,
		device_os="[web test service] linux",
		device_id="[web test service] hehehe hahaha  test",
	}
    
    return skynet.call(host.service_config.login_service,"lua","client_login",login_data,nil,"<web test service>")
end

-- 测试扫码 绑定
function handles.weixin_scan_bind(host,get,post,request)
    
    local data,code = skynet.call(host.service_config.sczd_center_service,"lua","wechat_create_player",get.weixinUnionId)
    if not data then
        return code 
    end

    code = skynet.call(host.service_config.sczd_center_service,"lua","init_bind_parent",data.userId,get.parent_id)

    return {user_data=data,bind_result=code}
end

-----------------------------------------------------------

return function (dir_names,path,host,request,web_filereader)

    local _fname = dir_names[2]

    local _handle = handles[_fname]
    if not _handle then
        return true,404,"test func handle not found:" .. tostring(_fname)
    end

    local ok,_ret = xpcall(_handle,basefunc.error_handle,host,request.get,request.post,request)

    if ok then
        return true,200,_ret and cjson.encode(_ret) or "null"
    else
        return true,500,"test api call error:" .. tostring(code)
    end

end
