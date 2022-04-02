--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：测试
-- 使用方法：
--  call <service addr> exe_file "hotfix/fixtest.lua"
-- call redeem_code_center_service exe_file "hotfix/fix_redeem_code.lua"

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"
require "normal_enum"

local cjson = require "cjson"
cjson.encode_sparse_array(true,1,0)

local DATA = base.DATA
local CMD = base.CMD
local PUBLIC=base.PUBLIC


local code_data_num = 0
local content_num = 0

local function fix_data()

	-- 获取码的数据
	local code_data = skynet.call(DATA.service_config.data_service,"lua","query_redeem_code_data")
	for i,v in ipairs(code_data) do
		
		local rcd = DATA.redeem_code_data[v.code_type] or {}
		DATA.redeem_code_data[v.code_type] = rcd

		rcd[v.code_sub_type] = v

		v.id = nil
		v.use_args = cjson.decode(v.use_args)
		v.assets = cjson.decode(v.assets)

		code_data_num = code_data_num + 1
	end


	local content = skynet.call(DATA.service_config.data_service,"lua","query_redeem_code_content")
	for i,v in ipairs(content) do
		
		local cc = DATA.redeem_code_content[v.code_type] or {}
		DATA.redeem_code_content[v.code_type] = cc

		local cst = cc[v.code_sub_type] or {}
		cc[v.code_sub_type] = cst

		cst[v.key_code] = {used_count=v.used_count}

		content_num = content_num + 1
	end

	dump(DATA.redeem_code_data,"DATA.redeem_code_data+++++++++")
	dump(DATA.redeem_code_content,"DATA.redeem_code_content+++++++++++++")

end


return function()

	fix_data()

	return " ok " .. code_data_num .. "|" .. content_num

end