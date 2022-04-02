local basefunc=require "basefunc"

local function dump_value_(v)
    if type(v) == "string" then
        v = "\"" .. v .. "\""
    end

    return tostring(v)
end

local function dump_key_(v)
    if type(v) == "number" then
        return "[" .. tostring(v) .. "]"
    elseif type(v) == "string" and string.match(v,"^%a[%a%d_]*$") then
        return v
    end

    return "[\"" .. tostring(v) .. "\"]"
end

function dump(value, description, nesting)
    if type(nesting) ~= "number" then nesting = 30 end

    local refTableIndex = 0

    -- 表 hash => {line=,refTableIndex=}
    local lookupTable = {}

    local result = {}

    local traceback = basefunc.string.split(debug.traceback("", 2), "\n")

	-- by lyx
	result[#result +1] = "dump from: " .. basefunc.string.trim(traceback[3])
    -- print("dump from: " .. basefunc.string.trim(traceback[3]))

    local function dump_(value, description, indent, nest, keylen)
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - (description and string.len(dump_key_(description)) or 0))
        end
        if type(value) ~= "table" then
            if description then
                result[#result +1 ] = string.format("%s%s%s = %s", indent, dump_key_(description), spc, dump_value_(value))
            else
                result[#result +1 ] = indent .. dump_value_(value)
            end
        elseif lookupTable[tostring(value)] then

            -- 引用表 序号
            if not lookupTable[tostring(value)].refTableIndex then
                refTableIndex = refTableIndex + 1
                lookupTable[tostring(value)].refTableIndex = refTableIndex

                result[lookupTable[tostring(value)].line] = result[lookupTable[tostring(value)].line] .. "    -- *REF:" .. tostring(refTableIndex) .. "*"
            end

            if description then
                result[#result +1 ] = string.format("%s%s%s = *REF:%s*", indent, dump_key_(description), spc,tostring(lookupTable[tostring(value)].refTableIndex))
            else
                result[#result +1 ] = indent .. "*REF:" .. tostring(lookupTable[tostring(value)].refTableIndex) .. "*"
            end
        else
            lookupTable[tostring(value)] = {line=#result+1}
            if nest > nesting then
                if description then
                    result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, dump_key_(description))
                else
                    result[#result +1 ] = indent .. "*MAX NESTING*"
                end
            else
                if description then
                    result[#result +1 ] = string.format("%s%s = {", indent, dump_key_(description))
                else
                    result[#result +1 ] = indent .. "{"
                end
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = dump_value_(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                local _array_len = 0 -- #value -- Êý×é²¿·ÖµÄ³¤¶È
                for i, k in ipairs(keys) do
                    if type(k) == "number" and k > 0 and k <= _array_len then
                        -- Êý×é·½Ê½£¬²»Ìá¹© key
                        dump_(values[k], nil, indent2, nest + 1, keylen)
                    else
                        dump_(values[k], k, indent2, nest + 1, keylen)
                    end
                    result[#result] = result[#result] .. ","
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    dump_(value, description  or "<var>" , " ", 1)

	-- by lyx
	print(table.concat(result,"\n"))
--    for i, line in ipairs(result) do
--        print(line)
--	end

end