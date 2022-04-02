local basefunc = require "basefunc"
local printfunc = require "printfunc"
local nor_ddz_ai_base_lib=require "ddz_tuoguan.nor_ddz_ai_base_lib"
local ddz_tg_assist_lib = require "ddz_tuoguan.ddz_tg_assist_lib"
local landai_util=require "ddz_tuoguan.landai_util"
local LysCards=require "ddz_tuoguan.lys_cards"
local tgland_core = require "tgland.core"
local skynet = require "skynet_plus"

local  this={}


local all_card_type={1,2,3,4,5,6,7,8,9,10,11,12,13,14}
local function max_face(l,r) 
	if not l then 
		return r 
	end

	if not r then 
		return l 
	end

	if l< r then 
		return r 
	end
	return l 
end

local function face_is_bigger(l,r)
	if not l then 
		return false 
	end

	if not r then 
		return true 
	end

	return l>r 

end
	


--[[
	true or false
	1:敌方一手出
	2：敌方上手 必赢  出了牌后 省AB B A 且我没炸弹  


--]]
function this.check_enemy_is_win(cp_data,data)

	local my_seat_id = data.base_info.my_seat 
	local is_dz=data.base_info.seat_type[my_seat_id]

	local nm_seat_id={}
	local dz_seat_id=0 


	-- 获取地主农民的位置id 
	for k,v in ipairs(data.base_info.seat_type) do 
		if v == 0 then 
			table.insert(nm_seat_id,k) 
		else 
			dz_seat_id=k
		end
	end

	-- 如果是地主 
	if is_dz then 
		for k,v in ipairs(nm_seat_id) do 
			if this.check_seat_is_win(cp_data,v,data) then 
				return true 
			end
		end
	else 
		if this.check_seat_is_win(dz_seat_id) then 
			return true
		end
	end
	return false

end

function this.check_seat_is_win(cp_data,seat_id,data)
	local pai_nu=0


	local seat_pai=data.pai_map[seat_id] 
	for k,v in ipairs(seat_pai) do 
		pai_nu= pai_nu+#v
	end


	if pai_nu >=4 then 
		return false 
	end

	--检测是否有牌可以出
	local cp_type=cp_data.type 


	--没有牌可以出
	if not seat_pai[cp_type]  or #seat_pai[cp_type] == 0  then 
		return false
	end

	local seat_cp_type_nu=#seat_pai[cp_type]
	


	local seat_pai_info={}
	local not_zhanshou_nu=0


	local has_bigger=false 
	local bigger_is_zhanshou=false
	local bigger_nu=0


	for k,v in ipairs(seat_pai) do 
		seat_pai_info[k]={}

		for dk,dv in ipairs(v) do 
			--TODO(check is zhanshou)
			local is_zhanshou=query(pai_type,pai_data)
			local bigger_cp=false 

			if this.pai_bigger({type=k, data=dv},cp_data) then 
				bigger_cp=true
				has_bigger=true 
				bigger_nu=bigger_nu+1
				if has_bigger and not bigger_is_zhanshou then 
					if is_zhanshou then 
						bigger_is_zhanshou = true 
					end
				end
			end

			if not is_zhanshou then 
				not_zhanshou_nu=not_zhanshou_nu+1
			end


			table.insert(seat_pai_info[k],{
				is_zhanshou=is_zhanshou,
				type=k,
				data=dv,
				bigger_cp=true,
			})
		end
	end

	if not has_bigger then 
		return false 
	end


	if not bigger_is_zhanshou  then 
		return false 
	end

	-- 类似于 W  Q 3 ，只有W为大牌
	if not_zhanshou_nu==2 then 
		if bigger_nu >= 2 then 
			return true
		end
		return  false 
	end


	if not_zhanshou_nu >1 then 
		return false 
	end

	return true 

end


function this.pai_bigger(left,right)

	if left.type ~= right.type then 

		if left.type == 14 then 
			return true 
		end

		if right.type == 14 then 
			return false 
		end

		if left.type == 13 then 
			return true
		end

		return false 
	end

	local ptype= left.type 
	

	if ptype == 1 or ptype == 2  or ptype == 3 or ptype ==13 then 
		return  left.data > right.data 
	end

	if ptype == 4 or ptype == 5 or ptype == 8 or ptype == 9   then 
		return left.data[1] >right.data[1] 
	end


	if ptype == 6 or ptype == 7 or ptype == 10 or ptype == 11 or ptype == 12 then 
		local left_serial_nu= left.data[2]-left.data[1]+1
		local right_serial_nu = right.data[2]-right.data[1]+1 
		if left_serial_nu~=right_serial_nu then 
			return false 
		end

		return left.data[2] > right.data[2] 
	end
end



--[[
	给所有人分牌
	data={
		
		fen_pai={}
		query_map={}
	}
--]]
function this.fenpai_for_all(data)
	if skynet.getcfg("ddz_tuoguan_imp_c") then 
		return this.fenpai_for_all_imp_c(data)
	else 
		return this.fenpai_for_all_imp_lua(data)
	end
end


function this.c_fenpai_result_cast(pai)
	local new_pai={}
	for pk,pv in pairs(pai) do 
		if pk=="pai" then 
			for pai_type,pai_data in pairs(pv) do 
				if pai_type == 14 then 
					if #pai_data > 0 then 
						new_pai[14]=true
					end
				else 
					local new_pai_data={}
					for kkkkx,kkkkv in pairs(pai_data) do 
						local sing_pai={}
						for wwwx,wwwv in ipairs(kkkkv.pai) do 
							if wwwv == 0 then 
								break
							end
							table.insert(sing_pai,wwwv)
						end
						table.insert(new_pai_data,sing_pai)
					end
					new_pai[pai_type]=new_pai_data
				end
			end
		else 
			new_pai[pk]=pv
		end
	end
	return new_pai

end


function this.c_all_fenpai_result_cast(pai)
	local result={}
	for k,v in ipairs(pai) do 
		result[k]=this.c_fenpai_result_cast(v)
	end
	return result
end





function this.fenpai_for_all_imp_c(data)
	local cfenpai_result=tgland_core.fenpai_for_all(
			data.pai_map,
			data.limit_cfg.sz_min_len,
			data.limit_cfg.sz_max_len,
			data.kaiguan,
			data.base_info.my_seat,
			data.base_info.dz_seat,
			data.base_info.seat_count)

	data.fen_pai=this.c_all_fenpai_result_cast(cfenpai_result.fen_pai)
	for k,v in ipairs(data.fen_pai) do 
		this.sort_fenpai_type(v)
	end

	data.xjbest_fenpai=this.c_all_fenpai_result_cast(cfenpai_result.xjbest_fenpai)
	data.query_map=cfenpai_result.query_map

end

function this.fenpai_for_all_imp_lua(data)
	data.query_map=data.query_map or ddz_tg_assist_lib.generate_exist_map(data)
	data.fen_pai={}
	data.xjbest_fenpai={}
	for i=1,data.base_info.seat_count do

		local power_cfg=ddz_tg_assist_lib.get_power_cfg(1,data.query_map)
		power_cfg.my_seat=i
		local fen_pai=nor_ddz_ai_base_lib.nor_ddz_analyse_pai(basefunc.deepcopy(data.pai_map[i]),data.kaiguan,data.limit_cfg,power_cfg)
		this.sort_fenpai_type(fen_pai)
		data.fen_pai[i]=fen_pai

		--按下叫最优分牌
		fen_pai=nor_ddz_ai_base_lib.nor_ddz_analyse_pai_by_xjBest(basefunc.deepcopy(data.pai_map[i]),data.kaiguan,data.limit_cfg,power_cfg)
		this.sort_fenpai_type(fen_pai)
		data.xjbest_fenpai[i]=fen_pai

	end
	 --dump(data.fen_pai)
	-- dump(data.xjbest_fenpai)

end


function this.fenpai_for_one(data,seat)
	if skynet.getcfg("ddz_tuoguan_imp_c") then 
		return this.fenpai_for_one_imp_c(data,seat)
	else 
		return this.fenpai_for_one_imp_lua(data,seat)
	end

end


function this.fenpai_for_one_imp_c(data,seat)
	local cfenpai_result=tgland_core.fenpai_for_one(
			data.pai_map,
			data.limit_cfg.sz_min_len,
			data.limit_cfg.sz_max_len,
			data.kaiguan,
			data.base_info.my_seat,
			data.base_info.dz_seat,
			data.base_info.seat_count)

	local fen_pai=this.c_fenpai_result_cast(cfenpai_result.fen_pai[seat])
	return fen_pai

end



function this.fenpai_for_one_imp_lua(data,seat)
	data.query_map=data.query_map or ddz_tg_assist_lib.generate_exist_map(data)
	local power_cfg=ddz_tg_assist_lib.get_power_cfg(seat,data.query_map)
	local fen_pai=nor_ddz_ai_base_lib.nor_ddz_analyse_pai(basefunc.deepcopy(data.pai_map[seat]),data.kaiguan,data.limit_cfg,power_cfg)
	this.sort_fenpai_type(fen_pai)
	return fen_pai
end	




function this.sort_fenpai_type(fen_pai)
	for k,v in pairs(fen_pai) do  

		if k~=14 and type(k) == "number" then 
			table.sort(v,function(l,r)
				return ddz_tg_assist_lib.get_key_pai(k,l) > ddz_tg_assist_lib.get_key_pai(k,r)
			end)
		end
	end
end










------------

local  function daipai_cmp_less(l,r)
	return l[1]<r[1]
end


function this.check_my_will_win(data,pai_info) 

	local pai_score= ddz_tg_assist_lib.take_paidata_by_hash(data.boyi_map,pai_info)
	if not pai_score then 
		return false
	end

	if pai_score > 0 then 
		return true
	end

	return false 

end

function this.check_op_will_win(data,pai_info) 
	local pai_score= ddz_tg_assist_lib.take_paidata_by_hash(data.boyi_map,pai_info)

	if not pai_score then 
		return false
	end
	if pai_score < 0 then 
		return true
	end
	return false 
end


function this.check_chupai_not_faild(data,pai_info)
	local pai_score=ddz_tg_assist_lib.take_paidata_by_hash(data.boyi_map,pai_info) 
	if not pai_score then 
		return true 
	end

	if data.boyi_max_score > 0 then 
		if pai_score > 0 then 
			return true 
		end
	end



	if pai_score == data.boyi_max_score then 
		return true
	end



	if data.boyi_max_score == 0 then 
		if data.boyi_min_score ==-1 then  
			--return true
		elseif pai_score > data.boyi_min_score then 
			return true 
		end
	end


	return false 



end


function this.check_chupai_ok(data,pai_info) 
	local my_seat=data.base_info.my_seat 
	local dz_seat=data.base_info.dz_seat

	if data.kaiguan[pai_info.type] ~= 1 and pai_info.type ~= 0 then 
		if pai_info.type ~=3  then 
			return false 
		else 
			local my_seat =data.base_info.my_seat
			if data.pai_re_count [my_seat ] ~= 3  then 
				return false 
			else 
				return true
			end
		end
	end


	local pai_score=ddz_tg_assist_lib.take_paidata_by_hash(data.boyi_map,pai_info) 

	if not pai_score then 
		return true
	end

	if pai_score == data.boyi_max_score then 
		return true
	end

	--修复：某些情况下，其它小伙伴里面有炸弹，导致放弃分数为更高,炸弹一直出不去
	if pai_info.type == 13 or pai_info.type == 14 then 
		if pai_score > 0 then 
			return true
		end
	end


	--处理某些情况三带判断不准的情况
	if my_seat == dz_seat  and (pai_info.type == 5 or pai_info.type ==4 ) then 
		for k,v in ipairs(data.boyi_list) do 
			if v.type == pai_info.type and v.pai[1]==pai_info.pai[1] then 
				if v.pai[2]> pai_info.pai[2] then 
					if v.score== data.boyi_max_score then 
						return true
					end
				end
			end
		end
	end


	local pai_count = ddz_tg_assist_lib.get_pai_count(pai_info.type,pai_info.pai)

	if data.boyi_max_score == 0  and (pai_count > 4 ) then 
		if data.boyi_min_score ==-1 then  
			--return true
		elseif pai_score > data.boyi_min_score then 
			return true 
		end
	end


	return false 
end


function this.get_pai_type_serial(pai_type,pai_data)
	if pai_type == 6 or pai_type == 7 
		or pai_type == 10 or pai_type ==11 or pai_type==12 then 
		return pai_data[2]-pai_data[1] +1
	end
	return 1 
end


function this.get_all_possible_shunzi(data,my_pai_map,last_pai_data,equal)

	local last_pai_type=last_pai_data.type 
	local last_pai_serial=this.get_pai_type_serial(last_pai_type,last_pai_data.pai)
	local last_key=ddz_tg_assist_lib.get_key_pai(last_pai_data.type,last_pai_data.pai)

	local pai_map={}

	local ret ={}



	if my_pai_map[last_pai_type] and #my_pai_map[last_pai_type] > 0 then 

		--收集所有的牌
		for k,v in ipairs(my_pai_map[last_pai_type])  do 
			ddz_tg_assist_lib.change_pai_map_data(pai_map,last_pai_type,v,true)
		end

		local lys_cards=LysCards.new() 
		lys_cards:set_fcards2(pai_map)
		local start_key=last_key+1 
		if equal then 
			start_key=last_key
		end

		for i= start_key,14,1 do 
			if lys_cards:get_typeFaceNu(last_pai_type,last_pai_serial,i) > 0 then 
				local n_cards=lys_cards:copy()
				n_cards:remove_typeFace(last_pai_type,last_pai_serial,i)
				local split_map=n_cards:to_paimap()
				local fen_pai=nor_ddz_ai_base_lib.nor_ddz_analyse_pai(split_map)
				local score,shoushu,bomb_count= nor_ddz_ai_base_lib.default_get_fenpai_score(fen_pai)
				fen_pai.shoushu=shoushu
				fen_pai.score=score


				table.insert(ret,{
					pai={type=last_pai_type,pai={i-last_pai_serial+1,i}},
					left_fen_pai=fen_pai
				})

			end
		end
	end
	--dump(ret)

	table.sort(ret,function(l,r)
		if l.left_fen_pai.shoushu == r.left_fen_pai.shoushu then 
			return l.left_fen_pai.score > r.left_fen_pai.score 
		end
		return l.left_fen_pai.shoushu < r.left_fen_pai.shoushu 
	end)
	return ret 

end



function this.get_danpai_list(data,seat_id,break_pair,break_serial,zhanshou_dan,zhanshou_dui,force_serial,ignore)
	local pai_map=data.fen_pai[seat_id] 
	local ret ={}

	local ignore_pai=ignore or {}



	--单牌
	if pai_map[1]  then  
		for k,v in ipairs(pai_map[1]) do  
			if not ignore_pai[v[1]] then 
				local pai_score=ddz_tg_assist_lib.get_pai_score(data.query_map,seat_id,1,v) 
				if pai_score <7 or v[1] < 13 then 
					table.insert( ret,v)
				end

			end
		end
	end


	--三带1 
	if pai_map[4]   then  
		for k,v in ipairs(pai_map[4]) do 
			if not ignore_pai[v[2]] then 

				table.insert(ret,{v[2]})
			end
		end
	end


	--四带2 
	if pai_map[8] then 
		for k,v in ipairs(pai_map[8]) do 
			if not ignore_pai[v[2]] then 
				table.insert(ret,{v[2]})
			end

			if not ignore_pai[v[3]] then 
				table.insert(ret,{v[3]})
			end
		end
	end


	--飞机带单
	if pai_map[10] then 
		for k,v in ipairs(pai_map[10]) do 
			for k1,v1 in ipairs(v) do 
				if k1>2 then 
					if not ignore_pai[v1] then 
						table.insert(ret,{v1})
					end
				end
			end
		end
	end


	if #ret == 0 then 
		if pai_map[6] and break_serial then 
			for k,v in ipairs(pai_map[6]) do 
				if v[2]-v[1]>=5 then 
					if not ignore_pai[v[1]] then
						table.insert(ret,{v[1]})
					end
				end
			end
		end
	end




	-- 拿非占手对
	if #ret == 0 then 
		if pai_map[2] and break_pair then  
			for k,v in ipairs(pai_map[2]) do  
				if not ignore_pai[v[1]] then 
					local pai_score=ddz_tg_assist_lib.get_pai_score(data.query_map,seat_id,2,v) 
					if pai_score <7 then 

						table.insert( ret,v)
					end
				end
			end
		end
	end

	--拿占手单
	if #ret==0 and zhanshou_dan then 
		for k,v in ipairs(pai_map[1]) do  
			if not ignore_pai[v[1]] then 
				local pai_score=ddz_tg_assist_lib.get_pai_score(data.query_map,seat_id,1,v) 
				if pai_score >= 7 then 
					table.insert( ret,v)
				end

			end
		end
	end

	-- 拿占手对
	if #ret == 0 and zhanshou_dui then 
		if pai_map[2] and break_pair then  
			for k,v in ipairs(pai_map[2]) do  
				if not ignore_pai[v[1]] then 
					local pai_score=ddz_tg_assist_lib.get_pai_score(data.query_map,seat_id,2,v) 
					if pai_score >= 7 and v[1] >= 13 then 
						table.insert( ret,v)
					end
				end
			end
		end
	end


	if #ret == 0 and force_serial then 
		if pai_map[6]  then 
			for k,v in ipairs(pai_map[6]) do 
				if v[2]-v[1]>=5 then 
					if not ignore_pai[v[1]] then
						table.insert(ret,{v[1]})
					end
				end
			end
		end
	end



	table.sort(ret,daipai_cmp_less)
	return ret
end



function this.get_bomb_list(data,seat_id) 
	local pai_map=data.fen_pai[seat_id] 
	local ret ={}

	if pai_map[8] then 
		for k,v in ipairs(pai_map[8]) do 
			table.insert(ret,{v[1]})
		end
	end

	if pai_map[9] then 
		for k,v in ipairs(pai_map[9]) do 
			table.insert(ret,{v[1]})
		end
	end

	if pai_map[13] then 
		for k,v in ipairs(pai_map[13]) do 
			table.insert(ret,{v[1]})
		end
	end
	return ret


end

function this.get_duizi_list(data,seat_id, break_liandui, zhanshou_dui ,ignore) 

	local pai_map=data.fen_pai[seat_id] 

	local ret ={}

	local ignore_pai=ignore or {}

	--非占手对
	if pai_map[2]  then  
		for k,v in ipairs(pai_map[2]) do  
			if not ignore_pai[v[1]] then 

				local pai_score=ddz_tg_assist_lib.get_pai_score(data.query_map,seat_id,2,v) 
				if pai_score <7 or  v[1] < 13 then 

					table.insert( ret,v)
				end
			end
		end
	end


	--三带二
	if pai_map[5]   then  
		for k,v in ipairs(pai_map[5]) do 
			if not ignore_pai[v[2]] then 
				table.insert(ret,{v[2]})
			end
		end
	end


	--四带2对
	if pai_map[9] then 
		for k,v in ipairs(pai_map[9]) do 
			if not ignore_pai[v[2]] then 
				table.insert(ret,{v[2]})
			end

			if not ignore_pai[v[3]] then 
				table.insert(ret,{v[3]})
			end
		end

	end

	--飞机带对
	if pai_map[11] then 
		for k,v in ipairs(pai_map[11]) do 
			for k1,v1 in ipairs(v) do 
				if k1>2 then 
					if not ignore_pai[v1] then 
						table.insert(ret,{v1})
					end
				end
			end
		end
	end

	--连对
	if #ret==0 and pai_map[7] and break_liandui then 
		for k,v in ipairs(pai_map[7]) do 
			if not ignore_pai[v[2]] then 
				table.insert(ret,{v[2]})
			end
		end
	end


	--占手对
	if #ret==0 and zhanshou_dui   then  
		for k,v in ipairs(pai_map[2]) do  
			if not ignore_pai[v[1]] then 
				local pai_score=ddz_tg_assist_lib.get_pai_score(data.query_map,seat_id,2,v) 
				if pai_score >=7 and v[1]>=13 then 
					table.insert( ret,v)
				end
			end
		end
	end


	table.sort(ret,daipai_cmp_less)
	return ret
end

function this.sandai1_use_smaller_daipai(data,seat_id,o_pai)
	local pai_map=data.fen_pai[seat_id]

	local dai_pai=this.get_danpai_list(data,seat_id,false,true,false,false,false,{
		[o_pai[1]]=true
	})

	local pai=basefunc.deepcopy(o_pai)
	if #dai_pai==0 then 
		return pai
	end
	pai[2]= dai_pai[1][1]
	return pai 
end

function this.sandai2_use_smaller_daipai(data,seat_id,o_pai) 
	local pai_map=data.fen_pai[seat_id]

	local dai_pai=this.get_duizi_list(data,seat_id,false,false,{
		[o_pai[1]]=true
	}) 

	local pai=basefunc.deepcopy(o_pai)

	if #dai_pai==0 then 
		return pai
	end

	pai[2]=dai_pai[1][1] 
	return pai 
end


function this.bomb_dai_dan_use_smaller_daipai(data,seat_id,o_pai)
	local pai_map=data.fen_pai[seat_id]


	local dai_pai=this.get_danpai_list(data,seat_id,false,true,false,false,false,{
		[o_pai[1]]=true
	})

	local pai=basefunc.deepcopy(o_pai)

	if #dai_pai<2 then 
		return pai
	end


	pai[2]=dai_pai[1][1] 
	pai[3]=dai_pai[2][1] 

	return pai 

end

function this.bomb_dai_dui_use_smaller_daipai(data,seat_id,o_pai)
	local pai_map=data.fen_pai[seat_id]

	local dai_pai=this.get_duizi_list(data,seat_id,false,false,{
		[o_pai[1]]=true
	}) 

	local pai=basefunc.deepcopy(o_pai)

	if #dai_pai<2 then 
		return pai
	end

	pai[2]=dai_pai[1][1] 
	pai[3]=dai_pai[2][1] 

	return pai 
end

function this.feiji_1_use_smaller_daipai(data,seat_id ,o_pai)
	local pai_map=data.fen_pai[seat_id]

	local ignore={}
	for i= o_pai[1],o_pai[2] do 
		ignore[i]=true
	end

	local dai_pai=this.get_danpai_list(data,seat_id,false,true,false,false,false,ignore)

	local pai=basefunc.deepcopy(o_pai)

	local serial_nu=pai[2]-pai[1]+1 

	if #dai_pai<serial_nu then 
		return pai 
	end

	for i = 1,serial_nu   do 
		pai[2+i]=dai_pai[i][1]
	end


	return pai
end


function this.feiji_2_use_smaller_daipai(data, seat_id ,o_pai)

	local pai_map=data.fen_pai[seat_id]
	local ignore={}
	for i= o_pai[1],o_pai[2] do 
		ignore[i]=true
	end


	local dai_pai=this.get_duizi_list(data,seat_id,false,false,ignore)
	local pai=basefunc.deepcopy(o_pai)

	local serial_nu=pai[2]-pai[1]+1 

	if #dai_pai<serial_nu then 
		return pai 
	end

	for i = 1,serial_nu   do 
		pai[2+i]=dai_pai[i][1]
	end
	return pai
end

function this.youhua_daipai(data,seat_id,pai,you_dandui,_dandui_key)

	local last_pai =data.last_pai 


	local dandui_key =_dandui_key or 0

	local result=basefunc.deepcopy(pai)

	if result.no_youha then 
		return result
	end


	if result.type == 4 then 
		result.pai=this.sandai1_use_smaller_daipai(data,seat_id,result.pai)
	elseif result.type ==5 then 
		result.pai=this.sandai2_use_smaller_daipai(data,seat_id,result.pai)
	elseif result.type ==8 then 
		result.pai=this.bomb_dai_dan_use_smaller_daipai(data,seat_id,result.pai)
	elseif result.type == 9 then 
		result.pai=this.bomb_dai_dui_use_smaller_daipai(data,seat_id,result.pai)
	elseif result.type == 10 then 
		result.pai=this.feiji_1_use_smaller_daipai(data,seat_id,result.pai)
	elseif result.type == 11 then 
		result.pai=this.feiji_2_use_smaller_daipai(data,seat_id,result.pai)

	elseif result.type == 13 then 

		local bomb_list = this.get_bomb_list(data,data.base_info.my_seat) 
		if #bomb_list>=1 then 
			if last_pai.type ~= 13 then 
				result.pai=bomb_list[#bomb_list]
			else 
				for k,v in ipairs(bomb_list) do 
					if v[1]> last_pai.pai[1] and v[1] < result.pai[1]  then 
						result.pai=v
						break
					end
				end
			end
		end

	elseif result.type ==1 and you_dandui then 

		local danpai_list= this.get_danpai_list(data,data.base_info.my_seat,false,false,false,false,false,nil)
		for k,v in ipairs(danpai_list) do 

			local now_pai={
				type= 1,
				pai=v,
			}

			if v[1] < result.pai[1] and v[1] > dandui_key then 
				if this.check_chupai_ok(data,now_pai) then 
					result.pai=v
					break
				end
			end
		end


	elseif result.type ==2 and youhua_daipai then 
		local dui_list=this.get_duizi_list(data,data.base_info.my_seat,false,false,nil)
		for k,v in ipairs(dui_list) do 
			local now_pai={
				type= 1,
				pai=v
			}
			if v[1] < result.pai[1] and v[1] >dandui_key then 
				if this.check_chupai_ok(data,now_pai) then 
					result.pai=v
					break
				end
			end
		end
	end

	return result 
end




-- by lyx: 查找 不大于 伙伴 指定牌的 最小牌。
--		  注意： 需保证 牌 从大到小排序
function this.search_min_less_pai(_type,_my_pai,_partner_pai,_max_key_pai)


	local _m = _my_pai[#_my_pai]
	local _key_pai = ddz_tg_assist_lib.get_key_pai(_type,_m)

	if _max_key_pai and _max_key_pai<=_key_pai then
		return nil
	end

	-- 从最小的开始找
	for i1=#_partner_pai,1,-1 do

		local _p = _partner_pai[i1]

		if  ddz_tg_assist_lib.get_key_pai(_type,_p) > _key_pai then
			return _m
		end
	end

	return nil
end

-- by lyx: 查找 不大于指定牌的 最小牌。 顺子、连对、飞机（飞机不考虑带牌）
--		  注意： 需保证 牌 从大到小排序
function this.search_min_less_pai_szldfj(_type,_my_pai,_other_pai,_max_key_pai)

	_max_key_pai = _max_key_pai or 100

	-- 从最小的开始找
	for i1=#_other_pai,1,-1 do
		for i2=#_my_pai,1,-1 do
			local _p = _other_pai[i1]
			local _m = _my_pai[i2]
			if _p[2] - _p[1] == _m[2] - _m[1] then
				local _key_pai = ddz_tg_assist_lib.get_key_pai(_type,_m)
				if _key_pai < _max_key_pai and ddz_tg_assist_lib.get_key_pai(_type,_p) > _key_pai then
					return _m
				else
					break 	-- 退出（后面的 _key_pai 会更大）
				end
			end
		end
	end

	return nil
end

function this.sandai_to_sandai_dan(data,seat_id,pai,force)

	local dai_pai 

	if force then 
		dai_pai=this.get_danpai_list(data,seat_id,true,true,true,true,true,{[pai[1]]=true})
	else 
		dai_pai=this.get_danpai_list(data,seat_id,true,true,false,false,false,{[pai[1]]=true})
	end


	if #dai_pai== 0 then 

		return nil
	end

	return {pai[1],dai_pai[1][1]}
end


function this.sandai_to_sandai_dui(data,seat_id,pai,force )

	local dui_pai 
	if force then 
		dui_pai=this.get_duizi_list(data,seat_id,true,false,{[pai[1]]=true}) 
	else 
		dui_pai=this.get_duizi_list(data,seat_id,true,true,{[pai[1]]=true}) 
	end
	if #dui_pai==0 then 
		return nil 
	end
	return {pai[1],dui_pai[1][1]}


end


function this.feiji_to_feiji_dan(data,seat_id,pai,force )
	local serial_nu=pai[2]-pai[1]+1

	local dai_pai
	local ignore ={}
	for i=pai[1],pai[2]  do 
		ignore[i]=true
	end



	if force then 
		dai_pai=this.get_danpai_list(data,seat_id,true,true,true,true,true,ignore)
	else 
		dai_pai=this.get_danpai_list(data,seat_id,true,true,false,false,false,ignore)
	end


	if #dai_pai < serial_nu then 
		return nil
	end


	local pai={pai[1],pai[2]}

	for i=1,serial_nu do 
		table.insert(pai,dai_pai[i][1])
	end


	return pai
end


function this.feiji_to_feiji_dui(data,seat_id,pai,force )

	local serial_nu=pai[2]-pai[1]+1

	local dui_pai 

	local ignore ={}
	for i=pai[1],pai[2]  do 
		ignore[i]=true
	end


	if force then 
		dui_pai=this.get_duizi_list(data,seat_id,true,false,ignore)
	else 
		dui_pai=this.get_duizi_list(data,seat_id,true,true,ignore)
	end

	if #dui_pai< serial_nu then 
		return nil
	end


	local pai={pai[1],pai[2]}

	for i=1,serial_nu do 
		table.insert(pai,dui_pai[i][1])
	end


	return pai
end





------------------------------------------



-- by lyx: 首发出牌，送牌给队友  不拆烂自己的牌
--返回： {type=,pai=}  或 nil （没找到）
function this.nor_songpai(data)

	local my_seat = data.base_info.my_seat

	--队友位置
	local p_seat,is_next=ddz_tg_assist_lib.get_partner_seat(data,my_seat)


	--如果有队友
	if p_seat then
		local want_list
		--队友是我的下家
		if is_next then
			want_list=ddz_tg_assist_lib.get_partner_want_pai_list(data,my_seat,p_seat,"no_ctrl")
		else
			want_list=ddz_tg_assist_lib.get_partner_want_pai_list(data,my_seat,p_seat,"ctrl")
		end


		if want_list then
			local my_pai=data.fen_pai[my_seat]
			local p_pai=data.fen_pai[p_seat]
			for k,v in ipairs(want_list) do

				local _my_pai_array = my_pai[v.type]
				local _song_pai

				if _my_pai_array and #_my_pai_array > 0 then
					--顺子 or 连队 长度必须相等
					if v.type==6 or v.type == 7 then

						_song_pai = this.search_min_less_pai_szldfj(v.type,_my_pai_array,p_pai[v.type])

						--飞机
					elseif v.type==10 or v.type==11 then 

						_song_pai = this.search_min_less_pai_szldfj(v.type,_my_pai_array,p_pai[v.type])
						if _song_pai then
							--  带牌的 置换
							if v.type==10 then
								_song_pai = this.feiji_to_feiji_dan(data,my_seat,_song_pai,false)	
							else
								_song_pai = this.feiji_to_feiji_dui(data,my_seat,_song_pai,false)	
							end						
						end

						--三带类型 考虑带牌的置换
					elseif v.type==4 or v.type==5 then 
						_song_pai = this.search_min_less_pai(v.type,_my_pai_array,p_pai[v.type],v.max_noctrl)
						if _song_pai then
							--  带牌的 置换
							if v.type==4 then
								_song_pai = this.sandai_to_sandai_dan(data,my_seat,_song_pai,false)	
							else
								_song_pai = this.sandai_to_sandai_dui(data,my_seat,_song_pai,false)	
							end						
						end
					else


						--找到此类型里面 我最小的牌  并且小于v.max_noctrl
						_song_pai = this.search_min_less_pai(v.type,_my_pai_array,p_pai[v.type],v.max_noctrl)
					end

					if _song_pai then
						local _sp_data = {type=v.type,pai=_song_pai}
						if this.check_chupai_ok(data,_sp_data) then -- 检查是否 得分 最高
							return _sp_data
						end
					end

				end
			end
		end
		return false
	end
	return nil
end

--强力送牌  一般情况下辅助才会如此做 尽量拆掉自己的牌去送牌
function this.force_songpai(data)
	--先尝试普通送牌
	local _song_pai = this.nor_songpai(data)
	if _song_pai then
		return _song_pai
	end

	--强制拆牌送

end
--队友爆牌给队友送牌
function this.baopai_songpai_to_p(data)
	--队友位置
	local p_seat,is_next=ddz_tg_assist_lib.get_partner_seat(data,my_seat)
	if is_next then
		local p_pai=data.fen_pai[p_seat]
		local p_type=100
		if (p_pai[1] and #p_pai[1]>0) then
			p_type=1
		elseif (p_pai[2] and #p_pai[2]>0) then
			p_type=2
		end
		if p_pai.shoushu==1 and (p_type==1 or p_type==2) then
			for i=3,14 do
				if data.pai_map[my_seat][i] and data.pai_map[my_seat][i]>=p_type and i<p_pai[p_type][1][1] then
					if this.check_chupai_ok(data,{type=1,pai={i}}) then
						return {type=1,pai={i}}
					end
					break
				end
			end
		end
	end
	return nil
end

function this.get_dingpai_from_list(data,_cp_data,_my_list,_other_list)
	--dump(_cp_data)
	-- 找到牌能顶到 _other_list 中的牌所在序号
	local _other_chupai_index=#_other_list + 1
	local _other_chupai_key

	local _my_chupai
	local _cp = {type=_cp_data.type}

	for i=#_my_list,1,-1 do

		local _my_key = ddz_tg_assist_lib.get_key_pai(_cp_data.type,_my_list[i])

		-- 找能顶到的牌（大于 _my_key 中 最小的）
		for j=_other_chupai_index-1,1,-1 do 
			local _o_key = ddz_tg_assist_lib.get_key_pai(_cp_data.type,_other_list[j])
			if _o_key > _my_key then 

				-- 能顶 更大的牌 才更新 _my_chupai
				if _o_key > (_other_chupai_key or 0) then 

					_cp.pai = _my_list[i]
					if this.check_chupai_ok(data,_cp) then
						_my_chupai = _my_list[i]
						_other_chupai_index = j
						_other_chupai_key = _o_key
					end
				end

				break
			end
		end

		-- 顶到肺了:)
		if _other_chupai_index == 1 then
			break
		end
	end	

	if _my_chupai then
		_cp.pai = _my_chupai
		return _cp
	else
		return nil
	end
end

-- by lyx: 从 _my_list 中找一手牌，达到 最大的 顶  _other_list 中牌的 效果，且自己代价最小
--		  注意： 需保证 牌 从大到小排序
function this.get_dingpai(data,_cp_data,_my_list,_other_list)

	local _cp = this.get_dingpai_from_list(data,_cp_data,_my_list,_other_list)

	-- 尝试拆不重要的牌
	if not _cp then

		local _chai_pai 

		if 1 == _cp_data.type then
			_chai_pai = this.get_danpai_list(data,data.base_info.my_seat,false,false,true,false,false)
		elseif 2 == _cp_data.type then
			_chai_pai = this.get_duizi_list(data,data.base_info.my_seat,false,false)
		end

		if _chai_pai then
			_chai_pai = ddz_tg_assist_lib.get_pai_by_big_and_type(_cp_data.type,_chai_pai,_cp_data.pai)
			if _chai_pai then
				_cp = this.get_dingpai_from_list(data,_cp_data,_chai_pai,_other_list)
			end
		end
	end

	-- 没找到，出最小的一张牌
	if not _cp and next(_my_list) then
		local _tmp = {type=_cp_data.type,pai=_my_list[#_my_list]}
		if this.check_chupai_ok(data,_tmp) then
			_cp = _tmp
		end
	end

	return _cp
end

--普通顶牌
function this.nor_dingpai(data,force)

	local my_seat = data.base_info.my_seat
	local dz_seat=data.base_info.dz_seat
	local dz_pai=data.fen_pai[dz_seat]
	local p_pai=data.fen_pai[p_seat]
	local my_pai=data.fen_pai[my_seat]

	local cp_data = data.last_pai

	--队友位置
	local p_seat,is_next=ddz_tg_assist_lib.get_partner_seat(data,my_seat)

	local _ding_pai

	if not (cp_data.type==1 or cp_data.type ==2 ) then  
		return nil 
	end

	local my_list 

	if not force then 
		my_list=ddz_tg_assist_lib.get_pai_by_big_and_type_noctrl(cp_data.type,my_pai[cp_data.type],cp_data.pai,my_seat,data.query_map)
	else 
		local temp_list 
		if cp_data.type == 1 then 
			temp_list= this.get_bigger_danpai(my_pai,cp_data.pai[1],false)

		elseif cp_data.type ==2 then 
			temp_list= this.get_bigger_duizi(my_pai,cp_data.pai[1],false)
		end

		table.sort(temp_list,function(l,r)
			return ddz_tg_assist_lib.get_key_pai(l.take.type,l.take.pai) > ddz_tg_assist_lib.get_key_pai(r.take.type,r.take.pai)
		end)

		my_list={}
		for k,v in ipairs(temp_list) do 
			table.insert(my_list,v.take.pai)
		end
	end
	if not my_list or #my_list==0 then 
		return nil 
	end


	--如果有队友
	if p_seat then

		--队友是我的下家
		if is_next then
			--队友是我下家并且 出牌人是地主
			if cp_data.p==dz_seat then
				--队友不要此类型的牌
				local p_list=ddz_tg_assist_lib.get_pai_by_big_and_type(cp_data.type,p_pai[cp_data.type],cp_data.pai)
				if not p_list or #p_list==0 then
					--地主有可以过的牌
					local dz_list=ddz_tg_assist_lib.get_pai_by_big_and_type_noctrl(cp_data.type,dz_pai[cp_data.type],cp_data.pai,dz_seat,data.query_map)
					if dz_list and #dz_list>0 then

						--我能顶 选出我的顶牌
						_ding_pai = this.get_dingpai(data,cp_data,my_list,dz_list)
					end
				end
			end
		else
			--地主有可以过的牌
			local dz_list=ddz_tg_assist_lib.get_pai_by_big_and_type_noctrl(cp_data.type,dz_pai[cp_data.type],cp_data.pai,dz_seat,data.query_map)
			if dz_list and #dz_list>0 then

				--我能顶 选出我的顶牌
				_ding_pai = this.get_dingpai(data,cp_data,my_list,dz_list)
			end

		end
	end

	if _ding_pai then 
		_ding_pai.tag= landai_util.get_traceback_info()
	end

	return _ding_pai
end
--强力顶牌
function this.froce_dingpai(data)

	--先尝试普通顶牌
	local _ding_pai = this.nor_dingpai(data,true)
	if _ding_pai then
		return _ding_pai
	end
	--强制拆牌顶
	if data.last_pai.type==1 or data.last_pai.type==2 then
		local my_seat = data.base_info.my_seat
		local cp_data = data.last_pai
		local dz_seat=data.base_info.dz_seat
		local dz_pai=data.fen_pai[dz_seat]
		local my_pai=data.fen_pai[my_seat]
		local my_pai_map=data.pai_map[my_seat]
		--地主有可以过的牌
		local dz_list=ddz_tg_assist_lib.get_pai_by_big_and_type_noctrl(cp_data.type,dz_pai[cp_data.type],cp_data.pai,dz_seat,data.query_map)
		if dz_list and #dz_list>0 then
			local dz_cp_pai=dz_list[#dz_list]
			local dz_cp_pai_key=ddz_tg_assist_lib.get_key_pai(data.last_pai.type,dz_cp_pai)
			--找到我最大的牌去顶
			for i=14,3,-1 do
				if my_pai_map[i] and my_pai_map[i]>=data.last_pai.type and my_pai_map[i]<4 and  i>=dz_cp_pai_key then
					return {type=data.last_pai.type,pai={i}}
				end
			end
		end
	end
	return nil 
end
--顺过并且不阻挡队友   no_compplete为true表示不完全阻挡即可 及表示略微阻挡是可以的
function this.shunguo_no_stop(data,my_seat,cp_data,no_compplete,try_max)
	--print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
	--队友位置
	local p_seat,is_next=ddz_tg_assist_lib.get_partner_seat(data,my_seat)
	--print(p_seat,is_next)
	--如果有队友
	if p_seat then
		local p_pai=data.fen_pai[p_seat]
		local my_pai=data.fen_pai[my_seat]
		local my_list=ddz_tg_assist_lib.get_pai_by_big_and_type_noctrl(cp_data.type,my_pai[cp_data.type],cp_data.pai,my_seat,data.query_map)
		local p_list=ddz_tg_assist_lib.get_pai_by_big_and_type_noctrl(cp_data.type,p_pai[cp_data.type],cp_data.pai,p_seat,data.query_map)

		--没有非占手牌，看下占手牌有没有
		if not p_list or #p_list==0 then 
			p_list= ddz_tg_assist_lib.get_pai_by_big_and_type(cp_data.type,p_pai[cp_data.type],cp_data.pai)
		end

		if cp_data.type==1 and my_list and #my_list>0 then
			--去飞机和三带中找更小的
			my_list=this.get_danpai_list(data,my_seat,false,false,false,false,false)
			my_list=ddz_tg_assist_lib.get_pai_by_big_and_type_noctrl(cp_data.type,my_list,cp_data.pai,my_seat,data.query_map)
		elseif cp_data.type==2 then
			my_list=this.get_duizi_list(data,my_seat, false, false ) 
			my_list=ddz_tg_assist_lib.get_pai_by_big_and_type_noctrl(cp_data.type,my_list,cp_data.pai,my_seat,data.query_map)
		end



		if my_list and #my_list>0 and p_list and #p_list>0 then


			local pos=#p_list
			if no_compplete then
				pos=1
			end
			local p_key=ddz_tg_assist_lib.get_key_pai(cp_data.type,p_list[pos])
			if try_max then
				local max_pai_info
				for k=#my_list,1,-1 do
					local my_key=ddz_tg_assist_lib.get_key_pai(cp_data.type,my_list[k])
					if my_key<p_key  then
						local pai_info={type=cp_data.type,pai=my_list[#my_list],tag=landai_util.get_traceback_info()}
						if this.check_chupai_ok(data,pai_info) then
							max_pai_info=pai_info
						end
					end
				end
				if max_pai_info then
					return max_pai_info
				end
			else
				local my_key=ddz_tg_assist_lib.get_key_pai(cp_data.type,my_list[#my_list])	
				if my_key<p_key  then
					local pai_info={type=cp_data.type,pai=my_list[#my_list],tag=landai_util.get_traceback_info()}
					if this.check_chupai_ok(data,pai_info) then
						return pai_info
					end
				end
			end


		end
	end



	return nil
end



-- by lyx: 得到 敌人 的座位号 （数组）
function this.get_enemy_seat(data,my_seat)
	if my_seat == data.base_info.dz_seat then
		local ret = {}
		for i=1,3 do
			if i ~= my_seat then
				ret[#ret + 1] = i
			end
		end

		return ret
	else
		return {data.base_info.dz_seat}
	end
end


-- by lyx: 得到上手牌列表：比给定牌大 的 牌 ，没有则会强制拆牌的情况
-- 	cp_data 出牌 {type=,pai=}
function this.get_shangshou_pai(data,my_pai,cp_data)
	local pai_map=my_pai


	-- 找大于 单牌、对子、三张的 牌，考虑 拆牌
	local bigger_pai123_funcs = 
	{
		[1]=this.get_bigger_danpai,
		[2]=this.get_bigger_duizi,
		[3]=this.get_bigger_sandai,
		[4]=this.get_bigger_sandai_1,
		[5]=this.get_bigger_sandai_2,
	}

	--找大于 顺子 、 连对 、 飞机的 牌，考虑 拆牌
	local bigger_pai_szldfj = 
	{
		[6]=true,
		[7]=true,
		[10]=true,
		[11]=true,
		[12]=true,
	}

	-- 顺子 、 连对 、 飞机
	if bigger_pai_szldfj[cp_data.type] then

		local _ret
		local _shunzi = this.get_all_possible_shunzi(data,my_pai,cp_data,false)
		for k,v in ipairs(_shunzi) do 
			if v.left_fen_pai[1] or #v.left_fen_pai[1]<=3 then -- 限定多出来 的散牌 
				_ret = _ret or {}
				_ret[#_ret + 1] = v.pai.pai
			end
		end

		return _ret
	end

	-- 单牌、对子、三张
	local _func = bigger_pai123_funcs[cp_data.type]

	if _func then
		local _pais = _func(pai_map,cp_data.pai[1],cp_data.type == 1) -- 单牌 才强制拆 （其他的 都是用炸弹 ，由调用者处理）

		local _ret
		if _pais and next(_pais) then
			for _,v in ipairs(_pais) do
				_ret = _ret or {}
				_ret[#_ret + 1] = v.take.pai
			end
		end

		return _ret
	end

	return nil
end

-- by lyx: 从列表中选择出牌，从最后一个（最小）开始找
function this.find_ok_chupai(data,_type,_pai_list)

	local _cp = {type=_type}
	for i=#_pai_list,1,-1 do
		_cp.pai = _pai_list[i]
		if this.check_chupai_ok(data,_cp)  then
			return _cp.pai
		end
	end

	return nil
end

-- by lyx: 从给定的候选 牌 list 中上手，并且 要大于或等于 对手的最大牌
-- 从最后一张开始找（最小）
-- 参数 _en_max_pai ： 敌人的最大牌
-- 返回 {type=,pai=,} 或 nil
function this.shangshou_from_list(data,_type,_pai_list,_en_max_pai)

	-- 对手 有 牌，继续筛选
	if _en_max_pai then
		_pai_list = ddz_tg_assist_lib.get_pai_by_big_and_type(_type,_pai_list,_en_max_pai,true) or _pai_list
	end

	local result = this.find_ok_chupai(data,_type,_pai_list)

	return result 
end

-- by lyx: 查找 上手牌
-- force 是否拆牌 强制上手
-- bomb 是否用炸弹强制上手
function this.shangshou(data,my_seat,cp_data,force,bomb)

	local my_pai = data.fen_pai[my_seat]

	-- 敌人的座位
	local _enemy_seats = this.get_enemy_seat(data,my_seat)

	-- 计算的出牌
	local _chu_pai

	if my_pai[cp_data.type] then

		-- 找敌人 手中最大牌
		local _en_max_pai
		local _en_max_key
		for _seat,_ in ipairs(_enemy_seats) do
			local _e_pai = data.fen_pai[_seat][cp_data.type] and data.fen_pai[_seat][cp_data.type][1]
			if _e_pai then
				local _e_key = ddz_tg_assist_lib.get_key_pai(cp_data.type,_e_pai)
				if not _en_max_key or _en_max_key < _e_key then
					_en_max_pai = _e_pai
					_en_max_key = _e_key
				end
			end
		end


		local _pai_list = ddz_tg_assist_lib.get_pai_by_big_and_type(cp_data.type,my_pai[cp_data.type],cp_data.pai)

		if _pai_list and next(_pai_list) then
			_chu_pai = this.shangshou_from_list(data,cp_data.type,_pai_list,_en_max_pai)
		end

		-- 没找到，考虑拆牌 
		if not _chu_pai and force then
			local _chai_list = this.get_shangshou_pai(data,my_pai,cp_data)
			if _chai_list and next(_chai_list) then
				-- 从最大的开始找
				basefunc.reverse(_chai_list)
				_chu_pai = this.shangshou_from_list(data,cp_data.type,_chai_list,_en_max_pai)
			end
		end
	end

	-- 炸弹上手：以上步骤没找到，且上家出牌不是炸弹
	if not _chu_pai and bomb and 13 ~= cp_data.type and 14 ~= cp_data.type then
		if my_pai[13] and next(my_pai[13]) then
			_chu_pai = this.find_ok_chupai(data,13,my_pai[13])
			if _chu_pai then 
				return {type=13,pai=_chu_pai,tag=landai_util.get_traceback_info()}
			end
		end
	end

	if _chu_pai then 
		return {type=cp_data.type,pai=_chu_pai,tag=landai_util.get_traceback_info()}
	end
	return nil 
end

-- 上手：
-- 	1：辅助，队友无法上手时，我上手为其送牌 （强制上手）
-- 	2：我未下叫，队友下叫，且队友无法上手，我上手为其送牌（nor上手）
-- 	3：我离下叫>1，队友离下叫==1，且队友无法上手，我上手为其送牌（nor上手） 
-- 	4：正常出

-- 顶牌：
-- 	1：辅助，强制顶   
-- 	2：普通人 nor顶
-- 	注意项：情况分为 下家是地主 和下家是队友  需要判断需不需要顶（如：地主无此类型的牌 则不需要顶   下家是队友，但是队友无牌也需要顶）

-- 顺过：
-- 	1：辅助：不能阻挡队友
-- 	2：我未下叫，队友下叫，不能阻挡队友
-- 	3：我离下叫>1，队友离下叫==1，不能阻挡队友（nor上手）
-- 	3：我离下叫==1，队友离下叫==1，我出牌后也不下叫，则不能阻挡队友（nor上手）


-- 正常出
--队友无法上手 或者上手后浪费 我来上手 然后送给队友牌(自己必须要能送牌)
-- by lyx: 农民跟牌


--[[
function this.nongmin_passive(data,my_seat,cp_data)
--队友位置
local p_seat,is_next=this.get_partner_seat(data,my_seat)

--如果有队友
if p_seat then
local dz_seat=data.base_info.dz_seat
local dz_pai=data.fen_pai[dz_seat]
local p_pai=data.fen_pai[p_seat]
local my_pai=data.fen_pai[my_seat]

if is_next then
--上手的情况

--地主出牌
if cp_data.p~=p_seat then

--获取比地主大的牌
local p_list=ddz_tg_assist_lib.get_pai_by_big_and_type(cp_data.type,p_pai[cp_data.type],cp_data.pai)
--我下叫了
if my_pai.xiajiao==0 then
--正常出牌

local result = this.nongmin_xiaojiao_chupai()
if result then 
return result
end
end	

---没有大于当前的牌
if not p_list or #p_list==0 then
if "我是辅助" then
if "强制能送牌" then
if p_pai.xiajiao==0 then
--可以动炸弹强制上手

else
--强制能上手

end
end
else
--上手 
if "能送牌" then
if p_pai.xiajiao==0 then
--可以动炸弹上手
elseif (p_pai.xiajiao>-3 and my_pai.xiajiao<p_pai.xiajiao) then
--不动炸弹上手
local pai=this.shangshou(data,my_seat,cp_data)
if pai then
return pai
end
end
end
end

--顶牌
if "我是辅助" then

elseif "不顶对面会顺过下叫" then

end

end
--上面尝试都不行则尝试顺过
if (p_pai.xiajiao>-2 and my.xiajiao<p_pai.xiajiao) or "我是辅助" then
--不顶顺过
local pai=this.shunguo_no_stop(data,my_seat,cp_data)
if pai then
return pai
end
end
--正常出牌 ###_test

else
--队友下叫了
if p_pai.xiajiao==0 then

--不顶顺过
local pai=this.shunguo_no_stop(data,my_seat,cp_data)
if pai then
return pai
end

--尝试过
end	
if my_pai.xiajiao==0 then
--正常出牌
end
--上面尝试都不行则尝试顺过
if (p_pai.xiajiao>-2 and my.xiajiao<p_pai.xiajiao) or "我是辅助" then
--不顶顺过
local pai=this.shunguo_no_stop(data,my_seat,cp_data)
if pai then
return pai
end
end
--正常出牌 ###_test
end
else
--不是我的队友出牌
if cp_data.p~=p_seat then
--我下叫了
if my_pai.xiajiao==0 then
--正常出牌
end
if "我是辅助" or dz_pai.xiajiao>-2 then
--顶牌
end
--正常出牌					
else
--
local dz_list=ddz_tg_assist_lib.get_pai_by_big_and_type(cp_data.type,dz_pai[cp_data.type],cp_data.pai)
--地主无此类型的牌
if not dz_list or #dz_list==0 then
--队友下叫了
if p_pai.xiajiao==0 then

--不顶顺过
local pai=this.shunguo_no_stop(data,my_seat,cp_data)
if pai then
return pai
end
--尝试过
end	
end


if my_pai.xiajiao==0 then
--正常出牌
end


if "我是辅助" or dz_pai.xiajiao>-2 then

--顶牌
end

--正常出牌

end
end 
end
end


--]]




function this.froce_shangshou(data,my_seat,cp_data)



end




--- 人性化处理

function this.passive_human_like_bomb_giveup(data)

	local my_pai_map=data.fen_pai[data.base_info.my_seat]

	if not this.check_my_will_win(data,{type=0})  then 
		return  nil 
	end

	if data.pai_re_count[data.base_info.my_seat] == 4 then 
		return nil 
	end

	local pai_list=ddz_tg_assist_lib.fenpai_map_to_list(my_pai_map,false)

	if #pai_list >2 then  
		return nil 
	end




	if my_pai_map[13]  and #my_pai_map[13]==1  and not my_pai_map[14] then 
		local biggest_bomb=my_pai_map[13][1] 
		if not this.check_my_will_win(data,{type=13,pai=biggest_bomb}) then 
			return nil 
		end

		local bigger_nu= ddz_tg_assist_lib.get_pai_is_bigger_in_unkown(data.query_map,data.base_info.my_seat,13,biggest_bomb)

		if bigger_nu>0 then 
			return {type=0}
		end
	end
end


function this.passive_full_play(data)
	local last_pai=data.last_pai 

	if last_pai.type ==14 then 
		return nil 
	end

	local my_seat=data.base_info.my_seat
	local my_pai=data.fen_pai[my_seat]

	local pai_list=ddz_tg_assist_lib.fenpai_map_to_list(my_pai)


	if #pai_list ~= 1 then 
		return nil 
	end

	local pai_info=pai_list[1]

	if pai_info.type ==last_pai.type then 
		if ddz_tg_assist_lib.get_key_pai(pai_info.type,pai_info.pai) > ddz_tg_assist_lib.get_key_pai(last_pai.type,last_pai.pai) then 
			return pai_info
		end

	elseif pai_info.type ==13 or pai_info.type == 14 then 
		return pai_info
	end
end




function this.passive_human_like_cp(data)
	local result =nil 

	result = this.passive_human_like_bomb_giveup(data)
	if result then 
		return result 
	end

end






function this.get_bigger_danpai(pai_map,face,force)
	local ret={}

	--对子
	if pai_map[2]  and #pai_map[2] >0 then 
		if face_is_bigger(pai_map[2][1][1],face) then 
			table.insert(ret,{
				take={type=1,pai={pai_map[2][1][1]}},
				from={type=2,pai={pai_map[2][1][1]}}
			})
		end
	end

	--三张 
	if pai_map[3] and #pai_map[3] > 0 then 
		if face_is_bigger(pai_map[3][1][1],face) then 
			table.insert(ret,{
				take={type=1,pai={pai_map[3][1][1]}},
				from={type=3,pai={pai_map[3][1][1]}}
			})
		end

	end

	--三带一
	if pai_map[4] and #pai_map[4]> 0 then 
		for k,v in ipairs(pai_map[4]) do 
			local biggest_face=max_face(v[1],v[2]) 
			if face_is_bigger(biggest_face,face) then 
				table.insert(ret,{
					take={type=1,pai={biggest_face}},
					from={type=4,pai=v}
				})
			end 
		end
	end


	--三带一对
	if pai_map[5] and #pai_map[5]> 0 then 
		for k,v in ipairs(pai_map[5]) do 
			local biggest_face = max_face(v[1],v[2]) 
			if face_is_bigger(biggest_face,face) then 
				table.insert(ret,{
					take={type=1,pai={biggest_face}},
					from={type=5,pai=v}
				})
			end
		end
	end



	--四带2
	if pai_map[8] and #pai_map[8] > 0 then 
		for k,v in ipairs(pai_map[8]) do 
			local mface=max_face(v[1],max_face(v[2],v[3]))

			if face_is_bigger(mface,face) then 
				table.insert(ret,{
					take={type=1,pai={mface}},
					from={type=8,pai=v}
				})
			end
		end
	end

	--四带2对
	if pai_map[9] and #pai_map[9] > 0 then 
		for k,v in ipairs(pai_map[9]) do 
			local mface=max_face(v[1],max_face(v[2],v[3]))
			if face_is_bigger(mface,face) then 
				table.insert(ret,{
					take={type=1,pai={mface}},
					from={type=9,pai=v}
				})
			end
		end

	end

	--顺子
	if pai_map[6] and #pai_map[6] >0 then 
		for k,v in ipairs(pai_map[6]) do 
			if v[2]-v[1]>=5 then 
				if face_is_bigger(v[2],face) then 
					table.insert(ret,{
						take={type=1,pai={v[2]}},
						from={type=6,pai=v}
					})
				end
			end
		end
	end


	--连对
	if pai_map[7] and #pai_map[7] >0 then 
		local biggest_face =  pai_map[7][1][2]
		if face_is_bigger(biggest_face,face) then 
			table.insert(ret,{
				take={type=1,pai={biggest_face}},
				from={type=7,pai=pai_map[7][1]}
			})
		end
	end


	--飞机带单
	if pai_map[10] and #pai_map[10] > 0 then 
		for k,v in ipairs(pai_map[10]) do 
			local biggest_face = nil 
			dump(v,"xxxxxxxxxxxxxxxxxxxxxxxxxxx big fase:")
			for fk,fv in ipairs(v) do 
				if fk~=1 then 
					biggest_face=max_face(biggest_face,fv)
				end
			end

			if face_is_bigger(biggest_face,face) then 
				table.insert(ret,{
					take={type=1,pai={biggest_face}},
					from={type=10,pai=v}
				})
			end

		end
	end


	--飞机带对
	if pai_map[11] and #pai_map[11] > 0 then 
		for k,v in ipairs(pai_map[11]) do 
			local biggest_face= nil 
			for fk,fv in ipairs(v) do 
				if fk~=1 then 
					biggest_face=max_face(biggest_face,fv)
				end
			end

			if face_is_bigger(biggest_face,face) then 
				table.insert(ret,{
					take={type=1,pai={biggest_face}},
					from={type=11,pai=v}
				})
			end

		end
	end

	--飞机
	if pai_map[12] and #pai_map[12] > 0 then 
		local biggest_face= pai_map[12][1][2]
		if face_is_bigger(biggest_face,face) then 
			table.insert(ret,{
				take={type=1,pai={biggest_face}},
				from={type=12,pai=pai_map[12][1]}
			})
		end
	end




	--炸弹
	if pai_map[13] and #pai_map[13] > 0 then 
		local biggest_face =pai_map[13][1][1]
		if face_is_bigger(biggest_face,face) then 
			table.insert(ret,{
				take={type=1,pai={biggest_face}},
				from={type=13,pai=pai_map[13][1]}
			})

		end
	end




	if pai_map[6] and #pai_map[6] >0 and force then 
		for k,v in ipairs(pai_map[6]) do 
			if v[2]-v[1]==4 then 
				if face_is_bigger(v[2],face) then 
					table.insert(ret,{
						take={type=1,pai={v[2]}},
						from={type=6,pai=v}
					})
				end
			end
		end
	end

	return ret
end



-- 当分牌中没有对子时，从一副牌中获取一个大于face最大的对子
-- 可拆：所有牌型都可拆
-- 没有可拆的返回nil 
function this.get_bigger_duizi(pai_map,face,op_will_win)
	local ret={}

	-- 从单张中找，看有没有可以合并的

	if pai_map[1] and #pai_map[1] >0 then 
		local pai_nu=0 
		local last_pai=nil 
		for k,v in ipairs(pai_map[1]) do 
			if face_is_bigger(v[1],face) then 
				if last_pai ~=v[1] then 
					last_pai=v[1] 
					pai_nu = 1 
				else 
					pai_nu=pai_nu + 1 
					if pai_nu >=2 then 
						table.insert(ret,{
							take={type=2,pai=v},
							from={type=2,pai=v}
						})
						break;
					end
				end
			end
		end
	end




	--三张 
	if pai_map[3] and #pai_map[3] > 0 then 
		if face_is_bigger(pai_map[3][1][1],face) then 
			table.insert(ret,{
				take={type=2,pai={pai_map[3][1][1]}},
				from={type=3,pai={pai_map[3][1][1]}}
			})
		end
	end

	--三带一
	if pai_map[4] and #pai_map[4]> 0 then 
		for k,v in ipairs(pai_map[4]) do 
			local biggest_face=v[1]
			if face_is_bigger(biggest_face,face) then 
				table.insert(ret,{
					take={type=2,pai={biggest_face}},
					from={type=4,pai=v}
				})
			end 
		end
	end


	--三带一对
	if pai_map[5] and #pai_map[5]> 0 then 

		for k,v in ipairs(pai_map[5]) do 
			local biggest_face = max_face(v[1],v[2]) 
			if face_is_bigger(biggest_face,face) then 
				table.insert(ret,{
					take={type=2,pai={biggest_face}},
					from={type=5,pai=v}
				})
			end
		end
	end



	--四带2
	if pai_map[8] and #pai_map[8] > 0 then 
		for k,v in ipairs(pai_map[8]) do 
			local mface=v[1]
			if face_is_bigger(mface,face) then 
				table.insert(ret,{
					take={type=2,pai={mface}},
					from={type=8,pai=v}
				})
			end
		end
	end




	--四带2对
	if pai_map[9] and #pai_map[9] > 0 then 
		for k,v in ipairs(pai_map[9]) do 

			local mface=max_face(v[1],max_face(v[2],v[3]))
			if face_is_bigger(mface,face) then 
				table.insert(ret,{
					take={type=2,pai={mface}},
					from={type=9,pai=v}
				})
			end

		end
	end

	--连对
	if pai_map[7] and #pai_map[7] >0 then 
		local biggest_face =  pai_map[7][1][2]
		if face_is_bigger(biggest_face,face) then 
			table.insert(ret,{
				take={type=2,pai={biggest_face}},
				from={type=7,pai=pai_map[7][1]}
			})
		end

	end


	--飞机带单
	if pai_map[10] and #pai_map[10] > 0 then 
		local pai_info=pai_map[10][1]

		if face_is_bigger(pai_info[2],face) then 
			table.insert(ret,{
				take={type=2,pai={pai_info[2]}},
				from={type=10,pai=pai_info}
			})
		end
	end



	--飞机带对
	if pai_map[11] and #pai_map[11] > 0 then 
		for k,v in ipairs(pai_map[11]) do 
			local biggest_face=nil 
			for fk,fv in ipairs(v) do 
				if fk~=1 then 
					biggest_face=max_face(biggest_face,fv)
				end
			end
			if face_is_bigger(biggest_face,face) then 
				table.insert(ret,{
					take={type=2,pai={biggest_face}},
					from={type=11,pai=v}
				})
			end
		end
	end


	--飞机
	if pai_map[12] and #pai_map[12] > 0 then 
		local biggest_face=max_face(biggest_face,pai_map[12][1][2])

		if face_is_bigger(biggest_face,face) then 
			table.insert(ret,{
				take={type=2,pai={biggest_face}},
				from={type=12,pai=pai_map[12][1]}
			})
		end
	end


	--炸弹
	if pai_map[13] and #pai_map[13]>0 and op_will_win then 

		local biggest_face =pai_map[13][1][1]
		if face_is_bigger(biggest_face,face) then 
			table.insert(ret,{
				take={type=2,pai={biggest_face}},
				from={type=13,pai=pai_map[13][1]}
			})
		end
	end

	return ret
end





-- 当分牌中没有三张时，从一副牌中获取一个大于face最大的三张
-- 没有可拆的返回nil 
function this.get_bigger_sandai(pai_map,face,op_will_win)

	local ret={}


	--三带一
	if pai_map[4] and #pai_map[4]> 0 then 
		local biggest_face=pai_map[4][1][1]
		if face_is_bigger(biggest_face,face) then 
			table.insert(ret,{
				take={type=3,pai={biggest_face}},
				from={type=4,pai=pai_map[4][1]}
			})
		end
	end



	--三带一对
	if pai_map[5] and #pai_map[5]> 0 then 
		local biggest_face=pai_map[5][1][1]
		if face_is_bigger(biggest_face,face) then 
			table.insert(ret,{
				take={type=3,pai={biggest_face}},
				from={type=5,pai=pai_map[5][1]}
			})
		end
	end

	--[[
	--四带2
	if pai_map[8] and #pai_map[8] > 0 then 
	for k,v in ipairs(pai_map[8]) do 
	local mface=v[1]
	if face_is_bigger(mface,face) then 
	table.insert(ret,{
	take={type=3,pai=mface},
	from={type=8,pai=v}
	})
	end
	end
	end

	--四带2对
	if pai_map[9] and #pai_map[9] > 0 then 
	for k,v in ipairs(pai_map[9]) do 

	local mface=max_face(v[1],max_face(v[2],v[3]))
	if face_is_bigger(mface,face) then 
	table.insert(ret,{
	take={type=3,pai=mface},
	from={type=9,pai=v}
	})
	end

	end
	end
	--]]



	--飞机带单
	if pai_map[10] and #pai_map[10] > 0 then 
		local biggest_face=pai_map[10][1][2] 
		if face_is_bigger(biggest_face,face) then 
			table.insert(ret,{
				take={type=3,pai={biggest_face}},
				from={type=10,pai=pai_map[10][1]}
			})
		end
	end



	--飞机带对
	if pai_map[11] and #pai_map[11] > 0 then 
		local biggest_face=pai_map[11][1][2]
		if face_is_bigger(biggest_face,face) then 
			table.insert(ret,{
				take={type=3,pai={biggest_face}},
				from={type=11,pai=pai_map[11][1]}
			})
		end
	end



	--飞机
	if pai_map[12] and #pai_map[12] > 0 then 
		local biggest_face=pai_map[12][1][2]
		if face_is_bigger(biggest_face,face) then 
			table.insert(ret,{
				take={type=3,pai={biggest_face}},
				from={type=12,pai=pai_map[12][1]}
			})
		end
	end



	--炸弹
	if pai_map[13] and #pai_map[13]>0 and op_will_win then 
		local biggest_face=pai_map[13][1][1]
		if face_is_bigger(biggest_face,face) then 
			table.insert(ret,{
				take={type=3,pai={biggest_face}},
				from={type=13,pai=pai_map[13][1]}

			})
		end

	end

	return ret

end

-- 当分牌中没有三带1时，从一副牌中获取一个大于face最大的三张1
-- 没有可拆的返回nil 
function this.get_bigger_sandai_1(pai_map,face)
	local ret={}

	local biggest_face =nil 




	--三带一对
	if pai_map[5] and #pai_map[5]> 0 then 
		local biggest_face=pai_map[5][1][1]
		if face_is_bigger(biggest_face,face) then 
			table.insert(ret,{
				take={type=4,pai={biggest_face,pai_map[5][1][2]}},
				from={type=5,pai=pai_map[5][1]}
			})
		end
	end



	--飞机带单
	if pai_map[10] and #pai_map[10] > 0 then 
		local pai_info=pai_map[10][1]

		if face_is_bigger(pai_info[2],face) then 
			table.insert(ret,{
				take={type=4,pai={pai_info[2],pai_info[3]}},
				from={type=10,pai=pai_info}
			})
		end
	end


	--飞机带对 
	if pai_map[11] and #pai_map[11] > 0 then 
		local pai_info=pai_map[11][1]
		if face_is_bigger(pai_info[2],face) then 
			table.insert(ret,{
				take={type=4,pai={pai_info[2],pai_info[3]}},
				from={type=11,pai=pai_info}
			})
		end
	end




	return ret



end




-- 当分牌中没有三带2时，从一副牌中获取一个大于face最大的三张2
-- 没有可拆的返回nil 
function this.get_bigger_sandai_2(pai_map,face)
	local ret ={}

	--飞机带对 
	if pai_map[11] and #pai_map[11] > 0 then 
		local pai_info =pai_map[11][1]
		if face_is_bigger(pai_info[2],face) then 
			table.insert(ret,{
				take={type=5,pai={pai_info[2],pai_info[3]}},
				from={type=11,pai=pai_info}
			})
		end
	end

	return ret

end



function this.get_bigger_merge_sandai_1(data,seat_id,face,last_pai_serial,op_will_win) 
	local pai_map= data.fen_pai[seat_id]

	local ret={}

	local daipai_list 

	if op_will_win then 
		daipai_list =this.get_danpai_list(data,seat_id,true,true,true,true,true)
	else 
		daipai_list =this.get_danpai_list(data,seat_id,true,true,false,false,false)
	end
	if #daipai_list ==0 then 
		return ret 
	end


	if pai_map[3] then 
		for k,v in ipairs(pai_map[3]) do 
			local pai_info=v 
			if face_is_bigger(pai_info[1],face) then 
				table.insert(ret,{
					take={type=4,pai={pai_info[1],daipai_list[1][1]}}
				})
			end
		end
	end
	return ret

end


function this.get_bigger_merge_sandai_2(data,seat_id,face,last_pai_serial,op_will_win) 

	local pai_map= data.fen_pai[seat_id]


	local ret={}
	local daipai_list 
	if op_will_win then 
		daipai_list=this.get_duizi_list(data,seat_id,true,true)
	else 
		daipai_list=this.get_duizi_list(data,seat_id,true,false)
	end

	if #daipai_list ==0 then 
		return ret 
	end


	if pai_map[3] then 
		for k,v in ipairs(pai_map[3]) do 
			local pai_info=v 
			if face_is_bigger(pai_info[1],face) then 
				table.insert(ret,{
					take={type=5,pai={pai_info[1],daipai_list[1][1]}}
				})
			end
		end
	end


	if pai_map[4] then 
		for k,v in ipairs(pai_map[4]) do 
			local pai_info=v 
			if face_is_bigger(pai_info[1],face) then 
				table.insert(ret,{
					take={type=5,pai={pai_info[1],daipai_list[1][1]}}
				})
			end
		end
	end


	return ret

end


function this.get_bigger_merge_feiji_1(data,seat_id,face ,last_pai_serial,op_will_win) 

	local ret={}

	local daipai_list 

	if op_will_win then 
		daipai_list= this.get_danpai_list(data,seat_id,true,true,true,true,true)
	else 
		daipai_list= this.get_danpai_list(data,seat_id,true,true,false,false,false)
	end


	if #daipai_list < last_pai_serial then 
		return ret
	end

	if pai_map[10] then 
		for k,v in pai_map[10] do 

			local v_serial=this.get_pai_type_serial(10,v) 

			if face_is_bigger(v[2],face) then 
				local pai= {v[2]-last_pai_serial+1,v[2]}

				for i=1,last_pai_serial do 
					table.insert(pai,daipai_list[i][1])
				end

				table.insert(ret,{
					take={type=10,pai=pai}
				})

			end
		end
	end
end


function this.get_bigger_merge_feiji_2(data,seat_id,face,last_pai_serial,op_will_win) 

	local ret={}

	local daipai_list 
	if op_will_win then 
		daipai_list= this.get_duizi_list(data,seat_id,true,true)
	else 
		daipai_list= this.get_duizi_list(data,seat_id,true,false)
	end

	if #daipai_list < last_pai_serial then 
		return ret
	end

	if pai_map[10] then 
		for k,v in pai_map[10] do 

			local v_serial=this.get_pai_type_serial(10,v) 

			if face_is_bigger(v[2],face) then 
				local pai= {v[2]-last_pai_serial+1,v[2]}

				for i=1,last_pai_serial do 
					table.insert(pai,daipai_list[i][1])
				end

				table.insert(ret,{
					take={type=11,pai=pai}
				})

			end
		end
	end


	if pai_map[11] then 
		for k,v in pai_map[11] do 

			local v_serial=this.get_pai_type_serial(10,v) 

			if face_is_bigger(v[2],face) then 
				local pai= {v[2]-last_pai_serial+1,v[2]}

				for i=1,last_pai_serial do 
					table.insert(pai,daipai_list[i][1])
				end

				table.insert(ret,{
					take={type=11,pai=pai}
				})

			end
		end
	end


end




--先走顺子连队等牌  
function this.chupai_by_choose(data,choose)
	local my_seat=data.base_info.my_seat
	local my_pai=data.fen_pai[my_seat]
	--先尝试走顺子 连队  飞机等
	for i=1,14 do
		if choose[i] and  my_pai[i] and #my_pai[i]>0 then
			local chupai_info=  {type=i,pai=my_pai[i][#my_pai[i]]}
			if this.check_chupai_ok(data,chupai_info) then 
				return chupai_info
			end
		end
	end
	return nil
end


--现将 3-12的牌出掉  而且先出 6-12 再出 三带
function this.chupai_by_3_12(data)
	local pai
	pai=this.chupai_by_choose(data,{[6]=true,[7]=true,[8]=true,[9]=true,[10]=true,[11]=true,[12]=true})
	if pai then
		return pai
	end

	pai=this.chupai_by_choose(data,{[3]=true,[4]=true,[5]=true})
	if pai then
		return pai
	end

	return nil

end


--敌人爆牌
function this.chupai_by_enemy_baopai(data)
	local my_seat=data.base_info.my_seat

	local my_pai=data.fen_pai[my_seat]

	local next_p=data.base_info.my_seat+1
	if next_p>#data.base_info.seat_type then
		next_p=1
	end

	if data.boyi_max_score~=0 then
		local bp=ddz_tg_assist_lib.get_enemy_bao_pai(data)
		if bp and bp>0 and bp<4 then
			local pai
			pai=this.chupai_by_3_12(data)
			if pai then
				if this.check_chupai_ok(data,pai)  then 
					return pai
				end
			end

			if bp==1 then
				pai=this.chupai_by_choose(data,{[2]=true})
				if pai then
					if this.check_chupai_ok(data,pai)  then 
						return pai
					end
				end

				--下家是我的队友
				if data.base_info.seat_type[next_p]==data.base_info.seat_type[my_seat] then
					--先尝试走对子
					if my_pai[2] and #my_pai[2]>0 then
						if this.check_chupai_ok(data,{type=2,pai=my_pai[2][#my_pai[2]]}) and my_pai[2][#my_pai[2]][1]<14 then
							return {type=2,pai=my_pai[2][#my_pai[2]]}
						end
					end

					if my_pai[1] and #my_pai[1]>0 then
						if this.check_chupai_ok(data,{type=1,pai=my_pai[1][1]}) then
							return {type=1,pai=my_pai[1][1]}
						end
					end
					--下家是敌人 
				elseif my_pai[1] and #my_pai[1]>0 then  --data.boyi_max_score<0 and
					local p_seat,is_next=ddz_tg_assist_lib.get_partner_seat(data,my_seat)
					if p_seat and data.pai_re_count[p_seat] ~= 1  then 
						--找非占手牌中的最大的出
						for i=1,#my_pai[1] do
							local pai={type=1,pai=my_pai[1][i]}
							local score=ddz_tg_assist_lib.get_pai_score(data.query_map,my_seat,pai.type,pai.pai) 
							pai.no_youha=true
							if (score <7 and this.check_chupai_ok(data,pai))  then
								return pai
							end
						end 

					else 
						for i=1,#my_pai[1] do
							local pai={type=1,pai=my_pai[1][i]}
							pai.no_youha=true
							if  this.check_chupai_ok(data,pai)  then
								return pai
							end
						end 
					end
				end
				--出单牌  从倒数第二张开始先出
				if my_pai[1] and #my_pai[1]>1 then
					if this.check_chupai_ok(data,{type=1,pai=my_pai[1][#my_pai[1]-1]}) then
						local pai_info =  {type=1,pai=my_pai[1][#my_pai[1]-1]}
						return pai_info 
					end
				end
			elseif bp==2 then
				pai=this.chupai_by_choose(data,{[1]=true})
				if pai then
					if this.check_chupai_ok(data,pai)  then 
						return pai
					end
				end
				--下家是我的队友
				if data.base_info.seat_type[next_p]==data.base_info.seat_type[my_seat] then
					--出对子  
					if my_pai[2]  and #my_pai[2]>0 then
						if this.check_chupai_ok(data,{type=2,pai=my_pai[2][1]}) then
							return {type=2,pai=my_pai[2][1]}
						end
					end
				else
					for i=3,14 do
						if data.pai_map[my_seat][i] and data.pai_map[my_seat][i]>0 then
							if this.check_chupai_ok(data,{type=1,pai={i}}) then
								return {type=1,pai={i}}
							end
							break
						end
					end
				end
				--出对子  从倒数第二张开始先出
				if my_pai[2] and #my_pai[2]>1 then
					if this.check_chupai_ok(data,{type=2,pai=my_pai[2][#my_pai[2]-1]}) then
						return {type=2,pai=my_pai[2][#my_pai[2]-1]}
					end
				end

			elseif bp==3 then
				--出单牌  从倒数第二张开始先出
				if my_pai[1] and #my_pai[1]>1 then
					if this.check_chupai_ok(data,{type=1,pai=my_pai[1][#my_pai[1]-1]}) then
						return {type=1,pai=my_pai[1][#my_pai[1]-1]}
					end
				end
				--出对子  从倒数第二张开始先出
				if my_pai[2] and #my_pai[2]>1 then
					if this.check_chupai_ok(data,{type=2,pai=my_pai[2][#my_pai[2]-1]}) then
						return {type=2,pai=my_pai[2][#my_pai[2]-1]}
					end
				end
			end
		end
	end

	return nil

end
function this.nm_genpai_by_enemy_baopai(data)

	local my_seat = data.base_info.my_seat
	local my_pai=data.fen_pai[my_seat]
	local cp_data = data.last_pai
	local bp=ddz_tg_assist_lib.get_enemy_bao_pai(data)
	if bp and bp>0 and bp<4 then
		--队友位置
		local p_seat,is_next=ddz_tg_assist_lib.get_partner_seat(data,my_seat)
		if not is_next then
			local my_list=ddz_tg_assist_lib.get_pai_by_big_and_type(cp_data.type,my_pai[cp_data.type],cp_data.pai)
			if my_list and #my_list>0 then
				local pai={type=cp_data.type,pai=my_list[1],tag=landai_util.get_traceback_info()}
				if this.check_chupai_ok(data,pai) then
					if (my_pai.shoushu==2 and data.boyi_max_score>0) or data.boyi_max_score<0 then
						return pai
					elseif p_seat and data.boyi_max_score>0 then
						local p_pai=data.fen_pai[p_seat]
						local p_list=ddz_tg_assist_lib.get_pai_by_big_and_type(cp_data.type,p_pai[cp_data.type],pai.pai)
						if p_list and #p_list>0 then
							return pai
						end
					end
				end 
			end
		end
	end
	return nil
end

function this.check_is_bi_win(data)
	if data.boyi_min_score >0 then 
		return true 
	end
	return false 
end


function this.check_is_bi_failed(data)
	if data.boyi_max_score <0 then 
		return true 
	end
	return  false 

end


function this.initiative_enemy_baopai_cp(data,is_dz)
	if ddz_tg_assist_lib.get_enemy_bao_pai(data) ==0 then 
		return nil 
	end


	if is_dz then 
		return this.chupai_by_enemy_baopai(data)
	else 
		if ddz_tg_assist_lib.get_next_is_enemy(data) or data.boyi_max_score>0 then 
			return this.chupai_by_enemy_baopai(data)
		elseif not ddz_tg_assist_lib.get_next_is_enemy(data) and data.boyi_max_score< 0 then  
			return this.chupai_by_enemy_baopai(data)
		end
	end
	return nil 
end




function this.initiative_full_cp(data)

	local my_seat=data.base_info.my_seat
	local my_pai=data.fen_pai[my_seat]

	local pai_list=ddz_tg_assist_lib.fenpai_map_to_list(my_pai)


	if #pai_list ~= 1 then 
		return nil 
	end

	local pai_info=pai_list[1]

	if pai_info.type == 8  or pai_info.type == 9 then 
		return nil 
	end

	return pai_info 

end 

function this.fen_pai_left_less_two_cp(data)

	local last_pai_data={
		p=data.last_seat ,
		type=data.last_pai.type,
		pai=data.last_pai.pai
	}


	local last_pai_type=last_pai_data.type 

	local last_pai_serial=this.get_pai_type_serial(last_pai_type,last_pai_data.pai)
	local last_key=ddz_tg_assist_lib.get_key_pai(last_pai_data.type,last_pai_data.pai)


	if last_pai_type == 14 then 
		return nil 
	end

	local my_seat=data.base_info.my_seat
	local my_pai=data.fen_pai[my_seat]

	local pai_list_with_bomb= ddz_tg_assist_lib.fenpai_map_to_list(my_pai,false)

	local pai_list=ddz_tg_assist_lib.fenpai_map_to_list(my_pai,true)

	--dump(pai_list)
	if #pai_list >=2 then  
		return nil 
	end



	--dump(my_pai)
	local big_list=ddz_tg_assist_lib.get_pai_by_big_and_type(last_pai_type,my_pai[last_pai_type],last_pai_data.pai)

	if big_list and #big_list >0 then 
		local pai={
			type=last_pai_type,
			pai=big_list[1]
		}
		if this.check_chupai_ok(data,pai) then 
			return pai
		end

	end


	if #pai_list_with_bomb == 2 then 
		if my_pai[14] then 
			local pai= {
				type=14
			}
			if this.check_chupai_ok(data,pai) then 
				return pai
			end
		end
	end



	if last_pai_type~=13 and  my_pai[13] and #my_pai[13] >=1 then 
		for i=#my_pai[13],1,-1 do 
			local bomb_pai=my_pai[13][i]
			local score,is_biggest= ddz_tg_assist_lib.get_pai_score(data.query_map,my_seat,13,bomb_pai)

			if is_biggest then 
				local pai={
					type=13,
					pai=bomb_pai
				}
				if this.check_chupai_ok(data,pai) then 
					return pai
				end
			end
		end
	end


	if my_pai[14] then 
		local pai= {
			type=14
		}
		if this.check_chupai_ok(data,pai) then 
			return pai
		end
	end

	return nil 

end

function this.passive_bomb_danpai_smaller(data,d_key)
	--dump(d_key)

	local my_seat=data.base_info.my_seat
	local my_pai=data.fen_pai[my_seat]

	local dan_pai=my_pai[1]

	if dan_pai and #dan_pai > 0 then 
		if dan_pai[#dan_pai][1] > d_key then 
			return nil 
		end
	end

	if my_pai[13]  and #my_pai[13] > 0 then 
		return {
			type =13,
			pai=my_pai[13][#my_pai[13]]
		}
	end

	if my_pai[14] then 
		return {
			type =14,
		}
	end

end


function this.parnter_baopao_dz_chupai(data)
	local my_seat=data.base_info.my_seat
	local p_seat=ddz_tg_assist_lib.get_partner_seat(data,my_seat)

	if data.pai_re_count[p_seat] ~= 1 or data.last_pai.type ~= 1  then 
		return nil 
	end

	local cp_data={
		p=data.last_seat ,
		type=data.last_pai.type,
		pai=data.last_pai.pai
	}


	--地主位置
	local dz_seat=data.base_info.dz_seat

	--地主牌
	local dz_pai=data.fen_pai[dz_seat]

	--队友牌
	local p_pai=data.fen_pai[p_seat]

	--自己牌
	local my_pai=data.fen_pai[my_seat]

	--我的位置
	local my_seat= data.base_info.my_seat 

	local p_list= p_pai[1] 


	if not p_list or #p_list ~= 1 then 
		return nil 
	end

	local min_pai,max_pai

	for k,v in pairs(data.pai_map[my_seat])  do 
		if v > 0 then 
			if not min_pai then 
				min_pai=k 
			else 
				if min_pai>k then 
					min_pai =k 
				end
			end


			if not max_pai then 
				max_pai = k
			else 
				if max_pai < k then 
					max_pai = k
				end
			end
		end
	end

	print(min_pai,max_pai,cp_data.pai[1])



	local my_list = my_pai[1]
	if not my_list or #my_list < 2  then 
		return nil 
	end


	if min_pai >=cp_data.pai[1] then 
		return nil 
	end

	if min_pai >= p_list[1][1] then 
		return nil 
	end


	local max_pai_score=ddz_tg_assist_lib.get_pai_score_use_allunkown(data.query_map,my_seat,1,{max_pai})


	if max_pai_score >=7 then 
		return {
			type=1,
			pai={max_pai}
		}
	end

	return nil 

end





return this


