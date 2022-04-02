

local er_mj_hupai_ctrl_lib={}

--###_test  还没有配置
local er_7_hupai_cfg={}

 

function er_mj_hupai_ctrl_lib.get_er_7_hupai_by_fan(fan)
	if er_7_hupai_cfg[fan] then
		local len=#er_7_hupai_cfg[fan]
		return er_7_hupai_cfg[fan][math.random(1,len)]
	end
end

--[[
	key :pos 位置
	value: fan   0 不用管  -1 无法胡

--]]
local ermj7_r_step_min=6
local ermj7_r_step_max=15
function er_mj_hupai_ctrl_lib.get_er_7_hupai_data(pos_info)
	if pos_info then
		local data={}
		data.hp_type={}
		data.hp_pai_step_num={}
		data.hupai={}
		for pos,v in ipairs(pos_info) do
			if v>0 then
				local pai=get_er_7_hupai_by_fan(v)
				local hupai_pos=math.random(1,#pai)
				local hupai=pai[hupai_pos]
				pai[hupai_pos]=nil
				for k,v in pairs(pai) do
					data.hp_type[pos][#data.hp_type[pos]+1]=v
				end
				data.hupai[pos]=hupai
				data.hp_pai_step_num[pos]=math.random(ermj7_r_step_min,ermj7_r_step_max)
			elseif v==0 then
				data.hp_pai_step_num[pos]=v
			elseif v==-1 then
				data.hp_pai_step_num[pos]=-1
			end
		end
		return data
	end
	return nil

end
	












