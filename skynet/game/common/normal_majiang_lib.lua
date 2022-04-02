--
-- Author: hw
-- Date: 2018/3/20
-- 说明：麻将
-- package.path=package.path..";/Users/hewei/project/JyQipai_server/skynet/game/common/?.lua"
local basefunc = require "basefunc"
require"printfunc"

local normal_majiang={}

--[[
	麻将的表示：

	11 ~ 19  : 筒
	21 ~ 29  : 条
	31 ~ 39  : 万

	基础胡牌类型（选其一，不能组合）
	ping_hu		平胡		x1
	qi_dui 		七对  	x4


	基础番型（可相互组合）
	qing_yi_se  清一色	x4
	da_dui_zi   大对子	x2
	dai_geng  	带根	x2 （2 根 x4 ，依次类推）

	特殊番型
	jin_gou_diao	金钩吊 x4
	dai_yao_jiu		带幺九 x4
	jiang_dui		将对 x8

--]]

local random = math.random
local floor = math.floor
local min = math.min
local fmod = math.fmod


normal_majiang.SEAT_COUNT = 4
local SEAT_COUNT = normal_majiang.SEAT_COUNT


-- 基础胡牌类型定义： 番型 -> 番数
normal_majiang.MULTI_TYPES =
{
	-- 牌型
	qing_yi_se 		= 2,
	da_dui_zi 		= 1,
	qi_dui			= 2,
	long_qi_dui		= 3,

	dai_geng 		= 1,
	
	jiang_dui       = 3, --将对
	men_qing		= 1, --门清
	zhong_zhang		= 1, --中章
	jin_gou_diao    = 1, --金钩钓
	yao_jiu	 		= 2, --幺九

	-- 其它：和胡牌方式相关的
	hai_di_ly 		= 1, -- 海底捞月 最后一张牌胡牌（自摸）
	hai_di_pao 		= 1, -- 海底炮  最后一张牌胡牌（被人点炮）
	tian_hu 		= 5, -- 天胡：庄家，第一次发完牌既胡牌
	di_hu	 		= 5, -- 地胡：非庄家第一次发完牌 既自摸或 被别人点炮
	gang_shang_hua  = 1, -- 杠上花：自己杠后补杠自摸
	gang_shang_pao  = 1, -- 杠上炮：别人杠后补杠点炮
	zimo            = 1, -- 自摸
	qiangganghu     = 1, -- 抢杠胡 
}

-- 杠收的钱（番数）
normal_majiang.GANG_TYPES =
{
	zg = 1,
	wg = 0,
	ag = 1,
}
local mj_kaiguan={
	qing_yi_se 		= true,
	da_dui_zi 		= true,
	qi_dui			= true,
	long_qi_dui		= true,
	--将对
	jiang_dui       = true,
	men_qing		= true,
	zhong_zhang		= true,
	jin_gou_diao    = true,
	yao_jiu	 		= true, 


	-- 其它：和胡牌方式相关的
	hai_di_ly 		= true, -- 海底捞月 最后一张牌胡牌（自摸）
	hai_di_pao 		= true, -- 海底炮  最后一张牌胡牌（被人点炮）
	tian_hu 		= true, -- 天胡：庄家，第一次发完牌既胡牌
	di_hu	 		= true, -- 地胡：非庄家第一次发完牌 既自摸或 被别人点炮
	gang_shang_hua  = true, -- 杠上花：自己杠后补杠自摸
	gang_shang_pao  = true, -- 杠上炮：别人杠后补杠点炮
	zimo            = true, -- 自摸
	qiangganghu     = true, -- 抢杠胡 
	zimo_jiafan     = true, -- 自摸加翻 
	zimo_jiadian     = true, -- 自摸加点 
}
--jiang 将牌的数量（对子）
--[[ list=
{
	type 1 将  2 大对子 3 连子
	pai_type 牌类型  若type==3 则为起始位置的牌
}
--]]
local function compute_nor_hupai_info(pai_map,_s,all_num,jiang_num,list,list_pos,info)
	for s=_s,39 do
		if pai_map[s] and pai_map[s]>0 then
			--先取 （大对子）
			if pai_map[s]>2 then

				list[list_pos]=list[list_pos] or {}
				list[list_pos].type=2
				list[list_pos].pai_type=s

				if all_num-3==0 then
					if jiang_num==1 then
						info[#info+1]={jiang_num=jiang_num,list_pos=list_pos,list=basefunc.deepcopy(list)}
					end
					return
				end
				pai_map[s]=pai_map[s]-3

				local next=s
				if pai_map[s]==0 then
					next=s+1
				end
				compute_nor_hupai_info(pai_map,next,all_num-3,jiang_num,list,list_pos+1,info)

				pai_map[s]=pai_map[s]+3
			end
			--取顺子
			if s+2<=39 and pai_map[s] and pai_map[s+1] and pai_map[s+2] and pai_map[s+1]>0 and pai_map[s+2]>0 then


				list[list_pos]=list[list_pos] or {}
				list[list_pos].type=3
				list[list_pos].pai_type=s

				if all_num-3==0 then
					if jiang_num==1 then
						info[#info+1]={jiang_num=jiang_num,list_pos=list_pos,list=basefunc.deepcopy(list)}
					end
					return
				end
				pai_map[s]=pai_map[s]-1
				pai_map[s+1]=pai_map[s+1]-1
				pai_map[s+2]=pai_map[s+2]-1

				local next=s
				if pai_map[s]==0 then
					next=s+1
				end

				compute_nor_hupai_info(pai_map,next,all_num-3,jiang_num,list,list_pos+1,info)

				pai_map[s]=pai_map[s]+1
				pai_map[s+1]=pai_map[s+1]+1
				pai_map[s+2]=pai_map[s+2]+1
			end
			--取将
			if pai_map[s]>1 and jiang_num==0 then

				list[list_pos]=list[list_pos] or {}
				list[list_pos].type=1
				list[list_pos].pai_type=s

				if all_num-2==0 then
					info[#info+1]={jiang_num=jiang_num,list_pos=list_pos,list=basefunc.deepcopy(list)}
					return
				end
				pai_map[s]=pai_map[s]-2

				local next=s
				if pai_map[s]==0 then
					next=s+1
				end

				compute_nor_hupai_info(pai_map,next,all_num-2,jiang_num+1,list,list_pos+1,info)

				pai_map[s]=pai_map[s]+2

			end

			return
		end
	end
	return
end
--7对
local function check_7d_hupai_info(pai_map,all_num,kaiguan)
	if kaiguan and not kaiguan.qi_dui then
		return false
	end
	if all_num~=14 then
		return false
	end
	for k,v in pairs(pai_map) do
		if v>0 and v~=2 and v~=4 then
			return false
		end
	end
	return true
end
--大对子
local function check_is_daduizi(list,kaiguan)
	if kaiguan and not kaiguan.da_dui_zi then
		return false
	end
	for _,v in ipairs(list) do
		if v.type~=1 and v.type~=2 then
			return false
		end
	end
	return true
end
--幺九
local function check_is_yaojiu(list,pg_map,kaiguan)
	if kaiguan and not kaiguan.yao_jiu then
		return false
	end
	for _,v in ipairs(list) do
		if v.type==3 then
			local p=v.pai_type%10
			if p~=1 and p~=7 then
				return false
			end
		else
			local p=v.pai_type%10
			if p~=1 and p~=9 then
				return false
			end
		end
	end
	if pg_map then
		for k,v in pairs(pg_map) do
			local c=k%10
			if c~=1 and  c~=9 then
				return false
			end
		end
	end
	return true
end
--将对
local function check_is_jiangdui(pai_map,pg_map,kaiguan)	
	if kaiguan and not kaiguan.jiang_dui then
		return false
	end

	for k,v in pairs(pai_map) do
		if v>0 then
			local c=k%10
			if c~=2 and  c~=5 and  c~=8 then
				return false
			end
		end
	end
	if pg_map then
		for k,v in pairs(pg_map) do
			local c=k%10
			if c~=2 and  c~=5 and  c~=8 then
				return false
			end
		end
	end
	return true
end
--门清
local function check_is_menqing(pg_map,kaiguan)
	if kaiguan and not kaiguan.men_qing then
		return false
	end
	for k,v in pairs(pg_map) do
		if v~="ag" then
			return false
		end
	end
	return true
end
--中章
local function check_is_zhongzhang(pai_map,pg_map,kaiguan)
	if kaiguan and not kaiguan.zhong_zhang then
		return false
	end
	for k,v in pairs(pai_map) do
		if v>0 then
			local c=k%10
			if c==1 or  c==9 then
				return false
			end
		end
	end
	if pg_map then
		for k,v in pairs(pg_map) do
			local c=k%10
			if c==1 or  c==9 then
				return false
			end
		end
	end
	return true
end
--金钩钓
local function check_is_jingoudiao(pai_map,kaiguan)
	if kaiguan and not kaiguan.jin_gou_diao then
		return false
	end
	local count=0
	for k,v in pairs(pai_map) do
		count=count+v
	end
	if count==2 then
		return true
	end
	return false
end
local function get_geng_num(pai_map,pg_map)
	local num=0
	if pai_map then
		for id,v in pairs(pai_map) do
			if v==4 then
				num=num+1
			elseif v==1 and pg_map and (pg_map[id]=="peng" or pg_map[id]==3) then
				num=num+1
			end
		end
	end
	if pg_map then
		for _,v in pairs(pg_map) do
			if v=="wg" or v=="zg" or v=="ag" or v==4 then
				num=num+1
			end
		end
	end
	return num
end
local function compute_hupai_info(pai_map,pg_map,all_num,huaSe_count,kaiguan)
	local info={}
	compute_nor_hupai_info(basefunc.deepcopy(pai_map),11,all_num,0,{},1,info)
	-- 1 平胡 2 大对子 3 7对 4幺九 5将对
	local hupai_type
	if #info>0 then
		hupai_type=1
		--计算最大胡牌
		for _,v in ipairs(info) do
			--是否为大对子
			if 2>hupai_type then
				if check_is_daduizi(v.list,kaiguan) then
					hupai_type=2
					--是否为将对
					if check_is_jiangdui(pai_map,pg_map,kaiguan) then
						hupai_type=5
					end
				end
			end
			--幺舅九
			if 4>hupai_type then
				if check_is_yaojiu(v.list,pg_map,kaiguan) then
					hupai_type=4
				end
			end
		end
	end
	if check_7d_hupai_info(pai_map,all_num,kaiguan) then
		if not hupai_type or 3>hupai_type then
			hupai_type=3
		end
	end
	if hupai_type then
		local geng_num=get_geng_num(pai_map,pg_map)
		local res={}

		if hupai_type==3 then
			if geng_num>0 then
				--龙7对
				geng_num=geng_num-1
				res.long_qi_dui=normal_majiang.MULTI_TYPES.long_qi_dui
			else
				--7对
				res.qi_dui=normal_majiang.MULTI_TYPES.qi_dui
			end
		elseif  hupai_type==2 then
			--大对子
			res.da_dui_zi=normal_majiang.MULTI_TYPES.da_dui_zi

		elseif hupai_type==5 then
			--将对
			res.jiang_dui=normal_majiang.MULTI_TYPES.jiang_dui
		elseif hupai_type==4 then
			--幺九
			res.yao_jiu=normal_majiang.MULTI_TYPES.yao_jiu
		end
		if geng_num>0 then
			res.dai_geng = geng_num
		end
		--检查清一色
		if huaSe_count==1 and kaiguan.qing_yi_se then
			res.qing_yi_se=normal_majiang.MULTI_TYPES.qing_yi_se
		end
		--检查中章
		if check_is_zhongzhang(pai_map,pg_map,kaiguan) then
			res.zhong_zhang=normal_majiang.MULTI_TYPES.zhong_zhang
		end
		--检查门清
		if check_is_menqing(pg_map,kaiguan) then
			res.men_qing=normal_majiang.MULTI_TYPES.men_qing
		end
		--检查金钩钓
		if check_is_jingoudiao(pai_map,kaiguan) then
			res.jin_gou_diao=normal_majiang.MULTI_TYPES.jin_gou_diao
		end

		local mul=0
		for _,v in pairs(res) do
			mul=mul+v
		end
		return {hu_type_info=res,mul=mul,geng_num=geng_num}
	end
	return nil
end
local function tongji_pai_info(pai_map,huaSe)
	local count=0
	huaSe=huaSe or {0,0,0}
	if pai_map then
		for id,v in pairs(pai_map) do
			if v>0 then
				local c=math.floor(id/10)
				huaSe[c]=1
				count=count+v
			end
		end
	end
	return count
end
local function tongji_penggang_info(pg_map,huaSe)
	local count=0
	huaSe=huaSe or {0,0,0}
	if pg_map then
		for id,v in pairs(pg_map) do
			local c=math.floor(id/10)
			huaSe[c]=1
			count=count+3
		end
	end
	return count
end
--杠上花
local function check_is_gangshanghua(act_list,seat_num,kaiguan)
	if kaiguan and not kaiguan.gang_shang_hua then
		return false
	end
	if act_list then
		if #act_list>1 then
			local act1=act_list[#act_list]
			local act2=act_list[#act_list-1]
			if act1.type=="mo_pai" and act1.p==seat_num and (act2.type=="wg" or act2.type=="zg" or act2.type=="ag")  and act2.p==seat_num then
				return true
			end
		end
	end
	return false
end
--杠上炮
local function check_is_gangshangpao(act_list,cp_seat_num,kaiguan)
	if kaiguan and not kaiguan.gang_shang_pao then
		return false
	end
	if act_list then
		if #act_list>2 then
			local act1=act_list[#act_list]
			local act2=act_list[#act_list-1]
			local act3=act_list[#act_list-2]
			if act1.type=="cp" and act1.p==cp_seat_num and act2.type=="mo_pai" and act2.p==cp_seat_num and (act3.type=="wg" or act3.type=="zg" or act3.type=="ag")  and act3.p==cp_seat_num then
				return true
			end
		end
	end
	return false
end
--[[

 参数 总张数14张
 pai_map  手里还没出的牌
 pg  碰杠的牌
 返回
 {
  hu_type_info 其他表示胡牌类型 normal_majiang.MULTI_TYPES
  mul 总番数
  geng_num
 }
 返回 nil 表示不糊
--]]
function normal_majiang.get_hupai_info(pai_map,pg_map,must_que,kaiguan)

  local huaSeMap={0,0,0}
  local count1=tongji_pai_info(pai_map,huaSeMap)
  local count2=tongji_penggang_info(pg_map,huaSeMap)

  local huaSe_count=huaSeMap[1]+huaSeMap[2]+huaSeMap[3]

  if count1+count2~=14 or huaSe_count>2 then
    return nil
  end
  if must_que and huaSeMap[must_que] and huaSeMap[must_que]>0 then
    return nil
  end

  return compute_hupai_info(basefunc.deepcopy(pai_map),pg_map,count1,huaSe_count,kaiguan)
end


function normal_majiang.get_last_cp_by_act_list(act_list,seat_num)
	if act_list then
		local len=#act_list
		for i=len,1,-1 do
			if act_list[i].type=="cp" then
				if seat_num then
					if seat_num and act_list[i].p==seat_num then
						return nil
					end
				end
				return act_list[i],i
			end
		end
	end
	return nil
end
--[[
{
  hu_type_info 其他表示胡牌类型 normal_majiang.MULTI_TYPES
  mul 总番数
  total 总倍数
  geng_num
  dianpao_p --点炮人  自摸没有
  hu_pai  --胡的牌  天胡没有
 }
 --]]
function normal_majiang.get_hupai_all_info(pai_map,pg_map,must_que,act_list,seat_num,zj_seat_num,mopai_count,chupai_count,remain_card,kaiguan)
	local huaSeMap={0,0,0}

	local count1=tongji_pai_info(pai_map,huaSeMap)
	local count2=tongji_penggang_info(pg_map,huaSeMap)

	local huaSe_count=huaSeMap[1]+huaSeMap[2]+huaSeMap[3]

	if  huaSe_count>2 then
	    return nil
	end
	if must_que and huaSeMap[must_que] and huaSeMap[must_que]>0  then
	    return nil
	end
	--是否是自摸
	local is_zimo=true
	--是否是强杠胡
	local is_qiangganghu=false
	--点炮的牌
	local pao_pai
	--点炮的人的座位号
	local pao_p
	--
	if count1+count2==13 then
		local act,pos=normal_majiang.get_last_cp_by_act_list(act_list,seat_num)
		if not act or pos~=#act_list then
			if  kaiguan.qiangganghu and act_list and #act_list>0 and act_list[#act_list].type=="wg" and act_list[#act_list].p~=seat_num then
				act=act_list[#act_list]
				is_qiangganghu=true
			else
				return nil
			end
		end
		is_zimo=false
		pao_pai=act.pai
		pao_p=act.p
		if normal_majiang.flower(pao_pai) ==must_que then
			return nil
		end
		pai_map[pao_pai]=(pai_map[pao_pai] or 0) +1

	end
	local res=normal_majiang.get_hupai_info(pai_map,pg_map,must_que,kaiguan)
	if not is_zimo then
		pai_map[pao_pai]=pai_map[pao_pai] - 1
	end

	if res then
		res.total=0
		--判断自摸
		if is_zimo then
			--自摸加翻
			if kaiguan.zimo_jiafan then
				res.hu_type_info.zimo=normal_majiang.MULTI_TYPES.zimo
			--自摸加点
			elseif kaiguan.zimo_jiadian then
				res.total=res.total+1
			end
			--判断杠上花
			if check_is_gangshanghua(act_list,seat_num,kaiguan) then
				res.hu_type_info.gang_shang_hua=normal_majiang.MULTI_TYPES.gang_shang_hua
			end
			--判断海底捞月
			if kaiguan.hai_di_ly and remain_card==0 then
				res.hu_type_info.hai_di_ly=normal_majiang.MULTI_TYPES.hai_di_ly
			end
			--判断天胡
			if  kaiguan.tian_hu and seat_num==zj_seat_num and chupai_count==0 and mopai_count==0 then
				res.hu_type_info.tian_hu=normal_majiang.MULTI_TYPES.tian_hu
				--天胡不算自摸
				res.hu_type_info.zimo=nil
			else
				--自摸的牌  --天胡没有胡的牌
				res.hu_pai=act_list[#act_list].pai
			end
		else
			--判断杠上炮
			if check_is_gangshangpao(act_list,pao_p,kaiguan) then
				res.hu_type_info.gang_shang_pao=normal_majiang.MULTI_TYPES.gang_shang_pao
			end

			--判断海底炮
			if  kaiguan.hai_di_pao and remain_card==0 then
				res.hu_type_info.hai_di_pao=normal_majiang.MULTI_TYPES.hai_di_pao
			end
			--判断地胡
			if kaiguan.di_hu and pao_p==zj_seat_num and chupai_count==0 and mopai_count==0 and remain_card==55 then
				res.hu_type_info.di_hu=normal_majiang.MULTI_TYPES.di_hu
			end
			if is_qiangganghu then
				res.hu_type_info.qiangganghu=normal_majiang.MULTI_TYPES.qiangganghu
			end
			res.dianpao_p=pao_p
			res.hu_pai=pao_pai
		end
		res.mul=0
		for _,v in pairs(res.hu_type_info) do
			res.mul=res.mul+v
		end
		res.total=res.total+2^res.mul
	end
	return res
end
--[[

-参数  总张数13张
  pai_map  手里还没出的牌
   pg  碰杠的牌
返回
{
  {
    ting_pai
    hu_type_info  表示胡牌类型
    mul 倍数
    geng_num 根的数量
  }
}
如果 未听牌，返回 nil
--]]
function normal_majiang.get_ting_info(pai_map,pg_map,must_que,kaiguan)
  local huaSeMap={0,0,0}
  local count1=tongji_pai_info(pai_map,huaSeMap)
  local count2=tongji_penggang_info(pg_map,huaSeMap)

  local huaSe_count=huaSeMap[1]+huaSeMap[2]+huaSeMap[3]
  if count1+count2~=13 or huaSe_count>2 then
    return nil
  end
  if must_que and huaSeMap[must_que] and huaSeMap[must_que]>0 then
    return nil
  end
  
  local check_have_lianzi=function(pm,s)
    if s+2<40 and pm[s] and pm[s+1] and pm[s+2] and pm[s]>0 and pm[s+1]>0 and pm[s+2]>0  then
      return true
    end
    if s-1>10 and s+1<40 and pm[s] and pm[s+1] and pm[s-1] and pm[s]>0 and pm[s+1]>0 and pm[s-1]>0  then
      return true
    end
    if s-2>10  and pm[s] and pm[s-1] and pm[s-2] and pm[s]>0 and pm[s-1]>0 and pm[s-2]>0  then
      return true
    end
    return false
  end
  local pai_map_copy=basefunc.deepcopy(pai_map)
  local list
  for s=11,39 do
  	if s%10~=0 then
	    pai_map_copy[s]=pai_map_copy[s] or 0
	    pai_map_copy[s]=pai_map_copy[s] + 1
	    if pai_map_copy[s]>1 or check_have_lianzi(pai_map_copy,s) then
	    	local count=tongji_pai_info(pai_map_copy)
	      	local res=compute_hupai_info(basefunc.deepcopy(pai_map_copy),pg_map,count,huaSe_count,kaiguan)
	      	if res then
	        	res.ting_pai=s
	        	list=list or {}
	        	list[#list+1]=res
	     	end
	    end
	    pai_map_copy[s]=pai_map_copy[s] - 1
	    if pai_map_copy[s]==0 then
	      pai_map_copy[s]=nil
	    end
	end
  end
  --
  return list
end
function normal_majiang.get_ting_map_info(pai_map,pg_map,must_que,kaiguan)
	local list=normal_majiang.get_ting_info(pai_map,pg_map,must_que,kaiguan)
	local map
	if list then
		map = {}
		for i,v in ipairs(list) do
			map[v.ting_pai]=v
			map.total_count=i
		end
	end
	return map
end
--检测血流成河胡牌之后还能不能杠   只能暗杠  弯杠
function normal_majiang.check_xueliu_hu_gang(pai_map,pg_map,must_que,gang_pai,ting_map,kaiguan)
	if pai_map[gang_pai] and pai_map[gang_pai]>0 then

		if pai_map[gang_pai]==1 and pg_map[gang_pai]=="peng" then
			pai_map[gang_pai]=nil
			pg_map[gang_pai]="wg"
			local list=normal_majiang.get_ting_map_info(pai_map,pg_map,must_que,kaiguan)
			pai_map[gang_pai]=1
			pg_map[gang_pai]="peng"
			if list then
				if list.total_count==ting_map.total_count and list.total_count and list.total_count>0 then
					for i,v in ipairs(list) do
						if not ting_map[v.ting_pai] then
							return false
						end
					end
					return true
				end
			end
		elseif pai_map[gang_pai]>3 then

			local sum=pai_map[gang_pai]
			pai_map[gang_pai]=nil
			pg_map[gang_pai]="ag"
			local list=normal_majiang.get_ting_map_info(pai_map,pg_map,must_que,kaiguan)
			pai_map[gang_pai]=sum
			pg_map[gang_pai]=nil
			if list then
				if list.total_count==ting_map.total_count and list.total_count and list.total_count>0 then
					for i,v in ipairs(list) do
						if not ting_map[v.ting_pai] then
							return false
						end
					end
					return true
				end
			end
		end
	end

	return false
end
--[[
-参数 总张数14张
 pai_map  手里还没出的牌
 pg  碰杠的牌
返回
{
  chupai={
      {
        ting_pai
        hu_type nil 表示不糊  其他表示胡牌类型
        mul 倍数
        geng 根的数量
      }
  }
}
--]]
function normal_majiang.get_chupai_ting_info(pai_map,pg_map,must_que,kaiguan)
  local huaSeMap={0,0,0}
  local count1=tongji_pai_info(pai_map,huaSeMap)
  local count2=tongji_penggang_info(pg_map,huaSeMap)

  local huaSe_count=huaSeMap[1]+huaSeMap[2]+huaSeMap[3]

  if count1+count2~=14 or (huaSeMap[1]>1 and huaSeMap[2]>1 and  huaSeMap[3]>1) then
    return nil
  end
  local map
  local pai_map_copy=basefunc.deepcopy(pai_map)
  for id,v in pairs(pai_map_copy) do
    if v>0 then
      pai_map_copy[id]=pai_map_copy[id]-1

      local res=normal_majiang.get_ting_info(pai_map_copy,pg_map,must_que,kaiguan)
      if res then
        map=map or {}
        map[id]=res
      end
      pai_map_copy[id]=pai_map_copy[id]+1
    end
  end

  return map
end

--洗牌
local function new_pai_pool()

	local _pai={
			11,12,13,14,15,16,17,18,19,
			11,12,13,14,15,16,17,18,19,
			11,12,13,14,15,16,17,18,19,
			11,12,13,14,15,16,17,18,19,

			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,
			21,22,23,24,25,26,27,28,29,

			31,32,33,34,35,36,37,38,39,
			31,32,33,34,35,36,37,38,39,
			31,32,33,34,35,36,37,38,39,
			31,32,33,34,35,36,37,38,39,
		}

	-- gang
	-- local _pai={
	-- 		11,12,13,14,15,16,17,18,19,
	-- 		11,12,13,14,15,16,17,18,19,
	-- 		11,12,13,14,15,16,17,18,19,
	-- 		11,12,13,14,15,16,17,18,19,

	-- 		24,25,26,27,28,29,
	-- 		24,25,26,27,28,29,
	-- 		24,25,26,27,28,29,
	-- 		28,29,

	-- 		21,22,23,
	-- 		21,22,23,
	-- 		21,22,23,
	-- 		21,22,23,24,

	-- 		34,35,36,
	-- 		34,35,36,
	-- 		34,35,36,
	-- 		34,35,36,25,

	-- 		37,38,39,
	-- 		37,38,39,
	-- 		37,38,39,
	-- 		37,38,39,26,

	-- 		31,32,33,
	-- 		31,32,33,
	-- 		31,32,33,
	-- 		31,32,33,27,
	-- 	}

	-- -- 7 dui
	-- local _pai={
	-- 		16,17,18,19,
	-- 		11,12,13,14,15,16,
	-- 		11,12,13,14,15,16,19,
	-- 		11,12,13,14,15,16,

	-- 		21,22,23,24,25,26,27,28,
	-- 		21,22,23,24,25,26,27,28,29,
			
	-- 		27,28,
	-- 		27,28,
			
	-- 		17,17,18,19,18,29,
	-- 		11,12,29,13,14,15,

	-- 		21,22,23,24,25,26,
	-- 		21,22,23,24,25,26,17,

	-- 		34,35,36,37,38,39,
	-- 		34,35,36,37,38,39,18,
			
	-- 		37,38,39,31,32,33,
	-- 		37,38,39,31,32,33,19,

	-- 		31,32,33,34,35,36,
	-- 		31,32,33,34,35,36,29,
	-- 	}


	-- -- da dui zi
	-- local _pai={
	-- 		11,12,13,14,15,
	-- 		11,12,13,14,15,
	-- 		11,12,13,14,15,
	-- 		15,

	-- 		21,22,23,24,25,26,27,28,29,
	-- 		28,39,
	-- 		28,39,
	-- 		28,39,

	-- 		31,32,33,34,35,36,37,38,39,

	-- 		16,17,18,19,
	-- 		16,17,18,19,
	-- 		16,17,18,19,

	-- 		11,12,13,14,

	-- 		24,25,26,27,
	-- 		24,25,26,27,
	-- 		24,25,26,27,16,

	-- 		29,21,22,23,
	-- 		29,21,22,23,
	-- 		29,21,22,23,17,

	-- 		35,36,37,38,
	-- 		35,36,37,38,
	-- 		35,36,37,38,18,

	-- 		31,32,33,34,
	-- 		31,32,33,34,
	-- 		31,32,33,34,19,
	-- 	}



	-- -- long qi dui
	-- local _pai={
	-- 		16,17,18,19,
	-- 		11,12,13,14,15,16,
	-- 		11,12,13,14,15,16,19,
	-- 		11,12,13,14,15,16,

	-- 		26,21,23,24,25,26,27,28,
	-- 		26,21,23,24,25,26,27,28,29,
			
	-- 		27,28,
	-- 		27,28,
			
	-- 		17,17,18,19,18,29,
	-- 		11,12,29,13,14,15,

	-- 		22,21,22,23,24,25,
	-- 		22,21,22,23,24,25,17,

	-- 		37,35,36,37,38,39,
	-- 		37,35,36,37,38,39,18,
			
	-- 		33,38,34,39,32,33,
	-- 		33,38,34,39,32,33,19,

	-- 		31,31,32,34,35,36,
	-- 		31,31,32,34,35,36,29,
	-- 	}


	-- -- qing yi se - 7 dui
	-- local _pai={
	-- 		11,12,13,14,15,16,17,18,
	-- 		11,12,13,14,15,16,17,18,
	-- 		17,18,
	-- 		17,18,19,

	-- 		21,22,23,24,25,26,27,28,29,
	-- 		21,22,23,24,25,26,27,28,
	-- 		27,28,
	-- 		27,28,

	-- 		37,38,39,
			

	-- 		29,29,19,19,
	-- 		37,38,39,39,38,37,37,

	-- 		11,12,13,14,15,16,
	-- 		11,12,13,14,15,16,19,

	-- 		21,22,23,24,25,26,
	-- 		21,22,23,24,25,26,29,

	-- 		31,32,33,34,35,36,
	-- 		31,32,33,34,35,36,38,

	-- 		31,32,33,34,35,36,
	-- 		31,32,33,34,35,36,39,
	-- 	}


	-- -- qing yi se
	-- local _pai={
	-- 		11,12,13,14,15,16,17,18,
	-- 		11,12,13,14,15,16,17,
	-- 		17,18,19,
	-- 		14,18,

	-- 		24,25,26,27,28,29,
	-- 		21,22,23,24,29,
	-- 		27,28,29,
	-- 		21,22,23,24,25,26,27,29,

	-- 		31,33,34,37,38,
	-- 		31,34,37,38,
			
	-- 		39,28,19,18,19,

	-- 		11,12,13,14,15,16,
	-- 		11,12,13,15,16,17,19,

	-- 		21,22,23,24,25,26,
	-- 		21,22,23,25,26,27,28,

	-- 		31,32,33,37,38,39,
	-- 		32,34,35,37,38,39,36,
			
	-- 		31,32,33,36,36,36,
	-- 		32,33,34,35,35,35,39,
	-- 	}


	-- -- qing long qi dui
	-- local _pai={
	-- 		11,12,13,14,15,16,17,18,19,
	-- 		11,12,13,14,15,16,17,18,19,
	-- 		11,12,13,14,15,16,17,18,19,
	-- 		11,12,13,14,15,16,17,18,19,

	-- 		22,23,24,26,
			
	-- 		32,33,34,35,36,
	-- 		38,39,28,
			
	-- 		29,29,27,28,37,38,37,39,

	-- 		32,33,34,35,36,
	-- 		35,38,39,37,
	-- 		35,38,39,29,

	-- 		22,23,24,26,
	-- 		25,26,27,28,
	-- 		25,26,27,28,29,

	-- 		21,21,21,21,
	-- 		22,23,24,25,
	-- 		22,23,24,25,27,

	-- 		31,31,31,31,
	-- 		32,33,34,36,
	-- 		32,33,34,36,37,

	-- 	}


	-- duan yao jiu
	-- local _pai={
	-- 		11,12,13,14,15,16,17,18,19,
	-- 		11,12,13,14,15,16,17,18,19,
	-- 		11,12,13,14,15,16,17,18,19,
	-- 		11,12,13,14,15,16,17,18,19,

	-- 		21,22,29,
			
	-- 		31,31,36,37,39,
			

	-- 		31,36,38,39,28,37,28,38,35,38,39,
	-- 		31,

	-- 		21,22,23,24,25,26,
	-- 		21,29,27,21,29,29,39,

	-- 		32,33,34,23,24,25,
	-- 		32,33,34,26,27,28,28,

	-- 		32,33,34,35,36,37,
	-- 		22,23,24,25,26,27,35,

	-- 		32,33,34,35,36,37,
	-- 		22,23,24,25,26,27,38,

	-- 	}

	-- jiang dui
	-- local _pai={
	-- 	11,13,14,16,17,19,
	-- 	11,13,14,16,17,19,
	-- 	11,13,14,16,17,19,
	-- 	11,12,13,14,15,16,17,19,

	-- 	21,23,24,26,27,29,
	-- 	21,23,24,26,27,29,
	-- 	21,29,
	-- 	21,22,23,24,25,26,27,28,29,

	-- 	31,33,34,18,36,18,39,

	-- 	32,33,34,35,36,37,38,
	-- 	31,33,34,36,37,31,

	-- 	31,33,34,36,37,39,39,
	-- 	23,24,26,27,37,39,

	-- 	32,35,12,15,18,
	-- 	32,35,12,15,
	-- 	32,35,12,15,

	-- 	22,25,28,38,
	-- 	22,25,28,38,
	-- 	22,25,28,38,18,

	-- }


	-- 一手好牌，天胡
	-- local _pai={

	-- 		26,28,
	-- 		26,28,
	-- 		26,
	-- 		26,27,28,29,
	-- 		35,11,

	-- 		36,36,36,37,37,37,38,38,38,39,39,39,27,
	-- 		31,31,31,32,32,32,33,33,33,34,34,34,35,
	-- 		21,21,22,22,22,23,23,23,24,24,24,36,25,

	-- 		18,19,15,15,14,17,

	-- 		11,11,11,12,12,12,13,13,13,14,15,16,17,
	-- 		16,17,18,19,15,18,19,16,18,19,16,21,14,
	-- 		35,27,27,29,29,29,24,12,13,25,17,25,38,
	-- 		14,21,22,23,31,32,33,34,35,39,28,25,37,
	-- 	}
	-- 一手好牌 过手胡
	-- local _pai={


	-- 		26,11,28,
	-- 		26,28,
	-- 		26,
	-- 		34,34,34,35,
	-- 		35,

	-- 		36,36,36,37,37,37,38,38,38,39,39,39,27,
	-- 		21,21,22,22,22,23,23,23,24,24,24,36,25,
	-- 		16,17,18,19,16,17,18,19,16,17,18,19,16,

	-- 		18,19,15,15,15,21,

	-- 		26,27,28,29,31,31,31,32,32,32,33,33,33,
	-- 		35,27,27,29,29,29,24,12,13,25,17,25,38,
	-- 		14,21,22,23,31,32,33,34,35,39,28,25,37,
	-- 		11,11,11,12,12,12,13,13,13,14,14,14,15,
	-- 	}
	--一炮多响
	-- local _pai={

	-- 		16,17,18,19,
	-- 		16,17,18,19,
	-- 		16,17,18,19,
	-- 		16,17,18,19,

	-- 		26,11,28,
	-- 		26,28,
	-- 		26,
	-- 		26,27,28,29,
	-- 		35,36,38,37,

	-- 		15,35,15,27,27,29,29,29,24,12,13,
	-- 		14,21,22,23,31,32,33,34,35,39,15,28,25,25,25,
	-- 		36,36,36,37,37,37,38,38,24,39,21,33,11,
	-- 		11,12,13,14,15,16,31,32,33,33,33,31,37,
	-- 		24,25,26,27,28,29,12,13,14,14,15,16,21,
	-- 		24,25,26,27,28,29,12,13,14,14,15,16,21,
	-- 		24,25,26,27,28,29,12,13,14,14,15,16,21,
	-- 	}
	--弯杠和抢杠胡
	-- local _pai={

	-- 		16,17,18,19,
	-- 		16,17,18,19,
	-- 		16,17,18,19,
	-- 		16,17,18,19,

	-- 		26,11,28,
	-- 		26,28,
	-- 		26,
	-- 		26,27,28,29,
	-- 		35,36,38,37,

	-- 		15,35,15,27,27,29,29,29,24,12,13,
	-- 		14,21,22,23,31,32,33,34,35,39,15,28,25,25,25,
	-- 		36,36,36,37,35,38,38,16,38,21,33,16,

	-- 		21,35,36,36,35,35,34,34,19,19,19,18,18,
	-- 		11,12,13,14,13,13,16,16,39,39,39,39,38,
	-- 		24,25,26,27,28,29,12,13,14,14,15,21,21,
	-- 		31,31,31,32,33,34,37,11,11,22,22,36,36,
	-- 	}

	--杠但无叫
	-- local _pai={

			
	-- 		39,39,38,21,35,19,33,16,36,19,36,31,31,19,36,37,35,14,38,14,25,25,38,14,16,19,

	-- 		19,19,19,14,14,14,18,11,21,35,39,15,28,
	-- 		39,39,39,38,36,36,36,27,28,29,36,38,37,
	-- 		24,24,24,25,25,25,26,27,28,29,21,21,22,
	-- 		31,31,31,32,32,32,33,34,29,22,36,36,36,
	-- 	}
	
	local _count=#_pai
	local _rand=1
	local _jh
	for _i=1,_count-1 do
		_jh=_pai[_i]
		_rand=random(_i,_count)
		_pai[_i]=_pai[_rand]
		_pai[_rand]=_jh
	end

	return _pai
end

-- 得到牌的花色
function normal_majiang.flower(_pai)
	return floor(_pai/10)
end
local flower = normal_majiang.flower

normal_majiang.flowers =
{
	[1]=true,
	[2]=true,
	[3]=true,
}

-- 定缺是否完成
function normal_majiang.is_ding_que_finished(_values)
	for i=1,SEAT_COUNT do
		if not _values[i] or not normal_majiang.flowers[_values[i]]  then
			return false
		end
	end

	return true
end

-- map 的牌集合 转换为 list
function normal_majiang.get_pai_list_by_map(_pai_map)
	if _pai_map then
		local list={}
		for _pai_id,_count in pairs(_pai_map) do
			for i=1,_count do
				list[#list+1]=_pai_id
			end
		end
		return list
	end

	return nil
end

-- list 牌的集合 转换为 map
function normal_majiang.get_pai_map_by_list(_pai_list)
	if _pai_list then
		local map = {}
		for _,_pai in ipairs(_pai_list) do
			map[_pai] = (map[_pai] or 0) + 1
		end

		return map
	end

	return nil
end


-- 转换 pai 的 list 为string，支持多个，每个之间用 | 隔开
function normal_majiang.pai_list_tostring(...)
	local _lists = {...}
	local _lss = {}
	for _,_list in ipairs(_lists) do
		local strs = {}
		for _,_pai in ipairs(_list) do
			strs[#strs + 1] = tostring(_pai)
		end

		_lss[#_lss + 1] = table.concat(strs,",")
	end

	return table.concat(_lss,"|")
end

local function _pai_order(_pai,_que_flower)
	if flower(_pai) == _que_flower then
		return _pai + 99999
	else
		return _pai
	end
end

-- 排序
-- 参数：
--	_pai_list 牌的列表
--	_que_pai （可选）打缺的花色，会排在最后
function normal_majiang.sort_pai(_pai_list,_que_flower)
	table.sort(_pai_list,function(_p1,_p2)
		return _pai_order(_p1,_que_flower)  <  _pai_order(_p2,_que_flower)
	end)
end

-- 自动出牌
function normal_majiang.auto_chupai(_mo_pai,_pai_map,_que_pai)

	--摸的牌恰好是缺直接打
	if _mo_pai and flower(_mo_pai) == _que_pai then
		return _mo_pai
	end

	local ret = _mo_pai

	-- 找一张缺牌没有就其他牌
	for _pai,_num in pairs(_pai_map) do

		if _num > 0 then
			if flower(_pai) == _que_pai then
				return _pai
			end
			if not ret then
				ret = _pai
			end
		end

	end

	return ret
end


-- 根据手上的牌，找一个最合适的花色定缺
-- 参数 _pai_list ： 牌的数组
function normal_majiang.ding_que(_pai_list)

	local _flower = {}

	for _,_pai in ipairs(_pai_list) do
		local f = flower(_pai)
		_flower[f] = (_flower[f] or 0) + 1
	end

	if (_flower[1] or 0) > (_flower[2] or 0) then
		return (_flower[2] or 0) > (_flower[3] or 0) and 3 or 2
	else
		return (_flower[1] or 0) > (_flower[3] or 0) and 3 or 1
	end
end

local function copy_pai_map(_pai_map)
	local ret = {}
	for _pai,_count in pairs(_pai_map) do
		ret[_pai] = _count
	end

	return ret
end

--[[ 计算 碰 杠 胡
 参数：
 	_pai_map,_pai_pg_map ： 手上的牌，碰杠的牌
 	_pai : 牌，如果为 nil ，则为 判断天胡
 	_is_self : 是否是自己摸起来的牌
 返回 nil 或一个表：
	{
		peng=_pai
		gang=, （"zg" 直杠, "ag" 暗杠， "wg" 弯杠）
		hu={
			hu_type_info={qing_yi_se=2,da_dui_zi=1,...}, -- 胡牌牌型（所有方案里面最大的）
			mul      总倍数
			geng_num 总根数
		}
	}
--]]
function normal_majiang.get_peng_gang_hu(_pai_map,_pai_pg_map,_pai,_is_self)

	-- 处理天胡的 情况
	if not _pai then
		local _hu = normal_majiang.get_hupai_info(_pai_map,_pai_pg_map)
		if _hu then
			return {hu = _hu }
		else
			return nil
		end
	end

	local ret

	if (_pai_map[_pai] or 0) >= 2 then
		if not ret then ret = {} end
		ret.peng = _pai
	end

	if (_pai_map[_pai] or 0) >= 3 then
		if not ret then ret = {} end
		ret.gang = _is_self and "ag" or "zg"
	elseif _is_self and (_pai_pg_map[_pai] or 0) >= 3 then
		if not ret then ret = {} end
		ret.gang = "wg"
	end

	-- 调用胡牌函数
	local _count = _pai_map[_pai] or 0
	_pai_map[_pai] = _count + 1
	local hu_pai = normal_majiang.get_hupai_info(_pai_map,_pai_pg_map)
	_pai_map[_pai] = _count > 0 and _count or nil

	if hu_pai then
		if not ret then ret = {} end
		ret.hu = hu_pai
	end

	return ret
end

--发牌
function  normal_majiang.fapai(_play_data,_zhuang_seat,zhangshu)
	zhangshu=zhangshu or 4
	if zhangshu>13 then
		zhangshu=13
	end

	-- 先每人发 13 张
	local _len = #_play_data.pai_pool
	local _count=13
	local _pai
	while _count>0 do
		for i=1,SEAT_COUNT do
			for j=1,zhangshu do
				_pai=_play_data.pai_pool[_len]
				_play_data[i].pai[_pai] = (_play_data[i].pai[_pai] or 0) + 1
				_play_data.pai_pool[_len]=nil
				_len=_len-1
			end
		end
		_count=_count-zhangshu
		if zhangshu>_count then
			zhangshu=_count
		end
	end

	-- 庄家再发一张
	_pai=_play_data.pai_pool[_len]
	_play_data[_zhuang_seat].pai[_pai] = (_play_data[_zhuang_seat].pai[_pai] or 0) + 1
	_play_data.pai_pool[_len]=nil
	--_play_data.remain_card_count =#_play_data.pai_pool

end

function normal_majiang.pai_count(_play_data)
	return #_play_data.pai_pool
end

function normal_majiang.pop_pai(_play_data)
	-- local len=_play_data.remain_card_count
	-- if len==0 then
	-- 	return nil
	-- end

	if _play_data.pai_empty then
		return nil
	end

	local len=#_play_data.pai_pool
	if len == 0 then
		return nil
	end

	local pai=_play_data.pai_pool[len]
	_play_data.pai_pool[len]=nil
	len=len-1
	if  len==0 then
		_play_data.pai_empty = true
	end
	--_play_data.remain_card_count =len
	return pai
end

-- function normal_majiang.pai_empty(_play_data)
-- 	return _play_data.remain_card_count==0
-- end

-- 下一个 有操作 权座位号
function normal_majiang.next_oper_seat(_play_data,_cur_seat)
	for i=1,SEAT_COUNT do
		_cur_seat = fmod(_cur_seat,SEAT_COUNT) + 1

		-- 未胡牌的 才有发言权
		if not _play_data[_cur_seat].hu_order then
			return _cur_seat
		end
	end

	return nil
end

function normal_majiang.reset_seat_data(_datas,_value)
	for i=1,SEAT_COUNT do
		_datas[i] = basefunc.deepcopy(_value)
	end
end

function normal_majiang.seat_p_count(_datas)

	local _count = 0
	for i=1,SEAT_COUNT do
		if _datas[i] then
			_count = _count + 1
		end
	end

	return _count
end


function  normal_majiang.new_game()

	local _play_data={}

	-- 庄家
	_play_data.zhuang_seat=0

	--当前有摸牌权限的人
	_play_data.cur_p=0

	-- 当前出牌
	_play_data.cur_chupai={p=nil,pai=nil}

	-- 牌池
	_play_data.pai_pool = new_pai_pool()

	_play_data.pai_empty = false -- 牌池是否为空

	--_play_data.remain_card_count=108

	-- 正在等待选择 碰杠胡的 人 seat_num => 函数 get_peng_gang_hu 返回的数据
	_play_data.wait_pengganghu_data={}

	-- 正在等待选择 胡的 人 seat_num => 胡牌类型 "zimo"/"pao"/"qghu" , 自摸/别人点炮/抢杠胡 ，如果有，则需要挂起碰杠
	_play_data.wait_hu_data={}

	-- 挂起的碰杠（收到消息，但挂起操作），{pg_type="peng"/"wg"/"zg",pai=,seat_num=}
	_play_data.suspend_peng_gang = nil

	-- 定缺数据
	_play_data.p_ding_que = {}

	--玩家数据 key=位置号（1，2，... SEAT_COUNT）
	for i=1,SEAT_COUNT do

		_play_data[i]={

			--手里牌列表：key -> count ；！！注意：为 0 的时候一定要设为 nil
			pai={},
			--倒下的牌：碰或杠， pai -> count ，注意： .pai 和 .pg_pai 中不会重复
			pg_pai={},
			--碰杠类型 pai -> zg/wg/ag/peng
			pg_type={},
			--当前摸到的牌
			mo_pai = nil,

			--胡牌顺序号，nil 表示未胡牌
			hu_order=nil,
			--胡的牌
			hu_pai=nil,

			-- ‘过’ 牌标志：记录最近一次 放弃胡牌的 牌 和 座位号；用于在过庄之前不允许胡这张牌
			guo_pai = nil, -- {pai=,seat=}

			-- 离开：已经离开房间
			is_quit = false,
		}


	end
	return _play_data
end
function normal_majiang.get_init_jipaiqi()
	local jipaiqi={}
	for i=1,27 do
		jipaiqi[i]=4
	end
	return jipaiqi
end
function normal_majiang.jipaiqi_kick_pai(pai,jipaiqi,num)
	if pai  then
		pai=pai%10+math.floor(pai/10-1)*9
		if jipaiqi[pai] then
			num=num or 1
			jipaiqi[pai]=jipaiqi[pai]-num
			if jipaiqi[pai]<0 then
				print("记牌器 减牌变成负数")
				jipaiqi[pai]=0
			end
		end
	end
end

return normal_majiang
