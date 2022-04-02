local ddz_tuoguan=require "landai.nor_ddz_ai_base_lib"
local landai_util=require "landai.landai_util"
require "printfunc"

math.randomseed(os.time())

local pai_data={
	{
		pai={ 
			[2]={3,4,5} 
		},
		remove_nu=2,
	},
	{
		pai={ 
			[2]={3,4,5} 
		},
		remove_nu=3,
	},
	{
		pai={ 
			[2]={3,4,5} 
		},
		remove_nu=1,
	},
	{
		pai={ 
			[2]={3,4,5} 
		},
		remove_nu=5,
	},

}


--[[
for k,v in ipairs(pai_data) do 
	print("=================================")
	dump(v.pai,"origin pai")
	local ret=ddz_tuoguan.remove_duizhi(v.pai,v.remove_nu)
	dump(ret,"result")
	dump(v.pai,"remove_pai")
end
--]]



pai_data={
	{
		pai={ 
			[2]={3,4,5} 
		},
		remove_nu=2,
	},
	{
		pai={ 
			[2]={3,4,5} 
		},
		remove_nu=1,
	},
	{
		pai={ 
			[1]={6,7,8},
			[2]={3,4,5} 
		},
		remove_nu=3,
	},
	{
		pai={ 
			[1]={6,7,8},
			[2]={3,4,5} 
		},
		remove_nu=4,
	},
	{
		pai={ 
			[1]={6,7,8},
			[2]={3,4,5} 
		},
		remove_nu=20,
	},
}


for k,v in ipairs(pai_data) do 
	print("=================================")
	dump(v.pai,"origin pai")
	local ret=ddz_tuoguan.remove_daipai(v.pai,v.remove_nu)
	dump(ret,"result")
	dump(v.pai,"remove_pai")
end

