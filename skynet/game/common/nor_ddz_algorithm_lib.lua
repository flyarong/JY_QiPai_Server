
local basefunc = require "basefunc"
require"printfunc"
local nor_ddz_base_lib = require "nor_ddz_base_lib"

local nor_ddz_algorithm=basefunc.class()
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
--key=牌类型  value=此类型的牌的张数，特殊牌（如：顺子）则是最少张数

local pai_type=nor_ddz_base_lib.pai_type
local other_type=nor_ddz_base_lib.other_type
local pai_map=nor_ddz_base_lib.pai_map
local pai_to_startId_map=nor_ddz_base_lib.pai_to_startId_map
local pai_to_endId_map=nor_ddz_base_lib.pai_to_endId_map
local lz_id=nor_ddz_base_lib.lz_id
local lz_id_to_type=nor_ddz_base_lib.lz_id_to_type

--各种牌型的关键牌数量
nor_ddz_base_lib.key_pai_num={1,2,3,3,3,1,2,4,4,3,3,3,4,2,4}
local key_pai_num=nor_ddz_base_lib.key_pai_num
local KAIGUAN=nor_ddz_base_lib.KAIGUAN

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
    if lz_num>=c_num and lz_num>0 and not no_choose[lz_type] and lz_type>=start then
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

--{ type,pai}
local function get_pai_type(_pai_list,_lz_num)
    if type(_pai_list)~="table" or #_pai_list==0 then 
        return {type=0}
    end
    local _pai = nor_ddz_base_lib.sort_pai_by_amount(nor_ddz_base_lib.get_pai_typeHash_by_list(_pai_list))
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
function nor_ddz_algorithm:get_pai_type(_pai_list,_lz_num)
    local res=get_pai_type(_pai_list,_lz_num)
    return res
end

--按单牌 ，对子，三不带，炸弹的顺序选择一种牌
function nor_ddz_algorithm:auto_choose_by_order(pai_id_map,pai_type_map,lz_num,lz_type)
    local package=function (pai_id_map,type,pai,use_info)
                    local cp_list=nor_ddz_base_lib.get_cp_list_by_useInfo(pai_id_map,use_info)
                    local lazi_num=0
                    if cp_list.lz then
                        lazi_num=#cp_list.lz
                    end
                    return {
                              type=type,
                              cp_list=cp_list,
                              merge_cp_list=nor_ddz_base_lib.merge_nor_and_lz(cp_list),
                              lazi_num=lazi_num,
                              pai=pai
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
                    --如果没有开三不带则不能三不带除了只剩最后三张
                    if self.kaiguan[3] then
                        _type = 3
                        _pai[1] = _i
                    else
                        local count=0
                        for k,v in pairs(pai_id_map) do
                            count=count+1
                        end
                        --只剩最后三张也可以出三不带
                        if count==3 then
                            _type = 3
                            _pai[1] = _i
                        else
                            _type = 2
                            _pai[1] = _i
                        end
                    end
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
    return package(pai_id_map,_type,_pai,use_info)
end

function nor_ddz_algorithm:auto_choose_by_type(pai_id_map,pai_type_map,lz_num,lz_type,appointType,key_pai)

    if appointType==14 then 
        return {type=0}
    end
    if appointType==0 then
        return self:auto_choose_by_order(pai_id_map,pai_type_map,lz_num,lz_type)
    end
    
    local start_pos=3
    if key_pai and key_pai[1] then
        start_pos=key_pai[1]+1
    end
    local result
    local package=function (pai_map,type,pai,use_info)
                    local cp_list=nor_ddz_base_lib.get_cp_list_by_useInfo(pai_map,use_info,game_type)
                    local lazi_num=0
                    if cp_list.lz then
                        lazi_num=#cp_list.lz
                    end
                    result={
                              type=type,
                              cp_list=cp_list,
                              merge_cp_list=nor_ddz_base_lib.merge_nor_and_lz(cp_list),
                              lazi_num=lazi_num,
                              pai=pai
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
    if not result or not self.kaiguan[result.type] then
        result={type=0}
    end

    return result
end


--_other_cp_list:其他玩家的出牌，_my_pai_list:我手里的牌
function nor_ddz_algorithm:cp_hint(_other_type,_other_pai,pai_id_map,lz_num,lz_type)

	local pai_type_map=nor_ddz_base_lib.get_pai_typeHash(pai_id_map)
	pai_type_map[lz_type]=nil

    if _other_type then
        result = self:auto_choose_by_type(pai_id_map,pai_type_map,lz_num,lz_type,_other_type, _other_pai)
    else
        result = self:auto_choose_by_order(pai_id_map,pai_type_map,lz_num,lz_type)
    end
    return result
end

--检测自己是否有出牌的能力  0有资格，1没资格，2完全没资格（对方王炸） 对方所出牌的类型，出牌类型类型对应的牌，我的牌的hash
function nor_ddz_algorithm:check_cp_capacity(_act_list,pai_id_map,lz_num,lz_type)
    local _other_type=0
    local _other_pai
    local _pos=nor_ddz_base_lib.get_real_chupai_pos_by_act(_act_list)
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
    	local pai_type_map=nor_ddz_base_lib.get_pai_typeHash(pai_id_map)
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
        local res=self:auto_choose_by_type(pai_id_map,pai_type_map,lz_num,lz_type,_other_type,_other_pai)
        if res.type>0 then
            return 0
        end
        return 1    
    end
end

-- _gametype : laizi  nor  斗地主的类型
function nor_ddz_algorithm:ctor(_kaiguan,_gametype)
    self.type=_type
    self.kaiguan=_kaiguan or KAIGUAN
end
function nor_ddz_algorithm:mld_is_bimen(pai_map)
  local boom=0
  local zhu=0
  for i=1,14 do
    if pai_map[i] and pai_map[i]==4 then
      boom=boom+1
    end
  end
  for i=15,17 do
    if pai_map[i] then
      zhu=zhu+pai_map[i]
    end
  end

  if boom>1 or zhu+boom>2 then
    return true
  end

  if pai_map[16] and pai_map[17] and pai_map[16]==1 and pai_map[17]==1 then
    return true
  end

  return false
end

return nor_ddz_algorithm















 