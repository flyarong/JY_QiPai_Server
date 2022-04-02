local ddz_tuoguan=require "landai.ddz_tuoguan"


local result=ddz_tuoguan.do_split_card({
	pai_map={
		[1]={[4]=3,[6]=1},
		[2]={[10]=3,[8]=1},
		[3]={[9]=3,[12]=1}
	},
	dz_seat=1,
	base_info={
		seat_count=3
	}

})

print(os.time())

local score,biggest=ddz_tuoguan.get_pai_score(result,2,3,{[1]=3,[2]=8})


print(os.time())


print("score", score,biggest)









