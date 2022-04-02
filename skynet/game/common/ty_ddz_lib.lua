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
    -- 16: 假王炸
    -- 17: 超级炸弹
    -- 18：超级王炸

--]]
local tyDdzFunc ={}
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
    [14] = 2,
    [15] = 4,
    [16] = 2,
    [17] = 5,
    [18] = 3,
}

tyDdzFunc.act_type={
    jdz = 100,
    jiabei = 101,
    men = 102, --：闷
    kp = 103, --：看牌
    zp = 104, --：抓牌
    bz = 105, --：不抓
    dao = 106, --：倒
    bd = 107, --：不倒
    la = 108, --：拉
    bl = 109, --：不拉
}

local act_type = tyDdzFunc.act_type

tyDdzFunc.pai_map = {
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
    17,
    18,
}
local pai_map=tyDdzFunc.pai_map
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
    54,
    55
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
    54,
    55
}

--各种牌型的关键牌数量
local key_pai_num={1,2,3,3,3,1,2,4,4,3,3,3,4,2,4,2,5,3}
--向下一个人移交出牌权
local function guo(_play_data)
	_play_data.cur_p=_play_data.cur_p+1
	if _play_data.cur_p>3 then 
		_play_data.cur_p=1
	end
end
-- --统计牌的类型
function tyDdzFunc.get_pai_typeHash_by_list(_pai_list)
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
function tyDdzFunc.get_pai_typeHash(_pai)
    local _hash = {}
    for _id, _v in pairs(_pai) do
        if _v then
            _hash[pai_map[_id]] = _hash[pai_map[_id]] or 0
            _hash[pai_map[_id]] = _hash[pai_map[_id]] + 1
        end
    end
    return _hash
end
function tyDdzFunc.get_pai_list_by_map(_map)
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
start 起始点
c_num 选择数量
no_choose 不能选择的type map
返回值 牌类型 普通牌使用数量  癞子使用数量 
--]]
local function add_value_to_map(map,k,v)
    map[k]=map[k] or 0
    map[k]=map[k]+v
end
local function choose_paiType_by_num(phash,lz_num,start,c_num,no_choose,ty_type)
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
    if c_num>1 then
        --其次选比他小的 但加上癞子符合的
        for type,num in pairs(phash) do
            --癞子不能变大小王 所以要小于16      num必须大于零因为 为零时 癞子只能是他自己本身
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
    end
    if c_num<4 then
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
    end
    --最后癞子能代替的
    if ty_type and lz_num>=c_num and not no_choose[ty_type] and ty_type>=start then
        return ty_type,0,c_num
    end

    return nil
end
--单牌或者对子
local function get_dpOrDz_combination(phash,lz_num,start,no_choose,n_num)
    --听用不能当做单牌出
    if n_num ==1 then
        lz_num=0
    end
    local c_t_1,u_n_1,u_lz_n_1=choose_paiType_by_num(phash,lz_num,start,n_num,no_choose)
    if c_t_1 then
        return n_num,{c_t_1},{nor={[c_t_1]=u_n_1},lz={[c_t_1]=u_lz_n_1}}
    end
    return nil
end
--三带N 返回值  牌型分解 普通牌使用情况（key=paiTpye,value=num）  癞子牌使用情况key=paiTpye,value=num）   
local function get_3dn_combination(phash,lz_num,start,no_choose,n_num)
    
    local c_t_1,u_n_1,u_lz_n_1=choose_paiType_by_num(phash,lz_num,start,3,no_choose)
    if c_t_1 then
        if n_num and n_num==1 then
             --癞子不能带
            local c_t_2,u_n_2,u_lz_n_2=choose_paiType_by_num(phash,0,3,n_num,{[c_t_1]=true})
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
local function get_4dn_combination(phash,lz_num,start,no_choose,n_num)
    local c_t_1,u_n_1,u_lz_n_1=choose_paiType_by_num(phash,lz_num,start,4,no_choose)
    if c_t_1 then
        local nc={[c_t_1]=true}
        --癞子不能带
        local c_t_2,u_n_2,u_lz_n_2=choose_paiType_by_num(phash,0,0,n_num,nc)
        if c_t_2 then
            local _phash=basefunc.copy(phash)
            --4带2
            if n_num==1 then
                if _phash[c_t_2] and _phash[c_t_2]>0 then
                    _phash[c_t_2]=_phash[c_t_2]-1
                end
            else
               return nil
            end
            --  ty_type = 18
            local c_t_3,u_n_3,u_lz_n_3=choose_paiType_by_num(_phash,lz_num-u_lz_n_1,0,n_num,nc,18)
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
local function get_lianxu_combination(phash,lz_num,start,lx_num,count)
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
local function get_shunzi_combination(phash,lz_num,start,lx_num)
    local pai,use,u_lz_n=get_lianxu_combination(phash,lz_num,start,lx_num,1)
    if pai then
        return 6,pai,use
    end
    return nil
end
--连队
local function get_liandui_combination(phash,lz_num,start,lx_num)
    local pai,use,u_lz_n=get_lianxu_combination(phash,lz_num,start,lx_num,2)
    if pai then
        return 7,pai,use
    end
    return nil
end
--飞机  不带
local function get_feiji_combination(phash,lz_num,start,lx_num)
    local pai,use,u_lz_n=get_lianxu_combination(phash,lz_num,start,lx_num,3)
    if pai then
        return 12,pai,use
    end
    return nil
end
--飞机带单牌
local function get_feijid1_combination(phash,lz_num,start,lx_num)
    local s=start
    local e=14-lx_num+1
    --要考虑所有情况
    while s<=e do 
        local pai,use,u_lz_n=get_lianxu_combination(phash,lz_num,start,lx_num,3)
        if pai then
            local flag=true
            local nc={}
            -- for i=pai[1],pai[2] do
            --     nc[i]=true
            -- end
            local hash={}
            _lz_num=lz_num-u_lz_n
            local _phash=basefunc.copy(phash)
            for i=pai[1],pai[2] do
                _phash[i]= _phash[i]-3
            end
            for i=1,lx_num do
                local ptype,u_num,u_lz_num=choose_paiType_by_num(_phash,_lz_num,0,1,nc,18)
                if ptype then
                    hash[ptype]=hash[ptype] or 0
                    hash[ptype]=hash[ptype]+1
                   
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
local function get_wazha_combination(phash,lz_num)
    if phash[16]==1 and phash[17]==1 then
        return 14,{16,17},{nor={[16]=1,[17]=1},lz={}}
    end
    return nil
end
local function get_realZhadan_combination(phash,lz_num,start,no_choose)
    local c_t_1,u_n_1,u_lz_n_1=choose_paiType_by_num(phash,0,start,4,no_choose)
    if c_t_1 then
        --  真炸弹
        return 13,{c_t_1},{ nor={ [c_t_1]=u_n_1},lz={ [c_t_1]=0} }
    end
    return nil
end
local function get_jiaZhadan_combination(phash,lz_num,start,no_choose) 
    local c_t_1,u_n_1,u_lz_n_1=choose_paiType_by_num(phash,lz_num,start,4,no_choose)
    if c_t_1 then
        if u_lz_n_1 and u_lz_n_1>0 then
          --  假炸弹
            return 15,{c_t_1},{ nor={ [c_t_1]=u_n_1},lz={ [c_t_1]=u_lz_n_1} }
        else
            no_choose[c_t_1]=true
            return get_jiaZhadan_combination(phash,lz_num,start,no_choose) 
        end
    end
    return nil
end
--假王炸
local function get_jiawazha_combination(phash,lz_num)
    if lz_num==1 then
        if phash[16]==1  then
            return 16,{16,17},{nor={[16]=1},lz={[17]=1}}
        elseif phash[17]==1 then
            return 16,{16,17},{nor={[17]=1},lz={[16]=1}}
        end
    end
    return nil
end
--超级炸弹
local function get_superZhadan_combination(phash,lz_num,start,no_choose)
    if lz_num==1 then
        local c_t_1,u_n_1,u_lz_n_1=choose_paiType_by_num(phash,0,3,4,no_choose)
        if c_t_1 then
            return 17,{c_t_1},{ nor={ [c_t_1]=u_n_1},lz={[18]=1} }
        end
    end
    return nil
end
--超级王炸
local function get_superWangzha_combination(phash,lz_num,start,no_choose)
    if lz_num==1 then
        if phash[16]==1 and phash[17]==1 then
            return 18,{16,17},{ nor={ [16]=1,[17]=1},lz={ [18]=1} }
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
function tyDdzFunc.sort_pai_by_amount(_pai_count)
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
--[[
    -- function tyDdzFunc.get_pai_type(_pai_list,_lz_num)
    --     if type(_pai_list)~="table" or #_pai_list==0 then 
    --         return {type=0}
    --     end
    --     local _pai = tyDdzFunc.sort_pai_by_amount(tyDdzFunc.get_pai_typeHash_by_list(_pai_list))
    --     if not _pai then
    --         return false
    --     end
    --     --最大的相同牌数量
    --     local _max_num = _pai[1].amount
    --     --牌的种类  忽略花色
    --     local _type_count = #_pai

    --     if _type_count == 1 then
    --         if _max_num == 4 then
    --             --假炸弹
    --             if _lz_num and _lz_num<4 and _lz_num>0 then
    --                 return {type = 15, pai = {_pai[1].type}}
    --             end
    --             return {type = 13, pai = {_pai[1].type}}
    --         elseif _max_num < 4 then
    --             return {type = _max_num, pai = {_pai[1].type}}
    --         end
    --     elseif _max_num == 4 then
    --         if _type_count == 2 then
    --             --四带二  被带的牌相同情况
    --             if _pai[2].amount == 2 then
    --                 return {type = 8, pai = {_pai[1].type, _pai[2].type, _pai[2].type}}
    --             end
    --         elseif _type_count == 3 then
    --             --四带二
    --             if _pai[2].amount == 1 and _pai[3].amount == 1 and (_pai[2].type ~= 16 or _pai[3].type ~= 17) then
    --                 --四带两对
    --                 return {type = 8, pai = {_pai[1].type, _pai[2].type, _pai[3].type}}
    --             elseif _pai[2].amount == 2 and _pai[3].amount == 2 then
    --                 return {type = 9, pai = {_pai[1].type, _pai[2].type, _pai[3].type}}
    --             end
    --         end
    --     elseif _max_num == 2 then
    --         if _type_count > 2 then
    --             local _flag = true
    --             for _i = 2, _type_count do
    --                 if _pai[_i].amount ~= 2 then
    --                     _flag = false
    --                     break
    --                 end
    --             end
    --             if _flag and _pai[_type_count].type < 15 and _pai[_type_count].type - _pai[1].type == _type_count - 1 then
    --                 return {type = 7, pai = {_pai[1].type, _pai[_type_count].type}}
    --             end
    --         end
    --     elseif _max_num == 1 then
    --         if _type_count == 2 then
    --             --王炸
    --             if _pai[1].type == 16 and _pai[2].type == 17 then
    --                 return {type = 14, pai = {_pai[1].type, _pai[2].type}}
    --             end
    --         elseif _type_count > 4 then
    --             --顺子
    --             if _pai[_type_count].type < 15 and _pai[_type_count].type - _pai[1].type == _type_count - 1 then
    --                 return {type = 6, pai = {_pai[1].type, _pai[_type_count].type}}
    --             end
    --         end
    --     elseif _max_num == 3 then
    --         local _max_len = 1
    --         local _head = 1
    --         local _tail = 1

    --         local _cur_len = 1
    --         local _cur_head = 1
    --         local _cur_tail = 1
    --         for _i = 2, _type_count do
    --             if _pai[_i].amount == 3 then
    --                 if _pai[_i - 1].type + 1 == _pai[_i].type and _pai[_i].type < 15 then
    --                     _cur_len = _cur_len + 1
    --                     _cur_tail = _i
    --                 else
    --                     _cur_len = 1
    --                     _cur_head = _i
    --                     _cur_tail = _i
    --                 end
    --                 if _cur_len > _max_len then
    --                     _max_len = _cur_len
    --                     _head = _cur_head
    --                     _tail = _cur_tail
    --                 end
    --             else
    --                 break
    --             end
    --         end
    --         if _max_len == _type_count then
    --             --裸飞机
    --             return {type = 12, pai = {_pai[1].type, _pai[_type_count].type}}
    --         else
    --             local _count = 0
    --             --是否全部为对子
    --             local _is_double = true
    --             --大小王统计
    --             local _boss_count = 0
    --             for _i = 1, _type_count do
    --                 if _i < _head or _i > _tail then
    --                     _count = _count + _pai[_i].amount
    --                     if _pai[_i].amount ~= 2 then
    --                         _is_double = false
    --                     end
    --                     if _pai[_i].type == 16 or _pai[_i].type == 17 then
    --                         _boss_count = _boss_count + 1
    --                     end
    --                 end
    --             end
    --             if _count == _max_len and _boss_count < 2 then
    --                 --三带一
    --                 if _max_len == 1 then
    --                     return {type = 4, pai = {_pai[1].type, _pai[2].type}}
    --                 else
    --                     --飞机带单牌
    --                     local _pai_type = {type = 10, pai = {_pai[_head].type, _pai[_tail].type}}
    --                     for _i = 1, _type_count do
    --                         if _i < _head or _i > _tail then
    --                             for _k = 1, _pai[_i].amount do
    --                                 _pai_type.pai[#_pai_type.pai + 1] = _pai[_i].type
    --                             end
    --                         end
    --                     end
    --                     return _pai_type
    --                 end
    --             elseif _count == _max_len * 2 and _is_double then
    --                 --三带对
    --                 if _max_len == 1 then
    --                     return {type = 5, pai = {_pai[1].type, _pai[2].type}}
    --                 else
    --                     --飞机带对子
    --                     local _pai_type = {type = 11, pai = {_pai[_head].type, _pai[_tail].type}}
    --                     for _i = 1, _type_count do
    --                         if _i < _head or _i > _tail then
    --                             _pai_type.pai[#_pai_type.pai + 1] = _pai[_i].type
    --                         end
    --                     end
    --                     return _pai_type
    --                 end
    --             end
    --         end
    --     end
    --     return false
    -- end
--]]
function tyDdzFunc.get_pai_type(_pai_list,_lz_num,_appoint_type)
    if type(_pai_list)~="table" or #_pai_list==0 then 
        return {type=0}
    end
    local _pai_type_map=tyDdzFunc.get_pai_typeHash_by_list(_pai_list)
    local _pai = tyDdzFunc.sort_pai_by_amount(_pai_type_map)
    if not _pai then
        return false
    end
    --牌的数量
    local _pai_count=#_pai_list

    --最大的相同牌数量
    local _max_num = _pai[1].amount
    --牌的种类  忽略花色
    local _type_count = #_pai

    --不能单独出听用
    if _pai_count==1 and _lz_num==1 then
        return false
    end
    --特殊牌*****************
    --假王炸
    if _pai_count==2 and (_lz_num==1 and (_pai_type_map[16]==1 or _pai_type_map[17]==1) ) then
        local _key_pai=_pai_type_map[16] or _pai_type_map[17]
        return {type = 16, pai = {pai,18}}
    end
    --超级炸弹
    if _pai_count==5 and _lz_num==1 and _max_num==4 and _pai_type_map[18]==1  then
        return {type = 17, pai = {_pai[1].type,18}}
    end
    --超级王炸
    if _pai_count==3 and _lz_num==1 and _pai_type_map[16]==1 and _pai_type_map[17]==1 and  _pai_type_map[18]==1 then
        return {type = 18, pai = {17,16,18}}
    end

    --三代一
    if _pai_count==4 and _type_count==2 and _max_num==3 then
        if _pai[2].amount==1 then
            return {type = 4, pai = {_pai[1].type, _pai[2].type}}
        end
    end

    if _type_count == 1 then
        if _max_num == 4 then
            --假炸弹
            if _lz_num and _lz_num<4 and _lz_num>0 then
                return {type = 15, pai = {_pai[1].type}}
            end
            return {type = 13, pai = {_pai[1].type}}
        --单牌  对子 三不带    
        elseif _max_num < 4 then
            return {type = _max_num, pai = {_pai[1].type}}
        end
    end
    if _max_num == 4 then
        if _type_count == 2 then
            --四带二  被带的牌相同情况
            if _pai[2].amount == 2 then
                return {type = 8, pai = {_pai[1].type, _pai[2].type, _pai[2].type}}
            end
        elseif _type_count == 3 then
            --四带二
            if _pai[2].amount == 1 and _pai[3].amount == 1 then
                return {type = 8, pai = {_pai[1].type, _pai[2].type, _pai[3].type}}
            -- 四带两对
            -- elseif _pai[2].amount == 2 and _pai[3].amount == 2 then
            --     return {type = 9, pai = {_pai[1].type, _pai[2].type, _pai[3].type}}
            end
        end
    end
    if _max_num == 2 then
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
    end
    if _max_num == 1 then
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
    end
    --计算飞机情况
    if _max_num > 2 and _type_count>1 then

        local _max_len = 1
        local _head = 1
        local _tail = 1

        for _k=3,13 do
            if _pai_type_map[_k] and _pai_type_map[_k] >2 then
                local _cur_len = nil
                local _cur_head = nil
                local _cur_tail = nil
                for _s=_k,_k+_type_count-1 do
                    if _pai_type_map[_s] and _pai_type_map[_s] >2 and _s<15 then
                        if not _cur_len then
                            _cur_len=1
                            _cur_head=_s
                            _cur_tail=_s
                        else
                            _cur_len=_cur_len+1
                            _cur_tail=_s
                        end
                        if _cur_len and _cur_len>1 and _cur_len>=_max_len then
                            _max_len = _cur_len
                            _head = _cur_head
                            _tail = _cur_tail
                        end
                    else
                        break
                    end
                end
            end
        end
        if _max_len>1 then
            --飞机不带
            if _max_len*3==_pai_count then
                --如果指定为飞机带单牌 就进行尝试是否可以变成飞机带单牌 
                if _appoint_type==10  then
                    if _max_len==4 then
                        return {type = 10, pai = {_head+1,_tail}}
                    end
                    return false
                end
                return {type = 12, pai = {_head,_tail}}
            elseif _max_len*4==_pai_count then
                return {type = 10, pai = {_head,_tail}}
            elseif _max_len>4 and (_max_len-1)*4==_pai_count then
                return {type = 10, pai = {_head+1,_tail}}
            end
        end
    end
    return false
end
--按单牌 ，对子，三不带，炸弹的顺序选择一种牌  ###_test
function tyDdzFunc.auto_choose_by_order(pai_id_map,pai_type_map,lz_num,_my_pai_count)

    local use_info={nor={},lz={}}  
    local _type = nil
    local _pai={}

    local package=function (pai_id_map,type,use_info)
                local cp_list=tyDdzFunc.get_cp_list_by_useInfo(pai_id_map,use_info)
                local lazi_num=0
                if cp_list.lz then
                    lazi_num=#cp_list.lz
                end
                local nor_num=0
                if cp_list.nor then
                    nor_num=#cp_list.nor
                end 
                --检查是否只剩最后一张牌  并且是 听用牌
                if _my_pai_count and lazi_num==0 and lz_num==1 and lazi_num+nor_num==_my_pai_count-1 then
                    if type==1 then
                        type=2

                    elseif type==2 then
                        type=3

                    elseif type==3 then
                        type=15

                    elseif type==13 then
                        type=17
                    end
                    if type==17 then
                        use_info.lz[18]=1
                    else
                        use_info.lz[_pai[1]]=1
                    end

                    lazi_num=1
                    cp_list=tyDdzFunc.get_cp_list_by_useInfo(pai_id_map,use_info)
                end
                return {
                                      type=type,
                                      cp_list=cp_list,
                                      merge_cp_list=tyDdzFunc.merge_nor_and_lz(cp_list),
                                      lazi_num=lazi_num
                                    }
            end


    if  lz_num==1 and _my_pai_count==2 and (pai_type_map[16]==1 or pai_type_map[17]==1 ) then
        if pai_type_map[16]==1 then
            _type=16
            _pai[1]=16
            _pai[2]=17
            use_info.nor[16]=1
            use_info.lz[17]=1
        elseif pai_type_map[17]==1 then
           _type=16
            _pai[1]=16
            _pai[2]=17
            use_info.nor[17]=1
            use_info.lz[16]=1
        end
    elseif lz_num==1 and _my_pai_count==3 and pai_type_map[16]==1 and pai_type_map[17]==1 then
        _type=18
        _pai[1]=16
        _pai[2]=17
        _pai[3]=18
        use_info.nor[16]=1
        use_info.nor[17]=1
        use_info.lz[18]=1
    else
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
        use_info.nor[_pai[1]]=key_pai_num[_type]
    end
   
   
    return package(pai_id_map,_type,use_info)
end
function tyDdzFunc.replace_maxpai_to_ty(use_info)
    local max=0
    for k,v in pairs(use_info.nor) do
        if k>max and v>0 then
            max=k
        end
    end
    if max>0 then
        use_info.nor[max]=use_info.nor[max] - 1
        if use_info.nor[max]==0 then
            use_info.nor[max]=nil
        end 
        use_info.lz=use_info.lz or {}
        use_info.lz[max]=1
        return true
    end
    return false
end

function tyDdzFunc.auto_choose_by_type(pai_id_map,pai_type_map,lz_num,appointType,key_pai,_my_pai_count)
    --###_test
    -- if true then
    --     return  {type=0}
    -- end

    if appointType==16 or appointType==17 or appointType==18 then 
        return {type=0}
    end
    if appointType==0 then
        return tyDdzFunc.auto_choose_by_order(pai_id_map,pai_type_map,lz_num,_my_pai_count)
    end
    
    local start_pos=3
    if appointType and appointType~=14 and  key_pai and key_pai[1] then
        start_pos=key_pai[1]+1
    end

    local result
    local package=function (pai_map,type,pai,use_info)
                local cp_list=tyDdzFunc.get_cp_list_by_useInfo(pai_map,use_info)
                local lazi_num=0
                if cp_list.lz then
                    lazi_num=#cp_list.lz
                end
                local nor_num=0
                if cp_list.nor then
                    nor_num=#cp_list.nor
                end 
                --检查是否只剩最后一张牌  并且是 听用牌
                if _my_pai_count and lazi_num==0 and lz_num==1 and lazi_num+nor_num==_my_pai_count-1 then
                    --单牌无法替换
                    if type==1 then
                        return     
                    end
                    --把牌中最大的一张替换为替用
                    if type>1 then
                        if type==13 then
                            type=17
                            lazi_num=1
                            cp_list.lz={55}
                        elseif type==14 then
                            type=18
                            lazi_num=1
                            cp_list.lz={55}
                        else
                            if tyDdzFunc.replace_maxpai_to_ty(use_info) then
                                lazi_num=1
                                cp_list=tyDdzFunc.get_cp_list_by_useInfo(pai_map,use_info)
                            else
                                error("auto_choose_by_type---replace_maxpai_to_ty!!!")
                            end
                        end
                    end
                end

                result={
                          type=type,
                          cp_list=cp_list,
                          merge_cp_list=tyDdzFunc.merge_nor_and_lz(cp_list),
                          lazi_num=lazi_num
                        }
            end

    if  appointType==1 then
        --单牌
        local type,pai,use_info=get_dpOrDz_combination(pai_type_map,lz_num,start_pos,{},1)
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    elseif appointType==2 then
        --对子
        local type,pai,use_info=get_dpOrDz_combination(pai_type_map,lz_num,start_pos,{},2)
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    elseif appointType==3 then
        --三不带
        local type,pai,use_info=get_3dn_combination(pai_type_map,lz_num,start_pos,{})
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    elseif appointType==4 then
        --三带一
        local type,pai,use_info=get_3dn_combination(pai_type_map,lz_num,start_pos,{},1)
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    elseif appointType==6 then
        --顺子
        local type,pai,use_info=get_shunzi_combination(pai_type_map,lz_num,start_pos,key_pai[2]-key_pai[1]+1)
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    elseif appointType==7 then 
        --连队
        local type,pai,use_info=get_liandui_combination(pai_type_map,lz_num,start_pos,key_pai[2]-key_pai[1]+1)
        if type then
            package(pai_id_map,type,pai,use_info)
        end 
    elseif appointType==8 then
        --四带2
        local type,pai,use_info=get_4dn_combination(pai_type_map,lz_num,start_pos,{},1)
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    elseif appointType==10 then
        --飞机带单牌
        local type,pai,use_info=get_feijid1_combination(pai_type_map,lz_num,start_pos,key_pai[2]-key_pai[1]+1)
        if type then
            package(pai_id_map,type,pai,use_info)
        end 
    elseif appointType==12 then
        --飞机不带
        local type,pai,use_info=get_feiji_combination(pai_type_map,lz_num,start_pos,key_pai[2]-key_pai[1]+1)
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    elseif appointType==13 then
        --真炸弹
        local type,pai,use_info=get_realZhadan_combination(pai_type_map,lz_num,start_pos,{})
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    elseif appointType==14 then
        --超级炸弹
        local type,pai,use_info=get_superZhadan_combination(pai_type_map,lz_num,3,{})
        if type then
            package(pai_id_map,type,pai,use_info)
        else
            return {type=0}
        end 
    elseif appointType==15 then 
        --假炸弹
        local type,pai,use_info=get_jiaZhadan_combination(pai_type_map,lz_num,start_pos,{})
        if type then
            package(pai_id_map,type,pai,use_info)
        end   
    end
    if not result and appointType<13 then 
        local type,pai,use_info=get_jiaZhadan_combination(pai_type_map,lz_num,3,{})
        if type then
            package(pai_id_map,type,pai,use_info)
        end       
    end
    if not result and appointType~=13 then 
        local type,pai,use_info=get_realZhadan_combination(pai_type_map,lz_num,3,{})
        if type then
            package(pai_id_map,type,pai,use_info)
        end      
    end
    if not result then 
        --super王炸
        local type,pai,use_info=get_superWangzha_combination(pai_type_map,lz_num)
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    end
    if not result then 
        --王炸
        local type,pai,use_info=get_wazha_combination(pai_type_map,lz_num)
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    end
    if not result then 
        --假王炸
        local type,pai,use_info=get_jiawazha_combination(pai_type_map,lz_num)
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    end
    if not result then
        --超级炸弹
        local type,pai,use_info=get_superZhadan_combination(pai_type_map,lz_num,3,{})
        if type then
            package(pai_id_map,type,pai,use_info)
        end
    end
    if not result then
        result={type=0}
    end
    return result
end
--检查出牌后是否只剩下替用牌
function tyDdzFunc.check_is_only_ty(cp_list,_my_pai_count,ty_num)
    local cp_ty_num=0
    local cp_nor_num=0
    if cp_list and cp_list.lz then
        cp_ty_num=#cp_list.lz
    end
    if cp_list and cp_list.nor then
        cp_nor_num=#cp_list.nor 
    end


    if cp_ty_num==1 or ty_num==0 then
        return false
    end 
    if cp_ty_num+cp_nor_num==_my_pai_count-1 then
        return true
    end
    return false
end
--获得牌的list  牌的类型，数量
function tyDdzFunc.get_pai_list_by_type(_pai_map, _type, _num, _list)
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
function tyDdzFunc.list_to_map(_list)
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
function tyDdzFunc.get_real_chupai_pos_by_act(_act_list)
    local _pos=#_act_list
    local _limit=_pos-2
    if _limit<0 then 
        _limit=0
    end
    while _pos>_limit do
        if _act_list[_pos].type>0 and _act_list[_pos].type<19 then 
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
function tyDdzFunc.check_chupai_safe(_act_list,_p,_type,_pai)
	local _is_must=tyDdzFunc.is_must_chupai(_act_list,_p)
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
		if _act_list[_pos].type>0 and _act_list[_pos].type<19 then 
			break
		end
		_pos=_pos-1
	end
	--上个人出的超级炸弹 超级王炸 或者假王炸
	if _act_list[_pos].type==16 or _act_list[_pos].type==17 or _act_list[_pos].type==18 then 
		return false
	end
     --当前人出的足够大
    if _type==16 or _type==17 or _type==18 then 
        return true
    end
    --上个人出的王炸
    if _act_list[_pos].type==14 then
        if _type==17 then
            return true
        end
        return false
    end

	--和上个人出的牌的类型一致
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
        ----当前人出的足够大
        if _type==16 or _type==17 or _type==18 then 
            return true
        end
		--当前人出的是假炸弹
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
--_other_cp_list:其他玩家的出牌，_my_pai_list:我手里的牌 _my_pai_count--我剩余的牌数量
function tyDdzFunc.cp_hint(_other_type,_other_pai,pai_id_map,lz_num,_my_pai_count)

	local pai_type_map=tyDdzFunc.get_pai_typeHash(pai_id_map)
	pai_type_map[18]=nil
    if _other_type then
        result = tyDdzFunc.auto_choose_by_type(pai_id_map,pai_type_map,lz_num,_other_type, _other_pai,_my_pai_count)
    else
        result = tyDdzFunc.auto_choose_by_order(pai_id_map,pai_type_map,lz_num,_my_pai_count)
    end
    return result

end

function tyDdzFunc.is_must_chupai(_act_list)
    if #_act_list==0  or _act_list[#_act_list].type>=100 or ( #_act_list>1 and  _act_list[#_act_list].type==0 and _act_list[#_act_list-1].type==0) then 
        return true
    end
    return false
end

--检测自己是否有出牌的能力  0有资格，1没资格，2完全没资格（对方王炸） 对方所出牌的类型，出牌类型类型对应的牌，我的牌的hash
function tyDdzFunc.check_cp_capacity(_act_list,pai_id_map,lz_num,_my_pai_count)
    local _other_type=0
    local _other_pai
    local _pos=tyDdzFunc.get_real_chupai_pos_by_act(_act_list)
    if _pos then
        _other_type=_act_list[_pos].type
        _other_pai=_act_list[_pos].pai
    end


    if _other_type==0 then 
        return 0
    elseif _other_type==16 or _other_type==17 or _other_type==18 then 
        return 2
    else
    	--将癞子牌去掉
    	local pai_type_map=tyDdzFunc.get_pai_typeHash(pai_id_map)
		pai_type_map[18]=nil

        --如果我有双王
        if  pai_type_map[16]==1 and pai_type_map[17]==1 then
            return 0
        end

         --如果我有假王炸
        if  (pai_type_map[16]==1 or pai_type_map[17]==1) and lz_num==1 then
            return 0
        end

        --拥有各种数量的牌的统计
        local _type_num={0,0,0,0}
        for _k,_v in pairs(pai_type_map) do
            if _v>0 then
                _type_num[_v]=_type_num[_v]+1
            end
        end

         --我有超级炸弹 
        if lz_num==1 and _type_num[4]>0 then
            return 0
        end


        --我有炸弹 且对方没出炸弹
        if _other_type~=13 and _other_type~=15 and   (_type_num[4]>0  or (lz_num==1 and _type_num[3]>0) ) then
            return 0
        end
        if _other_type==15 and _type_num[4]>0  then
        	return 0
        end
        local res=tyDdzFunc.auto_choose_by_type(pai_id_map,pai_type_map,lz_num,_other_type,_other_pai,_my_pai_count)
        if res and res.type>0 then
            return 0
        end
        return 1    
    end
end
--获得出牌中使用的癞子数量
function tyDdzFunc.get_cp_list_useLZ_num(cp_list)
    local num=0
    if cp_list.lz then
        num=#cp_list.lz
    end
    return num
end

function tyDdzFunc.getAllPaiCount()
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
        [18]=1,
    }
end
function tyDdzFunc.jipaiqi(_cp_list,_jipaiqi)
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
	    	_jipaiqi[18]=_jipaiqi[18]-# _cp_list.lz
	    end
    end
end


--通过各种牌的使用信息 或者与服务器通讯的格式 cp_list
function tyDdzFunc.get_cp_list_by_useInfo(pai_id_map,useInfo)
    local nor_list={}
    if useInfo.nor then
        for k,v in pairs(useInfo.nor) do
            if v>0 then
                tyDdzFunc.get_pai_list_by_type(pai_id_map, k, v, nor_list)
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
function tyDdzFunc.merge_nor_and_lz(cp_list)
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
                --只能在 1-55 之间
                if v<1 or v>55  then
                    return false
                end
                list[#list+1]=v
                is_have_lz=true
            end
        end 
    end 
    return list,is_have_lz
end

function tyDdzFunc.get_pai_list_by_map(_map)	
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
function tyDdzFunc.xipai()
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
            55,
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
        --     55,
        -- }
	return _pai	
end
--发牌
function  tyDdzFunc.fapai(_pai,_play_data,_num)
	if not _num then 
		_num=1
	end
	local _fapai_count=#_pai-4
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
	for i=_fapai_count+1,55 do
		_play_data.dz_pai[#_play_data.dz_pai+1]=_pai[i]
	end
end
function tyDdzFunc.deduct_pai_by_cp_list(_pai_data,cp_list)
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
			local num=#cp_list.lz
            if num==1 then
    			_pai_data.pai[55]=nil
                if _pai_data.hash then
    			     _pai_data.hash[18]=_pai_data.hash[18]-1
                end
            end
		end
	end
end
function tyDdzFunc.chupai(_data,_p,_type,act_cp_list,_merge_cp_list,lazi_num)
	local _cp_type=tyDdzFunc.get_pai_type(_merge_cp_list,lazi_num,_type)
	if not _cp_type or _cp_type.type~=_type then 
		--出牌不合法
		return 1003
	end
	if not tyDdzFunc.check_chupai_safe(_data.play_data.act_list,_p,_type,_cp_type.pai) then
		--出牌不合法
		return 1003
	end

	_data.play_data.act_list[#_data.play_data.act_list+1]={type=_type,p=_p,pai=_cp_type.pai,lazi_num=lazi_num,cp_list=act_cp_list,merge_cp_list=_merge_cp_list}

	if _type~=0 then
		tyDdzFunc.deduct_pai_by_cp_list(_data.play_data[_p],act_cp_list,_data.laizi) 
		_data.play_data[_p].remain_pai=_data.play_data[_p].remain_pai-#_merge_cp_list
		if _data.play_data[_p].remain_pai==0 then 
			--game_over
			return 1
		end
	end
	guo(_data.play_data)
	return 0
end
function  tyDdzFunc.new_game()
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
function  tyDdzFunc.get_dz_candidate(_play_data)
    ---
	_play_data.dz_candidate=math.random(1,3)
	_play_data.cur_p=_play_data.dz_candidate
end
--地主产生则返回座位号 否则返回0 返回false表示叫地主失败
function tyDdzFunc.jiao_dizhu(_play_data,_p,_rate) 
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
	_play_data.act_list[#_play_data.act_list+1]={type=act_type.jdz,p=_p,rate=_rate}
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
function tyDdzFunc.jiabei(_play_data,_p_rate,_p,_rate)
	_play_data.act_list[#_play_data.act_list+1]={type=act_type.jiabei,p=_p,rate=_rate}
	if _rate>0 then 
		_p_rate[1]=_p_rate[1]*_rate
		_p_rate[2]=_p_rate[2]*_rate
		_p_rate[3]=_p_rate[3]*_rate
	end
	local _count=0
	local _is_jiabei=0
	for i=#_play_data.act_list,1,-1 do
		if _play_data.act_list[i].type==act_type.jiabei then 
			_count=_count+1
			if _play_data.act_list[i].rate>0 then 
				_is_jiabei=_is_jiabei+1
			end
		else
			break
		end
	end
	if _count==1 then
		--第一个人喊加倍 
		return 1
	--农民完成加倍
	elseif _count==2 then
		if _is_jiabei==0 then
			--加倍结束 
			return 3
		end
		_play_data.cur_p=_play_data.dizhu 
		return 2
	--所有人完成加倍  加倍结束	
	elseif _count==3 then 
		return 4
	end 
end
--发地主牌
function  tyDdzFunc.fapai_dizhu(_dz_pai,_dz_play_data)
	for i=1,4 do
		_dz_play_data.pai[_dz_pai[i]]=true
	end
	_dz_play_data.remain_pai=21
end
function  tyDdzFunc.set_dizhu(_play_data,_dizhu)
	assert(_dizhu==1 or _dizhu==2 or _dizhu==3)
	_play_data.dizhu=_dizhu
	_play_data.cur_p=_dizhu
	tyDdzFunc.fapai_dizhu(_play_data.dz_pai,_play_data[_dizhu])
end

--是否必倒
function tyDdzFunc.is_must_dao(map)
    local wang=0
    local two=0
    if map[16]==1 then
        wang=wang+1
    end
    if map[17]==1 then
        wang=wang+1
    end
    if map[15] then
        two=map[15]
    end
    if wang==2 or wang+two>2 then
        return true
    end
    local zhadan=0
    for _,v in pairs(map) do
        if v==4 then
            zhadan=zhadan+1
        end
    end
    if zhadan>1 or zhadan+wang+two>2 then
        return true
    end
    return false
end
--是否必抓
function tyDdzFunc.is_must_zhua(map)
    local wang=0
    local two=0
    if map[16]==1 then
        wang=wang+1
    end
    if map[17]==1 then
        wang=wang+1
    end
    if map[15] then
        two=map[15]
    end
    if wang==2 or wang+two>2 then
        return true
    end
    local zhadan=0
    for _,v in pairs(map) do
        if v==4 then
            zhadan=zhadan+1
        end
    end
    if zhadan>1 or zhadan+wang+two>2 then
        return true
    end
    return false
end

return tyDdzFunc






 