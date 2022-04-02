--
-- Author: hw
-- Date: 2018/3/23
-- Time: 
-- 说明：托管 的 管理
--ddz_match_room_service
--[[
	自动控水方案
		控制级别： 1,2,... n
		周期：以时间为周期，  
		调节参考量： 总水池， 周期内 每局平均盈利

--]]


local skynet = require "skynet_plus"
local nodefunc = require "nodefunc"
local base=require "base"

local basefunc = require "basefunc"
local nor_mj_create_haopai = require "nor_mj_create_haopai"

local nor_mj_room_lib = require "nor_mj_room_lib"
local mj_fhp_base_lib=require "mj_fahaopai_base_lib"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

local haopai_config
local haopai_config_time

DATA.tuoguan_data = DATA.tuoguan_data or 
{

	-- 默认的模式概率: 托管数量为 2, 或 3 时， 模式选择概率
	default_models_cfg = {{50,50},{25,25,25,25}},
}
local D = DATA.tuoguan_data

local function get_model_name(_d)
	if type(_d.model_name) == "number" then
		return "freestyle_game"
	else
		return "match_game"
	end
end

-- 根据配置 得到番数 步数 
local function get_fsbs_by_config(_param)

	local _fsbs_map = _param.config.haopai_fsbs_map

	local _fsbs 
	for _,_data in ipairs(_fsbs_map) do
		if _param.level_data.haopai_prob <= _data.haopai_prob then
			_fsbs = _data
			break
		end
	end

	_fsbs = _fsbs or _fsbs_map[#_fsbs_map]

	return basefunc.ranodm_array_i(_fsbs.hupai_fanshu),basefunc.ranodm_array_i(_fsbs.bushu)
end


--[[ 模式定义
local tuoguan_models_cfg = 
{
	-- 1 个托管
	{
		-- 1 自摸 （被玩家点炮 要考虑玩家定缺情况）
		{prob=100, model=1},	
	},
	-- 2 个托管
	{
		-- 1 点 2 炮（小翻 早走） 
		-- 1 自摸 （被玩家点炮 要考虑玩家定缺情况）
		{prob=50, model=1},	
		-- 都自摸（小翻 中翻）	考虑玩家点炮
		{prob=50, model=2},	
	},
	-- 3 个托管
	{
		-- 1 点 2 炮（小翻 早走）
		-- 1 点 3 炮
		-- 1 自摸 （被玩家点炮 要考虑玩家定缺情况）
		{prob=25, model=1},	
		-- 2 点 3 炮（小翻 早走）
		-- 1 点 2 炮
		-- 1 自摸 （被玩家点炮 要考虑玩家定缺情况）
		{prob=25, model=2},	
		-- 1 点 3 炮（小翻 早走）
		-- 1 2 自摸 （被玩家点炮 要考虑玩家定缺情况） 
		{prob=25, model=3},	
		-- 1，2，3都自摸 或被点炮
		{prob=25, model=4},	
	},
}
--]]

--[[ 根据配置 计算番数
local function get_fanshu_by_cfg()

	-- 根据盈利系数 构造概率表
	local _fan_prob = {100-tuoguan_win_factor,tuoguan_win_factor,tuoguan_win_factor}

	local _sum = 100 + tuoguan_win_factor

	local _prob_sum = 0
	local _rand = math.random(_sum)
	for i,_prob in ipairs(_fan_prob) do
		_prob_sum = _prob_sum + _prob
		if _rand <= _prob_sum then
			return i
		end
	end
	
	return _fan_prob[1]
end
--]]

-- 得到 两种花色以外的那种花色
local function get_other_color(_color1,_color2)
	for i=1,3 do
		if i~=_color1 and i~=_color2 then
			return i
		end
	end
end

-- 计算随机花色：依次计算 dq_color,f_color,s_color ， 不为 nil 才计算
function PUBLIC.calc_random_color(_hupai_data)

	-- 随机花色
	_hupai_data.dq_color = _hupai_data.dq_color or math.random(3)
	_hupai_data.f_color = _hupai_data.f_color or ((_hupai_data.dq_color + math.random(2) - 1) % 3 + 1)
	_hupai_data.s_color = get_other_color(_hupai_data.dq_color,_hupai_data.f_color)
end

-- 计算牌型
function PUBLIC.calc_hupai_data_type(_hupai_data,_fanshu,_bushu)
	--_hupai_data.hupai_fanshu = _fanshu or get_fanshu_by_cfg()
	_hupai_data.hupai_fanshu = _fanshu or 1

	-- 小番早走，大番 晚走 （加上一定的随机因素）
	if not _bushu then
		if math.random(100) < 85 then
			_bushu = math.min(_hupai_data.hupai_fanshu,3)
		else
			_bushu = math.random(3)
		end
	end

	_hupai_data.bushu = _bushu
end

PUBLIC.gen_hupai_data_funcs = 
{
	-- 1 个托管
	{
		-- 1 点 2 炮（小翻 早走） 
		-- 1 自摸 （被玩家点炮 要考虑玩家定缺情况）
		function(_model_data,_hupai_datas,_param)
			PUBLIC.calc_hupai_data_type(_hupai_datas[1],get_fsbs_by_config(_param))
			PUBLIC.calc_random_color(_hupai_datas[1])
		end,
	},

	-- 2 个托管
	{
		-- 1 点 2 炮（小翻 早走） 
		-- 1 自摸 （被玩家点炮 要考虑玩家定缺情况）
		function(_model_data,_hupai_datas,_param)
			PUBLIC.calc_hupai_data_type(_hupai_datas[2],get_fsbs_by_config(_param))
			PUBLIC.calc_random_color(_hupai_datas[2])

			PUBLIC.calc_hupai_data_type(_hupai_datas[1],get_fsbs_by_config(_param))
			_hupai_datas[1].dq_color = _hupai_datas[2].f_color  -- 定缺配合
			PUBLIC.calc_random_color(_hupai_datas[1])
		end,
	
		-- 都自摸（小翻 中翻）	考虑玩家点炮
		function(_model_data,_hupai_datas,_param)
			PUBLIC.calc_hupai_data_type(_hupai_datas[1],get_fsbs_by_config(_param))
			PUBLIC.calc_random_color(_hupai_datas[1])

			PUBLIC.calc_hupai_data_type(_hupai_datas[2],get_fsbs_by_config(_param))
			_hupai_datas[2].dq_color = get_other_color(_hupai_datas[1].dq_color)
			_hupai_datas[2].f_color = get_other_color(_hupai_datas[2].dq_color,_hupai_datas[1].f_color)
			PUBLIC.calc_random_color(_hupai_datas[2])
		end,
	},

	-- 3 个托管
	{
		-- 1 点 2 炮（小翻 早走）
		-- 1 点 3 炮
		-- 1 自摸 （被玩家点炮 要考虑玩家定缺情况）
		function(_model_data,_hupai_datas,_param)
			PUBLIC.calc_hupai_data_type(_hupai_datas[2],get_fsbs_by_config(_param))
			PUBLIC.calc_random_color(_hupai_datas[2])

			PUBLIC.calc_hupai_data_type(_hupai_datas[3],get_fsbs_by_config(_param))
			_hupai_datas[3].dq_color = get_other_color(_hupai_datas[2].dq_color)
			PUBLIC.calc_random_color(_hupai_datas[3])

			PUBLIC.calc_hupai_data_type(_hupai_datas[1],get_fsbs_by_config(_param))
			_hupai_datas[1].dq_color = get_other_color(_hupai_datas[2].dq_color,_hupai_datas[3].dq_color)
			PUBLIC.calc_random_color(_hupai_datas[1])
		end,

		-- 2 点 3 炮（小翻 早走）
		-- 1 点 2 炮
		-- 1 自摸 （被玩家点炮 要考虑玩家定缺情况）
		function(_model_data,_hupai_datas,_param)
			PUBLIC.calc_hupai_data_type(_hupai_datas[3],get_fsbs_by_config(_param))
			PUBLIC.calc_random_color(_hupai_datas[3])

			PUBLIC.calc_hupai_data_type(_hupai_datas[2],get_fsbs_by_config(_param))
			_hupai_datas[2].dq_color = _hupai_datas[3].f_color  -- 定缺配合
			PUBLIC.calc_random_color(_hupai_datas[2])

			PUBLIC.calc_hupai_data_type(_hupai_datas[1],get_fsbs_by_config(_param))
			_hupai_datas[1].dq_color = get_other_color(_hupai_datas[2].dq_color,_hupai_datas[3].dq_color)
			PUBLIC.calc_random_color(_hupai_datas[1])
		end,

		-- 1 点 3 炮（小翻 早走）
		-- 1 2 自摸 （被玩家点炮 要考虑玩家定缺情况） 
		function(_model_data,_hupai_datas,_param)
			PUBLIC.calc_hupai_data_type(_hupai_datas[3],get_fsbs_by_config(_param))
			PUBLIC.calc_random_color(_hupai_datas[3])

			PUBLIC.calc_hupai_data_type(_hupai_datas[1],get_fsbs_by_config(_param))
			_hupai_datas[1].dq_color = _hupai_datas[3].f_color  -- 定缺配合
			PUBLIC.calc_random_color(_hupai_datas[1])

			PUBLIC.calc_hupai_data_type(_hupai_datas[2],get_fsbs_by_config(_param))
			_hupai_datas[2].dq_color = get_other_color(_hupai_datas[1].dq_color,_hupai_datas[3].dq_color)
			PUBLIC.calc_random_color(_hupai_datas[2])
		end,

		-- 1，2，3都自摸 或被点炮
		function(_model_data,_hupai_datas,_param)
			PUBLIC.calc_hupai_data_type(_hupai_datas[1],get_fsbs_by_config(_param))
			PUBLIC.calc_random_color(_hupai_datas[1])

			PUBLIC.calc_hupai_data_type(_hupai_datas[2],get_fsbs_by_config(_param))
			_hupai_datas[2].dq_color = get_other_color(_hupai_datas[1].dq_color)
			PUBLIC.calc_random_color(_hupai_datas[2])

			PUBLIC.calc_hupai_data_type(_hupai_datas[3],get_fsbs_by_config(_param))
			_hupai_datas[3].dq_color = get_other_color(_hupai_datas[1].dq_color,_hupai_datas[2].dq_color)
			PUBLIC.calc_random_color(_hupai_datas[3])
		end,
	},
}


--[[ 计算 番数，步数，产生胡牌数据
填充到 _hupai_datas 的数据项：

	hupai_fanshu 番数
	bushu 步数
	dq_color 定缺
	f_color   首要花色
	s_color	  次要花色

--]]
function PUBLIC.gen_hupai_data(_model_data,_hupai_datas,_param)

	PUBLIC.gen_hupai_data_funcs[_model_data.tuoguan_count][_model_data.model](_model_data,_hupai_datas,_param)

end

local function list_to_map(list)
    local map = {}
    for _,v in ipairs(list) do
        map[v]=map[v] or 0
        map[v]=map[v] +1
    end
    return map
end

local function get_haopai_param(_config,_model_name,_game_id)

	local _m = _config[_model_name]
	if _m then

		local _game = _m[tonumber(_game_id) or "default"]

		if _game then
			return _game
		end

		if _m.default then
			return _m.default
		end
	end

	return _config.default

end

-- 返回 模式
local function select_model(_model_cfg,_tg_count)
	local _probs = _model_cfg[_tg_count-1]
	if _probs then
		return basefunc.ranodm_array_i(_probs)
	else
		return 1	-- 返回 模式 1
	end
	
end

local function select_levels(_d,_config)

	if _config.shoudong_levels then

		local _model_name = get_model_name(_d)

		if _config.shoudong_levels_cfg[_model_name][tonumber(_d.game_id)] then
			return _config.shoudong_levels_cfg[_model_name][tonumber(_d.game_id)]
		elseif _config.shoudong_levels_cfg[_model_name].default then
			return _config.shoudong_levels_cfg[_model_name].default
		else
			return _config.shoudong_levels_cfg.default or 5
		end
	else
		return DATA.gain_power and math.min(10,math.max(1,math.floor((DATA.gain_power+9)/10))) or 5
	end

end

--[[ 准备好牌参数 
	返回值：
	{
		config=, 			_config_file  的内容
		level_data=, 		等级配置中的数据
		tuoguan_count=,		控制的托管数量
	}

	返回 nil 表示出错，或 不需要控制托管
--]]
function PUBLIC.prepare_create_haopai_param(_d,_config_name)

	-- 参数准备
	local _param = {
		-- config=, 			"tuoguan_haopai_mj_xx_cfg.lua"  的内容
		-- level_data=, 		等级配置中的数据
		-- tuoguan_count=,		托管介入数量
	}

	local _cfg_time
	
	-- 取配置
	_param.config,_cfg_time = nodefunc.get_global_config(_config_name)
	if _cfg_time ~= haopai_config_time then
		print("tuoguan config updated:",haopai_config_time,_cfg_time,_config_name)
		haopai_config_time = _cfg_time
		dump(_param.config,"xxxxxxxxxxxxxx load tuoguan haopai config:")
	end

	local _level = select_levels(_d,_param.config)
	_param.level_data = _param.config.levels[_level]
	if not _param.level_data then
		print("tuoguan profit config error:",_level,#_param.levels)
		return nil
	end
	print("xxxxxxxxxxxxxxxxxxxxxxxx tuoguan profit config selected:",get_model_name(_d),_d.game_id,DATA.gain_power,_level,basefunc.tostring(_param.level_data))

	local _random = math.random(100)
	if _random > _param.level_data.control_prob then
		print("xxxxxxxxxxxxxx tuoguan do not control:",_random,_param.level_data.control_prob)
		return nil
	end

	return _param
end

-- 计算要受控制的托管
-- 返回 受控托管的座位号数组
-- 返回  nil 表示不需要控制
function PUBLIC.gen_ctrl_tuoguan_data(_d,_param)

	-- 计算介入托管数量
	local _tg_count = basefunc.ranodm_array_i(_param.level_data.ctrl_count_prob)
	local _ctrl_tuoguan = {}
	for i,_id in ipairs(_d.p_seat_number) do
		if not _d.real_player[i] then
			_ctrl_tuoguan[#_ctrl_tuoguan + 1] = i
			if #_ctrl_tuoguan == _tg_count then
				break
			end
		end
	end
    if #_ctrl_tuoguan == 0 then
        return nil
	end

	_param.tuoguan_count = #_ctrl_tuoguan
	
	-- 随机 打乱
	nor_mj_room_lib.random_list(_ctrl_tuoguan)
	
	return _ctrl_tuoguan
end

--[[ 创建二人 麻将的 好牌
	参数 _param 
	{
		config=, 			"tuoguan_haopai_mj_xx_cfg.lua"  的内容
		level_data=, 		等级配置中的数据
		tuoguan_count=,		控制的托管数量
	}
--]]
function PUBLIC.create_tuoguan_haopai_mj_er(_d,_param)

	-- 准备参数
	local _hao_pai_param = 
	{
		model = {
			tuoguan_count = 1,
		},
		hupai_data = {},
	}

	mj_fhp_base_lib.hupai_fanshu_config = _param.config.hupai_fanshu_config

	_hao_pai_param.model.model = 1
	_hao_pai_param.hupai_data[1] = {}

	PUBLIC.calc_hupai_data_type(_hao_pai_param.hupai_data[1],get_fsbs_by_config(_param))
	_hao_pai_param.hupai_data[1].dq_color = 3
	PUBLIC.calc_random_color(_hao_pai_param.hupai_data[1])

	local _pai_pool = list_to_map(_d.play_data.pai_pool)

	dump({_hao_pai_param,_pai_pool,_param.config.base_bushu_cfg,_param.config.try_count},"xxxxxxxxxxxxxxxxxxxxxx param to create_er_chupai_mopai_struct:")

	return nor_mj_create_haopai.create_er_chupai_mopai_struct(_hao_pai_param,_pai_pool,_param.config.base_bushu_cfg,_param.config.try_count)

end

--[[ 创建 血战到底 麻将的 好牌
	参数 _param 
	{
		config=, 			"tuoguan_haopai_mj_xx_cfg.lua"  的内容
		level_data=, 		等级配置中的数据
		tuoguan_count=,
	}
--]]
function PUBLIC.create_tuoguan_haopai_mj_xzdd(_d,_param)

	-- 准备参数
	local _hao_pai_param = 
	{
		model = {
			tuoguan_count = _param.tuoguan_count,
		},
		hupai_data = {},
	}

	mj_fhp_base_lib.hupai_fanshu_config = _param.config.hupai_fanshu_config

	_hao_pai_param.model.model = select_model(_param.level_data.model_prob or D.default_models_cfg,_param.tuoguan_count)
	
	for i=1,_param.tuoguan_count do
		_hao_pai_param.hupai_data[#_hao_pai_param.hupai_data + 1] = {}
	end

	-- 产生 胡牌数据
	PUBLIC.gen_hupai_data(_hao_pai_param.model,_hao_pai_param.hupai_data,_param)

	local _pai_pool = list_to_map(_d.play_data.pai_pool)

	dump({_hao_pai_param,_pai_pool,_param.config.base_bushu_cfg,_param.config.try_count},"xxxxxxxxxxxxxxxxxxxxxx param to create_chupai_mopai_struct:")

	return nor_mj_create_haopai.create_chupai_mopai_struct(_hao_pai_param,_pai_pool,_param.config.base_bushu_cfg,_param.config.try_count)
end

--[[ 游戏开始 时 调用
在桌子数据中放入管理器的数据项
    参数 ：
		_d 桌子数据，即 room 中的 game_table[_t_num]
生成 座位数据 _d.special_deal_data[seat_num] ：
	--   fapai_list
	--   mopai_list 
	--   cp_list
	--   hupai
	--   dq_color
	--   gang_map
	--   peng_map
	--   dianpao={}	 --map key=要给谁点炮 
	-- 	 hu_pao={} -- map key=谁给我点炮
--]]
function PUBLIC.prepare_tuoguan_data_impl(_d)

	
	-- 生成参数
	local _param = PUBLIC.prepare_create_haopai_param(_d,2==GAME_TYPE_SEAT[DATA.game_type] and "tuoguan_haopai_mj_er_cfg" or 
															"tuoguan_haopai_mj_xzdd_cfg")
	if not _param then
		print("prepare_create_haopai_param return nil !")
		return false
	end

	local _ctrl_tuoguan = PUBLIC.gen_ctrl_tuoguan_data(_d,_param)
	if not _ctrl_tuoguan then
		print("tuoguan ctrl is 0!")
		return false
	end

	local _haopai_func = 2==GAME_TYPE_SEAT[DATA.game_type] and PUBLIC.create_tuoguan_haopai_mj_er or 
									PUBLIC.create_tuoguan_haopai_mj_xzdd
	local _datas,_remain_pai_pool = _haopai_func(_d,_param)

	if not _datas then
		print("create_tuoguan_haopai result is nil")
		return false
	end

	-- 保存数据
	for i,_data in ipairs(_datas) do

		print("托管控制：", _ctrl_tuoguan[i] .. " -> " .. _d.p_seat_number[_ctrl_tuoguan[i]])

		-- 给 哪些人点炮： 转换成 座位号
		local _dianpao = {}
		if _data.dianpao then
			for _i2,_ in pairs(_data.dianpao) do
				_dianpao[_ctrl_tuoguan[_i2]] = true
			end
		end
		_data.dianpao = _dianpao

		_data.peng_map = _data.peng_map or {}
		_data.gang_map = _data.gang_map or {}

		-- 胡牌步数 倒计时，出牌一次 减 1
		_data.hupai_bushu_cd = math.random(_param.level_data.hupai_bushu[1],_param.level_data.hupai_bushu[2])

		_data.seat = _ctrl_tuoguan[i]
		_d.special_deal_data[_data.seat] = _data
	end

	-- 在被点炮 中 记录 谁 给自己点炮
	for _seat_num,_data in pairs(_d.special_deal_data) do
		for _seat_hu_pao,_ in pairs(_data.dianpao) do
			local hu_pao = _d.special_deal_data[_seat_hu_pao].hu_pao or {}
			hu_pao[_seat_num] = true
			_d.special_deal_data[_seat_hu_pao].hu_pao = hu_pao
		end
	end

	_d.play_data.pai_pool = _remain_pai_pool

	dump({_d.special_deal_data,_d.play_data.pai_pool},"xxxxxxxxxxxxxxxxxxxxxx create_chupai_mopai_struct result :")
	
	--[[--------------------------------- test --------------------------------------------
	local _check_pai_map = {}
	local count = 0
	for i,_data in ipairs(_datas) do
		for _,pai in pairs(_data.fapai_list) do
			_check_pai_map[pai] = (_check_pai_map[pai] or 0) + 1
			count = count + 1
		end
		for _,pai in pairs(_data.mopai_list) do
			_check_pai_map[pai] = (_check_pai_map[pai] or 0) + 1
			count = count + 1
		end
		if _data.hupai then
			_check_pai_map[_data.hupai] = (_check_pai_map[_data.hupai] or 0) + 1
			count = count + 1
		end
	end
	for _,pai in pairs(_d.play_data.pai_pool) do
		_check_pai_map[pai] = (_check_pai_map[pai] or 0) + 1
		count = count + 1
	end
	
	dump(_check_pai_map , "xxxxxxxxxxxxxxxxxxxxxx create_chupai_mopai_struct result 3333333333:")
	--]]

	return true
end

function PUBLIC.prepare_tuoguan_data(_d)

	-- 必须检查 配置参数是否合法，特别是 根数，二人麻将的根数

	-- 用 xpcall 包起来，避免崩溃导致的卡死
	local ok,ret = xpcall(PUBLIC.prepare_tuoguan_data_impl,basefunc.error_handle,_d)
	if ok then
		return ret
	else
		print("call prepare_tuoguan_data_impl error:",ret)
		return false
	end
end
