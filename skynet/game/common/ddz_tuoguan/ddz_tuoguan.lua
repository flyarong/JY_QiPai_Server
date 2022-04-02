local skynet = require "skynet_plus"
local base = require "base"
local basefunc = require "basefunc"
local cp_algorithm=require "ddz_tuoguan.ddz_tuoguan_cp_algorithm"
local landai_util=require "ddz_tuoguan.landai_util"

local ddz_tg_assist_lib = require "ddz_tuoguan.ddz_tg_assist_lib"
local ddz_ai_base_lib = require "ddz_tuoguan.nor_ddz_ai_base_lib"

local nor_ddz_base_lib =require "nor_ddz_base_lib"

local dz_chupai = require "ddz_tuoguan.dz_chupai"
local nm_chupai= require "ddz_tuoguan.nm_chupai"

local tgland = require "tgland.core"
local skynet = require "skynet_plus"

local ddz_tuoguan_think_time=require "ddz_tuoguan.ddz_tuoguan_think_time"

local CMD=base.CMD
local DATA=base.DATA
local PUBLIC=base.PUBLIC

local D = DATA.ddz_nor_data

-- 差牌的情况下是否叫地主
local function bad_pai_dizhu(_wave_status)
	if not DATA.game_info.match_name then
		return false
	end

	local _prop = skynet.getcfg(DATA.game_info.match_name .. "_" .. (_wave_status or "free") ..  "_bad_pai_dizhu")
	return math.random(100) < (tonumber(_prop) or 0)
end

local tclass=basefunc.class()


local TPlayData=basefunc.class()

dump_xx=dump 
--[[
 dump=function()

 end
 --]]


function TPlayData:ctor()

	-- 每个座位的信息
	self.seat_cards={}


	--3张底牌 
	self.left_3cards={}

	--最后一手牌
	self.last_playcards={}

	--最后一个打牌人的位置id 
	self.last_play_seatid=-1

	--我自己的位置
	self.my_seatid=-1

	--地主的位置id 
	self.robland_seatid=-1

	-- 地主 让牌数量
	self.rangpai_num = 0
	self.game_over_cfg = {0,0,0} 

	--天府斗地主 
	self.is_tfddz=false;

	--二人斗地主
	self.is_eren=false;

	-- 出牌次数
	self.cp_count = {0,0,0}

end





--设置最后一个人打牌的位置和牌信息
function TPlayData:do_playcards(seat_id,cards)

	self.last_playcards=cards
	self.last_play_seatid=seat_id

	self.cp_count[seat_id] = (self.cp_count[seat_id] or 0) + 1

	self:remove_seatcards(seat_id,cards)

end

function TPlayData:set_left3cards(cards)
	self.left_3cards=cards
end


function TPlayData:set_is_eren(value)
	self.is_eren=value
end



function TPlayData:set_dzseatid(seat_id,_rangpai_num)

	_rangpai_num=_rangpai_num or 0 

	self.robland_seatid=seat_id

	-- by lyx
	self.rangpai_num = _rangpai_num

	self.game_over_cfg = {}
	for i=1,DATA.seat_count do
		if i == seat_id then
			self.game_over_cfg[i] = 0
		else
			self.game_over_cfg[i] = _rangpai_num
		end
	end	

end

function TPlayData:set_myseatid(seat_id)
	self.my_seatid=seat_id
end


function TPlayData:set_istfddz(value)
	self.is_tfddz=value
end


-- NOTE: for easy to remove ,card use dict here 
function TPlayData:set_seatcards(seat_id,cards)
	self.seat_cards[seat_id]=cards
end

function TPlayData:get_seatcards(seat_id)
	return self.seat_cards[seat_id]
end

function TPlayData:get_seatcards_array(seat_id)

	seat_id = seat_id or self.my_seatid

	local result={}

	for k,v in pairs(self.seat_cards[seat_id]) do 
		local _card = nor_ddz_base_lib.pai_map[k]
		result[_card]=(result[_card] or 0)+1
	end
	return result

end


function TPlayData:add_seatcards(seat_id,cards)
	--[[
	dump(seat_id,"seat_id")
	dump(cards,"cards")
	dump(self.seat_cards,"seat_cards")
	--]]

	for k,v in ipairs(cards) do 
		self.seat_cards[seat_id][v]=true
	end
end



function TPlayData:remove_seatcards(seat_id,cards)
	for k,v in ipairs(cards) do 
		self.seat_cards[seat_id][v]=nil
	end
end


tclass.TPlayData=TPlayData

function tclass.set_game_type(_game_type)
	ddz_tg_assist_lib.set_game_type(_game_type)
end

function tclass.init_data(is_firstplay,tplaydata)

	local data={

		kaiguan  = ddz_tg_assist_lib.data_ddz_cfg.kaiguan,
		limit_cfg=ddz_tg_assist_lib.data_ddz_cfg.limit,
		cp_count = tplaydata.cp_count,

		pai_map={},

		last_pai=D.nor_ddz_algorithm:get_pai_type(tplaydata.last_playcards),
		firstplay= is_firstplay, 

		last_seat=tplaydata.last_play_seatid,
		base_info={
			dz_seat=tplaydata.robland_seatid,
			my_seat=tplaydata.my_seatid,
			seat_type={},
			seat_count=DATA.seat_count
		},
		game_over_cfg=tplaydata.game_over_cfg,

		seat_cards=tplaydata.seat_cards
	}




	-- 处理每个座位
	for i=1,DATA.seat_count do
		-- 牌
		data.pai_map[i] = tplaydata:get_seatcards_array(i)

		data.base_info.seat_type[i] = 0
	end
	if tplaydata.robland_seatid then
		data.base_info.seat_type[tplaydata.robland_seatid] = 1
	end

	return data
end

function tclass.playcards(is_firstplay,tplaydata,_data,debug_test)

	local data=_data or tclass.init_data(is_firstplay,tplaydata)


	local debug_log =false 
	if debug_log  then 

		local debug_data=basefunc.deepcopy(data)
		local pais=debug_data.pai_map


		for k,v in ipairs(debug_data.pai_map) do  
			local ss_cards=landai_util.pai_map2ss(v)
			debug_data.pai_map[k]=ss_cards
		end
		debug_data.firstplay=is_firstplay

		local origin_seat_cards={} 

		for i=1,data.base_info.seat_count do 
			table.insert(origin_seat_cards,data.seat_cards[i])
		end
		debug_data.game_over_cfg=data.game_over_cfg

		debug_data.origin_seat_cards=origin_seat_cards

		dump_xx(debug_data,"data")

		local comment_info={}

		for k,v in ipairs(debug_data.pai_map) do 
			local pai=v 

			if debug_data.base_info.seat_type[k]== 1 then 
				v=v.."[D]"
			end

			if k == debug_data.base_info.my_seat then 
				v=v.."[AC]"
			end

			if not is_firstplay then 
				if k==debug_data.last_seat then 
					v=v.."[L]" 
				end
			end

			table.insert(comment_info,v)
		end
		print("!!!!!@@@@#####")
		print("--".. table.concat(comment_info,"  ,  "))

	end



	cp_algorithm.fenpai_for_all(data)


	local status,cp_type,cp_list,think_time = xpcall(tclass.handle_chupai,basefunc.error_handle,data,is_firstplay,debug_test)

	if skynet.getcfg("ddz_tuoguan_imp_c") then 
		tgland.destroy_query_map(data.query_map)
	end

	if status then 
		return cp_type,cp_list,think_time 
	else 
		--error("handle_chupai error")
		print("handle_chupai error:",cp_type)
	end



end

function tclass.handle_chupai(data,is_firstplay,debug_test)

	local _chu_pai
	local cp_type,cp_list
	cp_type = 0

	for k,v in ipairs(data.fen_pai) do 
		v.abs_xiaojiao=ddz_tg_assist_lib.check_is_xiajiao_absolute(v,k,data.query_map)
	end

	--手上剩余的牌
	data.pai_re_count={}
	for k,v in ipairs(data.pai_map) do
		data.pai_re_count[k]=0
		for _,c in pairs(v) do 
			data.pai_re_count[k]=data.pai_re_count[k]+c
		end
	end
	data.pai_count=data.pai_re_count


	if is_firstplay then 
		local boyi_map,boyi_list=ddz_tg_assist_lib.get_cp_value_map(data,data.base_info.my_seat,nil)
		data.boyi_map=boyi_map 
		data.boyi_list=boyi_list

	else 
		local boyi_map,boyi_list=ddz_tg_assist_lib.get_cp_value_map(data,data.base_info.my_seat,{
			p=data.last_seat ,
			type=data.last_pai.type,
			pai=data.last_pai.pai
		})

		data.boyi_map=boyi_map 
		data.boyi_list=boyi_list
	end


	data.boyi_max_score,data.boyi_min_score=ddz_tg_assist_lib.get_best_cp_score(data.boyi_list)


	local boyi_list_total=#data.boyi_list

	local boyi_list_win=0 
	local boyi_list_lose=0 
	local boyi_list_unkown=0 

	--  ###_test by hewei
	local maxxx=1000
	for k,v in ipairs(data.boyi_list) do
		if v.score<=maxxx then
			maxxx= v.score
		else
			dump(data.boyi_list)
			error("sort error !!!!!")
		end

		if v.score > 0 then 
			boyi_list_win= boyi_list_win +1 

		elseif v.score ==0 then 
			boyi_list_unkown= boyi_list_unkown+1 
		elseif v.score <0 then 
			boyi_list_lose = boyi_list_lose + 1
		end

	end

	data.boyi_list_total = boyi_list_total 
	data.boyi_list_win= boyi_list_win 
	data.boyi_list_lose= boyi_list_lose
	data.boyi_list_unkown= boyi_list_unkown

	local _chu_pai
	if data.base_info.dz_seat==data.base_info.my_seat  then 
		_chu_pai = dz_chupai.dizhu_chupai(is_firstplay,data)
	else 
		_chu_pai = nm_chupai.nongmin_chupai(is_firstplay,data)
	end

	-- dump_xx(_chu_pai,"_chu_pai")

	--dump_xx(_chu_pai,"_chu_pai")
	local think_time=0
	if _chu_pai then
		think_time=ddz_tuoguan_think_time.get_think_time(data,_chu_pai)
	end

	if  debug_test then
		return _chu_pai
	end

	if _chu_pai and _chu_pai.type > 0 then
		cp_type,cp_list = _chu_pai.type,nor_ddz_base_lib.get_cp_list_by_cpData(
		data.seat_cards[data.base_info.my_seat],
		_chu_pai.type,
		_chu_pai.pai)
	end


	return cp_type,cp_list,think_time

end

function tclass.get_nor_ddz_xiaojiao_score_bad_dizhu(data)

	local res=cp_algorithm.fenpai_for_one(data,data.base_info.my_seat)

	local pai_map=data.pai_map[data.base_info.my_seat]

	local boom,wang,er=ddz_tg_assist_lib.get_dingzhu_count(pai_map)

	if boom+wang+er>0 and res.no_xiajiao_socre>-6 then
		if math.random(1,100)<80 then
			return 3
		elseif math.random(1,100)<70 then
			return 2
		else
			return 1
		end
	end

	return 1
end
--更加积极的叫地主
-- function tclass.get_nor_ddz_xiaojiao_score_jiji(is_firstplay,tplaydata)

-- 	local data=tclass.init_data(is_firstplay,tplaydata)

-- 	data.base_info.seat_type[tplaydata.my_seatid] = 1
-- 	data.base_info.dz_seat = tplaydata.my_seatid

-- 	local pai_map=data.pai_map[data.base_info.my_seat]

-- 	local boom,wang,er=ddz_tg_assist_lib.get_dingzhu_count(pai_map)
-- 	if boom+wang+er>3 or boom>3 or (wang+er>0 and boom+wang+er>2) then
-- 		return 3
-- 	end


-- 	local res=cp_algorithm.fenpai_for_one(data,data.base_info.my_seat)


-- 	if boom+wang+er>2 and res.no_xiajiao_socre>-6 then
-- 		if math.random(1,100)<70 then
-- 			return 3
-- 		else
-- 			return 2
-- 		end
-- 	end
-- 	if boom+wang+er>1 and res.no_xiajiao_socre>-6 then
-- 		if math.random(1,100)<50 then
-- 			return 3
-- 		elseif math.random(1,100)<50 then
-- 			return 2
-- 		elseif math.random(1,100)<30 then
-- 			return 1
-- 		end
-- 	end
-- 	if boom+wang+er>0 and res.no_xiajiao_socre>-2 then
-- 		if math.random(1,100)<30 then
-- 			return 3
-- 		elseif math.random(1,100)<40 then
-- 			return 2
-- 		elseif math.random(1,100)<50 then
-- 			return 1
-- 		end
-- 	end

-- 	return 0

-- end

function tclass.get_nor_ddz_xiaojiao_score(is_firstplay,tplaydata,_wave_status)

	local data=tclass.init_data(is_firstplay,tplaydata)
	if data.base_info.dz_seat then
		data.base_info.seat_type[data.base_info.dz_seat] = 0
	end
	data.base_info.seat_type[tplaydata.my_seatid] = 1
	data.base_info.dz_seat = tplaydata.my_seatid

	-- dump(data)


	-- 差牌也叫地主的 处理
	if bad_pai_dizhu(_wave_status) then
		-- print("get_nor_ddz_xiaojiao_score bad dizhu:",DATA.game_info.match_name,_wave_status)
		return tclass.get_nor_ddz_xiaojiao_score_bad_dizhu(data)
	end
	-- print("get_nor_ddz_xiaojiao_score normal:",DATA.game_info.match_name,_wave_status)

	local pai_map=data.pai_map[data.base_info.my_seat]

	-- 差牌也叫地主的 处理
	if bad_pai_dizhu(_wave_status) then
		return tclass.get_nor_ddz_xiaojiao_score_bad_dizhu(data)
	end

	local boom,wang,er=ddz_tg_assist_lib.get_dingzhu_count(pai_map)
	if boom+wang+er>4 or boom>3 then
		return 3
	end


	local res=cp_algorithm.fenpai_for_one(data,data.base_info.my_seat)

	if wang+er>0 and boom+wang+er>2 and (res.xiajiao>0 or res.no_xiajiao_socre>-3) then
		return 3
	end

	if boom+wang+er>2 and res.no_xiajiao_socre>-4 then
		if math.random(1,100)<70 then
			return 3
		else
			return 2
		end
	end
	if boom+wang+er>2 and res.no_xiajiao_socre>-5 then
		if math.random(1,100)<45 then
			return 3
		elseif math.random(1,100)<45 then
			return 2
		elseif math.random(1,100)<30 then
			return 1
		end
	end

	if boom+wang+er>2 and res.no_xiajiao_socre>-6 then
		if math.random(1,100)<30 then
			return 3
		elseif math.random(1,100)<30 then
			return 2
		elseif math.random(1,100)<30 then
			return 1
		end
	end  

	return 0

end

function tclass.get_zhadan_ddz_xiaojiao_score(is_firstplay,tplaydata,_wave_status)
	-- print("zhadanjiaofen")
	-- error("xxxxxxxxxxxx")
	local data=tclass.init_data(is_firstplay,tplaydata)
	if data.base_info.dz_seat then
		data.base_info.seat_type[data.base_info.dz_seat] = 0
	end
	data.base_info.seat_type[tplaydata.my_seatid] = 1
	data.base_info.dz_seat = tplaydata.my_seatid

	-- dump(data)


	-- 差牌也叫地主的 处理
	if bad_pai_dizhu(_wave_status) then
		-- print("get_nor_ddz_xiaojiao_score bad dizhu:",DATA.game_info.match_name,_wave_status)
		return tclass.get_nor_ddz_xiaojiao_score_bad_dizhu(data)
	end
	-- print("get_nor_ddz_xiaojiao_score normal:",DATA.game_info.match_name,_wave_status)

	local pai_map=data.pai_map[data.base_info.my_seat]

	-- 差牌也叫地主的 处理
	if bad_pai_dizhu(_wave_status) then
		return tclass.get_nor_ddz_xiaojiao_score_bad_dizhu(data)
	end

	local boom,wang,er=ddz_tg_assist_lib.get_dingzhu_count(pai_map)

	if boom+wang+er>6 or boom>3 then
		return 3
	end

	local res=cp_algorithm.fenpai_for_one(data,data.base_info.my_seat)

	if boom+wang+er>6 or (boom>2 and res.no_xiajiao_socre>-3) then
		local rd=math.random(1,100)
		if rd<75 then
			return 3
		elseif rd<90 then
			return 2
		else
			return 1
		end
	end

	if boom>1 and boom+wang+er>4 and (res.xiajiao>0 or res.no_xiajiao_socre>-2) then
		local rd=math.random(1,100)
		if rd<45 then
			return 3
		elseif rd<70 then
			return 2
		else
			return 1
		end
	end


	if boom>0 and wang+er>0 and boom+wang+er>3 and (res.xiajiao>0 or res.no_xiajiao_socre>-3) then
		local rd=math.random(1,100)
		if rd<20 then
			return 3
		elseif rd<40 then
			return 2
		elseif rd<70 then
			return 1
		end
	end

	if boom+wang+er>2 and res.no_xiajiao_socre>-4 then
		if math.random(1,100)<50 then
			return 1
		end
	end


	return 0

end

function tclass.get_nor_ddz_qiangdizhu_count_bad_dizhu(data)

	local res=cp_algorithm.fenpai_for_one(data,data.base_info.my_seat)

	local pai_map=data.pai_map[data.base_info.my_seat]

	local boom,wang,er=ddz_tg_assist_lib.get_dingzhu_count(pai_map)

	if boom+wang+er>5 or boom>4 then
		return 2
	end

	if wang+er>1 and boom+wang+er>3 and (res.xiajiao>0 or res.no_xiajiao_socre>-2) then
		return 2
	end

	if boom+wang+er>2 and res.no_xiajiao_socre>-3 then
		if math.random(1,100)<50 then
			return 2
		else
			return 1
		end
	end
	if boom+wang+er>2 and res.no_xiajiao_socre>-5 then
		if math.random(1,100)<45 then
			return 2
		elseif math.random(1,100)<75 then
			return 1
		elseif math.random(1,100)<20 then
			return 0
		end
	end

	if boom+wang+er>2 and res.no_xiajiao_socre>-6 then
		if math.random(1,100)<20 then
			return 2
		elseif math.random(1,100)<30 then
			return 1
		end
	end  

	return 0

end

-- 得到 抢地主次数： 0 , 1 ,2
function tclass.get_nor_ddz_qiangdizhu_count(is_firstplay,tplaydata,_wave_status)

	local data=tclass.init_data(is_firstplay,tplaydata)
	if data.base_info.dz_seat then
		data.base_info.seat_type[data.base_info.dz_seat] = 0
	end
	data.base_info.seat_type[tplaydata.my_seatid] = 1
	data.base_info.dz_seat = tplaydata.my_seatid
	
	local res=cp_algorithm.fenpai_for_one(data,data.base_info.my_seat)
	-- 差牌也叫地主的 处理
	if bad_pai_dizhu(_wave_status) then
		-- print("get_nor_ddz_qiangdizhu_count bad dizhu:",DATA.game_info.match_name,_wave_status)
		return tclass.get_nor_ddz_qiangdizhu_count_bad_dizhu(data)
	end
	-- print("get_nor_ddz_qiangdizhu_count normal :",DATA.game_info.match_name,_wave_status)

	local pai_map=data.pai_map[data.base_info.my_seat]

	local boom,wang,er=ddz_tg_assist_lib.get_dingzhu_count(pai_map)
	if (boom+wang+er>6 and res.no_xiajiao_socre>-3 ) or boom>4 then
		return 2
	end


	if wang+er>1 and boom+wang+er>4 and (res.xiajiao>0 or res.no_xiajiao_socre>-2) then
		if math.random(1,100)<60 then
			return 2
		else
			return 1
		end
	end

	if boom+wang+er>2 and res.no_xiajiao_socre>-2 then
		if math.random(1,100)<50 then
			return 2
		else
			return 1
		end
	end
	if boom+wang+er>2 and res.no_xiajiao_socre>-3 then
		if math.random(1,100)<15 then
			return 2
		elseif math.random(1,100)<40 then
			return 1
		elseif math.random(1,100)<20 then
			return 0
		end
	end

	if boom+wang+er>2 and res.no_xiajiao_socre>-5 then
		if math.random(1,100)<35 then
			return 1
		end
	end  

	return 0

end

return tclass













