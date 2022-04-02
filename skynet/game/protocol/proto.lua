--
-- Author: lyx
-- Date: 2018/3/13
-- Time: 10:16
-- 说明：协议解析文件
--

local sprotoparser = require "sprotoparser"
local basefunc = require "basefunc"
require "printfunc"

local proto = {}

local proto_path = "./game/protocol/"

-- 游戏定义
local games = {
	{name = "common",start_msg_id = 0},	-- 公用
	{name = "dbwg",start_msg_id = 1000},
	{name = "nmjxlfg",start_msg_id = 2000},
	{name = "tydfg",start_msg_id = 3000},
	{name = "nor_mj_xzdd",start_msg_id = 4000},
	{name = "nor_ddz_nor",start_msg_id = 5000},
	{name = "friendgame",start_msg_id = 6000},
	{name = "citymg",start_msg_id = 7000},
	{name = "nor_mg",start_msg_id = 8000},
	{name = "fg",start_msg_id = 9000},
	{name = "task",start_msg_id = 11000},
	{name = "sczd",start_msg_id = 12000},
	{name = "zajindan",start_msg_id = 13000},
	{name = "nor_gobang_nor",start_msg_id = 14000},
	{name = "fishing_game",start_msg_id = 15000},
	{name = "nor_fishing_nor",start_msg_id = 16000},
	{name = "xiaoxiaole",start_msg_id = 17000},
	{name = "dafuhao",start_msg_id = 18000},
}

-- 记录的静态消息编号表： 消息名 -> 消息 id
local message_id_static = {}

-- 消息名称表： 消息id -> 消息名
local message_name_map = {}

local function write_text_file(filename,data,mode)

	local file ,err = io.open(filename,mode or "w")
	if not file then
		print("write file data error:"..err)
		return false
	end
	file:write(data)
	file:close()

	return true
end

local function load_message_id_static()
	local _cache,_err = loadfile(proto_path .. "message_id_static.lua")
	if _cache then
		message_id_static = _cache()

		-- 填充 message_name_map
		for _name,_id in pairs(message_id_static) do
			if message_name_map[_id] then
				print("proto message id conflict:",_id)
			end
			message_name_map[_id] = _name
		end
	end
end

local function  write_message_id_static()

	local _infos = {}
	for _name,_id in pairs(message_id_static) do
		_infos[#_infos + 1] = {name=_name,id=_id}
	end

	table.sort(_infos,function (v1,v2)
		return v1.id < v2.id
	end)

	local _id_str = {"return {"}
	for _,_info in pairs(_infos) do

		_id_str[#_id_str + 1] = string.format("	%-40s = %d,",_info.name,_info.id)
	end
	_id_str[#_id_str + 1] = "}"

	write_text_file(proto_path .. "message_id_static.lua",table.concat(_id_str,"\n"))
end

-- 获取消息名
local function get_msg_name(_line)
	for _name in string.gmatch(_line,"%s*(%g+)%s*@") do
		return _name -- 只返回第一个
	end

	return nil
end

-- 查找一个未使用的id
local function find_unused_id(_id_start)
	for _id=_id_start,_id_start+9999 do
		if not message_name_map[_id] then
			return _id
		end
	end

	return nil
end

-- 加载协议文本，并替换 @ , $
-- 输出到 _out_lines
local function load_proto_file(_file,_start_msg_id,_out_lines)
	local _text = basefunc.path.read(proto_path .. _file)
	if not _text then
		print(string.format("error:load file '%s' error!",_file))
		return false
	end

	local _msg_id = _start_msg_id 	-- 消息 id
	local _data_id = 0			-- 消息里面的数据 id

	_out_lines[#_out_lines + 1] = ""
	_out_lines[#_out_lines + 1] = "########### " .. _file .. " #############" 
	_out_lines[#_out_lines + 1] = ""

	local lines = basefunc.string.split(_text,"\n")
	for _,_line in ipairs(lines) do

		_line = string.gsub(_line,"\r","") -- 干掉回车符

		local l,n
		local _msg_name = get_msg_name(_line)

		if _msg_name then

			local _static_id = message_id_static[_msg_name]

			-- 优先取 静态的 id
			if _static_id then
				l,n = string.gsub(_line, "@", tostring(_static_id))
			else
				-- 之前没有 id ，用自增长
				_msg_id = find_unused_id(_msg_id)
				l,n = string.gsub(_line, "@", tostring(_msg_id))

				-- 记录自己使用的 id
				message_id_static[_msg_name] = _msg_id
				message_name_map[_msg_id] = _msg_name

				if n > 0 then				
					_msg_id = _msg_id + 1
				end
			end

			if n > 0 then
				_data_id = 0
			else
				print(string.format("error:replace message '%s' id error!",_msg_name))
			end
		else
			l,n = string.gsub(_line, "%$", tostring(_data_id))
			if n > 0 then
				_data_id = _data_id + 1
			else
				-- 如果是 大括号 ，或 结构定义，则重新开始 _data_id
				if string.find(_line,"^%s*%.%g+") or string.find(_line,"[{}]+") then
					_data_id = 0
				end
			end
		end

		if n > 0 then
			_out_lines[#_out_lines + 1] = l
		else
			_out_lines[#_out_lines + 1] =_line
		end
	end

	return true
end

-- 加载给定游戏的协议
local function load_game_proto(_game,_both_lines,_c2s_lines,_s2c_lines)

	-- both
	if not load_proto_file(_game.name .. "_proto_both.sproto",_game.start_msg_id+1,_both_lines) then
		return false
	end
	-- c2s
	if not load_proto_file(_game.name .. "_proto_c2s.sproto",_game.start_msg_id+1,_c2s_lines) then
		return false
	end
	-- s2c
	if not load_proto_file(_game.name .. "_proto_s2c.sproto",_game.start_msg_id+1,_s2c_lines) then
		return false
	end

	return true
end

-- 加载消息 id 缓存
load_message_id_static()

-- 加载每个游戏的协议
local _both_lines = {}
local _c2s_lines = {}
local _s2c_lines = {}
for _,_game in ipairs(games) do
	if not load_game_proto(_game,_both_lines,_c2s_lines,_s2c_lines) then
		return proto
	end
end

local _c2s_text = table.concat(_both_lines,"\n") .. table.concat(_c2s_lines,"\n")
local _s2c_text = table.concat(_both_lines,"\n") .. table.concat(_s2c_lines,"\n")

write_text_file(proto_path .. "whole_proto_c2s.txt",_c2s_text)
write_text_file(proto_path .. "whole_proto_s2c.txt",_s2c_text)

io.write(">>>>>>>> parse proto c2s ...")
proto.c2s = sprotoparser.parse(_c2s_text)
print("ok")

io.write(">>>>>>>> parse proto s2c ...")
proto.s2c = sprotoparser.parse(_s2c_text)
print("ok")

-- 写入消息 id 缓存
write_message_id_static()

return proto