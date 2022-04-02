local basefunc=require"basefunc"
require"printfunc"
---------斗地主出牌
--[[
    协议：
        {
            type 0 : integer,--(出牌类型）
            pai 1 :*integer,--出的牌
        }
    牌类型
        3-17 分别表示
        3 4 5 6 7 8 9 10 J Q K A 2 小王 大王
    出牌类型
    -- 0： 过
    -- 1： 单牌
    -- 2： 对子
    -- 3： 三不带
    -- 4： 三带一    pai[1]代表三张部分 ，p[2]代表被带的牌
    -- 5： 三带一对    pai[1]代表三张部分 ，p[2]代表被带的对子
    -- 6： 顺子     pai[1]代表顺子起点牌，p[2]代表顺子终点牌
    -- 7： 连队         pai[1]代表连队起点牌，p[2]代表连队终点牌
    -- 8： 四带2        pai[1]代表四张部分 ，p[2]p[3]代表被带的牌
    -- 9： 四带两对
    -- 10：飞机带单牌（只能全部带单牌） pai[1]代表飞机起点牌，p[2]代表飞机终点牌，后面依次是要带的牌
    -- 11：飞机带对子（只能全部带对子）
    -- 12：飞机  不带
    -- 13：炸弹
    -- 14：王炸
    -- 15：假炸弹

--]]
local lzDdzFunc ={}
--key=牌类型  value=此类型的牌的张数，特殊牌（如：顺子）则是最少张数
local pai_type = {
    [0] = 0,
    [1] = 1,
    [2] = 2,
    [3] = 3,
    [4] = 4,
    [5] = 5,
    [6] = 5,
    [7] = 6,
    [8] = 6,
    [9] = 8,
    [10] = 8,
    [11] = 10,
    [12] = 6,
    [13] = 4,
    [14] = 2
}
--16
local other_type = {
    jdz = 100,
    jiabei = 101
}
lzDdzFunc.pai_map = {
    3,
    3,
    3,
    3,
    4,
    4,
    4,
    4,
    5,
    5,
    5,
    5,
    6,
    6,
    6,
    6,
    7,
    7,
    7,
    7,
    8,
    8,
    8,
    8,
    9,
    9,
    9,
    9,
    10,
    10,
    10,
    10,
    11,
    11,
    11,
    11,
    12,
    12,
    12,
    12,
    13,
    13,
    13,
    13,
    14,
    14,
    14,
    14,
    15,
    15,
    15,
    15,
    16,
    17
}
local pai_map=lzDdzFunc.pai_map
--各类型的牌的起始id
local pai_to_startId_map = {
    0,
    0,
    1,
    5,
    9,
    13,
    17,
    21,
    25,
    29,
    33,
    37,
    41,
    45,
    49,
    53,
    54
}
--各类型的牌的结束id
local pai_to_endId_map = {
    0,
    0,
    4,
    8,
    12,
    16,
    20,
    24,
    28,
    32,
    36,
    40,
    44,
    48,
    52,
    53,
    54
}
local lz_id={
    0,
    0,
    60,  --3
    61,  --4
    62,  --5
    63,  --6
    64,  --7
    65,  --8
    66,  --9
    67,  --10
    68,  --11
    69,  --12
    70,  --13
    71,  --14
    72,  --15
    73,  --16
    74,  --17 
}
local lz_id_to_type={
    [60]=3,
    [61]=4,
    [62]=5,
    [63]=6,
    [64]=7,
    [65]=8,
    [66]=9,
    [67]=10,
    [68]=11,
    [69]=12,
    [70]=13,
    [71]=14,
    [72]=15,
    [73]=16,
    [74]=17, 
}
--各种牌型的关键牌数量
local key_pai_num={1,2,3,3,3,1,2,4,4,3,3,3,4,2,}
--向下一个人移交出牌权
local function guo(_play_data)
	_play_data.cur_p=_play_data.cur_p+1
	if _play_data.cur_p>3 then 
		_play_data.cur_p=1
	end
end
-- --统计牌的类型
function lzDdzFunc.get_pai_typeHash_by_list(_pai_list)
    if type(_pai_list) == "table" then
        local _pai_type_count = {}
        for _, _p_id in ipairs(_pai_list) do
            _pai_type_count[pai_map[_p_id]] = _pai_type_count[pai_map[_p_id]] or 0
            _pai_type_count[pai_map[_p_id]] = _pai_type_count[pai_map[_p_id]] + 1
        end
        return _pai_type_count
    end
    return nil
end
function lzDdzFunc.get_pai_typeHash(_pai)
    local _hash = {}
    for _id, _v in pairs(_pai) do
        if _v then
            _hash[pai_map[_id]] = _hash[pai_map[_id]] or 0
            _hash[pai_map[_id]] = _hash[pai_map[_id]] + 1
        end
    end
    return _hash
end
function lzDdzFunc.get_pai_list_by_map(_map)
    if _map then
        local list = {}
        for _pai_id, _v in pairs(_map) do
            if _v then
                list[#list + 1] = _pai_id
            end
        end
        return list
    end
    return nil
end
--[[
phash 备选的牌hash
lz_num 癞子的数量
lz_type 癞子牌的牌类型
start 起始点
c_num 选择数量
no_choose 不能选择的type map
返回值 牌类型 普通牌使用数量  癞子使用数量 
--]]
local function add_value_to_map(map,k,v)
    map[k]=map[k] or 0
    map[k]=map[k]+v
end
local function choose_paiType_by_num(phash,lz_num,lz_type,start,c_num,no_choose)
    --优先选天生符合的
    local p_type,u_num,u_lz_num
    for type,num in pairs(phash) do
        if not no_choose[type] and type>=start and num==c_num then
            if not p_type then
                p_type=type
                u_num=num 
                u_lz_num=0
            --尽量选小牌
            elseif type<p_type then
                p_type=type
                u_num=num 
                u_lz_num=0
            end
        end
    end
    if p_type then
        return p_type,u_num,u_lz_num
    end

    --其次选比他小的 但加上癞子符合的
    for type,num in pairs(phash) do
        --癞子不能变大小王 所以要小于16
        if not no_choose[type] and type>=start and num>0 and num<c_num  and num+lz_num>=c_num and type<16 then
            if not p_type then
                p_type=type
                u_num=num 
                u_lz_num=c_num-num
            --使用癞子少的牌
            elseif (num>u_num) or (num==u_num and type<p_type) then
                p_type=type
                u_num=num 
                u_lz_num=c_num-num
            end
        end
    end
    if p_type then
        return p_type,u_num,u_lz_num
    end
    local max_num
    --再其次选比他大的符合的
    for type,num in pairs(phash) do
        if not no_choose[type] and type>=start and num>c_num then
            if not p_type then
                p_type=type
                u_num=c_num
                max_num=num
                u_lz_num=0
            --尽量选数量少的牌 
            elseif (num<max_num) or (num==max_num and type<p_type) then
                p_type=type
                u_num=c_num
                max_num=num 
                u_lz_num=0
            end
        end
    end
    if p_type then
        return p_type,u_num,u_lz_num
    end
    --最后癞子能代替的
    if lz_num>=c_num and not no_choose[lz_type] and lz_type>=start then
        return lz_type,0,c_num
    end


    return nil
end
--单牌或者对子
local function get_dpOrDz_combination(phash,lz_num,lz_type,start,no_choose,n_num)
    
    local c_t_1,u_n_1,u_lz_n_1=choose_paiType_by_num(phash,lz_num,lz_type,start,n_num,no_choose)
    if c_t_1 then
        return n_num,{c_t_1},{nor={[c_t_1]=u_n_1},lz={[c_t_1]=u_lz_n_1}}
    end
    return nil
end
--三带N 返回值  牌型分解 普通牌使用情况（key=paiTpye,value=num）  癞子牌使用情况key=paiTpye,value=num）   
local function get_3dn_combination(phash,lz_num,lz_type,start,no_choose,n_num)
    
    local c_t_1,u_n_1,u_lz_n_1=choose_paiType_by_num(phash,lz_num,lz_type,start,3,no_choose)
    if c_t_1 then
        if n_num and n_num>0 then
            local c_t_2,u_n_2,u_lz_n_2=choose_paiType_by_num(phash,lz_num-u_lz_n_1,lz_type,3,n_num,{[c_t_1]=true})
            if c_t_2 then
                local use_info={nor={},lz={}}
                add_value_to_map( use_info.nor,c_t_1,u_n_1)
                add_value_to_map( use_info.nor,c_t_2,u_n_2)
                add_value_to_map( use_info.lz,c_t_1,u_lz_n_1)
                add_value_to_map( use_info.lz,c_t_2,u_lz_n_2)
                --成功选取到
                return 3+n_num,{c_t_1,c_t_2},use_info
            end
        else
            --3不带
            return 3,{c_t_1},{nor={[c_t_1]=u_n_1},lz={[c_t_1]=u_lz_n_1}}
        end
    end
    return nil
end
local function get_4dn_combination(phash,lz_num,lz_type,start,no_choose,n_num)
    local c_t_1,u_n_1,u_lz_n_1=choose_paiType_by_num(phash,lz_num,lz_type,start,4,no_choose)
    if c_t_1 then
        local nc={[c_t_1]=true}
        local c_t_2,u_n_2,u_lz_n_2=choose_paiType_by_num(phash,lz_num-u_lz_n_1,lz_type,0,n_num,nc)
        if c_t_2 then
            local _phash=basefunc.copy(phash)
            --4带2
            if n_num==1 then
                if _phash[c_t_2] and _phash[c_t_2]>0 then
                    _phash[c_t_2]=_phash[c_t_2]-1
                end
                -- 不能同时选双王
                if c_t_2>15 then
                    nc[16]=true
                    nc[17]=true
                end
            --4带2对    
            else
               nc[c_t_2]=true 
            end
            local c_t_3,u_n_3,u_lz_n_3=choose_paiType_by_num(_phash,lz_num-u_lz_n_1-u_lz_n_2,lz_type,0,n_num,nc)
            if c_t_3 then
                --成功选取到
                local use_info={nor={},lz={}}
                add_value_to_map(use_info.nor,c_t_1,u_n_1)
                add_value_to_map(use_info.nor,c_t_2,u_n_2)
                add_value_to_map(use_info.nor,c_t_3,u_n_3)
                add_value_to_map(use_info.lz,c_t_1,u_lz_n_1)
                add_value_to_map(use_info.lz,c_t_2,u_lz_n_2)
                add_value_to_map(use_info.lz,c_t_3,u_lz_n_3)
                return 7+n_num,{c_t_1,c_t_2,c_t_3},use_info
            end
        end
    end
    return nil
end
local function get_lianxu_combination(phash,lz_num,lz_type,start,lx_num,count)
    local s=start
    local e=14-lx_num+1
    while s<=e do
        local _num=phash[s] or 0
        if _num+lz_num>=count then
            local _lz=lz_num
            local _e=s+lx_num-1
            local nor={}
            local lz={}
            for i=s,_e do
                _num=phash[i] or 0
                if _num+_lz<count then
                    s=s+1
                    break
                else
                    local nor_use=_num
                    if nor_use>count then
                        nor_use=count
                    end
                    nor[i]=nor_use
                    lz[i]=count-nor_use
                    _lz=_lz-(count-nor_use)
                end
                --成功匹配
                if i==_e then
                    return {s,_e},{nor=nor,lz=lz},lz_num-_lz
                end 
            end
        else
            s=s+1
        end
    end
    return nil
end
--顺子
local function get_shunzi_combination(phash,lz_num,lz_type,start,lx_num)
    local pai,use,u_lz_n=get_lianxu_combination(phash,lz_num,lz_type,start,lx_num,1)
    if pai then
        return 6,pai,use
    end
    return nil
end
--连队
local function get_liandui_combination(phash,lz_num,lz_type,start,lx_num)
    local pai,use,u_lz_n=get_lianxu_combination(phash,lz_num,lz_type,start,lx_num,2)
    if pai then
        return 7,pai,use
    end
    return nil
end
--飞机  不带
local function get_feiji_combination(phash,lz_num,lz_type,start,lx_num)
    local pai,use,u_lz_n=get_lianxu_combination(phash,lz_num,lz_type,start,lx_num,3)
    if pai then
        return 12,pai,use
    end
    return nil
end
--飞机带对子（只能全部带对子）
local function get_feijid2_combination(phash,lz_num,lz_type,start,lx_num)
    local s=start
    local e=14-lx_num+1
    --要考虑所有情况
    while s<=e do 
        local pai,use,u_lz_n=get_lianxu_combination(phash,lz_num,lz_type,start,lx_num,3)
        if pai then
            local flag=true
            local nc={}
            for i=pai[1],pai[2] do
                nc[i]=true
            end
            _lz_num=lz_num-u_lz_n
            for i=1,lx_num do
                local ptype,u_num,u_lz_num=choose_paiType_by_num(phash,_lz_num,lz_type,0,2,nc)
                if ptype then
                    nc[ptype]=true
                    _lz_num=_lz_num-u_lz_num
                    pai[#pai+1]=ptype
                    add_value_to_map(use.nor,ptype,u_num)
                    add_value_to_map(use.lz,ptype,u_lz_num)
                else
                    flag=false
                    break
                end
            end
            if flag then
                --成功
                return 11,pai,use 
            end 
        else
            return nil
        end
        s=s+1
    end
    return nil
end
--飞机带单牌
local function get_feijid1_combination(phash,lz_num,lz_type,start,lx_num)
    local s=start
    local e=14-lx_num+1
    --要考虑所有情况
    while s<=e do 
        local pai,use,u_lz_n=get_lianxu_combination(phash,lz_num,lz_type,start,lx_num,3)
        if pai then
            local flag=true
            local nc={}
            for i=pai[1],pai[2] do
                nc[i]=true
            end
            local hash={}
            _lz_num=lz_num-u_lz_n
            local _phash=basefunc.copy(phash)
            for i=1,lx_num do
                local ptype,u_num,u_lz_num=choose_paiType_by_num(_phash,_lz_num,lz_type,0,1,nc)
                if ptype then
                    hash[ptype]=hash[ptype] or 0
                    hash[ptype]=hash[ptype]+1
                    --双王只能2选一
                    if ptype>15 then
                       nc[16]=true
                       nc[17]=true
                    end
                    --不能有炸弹
                    if hash[ptype]==3 then
                        nc[ptype]=true
                    end
                    --防止变成了 飞机不带
                    if hash[ptype]==2 and ptype==pai[1]-1 and ptype>=3  then
                        nc[ptype]=true
                    end
                    if hash[ptype]==2 and ptype==pai[2]+1 and ptype<15  then
                        nc[ptype]=true
                    end
                    if _phash[ptype] and _phash[ptype]>0 then
                        _phash[ptype]=_phash[ptype]-u_num
                    end
                    _lz_num=_lz_num-u_lz_num
                    pai[#pai+1]=ptype
                    add_value_to_map(use.nor,ptype,u_num)
                    add_value_to_map(use.lz,ptype,u_lz_num)
                else
                    flag=false
                    break
                end
            end
            if flag then
                --成功
                return 10,pai,use 
            end 
        else
            return nil
        end
        s=s+1
    end
    return nil
end
 --王炸
local function get_wazha_combination(phash,lz_num,lz_type)
    if phash[16]==1 and phash[17]==1 then
        return 14,{16,17},{nor={[16]=1,[17]=1},lz={}}
    end
    return nil
end
local function get_realZhadan_combination(phash,lz_num,lz_type,start,no_choose)
    local c_t_1,u_n_1,u_lz_n_1=choose_paiType_by_num(phash,0,lz_type,start,4,no_choose)
    if c_t_1 then
        --  真炸弹
        return 13,{c_t_1},{ nor={ [c_t_1]=u_n_1},lz={ [c_t_1]=0} }
    else
        if lz_num==4 and lz_type>=start then
            return 13,{lz_type},{ nor={ [lz_type]=0},lz={ [lz_type]=4} }
        end
    end
    return nil
end
local function get_jiaZhadan_combination(phash,lz_num,lz_type,start,no_choose) 
    local c_t_1,u_n_1,u_lz_n_1=choose_paiType_by_num(phash,lz_num,lz_type,start,4,no_choose)
    if c_t_1 then
        if u_lz_n_1 and u_lz_n_1>0 and u_lz_n_1<4 then
          --  假炸弹
            return 15,{c_t_1},{ nor={ [c_t_1]=u_n_1},lz={ [c_t_1]=u_lz_n_1} }
        else
            no_choose[c_t_1]=true
            return get_jiaZhadan_combination(phash,lz_num,lz_type,start,no_choose) 
        end
    end
    return nil
end
-- --[[
-- {
--  _pai=
--  {
--      {
--      type,
--      amount,
--      }
--  }
--  按 数量从高到低  牌从小到大排好序
-- }
-- --]]
function lzDdzFunc.sort_pai_by_amount(_pai_count)
    if type(_pai_count) == "table" then
        local _pai = {}
        for _id, _amount in pairs(_pai_count) do
            _pai[#_pai + 1] = {type = _id, amount = _amount}
        end
        table.sort(
            _pai,
            function(a, b)
                if a.amount ~= b.amount then
                    return a.amount > b.amount
                end
                return a.type < b.type
            end
        )
        if #_pai==0 then
            return nil
        end
        return _pai
    end
    return nil
end
function lzDdzFunc.get_pai_type(_pai_list,_lz_num)
    if type(_pai_list)~="table" or #_pai_list==0 then 
        return {type=0}
    end
    local _pai = lzDdzFunc.sort_pai_by_amount(lzDdzFunc.get_pai_typeHash_by_list(_pai_list))
    if not _pai then
        return false
    end
    --最大的相同牌数量
    local _max_num = _pai[1].amount
    --牌的种类  忽略花色
    local _type_count = #_pai

    if _type_count == 1 then
        if _max_num == 4 then
            --假炸弹
            if _lz_num and _lz_num<4 and _lz_num>0 then
                return {type = 15, pai = {_pai[1].type}}
            end
            return {type = 13, pai = {_pai[1].type}}
        elseif _max_num < 4 then
            return {type = _max_num, pai = {_pai[1].type}}
        end
    elseif _max_num == 4 then
        if _type_count == 2 then
            --四带二  被带的牌相同情况
            if _pai[2].amount == 2 then
                return {type = 8, pai = {_pai[1].type, _pai[2].type, _pai[2].type}}
            end
        elseif _type_count == 3 then
            --四带二
            if _pai[2].amount == 1 and _pai[3].amount == 1 and (_pai[2].type ~= 16 or _pai[3].type ~= 17) then
                --四带两对
                return {type = 8, pai = {_pai[1].type, _pai[2].type, _pai[3].type}}
            elseif _pai[2].amount == 2 and _pai[3].amount == 2 then
                return {type = 9, pai = {_pai[1].type, _pai[2].type, _pai[3].type}}
            end
        end
    elseif _max_num == 2 then
        if _type_count > 2 then
            local _flag = true
            for _i = 2, _type_count do
                if _pai[_i].amount ~= 2 then
                    _flag = false
                    break
                end
            end
            if _flag and _pai[_type_count].type < 15 and _pai[_type_count].type - _pai[1].type == _type_count - 1 then
                return {type = 7, pai = {_pai[1].type, _pai[_type_count].type}}
            end
        end
    elseif _max_num == 1 then
        if _type_count == 2 then
            --王炸
            if _pai[1].type == 16 and _pai[2].type == 17 then
                return {type = 14, pai = {_pai[1].type, _pai[2].type}}
            end
        elseif _type_count > 4 then
            --顺子
            if _pai[_type_count].type < 15 and _pai[_type_count].type - _pai[1].type == _type_count - 1 then
                return {type = 6, pai = {_pai[1].type, _pai[_type_count].type}}
            end
        end
    elseif _max_num == 3 then
        local _max_len = 1
        local _head = 1
        local _tail = 1

        local _cur_len = 1
        local _cur_head = 1
        local _cur_tail = 1
        for _i = 2, _type_count do
            if _pai[_i].amount == 3 then
                if _pai[_i - 1].type + 1 == _pai[_i].type and _pai[_i].type < 15 then
                    _cur_len = _cur_len + 1
                    _cur_tail = _i
                else
                    _cur_len = 1
                    _cur_head = _i
                    _cur_tail = _i
                end
                if _cur_len > _max_len then
                    _max_len = _cur_len
                    _head = _cur_head
                    _tail = _cur_tail
                end
            else
                break
            end
        end
        if _max_len == _type_count then
            --裸飞机
            return {type = 12, pai = {_pai[1].type, _pai[_type_count].type}}
        else
            local _count = 0
            --是否全部为对子
            local _is_double = true
            --大小王统计
            local _boss_count = 0
            for _i = 1, _type_count do
                if _i < _head or _i > _tail then
                    _count = _count + _pai[_i].amount
                    if _pai[_i].amount ~= 2 then
                        _is_double = false
                    end
                    if _pai[_i].type == 16 or _pai[_i].type == 17 then
                        _boss_count = _boss_count + 1
                    end
                end
            end
            if _count == _max_len and _boss_count < 2 then
                --三带一
                if _max_len == 1 then
                    return {type = 4, pai = {_pai[1].type, _pai[2].type}}
                else
                    --飞机带单牌
                    local _pai_type = {type = 10, pai = {_pai[_head].type, _pai[_tail].type}}
                    for _i = 1, _type_count do
                        if _i < _head or _i > _tail then
                            for _k = 1, _pai[_i].amount do
                                _pai_type.pai[#_pai_type.pai + 1] = _pai[_i].type
                            end
                        end
                    end
                    return _pai_type
                end
            elseif _count == _max_len * 2 and _is_double then
                --三带对
                if _max_len == 1 then
                    return {type = 5, pai = {_pai[1].type, _pai[2].type}}
                else
                    --飞机带对子
                    local _pai_type = {type = 11, pai = {_pai[_head].type, _pai[_tail].type}}
                    for _i = 1, _type_count do
                        if _i < _head or _i > _tail then
                            _pai_type.pai[#_pai_type.pai + 1] = _pai[_i].type
                        end
                    end
                    return _pai_type
                end
            end
        end
    end
    return false
end
--按单牌 ，对子，三不带，炸弹的顺序选择一种牌
function lzDdzFunc.auto_choose_by_order(pai_id_map,pai_type_map,lz_num,lz_type)
    local package=function (pai_id_map,type,use_info)
                local cp_list=lzDdzFunc.get_cp_list_by_useInfo(pai_id_map,use_info)
                local lazi_num=0
                if cp_list.lz then
                    lazi_num=#cp_list.lz
                end
                return {
                                      type=type,
                                      cp_list=cp_list,
                                      merge_cp_list=lzDdzFunc.merge_nor_and_lz(cp_list),
                                      lazi_num=lazi_num
                                    }
            end

    local _type = nil
    local _pai={}
    for _i = 3, 17 do
        if pai_type_map[_i] then
            --danpai
            if pai_type_map[_i] == 1 then
                _pai[1] = _i
                _type=1
                break
            elseif pai_type_map[_i] == 2 then
                if not _type or _type > 2 then
                    _type = 2
                    _pai[1] = _i
                end
            elseif pai_type_map[_i] == 3 then
                if not _type or _type > 3 then
                    _type = 3
                    _pai[1] = _i
                end
            elseif pai_type_map[_i] == 4 then
                if not _type then
                    _type = 13
                    _pai[1] = _i
                end
            end
        end
    end
    local use_info={nor={},lz={}}  
    if not _type and lz_num>0 then
        _type =1
        _pai[1]=lz_type
        use_info.lz[lz_type]=1
    else
        use_info.nor[_pai[1]]=key_pai_num[_type]
    end
    return package(pai_id_map,_type,use_info)
end
function lzDdzFunc.auto_choose_by_type(pai_id_map,pai_type_map,lz_num,lz_type,appointType,key_pai)
    --###_test
    -- if true then
    --     return  {type=0}
    -- end
    if appointType==14 then 
        return {type=0}
    end
    if appointType==0 then
        return lzDdzFunc.auto_choose_by_order(pai_id_map,pai_type_map,lz_num,lz_type)
    end
    
    local start_pos=3
    if key_pai and key_pai[1] then
        start_pos=key_pai[1]+1
    end

    local result
    local package=function (pai_map,type,pai,use_info)
                local cp_list=lzDdzFunc.get_cp_list_by_useInfo(pai_map,use_info)
                local lazi_num=0
                if cp_list.lz then
                    lazi_num=#cp_list.lz
                end
                result={
                          type=type,
                          cp_list=cp_list,
                          merge_cp_list=lzDdzFunc.merge_nor_and_lz(cp_list),
                          lazi_num=lazi_num
                        }
            end

    if  appointType==1 then
        --单牌
        local type,pai,use_info=get_dpOrDz_combination(pai_type_map,lz_num,lz_type,start_pos,{},1)
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    elseif appointType==2 then
        --对子
        local type,pai,use_info=get_dpOrDz_combination(pai_type_map,lz_num,lz_type,start_pos,{},2)
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    elseif appointType==3 then
        --三不带
        local type,pai,use_info=get_3dn_combination(pai_type_map,lz_num,lz_type,start_pos,{})
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    elseif appointType==4 then
        --三带一
        local type,pai,use_info=get_3dn_combination(pai_type_map,lz_num,lz_type,start_pos,{},1)
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    elseif appointType==5 then
        --三带二
        local type,pai,use_info=get_3dn_combination(pai_type_map,lz_num,lz_type,start_pos,{},2)
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    elseif appointType==6 then
        --顺子
        local type,pai,use_info=get_shunzi_combination(pai_type_map,lz_num,lz_type,start_pos,key_pai[2]-key_pai[1]+1)
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    elseif appointType==7 then 
        --连队
        local type,pai,use_info=get_liandui_combination(pai_type_map,lz_num,lz_type,start_pos,key_pai[2]-key_pai[1]+1)
        if type then
            package(pai_id_map,type,pai,use_info)
        end 
    elseif appointType==8 then
        --四带2
        local type,pai,use_info=get_4dn_combination(pai_type_map,lz_num,lz_type,start_pos,{},1)
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    elseif appointType==9 then
        --四带2对
        local type,pai,use_info=get_4dn_combination(pai_type_map,lz_num,lz_type,start_pos,{},2)
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    elseif appointType==10 then
        --飞机带单牌
        local type,pai,use_info=get_feijid1_combination(pai_type_map,lz_num,lz_type,start_pos,key_pai[2]-key_pai[1]+1)
        if type then
            package(pai_id_map,type,pai,use_info)
        end 
    elseif appointType==11 then
        --飞机带单牌
        local type,pai,use_info=get_feijid2_combination(pai_type_map,lz_num,lz_type,start_pos,key_pai[2]-key_pai[1]+1)
        if type then
            package(pai_id_map,type,pai,use_info)
        end 
    elseif appointType==12 then
        --飞机不带
        local type,pai,use_info=get_feiji_combination(pai_type_map,lz_num,lz_type,start_pos,key_pai[2]-key_pai[1]+1)
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    elseif appointType==13 then
        --真炸弹
        local type,pai,use_info=get_realZhadan_combination(pai_type_map,lz_num,lz_type,start_pos,{})
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    elseif appointType==15 then 
        --假炸弹
        local type,pai,use_info=get_jiaZhadan_combination(pai_type_map,lz_num,lz_type,start_pos,{})
        if type then
            package(pai_id_map,type,pai,use_info)
        end   
    end
    if not result and appointType<13 then 
        local type,pai,use_info=get_jiaZhadan_combination(pai_type_map,lz_num,lz_type,3,{})
        if type then
            package(pai_id_map,type,pai,use_info)
        end       
    end
    if not result and appointType~=13 then 
        local type,pai,use_info=get_realZhadan_combination(pai_type_map,lz_num,lz_type,3,{})
        if type then
            package(pai_id_map,type,pai,use_info)
        end      
    end
    if not result then 
        --王炸
        local type,pai,use_info=get_wazha_combination(pai_type_map,lz_num,lz_type)
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    end
    if not result then
        result={type=0}
    end
    return result
end
--获得牌的list  牌的类型，数量
function lzDdzFunc.get_pai_list_by_type(_pai_map, _type, _num, _list)
    _list = _list or {}
    if type(_num) == "number" and _num > 0 then
        for _i = pai_to_startId_map[_type], pai_to_endId_map[_type] do
            if _pai_map[_i] then
                _list[#_list + 1] = _i
                _num = _num - 1
                if _num == 0 then
                    break
                end
            end
        end
        if _num > 0 then
            return false
        end
    end
    return _list
end
function lzDdzFunc.list_to_map(_list)
    if _list then
        local _map = {}
        for _, _id in ipairs(_list) do
            _map[_id] = _map[_id] or 0
            _map[_id]= _map[_id]+1
        end
        return _map
    end
    return nil
end
--从出牌序列中获得最近出牌的人的位置
function lzDdzFunc.get_real_chupai_pos_by_act(_act_list)
    local _pos=#_act_list
    local _limit=_pos-2
    if _limit<0 then 
        _limit=0
    end
    while _pos>_limit do
        if _act_list[_pos].type>0 and _act_list[_pos].type<16 then 
            break
        end
        _pos=_pos-1
    end
    if _pos==_limit then
        return nil
    end
    return _pos
end

--检测出的牌是否合法          
function lzDdzFunc.check_chupai_safe(_act_list,_p,_type,_pai)
	local _is_must=lzDdzFunc.is_must_chupai(_act_list,_p)
	if _type==0 then 
		if _is_must then
			return false
		end
		return true
	end
	if _is_must then 
		return true
	end
	local _pos=#_act_list
	while _pos>0 do
		if _act_list[_pos].type>0 and _act_list[_pos].type<16 then 
			break
		end
		_pos=_pos-1
	end
	--上个人出的王炸
	if _act_list[_pos].type==14 then 
		return false
	end
	--必须要和上个人出的牌的类型一致
	if _type==_act_list[_pos].type then
		if _type<6 or _type==13 or _type==15 or _type==8 or _type==9 then 
			if _pai[1]>_act_list[_pos].pai[1] then 
				return true
			end
		else
			local sum=_pai[2]-_pai[1]
			if sum==_act_list[_pos].pai[2]-_act_list[_pos].pai[1] and _pai[1]>_act_list[_pos].pai[1] then 
				return true
			end
		end
	else
		--当前人出的是炸弹或王炸
		if _act_list[_pos].type~=13 or _type==15 then 
			return true
		end
		--当前人出的是炸弹或王炸
		if _type==13 or _type==14 then 
			return true
		end
	end
	return false
end
--_other_cp_list:其他玩家的出牌，_my_pai_list:我手里的牌
function lzDdzFunc.cp_hint(_other_type,_other_pai,pai_id_map,lz_num,lz_type)

	local pai_type_map=lzDdzFunc.get_pai_typeHash(pai_id_map)
	pai_type_map[lz_type]=nil

    if _other_type then
        result = lzDdzFunc.auto_choose_by_type(pai_id_map,pai_type_map,lz_num,lz_type,_other_type, _other_pai)
    else
        result = lzDdzFunc.auto_choose_by_order(pai_id_map,pai_type_map,lz_num,lz_type)
    end
    return result

end

function lzDdzFunc.is_must_chupai(_act_list)
    if #_act_list==0  or _act_list[#_act_list].type>=100 or ( #_act_list>1 and  _act_list[#_act_list].type==0 and _act_list[#_act_list-1].type==0) then 
        return true
    end
    return false
end

--检测自己是否有出牌的能力  0有资格，1没资格，2完全没资格（对方王炸） 对方所出牌的类型，出牌类型类型对应的牌，我的牌的hash
function lzDdzFunc.check_cp_capacity(_act_list,pai_id_map,lz_num,lz_type)
    local _other_type=0
    local _other_pai
    local _pos=lzDdzFunc.get_real_chupai_pos_by_act(_act_list)
    if _pos then
        _other_type=_act_list[_pos].type
        _other_pai=_act_list[_pos].pai
    end


    if _other_type==0 then 
        return 0
    elseif _other_type==14 then 
        return 2
    else
    	--将癞子牌去掉
    	local pai_type_map=lzDdzFunc.get_pai_typeHash(pai_id_map)
		pai_type_map[lz_type]=nil
        --如果我有双王
        if  pai_type_map[16]==1 and pai_type_map[17]==1 then
            return 0
        end
        --拥有各种数量的牌的统计
        local _type_num={0,0,0,0}
        for _k,_v in pairs(pai_type_map) do
            if _v>0 then
                _type_num[_v]=_type_num[_v]+1
            end
        end


        --我有炸弹 且对方没出炸弹
        if _other_type~=13 and _other_type~=15 and  (_type_num[4]>0 or lz_num==4 or (lz_num>0 and _type_num[3]>0) or (lz_num>1 and _type_num[2]>0) or (lz_num>2 and _type_num[1]>0)) then
            return 0
        end
        if _other_type==15 and (_type_num[4]>0 or lz_num==4) then
        	return 0
        end
        local res=lzDdzFunc.auto_choose_by_type(pai_id_map,pai_type_map,lz_num,lz_type,_other_type,_other_pai)
        if res.type>0 then
            return 0
        end
        return 1    
    end
end
--获得出牌中使用的癞子数量
function lzDdzFunc.get_cp_list_useLZ_num(cp_list)
    local num=0
    if cp_list.lz then
        num=#cp_list.lz
    end
    return num
end

function lzDdzFunc.getAllPaiCount()
    return {
        [1]=0,
        [2]=0,
        [3]=0,
        [3]=4,
        [4]=4,
        [5]=4,
        [6]=4,
        [7]=4,
        [8]=4,
        [9]=4,
        [10]=4,
        [11]=4,
        [12]=4,
        [13]=4,
        [14]=4,
        [15]=4,
        [16]=1,
        [17]=1,
    }
end
function lzDdzFunc.jipaiqi(_cp_list,_jipaiqi,_laizi_type)
    local pai=nil
    if _cp_list then
    	if _cp_list.nor then
	        local k
	        for _,v in ipairs(_cp_list.nor) do
	            k=pai_map[v]
	            _jipaiqi[k]=_jipaiqi[k]-1
	        end
	    end
	    if _cp_list.lz then
	    	_jipaiqi[_laizi_type]=_jipaiqi[_laizi_type]-# _cp_list.lz
	    end
    end
end


--如果一个序列里面的牌是癞子变化而来的 则将其转换为癞子序号
function lzDdzFunc.list_convert_to_lz(list,lz_map)
    if lz_map then
        for idx,v in ipairs(list) do
            local _v=pai_map[v]
            if lz_map[_v] and lz_map[_v]>0 then
                --变为lz对应的序号 ###_test
                list[idx]=lz_id[_v]
                lz_map[_v]=lz_map[_v]-1
            end
        end
    end
    return list
end

--通过各种牌的使用信息 或者与服务器通讯的格式 cp_list
function lzDdzFunc.get_cp_list_by_useInfo(pai_id_map,useInfo)
    local nor_list={}
    if useInfo.nor then
        for k,v in pairs(useInfo.nor) do
            if v>0 then
                lzDdzFunc.get_pai_list_by_type(pai_id_map, k, v, nor_list)
            end
        end
    end
    local lz_list={}
    if useInfo.lz then
        for k,v in pairs(useInfo.lz) do
            if v>0 then
                for i=1,v do
                    lz_list[#lz_list+1]=pai_to_endId_map[k]
                end
            end
        end
    end
    if #nor_list==0 then
        nor_list=nil
    end
    if #lz_list==0 then
        lz_list=nil
    end
    return {nor=nor_list,lz=lz_list}
end
--将普通牌和癞子牌合并  参数 服务器通讯的格式 cp_list 并返回是否含有lz
function lzDdzFunc.merge_nor_and_lz(cp_list)
    local list={}
    local is_have_lz=false
    if cp_list then
        if cp_list.nor then
            for _,v in ipairs(cp_list.nor) do
                list[#list+1]=v
            end
        end
        if cp_list.lz then
            for _,v in ipairs(cp_list.lz) do
                --癞子只能在1-52之间
                if v<1 or v>52 then
                    return false
                end
                list[#list+1]=v
                is_have_lz=true
            end
        end 
    end 
    return list,is_have_lz
end

function lzDdzFunc.get_pai_list_by_map(_map)	
	if _map then 
		local list={}
		for _pai_id,_v in pairs(_map) do
			if _v then 
				list[#list+1]=_pai_id
			end
		end
		return list
	end
	return nil
end

--**********************逻辑辅助函数
--洗牌
function lzDdzFunc.xipai()
	local _pai={
			1,2,3,4,
			5,6,7,8,
			9,10,11,12,
			13,14,15,16,
			17,18,19,20,
			21,22,23,24,
			25,26,27,28,
			29,30,31,32,
			33,34,35,36,
			37,38,39,40,
			41,42,43,44,
			45,46,47,48,
			49,50,51,52,
			53,
			54,
		}		
	local _count=#_pai
	local _rand=1
	local _jh	
	for _i=1,_count-1 do 
		_jh=_pai[_i]
		_rand=math.random(_i,_count)
		_pai[_i]=_pai[_rand]
		_pai[_rand]=_jh
	end
    -- 炸弹
        -- local _pai={
        --     1,2,3,4,
        --     25,26,27,28,
        --     21,22,23,24,
        --     29,30,31,32,
        --     33,34,35,36,
        --     17,18,19,20,
        --     37,38,39,40,
        --     13,14,15,16,
        --     41,42,43,44,
        --     9,10,11,12,
        --     45,46,47,48,
        --     5,6,7,8,
        --     49,50,51,52,
        --     53,
        --     54,
        -- }
	return _pai	
end
--发牌
function  lzDdzFunc.fapai(_pai,_play_data,_num)
	if not _num then 
		_num=1
	end
	local _fapai_count=#_pai-3
	local _i=1
	while _i<=_fapai_count do
		for _p=1,3 do
			if _play_data[_p].remain_pai<17 then
				for _k=1,_num do
					_play_data[_p].pai[_pai[_i]]=true
					_play_data[_p].remain_pai=_play_data[_p].remain_pai+1
					_i=_i+1
					if _play_data[_p].remain_pai>=17 then 
						break
					end
				end
			end
		end
	end
	for i=_fapai_count+1,54 do
		_play_data.dz_pai[#_play_data.dz_pai+1]=_pai[i]
	end


	if false then
		return
	end
	-- end
end
function lzDdzFunc.deduct_pai_by_cp_list(_pai_data,cp_list,laizhi_type)
	if cp_list  then 
		if cp_list.nor then
			for _,_pai_id in ipairs(cp_list.nor) do
				if _pai_data.hash then
					_pai_data.hash[pai_map[_pai_id]]=_pai_data.hash[pai_map[_pai_id]]-1
				end
				_pai_data.pai[_pai_id]=nil
			end
		end
		if cp_list.lz then
			local s=pai_to_startId_map[laizhi_type]
			local e=pai_to_endId_map[laizhi_type]
			local num=#cp_list.lz
			for i=s,e do
				if num<1 then
					break
				end
				if _pai_data.pai[i] then
					_pai_data.pai[i]=nil
					if _pai_data.hash then
						_pai_data.hash[laizhi_type]=_pai_data.hash[laizhi_type]-1
					end
					num=num-1
				end
			end
		end
	end
end
function lzDdzFunc.chupai(_data,_p,_type,act_cp_list,_merge_cp_list,lazi_num)
	local _cp_type=lzDdzFunc.get_pai_type(_merge_cp_list,lazi_num)
	if not _cp_type or _cp_type.type~=_type then 
		--出牌不合法
		return 1003
	end
	if not lzDdzFunc.check_chupai_safe(_data.play_data.act_list,_p,_type,_cp_type.pai) then
		--出牌不合法
		return 1003
	end

	_data.play_data.act_list[#_data.play_data.act_list+1]={type=_type,p=_p,pai=_cp_type.pai,lazi_num=lazi_num,cp_list=act_cp_list,merge_cp_list=_merge_cp_list}

	if _type~=0 then
		lzDdzFunc.deduct_pai_by_cp_list(_data.play_data[_p],act_cp_list,_data.laizi) 
		_data.play_data[_p].remain_pai=_data.play_data[_p].remain_pai-#_merge_cp_list
		if _data.play_data[_p].remain_pai==0 then 
			--game_over
			return 1
		end
	end
	guo(_data.play_data)
	return 0
end
function  lzDdzFunc.new_game()
	local _play_data={}
	--地主
	_play_data.dizhu=0
	--首位地主候选人
	_play_data.dz_candidate=0
	--当前出牌权或者叫地主等权限的拥有人
	_play_data.cur_p=0
	--已出出牌序列
	_play_data.act_list={}
	--地主牌
	_play_data.dz_pai={}
	--玩家数据 key=位置号（1，2，3） 
	for i=1,3 do
		_play_data[i]={}
		--手里全部牌的列表
		_play_data[i].pai={}
		--剩余的牌数量
		_play_data[i].remain_pai=0
	end
	return _play_data
end
--获得第一位地主候选人
function  lzDdzFunc.get_dz_candidate(_play_data)
    --- 
	_play_data.dz_candidate=math.random(1,3)
	_play_data.cur_p=_play_data.dz_candidate
end
--地主产生则返回座位号 否则返回0 返回false表示叫地主失败
function lzDdzFunc.jiao_dizhu(_play_data,_p,_rate) 
	if not _p or _p~=_play_data.cur_p then 
		--非法的出牌顺序
		return 1002
	end
	
	local _max=0
	local _pos=0
	for i=#_play_data.act_list,1,-1 do 
		if _play_data.act_list[i].rate>_max then 
			_max=_play_data.act_list[i].rate
			_pos=_play_data.act_list[i].p
		end
	end
	--必须越来越大
	if _rate<=_max and _rate~=0 then
		return 1003
	else
		if _rate~=0 then
			_pos=_p
			_max=_rate
		end
	end
	_play_data.act_list[#_play_data.act_list+1]={type=other_type.jdz,p=_p,rate=_rate}
	if _rate==3 then
		_play_data.cur_p=0 
		return _p
	end 
	guo(_play_data)

	if _play_data.cur_p==_play_data.dz_candidate then
		 _play_data.cur_p=0 
		if _max>0 then 
			return _pos
		end
		--没有地主
		return -1
	end
	return 0 
	
end
function lzDdzFunc.jiabei(_play_data,_p_rate,_p,_rate)
	_play_data.act_list[#_play_data.act_list+1]={type=other_type.jiabei,p=_p,rate=_rate}
	if _rate>0 then 
		_p_rate[1]=_p_rate[1]*_rate
		_p_rate[2]=_p_rate[2]*_rate
		_p_rate[3]=_p_rate[3]*_rate
	end
    if _rate>0  then 
        if  _play_data.dizhu==_p then
            _p_rate[1]=_p_rate[1]*_rate
            _p_rate[2]=_p_rate[2]*_rate
            _p_rate[3]=_p_rate[3]*_rate
        else
            local cur_rate=_p_rate[_p]
            _p_rate[_p]=_p_rate[_p]*_rate
            _p_rate[_play_data.dizhu]=_p_rate[_play_data.dizhu]+_p_rate[_p]-cur_rate
        end
    end

	local _count=0
	local _is_jiabei=0
	for i=#_play_data.act_list,1,-1 do
		if _play_data.act_list[i].type==other_type.jiabei then 
			_count=_count+1
			if _play_data.act_list[i].rate>0 then 
				_is_jiabei=_is_jiabei+1
			end
		else
			break
		end
	end
	if _count==3 then 
		return 4
	end 
end
--发地主牌
function  lzDdzFunc.fapai_dizhu(_dz_pai,_dz_play_data)
	for i=1,3 do
		_dz_play_data.pai[_dz_pai[i]]=true
	end
	_dz_play_data.remain_pai=20
end
function  lzDdzFunc.set_dizhu(_data,_dizhu)
	assert(_dizhu==1 or _dizhu==2 or _dizhu==3)

    local _rate=_data.p_jdz[_dizhu]
    local all_rate=0
    for i=1,3 do
        _data.p_rate[i]=_data.p_rate[i]*_rate
        if i~=_dizhu then
            all_rate=all_rate+_data.p_rate[i]
        end
    end
    _data.p_rate[_dizhu]=all_rate
    _data.play_data.dizhu=_dizhu
    _data.play_data.cur_p=_dizhu
    lzDdzFunc.fapai_dizhu(_data.play_data.dz_pai,_data.play_data[_dizhu])
end

return lzDdzFunc






 