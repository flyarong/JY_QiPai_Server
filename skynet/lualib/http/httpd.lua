local internal = require "http.internal"

local table = table
local string = string
local type = type

local httpd = {}

local http_status_msg = {
	[100] = "Continue",
	[101] = "Switching Protocols",
	[200] = "OK",
	[201] = "Created",
	[202] = "Accepted",
	[203] = "Non-Authoritative Information",
	[204] = "No Content",
	[205] = "Reset Content",
	[206] = "Partial Content",
	[300] = "Multiple Choices",
	[301] = "Moved Permanently",
	[302] = "Found",
	[303] = "See Other",
	[304] = "Not Modified",
	[305] = "Use Proxy",
	[307] = "Temporary Redirect",
	[400] = "Bad Request",
	[401] = "Unauthorized",
	[402] = "Payment Required",
	[403] = "Forbidden",
	[404] = "Not Found",
	[405] = "Method Not Allowed",
	[406] = "Not Acceptable",
	[407] = "Proxy Authentication Required",
	[408] = "Request Time-out",
	[409] = "Conflict",
	[410] = "Gone",
	[411] = "Length Required",
	[412] = "Precondition Failed",
	[413] = "Request Entity Too Large",
	[414] = "Request-URI Too Large",
	[415] = "Unsupported Media Type",
	[416] = "Requested range not satisfiable",
	[417] = "Expectation Failed",
	[500] = "Internal Server Error",
	[501] = "Not Implemented",
	[502] = "Bad Gateway",
	[503] = "Service Unavailable",
	[504] = "Gateway Time-out",
	[505] = "HTTP Version not supported",
	[600] = "Rewrite url",  -- by lyx
}

local function readall(readbytes, bodylimit)
	local tmpline = {}
	local body = internal.recvheader(readbytes, tmpline, "")
	if not body then
		return 413	-- Request Entity Too Large
	end
	local request = assert(tmpline[1])
	local method, url, httpver = request:match "^(%a+)%s+(.-)%s+HTTP/([%d%.]+)$"
	assert(method and url and httpver)
	httpver = assert(tonumber(httpver))
	if httpver < 1.0 or httpver > 1.1 then
		return 505	-- HTTP Version not supported
	end
	local header = internal.parseheader(tmpline,2,{})
	if not header then
		return 400	-- Bad request
	end
	local length = header["content-length"]
	if length then
		length = tonumber(length)
	end
	local mode = header["transfer-encoding"]
	if mode then
		if mode ~= "identity" and mode ~= "chunked" then
			return 501	-- Not Implemented
		end
	end

	if mode == "chunked" then
		body, header = internal.recvchunkedbody(readbytes, bodylimit, header, body)
		if not body then
			return 413
		end
	else
		-- identity mode
		if length then
			if bodylimit and length > bodylimit then
				return 413
			end
			if #body >= length then
				body = body:sub(1,length)
			else
				local padding = readbytes(length - #body)
				body = body .. padding
			end
		end
	end

	return 200, url, method, header, body
end

function httpd.read_request(...)
	local ok, code, url, method, header, body = pcall(readall, ...)
	if ok then
		return code, url, method, header, body
	else
		return nil, code
	end
end

local function writeall(writefunc, statuscode, bodyfunc, header)
	local statusline = string.format("HTTP/1.1 %03d %s\r\n", statuscode, http_status_msg[statuscode] or "")
	writefunc(statusline)
	if header then
		for k,v in pairs(header) do
			if type(v) == "table" then
				for _,v in ipairs(v) do
					writefunc(string.format("%s: %s\r\n", k,v))
				end
			else
				writefunc(string.format("%s: %s\r\n", k,v))
			end
		end
	end
	local t = type(bodyfunc)
	if t == "string" then
		writefunc(string.format("content-length: %d\r\n\r\n", #bodyfunc))
		writefunc(bodyfunc)
	elseif t == "function" then
		writefunc("transfer-encoding: chunked\r\n")
		while true do
			local s = bodyfunc()
			if s then
				if s ~= "" then
					writefunc(string.format("\r\n%x\r\n", #s))
					writefunc(s)
				end
			else
				writefunc("\r\n0\r\n\r\n")
				break
			end
		end
	else
		assert(t == "nil")
		writefunc("\r\n")
	end
end

function httpd.write_response(...)
	return pcall(writeall, ...)
end

-- 计算字符所在的行、列
local function calc_rowcol(str,pos)

	if pos <= 1 then
		return 1,1
	end
	if pos > #str then
		pos = #str
	end

	local row = 1
	local col = 0
	for i=1,pos,1 do
		col = col + 1
		if 10 == string.byte(str,i,i) then
			row = row + 1
			col = 0
		end
	end

	return row,col
end

local function rowcol(str,pos)
	return string.format("row %d,col %d",calc_rowcol(str,pos))
end

-- 默认的文件读取器
-- 返回值：
--	context   文件内容。如果出错 则为 nil，随后返回 错误号，错误描述内容
--	fileType  文件类型
-- 		"lua"   直接执行的 lua 源文件
-- 		"html"  静态 html 页面
-- 		"lweb"  混合 lua 和 html 类型的服务器脚本
local function default_filereader(filename)
	local fobj,err = io.open(filename,"r")
	if not fobj then
		return nil,404,err
	end

	local context = fobj:read("a")
	fobj:close()

	--add by lcx
	if filename:match( ".+%.lua$" ) then
		return context,"lua"
	end

	if filename:match(".+%.lweb$") or filename:match(".+%.lweb%.html$") then
		return context,"lweb"
	end

	-- 其他，直接返回 "html" 作为静态页面
	return context,"html"

end

-- 脚本的头和尾。注意：这些代码只能是一行，否则 内部报错信息的行号会不准确！！！
local __loadhtmlua_header =
	[[local function script_main(host,request) ]] ..
		[[local htmlines,rewrite_url = {},nil ]] ..
		[[local function echo(s) ]] ..
			[[htmlines=htmlines or {} ]] ..
			[[htmlines[#htmlines + 1] = tostring(s) ]] ..
		[[end ]] ..
		[[local function rewrite(url) ]] ..
			[[rewrite_url = url ]] ..
			[[error("rewrite_url") ]] ..
		[[end ]] ..
		[[local body_func = function() ]]
local __loadhtmlua_tail =
		[[end ]] ..
		[[body_func() ]] ..
		[[return htmlines,rewrite_url ]] ..
	[[end ]] ..
	[[return script_main ]]

--[[
功能：载入 htmlua 脚本，生成 lua 语句块，用于后续处理 http 请求
 参数：
 	filename ：文件名
 	filereader ：文件读取器，可选。用于调用者处理特殊的文件读取逻辑，例如默认页面的优先顺序等； 如果出错，第二个返回值必须包含出错原因
返回：
	contextType   内容的类型。 如果出错 ，则为 nil，随后返回 错误号，错误描述内容
 		"script"  脚本
 		"static"  静态内容

	context       内容
--]]
function httpd.loadhtmlua(filename,filereader)

	filereader = filereader or default_filereader

	local htmlua,filetype,err = filereader(filename)
	if not htmlua then
		return nil,404,string.format("resource type '%s' not found,%s!",tostring(filetype),tostring(err))
	end

	-- 静态页面
	if "html" == filetype then
		return "static",htmlua
	end

	-- 脚本序列
	local script = {}
	table.insert(script,__loadhtmlua_header)

	if "lweb" == filetype then	-- lua 和 html 的混合

		-- 收集脚本
		local pos = 1
		local next_openpos
		while true do
			local openpos = next_openpos and next_openpos or htmlua:find("<?",pos,true)
			if openpos then

				-- 插入 html
				table.insert(script," echo([=[" .. htmlua:sub(pos,openpos-1) .. "]=]) ")

				-- 插入脚本
				local closepos = htmlua:find("?>",openpos + 2,true)
				if closepos then

					-- 不允许嵌套的 脚本标签
					next_openpos = htmlua:find("<?",openpos + 2,true)
					if next_openpos and next_openpos < closepos then
						return nil,500,"(" .. rowcol(htmlua,next_openpos) .. ")'?>' expected ,got '<?' !"
					end

					table.insert(script,htmlua:sub(openpos+2,closepos-1))
					pos = closepos+2
				else
					return nil,500,"(" .. rowcol(htmlua,openpos) .. ") script '<?' not closed!"
				end
			else
				-- 插入 html
				table.insert(script," echo([=[" .. htmlua:sub(pos,htmlua:len()) .. "]=]) ")

				break
			end
		end
	elseif "lua" == filetype then			-- 纯 lua 脚本
		table.insert(script,htmlua)
	else
		return nil,500,string.format("file type error! file:%s,type:%s!",tostring(filename),tostring(filetype))
	end


	table.insert(script,__loadhtmlua_tail)


	-- 载入生成的lua脚本
	local chunk ,err = load(table.concat(script),filename)

	if not chunk then
		return nil,500,err
	end

	-- 执行脚本，得到脚本内定义的 script_main 函数
	local ok,script_main = pcall(chunk)
	if ok then
		return "script",script_main
	else
		return nil,500,script_main
	end
end

--[[

 功能：处理 html 嵌入的 lua 脚本
 参数：
 	filename ：脚本文件名
 	host : 主机的相关信息
 	request : 请求的相关信息
 	filereader ：文件内容读取函数，可选。 实现方式参见默认的读取函数： default_filereader
 	disable_cache ： 禁用缓存，默认为开启（false）
 说明：
	1、脚本中支持的内置函数/功能：
	 	echo(xxxx) ： 输出 html 内容。
		rewrite(url) ：重定向页面
	2、脚本中支持的内置对象
	 	request ：可访问本次请求的相关数据

 返回值：
 	http代码：
 		200 为正常，
 		600 重定向，第二个参数为重定向的 url 地址
 		其他值 ： 出错；
 	http页面内容：

--]]
local htmllua_caches = {}
function httpd.parse_htmlua(filename,host,request,filereader,disable_cache)

	local cache_info
	if not disable_cache then
		cache_info = htmllua_caches[filename]
	end

	if not cache_info then

		cache_info = {}

		local contextType,context,err = httpd.loadhtmlua(filename,filereader)
		if not contextType then
			return context,err
		end

		if "script" == contextType then
			cache_info.script_main = context
		elseif "static" == contextType then
			cache_info.htmltext = context
		else
			return 500,string.format("context type error! file=%s, type=%s",filename,contextType)
		end

		-- 缓存
		if not disable_cache then
			htmllua_caches[filename] = cache_info
		end
	end

	-- 静态页面
	if cache_info.htmltext then
		return 200 ,cache_info.htmltext
	end

	-- 动态页面
	local ok,htmlines,rewrite_url = xpcall(cache_info.script_main, function( err ) 
		
		-- return err
		local traceinfo = debug.traceback( err, 2 )
		print( "httpd 异常：" )
		print( traceinfo )
		
		return traceinfo
	end,host,request)

	-- 重定向
	if rewrite_url then
		return 600,rewrite_url
	end

	if ok then
		return 200,table.concat(htmlines)
	end

	-- 出错
	return 500,"run script error:" .. htmlines
end


return httpd
