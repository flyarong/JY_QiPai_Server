--
-- Created by lyx.
-- User: hare
-- Date: 2018/11/6
-- Time: 14:59
-- 装扮管理器
--

local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local task_initer = require "task.init"

local DATA = base.DATA
local CMD = base.CMD
local REQUEST = base.REQUEST
local PUBLIC = base.PUBLIC
local PROTECT = {}

local MSG = {}

local dress_config = {}

local return_msg={result=0}

local dress_id_to_data_hash = {}

local dress_free_data = {}

--装扮的类型
local dress_type = {
	"head_frame",
	"expression",
	"phrase",
}

local function load_data()
	
	DATA.player_data.dress_data = {}

	local dressed_data = skynet.call(DATA.service_config.data_service,"lua","query_player_dressed_data",DATA.my_id)
	local dress_info_data = skynet.call(DATA.service_config.data_service,"lua","query_player_dress_info_data",DATA.my_id)
	dress_free_data = skynet.call(DATA.service_config.data_service,"lua","query_player_dress_free_data")

	DATA.player_data.dress_data.dressed_head_frame = dressed_data.dressed_head_frame

	--初始化表
	for i,t in ipairs(dress_type) do
		DATA.player_data.dress_data[t] = {}
		dress_id_to_data_hash[t] = {}
	end

	for dt,did in pairs(dress_info_data) do
		DATA.player_data.dress_data[dt] = DATA.player_data.dress_data[dt] or {}
		local dd = DATA.player_data.dress_data[dt]
		
		for di,d in pairs(did) do

			local num = d.num>=0 and d.num or nil
			local time = nil
			if d.time>=0 then
				time = math.max(d.time - os.time(),0)
			end

			dd[#dd+1] = {
				id = di,
				num = num,
				time = time,
				rtime = d.time>0 and d.time or nil,
			}

			dress_id_to_data_hash[dt] = dress_id_to_data_hash[dt] or {}
			dress_id_to_data_hash[dt][di] = #dd

		end

	end

	-- dump(DATA.player_data.dress_data,"DATA.player_data.dress_data--------------------*-*-*-")
end


-- 装扮数据变化
local function change_dress_data(_type,_id,_num,_time,_change_type)

	_id = tonumber(_id)
	
	local dd = DATA.player_data.dress_data[_type]
	if not dd then
		return
	end

	local cd = nil

	local index = dress_id_to_data_hash[_type][_id]
	if index then
		
		local d = dd[index]
		if _num and d.num and d.num >= 0 then
			d.num = math.max(d.num + _num,0)
		end
		if _time and d.time and d.time >= 0 then
			d.rtime = d.rtime + _time
			d.time = math.max(d.rtime - os.time(),0)
		end
		cd = d

	else

		dd[#dd+1]={
			id = _id,
			num = _num,
			time = _time,
			rtime = _time and os.time() + _time or nil,
		}
		cd = dd[#dd]
		dress_id_to_data_hash[_type][_id] = #dd

	end

	skynet.send(DATA.service_config.data_service,"lua","insert_player_dress_info_log"
					,DATA.my_id
					,_type
					,_id
					,_num or 0
					,_time or 0
					,_change_type)

	skynet.send(DATA.service_config.data_service,"lua","update_player_dress_info_data"
					,DATA.my_id
					,_type
					,_id
					,cd.num or -1
					,cd.rtime)

end


--- 
function REQUEST.dressed_head_frame(self)

	if type(self.id)~="number" or self.id < 1  then
		return_msg.result=1001
		return return_msg
	end

	local ok = false

	if not dress_free_data[self.id] then
		
		local index = dress_id_to_data_hash["head_frame"][self.id]

		if not index then
			return_msg.result=3901
			return return_msg
		end

	end

	DATA.player_data.dress_data.dressed_head_frame = self.id

	skynet.send(DATA.service_config.data_service,"lua","update_player_dressed_data"
					,DATA.my_id,self.id)

	return_msg.result=0
	return return_msg

end


function REQUEST.query_dress_data(self)

	return {dress_data=DATA.player_data.dress_data,result=0}

end

-- 获取一个装扮的数据
function PUBLIC.get_dress_data(_type,_id)

	_id = tonumber(_id)

	local dd = DATA.player_data.dress_data[_type]
	if not dd then
		return
	end

	local index = dress_id_to_data_hash[_type][_id]
	return dd[index]

end


-- 使用一个装扮
function PUBLIC.use_dress(_id)
	_id = tonumber(_id)

	if skynet.getcfg("tuoguan_interaction_always") and not basefunc.chk_player_is_real(DATA.my_id) then
		return 0
	end

	-- 免费使用
	if dress_free_data[_id] then
		return 0
	end

	local _type = "expression"
	local dd = PUBLIC.get_dress_data(_type,_id)

	if not dd then
		_type = "phrase"
		dd = PUBLIC.get_dress_data(_type,_id)
	end

	if not dd then
		return 3902
	end

	-- 时间暂时不判定
	if dd.num == 0 then
		return 3903
	elseif dd.num == nil then
		return 0
	end


	change_dress_data(_type,_id,-1,nil,"use_dress")

	dd = PUBLIC.get_dress_data(_type,_id)

	--推送单条消息
	PUBLIC.request_client("notify_dress_item_change_msg",
		{
			dress_type = _type,
			dress_id = _id,
			dress_num = dd.num,
			dress_time = nil,
			change_type = "use_dress",
		})

	return 0
end




-- 装扮数据变化推送
function PUBLIC.notify_dress_change_msg(_type)
	PUBLIC.request_client("notify_dress_change_msg",{dress_data=DATA.player_data.dress_data,type=_type})
end


-- 新增无限装扮数据 [荣耀等级提升|VIP状态变化...]
local function add_nl_dress_data(_change_type,_head_frames,_expressions,_phrases)
	
	if _head_frames then
		for i,id in ipairs(_head_frames) do
			change_dress_data("head_frame",id,nil,nil,_change_type)
		end
	end

	if _expressions then
		for i,id in ipairs(_expressions) do
			change_dress_data("expression",id,nil,nil,_change_type)
		end
	end

	if _phrases then
		for i,id in ipairs(_phrases) do
			change_dress_data("phrase",id,nil,nil,_change_type)
		end
	end

	PUBLIC.notify_dress_change_msg(_change_type)
end



function MSG.glory_promoted_dress(_,_head_frames,_expressions,_phrases)
	add_nl_dress_data("glory_promoted",_head_frames,_expressions,_phrases)
end


function MSG.become_vip_dress(_,_head_frames,_expressions,_phrases)
	add_nl_dress_data("become_vip",_head_frames,_expressions,_phrases)
end


function MSG.buy_dress(_,_type,_id,_num,_time,_buy_type)
	change_dress_data(_type,tonumber(_id),_num,_time,_buy_type)
	PUBLIC.notify_dress_change_msg(_buy_type)
end


function PROTECT.init()
	load_data()

	DATA.msg_dispatcher:register(MSG,MSG)

end

return PROTECT