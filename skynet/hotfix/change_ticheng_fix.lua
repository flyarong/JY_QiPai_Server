--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：修复 get_player_openid  的问题
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"
require "normal_enum"


require "printfunc"

local DATA = base.DATA
local CMD = base.CMD
local PUBLIC=base.PUBLIC

return function()

	local tc_data={
		['1076418']=594045,
		['109221']=572454,
		['108629']=176184,
		['1020282']=166944,
		['1016865']=101759,
		['1019250']=91812,
		['1019261']=75824,
		['101868259']=59268,
		['102089130']=48003,
		['102438585']=43584,
		['1044281']=36984,
		['1019500']=31788,
		['102301137']=24235,
		['10795214']=22375,
		['105801']=21403,
		['10104338']=19020,
		['1036347']=18973,
		['1024412']=18223,
		['1011721']=17723,
		['102077092']=12588,
	}
	local kouchu_flag={}

	for id,v in pairs(tc_data) do
		-- local ps=skynet.call(DATA.service_config.sczd_center_service,"lua","query_all_parents" ,id)
		-- if ps and type(ps)=='table' then
		-- 	for _,p_id in ipairs(ps) do
		-- 		if DATA.gjhhr_data[p_id] and tc_data[p_id] then
		-- 			tc_data[p_id]=tc_data[p_id]-v
		-- 		end
		-- 	end
		-- end
		-- if DATA.gjhhr_data[id].parent_gjhhr and tc_data[DATA.gjhhr_data[id].parent_gjhhr]  then
		-- 	local k_id=id
		-- 	while k_id and not kouchu_flag[k_id] and tc_data[k_id] do
		-- 		local p_id= DATA.gjhhr_data[k_id].parent_gjhhr
		-- 		if p_id and tc_data[p_id] then
		-- 			tc_data[p_id]=tc_data[p_id]
		-- 		end
		-- 	end 
		-- end
		local ps={}
		local k_id=id
		local time=0
		while k_id and time<100 do
			ps[#ps+1]=k_id
			k_id=DATA.gjhhr_data[k_id].parent_gjhhr
			time=time+1
		end
		local len=#ps
		for i=len,1,-1 do 
			if not kouchu_flag[ps[i]] then
				k_id=ps[i]
				kouchu_flag[k_id]=true
				local p_id=DATA.gjhhr_data[k_id].parent_gjhhr 
				if  p_id then
		 			tc_data[p_id]=tc_data[p_id]-tc_data[k_id]
				end
			end
		end
	end

	return tc_data
end