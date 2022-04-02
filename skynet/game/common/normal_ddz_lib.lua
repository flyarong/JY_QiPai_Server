--
-- Author: hw
-- Date: 2018/3/20
-- 说明：斗地主

require"printfunc"
local normal_ddz={}
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
	-- 4： 三带一 	 pai[1]代表三张部分 ，p[2]代表被带的牌
	-- 5： 三带一对    pai[1]代表三张部分 ，p[2]代表被带的对子
	-- 6： 顺子  	 pai[1]代表顺子起点牌，p[2]代表顺子终点牌
	-- 7： 连队		 pai[1]代表连队起点牌，p[2]代表连队终点牌
	-- 8： 四带2    	 pai[1]代表四张部分 ，p[2]p[3]代表被带的牌
	-- 9： 四带两对	 
	-- 10：飞机带单牌（只能全部带单牌） pai[1]代表飞机起点牌，p[2]代表飞机终点牌，后面依次是要带的牌
	-- 11：飞机带对子（只能全部带对子）
	-- 12：飞机  不带 
	-- 13：炸弹
	-- 14：王炸
	
--]]
--key=牌类型  value=此类型的牌的张数，特殊牌（如：顺子）则是最少张数
local pai_type={
	[0]=0,
	[1]=1,
	[2]=2,
	[3]=3,
	[4]=4,
	[5]=5,
	[6]=5,
	[7]=6,
	[8]=6,
	[9]=8,
	[10]=8,
	[11]=10,
	[12]=6,
	[13]=4,
	[14]=2,
}
--16
local other_type={
	jdz=100,
	jiabei=101,
}
local pai_map={
			3,3,3,3,
			4,4,4,4,
			5,5,5,5,
			6,6,6,6,
			7,7,7,7,
			8,8,8,8,
			9,9,9,9,
			10,10,10,10,
			11,11,11,11,
			12,12,12,12,
			13,13,13,13,
			14,14,14,14,
			15,15,15,15,
			16,
			17,
		}
--各类型的牌的起始id
local pai_to_startId_map = {
    0,
    0,
    1,
    5,
    9,
    13,
    17,
    21,
    25,
    29,
    33,
    37,
    41,
    45,
    49,
    53,
    54,
}
--各类型的牌的结束id
local pai_to_endId_map = {
    0,
    0,
    4,
    8,
    12,
    16,
    20,
    24,
    28,
    32,
    36,
    40,
    44,
    48,
    52,
    53,
    54,
}

-- by lyx ，增加允许外部访问的数据
normal_ddz.pai_map = pai_map
normal_ddz.pai_to_startId_map = pai_to_startId_map
normal_ddz.other_type = other_type

--向下一个人移交出牌权
local function guo(_play_data)
	_play_data.cur_p=_play_data.cur_p+1
	if _play_data.cur_p>3 then 
		_play_data.cur_p=1
	end
end
--检测是否为必须出牌（即首位出牌的人）
local function is_must_chupai(_act_list,_p)
	if #_act_list==0  or _act_list[#_act_list].type>=100 or ( #_act_list>1 and  _act_list[#_act_list].type==0 and _act_list[#_act_list-1].type==0) then 
		return 1
	end
	return nil
end

--检测出的牌是否合法            (玩家手里的牌，之前的出牌序列，要出的牌的类型，要出的牌，是否为必须出牌）
local function check_chupai_safe(_act_list,_p,_type,_pai)
	local _is_must=is_must_chupai(_act_list,_p)
	if _type==0 then 
		if _is_must then
			return false
		end
		return true
	end
	if _is_must then 
		return true
	end
	local _pos=#_act_list
	while _pos>0 do
		if _act_list[_pos].type>0 and _act_list[_pos].type<14 then 
			break
		end
		_pos=_pos-1
	end
	--上个人出的王炸
	if _act_list[_pos].type==14 then 
		return false
	end
	--必须要和上个人出的牌的类型一致
	if _type==_act_list[_pos].type then
		if _type<6 or _type==13 or _type==8 or _type==9 then 
			if _pai[1]>_act_list[_pos].pai[1] then 
				return true
			end
		else
			local sum=_pai[2]-_pai[1]
			if sum==_act_list[_pos].pai[2]-_act_list[_pos].pai[1] and _pai[1]>_act_list[_pos].pai[1] then 
				return true
			end
		end
	else
		--当前人出的是炸弹或王炸
		if _type==13 or _type==14 then 
			return true
		end
	end
	return false
end
--普通洗牌
local function xipai_nor_xipai()
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
	local _count=#_pai
	local _rand=1
	local _jh	
	for _i=1,_count-1 do 
		_jh=_pai[_i]
		_rand=math.random(_i,_count)
		_pai[_i]=_pai[_rand]
		_pai[_rand]=_jh
	end
	return _pai	
end
--不洗牌算法
local function xipai_buxipai()
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
	local _pai=xipai_nor_xipai()
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
	local dui_count=5
	local dui_pai_count=11
	_fen_pai={}
	fenpai(_pai,_fen_pai,dui_pai_count,dui_count)
	local random_count=5
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
	return _pai
end
--洗牌
function normal_ddz.xipai()
	-- return xipai_nor_xipai()
	return xipai_buxipai()
end

--发牌
function  normal_ddz.fapai(_pai,_play_data,_num)
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
					if _play_data[_p].remain_pai>=17 then 
						break
					end
				end
			end
		end
	end
	for i=_fapai_count+1,54 do
		_play_data.dz_pai[#_play_data.dz_pai+1]=_pai[i]
	end


	if false then
		return
	end


	-- local p1={5,9,13,17,21,25,29,33,37,41,45,49,1,2,3,12,8}
	-- local p2={6,10,14,18,22,26,30,34,38,42,46,50,16,20,24,28,32}
	-- local p3={7,11,15,19,23,27,31,35,39,43,47,51,36,40,44,48,52}
	-- local dz={53,54,4}
	
	-- _play_data[1].pai={}
	-- _play_data[1].remain_pai=0
	-- _play_data[2].pai={}
	-- _play_data[2].remain_pai=0
	-- _play_data[3].pai={}
	-- _play_data[3].remain_pai=0

	-- for i,v in ipairs(p1) do
	-- 	local _p=1
	-- 	_play_data[_p].pai[v]=true
	-- 	_play_data[_p].remain_pai=_play_data[_p].remain_pai+1
	-- end

	-- for i,v in ipairs(p2) do
	-- 	local _p=2
	-- 	_play_data[_p].pai[v]=true
	-- 	_play_data[_p].remain_pai=_play_data[_p].remain_pai+1
	-- end


	-- for i,v in ipairs(p3) do
	-- 	local _p=3
	-- 	_play_data[_p].pai[v]=true
	-- 	_play_data[_p].remain_pai=_play_data[_p].remain_pai+1
	-- end

	-- for i,v in ipairs(dz) do

	-- 	_play_data.dz_pai[#_play_data.dz_pai+1]=v

	-- end
end
--新手引导发牌
function  normal_ddz.xsyd_fapai(_pai,_play_data,_num,player_seat)
	_num=_num or 1
	local haopai={53,54,51,50,52,49,48,47,46,44,43,42,1,6,9,13,20,}
	for _,v in ipairs(haopai) do
		_play_data[player_seat].pai[v]=true
	end
	_play_data[player_seat].remain_pai=17

	local _new_pai={}
	for _,v in ipairs(_pai) do
		if not _play_data[player_seat].pai[v] then
			_new_pai[#_new_pai+1]=v
		end
	end
	_pai=_new_pai


	dump(player_seat,"player_seat***--")
	
	local _fapai_count=#_pai-3
	local _i=1
	while _i<=_fapai_count do
		for _p=1,3 do
			if _p~=player_seat then
				if _play_data[_p].remain_pai<17 then
					for _k=1,_num do
						_play_data[_p].pai[_pai[_i]]=true
						_play_data[_p].remain_pai=_play_data[_p].remain_pai+1
						_i=_i+1
						if _play_data[_p].remain_pai>=17 then 
							break
						end
					end
				end
			end
		end
	end
	for i=_fapai_count+1,_fapai_count+4 do
		_play_data.dz_pai[#_play_data.dz_pai+1]=_pai[i]
	end




	-- local p1={5,9,13,17,21,25,29,33,37,41,45,49,1,2,3,12,8}
	-- local p2={6,10,14,18,22,26,30,34,38,42,46,50,16,20,24,28,32}
	-- local p3={7,11,15,19,23,27,31,35,39,43,47,51,36,40,44,48,52}
	-- local dz={53,54,4}
	
	-- _play_data[1].pai={}
	-- _play_data[1].remain_pai=0
	-- _play_data[2].pai={}
	-- _play_data[2].remain_pai=0
	-- _play_data[3].pai={}
	-- _play_data[3].remain_pai=0

	-- for i,v in ipairs(p1) do
	-- 	local _p=1
	-- 	_play_data[_p].pai[v]=true
	-- 	_play_data[_p].remain_pai=_play_data[_p].remain_pai+1
	-- end

	-- for i,v in ipairs(p2) do
	-- 	local _p=2
	-- 	_play_data[_p].pai[v]=true
	-- 	_play_data[_p].remain_pai=_play_data[_p].remain_pai+1
	-- end


	-- for i,v in ipairs(p3) do
	-- 	local _p=3
	-- 	_play_data[_p].pai[v]=true
	-- 	_play_data[_p].remain_pai=_play_data[_p].remain_pai+1
	-- end

	-- for i,v in ipairs(dz) do

	-- 	_play_data.dz_pai[#_play_data.dz_pai+1]=v

	-- end
end
--获得第一位地主候选人
function  normal_ddz.get_dz_candidate(_play_data)
	_play_data.dz_candidate=math.random(1,3)
	_play_data.cur_p=_play_data.dz_candidate
end
--地主产生则返回座位号 否则返回0 返回false表示叫地主失败
function normal_ddz.jiao_dizhu(_play_data,_p,_rate) 
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
	if _rate==3 then
		_play_data.cur_p=0 
		return _p
	end 
	guo(_play_data)

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
function normal_ddz.jiabei(_play_data,_p_rate,_p,_rate)
	_play_data.act_list[#_play_data.act_list+1]={type=other_type.jiabei,p=_p,rate=_rate}
	if _rate>0  then 
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
--发地主牌
local function  fapai_dizhu(_dz_pai,_dz_play_data)
	for i=1,3 do
		_dz_play_data.pai[_dz_pai[i]]=true
	end
	_dz_play_data.remain_pai=20
end
function  normal_ddz.set_dizhu(_data,_dizhu)
	assert(_dizhu==1 or _dizhu==2 or _dizhu==3)
	local _rate=_data.p_jdz[_dizhu]
	local all_rate=0
	for i=1,3 do
		_data.p_rate[i]=_data.p_rate[i]*_rate
		if i~=_dizhu then
			all_rate=all_rate+_data.p_rate[i]
		end
	end
	_data.p_rate[_dizhu]=all_rate
	_data.play_data.dizhu=_dizhu
	_data.play_data.cur_p=_dizhu
	fapai_dizhu(_data.play_data.dz_pai,_data.play_data[_dizhu])
end


function normal_ddz.deduct_pai_by_list(_pai_data,_deduct_pai)
	if _deduct_pai then 
		for _,_pai_id in ipairs(_deduct_pai) do
			if _pai_data.hash then
				_pai_data.hash[pai_map[_pai_id]]=_pai_data.hash[pai_map[_pai_id]]-1
			end
			_pai_data.pai[_pai_id]=nil
		end
	end
end
function normal_ddz.is_must_chupai(_act_list,_p)
	return is_must_chupai(_act_list,_p)
end
--出牌人  出牌类型   pai出的牌()
function normal_ddz.chupai(_play_data,_p,_type,_cp_list)
	if not _p or _p~=_play_data.cur_p then 
		--非法的出牌顺序
		return 1002
	end
	local _cp_type=normal_ddz.get_pai_type(_cp_list)
	if not _cp_type or _cp_type.type~=_type then 
		--出牌不合法
		return 1003
	end
	if not check_chupai_safe(_play_data.act_list,_p,_type,_cp_type.pai) then
		--出牌不合法
		return 1003
	end

	_play_data.act_list[#_play_data.act_list+1]={type=_type,p=_p,pai=_cp_type.pai,cp_list=_cp_list}
	if _type~=0 then
		normal_ddz.deduct_pai_by_list(_play_data[_p],_cp_list) 
		_play_data[_p].remain_pai=_play_data[_p].remain_pai-#_cp_list
		if _play_data[_p].remain_pai==0 then 
			--game_over`
			return 1
		end
	end
	guo(_play_data)
	return 0
end
--按单牌 ，对子，三不带，炸弹的顺序选择一种牌
function normal_ddz.auto_choose_by_order(_p_pai)
	local _type=nil
	local _pai={}
	for _i=3,17 do
		if _p_pai[_i] then
			--danpai 
			if _p_pai[_i]==1 then 
				if _i<16 or (_i==16 and (not _p_pai[17] or _p_pai[17]==0)) or (_i==17 and (not _p_pai[16] or _p_pai[16]==0)) then
					_pai[1]=_i 
					return 1,_pai
				end
			elseif _p_pai[_i]==2 then
				if not _type or _type>2 then 
					_type=2
					_pai[1]=_i
				end
			elseif _p_pai[_i]==3 then
				if not _type or _type>3 then 
					_type=3
					_pai[1]=_i
				end
			elseif _p_pai[_i]==4 then
				if not _type then 
					_type=13
					_pai[1]=_i
				end
			end
		end
	end
	if not _type then 
		_type=0
		if _p_pai[16] and _p_pai[17] and _p_pai[16]==1 and _p_pai[17]==1 then 
			_type=14
			_pai[1]=16
			_pai[2]=17
		end
	end
	return _type,_pai
end

--按牌型选择最小的牌出
function normal_ddz.auto_choose_by_type(_type,_pai,_p_pai)
	--###_test
	-- if true then
	-- 	return 0
	-- end
	local _my_type=nil
	local _my_pai={}
	if _type==14 then 
		return 0
	end
	if _type==0 then
		return auto_choose_by_order(_p_pai)
	end

	if _type<=3 or _type==13 then
		local _num=_type
		if _type==13 then
			_num=4
		end
		for _i=_pai[1]+1,17 do
			if _p_pai[_i]==_num then 
				_my_type=_type
				_my_pai[1]=_i
				if (_i==16 or _i==17) and _p_pai[16]==1 and _p_pai[17]==1 then
					_my_type=14
					_my_pai[1]=16
					_my_pai[2]=17
				end
				return _my_type,_my_pai
			elseif  _p_pai[_i] and _p_pai[_i]>_num then
				if not _my_type then
					_my_type=_type
					_my_pai[1]=_i
				elseif _p_pai[_i]<_p_pai[_my_pai[1]] then
					_my_type=_type
					_my_pai[1]=_i
				end
			end
		end
		if _my_type then
			return _my_type,_my_pai
		end
	elseif _type==4 or _type==5 then
		local _f=nil 
		local _s=nil
		for _i=_pai[1]+1,15 do
			if _p_pai[_i] and _p_pai[_i]==3 then 
				_f=_i
				break
			end
		end
		if _f then
			local _num=1
			if _type==5 then
				_num=2
			end
			for _i=3,17 do
				if _p_pai[_i]==_num then 
					_s=_i
					if (_i==16 or _i==17) and  _p_pai[16]==1 and _p_pai[17]==1 then
						_s=nil
					end
					break
				end
			end
			if not _s then
				for _i=3,15 do
					if _p_pai[_i] and _i~=_f and _p_pai[_i]>_num and _p_pai[_i]<4  then 
						_s=_i
						break
					end
				end
			end
		end
		if _f and _s then 
			_my_pai[1]=_f
			_my_pai[2]=_s
			return _type,_my_pai
		end
	elseif _type==6 or _type==7 then 
		local _limit=14-(_pai[2]-_pai[1])
		local _i=_pai[1]+1
		local flag=true
		local _num=1
		if _type==7 then
			_num=2
		end
		while _i<=_limit do 
			flag=true
			for _k=_i,_i+_pai[2]-_pai[1] do
				if not _p_pai[_k] or _p_pai[_k]<_num then
					flag=false
					_i=_k
					break
				end 
			end
			if flag then
				_my_pai[1]=_i
				_my_pai[2]=_i+(_pai[2]-_pai[1]) 
				return _type,_my_pai
			end
			_i=_i+1
		end
	elseif _type==8 or _type==9 then
		for _i=_pai[1]+1,15 do
			if  _p_pai[_i]==4 then
				_my_pai[1]=_i
				break
			end 
		end
			
		if _my_pai[1] then
			local _num=1 
			if _type==9 then
				_num=2
			end
			--先选天然满足条件的牌
			for _i=3,17 do
				if _p_pai[_i]==_num then
					if _i<16 or _p_pai[16]~=1 or _p_pai[17]~=1 then
						_my_pai[#_my_pai+1]=_i
						if #_my_pai-1==2 then
							break
						end
					end
				end
			end
			local _remain=2-(#_my_pai-1)
			if _remain>0 then
				--从小到大尽量使用
				for _i=3,15 do
					if  _p_pai[_i] and _i~= _my_pai[1] and _p_pai[_i]>_num then
						if _type==9 then
							_my_pai[#_my_pai+1]=_i
							_remain=_remain-1
						else
							for _k=1,2 do
								_my_pai[#_my_pai+1]=_i
								_remain=_remain-1
								if _remain==0 then
									break
								end
							end
						end
						if _remain==0 then
							break
						end
					end
				end
			end
			if _remain==0 then
				return _type,_my_pai
			else
				_my_pai={}
			end
		end
	elseif _type==10 or _type==11 or _type==12 then
		local _len=_pai[2]-_pai[1]+1
		local _limit=14-(_pai[2]-_pai[1])
		local _i=_pai[1]+1
		local flag=true
		while _i<=_limit do 
			flag=true
			for _k=_i,_i+_pai[2]-_pai[1] do
				if not _p_pai[_k] or _p_pai[_k]<3 then
					flag=false
					_i=_k
					break
				end 
			end
			if flag then
				_my_pai[1]=_i
				_my_pai[2]=_i+(_pai[2]-_pai[1]) 
				break
			end
			_i=_i+1
		end
		if _my_pai[1] then
			if  _type==12 then
				return  _type,_my_pai
			end
			local _num=1 
			if _type==11 then
				_num=2
			end
			--先选天然满足条件的牌
			for _i=3,17 do
				if _p_pai[_i]==_num then
					if _i<16 or _p_pai[16]~=1 or _p_pai[17]~=1 then
						_my_pai[#_my_pai+1]=_i
						if #_my_pai-2==_len then
							break
						end
					end
				end
			end
			local _remain=_len-(#_my_pai-2)
			if _remain>0 then
				--从小到大尽量使用
				for _i=3,15 do
					if  _p_pai[_i] and (_i< _my_pai[1] or _i>_my_pai[2]) and _p_pai[_i]>_num then
						if _type==11 then
							_my_pai[#_my_pai+1]=_i
							_remain=_remain-1
						else
							for _k=1,_p_pai[_i] do
								if _k<3 or (_k==3 and _i~=_my_pai[1]-1 and _i~=_my_pai[2]+1 ) then
									_my_pai[#_my_pai+1]=_i
									_remain=_remain-1
									if _remain==0 then
										break
									end
								end
							end
						end
						if _remain==0 then
							break
						end
					end
				end
			end
			if _remain==1 and _type==10 and _p_pai[16]==1 and _p_pai[17]==1 then
				_remain=0
				_my_pai[#_my_pai+1]=16
			end 
			if _remain==0 then
				return _type,_my_pai
			else
				_my_pai={}
			end
		end
	end
	if _type~=13 then 
		for _i=1,15 do
			if _p_pai[_i]==4 then
				_my_pai[1]=_i
				return 13,_my_pai
			end
		end 
	end
	if  _p_pai[16]==1 and _p_pai[17]==1 then
			_my_pai[1]=16
			_my_pai[2]=17
			return 14,_my_pai
	end 
	return 0
end
--获得牌的list  牌的类型，数量
local function get_pai_list_by_type(_pai_map,_type,_num,_list)
	_list=_list or {}
	if type(_num)=="number" and _num>0 then
		for _i=pai_to_startId_map[_type],pai_to_endId_map[_type] do
			if _pai_map[_i] then
				_list[#_list+1]=_i
				_num=_num-1
				if _num==0 then
					break
				end
			end 
		end
		if _num>0 then
			return false 
		end
	end
	return _list
	-- body
end
function normal_ddz.get_cp_list(_c_hash,_type,_pai)
	-- ###_test
	if _type==0 then 
		return nil
	end
	local _list={}

	if _type<4 then
		get_pai_list_by_type(_c_hash,_pai[1],_type,_list)
	elseif _type==4 then
		get_pai_list_by_type(_c_hash,_pai[1],3,_list)
		get_pai_list_by_type(_c_hash,_pai[2],1,_list)
	elseif _type==5 then
		get_pai_list_by_type(_c_hash,_pai[1],3,_list)
		get_pai_list_by_type(_c_hash,_pai[2],2,_list)
	elseif _type==13 then
		get_pai_list_by_type(_c_hash,_pai[1],4,_list)
	elseif _type==14 then 
		_list[1]=53
		_list[2]=54
	elseif _type==6 then
		for _i=_pai[1],_pai[2] do
			get_pai_list_by_type(_c_hash,_i,1,_list)
		end
	elseif _type==7 then
		for _i=_pai[1],_pai[2] do
			get_pai_list_by_type(_c_hash,_i,2,_list)
		end
	elseif _type==8 then
		get_pai_list_by_type(_c_hash,_pai[1],4,_list)
		if _pai[2]~=_pai[3] then
			get_pai_list_by_type(_c_hash,_pai[2],1,_list)
			get_pai_list_by_type(_c_hash,_pai[3],1,_list)
		else
			get_pai_list_by_type(_c_hash,_pai[2],2,_list)
		end
	elseif _type==9 then
		get_pai_list_by_type(_c_hash,_pai[1],4,_list)
		get_pai_list_by_type(_c_hash,_pai[2],2,_list)
		get_pai_list_by_type(_c_hash,_pai[3],2,_list)
	elseif _type==10 then
		for _i=_pai[1],_pai[2] do
			get_pai_list_by_type(_c_hash,_i,3,_list)
		end
		local _count={}
		for _i=3,3+_pai[2]-_pai[1] do
			_count[_pai[_i]]=_count[_pai[_i]] or 0
			_count[_pai[_i]]=_count[_pai[_i]]+1
		end
		for _id,_num in pairs(_count) do
			get_pai_list_by_type(_c_hash,_id,_num,_list)
		end
	elseif _type==11 then
		for _i=_pai[1],_pai[2] do
			get_pai_list_by_type(_c_hash,_i,3,_list)
		end
		for _i=3,3+_pai[2]-_pai[1] do
			get_pai_list_by_type(_c_hash,_pai[_i],2,_list)
		end
	elseif _type==12 then
		for _i=_pai[1],_pai[2] do
			get_pai_list_by_type(_c_hash,_i,3,_list)
		end
	end
	return _list
end

--统计牌的类型
local function get_pai_typeHash_by_list(_pai_list)
	local _pai_type_count={}
	for _,_p_id in ipairs(_pai_list) do
		_pai_type_count[pai_map[_p_id]]=_pai_type_count[pai_map[_p_id]] or 0 
		_pai_type_count[pai_map[_p_id]]=_pai_type_count[pai_map[_p_id]]+1
	end
	return _pai_type_count
end
--[[
{
	_pai=
	{
		{
		type,
		amount,
		}
	}
	按 数量从高到低  牌从小到大排好序
}
--]]
local function sort_pai_by_amount(_pai_count)
	local _pai={}
	for _id,_amount in pairs(_pai_count) do
		_pai[#_pai+1]={type=_id,amount=_amount}
	end
	table.sort( _pai, function (a,b)
							if a.amount~=b.amount then 
								return  a.amount>b.amount
							end
							return a.type<b.type
						end )
	return _pai
end	
function normal_ddz.get_pai_type(_pai_list)
	if type(_pai_list)~="table" then 
		return {type=0}
	end
	local _pai=sort_pai_by_amount(get_pai_typeHash_by_list(_pai_list))
	--最大的相同牌数量
	local _max_num=_pai[1].amount
	--牌的种类  忽略花色
	local _type_count=#_pai

	if _type_count==1 then 
		if _max_num==4 then 
			return {type=13,pai={_pai[1].type}}
		elseif _max_num<4 then 
			return {type=_max_num,pai={_pai[1].type}} 
		end
	elseif _max_num==4 then 
		if _type_count==2 then
			--四带二  被带的牌相同情况 
			if _pai[2].amount==2 then 
				return {type=8,pai={_pai[1].type,_pai[2].type,_pai[2].type}}
			end
		elseif _type_count==3 then 
			--四带二 
			if _pai[2].amount==1 and _pai[3].amount==1 and (_pai[2].type~=16 or _pai[3].type~=17) then 
				return {type=8,pai={_pai[1].type,_pai[2].type,_pai[3].type}}
			--四带两对
			elseif _pai[2].amount==2 and _pai[3].amount==2 then 
				return {type=9,pai={_pai[1].type,_pai[2].type,_pai[3].type}}
			end
		end
	elseif _max_num==2 then
		if _type_count>2 then 
			local _flag=true
			for _i=2,_type_count do 
				if _pai[_i].amount~=2 then
					_flag=false
					break
				end 
			end	
			if _flag and _pai[_type_count].type<15 and _pai[_type_count].type-_pai[1].type==_type_count-1 then 
				return {type=7,pai={_pai[1].type,_pai[_type_count].type}}
			end
		end
	elseif _max_num==1 then
		if _type_count==2 then
			--王炸
			if _pai[1].type==16 and _pai[2].type==17 then
				return {type=14,pai={_pai[1].type,_pai[2].type}}
			end
		elseif _type_count>4 then 
			--顺子
			if _pai[_type_count].type<15 and _pai[_type_count].type-_pai[1].type==_type_count-1 then
				return {type=6,pai={_pai[1].type,_pai[_type_count].type}}
			end
		end
	elseif _max_num==3 then
		local _max_len=1
		local _head=1
		local _tail=1

		local _cur_len=1
		local _cur_head=1
		local _cur_tail=1
		for _i=2,_type_count do 
			if _pai[_i].amount==3  then
				if  _pai[_i-1].type+1==_pai[_i].type and _pai[_i].type<15 then  
					_cur_len=_cur_len+1
					_cur_tail=_i
				else
					_cur_len=1
					_cur_head=_i
					_cur_tail=_i
				end
				if _cur_len>_max_len then 
					_max_len=_cur_len
					_head=_cur_head
					_tail=_cur_tail
				end
			else
				break
			end
		end
		if _max_len==_type_count then
			--裸飞机
			return {type=12,pai={_pai[1].type,_pai[_type_count].type}}
		else

			local _count=0
			--是否全部为对子
			local _is_double=true
			--大小王统计
			local _boss_count=0
			for _i=1,_type_count do
				if _i<_head or _i>_tail then 
					_count=_count+_pai[_i].amount
					if _pai[_i].amount~=2 then 
						_is_double=false
					end
					if _pai[_i].type==16 or _pai[_i].type==17 then 
						_boss_count=_boss_count+1
					end
				end
			end
			if _count==_max_len and _boss_count<2 then 
				--三带一
				if _max_len==1 then 
					return {type=4,pai={_pai[1].type,_pai[2].type}}
				else
				--飞机带单牌
					local _pai_type= {type=10,pai={_pai[_head].type,_pai[_tail].type}}
					for _i=1,_type_count do
						if _i<_head or _i>_tail then
							for _k=1,_pai[_i].amount do
								_pai_type.pai[#_pai_type.pai+1]=_pai[_i].type
							end
						end 
					end
					return _pai_type
				end
			elseif _count==_max_len*2 and _is_double then
				--三带对 
				if _max_len==1 then 
					return {type=5,pai={_pai[1].type,_pai[2].type}}
				else
				--飞机带对子
					local _pai_type={type=11,pai={_pai[_head].type,_pai[_tail].type}}
					for _i=1,_type_count do
						if _i<_head or _i>_tail then
							_pai_type.pai[#_pai_type.pai+1]=_pai[_i].type
						end 
					end
					return _pai_type
				end
			end
		end
	end
	return false
end
--_pai为map
function  normal_ddz.get_pai_typeHash(_pai)
	local _hash={}
	for _id,_v in pairs(_pai) do
		if _v then 
			_hash[pai_map[_id]]=_hash[pai_map[_id]] or 0
			_hash[pai_map[_id]]=_hash[pai_map[_id]]+1
		end
	end
	return _hash
end
function normal_ddz.get_pai_list_by_map(_map)	
	if _map then 
		local list={}
		for _pai_id,_v in pairs(_map) do
			if _v then 
				list[#list+1]=_pai_id
			end
		end
		return list
	end
	return nil
end
--关键牌数量
local key_pai_num={1,2,3,3,3,1,2,4,4,3,3,3,4,2,}
--检测自己是否有出牌的能力  0有资格，1没资格，2完全没资格（对方王炸） 对方所出牌的类型，出牌类型类型对应的牌，我的牌的hash
function normal_ddz.check_cp_capacity(_act_list,_pai_hash)	
	local _other_type=0
	local _other_pai
	--选出对手所出牌型
	if _act_list then 
		local s=#_act_list
		for _i=1,2 do 
			if _act_list[s].type>0 and _act_list[s].type<15 then 
				_other_type=_act_list[s].type
				_other_pai=_act_list[s].pai
				break
			end
			s=s-1
		end
	end


	if _other_type==0 then 
		return 0
	elseif _other_type==14 then 
		return 2
	else
		--如果我有双王
		if  _pai_hash[16]==1 and _pai_hash[17]==1 then
			return 0
		end
		local _type_num={0,0,0,0}
		for _k,_v in pairs(_pai_hash) do
			if _v>0 then
				_type_num[_v]=_type_num[_v]+1
			end
		end
		if _other_type~=13 and _type_num[4]>0 then
			return 0
		end
		local _num=key_pai_num[_other_type]
		--是否有比对方关键牌大的pai
		local is_have_big=false
		for _k,_v in pairs(_pai_hash) do
			if _k>_other_pai[1] and _v>=_num then 
				is_have_big=true
				break
			end	
		end
		if not is_have_big then
			return 1
		end

		if _other_type<4 or _other_type==13 then
			return 0
		elseif _other_type==4 then
			if _type_num[1]+_type_num[2]+_type_num[3]+_type_num[4]>1 then
				return 0
			end
		elseif _other_type==5 then
			if _type_num[2]+_type_num[3]+_type_num[4]>1 then
				return 0
			end
		elseif _other_type==6 or _other_type==7 or _other_type>9 then
			local _s=_other_pai[1]+1
			local _count=_other_pai[2]-_other_pai[1]
			local _e=15-_count
			local _flag=false
			while _s<_e do
				_flag=true
				for _i=_s,_s+_count do
					if not _pai_hash[_i] or _pai_hash[_i]<_num then
						_s=_i+1
						_flag=false
						break
					end
				end
				if _flag then
					break
				end
			end
			if _flag then
				if _other_type==6 or _other_type==7 or _other_type==12 then
					return 0
				end
				if _other_type==10 then
					local _total=0
					--计算是否有紧挨着的三个
					local _next_san=_s+_count+1
					if _next_san<15 and _pai_hash[_next_san] and _pai_hash[_next_san]>2 then
						_type_num[_pai_hash[_next_san]]=_type_num[_pai_hash[_next_san]]-1
						_total=_total+2
					end
					_next_san=_s-1
					if _next_san>2 and _pai_hash[_next_san] and _pai_hash[_next_san]>2 then
						_type_num[_pai_hash[_next_san]]=_type_num[_pai_hash[_next_san]]-1
						_total=_total+2
					end
					_total=_total+_type_num[1]+_type_num[2]*2+_type_num[3]*3+_type_num[4]*3-(_count+1)*3
					if _total>=_count+1 then
						return 0
					end

				elseif _other_type==11 then
					if _type_num[2]+_type_num[3]+_type_num[4]>=(_count+1)*2 then
						return 0
					end
				end
			end	
		end
		
		return 1	
	end

end
function normal_ddz.getAllPaiCount()
    return {
    	[1]=0,
    	[2]=0,
        [3]=4,
        [4]=4,
        [5]=4,
        [6]=4,
        [7]=4,
        [8]=4,
        [9]=4,
        [10]=4,
        [11]=4,
        [12]=4,
        [13]=4,
        [14]=4,
        [15]=4,
        [16]=1,
        [17]=1,
    }
end
function normal_ddz.jipaiqi(_cp_list,_jipaiqi)
    local pai=nil
    if _cp_list then
        local k
        for _,v in ipairs(_cp_list) do
            k=pai_map[v]
            _jipaiqi[k]=_jipaiqi[k]-1
        end
    end
end

function  normal_ddz.new_game()
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



--倍率矫正到最大倍率之下
function normal_ddz.fix_rate(_datas)
	local _d=_datas

	if not _d.table_config 
		or not _d.table_config.game_config then
		return
	end

	local mr = _d.table_config.game_config.feng_ding
	if mr and mr > 0 then
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



return normal_ddz





 