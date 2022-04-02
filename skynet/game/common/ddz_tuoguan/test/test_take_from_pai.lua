local dz_chupai=require "ddz_tuoguan.dz_chupai"
local landai_util=require "ddz_tuoguan.landai_util"
local cp_algorithm=require "ddz_tuoguan.ddz_tuoguan_cp_algorithm"
local ddz_tg_assist_lib= require "ddz_tuoguan.ddz_tg_assist_lib"
require "printfunc"





local pai_map={

	[1]={12,11,9},
	[2]={13,10},
	[3]={14,8},
	[4]={{10,3}},         --三带1 
	[5]={{12,13}},		 --三带2
	[6]={{8,12},{3,7}},  --顺子
	[7]={{8,10},{3,7}},  --连对
	[8]={{12,3}},        --四带2单
	[9]={{13,3}},        --四带2双


	[10]={{8,10,3,4,13}}, --飞机带单
	[11]={{9,11,3,13,5}}, --飞机带双
	[12]={{9,11}},        --飞机
	[13]={13}             --炸弹
}



local result =dz_chupai.get_bigger_danpai(pai_map,8)

table.sort(result,function(l,r)
	return ddz_tg_assist_lib.get_key_pai(l.take.type,l.take.data) > ddz_tg_assist_lib.get_key_pai(r.take.type,r.take.data)
end)

dump(result)


