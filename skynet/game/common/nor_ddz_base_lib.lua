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
local nor_ddz_base_lib ={}
--key=牌类型  value=此类型的牌的张数，特殊牌（如：顺子）则是最少张数
nor_ddz_base_lib.pai_type = {
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
    [15] = 4
}
local pai_type=nor_ddz_base_lib.pai_type


nor_ddz_base_lib.other_type = {
    jdz = 100,
    jiabei = 101,
    er_qdz=102,
    mld_kp = 103, --：看牌
    mld_zhua = 104, --：抓牌
    mld_bz = 105, --：不抓
    mld_dao = 106, --：倒
    mld_bd = 107, --：不倒
    mld_la = 108, --：拉
    mld_bl = 109, --：不拉
    mld_men = 110, --：闷
}

local other_type=nor_ddz_base_lib.other_type
nor_ddz_base_lib.pai_map = {
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
local pai_map=nor_ddz_base_lib.pai_map
--各类型的牌的起始id
nor_ddz_base_lib.pai_to_startId_map = {
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
local pai_to_startId_map=nor_ddz_base_lib.pai_to_startId_map

--各类型的牌的结束id
nor_ddz_base_lib.pai_to_endId_map = {
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
local pai_to_endId_map=nor_ddz_base_lib.pai_to_endId_map

nor_ddz_base_lib.lz_id={
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
local lz_id=nor_ddz_base_lib.lz_id

nor_ddz_base_lib.lz_id_to_type={
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
local lz_id_to_type=nor_ddz_base_lib.lz_id_to_type

--各种牌型的关键牌数量
nor_ddz_base_lib.key_pai_num={1,2,3,3,3,1,2,4,4,3,3,3,4,2,4}
local key_pai_num=nor_ddz_base_lib.key_pai_num

nor_ddz_base_lib.KAIGUAN={
    [0]=true,
    [1]=true,
    [2]=true,
    [3]=true,
    [4]=true,
    [5]=true,
    [6]=true,
    [7]=true,
    [8]=true,
    [9]=true,
    [10]=true,
    [11]=true,
    [12]=true,
    [13]=true,
    [14]=true,
    [15]=true,
}
local KAIGUAN=nor_ddz_base_lib.KAIGUAN


nor_ddz_base_lib.KAIGUAN_MLD={
    [0]=true,
    [1]=true,
    [2]=true,
    [3]=false,--
    [4]=true,
    [5]=false,--
    [6]=true,
    [7]=true,
    [8]=true,
    [9]=false,--
    [10]=true,
    [11]=false,--
    [12]=false,--
    [13]=true,
    [14]=true,
    [15]=true,
}



-- --统计牌的类型
function nor_ddz_base_lib.get_pai_typeHash_by_list(_pai_list)
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
function nor_ddz_base_lib.get_pai_typeHash(_pai)
    local _hash = {}
    for _id, _v in pairs(_pai) do
        if _v then
            _hash[pai_map[_id]] = _hash[pai_map[_id]] or 0
            _hash[pai_map[_id]] = _hash[pai_map[_id]] + 1
        end
    end
    return _hash
end
function nor_ddz_base_lib.get_pai_list_by_map(_map)
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
    {
     _pai=
     {
         {
         type,
         amount,
         }
     }
     按 数量从高到低  牌从小到大排好序
    }
--]]
function nor_ddz_base_lib.sort_pai_by_amount(_pai_count)
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

--获得牌的list  牌的类型，数量
function nor_ddz_base_lib.get_pai_list_by_type(_pai_map, _type, _num, _list)
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

function get_useInfo_by_cpData( _type, _pai)
    if _type == 0 then
        return nil
    end
    local useInfo={nor={},lz={}}
    if _type <= 3 then
        useInfo.nor[_pai[1]]=_type
    elseif _type == 4 then
        useInfo.nor[_pai[1]]=3
        useInfo.nor[_pai[2]]=1
    elseif _type == 5 then
        useInfo.nor[_pai[1]]=3
        useInfo.nor[_pai[2]]=2
    elseif _type == 6 then
        for p = _pai[1],_pai[2] do
           useInfo.nor[p]=1
        end
    elseif _type == 7 then
        for p = _pai[1],_pai[2] do
           useInfo.nor[p]=2
        end
    elseif _type == 8 then
        useInfo.nor[_pai[1]]=4
        useInfo.nor[_pai[2]]=1
        useInfo.nor[_pai[3]]=useInfo.nor[_pai[3]] or 0
        useInfo.nor[_pai[3]]=useInfo.nor[_pai[3]]+1
    elseif _type == 9 then
        useInfo.nor[_pai[1]]=4
        useInfo.nor[_pai[2]]=2
        useInfo.nor[_pai[3]]=useInfo.nor[_pai[3]] or 0
        useInfo.nor[_pai[3]]=useInfo.nor[_pai[3]]+2
    elseif _type == 10 then
        for p = _pai[1],_pai[2] do
            useInfo.nor[p]=3
        end
        for i=3,3+_pai[2]-_pai[1] do
            useInfo.nor[_pai[i]]=useInfo.nor[_pai[i]] or 0
            useInfo.nor[_pai[i]]=useInfo.nor[_pai[i]]+1
        end
    elseif _type == 11 then
        for p = _pai[1],_pai[2] do
            useInfo.nor[p]=3
        end
        for i=3,3+_pai[2]-_pai[1] do
            useInfo.nor[_pai[i]]=useInfo.nor[_pai[i]] or 0
            useInfo.nor[_pai[i]]=useInfo.nor[_pai[i]]+2
        end
    elseif _type == 12 then
        for p = _pai[1],_pai[2] do
            useInfo.nor[p]=3
        end
    elseif _type == 13 then
        useInfo.nor[_pai[1]]=4
    elseif _type == 14 then
        useInfo.nor[16]=1
        useInfo.nor[17]=1
    end

    return useInfo
end

-- by lyx: 根据牌组合类型 得到 牌 id list
function nor_ddz_base_lib.get_cp_list_by_cpData(_pai_map, _type, _pai, _list)
    if _type==0 then
        return nil
    end   
    local useInfo=get_useInfo_by_cpData( _type, _pai)
    local cp=nor_ddz_base_lib.get_cp_list_by_useInfo(_pai_map,useInfo)
    return cp
end

function nor_ddz_base_lib.list_to_map(_list)
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
function nor_ddz_base_lib.get_real_chupai_pos_by_act(_act_list)

    local _pos
    local _limit
    if nor_ddz_base_lib.game_type=="nor_ddz_er" then
        _pos=#_act_list
        _limit=_pos-1
    else
        _pos=#_act_list
        _limit=_pos-2 
    end

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

function nor_ddz_base_lib.is_must_chupai(_act_list)
    if nor_ddz_base_lib.game_type=="nor_ddz_er" then
        if #_act_list==0  or _act_list[#_act_list].type>=100 or  _act_list[#_act_list].type==0 then 
            return true
        end
    else
        if #_act_list==0  or _act_list[#_act_list].type>=100 or ( #_act_list>1 and  _act_list[#_act_list].type==0 and _act_list[#_act_list-1].type==0) then 
            return true
        end
    end
    return false
end

--获得出牌中使用的癞子数量
function nor_ddz_base_lib.get_cp_list_useLZ_num(cp_list)
    local num=0
    if cp_list.lz then
        num=#cp_list.lz
    end
    return num
end


function nor_ddz_base_lib.getAllPaiCount()
    if nor_ddz_base_lib.game_type=="nor_ddz_er" then
        return {
            [1]=0,
            [2]=0,
            [3]=0,
            [4]=0,
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
    else
        return {
            [1]=0,
            [2]=0,
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
end

function nor_ddz_base_lib.jipaiqi(_cp_list,_jipaiqi,_laizi_type)
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
function nor_ddz_base_lib.list_convert_to_lz(list,lz_map)
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

--通过各种牌的使用信息 或者与服务器通讯的格式 cp_list gameType:游戏类型 
function nor_ddz_base_lib.get_cp_list_by_useInfo(pai_id_map,useInfo,gameType)
    local nor_list={}
    if useInfo.nor then
        for k,v in pairs(useInfo.nor) do
            if v>0 then
                nor_ddz_base_lib.get_pai_list_by_type(pai_id_map, k, v, nor_list)
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
function nor_ddz_base_lib.merge_nor_and_lz(cp_list)
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

function nor_ddz_base_lib.deduct_pai_by_cp_list(_pai_data,cp_list,laizhi_type)
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


--检测出的牌是否合法          
function nor_ddz_base_lib.check_chupai_safe(_act_list,_p,_type,_pai)
    local _is_must=nor_ddz_base_lib.is_must_chupai(_act_list,_p)
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

function nor_ddz_base_lib.set_game_type(_g_type)
    nor_ddz_base_lib.game_type=_g_type
end


--是否必 闷拉倒
function nor_ddz_base_lib.is_must_zhua(map)
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

--发地主牌
function nor_ddz_base_lib.fapai_dizhu(_dz_pai,_dz_play_data)
    for i=1,3 do
        _dz_play_data.pai[_dz_pai[i]]=true
    end
    _dz_play_data.remain_pai=20
end

return nor_ddz_base_lib






 