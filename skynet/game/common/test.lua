--
-- Author: lyx
-- Date: 2018/3/16
-- Time: 15:31
-- 说明：测试、试验 代码
--

local test = {}

math.randomseed(os.time())

local skynet = require "skynet"

local sproto_core = require "sproto.core"

local print = skynet.orig_print or print

----------------------------------------------------------
-- 测试 listmap 的性能

local basefunc = require "basefunc"

local testclient = basefunc.class()

function testclient:ctor()
	self.xxx = 234
	self.totaltime = 0
end

function testclient:update(dt)
	self.totaltime = self.totaltime + dt
end

local listmap_test_count = 30000000

-- 采用 lua 表测试（intel cpu i5 4460 3.2GHz）
-- listmap_test_count == 3000w 的结果
-- build time : 21s  (140w/s)
-- create time : 48s  (62.5w/s)
-- call time : 17s (176w/s)
local function listmap_call_with_table()
	local testclients = {}

	local starttime = os.time()
	print("build start")
	math.randomseed(os.time())
	local fds = {}
	local used = {}
	for i = 1,listmap_test_count do
		local fd = math.random(listmap_test_count * 7)
		while used[fd] do
			fd = math.random(listmap_test_count * 7)
		end
		used[fd] = true
		fds[#fds+1] = fd
	end
	print("build end:",os.time() - starttime)

	starttime = os.time()
	print("create start")
	for i=1,#fds do
		testclients[fds[i] ] = testclient.new()
	end
	print("create end:",os.time() - starttime)

	starttime = os.time()
	print("call start")
	for k,v in pairs(testclients) do
		v:update(2)
	end
	print("call end:",os.time() - starttime)
end

-- 采用 listmap 表测试（intel cpu i5 4460 3.2GHz）
-- listmap_test_count == 3000w 的结果
-- build time : 21s (140w/s)
-- create time : 136s (22w/s)
-- call time : 18s (166.5w/s)
local function listmap_call()
	local testclients = basefunc.listmap.new()

	local starttime = os.time()
	print("build start")
	math.randomseed(os.time())
	local fds = {}
	local used = {}
	for i = 1,listmap_test_count do
		local fd = math.random(listmap_test_count * 7)
		while used[fd] do
			fd = math.random(listmap_test_count * 7)
		end
		used[fd] = true
		fds[#fds+1] = fd
	end
	print("build end:",os.time() - starttime)

	starttime = os.time()
	print("create start")
	for i=1,#fds do
		testclients:push_back(fds[i],testclient.new())
	end
	print("create end:",os.time() - starttime)

	starttime = os.time()
	print("call start")
	for v in testclients.list:values() do
		v:update(2)
	end
	print("call end:",os.time() - starttime)
end

----------------------------------------------------------
-- 测试 rsa 加密解密的性能
--
--        === 环境准备 ===
-- 安装 openssl
-- 		sudo apt-get install openssl
-- 		sudo apt-get install libssl-dev
-- 生成私钥（其中包含公钥）
--		openssl genrsa -out rsa_private_key.pem 1024
-- 提取公钥
--		openssl rsa -in rsa_private_key.pem -pubout -out rsa_public_key.pem
--

-- local rsa = require "rsa"

-- local private_rsakey=[[
-- -----BEGIN RSA PRIVATE KEY-----
-- MIICXAIBAAKBgQC8UkE4e6vdEcBNOAOQZggy1B6LuidkNQZfZXu1yoDIUNVLtyXz
-- f+IgJXSGyawhK4M2qhIZ2cbu9wsOH7F7mQbst/lfK/8KLxeUjQ4UFqaAmcSsB2os
-- TnNgL0HJf58RZo6ZTRsxqieSAUp2+kbM8pXCXNuYLecqCoMc/rSV+X2FdQIDAQAB
-- AoGAXyuyijj1weMWq++C3Zayzf0k8rhA8ANcFRnUSyrrqlAvevQz2brnLBfBq9x/
-- gMPcq+OHAklsn5d5nsmliDDtrhRtGm5zCpYuXuUQ1xp+GRrFrlGxSBfJEHA/6F4g
-- a7mUD/4k7fs1Mw1QWqu1lEaYCidR+dXL1jGbkZEekaH70AECQQD2EObZDtK1+Hji
-- 82kgDkPWjV1qhI7SohVFrHgjE0I8nrmOn7/6nuxP9JM1r0rQsnJ4/4MiF7Av4kpy
-- peWrp6qVAkEAw+yPXHsHqiZdjghk4KokVKnBsa1E3WKqr5QjXvOd/Sto4PLRKLUP
-- CpmZmHBtoeqaWGNesbvX3TYxbcG+ZfiXYQJABPiacVAnWZ3Hc25PdWJUZIU+meRL
-- rl2v6FRvqOW+tNLQFN2NV1bWl1btkmwUKtswDNm8oHeyC4Wa024ekbU1cQJBAMDj
-- w3jfP3qK7wyIwxhVKhOYVbQhzGzRWQ4noHM5EdBQzp65MKcNKtPayVdFSQpiOLbQ
-- jkgZkbqeQie22Ub3acECQG5XboepIrHQ5x7rXJywK6B19F2sMndlJd1h8wPsYa0v
-- xcNBrm4X8MWiGZUH8U23hIz1FHCAFpj1TZDj4gezGL0=
-- -----END RSA PRIVATE KEY-----
-- ]]

-- local public_rsakey=[[
-- -----BEGIN PUBLIC KEY-----
-- MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC8UkE4e6vdEcBNOAOQZggy1B6L
-- uidkNQZfZXu1yoDIUNVLtyXzf+IgJXSGyawhK4M2qhIZ2cbu9wsOH7F7mQbst/lf
-- K/8KLxeUjQ4UFqaAmcSsB2osTnNgL0HJf58RZo6ZTRsxqieSAUp2+kbM8pXCXNuY
-- LecqCoMc/rSV+X2FdQIDAQAB
-- -----END PUBLIC KEY-----
-- ]]

-- local rsa_text_test = [[ewkdf_2333333,fffff,sssssssssss,)))))fasdddddddddddddddddddddddddddagent.max_login=12]]

-- -- 加密测试（intel cpu i5 4460 3.2GHz）
-- -- time : 23s (4.3w/s)
-- local function rsa_encrypt()

-- 	local starttime = os.time()

-- 	print("rsa_encrypt start")
-- 	local en_text
-- 	for i=1,1000000 do
-- 		en_text = rsa.public_encrypt(rsa_text_test,public_rsakey)
-- 	end

-- 	print("rsa_encrypt end:",os.time() - starttime)
-- 	print("encrypt:",string.gsub(en_text, ".", function(char) return string.format("%X", string.byte(char)) end))
-- end

-- -- 解密测试（intel cpu i5 4460 3.2GHz）
-- -- time : 18s (2700/s)
-- local function rsa_decrypt()
-- 	local en_text = rsa.public_encrypt(rsa_text_test,public_rsakey)

-- 	local starttime = os.time()
-- 	print("rsa_decrypt start")
-- 	local de_text
-- 	for i=1,50000 do
-- 		de_text = rsa.private_decrypt(en_text,private_rsakey)
-- 	end
-- 	print("rsa_decrypt end:",os.time() - starttime)
-- 	print("decrypt:",de_text)
-- end


----------------------------------------------------------
-- 测试 des 加密解密的性能
--

local crypt = require "client.crypt"

local des_key_test = "fqlWi3aE"
local des_text_test = "fjlaksdjfowiergtoiwq43082974r!234h123oi481elfdalskcfbhklasudyrfqwe3ru8asdfh283!@#$!@34klsjadhflsajdfhlkaejqwerfghery73456345623hsdf"

-- des 加密测试（intel cpu i5 4460 3.2GHz）
-- time : 11s (45.5w/s)
local function des_encrypt()

	local starttime = os.time()
	print("des_encrypt start")
	local des_en
	for i=1,5000000 do
		des_en = crypt.desencode(des_key_test,des_text_test)
	end

	print("des_encrypt end:",os.time() - starttime)
	print("encrypt:",string.len(des_en),crypt.hexencode(des_en))
end

-- des 解密测试（intel cpu i5 4460 3.2GHz）
-- time : 11s (45.5w/s)
local function des_decrypt()

	local starttime = os.time()
	print("des_decrypt start")
	local des_en = crypt.desencode(des_key_test,des_text_test)
	local des_de
	for i=1,5000000 do
		des_de = crypt.desdecode(des_key_test,des_en)
	end

	print("des_decrypt end:",os.time() - starttime)
	print("decrypt:",string.len(des_de),des_de)
end

local xtea_key_test = "jF#@%&sadAGewq#4"
local xtea_text_test = "fjlaksdjfowiergtoiwq43082974r!234h123oi481elfdalskcfbhklasudyrfqwe3ru8asdfh283!@#$!@34klsjadhflsajdfhlkaejqwerfghery73456345623hsdf"


-- xtea 加密测试（intel cpu i7 4790k 4GHz）
-- time : 3s (166.6w/s)
local function xtea_encrypt()

	local starttime = os.time()
	print("xtea_encrypt start")
	local xtea_en
	for i=1,5000000 do
		xtea_en = sproto_core.xteaencrypt(xtea_text_test,xtea_key_test)
	end

	print("xtea_encrypt end:",os.time() - starttime)
	print("encrypt:",string.len(xtea_en),crypt.hexencode(xtea_en))

	local decrypt_str = sproto_core.xteadecrypt(xtea_en,xtea_key_test)
	print("decrypt:",string.len(decrypt_str),decrypt_str)
end

----------------------------------------------------------
-- 测试参数传递方式： 多参数 和 单一表
--

-- 多参数
-- time : 7s (1428w/s)
local function call_args_multi(_arg_param1,_name_xfwe2,_ffacqae,_qeurejfgd,_kcqwewe,_xsaerwe)
	return _arg_param1 + _name_xfwe2 + _ffacqae,_kcqwewe
end

-- 单一表
-- time : 48s (208w/s)
local function call_args_table(_data)
	return _data._arg_param1 + _data._name_xfwe2 + _data._ffacqae,_data._kcqwewe
end

local function call_args_test(_is_muti)

	local count =  100000000

	local v1 = 0
	local s1

	local starttime = os.time()

	if _is_muti then
		print("call_args_multi start")
		for i=1,count do
			local _v1,_s1 = call_args_multi(i+2,i+5,i+1,"ff#1434","mktfghjmkk.yut54324523","grrfsdfgbdf")
			v1,s1 = v1 + _v1 + i,_s1
		end
		print("call_args_multi end",os.time() - starttime)
	else
		print("call_args_table start")
		for i=1,count do
			local _v1,_s1 = call_args_table({
				_arg_param1 = i+2,
				_name_xfwe2 = i+5,
				_ffacqae = i+1,
				_qeurejfgd = "ff#1434",
				_kcqwewe = "mktfghjmkk.yut54324523",
				_xsaerwe = "grrfsdfgbdf"})
			v1,s1 = v1 + _v1 + i,_s1
		end
		print("call_args_table end",os.time() - starttime)
	end

	print("call args :",v1,s1)

end

----------------------------------------------------------
-- 测试函数调用方式： 直接调用 ； pcall； xpcall
--


local function func_ncall_test(arg1,arg2,arg3)
	return arg1+arg2+arg3
end

local _ncall_test_count = 200000000

-- 直接调用
-- time : 2e/9s (2200w/s)
local function test_call_normal()

	print("test_call_normal start")

	local starttime = os.time()

	local sum_value = 0
	for i=1,_ncall_test_count do
		local result = func_ncall_test(3,3,5)
		sum_value = sum_value + result
	end

	print("test_call_normal end",os.time() - starttime)
end

-- pcall
-- time : 2e/18s (1100w/s)
local function test_call_pcall()

	print("test_call_pcall start")

	local starttime = os.time()

	local sum_value = 0
	for i=1,_ncall_test_count do
		local ok,result = pcall(func_ncall_test,3,3,5)
		if ok then
			sum_value = sum_value + result
		end
	end

	print("test_call_pcall end",os.time() - starttime)
end

-- xpcall
-- time : 2e/20s (1000w/s)
local function test_call_xpcall()

	print("test_call_xpcall start")

	local function err_handle(msg) end

	local starttime = os.time()

	local sum_value = 0
	for i=1,_ncall_test_count do
		local ok,result = xpcall(func_ncall_test,err_handle,3,3,5)
		if ok then
			sum_value = sum_value + result
		end
	end

	print("test_call_xpcall end",os.time() - starttime)
end

-- xpcall2 : 每次用新的匿名函数
-- time : 2e/20s (1000w/s) , 和 test_call_xpcall 比没什么变化
local function test_call_xpcall2()

	print("test_call_xpcall2 start")

	local starttime = os.time()

	local sum_value = 0
	for i=1,_ncall_test_count do
		local ok,result = xpcall(func_ncall_test,function(msg) end,3,3,5)
		if ok then
			sum_value = sum_value + result
		end
	end

	print("test_call_xpcall2 end",os.time() - starttime)
end

----------------------------------------------------------
-- 定位扑克牌：通过键-值 和 整除拆分
--

-- 用键查询： 5e/9s  = 5500w/s
-- 用整数计算：5e/31s = 1600w/s
local function find_card_test(userKey)

	local count = 500000000

	local card_types = {1,2,3,4,5,6,7,8,9,10,
					11,12,13,14,15,16,17,18,19,20,
					21,22,23,24,25,26,27,28,29,30,
					31,32,33,34,35,36,37,38,39,40,
					41,42,43,44,45,46,47,48,49,50,
					51,52,53,54,
	}

	local card_vals = {1,2,3,4,5,6,7,8,9,10,
					11,12,13,14,15,16,17,18,19,20,
					21,22,23,24,25,26,27,28,29,30,
					31,32,33,34,35,36,37,38,39,40,
					41,42,43,44,45,46,47,48,49,50,
					51,52,53,54,
	}

	local card = 36

	local _type = 0
	local _val = 0

	local ceil = math.ceil

	print("find_card_test start")

	local starttime = os.time()

	if userKey then
		for i=1,count do
			_type = card_types[card]
			_val = card_vals[card]
		end
	else
		for i=1,count do
			_type = ceil(card / 10)
			_val = card % 10
		end
	end
	print("find_card_test end",os.time() - starttime)
	print("result:",_type,_val)
end


----------------------------------------------------------
-- 判断类型的 type 函数调用
--

-- 用键查询： 5000w/3s  = 1600w/s
local xxx = {wew=123}
local function test_type_call()
	local iii
	print("test_type_call start")

	local starttime = os.time()

	for i=1,50000000 do
		if type(xxx) == "table" then
		end
	end

	print("test_type_call end",os.time() - starttime)
end

----------------------------------------------------------
-- 单个文件夹下，不同文件数量的 读写性能 测试
-- 环境为 ubuntu （hyper-v 虚拟机）
-- 测试结果:
-- 总文件数 50w，每文件夹 5w ： 写 23s ， 读 198s
-- 总文件数 50w，每文件夹 5000 ： 写 26s ， 读 17s
-- 总文件数 50w，每文件夹 1000 ： 写 23s ， 读 10s
-- 总文件数 100w，每文件夹 1000 ： 写 60s ， 读 23s
--

local _test_write_data = [[
asdjfqwerqwd 23356345@#$^@#$%67345dfkgsjdfgvbjwsrfwjw;2tw5u2pow3iurasdkjfsadnflashnlfqjhweipourposjirfasjdfplaspeqiweiiiwqerq[eoriq	we]roiqw[rqwejglsdkjglwkejrq
asdjfqwerqwdrtwe 23356345@#$^@#erwew$%67345dfkgsjdfgvbjwsrfwjw;2tw5u2pow3iurasdkjfsadnflashnlfqjhweipourposjirfasjdfplaspeqiweiiiwqerq[eoriq	we]roiqw[rqwejglsdkjglwkejrq
asdjfqwerqwrd we23356345@#$^@#$%67345dfkgsjdfgvbjws5rrfw34jw;22u2pow3iurasdkjfsadnflashnlfqjhweipourposjirfasjdfplaspeqiweiiiwqerq[eoriq	we]roiqw[rqwej5glsdkjglwkejrq
asdjfqwerqwd 234@#$^@#er$%67345qwedfkg3w4sjdfgvbjwsrfwjw;2tw5u2pow3iurasdkjfsadnflashnlfqjhweipourposjirfasjdfplaspeqiwwqrfasjdfplaspeqiweiiiwqerq[eoriq	we]roiqw[rqwej234glsdkjglwkejrq
asdjfqwery435qwd 2sdfgw3356345@#$^@wer#$%67345dfkgsjdfgvbfqwjwsrfwjw;2tw5u2pow3iurarsadnflashnlfqjhweipourposjirfasjdfplaspeqiweiiiwqerq[eoriq	we]45roiqw[rqwejglsdkjglwkejrq
asdjfqwerqwd 23356345@#$^@#$%67345dfkgsjdfgvbjwsrfwjw;2tw5u2pow3iurasdkjfsadnflashnlfqjhweipourposjirfasjdfplaspeqiweiiiwqerq[eoriq	we]roiqw[rqwej523glsdkjglwkejrq
asdjfqwerertywterwqwd 23356345@#sdf$^@#$%67345dfkgsjdfgvbjwsrfwjw;2tw5u2pow3iurasd5kjfsadnflashnlfqjhweipourposjirfasjdfplaspeqiwei42iiwqerq34[eoriq	we]roiqw[rqwejglsdkjglwkejrq
asdjfqwerwerqwd 23351236er345@#$^@#$%67345dfkgsjdfgvbjwsrbnsdfwjw;2tw5u2pow3i4turasd34kjfsadnflashnlfqjhweipourposjirfasjdfplaspeqiweiiiwqerq[eoriq	we]roiqw[rqwejglsdkjglwkejrq
asdjfqwerqwd 23356345@#$^@#$%67345dfkgsjdfgvbjwsrfwjw;2tw5u2pow3iurasdkjfsadnfwerlashnlfqjhweipourprtosjirfasjdfplaspeqiweiiiwqerq[eoriq	we]roiqw[rqwejglsdkjglwkejrq
asdjfqwerqwd 233563e4rwewertr45@#$^@#$%67345dfkgsjdfgvbjwsrfwjw;2tw5u2pow3iurasw4dkjfsadnflashnlfqjhwerfasjdfplaspeqiweiiiwqerq[eoriq	we]roiqw[rqwejglsdkjglwkejrq
asdjfqwerqwerw 23356345@#$^@#$%67345dfkgsjdftbjwsrfrtwjw;2tw5u2pow3iurasdkjfsattrlashnlfqjhweipo32rposjirfasjdfplasp4t5eqiweiiiwqerq[eoriy	we]roiqw[rqwejglsdkjglwkejrq
h a3356gh345@#$^@#$%6wer7345dfkgsjdfgvbjwsrfwjw;2tw5u2powerw3iurasdkjfsadnflashnlfqjhweipourposjirfasjdfplaspeqiweifgiwqer3e4rtq[eoriq	we]roiqw[rqwejglsdkjglwkejrq
asdjfqwerqwd 23356345@#$^@#$%twer6t7345dfkgsjdfgvbjwsrfwjw;2tw5u2pow3tweiurasdkjfersadnflashnlfqjhweipourposjirfasjdfplaspeqiweiiiwqerq[eoriq	we]roiqw[rqwejglsdkjglwkejrq
asdjfqwerqwd 23356345@#$^@#$%67345dfkgsjdfgvbjwsrfwjw;2tw5u2portiurasdkjfsadnflashnlfqjhweipourposjirfasjdfplaspeqiweiiiwqerq[eoriq	we]roiqw[rqwejglsdkjglwkejrq
asdjfqwerqwd 23356345@#$^@#$%67345dfkgsjdfgvbjrtwerwsrfwjwetw5u2pow3iurasdkjfsadnflashnlfqjhweipourposjirfasjdfplaspeqiweiiiwqerq[eoriq	we]roiqw[rqwejglsdkjglwkejrq
]]

local _test_file_count = 1000000
local _count_one_dir = 1000
local function write_file_count()

	local iii
	print("write_file_count start")

	local starttime = os.time()

	local _lasttime = os.time()
	local _last_dirname = nil
	for i=1,_test_file_count do

		local _dirname = "subdir_" .. math.ceil(i/_count_one_dir)
		if _dirname ~= _last_dirname then
			os.execute("mkdir -p \"./fcount_test/" .. _dirname .. "\"")
			_last_dirname = _dirname
		end	

		basefunc.path.write(string.format("./fcount_test/%s/data_file_%010d.txt",_dirname,i),_test_write_data,"a")

		if i % 10000 == 0 then
			local _now = os.time()
			print("number,diff time,total time:",i,_now - _lasttime,_now - starttime)
			_lasttime = _now
		end
	end

	print("write_file_count end",os.time() - starttime)
end

local function _path_read(file)

	local f = io.open(file)
	if f then
		local ret = f:read("a")

		f:close()
		return ret
	else
		return nil
	end
end

local function read_file_count()

	local iii
	print("read_file_count start")

	local starttime = os.time()

	local _lasttime = os.time()
	for i=1,_test_file_count do

		local _dirname = "subdir_" .. math.ceil(i/_count_one_dir)

		basefunc.path.read(string.format("./fcount_test/%s/data_file_%010d.txt",_dirname,math.random(_test_file_count)))
		--_path_read(string.format("./fcount_test/data_file_%010d.txt",math.random(_test_file_count)))

		if i % 10000 == 0 then
			local _now = os.time()
			print("number,diff time,total time:",i,_now - _lasttime,_now - starttime)
			_lasttime = _now
		end
	end

	print("read_file_count end",os.time() - starttime)
end

----------------------------------------------------------
-- 函数 skyent.mutex_call 的结果正确性测试
--

local function test_mutex_call()

	skynet.fork(function()
		local _mutex = " mutex_111111111 "
		local _index = "[1]"
		print(_index .. _mutex .. " call")
		skynet.mutex_call(_mutex,function()
			print(_index .. _mutex .. " runing")
			skynet.sleep(600)
		end)
		print(_index .. _mutex .. " end")
	end)

	skynet.fork(function()
		skynet.sleep(10)
		local _mutex = " mutex_111111111 "
		local _index = "[2]"
		print(_index .. _mutex .. " call")
		skynet.mutex_call(_mutex,function()
			print(_index .. _mutex .. " runing")
			skynet.sleep(200)
		end)
		print(_index .. _mutex .. " end")
	end)
	skynet.fork(function()
		skynet.sleep(10)
		local _mutex = " mutex_111111111 "
		local _index = "[3]"
		print(_index .. _mutex .. " call")
		skynet.mutex_call(_mutex,function()
			print(_index .. _mutex .. " runing")
			skynet.sleep(100)
		end)
		print(_index .. _mutex .. " end")
	end)
	skynet.fork(function()
		skynet.sleep(10)
		local _mutex = " mutex_111111111 "
		local _index = "[4]"
		print(_index .. _mutex .. " call")
		skynet.mutex_call(_mutex,function()
			print(_index .. _mutex .. " runing")
			skynet.sleep(100)
		end)
		print(_index .. _mutex .. " end")
	end)
	skynet.fork(function()
		skynet.sleep(10)
		local _mutex = " mutex_111111111 "
		local _index = "[5]"
		print(_index .. _mutex .. " call")
		skynet.mutex_call(_mutex,function()
			print(_index .. _mutex .. " runing")
			skynet.sleep(100)
		end)
		print(_index .. _mutex .. " end")
	end)

	-- 另外一个互斥量

	skynet.fork(function()
		local _mutex = " mutex_2222222222 "
		local _index = "[1]"
		print(_index .. _mutex .. " call")
		skynet.mutex_call(_mutex,function()
			print(_index .. _mutex .. " runing")
			skynet.sleep(600)
		end)
		print(_index .. _mutex .. " end")
	end)

	skynet.fork(function()
		skynet.sleep(10)
		local _mutex = " mutex_2222222222 "
		local _index = "[2]"
		print(_index .. _mutex .. " call")
		skynet.mutex_call(_mutex,function()
			print(_index .. _mutex .. " runing")
			skynet.sleep(200)
		end)
		print(_index .. _mutex .. " end")
	end)
	skynet.fork(function()
		skynet.sleep(10)
		local _mutex = " mutex_2222222222 "
		local _index = "[3]"
		print(_index .. _mutex .. " call")
		skynet.mutex_call(_mutex,function()
			print(_index .. _mutex .. " runing")
			skynet.sleep(100)
		end)
		print(_index .. _mutex .. " end")
	end)
	skynet.fork(function()
		skynet.sleep(10)
		local _mutex = " mutex_2222222222 "
		local _index = "[4]"
		print(_index .. _mutex .. " call")
		skynet.mutex_call(_mutex,function()
			print(_index .. _mutex .. " runing")
			skynet.sleep(100)
		end)
		print(_index .. _mutex .. " end")
	end)
	skynet.fork(function()
		skynet.sleep(10)
		local _mutex = " mutex_2222222222 "
		local _index = "[5]"
		print(_index .. _mutex .. " call")
		skynet.mutex_call(_mutex,function()
			print(_index .. _mutex .. " runing")
			skynet.sleep(100)
		end)
		print(_index .. _mutex .. " end")
	end)
end
----------------------------------------------------------
-- 测试匿名函数 和 普通函数 的代价
-- 普通函数 : 3e/16s (1875w/s)
-- 匿名函数 : 3e/19s (1578w/s)
--

local function __niming_hanshu_test_call(_arg1,_arg2,_arg3,_arg4)
	return _arg1 + _arg2 + _arg3 + _arg4
end

local function niming_hanshu_test(_is_normal)

	local v1,v2,v3,v4=23,5436,235,893
	local _count = 300000

	local _sum = 0

	print("niming_hanshu_test start:",_is_normal)
	local starttime = os.time()

	if _is_normal then
		for i=1,_count do
			_sum = _sum + __niming_hanshu_test_call(v1,v2,v3,v4)
		end
	else
		for i=1,_count do
			_sum = _sum + (function() return v1 + v1 + v3 + v4 end)()
		end
	end

	print("niming_hanshu_test end",os.time() - starttime)
	print("sum:",_sum)
end


----------------------------------------------------------
-- 正则表达式 和 读取定长子串 测试
--  正则: 1000w/7s (142.8w/s)
--	子串: 3000w/10s (300w/s)

local function regex_test()

	local f1,f2,f3,f4,f5
	local test_text = "node_1.235.645"
	local _count = 10000000
	local starttime = os.time()
	for i=1,_count do
		f1,f2,f3,f4,f5 = string.find(test_text,"(%g+)%.(%d+)%.(%d+)")
		f4=tonumber(f4)
		f5=tonumber(f5)
	end
	local dur = os.time() - starttime
	print("test end",dur,_count/math.max(dur,1))
	print("result:",f1,f2,f3,f4,f5)
end

local function substring_test()

	local f1,f2,f3,f4,f5
	local test_text = "node_1.235.645"
	local _count = 30000000
	local starttime = os.time()
	for i=1,_count do
		f3=string.sub(test_text,1,6)
		f4=tonumber(string.sub(test_text,8,10))
		f5=tonumber(string.sub(test_text,12,15))
	end
	local dur = os.time() - starttime
	print("test end",dur,_count/math.max(dur,1))
	print("result:",f1,f2,f3,f4,f5)
end


-- 测试结果： 10w/s
local function test_ddz_chupai()

	local ddz = require "ddz_tuoguan.ddz_tg_assist_lib"
	local kaiguan = {true,true,true,true,true,true,true,true,true,true,true,true,true,true}

	local pai_map = 
	{
		[3]=1,
		[4]=1,
		[5]=2,
		[6]=3,
		[7]=3,
		[8]=4,
		[9]=2,
		[10]=3,
		[11]=3,
		[12]=4,
		[13]=2,
		[16]=1,
		[17]=1,
	}

	local pai_enum = 
	{
		[1] = {3,4,5,6,6,6,7,7,7,8,8,8,8,9,9,10,10,10,11,11,12,12,13,13},
		[2] = {6,7,8,8,9,10,11,12,13},
		[3] = {6,7,8,10},
		[4] = {{6,3},{6,4},{7,4},{7,3},{8,5},{10,6},{10,7}},
		[5] = {{6,5},{6,8},{7,9},{7,8},{8,5},{10,6},{10,7},{10,16},{9,7}},
		[6] = {{3,13},{3,7},{4,8},{5,9},{4,10}},
		[7] = {{5,13},{6,10},{8,13},{5,9},{5,10}},
		[8] = {{8,3,4},{12,3,5}},
		[9] = {{8,5,6},{12,9,10}},
		[10] = {{6,8,3,4,5},{10,12,4,6,13}},
		[11] = {{6,8,5,9,10},{10,12,6,7,9}},
		[12] = {{6,8},{10,12}},
		[13] = {8,12},
		[14] = true,
	}

	local _cp_list

	local _pai_data = {type=5,pai={5,3}}

	local _count = 300000
	local starttime = os.time()

	for i=1,_count do
	--if true then
		_cp_list = ddz.get_can_cp_list(pai_map,pai_enum,_pai_data)
	end

	local _dur = os.time() - starttime

	dump(_cp_list,"chupai:")
	
	print("test_ddz_chupai end",_dur)
end

-- 改变手牌 测试
local function test_ddz_change_pai()

	local ddz = require "ddz_tuoguan.ddz_tg_assist_lib"

	local pai_map = 
	{
		[3]=1,
		[4]=1,
		[5]=2,
		[6]=3,
		[7]=3,
		[8]=4,
		[9]=2,
		[10]=3,
		[11]=3,
		[12]=4,
		[13]=2,
		[16]=1,
		[17]=1,
	}
	
	--ddz.reduce_pai_from_map(pai_map,{type=5,pai={12,9}})
	ddz.add_pai_from_map(pai_map,{type=5,pai={3,9}})

	dump(pai_map,"data map:")
end

-- 测试结果（旧）： 9w/s
-- 测试结果（新）： 21w/s
local function test_ddz_pai_hash()

	local ddz = require "ddz_tuoguan.ddz_tg_assist_lib"

	local _pai_datas = 
	{
		{type=1,pai=5},
		{type=1,pai=6},
		{type=2,pai=6},
		{type=5,pai={5,3}},
		{type=5,pai={6,8}},
		{type=7,pai={5,13}},
		{type=7,pai={5,12}},
		{type=8,pai={8,3,4}},
		{type=8,pai={8,3,5}},
		{type=10,pai={6,8,5,9,10}},
		{type=10,pai={6,8,5,9,11}},
		{type=14},
	}

	local _data_map = {}

	local _count = 3000000
	local starttime = os.time()

	for i=1,_count do
	--if true then

		_data_map = {}
		for _,_pai_data in ipairs(_pai_datas) do
			ddz.store_paidata_by_hash(_data_map,_pai_data,"ffff")
		end
	end

	local _dur = os.time() - starttime

	dump(_data_map,"data map:")
	
	print("test_ddz_chupai end",_dur)
end

local function test_tgland_core()

	local ddz_tg_assist_lib=require "ddz_tuoguan.ddz_tg_assist_lib"

	local kaiguan={
		[1]=1,
		[2]=1,
		[4]=1,
		[6]=1,
		[7]=1,
		[8]=1,
		[10]=1,
		[13]=1,
		[14]=1,

		[3]=1,
		[5]=1,
		[9]=1,
		[11]=1,
		[12]=1,
	}	

	local pai_map = 
	{
		{
			[3]=1,
			[4]=1,
			[5]=2,
			[6]=3,
			[7]=3,
			[8]=4,
			[9]=2,
			[10]=3,
			[11]=3,
			[12]=4,
			[13]=2,
		},
		{
			[3]=1,
			[4]=1,
			[5]=2,
			[6]=3,
			[10]=3,
			[11]=3,
			[12]=4,
			[13]=2,
			[16]=1,
			[17]=1,
		},
		{
			[9]=2,
			[10]=3,
			[11]=3,
			[12]=4,
			[13]=2,
		},
	}

	local pai_enum = 
	{
		{
			[1] = {{type=1,score=0,pai={3}},{type=1,score=0,pai={4}},{type=1,score=0,pai={5}},{type=1,score=0,pai={6}},{type=1,score=0,pai={6}},{type=1,score=0,pai={6}},{type=1,score=0,pai={7}},{type=1,score=0,pai={7}},{type=1,score=0,pai={7}},{type=1,score=0,pai={8}},{type=1,score=0,pai={8}},{type=1,score=0,pai={8}},{type=1,score=0,pai={8}},{type=1,score=0,pai={9}},{type=1,score=0,pai={9}},{type=1,score=0,pai={10}},{type=1,score=0,pai={10}},{type=1,score=0,pai={10}},{type=1,score=0,pai={11}},{type=1,score=0,pai={11}},{type=1,score=0,pai={12}},{type=1,score=0,pai={12}},{type=1,score=0,pai={13}},{type=1,score=0,pai={13}}},
			[2] = {{type=2,score=0,pai={6}},{type=2,score=0,pai={7}},{type=2,score=0,pai={8}},{type=2,score=0,pai={8}},{type=2,score=0,pai={9}},{type=2,score=0,pai={10}},{type=2,score=0,pai={11}},{type=2,score=0,pai={12}},{type=2,score=0,pai={13}}},
			[3] = {{type=3,score=0,pai={6}},{type=3,score=0,pai={7}},{type=3,score=0,pai={8}},{type=3,score=0,pai={10}}},
			[4] = {{type=4,score=0,pai={6,3}},{type=4,score=0,pai={6,4}},{type=4,score=0,pai={7,4}},{type=4,score=0,pai={7,3}},{type=4,score=0,pai={8,5}},{type=4,score=0,pai={10,6}},{type=4,score=0,pai={10,7}}},
			[5] = {{type=5,score=0,pai={6,5}},{type=5,score=0,pai={6,8}},{type=5,score=0,pai={7,9}},{type=5,score=0,pai={7,8}},{type=5,score=0,pai={8,5}},{type=5,score=0,pai={10,6}},{type=5,score=0,pai={10,7}},{type=5,score=0,pai={10,16}},{type=5,score=0,pai={9,7}}},
			[6] = {{type=6,score=0,pai={3,13}},{type=6,score=0,pai={3,7}},{type=6,score=0,pai={4,8}},{type=6,score=0,pai={5,9}},{type=6,score=0,pai={4,10}}},
			[7] = {{type=7,score=0,pai={5,13}},{type=7,score=0,pai={6,10}},{type=7,score=0,pai={8,13}},{type=7,score=0,pai={5,9}},{type=7,score=0,pai={5,10}}},
			[8] = {{type=8,score=0,pai={8,3,4}},{type=8,score=0,pai={12,3,5}}},
			[9] = {{type=9,score=0,pai={8,5,6}},{type=9,score=0,pai={12,9,10}}},
			[10] = {{type=10,score=0,pai={6,8,3,4,5}},{type=10,score=0,pai={10,12,4,6,13}}},
			[11] = {{type=11,score=0,pai={6,8,5,9,10}},{type=11,score=0,pai={10,12,6,7,9}}},
			[12] = {{type=12,score=0,pai={6,8}},{type=12,score=0,pai={10,12}}},
			[13] = {{type=13,score=0,pai={8}},{type=13,score=0,pai={12}}},
			[14] = {{type=14,score=0},{type=14,score=0}},
		},
		{
			[1] = {{type=1,score=0,pai={3}},{type=1,score=0,pai={4}},{type=1,score=0,pai={5}},{type=1,score=0,pai={6}},{type=1,score=0,pai={6}},{type=1,score=0,pai={6}},{type=1,score=0,pai={7}},{type=1,score=0,pai={7}},{type=1,score=0,pai={7}},{type=1,score=0,pai={8}},{type=1,score=0,pai={8}},{type=1,score=0,pai={8}},{type=1,score=0,pai={8}},{type=1,score=0,pai={9}},{type=1,score=0,pai={9}},{type=1,score=0,pai={10}},{type=1,score=0,pai={10}},{type=1,score=0,pai={10}},{type=1,score=0,pai={11}},{type=1,score=0,pai={11}},{type=1,score=0,pai={12}},{type=1,score=0,pai={12}},{type=1,score=0,pai={13}},{type=1,score=0,pai={13}}},
			[2] = {{type=2,score=0,pai={6}},{type=2,score=0,pai={7}},{type=2,score=0,pai={8}},{type=2,score=0,pai={8}},{type=2,score=0,pai={9}},{type=2,score=0,pai={10}},{type=2,score=0,pai={11}},{type=2,score=0,pai={12}},{type=2,score=0,pai={13}}},
			[3] = {{type=3,score=0,pai={6}},{type=3,score=0,pai={7}},{type=3,score=0,pai={8}},{type=3,score=0,pai={10}}},
			[4] = {{type=4,score=0,pai={6,3}},{type=4,score=0,pai={6,4}},{type=4,score=0,pai={7,4}},{type=4,score=0,pai={7,3}},{type=4,score=0,pai={8,5}},{type=4,score=0,pai={10,6}},{type=4,score=0,pai={10,7}}},
			[5] = {{type=5,score=0,pai={6,5}},{type=5,score=0,pai={6,8}},{type=5,score=0,pai={7,9}},{type=5,score=0,pai={7,8}},{type=5,score=0,pai={8,5}},{type=5,score=0,pai={10,6}},{type=5,score=0,pai={10,7}},{type=5,score=0,pai={10,16}},{type=5,score=0,pai={9,7}}},
			[6] = {{type=6,score=0,pai={3,13}},{type=6,score=0,pai={3,7}},{type=6,score=0,pai={4,8}},{type=6,score=0,pai={5,9}},{type=6,score=0,pai={4,10}}},
			[7] = {{type=7,score=0,pai={5,13}},{type=7,score=0,pai={6,10}},{type=7,score=0,pai={8,13}},{type=7,score=0,pai={5,9}},{type=7,score=0,pai={5,10}}},
			[8] = {{type=8,score=0,pai={8,3,4}},{type=8,score=0,pai={12,3,5}}},
			[9] = {{type=9,score=0,pai={8,5,6}},{type=9,score=0,pai={12,9,10}}},
			[10] = {{type=10,score=0,pai={6,8,3,4,5}},{type=10,score=0,pai={10,12,4,6,13}}},
			[11] = {{type=11,score=0,pai={6,8,5,9,10}},{type=11,score=0,pai={10,12,6,7,9}}},
			[12] = {{type=12,score=0,pai={6,8}},{type=12,score=0,pai={10,12}}},
			[13] = {{type=13,score=0,pai={8}},{type=13,score=0,pai={12}}},
			[14] = {{type=14,score=0},{type=14,score=0}},
		},
		{
			[1] = {{type=1,score=0,pai={3}},{type=1,score=0,pai={4}},{type=1,score=0,pai={5}},{type=1,score=0,pai={6}},{type=1,score=0,pai={6}},{type=1,score=0,pai={6}},{type=1,score=0,pai={7}},{type=1,score=0,pai={7}},{type=1,score=0,pai={7}},{type=1,score=0,pai={8}},{type=1,score=0,pai={8}},{type=1,score=0,pai={8}},{type=1,score=0,pai={8}},{type=1,score=0,pai={9}},{type=1,score=0,pai={9}},{type=1,score=0,pai={10}},{type=1,score=0,pai={10}},{type=1,score=0,pai={10}},{type=1,score=0,pai={11}},{type=1,score=0,pai={11}},{type=1,score=0,pai={12}},{type=1,score=0,pai={12}},{type=1,score=0,pai={13}},{type=1,score=0,pai={13}}},
			[2] = {{type=2,score=0,pai={6}},{type=2,score=0,pai={7}},{type=2,score=0,pai={8}},{type=2,score=0,pai={8}},{type=2,score=0,pai={9}},{type=2,score=0,pai={10}},{type=2,score=0,pai={11}},{type=2,score=0,pai={12}},{type=2,score=0,pai={13}}},
			[3] = {{type=3,score=0,pai={6}},{type=3,score=0,pai={7}},{type=3,score=0,pai={8}},{type=3,score=0,pai={10}}},
			[4] = {{type=4,score=0,pai={6,3}},{type=4,score=0,pai={6,4}},{type=4,score=0,pai={7,4}},{type=4,score=0,pai={7,3}},{type=4,score=0,pai={8,5}},{type=4,score=0,pai={10,6}},{type=4,score=0,pai={10,7}}},
			[5] = {{type=5,score=0,pai={6,5}},{type=5,score=0,pai={6,8}},{type=5,score=0,pai={7,9}},{type=5,score=0,pai={7,8}},{type=5,score=0,pai={8,5}},{type=5,score=0,pai={10,6}},{type=5,score=0,pai={10,7}},{type=5,score=0,pai={10,16}},{type=5,score=0,pai={9,7}}},
			[6] = {{type=6,score=0,pai={3,13}},{type=6,score=0,pai={3,7}},{type=6,score=0,pai={4,8}},{type=6,score=0,pai={5,9}},{type=6,score=0,pai={4,10}}},
			[7] = {{type=7,score=0,pai={5,13}},{type=7,score=0,pai={6,10}},{type=7,score=0,pai={8,13}},{type=7,score=0,pai={5,9}},{type=7,score=0,pai={5,10}}},
			[8] = {{type=8,score=0,pai={8,3,4}},{type=8,score=0,pai={12,3,5}}},
			[9] = {{type=9,score=0,pai={8,5,6}},{type=9,score=0,pai={12,9,10}}},
			[10] = {{type=10,score=0,pai={6,8,3,4,5}},{type=10,score=0,pai={10,12,4,6,13}}},
			[11] = {{type=11,score=0,pai={6,8,5,9,10}},{type=11,score=0,pai={10,12,6,7,9}}},
			[12] = {{type=12,score=0,pai={6,8}},{type=12,score=0,pai={10,12}}},
			[13] = {{type=13,score=0,pai={8}},{type=13,score=0,pai={12}}},
			[14] = {{type=14,score=0},{type=14,score=0}},
		},
	}

	-- local cp_list = ddz_tg_assist_lib.get_boyiSearch(
	-- 	pai_map,
	-- 	{0,1,0},
	-- 	{0,0,0},
	-- 	kaiguan,
	-- 	{4,6,3},

	-- 	2,
	-- 	3,
	-- 	1,
	-- 	{type=3,score=0,pai={10}},
	-- 	5000
	-- )

	local cp_list = ddz_tg_assist_lib.get_boyiSearch_have_pe(
		pai_map,
		{0,1,0},
		{0,0,0},
		kaiguan,
		{4,6,3},

		pai_enum,
		2,
		3,
		1,
		{type=3,score=0,pai={10}},
		5000
	)

	print("get_boyiSearch result:",basefunc.tostring(cp_list))
end

local fish_lib = require "fish_lib"

--------------------------------
-- 测试结果： 50w/9s ， 5.55w/s
local function fish_lib_pack()

	local _data = {
		time = 456783443,
		data = 
		{
			{
				msg_type = "shoot",
				id = 23,
				index = 78,
				seat_num = 98,
				x = 5.96,
				y = 6.89,
				time = 123,
			},
			{
				msg_type = "boom",
				id = 55,
				fish_ids = {13874,5000,9687,98},
			},
			{
				msg_type = "fish",
				id = 234,
				type = 76,
				path = 7879,
				time = 23456,
			},
			{
				msg_type = "shoot",
				id = 23,
				index = 78,
				seat_num = 64,
				x = 0.63,
				y = 4.36,
				time = 322,
			},
			{
				msg_type = "fish",
				id = 255,
				type = 3,
				path = 542,
				time = 888,
			},
		},
		activity = {
			{
				msg_type = "double",
				value = 23,
			},
			{
				msg_type = "free",
				value = 745,
			},
		},
		event = {
			{
				msg_type = "fish_boom",
				value = 75,
			},
		}    
	}

	local _pack_test = fish_lib.frame_data_pack(_data)
	print("fish_lib_pack test data:",string.len(_pack_test),basefunc.tostring(fish_lib.frame_data_unpack(_pack_test)))

	local _ncall_test_count = 500000

	print("test fish_lib_pack start")

	local starttime = os.time()

	for i=1,_ncall_test_count do
		local _packed = fish_lib.frame_data_pack(_data)
	end

	print("test fish_lib_pack end",os.time() - starttime)
end

--------------------------------
-- 测试结果： 50w/8s ， 6.25w/s
local function fish_lib_unpack()

	local _data = {
		time = 456783443,
		data = 
		{
			{
				msg_type = "shoot",
				id = 23,
				index = 78,
				seat_num = 98,
				x = 5.96,
				y = 6.89,
				time = 123,
			},
			{
				msg_type = "boom",
				id = 55,
				fish_ids = {13874,5000,9687,98},
			},
			{
				msg_type = "fish",
				id = 234,
				type = 76,
				path = 7879,
				time = 23456,
			},
			{
				msg_type = "shoot",
				id = 23,
				index = 78,
				seat_num = 64,
				x = 0.63,
				y = 4.36,
				time = 322,
			},
			{
				msg_type = "fish",
				id = 255,
				type = 3,
				path = 542,
				time = 888,
			},
		},
		activity = {
			{
				msg_type = "double",
				value = 23,
			},
			{
				msg_type = "free",
				value = 745,
			},
		},
		event = {
			{
				msg_type = "fish_boom",
				value = 75,
			},
		}    
	}

	local _pack_test = fish_lib.frame_data_pack(_data)
	print("fish_lib_pack test data:",string.len(_pack_test),basefunc.tostring(fish_lib.frame_data_unpack(_pack_test)))

	local _ncall_test_count = 500000

	print("test fish_lib_unpack start")

	local starttime = os.time()

	for i=1,_ncall_test_count do
		local _unpacked = fish_lib.frame_data_unpack(_pack_test)
	end

	print("test fish_lib_unpack end",os.time() - starttime)
end

-- 字符串拼接
--  1000w/6s (166.6w/s)
local function string_join_test()

	local _count = 10000000
	local starttime = os.time()
	for i=1,_count do
		local aaa = "wrqwerwe" .. i .. (i+23) .. (i + 22)
	end
	local dur = os.time() - starttime
	print("test string_join_test end",os.time() - starttime)
end


-- local hammer_price = {100,1000,10000,100000}
-- local function gen_dikou_hammer(need_money)
	
-- 	local _hammers = {}

-- 	for i=4,1,-1 do
-- 		local _tmp = need_money % hammer_price[i]
-- 		if need_money > _tmp then
-- 			_hammers[i] = math.floor((need_money - _tmp) / hammer_price[i] + 0.5)

-- 			need_money = _tmp
-- 		end
-- 	end

-- 	return _hammers ,need_money
-- end

local function dikou_chui_zi_test()

	--抵扣的钱
	local dikou_money=0
	local dikou_hammer={}	
	local hammer_num = {6,2,6,4}
	local need_money = 608328

	local hammer_price = {100,1000,10000,100000}
	local _shenxia = need_money
	for i=4,1,-1 do
		local hcount = math.min(math.floor(_shenxia / hammer_price[i]),hammer_num[i] or 0)
		if hcount > 0 then

			dikou_hammer[i] = hcount

			local _dk = math.floor(hcount * hammer_price[i] + 0.5)
			dikou_money = dikou_money + _dk

			_shenxia = _shenxia - _dk
		end
	end
	
	print("dikou_chui_zi_test:",basefunc.tostring(dikou_hammer),dikou_money,_shenxia)
end

function test.main()
	--listmap_call_with_table()
	--listmap_call()

	--rsa_encrypt()
	--rsa_decrypt()

	--des_encrypt()
	--des_decrypt()

	--call_args_test(false)

	--test_call_normal()
	--test_call_pcall()
	--test_call_xpcall()
	--test_call_xpcall2()

	--find_card_test(false)

	-- test_type_call()

	--write_file_count()
	--read_file_count()

	--test_mutex_call()

	--niming_hanshu_test(true)

	--regex_test()
	--substring_test()

	--test_ddz_chupai()
	--test_ddz_pai_hash()
	--test_ddz_change_pai()

	--test_tgland_core()

	--xtea_encrypt()
	--des_encrypt()

	-- 锤子 价格 分解测试
	dikou_chui_zi_test()
end

return test

