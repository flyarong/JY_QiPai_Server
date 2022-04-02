
local fish_lib = {}

-- 字节的 位掩码，从低位算起
-- local byte_masks = 
-- {
--     0xFF,
--     0xFF00,
--     0xFF0000,
--     0xFF000000,
-- }
-- local byte_masks_not = 
-- {
--     ~0xFF,
--     ~0xFF00,
--     ~0xFF0000,
--     ~0xFF000000,
-- }
-- local byte_shift = 
-- {
--     0,
--     8,
--     16,
--     24,
-- }

local MSG_TYPE = 
{
    shoot = 0,  [0] = "shoot",
    boom = 1,   [1] = "boom",
    fish = 2,   [2] = "fish",
    double = 3, [3] = "double",
    free = 4,   [4] = "free",
    fish_boom = 5,[5] = "fish_boom",
}

local floor = math.floor
local min = math.min
local max = math.max
local str_byte = string.byte
local str_char = string.char
local str_sub = string.sub

local pow
if _VERSION == "Lua 5.3" then
    pow = function(a,b)
        return a ^ b
    end
else
    pow = math.pow
end

local lshift
-- if _VERSION == "Lua 5.3" then
--     lshift = function(a,b)
--         return a << b
--     end
-- else
--     lshift = function(a,b)
--         return a * pow(2,b)
--     end
-- end
lshift = function(a,b)
    return a * pow(2,b)
end

local rshift
-- if _VERSION == "Lua 5.3" then
--     rshift = function(a,b)
--         return a >> b
--     end
-- else
--     rshift = function(a,b)
--         return floor(a / pow(2,b))
--     end
-- end
rshift = function(a,b)
    return floor(a / pow(2,b))
end

-- local pick_byte
-- if _VERSION == "Lua 5.3" then
--     pick_byte = function(_v,_i)
--         return str_char(_v & byte_masks[_i] >> byte_shift[_i])
--     end
-- else
--     pick_byte = function(_v,_i)
--         return str_char(rshift(_v ,byte_shift[_i]) % 256)
--     end
-- end


-- 移动二进制位： 从高位开始
--  _v1,_l1 ： 来源数据和 位长
--  _v2,_l2 ： 目标数据和 位长
-- _bit ： 要移动的位长
-- 返回： 新的来源值 + 新的目标值
local function move_bit(_v1,_l1,_v2,_l2,_bit)
    
end

-- 打包字节位
-- _bit ： 值占用的位数量
-- _tail ：当前字节尾部 剩余的 位数
-- 返回： 尾部字节剩余的位数 _tail
local function pack_bit(_data,_value,_bit,_tail)

    if _value > pow(2,_bit) then 
        error(string.format("data %s too long for bit %s !",tostring(_value),tostring(_bit)))
    end

    _tail = _tail or 0

    _bit_tmp = _bit
    _value_tmp = _value
    while _bit_tmp > 0 do -- 每次处理最多一个字节的位长

        -- 扩充容量
        if _tail == 0 then
            _data[#_data + 1] = str_char(0)
            _tail = 8
        end

        -- 本次处理位长
        local _len =  min(_tail,_bit_tmp)

        -- 剩余位长： 总长 - 本次处理长度
        local _next_len = _bit_tmp - _len

        local _v = rshift(_value_tmp,_next_len)
        _data[#_data] = _data[#_data] + lshift(_v,_tail - _len) -- 左移，低位 留出 本 字节中 剩余的位
        
        _value_tmp = _value_tmp - lshift(_v,_next_len) -- 去掉 已打包的 高位
        _bit_tmp = _next_len

        _tail = _tail - _len
    end

    return _tail
end

-- 解包字节位
-- _bit ： 值占用的位数量
-- _offset : 字节偏移
-- _tail ：当前字节尾部 剩余的 位数
-- 返回： 解包值 + 字节偏移 + 尾部字节剩余的位数 _tail
local function unpack_bit(_data,_bit,_offset,_tail)
    
    _bit_tmp = _bit
    _value_tmp = 0
    
    _offset = _offset or 1
    _tail = _tail or 8

    while _bit_tmp > 0 do
        if 0 == _tail then
            _tail = 8
            _offset = _offset + 1
        end

        
    end
end

-- 打包：加入到字节数组尾部
local function pack_msg_type(_data,_msg_type)
    if not MSG_TYPE[_msg_type] then
        error("invalid msg type:" .. tostring(_msg_type))
    end
    _data[#_data + 1] = tostring(MSG_TYPE[_msg_type])
end

-- 解包：从指定的便宜取出
-- 返回：数据 + 新的偏移
local function unpack_msg_type(_data,_offset)
    return MSG_TYPE[tonumber(str_sub(_data,_offset,_offset))],_offset + 1
end

local function pack_int8(_data,_value)
    _data[#_data + 1] = str_char(_value)
end
local function unpack_int8(_data,offset)
    return str_byte(_data,offset),offset + 1
end

local function pack_int16(_data,_value)
    _data[#_data + 1] = str_char(rshift(_value ,8))
    _data[#_data + 1] = str_char(_value % 256)
end
local function unpack_int16(_data,offset)
    return lshift(str_byte(_data,offset),8) + str_byte(_data,offset+1),offset + 2
end

local function pack_int32(_data,_value)
    _data[#_data + 1] = str_char(rshift(_value ,24))
    _data[#_data + 1] = str_char(rshift(_value ,16) % 256)
    _data[#_data + 1] = str_char(rshift(_value ,8) % 256)
    _data[#_data + 1] = str_char(_value % 256)
end
local function unpack_int32(_data,offset)
    return 
        lshift(str_byte(_data,offset),24) + 
        lshift(str_byte(_data,offset+1),16) + 
        lshift(str_byte(_data,offset+2),8) + 
        str_byte(_data,offset+3),
        offset + 4
end


-- 解包/打包函数
local packer = {}
local unpacker = {}

function packer.shoot(_data,_d)
    pack_int8(_data,_d.id)
    pack_int8(_data,_d.index)
    pack_int8(_data,_d.seat_num)
    pack_int16(_data,floor(_d.x * 1000) + 12800)
    pack_int16(_data,floor(_d.y * 1000) + 7200)
    pack_int16(_data,_d.time + 10000)
end
function unpacker.shoot(_data,_offset,_d)
    _d = _d or {}
    _d.id       ,_offset = unpack_int8(_data,_offset)
    _d.index    ,_offset = unpack_int8(_data,_offset)
    _d.seat_num ,_offset = unpack_int8(_data,_offset)
    _d.x        ,_offset = unpack_int16(_data,_offset)
    _d.y        ,_offset = unpack_int16(_data,_offset)
    _d.time     ,_offset = unpack_int16(_data,_offset)

    _d.x = _d.x/1000 - 12.8
    _d.y = _d.y/1000 - 7.2
    _d.time = _d.time - 10000
    
    return _d,_offset
end

function packer.boom(_data,_d)
    pack_int8(_data,_d.id)

    if #_d.fish_ids > 255 then
        error("too long fish_ids:",#_d.fish_ids)
    end
    pack_int8(_data,#_d.fish_ids)
    for _,_fid in ipairs(_d.fish_ids) do
        pack_int16(_data,_fid)
    end
end
function unpacker.boom(_data,_offset,_d)
    _d = _d or {}

    _d.id,_offset = unpack_int8(_data,_offset)
    local _fcount
    _fcount,_offset = unpack_int8(_data,_offset)

    _d.fish_ids = {}
    for j=1,_fcount do
        _d.fish_ids[#_d.fish_ids + 1],_offset = unpack_int16(_data,_offset)
    end

    return _d,_offset
end

function packer.fish(_data,_d)
    pack_int16(_data,_d.id)
    pack_int8(_data,_d.type)
    pack_int16(_data,_d.path)
    pack_int16(_data,_d.time)
end
function unpacker.fish(_data,_offset,_d)
    _d = _d or {}

    _d.id   ,_offset = unpack_int16(_data,_offset)
    _d.type ,_offset = unpack_int8(_data,_offset)
    _d.path ,_offset = unpack_int16(_data,_offset)
    _d.time ,_offset = unpack_int16(_data,_offset)

    return _d,_offset
end

function packer.double(_data,_d)
    pack_int16(_data,_d.value)
end
function unpacker.double(_data,_offset,_d)
    _d = _d or {}
    _d.value ,_offset = unpack_int16(_data,_offset)
    return _d,_offset
end

function packer.fish_boom(_data,_d)
    pack_int8(_data,_d.value)
end
function unpacker.fish_boom(_data,_offset,_d)
    _d = _d or {}
    _d.value ,_offset = unpack_int8(_data,_offset)
    return _d,_offset
end

packer.free = packer.double
unpacker.free = unpacker.double

local function pack_array(_data,_array)

    pack_int16(_data,#_array)
    for _,_d in ipairs(_array) do
        pack_msg_type(_data,_d.msg_type)
        packer[_d.msg_type](_data,_d)
    end
end

local function unpack_array(_data,_offset)

    local _ret = {}

    local _count
    _count,_offset = unpack_int16(_data,_offset)
    for i=1,_count do
        local _d = {}

        _d.msg_type,_offset = unpack_msg_type(_data,_offset)
        _d,_offset = unpacker[_d.msg_type](_data,_offset,_d)

        _ret[#_ret + 1] = _d
    end

    return _ret,_offset
end

--[[

    技能 = 
    {
        1 = 核弹 - 1普通,2金色
    }

    --发射子弹
    shoot = 
    {
        [1]={
            id = 212,       1 ~ 255
            index = 3,      1 ~ 255
            seat_num = 1,   1 ~ 4
            x = 152,        1 ~ 65535
            y = 622,        1 ~ 65535
            time = 123,     1 ~ 65535
        },
    }

    --子弹碰撞
    boom = 
    {
        [1]={
            id = 211,               1 ~ 255
            fish_ids = {23,542},   1 ~ 65535
            data = {1,48}         特殊鱼死后引起其他鱼的总倍数
                                    技能：{1-炸弹,2-技能,3-红包}
            money = 652314,     这波鱼的奖励总和
        },
    }

    
    --产生一组鱼
    fish_group = 
    {
        [1]={
            ids = {123,},        1 ~ 65535
            types = {123,},       1 ~ 255
            group_id = 2,
            path = 123,     1 ~ 65535
            time = 123,     1 ~ 65535
            speed = 100,
        },
    }


    --产生一个敢死队的鱼
    fish_team = 
    {
        [1]={
            id = 65,        1 ~ 65535
            types = {1,2,3},       1 ~ 255
            path = 123,     1 ~ 65535
            time = 123,     1 ~ 65535
            speed = 100,
        },
    }

    --特殊的鱼死了(携带东西的,爆炸鱼,闪电鱼,红包鱼等等)
    fish_explode = 
    {
        [1]={
            id = 123,        1 ~ 65535
            fish_ids = {23,542},   1 ~ 65535
            data = {1,48}         特殊鱼死后引起其他鱼的总倍数
                                    技能：{1-炸弹鱼,2-技能,3-红包}
            money = 652314,     这波鱼的奖励总和
        },
    }

    time = 15200126376,

    --活动
    activity = {
        [1] = {
            msg_type = "crit", --s
            begin_time = 1, --开始的相对时间
            time = 3, --活动持续时间
            seat_num = 1, 1 ~ 65535
            rate = 2, --倍率
            score = 15200,
        },
        [2] = {
            msg_type = "free_bullet", --免费子弹
            seat_num = 1,
            num = 30, 1 ~ 65535
            score = 15200,
        },
        [3] = {
            msg_type = "power", --s
            begin_time = 1, --开始的相对时间
            time = 3, --活动持续时间
            seat_num = 1, 1 ~ 65535
            score = 15200,
        },
    },

    --事件
    event = {
        [1] = {
            msg_type = "fish_boom",
            value = 0, 1 ~ 255
        },
        [2] = {
            msg_type = "boss",
            value = 0, 
        },
    }

    --技能
    skill = {
        [1] = {
            msg_type = "frozen",
            value = 10, 1 ~ 255 -s
            seat_num = 1,
        },
        [2] = {
            msg_type = "lock",
            value = 10, 1 ~ 255 -s
            seat_num = 3,
        },
        [2] = {
            msg_type = "summon",
            value = 514, fish id
            seat_num = 3,
        },
        [2] = {
            msg_type = "laser",
            value = 514,
            seat_num = 3,
            index = 3,
            fish_ids = {},
            data = {1,48}
        },
        [2] = {
            msg_type = "missile",
            value = 1212,
            seat_num = 3,
            fish_ids = {},
            data = {1,48}
        },
    }

]]
function fish_lib.frame_data_pack(_data)
do
    return _data
end
    local _ret = {}

    if #_data > 255 then
        error("too long frame data pack:",#_data)
    end

    -- 时间戳
    pack_int32(_ret,_data.time or 0)
    
    -- data 
    pack_array(_ret,_data.data or {})

    -- activity
    pack_array(_ret,_data.activity or {})

    -- event
    pack_array(_ret,_data.event or {})

    return table.concat(_ret)
end

function fish_lib.frame_data_unpack(_data)
do
    return _data
end
    local _ret = {}
    local _offset = 1

    _ret.time,_offset = unpack_int32(_data,_offset)

    _ret.data,_offset = unpack_array(_data,_offset)

    _ret.activity,_offset = unpack_array(_data,_offset)

    _ret.event,_offset = unpack_array(_data,_offset)
    
    return _ret
end




return fish_lib