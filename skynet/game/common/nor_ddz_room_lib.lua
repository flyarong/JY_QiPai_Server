-- package.path=package.path..";/Users/hewei/project/JyQipai_server/skynet/game/common/?.lua"


local skynet = require "skynet_plus"
local basefunc=require"basefunc"
local nodefunc = require "nodefunc"
require"printfunc"
local nor_ddz_base_lib = require "nor_ddz_base_lib"
local nor_ddz_algorithm_lib = require "nor_ddz_algorithm_lib"

local ddz_create_hp = require "ddz_create_hp"

local ddz_fa_hao_pai = require "ddz_fa_hao_pai"

---------斗地主出牌
--[[
    协议：
        {
            type 0 : integer,--(出牌类型）
            pai 1 :*integer,--出的牌
        }
    牌类型
        3-17 分别表示
        3 4 5 6 7 8 9 10 J Q K A 2 小王 大王
    出牌类型
    -- 0： 过
    -- 1： 单牌
    -- 2： 对子
    -- 3： 三不带
    -- 4： 三带一    pai[1]代表三张部分 ，p[2]代表被带的牌
    -- 5： 三带一对    pai[1]代表三张部分 ，p[2]代表被带的对子
    -- 6： 顺子     pai[1]代表顺子起点牌，p[2]代表顺子终点牌
    -- 7： 连队         pai[1]代表连队起点牌，p[2]代表连队终点牌
    -- 8： 四带2        pai[1]代表四张部分 ，p[2]p[3]代表被带的牌
    -- 9： 四带两对
    -- 10：飞机带单牌（只能全部带单牌） pai[1]代表飞机起点牌，p[2]代表飞机终点牌，后面依次是要带的牌
    -- 11：飞机带对子（只能全部带对子）
    -- 12：飞机  不带
    -- 13：炸弹
    -- 14：王炸
    -- 15：假炸弹

--]]
local nor_ddz_room_lib ={}

local pai_type=nor_ddz_base_lib.pai_type
local other_type=nor_ddz_base_lib.other_type
local pai_map=nor_ddz_base_lib.pai_map
local pai_to_startId_map=nor_ddz_base_lib.pai_to_startId_map
local pai_to_endId_map=nor_ddz_base_lib.pai_to_endId_map
local lz_id=nor_ddz_base_lib.lz_id
local lz_id_to_type=nor_ddz_base_lib.lz_id_to_type


-- 二人抢地主最大次数
local er_qiang_dz_max_count = 2






--向下一个人移交出牌权
local function guo(_data)
	_data.play_data.cur_p=_data.play_data.cur_p+1
	if _data.play_data.cur_p>_data.seat_count then 
		_data.play_data.cur_p=1
	end
end


--**********************逻辑辅助函数
--按dui_count张牌分段检查 若炸弹小于boom_limit个则返回false   dui_limit--堆的计数数量
local function xipai_boom_check(pai,boom_limit,dui_count,dui_limit)
	
	local boom=0
	local i=0
	while true do
		if dui_limit and i>dui_limit then
			break
		end
		local start_p=1+i*dui_count
		local end_p=start_p+dui_count-1
		if end_p>#pai then
			break
		end
		local map={}
		for k=start_p,end_p do
			local _p=pai_map[pai[k]]
			map[_p]=map[_p] or 0
			map[_p]=map[_p]+1
		end
		for k,v in pairs(map) do
			if v==4 then
				boom=boom+1
			end
		end
		if map[16]==1 and map[17]==1 then
			boom=boom+1
		end
		i=i+1
	end
	if boom>=boom_limit then
		return boom
	end
	return false,boom

end

--普通洗牌
local function xipai_nor_xipai(_count)
	local _pai={
			1,2,3,4,
			5,6,7,8,
			9,10,11,12,
			13,14,15,16,
			17,18,19,20,
			21,22,23,24,
			25,26,27,28,
			29,30,31,32,
			33,34,35,36,
			37,38,39,40,
			41,42,43,44,
			45,46,47,48,
			49,50,51,52,
			53,
			54,
		}
	--牌型置换 随机选三张牌和最后三张牌置换*********
	local _start=#_pai-2
	if  _start<1 then
		_start=1
	end
	for _i=_start,#_pai do
		local _jh=_pai[_i]
		local _rand=math.random(_i,#_pai)
		_pai[_i]=_pai[_rand]
		_pai[_rand]=_jh
	end
	--**************
		
	_count =_count or #_pai
	local _rand=1
	local _jh	
	for _i=1,_count-1 do 
		_jh=_pai[_i]
		_rand=math.random(_i,#_pai)
		_pai[_i]=_pai[_rand]
		_pai[_rand]=_jh
	end

	if skynet.getcfg("dev_debug") then
		_pai={
			1,2,3,4,
			5,6,7,8,
			9,10,11,12,
			13,14,15,16,
			17,18,19,20,
			21,22,23,24,
			25,26,27,28,
			29,30,31,32,
			33,34,35,36,
			37,38,39,40,
			41,42,43,44,
			45,46,47,48,
			49,50,51,52,
			53,
			54,
		}
	end

	return _pai	
end


--不洗牌算法
local function xipai_buxipai(xp_count,depth,boom_limit,boom_max,max_pai)
	--  将牌分成N堆   pai：被分的牌  fen_pai：分好后储存的地方  count每堆的数量  max_zu分成几堆   
	local fenpai=function (pai,fen_pai,count,max_zu)
		local _cur=1
		for k=1,#pai do
			fen_pai[_cur]=fen_pai[_cur] or {}
			fen_pai[_cur][#fen_pai[_cur]+1]=pai[k]
			if k%count==0 then
				_cur=_cur+1
				if _cur>max_zu then
					_cur=max_zu
				end
			end
		end
	end
	local _pai=xipai_nor_xipai(xp_count)
	--将牌分成三堆按大小顺序排序后重新洗牌
	local _fen_pai={}
	fenpai(_pai,_fen_pai,17,3)

	--将牌排序后重新合并
	_pai={}
	for k=1,3 do
		table.sort( _fen_pai[k], function (a,b)
									return a>b
								end )
		for i=1,#_fen_pai[k] do
			_pai[#_pai+1]=_fen_pai[k][i]
		end
	end
	--分成N堆进行重排
	local dui_count=6
	local dui_pai_count=9
	_fen_pai={}
	fenpai(_pai,_fen_pai,dui_pai_count,dui_count)
	local random_count=6
	for i=1,random_count do
		local rd=math.random(1,dui_count)
		if rd~=i then
			local ls=_fen_pai[rd]
			_fen_pai[rd]=_fen_pai[i]
			_fen_pai[i]=ls
		end
	end
	_pai={}
	for k=1,dui_count do
		for i=1,#_fen_pai[k] do
			_pai[#_pai+1]=_fen_pai[k][i]
		end
	end
	if not boom_limit then
		local gl=math.random(1,100)
		if gl<30 then
			boom_limit=4
		elseif gl <70 then
			boom_limit=5
		else
			boom_limit=6
		end
	end
	local boom_count,boom_count_2=xipai_boom_check(_pai,boom_limit,17)
	
	if not boom_count and (not boom_max or boom_count_2>boom_max) then
		boom_max=boom_count_2
		max_pai=_pai
	end
	if boom_count then
		return _pai
	elseif depth and depth>30 then
		return max_pai
	else
		depth=depth or 0
		return xipai_buxipai(xp_count,depth+1,boom_limit,boom_max,max_pai)
	end

	return _pai
end

--二人斗地主*****
--普通洗牌
local function er_xipai_nor_xipai(_count)
	--二人地主需要去掉 3，4
	local _pai={
			9,10,11,12,
			13,14,15,16,
			17,18,19,20,
			21,22,23,24,
			25,26,27,28,
			29,30,31,32,
			33,34,35,36,
			37,38,39,40,
			41,42,43,44,
			45,46,47,48,
			49,50,51,52,
			53,
			54,
		}

	--牌型置换 随机选三张牌和最后三张牌置换*********
	local _start=#_pai-2
	if  _start<1 then
		_start=1
	end
	for _i=_start,#_pai do
		local _jh=_pai[_i]
		local _rand=math.random(_i,#_pai)
		_pai[_i]=_pai[_rand]
		_pai[_rand]=_jh
	end
	--**************
				
	_count=_count or #_pai
	local _rand=1
	local _jh	
	for _i=1,_count-1 do 
		_jh=_pai[_i]
		_rand=math.random(_i,#_pai)
		_pai[_i]=_pai[_rand]
		_pai[_rand]=_jh
	end

	if skynet.getcfg("dev_debug") then
		_pai={
			9,10,11,12,
			13,14,15,16,
			17,18,19,20,
			21,22,23,24,
			25,26,27,28,
			29,30,31,32,
			33,34,35,36,
			37,38,39,40,
			41,42,43,44,
			45,46,47,48,
			49,50,51,52,
			53,
			54,
		}
	end

	return _pai	
end
--不洗牌算法
local function er_xipai_buxipai(xp_count,depth,boom_limit,boom_max,max_pai)
	--  将牌分成N堆   pai：被分的牌  fen_pai：分好后储存的地方  count每堆的数量  max_zu分成几堆   
	local fenpai=function (pai,fen_pai,count,max_zu)
		local _cur=1
		for k=1,#pai do
			fen_pai[_cur]=fen_pai[_cur] or {}
			fen_pai[_cur][#fen_pai[_cur]+1]=pai[k]
			if k%count==0 then 
				_cur=_cur+1
				if _cur>max_zu then
					_cur=max_zu
				end
			end
		end
	end
	local _pai=er_xipai_nor_xipai(xp_count)
	--将牌分成三堆按大小顺序排序后重新洗牌
	local _fen_pai={}
	fenpai(_pai,_fen_pai,17,3)

	--将牌排序后重新合并
	_pai={}
	for k=1,3 do
		table.sort( _fen_pai[k], function (a,b)
									return a>b
								end )
		for i=1,#_fen_pai[k] do
			_pai[#_pai+1]=_fen_pai[k][i]
		end
	end
	--分成N堆进行重排
	local dui_count=7
	local dui_pai_count=7
	_fen_pai={}
	fenpai(_pai,_fen_pai,dui_pai_count,dui_count)
	local random_count=6
	for i=1,random_count do
		local rd=math.random(1,dui_count)
		if rd~=i then
			local ls=_fen_pai[rd]
			_fen_pai[rd]=_fen_pai[i]
			_fen_pai[i]=ls
		end
	end
	_pai={}
	for k=1,dui_count do
		for i=1,#_fen_pai[k] do
			_pai[#_pai+1]=_fen_pai[k][i]
		end
	end
	if not boom_limit then
		if math.random(1,100)<50 then
			boom_limit=4
		else
			boom_limit=5
		end
	end
	local boom_count,boom_count_2=xipai_boom_check(_pai,boom_limit,17,2)
	
	if not boom_count and (not boom_max or boom_count_2>boom_max) then
		boom_max=boom_count_2
		max_pai=_pai
	end
	if boom_count then
		return _pai
	elseif depth and depth>30 then
		return max_pai
	else
		depth=depth or 0
		return er_xipai_buxipai(xp_count,depth+1,boom_limit,boom_max,max_pai)
	end
	return _pai
end
--**************


--洗牌
function nor_ddz_room_lib.xipai(_d)
	if nor_ddz_room_lib.game_type=="nor_ddz_er" then
		print("----------------------------------- nor_ddz er_xipai_buxipai ")
		return er_xipai_buxipai(25)
	elseif nor_ddz_room_lib.game_type=="nor_ddz_boom" then
		print("----------------------------------- nor_ddz_boom_xipai_buxipai ")
		return xipai_buxipai(25)
	elseif nor_ddz_room_lib.game_type=="nor_ddz_nor" and _d and _d.jdz_type=="mld" then
		print("----------------------------------- nor_ddz_mld_xipai_buxipai ")
		return xipai_buxipai(nil,0)
	else
		print("----------------------------------- nor_ddz xipai_nor_xipai ")
		return xipai_nor_xipai()
	end
end

local function get_xsyd_real_player_seat(_d)
	local player_seat = nil
	for i,v in ipairs(_d.p_info) do
		if basefunc.chk_player_is_real(v.id) then
			player_seat=v.seat_num
			break
		end
	end
	return player_seat
end

---***************
local function nor_fapai(_pai,_play_data,_num)
	if skynet.getcfg("dev_debug") then
		_num = 17
	end

	if not _num then 
		_num=1
	end
	local _fapai_count=#_pai-3
	local _i=1
	while _i<=_fapai_count do
		for _p=1,3 do
			if _play_data[_p].remain_pai<17 then
				for _k=1,_num do
					_play_data[_p].pai[_pai[_i]]=true
					_play_data[_p].remain_pai=_play_data[_p].remain_pai+1
					_i=_i+1
					if _play_data[_p].remain_pai>=17 or _i>_fapai_count then 
						break
					end
				end
			end
		end
	end
	for i=_fapai_count+1,#_pai do
		_play_data.dz_pai[#_play_data.dz_pai+1]=_pai[i]
	end
end

---- 给某个位置发特定好牌
-- {
-- 	{ pai_type = "boom"  , min_num = 1, max_num = 1 , min_pai = 3 , max_pai = 15, gailv_type = 1 },
-- 	{ pai_type = "danpai"  , min_num = 2, max_num = 2 , min_pai = 15 , max_pai = 15, gailv_type = 1 },
-- 	{ pai_type = "danpai"  , min_num = 1, max_num = 1 , min_pai = 16 , max_pai = 17, gailv_type = 1 },
-- 	{ pai_type = "danpai"  , min_num = 2, max_num = 2 , min_pai = 14 , max_pai = 14, gailv_type = 1 },
-- 	{ pai_type = "danpai"  , min_num = 0, max_num = 0 , min_pai = 3 , max_pai = 17, gailv_type = 4 },
-- }
function nor_ddz_room_lib.fa_nice_pai_for_seat( _d , _nice_pai_seat , _nice_pai_type_cfg , _num )
	local _play_data = _d.play_data

	---- 选牌池
	local total_pai_map = ddz_fa_hao_pai.get_pai_map()
	if _d.game_type=="nor_ddz_nor" then
		total_pai_map = ddz_fa_hao_pai.get_er_pai_map()
	end

	---
	local nice_pai_id_list = ddz_fa_hao_pai.create_type_pai( total_pai_map , _nice_pai_type_cfg )

	---- 给好牌位置发
	for key , pai_id in pairs(nice_pai_id_list) do
		_play_data[ _nice_pai_seat ].pai[ pai_id ]=true
		_play_data[ _nice_pai_seat ].remain_pai = _play_data[ _nice_pai_seat ].remain_pai + 1
	end

	---- 从牌池里面剔除
	for key , pai_id in pairs(nice_pai_id_list) do
		for _key,_pai_id in pairs(_play_data.pai) do
			if pai_id == _pai_id then
				table.remove( _play_data.pai , _key )
				break
			end
		end
	end

	local _pai = _play_data.pai

	if not _num then 
		_num=1
	end
	local _fapai_count=#_pai-3
	local _i=1
	while _i<=_fapai_count do
		for _p=1,3 do
			if _p ~= _nice_pai_seat then

				if _play_data[_p].remain_pai<17 then
					for _k=1,_num do
						_play_data[_p].pai[_pai[_i]]=true
						_play_data[_p].remain_pai=_play_data[_p].remain_pai+1
						_i=_i+1
						if _play_data[_p].remain_pai>=17 or _i>_fapai_count then 
							break
						end
					end
				end
			end
		end
	end
	for i=_fapai_count+1,#_pai do
		_play_data.dz_pai[#_play_data.dz_pai+1]=_pai[i]
	end


end


----- 
local last_config_time = 0
function nor_ddz_room_lib.fa_nice_pai_new(_d , gain_power , wave_status , nice_pai_seat_num , laji_pai_seat_num , is_for_player )

	if wave_status == "down" then
		if gain_power > 50 then
			gain_power = 50
		end
		if gain_power < 0 then
			gain_power = 0
		end
	elseif wave_status == "up" then
		if gain_power < 50 then
			gain_power = 50
		end
		if gain_power > 100 then
			gain_power = 100
		end
	end

	local ctrl_power = 0
	ctrl_power = 100 * ( math.abs(gain_power - 50)/50 )

	local ctrl_grade = math.ceil( ctrl_power / 20 )
	ctrl_grade = ctrl_grade == 0 and 1 or ctrl_grade
	

	local _play_data = _d.play_data

	print("--------------------fa_nice_pai_new , _d.game_type:",_d.game_type)

	----- 根据ddz类型使用不同的 发好牌 配置
	local raw_configs = nil
	local config_time = 0
	if _d.game_type=="nor_ddz_nor" and _d.jdz_type == "nor" then
		raw_configs,config_time = nodefunc.get_global_config("tuoguan_haopai_ddz_nor_cfg") 
	elseif _d.game_type=="nor_ddz_nor" and _d.jdz_type == "mld" then
		raw_configs,config_time = nodefunc.get_global_config("tuoguan_haopai_ddz_mld_cfg") 
	elseif _d.game_type=="nor_ddz_er" then
		raw_configs,config_time = nodefunc.get_global_config("tuoguan_haopai_ddz_er_cfg") 
	elseif _d.game_type=="nor_ddz_boom" then --- 炸弹场
		raw_configs,config_time = nodefunc.get_global_config("tuoguan_haopai_ddz_boom_cfg") 
	end
	if config_time ~= last_config_time then
		last_config_time = config_time
		--dump( raw_configs , "------------------------------- reload_hao_pai_config:" )
		print("---------------- nor_ddz_room_lib.fa_nice_pai_new --- reload_hao_pai_config" , last_config_time , config_time)
	end

	local function nor_fapai()
		_d.play_data.pai = nor_ddz_room_lib.xipai(_d)
		nor_ddz_room_lib.fapai(_d,17)
		--随机确定出叫地主顺序
		nor_ddz_room_lib.get_dz_candidate(_d)
	end

	if is_for_player then
		local old_ctrl_grade = ctrl_grade
		ctrl_grade = 6
		if not raw_configs.grade or not raw_configs.grade[ctrl_grade] then
			ctrl_grade = old_ctrl_grade
		end
	end

	local fa_hap_pai_cfg = nil
	---- 如果没有配置，就直接发牌
	if not raw_configs then
		nor_fapai()

		return false
	else
		if raw_configs.grade and raw_configs.grade[ctrl_grade] then
			fa_hap_pai_cfg = raw_configs.grade[ctrl_grade]
		end

		if not fa_hap_pai_cfg then
			nor_fapai()

			return false
		end
	end

	------- 随机发好牌，做一个控制
	local gailv = 50
	if not is_for_player then
		local rand = math.random(100)
		if _d.game_model and _d.game_id and fa_hap_pai_cfg.fa_hao_pai_gailv then
			gailv = fa_hap_pai_cfg.fa_hao_pai_gailv[_d.game_model] and fa_hap_pai_cfg.fa_hao_pai_gailv[_d.game_model][_d.game_id] or nil
			gailv = gailv or fa_hap_pai_cfg.fa_hao_pai_gailv.default

			if rand > gailv then
				nor_fapai()
				return false
			end

		end
	end

	
	
	
	local pai_id_list_vec = ddz_fa_hao_pai.create_all_hand_card( raw_configs.pai_map , fa_hap_pai_cfg , ctrl_power )

	---- 
	local seat_list = {}

	seat_list[1] = nice_pai_seat_num
	seat_list[2] = laji_pai_seat_num + nice_pai_seat_num == 3 and 3 or ( laji_pai_seat_num + nice_pai_seat_num == 4 and 2 or 1 )
	seat_list[3] = laji_pai_seat_num

	----关键打印,不可注释!!
	dump(pai_id_list_vec , string.format("-----------------------pai_id_list_vec:%d,gailv:%d",_d.game_id , gailv ))


	for key=1,3 do

		for _key , pai_id in pairs( pai_id_list_vec[key] ) do
			local target_seat = seat_list[key]

			_play_data[ target_seat ].pai[ pai_id ]=true
			_play_data[ target_seat ].remain_pai = _play_data[ target_seat ].remain_pai + 1

		end
		

	end

	for key,pai_id in pairs(pai_id_list_vec[4] ) do
		_play_data.dz_pai[#_play_data.dz_pai + 1] = pai_id
	end

	return true
end


--- 发好牌
function nor_ddz_room_lib.fa_nice_pai(_d , nice_seat)
	--local test1 = ddz_create_hp.nor_ddz_hp()
	--dump( test1 , "-=-====================  fa_nice_pai , test_1" )


		-- nor_ddz_hp_shuangfei=40
		-- nor_ddz_hp_sanfei=50,
		-- nor_ddz_hp_max_boom=2,
		-- nor_ddz_hp_boom=60,
		-- nor_ddz_hp_limit_dp_count=50,
	local nor_ddz_hp_level1_cfg={
									shuangfei=skynet.getcfg_2number("nor_ddz_hp_shuangfei"),
									sanfei=skynet.getcfg_2number("nor_ddz_hp_sanfei"),
									--最大炸弹数
									max_boom=skynet.getcfg_2number("nor_ddz_hp_max_boom"),
									boom=skynet.getcfg_2number("nor_ddz_hp_boom"),
									--单牌数量限制  尽量少的产生单牌
									limit_dp_count=skynet.getcfg_2number("nor_ddz_hp_limit_dp_count"),
								}

	local nice_pai = ddz_create_hp.nor_ddz_hp_level1(nor_ddz_hp_level1_cfg)
	--dump( nice_pai , "-=-====================  fa_nice_pai , test_2" )
	local remain_pai = ddz_create_hp.get_re_pai_pool(nice_pai)

	local dizhu_pai = ddz_create_hp.get_dizhu_pai(nice_pai)

	

	local _play_data = _d.play_data

	if _play_data and _play_data[nice_seat] then
		_play_data[nice_seat].pai = nice_pai
		_play_data[nice_seat].remain_pai = 17
	end

	local remain_num = #remain_pai
	local index = 0
	while true do
		local is_break = false
		for i = 1, GAME_TYPE_SEAT[nor_ddz_room_lib.game_type] do
			if i ~= nice_seat then
				index = index + 1
				if index > remain_num then
					is_break = true
					break
				end
				_play_data[i].pai[ remain_pai[index] ]=true
				_play_data[i].remain_pai = _play_data[i].remain_pai + 1
			end
		end

		if is_break then
			break
		end

	end

	_play_data.dz_pai=dizhu_pai
	
end

--新手引导发牌
local function xsyd_fapai(_d,_num)
	local _pai,_play_data=_d.play_data.pai,_d.play_data
	local player_seat = get_xsyd_real_player_seat(_d)

	nor_ddz_room_lib.fa_nice_pai(_d , player_seat)

	--[[
		双王|2 1-3个随机|A 1-4个随机|剩余牌随机
	]]
	-- local haopai={53,54}
	-- local _2 = {1,2,3,4}
	-- local _A = {49,50,51,52}
	-- local _O = {
	-- 		5,6,7,8,
	-- 		9,10,11,12,
	-- 		13,14,15,16,
	-- 		17,18,19,20,
	-- 		21,22,23,24,
	-- 		25,26,27,28,
	-- 		29,30,31,32,
	-- 		33,34,35,36,
	-- 		37,38,39,40,
	-- 		41,42,43,44,
	-- 		45,46,47,48,}

	-- local r = math.random(1,3)
	-- for i=1,r do
	-- 	haopai[#haopai+1]=_2[i]
	-- end

	-- local r = math.random(1,4)
	-- for i=1,r do
	-- 	haopai[#haopai+1]=_A[i]
	-- end

	-- for i=#haopai,16 do
	-- 	while true do
	-- 		local r = math.random(1,#_O)
	-- 		if _O[r] then
	-- 			haopai[#haopai+1]=_O[r]
	-- 			_O[r] = nil
	-- 			break
	-- 		end
	-- 	end
	-- end

	-- for _,v in ipairs(haopai) do
	-- 	_play_data[player_seat].pai[v]=true
	-- end
	-- _play_data[player_seat].remain_pai=17

	-- local _new_pai={}
	-- for _,v in ipairs(_pai) do
	-- 	if not _play_data[player_seat].pai[v] then
	-- 		_new_pai[#_new_pai+1]=v
	-- 	end
	-- end
	-- _pai=_new_pai


	-- dump(player_seat,"player_seat***--")
	
	-- local _fapai_count=#_pai-3
	-- local _i=1
	-- while _i<=_fapai_count do
	-- 	for _p=1,3 do
	-- 		if _p~=player_seat then
	-- 			if _play_data[_p].remain_pai<17 then
	-- 				for _k=1,_num do
	-- 					_play_data[_p].pai[_pai[_i]]=true
	-- 					_play_data[_p].remain_pai=_play_data[_p].remain_pai+1
	-- 					_i=_i+1
	-- 					if _play_data[_p].remain_pai>=17 then 
	-- 						break
	-- 					end
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end
	-- for i=_fapai_count+1,_fapai_count+4 do
	-- 	_play_data.dz_pai[#_play_data.dz_pai+1]=_pai[i]
	-- end
end

local function debug_guding_fapai(_play_data,_p_info)
	local landai_util=require "ddz_tuoguan.landai_util"
	local pai={
				skynet.getcfg("debug_gufing_fp_p1"),
				skynet.getcfg("debug_gufing_fp_p2"),
				skynet.getcfg("debug_gufing_fp_p3"),
				}
	--第一个一定发给真实玩家
	local sort_pai={}
	local pos=1
	for k,v in ipairs(_p_info) do
		if not v.is_robot then
			pos=k
			break
		end
	end

	dump({pos,_p_info},"xxxxxxxxxxxxxxxx  debug_guding_fapai  ")

	-- ]]
	local max_seat=#pai
	local count=1
	while count<=max_seat do
		sort_pai[pos]=pai[count]
		count=count+1
		pos=pos+1
		if pos>max_seat then
			pos = 1
		end
	end			

				
	local pai_map={}

	for k,v in ipairs(sort_pai) do
		if type(v) == "string" then 
			pai_map[k]=	landai_util.cards2pai( landai_util.ss2cards(v))
		else 
			pai_map[k] =landai_util.idcards2pai(v)
		end
	end	

	dump(pai_map,"AFDFDFDFFDFDAAAAAAAAAAAAAAAA")


	local pai_hash={}		
	for k,v in ipairs(pai_map) do
		_play_data[k].pai={}
		local count=0
		for pai_type,sum in pairs(v) do
			for i=1,sum do
				for pos=pai_to_startId_map[pai_type],pai_to_endId_map[pai_type] do
					if not pai_hash[pos] then
						pai_hash[pos]=true
						_play_data[k].pai[pos]=true
						count=count+1
						break
					end
				end
			end
		end
		_play_data[k].remain_pai=count
	end

	dump(_play_data,"***************************")
	for i=1,54 do
		if not pai_hash[i] then
			_play_data.dz_pai[#_play_data.dz_pai+1]=i
		end
	end
end
--发牌
function nor_ddz_room_lib.fapai(_d,_num)
	local _pai,_play_data=_d.play_data.pai,_d.play_data

	print("xxxxxxxxxxxxxxfffdddddddd dev_debug_gufing_fp:",skynet.getcfg("dev_debug_gufing_fp"))
	if skynet.getcfg("dev_debug_gufing_fp") then
		debug_guding_fapai(_play_data,_d.p_info)
		return 	
	end

	if nor_ddz_room_lib.game_type=="nor_ddz_er" then
		return nor_fapai(_pai,_play_data,17)
	elseif _d.game_tag=="xsyd" then
		return xsyd_fapai(_d,_num)
	else
		return nor_fapai(_pai,_play_data,_num)
	end 
end

---***************

function nor_ddz_room_lib.chupai(_data,_p,_type,_key_pai,act_cp_list,_merge_cp_list,lazi_num)

	if not nor_ddz_base_lib.check_chupai_safe(_data.play_data.act_list,_p,_type,_key_pai) then
		--出牌不合法
		return 1003
	end

	_data.play_data.act_list[#_data.play_data.act_list+1]={type=_type,p=_p,pai=_key_pai,lazi_num=lazi_num,cp_list=act_cp_list,merge_cp_list=_merge_cp_list}

	if _type~=0 then
		nor_ddz_base_lib.deduct_pai_by_cp_list(_data.play_data[_p],act_cp_list,_data.laizi) 
		_data.play_data[_p].remain_pai=_data.play_data[_p].remain_pai-#_merge_cp_list
		
		--根据游戏模式来判断
		if nor_ddz_room_lib.game_type=="nor_ddz_er" and _p~=_data.play_data.dizhu then
			if _data.play_data[_p].remain_pai<= _data.rangpai_num then
				--game_over
				return 1
			end
		else
			if _data.play_data[_p].remain_pai==0 then 
				--game_over
				return 1
			end
		end
	end
	guo(_data)
	return 0
end

function  nor_ddz_room_lib.new_game()
	local _play_data={}
	--地主
	_play_data.dizhu=0
	--首位地主候选人
	_play_data.dz_candidate=0
	--当前出牌权或者叫地主等权限的拥有人
	_play_data.cur_p=0
	--已出出牌序列
	_play_data.act_list={}
	--地主牌
	_play_data.dz_pai={}
	--玩家数据 key=位置号（1，2，3） 
	for i=1,3 do
		_play_data[i]={}
		--手里全部牌的列表
		_play_data[i].pai={}
		--剩余的牌数量
		_play_data[i].remain_pai=0
	end
	return _play_data
end

--获得第一位地主候选人
function nor_ddz_room_lib.get_dz_candidate(_d)
    local _play_data = _d.play_data
	if skynet.getcfg("dev_debug_gufing_dz") then
		--第一个一定发给真实玩家
		local pos=0
		for k,v in ipairs(_d.p_info) do
			if not v.is_robot then
				pos=k-1
				break
			end
		end
		pos=pos+skynet.getcfg_2number("debug_gufing_dz")
		if pos>#_d.p_info then
			pos=pos-#_d.p_info
		end
		_play_data.dz_candidate=pos
		_play_data.cur_p=_play_data.dz_candidate
		return 
	end
	if nor_ddz_room_lib.game_type=="nor_ddz_er" then 
		_play_data.dz_candidate=math.random(1,2)
		_play_data.cur_p=_play_data.dz_candidate
	elseif _d.game_tag=="xsyd" then 
		_play_data.dz_candidate=get_xsyd_real_player_seat(_d)
		_play_data.cur_p=_play_data.dz_candidate
	else
		_play_data.dz_candidate=math.random(1,3)
		_play_data.cur_p=_play_data.dz_candidate
	end
end



local function nor_jiao_dizhu(_d,_p,_rate)
	local _play_data=_d.play_data
	if not _p or _p~=_play_data.cur_p then 
		--非法的出牌顺序
		return 1002
	end
	
	local _max=0
	local _pos=0
	for i=#_play_data.act_list,1,-1 do 
		if _play_data.act_list[i].rate>_max then 
			_max=_play_data.act_list[i].rate
			_pos=_play_data.act_list[i].p
		end
	end
	--必须越来越大
	if _rate<=_max and _rate~=0 then
		return 1003
	else
		if _rate~=0 then
			_pos=_p
			_max=_rate
		end
	end
	_play_data.act_list[#_play_data.act_list+1]={type=other_type.jdz,p=_p,rate=_rate}

	_d.p_jdz[_p]=_rate
	if _rate>_d.p_jdz_rate then 
		_d.p_jdz_rate=_rate
	end

	if _rate==3 then
		_play_data.cur_p=0 
		return _p
	end 
	guo(_d)

	if _play_data.cur_p==_play_data.dz_candidate then
		 _play_data.cur_p=0 
		if _max>0 then 
			return _pos
		end
		--没有地主
		return -1
	end
	return 0 
end
local function er_jiao_dizhu(_d,_p,_rate)
	local _play_data=_d.play_data
	if not _p or _p~=_play_data.cur_p then 
		--非法的出牌顺序
		return 1002
	end
	
	if _rate>1 then
		_rate=1
	end

	_play_data.act_list[#_play_data.act_list+1]={type=other_type.jdz,p=_p,rate=_rate}

	_d.p_jdz[_p]=_rate
	if _rate>_d.p_jdz_rate then 
		_d.p_jdz_rate=_rate
	end

	guo(_d)
	--1代表叫地主
	if _rate==1 then
		return _p
	end 

	if _play_data.cur_p==_play_data.dz_candidate then
		 _play_data.cur_p=0 
		--没有地主
		return -1
	end
	return 0 
end
--地主产生则返回座位号 否则返回0 返回false表示叫地主失败
function nor_ddz_room_lib.jiao_dizhu(_d,_p,_rate) 
	if nor_ddz_room_lib.game_type=="nor_ddz_er" then
		return er_jiao_dizhu(_d,_p,_rate)	
	else
		return nor_jiao_dizhu(_d,_p,_rate)	
	end
end

function nor_ddz_room_lib.jiabei(_play_data,_p_rate,_p,_rate)
	_play_data.act_list[#_play_data.act_list+1]={type=other_type.jiabei,p=_p,rate=_rate}
	if _rate>0 then 
		if  _play_data.dizhu==_p then
			_p_rate[1]=_p_rate[1]*_rate
			_p_rate[2]=_p_rate[2]*_rate
			_p_rate[3]=_p_rate[3]*_rate
		else
			local cur_rate=_p_rate[_p]
			_p_rate[_p]=_p_rate[_p]*_rate
			_p_rate[_play_data.dizhu]=_p_rate[_play_data.dizhu]+_p_rate[_p]-cur_rate
		end
	end
	local _count=0
	local _is_jiabei=0
	for i=#_play_data.act_list,1,-1 do
		if _play_data.act_list[i].type==other_type.jiabei then 
			_count=_count+1
			if _play_data.act_list[i].rate>0 then 
				_is_jiabei=_is_jiabei+1
			end
		else
			break
		end
	end

	if _count==3 then 
		return 4
	end 
end

function nor_ddz_room_lib.er_qiang_dizhu(_d,_p,_rate)

	_d.play_data.act_list[#_d.play_data.act_list+1]={type=other_type.er_qdz,p=_p,rate=_rate}
	if _rate==1 then
		_d.qiang_dz_count=_d.qiang_dz_count+1
		if _d.qiang_dz_count==1 then
			_d.rangpai_num=2
		else
			_d.rangpai_num=_d.rangpai_num+1
		end
		if _d.qiang_dz_count==er_qiang_dz_max_count then 
			return _d.play_data.cur_p
		end
	else
		local dizhu=1
		if dizhu==_d.play_data.cur_p then
			dizhu=2
		end

		return dizhu
	end
	guo(_d)
	return 0
end

--发地主牌
function  nor_ddz_room_lib.fapai_dizhu(_dz_pai,_dz_play_data)
	for i=1,3 do
		_dz_play_data.pai[_dz_pai[i]]=true
	end
	_dz_play_data.remain_pai=20
end

function  nor_ddz_room_lib.set_dizhu(_data,_dizhu,_not_fa_dizhu_pai)
	assert(_dizhu==1 or _dizhu==2 or _dizhu==3)

	local _rate=_data.p_jdz[_dizhu]
	_rate = math.max(_rate,1)
	local all_rate=0
	for i=1,_data.seat_count do
		_data.p_rate[i]=_data.p_rate[i]*_rate
		if i~=_dizhu then
			all_rate=all_rate+_data.p_rate[i]
		end
	end
	_data.p_rate[_dizhu]=all_rate

	_data.play_data.dizhu=_dizhu
	_data.play_data.cur_p=_dizhu

	if _not_fa_dizhu_pai then
	else
		nor_ddz_room_lib.fapai_dizhu(_data.play_data.dz_pai,_data.play_data[_dizhu])
	end
	
end

--倍率矫正到最大倍率之下
function nor_ddz_room_lib.fix_rate(_datas)
	local _d=_datas

	if not _d.table_config 
		or not _d.table_config.game_config then
		return
	end

	local mr = _d.table_config.game_config.feng_ding
	if mr and mr > 0 then

		-- 二人斗地主
		if _d.game_type=="nor_ddz_er" then

			for _i=1,_d.seat_count do
				_d.p_rate[_i] = math.min(_d.p_rate[_i],mr)
			end

		else

			local dzr = 0
			for _i=1,_d.seat_count do
				if _i ~= _d.play_data.dizhu then
					_d.p_rate[_i] = math.min(_d.p_rate[_i],mr)
					dzr = dzr + _d.p_rate[_i]
				end
			end
			_d.p_rate[_d.play_data.dizhu] = dzr

		end

	end

end

function nor_ddz_room_lib.set_game_type(_g_type)
	nor_ddz_room_lib.game_type=_g_type
end



return nor_ddz_room_lib






 
