--HEWEI
-- 斗地主生成好牌
-- package.path=package.path..";/Users/hewei/project/JyQipai_server/skynet/game/common/?.lua"
-- require "printfunc"

local DDZ_CREATE_HP={}

local nor_ddz_hp_cfg={
	sw= 60,  --得到双王的概率
	dw=80,  --得到大王的概率
	er=75,  --得到二的概率
	boom=70,

	shuangfei=40,
	sanfei=60,
	--最大炸弹数
	max_boom=2,

	--单牌数量限制  尽量少的产生单牌
	limit_dp_count=50
}

local nor_ddz_hp_level1_cfg={
	shuangfei=30,
	sanfei=35,
	--最大炸弹数
	max_boom=2,

	boom=60,
	--单牌数量限制  尽量少的产生单牌
	limit_dp_count=30,
}
--限制炸弹
function DDZ_CREATE_HP.nor_ddz_hp_level1(cfg)
	cfg=cfg or nor_ddz_hp_level1_cfg
	local pai_map={}
	local all_num=20 
	local count=0
	local max_boom=cfg.max_boom
	--高级牌
	local gaoji_pai={
		{17,16,15,15,15},
		{17,16,15,15},
		{17,15,15,15,15},
		{15,15,15,15},
		{17,15,15,15},
		{17,16,15},
		{16,15,15,15},
		{15,15,15},
		{16,15,15,15,15},
	}

	local gj= math.random(1,#gaoji_pai)
	count=count+(#gaoji_pai[gj])
	for k,v in ipairs(gaoji_pai[gj]) do
		pai_map[v]=pai_map[v] or 0
		pai_map[v]=pai_map[v]+1
	end

	for k,v in pairs(pai_map) do
		if v==4 then
			max_boom=max_boom-1
		end
	end

	if pai_map[16] and pai_map[17] and pai_map[16]==1 and pai_map[17]==1 then
		max_boom=max_boom-1
	end

	local get_ld_or_sz_or_sandai=function (len,num)
		local start=math.random(3,15-len)
		for i=1,len do
			pai_map[start]=pai_map[start] or 0
			pai_map[start]=pai_map[start] + num
			start=start+1
			count=count+num
		end
	end

	local v=math.random(1,3)
	--顺子	
	if v==1 then
		get_ld_or_sz_or_sandai(math.random(6,10),1)
	--连队	
	elseif v==2 then
		get_ld_or_sz_or_sandai(math.random(3,4),2)
	--三代	
	else
		local v2=math.random(1,100)
		if v2<cfg.shuangfei then
			get_ld_or_sz_or_sandai(2,3)
		elseif v2<cfg.sanfei then
			get_ld_or_sz_or_sandai(3,3)
		--三带
		else
			--两个或者三个
			local v2=math.random(1,100)
			local num=2
			if v2<50 then
				num=3
			end
			local sd=math.random(12,14)
			pai_map[sd]=pai_map[sd] or 0
			pai_map[sd]=pai_map[sd]+3
			count=count+3
			num=num-1
			while num>0 do
				sd=math.random(3,14)
				if not pai_map[sd] then 
					pai_map[sd]=pai_map[sd] or 0
					pai_map[sd]=pai_map[sd]+3
					count=count+3
					num=num-1
				end
			end
		end
	end



	for i=1,2 do
		if count<17 and max_boom>0 and math.random(1,100)< cfg.boom then
			local card=math.random(3,14)
			--找一个没出现过的牌
			local boom_list={}
			for k=3,14 do
				if not pai_map[k] or pai_map[k]==0 then
					boom_list[#boom_list+1]=k
				end
			end
			if #boom_list>0 then 
				pai_map[boom_list[math.random(1,#boom_list)]]=4
				count=count+4
				max_boom=max_boom-1
			end
		end
	end

	local add_sandai=function ()
		--找一个没出现过的牌
		local sd_list={}
		for k=3,14 do
			if not pai_map[k] or pai_map[k]==0 then
				sd_list[#sd_list+1]=k
			end
		end
		if #sd_list>0 then 
			pai_map[sd_list[math.random(1,#sd_list)]]=3
			count=count+3
		end
	end

	--再来一个三代一
	if count<13 then
		add_sandai()
	end 
	if count<17 and math.random(1,100)<cfg.limit_dp_count then
		add_sandai()
	end

	--补充对子
	local add_dz=function ( )
			local dz_start=12
			for i=1,5 do 
				--如果张数还不够给与一个大对子
				if count<17 then
					local card=math.random(dz_start,14)
					for k=card,14 do
						if not pai_map[k] or pai_map[k]<2 then
							pai_map[k]=pai_map[k] or 0
							pai_map[k]=pai_map[k]+2
							count=count+2
							break
						end
					end
					dz_start=dz_start-3
					if dz_start<3 then
						dz_start=3
					end
				end
			end
	end

	if count<19 and math.random(1,100)<cfg.limit_dp_count then
		add_dz()
	end

	local dp_start=9
	while count<20 do
		local card=math.random(dp_start,14)
		if not pai_map[card] or pai_map[card]<3 then
			pai_map[card]=pai_map[card] or 0
			pai_map[card]=pai_map[card]+1
			count=count+1
		end
		dp_start=dp_start-3
		if dp_start<3 then
			dp_start=3
		end
	end

	return  DDZ_CREATE_HP.get_pai_no(pai_map)
end


function DDZ_CREATE_HP.nor_ddz_hp_by_gailv(cfg)
	cfg=cfg or nor_ddz_hp_cfg
	local pai_map={}
	local all_num=20 
	local count=0
	
	local get_ld_or_sz=function (len,num)
		local start=math.random(3,15-len)
		for i=1,len do
			pai_map[start]=num
			start=start+1
			count=count+num
		end
	end
	
	local get_feiji=function (len)
		local start=math.random(3,15-len)
		for i=1,len do
			pai_map[start]=3
			start=start+1
			count=count+3
		end
	end


	local v=math.random(1,3)
	--顺子	
	if v==1 then
		get_ld_or_sz(math.random(8,12),1)
	--连队	
	elseif v==2 then
		get_ld_or_sz(math.random(4,6),2)
	--三代	
	else
		local v2=math.random(1,100)
		if v2<cfg.shuangfei then
			get_feiji(2)
		elseif v2<cfg.sanfei then
			get_feiji(3)
		--三带
		else
			--两个或者三个
			local v2=math.random(1,100)
			local num=2
			if v2<50 then
				num=3
			end
			local sd=math.random(12,14)
			pai_map[sd]=3
			count=count+3
			num=num-1
			while num>0 do
				sd=math.random(3,14)
				if not pai_map[sd] then 
					pai_map[sd]=3
					count=count+3
					num=num-1
				end
			end
		end
	end

	--王
	if math.random(1,100)< cfg.sw then
		pai_map[17]=1
		pai_map[16]=1
		count=count+2
	else
		if math.random(1,100)< cfg.dw then
			pai_map[17]=1
		else
			pai_map[16]=1
		end
		count=count+1
	end

	for i=1,4 do
		if math.random(1,100)< cfg.er then
			pai_map[15]=pai_map[15] or 0
			pai_map[15]=pai_map[15]+1
			count=count+1
		end
	end
	if not pai_map[15] then
		pai_map[15]=math.random(1,2)
		count=count+pai_map[15]
	end 

	for i=1,2 do
		if count<17 and math.random(1,100)< cfg.boom then
			local card=math.random(3,14)
			--找一个没出现过的牌
			for k=card,14 do
				if not pai_map[card] then
					pai_map[card]=4
					count=count+4
					break
				end
			end
			
		end
	end
	--如果张数还不够给与一个对子
	if count<19 then
		local card=math.random(11,14)
		for k=card,14 do
			if not pai_map[card] or pai_map[card]<3 then
				pai_map[card]=pai_map[card] or 0
				pai_map[card]=pai_map[card]+2
				count=count+2
				break
			end
		end
	end
	--如果张数还不够给与一个对子
	if count<19 then
		local card=math.random(3,14)
		for k=card,14 do
			if not pai_map[card] or pai_map[card]<3 then
				pai_map[card]=pai_map[card] or 0
				pai_map[card]=pai_map[card]+2
				count=count+2
				break
			end
		end
	end

	while count<20 do
		local card=math.random(3,14)
		if not pai_map[card] or pai_map[card]<4 then
			pai_map[card]=pai_map[card] or 0
			pai_map[card]=pai_map[card]+1
			count=count+1
		end
	end
	return  DDZ_CREATE_HP.get_pai_no(pai_map)
end

function DDZ_CREATE_HP.get_pai_no(pai_map)
	local pai_no_map={}
	local pai={
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

	local k=1
	for i=3,17 do
		if pai_map[i] and pai_map[i]>0 then
			local r=3
			if i>15 then
				r=0
			end
			local pos
			for l=1,pai_map[i] do
				pos=math.random(k,k+r)
				pai_no_map[pai[pos]]=true
				pai[pos]=pai[k+r]
				r=r-1
			end
		end
		if i<16 then
			k=k+4
		else
			k=k+1
		end

	end
	return pai_no_map
end

function DDZ_CREATE_HP.get_re_pai_pool(pai_no_map)
	local pai={
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
	for k,v in pairs(pai_no_map) do
		pai[k]=nil
	end
	local k=1
	local new_pai={}
	for i=1,54	do
		if pai[i] then
			new_pai[k]=pai[i]
			k=k+1
		end
	end

	---- 打乱顺序
	local count = #new_pai
	for i=1,count-1 do
		local random_index = math.random(i,count)
		new_pai[i],new_pai[random_index] = new_pai[random_index],new_pai[i]
	end


	return new_pai
end
--取地主牌
function DDZ_CREATE_HP.get_dizhu_pai(pai_no_map)
	local dz_pai={}
	local count=0
	-- dump(pai_no_map,">>>>>>>>>>>>>>>>>>>>>>>>> get_dizhu_pai")
	while count<3 do
		local pos=math.random(1,47)
		if pai_no_map[pos] then
			dz_pai[#dz_pai+1]=pos
			pai_no_map[pos]=nil
			count=count+1
		end
	end
	return dz_pai
end



-- for i=1,100000 do
-- 	local pai=DDZ_CREATE_HP.nor_ddz_hp_level1()
-- 	local c=0
-- 	for k,v in pairs(pai) do
-- 		c=c+1
-- 	end
-- 	if c~=20 then
-- 		print(c)
-- 		dump(pai)
-- 		break
-- 	end
-- end
-- dump(pai)


-- local pai=DDZ_CREATE_HP.nor_ddz_hp()
-- local pai_list=DDZ_CREATE_HP.get_pai_no(pai)
-- dump(pai_list)
-- print("***************")
-- local re_pai=DDZ_CREATE_HP.tichu_pai(pai_list)
-- dump(repai)
-- print("***************")
-- local new_pai_list,dz_pai=DDZ_CREATE_HP.qu_dizhi_pai(pai_list)
-- dump(new_pai_list)
-- dump(dz_pai)
return DDZ_CREATE_HP

















