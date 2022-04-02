--
-- Author: lyx
-- Date: 2018/4/14
-- Time: 10:31
-- 说明：通用函数
--

require "normal_enum"

local funcs = {}

-- 检查参数
-- 返回 0 或 错误号
function funcs.check_client_option(_options,_onlyone_configs)

	-- 对单选项归组
	local _onlyone_groups = {}

	-- 配置项 => group
	local _onlyone_name2group = {}
	local _last_id = 0
	for _,_groups in ipairs(_onlyone_configs) do
		for _,g in ipairs(_groups) do
			_last_id = _last_id + 1
			_onlyone_groups[#_onlyone_groups + 1] = {}
			for _,_name in ipairs(g) do
				table.insert(_onlyone_groups[#_onlyone_groups],_name)
				_onlyone_name2group[_name] = _onlyone_groups[#_onlyone_groups]
			end
		end
	end

	-- 分组重复记录： group => name
	local _dupli_groups = {}

	for _,_opt in ipairs(_options) do

		if not _opt.option then
			print("check_client_option error:option name is nil!")
			return 2020
		end

		if _onlyone_name2group[_opt.option] then
			if _dupli_groups[_onlyone_name2group[_opt.option]] then
				print("check_client_option error: option duplication:",_dupli_groups[_onlyone_name2group[_opt.option]],_opt.option)
				return 2019
			else
				_dupli_groups[_onlyone_name2group[_opt.option]] = _opt.option
			end
		end
	end

	for _,_group in ipairs(_onlyone_groups) do
		if not _dupli_groups[_group] then
			print("check_client_option error:shoould select one from:",table.concat(_group,","))
			return  2021
		end
	end

	return 0
end



return funcs