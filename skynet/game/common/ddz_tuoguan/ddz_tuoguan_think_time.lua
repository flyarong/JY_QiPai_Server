--hw
--斗地主托管假装思考时间


local this={}


function this.get_think_time(data,cp)
	local seat=data.base_info.my_seat
	if cp.type>12 then
		if data.fen_pai[seat].shoushu>5 then
			if math.random(1,100)<70 then
				return math.random(50,400)
			end
		elseif data.fen_pai[seat].shoushu>4 then
			if math.random(1,100)<60 then
				return math.random(50,200)
			end	
		elseif data.fen_pai[seat].shoushu>3 then	
			if math.random(1,100)<50 then
				return math.random(1,200)
			end	
		end
	elseif cp.type>=6 and cp.type<=12 then
		if data.fen_pai[seat].shoushu>1 then
			local count=0
			if cp.type==6 or cp.type==7 then
				count=(cp.pai[2]-cp.pai[1]+1)*(cp.type-5) 
			elseif cp.type==12 then
				count=(cp.pai[2]-cp.pai[1]+1)*3
			elseif cp.type==11 or cp.type==10 then
				count=(cp.pai[2]-cp.pai[1]+1)*(3+cp.type-9)	
			end
			if count>5 then
				count=(count-5)*10+100
				if count>300 then
					count=300
				end
				return math.random(count,301)
			end
			local start=80
			if cp.type==8 or cp.type==9 then
				start=120
			end
			if math.random(1,100)<65 then
				return math.random(start,250)
			end
		elseif data.fen_pai[seat].shoushu==1 and (cp.type==9 or cp.type==8) then
			if math.random(1,100)<70 then
				return math.random(50,300)
			end
		end
	elseif data.fen_pai[seat].shoushu>1 then
		if math.random(1,100)<30 then
			return math.random(10,150)
		end
	end
	return 0
end


return this







