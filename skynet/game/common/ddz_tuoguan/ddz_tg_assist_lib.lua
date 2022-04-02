local basefunc = require "basefunc"
local printfunc = require "printfunc"
local LysCards=require "ddz_tuoguan.lys_cards"
local ExistAnalysis= require "ddz_tuoguan.exist_analysis"

local skynet = require "skynet_plus"
local tgland_core = require "tgland.core"


local  this={}
-- 出牌类型
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
    -- 16: 假王炸
    -- 17: 超级炸弹
	-- 18：超级王炸
local nor_data_ddz_cfg={
		limit={
			sz_min_len={5,3,2} ,  --1表示顺子  2表示连对 3飞机
			sz_max_len={12,10,6},
		},
		kaiguan={
			[1]=1,
			[2]=1,
			[4]=1,
			[6]=1,
			[7]=1,
			[8]=1,
			[10]=1,
			[13]=1,
			[14]=1,

			[3]=1,
			[5]=1,
			[9]=1,
			[11]=1,
			[12]=1,
		},
}

local mld_data_ddz_cfg={
	limit={
		sz_min_len={5,3,2} ,  --1表示顺子  2表示连对 3飞机
		sz_max_len={12,10,6},
	},
	kaiguan={
		
		[1]=1,
		[2]=1,
		[4]=1,
		[6]=1,
		[7]=1,
		[8]=1,
		[10]=1,
		[13]=1,
		[14]=1,

		[3]=nil,
		[5]=nil,
		[9]=nil,
		[11]=nil,
		[12]=nil,
	},
}

this.data_ddz_cfg=nor_data_ddz_cfg


function this.set_game_type(_type)
	if "mld" == _type then
		this.data_ddz_cfg = mld_data_ddz_cfg
	else
		this.data_ddz_cfg = nor_data_ddz_cfg
	end
end

local function change_pai_count(pai_map,_pai,_add,_count)
	if _add then
		pai_map[_pai] = (pai_map[_pai] or 0) + _count
	else
		pai_map[_pai] = pai_map[_pai] - _count
	end

	if pai_map[_pai] < 1 then
		pai_map[_pai] = nil
	end
end
-- 判断手牌 是否包含要出的牌
-- 参数 pai_type 牌组合的类型
--		pai 牌组合的数据数组
--		add ： 加入 true， 去掉 false
-- 返回 true/false
local function change_pai_map_data(pai_map,pai_type,pai,add)

	-- 单牌, 对子,三不带
	if pai_type <= 3 then
		change_pai_count(pai_map,pai[1],add,pai_type)
	end

	if pai_type == 4 then --  三带一 
		change_pai_count(pai_map,pai[1],add,3)
		change_pai_count(pai_map,pai[2],add,1)
	elseif pai_type == 5 then -- 三带一对
		change_pai_count(pai_map,pai[1],add,3)
		change_pai_count(pai_map,pai[2],add,2)
	elseif pai_type == 6 or pai_type == 7 then -- 顺子、连对

		local _count = pai_type == 6 and 1 or 2
		for i=pai[1],pai[2] do
			change_pai_count(pai_map,i,add,_count)
		end

	elseif pai_type == 8 then -- 四带2

		change_pai_count(pai_map,pai[1],add,4)
		change_pai_count(pai_map,pai[2],add,1)
		change_pai_count(pai_map,pai[3],add,1)

	elseif pai_type == 9 then -- 四带2对

		change_pai_count(pai_map,pai[1],add,4)
		change_pai_count(pai_map,pai[2],add,2)
		change_pai_count(pai_map,pai[3],add,2)

	elseif pai_type == 10 or pai_type == 11 or pai_type == 12 then 

		-- 飞机带单牌、飞机带对子,飞机  不带

		for i=pai[1],pai[2] do
			change_pai_count(pai_map,i,add,3)
		end

		if pai_type == 10 or pai_type == 11 then

			local _count = pai_type == 10 and 1 or 2
			for i=3,3 + (pai[2]-pai[1]) do
				change_pai_count(pai_map,pai[i],add,_count)
			end
		end

		return true
	elseif pai_type == 13 then -- 炸弹
		change_pai_count(pai_map,pai[1],add,4)
	elseif pai_type == 14 then -- 王炸
		change_pai_count(pai_map,16,add,1)
		change_pai_count(pai_map,17,add,1)
	end
end     
--获得牌的控手数据 pai_type 牌类型 pai_data牌数据list  单牌 2以上的都算做下叫
function  this.get_zhanshou_data(pai_type,pai_data,my_seat,query_map)
	if pai_data and type(pai_data)=="table" then
		--=控手牌数量
		local ctrl=0
		--非控手牌 小于7分的
		local no_ctrl=0
		for k,v in ipairs(pai_data) do
			local s=this.get_pai_score(query_map,my_seat,pai_type,v) 

			--v.score= s 

			--单牌2以上都算控手 
			if s>6 or (pai_type==1 and v[1]>14) then
				ctrl=ctrl+1
			else
				no_ctrl=no_ctrl+1
			end
		end
		return ctrl,no_ctrl
	end
	return 0,0
end




--绝对下叫  不考虑2的情况
function  this.get_sure_zhanshou_data(pai_type,pai_data,my_seat,query_map)
	if pai_data and type(pai_data)=="table" then
		--=控手牌数量
		local ctrl=0
		--非控手牌 小于7分的
		local no_ctrl=0
		for k,v in ipairs(pai_data) do
			local s=this.get_pai_score(query_map,my_seat,pai_type,v) 
			--单牌2以上都算控手 
			if s>6 then
				ctrl=ctrl+1
			else
				no_ctrl=no_ctrl+1
			end
		end
		return ctrl,no_ctrl
	end
	return 0,0

end

function this.get_abs_zhanshou_data(pai_type,pai_data,my_seat,query_map,all_unkown) 

	if pai_data and type(pai_data)=="table" then

		--绝对控手的数量
		local abs_ctrl =0

		--=控手牌数量
		local ctrl=0

		--非控手牌 小于7分的
		local no_ctrl=0

		for k,v in ipairs(pai_data) do
			local s,is_abs=this.get_pai_score(query_map,my_seat,pai_type,v,all_unkown) 
			--[[
			v.score=s 
			v.is_abs=is_abs
			--]]

			--dump(v,pai_type)
			--print(s,is_abs)

			--单牌2以上都算控手 
			if s>6 then

				if is_abs then 
					abs_ctrl=abs_ctrl+1
				else 
					ctrl=ctrl+1
				end

			else
				no_ctrl=no_ctrl+1
			end
		end

		return abs_ctrl,ctrl,no_ctrl

	end

	return 0,0,0
end




--获取一种类型的牌的多余非占牌数量
function this.get_extraNozhanshou_sum(pai_type,pai_data,my_seat,query_map,use_sure)
	local ctrl =nil 
	local no_ctrl = nil 

	if use_sure then 
		ctrl,no_ctrl=this.get_sure_zhanshou_data(pai_type,pai_data,my_seat,query_map)
	else 
		ctrl,no_ctrl=this.get_zhanshou_data(pai_type,pai_data,my_seat,query_map)
	end

	if no_ctrl-ctrl<0 then
		return 0,ctrl,no_ctrl
	end


	return no_ctrl-ctrl,ctrl,no_ctrl 
end
--分析控手一个类型的牌的控手类型  --
--[[ 
返回值
0绝对控制 AB 或 A型  ctrl>=no_ctrl
1相对控制 控制数量 非控制牌数量 no_ctrl-ctrl=1
2 负数没有控制权 控制数量 非控制牌数量
--]]
function  this.analysis_pai_ctrl_type(pai_type,pai_data,my_seat,query_map,use_sure)
	local extraNozhanshou_sum,ctrl,no_ctrl= this.get_extraNozhanshou_sum(pai_type,pai_data,my_seat,query_map,use_sure)
	if extraNozhanshou_sum==0 then
		return 0,ctrl,no_ctrl
	elseif extraNozhanshou_sum==1 then
		return 1,ctrl,no_ctrl
	else
		return 2,ctrl,no_ctrl
	end
end



function this.analysis_pai_abs_ctrl_type(type,pai_data,my_seat,query_map,all_unkown)
	return this.get_abs_zhanshou_data(type,pai_data,my_seat,query_map,all_unkown)
end






--[[
返回值：
下叫类型
1 a 全是a
2 a_1_b ab类型 但是只有一个 ab
3 ab ab类型 有多个ab
4 a7b  有多个ab和一个a7b 
5 abc abc 类型
0 未下叫
--]]


function this.check_is_xiajiao_absolute(fen_pai,my_seat,query_map,all_unkown)
	--dump(fen_pai,my_seat)

	local a=0
	local ab=0
	local abc=0

	local a7b=0

	local no=0
	local extraNozhanshou=0

	--统计炸弹数量
	local bomb=0

	if fen_pai[13] then
		bomb=bomb+#fen_pai[13]
	end
	if fen_pai[14] then
		bomb=bomb+1
	end

	for i=1,12 do
		if fen_pai[i] and this.data_ddz_cfg.kaiguan[i]==1 then
			local abs_ctrl,ctrl, no_ctrl=this.analysis_pai_abs_ctrl_type(i,fen_pai[i],my_seat,query_map,all_unkown)
			--[[
			fen_pai[i].abs_ctrl=abs_ctrl 
			fen_pai[i].ctrl=ctrl 
			fen_pai[i].no_ctrl=no_ctrl
			--]]

			if abs_ctrl - no_ctrl >=0 then 
				if abs_ctrl > 0 then 
					if no_ctrl ==0 then 
						a=a+1 
					else 
						ab=ab+1 
					end
				end
			elseif no_ctrl- abs_ctrl == 1 then 
				if ctrl >= 1 then 
					a7b =a7b + 1 
				else 
					abc=abc+1 
				end
				extraNozhanshou=extraNozhanshou+no_ctrl-abs_ctrl
			else
				no=no+1
				extraNozhanshou=extraNozhanshou+no_ctrl-abs_ctrl
			end
		end
	end
	--如果不允许三不带  最后三张牌也可以三不带
	if this.data_ddz_cfg.kaiguan[3]~=1 and fen_pai[3] and #fen_pai[3]>0 then
		local shoushu=0
		for i=1,13 do
			if fen_pai[i] then
				shoushu=shoushu+#fen_pai[i]
			end
		end
		if fen_pai[14] then
			shoushu=shoushu+1
		end
		if shoushu>1 then
			no=no+1
			extraNozhanshou=extraNozhanshou+1
		else
			a=a+1
		end
	end

	if extraNozhanshou-bomb>1 then
		return 0,bomb-extraNozhanshou
	end
	--print(a,ab,abc,no,a7b)

	if ab==0 and abc==0 and no==0 and a7b == 0 then
		return 1,0 
	end

	if extraNozhanshou-bomb<=0 then
		if ab<2 and abc==0 and no==0 and a7b == 0 then
			return 2,0 
		end

		if  abc==0 and no==1 and a7b ==0 then
			return 3,0 
		end

		if abc == 0 and no ==1 and a7b == 1 then 
			return 4,0 
		end
	end

	return 5,0
end


--检查牌是否处于赢结构  下叫
--[[
下叫结构
每一个类别  (控手牌数量 >= 非控手牌数量 ) 
则当前类别 多余非控手牌数量 为零

所有类别多余非控手牌数量 - 炸弹数量<=1


返回值：
下叫类型
1 a 全是a
2 a_1_b ab类型 但是只有一个 ab
3 ab ab类型 有多个ab
4 abc abc 类型
0 未下叫
--]]

function this.check_is_xiajiao(fen_pai,my_seat,query_map,use_sure)

	local a=0
	local ab=0
	local abc=0

	local no=0
	local extraNozhanshou=0

	--统计炸弹数量
	local bomb=0

	local no_shoushu=0

	if fen_pai[13] then
		bomb=bomb+#fen_pai[13]
	end
	if fen_pai[14] then
		bomb=bomb+1
	end


	for i=1,12 do
		if fen_pai[i] and this.data_ddz_cfg.kaiguan[i]==1 then
			local status,ctrl,no_ctrl=this.analysis_pai_ctrl_type(i,fen_pai[i],my_seat,query_map,use_sure)
			if status==0 then
				if no_ctrl==0 then
					a=a+1
				else
					ab=ab+1
				end
			elseif status==1 then
				abc=abc+1
				extraNozhanshou=extraNozhanshou+1
				no_shoushu=no_shoushu+no_ctrl+ctrl
			elseif status==2 then
				no=no+1
				extraNozhanshou=extraNozhanshou+no_ctrl-ctrl
				no_shoushu=no_shoushu+no_ctrl+ctrl
			end
		end
	end
	--如果不允许三不带  最后三张牌也可以三不带
	if this.data_ddz_cfg.kaiguan[3]~=1 and fen_pai[3] and #fen_pai[3]>0 then
		local shoushu=0
		for i=1,13 do
			if fen_pai[i] then
				shoushu=shoushu+#fen_pai[i]
			end
		end
		if fen_pai[14] then
			shoushu=shoushu+1
		end
		if shoushu>1 then
			no=no+1
			extraNozhanshou=extraNozhanshou+1
		else
			a=a+1
		end
	end
	if extraNozhanshou-bomb>1 then
		return 0,bomb-extraNozhanshou
	end
	if ab==0 and abc==0 and no==0 then
		return 1,0 
	end
	if extraNozhanshou==1 and no_shoushu==1 and ab==0 and abc<=1 then
		return 2,0
	end

	if extraNozhanshou-bomb<=0 then
		if ab<2 and abc<1 and no<1 then
			return 2,0 
		end
		return 3,0
	end
	return 4,0
end
--不包含 4带2 顺子 和 连队 飞机的判断
function this.check_is_xiajiao_special(fen_pai,my_seat,query_map,use_sure)
	local a=0
	local ab=0
	local abc=0

	local no=0
	local extraNozhanshou=0

	local no_shoushu=0

	--统计炸弹数量
	local bomb=0

	if fen_pai[13] then
		bomb=bomb+#(fen_pai[13])
	end
	if fen_pai[14] then
		bomb=bomb+1
	end


	for i=1,5 do
		if fen_pai[i] and this.data_ddz_cfg.kaiguan[i]==1 then
			local status,ctrl,no_ctrl=this.analysis_pai_ctrl_type(i,fen_pai[i],my_seat,query_map,use_sure)

			if status==0 then
				if no_ctrl==0 then
					a=a+1
				else
					ab=ab+1
				end
			elseif status==1 then
				abc=abc+1
				extraNozhanshou=extraNozhanshou+1
				no_shoushu=no_shoushu+no_ctrl+ctrl
			elseif status==2 then
				no=no+1
				extraNozhanshou=extraNozhanshou+no_ctrl-ctrl
				no_shoushu=no_shoushu+no_ctrl+ctrl
			end


		end
	end

	--如果不允许三不带  最后三张牌也可以三不带
	if this.data_ddz_cfg.kaiguan[3]~=1 and fen_pai[3] and #fen_pai[3]>0 then
		local shoushu=0

		for i=1,13 do
			if fen_pai[i] then
				shoushu=shoushu+#fen_pai[i]
			end
		end
		if fen_pai[14] then
			shoushu=shoushu+1
		end

		if shoushu>1 then
			no=no+1
			extraNozhanshou=extraNozhanshou+1
		else
			a=a+1
		end
	end


	if extraNozhanshou-bomb>1 then
		return 0,bomb-extraNozhanshou
	end
	if ab==0 and abc==0 and no==0 then
		return 1,0 
	end
	if extraNozhanshou==1 and no_shoushu==1 and ab==0 and abc<=1 then
		return 2,0
	end


	if extraNozhanshou-bomb<=0 then
		if ab<2 and abc<1 and no<1 then
			return 2,0 
		end
		return 3,0
	end
	return 4,0
end




-- 移除某类型的牌，
-- force如果为true 表示要求如果没有些类型的牌，则对其它类型的牌进行强拆
--
-- 移除成功，返回true
-- 移除失败，返回false 

function this.remove_pai(pai_struct,pai_data,force) 

end





--出牌后是否下叫
function this.check_is_xiajiao_by_cp(cp_data,pai_struct,query,check_bomb,check_rocket)
end


--获得关键牌
function this.get_key_pai(pai_type,pai_data)

	if pai_type==0 then
		return nil
	end

	if pai_type<6 or pai_type==8 or pai_type==9 or pai_type==13 then
		--dump(pai_data)
		return pai_data[1]

	elseif  pai_type==6 or pai_type==7 or pai_type==10 or pai_type==11 or pai_type==12 then
		return pai_data[2]
	elseif pai_type==14 then
		return 17
	end
	return nil

end



--获取你的价值牌  顺子类的  取中位数
function this.get_key_value_pai(pai_type,pai_data)

	if pai_type == 4 or pai_type == 5 or pai_type <= 3 then 
		return pai_data[1]
	end

	if pai_type == 8 or pai_type == 9 then 
		if pai_data[1] < 14 then 
			return 14 
		end
		return pai_data[1]
	end

	if pai_type == 6 then 
		return math.floor((pai_data[1]+pai_data[2])/2) - 1
	end


	if pai_type ==7 or pai_type ==10 or pai_type == 11 or pai_type == 12 then 
		return math.floor((pai_data[1]+pai_data[2])/2)
	end

	if pai_type == 13 then 
		return 18 
	end

	if pai_type == 14 then 
		return 19
	end
	assert(false,"error pai_type("..pai_type..")")

end

function this.get_power_cfg(seat,query_map)
	local nor_pai_power_cfg={}
	nor_pai_power_cfg.my_seat=seat
	nor_pai_power_cfg.query_map=query_map
	nor_pai_power_cfg.base_score=function (pai)
		return pai-10
	end
	nor_pai_power_cfg[1]=function (pai)
		return this.get_pai_score(nor_pai_power_cfg.query_map,nor_pai_power_cfg.my_seat,1,pai)
	end
	nor_pai_power_cfg[2]=function (pai)
		return this.get_pai_score(nor_pai_power_cfg.query_map,nor_pai_power_cfg.my_seat,2,pai)
	end
	nor_pai_power_cfg[3]=function (pai)
		return this.get_pai_score(nor_pai_power_cfg.query_map,nor_pai_power_cfg.my_seat,3,pai)
	end
	nor_pai_power_cfg[4]= function(pai)
		return this.get_pai_score(nor_pai_power_cfg.query_map,nor_pai_power_cfg.my_seat,4,pai)
	end


	nor_pai_power_cfg[5]=function(pai)
		return this.get_pai_score(nor_pai_power_cfg.query_map,nor_pai_power_cfg.my_seat,5,pai)
	end
	nor_pai_power_cfg[6]=function (pai)
		return this.get_pai_score(nor_pai_power_cfg.query_map,nor_pai_power_cfg.my_seat,6,pai)
	end
	nor_pai_power_cfg[7]=function (pai)
		return this.get_pai_score(nor_pai_power_cfg.query_map,nor_pai_power_cfg.my_seat,7,pai)
	end
	nor_pai_power_cfg[8]=function (pai)
		return this.get_pai_score(nor_pai_power_cfg.query_map,nor_pai_power_cfg.my_seat,8,pai)
	end
	nor_pai_power_cfg[9]=function (pai)
		return this.get_pai_score(nor_pai_power_cfg.query_map,nor_pai_power_cfg.my_seat,9,pai)
	end
	nor_pai_power_cfg[10]=function (pai)
		return this.get_pai_score(nor_pai_power_cfg.query_map,nor_pai_power_cfg.my_seat,10,pai)
	end
	nor_pai_power_cfg[11]=function (pai)
		return this.get_pai_score(nor_pai_power_cfg.query_map,nor_pai_power_cfg.my_seat,11,pai)
	end
	nor_pai_power_cfg[12]=function (pai)
		return this.get_pai_score(nor_pai_power_cfg.query_map,nor_pai_power_cfg.my_seat,12,pai)
	end
	nor_pai_power_cfg[13]=function (pai)
		return 15
	end
	nor_pai_power_cfg[14]=function (pai)
		return 15
	end
	return nor_pai_power_cfg
end

--下叫优先并且下叫更好更优先
function this.get_power_cfg_by_xiaojiaobest(seat,query_map)
	local p_cfg=this.get_power_cfg(seat,query_map)
	p_cfg.compare_fenpai=xiaojiaobest_compare_fenpai
end	
--获取一个类型比规定值小的牌 
function this.get_pai_by_small_and_type(pai_type,pai_data,limit_pai,contain_dengyu)
	if pai_data then
		local list={}
		local key=nil
		if limit_pai then
			key=this.get_key_pai(pai_type,limit_pai)
		end
		for k,v in ipairs(pai_data) do
			if not key or this.get_key_pai(pai_type,v)<key or (contain_dengyu and this.get_key_pai(pai_type,v)==key) then
				if pai_type~=6 and pai_type~=7 and pai_type~=10 and pai_type~=11 and pai_type~=12 then
					list[#list+1]=v
				elseif (pai_type==6 or pai_type==7 or (pai_type>9 and pai_type<13)) and v[2]-v[1]<=limit_pai[2]-limit_pai[1] then
					list[#list+1]=v
				end
			end
		end
		return list
	end
	return nil
end
--获取一个类型比规定值大的牌
function this.get_pai_by_big_and_type(pai_type,pai_data,limit_pai,contain_dengyu)

	if pai_data then
		local list={}
		local key=nil
		if limit_pai then
			key=this.get_key_pai(pai_type,limit_pai)
		end

		for k,v in ipairs(pai_data) do

			if not key or this.get_key_pai(pai_type,v)>key or (contain_dengyu and this.get_key_pai(pai_type,v)==key) then
				if pai_type~=6 and pai_type~=7 and pai_type~=10 and pai_type~=11 and pai_type~=12 then
					list[#list+1]=v
				elseif (pai_type==6 or pai_type==7 or (pai_type>9 and pai_type<13)) and v[2]-v[1]==limit_pai[2]-limit_pai[1] then
					list[#list+1]=v
				end
			end
		end
		return list
	end
	return nil
end
--获取一个类型比规定值大的非占手牌
function this.get_pai_by_big_and_type_noctrl(pai_type,pai_data,limit_pai,seat,query_map)

	if pai_data then
		local list={}
		local key=nil
		if limit_pai then
			key=this.get_key_pai(pai_type,limit_pai)
		end
		for k,v in ipairs(pai_data) do
			if not key or this.get_key_pai(pai_type,v)>key and this.get_pai_score(query_map,seat,pai_type,v)<7 then

				if pai_type~=6 and pai_type~=7 and pai_type~=10 and pai_type~=11 and pai_type~=12 then
					list[#list+1]=v
				elseif  (pai_type==6 or pai_type==7 or (pai_type>9 and pai_type<13)) and v[2]-v[1]==limit_pai[2]-limit_pai[1] then
					list[#list+1]=v
				end

			end
		end
		return list
	end
	return nil

end

function this.get_paiEnum(pai_map)

	local face_3=3
	local face_a=14 
	local face_2=15 
	local face_lw=16
	local face_bw=17


	local ret={
		[1]={},
		[2]={},
		[3]={},

		[4]={},
		[5]={},

		[6]={}, --顺子
		[7]={}, --连队

		[13]={}, --炸弹
		[14]=nil --王炸

	}


	local lys_cards=LysCards.new()
	lys_cards:set_fcards2(pai_map) 
	local max_serial_1=lys_cards:get_maxSerialNu(1)
	local max_serial_2=lys_cards:get_maxSerialNu(2)
	--print(max_serial_1, max_serial_2)

	--处理单张，对子，三张，炸弹
	for i=face_bw,face_3,-1 do 
		local f_nu=lys_cards._face_nu[i] 
		if f_nu ==1 then 
			ret[1][#ret[1]+1]={i}
		elseif f_nu ==2 then 
			ret[1][#ret[1]+1]={i}
			ret[2][#ret[2]+1]={i}

		elseif f_nu == 3 then 
			ret[1][#ret[1]+1]={i}
			ret[2][#ret[2]+1]={i}
			ret[3][#ret[3]+1]={i}
		elseif f_nu == 4 then 
			ret[1][#ret[1]+1]={i}
			ret[2][#ret[2]+1]={i}
			ret[3][#ret[3]+1]={i}
			ret[13][#ret[13]+1]={i}
		end
	end

	--处理顺子
	for s=5,max_serial_1 do 
		for f=face_a,face_3+s-1,-1 do 
			if lys_cards:get_serialSingleTypeFaceNu(s,f)>0 then 
				ret[6][#ret[6]+1]={f-s+1,f}
			end
		end
	end

	--处理对子 
	for s=3,max_serial_2 do 
		for f=face_a,face_3+s-1,-1 do 
			if lys_cards:get_serialPairTypeFaceNu(s,f)> 0 then 
				ret[7][#ret[7]+1]={f-s+1,f}
			end
		end
	end

	--处理和三带一对
	for _,v3 in ipairs(ret[3]) do 
		for _,v1 in ipairs(ret[1]) do 
			if v3[1]~=v1[1] then 
				ret[4][#ret[4]+1]={v3[1],v1[1]}
			end
		end

		for _,v2 in ipairs(ret[2]) do 
			if v3[1]~=v2[1] then 
				ret[5][#ret[5]+1]={v3[1],v2[1]}
			end
		end
	end

	if lys_cards:get_rocketTypeNu() > 0 then 
		ret[14]=true

	end

	return ret

end

-- 判断手牌 是否包含要出的牌
-- 参数 pai_data : {type=,pai=}
-- 返回 true/false
function this.check_pai_is_exist(pai_map,pai_data)

	-- 单牌, 对子,三不带
	if pai_data.type <= 3 then
		return (pai_map[pai_data.pai[1]] or 0) >= pai_data.type
	elseif pai_data.type == 4 then --  三带一 
		return  (pai_map[pai_data.pai[1]] or 0) >= 3 and (pai_map[pai_data.pai[2]] or 0) >= 1
	elseif pai_data.type == 5 then -- 三带一对
		return  (pai_map[pai_data.pai[1]] or 0) >= 3 and (pai_map[pai_data.pai[2]] or 0) >= 2
	elseif pai_data.type == 6 or pai_data.type == 7 then -- 顺子、连对

		local _count = pai_data.type == 6 and 1 or 2

		for i=pai_data.pai[1],pai_data.pai[2] do
			if (pai_map[i] or 0) < _count then
				return false
			end
		end

		return true
	elseif pai_data.type == 8 then -- 四带2
		return  (pai_map[pai_data.pai[1]] or 0) >= 4 and 
		(pai_map[pai_data.pai[2]] or 0) >= 1  and
		(pai_map[pai_data.pai[3]] or 0) >= 1
	elseif pai_data.type == 9 then -- 四带2对
		return  (pai_map[pai_data.pai[1]] or 0) >= 4 and 
		(pai_map[pai_data.pai[2]] or 0) >= 2  and
		(pai_map[pai_data.pai[3]] or 0) >= 2
	elseif pai_data.type == 10 or pai_data.type == 11 or pai_data.type == 12 then 

		-- 飞机带单牌、飞机带对子,飞机  不带

		for i=pai_data.pai[1],pai_data.pai[2] do
			if (pai_map[i] or 0) < 3 then
				return false
			end
		end

		if pai_data.type == 10 or pai_data.type == 11 then

			local _count = pai_data.type == 10 and 1 or 2

			for i=3,3 + (pai_data.pai[2]-pai_data.pai[1]) do
				if (pai_map[pai_data.pai[i]] or 0) < _count then
					return false
				end
			end
		end

		return true
	elseif pai_data.type == 13 then -- 炸弹
		return (pai_map[pai_data.pai[1]] or 0) >= 4
	elseif pai_data.type == 14 then -- 王炸
		return (pai_map[16] or 0) >= 1 and (pai_map[17] or 0) >= 1
	end

	return false
end 




-- 判断能否出给定的牌
-- 参数 pai_data0 : 别人出的牌， nil 表示 自己首出
-- 参数 pai_data : 自己要出的牌
-- 返回 true/false
function this.check_can_chupai(pai_data0,pai_data)

	if not pai_data0 then
		return true
	end

	-- 王炸 最大
	if pai_data.type == 14 then
		return true
	elseif pai_data0.type == 14 then
		return false
		-- 炸弹比大小
	elseif pai_data.type == 13 then
		if pai_data0.type == 13 then
			return pai_data.pai[1] > pai_data0.pai[1]
		else
			return true
		end
	elseif pai_data0.type == 13 then
		return false

		-- 同类型比大小
	elseif pai_data.type == pai_data0.type then
		if pai_data0.type == 6 or pai_data0.type == 7 or pai_data0.type == 10 or pai_data0.type == 11 or pai_data0.type ==12 then
			if ((pai_data0.pai[2]-pai_data0.pai[1]) ~= (pai_data.pai[2]-pai_data.pai[1])) then
				return false;
			end
		end
		return pai_data.pai[1] > pai_data0.pai[1]
	else
		return false
	end
end

--[[ 牌数组 加入到出牌 list
-- 参数：
_pai_map 手牌
_type , _pai_array 拆分好的牌
_pai_data 上家的出牌
_cp_list 要加入的 出牌 list
--]]
local function append_chupai_list(_pai_map,_type,_pai_array,_pai_data,_cp_list,kaiguan)
	for _,_pai in ipairs(_pai_array) do
		local _pd = {type=_type,pai=_pai}
		if this.check_can_chupai(_pai_data,_pd) and this.check_pai_is_exist(_pai_map,_pd) then
			_cp_list[#_cp_list + 1] = _pd
		end
	end
end

--[[ 计算出牌列表
参数 
pai_enum ： {[type]={pai1,pai2,...},...}
kaiguan ：允许的出牌类型 （如果是 3 不带 在最后，则总是允许）

返回 可能的出牌列表：{{type=,pai=},...}
无法出牌 返回 nil
--]]
function this.get_can_cp_list(pai_map,pai_enum,pai_data,kaiguan)
	local _cp_list = {}
	if pai_data then

		-- 对方王炸不用看了
		if pai_data.type == 14 then 
			return nil
		end

		-- 加入王炸
		if pai_enum[14] then
			local _pd = {type=14}
			if this.check_pai_is_exist(pai_map,_pd) then
				_cp_list[#_cp_list + 1] = _pd
			end
		end

		-- 加入炸弹
		if pai_enum[13] then
			append_chupai_list(pai_map,13,pai_enum[13],pai_data,_cp_list)
		end

		-- 加入同类型
		if pai_data.type ~= 13 and pai_enum[pai_data.type] then
			append_chupai_list(pai_map,pai_data.type,pai_enum[pai_data.type],pai_data,_cp_list)
		end

	else

		-- 可以出所有的牌
		for _type,_pai_array in pairs(pai_enum) do

			-- 处理3不带开关
			local _can_add = kaiguan[_type]

			if _type == 3 and not _can_add then
				-- 统计牌的张数
				local _sum = 0
				for _,_count in pairs(pai_map) do
					_sum = _sum + _count
				end
				if _sum == 3 then
					_can_add = true
				end
			end

			if _can_add then
				if _type == 14 then
					local _pd = {type=_type}
					if this.check_pai_is_exist(pai_map,_pd) then
						_cp_list[#_cp_list + 1] = _pd
					end
				else
					for _,_pai in ipairs(_pai_array) do
						local _pd = {type=_type,pai=_pai}
						if this.check_pai_is_exist(pai_map,_pd) then
							_cp_list[#_cp_list + 1] = _pd
						end
					end
				end
			end
		end
	end

	return next(_cp_list) and _cp_list
end

-- 指数查表
this.hash_power_table = {
	math.floor(17^1+0.5),math.floor(17^2+0.5),math.floor(17^3+0.5),math.floor(17^4+0.5),math.floor(17^5+0.5),
	math.floor(17^6+0.5),math.floor(17^7+0.5),math.floor(17^8+0.5),math.floor(17^9+0.5),math.floor(17^10+0.5),
	math.floor(17^11+0.5),math.floor(17^12+0.5),math.floor(17^13+0.5),math.floor(17^14+0.5),math.floor(17^15+0.5),
}
local hash_power_table = this.hash_power_table

-- by lyx: 去掉 pai_data
function this.reduce_pai_from_map(pai_map,pai_data)
	change_pai_map_data(pai_map,pai_data.type,pai_data.pai,false)
end
-- 加入 pai_data
function this.add_pai_from_map(pai_map,pai_data)
	change_pai_map_data(pai_map,pai_data.type,pai_data.pai,true)
end
local function pai_data_hash_key(pai_data)

	-- 飞机
	if pai_data.type  == 10 or pai_data.type == 11 then
		local _key = pai_data.type + pai_data.pai[1] * 17 + pai_data.pai[2] * hash_power_table[2]
		local dai_pais = {} -- 带牌，要排序
		for i=3,3 + (pai_data.pai[2]- pai_data.pai[1]) do
			dai_pais[#dai_pais + 1] = pai_data.pai[i]
		end
		table.sort(dai_pais)
		for i,pai in ipairs(dai_pais) do
			if i < 13 then
				_key = _key + pai * hash_power_table[i+2]
			else
				_key = _key .. "_" .. pai
			end
		end

		return _key

		-- 四带二， 四带两对
	elseif pai_data.type == 8 or pai_data.type == 9 then
		if pai_data.pai[2] < pai_data.pai[3]  then -- 固定顺序
			return pai_data.type + pai_data.pai[1] * 17 + pai_data.pai[2] * hash_power_table[2] + pai_data.pai[3] * hash_power_table[3]
		else
			return pai_data.type + pai_data.pai[1] * 17 + pai_data.pai[3] * hash_power_table[2] + pai_data.pai[2] * hash_power_table[3]
		end
	elseif pai_data.type == 4 or pai_data.type == 5 or pai_data.type == 6 or pai_data.type == 7 or pai_data.type == 12 then
		return pai_data.type + pai_data.pai[1] * 17 + pai_data.pai[2] * hash_power_table[2]
	elseif pai_data.type == 1 or pai_data.type == 2 or pai_data.type == 3 or pai_data.type == 13 then
		return pai_data.type + pai_data.pai[1] * 17
	else
		return pai_data.type
	end
end


this.pai_data_hash_key=pai_data_hash_key 

-- by lyx: 存储 hash
function this.store_paidata_by_hash(map,pai_data,value)
	map[this.pai_data_hash_key(pai_data)] = value
end

-- 取出 hash
function this.take_paidata_by_hash(map,pai_data)
	return map[this.pai_data_hash_key(pai_data)]
end

function this.get_pai_count(_type,pai)
	if _type<6 then
		return _type
	elseif _type==6 then
		return pai[2]-pai[1]+1
	elseif _type==7 then
		return (pai[2]-pai[1]+1)*2
	elseif _type==13 then
		return 4
	elseif _type==14 then
		return 2
	elseif _type==8 then
		return 6
	elseif _type==9 then
		return 8
	elseif _type==10 then
		return (pai[2]-pai[1]+1)*4
	elseif _type==11 then
		return (pai[2]-pai[1]+1)*5
	elseif _type==12 then
		return (pai[2]-pai[1]+1)*3
	end
end

--[[
cp_data
{
p 出牌人
type
pai	
}
--]]
-- local times=0
function this.get_all_cp_value_boyi(pai_map,pai_enum,cur_p,seat_type,game_over_info,cp_data,kaiguan,_times_limit,type_limit)
	local res={}
	local res_list={}
	local pai_count={}
	for k,v in ipairs(pai_map) do
		pai_count[k]=0
		for _,c in pairs(v) do
			pai_count[k]=pai_count[k]+c
		end
	end

	local times_limit=_times_limit or 3000

	this.owner_seat_type=seat_type[cur_p]
	this.ptype_kaiguan=kaiguan or this.data_ddz_cfg.kaiguan
	this.pai_enum=pai_enum
	this.game_over_info=game_over_info
	this.seat_type=seat_type	

	local cp_list

	cp_list=this.get_can_cp_list(pai_map[cur_p],this.pai_enum[cur_p],cp_data,this.ptype_kaiguan)
	-- dump(cp_list)
	-- cp_list={ {
	-- 		        pai = {
	-- 		            3,
	-- 		            4,
	-- 		        },
	-- 		        type  = 4,
	-- 		    }
	-- 		}
	local next_times=0
	if cp_list then
		next_times=#cp_list
	end
	if cp_data then
		next_times=next_times+1
	end
	next_times=math.floor(times_limit/next_times)

	local next_p=cur_p+1
	if next_p>#this.seat_type then
		next_p=1
	end

	local _is_max=true
	if  this.seat_type[cur_p]~=this.seat_type[next_p] then
		_is_max=not _is_max
	end

	value=-10000

	--过
	if cp_data and next_times>0  and (not type_limit or type_limit[0]) then
		local _cp_data=cp_data
		if next_p==cp_data.p then
			_cp_data=nil
		end
		local _score=this.search_cp_value_boyi(pai_map,pai_count,0,next_p,_cp_data,next_times,_is_max,value,1)

		this.store_paidata_by_hash(res,{type=0},_score)
		res_list[#res_list+1]={type=0,score=_score}
	end
	if cp_list then
		local p_c=0
		for k,v in ipairs(cp_list) do
			if (not type_limit or type_limit[v.type]) then
				p_c=this.get_pai_count(v.type,v.pai)

				local score=0

				if v.type==14 or v.type==13 then
					score=score+1
				end
				pai_count[cur_p]=pai_count[cur_p]-p_c


				this.reduce_pai_from_map(pai_map[cur_p],v)


				if pai_count[cur_p]<=this.game_over_info[cur_p] then
					score=score+1
				elseif next_times>0  then
					v.p=cur_p
					score=this.search_cp_value_boyi(pai_map,pai_count,score,next_p,v,next_times,_is_max,value,1)
					v.p=nil
				else
					score=0
				end

				--v.score=score

				this.store_paidata_by_hash(res,v,score)
				res_list[#res_list+1]=v

				pai_count[cur_p]=pai_count[cur_p]+p_c
				this.add_pai_from_map(pai_map[cur_p],v)
			end

		end
	end

	-- print("UUuUUUUU  ",times)
	--dump(res_list)
	return res,res_list

end
--is_max true表示max false表示min 
function this.search_cp_value_boyi(pai_map,pai_count,score,cur_p,cp_data,times_limit,is_max,a_b_cut,depth)
	-- dump(pai_data)
	-- dump(this.pai_enum[cur_p])
	-- dump(pai_map[cur_p])
	-- print(cur_p)
	-- times=times+1
	local cp_is_max=is_max

	local cp_list=this.get_can_cp_list(pai_map[cur_p],this.pai_enum[cur_p],cp_data,this.ptype_kaiguan)
	local next_times=0
	if cp_list then
		next_times=#cp_list
	end
	if cp_data then
		next_times=next_times+1
	end
	next_times=math.floor(times_limit/next_times)

	local next_p=cur_p+1
	if next_p>#this.seat_type then
		next_p=1
	end
	local _is_max=is_max
	if  this.seat_type[cur_p]~=this.seat_type[next_p] then
		_is_max=not _is_max
	end

	local last_p=cur_p-1
	if last_p<1 then
		last_p=#this.seat_type
	end
	local last_is_max=is_max
	if this.seat_type[cur_p]~=this.seat_type[last_p] then
		last_is_max=not last_is_max
	end 


	local value=10000
	if is_max then
		value=-10000
	end



	if cp_list then
		local p_c=0
		local _score

		-- --能走必走
		for k,v in ipairs(cp_list) do
			p_c=this.get_pai_count(v.type,v.pai)
			_score=score
			--炸弹
			if v.type==14 or v.type==13 then
				_score=_score+1
			end

			if pai_count[cur_p]-p_c<=this.game_over_info[cur_p] and (v.type~=8 and v.type~=9) then
				_score=_score+1
				if this.owner_seat_type~=this.seat_type[cur_p] then
					_score=-_score
				end
				return _score
			end
		end

		for k,v in ipairs(cp_list) do
			--炸弹
			if v.type==14 or v.type==13 then
				score=score+1
			end
			p_c=this.get_pai_count(v.type,v.pai)
			pai_count[cur_p]=pai_count[cur_p]-p_c
			this.reduce_pai_from_map(pai_map[cur_p],v)

			if pai_count[cur_p]<=this.game_over_info[cur_p] then
				_score=score+1
				if this.owner_seat_type~=this.seat_type[cur_p] then
					_score=-_score
					-- print("xxxx")
				end
				-- print("win  ",_score,cur_p)
			elseif next_times>0 and depth<100 then
				v.p=cur_p
				_score=this.search_cp_value_boyi(pai_map,pai_count,score,next_p,v,next_times,_is_max,value,depth+1)
			else
				_score=0
			end

			if is_max then
				if _score>value then
					value=_score
				end
			else
				if _score<value then
					value=_score
				end
			end

			--炸弹
			if v.type==14 or v.type==13 then
				score=score-1
			end
			pai_count[cur_p]=pai_count[cur_p]+p_c
			this.add_pai_from_map(pai_map[cur_p],v)
			if a_b_cut then
				if is_max then
					--当前是max则上一个一定是min 大于阈值则返回
					if value>=a_b_cut then
						return value
					end
				else
					--上一个是max
					if last_is_max and value<=a_b_cut then
						return value
					end
				end
			end
		end
	end
	--过
	if cp_data and next_times>0 and depth<100 then
		local _cp_data=cp_data
		if next_p==cp_data.p then
			_cp_data=nil
		end
		local _score=this.search_cp_value_boyi(pai_map,pai_count,score,next_p,_cp_data,next_times,_is_max,value,depth+1)
		if is_max then
			if _score>value then
				value=_score
			end
		else
			if _score<value then
				value=_score
			end
		end
	end

	if value==10000 or value==-10000 then
		value=0
	end
	-- if depth==6 then
	-- dump(cp_data)
	-- dump(cp_list)
	-- dump(pai_map)
	-- times=times+1
	-- print(depth,value,cur_p,"dg_sx"..times,is_max,_is_max)

	-- end
	return value
end
--获得cp价值map and list
--[[
data=
{
fen_pai
pai_enum
pai_map
base_info={

}
}
seat 要出牌的人
cur_cp_data --当前出的牌
{
p--出牌人的座位号
type
pai
}
--]]
--old
-- function this.get_cp_value_map(data,seat,cur_cp_data)

-- 	if not data.pai_enum then
-- 		data.pai_enum={}
-- 		for k,v in ipairs(data.pai_map) do
-- 			data.pai_enum[k]=this.get_paiEnum(v)
-- 		end
-- 	end
-- 	--全匹配搜索
-- 	local map,list=this.get_all_cp_value_boyi(data.pai_map,data.pai_enum,seat,data.base_info.seat_type,data.game_over_cfg,cur_cp_data,data.kaiguan,3000)
-- 	--dump(list,"****************")
-- 	--如果是地主并且总人数等于3人 则去掉一个农民搜索
-- 	if data.base_info.seat_type[seat]==1 and #data.base_info.seat_type>2 then
-- 		local pai_enum={}
-- 		pai_enum[1]=data.pai_enum[seat]
-- 		local pai_map={}
-- 		pai_map[1]=data.pai_map[seat]
-- 		local seat_type={1,0}
-- 		local game_over_cfg={}
-- 		game_over_cfg[1]=data.game_over_cfg[seat]
-- 		local cur_cp_data_copy
-- 		if cur_cp_data then
-- 			cur_cp_data_copy=basefunc.deepcopy(cur_cp_data)
-- 			cur_cp_data_copy.p=2
-- 		end
-- 		local res={}
-- 		for k=1,#data.base_info.seat_type do
-- 			if data.base_info.seat_type[k]~=1 then
-- 				pai_enum[2]=data.pai_enum[k]
-- 				pai_map[2]=data.pai_map[k]
-- 				game_over_cfg[2]=data.game_over_cfg[k]
-- 				res[#res+1]={}
-- 				res[#res].map,res[#res].list=this.get_all_cp_value_boyi(pai_map,pai_enum,1,seat_type,game_over_cfg,cur_cp_data_copy,data.kaiguan,2000)
-- 			end
-- 		end
-- 		--刷新map,list数据
-- 		for k,v in pairs(map) do
-- 			for i,n in ipairs(res) do
-- 				if n.map[k] and n.map[k]<0 and n.map[k]<v then
-- 					map[k]=n.map[k]
-- 				end
-- 			end
-- 		end
-- 		for k,v in ipairs(list) do
-- 			v.score=this.take_paidata_by_hash(map,v)
-- 		end
-- 	end
-- 	--按分牌 搜索不要 的情况
-- 	local map2,list2=this.get_all_cp_value_boyi(data.pai_map,data.fen_pai,seat,data.base_info.seat_type,data.game_over_cfg,cur_cp_data,data.kaiguan,300,{[0]=true})
-- 	local hash_v=pai_data_hash_key({type=0})
-- 	if map and map2 and map[hash_v] and map2[hash_v] and map2[hash_v]<0 and map2[hash_v]<map[hash_v] then
-- 		map[hash_v]=map2[hash_v]
-- 		if list and list[1] and list[1].type==0 then
-- 			list[1].score=map[hash_v]
-- 		end
-- 	end
-- 	return map,list
-- end	
--检查牌是否1️以炸弹为主  
function this.check_pai_bomb_main(fen_pai)
	if not fen_pai then
		return false
	end

	local bomb=0
	local dan=0
	local shuang=0
	local other=0
	for i=1,13 do
		if fen_pai[i] then
			if i==1 then
				dan=dan+#fen_pai[i]
			elseif i==2 then
				shuang=shuang+#fen_pai[i]
			elseif i==13 then
				bomb=bomb+#fen_pai[i]
			else
				other=other+#fen_pai[i]
			end
		end
	end
	if fen_pai[14] then
		bomb=bomb+1
	end
	if bomb>=dan+shuang+other then
		return true
	end
	return false

end

function this.get_cp_value_map(data,seat,cur_cp_data)

	local cp_p
	if cur_cp_data then
		cp_p=cur_cp_data.p
	end
	data.kaiguan=data.kaiguan or nor_data_ddz_cfg.kaiguan
	--全匹配搜索 调用c++端
	local list=this.get_boyiSearch(
	data.pai_map,
	data.base_info.seat_type,
	data.game_over_cfg,
	data.kaiguan,
	data.cp_count,
	seat, -- 当前该出牌的人
	#data.base_info.seat_type,
	cp_p, -- 出了牌的人
	cur_cp_data, -- 出了的牌
	5000
	)
	-- dump(list)
	

	local search_times=5000
	local is_not_chaifen=nil
	if seat and  data.fen_pai and this.check_pai_bomb_main(data.fen_pai[seat]) then
		search_times=8000
		is_not_chaifen=true
	end

	local pai_enum=this.get_paiEnum_by_fenPai(data,is_not_chaifen)
	-- dump(pai_enum,"testIIIIIIIIII")
	--掉c++端进行第二次搜索
	local list_2=this.get_boyiSearch_have_pe(
	data.pai_map,
	data.base_info.seat_type,
	data.game_over_cfg,
	data.kaiguan,
	data.cp_count,
	pai_enum,
	seat, -- 当前该出牌的人
	#data.base_info.seat_type,
	cp_p, -- 出了牌的人
	cur_cp_data, -- 出了的牌
	search_times
	)

	-- dump(list_2,"list_2****")

	--生成map和list
	local map={}
	for k,v in ipairs(list) do
		map[this.pai_data_hash_key(v)]=v.score
	end

	local hash_value
	--更新map
	for k,v in ipairs(list_2) do
		hash_value=this.pai_data_hash_key(v)
		if not map[hash_value] then
			list[#list+1]=v
			map[hash_value]=v.score
		else
			if  v.score~=0 and map[hash_value]==0 then
				if v.score~=map[hash_value] then
					map[hash_value]=v.score
				end
			end
		end
	end

	--如果我是农民
	--我主动 出牌尝试能否单独打赢
	--我被动出牌 出牌人是我队友 
	--尝试我能否单独打赢  
	--尝试我的队友能否单独打赢
	--我被动出牌 出牌人是地主 
	--尝试我能否单独打赢 
	--如果下家是队友 尝试他能否单独打赢




	--更新list
	for k,v in ipairs(list) do
		v.score=map[this.pai_data_hash_key(v)]
	end
	-- dump(list)
	return map,list
end
--按分牌方式得到paiEnum 并且和按下叫最优一起合并
function this.get_paiEnum_by_fenPai(data,is_not_chaifen)
	local pai_enum={}
	local power_cfg=this.get_power_cfg(1,data.query_map)
	for i,_ in ipairs(data.base_info.seat_type) do
		local enum={}
		local fen_pai=data.fen_pai[i]
		local pai_map=data.pai_map[i]

		enum[1]={}
		for k,v in pairs(pai_map) do
			if not is_not_chaifen then
				if v>0 then
					enum[1][#enum[1]+1]={type=1,pai={k}}
				end
				--分对子
				if v>1 then
					enum[2]=enum[2] or {}
					enum[2][#enum[2]+1]={type=2,pai={k}}
				end
				--三不带
				if v>2 then
					enum[3]=enum[3] or {}
					enum[3][#enum[3]+1]={type=3,pai={k}}
				end
			end
			if v>3 then
				enum[13]=enum[13] or {}
				enum[13][#enum[13]+1]={type=13,pai={k}}
			end
		end
		if pai_map[16]==1 and pai_map[17]==1 then
			enum[14]=enum[14] or {}
			enum[14][#enum[14]+1]={type=14,pai={}}
		end

		--按下叫最优分牌
		power_cfg.my_seat=i
		local xjbest_fenpai=data.xjbest_fenpai[i]

		-- dump(fen_pai,"fenpai xxxxxxxxx  "..i)
		-- dump(xjbest_fenpai,"xjbest_fenpai xxxxxxxxx  "..i)


		for t=1,12 do
			local hash={}
			if fen_pai[t] and #fen_pai[t]>0 then
				enum[t]={}
				for k,v in pairs(fen_pai[t]) do
					enum[t][#enum[t]+1]={type=t,pai=v}
					hash[this.pai_data_hash_key(enum[t][#enum[t]])]=true
				end
			end
			if xjbest_fenpai[t] and #xjbest_fenpai[t]>0 then
				enum[t]=enum[t] or {}
				for k,v in pairs(xjbest_fenpai[t]) do
					if not hash[this.pai_data_hash_key({type=t,pai=v})] then
						enum[t][#enum[t]+1]={type=t,pai=v}
					end				
				end
			end
		end
		pai_enum[i]=enum
	end
	-- dump(pai_enum)
	return pai_enum

end
-- function this.get_paiEnum_by_fenPai(data)
-- 	local pai_enum={}
-- 	local power_cfg=this.get_power_cfg(1,data.query_map)
-- 	for i,_ in ipairs(data.base_info.seat_type) do
-- 		local enum={}
-- 		local fen_pai=data.fen_pai[i]
-- 		local pai_map=data.pai_map[i]

-- 		local enum_hash={}
-- 		local single_tq_type={[1]=1,[2]=2,[3]=3,[13]=4}
-- 		for k,v in pairs(pai_map) do
-- 			for _type,_count in pairs(single_tq_type) do
-- 				if v==_count then
-- 					enum[_type]=enum[_type] or {}
-- 					enum[_type][#enum[_type]+1]={type=_type,pai={k}}

-- 					enum_hash[_type]=enum_hash[_type] or {}
-- 					enum_hash[_type][this.pai_data_hash_key(enum[_type][#enum[_type]])]=true
-- 				end
-- 			end
-- 		end

-- 		if pai_map[16]==1 and pai_map[17]==1 then
-- 			enum[14]=enum[14] or {}
-- 			enum[14][#enum[14]+1]={type=14,pai={}}
-- 		end


-- 		--按最小牌分解 最大牌分解单牌和对子
-- 		local test_count=2
-- 		local fenjie_pai_type={[1]={p_c=1,count=test_count},[2]={p_c=2,count=test_count}}
-- 		for pai=3,17 do
-- 			if pai_map[pai] and  pai_map[pai]>0 then
-- 				for _type,_data in pairs(fenjie_pai_type) do
-- 					local v=pai_map[pai] 
-- 					if v>_data.p_c and _data.count>0 then
-- 						local pai_data={type=_type,pai={pai}}
-- 						if not enum_hash[_type] or not enum_hash[_type][this.pai_data_hash_key(pai_data)] then
-- 							enum[_type]=enum[_type] or {}
-- 							enum[_type][#enum[_type]+1]=pai_data
-- 							enum_hash[_type]=enum_hash[_type] or {}
-- 							enum_hash[_type][this.pai_data_hash_key(pai_data)]=true
-- 							if pai_map[pai]<4 or _data.have_zhadan then
-- 								_data.count=_data.count-1
-- 							end
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 		--按最大牌分解 最大牌分解单牌和对子
-- 		fenjie_pai_type={[1]={p_c=1,count=test_count},[2]={p_c=2,count=test_count}}
-- 		for pai=17,3,-1 do
-- 			if pai_map[pai] and  pai_map[pai]>0 then
-- 				for _type,_data in pairs(fenjie_pai_type) do
-- 					local v=pai_map[pai] 
-- 					if v>_data.p_c and _data.count>0 then
-- 						local pai_data={type=_type,pai={pai}}
-- 						if not enum_hash[_type] or not enum_hash[_type][this.pai_data_hash_key(pai_data)] then
-- 							enum[_type]=enum[_type] or {}
-- 							enum[_type][#enum[_type]+1]=pai_data
-- 							enum_hash[_type]=enum_hash[_type] or {}
-- 							enum_hash[_type][this.pai_data_hash_key(pai_data)]=true
-- 							_data.count=_data.count-1
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end



-- 		--按下叫最优分牌
-- 		power_cfg.my_seat=i
-- 		local xjbest_fenpai=data.xjbest_fenpai[i]
-- 		for t=4,12 do
-- 			local hash={}
-- 			if fen_pai[t] and #fen_pai[t]>0 then
-- 				enum[t]={}
-- 				for k,v in pairs(fen_pai[t]) do
-- 					enum[t][#enum[t]+1]={type=t,pai=v}
-- 					hash[this.pai_data_hash_key(enum[t][#enum[t]])]=true
-- 				end
-- 			end
-- 			if xjbest_fenpai[t] and #xjbest_fenpai[t]>0 then
-- 				enum[t]=enum[t] or {}
-- 				for k,v in pairs(xjbest_fenpai[t]) do
-- 					if not hash[this.pai_data_hash_key({type=t,pai=v})] then
-- 						enum[t][#enum[t]+1]={type=t,pai=v}
-- 					end				
-- 				end
-- 			end
-- 		end
-- 		pai_enum[i]=enum
-- 	end
-- 	-- dump(pai_enum,"*****^^^^&&&&&&")
-- 	return pai_enum

-- end
--牌排序价值
local pai_type_sort_value={
	[0]=4,
	[1]=2,
	[2]=2,
	[3]=1,
	[4]=1,
	[5]=1,
	[6]=1,
	[7]=1,
	[8]=3,
	[9]=3,
	[10]=1,
	[11]=1,
	[12]=1,
	[13]=5,
	[14]=5,
}
--get best cp
function this.get_best_cp_score(s_list)
	if s_list and #s_list>0 then
		table.sort( s_list, function (a,b)
			if a.score>b.score then
				return true	
			end 
			if a.score<b.score then
				return false
			end
			-- dump(a)
			-- dump(b)
			if pai_type_sort_value[a.type]<pai_type_sort_value[b.type] then
				return true
			end
			if pai_type_sort_value[a.type]>pai_type_sort_value[b.type] then
				return false
			end 
			local p1
			if a.type>0 then
				p1=this.get_key_value_pai(a.type,a.pai)
			end
			local p2
			if b.type>0 then
				p2=this.get_key_value_pai(b.type,b.pai)
			end
			if p1 and p2 then
				if p1 > p2 then
					return false
				end
				if p1<p2 then
					return true
				end
			end
			if a.type==b.type and (a.type==4 or a.type==5) then
				if a.pai[2]<b.pai[2] then
					return true
				end
				return false
			end
			return a.score>b.score

		end )
		local max=s_list[1].score
		local min=s_list[#s_list].score
		local len=#s_list
		return max,min
	end
	return nil
end



this.change_pai_map_data=change_pai_map_data 



local pai_type_serial_map={
	[6]=true,
	[7]=true,

	[10]=true,
	[11]=true,
	[12]=true,
}


function this.get_pai_score_use_allunkown(split_info,seat_id,pai_type,pai_data)
	return this.get_pai_score(split_info,seat_id,pai_type,pai_data,true)
end



function this.get_pai_score(query_map,seat_id,pai_type,pai_data,use_sure)
	if skynet.getcfg("ddz_tuoguan_imp_c") then 
		return this.get_pai_score_imp_c(query_map,seat_id,pai_type,pai_data,use_sure)
	else 
		return this.get_pai_score_imp_lua(query_map,seat_id,pai_type,pai_data,use_sure)
	end
end



function this.get_pai_score_imp_c(query_map,seat_id,pai_type,pai_data,use_sure)

	if pai_type == 14 then 
		return tgland_core.query_map_get_pai_score(query_map,seat_id,{type=pai_type,pai={}},use_sure)
	else 

		return tgland_core.query_map_get_pai_score(query_map,seat_id,{type=pai_type,pai=pai_data},use_sure)
	end

end



function this.get_pai_score_imp_lua(split_info,seat_id,pai_type,pai_data,all_unkown)
	--print(split_info,seat_id,pai_type,pai_data)

	if pai_type == 0 then
		return 0
	end

	local op_table =nil
	if all_unkown then 
		op_table=split_info.all_is_op_exist[seat_id]
	else 
		op_table=split_info.op_card_type_exist[seat_id] 
	end


	local all_table=split_info.all_card_type 
	local my_table=split_info.card_type_exist[seat_id]

	local biggest=false

	if pai_type == 13 then  -- 炸弹

		local bomb_nu = all_table:get_biggerEqCardNu(pai_type,nil,3)
		local bigger_nu= op_table:get_biggerCardNu(pai_type,nil, pai_data[1])

		if bigger_nu == 0 then 
			return 7+ bomb_nu - bigger_nu ,true
		else 
			return 7+ bomb_nu - bigger_nu ,false
		end

	end



	if pai_type == 14 then  --王炸
		local bomb_nu = all_table:get_biggerEqCardNu(pai_type,nil,3)
		return  7 + bomb_nu
	end


	local serial=nil 
	if pai_type_serial_map[pai_type] then 
		serial=pai_data[2]-pai_data[1]+1
	end

	local face = nil 

	-- if pai_type ==  1  or pai_type==2 or pai_type == 3 or pai_type == 13 then 
	-- 	face=pai_data
	-- else 
	-- 	face=pai_data[1]
	-- end
	if serial then 
		face= pai_data[2]
	else 
		face=pai_data[1]
	end

	local score


	local bigger_nu= all_table:get_biggerCardNu(pai_type,serial,face)

	score= 7 - bigger_nu 
	local has_eq=false

	-- 对手牌没有比自己大的牌

	if seat_id ~= split_info.dz_seat  then 

		local op_bigger_nu= op_table:get_biggerCardNu(pai_type,serial,face)
		if  op_bigger_nu== 0 then 

			if op_table:get_typeFaceNu(pai_type,serial,face) ==0 then 
				return 7,true
			end

			return 7,false
		end


	else 
		local has=false
		local is_biggest=true

		for k,v in ipairs(split_info.land_op_exist) do 
			local big_nu= v:get_biggerCardNu(pai_type,serial,face)

			if big_nu > 0 then 
				has=true
				is_biggest=false
				break
			else 
				if v:get_typeFaceNu(pai_type,serial,face)>0  then 
					is_biggest=false
				end
			end
		end

		--print(pai_type,serial,face,has,is_biggest)


		if not has then 
			return  7,is_biggest
		end

	end

	return score , false

end




--[[
--table_info
--{
--		pai_map={
--			[1]={
--				12=4,
--				13=1
--			},
--			[2]={},
--			[3]={}
--
--		},
--		
--		base_info={
seat_count =3
dz_seat= 1    地主的位置id 
--		},
--
--
--}
--]]


function this.get_pai_type_card_nu(pai_type,pai_data)
	if pai_type == 1 then 
		return 1 
	end

	if pai_type == 2 then 
		return 2 
	end

	if pai_type == 3 then 
		return 3 
	end

	if pai_type ==4 then 
		return 4 
	end

	if pai_type == 5 then 
		return 5 
	end


	if pai_type == 6 then 
		return pai_data[2]-pai_data[1]+1
	end


	if pai_type == 7 then 
		return (pai_data[2]-pai_data[1]+1)*2
	end

	if pai_type == 8 then 
		return 6 
	end

	if pai_type == 9 then 
		return 8 
	end


	if pai_type == 10 then 
		return (pai_data[2]-pai_data[1]+1)*4
	end 

	if pai_type == 11 then 
		return (pai_data[2]-pai_data[1]+1)*5
	end 

	if pai_type == 12 then 
		return (pai_data[2]-pai_data[1]+1)*3
	end 

	if pai_type == 13 then 
		return 4 
	end

	if pai_type == 14 then 
		return 2 
	end 
end



function this.get_pai_is_bigger_in_unkown(query_map,seat_id,pai_type,pai_data)
	if skynet.getcfg("ddz_tuoguan_imp_c") then 
		return this.get_pai_is_bigger_in_unkown_imp_c(query_map,seat_id,pai_type,pai_data)
	else 
		return this.get_pai_is_bigger_in_unkown_imp_lua(query_map,seat_id,pai_type,pai_data)
	end
end


function this.get_pai_is_bigger_in_unkown_imp_c(query_map,seat_id,pai_type,pai_data)

	if pai_type == 14 then 

		return tgland_core.query_map_get_pai_is_bigger_in_unkown(query_map,seat_id,{type=pai_type,data={}})
	else 

		return tgland_core.query_map_get_pai_is_bigger_in_unkown(query_map,seat_id,{type=pai_type,data=pai_data})
	end

end

function this.get_pai_is_bigger_in_unkown_imp_lua(query_map,seat_id,pai_type,pai_data)

	local pai_card_nu=this.get_pai_type_card_nu(pai_type,pai_data)
	local op_max_card_nu= query_map.op_max_card_nu[seat_id] 
	local unkown_table=query_map.op_unkown_exist[seat_id]


	if op_max_card_nu< pai_card_nu then 
		return 0
	end


	if pai_type == 14 then 
		return 0
	end

	local serial=nil 
	if pai_type_serial_map[pai_type] then 
		serial=pai_data[2]-pai_data[1]+1
	end

	local face = nil 
	if serial then 
		face= pai_data[2]
	else 
		face=pai_data[1]
	end

	local bigger_nu= unkown_table:get_biggerCardNu(pai_type,serial,face)

	return bigger_nu

end


function this.get_pre_seat_id(data)

	local my_seat = data.base_info.my_seat 
	local pre_id = my_seat -1 
	if pre_id <=0 then 
		pre_id= pre_id + data.base_info.seat_count 
	end
	return pre_id 

end

function this.get_next_seat_id(data)

	local my_seat = data.base_info.my_seat 
	local next_id = my_seat + 1 
	local seat_nu = data.base_info.seat_count
	if next_id > seat_nu then 
		next_id= next_id -seat_nu 
	end

	return next_id 

end




function this.generate_exist_map(table_info)

	local action_seat_id =table_info.action_seat_id
	local land_seat_id = table_info.base_info.dz_seat 

	local seat_nu = table_info.base_info.seat_count


	local seat_card_nu={}



	local result={
		card_type_exist={ },
		op_card_type_exist={ },
		seat_card_nu={},
		op_unkown_exist={},
		all_is_op_exist={},
		op_max_card_nu={},
		all_card_type=nil
	}


	for k,v in pairs(table_info.pai_map) do 
		local lys_cards=LysCards.new()
		lys_cards:set_fcards2(v)

		result.seat_card_nu[k]=lys_cards:getCardNu()

		local exist_analysis=ExistAnalysis.new()
		exist_analysis:set_card(lys_cards)

		result.card_type_exist[k]=exist_analysis

	end


	for i=1,seat_nu do 

		local unkown_cards=LysCards.new()
		for k,v in pairs(table_info.pai_map) do 
			if k ~= i then 
				unkown_cards:add_fcards2(v)
			end
		end

		local pre_id=land_seat_id-1 
		if pre_id <= 0 then 
			pre_id =pre_id+seat_nu
		end
		local next_id=land_seat_id+1 
		if next_id > seat_nu then 
			next_id= next_id-seat_nu 
		end


		local unkown_exist_analysis=ExistAnalysis.new()
		unkown_exist_analysis:set_card(unkown_cards)

		result.op_unkown_exist[i]=unkown_exist_analysis


		local exist_analysis=ExistAnalysis.new()

		exist_analysis:merge(result.card_type_exist[pre_id])

		if pre_id ~= next_id then 
			exist_analysis:merge(result.card_type_exist[next_id])
		end

		result.op_card_type_exist[i]=exist_analysis
		result.all_is_op_exist[i]=exist_analysis
		result.land_op_exist={ result.card_type_exist[pre_id],result.card_type_exist[next_id]}
		result.op_max_card_nu[i]=math.max(result.seat_card_nu[pre_id],result.seat_card_nu[next_id])

		--更新农民的为地主表
		if i~=land_seat_id then 
			result.op_card_type_exist[i]=result.card_type_exist[land_seat_id]
			result.op_max_card_nu[i]=result.seat_card_nu[land_seat_id]
		end

	end

	local all_exist=ExistAnalysis.new()
	for k,v in pairs(result.card_type_exist) do 
		all_exist:merge(v)
	end


	result.all_card_type=all_exist
	result.dz_seat=land_seat_id







	return result 
end
--获得非占手牌的的最大牌 如果没有非占手牌则返回 最大的牌
function this.get_maxpai_noctrl(type,pai_data,my_seat,query_map)
	if pai_data then
		local max_pai=nil
		local score=nil
		for k,v in ipairs(pai_data) do
			local s=this.get_pai_score(query_map,my_seat,type,v)
			local k_p=this.get_key_pai(v.type,v.pai)
			if not max_pai  then
				max_pai=k_p
				score=s
			elseif s>=7 and score>=7  and k_p>max_pai then
				max_pai=k_p
				score=s
			elseif s<7 and score>=7 then
				max_pai=k_p
				score=s
			elseif s<7 and score<7 and 	k_p>max_pai then
				max_pai=k_p
				score=s
			end
		end
		return max_pai
	end
	return nil
end

local compare_func_by_ctrl=function (a,b)
	if a.ctrl~=b.ctrl then
		return a.ctrl>b.ctrl
	end
	return a.no_ctrl>b.no_ctrl
end
--按no_ctrl数量排序  前提有ctrl
local compare_func_by_noCtrl=function (a,b)
	if a.ctrl>0 and b.ctrl>0 then
		if a.no_ctrl~=b.no_ctrl then
			return a.no_ctrl>b.no_ctrl
		end
		return a.ctrl>b.ctrl
	end
	if a.ctrl~=b.ctrl then
		return a.ctrl>b.ctrl
	end 
	return a.no_ctrl>b.no_ctrl
end

--获得最想要的牌的list  按最想要程度排序
function this.get_best_want_pai_list(fen_pai,my_seat,query_map,compare_func)
	if type(compare_func) =="string" then
		if compare_func=="ctrl" then
			compare_func=compare_func_by_ctrl
		elseif compare_func=="no_ctrl" then
			compare_func=compare_func_by_noCtrl
		else
			compare_func=compare_func_by_ctrl
		end
	elseif  type(compare_func) ~="function" then
		compare_func=compare_func_by_ctrl
	end
	local list={}
	for i=1,12 do
		if fen_pai[i] and #fen_pai[i]>0 then
			list[#list+1]={type=i}
			list[#list].ctrl,list[#list].no_ctrl=this.get_zhanshou_data(i,fen_pai[i],my_seat,query_map)
			list[#list].max_noctrl=this.get_maxpai_noctrl(i,pai_data,fen_pai[i],my_seat,query_map)

		end
	end
	table.sort(list,compare_func)
	return list
end


function this.get_partner_want_pai_list(data,my_seat,partner_seat,compare_func)
	if partner_seat then
		local next_s=my_seat+1
		if next_s>#data.base_info.seat_type then
			next_s=1
		end
		if next_s==partner_seat then
			return this.get_best_want_pai_list(data.fen_pai[partner_seat],partner_seat,data.query_map,"no_ctrl")
		else
			return this.get_best_want_pai_list(data.fen_pai[partner_seat],partner_seat,data.query_map,"ctrl")
		end
	end
	return nil
end

function this.get_fuzhu_info(data,my_seat,partner_seat)
	if my_seat and partner_seat then
		local fuzhu={}

		--去除连队和顺子以后的 占手牌数量
		local zs={}
		local seat={my_seat,partner_seat}
		for k,v in ipairs(seat) do
			for i=1,14 do
				if i~=6 and i~=7 then
					if data.fen_pai[v][i] then
						local ctrl = this.get_zhanshou_data(pai_type,pai_data,v,data.query_map)
						zs[v]=zs[v] or 0
						zs[v]=zs[v]+ctrl
					end
				end
			end
			if zs[v]==0 then
				zs[v]=-2
			end
		end
		--离下叫的分数
		local my_s=data.fen_pai[my_seat].no_xiajiao_socre+zs[my_seat]
		local p_s=data.fen_pai[partner_seat].no_xiajiao_socre+zs[partner_seat]

		local  fuzhu_cfg=3
		if my_s-p_s>fuzhu_cfg then
			fuzhu[partner_seat]=true
		elseif p_s-my_s>fuzhu_cfg then
			fuzhu[my_seat]=true
		end
		local next_p=my_seat+1
		if next_p>#data.base_info.seat_type then
			next_p=1
		end
		--如果我的下家是地主 并且我和我的队友都不是辅助  则放宽我成为辅助的条件
		if not fuzhu[my_seat] and not fuzhu[partner_seat] and next_p==data.base_info.dz_seat  then
			--跟牌
			if data.last_pai then
				if zs[my_seat]<=0 and data.fen_pai[partner_seat].no_xiajiao_socre<-2 then
					fuzhu[my_seat]=true
				end
			else
				if zs[my_seat]<=0 and data.fen_pai[partner_seat].no_xiajiao_socre<-4 then
					fuzhu[my_seat]=true
				end
			end
		end

		data.fuzhu_info=fuzhu
	end
end
--获取队友的位置 并返回是否是自己的下家
function this.get_partner_seat(data,my_seat)
	local p_seat
	local is_next

	for k,v in ipairs(data.base_info.seat_type) do
		if k~=my_seat and v==data.base_info.seat_type[my_seat] then
			p_seat=k
			if k-1==my_seat or k==1 and my_seat==#data.base_info.seat_type then
				is_next=true
			end
			break
		end
	end
	return p_seat,is_next
end
--[[
1 爆单
2 暴双
3 又爆单又爆双
--]]
function this.get_enemy_bao_pai(data)
	local my_seat=data.base_info.my_seat
	local bp={}
	local seat_num= data.base_info.seat_count

	for i=1,seat_num do
		if i~=my_seat and data.base_info.seat_type[my_seat]~=data.base_info.seat_type[i] then
			--dump(data.game_over_cfg)
			bp[data.pai_re_count[i]-data.game_over_cfg[i]]=true
		end
	end


	if bp[1] and bp[2] then
		return 3
	end
	if bp[1] then
		return 1
	end
	if bp[2] then
		return 2
	end
	return 0
end

function this.get_next_is_enemy(data)
	local my_seat = data.base_info.my_seat
	local dz_seat= data.base_info.dz_seat 

	if my_seat == dz_seat then 
		return true
	end

	local next_seat=my_seat + 1 

	if next_seat > data.base_info.seat_count then 
		next_seat= 1 
	end


	if next_seat == dz_seat then 
		return true
	end

	return false
end




--判断是否出牌后立刻就会输掉 除了炸弹
function this.check_is_lose_by_one(data,cp)
	local seat_num= data.base_info.seat_count
	local my_seat=data.base_info.my_seat
	for i=1,seat_num do
		if i~=my_seat and data.base_info.seat_type[my_seat]~=data.base_info.seat_type[i] then

			if data.fen_pai[i][cp.type] then
				local res=this.get_pai_by_big_and_type(cp.type,data.fen_pai[i][cp.type],cp.pai)
				if res and #res>0  and data.pai_count[i]-this.get_pai_count(cp.type,res[#res].pai)<=data.game_over_cfg[i] then
					if cp.type==6 or cp.type==7 or cp.type==10 or cp.type==11 or cp.type==12 then
						if res[#res].pai[2]-res[#res].pai[1] == cp.pai[2]-cp.pai[1] then
							return true
						end
					else
						return true							
					end 
				end
			end

		end
	end
	return nil
end

function this.fen_pai_map_nu(pai_map)
	local list=this.fenpai_map_to_list(pai_map)
	return #list
end

function this.get_pai_xiajiao_score(data,seat_id,pai,sure) 
	local score = this.get_pai_score( data.query_map, seat_id, pai.type, pai.pai)

	if score > 6  then 
		return score 
	end

	if pai.type == 1 and pai.pai[1] >=15 and not sure  then 
		return 7 
	end

	return score 
end


function this.fenpai_map_to_list(pai_map,ignore_bomb)
	local pai_list={}

	for i=1,12 do 
		if pai_map[i] then 
			for k,v in ipairs(pai_map[i])  do 
				table.insert(pai_list,{
					type=i,
					pai=v
				})
			end
		end
	end

	if not ignore_bomb then 

		if pai_map[13] then 
			for k,v in ipairs(pai_map[13])  do 
				table.insert(pai_list,{
					type=13,
					pai=v
				})
			end
		end

		if pai_map[14]  then 
			table.insert(pai_list,{
				type=14,
				pai=true
			})
		end
	end

	return pai_list 
end

local function remove_unuse_pai(_pai_data)

	local _type,_pai = _pai_data.type,_pai_data.pai

	if _type == 0 or _type == 14 then
		_pai_data.pai = nil
	elseif _type <=3 or _type == 13 then
		basefunc.tsetnil(_pai,2)
	elseif _type >= 4 and _type <= 7 or _type == 12 then
		basefunc.tsetnil(_pai,3)
	elseif _type == 8 or _type == 9 then
		basefunc.tsetnil(_pai,4)
	elseif _type  == 10 or _type == 11 then
		basefunc.tsetnil(_pai,4 + (_pai[2] - _pai[1]))
	end

end

-- by lyx: 导出的 C++ 同名函数
function this.get_boyiSearch(
	pai_map,
	seat_type,
	game_over_info,
	kaiguan,
	cp_count,
	cur_p, -- 当前该出牌的人
	all_seat,
	cp_p, -- 出了牌的人
	cp_data, -- 出了的牌
	times_limit
	)

	-- dump({
	-- 	pai_map,
	-- 	seat_type,
	-- 	game_over_info,
	-- 	kaiguan,
	-- 	cp_count,
	-- 	cur_p,
	-- 	all_seat,
	-- 	cp_p or 0,
	-- 	cp_data or {type=0},
	-- 	times_limit
	-- },"xxxxxxxxxxxxxxxx get_boyiSearch param:")


	local ret = tgland_core.get_boyiSearch(
	pai_map,
	seat_type,
	game_over_info,
	kaiguan,
	cp_count,
	cur_p,
	all_seat,
	cp_p or 0,
	cp_data or {type=0},
	times_limit
	)

	for _,v in ipairs(ret) do
		remove_unuse_pai(v)
	end

	return ret
end
function this.get_boyiSearch_have_pe(
	pai_map,
	seat_type,
	game_over_info,
	kaiguan,
	cp_count,

	pai_enum,
	cur_p, -- 当前该出牌的人 
	all_seat,
	cp_p, -- 出了牌的人
	cp_data, -- 出了的牌
	times_limit
	)
	--	dump({
	--		pai_map,
	--		seat_type,
	--		game_over_info,
	--		kaiguan,
	--		cp_count,
	--		pai_enum,
	--		cur_p,
	--		all_seat,
	--		cp_p or 0,
	--		cp_data or {type=0},
	--		times_limit
	--	},"xxxxxxxxxxxxxxxx get_boyiSearch_have_pe param:")

	local ret = tgland_core.get_boyiSearch_have_pe(
	pai_map,
	seat_type,
	game_over_info,
	kaiguan,
	cp_count,
	pai_enum,
	cur_p,
	all_seat,
	cp_p or 0,
	cp_data or {type=0},
	times_limit
	)

	for _,v in ipairs(ret) do
		remove_unuse_pai(v)
	end

	return ret
end

-- 获得定主数量  2以上算  炸弹算一个
function this.get_dingzhu_count(pai_map)
	local boom = 0
	local wang = 0
	local er=0
	for i = 1, 13 do
		if pai_map[i] and pai_map[i] == 4 then
			boom = boom + 1
		end
	end
	for i = 15, 15 do
		if pai_map[i] then
			er = er + pai_map[i]
		end
	end
	for i = 16, 17 do
		if pai_map[i] then
			wang = wang + pai_map[i]
		end
	end

	return boom,er,wang
end


return this
