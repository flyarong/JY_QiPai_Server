return {
	match_info=
	{
		[1]=
		{
			id = 1,
			match_model = "xsyd",
			match_model_path = "ddz_match_xsyd_manager_service/ddz_match_xsyd_manager_service",
			matching_path = "normal_match_service/normal_match_service",
			signup_model = "renmanjikai",
			game_type = "nor_ddz_nor",
			enable = 1,
			over_time = 0,
		},
		[2]=
		{
			id = 2,
			match_model = "jbs",
			match_model_path = "normal_match_manager_service/normal_match_manager_service",
			matching_path = "normal_match_service/normal_match_service",
			signup_model = "renmanjikai",
			game_type = "nor_ddz_nor",
			enable = 1,
			over_time = 0,
		},
		[3]=
		{
			id = 3,
			match_model = "jbs",
			match_model_path = "normal_match_manager_service/normal_match_manager_service",
			matching_path = "normal_match_service/normal_match_service",
			signup_model = "renmanjikai",
			game_type = "nor_ddz_nor",
			enable = 1,
			over_time = 0,
		},
	},
	match_data_config=
	{
		[1]=
		{
			id = 1,
			data_config_id = 1,
			name = "新手引导",
			init_prel_score = 1000,
			init_final_score = 1000,
			final_factor = 10,
			enter_config_id = {1,},
		},
		[2]=
		{
			id = 2,
			data_config_id = 2,
			name = "1元公益基金赛",
			init_prel_score = 10000,
			init_final_score = 100000,
			final_factor = 10,
			enter_config_id = {2,},
		},
		[3]=
		{
			id = 3,
			data_config_id = 3,
			name = "5元公益基金赛",
			init_prel_score = 10000,
			init_final_score = 100000,
			final_factor = 10,
			enter_config_id = {3,},
		},
	},
	renmanjikai=
	{
		[1]=
		{
			id = 1,
			begin_signup_time = 0,
			end_signup_time = 2836565234,
			begin_game_condi = 3,
			max_round = -1,
			max_concurrency_game = 200,
			sign_condi = 1,
			close_time = 600,
			is_cancel_sign = 0,
			cancel_cd = 0,
		},
		[2]=
		{
			id = 2,
			begin_signup_time = 0,
			end_signup_time = 2836565234,
			begin_game_condi = 3,
			max_round = -1,
			max_concurrency_game = 200,
			sign_condi = 2,
			close_time = 600,
			is_cancel_sign = 1,
			cancel_cd = 15,
		},
		[3]=
		{
			id = 3,
			begin_signup_time = 0,
			end_signup_time = 2836565234,
			begin_game_condi = 3,
			max_round = -1,
			max_concurrency_game = 200,
			sign_condi = 3,
			close_time = 600,
			is_cancel_sign = 1,
			cancel_cd = 15,
		},
	},
	dingshikai=
	{
		[1]=
		{
			id = 1,
			begin_signup_time = 0,
			signup_dur = 0,
			begin_game_condi = 0,
			max_signup_person = 0,
			sign_condi = 0,
			close_time = 0,
			is_cancel_sign = 0,
			cancel_cd = 0,
		},
		[2]=
		{
			id = 2,
			begin_signup_time = 0,
			signup_dur = 0,
			begin_game_condi = 0,
			max_signup_person = 0,
			sign_condi = 0,
			close_time = 0,
			is_cancel_sign = 0,
			cancel_cd = 0,
		},
		[3]=
		{
			id = 3,
			begin_signup_time = 0,
			signup_dur = 0,
			begin_game_condi = 0,
			max_signup_person = 0,
			sign_condi = 0,
			close_time = 0,
			is_cancel_sign = 0,
			cancel_cd = 0,
		},
	},
	match_enter_config=
	{
		[1]=
		{
			id = 1,
			enter_config_id = 1,
			asset_type = "jing_bi",
			asset_count = 0,
			judge_type = 1,
		},
		[2]=
		{
			id = 2,
			enter_config_id = 2,
			asset_type = "jing_bi",
			asset_count = 2000,
			judge_type = 1,
		},
		[3]=
		{
			id = 3,
			enter_config_id = 3,
			asset_type = "jing_bi",
			asset_count = 10000,
			judge_type = 1,
		},
	},
	match_game_config=
	{
		[1]=
		{
			id = 1,
			game_config_id = 1,
			round = 1,
			round_type = 1,
			rise_num = 3,
			rise_score = 0,
			race_count = 1,
			init_rate = 1,
			init_stake = 100,
		},
		[2]=
		{
			id = 2,
			game_config_id = 2,
			round = 1,
			round_type = 1,
			rise_num = 3,
			rise_score = 0,
			race_count = 1,
			init_rate = 1,
			init_stake = 100,
		},
		[3]=
		{
			id = 3,
			game_config_id = 3,
			round = 1,
			round_type = 1,
			rise_num = 3,
			rise_score = 0,
			race_count = 1,
			init_rate = 1,
			init_stake = 100,
		},
	},
	match_award_config=
	{
		[1]=
		{
			id = 1,
			award_config_id = 1,
			rank = "1~1",
			asset_type = "shop_gold_sum",
			asset_count = 100,
		},
		[2]=
		{
			id = 2,
			award_config_id = 1,
			rank = "1~1",
			asset_type = "jing_bi",
			asset_count = 6000,
		},
		[3]=
		{
			id = 3,
			award_config_id = 1,
			rank = "2~2",
			asset_type = "shop_gold_sum",
			asset_count = 100,
		},
		[4]=
		{
			id = 4,
			award_config_id = 1,
			rank = "2~2",
			asset_type = "jing_bi",
			asset_count = 6000,
		},
		[5]=
		{
			id = 5,
			award_config_id = 1,
			rank = "3~3",
			asset_type = "shop_gold_sum",
			asset_count = 100,
		},
		[6]=
		{
			id = 6,
			award_config_id = 1,
			rank = "3~3",
			asset_type = "jing_bi",
			asset_count = 6000,
		},
		[7]=
		{
			id = 7,
			award_config_id = 2,
			rank = "1~1",
			asset_type = "diamond",
			asset_count = 100,
		},
		[8]=
		{
			id = 8,
			award_config_id = 2,
			rank = "1~1",
			asset_type = "shop_gold_sum",
			asset_count = 100,
		},
		[9]=
		{
			id = 9,
			award_config_id = 2,
			rank = "2~2",
			asset_type = "diamond",
			asset_count = 50,
		},
		[10]=
		{
			id = 10,
			award_config_id = 2,
			rank = "2~2",
			asset_type = "shop_gold_sum",
			asset_count = 50,
		},
		[11]=
		{
			id = 11,
			award_config_id = 2,
			rank = "3~3",
			asset_type = "diamond",
			asset_count = 20,
		},
		[12]=
		{
			id = 12,
			award_config_id = 2,
			rank = "3~3",
			asset_type = "shop_gold_sum",
			asset_count = 20,
		},
		[13]=
		{
			id = 13,
			award_config_id = 3,
			rank = "1~1",
			asset_type = "diamond",
			asset_count = 500,
		},
		[14]=
		{
			id = 14,
			award_config_id = 3,
			rank = "1~1",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[15]=
		{
			id = 15,
			award_config_id = 3,
			rank = "2~2",
			asset_type = "diamond",
			asset_count = 200,
		},
		[16]=
		{
			id = 16,
			award_config_id = 3,
			rank = "2~2",
			asset_type = "shop_gold_sum",
			asset_count = 200,
		},
		[17]=
		{
			id = 17,
			award_config_id = 3,
			rank = "3~3",
			asset_type = "diamond",
			asset_count = 100,
		},
		[18]=
		{
			id = 18,
			award_config_id = 3,
			rank = "3~3",
			asset_type = "shop_gold_sum",
			asset_count = 100,
		},
	},
	broadcast=
	{
		[1]=
		{
			id = 1,
			match_id = 2,
			content = "1元公益基金",
		},
		[2]=
		{
			id = 2,
			match_id = 3,
			content = "5元公益基金",
		},
	},
}