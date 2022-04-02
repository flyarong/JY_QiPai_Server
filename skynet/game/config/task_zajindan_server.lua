return {
	task=
	{
		[50]=
		{
			id = 50,
			enable = 1,
			name = "砸金蛋_累积奖励活动任务",
			own_type = "normal",
			task_enum = "common",
			process_id = 1,
			is_reset = 0,
			reset_delay = 1,
			start_valid_time = 1552428000,
			end_valid_time = 1553270399,
		},
		[100]=
		{
			id = 100,
			enable = 1,
			name = "砸金蛋_累积奖励活动任务(4.4~4.10)",
			own_type = "normal",
			task_enum = "common",
			process_id = 2,
			is_reset = 0,
			reset_delay = 1,
			start_valid_time = 1554339600,
			end_valid_time = 1554911940,
		},
		[101]=
		{
			id = 101,
			enable = 1,
			name = "捕鱼累计赢金活动",
			own_type = "normal",
			task_enum = "common",
			process_id = 3,
			is_reset = 1,
			reset_delay = 1,
			start_valid_time = 1557093600,
			end_valid_time = 1557676740,
		},
		[102]=
		{
			id = 102,
			enable = 1,
			name = "消消乐赢金活动",
			own_type = "normal",
			task_enum = "common",
			process_id = 4,
			is_reset = 0,
			reset_delay = 1,
			start_valid_time = 1559782800,
			end_valid_time = 1560355200,
		},
	},
	process_data=
	{
		[1]=
		{
			id = 1,
			process_id = 1,
			condition_type = "zajindan_award",
			condition_id = 0,
			process = {180000,400000,1300000,3000000,14000000,70000000,291120000},
			awards = {1,2,3,4,5},
			get_award_type = "nor",
		},
		[2]=
		{
			id = 2,
			process_id = 2,
			condition_type = "zajindan_award",
			condition_id = 0,
			process = {280000,400000,1200000,3000000,14000000,40000000,221120000},
			awards = {1,2,3,4,5},
			get_award_type = "nor",
		},
		[3]=
		{
			id = 3,
			process_id = 3,
			condition_type = "buyu_award",
			condition_id = 0,
			process = {20000,30000,50000,400000,500000,4000000},
			awards = {6,7,8,9,10,11},
			get_award_type = "random",
		},
		[4]=
		{
			id = 4,
			process_id = 4,
			condition_type = "xiaoxiaole_award",
			condition_id = 0,
			process = {180000,400000,1300000,3000000,14000000,40000000,121120000},
			awards = {12,13,14,15,16},
			get_award_type = "nor",
		},
	},
	condition=
	{
	},
	award_data=
	{
		[1]=
		{
			id = 1,
			award_id = 1,
			asset_type = "shop_gold_sum",
			asset_count = 80,
			get_weight = 1,
		},
		[2]=
		{
			id = 2,
			award_id = 2,
			asset_type = "shop_gold_sum",
			asset_count = 180,
			get_weight = 1,
		},
		[3]=
		{
			id = 3,
			award_id = 3,
			asset_type = "shop_gold_sum",
			asset_count = 280,
			get_weight = 1,
		},
		[4]=
		{
			id = 4,
			award_id = 4,
			asset_type = "shop_gold_sum",
			asset_count = 380,
			get_weight = 1,
		},
		[5]=
		{
			id = 5,
			award_id = 5,
			asset_type = "shop_gold_sum",
			asset_count = 880,
			get_weight = 1,
		},
		[6]=
		{
			id = 6,
			award_id = 6,
			asset_type = "prop_fish_lock",
			asset_count = 1,
			get_weight = 2,
		},
		[7]=
		{
			id = 7,
			award_id = 6,
			asset_type = "prop_fish_frozen",
			asset_count = 1,
			get_weight = 2,
		},
		[8]=
		{
			id = 8,
			award_id = 6,
			asset_type = "fish_coin",
			asset_count = 800,
			get_weight = 2,
		},
		[9]=
		{
			id = 9,
			award_id = 6,
			asset_type = "fish_coin",
			asset_count = 1000,
			get_weight = 2,
		},
		[10]=
		{
			id = 10,
			award_id = 6,
			asset_type = "shop_gold_sum",
			asset_count = 50,
			get_weight = 1,
		},
		[11]=
		{
			id = 11,
			award_id = 6,
			asset_type = "shop_gold_sum",
			asset_count = 100,
			get_weight = 1,
		},
		[12]=
		{
			id = 12,
			award_id = 7,
			asset_type = "prop_fish_lock",
			asset_count = 2,
			get_weight = 20,
		},
		[13]=
		{
			id = 13,
			award_id = 7,
			asset_type = "prop_fish_frozen",
			asset_count = 2,
			get_weight = 20,
		},
		[14]=
		{
			id = 14,
			award_id = 7,
			asset_type = "fish_coin",
			asset_count = 1000,
			get_weight = 25,
		},
		[15]=
		{
			id = 15,
			award_id = 7,
			asset_type = "fish_coin",
			asset_count = 2000,
			get_weight = 20,
		},
		[16]=
		{
			id = 16,
			award_id = 7,
			asset_type = "shop_gold_sum",
			asset_count = 100,
			get_weight = 10,
		},
		[17]=
		{
			id = 17,
			award_id = 7,
			asset_type = "shop_gold_sum",
			asset_count = 200,
			get_weight = 5,
			broadcast_content = "2元红包劵",
		},
		[18]=
		{
			id = 18,
			award_id = 8,
			asset_type = "prop_fish_lock",
			asset_count = 3,
			get_weight = 3990,
		},
		[19]=
		{
			id = 19,
			award_id = 8,
			asset_type = "prop_fish_frozen",
			asset_count = 3,
			get_weight = 3000,
		},
		[20]=
		{
			id = 20,
			award_id = 8,
			asset_type = "fish_coin",
			asset_count = 2000,
			get_weight = 2000,
		},
		[21]=
		{
			id = 21,
			award_id = 8,
			asset_type = "fish_coin",
			asset_count = 5000,
			get_weight = 1000,
		},
		[22]=
		{
			id = 22,
			award_id = 8,
			asset_type = "shop_gold_sum",
			asset_count = 100,
			get_weight = 5,
		},
		[23]=
		{
			id = 23,
			award_id = 8,
			asset_type = "shop_gold_sum",
			asset_count = 500,
			get_weight = 5,
			broadcast_content = "5元红包劵",
		},
		[24]=
		{
			id = 24,
			award_id = 9,
			asset_type = "prop_fish_lock",
			asset_count = 5,
			get_weight = 3090,
		},
		[25]=
		{
			id = 25,
			award_id = 9,
			asset_type = "prop_fish_frozen",
			asset_count = 5,
			get_weight = 3000,
		},
		[26]=
		{
			id = 26,
			award_id = 9,
			asset_type = "fish_coin",
			asset_count = 20000,
			get_weight = 2900,
		},
		[27]=
		{
			id = 27,
			award_id = 9,
			asset_type = "fish_coin",
			asset_count = 100000,
			get_weight = 1000,
		},
		[28]=
		{
			id = 28,
			award_id = 9,
			asset_type = "shop_gold_sum",
			asset_count = 300,
			get_weight = 5,
			broadcast_content = "3元红包劵",
		},
		[29]=
		{
			id = 29,
			award_id = 9,
			asset_type = "shop_gold_sum",
			asset_count = 1000,
			get_weight = 5,
			broadcast_content = "10元红包劵",
		},
		[30]=
		{
			id = 30,
			award_id = 10,
			asset_type = "prop_fish_lock",
			asset_count = 8,
			get_weight = 3000,
		},
		[31]=
		{
			id = 31,
			award_id = 10,
			asset_type = "prop_fish_frozen",
			asset_count = 8,
			get_weight = 3401,
		},
		[32]=
		{
			id = 32,
			award_id = 10,
			asset_type = "fish_coin",
			asset_count = 50000,
			get_weight = 3097,
		},
		[33]=
		{
			id = 33,
			award_id = 10,
			asset_type = "fish_coin",
			asset_count = 200000,
			get_weight = 500,
		},
		[34]=
		{
			id = 34,
			award_id = 10,
			asset_type = "shop_gold_sum",
			asset_count = 500,
			get_weight = 1,
			broadcast_content = "5元红包劵",
		},
		[35]=
		{
			id = 35,
			award_id = 10,
			asset_type = "shop_gold_sum",
			asset_count = 2000,
			get_weight = 1,
			broadcast_content = "20元红包劵",
		},
		[36]=
		{
			id = 36,
			award_id = 11,
			asset_type = "prop_fish_lock",
			asset_count = 15,
			get_weight = 3299,
		},
		[37]=
		{
			id = 37,
			award_id = 11,
			asset_type = "prop_fish_frozen",
			asset_count = 15,
			get_weight = 3400,
		},
		[38]=
		{
			id = 38,
			award_id = 11,
			asset_type = "fish_coin",
			asset_count = 100000,
			get_weight = 3000,
		},
		[39]=
		{
			id = 39,
			award_id = 11,
			asset_type = "fish_coin",
			asset_count = 500000,
			get_weight = 300,
		},
		[40]=
		{
			id = 40,
			award_id = 11,
			asset_type = "shop_gold_sum",
			asset_count = 1000,
			get_weight = 1,
			broadcast_content = "10元红包劵",
		},
		[41]=
		{
			id = 41,
			award_id = 11,
			asset_type = "shop_gold_sum",
			asset_count = 5000,
			get_weight = 1,
			broadcast_content = "50元红包劵",
		},
		[42]=
		{
			id = 42,
			award_id = 12,
			asset_type = "shop_gold_sum",
			asset_count = 80,
			get_weight = 1,
		},
		[43]=
		{
			id = 43,
			award_id = 13,
			asset_type = "shop_gold_sum",
			asset_count = 180,
			get_weight = 1,
		},
		[44]=
		{
			id = 44,
			award_id = 14,
			asset_type = "shop_gold_sum",
			asset_count = 280,
			get_weight = 1,
		},
		[45]=
		{
			id = 45,
			award_id = 15,
			asset_type = "shop_gold_sum",
			asset_count = 480,
			get_weight = 1,
		},
		[46]=
		{
			id = 46,
			award_id = 16,
			asset_type = "shop_gold_sum",
			asset_count = 1880,
			get_weight = 1,
		},
	},
}