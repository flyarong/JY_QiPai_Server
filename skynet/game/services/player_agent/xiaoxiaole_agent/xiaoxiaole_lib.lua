-- package.path=package.path..";/Users/hewei/project/JyQipai_server/skynet/game/services/player_agent/xiaoxiaole_agent/?.lua"..";/Users/hewei/project/JyQipai_server/skynet/game/common/?.lua"
local basefunc = require "basefunc"
require "printfunc"

local this={}
this.wide_max=8
this.high_max=8
this.xc_limit=3
this.xc_limit_max=8
this.lucky_type=6

--[[
	 xc_pos_map    1 1 = 1
	 xc_moreInfo_map 1 1 ={ type=1,no--编号,o_x ,o_y原始的xy坐标 }
	 xc_no_map no={}

	 xc_num_map={
			
			key:消除数量
			value={
				{xc_no_list={1,2,3},round--在第几轮被消除的,type 种类}  


			}
	 }

	 xc_map=4   6
	 lucky_map[4]=  

	 not_xc_map={}  key=no  value=true
	 round_map={}  key=round  value=moreInfo_map

--]]

function this.xcString_2_xcMap(str,xc_pos_map,max_wide)
  xc_pos_map =xc_pos_map or {}
  print( "#xc_str1:" .. #str)
  local max_high = #str / max_wide
  print ("max_high:",max_high)
  local i = 1
  local id = 0
  for x=1,max_high do
    for y=1,max_wide do
      xc_pos_map[x] = xc_pos_map[x] or {}
      id = string.sub(str,i,i)
      xc_pos_map[x][y] = tonumber(id)

      i = i + 1
    end
  end
  --dump( xc_pos_map , "xcString_2_xcMap 111" )
  print( "xc_str:" .. str)
  print( "#xc_str2:" .. #str)

  return xc_pos_map
end
function this.xcMap_2_moreInfo(xc_map,xc_moreInfo_map,xc_no_map)

	--dump(xc_map , "xxxx-----xcMap_2_moreInfo_xc_map")


	xc_moreInfo_map=xc_moreInfo_map or {}
	xc_no_map=xc_no_map or {}

	local no=1
	if xc_map then
		local x=1
		while true do
			if not xc_map[x] then
				break
			end
			xc_moreInfo_map[x]=xc_moreInfo_map[x] or {}
			print("xxx---xcMap_2_moreInfo:",x , this.wide_max )
			for i=1,this.wide_max do
				xc_moreInfo_map[x][i]={type=xc_map[x][i],no=no,o_x=x,o_y=i}
				xc_no_map[no]=xc_moreInfo_map[x][i]
				no=no+1
			end
			x=x+1
		end
	end

	--dump(xc_moreInfo_map , "xxxx-----xcMap_2_moreInfo_xc_moreInfo_map")

	return xc_moreInfo_map,xc_no_map
end

--  high_or_wide 0 表示 横竖都要搜索  1 表示横向搜索  2表示竖向搜索  is_clear--是否清除
function this.check_can_xc_by_point(xc_moreInfo_map,x,y,xc_type,high_or_wide,hash_map,xc_vec,is_clear)

	if high_or_wide==1 then
		local start_p=x
		local end_p=x
		while start_p>0 do
			if xc_moreInfo_map[start_p] and xc_moreInfo_map[start_p][y] and xc_moreInfo_map[start_p][y].type==xc_type then
				start_p=start_p-1
			else
				break
			end
		end
		start_p=start_p+1
		while end_p<=this.high_max do
			if xc_moreInfo_map[end_p] and xc_moreInfo_map[end_p][y] and  xc_moreInfo_map[end_p][y].type==xc_type then
				end_p=end_p+1
			else
				break
			end
		end
		end_p=end_p-1
		if end_p-start_p+1>=this.xc_limit then
			for i=start_p,end_p do
				if not hash_map[i] or (hash_map[i] and not hash_map[i][y]) then
					hash_map[i] = hash_map[i] or {}
					hash_map[i][y]=true
					xc_vec =xc_vec or {}
					xc_vec[#xc_vec+1]=xc_moreInfo_map[i][y].no
					this.check_can_xc_by_point(xc_moreInfo_map,i,y,xc_type,2,hash_map,xc_vec,is_clear)
					if is_clear then
						xc_moreInfo_map[i][y].type=0
					end
				end
			end
		end
	elseif high_or_wide==2 then
		local start_p=y
		local end_p=y
		while start_p>0 do
			if xc_moreInfo_map[x] and xc_moreInfo_map[x][start_p] and xc_moreInfo_map[x][start_p].type==xc_type then
				start_p=start_p-1
			else
				break
			end
		end
		start_p=start_p+1
		while end_p<=this.wide_max do
			if xc_moreInfo_map[x] and xc_moreInfo_map[x][end_p] and xc_moreInfo_map[x][end_p].type==xc_type then
				end_p=end_p+1
			else
				break
			end
		end
		end_p=end_p-1
		if end_p-start_p+1>=this.xc_limit then
			for i=start_p,end_p do
				if not hash_map[x] or (hash_map[x] and not hash_map[x][i]) then
					hash_map[x] = hash_map[x] or {}
					hash_map[x][i]=true
					xc_vec =xc_vec or {}
					xc_vec[#xc_vec+1]=xc_moreInfo_map[x][i].no
					this.check_can_xc_by_point(xc_moreInfo_map,x,i,xc_type,1,hash_map,xc_vec,is_clear)
					if is_clear then
						xc_moreInfo_map[x][i].type=0
					end
				end
			end
		end
	elseif not high_or_wide or high_or_wide==0 then
		hash_map=hash_map or {}
		if not hash_map[x] or (hash_map[x] and not hash_map[x][y]) then
			this.check_can_xc_by_point(xc_moreInfo_map,x,y,xc_type,1,hash_map,xc_vec,is_clear)
		end
		if not hash_map[x] or (hash_map[x] and not hash_map[x][y]) then
			this.check_can_xc_by_point(xc_moreInfo_map,x,y,xc_type,2,hash_map,xc_vec,is_clear)
		end
	end
end

local function rinima( xc_moreInfo_map )
	for i=1,1000 do
		if not xc_moreInfo_map[i] then
			break
		end
		local str=""
		for j=1,8 do
			if xc_moreInfo_map[i][j] then
				str=str..xc_moreInfo_map[i][j].type
			else
				str=str.."*"
			end
		end
		print(str)
	end
	-- body
end
--把map塌缩  去除当中的0
function this.xc_tasuo_by_moreInfoMap(xc_moreInfo_map)
	local copy=basefunc.deepcopy(xc_moreInfo_map)
	for y=1,this.wide_max do
		local k=1
		local pos=1
		while xc_moreInfo_map[pos] and xc_moreInfo_map[pos][y] do
			if xc_moreInfo_map[pos][y].type==0 then
				xc_moreInfo_map[pos][y]=nil
			else
				if pos~=k then
					xc_moreInfo_map[k][y]=xc_moreInfo_map[pos][y]
					xc_moreInfo_map[pos][y]=nil
				end
				k=k+1	
			end
			pos=pos+1
		end
	end 
	--
	for x=1,this.high_max do
		for y=1,this.wide_max do
			if not xc_moreInfo_map[x][y] then
				print("before")
				rinima(copy)
				print("after")
				rinima(xc_moreInfo_map)
				-- error("xxxxxx")
				return false
			end
		end
	end
	return true
end
--获得no 到 xy的映射
function this.get_No2XyMap(xc_moreInfo_map)
	local no_2_xy={}
	if xc_moreInfo_map then
		for x,sets in pairs(xc_moreInfo_map) do
			for y,v in pairs(sets) do
				no_2_xy[v.no]={x=x,y=y}
			end 
		end
	end
	return no_2_xy
end
--  
function this.get_rate(_type,count)

	this.base_rate_cfg=this.base_rate_cfg or {
												{1,2,5,10,15,50},
												{2,5,10,30,60,100},
												{5,10,20,50,100,200},
												{10,30,60,120,250,500},
												{40,100,300,600,800,1500},
												}
	if count<this.xc_limit or _type<1 or _type>5 then
		return 0
	end
	if count>this.xc_limit_max then
		count=this.xc_limit_max
	end
	return this.base_rate_cfg[_type][count-this.xc_limit+1]

end
function this.get_rate_by_xcNumMap(xc_num_map)
	local rate=0
	if xc_num_map then

		for count,sets in pairs(xc_num_map) do
			for _,v in pairs(sets) do
				rate=rate+ this.get_rate(v.type,count)
			end
		end
	end
	return rate
end
--检查一个map是否等于一个确定的rate 前提是没有 lucky 4连  和 lucky 5连  need_roundMap--是否须有保存round_map
function this.get_xcNumMap(xc_moreInfo_map,lucky_map,need_roundMap)

	print("xxx---get_xcNumMap___xc_moreInfo_map:")
	--rinima(xc_moreInfo_map)
	--dump(lucky_map , "xxx---get_xcNumMap__lucky_map:")

	local map_copy=basefunc.deepcopy(xc_moreInfo_map)  --拷贝  
	local xc_no_map={} 
	for x,sets in pairs(map_copy) do
		for y,v in pairs(sets) do
			xc_no_map[v.no]=v
		end
	end
	
	local round_map=nil
	if need_roundMap then
		round_map={}
	end

	local xc_num_map={}
	local round=1
	--lucky相连能消除的数量
	local lucky_lian_count={}
	--获得 lucky相连能消除的数量
	local get_lucky_xc_count_by_xcVec= function(_lucky_lian_count,xc_vec,cur_no_2_xy,_xc_moreInfo_map)
		local map={}
		for k,v in ipairs(xc_vec) do
			local xy=cur_no_2_xy[v]
			map[xy.x]=map[xy.x] or {}
			map[xy.x][xy.y]=basefunc.deepcopy(_xc_moreInfo_map[xy.x][xy.y])
		end
		--dump(map,"xxxxxxxxxxx&&&&&")
		for x,sets in pairs(map) do
			for y,v in pairs(sets) do
				if v and v.type>0 then
					local xc_vec={}
					this.check_can_xc_by_point(map,x,y,v.type,0,nil,xc_vec,true)
					_lucky_lian_count=_lucky_lian_count or {}
					_lucky_lian_count[#xc_vec]=_lucky_lian_count[#xc_vec] or 0
					_lucky_lian_count[#xc_vec]=_lucky_lian_count[#xc_vec]+1
				end
			end 
		end
		-- body
	end

	while true do
		if round_map then
			round_map[round]=basefunc.deepcopy(map_copy)
		end
		local cur_no_2_xy=this.get_No2XyMap(map_copy)
		--先转换 lucky
		for x=1,this.high_max do
			for y=1,this.wide_max do
				if map_copy[x][y].type==this.lucky_type then
					local xc_vec={}
					this.check_can_xc_by_point(map_copy,x,y,this.lucky_type,0,nil,xc_vec)
					if next(xc_vec) then
						--dump(xc_vec,"xxx")
						for k,v in ipairs(xc_vec) do
							xc_no_map[v].type=lucky_map[v]
						end
						get_lucky_xc_count_by_xcVec(lucky_lian_count,xc_vec,cur_no_2_xy,map_copy)
					end
				end
			end
		end
		--
		local xc_flag=false
		--消除
		for x=1,this.high_max do
			for y=1,this.wide_max do
				if map_copy[x] and map_copy[x][y]  and map_copy[x][y].type>0 then
					local xc_type=map_copy[x][y].type
					if xc_type>0 then
						local xc_vec={}
						
						this.check_can_xc_by_point(map_copy,x,y,xc_type,0,nil,xc_vec,true)
						if next(xc_vec) then
							local len=#xc_vec
							xc_num_map[len]=xc_num_map[len] or {}
							xc_num_map[len][#xc_num_map[len]+1]={xc_no_list=xc_vec,round=round,type=xc_type}
							xc_flag=true
						end
					end
				end
			end
		end
		if not xc_flag then
			break
		else
			print("----------------------")
			rinima(map_copy)
			if not this.xc_tasuo_by_moreInfoMap(map_copy) then
				return false,lucky_lian_count,round_map
			end
			
		end
		round=round+1
	end

	return xc_num_map,lucky_lian_count,round_map
end
--获得不能消除的 xcNumMap
function this.get_not_xcNumMap(xc_num_map,round_map)
	xc_num_map=xc_num_map or {}
	local len=#round_map
	local map=round_map[len]
	local hash={}
	for x=1,this.high_max do
		for y=1,this.wide_max do
			if not hash[map[x][y].no] then
				if y<this.wide_max and map[x][y].type==map[x][y+1].type  and not hash[map[x][y+1].no] then
					xc_num_map[2]=xc_num_map[2] or {}
					xc_num_map[2][#xc_num_map[2]+1]={xc_no_list={map[x][y].no,map[x][y+1].no},type=map[x][y].type,round=len}
					hash[map[x][y+1].no]=true
				elseif x<this.high_max and map[x][y].type==map[x+1][y].type  and not hash[map[x+1][y].no] then
					xc_num_map[2]=xc_num_map[2] or {}
					xc_num_map[2][#xc_num_map[2]+1]={xc_no_list={map[x][y].no,map[x+1][y].no},type=map[x][y].type,round=len}
					hash[map[x+1][y].no]=true
				else
					xc_num_map[1]=xc_num_map[1] or {}
					xc_num_map[1][#xc_num_map[1]+1]={xc_no_list={map[x][y].no},type=map[x][y].type,round=len}
				end
				hash[map[x][y].no]=true

			end
		end
	end
end
function this.get_notXcMap(not_xc_map,round_map)
	not_xc_map=not_xc_map or {}
	xc_num_map=xc_num_map or {}
	local map=round_map[#round_map]
	for x=1,this.high_max do
		for y=1,this.wide_max do
			not_xc_map[map[x][y].no]=true
		end
	end
	return not_xc_map
end

function this.check_map_equal_rate(xc_moreInfo_map,lucky_map,rate)
	--dump(xc_moreInfo_map , "xxx-----check_map_equal_rate__xc_moreInfo_map :" )
	--dump(lucky_map , "xxx-----check_map_equal_rate__lucky_map :")
	print("xxx-----check_map_equal_rate__rate :" , rate)

	local xc_num_map,lucky_lian_count,round_map=this.get_xcNumMap(xc_moreInfo_map,lucky_map,false)
	if not xc_num_map then 
		return false
	end
	local real_rate=this.get_rate_by_xcNumMap(xc_num_map)
	print("xxx-----check_map_equal_rate__rate22 :" , rate)
	print("xxx-----check_map_equal_rate__real_rate :" , real_rate)
	if real_rate==rate then
		print("xxx-----check_map_equal_rate___true",real_rate,rate)
		return true
	end
	print("xxx-----check_map_equal_rate___false",real_rate,rate)
	return false
end
--检查map是否有确定的相连
function this.check_map_is_have_lucky_lian(xc_moreInfo_map,lucky_map,lian_count)
	--dump(xc_moreInfo_map , "xxx-----check_map_is_have_lucky_lian__xc_moreInfo_map :" )
	--dump(lucky_map , "xxx-----check_map_is_have_lucky_lian__lucky_map :")
	local xc_num_map,lucky_lian_count,round_map=this.get_xcNumMap(xc_moreInfo_map,lucky_map,false)
	-- dump(lucky_lian_count)
	if not lucky_lian_count or not lucky_lian_count[lian_count] or lucky_lian_count[lian_count]==0 then
		return false
	end
	return true
end

function this.moreInfomMap_2_string(xc_moreInfo_map,lucky_map)
	local str=""
	local lucky_str=""
	local x=1
	while xc_moreInfo_map[x] do
		for y=1,this.wide_max do
			str=str..xc_moreInfo_map[x][y].type
			if xc_moreInfo_map[x][y].type==this.lucky_type then
				lucky_str=lucky_str..lucky_map[xc_moreInfo_map[x][y].no]
			end
		end
		x = x + 1
	end
	return str,lucky_str
end
--[[
1：将所有的元素编号

2： 选出  3消
		 4消
		 N消
   选出无影响区域
3：
	3消：选出  需要的 3 消
		制造假四消或假5消

		选择假三消
	
	1：查看是否影响原来的消除  影响则取消

	--------------

		
	4-5消：选出4消或者五消  或者强行安插

4：填充
	随机选择  
	1：查看是否影响原来的消除  影响则取消
	循环 N次

xy
no
{
	{1,2,3}  
	{}


}





--]]



----------------------------------------------------------------------------------------------------------------------------add by wss ↓↓↓
--- 创建连接样式 , PS:以n个为基础，多余的补成样式
function this.create_lian_style( base_num , extra_num , target_dir , target_style , force_start_x , force_start_y )

    local dir_factor = { heng = { 
                                  { start_x = 1, start_y = 1, x_factor = -1 , y_factor = 0 } ,
                                  { start_x = 3, start_y = 1, x_factor = 1 , y_factor = 0 } ,
                                  { start_x = 1, start_y = 1, x_factor = -1 , y_factor = 0 , x_change_factor = 1 , y_change_factor = 0 , x_change_offset = base_num } ,
                                  { start_x = 1, start_y = 1, x_factor = 0 , y_factor = -1 } ,
                                  { start_x = 2, start_y = 1, x_factor = 0 , y_factor = -1 } ,
                                  { start_x = 3, start_y = 1, x_factor = 0 , y_factor = -1 } ,
                                  { start_x = 3, start_y = 1, x_factor = 0 , y_factor = 1 } ,
                                  { start_x = 2, start_y = 1, x_factor = 0 , y_factor = 1 } ,
                                  { start_x = 1, start_y = 1, x_factor = 0 , y_factor = 1 } ,
                                  { start_x = 1, start_y = 1, x_factor = 0 , y_factor = 1 , x_change_factor = 0 , y_change_factor = 1 } ,
                                  { start_x = 2, start_y = 1, x_factor = 0 , y_factor = 1 , x_change_factor = 0 , y_change_factor = 1 } ,
                                  { start_x = 3, start_y = 1, x_factor = 0 , y_factor = 1 , x_change_factor = 0 , y_change_factor = 1 } ,
                                } ,
                          shu = { 
                                  { start_x = 1, start_y = 1, x_factor = 0 , y_factor = -1 } ,
                                  { start_x = 1, start_y = 3, x_factor = 0 , y_factor = 1 } ,
                                  { start_x = 1, start_y = 1, x_factor = 0 , y_factor = -1 , x_change_factor = 0 , y_change_factor = 1 , x_change_offset = base_num } ,
                                  { start_x = 1, start_y = 1, x_factor = 1 , y_factor = 0 } ,
                                  { start_x = 1, start_y = 2, x_factor = 1 , y_factor = 0 } ,
                                  { start_x = 1, start_y = 3, x_factor = 1 , y_factor = 0 } ,
                                  { start_x = 1, start_y = 3, x_factor = -1 , y_factor = 0 } ,
                                  { start_x = 1, start_y = 2, x_factor = -1 , y_factor = 0 } ,
                                  { start_x = 1, start_y = 1, x_factor = -1 , y_factor = 0 } ,
                                  { start_x = 1, start_y = 1, x_factor = 1 , y_factor = 0 , x_change_factor = 1 , y_change_factor = 0 } ,
                                  { start_x = 1, start_y = 2, x_factor = 1 , y_factor = 0 , x_change_factor = 1 , y_change_factor = 0 } ,
                                  { start_x = 1, start_y = 3, x_factor = 1 , y_factor = 0 , x_change_factor = 1 , y_change_factor = 0 } ,
                                } ,
                      }

    local dir = target_dir
    if not dir then
        dir = math.random() < 0.5 and "heng" or "shu"
    end
    local style_id = target_style
    if not style_id then
        style_id = math.random( #dir_factor[dir] )
    end
    if style_id > #dir_factor[dir] then
    	style_id = (style_id - 1) % #dir_factor[dir] + 1
    end

    ----- 获取并检查一个样式
    local get_check_style = function(dir , style_id)
        local style_data = dir_factor[dir][style_id]

        -- x , y可用的 随机区间 间距
        local x_dis = (dir == "heng") and this.wide_max - base_num or this.wide_max
        local y_dis = (dir == "shu") and this.high_max - base_num or this.high_max

        --- 这个方向上额外的也会消耗随机区间
        x_dis = x_dis - math.abs( style_data.x_factor ) * extra_num
        y_dis = y_dis - math.abs( style_data.y_factor ) * extra_num

        if x_dis < 0 or y_dis < 0 then
            ---- 直接退出
            return false , style_id , style_data , x_dis , y_dis
        end
        return true , style_id , style_data , x_dis , y_dis
    end

    local is_get , style_id , style_data , x_dis , y_dis = get_check_style(dir , style_id)

    ----- 没找到，则全部找一遍
    if not is_get then
        local is_find = false
        for key = 1,#dir_factor[dir]-1 do
            local real_style_id = (style_id + key - 1) % #dir_factor[dir] + 1

            local is_get , ret_style_id , ret_style_data = get_check_style(dir , real_style_id)
            if is_get then
                is_find = true
                style_id = ret_style_id
                style_data = ret_style_data
                break
            end
        end

        if not is_find then
            return nil , dir , style_id
        end
    end



    ------ x,y的起始位置
    local x_start_pos = 0
    if style_data.x_factor == -1 then
         x_start_pos = math.max( 0 , - style_data.x_factor * (style_data.x_change_factor and style_data.x_change_factor or extra_num ) ) + 1
    elseif style_data.x_factor == 1 then
        if style_data.x_change_factor then
            x_start_pos = math.max( 0 ,( extra_num - style_data.x_change_factor) ) + 1
        end
    end
    
    local y_start_pos = 0
    if style_data.y_factor == -1 then
         y_start_pos = math.max( 0 , - style_data.y_factor * (style_data.y_change_factor and style_data.y_change_factor or extra_num ) ) + 1
    elseif style_data.y_factor == 1 then
        if style_data.y_change_factor then
            y_start_pos = math.max( 0 ,( extra_num - style_data.y_change_factor) ) + 1
        end
    end

    ---- 
    local x_rand_start = x_start_pos + math.random( x_dis )
    local y_rand_start = y_start_pos + math.random( y_dis )

    ----  强制位置
    x_rand_start = force_start_x or x_rand_start
    y_rand_start = force_start_y or y_rand_start

    ---- 那些位置是样式中的
    local style_pos_vec = {}
    ---- 处理基础的
    for key = 1,base_num do
        local x = x_rand_start + (key-1) * (dir == "heng" and 1 or 0)
        local y = y_rand_start + (key-1) * (dir == "shu" and 1 or 0)

        style_pos_vec[#style_pos_vec + 1] = {x = x , y = y}
    end
    ---- 处理额外的
    for key = 1, extra_num do
        local real_x_factor = style_data.x_factor
        local real_y_factor = style_data.y_factor

        local x_change_offset = 0
        local y_change_offset = 0

        if style_data.x_change_factor and key >= style_data.x_change_factor then
            real_x_factor = -style_data.x_factor
            x_change_offset = style_data.x_change_offset or 0
        end
        if style_data.y_change_factor and key >= style_data.y_change_factor then
            real_y_factor = -style_data.y_factor
            y_change_offset = style_data.y_change_offset or 0
        end

        local x = x_rand_start + (style_data.start_x - 1) + real_x_factor * key + real_x_factor * x_change_offset
        local y = y_rand_start + (style_data.start_y - 1) + real_y_factor * key + real_y_factor * y_change_offset
        style_pos_vec[#style_pos_vec + 1] = {x = x , y = y}
    end

    return style_pos_vec , dir , style_id
end

---- 获得一个 不会和周围lucky 有相连的 连接样式\
-- 参数:deal_xc_pos_map 带lucky的位置map
function this.create_single_lian_style( round_xc_moreinfo_map , deal_xc_pos_map , base_num , extra_num , target_dir , target_style , force_start_x , force_start_y )
    local style_pos_vec , dir , style_id = this.create_lian_style( base_num , extra_num , target_dir , target_style , force_start_x , force_start_y )

    if not round_xc_moreinfo_map or type(round_xc_moreinfo_map) ~= "table" or not next(round_xc_moreinfo_map) then
    	return false , dir , style_id
    end

    local style_details_vec = {}
    ---- 确定在这一轮中的样式位置的元素 no
    if style_pos_vec then
	    for key , data in pairs(style_pos_vec) do
	    	local _x = data.x
	    	local _y = data.y

	    	if round_xc_moreinfo_map[_y] and round_xc_moreinfo_map[_y][_x] then
	    		local more_info = round_xc_moreinfo_map[_y][_x]

	    		style_details_vec[#style_details_vec + 1] = { x = _x , y = _y , o_x = more_info.o_x , o_y = more_info.o_y , no = more_info.no , item_type = more_info.type }
	    	else
	    		return false , dir , style_id
	    	end

	    end
	    return style_details_vec , dir , style_id
    end

    
    return false , dir , style_id
end


--- 获得一个位置不会和其他位置相消的元素列表
function this.get_canot_xc_item_list( xc_pos_map , x , y , dir , dir_factor )
  -- 可以相消的元素
  local can_xc_vec = {}
  local canot_xc_vec = {}

  local deal = function( x_factor , y_factor , dir_factor )
      local vec = {}

      local deal_one = function(first_index , seconde_index)
          if xc_pos_map[ x + x_factor * first_index ] and xc_pos_map[x + x_factor * first_index][y + y_factor * first_index ] and
             xc_pos_map[x + x_factor * seconde_index] and xc_pos_map[x + x_factor * seconde_index][y + y_factor * seconde_index ] and 
              xc_pos_map[x + x_factor * first_index][y + y_factor * first_index ] == xc_pos_map[x + x_factor * seconde_index][y + y_factor * seconde_index ] then
            local item = xc_pos_map[x + x_factor * first_index][y + y_factor * first_index ]

            vec[ item ] = true
          end
      end

      local dir_fac_vec = {[-1] = {-2,-1} , [0] = {-1,1} , [1] = {1,2} }

      if dir_factor then
          local first_index = dir_fac_vec[dir_factor][1]
          local seconde_index = dir_fac_vec[dir_factor][2]
          deal_one(first_index , seconde_index)
      
      else

        for i=1,3 do
            local index = {-2,-1,1,2}
            local first_index = index[i]
            local seconde_index = index[i+1]

            deal_one(first_index , seconde_index)
        end
      end
      return vec
  end

  if dir == "heng" then
      --- 检查横方向上的，先看左边两个
      local can_vec = deal(1 , 0 , dir_factor)
      basefunc.merge( can_vec , can_xc_vec )

  elseif dir == "shu" then
      local can_vec = deal(0 , 1 , dir_factor)
      basefunc.merge( can_vec , can_xc_vec )
  elseif not dir then
      local can_vec = deal(0 , 1 , dir_factor)
      basefunc.merge( can_vec , can_xc_vec )
      can_vec = deal(1 , 0 , dir_factor)
      basefunc.merge( can_vec , can_xc_vec )
  end

  ------ 最后整理
  for key = 1 , this.total_item_type_num do
      if not can_xc_vec[key] then
          canot_xc_vec[key] = true
      end
  end

  return canot_xc_vec
end

----- 
---- 找到这些个相连的元素no在这一轮map中 的 起始点的 xy 以及方向 
function this.get_start_pos_and_dir( round_xc_map , xc_no_list )
	local in_round_data = {}
	for key,item_no in ipairs(xc_no_list) do
		local in_round_x = 0
		local in_round_y = 0
		-----
		for _y,x_data in pairs(round_xc_map) do
			local is_find = false
			for _x,data in pairs(x_data) do
				if data.no == item_no then
					in_round_x = _x
					in_round_y = _y
					is_find = true
					break
				end
			end
			if is_find then
				break
			end
		end

		if in_round_x == 0 or in_round_y == 0 then
			return false
		end

		in_round_data[#in_round_data + 1] = { in_round_x = in_round_x , in_round_y = in_round_y , item_no = item_no }

	end

	----- 收集到之后处理
	local min_x = 1000
	local min_y = 1000
	local x_axis_vec = {}
	local y_axis_vec = {}

	for key,data in ipairs(in_round_data) do
		if data.in_round_x < min_x then
			min_x = data.in_round_x
		end
		if data.in_round_y < min_y then
			min_y = data.in_round_y
		end

		x_axis_vec[data.in_round_x] = true
		y_axis_vec[data.in_round_y] = true
	end

	local x_axis_num = 0
	local y_axis_num = 0
	for key,data in pairs(x_axis_vec) do
		x_axis_num = x_axis_num + 1
	end
	for key,data in pairs(y_axis_vec) do
		y_axis_num = y_axis_num + 1
	end

	local dir = "heng"
	if x_axis_num == 1 then
		dir = "shu"
	elseif y_axis_num == 1 then
		dir = "heng"
	end

	return {x = min_x , y = min_y} , dir
end


----- 创建3连or 1连，2连...
function this.create_lian123_lucky(xc_pos_map , xc_moreInfo_map , xc_no_map , xc_num_map ,round_map , not_xc_map , lian_type , real_lian_num , lian_num )
    local deal_xc_pos_map = basefunc.deepcopy(xc_pos_map)
    local lucky_map = {}

    
    local force_start_x = nil
    local force_start_y = nil

    local style_details_vec = nil
    local dir = nil
    local style_id = nil

    local target_lucky_item = nil

    local lian_type_num = 0
    if lian_type == "lian1" then
    	lian_type_num = 1
    elseif lian_type == "lian2" then
    	lian_type_num = 2
    elseif lian_type == "lian3" then
    	lian_type_num = 3
    end
    if real_lian_num == 0 then
	    lian_type_num = 0
	end

    local random_index = nil

    --if real_lian_num == 3 then
    local deal_create_lian_style = function(target_dir , target_style_id)
    	if lian_type_num == 0 then

    		local round_xc_map = round_map[ math.random(#round_map) ]
    		style_details_vec,dir,style_id = this.create_single_lian_style( round_xc_map , deal_xc_pos_map , lian_type_num , lian_num - lian_type_num ,
            																 target_dir , target_style_id )
        elseif xc_num_map[lian_type_num] and next(xc_num_map[lian_type_num]) then
        	random_index = math.random( #xc_num_map[lian_type_num] )
            local rand_data = xc_num_map[lian_type_num][ random_index ]
            local xc_no_list = rand_data.xc_no_list
            local round = rand_data.round
            local item_type = rand_data.type

            --dump(xc_no_list , "------deal___xc_no_list:")
            print("--------deal___round:", round)
            --dump(round_map[round] , "------round_map[round]:")

            if not xc_no_list then
            	dump(rand_data , string.format( "-------- not xc_no_list , rand_data: lian_type_num:%d" , lian_type_num ) )
            end

            assert( #xc_no_list == lian_type_num , string.format( "#xc_no_list ~= lian_type_num , %d", lian_type_num) )

            local round_xc_map = round_map[round]

            assert(round_xc_map , string.format("no round_xc_map for round:%d",round) )

            ---- 找到这些个相连的元素no在这一轮map中 的 起始点的 xy 以及方向 
            local in_round_start_pos , target_dir = this.get_start_pos_and_dir( round_xc_map , xc_no_list )

            print("--------deal__in_round_start_pos:" , in_round_start_pos.x , in_round_start_pos.y)
            print("--------deal__in_round_target_dir:" , target_dir)

            if not in_round_start_pos then
            	error( "--------------not in_round_start_pos" )
            	return false
            end
            
            style_details_vec,dir,style_id = this.create_single_lian_style( round_xc_map , deal_xc_pos_map , lian_type_num , lian_num - lian_type_num ,
            																 target_dir , target_style_id , in_round_start_pos.x , in_round_start_pos.y )

            --dump(style_details_vec , "xxxx---------style_details_vec:")

            if lian_type_num == 3 then
            	target_lucky_item = item_type
            end

        else
            return false
        end
    end

    deal_create_lian_style()


    --if not style_details_vec then
    --    return false
    --else
        local same_lucky_num = 0
        if target_lucky_item then
            same_lucky_num = real_lian_num
        else
            same_lucky_num = 0
        end

        local is_deal =  this.deal_replace(style_details_vec , not_xc_map , deal_xc_pos_map , xc_moreInfo_map , lucky_map , same_lucky_num , dir , target_lucky_item)
    
        if not is_deal then
	      	local is_succ = false
	      	---- 如果没有处理成功 , 循环搞15次
	      	for key = 1,15 do
	      		---- 还原数据
	      		deal_xc_pos_map = basefunc.deepcopy(xc_pos_map)
	      		lucky_map = {}

	      		local target_dir = dir
	      		local target_style_id = (style_id or 0) + key

	      		deal_create_lian_style(target_dir , target_style_id)
	      		local is_deal = this.deal_replace(style_details_vec , not_xc_map , deal_xc_pos_map , xc_moreInfo_map , lucky_map , same_lucky_num , dir , target_lucky_item)
	      		
	      		if is_deal then
	      			is_succ = true
	      			break
	      		else
	      			print("xxxxxxxx-----------------create_lian123_lucky_________")
	      		end
	      	end

	      	if not is_succ then
		      return false
		    end

	      end

	      -----
	      if random_index and xc_num_map[lian_type_num] and xc_num_map[lian_type_num][random_index] then
	      		table.remove( xc_num_map[lian_type_num] , random_index )
	      end

    --end


    return deal_xc_pos_map , lucky_map
end

----- 创建真4连5连lucky
function this.create_lian45_lucky( not_xc_map , round_map , xc_pos_map , xc_moreInfo_map , lian_type , real_lian_num , lian_num , lucky_item )
      local deal_xc_pos_map = basefunc.deepcopy(xc_pos_map)
      --- key = no , value = item
      local lucky_map = {}

      local style_details_vec = nil
      local dir = nil
      local style_id = nil

      local xc_lucky_num = real_lian_num

      local random_round_index = math.random(#round_map)
      local randon_round_data = round_map[random_round_index]

      local deal_create_lian_style = function(target_dir , target_style_id)
      	if lian_type == "lian4" then
	          style_details_vec,dir,style_id = this.create_single_lian_style( randon_round_data , deal_xc_pos_map , 4 , lian_num - 4 , target_dir , target_style_id )
	    elseif lian_type == "lian5" then
	          style_details_vec,dir,style_id = this.create_single_lian_style( randon_round_data , deal_xc_pos_map , 3 , lian_num - 3 , target_dir , target_style_id )
	    end
  	  end

      deal_create_lian_style()

      --dump( style_details_vec , "create_lian45_lucky____style_details_vec" )

      local is_deal = this.deal_replace(style_details_vec , not_xc_map , deal_xc_pos_map , xc_moreInfo_map , lucky_map , xc_lucky_num , dir , lucky_item)

      if not is_deal then
      	local is_succ = false
      	---- 如果没有处理成功 , 循环搞15次
      	for key = 1,15 do
      		---- 还原数据
      		deal_xc_pos_map = basefunc.deepcopy(xc_pos_map)
      		lucky_map = {}

      		local target_dir = dir
      		local target_style_id = (style_id or 0) + key

      		deal_create_lian_style(target_dir , target_style_id)
      		local is_deal = this.deal_replace(style_details_vec , not_xc_map , deal_xc_pos_map , xc_moreInfo_map , lucky_map , xc_lucky_num , dir , lucky_item)
      	
      		if is_deal then
      			is_succ = true
      			break
      		end
      	end

      	if not is_succ then
	      return false
	    end

      end

    return deal_xc_pos_map , lucky_map
end


function this.deal_replace(style_details_vec , not_xc_map , deal_xc_pos_map , xc_moreInfo_map , lucky_map , xc_lucky_num , dir , lucky_item)
    if style_details_vec and type(style_details_vec) == "table" and next(style_details_vec) then
          local index = 0
          for key,data in pairs(style_details_vec) do
              index = index + 1
              local _x = data.x
              local _y = data.y
              local o_x = data.o_x
              local o_y = data.o_y
              local item_no = data.no
              local item_type = data.item_type

              local is_same = false
              if index <= xc_lucky_num then
                  is_same = true
              end

                ----- 
              if not is_same then
                  ----- 这个假的需要满足
                  --- 不能和要变成的真的lucky相同
                  --- 在not_xc_map中

                  if item_type == lucky_item or not not_xc_map[item_no] then
                  		return false
                  end

                  this.replace_one_item( o_x , o_y , deal_xc_pos_map , xc_moreInfo_map , item_no , lucky_map , item_type)

              else
                  this.replace_one_item( o_x , o_y , deal_xc_pos_map , xc_moreInfo_map , item_no , lucky_map , lucky_item)

              end
          end

          return true
      end

    return false
end


--- 替换一个位置的元素
function this.replace_one_item( o_x , o_y , xc_pos_map , xc_moreInfo_map , item_no , lucky_map , replace_item)

    lucky_map[item_no] = replace_item

    xc_pos_map[o_x][o_y] = this.lucky_type

end


function this.get_random_item(vec)
    if not vec and not next(vec) then
        return nil
    end

    local list = {}
    for item,bool in pairs(vec) do
        list[#list + 1] = item
    end

    local random_index = math.random( #list )

    return list[random_index]
end

---- 通过原始的moreinfo_map 和当前的lucky_map 获得最新的moreInfo_map
function this.get_lucky_moreinfo_map( moreinfo_map , lucky_map )
	local ret_moreinfo_map = basefunc.deepcopy(moreinfo_map)
	for _x,x_data in pairs(ret_moreinfo_map) do
		for _y,data in pairs(x_data) do
			if lucky_map[data.no] then
				data.type = this.lucky_type -- lucky_map[data.no] 
			end
		end
	end

	return ret_moreinfo_map
end

--创建lucky
function this.create_lucky(xc_str,rate,lucky_data)
	---- 消除位置map , [x][y] = item_type
	local xc_pos_map=this.xcString_2_xcMap(xc_str,nil,this.wide_max)
	---- 
	local xc_moreInfo_map,xc_no_map=this.xcMap_2_moreInfo(xc_pos_map,nil,nil)

	--dump(xc_moreInfo_map , "xxx____start___ xc_moreInfo_map:")

	--dump(xc_no_map , "xxx____start___ xc_no_map:" )

	local lucky_map={}
	---- 消除
	local xc_num_map,lucky_lian_count,round_map=this.get_xcNumMap(xc_moreInfo_map,lucky_map,true)

	if not xc_num_map then
		error("xc_str data error : "..xc_str)
	end
	---- 不能消除map
	--dump( round_map , "xxx------round_map:" )

	this.get_not_xcNumMap(xc_num_map,round_map)

	--dump(xc_num_map , "xxx____start___ xc_num_map:" )

	local not_xc_map=this.get_notXcMap(nil,round_map)

	--dump(not_xc_map , "xxx____start___not_xc_map:")

	if lucky_data and type(lucky_data) == "table" and next(lucky_data) then
		table.sort( lucky_data , function(a,b)
			return a.lian_type and a.lian_type == "lian3"
		end)
	end

	local test_orignal_rate = function()
		local xc_num_map,lucky_lian_count,round_map=this.get_xcNumMap(xc_moreInfo_map,lucky_map,false)
		local real_rate=this.get_rate_by_xcNumMap(xc_num_map)
		print("xxx------------test_orignal_rate________real_rate:",real_rate  ,  rate)

		---
		print("xxxx----------------------------- orignal__xc_moreInfo_map:")
		rinima(xc_moreInfo_map)
	end

	test_orignal_rate()

	---------- test ----

	--[[local test_lucky_map = {
     [56] = 5,
     [64] = 5,
     [72] = 5,
 	}

	local test_data = {
		"15222413",
		"31122514",
		"35353222",
		"45221534",
		"15234542",
		"41441511",
		"53411416",
		"32112236",
		"01442246",
		"03000500",
		"01000300",
		"00000300",
	}
	----
	local test_moreinfo = {}
	local test_no = 0
	for y,data in ipairs(test_data) do
		for x = 1,8 do
			test_no = test_no + 1
			test_moreinfo[y] = test_moreinfo[y] or {}
			test_moreinfo[y][x] = { type = tonumber( string.sub( data , x,x ) ) , no = test_no , o_x = x , o_y = y }
		end 
	end
	print("xxx-----------test_moreinfo:")
	rinima( test_moreinfo )

	this.get_xcNumMap(test_moreinfo,test_lucky_map, true )--]]

	---------- test -----


	local total_lucky_map = {}

	local lian3_data = {}
	local lian45_data = {}
	local other_data = {}

	print("xxxx-------------- progress 1")

	dump(lucky_data , "xxx----------------original__lucky_data")

	for key,data in ipairs(lucky_data) do
		if data.lian_type == "lian4" or data.lian_type == "lian5" then
			lian45_data[#lian45_data + 1] = data
		elseif data.lian_type == "lian3" then
			lian3_data[#lian3_data + 1] = data
		else
			other_data[#other_data + 1] = data
		end
	end

	print("xxxx-------------- progress 2")

	---- 处理 一次 3连
	local deal_once_lian3 = function(lian3_data , total_lucky_map)
		local xc_num_map_tem = basefunc.deepcopy(xc_num_map)

		local total_lucky_map_tem = basefunc.deepcopy(total_lucky_map)

		for key,data in pairs(lian3_data) do
			local ret_deal_xc_pos_map , ret_lucky_map = this.create_lian123_lucky(xc_pos_map , xc_moreInfo_map , xc_no_map , xc_num_map_tem , round_map , 
																							not_xc_map , data.lian_type , data.real_lian_num , data.lian_num )
			basefunc.merge( ret_lucky_map , total_lucky_map_tem )
		end

		local total_moreinf_map = this.get_lucky_moreinfo_map( xc_moreInfo_map , total_lucky_map_tem )

		local is_succ = this.check_map_equal_rate(total_moreinf_map,total_lucky_map_tem,rate)

		if is_succ then
			print("xxx--------------------create_lian123_lucky____check_map_equal_rate____true")
			total_lucky_map = basefunc.merge( total_lucky_map_tem , total_lucky_map )
		else
			print("xxx--------------------create_lian123_lucky____check_map_equal_rate____false")
		end

		return is_succ
	end

	print("xxxx-------------- progress 3")

	local real_lian_num = 0 

	---- 处理 一次 4,5 连
	local deal_once_lian45 = function(lian45_data , total_lucky_map)
		local total_lucky_map_tem = basefunc.deepcopy(total_lucky_map)

		
		for key,data in pairs(lian45_data) do
			
			local ret_deal_xc_pos_map , ret_lucky_map = this.create_lian45_lucky( not_xc_map , round_map , xc_pos_map , xc_moreInfo_map , data.lian_type , 
																					data.real_lian_num , data.lian_num , data.lucky_item )

			basefunc.merge( ret_lucky_map , total_lucky_map_tem )

			real_lian_num = data.real_lian_num

		end

		local total_moreinf_map = this.get_lucky_moreinfo_map( xc_moreInfo_map , total_lucky_map_tem )

		--dump(total_lucky_map_tem , "xxxx----------------deal_once_lian45____total_lucky_map_tem")

		local is_succ = this.check_map_is_have_lucky_lian(total_moreinf_map,total_lucky_map_tem,real_lian_num)

		if is_succ then
			print("xxx--------------------create_lian45_lucky____check_map_is_have_lucky_lian____true")
			total_lucky_map = basefunc.merge( total_lucky_map_tem , total_lucky_map )
		else
			print("xxx--------------------create_lian45_lucky____check_map_is_have_lucky_lian____false")
		end

		return is_succ
	end

	print("xxxx-------------- progress 4")

	---- 处理 一次 other 连
	local deal_once_lian_other = function(lian_other_data , total_lucky_map , is_lian3_succ , is_lian45_succ )
		local total_lucky_map_tem = basefunc.deepcopy(total_lucky_map)

		for key,data in pairs(lian_other_data) do
			
			local ret_deal_xc_pos_map , ret_lucky_map = this.create_lian123_lucky(xc_pos_map , xc_moreInfo_map , xc_no_map , xc_num_map , round_map , 
																							not_xc_map , data.lian_type , data.real_lian_num , data.lian_num )

			basefunc.merge( ret_lucky_map , total_lucky_map_tem )
		end

		local total_moreinf_map = this.get_lucky_moreinfo_map( xc_moreInfo_map , total_lucky_map_tem )

		local is_succ = false

		if is_lian45_succ then
			print("xxxx--------deal_once_lian_other_____is_lian45_succ_")
		 	is_succ = this.check_map_is_have_lucky_lian(total_moreinf_map,total_lucky_map_tem,real_lian_num)
		else
			print("xxxx--------deal_once_lian_other_____is_lian3_succ_")
			is_succ = this.check_map_equal_rate(total_moreinf_map,total_lucky_map_tem,rate)
		end
		print("xxx-----------------deal_once_lian_other__is_succ:",is_succ)
		if is_succ then
			total_lucky_map = basefunc.merge( total_lucky_map_tem , total_lucky_map )
		end

		return is_succ
	end

	print("xxxx-------------- progress 5")

	---- 处理12345连
	local deal_lian12345 = function(lian_data , deal_func , ...)
		local deal_times = 0
		for i=1,10 do
			if lian_data and next(lian_data) then
				deal_times = deal_times + 1
				local is_succ = deal_func(lian_data , total_lucky_map , ...)
				if is_succ then
					return true
				end
			end

			--- 处理3次，清掉一个
			if deal_times % 2 == 0 then
				lian_data[#lian_data] = nil
			end

		end

		return false
	end
	
	print("xxxx-------------- progress 6")

	local is_lian3_succ = deal_lian12345(lian3_data , deal_once_lian3)
	print("xxxx-------------- progress 7")
	local is_lian45_succ = deal_lian12345(lian45_data , deal_once_lian45)
	print("xxxx-------------- progress 8")
	--dump(other_data , "xxxx------------------------------other_data:")

	local is_lian_other_succ = deal_lian12345(other_data , deal_once_lian_other , is_lian3_succ , is_lian45_succ)
	print("xxxx-------------- progress 9")

	dump(total_lucky_map , "--------------total_lucky_map:")
	---- 获取最终的moreinfo map 
	local total_moreinf_map = this.get_lucky_moreinfo_map( xc_moreInfo_map , total_lucky_map )
	print("xxxx-------------- progress 10")
	----- 获取最终的xc_str , lucky_str
	local xc_map_str , lucky_str = this.moreInfomMap_2_string(total_moreinf_map,total_lucky_map)
	print("xxxx-------------- progress 11")

	print("lucky_str:",lucky_str)

	return xc_map_str , lucky_str
end


--test  hewei *************


-- local xc_str="22215235421232452423515251512111421113323412542333454135145443114133253400100000"
-- ---- 消除位置map , [x][y] = item_type
-- local xc_pos_map=this.xcString_2_xcMap(xc_str,nil,this.wide_max)
-- ---- 
-- local xc_moreInfo_map,xc_no_map=this.xcMap_2_moreInfo(xc_pos_map,nil,nil)

-- -- dump(xc_moreInfo_map , "xxx____start___ xc_moreInfo_map:")

-- local lucky_map={}
-- ---- 消除
-- local xc_moreInfo_map={
--      [1] = {
--          [1] = {
--              no     = 1,
--              o_x    = 1,
--              o_y    = 1,
--              type   = 1,
--          },
--          [2] = {
--              no     = 2,
--              o_x    = 1,
--              o_y    = 2,
--              type   = 3,
--          },
--          [3] = {
--              no     = 3,
--              o_x    = 1,
--              o_y    = 3,
--              type   = 3,
--          },
--          [4] = {
--              no     = 4,
--              o_x    = 1,
--              o_y    = 4,
--              type   = 4,
--          },
--          [5] = {
--              no     = 5,
--              o_x    = 1,
--              o_y    = 5,
--              type   = 4,
--          },
--          [6] = {
--              no     = 6,
--              o_x    = 1,
--              o_y    = 6,
--              type   = 1,
--          },
--          [7] = {
--              no     = 7,
--              o_x    = 1,
--              o_y    = 7,
--              type   = 1,
--          },
--          [8] = {
--              no     = 8,
--              o_x    = 1,
--              o_y    = 8,
--              type   = 1,
--          },
--      },
--      [2] = {
--          [1] = {
--              no     = 9,
--              o_x    = 2,
--              o_y    = 1,
--              type   = 1,
--          },
--          [2] = {
--              no     = 10,
--              o_x    = 2,
--              o_y    = 2,
--              type   = 3,
--          },
--          [3] = {
--              no     = 11,
--              o_x    = 2,
--              o_y    = 3,
--              type   = 3,
--          },
--          [4] = {
--              no     = 12,
--              o_x    = 2,
--              o_y    = 4,
--              type   = 3,
--          },
--          [5] = {
--              no     = 13,
--              o_x    = 2,
--              o_y    = 5,
--              type   = 4,
--          },
--          [6] = {
--              no     = 14,
--              o_x    = 2,
--              o_y    = 6,
--              type   = 3,
--          },
--          [7] = {
--              no     = 15,
--              o_x    = 2,
--              o_y    = 7,
--              type   = 3,
--          },
--          [8] = {
--              no     = 16,
--              o_x    = 2,
--              o_y    = 8,
--              type   = 5,
--          },
--      },
--      [3] = {
--          [1] = {
--              no     = 17,
--              o_x    = 3,
--              o_y    = 1,
--              type   = 1,
--          },
--          [2] = {
--              no     = 18,
--              o_x    = 3,
--              o_y    = 2,
--              type   = 5,
--          },
--          [3] = {
--              no     = 19,
--              o_x    = 3,
--              o_y    = 3,
--              type   = 5,
--          },
--          [4] = {
--              no     = 20,
--              o_x    = 3,
--              o_y    = 4,
--              type   = 3,
--          },
--          [5] = {
--              no     = 21,
--              o_x    = 3,
--              o_y    = 5,
--              type   = 1,
--          },
--          [6] = {
--              no     = 22,
--              o_x    = 3,
--              o_y    = 6,
--              type   = 5,
--          },
--          [7] = {
--              no     = 23,
--              o_x    = 3,
--              o_y    = 7,
--              type   = 3,
--          },
--          [8] = {
--              no     = 24,
--              o_x    = 3,
--              o_y    = 8,
--              type   = 3,
--          },
--      },
--      [4] = {
--          [1] = {
--              no     = 25,
--              o_x    = 4,
--              o_y    = 1,
--              type   = 5,
--          },
--          [2] = {
--              no     = 26,
--              o_x    = 4,
--              o_y    = 2,
--              type   = 3,
--          },
--          [3] = {
--              no     = 27,
--              o_x    = 4,
--              o_y    = 3,
--              type   = 1,
--          },
--          [4] = {
--              no     = 28,
--              o_x    = 4,
--              o_y    = 4,
--              type   = 3,
--          },
--          [5] = {
--              no     = 29,
--              o_x    = 4,
--              o_y    = 5,
--              type   = 3,
--          },
--          [6] = {
--              no     = 30,
--              o_x    = 4,
--              o_y    = 6,
--              type   = 1,
--          },
--          [7] = {
--              no     = 31,
--              o_x    = 4,
--              o_y    = 7,
--              type   = 3,
--          },
--          [8] = {
--              no     = 32,
--              o_x    = 4,
--              o_y    = 8,
--              type   = 3,
--          },
--      },
--      [5] = {
--          [1] = {
--              no     = 33,
--              o_x    = 5,
--              o_y    = 1,
--              type   = 3,
--          },
--          [2] = {
--              no     = 34,
--              o_x    = 5,
--              o_y    = 2,
--              type   = 3,
--          },
--          [3] = {
--              no     = 35,
--              o_x    = 5,
--              o_y    = 3,
--              type   = 1,
--          },
--          [4] = {
--              no     = 36,
--              o_x    = 5,
--              o_y    = 4,
--              type   = 3,
--          },
--          [5] = {
--              no     = 37,
--              o_x    = 5,
--              o_y    = 5,
--              type   = 3,
--          },
--          [6] = {
--              no     = 38,
--              o_x    = 5,
--              o_y    = 6,
--              type   = 3,
--          },
--          [7] = {
--              no     = 39,
--              o_x    = 5,
--              o_y    = 7,
--              type   = 3,
--          },
--          [8] = {
--              no     = 40,
--              o_x    = 5,
--              o_y    = 8,
--              type   = 2,
--          },
--      },
--      [6] = {
--          [1] = {
--              no     = 41,
--              o_x    = 6,
--              o_y    = 1,
--              type   = 3,
--          },
--          [2] = {
--              no     = 42,
--              o_x    = 6,
--              o_y    = 2,
--              type   = 3,
--          },
--          [3] = {
--              no     = 43,
--              o_x    = 6,
--              o_y    = 3,
--              type   = 3,
--          },
--          [4] = {
--              no     = 44,
--              o_x    = 6,
--              o_y    = 4,
--              type   = 3,
--          },
--          [5] = {
--              no     = 45,
--              o_x    = 6,
--              o_y    = 5,
--              type   = 4,
--          },
--          [6] = {
--              no     = 46,
--              o_x    = 6,
--              o_y    = 6,
--              type   = 3,
--          },
--          [7] = {
--              no     = 47,
--              o_x    = 6,
--              o_y    = 7,
--              type   = 2,
--          },
--          [8] = {
--              no     = 48,
--              o_x    = 6,
--              o_y    = 8,
--              type   = 1,
--          },
--      },
--      [7] = {
--          [1] = {
--              no     = 49,
--              o_x    = 7,
--              o_y    = 1,
--              type   = 5,
--          },
--          [2] = {
--              no     = 50,
--              o_x    = 7,
--              o_y    = 2,
--              type   = 4,
--          },
--          [3] = {
--              no     = 51,
--              o_x    = 7,
--              o_y    = 3,
--              type   = 2,
--          },
--          [4] = {
--              no     = 52,
--              o_x    = 7,
--              o_y    = 4,
--              type   = 6,
--          },
--          [5] = {
--              no     = 53,
--              o_x    = 7,
--              o_y    = 5,
--              type   = 4,
--          },
--          [6] = {
--              no     = 54,
--              o_x    = 7,
--              o_y    = 6,
--              type   = 3,
--          },
--          [7] = {
--              no     = 55,
--              o_x    = 7,
--              o_y    = 7,
--              type   = 2,
--          },
--          [8] = {
--              no     = 56,
--              o_x    = 7,
--              o_y    = 8,
--              type   = 2,
--          },
--      },
--      [8] = {
--          [1] = {
--              no     = 57,
--              o_x    = 8,
--              o_y    = 1,
--              type   = 5,
--          },
--          [2] = {
--              no     = 58,
--              o_x    = 8,
--              o_y    = 2,
--              type   = 4,
--          },
--          [3] = {
--              no     = 59,
--              o_x    = 8,
--              o_y    = 3,
--              type   = 5,
--          },
--          [4] = {
--              no     = 60,
--              o_x    = 8,
--              o_y    = 4,
--              type   = 1,
--          },
--          [5] = {
--              no     = 61,
--              o_x    = 8,
--              o_y    = 5,
--              type   = 1,
--          },
--          [6] = {
--              no     = 62,
--              o_x    = 8,
--              o_y    = 6,
--              type   = 3,
--          },
--          [7] = {
--              no     = 63,
--              o_x    = 8,
--              o_y    = 7,
--              type   = 3,
--          },
--          [8] = {
--              no     = 64,
--              o_x    = 8,
--              o_y    = 8,
--              type   = 3,
--          },
--      },
--      [9] = {
--          [1] = {
--              no     = 65,
--              o_x    = 9,
--              o_y    = 1,
--              type   = 1,
--          },
--          [2] = {
--              no     = 66,
--              o_x    = 9,
--              o_y    = 2,
--              type   = 4,
--          },
--          [3] = {
--              no     = 67,
--              o_x    = 9,
--              o_y    = 3,
--              type   = 3,
--          },
--          [4] = {
--              no     = 68,
--              o_x    = 9,
--              o_y    = 4,
--              type   = 6,
--          },
--          [5] = {
--              no     = 69,
--              o_x    = 9,
--              o_y    = 5,
--              type   = 2,
--          },
--          [6] = {
--              no     = 70,
--              o_x    = 9,
--              o_y    = 6,
--              type   = 2,
--          },
--          [7] = {
--              no     = 71,
--              o_x    = 9,
--              o_y    = 7,
--              type   = 1,
--          },
--          [8] = {
--              no     = 72,
--              o_x    = 9,
--              o_y    = 8,
--              type   = 3,
--          },
--      },
--      [10] = {
--          [1] = {
--              no     = 73,
--              o_x    = 10,
--              o_y    = 1,
--              type   = 3,
--          },
--          [2] = {
--              no     = 74,
--              o_x    = 10,
--              o_y    = 2,
--              type   = 2,
--          },
--          [3] = {
--              no     = 75,
--              o_x    = 10,
--              o_y    = 3,
--              type   = 3,
--          },
--          [4] = {
--              no     = 76,
--              o_x    = 10,
--              o_y    = 4,
--              type   = 2,
--          },
--          [5] = {
--              no     = 77,
--              o_x    = 10,
--              o_y    = 5,
--              type   = 2,
--          },
--          [6] = {
--              no     = 78,
--              o_x    = 10,
--              o_y    = 6,
--              type   = 4,
--          },
--          [7] = {
--              no     = 79,
--              o_x    = 10,
--              o_y    = 7,
--              type   = 5,
--          },
--          [8] = {
--              no     = 80,
--              o_x    = 10,
--              o_y    = 8,
--              type   = 3,
--          },
--      },
--      [11] = {
--          [1] = {
--              no     = 81,
--              o_x    = 11,
--              o_y    = 1,
--              type   = 2,
--          },
--          [2] = {
--              no     = 82,
--              o_x    = 11,
--              o_y    = 2,
--              type   = 2,
--          },
--          [3] = {
--              no     = 83,
--              o_x    = 11,
--              o_y    = 3,
--              type   = 5,
--          },
--          [4] = {
--              no     = 84,
--              o_x    = 11,
--              o_y    = 4,
--              type   = 6,
--          },
--          [5] = {
--              no     = 85,
--              o_x    = 11,
--              o_y    = 5,
--              type   = 0,
--          },
--          [6] = {
--              no     = 86,
--              o_x    = 11,
--              o_y    = 6,
--              type   = 5,
--          },
--          [7] = {
--              no     = 87,
--              o_x    = 11,
--              o_y    = 7,
--              type   = 2,
--          },
--          [8] = {
--              no     = 88,
--              o_x    = 11,
--              o_y    = 8,
--              type   = 3,
--          },
--      },
--      [12] = {
--          [1] = {
--              no     = 89,
--              o_x    = 12,
--              o_y    = 1,
--              type   = 4,
--          },
--          [2] = {
--              no     = 90,
--              o_x    = 12,
--              o_y    = 2,
--              type   = 4,
--          },
--          [3] = {
--              no     = 91,
--              o_x    = 12,
--              o_y    = 3,
--              type   = 3,
--          },
--          [4] = {
--              no     = 92,
--              o_x    = 12,
--              o_y    = 4,
--              type   = 6,
--          },
--          [5] = {
--              no     = 93,
--              o_x    = 12,
--              o_y    = 5,
--              type   = 0,
--          },
--          [6] = {
--              no     = 94,
--              o_x    = 12,
--              o_y    = 6,
--              type   = 2,
--          },
--          [7] = {
--              no     = 95,
--              o_x    = 12,
--              o_y    = 7,
--              type   = 3,
--          },
--          [8] = {
--              no     = 96,
--              o_x    = 12,
--              o_y    = 8,
--              type   = 1,
--          },
--      },
--      [13] = {
--          [1] = {
--              no     = 97,
--              o_x    = 13,
--              o_y    = 1,
--              type   = 0,
--          },
--          [2] = {
--              no     = 98,
--              o_x    = 13,
--              o_y    = 2,
--              type   = 4,
--          },
--          [3] = {
--              no     = 99,
--              o_x    = 13,
--              o_y    = 3,
--              type   = 2,
--          },
--          [4] = {
--              no     = 100,
--              o_x    = 13,
--              o_y    = 4,
--              type   = 3,
--          },
--          [5] = {
--              no     = 101,
--              o_x    = 13,
--              o_y    = 5,
--              type   = 0,
--          },
--          [6] = {
--              no     = 102,
--              o_x    = 13,
--              o_y    = 6,
--              type   = 2,
--          },
--          [7] = {
--              no     = 103,
--              o_x    = 13,
--              o_y    = 7,
--              type   = 2,
--          },
--          [8] = {
--              no     = 104,
--              o_x    = 13,
--              o_y    = 8,
--              type   = 1,
--          },
--      },
--      [14] = {
--          [1] = {
--              no     = 105,
--              o_x    = 14,
--              o_y    = 1,
--              type   = 0,
--          },
--          [2] = {
--              no     = 106,
--              o_x    = 14,
--              o_y    = 2,
--              type   = 5,
--          },
--          [3] = {
--              no     = 107,
--              o_x    = 14,
--              o_y    = 3,
--              type   = 2,
--          },
--          [4] = {
--              no     = 108,
--              o_x    = 14,
--              o_y    = 4,
--              type   = 5,
--          },
--          [5] = {
--              no     = 109,
--              o_x    = 14,
--              o_y    = 5,
--              type   = 0,
--          },
--          [6] = {
--              no     = 110,
--              o_x    = 14,
--              o_y    = 6,
--              type   = 3,
--          },
--          [7] = {
--              no     = 111,
--              o_x    = 14,
--              o_y    = 7,
--              type   = 5,
--          },
--          [8] = {
--              no     = 112,
--              o_x    = 14,
--              o_y    = 8,
--              type   = 1,
--          },
--      },
--      [15] = {
--          [1] = {
--              no     = 113,
--              o_x    = 15,
--              o_y    = 1,
--              type   = 0,
--          },
--          [2] = {
--              no     = 114,
--              o_x    = 15,
--              o_y    = 2,
--              type   = 5,
--          },
--          [3] = {
--              no     = 115,
--              o_x    = 15,
--              o_y    = 3,
--              type   = 2,
--          },
--          [4] = {
--              no     = 116,
--              o_x    = 15,
--              o_y    = 4,
--              type   = 3,
--          },
--          [5] = {
--              no     = 117,
--              o_x    = 15,
--              o_y    = 5,
--              type   = 0,
--          },
--          [6] = {
--              no     = 118,
--              o_x    = 15,
--              o_y    = 6,
--              type   = 3,
--          },
--          [7] = {
--              no     = 119,
--              o_x    = 15,
--              o_y    = 7,
--              type   = 4,
--          },
--          [8] = {
--              no     = 120,
--              o_x    = 15,
--              o_y    = 8,
--              type   = 3,
--          },
--      },
--      [16] = {
--          [1] = {
--              no     = 121,
--              o_x    = 16,
--              o_y    = 1,
--              type   = 0,
--          },
--          [2] = {
--              no     = 122,
--              o_x    = 16,
--              o_y    = 2,
--              type   = 5,
--          },
--          [3] = {
--              no     = 123,
--              o_x    = 16,
--              o_y    = 3,
--              type   = 5,
--          },
--          [4] = {
--              no     = 124,
--              o_x    = 16,
--              o_y    = 4,
--              type   = 3,
--          },
--          [5] = {
--              no     = 125,
--              o_x    = 16,
--              o_y    = 5,
--              type   = 0,
--          },
--          [6] = {
--              no     = 126,
--              o_x    = 16,
--              o_y    = 6,
--              type   = 1,
--          },
--          [7] = {
--              no     = 127,
--              o_x    = 16,
--              o_y    = 7,
--              type   = 3,
--          },
--          [8] = {
--              no     = 128,
--              o_x    = 16,
--              o_y    = 8,
--              type   = 4,
--          },
--      },
--      [17] = {
--          [1] = {
--              no     = 129,
--              o_x    = 17,
--              o_y    = 1,
--              type   = 0,
--          },
--          [2] = {
--              no     = 130,
--              o_x    = 17,
--              o_y    = 2,
--              type   = 3,
--          },
--          [3] = {
--              no     = 131,
--              o_x    = 17,
--              o_y    = 3,
--              type   = 4,
--          },
--          [4] = {
--              no     = 132,
--              o_x    = 17,
--              o_y    = 4,
--              type   = 2,
--          },
--          [5] = {
--              no     = 133,
--              o_x    = 17,
--              o_y    = 5,
--              type   = 0,
--          },
--          [6] = {
--              no     = 134,
--              o_x    = 17,
--              o_y    = 6,
--              type   = 0,
--          },
--          [7] = {
--              no     = 135,
--              o_x    = 17,
--              o_y    = 7,
--              type   = 4,
--          },
--          [8] = {
--              no     = 136,
--              o_x    = 17,
--              o_y    = 8,
--              type   = 3,
--          },
--      },
--      [18] = {
--          [1] = {
--              no     = 137,
--              o_x    = 18,
--              o_y    = 1,
--              type   = 0,
--          },
--          [2] = {
--              no     = 138,
--              o_x    = 18,
--              o_y    = 2,
--              type   = 2,
--          },
--          [3] = {
--              no     = 139,
--              o_x    = 18,
--              o_y    = 3,
--              type   = 5,
--          },
--          [4] = {
--              no     = 140,
--              o_x    = 18,
--              o_y    = 4,
--              type   = 3,
--          },
--          [5] = {
--              no     = 141,
--              o_x    = 18,
--              o_y    = 5,
--              type   = 0,
--          },
--          [6] = {
--              no     = 142,
--              o_x    = 18,
--              o_y    = 6,
--              type   = 0,
--          },
--          [7] = {
--              no     = 143,
--              o_x    = 18,
--              o_y    = 7,
--              type   = 0,
--          },
--          [8] = {
--              no     = 144,
--              o_x    = 18,
--              o_y    = 8,
--              type   = 3,
--          },
--      },
--      [19] = {
--          [1] = {
--              no     = 145,
--              o_x    = 19,
--              o_y    = 1,
--              type   = 0,
--          },
--          [2] = {
--              no     = 146,
--              o_x    = 19,
--              o_y    = 2,
--              type   = 0,
--          },
--          [3] = {
--              no     = 147,
--              o_x    = 19,
--              o_y    = 3,
--              type   = 3,
--          },
--          [4] = {
--              no     = 148,
--              o_x    = 19,
--              o_y    = 4,
--              type   = 3,
--          },
--          [5] = {
--              no     = 149,
--              o_x    = 19,
--              o_y    = 5,
--              type   = 0,
--          },
--          [6] = {
--              no     = 150,
--              o_x    = 19,
--              o_y    = 6,
--              type   = 0,
--          },
--          [7] = {
--              no     = 151,
--              o_x    = 19,
--              o_y    = 7,
--              type   = 0,
--          },
--          [8] = {
--              no     = 152,
--              o_x    = 19,
--              o_y    = 8,
--              type   = 0,
--          },
--      },
--      [20] = {
--          [1] = {
--              no     = 153,
--              o_x    = 20,
--              o_y    = 1,
--              type   = 0,
--          },
--          [2] = {
--              no     = 154,
--              o_x    = 20,
--              o_y    = 2,
--              type   = 0,
--          },
--          [3] = {
--              no     = 155,
--              o_x    = 20,
--              o_y    = 3,
--              type   = 5,
--          },
--          [4] = {
--              no     = 156,
--              o_x    = 20,
--              o_y    = 4,
--              type   = 5,
--          },
--          [5] = {
--              no     = 157,
--              o_x    = 20,
--              o_y    = 5,
--              type   = 0,
--          },
--          [6] = {
--              no     = 158,
--              o_x    = 20,
--              o_y    = 6,
--              type   = 0,
--          },
--          [7] = {
--              no     = 159,
--              o_x    = 20,
--              o_y    = 7,
--              type   = 0,
--          },
--          [8] = {
--              no     = 160,
--              o_x    = 20,
--              o_y    = 8,
--              type   = 0,
--          },
--      },
--  }

--  local lucky_map={
--      [52] = 1,
--      [68] = 1,
--      [84] = 1,
--      [92] = 1,
--  }
-- local xc_num_map,lucky_lian_count,round_map=this.get_xcNumMap(xc_moreInfo_map,lucky_map,true)
-- dump(xc_num_map)
-- print(this.get_rate_by_xcNumMap(xc_num_map))
-- print(this.check_map_is_have_lucky_lian(xc_moreInfo_map,lucky_map,4))
--test  hewei *************


return this






