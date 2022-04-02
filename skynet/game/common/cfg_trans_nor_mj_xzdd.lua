--
-- Author: lyx
-- Date: 2018/4/14
-- Time: 10:31
-- 说明：血战到底 配置转换 函数
--

local basefunc = require "basefunc"

local mj_xzdd = {}

mj_xzdd.trans = 
{
	-- 配置项清单
	configs = 
	{
		-- 封顶
		feng_ding_3f = {kaiguan={max_fan=3}},
		feng_ding_4f = {kaiguan={max_fan=4}},
		feng_ding_5f = {kaiguan={max_fan=5}},
		feng_ding_8f = {kaiguan={max_fan=8}},

		-- 自摸模式： 自摸加番，自摸加点
		zimo_jiafan = {kaiguan={zimo_jiadian=false,zimo_jiafan=true}},
		zimo_jiadi = {kaiguan={zimo_jiadian=true,zimo_jiafan=false}},
		zimo_bujia = {kaiguan={zimo_jiafan=false,zimo_jiadian=false}},

		da_dui_zi_x2 =  {kaiguan={da_dui_zi=true},multi={da_dui_zi=1}},
		hai_di_ly_x2 = {kaiguan={hai_di_ly=true},multi={hai_di_ly=1}},
		hai_di_pao_x2 = {kaiguan={hai_di_pao=true},multi={hai_di_pao=1}},

		-- 天地胡
		tian_di_hu = {kaiguan={tian_hu=true,di_hu=true},multi={tian_hu=5,di_hu=5}},

		-- 门清中张
		men_qing_zhong_zhang = {kaiguan={men_qing=true,zhong_zhang=true}},

		-- 幺九将对
		yao_jiu_jiang_dui = {kaiguan={yao_jiu=true,qiangganghu=true}},

		-- 换三张
		huan_san_zhang = {kaiguan = {huan_san_zhang = true}},

		-- 打漂
		da_Piao = {kaiguan = {da_Piao = true}},
	},

	-- 配置项 默认值
	configs_default = 
	{
		kaiguan=
		{
			max_fan = nil,
			zimo_jiafan = true,
			zimo_jiadian = true,
			da_dui_zi = true,
			hai_di_ly = true,
			hai_di_pao = true,
			tian_hu = true,
			di_hu = true,

			men_qing = false,
			zhong_zhang = false,

			yao_jiu = false,
			zhong_zhang = false,

			huan_san_zhang = false,
		},
		multi = 
		{
			da_dui_zi=1,
			hai_di_ly=1,
			hai_di_pao=1,
			di_hu=5,
			tian_hu=5,
		},
	},

	-- 单选控制：多个里面只能选一个，且必须选一个
	onlyone=
	{
		{"feng_ding_3f","feng_ding_4f","feng_ding_5f","feng_ding_8f"},
		{"zimo_jiafan","zimo_jiadi","zimo_bujia"},
	},
}

-- 开关配置
mj_xzdd.kaiguan = 
{
	qing_yi_se 		= true,
	da_dui_zi 		= true,
	qi_dui			= true,
	long_qi_dui		= true,
	--将对
	jiang_dui       = true,
	men_qing		= true,
	zhong_zhang		= true,
	jin_gou_diao    = true,
	yao_jiu	 		= true, 


	-- 其它：和胡牌方式相关的
	hai_di_ly 		= true, -- 海底捞月 最后一张牌胡牌（自摸）
	hai_di_pao 		= true, -- 海底炮  最后一张牌胡牌（被人点炮）
	tian_hu 		= true, -- 天胡：庄家，第一次发完牌既胡牌
	di_hu	 		= true, -- 地胡：非庄家第一次发完牌 既自摸或 被别人点炮
	gang_shang_hua  = true, -- 杠上花：自己杠后补杠自摸
	gang_shang_pao  = true, -- 杠上炮：别人杠后补杠点炮
	zimo            = true, -- 自摸
	qiangganghu     = true, -- 抢杠胡 
	zimo_jiafan     = true, -- 自摸加翻 
	zimo_jiadian    = nil, -- 自摸加点
	--zimo_bujiadian  = nil,  --自摸不加
 	max_fan         = nil,   --封顶番数	
 	huan_san_zhang  = false,  -- 换三张
 	da_Piao         = false,
}

-- 番数配置
mj_xzdd.multi = 
{
	-- 牌型
	qing_yi_se 		= 2,
	da_dui_zi 		= 1,
	qi_dui			= 2,
	long_qi_dui		= 3,

	dai_geng 		= 1,
	
	jiang_dui       = 3, --将对
	men_qing		= 1, --门清
	zhong_zhang		= 1, --中章
	jin_gou_diao    = 1, --金钩钓
	yao_jiu	 		= 2, --幺九

	-- 其它：和胡牌方式相关的
	hai_di_ly 		= 1, -- 海底捞月 最后一张牌胡牌（自摸）
	hai_di_pao 		= 1, -- 海底炮  最后一张牌胡牌（被人点炮）
	tian_hu 		= 5, -- 天胡：庄家，第一次发完牌既胡牌
	di_hu	 		= 5, -- 地胡：非庄家第一次发完牌 既自摸或 被别人点炮
	gang_shang_hua  = 1, -- 杠上花：自己杠后补杠自摸
	gang_shang_pao  = 1, -- 杠上炮：别人杠后补杠点炮
	zimo            = 1, -- 自摸
	qiangganghu     = 1, -- 抢杠胡 

}

local function copy_trans_value(_trans_values,_outs)
	if _trans_values then
		for _k,_v in pairs(_trans_values) do
			if "_use_real" == _v then
				_outs[_k] = _opt.value
			else
				_outs[_k] = _v
			end
		end
	end
end

-- 转换 游戏规则
-- 返回值： 开关表，番数表
function mj_xzdd.translate(_options)
	
	-- 拷贝原始配置
	local ret = {
		kaiguan = basefunc.deepcopy(mj_xzdd.kaiguan),
		multi = basefunc.deepcopy(mj_xzdd.multi),
	}

	-- 拷贝 trans 定义的默认配置
	basefunc.merge(mj_xzdd.trans.configs_default.kaiguan,ret.kaiguan)
	basefunc.merge(mj_xzdd.trans.configs_default.multi,ret.multi)

	-- 依次处理
	for _,_opt in ipairs(_options) do
		local _trans = mj_xzdd.trans.configs[_opt.option]
		if _trans then

			copy_trans_value(_trans.kaiguan,ret.kaiguan)
			copy_trans_value(_trans.multi,ret.multi)

		end
	end

	return ret
end

return mj_xzdd