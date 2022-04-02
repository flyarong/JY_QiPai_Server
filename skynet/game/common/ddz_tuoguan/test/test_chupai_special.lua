package.cpath = "../../luaclib/?.so;"..package.cpath

local basefunc= require "basefunc"
local dz_chupai=require "ddz_tuoguan.dz_chupai"
local nm_chupai=require "ddz_tuoguan.nm_chupai"
local landai_util=require "ddz_tuoguan.landai_util"
local cp_algorithm=require "ddz_tuoguan.ddz_tuoguan_cp_algorithm"
local ddz_tg_assist_lib= require "ddz_tuoguan.ddz_tg_assist_lib"
local nor_ddz_base_lib=require "nor_ddz_base_lib"
require "printfunc"




--[[
local data={
	base_info={dz_seat=1,my_seat=1,seat_count=3,seat_type={[1]=1,[2]=0,[3]=0,},},
	firstplay=false,game_over_cfg={[1]=0,[2]=0,[3]=0,},
	last_pai={pai={[1]=10,},type=1,},
	last_seat=3,
	pai_map={
		[1]="Ww22AAKKQQT99987765",
		[2]="22KQJT88765443",
		[3]="22AAKQJT98544",
	},
}
--]]


-- from dz_to_nm 我下叫了
local data={
	base_info={dz_seat=1,my_seat=2,seat_count=3,seat_type={[1]=1,[2]=0,[3]=0,},},
	firstplay=false,game_over_cfg={[1]=0,[2]=0,[3]=0,},
	last_pai={pai={[1]=10,},type=1,},
	last_seat=1,
	pai_map={
		[1]="22AAKKQQT99987765",
		[2]="w22KQJT98876543",
		[3]="22AAKQJT98544",
	},
}

-- from dz_to_nm  我没下叫，对友有大于当前的牌
local data={
	base_info={dz_seat=1,my_seat=2,seat_count=3,seat_type={[1]=1,[2]=0,[3]=0,},},
	firstplay=false,game_over_cfg={[1]=0,[2]=0,[3]=0,},
	last_pai={pai={[1]=13,},type=1,},
	last_seat=1,
	pai_map={
		[1]="AAKKQQ99987765",
		[2]="w22KQJ9887655543",
		[3]="AQJT986663",
	},
}

-- from dz_to_nm  我没下叫，对友有大于当前的牌,我不顶顺过 ((FIXED),该情况可以出KQJ，但并没出)
local data={
	base_info={dz_seat=1,my_seat=2,seat_count=3,seat_type={[1]=1,[2]=0,[3]=0,},},
	firstplay=false,game_over_cfg={[1]=0,[2]=0,[3]=0,},
	last_pai={pai={[1]=10,},type=1,},
	last_seat=1,
	pai_map={
		[1]="AAKKQQ99987765",
		[2]="w22KQJ9887655543",
		[3]="AQJT986663",
	},
}


-- from dz_to_nm 我没下叫了，对友没有大于当前牌型的牌
local data={
	base_info={dz_seat=1,my_seat=2,seat_count=3,seat_type={[1]=1,[2]=0,[3]=0,},},
	firstplay=false,game_over_cfg={[1]=0,[2]=0,[3]=0,},
	last_pai={pai={[1]=13,},type=2,},
	last_seat=1,
	pai_map={
		[1]="AAKKQQ99987765",
		[2]="w22KQJ9887655543",
		[3]="AKQJT986663",
	},
}

-- from_dz_to_nm 对友没有大于当前牌型的牌，我是辅助
local data={
	base_info={dz_seat=1,my_seat=2,seat_count=3,seat_type={[1]=1,[2]=0,[3]=0,},},
	firstplay=false,game_over_cfg={[1]=0,[2]=0,[3]=0,},
	last_pai={pai={[1]=13,},type=2,},
	last_seat=1,
	pai_map={
		[1]="AAKKQQ99987765",
		[2]="22 KQJ986543",
		[3]="A QJT986663",
	},
}

-- from_dz_to_nm 对友没有大于当前牌型的牌，我是辅助，炸弹强制上手(NEED_FIXBUG,炸弹被分到4带2中去了)
local data={
	base_info={dz_seat=1,my_seat=2,seat_count=3,seat_type={[1]=1,[2]=0,[3]=0,},},
	firstplay=false,game_over_cfg={[1]=0,[2]=0,[3]=0,},
	last_pai={pai={[1]=13,},type=2,},
	last_seat=1,
	pai_map={
		[1]="AAKKQQ99987765",
		[2]="22 KQJ 98 654 3333",
		[3]="A QJT98 6663",
	},
}

-- from_dz_to_nm 对友没有大于当前牌型的牌，我是辅助，可以强制送牌
local data={
	base_info={dz_seat=1,my_seat=2,seat_count=3,seat_type={[1]=1,[2]=0,[3]=0,},},
	firstplay=false,game_over_cfg={[1]=0,[2]=0,[3]=0,},
	last_pai={pai={[1]=13,},type=2,},
	last_seat=1,
	pai_map={
		[1]="AAKKQQ99987765",
		[2]="22 KQJ87654433",
		[3]="A QJT986663",
	},
}


-- from_nm_to_dz 地主有大于此类型的牌,我没下叫
local data={
	base_info={dz_seat=1,my_seat=3,seat_count=3,seat_type={[1]=1,[2]=0,[3]=0,},},
	firstplay=false,game_over_cfg={[1]=0,[2]=0,[3]=0,},
	last_pai={pai={[1]=10,},type=2,},
	last_seat=2,
	pai_map={
		[1]="AAKKQ99987765",
		[2]="22QJT986663",
		[3]="KK4433",
	},
}


-- from_nm_to_dz 地主有大于此类型的牌,我下叫了 
local data={
	base_info={dz_seat=1,my_seat=3,seat_count=3,seat_type={[1]=1,[2]=0,[3]=0,},},
	firstplay=false,game_over_cfg={[1]=0,[2]=0,[3]=0,},
	last_pai={pai={[1]=10,},type=2,},
	last_seat=2,
	pai_map={
		[1]="AAKKQ99987765",
		[2]="22QJT986663",
		[3]="KKW",
	},
}

-- from_nm_to_dz 地主没有大于此类型的牌,我不顶顺过
local data={
	base_info={dz_seat=1,my_seat=3,seat_count=3,seat_type={[1]=1,[2]=0,[3]=0,},},
	firstplay=false,game_over_cfg={[1]=0,[2]=0,[3]=0,},
	last_pai={pai={[1]=10,},type=2,},
	last_seat=2,
	pai_map={
		[1]="AAKKQQ99987765",
		[2]="22QJT986663",
		[3]="KKW",
	},
}

-- from_nm_to_dz 地主没有大于此类型的牌,对友下叫了，我下叫了
local data={
	base_info={dz_seat=1,my_seat=3,seat_count=3,seat_type={[1]=1,[2]=0,[3]=0,},},
	firstplay=false,game_over_cfg={[1]=0,[2]=0,[3]=0,},
	last_pai={pai={[1]=10,},type=2,},
	last_seat=2,
	pai_map={
		[1]="AAKKQQ99987765",
		[2]="22KKQJT986663",
		[3]="KKW",
	},
}

-- from_nm_to_dz 地主没有大于此类型的牌,对友没下叫了，我下叫了
local data={
	base_info={dz_seat=1,my_seat=3,seat_count=3,seat_type={[1]=1,[2]=0,[3]=0,},},
	firstplay=false,game_over_cfg={[1]=0,[2]=0,[3]=0,},
	last_pai={pai={[1]=10,},type=2,},
	last_seat=2,
	pai_map={
		[1]="AAKKQQ99987765",
		[2]="22KKQJ986663",
		[3]="KKW",
	},
}

-- from_nm_to_nm 队友下叫了 
local data={
	base_info={dz_seat=1,my_seat=2,seat_count=3,seat_type={[1]=1,[2]=0,[3]=0,},},
	firstplay=false,game_over_cfg={[1]=0,[2]=0,[3]=0,},
	last_pai={pai={[1]=10,},type=2,},
	last_seat=3,
	pai_map={
		[1]="AAKKQQ99987765",
		[2]="KKW",
		[3]="22KKQJT986663",
	},
}

-- from_nm_to_nm 队友没下叫了，我下叫了 
local data={
	base_info={dz_seat=1,my_seat=2,seat_count=3,seat_type={[1]=1,[2]=0,[3]=0,},},
	firstplay=false,game_over_cfg={[1]=0,[2]=0,[3]=0,},
	last_pai={pai={[1]=10,},type=2,},
	last_seat=3,
	pai_map={
		[1]="AAKKQQ99987765",
		[2]="KKW",
		[3]="22KKQJ986663",
	},
}

-- from_nm_to_nm 队友没下叫了，我下叫了,队友是占手牌 
local data={
	base_info={dz_seat=1,my_seat=2,seat_count=3,seat_type={[1]=1,[2]=0,[3]=0,},},
	firstplay=false,game_over_cfg={[1]=0,[2]=0,[3]=0,},
	last_pai={pai={[1]=15,},type=2,},
	last_seat=3,
	pai_map={
		[1]="AAKKQQ99987765",
		[2]="TTTTW",
		[3]="22KKQJ986663",
	},
}


-- from_nm_to_nm 队友没下叫了，我没下叫,队有是非占手牌 
local data={
	base_info={dz_seat=1,my_seat=2,seat_count=3,seat_type={[1]=1,[2]=0,[3]=0,},},
	firstplay=false,game_over_cfg={[1]=0,[2]=0,[3]=0,},
	last_pai={pai={[1]=10,},type=2,},
	last_seat=3,
	pai_map={
		[1]="AAKKQQ99987765",
		[2]="QQW345",
		[3]="22KKQJ986663",
	},
}

-- from_nm_to_nm 队友没下叫了，我没下叫,队有是非占手牌 
local data={
	base_info={dz_seat=1,my_seat=2,seat_count=3,seat_type={[1]=1,[2]=0,[3]=0,},},
	firstplay=false,game_over_cfg={[1]=0,[2]=0,[3]=0,},
	last_pai={pai={[1]=10,},type=2,},
	last_seat=3,
	pai_map={
		[1]="AAKKQQ99987765",
		[2]="KKW345",
		[3]="22KKQJ986663",
	},
}


-- from_dz_to_dz  我下叫了
local data={
	base_info={dz_seat=1,my_seat=3,seat_count=3,seat_type={[1]=1,[2]=0,[3]=0,},},
	firstplay=false,game_over_cfg={[1]=0,[2]=0,[3]=0,},
	last_pai={pai={[1]=10,},type=2,},
	last_seat=1,
	pai_map={
		[1]="AAKKQQ99987765",
		[2]="KKW345",
		[3]="22KKQJT986663",
	},
}



-- from_dz_to_dz  我没下叫
local data={
	base_info={dz_seat=1,my_seat=3,seat_count=3,seat_type={[1]=1,[2]=0,[3]=0,},},
	firstplay=false,game_over_cfg={[1]=0,[2]=0,[3]=0,},
	last_pai={pai={[1]=10,},type=2,},
	last_seat=1,
	pai_map={
		[1]="AAKK98765",
		[2]="KKW3",
		[3]="AAQQJ986663",
	},
}




for k,v in ipairs(data.pai_map) do 
	data.pai_map[k]= landai_util.cards2pai(landai_util.ss2cards(v))
end

ddz_tg_assist_lib.set_game_type("nor")

data.kaiguan = ddz_tg_assist_lib.data_ddz_cfg.kaiguan
--dump(data.kaiguan)








for i =1,1 do 

	cp_algorithm.fenpai_for_all(data)

	for k,v in ipairs(data.fen_pai) do 
		v.abs_xiaojiao=ddz_tg_assist_lib.check_is_xiajiao_absolute(v,k,data.query_map)
	end


	dump(data.fen_pai)



	data.pai_count=data.query_map.seat_card_nu

	local is_firstplay=data.firstplay 

	if is_firstplay then 
		local boyi_map,boyi_list=ddz_tg_assist_lib.get_cp_value_map(data,data.base_info.my_seat,nil)
		data.boyi_map=boyi_map 
		data.boyi_list=boyi_list

	else 

		local boyi_map,boyi_list=ddz_tg_assist_lib.get_cp_value_map(data,data.base_info.my_seat,{
			p=data.last_seat ,
			type=data.last_pai.type,
			pai=data.last_pai.pai
		})

		data.boyi_map=boyi_map 
		data.boyi_list=boyi_list
	end


	data.boyi_max_score,data.boyi_min_score=ddz_tg_assist_lib.get_best_cp_score(data.boyi_list)
	dump(data.boyi_list,"bossssssssssssssssssss")
	--  ###_test by hewei
	local maxxx=1000

	local boyi_list_total=#data.boyi_list

	local boyi_list_win=0 
	local boyi_list_lose=0 
	local boyi_list_unkown=0 



	for k,v in ipairs(data.boyi_list) do
		if v.score<=maxxx then
			maxxx= v.score
		else
			dump(data.boyi_list)
			error("sort error !!!!!")
		end
		if v.score > 0 then 
			boyi_list_win= boyi_list_win +1 

		elseif v.score ==0 then 
			boyi_list_unkown= boyi_list_unkown+1 
		elseif v.score <0 then 
			boyi_list_lose = boyi_list_lose + 1
		end
	end

	data.boyi_list_total = boyi_list_total 
	data.boyi_list_win= boyi_list_win 
	data.boyi_list_lose= boyi_list_lose
	data.boyi_list_unkown= boyi_list_unkown

	local _chu_pai
	if data.base_info.dz_seat==data.base_info.my_seat  then 
		_chu_pai = dz_chupai.dizhu_chupai(is_firstplay,data)
	else 
		_chu_pai = nm_chupai.nongmin_chupai(is_firstplay,data)
	end

	dump(_chu_pai,"chu_pai")

	cp_type=_chu_pai.type 
	--cp_list= nor_ddz_base_lib.get_pai_list_by_data( data.origin_seat_cards[data.base_info.my_seat], _chu_pai.type, _chu_pai.pai)




end

print(os.time())

