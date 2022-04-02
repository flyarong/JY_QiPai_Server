-- Author: cl
-- Date: 2019/3/11
-- Time: 13:45
-- 说明：所有设计到的常量
local landai_enum={}

landai_enum.cardtypes={12,7,6,13,14,3,2,1}
require "printfunc"



landai_enum.s2cardtype={

	["ST"]=12,    -- 飞机
	["SP"]=7,    -- 连子
	["SS"]=6,    -- 顺子

	["BOMB"]=13,  -- 炸弹
	["ROCKET"]=14, --王炸
	["THREE"]=3, -- 三张
	["PAIR"]= 2,  -- 对子
	["SINGLE"]=1 -- 

}

landai_enum.cardtype2s={
	[12]="ST",
	[7]="SP",
	[6]="SS",
	[13]="BOMB",
	[3]="THREE",
	[2]="PAIR",
	[1]="SINGLE",
	[14]="ROCKET",
}

landai_enum.cardtype2short={
	[12]="ST",
	[7]="SP",
	[6]="SS",
	[13]="B",
	[3]="T",
	[2]="P",
	[1]="S",
	[14]="R",
}

landai_enum.serial_info={
	[12]={min=2,max=6},
	[7]={min=3,max=10},
	[6]={min=5,max=12},
}






landai_enum.faces={ 3,4,5,6,7,8,9,10,11,12,13,14,15,16,17 }
landai_enum.faces_no2w={ 3,4,5,6,7,8,9,10,11,12,13,14}
landai_enum.faces_now={ 3,4,5,6,7,8,9,10,11,12,13,14,15}

landai_enum.face2s={
	[3]="3",
	[4]="4",
	[5]="5",
	[6]="6",
	[7]="7",
	[8]="8",
	[9]="9",
	[10]="T",
	[11]="J",
	[12]="Q",
	[13]="K",
	[14]="A",
	[15]="2",
	[16]="w",
	[17]="W",
}

landai_enum.s2face={
	["3"]=3,
	["4"]=4,
	["5"]=5,
	["6"]=6,
	["7"]=7,
	["8"]=8,
	["9"]=9,
	["T"]=10,
	["J"]=11,
	["Q"]=12,
	["K"]=13,
	["A"]=14,
	["2"]=15,
	["w"]=16,
	["W"]=17,
}





local allcardtypes={}

local all_serial_type={}
local all_type={}

for _,t in ipairs(landai_enum.cardtypes) do 



	if t==landai_enum.s2cardtype.ST then 
		allcardtypes[t]={}

		for i = 2,6 do 
			for _,f in ipairs(landai_enum.faces_no2w) do 
				if f-i+1 >=landai_enum.s2face["3"] then 
					if not allcardtypes[t][i] then 
						allcardtypes[t][i]={}
					end
					table.insert(allcardtypes[t][i],f)
					table.insert(all_type,{t=t,s=i,f=f})
					table.insert(all_serial_type,{t=t,s=i,f=f})
				end
			end
		end

	elseif t==landai_enum.s2cardtype.SP then 
		allcardtypes[t]={}
		for i = 3,10 do 
			for _,f in ipairs(landai_enum.faces_no2w) do 
				if f-i+1 >=landai_enum.s2face["3"] then 
					if not allcardtypes[t][i] then 
						allcardtypes[t][i]={}
					end
					table.insert(allcardtypes[t][i],f)
					table.insert(all_type,{t=t,s=i,f=f})
					table.insert(all_serial_type,{t=t,s=i,f=f})
				end
			end
		end
	elseif t==landai_enum.s2cardtype.SS then 
		allcardtypes[t]={}
		for i = 5,12 do 
			for _,f in ipairs(landai_enum.faces_no2w) do 
				if f-i+1 >=landai_enum.s2face["3"] then 
					if not allcardtypes[t][i] then 
						allcardtypes[t][i]={}
					end
					table.insert(allcardtypes[t][i],f)
					table.insert(all_type,{t=t,s=i,f=f})
					table.insert(all_serial_type,{t=t,s=i,f=f})
				end
			end
		end

	elseif t==landai_enum.s2cardtype.ROCKET then 
		allcardtypes[t]=true
		table.insert(all_type,{t=t})

	elseif t==landai_enum.s2cardtype.SINGLE then 
		allcardtypes[t]={}
		for _,f in ipairs(landai_enum.faces)  do 
			table.insert(allcardtypes[t],f)
			table.insert(all_type,{t=t,f=f})
		end
	else 
		allcardtypes[t]={}
		for _,f in ipairs(landai_enum.faces_now)  do 
			table.insert(allcardtypes[t],f)
			table.insert(all_type,{t=t,f=f})
		end
	end

end

allcardtypes["all"]=all_type
allcardtypes["all_serial"]=all_serial_type

landai_enum.allcardtypes=allcardtypes


return landai_enum

