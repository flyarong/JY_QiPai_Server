-- package.path=package.path..";/Users/hewei/project/JyQipai_server/skynet/game/common/?.lua"
require "printfunc"

local fahaopai_algorithm={}


function fahaopai_algorithm.get_hupai_by_model(list,model_data)
	
	for t,v in pairs(model_data) do
		for pai,num in pairs(v) do
			for i=1,num do
				if t=="ddz" then
					list[#list+1]=pai
					list[#list+1]=pai
					list[#list+1]=pai
				elseif t=="jiang" or t=="lqd" then
					list[#list+1]=pai
					list[#list+1]=pai
				elseif t=="sz" then
					list[#list+1]=pai
					list[#list+1]=pai+1
					list[#list+1]=pai+2
				end
			end
		end
	end

end
function fahaopai_algorithm.change_mode_by_color(data,huase,model_data)
	
	for t,v in pairs(model_data) do
		for pai,num in pairs(v) do
			data[t][huase*10+pai]=num
		end
	end

end

--获得普通的胡牌模板  count 数量  是否要将   not_yi_jiu--不要1和9
function fahaopai_algorithm.get_nor_hupai_model(count,jiang,ddz_gailv,not_yi_jiu)
	local hash={}

	local haopai={ddz={},sz={},jiang={}}

	--产生大对子和顺子  尽量让顺子在前 尽量不要出现顺子和大对子重合
	local ddz_or_sz_list={}
	for i=1,count do
		local ddz_or_sz=math.random(1,100)
		if ddz_or_sz<=ddz_gailv then			
			--大对子
			ddz_or_sz_list[#ddz_or_sz_list+1]=1
		end
	end
	local len=count-#ddz_or_sz_list
	for i=1,len do
		--顺子
		ddz_or_sz_list[#ddz_or_sz_list+1]=2
	end

	
	local ddz_start=1
	local ddz_end=9
	local sz_start=1
	local sz_end=7
	local jiang_start=1
	local jiang_end=9

	if not_yi_jiu then
		ddz_start=2
		ddz_end=8
		sz_start=2
		sz_end=6
		jiang_start=2
		jiang_end=8
	end

	local _pos=1
	while count>0 do
		local ddz_or_sz=ddz_or_sz_list[_pos]
		if ddz_or_sz==1 then
			local pai=math.random(ddz_start,ddz_end)
			while true do
				hash[pai]=hash[pai] or 0
				if hash[pai]+3<=4 then
					haopai.ddz[pai]=1
					hash[pai]=hash[pai]+3
					break
				end
				pai=pai+1
				if pai>ddz_end then
					pai=ddz_start
				end
			end
		else
			local yuxuan_pai=math.random(sz_start,sz_end)
			local ls_count=100
			local pai=0
			for i=yuxuan_pai,sz_end do

				hash[i]=hash[i] or 0
				hash[i+1]=hash[i+1] or 0
				hash[i+2]=hash[i+2] or 0

				if hash[i]+1<=4 and hash[i+1]+1<=4 and hash[i+2]+1<=4 then
					local c=hash[i]+hash[i+1]+hash[i+2]
					if c<ls_count then
						ls_count=c
						pai=i
					end
					if ls_count==0 then
						break
					end
				end

			end
			for i=1,yuxuan_pai-1 do

				hash[i]=hash[i] or 0
				hash[i+1]=hash[i+1] or 0
				hash[i+2]=hash[i+2] or 0

				if hash[i]+1<=4 and hash[i+1]+1<=4 and hash[i+2]+1<=4 then
					local c=hash[i]+hash[i+1]+hash[i+2]
					if c<ls_count then
						ls_count=c
						pai=i
					end
					if ls_count==0 then
						break
					end
				end
				
			end
			hash[pai]=hash[pai] + 1
			hash[pai+1]=hash[pai+1] +1
			hash[pai+2]=hash[pai+2] +1
			haopai.sz[pai]=haopai.sz[pai] or 0
			haopai.sz[pai]=haopai.sz[pai]+1
		end
		count=count-1
		_pos=_pos+1
	end

	if jiang then
		while true do
			local pai=math.random(jiang_start,jiang_end)
			hash[pai]=hash[pai] or 0
			if hash[pai]+2<4 then
				haopai.jiang[pai]=1
				break
			end
		end
	end

	return haopai
end
--is_dq 是否需要定缺 胡牌摸牌次数上下限 hu_time_min hu_time_max  count牌的组数，一组三张
function fahaopai_algorithm.get_qingyise_hupai_data(is_dq,no_color,count,hu_time_min,hu_time_max,ddz_gailv,peng_gailv,gang_gailv)
	local model_data=fahaopai_algorithm.get_nor_hupai_model(count,true,ddz_gailv)
	local huase=math.random(1,3)
	if no_color and huase==no_color then
		huase=huase+1
		if huase>3 then
			huase=1
		end
	end

	local model_data_color={ddz={},sz={},jiang={}}
	fahaopai_algorithm.change_mode_by_color(model_data_color,huase,model_data)

	local hu_pai={}
	fahaopai_algorithm.get_hupai_by_model(hu_pai,model_data_color)
	local hash={}
	for _,v in ipairs(hu_pai) do
		hash[v]=hash[v] or 0
		hash[v]=hash[v] + 1
	end


	local times=math.random(hu_time_min,hu_time_max)
	--选出需要摸的牌
	local mopai={}
	for i=1,times do
		local loc=math.random(1,#hu_pai)
		mopai[#mopai+1]=hu_pai[loc]
		hu_pai[loc]=hu_pai[#hu_pai]
		hu_pai[#hu_pai]=nil
	end

	--选出要打的牌
	local dapai={}

	local dapai_color={}
	for c=1,3 do
		if c~=huase and c~=no_color then
			dapai_color[#dapai_color+1]=c
		end
	end


	times=times-1
	for i=1,times do
		while true do
			local pos=math.random(1,9)
			local pai=dapai_color[math.random(1,#dapai_color)]*10+pos
			hash[pai]=hash[pai] or 0
			if hash[pai]+1<3 then
				dapai[#dapai+1]=pai
				hu_pai[#hu_pai+1]=pai
				hash[pai]=hash[pai]+1
				break
			end
		end
	end
	local dingque
	if is_dq then
		local color={}
		local max_c
		local max_num=0
		for pai,num in ipairs(dapai) do
			local c=math.floor(pai/10)
			color[c]=color[c] or 0
			color[c]=color[c]+num
			if color[c]>max_num then
				max_num=color[c]
				max_c=c
			end
		end
		for i=1,3 do
			if i~=max_c and i~=huase then
				dingque=i
				break
			end
		end
	end
	local data={}
	data.fapai=hu_pai
	data.mopai=mopai
	data.dingque=dingque
	data.model_data=model_data_color
	data.dapai=dapai
	data.peng_gailv=peng_gailv
	data.gang_gailv=gang_gailv
	return data
end
--is_dq 是否需要定缺 胡牌摸牌次数上下限 hu_time_min hu_time_max  count牌的组数，一组三张
function fahaopai_algorithm.get_nor_hupai_data(is_dq,no_color,count,hu_time_min,hu_time_max,ddz_gailv,peng_gailv,gang_gailv)
	local count_1=count
	if count>1 then
		count_1=math.random(1,count-1)
	end
	local count_2=count-count_1

	local model_data=fahaopai_algorithm.get_nor_hupai_model(count_1,true,ddz_gailv,true)
	local huase=math.random(1,3)
	if no_color and huase==no_color then
		huase=huase+1
		if huase>3 then
			huase=1
		end
	end


	local model_data_1=fahaopai_algorithm.get_nor_hupai_model(count_2,false,ddz_gailv,true)
	local huase_1=math.random(1,3)
	for i=1,3 do
		if huase_1~=no_color and huase_1~=huase then
			break
		end
		huase_1=huase_1+1
		if huase_1>3 then
			huase_1=1
		end
	end

	local model_data_color={ddz={},sz={},jiang={}}
	fahaopai_algorithm.change_mode_by_color(model_data_color,huase,model_data)
	fahaopai_algorithm.change_mode_by_color(model_data_color,huase_1,model_data_1)

	local hu_pai={}
	fahaopai_algorithm.get_hupai_by_model(hu_pai,model_data_color)

	local hash={}
	for _,v in ipairs(hu_pai) do
		hash[v]=hash[v] or 0
		hash[v]=hash[v] + 1
	end

	local times=math.random(hu_time_min,hu_time_max)
	--选出需要摸的牌
	local mopai={}
	for i=1,times do
		local loc=math.random(1,#hu_pai)
		mopai[#mopai+1]=hu_pai[loc]
		hu_pai[loc]=hu_pai[#hu_pai]
		hu_pai[#hu_pai]=nil
	end

	--选出要打的牌
	local dapai={}

	local dapai_color={}
	for c=1,3 do
		if c~=huase and c~=no_color  then
			dapai_color[#dapai_color+1]=c
		end
	end


	times=times-1
	for i=1,times do
		while true do
			local pos=math.random(1,9)
			local pai=dapai_color[math.random(1,#dapai_color)]*10+pos
			hash[pai]=hash[pai] or 0
			if hash[pai]+1<3 then
				dapai[#dapai+1]=pai
				hu_pai[#hu_pai+1]=pai
				hash[pai]=hash[pai]+1
				break
			end
		end
	end
	local dingque
	if is_dq then
		for c=1,3 do
			if c~=huase and c~=no_color and  c~=huase_1 then
				dingque=c
			end
		end
	end
	local data={}
	data.fapai=hu_pai
	data.mopai=mopai
	data.dingque=dingque
	data.model_data=model_data_color
	data.dapai=dapai
	data.peng_gailv=peng_gailv
	data.gang_gailv=gang_gailv
	return data
end
function fahaopai_algorithm.get_longqidui_data(is_dq,no_color,count,hu_time_min,hu_time_max,ddz_gailv,peng_gailv,gang_gailv)
	local get_duizi=function (data,num,huase,is_jiang)
		local dz=data.lqd
		local hash={}
		local s=huase*10+1
		local e=huase*10+9
		for i=1,num do
			while true do
				local pai=math.random(s,e)
				hash[pai]=hash[pai] or 0
				if hash[pai]+2<4 and (not dz[pai] or dz[pai]==0) then
					dz[pai]=1
					hash[pai]=hash[pai]+2
					break
				end
			end
		end
		if is_jiang then
			while true do
				local pai=math.random(s,e)
				hash[pai]=hash[pai] or 0
				if hash[pai]+2<4  then
					data.jiang[pai]=1
					break
				end
			end
		end
		return dz
	end
	local count_1=count
	count_1=math.random(1,count)
	
	local count_2=count-count_1

	local model_data_color={lqd={},jiang={}}

	local huase=math.random(1,3)
	if no_color and huase==no_color then
		huase=huase+1
		if huase>3 then
			huase=1
		end
	end
	get_duizi(model_data_color,count_1,huase,true)

	local huase_1=math.random(1,3)
	for i=1,3 do
		if huase_1~=no_color and huase_1~=huase then
			break
		end
		huase_1=huase_1+1
		if huase_1>3 then
			huase_1=1
		end
	end
	get_duizi(model_data_color,count_2,huase_1)

	

	local hu_pai={}
	fahaopai_algorithm.get_hupai_by_model(hu_pai,model_data_color)

	local hash={}
	for _,v in ipairs(hu_pai) do
		hash[v]=hash[v] or 0
		hash[v]=hash[v] + 1
	end


	local times=math.random(hu_time_min,hu_time_max)
	--选出需要摸的牌
	local mopai={}
	for i=1,times do
		local loc=math.random(1,#hu_pai)
		mopai[#mopai+1]=hu_pai[loc]
		hu_pai[loc]=hu_pai[#hu_pai]
		hu_pai[#hu_pai]=nil
	end

	--选出要打的牌
	local dapai={}

	local dapai_color={}
	for c=1,3 do
		if c~=huase and c~=no_color  then
			dapai_color[#dapai_color+1]=c
		end
	end


	times=times-1
	for i=1,times do
		while true do
			local pos=math.random(1,9)
			local pai=dapai_color[math.random(1,#dapai_color)]*10+pos
			hash[pai]=hash[pai] or 0
			if hash[pai]+1<3 then
				dapai[#dapai+1]=pai
				hu_pai[#hu_pai+1]=pai
				hash[pai]=hash[pai]+1
				break
			end
		end
	end
	local dingque
	if is_dq then
		for c=1,3 do
			if c~=huase and c~=no_color and  c~=huase_1 then
				dingque=c
			end
		end
	end
	local data={}
	data.fapai=hu_pai
	data.mopai=mopai
	data.dingque=dingque
	data.model_data=model_data_color
	data.dapai=dapai
	data.peng_gailv=peng_gailv
	data.gang_gailv=gang_gailv
	return data
end










function fahaopai_algorithm.nor_ddz_get_haopai(hu_time_min,hu_time_max,ddz_gailv,peng_gailv,gang_gailv,qys_gl,lqd_gl)
	local qys_gl=qys_gl or 60
	local lqd_gl=lqd_gl or 20

	if math.random(1,100)<qys_gl then
		-- print("qys")
		return fahaopai_algorithm.get_qingyise_hupai_data(true,nil,4,hu_time_min,hu_time_max,ddz_gailv,peng_gailv,gang_gailv)
	elseif math.random(1,100)<lqd_gl then
		-- print("lqd")
		return fahaopai_algorithm.get_longqidui_data(true,nil,6,hu_time_min,hu_time_max,0,0,0)
	else
		return fahaopai_algorithm.get_nor_hupai_data(true,nil,4,hu_time_min,hu_time_max,ddz_gailv,peng_gailv,gang_gailv)
	end 
end
function fahaopai_algorithm.er_ddz_get_haopai(no_color,hu_time_min,hu_time_max,ddz_gailv,peng_gailv,gang_gailv,qys_gl,lqd_gl)
	local lqd_gl=lqd_gl or 40
	local qys_gl=qys_gl or 95

	if math.random(1,100)<lqd_gl then
		return fahaopai_algorithm.get_longqidui_data(nil,no_color,3,hu_time_min,hu_time_max,0,0,0)
	elseif math.random(1,100)<qys_gl then
		return fahaopai_algorithm.get_qingyise_hupai_data(nil,no_color,2,hu_time_min,hu_time_max,ddz_gailv,peng_gailv,gang_gailv)
	else
		return fahaopai_algorithm.get_nor_hupai_data(nil,no_color,2,hu_time_min,hu_time_max,ddz_gailv,peng_gailv,gang_gailv)
	end 
end





-- math.randomseed(os.time()*72453) 
-- for i=1,200000 do
	-- fahaopai_algorithm.nor_ddz_get_haopai(5,9,35,20,20)
	-- fahaopai_algorithm.er_ddz_get_haopai(1,2,5,35,20,20)
-- end
-- dump(fahaopai_algorithm.nor_ddz_get_haopai(5,9,35,20,20))
-- dump(fahaopai_algorithm.er_ddz_get_haopai(1,2,5,35,20,20))
-- math.randomseed(os.time()*72453) 
-- for i=1,2000000 do
-- 	if i%100000==0 then
-- 		print(i)
-- 	end
-- 	-- local data=fahaopai_algorithm.nor_ddz_get_haopai(4,7,40,60,40,60,20)
-- 	local data=fahaopai_algorithm.er_ddz_get_haopai(3,2,4,40,60,40,95,40)
-- 	if #data.fapai~=7 then  
-- 		print("error!!")
-- 		dump(data)
-- 		break
-- 	end
-- end
	-- er_mj_hp_hu_time_min=2,
	-- er_mj_hp_hu_time_max=4,
	-- er_mj_hp_ddz_gailv=40,
	-- er_mj_hp_peng_gailv=60,
	-- er_mj_hp_gang_gailv=40,
	-- nor_mj_hp_hu_time_min=4,
	-- nor_mj_hp_hu_time_max=7,
	-- nor_mj_hp_ddz_gailv=40,
	-- nor_mj_hp_peng_gailv=60,
	-- nor_mj_hp_gang_gailv=40,

	-- er_mj_hp_qys_gailv=95,
	-- er_mj_hp_lqd_gailv=40,
	-- nor_mj_hp_qys_gailv=60,
	-- nor_mj_hp_lqd_gailv=20,


	-- er_mj_hp_hu_time_min=2,
	-- er_mj_hp_hu_time_max=4,
	-- er_mj_hp_ddz_gailv=90,
	-- er_mj_hp_peng_gailv=30,
	-- er_mj_hp_gang_gailv=30,
	-- nor_mj_hp_hu_time_min=4,
	-- nor_mj_hp_hu_time_max=7,
	-- nor_mj_hp_ddz_gailv=90,
	-- nor_mj_hp_peng_gailv=30,
	-- nor_mj_hp_gang_gailv=40,

	-- er_mj_hp_qys_gailv=30,
	-- er_mj_hp_lqd_gailv=40,
	-- nor_mj_hp_qys_gailv=10,
	-- nor_mj_hp_lqd_gailv=20,

return fahaopai_algorithm












