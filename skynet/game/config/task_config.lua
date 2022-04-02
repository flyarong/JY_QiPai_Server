return {
	task_tge=
	{
		[1]=
		{
			id = 1,
			type = "game",
			name = "对局红包",
			icon_image = "task_icon_hb",
			order_id = 1,
			is_show = 1,
		},
		[2]=
		{
			id = 2,
			type = "vip",
			name = "VIP奖励",
			icon_image = "task_icon_vip",
			order_id = 3,
			is_show = 0,
		},
		[3]=
		{
			id = 3,
			type = "day",
			name = "每日奖励",
			icon_image = "task_icon_hb",
			order_id = 2,
			is_show = 0,
		},
	},
	game=
	{
		[1]=
		{
			id = 1,
			task_id = 1,
			task_type = "game",
			icon_image = "com_icon_hb",
			desc = "任意初入江湖玩5局领0.01红包券",
			name = "对局红包",
			gotoUI = "free_hall",
			goto_game_type = "nor_mj_xzdd_er_7",
			tips = "完成任务领0.01红包券",
			order_id = 1,
		},
		[2]=
		{
			id = 2,
			task_id = 2,
			task_type = "game",
			icon_image = "com_icon_hb",
			desc = "任意小试牛刀玩5局领0.08红包券",
			name = "对局红包",
			gotoUI = "free_hall",
			goto_game_type = "nor_mj_xzdd_er_7",
			tips = "完成任务领0.08红包券",
			order_id = 2,
		},
		[3]=
		{
			id = 3,
			task_id = 3,
			task_type = "game",
			icon_image = "com_icon_hb",
			desc = "任意锋芒毕露玩5局领0.3红包券",
			name = "对局红包",
			gotoUI = "free_hall",
			goto_game_type = "nor_mj_xzdd_er_7",
			tips = "完成任务领0.3红包券",
			order_id = 3,
		},
		[4]=
		{
			id = 4,
			task_id = 4,
			task_type = "game",
			icon_image = "com_icon_hb",
			desc = "任意力战群雄玩5局领0.75红包券",
			name = "对局红包",
			gotoUI = "free_hall",
			goto_game_type = "nor_mj_xzdd_er_7",
			tips = "完成任务领0.75红包券",
			order_id = 4,
		},
	},
	vip=
	{
		[1]=
		{
			id = 1,
			task_id = 4,
			task_type = "vip",
			icon_image = "com_icon_gold",
			desc = "Vip玩10局二人麻将锋芒毕露可领20元奖励",
			name = "Vip任务",
			gotoUI = "vip",
			goto_game_type = "nor_mj_xzdd_er_7",
			tips = "完成任务获得20元奖金",
			order_id = 1,
		},
	},
}