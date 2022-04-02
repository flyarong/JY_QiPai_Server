 package.path=package.path..";/Users/hewei/project/JyQipai_server/skynet/game/common/?.lua"

local PROTECT={}


function PROTECT.choose_bodong_type(_seat_num,data,gailv,random_wave_js_limit)
	if data and data.all_times and data.all_times==data.cur_times then

		data.dispirited_count=data.dispirited_count or 0

		if data.bd_type==1 then
			--沮丧次数   一次正弦波动算一次沮丧
			data.dispirited_count=data.dispirited_count+1
		elseif data.bd_type==2 and data.bd_factor  and data.bd_factor<0 then
			data.dispirited_count=data.dispirited_count+1
		end

		if random_wave_js_limit and data.dispirited_count>random_wave_js_limit then  
			data.dispirited_count=0
			return 1
		else
			return 2
		end
		
		return 1
	end
	return 1
end

function PROTECT.get_bodong(_seat_num,data,gailv,cfg,profit_cfg,bd_cfg,random_bd_cfg)
	if data and data.all_times and data.all_times==data.cur_times then
		data.bd_type=PROTECT.choose_bodong_type(_seat_num,data,gailv,profit_cfg.random_wave_js_limit)
		data.all_times=nil
	end
	--普通正弦或余弦波动
	if not data or not data.bd_type or data.bd_type==1 then
		return PROTECT.get_nor_bdGl(_seat_num,data,gailv,bd_cfg)
	--普通骰子型波动
	elseif data.bd_type==2 then
		return PROTECT.get_random_bdGl(_seat_num,data,gailv,random_bd_cfg)
	end
end
--[[
	--波动相关数据
		all_times   --总次数
		cur_times   --当前次数
		store_value --被存储下的值
		is_zheng    --当前波动是正还是负值
		bd_factor	--当前的波动系数

--]]
function PROTECT.get_nor_bdGl(_seat_num,data,gailv,cfg)
	if not data.all_times or data.all_times==data.cur_times then
		data.all_times=math.random(cfg.min_times,cfg.max_times)
		data.cur_times=1
		data.store_value=0
		data.bd_factor=math.random(cfg.min_bodong_value*10000,cfg.max_bodong_value*10000)/10000
		-- ***************
		local is_zheng
		if not data.bd_type or data.bd_type==1 then
			is_zheng=1
		else
			is_zheng=math.random(1,2)   --随机 正弦和余弦
			if is_zheng==2 then
				is_zheng=-1
			end
		end
		-- ***************
		data.bd_factor=data.bd_factor*is_zheng
		-- if _seat_num==1 then
		-- 	print("normal波动",data.all_times,data.bd_factor)
		-- end
	end
	--当前阶段   1，2
	local cur_stage=1
	if data.cur_times>math.floor(data.all_times/2) then
		cur_stage=2
	end
	local gl
	if cur_stage==1 then
		gl=gailv+gailv*data.bd_factor
		data.store_value=data.store_value+gl-gailv
	else
		local bd_factor=(data.store_value)/(data.all_times-data.cur_times)
		data.store_value=data.store_value-bd_factor
		gl=gailv-bd_factor
	end
	data.cur_times=data.cur_times+1


	-- if _seat_num==1 then
	-- 	print("normal ",gl)
	-- end
	return gl
end

--[[
	--波动相关数据
		all_times   --总次数
		cur_times   --当前次数
		store_value --被存储下的值
		is_zheng    --当前波动是正还是负值
		bd_factor	--当前的波动系数

--]]

function PROTECT.get_random_bdGl(_seat_num,data,gailv,random_bd_cfg)
	if not data.all_times or data.all_times==data.cur_times then

		data.all_times=0
		local rd=math.random(1,100)
		for k,v in ipairs(random_bd_cfg) do
			if rd<=v.change_times_power  then
				data.all_times=v.change_times
				break
			end
			rd=rd-v.change_times_power
		end

		data.bd_factor=0
		rd=math.random(1,100)
		for k,v in ipairs(random_bd_cfg) do
			if rd<=v.bd_power  then
				data.bd_factor=v.bd_factor
				break
			end
			rd=rd-v.bd_power
		end

		data.cur_times=1
		data.store_value=0
		
		local is_zheng=math.random(1,2)
		if is_zheng==2 then
			is_zheng=-1
		else
			data.dispirited_count=0
		end
		data.bd_factor=data.bd_factor*is_zheng

		-- ###_test **********
		-- if _seat_num==1 then
		-- 	if is_zheng==1 then
		-- 		print("波动为正",data.all_times,data.bd_factor)
		-- 	else
		-- 		print("波动为负",data.all_times,data.bd_factor)
		-- 	end
		-- end

	end

	local gl=gailv+gailv*data.bd_factor
	data.cur_times=data.cur_times+1
	-- if _seat_num==1 and data.cur_times%20==0 then
	-- 	print("data.cur_times ",data.cur_times)
	-- end
	-- if _seat_num==1 then
	-- 	print("random ",gl)
	-- end
	return gl
end
--[[
		all_times   --总次数
		cur_times   --当前次数
		store_value --被存储下的值
		is_zheng    --当前波动是正还是负值
		bd_factor	--当前的波动系数
--]]
function PROTECT.get_real_gl(_seat_num,profit_cfg,is_not_bodong,bd_data,bd_cfg,random_bd_cfg)
	local tichu_gl={}
	--利润
	tichu_gl[1]=profit_cfg.tax or 0
	--存储奖励
	tichu_gl[2]=profit_cfg.storage or 0

	-- dump(tichu_gl)
	-- dump(profit_cfg)
	local gailv=1
	for k,v in ipairs(tichu_gl) do
		gailv=gailv-v
	end


	if not is_not_bodong then
		return PROTECT.get_bodong(_seat_num,bd_data,gailv,cfg,profit_cfg,bd_cfg,random_bd_cfg)
	end
	return gailv
end





--test ********************************************************
	-- math.randomseed(os.time()*72453) 
	-- local bd_cfg={
	-- 	min_times=70,
	-- 	max_times=170,
	-- 	min_bodong_value=0.05,
	-- 	max_bodong_value=0.12,	
	-- }

	-- local profit_cfg={
	-- 	tax=0.0025,
	-- 	storage=0.03,
	-- }
	-- local bd_data={}
	-- local money=0
	-- local times=5000000
	-- local yu={}
	-- yu[1]={
	-- 	{0.2,5},
	-- 	{0.5,2},
	-- 	{0.1,10},
	-- }
	-- yu[2]={
	-- 	{0.2,5},
	-- 	{0.5,2},
	-- 	{0.1,10},
	-- 	{0.5,2},
	-- 	{0.125,8}
	-- }
	-- yu[3]={
	-- 	{0.2,5},
	-- 	{0.5,2},
	-- 	{0.1,10},
	-- 	{0.5,2},
	-- }
	-- yu[4]={
	-- 	{0.2,5},
	-- }
	-- yu[5]={
	-- 	{0.2,5},
	-- 	{1,1},
	-- }
	-- for i=1,times do 
	-- 	local gl=PROTECT.get_real_gl(profit_cfg,false,bd_data,bd_cfg)
	-- 	local pos=math.random(1,5)
	-- 	gl=gl/(#yu[pos])
	-- 	for k,v in ipairs(yu[pos]) do
	-- 		if math.random(1,100000)<v[1]*100000*gl then
	-- 			money=money+v[2]
	-- 		end
	-- 	end

	-- end
	-- local gl=(money/times)
	-- print("money: "..money.."  gl: "..gl.."   抽水:  "..(1-gl))	



--test ********************************************************



return PROTECT












