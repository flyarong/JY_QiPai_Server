-- package.path=package.path..";/Users/hewei/project/JyQipai_server/skynet/game/common/?.lua"
--
-- Author: lyx
-- Date: 2018/3/20
-- 说明：麻将 牌池 管理器
--[[
普通麻将
1:1个托管
  特点
    早走
    中走
    晚走

    晚自摸或点炮 打牌  
2：2个托管
    早走  大概率小牌 小概率中牌 极小概率大牌
    中走  中概率小牌或中牌 小概率大牌 
    晚走   平均概率

    小概率 互相点炮 走部分托管
3：3个托管
    大概率 互相点炮 走部分托管

胡牌速度
  早
  中
  晚

胡牌方式
  自摸
  点炮
    托管之间互相点跑
    玩家点炮


    参数
    {
        hupai_fanshu 胡牌番数
        bushu   步数等级： 1 , 2 ,3 
    }

    生成结果
    {
        fp={}      
        chupai_queue={}
        mopai={}
        hupai=
        dingque=
        peng={}
        gang={}
    }

--- 牌型出现的优先度    
0翻
  屁胡
1翻 
   1 大对子  1中章  1屁胡+1根  1门清
2翻 
   清一色
   大对子+中章
   屁胡+中章+杠
   大对子+杠

   7对
   屁胡+2根  
3翻
  清一色+中章
  清一色+对子
  7对+中章
  龙七对
  大对子+2杠

	model={
		tuoguan_count=1,2,3
		model=1-N
	}
	--数组
	hupai_data={
			{
				hupai_fanshu
				bushu
				dq_color
				f_color   --first_color
				s_color	  -- second_color
			}
	}
	}
--]]

local basefunc = require "basefunc"
local printfunc = require "printfunc"
local mj_fhp_base_lib=require "mj_fahaopai_base_lib"
local this = {}


local base_bushu_cfg={
	-- {3,5},
	-- {5,8},
	-- {7,10},	
	{2,4},
	{4,6},
	{6,8},	
}
--需要别人配合的杠的最大值
local peihe_gang_max=1
--需要别人配合的概率
local peihe_gang_gl_cfg=80
--需要别人配合的碰的最大值
local peihe_peng_max=2
--需要别人配合的概率
local peihe_peng_gl_cfg=50


local peihe_gang_max_2=1
local peihe_gang_gl_cfg_2=85
local peihe_peng_max_2=1
local peihe_peng_gl_cfg_2=90


local function map_to_list(map,_list)
	local list=_list or {}
	if map then
		for k,v in pairs(map) do
			for i=1,v do
				list[#list+1]=k
			end
		end
	end
	return list
end
local function list_to_map(list,_map)
	local map=_map or {}
	if list then
		for _,v in ipairs(list) do
			map[v]=map[v] or 0
			map[v]=map[v] +1
		end
	end
	return map
end
-- 根据配置 计算番数
local function get_fanshu_by_cfg()

	-- 根据盈利系数 构造概率表
	local _fan_prob = {100-tuoguan_win_factor,tuoguan_win_factor,tuoguan_win_factor}

	local _sum = 100 + tuoguan_win_factor

	local _prob_sum = 0
	local _rand = math.random(_sum)
	for i,_prob in ipairs(_fan_prob) do
		_prob_sum = _prob_sum + _prob
		if _rand <= _prob_sum then
			return i
		end
	end
	
	return _fan_prob[1]
end

local function random_list(list)
	if list then
		local _count=#list
		local _rand=1
		local _jh
		for _i=1,_count-1 do
			_jh=list[_i]
			_rand=math.random(_i,_count)
			list[_i]=list[_rand]
			list[_rand]=_jh
		end
	end
end
--not_four 不能从4杠里面提取
local function random_extract_pai_by_map(count,my_pai_map,filter_map)
	local list={}

	for k,v in pairs(my_pai_map) do
		if v>0 and (not filter_map or not filter_map[k]) then
			list[#list+1]=k
		end
	end
	local extract={}
	while count>0 do 
		local pos=math.random(1,#list)
		local v=list[pos]
		if my_pai_map[v]>0 then
			my_pai_map[v]=my_pai_map[v]-1
			count=count-1
			extract[#extract+1]=v
		else
			for i=pos+1,#list do
				list[i-1]=list[i]
			end
			list[#list]=nil
		end
		if #list==0 then
			return nil
		end
	end
	return extract
end
local function random_extract_peihe_pg_by_map(max,gl,pai_map,filter_map)
	local list={}
	for k,v in pairs(pai_map) do
		if (not filter_map or not filter_map[k]) then
			list[#list+1]=k
		end
	end
	random_list(list)
	local count=0
	local extract_list={}
	for k,v in ipairs(list) do 
		if math.random(1,100)<gl then
			extract_list[#extract_list+1]=v
			count=count+1
		end
		if count==max then
			break
		end
	end
	return extract_list
end
local function delete_pai_by_list(map,list)
	if map and list then
		for _,v in ipairs(list) do
			map[v]=map[v]-1
		end
	end
end

local function deal_base_operate(data,pai_map,_peihe_gang_max,_peihe_gang_gl_cfg,_peihe_peng_max,_peihe_peng_gl_cfg)
	--[[
		思路
			考虑点
				互相碰
						每个人最多3个碰牌能被配合
				互相杠
						
				点炮胡
				规避摸牌顺序
		1：选出胡牌 胡牌不能从杠中选取
		2:
			选出自己需要别人配合的碰和杠（此时手里的需要碰的牌一定要有2张）
		3：
			选出必须摸的牌（比如杠）
		4：
			碰杠胡配合分配
		5：			
			生成出牌摸牌序列，略微向前调整配合别人的出牌
		6: 
			将需要别人配合的牌添加至自己的摸牌尾部

	--]]	
	--提取出胡牌
	for k,v in ipairs(data) do
	 	v.hupai=random_extract_pai_by_map(1,v.my_pai_map,v.gang_map)[1]
	end

	--选出自己需要别人配合的碰和杠（此时手里的需要碰的牌一定要有2张）
	if #data>1 then
		for k,v in ipairs(data) do
			--选出需要配合的杠
			if v.gang_map then
				v.need_ph_gang_list=random_extract_peihe_pg_by_map(_peihe_gang_max,_peihe_gang_gl_cfg,v.gang_map)
			end
			--选出需要配合的碰
			if v.peng_map then
				v.need_ph_peng_list=random_extract_peihe_pg_by_map(_peihe_peng_max,_peihe_peng_gl_cfg,v.peng_map,{[v.hupai]=true})
			end
			-- print("需要别人配合的牌******",k)
			-- if v.need_ph_gang_list then
			-- 	dump(v.need_ph_gang_list)
			-- end
			-- if v.need_ph_peng_list then
			-- 	dump(v.need_ph_peng_list)
			-- end
			-- print("需要别人配合的牌******",k)
		end
	end
	-- 选出必须摸的牌（比如杠）
	for k,v in ipairs(data) do
		--选出需要配合的杠
		if v.gang_map then
			local ph_gang_map=list_to_map(v.need_ph_gang_list)
			for g_pai,_ in pairs(v.gang_map) do
				if not ph_gang_map or not ph_gang_map[g_pai] then
					v.must_mopai_list=v.must_mopai_list or {}
					v.must_mopai_list[#v.must_mopai_list+1]=g_pai
				end
			end
		end
	end
	--扣除相应的牌
	for k,v in ipairs(data) do
		--扣除我的牌中别人配合的
		delete_pai_by_list(v.my_pai_map,v.need_ph_gang_list)
		delete_pai_by_list(v.my_pai_map,v.need_ph_peng_list)
		--扣除我的牌中必须要自己摸的牌
		delete_pai_by_list(v.my_pai_map,v.must_mopai_list)
	end
end
local function deal_bushu_operate(data,bushu_cfg)
	bushu_cfg=bushu_cfg or base_bushu_cfg
	for k,v in ipairs(data) do

		v.real_bushu=math.random(bushu_cfg[v.bushu][1],bushu_cfg[v.bushu][2])

		v.cp_list={}
		v.mopai_list={}
		v.must_mopai_list = v.must_mopai_list or {}
		v.peihe_other = v.peihe_other or {}
		basefunc.array_copy(v.must_mopai_list,v.mopai_list)
		basefunc.array_copy(v.peihe_other,v.cp_list)

		if #v.mopai_list>v.real_bushu then
			v.real_bushu=#v.mopai_list
		end
		if #v.cp_list>v.real_bushu then
			v.real_bushu=#v.cp_list
		end
	end
end
local function deal_create_mp_operate(data,pai_map,fapai_count)
	--生成 mopai_list
	for k,v in ipairs(data) do
		local _filter_map=list_to_map(v.need_ph_gang_list)
		list_to_map(v.need_ph_peng_list,_filter_map)

		local bs=v.real_bushu-#v.mopai_list
		if v.need_ph_peng_list then
			bs=bs-#v.need_ph_peng_list
		end
		local my_pai_map_copy=basefunc.deepcopy(v.my_pai_map)
		for p,v in pairs(_filter_map) do
			my_pai_map_copy[p]=nil
		end
		local my_pai_list=map_to_list(my_pai_map_copy)

		if bs>#my_pai_list then
			v.real_bushu=v.real_bushu-(bs-#my_pai_list)
			bs=#my_pai_list
		end
		if #my_pai_list-bs>fapai_count then
			bs=bs+(#my_pai_list-fapai_count)
			v.real_bushu=v.real_bushu+(#my_pai_list-fapai_count)
		end
		basefunc.array_copy(random_extract_pai_by_map(bs,v.my_pai_map,_filter_map),v.mopai_list)
		random_list(v.mopai_list)

		-- dump(v.mopai_list,"mopai_list xxxxxxx "..k.."  bushu  "..v.real_bushu)
		-- dump(map_to_list(v.my_pai_map),"my_pai_map xxxxxxx "..k)
		-- dump(v.need_ph_gang_list,"  need_ph_gang_list xxx "..k)
		-- dump(v.need_ph_peng_list,"  need_ph_peng_list xxx "..k)
	end
	return true
end
local function deal_create_cp_operate(data,pai_map,fapai_count)
	--生成 cp_list  -出牌选择可以优化  如 保证有一些定缺牌  牌型为中章可以加一些1-9
	for k,v in ipairs(data) do
		local cp_color={}
		local color_limit={}
		--二人麻将
		if fapai_count==7 then
			color_limit[3]=true
		end
		for c=1,3 do
			if c~=v.f_color and not color_limit[c] then
				cp_color[#cp_color+1]=c
			end
		end
		-- local cp_times=v.real_bushu-#v.cp_list
		local my_pai_list=map_to_list(v.my_pai_map)
		local cp_times=fapai_count-#v.cp_list-#my_pai_list
		if cp_times<0 then
			return nil
		end
		local cp_hash={}
		for i=1,cp_times do
			local count=0
			while count<200 do
				local pos=math.random(1,9)
				local pai=cp_color[math.random(1,#cp_color)]*10+pos
				cp_hash[pai]=cp_hash[pai] or 0
				if v.my_pai_map[pai]+1+cp_hash[pai]<3 and pai_map[pai]>=cp_hash[pai]+1 then
					v.cp_list[#v.cp_list+1]=pai
					cp_hash[pai]=cp_hash[pai]+1
					pai_map[pai]=pai_map[pai]-1
					break
				end
				count=count+1
			end
			if count==200 then
				return nil
			end
		end
		-- dump(v.cp_list,"cp_list xxxxxxx "..k.."  bushu "..cp_times)
		-- dump(map_to_list(v.my_pai_map),"my_pai_map xxxxxxx "..k)

		--出牌顺序可以优化
		--将定缺牌调整到最前面
		local dq_list={}
		local nor_list={}
		for i=1,#v.cp_list do
			if math.floor(v.cp_list[i]/10)==v.dq_color then
				dq_list[#dq_list+1]=v.cp_list[i]
			else
				nor_list[#nor_list+1]=v.cp_list[i]
			end
		end
		random_list(dq_list)
		random_list(nor_list)
		local ph_map=list_to_map(v.peihe_other or {})
		--将要配合别人的牌往前调整
		if ph_map then
			local ph_list={}
			local nor_list2={}
			for i=1,#nor_list do
				if ph_map[nor_list[i]] then
					ph_list[#ph_list+1]=nor_list[i]
				else
					nor_list2[#nor_list2+1]=nor_list[i]
				end
			end
			local ls_hb_list={}
			for k,v in ipairs(ph_list) do
				if #nor_list2>0 then
					if math.random(1,100)<50 then
						ls_hb_list[#ls_hb_list+1]=nor_list2[#nor_list2]
						nor_list2[#nor_list2]=nil
					end
					ls_hb_list[#ls_hb_list+1]=v
				else
					ls_hb_list[#ls_hb_list+1]=v
				end
				
			end
			basefunc.array_copy(ls_hb_list,nor_list2)
			nor_list=nor_list2
		end
		basefunc.array_copy(dq_list,nor_list)
		v.cp_list=nor_list
	end
	return true
end
local function deal_peihe_dispatch_operate(data,people_num,max)
	local count_hash={}
	for i=1,people_num do
		count_hash[i]=0
	end
	local deal_function=function (data,list,my_pos)
		if list then
			for _,p in ipairs(list) do 
				local pos=math.random(1,people_num)
				local pos_copy=pos
				local flag=0
				while true do
					if pos_copy~=my_pos and (flag>5 or count_hash[my_pos]<max) then
						break
					else
						pos_copy=pos_copy+1
						if pos_copy>people_num then
							pos_copy=1
						end
						flag=flag+1
					end
				end
				data[pos_copy].peihe_other=data[pos_copy].peihe_other or {}
				data[pos_copy].peihe_other[#data[pos_copy].peihe_other+1]=p
			end
			
		end
	end
	for k,v in ipairs(data) do
		if v.need_ph_gang_list then
			deal_function(data,v.need_ph_gang_list,k)
		end
		if v.need_ph_peng_list then
			deal_function(data,v.need_ph_peng_list,k)
		end
	end
end
function this.deal_tuoguan_1_model_1(data,pai_map,bushu_cfg,fapai_count)
	local status=true
	deal_base_operate(data,pai_map,0,0,0,0)

	-- deal_peihe_dispatch_operate(data,1,3)

	deal_bushu_operate(data,bushu_cfg)

	deal_create_mp_operate(data,pai_map,fapai_count)
	status=deal_create_cp_operate(data,pai_map,fapai_count)
	if not status then
		return nil
	end


	-- bushu_cfg=bushu_cfg or base_bushu_cfg
	
	-- local pai_data=data[1]
	-- local bushu=pai_data.bushu
	-- --确定步数
	-- bushu=math.random(bushu_cfg[bushu][1],bushu_cfg[bushu][2])
	
	-- --提取出胡牌
	-- local hupai=random_extract_pai_by_map(1,pai_data.my_pai_map,pai_data.gang_map)[1]



	-- --提取出必须摸的牌  （杠不能原手就有必须摸）
	-- local mopai_list={}
	-- if pai_data.gang_map then
	-- 	for k,v in pairs(pai_data.gang_map) do
	-- 		mopai_list[#mopai_list+1]=k
	-- 	end
	-- end

	-- local other_mp=bushu-1-#mopai_list
	-- if other_mp<0 then
	-- 	other_mp=0
	-- end
	-- --提取出其他摸的牌
	-- other_mp=random_extract_pai_by_map(other_mp,pai_data.my_pai_map)

	-- basefunc.array_copy(other_mp,mopai_list)


	-- --选出要打的牌
	-- local cp_list={}

	-- local dapai_color={}
	-- for c=1,3 do
	-- 	if c~=pai_data.f_color then
	-- 		dapai_color[#dapai_color+1]=c
	-- 	end
	-- end
	-- local dp_times=bushu-1
	-- local dp_hash={}
	-- for i=1,dp_times do
	-- 	while true do
	-- 		local pos=math.random(1,9)
	-- 		local pai=dapai_color[math.random(1,#dapai_color)]*10+pos
	-- 		dp_hash[pai]=dp_hash[pai] or 0
	-- 		if pai_data.my_pai_map[pai]+1+dp_hash[pai]<3 and pai_map[pai]>=dp_hash[pai]+1 then
	-- 			cp_list[#cp_list+1]=pai
	-- 			dp_hash[pai]=dp_hash[pai]+1
	-- 			break
	-- 		end
	-- 	end
	-- end
	
	-- for k,v in pairs(dp_hash) do
	-- 	pai_data.my_pai_map[k]=pai_data.my_pai_map[k]+v
	-- 	pai_map[k]=pai_map[k]-v
	-- end

	-- pai_data.mopai_list=mopai_list
	-- pai_data.cp_list=cp_list
	-- pai_data.hupai=hupai

	return true
end

function this.deal_tuoguan_2_model_1(data,pai_map,bushu_cfg,fapai_count)
	-- local peihe_dispatch =function  (data)
	-- 	-- body
	-- 	--碰杠胡 分配
	-- 	data[1].peihe_other={}
	-- 	basefunc.array_copy(data[2].need_ph_gang_list,data[1].peihe_other)
	-- 	basefunc.array_copy(data[2].need_ph_peng_list,data[1].peihe_other)

	-- 	data[2].peihe_other={}
	-- 	basefunc.array_copy(data[1].need_ph_gang_list,data[2].peihe_other)
	-- 	basefunc.array_copy(data[1].need_ph_peng_list,data[2].peihe_other)
	-- end

	deal_base_operate(data,pai_map,peihe_gang_max_2,peihe_gang_gl_cfg_2,peihe_peng_max_2,peihe_peng_gl_cfg_2)

	deal_peihe_dispatch_operate(data,2,3)

	deal_bushu_operate(data,bushu_cfg)
	--尽量规避摸牌顺序
	if data[1].real_bushu<data[2].real_bushu+1 then
		data[1].real_bushu=data[2].real_bushu+1
	end
	deal_create_mp_operate(data,pai_map,fapai_count)
	local status=true
	
	status=deal_create_cp_operate(data,pai_map,fapai_count)
	if not status then
		return nil
	end
	
	data[1].dianpao={[2]=true}
	return true
end
function this.deal_tuoguan_2_model_2(data,pai_map,bushu_cfg,fapai_count)

	deal_base_operate(data,pai_map,peihe_gang_max_2,peihe_gang_gl_cfg_2,peihe_peng_max_2,peihe_peng_gl_cfg_2)
	

	deal_peihe_dispatch_operate(data,2,3)

	deal_bushu_operate(data,bushu_cfg)

	deal_create_mp_operate(data,pai_map,fapai_count)
	local status=true
	status=deal_create_cp_operate(data,pai_map,fapai_count)
	if not status then
		return nil
	end
	return true
end

function this.deal_tuoguan_3_model_1(data,pai_map,bushu_cfg,fapai_count)

	deal_base_operate(data,pai_map,peihe_gang_max,peihe_gang_gl_cfg,peihe_peng_max,peihe_peng_gl_cfg)

	deal_peihe_dispatch_operate(data,3,3)

	deal_bushu_operate(data,bushu_cfg)
	--尽量规避摸牌顺序
	if data[1].real_bushu<data[2].real_bushu+1 then
		data[1].real_bushu=data[2].real_bushu+1
	end
	if data[1].real_bushu<data[3].real_bushu+1 then
		data[1].real_bushu=data[3].real_bushu+1
	end

	deal_create_mp_operate(data,pai_map,fapai_count)
	local status=true
	
	status=deal_create_cp_operate(data,pai_map,fapai_count)
	if not status then
		return nil
	end
	
	data[1].dianpao={[2]=true,[3]=true}
	return true
end
function this.deal_tuoguan_3_model_2(data,pai_map,bushu_cfg,fapai_count)

	deal_base_operate(data,pai_map,peihe_gang_max,peihe_gang_gl_cfg,peihe_peng_max,peihe_peng_gl_cfg)

	deal_peihe_dispatch_operate(data,3,3)

	deal_bushu_operate(data,bushu_cfg)
	--尽量规避摸牌顺序
	if data[1].real_bushu<data[2].real_bushu+1 then
		data[1].real_bushu=data[2].real_bushu+1
	end
	if data[1].real_bushu<data[3].real_bushu+1 then
		data[1].real_bushu=data[3].real_bushu+1
	end
	deal_create_mp_operate(data,pai_map,fapai_count)
	local status=true
	
	status=deal_create_cp_operate(data,pai_map,fapai_count)
	if not status then
		return nil
	end
	
	data[1].dianpao={[2]=true,[2]=true}
	return true
end
function this.deal_tuoguan_3_model_3(data,pai_map,bushu_cfg,fapai_count)
	deal_base_operate(data,pai_map,peihe_gang_max,peihe_gang_gl_cfg,peihe_peng_max,peihe_peng_gl_cfg)

	deal_peihe_dispatch_operate(data,3,3)

	deal_bushu_operate(data,bushu_cfg)
	--尽量规避摸牌顺序
	if data[1].real_bushu<data[2].real_bushu+1 then
		data[1].real_bushu=data[2].real_bushu+1
	end
	if data[1].real_bushu<data[3].real_bushu+1 then
		data[1].real_bushu=data[3].real_bushu+1
	end
	deal_create_mp_operate(data,pai_map,fapai_count)
	local status=true
	
	status=deal_create_cp_operate(data,pai_map,fapai_count)
	if not status then
		return nil
	end
	
	data[1].dianpao={[2]=true,[2]=true}
	return true
end
function this.deal_tuoguan_3_model_4(data,pai_map,bushu_cfg,fapai_count)
	deal_base_operate(data,pai_map,peihe_gang_max,peihe_gang_gl_cfg,peihe_peng_max,peihe_peng_gl_cfg)

	deal_peihe_dispatch_operate(data,3,3)

	deal_bushu_operate(data,bushu_cfg)
	--尽量规避摸牌顺序
	if data[1].real_bushu<data[2].real_bushu+1 then
		data[1].real_bushu=data[2].real_bushu+1
	end
	if data[1].real_bushu<data[3].real_bushu+1 then
		data[1].real_bushu=data[3].real_bushu+1
	end
	deal_create_mp_operate(data,pai_map,fapai_count)
	local status=true
	
	status=deal_create_cp_operate(data,pai_map,fapai_count)
	if not status then
		return nil
	end
	
	data[1].dianpao={[2]=true,[2]=true}
	return true
end
-- 一 	
-- 		1 点 2 炮（小翻 早走）
-- 		1 点 3 炮
-- 	   	1 自摸 （被玩家点炮 要考虑玩家定缺情况）

-- 	二 	
-- 		2 点 3 炮（小翻 早走）
-- 		1 点 2 炮
-- 	   	1 自摸 （被玩家点炮 要考虑玩家定缺情况）

-- 	三
-- 		1 点 3 炮（小翻 早走）
-- 	   	1 2 自摸 （被玩家点炮 要考虑玩家定缺情况） 

--  	四 
--  		1，2，3都自摸 或被点炮
local deal_function_map={
	[1]={
		[1]=this.deal_tuoguan_1_model_1,
	},
	[2]={
		[1]=this.deal_tuoguan_2_model_1,
		[2]=this.deal_tuoguan_2_model_2,
	},
	[3]={
		[1]=this.deal_tuoguan_3_model_1,
		[2]=this.deal_tuoguan_3_model_2,
		[3]=this.deal_tuoguan_3_model_3,
		[4]=this.deal_tuoguan_3_model_4,
	}	
}



local function get_return_struct(hupai_data,pai_map,fapai_count)
	local data={}
	for k,v in ipairs(hupai_data) do
		data[k]={}
		data[k].cp_list=v.cp_list

		data[k].fapai_list=map_to_list(v.my_pai_map)
		basefunc.array_copy(data[k].cp_list,data[k].fapai_list)

		if #data[k].fapai_list~=fapai_count then
			dump(data[k].fapai_list)
			print("error  ")
			return nil
		end
		

		data[k].mopai_list=v.mopai_list
		data[k].hupai=v.hupai
		data[k].dq_color=v.dq_color
		data[k].peng_map=v.peng_map
		data[k].gang_map=v.gang_map
		data[k].dianpao=v.dianpao
	end
	local pai_pool=map_to_list(pai_map)
	return data,pai_pool
end
--返回值
-- {
	-- {
	--   fapai_list
	--   mopai_list 
	--   cp_list
	--   hupai
	--   dq_color
	--   gang_map
	--   peng_map
	--   dianpao={}	 --map key=要给谁点炮 
	-- }
--}
--产生出牌摸牌结构
function this.create_chupai_mopai_struct(data,pai_map,_bushu_cfg,_try_count)
	if _try_count and _try_count>10 then
		return nil
	end
	local data_copy=basefunc.deepcopy(data)
	local hupai_data_copy=basefunc.deepcopy(data.hupai_data)
	local pai_map_copy=basefunc.deepcopy(pai_map)
	local status=mj_fhp_base_lib.nor_mj_get_haopai(data.hupai_data,pai_map)
	local try_count=0
	
	while try_count<10 and not status do
		data.hupai_data=basefunc.deepcopy(hupai_data_copy)
		pai_map=basefunc.deepcopy(pai_map_copy)
		status=mj_fhp_base_lib.nor_mj_get_haopai(data.hupai_data,pai_map)
		try_count=try_count+1
	end
	if status then
		local t_c=data.model.tuoguan_count
		local model=data.model.model
		--###_test
		for k,v in ipairs(data.hupai_data) do
			dump(v.my_pai_map)
		end
		local status=deal_function_map[t_c][model](data.hupai_data,pai_map,_bushu_cfg,13)
		if not status then
			_try_count=_try_count or 0
			return this.create_chupai_mopai_struct(data_copy,pai_map_copy,_bushu_cfg,_try_count)
		end

		local res,pai_pool=get_return_struct(data.hupai_data,pai_map,13)

		if not res then
			_try_count=_try_count or 0
			return this.create_chupai_mopai_struct(data_copy,pai_map_copy,_bushu_cfg,_try_count)
		end
		return res,pai_pool
	end

	return nil
end
function this.create_er_chupai_mopai_struct(data,pai_map,_bushu_cfg,_try_count)
	if _try_count and _try_count>10 then
		return nil
	end
	local data_copy=basefunc.deepcopy(data_copy)
	local hupai_data_copy=basefunc.deepcopy(data.hupai_data)
	local pai_map_copy=basefunc.deepcopy(pai_map)
	local status=mj_fhp_base_lib.nor_er_mj_get_haopai(data.hupai_data,pai_map)
	local try_count=0
	
	while try_count<10 and not status do
		data.hupai_data=basefunc.deepcopy(hupai_data_copy)
		pai_map=basefunc.deepcopy(pai_map_copy)
		status=mj_fhp_base_lib.nor_er_mj_get_haopai(data.hupai_data,pai_map)
		try_count=try_count+1
	end
	if status then
		local t_c=data.model.tuoguan_count
		local model=data.model.model
		--###_test
		for k,v in ipairs(data.hupai_data) do
			dump(v.my_pai_map)
		end
		local status=deal_function_map[t_c][model](data.hupai_data,pai_map,_bushu_cfg,7)
		if not status then
			_try_count=_try_count or 0
			return this.create_chupai_mopai_struct(data_copy,pai_map_copy,_bushu_cfg,_try_count)
		end

		local res,pai_pool=get_return_struct(data.hupai_data,pai_map,7)

		if not res then
			_try_count=_try_count or 0
			return this.create_er_chupai_mopai_struct(data_copy,pai_map_copy,_bushu_cfg,_try_count)
		end
		return res,pai_pool
	end

	return nil
end

-- math.randomseed(os.time()*72453) 
-- -- -- for i=1,100000 do
	-- local pai_map={}
	-- for i=11,29 do
	-- 	if i%10~=0 then
	-- 		pai_map[i]=4
	-- 	end
	-- end
	-- -- local data=	{
	-- -- 				model={
	-- -- 					tuoguan_count=3,
	-- -- 					model=1,
	-- -- 				},
	-- -- 				--数组
	-- -- 				hupai_data={
	-- -- 						{
	-- -- 							hupai_fanshu=2,
	-- -- 							bushu=2,
	-- -- 							dq_color=1,
	-- -- 							f_color=2,   --first_color
	-- -- 							s_color=3,	  -- second_color
	-- -- 						},
	-- -- 						{
	-- -- 							hupai_fanshu=0,
	-- -- 							bushu=1,
	-- -- 							dq_color=2,
	-- -- 							f_color=1,   --first_color
	-- -- 							s_color=3,	  -- second_color
	-- -- 						},
	-- -- 						{
	-- -- 							hupai_fanshu=1,
	-- -- 							bushu=1,
	-- -- 							dq_color=1,
	-- -- 							f_color=3,   --first_color
	-- -- 							s_color=2,	  -- second_color
	-- -- 						}
	-- -- 				}
	-- -- 	}
	-- local data =  {
 --         hupai_data = {
 --             [1] = {
 --                 bushu      = 3,
 --                 dq_color   = 3,
 --                 f_color    = 1,
 --                 hupai_fanshu     = 3,
 --                 s_color    = 2,
 --             },
 --         },
 --         model = {
 --             model           = 1,
 --             tuoguan_count   = 1,
 --         },
 --     }

	-- local res,pai_pool=this.create_er_chupai_mopai_struct(data,pai_map)	
	-- dump(res)
	-- if not res then
	-- 	print("xxxxx",i)
	-- 	break
	-- end
-- end





	-- hp_datas[1]={
	--    ["bushu"      ]  = 2,
	--    ["dq_color"   ]  = 1,
	--    ["f_color"    ]  = 2,
	--    ["gen_count"  ]  = 1,
	--    ["hu_pai_type"]  = "nor",
	--    ["hupai_fanshu"] = 2,
	--    ["prob"        ] = 15,
	--    ["s_color"   ]   = 3,
	--    ["zhongzhang" ]  = true
	-- }
	-- hp_datas[2]={
	--        ["bushu"       ] = 1,
	--        ["dq_color"    ] = 2,
	--        ["f_color"     ] = 1,
	--        ["hu_pai_type" ] = "nor",
	--        ["hupai_fanshu"] = 0,
	--        ["s_color"     ] = 3,
	-- }
	-- hp_datas[3]={
	--        ["bushu"       ] = 1,
	--        ["dq_color"    ] = 1,
	--        ["f_color"     ] = 3,
	--        ["hu_pai_type" ] = "nor",
	--        ["hupai_fanshu"] = 1,
	--        ["prob"       ]  = 30,
	--        ["s_color"    ]  = 2,
	--        ["zhongzhang" ]  = true,
	-- }


return this

