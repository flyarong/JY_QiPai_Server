return {
	areagame=
	{
		[1]=
		{
			id = 1,
			name = "成都",
			gamelist = {1,2,3,},
		},
		[2]=
		{
			id = 2,
			name = "眉山",
			gamelist = {1,2,3,},
		},
	},
	config=
	{
		[1]=
		{
			id = 1,
			gameID = 1,
			name = "血战到底",
			sceneName = "game_MjXzFK3D",
			ruleId = 1,
		},
		[2]=
		{
			id = 2,
			gameID = 2,
			name = "经典斗地主",
			sceneName = "game_DdzFK",
			ruleId = 2,
		},
		[3]=
		{
			id = 3,
			gameID = 3,
			name = "癞子斗地主",
			sceneName = "game_DdzFK",
			ruleId = 3,
		},
	},
	rule=
	{
		[1]=
		{
			id = 1,
			rule_item = {1,2,3,4,8},
		},
		[2]=
		{
			id = 2,
			rule_item = {5,6,7,},
		},
		[3]=
		{
			id = 3,
			rule_item = {5,6,7,},
		},
	},
	rule_item=
	{
		[1]=
		{
			id = 1,
			title = "封顶：",
			data = {1,},
		},
		[2]=
		{
			id = 2,
			title = "局数：",
			data = {2,},
		},
		[3]=
		{
			id = 3,
			title = "模式：",
			data = {3,},
		},
		[4]=
		{
			id = 4,
			title = "番型：",
			data = {4,},
		},
		[5]=
		{
			id = 5,
			title = "封顶：",
			data = {5,},
		},
		[6]=
		{
			id = 6,
			title = "局数：",
			data = {6,},
		},
		[7]=
		{
			id = 7,
			title = "玩法：",
			data = {7,},
		},
		[8]=
		{
			id = 8,
			title = "玩法：",
			data = {8,},
		},
	},
	options=
	{
		[1]=
		{
			id = 1,
			type = "one",
			firstsel = {0,1,0,0},
			names = {"3番（x8）","4番（x16）", "5番（x32）", "8番（x256）"},
			serV = {"feng_ding_3f","feng_ding_4f","feng_ding_5f","feng_ding_8f"},
			cardV = {0,0,0,0,},
		},
		[2]=
		{
			id = 2,
			type = "one",
			firstsel = {0,1,0},
			names = {"4局（2房卡）","8局（3房卡）", "16局（6房卡）"},
			serV = {"race_count_4","race_count_8","race_count_16"},
			cardV = {0,0,0,},
		},
		[3]=
		{
			id = 3,
			type = "one",
			firstsel = {0,1},
			names = { "自摸加底", "自摸加番"},
			serV = {"zimo_jiadi", "zimo_jiafan",},
			cardV = {0,0,},
		},
		[4]=
		{
			id = 4,
			type = "two",
			firstsel = {1,1,1},
			names = { "天地胡","门清中张","幺九将对"},
			serV = {"tian_di_hu","men_qing_zhong_zhang","yao_jiu_jiang_dui"},
			cardV = {0,0,0,},
		},
		[5]=
		{
			id = 5,
			type = "one",
			firstsel = {0,1,0,0},
			names = {"32倍","64倍", "128倍", "256倍"},
			serV = {"feng_ding_32b","feng_ding_64b","feng_ding_128b","feng_ding_256b"},
			cardV = {0,0,0,0,},
		},
		[6]=
		{
			id = 6,
			type = "one",
			firstsel = {0,1,0},
			names = {"4局（2房卡）","8局（3房卡）", "16局（6房卡）"},
			serV = {"race_count_4","race_count_8","race_count_16"},
			cardV = {0,0,0,},
		},
		[7]=
		{
			id = 7,
			type = "two",
			firstsel = {1,1,0,1},
			names = { "3张带一对","4张带两对","3张必带","叫加倍"},
			serV = {"san_dai_dui","si_dai_2dui","san_bi_dai","jia_bei"},
			cardV = {0,0,0,0,},
		},
		[8]=
		{
			id = 8,
			type = "two",
			firstsel = {1,},
			names = {"换3张",},
			serV = {"huan_san_zhang",},
			cardV = {0,},
		},
	},
}