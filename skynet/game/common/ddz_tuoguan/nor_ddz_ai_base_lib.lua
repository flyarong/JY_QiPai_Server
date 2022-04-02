-- package.path=package.path..";/Users/hewei/project/JyQipai_server/skynet/game/common/?.lua"
local basefunc = require "basefunc"
local printfunc = require "printfunc"
local ddz_tg_assist_lib=require "ddz_tuoguan.ddz_tg_assist_lib"

---------斗地主出牌
--[[
    协议：
        {
            type 0 : integer,--(出牌类型）
            pai 1 :*integer,--出的牌
        }
    牌类型
        3-17 分别表示
						 11 12 13 14 15  16   17
        3 4 5 6 7 8 9 10 J  Q  K  A  2  小王  大王
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
--[[
基础定义
    1.牌力基础价值：我们认为10属于中等位置，即<10单牌价值为负，大于10的单牌价值为正  
    2.非负数基础价值 1-15
牌类型价值
    1.单牌的价值定义：基础价值
    2.对牌的价值定义：10以下基础价值+1  10以上基础价值+2 

    3.三牌的价值定义：
        222为最大的牌 因此222的价值为7 AAA为6
        所以三牌（三不带，三带一，三带二）的价值定义为：
            基础价值+2
        
        飞机
         我认为一把牌，飞机数量一般不超过4个
            长度越长被管的概率越低 所以有加分
            4-6为4 7-9为5 10-Q为6 K-A为7 + (长度-2)
            <=7
    4.炸弹：
        我认为一副牌炸弹数一般小于5个
        所以最大的炸弹分数应该为12
        所以 3-5炸弹为8 6-7炸弹为9 8-10位10 JQK为11 A2王为12 
        非负基础价值+7 (7-15)
    5.四带
        我认为一副牌炸弹数一般小于5个
        所以 3-5四带为3 6-7四带为4 8-10位5 JQK为6 A2王为7

    6.单顺：
        长度越长被管的概率越低 所以有加分       
        头牌基础价值+ 3+(长度-5)/3
    7.连对：
        长度越长被管的概率越低 所以有加分
        5-6为0 7-8为1 9为2 10为3  j为4 Q为5 K为6  A为7
        头牌基础价值+3+(长度-3)  <=7
--]]



local this={}

local nor_pai_power_cfg

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
----默认的 nor_data_ddz_cfg **********************	
-- del by lyx
-- 	local nor_data_ddz_cfg={
-- 		kaiguan={
-- 			sz_min_len={5,3,2} ,  --1表示顺子  2表示连对 3飞机
-- 			sz_max_len={12,10,6},
-- 			[1]=true,
-- 			[2]=true,
-- 			[4]=true,
-- 			[6]=true,
-- 			[7]=true,
-- 			[8]=true,
-- 			[10]=true,
-- 			[13]=true,
-- 			[14]=true,

-- 			[3]=true,
-- 			[5]=true,
-- 			[9]=true,
-- 			[11]=true,
-- 			[12]=true,
-- 		},
-- }

----默认的power cfg **********************
local default_pai_power_cfg={}
	default_pai_power_cfg.base_score=function (pai)
	         return pai-10
	        end
	default_pai_power_cfg[1]=function(pai)
			return default_pai_power_cfg.base_score(pai[1])
		end
	default_pai_power_cfg[2]=function (pai)
	        local s=default_pai_power_cfg.base_score(pai[1])
	        if pai[1]<=10 then
	            return s+1
	        end
	        return s+2
	        end
	default_pai_power_cfg[3]=function (pai)
	         return default_pai_power_cfg.base_score(pai[1])+2
	        end
	default_pai_power_cfg[4]= function(pai)
		return default_pai_power_cfg.base_score(pai[1])+2
	end

	default_pai_power_cfg[5]=default_pai_power_cfg[4]
	default_pai_power_cfg[6]=function (pai)
	        --长度加成 长度越长
	        local s=default_pai_power_cfg.base_score(pai[2])
	        local len_s=math.floor((pai[2]-pai[1]+1-5)/3)
	        s=s+len_s+4
	        if s>7 then
	            s=7
	        end
	        return s
	        end
	default_pai_power_cfg[7]=function (pai)
	        local s=0
	        if pai[2]<7 then
	            s=2
	        elseif pai[2]<9 then
	            s=3
	        else
	            s=2+pai[2]-9
	        end
	        s=s+(pai[2]-pai[1]+1-3)
	        if s>7 then
	            s=7
	        end
	        return s
	        end
	default_pai_power_cfg[8]=function (pai)
		pai=pai[1]

	            local s=0
	            if pai<6 then
	                s=3
	            elseif pai<8 then
	                s=4
	            elseif pai<11 then
	                s=5
	            elseif pai<14 then
	                s=6
	            end
	            return s
	        end
	default_pai_power_cfg[9]=default_pai_power_cfg[8]
	default_pai_power_cfg[10]=function (pai)
	            local s=0
	            if pai[2]<7 then
	                s=4
	            elseif pai[2]<10 then
	                s=5
	            elseif pai[2]<13 then
	                s=6
	            else
	                s=7
	            end
	            s=s+(pai[2]-pai[1])
	            if s>7 then
	                s=7
	            end
	            return s
	        end
	default_pai_power_cfg[11]=default_pai_power_cfg[10]
	default_pai_power_cfg[12]=default_pai_power_cfg[10]
	default_pai_power_cfg[13]=function (pai)
	            -- local s=0
	            -- if pai<6 then
	            --     s=8
	            -- elseif pai<8 then
	            --     s=9
	            -- elseif pai<11 then
	            --     s=10
	            -- elseif pai<14 then
	            --     s=11
	            -- else
	            --     s=12
	            -- end

	            -- return s 
	            -- return pai-2+7
	            return 15
	        end
	default_pai_power_cfg[14]=function (pai)
	            return 15
	        end

	default_pai_power_cfg.get_fenpai_score=function(fen_pai)
		return this.default_get_fenpai_score (fen_pai)
	end

	default_pai_power_cfg.get_fenpai_value=function(fen_pai) 
		fen_pai.score=default_pai_power_cfg.get_fenpai_score(fen_pai)
	end


	default_pai_power_cfg.compare_fenpai=function (f1,f2 )
		if not f2 then 
			return f1 
		end

		if not f1 then 
			return f2 
		end

		return f1.score>f2.score and f1 or f2
	end        
--*********************************************************    

local sz_start_pai=3
local sz_end_pai=14


local function face_in_ignore_f_t(face,ignore)

	if not ignore then 
		return false 
	end

	if face>=ignore.f and face <= ignore.t then 
		return true
	end
	return false 
end

local function face_greater_cmp_func(l,r)
	return l[1]>r[1]
end

-- local function fen_pai_greater_cmp_func(l,r)
-- 		local result=this.compare_fenpai(l.fen_pai,r.fen_pai)
-- 		if result == l.fen_pai  then 
-- 			return true 
-- 		end

-- end


--
local function check_is_lianxu(pai_map,s,len,count,limit)
    for k=s,s+len-1 do
        if not pai_map[k] or pai_map[k]<count or k>=limit then
            for i=k+1,s+len-1 do
                if pai_map[i] and pai_map[i]>=count then
                    return nil,i
                end
            end
            return nil,s+len
        end
    end
    return true
end
local function chang_value_by_lianxu(pai_map,s,len,count)
    for k=s,s+len-1 do
        if count<0 then
            if not pai_map[k] or pai_map[k]<-count then
                return nil
            end
        else
            pai_map[k]=pai_map[k] or 0
        end

        pai_map[k]=pai_map[k]+count
    end
    return true
end
local function add_sz(data,s,len,_type)
    data.fen_pai[_type]=data.fen_pai[_type] or {}
    data.fen_pai[_type][#data.fen_pai[_type]+1]={s,s+len-1}
end
local function reduce_sz(data,_type)
    data.fen_pai[_type][#data.fen_pai[_type]]=nil
end
function this.get_score_by_paiType(_type,pai_data)
    return nor_pai_power_cfg[_type](pai_data)
end

function this.analyse_sandai(data)
	--do return true end 

    local count=0
	local sanda_info={}


	if not data.fen_pai[1] then 
		data.fen_pai[1]={}
	end
	local f1_nu=#data.fen_pai[1]

	if not data.fen_pai[2] then 
		data.fen_pai[2]={}
	end

	local f2_nu=#data.fen_pai[2]

	local fj_nu=0
	local f3_nu=0


	local fj_info=data.fen_pai[12]  or {}
	local sz_info=data.fen_pai[3] or {}
	local zd_info=data.fen_pai[13]  or {}

	-- 能带完的情况
	data.fen_pai[12]={}
	data.fen_pai[3]={}
	data.fen_pai[13]={}




	local sanda_info={}



	--提取最大队
	
	if data.fen_pai[2] and #data.fen_pai[2]>0  then 
		local pai=data.fen_pai[2][1] 
		table.remove(data.fen_pai[2],1)
		table.insert( sanda_info,{
			tp=2,
			td=pai
		})
	end



	--提取王炸

	if data.fen_pai[14] then 
		data.fen_pai[14]=nil 
		table.insert(sanda_info,{
			tp=14,
			tv=true,
		})
	end

	--提取炸弹
	local bomb_nu =0 
	for k,v in ipairs(zd_info) do 
		if bomb_nu <=2 then 
			table.insert(sanda_info,{
				tp=13,
				td=v,
			})
			bomb_nu=bomb_nu + 1
		else 
			table.insert(data.fen_pai[13],v)
		end
	end


	--提取三张
	for k,v in ipairs(sz_info) do 
		if k==#sz_info then 
			table.insert(sanda_info,{
				tp=3,
				td=v,
				last=true,
			})
		else 
			table.insert(sanda_info,{
				tp=3,
				td=v,
			})
		end
	end

	--提取飞机
	for k,v in ipairs(fj_info) do 
		table.insert(sanda_info,{
			tp=12,
			td=v,
		})

	end



	local c_fen_pai=this.extract_sandai_daipai(data.kaiguan,data.fen_pai,sanda_info,1)
	if c_fen_pai then 
		data.fen_pai=c_fen_pai
		return true
	end



	return false
end

--[[
允许三带对
看分数从小到大依次取
1 单牌
2 对子
不允许允许三带对
1 2单牌
2 1单牌和1从对子中抽取单牌
3 从对子中抽取2个单牌
--取一张牌的情况
1 1单牌
2 从对子中抽取1个单牌
--]]


function this.remove_duizhi(fen_pai,count,ignore)
	if not fen_pai[2] then 
		return nil
	end

	if #fen_pai[2]<count then 
		return  nil 
	end



	local ret={}

	for i=1,#fen_pai[2] do 
		local f = fen_pai[2][#fen_pai[2]]
		if not face_in_ignore_f_t(f[1],ignore) then 
			fen_pai[2][#fen_pai[2]]=nil 
			table.insert(ret,f)
			if #ret>=count then 
				return ret 
			end

		end
	end 
	return nil 

end



function this.remove_daipai(fen_pai,count,ignore)
	if not fen_pai[1] then 
		fen_pai[1]={}
	end

	if not fen_pai[2] then 
		fen_pai[2]={}
	end


	local f1_nu= #fen_pai[1]
	local f2_nu= #fen_pai[2]

	if f1_nu+f2_nu*2 < count then 
		return nil 
	end



	local ret={}

	for i=1,f1_nu+f2_nu*2 do 
		if #fen_pai[1]==0 then 
			local f2=fen_pai[2][#fen_pai[2]]
			if not face_in_ignore_f_t(f2[1],ignore) then 
				fen_pai[2][#fen_pai[2]]=nil 
				table.insert(fen_pai[1],f2)
				table.insert(fen_pai[1],f2)
			end
		end

		local f1=fen_pai[1][#fen_pai[1]]
		if not face_in_ignore_f_t(f1[1],ignore)  then 
			fen_pai[1][#fen_pai[1]]=nil
			table.insert(ret,f1)
			if #ret >=count then 
				return ret 
			end
		end

	end

	return nil

end



function this.extract_bomb_daipai(kuai_guan,fen_pai,sanda_info,pos)


	local ret_table={}
	local pai_info=sanda_info[pos]

	if not fen_pai[1] then 
		fen_pai[1]={}
	end


	if not fen_pai[2] then 
		fen_pai[2]={}
	end



	--折分为1+1+1+1 
	local fen_pai_1_1_1_1=basefunc.deepcopy(fen_pai)
	table.insert(fen_pai_1_1_1_1[1],pai_info.td)
	table.insert(fen_pai_1_1_1_1[1],pai_info.td)
	table.insert(fen_pai_1_1_1_1[1],pai_info.td)
	table.insert(fen_pai_1_1_1_1[1],pai_info.td)
	table.sort(fen_pai_1_1_1_1[1],face_greater_cmp_func)

	fen_pai_1_1_1_1=this.extract_sandai_daipai(kuai_guan,fen_pai_1_1_1_1,sanda_info,pos+1)
	if fen_pai_1_1_1_1 then 
		table.insert(ret_table,{
			fen_pai=fen_pai_1_1_1_1,
		})
	end


	--折分为2+1+1 
	local fen_pai_2_1_1=basefunc.deepcopy(fen_pai)
	table.insert(fen_pai_2_1_1[1],pai_info.td)
	table.insert(fen_pai_2_1_1[1],pai_info.td)
	table.insert(fen_pai_2_1_1[2],pai_info.td)

	table.sort(fen_pai_2_1_1[1],face_greater_cmp_func)
	table.sort(fen_pai_2_1_1[2],face_greater_cmp_func)

	fen_pai_2_1_1=this.extract_sandai_daipai(kuai_guan,fen_pai_2_1_1,sanda_info,pos+1)
	if fen_pai_2_1_1 then 
		table.insert(ret_table,{
			fen_pai=fen_pai_2_1_1,
		})
	end



	--折分为2+2 
	local fen_pai_2_2 = basefunc.deepcopy(fen_pai)
	table.insert(fen_pai_2_2[2],pai_info.td)
	table.insert(fen_pai_2_2[2],pai_info.td)
	table.sort(fen_pai_2_2[2],face_greater_cmp_func)

	fen_pai_2_2=this.extract_sandai_daipai(kuai_guan,fen_pai_2_2,sanda_info,pos+1)
	if fen_pai_2_2 then 
		table.insert(ret_table,{
			fen_pai=fen_pai_2_2,
		})
	end

	--折分为3+1
	local fen_pai_3_1=basefunc.deepcopy(fen_pai) 
	table.insert(fen_pai_3_1[1],pai_info.td)
	table.sort(fen_pai_3_1[1],face_greater_cmp_func)
	local n_sanda_info=basefunc.deepcopy(sanda_info)

	n_sanda_info[#n_sanda_info].last=false
	table.insert(n_sanda_info,{
		tp=3,
		td=pai_info.td,
		last=true
	})

	fen_pai_3_1=this.extract_sandai_daipai(kuai_guan,fen_pai_3_1,n_sanda_info,pos+1)

	if fen_pai_3_1 then 
		table.insert(ret_table,{
			fen_pai=fen_pai_3_1,
		})
	end




	--不带的情况
	local fen_pai0=basefunc.deepcopy(fen_pai)

	if not fen_pai0[13] then 
		fen_pai0[13]={}
	end
	table.insert(fen_pai0[13],pai_info.td)
	fen_pai0=this.extract_sandai_daipai(kuai_guan,fen_pai0,sanda_info,pos+1)
	if fen_pai0 then 
		table.insert(ret_table,{
			fen_pai=fen_pai0,
		})

	end


	--带单张的情况
	if kuai_guan[8] then 
		local fen_pai1=basefunc.deepcopy(fen_pai)
		local dp=this.remove_daipai(fen_pai1,2,{f=pai_info.td[1],t=pai_info.td[1]})

		if dp then 
			if not fen_pai1[8] then 
				fen_pai1[8] = {}
			end
			--table.insert(fen_pai1[8],{pai_info.td,dp[1],dp[2]})
			table.insert(fen_pai1[8],{pai_info.td[1],dp[1][1],dp[2][1]})
			fen_pai1 = this.extract_sandai_daipai(kuai_guan,fen_pai1,sanda_info,pos+1)
			table.insert(ret_table,{
				fen_pai=fen_pai1,
			})
		end
	end



	--带对的情况
	if kuai_guan[9] then 
		local fen_pai2=basefunc.deepcopy(fen_pai)
		local dp=this.remove_duizhi(fen_pai2,2,{f=pai_info.td[1],t=pai_info.td[1]})
		if dp then 
			if not fen_pai2[9] then 
				fen_pai2[9]= {}
			end
			table.insert(fen_pai2[9],{pai_info.td[1],dp[1][1],dp[2][1]})
			fen_pai2=this.extract_sandai_daipai(kuai_guan,fen_pai2,sanda_info,pos+1)


			table.insert(ret_table,{
				fen_pai=fen_pai2,
			})

		end


	end


	if #ret_table == 0 then 
		return nil 
	end




	--dump(ret_table)

	local ret_fen_pai=nil 
	for k,v in ipairs(ret_table) do
		ret_fen_pai=this.compare_fenpai(ret_fen_pai,v.fen_pai)
	end

	return ret_fen_pai



end


function this.extract_feiji_daipai(kuai_guan,fen_pai,sanda_info,pos)
	local ret_table={}
	local pai_info=sanda_info[pos]

	if kuai_guan[3] then 

		-- 不带的情况
		local fen_pai0=basefunc.deepcopy(fen_pai)
		if not fen_pai0[12] then 
			fen_pai0[12]={}
		end 

		table.insert(fen_pai0[12],pai_info.td)
		fen_pai0=this.extract_sandai_daipai(kuai_guan,fen_pai0,sanda_info,pos+1)

		if fen_pai0 then 
			table.insert(ret_table,{
				fen_pai=fen_pai0,
			})
		end

	end

	-- 带一的情况

	local fen_pai1=basefunc.deepcopy(fen_pai)
	local dp=this.remove_daipai(fen_pai1,pai_info.td[2]-pai_info.td[1]+1,{f=pai_info.td[1],t=pai_info.td[2]})
	if dp then 
		if not fen_pai1[10] then 
			fen_pai1[10]={}
		end
		--dump(pai_info)
		local fj_info={pai_info.td[1],pai_info.td[2]}
		for k,v in ipairs(dp) do 
			table.insert(fj_info,v[1])
		end
		table.insert(fen_pai1[10],fj_info)

		fen_pai1=this.extract_sandai_daipai(kuai_guan,fen_pai1,sanda_info,pos+1)
		if fen_pai1 then 
			table.insert(ret_table,{
				fen_pai=fen_pai1,
			})
		end
	end




	if kuai_guan[5] then 
		-- 带对的情况
		if fen_pai[2] and #fen_pai[2] > 0  then 
			local fen_pai2=basefunc.deepcopy(fen_pai)
			local dp=this.remove_duizhi(fen_pai2,pai_info.td[2]-pai_info.td[1]+1,{f=pai_info.td[1],t=pai_info.td[2]})
			if dp then 
				if not fen_pai2[11] then 
					fen_pai2[11]={}
				end
				local fj_info={pai_info.td[1],pai_info.td[2]}
				for k,v in ipairs(dp) do 
					table.insert(fj_info,v[1])
				end

				table.insert(fen_pai2[11],fj_info)
				fen_pai2=this.extract_sandai_daipai(kuai_guan,fen_pai2,sanda_info,pos+1)

				if fen_pai2 then 
					table.insert(ret_table,{
						fen_pai=fen_pai2,
					})
				end
			end
		end
	end

	if #ret_table == 0 then 
		return nil 
	end

	local ret_fen_pai=nil 
	for k,v in ipairs(ret_table) do
		ret_fen_pai=this.compare_fenpai(ret_fen_pai,v.fen_pai)
	end

	return ret_fen_pai

end


function this.extract_rocket_daipai(kuai_guan,fen_pai,sanda_info,pos)
	local ret_table={}
	local pai_info=sanda_info[pos]

	-- 王不拆的情况
	local fen_pai0=basefunc.deepcopy(fen_pai)
	fen_pai0[14]=true 
	fen_pai0=this.extract_sandai_daipai(kuai_guan,fen_pai0,sanda_info,pos+1)
	if fen_pai0 then 
		table.insert(ret_table,{
			fen_pai=fen_pai0
		})
	end

	-- 王拆成两张单牌
	local fen_pai1=basefunc.deepcopy(fen_pai)
	if not fen_pai1[1] then 
		fen_pai1[1]={}
	end

	table.insert(fen_pai1[1],{16})
	table.insert(fen_pai1[1],{17})
	table.sort(fen_pai1[1],face_greater_cmp_func)

	fen_pai1=this.extract_sandai_daipai(kuai_guan,fen_pai1,sanda_info,pos+1)
	if fen_pai1 then 
		table.insert(ret_table,{
			fen_pai=fen_pai1
		})
	end

	if #ret_table == 0 then 
		return nil 
	end

	local ret_fen_pai=nil 
	for k,v in ipairs(ret_table) do
		ret_fen_pai=this.compare_fenpai(ret_fen_pai,v.fen_pai)
	end

	return ret_fen_pai


end


function this.extract_pair_daipai(kuai_guan,fen_pai,sanda_info,pos)

	local pai_info=sanda_info[pos]
	local ret_table={}

	if not fen_pai[1] then 
		fen_pai[1]={}
	end

	if not fen_pai[2] then 
		fen_pai[2]={}
	end

	-- 拆成1+1 
	local fen_pai_1_1=basefunc.deepcopy(fen_pai)
	table.insert(fen_pai_1_1[1],pai_info.td)
	table.insert(fen_pai_1_1[1],pai_info.td)
	table.sort(  fen_pai_1_1[1],face_greater_cmp_func)


	fen_pai_1_1=this.extract_sandai_daipai(kuai_guan,fen_pai_1_1,sanda_info,pos+1)
	if fen_pai_1_1 then 
		table.insert(ret_table,{
			fen_pai=fen_pai_1_1 
		})
	end

	local fen_pai_2=basefunc.deepcopy(fen_pai)
	table.insert(fen_pai_2[2],pai_info.td)
	table.sort(  fen_pai_2[2],face_greater_cmp_func)

	fen_pai_2=this.extract_sandai_daipai(kuai_guan,fen_pai_2,sanda_info,pos+1)
	if fen_pai_2 then 
		table.insert(ret_table,{
			fen_pai=fen_pai_2
		})
	end

	--dump(ret_table)

	local ret_fen_pai=nil 
	for k,v in ipairs(ret_table) do
		ret_fen_pai=this.compare_fenpai(ret_fen_pai,v.fen_pai)
	end

	return ret_fen_pai



end


function this.extract_sandai_daipai(kuai_guan,fen_pai,sanda_info,pos)

	-- 三张的情况
	if pos > #sanda_info then 
		return fen_pai
	end


	local pai_info=sanda_info[pos]

	-- 飞机的情况
	if pai_info.tp==12 then 
		return this.extract_feiji_daipai(kuai_guan,fen_pai,sanda_info,pos)
	end

	if pai_info.tp==13 then 
		return this.extract_bomb_daipai(kuai_guan,fen_pai,sanda_info,pos)
	end

	if pai_info.tp==14 then 
		return this.extract_rocket_daipai(kuai_guan,fen_pai,sanda_info,pos)
	end

	if pai_info.tp==2 then 
		return this.extract_pair_daipai(kuai_guan,fen_pai,sanda_info,pos)
	end



	local ret_table={}

	if not fen_pai[1] then 
		fen_pai[1]={}
	end

	if not fen_pai[2] then 
		fen_pai[2]={}
	end

	-- 折成1+1+1 
	local fen_pai_1_1_1 =basefunc.deepcopy(fen_pai)
	table.insert(fen_pai_1_1_1[1],pai_info.td)
	table.insert(fen_pai_1_1_1[1],pai_info.td)
	table.insert(fen_pai_1_1_1[1],pai_info.td)
	table.sort(fen_pai_1_1_1[1],face_greater_cmp_func)
	fen_pai_1_1_1=this.extract_sandai_daipai(kuai_guan,fen_pai_1_1_1,sanda_info,pos+1)
	if fen_pai_1_1_1 then 
		table.insert(ret_table,{
			fen_pai=fen_pai_1_1_1,
		})
	end



	--折成2+1 
	local fen_pai_2_1 =basefunc.deepcopy(fen_pai)
	table.insert(fen_pai_2_1[1],pai_info.td)
	table.insert(fen_pai_2_1[2],pai_info.td)

	table.sort(fen_pai_2_1[1],face_greater_cmp_func)
	table.sort(fen_pai_2_1[2],face_greater_cmp_func)

	if kuai_guan[3]  or pai_info.last then 
		-- 不带的情况
		local fen_pai0=basefunc.deepcopy(fen_pai)
		table.insert(fen_pai0[3],pai_info.td)
		fen_pai0=this.extract_sandai_daipai(kuai_guan,fen_pai0,sanda_info,pos+1)
		if fen_pai0 then 

			--dump(fen_pai0)
			table.insert(ret_table,{
				fen_pai=fen_pai0,
			})
		end
	end

	-- 带一的情况
	local fen_pai1=basefunc.deepcopy(fen_pai)
	local dp=this.remove_daipai(fen_pai1,1,{f=pai_info.td[1],t=pai_info.td[1]})
	if dp then 
		if not fen_pai1[4] then 
			fen_pai1[4]={}
		end

		-- table.insert(fen_pai1[4],{pai_info.td,dp[1]})
		-- by lyx
		table.insert(fen_pai1[4],{pai_info.td[1],dp[1][1]})

		fen_pai1=this.extract_sandai_daipai(kuai_guan,fen_pai1,sanda_info,pos+1)
		if fen_pai1 then 
			table.insert(ret_table,{
				fen_pai=fen_pai1,
			})
		end
	end

	if kuai_guan[5] then 
		-- 带对的情况
		if fen_pai[2] and #fen_pai[2] > 0  then 
			local fen_pai2=basefunc.deepcopy(fen_pai)
			local dp=this.remove_duizhi(fen_pai2,1,{f=pai_info.td[1],t=pai_info.td[1]})
			if dp then 
				if not fen_pai2[5] then 
					fen_pai2[5]={}
				end

				--table.insert(fen_pai2[5],{pai_info.td,dp[1]})
				-- by lyx
				table.insert(fen_pai2[5],{pai_info.td[1],dp[1][1]})

				fen_pai2=this.extract_sandai_daipai(kuai_guan,fen_pai2,sanda_info,pos+1)

				if fen_pai2 then 
					table.insert(ret_table,{
						fen_pai=fen_pai2,
					})
				end
			end
		end
	end


	if #ret_table == 0 then 
		return nil 
	end


	local ret_fen_pai=nil 
	for k,v in ipairs(ret_table) do
		ret_fen_pai=this.compare_fenpai(ret_fen_pai,v.fen_pai)
	end

	return ret_fen_pai

end

--[[
--取两张牌的情况
1 2对子  
2 2单牌
3 1对子1单牌
4 1单牌和1从对子中抽取单牌
5 从对子中抽取2个单牌
6 1从对子中抽取单牌 1个对子
--取一张牌的情况
1 1对子  
2 1单牌
3 从对子中抽取1个单牌
--]]
function this.extract_sandai_daipai_shousu_min(data,count)
	data.fen_pai.dai_danpai={}
	--被带走的对子 （只是说她原本是对子，不一定）
	data.fen_pai.dai_duizi={}
	while count>0 do
		local fp=data.fen_pai
		if count>1 then
			local score=100000
			local _type=0
			local ls_s
			--取对子
			if fp[2] and #fp[2]>1 then
				--1  取两个对子
				ls_s=this.get_score_by_paiType(2,fp[2][#fp[2]]) + this.get_score_by_paiType(2,fp[2][#fp[2]-1])
				if  ls_s<score and data.kaiguan[5] then
					_type=1
					score=ls_s
				end
				--6   1从对子中抽取单牌+1个对子   
				ls_s=this.get_score_by_paiType(2,fp[2][#fp[2]]) + this.get_score_by_paiType(2,fp[2][#fp[2]-1])-this.get_score_by_paiType(1,fp[2][#fp[2]-1])
				if  ls_s<score and data.kaiguan[5] then
					_type=6
					score=ls_s
				end 
			end
			if fp[2] and #fp[2]>0 and fp[1] and #fp[1]>0 then
				--3 1对子1单牌
				ls_s=this.get_score_by_paiType(2,fp[2][#fp[2]]) + this.get_score_by_paiType(1,fp[1][#fp[1]])
				if  ls_s<score and data.kaiguan[5] then
					_type=3
					score=ls_s
				end
				--4 1单牌和1从对子中抽取单牌
				ls_s=this.get_score_by_paiType(1,fp[1][#fp[1]])+this.get_score_by_paiType(2,fp[2][#fp[2]])-this.get_score_by_paiType(1,fp[2][#fp[2]])
				if  ls_s<score then
					_type=4
					score=ls_s
				end
			end
			if fp[2] and #fp[2]>0 then
				--5  从对子中抽取2个单牌
				ls_s=this.get_score_by_paiType(2,fp[2][#fp[2]])
				if  ls_s<score then
					_type=5
					score=ls_s
				end
			end
			if fp[1] and #fp[1]>1 then
				--2 2单牌
				ls_s=this.get_score_by_paiType(1,fp[1][#fp[1]])+this.get_score_by_paiType(1,fp[1][#fp[1]-1])
				if  ls_s<score then
					_type=2
					score=ls_s
				end
			end
			if _type~=0 then
				count=count-2
				if _type==1 then
					fp.dai_duizi[#fp.dai_duizi+1]=fp[2][#fp[2]]
					fp[2][#fp[2]]=nil
					fp.dai_duizi[#fp.dai_duizi+1]=fp[2][#fp[2]]
					fp[2][#fp[2]]=nil
				elseif _type==2 then
					fp.dai_danpai[#fp.dai_danpai+1]=fp[1][#fp[1]]
					fp[1][#fp[1]]=nil
					fp.dai_danpai[#fp.dai_danpai+1]=fp[1][#fp[1]]
					fp[1][#fp[1]]=nil
				elseif _type==3 then
					fp.dai_duizi[#fp.dai_duizi+1]=fp[2][#fp[2]]
					fp[2][#fp[2]]=nil
					fp.dai_danpai[#fp.dai_danpai+1]=fp[1][#fp[1]]
					fp[1][#fp[1]]=nil
				elseif _type==4 then
					fp.dai_danpai[#fp.dai_danpai+1]=fp[1][#fp[1]]
					local p=fp[2][#fp[2]]
					fp.dai_danpai[#fp.dai_danpai+1]=p
					fp[2][#fp[2]]=nil
					fp[1][#fp[1]]=p
				elseif _type==5 then
					local p=fp[2][#fp[2]]
					fp.dai_danpai[#fp.dai_danpai+1]=p
					fp.dai_danpai[#fp.dai_danpai+1]=p
					fp[2][#fp[2]]=nil
				elseif _type==6 then
					local p=fp[2][#fp[2]]
					fp.dai_danpai[#fp.dai_danpai+1]=p
					fp[2][#fp[2]]=nil
					p=fp[2][#fp[2]]
					fp.dai_danpai[#fp.dai_danpai+1]=p
					fp[2][#fp[2]]=nil
					fp[1]=fp[1] or {}
					fp[1][#fp[1]+1]=p    
				end
			else
				--数量不足
				count=count-1
			end
		else
			local score=100000
			local _type=0
			local ls_s
			--取对子
			if fp[2] and #fp[2]>0 then
				--1  取1对子  
				ls_s=this.get_score_by_paiType(2,fp[2][#fp[2]])
				if  ls_s<score and data.kaiguan[5] then
					_type=1
					score=ls_s
				end
				--6   1从对子中抽取单牌
				ls_s=this.get_score_by_paiType(2,fp[2][#fp[2]])-this.get_score_by_paiType(1,fp[2][#fp[2]])
				if  ls_s<score then
					_type=3
					score=ls_s
				end 
			end
			if fp[1] and #fp[1]>0 then 
				ls_s=this.get_score_by_paiType(1,fp[1][#fp[1]])
				if  ls_s<score  then
					_type=2
					score=ls_s
				end
			end
			if _type~=0 then
				if _type==1 then 
					fp.dai_duizi[#fp.dai_duizi+1]=fp[2][#fp[2]]
					fp[2][#fp[2]]=nil
				elseif _type==2 then
					fp.dai_danpai[#fp.dai_danpai+1]=fp[1][#fp[1]]
					fp[1][#fp[1]]=nil
				elseif _type==3 then 
					local p=fp[2][#fp[2]]
					fp.dai_danpai[#fp.dai_danpai+1]=p
					fp[1]=fp[1] or {}
					fp[2][#fp[2]]=nil
					fp[1][#fp[1]+1]=p
				end 

			end
			count=count-1
		end 
	end 
end

function this.analyse_pai_other(pai_map,data)
	--提取 王炸
	if pai_map[16] and pai_map[17] then
		data.fen_pai[14]=true
	else
		for i=17,16,-1 do
			if pai_map[i] and pai_map[i]==1 then            
				data.fen_pai[1]=data.fen_pai[1] or {}
				data.fen_pai[1][#data.fen_pai[1]+1]={i}
			end
		end
	end
	--
	local sd_count=0
	for k,v in pairs(pai_map) do
		if v==3 then
			sd_count=sd_count+1
		end
	end
	local fen_pai=nil
	local data_copy=basefunc.deepcopy(data)
	-- for sd_fenjie=0,sd_count do
	-- dump(pai_map)
	data=basefunc.deepcopy(data_copy)
	local i=15
	while i>2 do
		if pai_map[i] then
			--提取炸弹
			if  pai_map[i]==4 then
				data.fen_pai[13]=data.fen_pai[13] or {}
				data.fen_pai[13][#data.fen_pai[13]+1]={i}
				--提取三带或飞机
			elseif pai_map[i]==3 then
				-- if i==sd_fenjie then
				-- 	data.fen_pai[2]=data.fen_pai[2] or {}
				-- 	data.fen_pai[2][#data.fen_pai[2]+1]=i
				-- 	data.fen_pai[1]=data.fen_pai[1] or {}
				-- 	data.fen_pai[1][#data.fen_pai[1]+1]=i
				-- else
				data.fen_pai[3]=data.fen_pai[3] or {}
				data.fen_pai[3][#data.fen_pai[3]+1]={i}
				-- end
				-- print("tttttt",i)
				--提取对子
			elseif pai_map[i]==2 then
				data.fen_pai[2]=data.fen_pai[2] or {}
				data.fen_pai[2][#data.fen_pai[2]+1]={i}
				--提取单牌    
			elseif pai_map[i]==1 then            
				data.fen_pai[1]=data.fen_pai[1] or {}
				data.fen_pai[1][#data.fen_pai[1]+1]={i}
			end
		end
		i=i-1
	end
	

	local status=this.analyse_sandai(data)
	if status then
		fen_pai = this.compare_fenpai(data.fen_pai,fen_pai)
	end
	-- end
	return fen_pai
	-- dump(data.fen_pai)
end
function this.merge_sz_pai(fen_pai)
	for _type=6,7 do
		if fen_pai and fen_pai[_type] then
			local pai_data=fen_pai[_type]
			local len=#pai_data
			for k=1,len  do
				local v=pai_data[k]
				if v then
					local len1=#pai_data
					for i=k+1,len do
						if pai_data[i] then
							if v[1]==pai_data[i][2]+1 then
								v[1]=pai_data[i][1]
								pai_data[i]=pai_data[#pai_data]
								pai_data[#pai_data]=nil
							elseif v[2]+1==pai_data[i][1] then
								v[2]=pai_data[i][2]
								pai_data[i]=pai_data[#pai_data]
								pai_data[#pai_data]=nil
							elseif _type==6 and v[1]==pai_data[i][1] and v[2]==pai_data[i][2] then
								pai_data[i]=pai_data[#pai_data]
								pai_data[#pai_data]=nil

								pai_data[k]=pai_data[#pai_data]
								pai_data[#pai_data]=nil

								fen_pai[7]=fen_pai[7] or {}
								fen_pai[7][#fen_pai[7]+1]={v[1],v[2]}
							end

						end
					end
				end
			end
		end
	end
end
--[[
data
--顺子类型的最短长度
kaiguan{
}
limit{
sz_min_len={5,3}   --1表示顺子  2表示连对
sz_max_len={12,10}
}
--]]


function this.analyse_pai(pai_map,data)
	--type：1表示顺子  2表示连队 3飞机
	data.fen_pai=data.fen_pai or {}
	for _type=1,3 do
		local start_p=sz_start_pai
		local end_p=sz_end_pai-data.limit.sz_min_len[_type]+1
		while start_p<=end_p do

			local len=data.limit.sz_min_len[_type]

			while len<=data.limit.sz_max_len[_type] do
				local status,next=check_is_lianxu(pai_map,start_p,len,_type,15) 
				if status then
					local pai_type=5+_type
					if _type==3 then
						pai_type=12
					end
					chang_value_by_lianxu(pai_map,start_p,len,-_type)
					add_sz(data,start_p,len,pai_type)
					this.analyse_pai(pai_map,data)
					chang_value_by_lianxu(pai_map,start_p,len,_type)
					reduce_sz(data,pai_type)
				else
					if len==data.limit.sz_min_len[_type] then
						start_p=next-1                       
					end
					break 
				end
				len=len+1            
			end
			start_p=start_p+1
		end
	end
	local pai_map_copy=basefunc.deepcopy(pai_map)
	local data_copy=basefunc.deepcopy(data)
	--分析其他牌


	local fen_pai=this.analyse_pai_other(pai_map_copy,data_copy)

	data.fen_pai_res=this.compare_fenpai(fen_pai,data.fen_pai_res)


end
--恢复对子和单牌  在计算分数的时候三带的对子和单牌加入了 dai_danpai dai_duizi
function this.resume_dp_and_dz(fen_pai)
	local map={}
	if fen_pai[1] then
		for k,v in ipairs(fen_pai[1]) do
			map[v]=map[v] or 0
			map[v]=map[v]+1
		end
	end
	if fen_pai[2] then
		for k,v in ipairs(fen_pai[2]) do
			map[v]=map[v] or 0
			map[v]=map[v]+2
		end
	end
	if fen_pai.dai_danpai then
		for k,v in ipairs(fen_pai.dai_danpai) do
			map[v]=map[v] or 0
			map[v]=map[v]+1
		end
		-- fen_pai.dai_danpai=nil
	end
	if fen_pai.dai_duizi then
		for k,v in ipairs(fen_pai.dai_duizi) do
			map[v]=map[v] or 0
			map[v]=map[v]+2
		end
		-- fen_pai.dai_duizi=nil
	end
	fen_pai[1]=nil
	fen_pai[2]=nil
	for i=3,17 do
		if map[i] then
			fen_pai[map[i]]=fen_pai[map[i]] or {}
			fen_pai[map[i]][#fen_pai[map[i]]+1]=i
		end
	end
end

function this.get_fenpai_score(fen_pai)
	if nor_pai_power_cfg.compare_fenpai and nor_pai_power_cfg.get_fenpai_score then
		return nor_pai_power_cfg.get_fenpai_score(fen_pai)
	end 

	return this.default_get_fenpai_score(fen_pai)
end


function this.default_get_fenpai_score(fen_pai)

	local score=0
	local shoushu=0
	local bomb_count=0
	for i=1,13 do
		if fen_pai[i] then
			for k,v in pairs(fen_pai[i]) do
				--print("xxxxxx type",i)
				--dump(v)
				score=score+this.get_score_by_paiType(i,v)
				shoushu=shoushu+1
			end
			if i==13 then
				bomb_count=bomb_count+#fen_pai[i]
			end
		end
	end
	if fen_pai[14] then
		score=score+this.get_score_by_paiType(14)
		shoushu=shoushu+1
		bomb_count=bomb_count+1
	end
	score=score-(shoushu-bomb_count-1)*7
	return score,shoushu,bomb_count
end


function this.get_fenpai_value(fen_pai)

	--dump(nor_pai_power_cfg.get_fenpai_value)
	if nor_pai_power_cfg.get_fenpai_value then
		return nor_pai_power_cfg.get_fenpai_value(fen_pai)
	end 

	local score,shoushu,bomb_count=this.get_fenpai_score(fen_pai)
	local xiajiao,no_xiajiao_socre=ddz_tg_assist_lib.check_is_xiajiao_special(fen_pai,nor_pai_power_cfg.my_seat,nor_pai_power_cfg.query_map)
	fen_pai.score=score
	fen_pai.shoushu=shoushu
	fen_pai.bomb_count=bomb_count
	fen_pai.xiajiao=xiajiao
	fen_pai.no_xiajiao_socre=no_xiajiao_socre

end

local function default_compare_fenpai(fen_pai_1,fen_pai_2)

	if fen_pai_1 and not fen_pai_2 then
		return fen_pai_1
	end

	if not fen_pai_1 and fen_pai_2 then
		return fen_pai_2
	end

	if not fen_pai_1 and not fen_pai_2 then 
		return nil 
	end



	if fen_pai_1.xiajiao>0 and fen_pai_2.xiajiao==0 then
		return fen_pai_1
	end
	if fen_pai_1.xiajiao==0 and fen_pai_2.xiajiao>0 then
		return fen_pai_2
	end
	if fen_pai_1.xiajiao==0 and fen_pai_2.xiajiao==0 then
		if fen_pai_1.no_xiajiao_socre>fen_pai_2.no_xiajiao_socre then
			return fen_pai_1
		end
		if fen_pai_1.no_xiajiao_socre<fen_pai_2.no_xiajiao_socre then
			return fen_pai_2
		end 
	end
	--炸弹数量
	if fen_pai_1.bomb_count>fen_pai_2.bomb_count then
		return fen_pai_1
	end
	if fen_pai_1.bomb_count<fen_pai_2.bomb_count then
		return fen_pai_2
	end
	--下叫类型
	if fen_pai_1.xiajiao<fen_pai_2.xiajiao then
		return fen_pai_1
	end 
	if fen_pai_1.xiajiao>fen_pai_2.xiajiao then
		return fen_pai_2
	end
	--分数
	if fen_pai_1.score>fen_pai_2.score then
		return fen_pai_1
	end
	if fen_pai_1.score<fen_pai_2.score then
		return fen_pai_2
	end

	if fen_pai_1.shoushu<fen_pai_2.shoushu then
		return fen_pai_1
	end 
	if fen_pai_1.shoushu>fen_pai_2.shoushu then
		return fen_pai_2
	end

	return fen_pai_2
end
function this.compare_fenpai(fen_pai_1,fen_pai_2)

	if fen_pai_1 and not fen_pai_1.score then
		this.get_fenpai_value(fen_pai_1)
	end
	if fen_pai_2 and not fen_pai_2.score then
		this.get_fenpai_value(fen_pai_2)
	end


	--dump(nor_pai_power_cfg.compare_fenpai) 
	if nor_pai_power_cfg.compare_fenpai then
		return nor_pai_power_cfg.compare_fenpai(fen_pai_1,fen_pai_2)
	end
	return default_compare_fenpai(fen_pai_1,fen_pai_2) 
end

function this.nor_ddz_analyse_pai(pai_map,kaiguan,limit_cfg,power_cfg)

	--kaiguan = kaiguan or nor_data_ddz_cfg
	-- by lyx
	kaiguan = kaiguan or ddz_tg_assist_lib.data_ddz_cfg.kaiguan
	limit_cfg=limit_cfg or ddz_tg_assist_lib.data_ddz_cfg.limit
	local data={kaiguan=kaiguan,limit=limit_cfg}

	nor_pai_power_cfg=power_cfg or default_pai_power_cfg


	--dump(pai_map)
	this.analyse_pai(pai_map,data)
	--dump(data.fen_pai)
	return data.fen_pai_res
end

local function get_fenpai_value_by_realxj(fen_pai)

	local score,shoushu,bomb_count=this.get_fenpai_score(fen_pai)
	local xiajiao,no_xiajiao_socre=ddz_tg_assist_lib.check_is_xiajiao_special(fen_pai,nor_pai_power_cfg.my_seat,nor_pai_power_cfg.query_map,true)
	fen_pai.score=score
	fen_pai.shoushu=shoushu
	fen_pai.bomb_count=bomb_count
	fen_pai.xiajiao=xiajiao
	fen_pai.no_xiajiao_socre=no_xiajiao_socre
end
local function xiaojiaobest_compare_fenpai(fen_pai_1,fen_pai_2)

	if fen_pai_1 and not fen_pai_2 then
		return fen_pai_1
	end
	if not fen_pai_1 and fen_pai_2 then
		return fen_pai_2
	end

	if not fen_pai_1 and not fen_pai_2 then 
		return nil 
	end

	if fen_pai_1.xiajiao>0 and fen_pai_2.xiajiao==0 then
		return fen_pai_1
	end
	if fen_pai_1.xiajiao==0 and fen_pai_2.xiajiao>0 then
		return fen_pai_2
	end
	if fen_pai_1.xiajiao==0 and fen_pai_2.xiajiao==0 then
		if fen_pai_1.no_xiajiao_socre>fen_pai_2.no_xiajiao_socre then
			return fen_pai_1
		end
		if fen_pai_1.no_xiajiao_socre<fen_pai_2.no_xiajiao_socre then
			return fen_pai_2
		end 
	end
	if fen_pai_1.xiajiao>0 and fen_pai_2.xiajiao>0 then
		if fen_pai_1.xiajiao<fen_pai_2.xiajiao then
			return fen_pai_1
		end
		if fen_pai_1.xiajiao>fen_pai_2.xiajiao then
			return fen_pai_2
		end
	end
	--炸弹数量
	if fen_pai_1.bomb_count>fen_pai_2.bomb_count then
		return fen_pai_1
	end
	if fen_pai_1.bomb_count<fen_pai_2.bomb_count then
		return fen_pai_2
	end
	--下叫类型
	if fen_pai_1.xiajiao<fen_pai_2.xiajiao then
		return fen_pai_1
	end 
	if fen_pai_1.xiajiao>fen_pai_2.xiajiao then
		return fen_pai_2
	end
	--分数
	if fen_pai_1.score>fen_pai_2.score then
		return fen_pai_1
	end
	if fen_pai_1.score<fen_pai_2.score then
		return fen_pai_2
	end

	if fen_pai_1.shoushu<fen_pai_2.shoushu then
		return fen_pai_1
	end 
	if fen_pai_1.shoushu>fen_pai_2.shoushu then
		return fen_pai_2
	end

	return fen_pai_2
end
--按下叫最优来生成牌
function this.nor_ddz_analyse_pai_by_xjBest(pai_map,kaiguan,limit_cfg,power_cfg)

	--kaiguan = kaiguan or nor_data_ddz_cfg
	-- by lyx
	kaiguan = kaiguan or ddz_tg_assist_lib.data_ddz_cfg.kaiguan
	limit_cfg=limit_cfg or ddz_tg_assist_lib.data_ddz_cfg.limit
	local data={kaiguan=kaiguan,limit=limit_cfg}

	nor_pai_power_cfg=power_cfg
	power_cfg.compare_fenpai=xiaojiaobest_compare_fenpai
	power_cfg.get_fenpai_value=get_fenpai_value_by_realxj

	--dump(pai_map)
	this.analyse_pai(pai_map,data)
	--dump(data.fen_pai)
	return data.fen_pai_res
end


local tremove = table.remove

-- by lyx : 牌处理函数 
-- 从一副牌中指定位置移除 指定类型的牌
--
-- pai={
-- 		[1]={3,4,5,6},
-- 		[2]={7,8},
-- 		[4]={{4,1},{5,1}}
--       ^           ^
--       |           |
--    pai_type      pos 
-- }
-- rm_type 移除牌的类型 
-- rm_data 移除牌的数据
-- 
-- 要求移除牌后，把多余的牌加到正确的位置上面
--
function this.pai_split_remove(pai,pai_type,pos,rm_type,rm_data)

	local _pai_map = {}

	-- 取出
	ddz_tg_assist_lib.change_pai_map_data(_pai_map,pai_type,pai[pai_type][pos],true)


	tremove(pai[pai_type],pos)

	--dump(_pai_map)
	-- 加入

	ddz_tg_assist_lib.change_pai_map_data(_pai_map,rm_type,rm_data,false)

	-- 分牌
	local fen_pai=this.nor_ddz_analyse_pai(_pai_map)
	if fen_pai then
		for _type,_pai_array in pairs(fen_pai) do
			if type(_type) == "number" then 
				local _type_d = pai[_type] or {}
				pai[_type] = _type_d

				basefunc.array_copy(_pai_array,_type_d)
			end
		end
	end
end


function this.check_is_xiajiao_after_cp(data,pai,pai_type,pai_data,absolute,all_unkown)
	local pai_after_cp=this.pai_remove(pai,pai_type,pai_data)

	if not pai_after_cp then 
		return false 
	end

	local xj_score=0

	if absolute then 
		xj_score = ddz_tg_assist_lib.check_is_xiajiao_absolute(pai_after_cp,data.base_info.my_seat,data.query_map,all_unkown)
	else 
		xj_score = ddz_tg_assist_lib.check_is_xiajiao(pai_after_cp,data.base_info.my_seat,data.query_map,false)
	end

	return xj_score ~= 0

end



function this.pai_remove(pai,pai_type,pai_data) 

	if not pai[pai_type] then 
		return nil 
	end

	local pai_data_after_cp= basefunc.deepcopy(pai)

	if pai_type == 14 then 
		pai_data_after_cp[14]=nil 
		return pai_data_after_cp 
	end

	for k,v in ipairs(pai_data_after_cp[pai_type]) do 
		if this.pai_equal(v,pai_data) then 
			table.remove(pai_data_after_cp[pai_type],k)
			return pai_data_after_cp 
		end
	end
	return nil 
end


function this.pai_equal(left,right)

	if #left ~= #right then 
		return false 
	end

	for k,v in ipairs(left)  do 
		if v ~= right[k] then 
			return false 
		end
	end
	return true
end


-- 从一个类型中移除一个牌型 
-- 生成一个pai map
function this.pai_type_remove(from_type,from_data,take_type,take_data)

	local _pai_map = {}

	-- 取出
	ddz_tg_assist_lib.change_pai_map_data(_pai_map,from_type,from_data,true)

	-- 加入
	ddz_tg_assist_lib.change_pai_map_data(_pai_map,take_type,take_data,false)

	-- 分牌
	local fen_pai=this.nor_ddz_analyse_pai(_pai_map)

	return fen_pai 

end





return this

