
require "printfunc"
local basefunc = require "basefunc"

local mj_fahaopai_base_lib={}


--大对子  count 数量,no_yao_jiu,9,pai_map 剩余的牌map,my_pai_map我的牌map color本次需要的颜色
local function get_ddz_or_dz_or_gang(need_count,limit_count,max_limit,count,no_yao_jiu,pai_map,my_pai_map,color,map)
	local s=1+color*10
	local e=9+color*10
	if no_yao_jiu then
		s=s+1
		e=e-1
	end
	local fail=nil

	for i=1,count do
		local v=math.random(s,e)
		local v_copy=v
		for k=1,2 do
			if k==2 then
				limit_count=max_limit
				--这个时候放弃中章 以做出牌为重
				s=1+color*10
				e=9+color*10
			end 
			while true do
				if my_pai_map[v]+need_count<limit_count and pai_map[v]>=need_count then
					map[v]=map[v] or 0
					map[v]=map[v] + 1
					my_pai_map[v]=my_pai_map[v]+need_count
					pai_map[v]=pai_map[v]-need_count
					break
				else
					v=v+1
					if v>e then
						v=s
					end
					if v==v_copy then
						fail=i-1
						break
					end
				end
			end
			if not fail then
				break
			end
		end
		if fail then
			break
		end
	end
	if fail then
		return nil,fail
	end
	return true
end
local function delete_pai_from_pai_map(data,pai_map,type)
	if data then
		if type=="sz" then
			for k,v in pairs(data) do
				pai_map[k]=pai_map[k]-1*v
				pai_map[k+1]=pai_map[k+1]-1*v
				pai_map[k+2]=pai_map[k+2]-1*v
			end
		else
			local count=3
			if type=="dz" then
				count=2
			elseif type=="gang" then
				count=4
			end
			for k,v in pairs(data) do
				pai_map[k]=pai_map[k]-count*v
			end
		end
	end

end

function mj_fahaopai_base_lib.get_ddz(count,no_yao_jiu,pai_map,my_pai_map,color,ddz)
	return get_ddz_or_dz_or_gang(3,4,5,count,no_yao_jiu,pai_map,my_pai_map,color,ddz)
end
--顺子
function mj_fahaopai_base_lib.get_shunzi(count,no_yao_jiu,pai_map,my_pai_map,color,map)
	local s=1+color*10
	local e=7+color*10
	if no_yao_jiu then
		s=s+1
		e=e-1
	end

	local fail=nil

	for i=1,count do
		local v=math.random(s,e)
		local v_copy=v
		local limit=4 
		for k=1,2 do
			local limit=4 
			if k==2 then
				limit=5
				--这个时候放弃中章 以做出牌为重
				s=1+color*10
				e=7+color*10
			end
			while true do
				if my_pai_map[v]+1<limit and my_pai_map[v+1]+1<limit and my_pai_map[v+2]+1<limit and pai_map[v]>0 and pai_map[v+1]>0 and pai_map[v+2]>0 then
					map[v]=map[v] or 0
					map[v]=map[v]+1
					my_pai_map[v]=my_pai_map[v]+1
					my_pai_map[v+1]=my_pai_map[v+1]+1
					my_pai_map[v+2]=my_pai_map[v+2]+1

					pai_map[v]=pai_map[v]-1
					pai_map[v+1]=pai_map[v+1]-1
					pai_map[v+2]=pai_map[v+2]-1

					break
				else
					v=v+1
					if v>e then
						v=s
					end
					if v==v_copy then
						fail=i-1
						break
					end
				end
			end
			if not fail then
				break
			end
		end
		if fail then
			break
		end

	end
	if fail then
		return nil,fail
	end
	return true
end
--小对子
function mj_fahaopai_base_lib.get_dz(count,no_yao_jiu,pai_map,my_pai_map,color,dz)
	return get_ddz_or_dz_or_gang(2,4,5,count,no_yao_jiu,pai_map,my_pai_map,color,dz)	
end
--杠  
function mj_fahaopai_base_lib.get_gang(count,no_yao_jiu,pai_map,my_pai_map,color,gang)
	return get_ddz_or_dz_or_gang(4,5,5,count,no_yao_jiu,pai_map,my_pai_map,color,gang)
end
local not_zhongzhang_adjust_cfg={
	{prop=40,type="ddz"},
	{prop=80,type="az"},
	{prop=100,type="dz"},
}
--如果不想胡中章 可以通过本函数略微调整
local function not_zhongzhang_adjust(pai_map,my_pai_map,peng_map,sz_map,jiang_map)
	local zz=true
	for k,v in pairs(my_pai_map) do
		if v>0 and (k%10==1 or k%10==9) then
			zz=false
			break
		end
	end

	if zz then
		local gl=math.random(1,100)
		local adjust_type=nil
		for k,v in ipairs(not_zhongzhang_adjust_cfg) do
			if gl<=v.prop then
				adjust_type=v.type
				break
			end
		end

		local count=0
		local flag=false
		while count<3 do
			--换对子
			if adjust_type=="ddz" then
				for v,k in pairs(my_pai_map) do
					if peng_map and peng_map[v] then
						local c=(math.floor(v/10))*10
						local bx={}
						if pai_map[c+1]>2 and my_pai_map[c+1]+3<4 then
							bx[#bx+1]=c+1
						end
						if pai_map[c+9]>2 and my_pai_map[c+9]+3<4 then
							bx[#bx+1]=c+9
						end
						if #bx>0 then
							local res=bx[math.random(1,#bx)]
							peng_map[res]=1
							peng_map[v]=nil
							my_pai_map[v]=my_pai_map[v]-3
							my_pai_map[res]=my_pai_map[res]+3

							pai_map[res]=pai_map[res]-3
							pai_map[v]=pai_map[v]+3
							flag=true
							print("xxxxxxxxxxxxxzzzhong   ddz",res,v)
							break
						end
					end
				end
			--换顺子
			elseif adjust_type=="sz" then
				for v,k in pairs(my_pai_map) do
					if sz_map and sz_map[v] then
						local c=(math.floor(v/10))*10
						local bx={}

						if pai_map[c+1]>0 and pai_map[c+2]>0 and pai_map[c+3]>0 and my_pai_map[c+1]+1<4 and my_pai_map[c+2]+1<4 and my_pai_map[c+3]+1<4 then
							bx[#bx+1]=c+1
						end
						if pai_map[c+7]>0 and pai_map[c+8]>0 and pai_map[c+9]>0 and my_pai_map[c+7]+1<4 and my_pai_map[c+8]+1<4 and my_pai_map[c+9]+1<4 then
							bx[#bx+1]=c+7
						end
						if #bx>0 then
							local res=bx[math.random(1,#bx)]
							sz_map[res]=1
							sz_map[v]=nil
							my_pai_map[v]=my_pai_map[v]-1
							my_pai_map[v+1]=my_pai_map[v+1]-1
							my_pai_map[v+2]=my_pai_map[v+2]-1

							my_pai_map[res]=my_pai_map[res]+1
							my_pai_map[res+1]=my_pai_map[res+1]+1
							my_pai_map[res+2]=my_pai_map[res+2]+1

							pai_map[v]=pai_map[v]+1
							pai_map[v+1]=pai_map[v+1]+1
							pai_map[v+2]=pai_map[v+2]+1

							pai_map[res]=pai_map[res]-1
							pai_map[res+1]=pai_map[res+1]-1
							pai_map[res+2]=pai_map[res+2]-1
							print("xxxxxxxxxxxxxzzzhong   sz",res,v)
							flag=true
							break
						end
					end	
				end
			--换将
			else
				for v,k in pairs(my_pai_map) do
					if jiang_map and jiang_map[v] then
						local c=(math.floor(v/10))*10
						local bx={}
						if pai_map[c+1]>1 and my_pai_map[c+1]+2<4 then
							bx[#bx+1]=c+1
						end
						if pai_map[c+9]>1 and my_pai_map[c+9]+2<4 then
							bx[#bx+1]=c+9
						end
						if #bx>0 then
							local res=bx[math.random(1,#bx)]
							jiang_map[res]=1
							jiang_map[v]=nil
							my_pai_map[v]=my_pai_map[v]-2
							my_pai_map[res]=my_pai_map[res]+2

							pai_map[res]=pai_map[res]-2
							pai_map[v]=pai_map[v]+2
							flag=true
							print("xxxxxxxxxxxxxzzzhong   dz",res,v)
							break
						end
					end
				end
			end
			if flag then
				break
			end
			count=count+1
		end
	end
end
--普通牌大对子数量配置
local nor_pai_ddz_count_cfg={
	[1]={
		{prop=100,ddz_count=0},
	},
	[2]={
		{prop=100,ddz_count=1},
	},
	[3]={
		{prop=60,ddz_count=1},
		{prop=100,ddz_count=2},
	},
	[4]={
		{prop=40,ddz_count=1},
		{prop=85,ddz_count=2},
		{prop=100,ddz_count=3},
	},
}
local no_qingyise_color_cfg={
	[1]={
		{prop=100,second_count=1},
	},
	[2]={
		{prop=95,second_count=1},
		{prop=100,second_count=2},
	},
	[3]={
		{prop=70,second_count=1},
		{prop=95,second_count=2},
		{prop=100,second_count=3},
	},
	[4]={
		{prop=60,second_count=1},
		{prop=90,second_count=2},
		{prop=95,second_count=3},
		{prop=100,second_count=4},
	},
	[5]={
		{prop=50,second_count=1},
		{prop=90,second_count=2},
		{prop=95,second_count=3},
		{prop=98,second_count=4},
		{prop=100,second_count=5},
	},
	[6]={
		{prop=45,second_count=1},
		{prop=85,second_count=2},
		{prop=90,second_count=3},
		{prop=95,second_count=4},
		{prop=98,second_count=5},
		{prop=100,second_count=6},
	},
	[7]={
		{prop=40,second_count=1},
		{prop=75,second_count=2},
		{prop=90,second_count=3},
		{prop=92,second_count=4},
		{prop=95,second_count=5},
		{prop=98,second_count=6},
		{prop=100,second_count=7},
	},
}
local function create_myPaiMap_by_typeCount(all_count,type_count,hp_data,pai_map)
		local color_data={}
		local no_yao_jiu=hp_data.zhongzhang
		local my_pai_map={}
		for i=11,39 do
			if i%10~=0 then
				my_pai_map[i]=0
			end
		end 

		local pai_map_copy=basefunc.deepcopy(pai_map)

		if hp_data.qiyise then
			color_data[1]=type_count
			color_data[1].color=hp_data.f_color
		else
			local cfg=no_qingyise_color_cfg[all_count]
			local second_count=0
			local gl=math.random(1,100)
			for k,v in ipairs(cfg) do
				if gl<=v.prop then
					second_count=v.second_count
					break
				end
			end
			local list={}
			for k,v in pairs(type_count) do
				if v>0 then
					for i=1,v do
						list[#list+1]=k
					end
				end
			end
			local type_count_2={sz_count=0,gang_count=0,ddz_count=0,dz_count=0}
			for i=1,second_count do
				local r=math.random(1,#list)
				type_count_2[list[r]]=type_count_2[list[r]]+1
				type_count[list[r]]=type_count[list[r]]-1
				list[r]=list[#list]
				list[#list]=nil
			end
			type_count.color=hp_data.f_color
			type_count_2.color=hp_data.s_color
			
			color_data[1]=type_count
			color_data[2]=type_count_2
		end
		local classify={
				sz={},
				ddz={},
				dz={},
				gang={},
			}
		for i=1,2 do 
			if color_data[i] then
				local d=color_data[i]
				local color=d.color
				local s1,fail_count=mj_fahaopai_base_lib.get_shunzi(d.sz_count,no_yao_jiu,pai_map_copy,my_pai_map,color,classify.sz)
				local s2,fail_count=mj_fahaopai_base_lib.get_ddz(d.ddz_count,no_yao_jiu,pai_map_copy,my_pai_map,color,classify.ddz)
				local s3,fail_count=mj_fahaopai_base_lib.get_dz(d.dz_count,no_yao_jiu,pai_map_copy,my_pai_map,color,classify.dz)
				local s4,fail_count=mj_fahaopai_base_lib.get_gang(d.gang_count,no_yao_jiu,pai_map_copy,my_pai_map,color,classify.gang)

				if not s1 or not s2 or not s3 or not s4 then
					dump(d)
					dump(pai_map)
					print("xxx eroror $%$%$%  ",s1,s2,s3,s4)
					return nil
				end
			end
		end


		delete_pai_from_pai_map(classify.sz,pai_map,"sz")
		delete_pai_from_pai_map(classify.ddz,pai_map,"ddz")
		delete_pai_from_pai_map(classify.dz,pai_map,"dz")	
		delete_pai_from_pai_map(classify.gang,pai_map,"gang")		
		
		return my_pai_map,classify
end

function mj_fahaopai_base_lib.create_nor_pai(count,hp_data,pai_map,try_count)
	local count_copy=count
	hp_data.gen_count=hp_data.gen_count or 0

	count_copy=count_copy-hp_data.gen_count

	local type_count={}

	type_count.gang_count=hp_data.gen_count

	local cfg=nor_pai_ddz_count_cfg[count_copy]
	local gl=math.random(1,100)
	if not cfg then
		dump({args={count,hp_data,pai_map,try_count},count_copy=count_copy},"xxxxxxxxx mj_fahaopai_base_lib.create_nor_pai error:")
	end
	for k,v in ipairs(cfg) do
		if gl<=v.prop then
			type_count.ddz_count=v.ddz_count
			break
		end
	end
	

	type_count.sz_count=count_copy-type_count.ddz_count
	type_count.dz_count=1
	--加1是算上将
	local my_pai_map,classify=create_myPaiMap_by_typeCount(count+1,type_count,hp_data,pai_map)

	if not my_pai_map then
		--增加大对子的数量
		try_count=try_count or 0
		try_count=try_count+1
		if try_count<=50 then
			return 	mj_fahaopai_base_lib.create_nor_pai(count,hp_data,pai_map,try_count)
		else
			return nil
		end
	end

	
	if not hp_data.zhongzhang then
		not_zhongzhang_adjust(pai_map,my_pai_map,classify.ddz,classify.sz,classify.dz)
	end
	hp_data.my_pai_map=my_pai_map
	if not hp_data.menqing then
		hp_data.peng_map=classify.ddz
		hp_data.gang_map=classify.gang
	end

	return true  
end

function mj_fahaopai_base_lib.create_ddz_pai(count,hp_data,pai_map,try_count)
	
	local count_copy=count
	hp_data.gen_count=hp_data.gen_count or 0

	count_copy=count_copy-hp_data.gen_count

	local type_count={}

	type_count.gang_count=hp_data.gen_count
	type_count.ddz_count=count_copy
	type_count.sz_count=0
	type_count.dz_count=1

	--加1是算上将
	local my_pai_map,classify=create_myPaiMap_by_typeCount(count+1,type_count,hp_data,pai_map)
	if not my_pai_map then
		try_count=try_count or 0
		try_count=try_count+1
		--多尝试几次
		if try_count<=50 then
			return 	mj_fahaopai_base_lib.create_ddz_pai(count,hp_data,pai_map,try_count)
		else
			return nil
		end
	end

	if not hp_data.zhongzhang then
		not_zhongzhang_adjust(pai_map,my_pai_map,classify.ddz,nil,classify.dz)
	end
	hp_data.my_pai_map=my_pai_map
	if not hp_data.menqing then
		hp_data.peng_map=classify.ddz
		hp_data.gang_map=classify.gang
	end

	return true 
end

function mj_fahaopai_base_lib.create_qidui_pai(count,hp_data,pai_map,try_count)

	local count_copy=count
	hp_data.gen_count=hp_data.gen_count or 0
	count_copy=count_copy-hp_data.gen_count*2

	local type_count={}
	type_count.gang_count=hp_data.gen_count
	type_count.ddz_count=0
	type_count.sz_count=0
	type_count.dz_count=count_copy+1

		--加1是算上将
	local my_pai_map,classify=create_myPaiMap_by_typeCount(type_count.dz_count+type_count.gang_count,type_count,hp_data,pai_map)
	if not my_pai_map then
		try_count=try_count or 0
		try_count=try_count+1
		--多尝试几次
		if try_count<=50 then
			return 	mj_fahaopai_base_lib.create_ddz_pai(count,hp_data,pai_map,try_count)
		else
			return nil
		end
	end

	if not hp_data.zhongzhang then
		not_zhongzhang_adjust(pai_map,my_pai_map,nil,nil,classify.dz)
	end

	hp_data.my_pai_map=my_pai_map

	--返回牌 
	return true 
end

--********************************************************
-- 胡牌番数的概率配置（不包括屁胡）
-- 番数 => 番型的组合数组
local hupai_fanshu_config = 
{
	-- 1 番
	{
		{prob=40, hu_pai_type="ddz"},
		{prob=30, hu_pai_type="nor",zhongzhang=true},
		{prob=20, hu_pai_type="nor",gen_count=1},
		{prob=10, hu_pai_type="nor",menqing=true},
	},

	-- 2 番
	{
		{prob=30, hu_pai_type="nor",qiyise=true},
		{prob=20, hu_pai_type="ddz",zhongzhang=true},
		{prob=15, hu_pai_type="nor",zhongzhang=true,gen_count=1},
		{prob=15, hu_pai_type="ddz",gen_count=1},
		{prob=10, hu_pai_type="qidui"},
		{prob=10, hu_pai_type="nor",gen_count=2},
	},
	-- 3 番 
	{
		{prob=25, hu_pai_type="nor",qiyise=true,zhongzhang=true},
		{prob=25, hu_pai_type="ddz",qiyise=true},
		{prob=20, hu_pai_type="qidui",zhongzhang=true},
		{prob=10, hu_pai_type="qidui",gen_count=1},
		{prob=10, hu_pai_type="nor",qiyise=true,menqing=true},
		{prob=10, hu_pai_type="ddz",zhongzhang=true,gen_count=1},
	},
}

-- 按概率得到牌型
-- 参数 _filter_cb ： 过滤器回调，如果 返回 false 则跳过
local function select_hupai_fanshu_prob(_probs,_filter_cb)

	local _sum = 0

	if not _filter_cb and _probs.sum_prob then
		_sum = _probs.sum_prob
	else
		for _,_d in ipairs(_probs) do
			if not _filter_cb or _filter_cb(_d) then
				_sum = _sum + _d.prob
			end
		end

		if not _filter_cb then
			_probs.sum_prob = _sum
		end
	end

	local _rand = math.random(_sum)

	local _cur_rand = 0
	for _,_d in ipairs(_probs) do
		if not _filter_cb or _filter_cb(_d) then
			_cur_rand = _cur_rand + _d.prob
			if _rand <= _cur_rand then
				return _d
			end
		end
	end

	error("select_hupai_fanshu_prob not found prob!")
end


--[[
解析普通麻将番数  得到要做的牌
（当只有一个人时  不能出现ddz）
参数：
  hp_datas 胡牌数据的数组： 
  {
    hupai_fanshu 胡牌番数
	bushu   步数
  }

填充数据：
    hu_pai_type= 牌型(nor ddz qidui)
    qiyise=true or false ——清一色 最多只有一家做清一色
    zhongzhang 
    menqing
	gen_count --根的数量  最大2个
返回 true/false	
--]]
function mj_fahaopai_base_lib.analysis_nor_fanshu(hp_datas)

  local _ret_datas = {}

  local _filter_cb 

  -- 一个托管，去掉大对子：一个托管 无法 互相之间碰牌！！
  if #hp_datas == 1 then

	_filter_cb = function(_props)
		if _props.hu_pai_type == "ddz" then
			return false
		else
			return true
		end
	end
  end

  local _filter = {prop=true}

  for i,hp_data in ipairs(hp_datas) do


    if hp_data.hupai_fanshu == 0 then
		hp_data.hu_pai_type = "nor"
	else

	  local hpfs_config = mj_fahaopai_base_lib.hupai_fanshu_config or hupai_fanshu_config
		
	  local _probs = hpfs_config[hp_data.hupai_fanshu] or hpfs_config[#hpfs_config]

      local _sel_prob = select_hupai_fanshu_prob(_probs,_filter_cb)
	  basefunc.merge_filter(_sel_prob,hp_data,_filter)
      
    end

  end

  return true
end
--********************************************************

--{
-- 	{
-- 		hupai_fanshu
-- 		bushu
-- 	}
-- 	{

-- 	}
-- }
function mj_fahaopai_base_lib.nor_mj_get_haopai(hp_data,pai_map)
	local status=mj_fahaopai_base_lib.analysis_nor_fanshu(hp_data)
	if status then
		for k,v in ipairs(hp_data) do
			-- print("xxxxxxx*******",k)
			if v.hu_pai_type=="nor" then
				status=mj_fahaopai_base_lib.create_nor_pai(4,v,pai_map)
			elseif v.hu_pai_type=="ddz" then
				status=mj_fahaopai_base_lib.create_ddz_pai(4,v,pai_map)
			elseif v.hu_pai_type=="qidui" then
				status=mj_fahaopai_base_lib.create_qidui_pai(6,v,pai_map)
			end
			if not status then
				dump(pai_map,"pai map")
				dump(hp_data,"create error "..k)
				return nil
			end
		end
		return true
	end

	return nil
end
function mj_fahaopai_base_lib.nor_er_mj_get_haopai(hp_data,pai_map)

	local status=mj_fahaopai_base_lib.analysis_nor_fanshu(hp_data)
	if status then
			for k,v in ipairs(hp_data) do
				if v.hu_pai_type=="nor" then
					status=mj_fahaopai_base_lib.create_nor_pai(2,v,pai_map)
				elseif v.hu_pai_type=="ddz" then
					status=mj_fahaopai_base_lib.create_ddz_pai(2,v,pai_map)
				elseif v.hu_pai_type=="qidui" then
					status=mj_fahaopai_base_lib.create_qidui_pai(3,v,pai_map)
				end
				if not status then
					return nil
				end
			end
			return true
	end

	return nil
end

return mj_fahaopai_base_lib


--[[
	1根据番数确定具体的胡牌类型

--]]











