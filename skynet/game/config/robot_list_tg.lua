--
-- Author: lyx
-- Date: 2018/4/25
-- Time: 16:08
-- 说明：托管玩家列表
--

local cjson = require "cjson"

local images_boy = require "robot_images_boy"
local images_girl = require "robot_images_girl"
local names_boy = require "robot_names_boy"
local names_girl = require "robot_names_girl"

local _users = {}

local function gen_user(_images,_names,_sex)
	local _ret = {}
	local _count = math.min(#_images,#_names)
	for i=1,_count do
	
		local _data = {
				id="robot_tg7_" .. _sex .. "_" .. (#_ret + 1),
				name=_names[i],
				image=_images[i],
				sex = _sex,
			}
	
		_data.json = cjson.encode(_data)
	
		_ret[#_ret + 1] = _data
	
	end

	return _ret
end

local _boys = gen_user(images_boy,names_boy,1)
local _girls = gen_user(images_girl,names_girl,0)

-- 取等量的男女（避免 只有男或女）
for i=1,math.min(#_boys,#_girls) do
	_users[#_users + 1] = _boys[i]
	_users[#_users + 1] = _girls[i]
end


return _users
