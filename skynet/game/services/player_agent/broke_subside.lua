--
-- Author: yy
-- Date: 2018/4/14
-- Time: 15:14
-- 说明：破产补助
--


local skynet = require "skynet_plus"
local base = require "base"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "normal_enum"
require"printfunc"


local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC
local REQUEST=base.REQUEST

local return_msg={result=0}

----------------------------------------------分享奖励-------------------------------------------------


----------------------------------------------破产奖励-------------------------------------------------

DATA.broke_subside_data = DATA.broke_subside_data or 
{	
	limit = 10000,      -- 能领取的限制

	-- 默认配置
	broke_subsidy_cfg =
	{
		-- 要分享才能获取
		share=
		{
			{num = 1,award = 6000},
		},

		-- 不分享就能获取
		free=
		{
			{num = 1,award = 3000},
		},
	},

	-- 新手配置： 从首次登录开始，每天一个，共 3 天
	broke_subsidy_xinshou_cfg = 
	{
		-- 第一天
		{
			-- 要分享才能获取
			share=
			{
				{award = 6000},
			},

			-- 不分享就能获取
			free=
			{
				{award = 3000},
				{award = 3000},
				{award = 3000},
			},
		},
		-- 第二天
		{
			-- 要分享才能获取
			share=
			{
				{award = 6000},
			},

			-- 不分享就能获取
			free=
			{
				{award = 3000},
				{award = 3000},
				{award = 3000},
			},
		},
		-- 第三天
		{
			-- 要分享才能获取
			share=
			{
				{award = 6000},
			},

			-- 不分享就能获取
			free=
			{
				{award = 3000},
				{award = 3000},
			},
		},
	},
    
    broke_subsidy_data = nil,
}
local D = DATA.broke_subside_data

function PUBLIC.prepare_subsidy_data()

	if not D.broke_subsidy_data then
		D.broke_subsidy_data = skynet.call(DATA.service_config.data_service,"lua","query_broke_subsidy_data",DATA.my_id)
	end

end

function PUBLIC.get_subsidy_data(_broke_subsidy_data,_type)


	if _type == "share" then
		return _broke_subsidy_data.num,_broke_subsidy_data.time
	else
		return _broke_subsidy_data.free_num,_broke_subsidy_data.free_time
	end
end

local function get_time()
	return tonumber(skynet.getcfg("xinshou_mock_time")) or os.time()
end


function PUBLIC.update_subsidy_data(_broke_subsidy_data,_type,_num,_time)
	if _type == "share" then
		_broke_subsidy_data.num = _num
		_broke_subsidy_data.time = _time
	else
		_broke_subsidy_data.free_num = _num
		_broke_subsidy_data.free_time = _time
	end

	skynet.send(DATA.service_config.data_service,"lua","update_broke_subsidy_data",DATA.my_id,_broke_subsidy_data)	
end

-- 得到今天已经领取的次数
function PUBLIC.get_today_subsidy_num(_broke_subsidy_data,_type)

	local _num,_time = PUBLIC.get_subsidy_data(_broke_subsidy_data,_type)

	if basefunc.day_diff(_time,get_time()) == 0 then
		return _num
	else
		return 0
	end
end

-- 得到今天应该领取的次数（从配置中取）
function PUBLIC.get_today_subsidy_num_cfg(_broke_subsidy_data,_type)

	local _day_index = basefunc.day_diff(_broke_subsidy_data.start_time,get_time()) + 1
	local _cfg = D.broke_subsidy_xinshou_cfg[_day_index] or D.broke_subsidy_cfg

	return _cfg and _cfg[_type] and #_cfg[_type] or 0
end

-- 递增领取次数，并更新时间
function  PUBLIC.inc_subsidy_num(_broke_subsidy_data,_type)

	local _num,_time = PUBLIC.get_subsidy_data(_broke_subsidy_data,_type)

	if basefunc.day_diff(_time,get_time()) == 0 then
		_num = _num + 1
	else
		_num = 1
	end

	PUBLIC.update_subsidy_data(_broke_subsidy_data,_type,_num,get_time())
end


-- 得到救助参数。 _type : "share"/"free"
-- 返回 ： nil 或 奖励数据
function PUBLIC.get_subsidy_cfg(_broke_subsidy_data,_type)
	
	local _num = PUBLIC.get_today_subsidy_num(_broke_subsidy_data,_type)

	local _day_index = basefunc.day_diff(_broke_subsidy_data.start_time,get_time()) + 1

	-- 取某天的配置，没有 就取默认的
	local _cfg = D.broke_subsidy_xinshou_cfg[_day_index] or D.broke_subsidy_cfg

	if _cfg and _cfg[_type] then
		return _cfg[_type][_num + 1]
	else
		return nil,0
	end
end

--破产补助
function REQUEST.broke_subsidy(self)

	if act_lock then
		return_msg.result=1008
		return return_msg
	end
	act_lock = true

	-- by lyx

	if CMD.query_asset_by_type(PLAYER_ASSET_TYPES.JING_BI) >= D.limit then
		act_lock = nil
		return_msg.result=4202
		return return_msg
	end

	PUBLIC.prepare_subsidy_data()
	local _cfg = PUBLIC.get_subsidy_cfg(D.broke_subsidy_data,"share")
	if not _cfg then
		act_lock = nil
		return_msg.result=4201
		return return_msg
	end

	PUBLIC.inc_subsidy_num(D.broke_subsidy_data,"share")

	print("broke_subsidy:",DATA.my_id,_cfg.award)

	local cur_date = tonumber(os.date("%Y%m%d"))

	CMD.change_asset_multi({[1]={asset_type=PLAYER_ASSET_TYPES.JING_BI,value=_cfg.award}}
							,ASSET_CHANGE_TYPE.BROKE_SUBSIDY,cur_date)

	act_lock = nil

	return_msg.result=0
	return return_msg
end

function REQUEST.query_broke_subsidy_num(self)

	-- by lyx
	PUBLIC.prepare_subsidy_data()
	local _num_cfg = PUBLIC.get_today_subsidy_num_cfg(D.broke_subsidy_data,"share")
	local _num = PUBLIC.get_today_subsidy_num(D.broke_subsidy_data,"share")
	print("query_broke_subsidy_num:",DATA.my_id,_num_cfg,_num)
	return {result=0,num=_num_cfg-_num}
end


--免费的直接领取的破产补助
function REQUEST.free_broke_subsidy(self)

	if act_lock then
		return_msg.result=1008
		return return_msg
	end
	act_lock = true

	-- by lyx

	if CMD.query_asset_by_type(PLAYER_ASSET_TYPES.JING_BI) >= D.limit then
		act_lock = nil
		return_msg.result=4202
		return return_msg
	end

	PUBLIC.prepare_subsidy_data()
	local _cfg = PUBLIC.get_subsidy_cfg(D.broke_subsidy_data,"free")
	if not _cfg then
		act_lock = nil
		return_msg.result=4201
		return return_msg
	end

	PUBLIC.inc_subsidy_num(D.broke_subsidy_data,"free")

	local cur_date = tonumber(os.date("%Y%m%d"))

	print("free_broke_subsidy:",DATA.my_id,_cfg.award)

	CMD.change_asset_multi({[1]={asset_type=PLAYER_ASSET_TYPES.JING_BI,value=_cfg.award}}
							,ASSET_CHANGE_TYPE.FREE_BROKE_SUBSIDY,cur_date)

	act_lock = nil

	return_msg.result=0
	return return_msg
end

function REQUEST.query_free_broke_subsidy_num(self)

	-- by lyx
	PUBLIC.prepare_subsidy_data()
	local _num_cfg = PUBLIC.get_today_subsidy_num_cfg(D.broke_subsidy_data,"free")
	local _num = PUBLIC.get_today_subsidy_num(D.broke_subsidy_data,"free")
	print("query_free_broke_subsidy_num:",DATA.my_id,_num_cfg,_num)
	return {result=0,num=_num_cfg-_num}
end

----------------------------------------------破产奖励-------------------------------------------------


