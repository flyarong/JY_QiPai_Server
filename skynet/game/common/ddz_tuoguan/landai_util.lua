-- Author: cl
-- Date: 2019/3/11
-- Time: 13:45
-- 说明：简单性的辅助性函数
--

local basefunc =require "basefunc"
local landai_enum=require "ddz_tuoguan.landai_enum"
local landai_util={}
local nor_ddz_base_lib=require "nor_ddz_base_lib"



function landai_util.get_traceback_info()
    local trace_info= debug.getinfo(2)

	return string.format("%s:%d:%s",basefunc.path.name(trace_info.source) , trace_info.currentline,trace_info.name)

end

function landai_util.map(t,f)
	local ret={}
	for k,v in pairs(t) do 
		local rk,rv=f(k,v)
		ret[rk]=rv
	end
	return ret
end

function landai_util.tablefv(t,func)
	local ret={}

	for k,v in pairs(t) do 
		table.insert(ret,func(k,v))
	end

	return ret

end

function landai_util.pai_map2ss(pai)

	local ss_p= landai_util.pai2cards(pai)
	landai_util.sortcards(ss_p)

	local ss_cards=landai_util.cards2ss(ss_p)

	return ss_cards

end

function landai_util.sortcards(v)
	table.sort(v,function(l,r) 
		return l> r 

	end)
	return v
end


function landai_util.sortscards(v)
	table.sort(v,function(l,r) 
		return landai_enum.s2face[l]>landai_enum.s2face[r]
	end)
	return v 
end

function landai_util.pai2cards(pai)
	local cards={}
	for k,v in pairs(pai) do 
		for i=1,v do 
			table.insert(cards,k)
		end
	end

	return cards 
end



function landai_util.s2cards(t)
	local ret={}
	for k,v in ipairs(t) do 
		table.insert(ret,landai_enum.s2face[v])
	end
	return ret
end

function landai_util.cards2ss(cards)
	local ret = {}
	for k,v in ipairs(cards) do 
		table.insert(ret,landai_enum.face2s[v])
	end
	return table.concat(ret,"")
end

function landai_util.ss2cards(t)
	local ret={}
	local len=string.len(t)
	for i=1 ,len do 
		local c=string.sub(t,i,i)
		if landai_enum.s2face[c] then 
			table.insert(ret,landai_enum.s2face[c])
		end
	end
	return ret
end



function landai_util.cards2pai(cards)
	local ret = {}
	for k,v in ipairs(cards) do 
		local old_value=ret[v] or 0 
		ret[v]=old_value +1 
	end
	return ret
end

function landai_util.idcards2pai(idcards)
	local ret ={}
	for k,v in pairs(idcards) do 
		local face = nor_ddz_base_lib.pai_map[k] 

		if not ret[face] then 
			ret[face]=0 
		end
		ret[face] = ret[face] + 1
	end
	return ret

end






function landai_util.pai2ss(pai)

	local name_map={
		[1]="dan_pai",
		[2]="dui_zhi",
		[3]="shan_zhang",
		[4]="shan_zhang1",
		[5]="shan_zhang2",
		[6]="shui_zhi",
		[7]="lian_dui",
		[8]="BS",
		[9]="BP",
		[10]="feiji_1",
		[11]="feiji_2",
		[12]="feiji",
		[13]="zha_dan", 
		[14]="wan_zhan",
		["dai_danpai"]="dai_danpai",
		["dai_duizi"]="dai_duizi"
	}

	local s_map={
		[6]=true,
		[7]=true,
		[12]=true
	}

	local st_12map={
		[4]=true,
		[5]=true,
	}



	local ret=landai_util.map(pai,function(k,v)
		if k == 14 then 
			return "wan_zha","TRUE"
		end
		if not s_map[k] and not st_12map[k] then 
			local rv=table.concat(landai_util.map(v,function(t,f)
				return t,tostring(landai_enum.face2s[f] or "*"..f )
			end),",")

			return name_map[k],rv
		elseif st_12map[k] then 
			local rv=table.concat(landai_util.map(v,function(t,f)
				return t,string.format("%s+%s",landai_enum.face2s[f[1]],landai_enum.face2s[f[2]])
			end),",")

			return name_map[k],rv
		else 
			local rv=table.concat(landai_util.map(v,function(t,f)
				return t,string.format("%s-%s",landai_enum.face2s[f[2]],landai_enum.face2s[f[1]])
			end),",")

			return name_map[k],rv

		end
	end)

	local ret =landai_util.tablefv(ret,function(k,v)
		return string.format("%s-{%s}",k,v)
	end)

	return table.concat(ret,"\n")
end



-- value to face and suit 
function landai_util.v2fu(value)

end



function landai_util.fu2v(face,suit)

end



return landai_util 
