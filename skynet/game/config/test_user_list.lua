--
-- Author: lyx
-- Date: 2018/9/10
-- Time: 15:13
-- 说明：测试 login id 用户清单
--

return 
{
	-- 允许在服务器为 "prepare_publish" 状态时登录
	login_on_prepare = 
	{
		["oBzSS0jQ_lCE2a_nzHCSlnJ2NKn8"]=true, -- 隆元线 老兔子
		["oBzSS0uaaaH7-gu4OL9oskrzh4MM"]=true, -- 何威 hewe
		["oBzSS0npptJ0HuyU940BUhtYJjRY"]=true, -- 罗魏 使徒
		["oBzSS0u15dIDn1k_IlUhjRw3k7Fc"]=true, -- 刘大铭 阿蝙
		["oBzSS0pwAOVYpOwP-Fnyk2LHUA_M"]=true, -- 万前平 农民工10
		["oBzSS0jy3AwUBE8eQRub4GzNPXqA"]=true, -- 余虹龙-互联网
		["oBzSS0hv50wjX2RKf0jyCkmRajDo"]=true, -- 杨洋 进击的电饭]煲😏
		["oBzSS0ocRBXFCN_NzdO1GOUpO6HI"]=true, -- 甘双丰 ganshuangfeng
		["oBzSS0qPKoiyyGg00mAZD6og5bhs"]=true, -- 段铭 不吃肉不舒服斯基
		["oBzSS0steZdi7_IVBXQxEjyPrLM0"]=true, -- 魏世顺 阿顺
		["oBzSS0jXZ5-k1Czh-AA7_rguN7u4"]=true, -- 杨宇
		--["oBzSS0kU_n0ZZ_MVBt8X_LOZT55Q"]=true, -- 张柯良 二宝砸家的大宝砸
		["oBzSS0r3qelDb7xWfAUWSHdhkG2c"]=true, -- 1011721 Ju.雪云
		["oBzSS0gKH-iWKJUE26ahyAnk3XsQ"]=true, -- 10142047 song彩瑜
		["oBzSS0kZBC2e8B1msxiSb9h5ehjo"]=true, -- 1016865 Er
		["oBzSS0vSyAJIgSBGyCXeRUti9sB8"]=true, -- 1017833 胖玻璃球～
		["oBzSS0jFFgW1ndOhUJy4CwoM_YiY"]=true, -- 1018816 A_牵挂（成都便民服务中心）
		["oBzSS0remc9isgxhuv-kJGrYiCvg"]=true, -- 1019261 糖糖
		["oBzSS0r2pWR8SDYxRLakTkZ_iuQk"]=true, -- 1019500 A癫子
		["oBzSS0hEHhVSwcdgFej7OwJtpdpQ"]=true, -- 1020282 ing
		["oBzSS0jJVWBziGVYfOjPYNO-KDtI"]=true, -- 1020356 6点以后-思想
		["oBzSS0oNY-Z1oe_Aex7i1zzKY7h8"]=true, -- 10246075 
		["oBzSS0mYX3hbpAe-dAgWXPggy3eE"]=true, -- 10248791 怪蜀黍
		["oBzSS0sPx0xO5ZUYIvtDEzDxqjrI"]=true, -- 10279749 ChenyiZzz
		["oBzSS0lksx0mnFIyKx7sr8P31csc"]=true, -- 1036008 A鲸鱼🐳 斗地主客服 鲸鲸
		["oBzSS0kU_n0ZZ_MVBt8X_LOZT55Q"]=true, -- 10366945 二宝砸家的大宝砸
		["oBzSS0r3q0SJkGsDMaAliDi_3O8g"]=true, -- 1052450 七年之一
		["oBzSS0jaRe3bT1JYL4KBDWixy6QQ"]=true, -- 1055452 Frank
		["oBzSS0jPYiMcNWvSKNE0sfsuKuVk"]=true, -- 105894 A鲸鱼 斗地主de 商城运营
		["oBzSS0nUq6gHXnUCFJ4PvFuhi9So"]=true, -- 106154 斗牛
		["oBzSS0qtRlLrsBiuGwcwB7ldMDWM"]=true, -- 10616038 阿Dié-
		["oBzSS0sovEpPpYWLlXxb11g1xooU"]=true, -- 10647272 晚
		["oBzSS0qfKn3ZBSKKCy3F6jZ41ggQ"]=true, -- 106797 Danny.
		["oBzSS0sd5HmBL1tGixVdtUdkKXEU"]=true, -- 10782885 鲸小妹
		["oBzSS0vCrf9PpqqYHvhhKxTuX8NM"]=true, -- 10795214 M王
		["oBzSS0oNubQLAeYi9NZ-lsgYVUxw"]=true, -- 108629 疯子
		["oBzSS0jp3kGFc1UM1ZP0OYl9aK1Q"]=true, -- 1088742 冰糖雪梨
		["oBzSS0k7GM3Xa-SLDZovpSF7fNK4"]=true, -- 109221 木.易
		["oBzSS0hIzMXlnOVnALA6NNQDFgvU"]=true, -- 1093770 lily
		["oBzSS0phIost37P2mU4E546XV0LI"]=true, -- 101380521 SaoSama 陈少哲
		["oBzSS0luwL5vU_CMRFW24KtHY-50"]=true, -- 102141866 黑。白 赵俊伏
		["oBzSS0k48ZyQvQXER8_tFpDJXFQY"]=true, -- 102162020 时光阡陌 周城宏
		["oBzSS0pDEy-OOZkTaH1LTzoIEdOM"]=true, -- 102752354 也许事与愿违 刘少游
	},

	-- 允许通过 remove_user 命令删除的用户（暂未实现）
	allow_remove = 
	{
		["R5mjpYGnU8C3l3PgzExR5GMY5OtA37z8"]=true, -- 游客
	},
}