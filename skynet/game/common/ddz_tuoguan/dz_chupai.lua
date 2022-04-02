local basefunc = require "basefunc"
local printfunc = require "printfunc"

local ddz_tg_assist_lib= require "ddz_tuoguan.ddz_tg_assist_lib"
local cp_algorithm=require "ddz_tuoguan.ddz_tuoguan_cp_algorithm"
local nor_ddz_ai_base_lib=require "ddz_tuoguan.nor_ddz_ai_base_lib"
local LysCards=require "ddz_tuoguan.lys_cards"

local this={}

local min = math.min
local max = math.max

local function pai_type_less_cmp_func(l,r)

	local l_value= ddz_tg_assist_lib.get_key_value_pai(l.type,l.pai)
	local r_value=ddz_tg_assist_lib.get_key_value_pai(r.type,r.pai)

	if l_value == r_value then 
		return ddz_tg_assist_lib.get_key_pai(l.type,l.pai) < ddz_tg_assist_lib.get_key_pai(r.type,r.pai)
	end

	return l_value < r_value 

end

-- 得到对手 小牌数量（相对 自己 的最大非控手牌）
function this.get_other_small_pai_count(_type,_my_pai,_other_pai)

	local pai_min=0
	local pai_max=0

	for k,v in ipairs(_my_pai)  do 
		for ok,ov in ipairs(_other_pai) do 
			local my_key=ddz_tg_assist_lib.get_key_pai(_type,v) 
			local other_key=ddz_tg_assist_lib.get_key_pai(_type,v)

			if my_key > other_key then 
				pai_max = pai_max + 1 

			elseif my_key < other_key then 
				pai_min= pai_min + 1 
			end
		end
	end
	return pai_max - pai_min 
end

--[[
by lyx: 计算能上手的评分	
参数 data ：
	{
		base_info = 
		{
			dz_seat    = ,
			my_seat    = ,
			seat_count = ,
			seat_type = {}, 座位类型，1 地主，0 农名
		},
		fen_pai = 
		{
			座位号 => 
			{
				牌组合类型 => 牌数据 
				bomb_count       = 1
				no_xiajiao_socre = -2
				score            = 4
				shoushu          = 5
				xiajiao          = 0
			}
		}
		last_pai = {type=牌组合类型,data=牌},
		last_seat = 最后一次出牌的座位,
		pai_map = {座位号=>pai_map},
		query_map = 用来查牌的评分, 7 分为控手牌
	}
返回值 ：拥有 使用 非控手牌 上手 的 机会 次数
--]]
function this.get_op_pai_small_nu(data)

	local my_seat = data.base_info.my_seat 
	local dz_seat =data.base_info.dz_seat 

	local op_seat=data.last_seat 
	if my_seat ~= dz_seat then 
		op_seat = dz_seat 
	end


	local _count = 0
	local pai_type= { 1,2,3,4,5,6,7} 

	for _type,_pai in pairs(data.fen_pai[data.base_info.my_seat]) do
		if 14 ~= _type and  type(_type) == "number" then -- 排除 王炸： 王炸没有非控手牌！！
			local _other_pai = data.fen_pai[op_seat][_type]
			if _other_pai then
				local score =  this.get_other_small_pai_count(_type,_pai,_other_pai)
				if score >= 2  or (score ==0 and #_other_pai>=2)  then
					_count = _count + 1
				end
			end
		end
	end

	return _count
end


this.get_pai_type_serial=cp_algorithm.get_pai_type_serial
this.get_bigger_merge_sandai_1=cp_algorithm.get_bigger_merge_sandai_1
this.get_bigger_merge_sandai_2=cp_algorithm.get_bigger_merge_sandai_2
this.get_bigger_merge_feiji_1=cp_algorithm.get_bigger_merge_feiji_1 
this.get_bigger_merge_feiji_2=cp_algorithm.get_bigger_merge_feiji_2 
this.get_bigger_danpai= cp_algorithm.get_bigger_danpai
this.get_bigger_duizi= cp_algorithm.get_bigger_duizi
this.get_bigger_sandai= cp_algorithm.get_bigger_sandai
this.get_bigger_sandai_1= cp_algorithm.get_bigger_sandai_1
this.get_bigger_sandai_2= cp_algorithm.get_bigger_sandai_2



function this.get_last_chupai(data)
	return data.last_pai 
end







function this.dizhu_passive_simple_cp(data)

	local my_pai_map =this.get_pai_map(data)
	local pai_info = this.dizhu_passive_simple_cp2(data)
	if not pai_info then 
		return pai_info
	end

	if pai_info.type ~= 1 or  pai_info.pai[1] < 16 then 
		return pai_info 
	end


	if not my_pai_map[2] or  #my_pai_map[2]==0 then 
		return pai_info 
	end


	local biggest_dui=my_pai_map[2][1] 

	if biggest_dui[1]~=15 then 
		return pai_info 
	end


	local last_pai_data=this.get_last_chupai(data)
	if last_pai_data.pai[1] >=15 then 
		return pai_info 
	end


	local b2pai={
		type =1,
		pai={15}
	}

	if cp_algorithm.check_chupai_ok(data,b2pai) then 
		return b2pai
	end

	return pai_info


end

function this.dizhu_passive_simple_cp2(data)


	local my_seat=data.base_info.my_seat 
	local dz_seat=data.base_info.dz_seat 


	local last_pai_data=this.get_last_chupai(data)
	local last_pai_type=last_pai_data.type 

	local last_pai_serial=this.get_pai_type_serial(last_pai_type,last_pai_data.pai)
	local last_key=ddz_tg_assist_lib.get_key_pai(last_pai_data.type,last_pai_data.pai)

	local my_pai_map =this.get_pai_map(data)

	local give_up={type=0}

	local op_seat= data.last_seat 
	if my_seat ~= dz_seat  then 
		op_seat = dz_seat 
	end

	local pre_seat= ddz_tg_assist_lib.get_pre_seat_id(data)
	local next_seat= ddz_tg_assist_lib.get_next_seat_id(data)

	local pre_card_nu= data.pai_count[pre_seat]
	local next_card_nu=data.pai_count[next_seat]

	local op_card_nu=data.pai_count[op_seat]


	--检查符合的牌型 
	if my_pai_map[last_pai_type] and #my_pai_map[last_pai_type] > 0 then 
		for i=#my_pai_map[last_pai_type],1,-1 do  

			local pai_info=nil 

			local v= my_pai_map[last_pai_type][i]

			local now_key=ddz_tg_assist_lib.get_key_pai(last_pai_type,v)

			local now_serial=this.get_pai_type_serial(last_pai_type,v)

			if now_key <=last_key then 
				goto next_loop
			end 


			if now_serial ~= last_pai_serial then 
				goto next_loop
			end



			pai_info = {
				type=last_pai_type,
				pai=v
			}
			if not this.check_chupai_ok(data,pai_info ) then 
				goto next_loop 

			end

			local score= ddz_tg_assist_lib.get_pai_score(data.query_map,my_seat,pai_info.type,pai_info.pai)
			--占手牌，是否要出
			if score == 7 then 

				--顺子类型的直接出
				if last_pai_type== 6 or last_pai_type == 7 or last_pai_type == 10  or last_pai_type == 11 or last_pai_type == 12 then 
					return pai_info
				end


				local extra_zp_nu = ddz_tg_assist_lib.get_extraNozhanshou_sum(last_pai_type,my_pai_map[last_pai_type],my_seat,data.query_map) 

				-- 对手还有我的牌
				local op_small_nu = this.get_op_pai_small_nu(data,last_pai_type,v)

				--dump(op_small_nu,"op_small_nu")
				if  extra_zp_nu <  2 then 
					return pai_info
				end

				if my_seat == dz_seat then 
					if pre_id == op_seat then 

						if op_small_nu < 2 or pre_card_nu < 9 then 
							return pai_info 
						end

					else 

						if pre_card_nu< 9 or next_card_nu< 9  or op_small_nu < 3 then 
							return pai_info
						end

					end
				end


				if this.check_chupai_ok(data,give_up) then 
					return give_up
				end

			end

			--尝试出牌
			if this.check_chupai_ok(data,pai_info) then 
				return pai_info
			end
			::next_loop::
		end
	end


	return nil

end





function this.dizhu_passive_split_noshunzhi_cp(data,my_pai_map,last_pai_data,op_will_win) 

	local my_seat=data.base_info.my_seat 

	local last_pai_type=last_pai_data.type 

	local last_pai_serial=this.get_pai_type_serial(last_pai_type,last_pai_data.pai)
	local last_key=ddz_tg_assist_lib.get_key_pai(last_pai_data.type,last_pai_data.pai)

	local give_up={type=0}

	local merge_map={
		[4]=this.get_bigger_merge_sandai_1,
		[5]=this.get_bigger_merge_sandai_2,
		[10]=this.get_bigger_merge_feiji_1,
		[11]=this.get_bigger_merge_feiji_2,
	}


	if merge_map[last_pai_type] then 
		local result = merge_map[last_pai_type](data,my_seat,last_key,last_pai_serial,op_will_win) 

		table.sort(result,function(l,r) 
			return ddz_tg_assist_lib.get_key_pai(l.take.type,l.take.pai) < ddz_tg_assist_lib.get_key_pai(r.take.type,r.take.pai)
		end)


		for k,v in ipairs(result) do 
			if this.check_chupai_ok(data,v.take) then 
				return v.take
			end
		end
	end


	local handle_map={
		[1]=this.get_bigger_danpai,
		[2]=this.get_bigger_duizi,
		[3]=this.get_bigger_sandai,
		[4]=this.get_bigger_sandai_1,
		[5]=this.get_bigger_sandai_2,
	}



	if not handle_map[last_pai_type] then 
		return nil 
	end


	local result =handle_map[last_pai_type](my_pai_map,last_key,op_will_win)

	table.sort(result,function(l,r)
		return ddz_tg_assist_lib.get_key_pai(l.take.type,l.take.pai) > ddz_tg_assist_lib.get_key_pai(r.take.type,r.take.pai)
	end)


	if #result == 0 then 
		return nil
	end

	local op_small_nu=this.get_op_pai_small_nu(data) 
	--dump(op_small_nu)

	if op_small_nu > 2  then 
		return  give_up 
	end

	if op_will_win then 
		return result[1].take
	else 
		for k,v in ipairs(result) do 


			local after_fen_pai=nor_ddz_ai_base_lib.pai_type_remove(v.from.type,v.from.pai,
			v.take.type,v.take.pai)

			local score= ddz_tg_assist_lib.get_pai_score(data.query_map,my_seat,v.take.type,v.take.pai)
			local rest_pai=nor_ddz_ai_base_lib.pai_type_remove(v.from.type,v.from.pai,v.take.type,v.take.pai)


			local rest_xiaojiao,no_xiao_jiao_score=ddz_tg_assist_lib.check_is_xiajiao(rest_pai,my_seat,data.query_map)

			if rest_xiaojiao ~=0 then 
				return v.take 
			end

			if no_xiao_jiao_score <= 2 or score==7 then 
				return v.take 
			end
			local danpai_nu=0 

			if rest_pai[1] then 
				danpai_nu=#rest_pai[1] 
			end


			if danpai_nu <=1 then 
				return v.take
			end

			if ddz_tg_assist_lib.get_key_pai(v.take.type,v.take.pai) >=13 and dai_danpai <3  then 
				return v.take
			end

		end
	end



	return nil

end





function this.dizhu_passive_split_shunzi_no_daipai_cp(data,my_pai_map,last_pai_data,op_will_win)

	local possible_shunzi=cp_algorithm.get_all_possible_shunzi(data,my_pai_map,last_pai_data)

	for k,v in ipairs(possible_shunzi) do 
		--连队，飞机直接出
		if last_pai_type ==7  or last_pai_type ==12 then 
			if this.check_chupai_ok(data,v.pai) then 
				return v.pai 
			end
		else 
			if op_will_win then 
				if this.check_chupai_ok(data,v.pai) then 
					return v.pai
				end
			else 
				if not v.left_fen_pai[1] then 
					return v.pai 
				end

				if v.left_fen_pai[1] and #v.left_fen_pai[1]<=2 then 
					return v.pai
				end
			end
		end
	end

end



function this.dizhu_passive_split_shunzi_cp(data,my_pai_map,last_pai_data,op_will_win)

	local last_pai_type=last_pai_data.type 

	local last_pai_serial=this.get_pai_type_serial(last_pai_type,last_pai_data.pai)
	local last_key=ddz_tg_assist_lib.get_key_pai(last_pai_data.type,last_pai_data.pai)

	if last_pai_type == 6 or last_pai_type == 7 or last_pai_type==12 then 
		return this.dizhu_passive_split_shunzi_no_daipai_cp(data,my_pai_map,last_pai_data,op_will_win)
	end




	--拆牌来出 顺子处理
	if last_pai_serial >=2 then 
		if my_pai_map[last_pai_type] and #my_pai_map[last_pai_type] > 0 then 
			for i=#my_pai_map[last_pai_type],1,-1 do  

				local v= my_pai_map[last_pai_type][i]

				local now_key=ddz_tg_assist_lib.get_key_pai(last_pai_type,v)

				local now_serial=this.get_pai_type_serial(last_pai_type,v)

				if now_key <=last_key then 
					goto next_loop
				end 


				if now_serial<=last_pai_serial then 
					goto next_loop 
				end


				local play_pai={
					type=last_pai_type,
					pai={ now_key, now_key-last_pai_serial+1 }
				}


				if not this.check_chupai_ok(data,play_pai) then 
					goto next_loop
				end


				--[[

				-- 连对，飞机，直接出
				if  last_pai_type == 7 or last_pai_type == 10 then 
				return {
				type=last_pai_type,
				pai={ now_key, now_key-last_pai_serial+1 }
				}
				end
				--]]

				--飞机带
				if last_pai_type == 12 or last_pai_type ==11 then 
					local data={now_key,now_key-last_pai_serial+1}
					for i=1,last_pai_serial  do 
						table.insert(v[i+2])
					end
					return {
						type=last_pai_type,
						pai=data,
					}
				end


				--[[
				if now_serial-last_pai_serial >=3 and last_pai_type ==6   then 

				--对手会赢 -- 强出
				if op_will_win then 
				return {
				type=last_pai_type,
				pai={ now_key, now_key-last_pai_serial+1 }
				}
				end

				goto next_loop 
				end
				--]]


				::next_loop::
			end
		end
		return nil 
	end

	return nil 

end



function this.dizhu_passive_split_cp(data,op_will_win)

	local my_seat=data.base_info.my_seat 

	local last_pai_data=this.get_last_chupai(data)
	local last_pai_type=last_pai_data.type 

	local last_pai_serial=this.get_pai_type_serial(last_pai_type,last_pai_data.pai)
	local last_key=ddz_tg_assist_lib.get_key_pai(last_pai_data.type,last_pai_data.pai)

	local my_pai_map =this.get_pai_map(data)

	local give_up= { type=0 }

	-- 顺子的处理
	if last_pai_serial >=2 then 

		local result=this.dizhu_passive_split_shunzi_cp(data,my_pai_map,last_pai_data,op_will_win)
		if result then 
			return result 
		end

	else --非顺子处理

		local result= this.dizhu_passive_split_noshunzhi_cp(data,my_pai_map,last_pai_data,op_will_win)
		if result then 
			return result 
		end

	end

	return nil 


end 





--建议出牌
function this.dizhu_passive_suggest_cp(data)
	return this.dizhu_suggest_cp(data)
end



--必赢打法 
function this.dizhu_passive_win_cp(data,force,use_bomb,use_absolute)

	local my_seat=data.base_info.my_seat 

	local last_pai_data=this.get_last_chupai(data)
	local last_pai_type=last_pai_data.type 

	local last_pai_serial=this.get_pai_type_serial(last_pai_type,last_pai_data.pai)
	local last_key=ddz_tg_assist_lib.get_key_pai(last_pai_data.type,last_pai_data.pai)

	local my_pai_map =this.get_pai_map(data)

	--[[
	if my_pai_map[last_pai_type] and #my_pai_map[last_pai_type]> 0 then 

		local extra_zp_nu,ctrl_nu,no_ctrl_nu=ddz_tg_assist_lib.get_extraNozhanshou_sum(last_pai_type,my_pai_map[last_pai_type],my_seat,data.query_map)
		if no_ctrl_nu>=ctrl_nu then 
			return nil 
		end
	end
	--]]


	--print(extra_zp_nu,ctrl_nu,no_ctrl_nu)



	--检查符合的牌型 
	if my_pai_map[last_pai_type] and #my_pai_map[last_pai_type] > 0 then 
		for i=#my_pai_map[last_pai_type],1,-1 do  

			local pai_info=nil 

			local v= my_pai_map[last_pai_type][i]

			local now_key=ddz_tg_assist_lib.get_key_pai(last_pai_type,v)

			local now_serial=this.get_pai_type_serial(last_pai_type,v)

			if now_key <=last_key then 
				goto next_loop
			end 


			if now_serial ~= last_pai_serial then 
				goto next_loop
			end



			pai_info = {
				type=last_pai_type,
				pai=v
			}

			local score= ddz_tg_assist_lib.get_pai_score(data.query_map,my_seat,pai_info.type,pai_info.pai)
			--dump(pai_info,tostring(i).." " ..score)


			--占手牌，是否要出
			if score < 7 then 
				if not (last_pai_type == 1 and v[1] > 14) then 
					goto next_loop 
				end
			end

			local pai_data_after_cp= basefunc.deepcopy(my_pai_map)

			nor_ddz_ai_base_lib.pai_split_remove(pai_data_after_cp,last_pai_type,i,last_pai_type,v)

			local xiao_type
			if use_absolute then 
				xiao_type =ddz_tg_assist_lib.check_is_xiajiao_absolute(pai_data_after_cp,my_seat,data.query_map)
				--dump(xiao_type)
			else 
				xiao_type =ddz_tg_assist_lib.check_is_xiajiao(pai_data_after_cp,my_seat,data.query_map)
			end

			if xiao_type ~= 0 or force then 
				if this.check_chupai_ok(data,pai_info) then 
					return pai_info 
				end
			end

			::next_loop::
		end
	end

	--炸弹
	if last_pai_type~=13 then 
		if my_pai_map[13] and #my_pai_map[13] > 0 and use_bomb then 
			for i=#my_pai_map[13],1,-1 do  
				local v= my_pai_map[13][i]
				local pai_data_after_cp= basefunc.deepcopy(my_pai_map)

				nor_ddz_ai_base_lib.pai_split_remove(pai_data_after_cp,13,i,13,v)

				local xiao_type =ddz_tg_assist_lib.check_is_xiajiao_absolute(pai_data_after_cp,my_seat,data.query_map)
				if (xiao_type >0 and xiao_type <= 5) or force then 
					local pai_info = {
						type=13,
						pai=v,
					}
					if this.check_chupai_ok(data,pai_info) then
						return pai_info 
					end


				end
			end
		end
	end


	--王炸
	if my_pai_map[14]  and use_bomb then 
		local pai_data_after_cp= basefunc.deepcopy(my_pai_map)
		pai_data_after_cp[14]=nil 
		local xiao_type =ddz_tg_assist_lib.check_is_xiajiao_absolute(pai_data_after_cp,my_seat,data.query_map)
		if (xiao_type > 0 and xiao_type <= 5) or force then 
			local pai_info = {
				type=14,
				pai=true,
			}
			if this.check_chupai_ok(data,pai_info) then 
				return pai_info 
			end
		end
	end
	return nil 
end



--对手不是必赢打法
function this.dizhu_passive_op_not_win_cp(data)

	local result =this.dizhu_passive_simple_cp(data,false)

	if result then 
		return result 
	end 

	result = this.dizhu_passive_split_cp(data,false)


	return result 

end





--对手必赢打法
function this.dizhu_passive_op_win_cp(data)


	local result =  this.dizhu_passive_simple_cp(data) 

	if result then 
		return result 
	end

	result = this.dizhu_passive_win_cp(data,false,true)

	if result then 
		return result 
	end

	result = this.dizhu_passive_split_cp(data,true)

	return result 

end



function this.dizhu_passive_cp(data)

	if data.last_pai.type == 14 then 
		return {type=0}
	end


	local last_cp_seat=data.last_seat 


	local result= nil 
	local give_up={type=0}

	local result = cp_algorithm.passive_full_play(data) 
	if result then 
		result.tag="full play" 
		return result 
	end


	result= cp_algorithm.fen_pai_left_less_two_cp(data) 
	if result then  
		result.tag="left_less_two_cp"
		return result
	end



	-- 人性化处理
	result= cp_algorithm.passive_human_like_cp(data)
	if result then 
		dump(result,"humanlike")
		return result 
	end





	-- 赢打法
	result= this.dizhu_passive_win_cp(data,false,true)
	if result then 
		dump(result,"win_play")
		return result 
	end


	local op_will_win=this.check_op_will_win(data,{type=0})

	if not op_will_win then 
		--对不是必赢打法
		result = this.dizhu_passive_op_not_win_cp(data)

		if result then 
			dump(result,"op_not_win_cp")
			return result 
		end
	else 
		--对手必赢打法
		result = this.dizhu_passive_op_win_cp(data)
		if result then 
			dump(result,"op_win_cp")
			return result 
		end
	end

	if not result then 
		-- 建议出牌
		result=this.dizhu_passive_suggest_cp(data) 
		if result then 
			dump(result,"suggest_play")
			return result 
		end
	end


	return give_up 

end






function this.get_my_fenpai_is_xiajiao_type(data,use_sure)
	local my_seat=data.base_info.my_seat 
	local fen_pai= data.fen_pai[my_seat]
	local query_map= data.query_map 
	local xiao_type =ddz_tg_assist_lib.check_is_xiajiao(fen_pai,my_seat,query_map,use_sure)

	return xiao_type 
end


function this.dizhu_suggest_cp(data)
	--dump(data.boyi_list)

	local result = data.boyi_list[1]

	if result.score <=0 and (result.type ==13  or result.type == 14) then 
		if data.boyi_min_score <0 and data.boyi_max_score <=0 then 
			if not data.firstplay then 
				return {
					type=0,
					tag="suggest_play"
				}
			end
		end
	end


	if result.type >=13 and result.score == 0 then 

		local my_seat= data.base_info.my_seat 
		local fen_pai = data.fen_pai[my_seat]

		for k,v in ipairs(data.boyi_list) do 
			if v.type  >= 13  then 

				local pai_data_after_cp= basefunc.deepcopy(fen_pai)

				nor_ddz_ai_base_lib.pai_split_remove(pai_data_after_cp,v.type,k,v.type,k)


				local xiao_jiao=ddz_tg_assist_lib.check_is_xiajiao_absolute(pai_data_after_cp,my_seat,data.query_map)
				if xiao_jiao > 0 then 
					return {
						type=v.type,
						pai=v.pai,
						tag="suggest_play"
					}
				end

			else 
				return {
					type=v.type,
					pai=v.pai,
					tag="suggest_play"
				}
			end
		end
	end


	--处理下家为单或双时
	if ddz_tg_assist_lib.get_next_is_enemy(data) then 
		local next_seat_id=ddz_tg_assist_lib.get_next_seat_id(data)
		local next_pai_count=data.pai_re_count[next_seat_id]
		if next_pai_count==1 or next_pai_count ==2 then 
			for k,v in ipairs(data.boyi_list) do 
				if v.type ~= next_pai_count and v.score == data.boyi_max_score then 
					return {
						type=v.type,
						pai=v.pai,
						tag="suggest_play"
					}
				end
			end
		end
	end





	return {
		type=result.type,
		pai=result.pai,
		tag="suggest_play"
	}


end


function this.dizhu_initiative_cp(data)

	--dump(data.boyi_list)

	local result =nil 

	--最后一手牌
	result = cp_algorithm.initiative_full_cp(data)
	if result then 
		return result 
	end

	--报牌
	result = cp_algorithm.initiative_enemy_baopai_cp(data,true)
	--dump(result)

	if result then 
		dump(result,"baopai")
		return result 
	end


	if cp_algorithm.check_is_bi_failed(data) then 
		result = cp_algorithm.chupai_by_3_12(data)
		if result then 

			return result 
		end
	end


	local xiao_jiao=this.get_my_fenpai_is_xiajiao_type(data)
	local sure_xiao_jiao= this.get_my_fenpai_is_xiajiao_type(data,true)
	local pai_map_nu=ddz_tg_assist_lib.fen_pai_map_nu(data.fen_pai[data.base_info.my_seat])



	if xiao_jiao == 0  then 
		local result = this.dizhu_cp_normal(data)
		if result then 

			return result 
		end
	else 
		if sure_xiao_jiao > 0 or (xiao_jiao~=4 and pai_map_nu >= 3) then 
			local result =this.dizhu_cp_xiaojiao(data)

			if result then 
				return result 
			end

		else 

			local result = this.dizhu_cp_normal(data)
			if result then  
				return result 
			end
		end
	end


	result = this.dizhu_suggest_cp(data)

	if result then 
		return result 
	end


end


function this.dizhu_cp_xiaojiao(data)
	-- dump(data.boyi_list)

	local xiao_type= this.get_my_fenpai_is_xiajiao_type(data) 

	local my_seat = data.base_info.my_seat

	-- print("xiao_type:  ",xiao_type)
	local chupai_list= this.get_type_chupai_list(data)
	this.sort_type_chupai_list(chupai_list)
	-- dump(chupai_list)

	local has_bomb=false 

	if data.fen_pai[my_seat][13] and #data.fen_pai[my_seat][13]>0 then 
		has_bomb =true
	end

	if data.fen_pai[14] then 
		has_bomb=true 
	end


	if #chupai_list == 1 then 
		if #chupai_list[1].pais<=2 and chupai_list[1].type ~=13 then 
			local pai_info={
				type = chupai_list[1].type,
				pai=chupai_list[1].pais[1]
			}

			if this.check_chupai_ok(data,pai_info) then 
				return pai_info
			end

		end
	end




	for k, v in ipairs(chupai_list) do 
		if (v.type == 13 or v.type == 14)   then 
			goto next_loop
		end


		--如果非占手牌的数量大于1的话，放到后面出
		if (v.extra_zp_nu >0  and v.not_zp_nu > 1) or (v.extra_zp_nu >0 and (data.fen_pai[data.base_info.my_seat].abs_xiaojiao==0 or data.fen_pai[data.base_info.my_seat].abs_xiaojiao>2)) then 
			local pai_info={
				type=v.type,
				pai=v.pais[#v.pais] 
			}

			if this.check_chupai_ok(data,pai_info) then 
				return pai_info
			end

		end

		-- 只有一张牌 
		if v.extra_zp_nu ==1  and v.not_zp_nu ==1 and not has_bomb then 
			goto next_loop
		end

		local pai_info = { type=v.type, pai=v.pais[#v.pais] }


		if this.check_chupai_ok(data,pai_info) then 
			--dump(pai_info)
			
			return pai_info
		end

		::next_loop::
	end


	--出多余占手牌
	local first_info=chupai_list[1]
	local small_first=first_info.pais[#(first_info.pais)]

	local ret= {
		type=first_info.type,
		pai=small_first
	}

	if this.check_chupai_ok(data,ret) then 
		return ret 
	end


	-- 找炸弹出
	
	local boyi_pai=data.boyi_list[1]

	if boyi_pai.type == 13 or boyi_pai.type ==14 then 
		for k, v in ipairs(chupai_list) do 

			if (v.type == 13 or v.type == 14)   and xiao_type ~= 4 then 
				local pai_info = { type=v.type, pai=v.pais[#v.pais] }

				if this.check_chupai_ok(data,pai_info) then 
					return pai_info
				end

			end
		end
	end



end


function this.sort_type_chupai_list(chupai_list)

	-- 对牌按照以下顺序排序
	-- 1. 多余未下叫牌，最多的类型  若有相等 
	-- 2. 按非占手牌数据量，多的先出 
	-- 3. 若相等，按最小牌优先出


	--dump(chupai_list)

	table.sort(chupai_list,function(l,r)
		if l.extra_zp_nu==r.extra_zp_nu then 
			if l.not_zp_nu == r.not_zp_nu then 
				local l_keypai=ddz_tg_assist_lib.get_key_value_pai(l.type,l.pais[#l.pais])
				local r_keypai=ddz_tg_assist_lib.get_key_value_pai(r.type,r.pais[#r.pais])
				return l_keypai<r_keypai 
			end

			return l.not_zp_nu > r.not_zp_nu 
		end

		return l.extra_zp_nu > r.extra_zp_nu 
	end)
end


--获取自己的牌
function this.get_pai_map(data)
	local my_seat= data.base_info.my_seat 
	local my_pai_map=data.fen_pai[my_seat]
	return my_pai_map
end

function this.get_type_chupai_list(data)
	local chupai_list={}
	local my_seat= data.base_info.my_seat

	local pai_type={2,3,4,5,6,7,8,9,10,11,12,13,14}

	local pai_map=this.get_pai_map(data)

	for kp,pais in ipairs(pai_type) do 
		if pai_map[kp] and #pai_map[kp] > 0 then 

			local extra_zp_nu,ctrl_nu,no_ctrl_nu=ddz_tg_assist_lib.get_extraNozhanshou_sum(kp,pai_map[kp],my_seat,data.query_map)
			--print(extra_zp_nu,ctrl_nu,no_ctrl_nu,kp)

			local not_zp_nu=no_ctrl_nu


			local bpais={}
			local spais={}

			for _,ps in ipairs(pai_map[kp]) do 
				local score =ddz_tg_assist_lib.get_pai_score(data.query_map,my_seat,kp,ps)
				if score==7 then 
					table.insert(bpais,ps) 
				else 
					table.insert(spais,ps)
				end
			end



			table.insert(chupai_list,{
				pais=pai_map[kp],  --所有的牌

				bpais=bpais,  --控手牌
				spais=spais,  --非控手牌

				type=kp, -- 牌类型

				extra_zp_nu=extra_zp_nu, --多余非占手牌的数量
				not_zp_nu=not_zp_nu,     --非占手牌的数量
				ctrl_nu=ctrl_nu  --占手牌的数量
			})

		end
	end


	if pai_map[14] then 
		table.insert(chupai_list,{
			pais={},
			bpais={},
			spais={},
			type=14,
			extra_zp_nu=0,
			not_zp_nu=0,
			ctrl_nu=1,
		})
	end



	return chupai_list
end


function this.get_all_chupai(data)

	local chupai_list={}
	local my_seat= data.base_info.my_seat
	local pai_map=this.get_pai_map(data)
	--dump(pai_map)

	for kp,type_pais in pairs(pai_map) do 
		if type(kp) =="number" then 
			if kp == 14 then 

				table.insert(chupai_list,{
					type=14,
					pai=true,
				})

			else 
				for _,pai_data in ipairs(type_pais) do 
					table.insert(chupai_list,{
						type=kp,
						pai=pai_data
					})
				end
			end
		end
	end
	return chupai_list
end



function this.check_op_will_win(data,pai_info)
	return cp_algorithm.check_op_will_win(data,pai_info)
end

function this.check_chupai_ok(data,pai_info) 
	return cp_algorithm.check_chupai_ok(data,pai_info)
end





--地主常规打法
function this.dizhu_cp_normal(data)

	-- 获取
	local chupai_list=this.get_all_chupai(data)
	table.sort(chupai_list,pai_type_less_cmp_func)
	--dump(chupai_list)




	-- 重小到大出
	for k,v in ipairs(chupai_list) do 
		if this.check_chupai_ok(data,v) then 

			return v 
		end

	end


	--  获取一个大牌出
	local type_chupai_list=this.get_type_chupai_list(data)


	this.sort_type_chupai_list(type_chupai_list)

	local type_chupai=type_chupai_list[1]
	local best_pai=type_chupai.pais[1]

	local pai= {
		type= type_chupai.type ,
		pai=best_pai
	}
	if cp_algorithm.check_chupai_ok(data,pai) then 
		return pai

	end

	return nil 
end




function this.dizhu_chupai(is_firstplay,data)
	local last_cp_seat=data.last_seat 

	if not data.boyi_map then 
		if is_firstplay then 
			local boyi_map,boyi_list=ddz_tg_assist_lib.get_cp_value_map(data,data.base_info.my_seat)
			data.boyi_map=boyi_map 
			data.boyi_list=boyi_list
		else 

			local boyi_map,boyi_list=ddz_tg_assist_lib.get_cp_value_map(data,data.base_info.my_seat, {
				p=last_cp_seat,
				type=data.last_pai.type,
				pai=data.last_pai.pai
			})

			data.boyi_map=boyi_map 
			data.boyi_list=boyi_list
		end
	end

	local my_seat= data.base_info.my_seat

	local result =nil

	if is_firstplay then 
		result =this.dizhu_initiative_cp(data)
		
	else 
		result = this.dizhu_passive_cp(data)
	end

	
	if not result  then 
		return {type=0}
	end

	if not  cp_algorithm.check_my_will_win(data,result) then 
		local you_ha=cp_algorithm.youhua_daipai(data,my_seat,result,is_firstplay)
		if cp_algorithm.check_chupai_ok(data,you_ha) then 
			result=you_ha
		else 
			if not cp_algorithm.check_chupai_ok(data,result) then 
				result=you_ha
			end
		end
	end

	return result 

end






return this 

