local basefunc = require "basefunc"
local printfunc = require "printfunc"

local ddz_tg_assist_lib= require "ddz_tuoguan.ddz_tg_assist_lib"
local cp_algorithm=require "ddz_tuoguan.ddz_tuoguan_cp_algorithm"
local nor_ddz_ai_base_lib=require "ddz_tuoguan.nor_ddz_ai_base_lib"
local landai_util=require "ddz_tuoguan.landai_util"

local dz_chupai= require "ddz_tuoguan.dz_chupai"




local this={}

--检查当前出牌对手是否会赢
this.check_op_will_win = cp_algorithm.check_op_will_win 


--建议出牌
this.nongmin_suggest_cp=dz_chupai.dizhu_suggest_cp 

--我的分牌是否下叫
this.get_my_fenpai_is_xiajiao_type=dz_chupai.get_my_fenpai_is_xiajiao_type


--检查我的出牌是否下叫
this.nongmin_cp_xiaojiao=dz_chupai.dizhu_cp_xiaojiao

--正常主动出牌
this.nongmin_initiative_normal_cp=dz_chupai.dizhu_cp_normal

--强制送牌
this.nongmin_force_songpai=cp_algorithm.force_songpai

--正常送牌
this.nongmin_normal_songpai = cp_algorithm.nor_songpai 


this.nongmin_passive_win_cp=dz_chupai.dizhu_passive_win_cp





--正常被动出牌
function this.nongmin_passive_normal_cp(data)

	local last_cp_seat=data.last_seat 

	local result= nil 
	local give_up={type=0}


	-- 赢打法
	result= this.nongmin_passive_win_cp(data,false,true,true)
	if result then 
		result.tag=landai_util.get_traceback_info()..":win_play"
		return result 
	end


	local op_will_win=this.check_op_will_win(data,{type=0})

	if not op_will_win then 
		--对不是必赢打法
		result = dz_chupai.dizhu_passive_op_not_win_cp(data)
		if result then 
			result.tag=landai_util.get_traceback_info()..":op_not_win_cp"
			--dump(result,"op_not_win_cp")
			return result 
		end

	else 
		--对手必赢打法
		result = dz_chupai.dizhu_passive_op_win_cp(data)
		if result then 
			result.tag=landai_util.get_traceback_info()..":op_win_cp"
			--dump(result,"op_win_cp")
			return result 
		end
	end


	return result 

end


function this.nongmin_no_partner_cp(data)
	return this.nongmin_passive_normal_cp(data)
end




-- by lyx:（检查自己是不是辅助)
function this.check_my_auxiliary(data)

	if data.base_info.seat_count == 2 then  
		return false 
	end

	if data.fuzhu_info then
		return data.fuzhu_info[data.base_info.my_seat]
	end

	return false 
end


function this.get_parner_seat(data)

	local my_seat=data.base_info.my_seat 
	local dz_seat=data.base_info.dz_seat 

	for i = i,data.seat_count  do 
		if i~=my_seat and i~=dz_seat then 
			return i 
		end
	end

	return -1
end

--获取我自己的下叫分
function this.get_my_xiaojiao_score(data)
	local my_seat_id = data.base_info.my_seat 
	return data.fen_pai[my_seat_id].no_xiajiao_socre 
end


--获取我队友的下叫分
function this.get_parner_xiaojiao_score(data)

	local parnter_seat=this.get_parner_seat 
	return data.fen_pai[parnter_seat].no_xiajiao_socre

end




function this.nongmin_initiative_cp(data)
	--dump(data.boyi_list)

	local result =nil 

	--最后一手牌
	result = cp_algorithm.initiative_full_cp(data)
	if result then 
		return result 
	end

	--我的下家我的朋友并且爆牌
	local result = cp_algorithm.baopai_songpai_to_p(data)
	if result then 
		return result 
	end
	

	--报牌
	result = cp_algorithm.initiative_enemy_baopai_cp(data,false)
	--dump(result)
	if result then 
		return result 
	end

	if cp_algorithm.check_is_bi_failed(data) then 
		result = cp_algorithm.chupai_by_3_12(data)
		--dump(result)
		if result then 
			return result 
		end
	end



	local xiao_jiao=this.get_my_fenpai_is_xiajiao_type(data)
	local sure_xiao_jiao= this.get_my_fenpai_is_xiajiao_type(data,true)
	local pai_map_nu=ddz_tg_assist_lib.fen_pai_map_nu(data.fen_pai[data.base_info.my_seat])



	if xiao_jiao==0 then 
		local result= this.nongmin_cp_no_xiaojiao(data)

		if result then 
			return result
		end
	else 
		if sure_xiao_jiao > 0 or (xiao_jiao~=4 and pai_map_nu >= 3) then 
			local result =this.nongmin_cp_xiaojiao (data)

			if result then 
				return result 
			end
		else 
			local result = this.nongmin_cp_no_xiaojiao(data)
			if result then  
				return result 
			end
		end
	end


	local result = this.nongmin_suggest_cp(data)
	--dump(result)

	if result then 
		return result 
	end

end




function this.nongmin_cp_no_xiaojiao(data)
	--dump(this.check_my_auxiliary(data),"sfsdfsf")
	if this.check_my_auxiliary(data) then 
		return this.nongmin_auxiliary_cp(data)
	else 
		return this.nongmin_no_auxiliary_cp(data)
	end

	--return this.nongmin_initiative_normal_cp(data)

end



--辅助打法
function this.nongmin_auxiliary_cp(data)
	-- 强制送牌
	local result = this.nongmin_force_songpai(data) 
	if result then 
		return result 
	end

	-- 正常出牌
	return this.nongmin_initiative_normal_cp(data)
end


--非辅助打法
function this.nongmin_no_auxiliary_cp(data)

	local result = nil 
	local my_seat = data.base_info.my_seat
	local p_seat=ddz_tg_assist_lib.get_partner_seat(data,my_seat)


	if p_seat then 
		local cp = data.last_pai
		local cp_seat = data.last_seat

		local my_pai = data.fen_pai[my_seat]

		local dz_pai = data.fen_pai[data.base_info.dz_seat]

		local p_pai=data.fen_pai[p_seat]


		local my_xiao_score=my_pai.xiajiao
		local parnter_xiao_score=p_pai.xiajiao

		-- 是否给下家送牌
		if parnter_xiao_score> -3  and  my_xiao_score < parnter_xiao_score then 
			result = this.nongmin_normal_songpai(data)
			if result then 
				return result 
			end
		end
	end

	--正常出牌
	result = this.nongmin_initiative_normal_cp(data)
	return  result

end




---------------------------跟牌部份----------------------
--- 农民跟牌

function this.nongmin_passive_cp(data)

	if data.last_pai.type == 14 then 
		return {type=0}
	end


	local my_seat=data.base_info.my_seat

	local p_seat,is_next=ddz_tg_assist_lib.get_partner_seat(data,my_seat)
	local result 

	result=cp_algorithm.passive_full_play(data)

	if result then 
		return result
	end



	-- 人性化处理
	result= cp_algorithm.passive_human_like_cp(data)
	if result then 
		return result 
	end


	--有队友时的打牌
	if p_seat then 
		result = this.nongmin_has_partner_cp(data)
	else 
		result=this.nongmin_no_partner_cp(data)
	end

	if result then 
		return result 
	end

	-- 建议出牌
	result=this.nongmin_suggest_cp(data) 
	if result then 
		dump(result,"suggest_play")
		return result 
	end

	return {type=0}

end



function this.nongmin_has_partner_cp(data)

	local my_seat=data.base_info.my_seat

	local cp_data={
		p=data.last_seat,
		type=data.last_pai.type,
		pai=data.last_pai.pai
	}

	local p_seat,is_next=ddz_tg_assist_lib.get_partner_seat(data,my_seat)

	local dz_seat=data.base_info.dz_seat
	local dz_pai=data.fen_pai[dz_seat]
	local p_pai=data.fen_pai[p_seat]
	local my_pai=data.fen_pai[my_seat]

	local result 


	local result=cp_algorithm.fen_pai_left_less_two_cp(data)

	if result then 
		dump(result,"less_two_cp")
		return result 
	end


	if is_next then 
		local parnter_pai_nu = data.pai_re_count[p_seat]
		if parnter_pai_nu == 1 and cp_data.type ~=13 and cp_data.type ~= 14  then 
			local result = cp_algorithm.passive_bomb_danpai_smaller(data,p_pai[1][1][1]) 
			if result and  cp_algorithm.check_chupai_ok(data,result) then 
				return result 
			end
		end

	end


	--print("SSSSSSSSS")
	--下家队友
	if is_next then 

		--出牌是地主
		if cp_data.p~=p_seat then
			result=this.nongmin_from_dz_to_nm(data)
		else  -- 出牌队友，地主不要
			result=this.nongmin_from_nm_to_nm(data)
		end

	else  -- 下家地主
		--出牌是地主
		if cp_data.p~=p_seat then
			result = this.nongmin_from_dz_to_dz(data)
			--出牌是对友
		else 
			result = this.nongmin_from_nm_to_dz(data)
		end
	end

	if result then 
		return result
	end

	return nil 
end






function this.nongmin_from_dz_to_nm(data)


	local my_seat=data.base_info.my_seat
	local cp_data={
		p=data.last_seat ,
		type=data.last_pai.type,
		pai=data.last_pai.pai
	}



	local p_seat=ddz_tg_assist_lib.get_partner_seat(data,my_seat)



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


	--获取比地主大的牌
	local p_list=ddz_tg_assist_lib.get_pai_by_big_and_type(cp_data.type,p_pai[cp_data.type],cp_data.pai)

	local result = cp_algorithm.parnter_baopao_dz_chupai(data)
	if result then 
		if cp_algorithm.check_chupai_ok(data,result)  then 
			return result
		end
	end


	

	--我下叫了
	if my_pai.xiajiao>0 then
		--正常出牌
		local pai= this.nongmin_passive_normal_cp(data)



		if pai then 
			local pai_by_score=ddz_tg_assist_lib.take_paidata_by_hash(data.boyi_map,pai) 
			local my_score=ddz_tg_assist_lib.get_pai_xiajiao_score(data,my_seat,pai)
			local cp_is_xiajiao= nor_ddz_ai_base_lib.check_is_xiajiao_after_cp(data,my_pai,pai.type,pai.pai,true)
			pai.tag=(pai.tag or "")..":my_pai xiao_jiao"
			if my_score > 6 then  
				if not cp_is_xiajiao then 
					goto xiajiao_end
				end
			end 

			if pai.type == 1 or pai.type ==2 then 
				local you_ha=cp_algorithm.youhua_daipai(data,my_seat,pai,true,cp_data.pai[1])
				if cp_algorithm.check_chupai_ok(data,you_ha) then 
					return you_ha
				end
			end

			if cp_algorithm.check_chupai_ok(data,pai) then 
				return pai 
			end
			::xiajiao_end::
		end
	end 



	---队友没有大于当前的牌
	if not p_list or #p_list==0 then
		if this.check_my_auxiliary(data)  then
			local song_pai=cp_algorithm.force_songpai(data,my_seat)

			if song_pai  then
				if p_pai.xiajiao>0 then
					--可以动炸弹强制上手
					result= cp_algorithm.shangshou(data,my_seat,cp_data,true,true)
				else
					--强制能上手
					result= cp_algorithm.shangshou(data,my_seat,cp_data,false,false)
				end


				if result then 
					result.tag=result.tag..":my_auxiliary shangshou song_pai"
					return result 
				end
			end
		else
			--如果敌人必赢 尽可能的占手 并且地主手数不多 尽可能的上手
			if data.boyi_max_score<0 and dz_pai.shoushu<5 then
				local _chu_pai=cp_algorithm.shangshou(data,my_seat,cp_data,false,false)
				if _chu_pai then
					return _chu_pai
				end
			else
				--上手 
				local song_pai=cp_algorithm.nor_songpai(data,my_seat)
				if song_pai then
					if p_pai.xiajiao>0 then

						--可以动炸弹强制上手
						local result=cp_algorithm.shangshou(data,my_seat,cp_data,true,true)
						if result then
							return result
						end

					elseif (p_pai.xiajiao>-3 and my_pai.xiajiao<p_pai.xiajiao) then
						--不动炸弹上手
						local result=cp_algorithm.shangshou(data,my_seat,cp_data,false,false)
						if result then
							return result
						end
					end
				end
			end
		end

		--顶牌
		if this.check_my_auxiliary(data) then
			local result = cp_algorithm.nor_dingpai(data,my_seat,cp_data)
			if result then 
				return result 
			end

			-- "不顶对面会顺过下叫"
		elseif  dz_pai.xiajiao>0 or (dz_pai.no_xiajiao_socre and dz_pai.no_xiajiao_socre>-2) then
			local result = cp_algorithm.nor_dingpai(data,my_seat,cp_data)
			if result then 
				return result 
			end

		end

	end




	--上面尝试都不行则尝试顺过
	if p_pai.xiajiao>0 or ( p_pai.no_xiajiao_socre>-2 and my_pai.no_xiajiao_socre<p_pai.no_xiajiao_socre) or this.check_my_auxiliary(data) then
		--不顶顺过
		local pai=cp_algorithm.shunguo_no_stop(data,my_seat,cp_data)
		dump(pai)

		if pai then
			return pai
		end

	if p_list and #p_list > 0  then 
			local give_up={type=0,tag=landai_util.get_traceback_info()..":give_up"}
			--尝试过
			if cp_algorithm.check_chupai_ok(data,give_up)  then 
				return give_up
			end
		end
	end


	--正常出牌 ###_test
	local pai=this.nongmin_passive_normal_cp(data)
	if pai then 
		pai.tag= (pai.tag or "") .. ":passive_normal_cp"
		--单牌对子对他们进行优化，找更小的单牌对子出
		if pai.type == 1 or pai.type ==2 then 
			local you_ha=cp_algorithm.youhua_daipai(data,my_seat,pai,true,cp_data.pai[1])
			if cp_algorithm.check_chupai_ok(data,you_ha) then 
				return you_ha
			end
		end

		if cp_algorithm.check_chupai_ok(data,pai) then 
			return pai 
		end

	end

	return pai
end



function this.nongmin_from_nm_to_nm(data)

	local my_seat=data.base_info.my_seat
	local cp_data={
		p=data.last_seat,
		type=data.last_pai.type,
		pai=data.last_pai.pai
	}

	local p_seat=ddz_tg_assist_lib.get_partner_seat(data,my_seat)

	--地主位置
	local dz_seat=data.base_info.dz_seat

	--地主牌
	local dz_pai=data.fen_pai[dz_seat]

	--队友牌
	local p_pai=data.fen_pai[p_seat]

	--自己牌
	local my_pai=data.fen_pai[my_seat]
	local give_up={type=0}


	--队友下叫了
	if p_pai.xiajiao>0 then

		--不顶顺过
		local pai=cp_algorithm.shunguo_no_stop(data,my_seat,cp_data)
		if pai then
			return pai
		end

		--尝试过
		if cp_algorithm.check_chupai_ok(data,give_up)  then 
			return give_up
		end
	end	


	--正常出牌
	if my_pai.xiajiao>0 then
		local score= ddz_tg_assist_lib.get_pai_xiajiao_score(data,my_seat,cp_data)

		if score >= 7 then 
			local pai=this.nongmin_passive_win_cp(data,false,true,true)
			if pai then 
				return pai
			end
		else 
			local pai=this.nongmin_passive_normal_cp(data,my_seat,cp_data)
			if pai then 
				return pai
			end
		end
	end


	--不顶顺过
	local pai=cp_algorithm.shunguo_no_stop(data,my_seat,cp_data)

	if pai then
		return pai
	end

	if cp_algorithm.check_chupai_ok(data,give_up) then 
		return give_up 
	end


	return nil
end


-- by lyx: 接地主牌，下家是地主
function this.nongmin_from_dz_to_dz(data)

	local my_seat = data.base_info.my_seat
	local cp = data.last_pai
	local cp_seat = data.last_seat
	local my_pai = data.fen_pai[my_seat]

	local dz_pai = data.fen_pai[data.base_info.dz_seat]

	local cp_data={
		p=data.last_seat ,
		type=data.last_pai.type,
		pai=data.last_pai.pai
	}
	--如果敌人必赢 尽可能的占手 并且地主手数不多 尽可能的上手
	if data.boyi_max_score<0 and dz_pai.shoushu<5 then
		local _chu_pai=cp_algorithm.shangshou(data,my_seat,cp_data,false)
		if _chu_pai then
			return _chu_pai
		end
	end


	local pai=cp_algorithm.nm_genpai_by_enemy_baopai(data)
	if pai then 
		return pai
	end


	--我下叫了
	if my_pai.xiajiao>0 then

		local pai = this.nongmin_passive_normal_cp(data)
		if pai then 
			return pai
		else
			return nil	
		end

	end


	if this.check_my_auxiliary(data) or dz_pai.xiajiao>0 or  dz_pai.no_xiajiao_socre>-3  or my_pai.no_xiajiao_socre<-3 then
		--顶牌
		local _chu_pai 
		local cp_score=ddz_tg_assist_lib.get_pai_score(data.query_map,data.base_info.dz_seat,cp_data.type,cp_data.pai)
		--我是辅助 地主下叫且手数不多
		if this.check_my_auxiliary(data) and dz_pai.xiajiao>0 and dz_pai.shoushu<5 then
			_chu_pai= cp_algorithm.froce_dingpai(data)
		else
			_chu_pai= cp_algorithm.nor_dingpai(data)
		end	
		if _chu_pai then
			return _chu_pai
		end
	end

	local pai = this.nongmin_passive_normal_cp(data)
	if pai then 
		return pai
	end

end

-- by lyx: 接队友的牌，下家是地主
function this.nongmin_from_nm_to_dz(data)


	local my_seat = data.base_info.my_seat
	local p_seat,is_next=ddz_tg_assist_lib.get_partner_seat(data,my_seat)

	local dz_pai = data.fen_pai[data.base_info.dz_seat]
	local cp_data = data.last_pai
	local my_pai = data.fen_pai[my_seat]
	local give_up= {type=0}

	local p_pai = data.fen_pai[data.last_seat]

	local dz_list=ddz_tg_assist_lib.get_pai_by_big_and_type(cp_data.type,dz_pai[cp_data.type],cp_data.pai)



	local pai= cp_algorithm.nm_genpai_by_enemy_baopai(data)
	if pai then 
		return pai
	end



	local cp_score=ddz_tg_assist_lib.get_pai_xiajiao_score(data,p_seat,cp_data)



	--地主无此类型的牌
	if not dz_list or #dz_list==0 then

		--不顶顺过
		local pai=cp_algorithm.shunguo_no_stop(data,my_seat,cp_data,true)

		if pai then
			if cp_algorithm.check_chupai_ok(data,pai) then 
				return pai
			end
		end


		if p_pai.abs_xiaojiao > 0 and  cp_score > 4 then 
			if cp_algorithm.check_chupai_ok(data,give_up) then 
				return give_up  
			end
		end



		pai = this.nongmin_passive_normal_cp(data)
		if pai then 
			local pai_by_score=ddz_tg_assist_lib.take_paidata_by_hash(data.boyi_map,pai) 
			local my_score=ddz_tg_assist_lib.get_pai_xiajiao_score(data,my_seat,pai)
			local cp_is_xiajiao =nil 

			if pai.type == 13 or pai.type == 14 then 
				cp_is_xiajiao= nor_ddz_ai_base_lib.check_is_xiajiao_after_cp(data,my_pai,pai.type,pai.pai,true,true)
			else 
				cp_is_xiajiao= nor_ddz_ai_base_lib.check_is_xiajiao_after_cp(data,my_pai,pai.type,pai.pai,true,false)
			end

			-- 队友出占手牌
			if ( (not pai_by_score or pai_by_score<=0) and  cp_score>=5) or  cp_score>6  then
				if cp_is_xiajiao and my_pai.shoushu<5 then 
					if cp_algorithm.check_chupai_ok(data,pai) then 
						return pai
					end
				end
				--尝试 过
				if cp_algorithm.check_chupai_ok(data,give_up) then 
					return give_up  
				end
			end

			if cp_score > 4  and my_score >6  then 
				if cp_is_xiajiao then 
					if cp_algorithm.check_chupai_ok(data,pai) then 
						return pai
					end
				end 
				--尝试 过
				if cp_algorithm.check_chupai_ok(data,give_up) then 
					return give_up  
				end
			end 
		end

		--单牌考虑 不阻碍对方最大牌 单牌都可以顺过
		if (cp_data.type == 1 and ddz_tg_assist_lib.get_key_pai(cp_data.type ,cp_data.pai) < 11) and (cp_data.type == 2 and ddz_tg_assist_lib.get_key_pai(cp_data.type ,cp_data.pai) < 11 and data.pai_re_count[data.base_info.dz_seat]>1) then 
			local pai=cp_algorithm.shunguo_no_stop(data,my_seat,cp_data,true)
			if pai then 
				return pai
			end
		end

	else
		--如果敌人必赢 尽可能的占手 并且地主手数不多 尽可能的上手
		if data.boyi_max_score<0 and dz_pai.shoushu<5  then
			local _chu_pai=cp_algorithm.shangshou(data,my_seat,cp_data,false)
			if _chu_pai then
				return _chu_pai
			end
		end
		local pai=cp_algorithm.shunguo_no_stop(data,my_seat,cp_data,true,true)
		if pai then 
			return pai
		end
	end




	-- 优化  尽可能的顶  降低自己成为辅助的条件
	local cp_score=ddz_tg_assist_lib.get_pai_score(data.query_map,my_seat,cp_data.type,cp_data.pai)
	if this.check_my_auxiliary(data) or dz_pai.xiajiao>0 or dz_pai.no_xiajiao_socre>-3 or data.boyi_max_score<0 or my_pai.no_xiajiao_socre<-3 then
		--顶牌
		local _chu_pai 
		--我是辅助 地主下叫且手数不多
		if this.check_my_auxiliary(data) and dz_pai.xiajiao>0 and dz_pai.shoushu<5 and cp_score<7 then
			_chu_pai= cp_algorithm.froce_dingpai(data)
		else
			_chu_pai= cp_algorithm.nor_dingpai(data)
		end	

		if _chu_pai then
			if cp_algorithm.check_chupai_ok(data,_chu_pai) then 
				return _chu_pai
			end
		end
		--顶失败 尝试过
		local _guo = {type=0}
		if cp_algorithm.check_chupai_ok(data,_guo) then 
			return _guo
		end
	end


	local pai = this.nongmin_passive_normal_cp(data)

	if pai then 
		local pai_by_score=ddz_tg_assist_lib.take_paidata_by_hash(data.boyi_map,pai) 
		local my_score=ddz_tg_assist_lib.get_pai_xiajiao_score(data,my_seat,pai)
		local cp_is_xiajiao 
		if pai.type == 13 or pai.type == 14 then 
			cp_is_xiajiao= nor_ddz_ai_base_lib.check_is_xiajiao_after_cp(data,my_pai,pai.type,pai.pai,true,true)
		else 
			cp_is_xiajiao= nor_ddz_ai_base_lib.check_is_xiajiao_after_cp(data,my_pai,pai.type,pai.pai,true,false)
		end

		-- 队友出占手牌
		if ( (not pai_by_score or pai_by_score<=0) and  cp_score>=5) or  cp_score>6  then
			if cp_is_xiajiao and my_pai.shoushu<5 then 
				if cp_algorithm.check_chupai_ok(data,pai) then 
					return pai
				end
			end
			--尝试 过
			if cp_algorithm.check_chupai_ok(data,give_up) then 
				return give_up  
			end
		end

		if cp_score > 4  and my_score >6  then 
			if cp_is_xiajiao then 
				if cp_algorithm.check_chupai_ok(data,pai) then 
					return pai
				end
			end 
			--尝试 过
			if cp_algorithm.check_chupai_ok(data,give_up) then 
				return give_up  
			end
		end 
	end

	if pai then 
		pai.tag = (pai.tag or "")..":normal"
		return pai
	end

	return nil
end



function this.nongmin_chupai(first_play,data)
	local my_seat= data.base_info.my_seat


	if not data.boyi_map then 
		if first_play then 
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


	local p_seat,is_next=ddz_tg_assist_lib.get_partner_seat(data,data.base_info.my_seat)
	ddz_tg_assist_lib.get_fuzhu_info(data,data.base_info.my_seat,p_seat)


	local result 
	if first_play then 
		result = this.nongmin_initiative_cp(data)
	else 
		result = this.nongmin_passive_cp(data)
	end


	if not result then 
		return {type = 0}
	end


	local you_ha=cp_algorithm.youhua_daipai(data,my_seat,result,first_play)
	--dump(you_ha)
	if cp_algorithm.check_chupai_ok(data,you_ha) then 
		result=you_ha
	else 
		if not cp_algorithm.check_chupai_ok(data,result) then 
			result=you_ha
		end
	end

	return result 

end



--
--正常被动 
--检查辅助
--上手
--







return this 
