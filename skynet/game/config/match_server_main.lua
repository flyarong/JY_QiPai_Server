return {
	match_info=
	{
		[1]=
		{
			id = 1,
			match_model = "jbs",
			match_model_path = "city_match_manager_service/city_match_manager_service",
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
			match_model_path = "city_match_manager_service/city_match_manager_service",
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
			match_model_path = "city_match_manager_service/city_match_manager_service",
			matching_path = "normal_match_service/normal_match_service",
			signup_model = "renmanjikai",
			game_type = "nor_ddz_nor",
			enable = 1,
			over_time = 0,
		},
		[4]=
		{
			id = 4,
			match_model = "xsyd",
			match_model_path = "city_match_manager_service/city_match_manager_service",
			matching_path = "normal_match_service/normal_match_service",
			signup_model = "renmanjikai",
			game_type = "nor_ddz_nor",
			enable = 1,
			over_time = 0,
		},
		[5]=
		{
			id = 5,
			match_model = "zy",
			match_model_path = "city_match_manager_service/city_match_manager_service",
			matching_path = "normal_match_service/normal_match_service",
			signup_model = "renmanjikai",
			game_type = "nor_ddz_nor",
			enable = 1,
			over_time = 0,
		},
		[6]=
		{
			id = 6,
			match_model = "zy",
			match_model_path = "city_match_fs_manager_service/city_match_fs_manager_service",
			matching_path = "normal_match_service/normal_match_service",
			signup_model = "dingshikai",
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
			name = "2元红包券赛",
			init_prel_score = 1000,
			init_final_score = 1000,
			final_factor = 10,
			enter_config_id = {1,},
			game_config_name = "match_game_config",
			award_config_id = 1,
			end_type = 1,
			end_value = 99999999,
			close_time = 600,
		},
		[2]=
		{
			id = 2,
			data_config_id = 2,
			name = "10元红包券赛",
			init_prel_score = 1000,
			init_final_score = 1000,
			final_factor = 10,
			enter_config_id = {2,},
			game_config_name = "match_game_config",
			award_config_id = 2,
			end_type = 1,
			end_value = 99999999,
			close_time = 600,
		},
		[3]=
		{
			id = 3,
			data_config_id = 3,
			name = "100元红包券赛",
			init_prel_score = 1000,
			init_final_score = 1000,
			final_factor = 10,
			enter_config_id = {3,},
			game_config_name = "match_game_config",
			award_config_id = 3,
			end_type = 1,
			end_value = 99999999,
			close_time = 600,
		},
		[4]=
		{
			id = 4,
			data_config_id = 4,
			name = "测试赛",
			init_prel_score = 1000,
			init_final_score = 1000,
			final_factor = 10,
			enter_config_id = {4,},
			game_config_name = "match_game_config",
			award_config_id = 4,
			end_type = 1,
			end_value = 99999999,
			close_time = 600,
		},
		[5]=
		{
			id = 5,
			data_config_id = 5,
			name = "鲸鱼杯公益斗地主海选赛",
			init_prel_score = 10000,
			init_final_score = 10000,
			final_factor = 10,
			enter_config_id = {5,},
		},
		[6]=
		{
			id = 6,
			data_config_id = 6,
			name = "鲸鱼杯公益斗地主复赛",
			init_prel_score = 10000,
			init_final_score = 10000,
			final_factor = 10,
			enter_config_id = {6,},
		},
	},
	renmanjikai=
	{
		[1]=
		{
			id = 1,
			begin_signup_time = 0,
			end_signup_time = 2836565234,
			begin_game_condi = 12,
			max_round = -1,
			max_concurrency_game = 10,
			sign_condi = 1,
			close_time = 600,
			is_cancel_sign = 1,
			cancel_cd = 15,
		},
		[2]=
		{
			id = 2,
			begin_signup_time = 0,
			end_signup_time = 2836565234,
			begin_game_condi = 12,
			max_round = -1,
			max_concurrency_game = 10,
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
			begin_game_condi = 6,
			max_round = -1,
			max_concurrency_game = 10,
			sign_condi = 3,
			close_time = 600,
			is_cancel_sign = 1,
			cancel_cd = 15,
		},
		[4]=
		{
			id = 4,
			begin_signup_time = 0,
			end_signup_time = 2836565234,
			begin_game_condi = 3,
			max_round = -1,
			max_concurrency_game = 10,
			sign_condi = 4,
			close_time = 600,
			is_cancel_sign = 1,
			cancel_cd = 15,
		},
		[5]=
		{
			id = 5,
			begin_signup_time = 1537934400,
			end_signup_time = 1538064000,
			begin_game_condi = 3,
			max_round = -1,
			max_concurrency_game = 200,
			sign_condi = 5,
			close_time = 1296000,
			is_cancel_sign = 1,
			cancel_cd = 15,
		},
		[6]=
		{
			id = 6,
			begin_signup_time = 0,
			end_signup_time = 0,
			begin_game_condi = 0,
			max_round = 0,
			max_concurrency_game = 0,
			sign_condi = 0,
			close_time = 1296000,
			is_cancel_sign = 0,
			cancel_cd = 0,
		},
	},
	dingshikai=
	{
		[1]=
		{
			id = 1,
			begin_signup_time = 0,
			signup_dur = 0,
			begin_game_condi = 3,
			max_signup_person = 120,
			sign_condi = 1,
			close_time = 600,
			is_cancel_sign = 1,
			cancel_cd = 15,
		},
		[2]=
		{
			id = 2,
			begin_signup_time = 0,
			signup_dur = 0,
			begin_game_condi = 3,
			max_signup_person = 120,
			sign_condi = 2,
			close_time = 600,
			is_cancel_sign = 1,
			cancel_cd = 15,
		},
		[3]=
		{
			id = 3,
			begin_signup_time = 0,
			signup_dur = 0,
			begin_game_condi = 3,
			max_signup_person = 120,
			sign_condi = 3,
			close_time = 600,
			is_cancel_sign = 1,
			cancel_cd = 15,
		},
		[4]=
		{
			id = 4,
			begin_signup_time = 0,
			signup_dur = 0,
			begin_game_condi = 3,
			max_signup_person = 120,
			sign_condi = 4,
			close_time = 600,
			is_cancel_sign = 1,
			cancel_cd = 15,
		},
		[5]=
		{
			id = 5,
			begin_signup_time = 0,
			signup_dur = 0,
			begin_game_condi = 3,
			max_signup_person = 120,
			sign_condi = 5,
			close_time = 600,
			is_cancel_sign = 1,
			cancel_cd = 15,
		},
		[6]=
		{
			id = 6,
			begin_signup_time = 1538135400,
			signup_dur = 600,
			begin_game_condi = 3,
			max_signup_person = 5000,
			sign_condi = 6,
			close_time = 864000,
			is_cancel_sign = 1,
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
			asset_count = 2000,
			judge_type = 1,
		},
		[2]=
		{
			id = 2,
			enter_config_id = 1,
			asset_type = "jing_bi",
			asset_count = 10000,
			judge_type = 1,
		},
		[3]=
		{
			id = 3,
			enter_config_id = 2,
			asset_type = "jing_bi",
			asset_count = 200000,
			judge_type = 1,
		},
		[4]=
		{
			id = 4,
			enter_config_id = 3,
			asset_type = "jing_bi",
			asset_count = 0,
			judge_type = 1,
		},
		[5]=
		{
			id = 5,
			enter_config_id = 4,
			asset_type = "jing_bi",
			asset_count = 0,
			judge_type = 1,
		},
		[6]=
		{
			id = 6,
			enter_config_id = 5,
			asset_type = "zy_city_match_ticket_hx",
			asset_count = 1,
			judge_type = 1,
		},
		[7]=
		{
			id = 7,
			enter_config_id = 6,
			asset_type = "zy_city_match_ticket_fs",
			asset_count = 1,
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
			round_type = 0,
			rise_num = 15,
			rise_score = 0,
			race_count = 2,
			init_rate = 1,
			init_stake = 300,
		},
		[2]=
		{
			id = 2,
			game_config_id = 1,
			round = 2,
			round_type = 0,
			rise_num = 12,
			rise_score = 0,
			race_count = 1,
			init_rate = 1,
			init_stake = 600,
		},
		[3]=
		{
			id = 3,
			game_config_id = 1,
			round = 3,
			round_type = 0,
			rise_num = 6,
			rise_score = 0,
			race_count = 1,
			init_rate = 1,
			init_stake = 300,
		},
		[4]=
		{
			id = 4,
			game_config_id = 1,
			round = 4,
			round_type = 1,
			rise_num = 3,
			rise_score = 0,
			race_count = 1,
			init_rate = 1,
			init_stake = 600,
		},
		[5]=
		{
			id = 5,
			game_config_id = 1,
			round = 5,
			round_type = 1,
			rise_num = 1,
			rise_score = 0,
			race_count = 1,
			init_rate = 1,
			init_stake = 1200,
		},
		[6]=
		{
			id = 6,
			game_config_id = 2,
			round = 1,
			round_type = 0,
			rise_num = 9,
			rise_score = 0,
			race_count = 1,
			init_rate = 1,
			init_stake = 300,
		},
		[7]=
		{
			id = 7,
			game_config_id = 2,
			round = 2,
			round_type = 0,
			rise_num = 6,
			rise_score = 0,
			race_count = 1,
			init_rate = 1,
			init_stake = 600,
		},
		[8]=
		{
			id = 8,
			game_config_id = 2,
			round = 3,
			round_type = 1,
			rise_num = 3,
			rise_score = 0,
			race_count = 1,
			init_rate = 1,
			init_stake = 300,
		},
		[9]=
		{
			id = 9,
			game_config_id = 2,
			round = 4,
			round_type = 1,
			rise_num = 1,
			rise_score = 0,
			race_count = 1,
			init_rate = 1,
			init_stake = 600,
		},
		[10]=
		{
			id = 10,
			game_config_id = 3,
			round = 1,
			round_type = 1,
			rise_num = 3,
			rise_score = 0,
			race_count = 1,
			init_rate = 1,
			init_stake = 300,
		},
		[11]=
		{
			id = 11,
			game_config_id = 3,
			round = 2,
			round_type = 1,
			rise_num = 1,
			rise_score = 0,
			race_count = 1,
			init_rate = 1,
			init_stake = 600,
		},
		[12]=
		{
			id = 12,
			game_config_id = 4,
			round = 1,
			round_type = 1,
			rise_num = 3,
			rise_score = 0,
			race_count = 1,
			init_rate = 1,
			init_stake = 1000,
		},
		[13]=
		{
			id = 13,
			game_config_id = 5,
			round = 1,
			round_type = 1,
			rise_num = 1,
			rise_score = 0,
			race_count = 2,
			init_rate = 1,
			init_stake = 100,
		},
		[14]=
		{
			id = 14,
			game_config_id = 6,
			round = 1,
			round_type = 0,
			rise_num = 150,
			rise_score = 0,
			race_count = 1,
			init_rate = 1,
			init_stake = 100,
		},
		[15]=
		{
			id = 15,
			game_config_id = 6,
			round = 2,
			round_type = 0,
			rise_num = 141,
			rise_score = 45,
			race_count = 1,
			init_rate = 1,
			init_stake = 150,
		},
		[16]=
		{
			id = 16,
			game_config_id = 6,
			round = 3,
			round_type = 0,
			rise_num = 132,
			rise_score = 80,
			race_count = 1,
			init_rate = 1,
			init_stake = 200,
		},
		[17]=
		{
			id = 17,
			game_config_id = 6,
			round = 4,
			round_type = 0,
			rise_num = 123,
			rise_score = 125,
			race_count = 1,
			init_rate = 1,
			init_stake = 250,
		},
		[18]=
		{
			id = 18,
			game_config_id = 6,
			round = 5,
			round_type = 0,
			rise_num = 114,
			rise_score = 180,
			race_count = 1,
			init_rate = 1,
			init_stake = 300,
		},
		[19]=
		{
			id = 19,
			game_config_id = 6,
			round = 6,
			round_type = 0,
			rise_num = 105,
			rise_score = 245.000000,
			race_count = 1,
			init_rate = 1,
			init_stake = 350,
		},
		[20]=
		{
			id = 20,
			game_config_id = 6,
			round = 7,
			round_type = 0,
			rise_num = 96,
			rise_score = 320,
			race_count = 1,
			init_rate = 1,
			init_stake = 400,
		},
		[21]=
		{
			id = 21,
			game_config_id = 6,
			round = 8,
			round_type = 0,
			rise_num = 87,
			rise_score = 405,
			race_count = 1,
			init_rate = 1,
			init_stake = 450,
		},
		[22]=
		{
			id = 22,
			game_config_id = 6,
			round = 9,
			round_type = 0,
			rise_num = 96,
			rise_score = 500,
			race_count = 1,
			init_rate = 1,
			init_stake = 500,
		},
		[23]=
		{
			id = 23,
			game_config_id = 6,
			round = 10,
			round_type = 0,
			rise_num = 66,
			rise_score = 660,
			race_count = 1,
			init_rate = 1,
			init_stake = 600,
		},
		[24]=
		{
			id = 24,
			game_config_id = 6,
			round = 11,
			round_type = 0,
			rise_num = 45,
			rise_score = 840,
			race_count = 1,
			init_rate = 1,
			init_stake = 700,
		},
		[25]=
		{
			id = 25,
			game_config_id = 6,
			round = 12,
			round_type = 0,
			rise_num = 15,
			rise_score = 1040,
			race_count = 1,
			init_rate = 1,
			init_stake = 800,
		},
		[26]=
		{
			id = 26,
			game_config_id = 6,
			round = 13,
			round_type = 0,
			rise_num = 6,
			rise_score = 1260,
			race_count = 1,
			init_rate = 1,
			init_stake = 900,
		},
		[27]=
		{
			id = 27,
			game_config_id = 6,
			round = 14,
			round_type = 1,
			rise_num = 3,
			rise_score = 0,
			race_count = 1,
			init_rate = 1,
			init_stake = 600,
		},
		[28]=
		{
			id = 28,
			game_config_id = 6,
			round = 15,
			round_type = 1,
			rise_num = 1,
			rise_score = 0,
			race_count = 2,
			init_rate = 1,
			init_stake = 800,
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
			rank = "2~2",
			asset_type = "shop_gold_sum",
			asset_count = 50,
		},
		[3]=
		{
			id = 3,
			award_config_id = 1,
			rank = "3~3",
			asset_type = "shop_gold_sum",
			asset_count = 20,
		},
		[4]=
		{
			id = 4,
			award_config_id = 1,
			rank = "4~9",
			asset_type = "jing_bi",
			asset_count = 2000,
		},
		[5]=
		{
			id = 5,
			award_config_id = 2,
			rank = "1~1",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[6]=
		{
			id = 6,
			award_config_id = 2,
			rank = "2~2",
			asset_type = "shop_gold_sum",
			asset_count = 200,
		},
		[7]=
		{
			id = 7,
			award_config_id = 2,
			rank = "3~3",
			asset_type = "shop_gold_sum",
			asset_count = 100,
		},
		[8]=
		{
			id = 8,
			award_config_id = 2,
			rank = "4~6",
			asset_type = "jing_bi",
			asset_count = 10000,
		},
		[9]=
		{
			id = 9,
			award_config_id = 3,
			rank = "1~1",
			asset_type = "shop_gold_sum",
			asset_count = 5000,
		},
		[10]=
		{
			id = 10,
			award_config_id = 3,
			rank = "2~2",
			asset_type = "shop_gold_sum",
			asset_count = 3000,
		},
		[11]=
		{
			id = 11,
			award_config_id = 3,
			rank = "3~3",
			asset_type = "shop_gold_sum",
			asset_count = 2000,
		},
		[12]=
		{
			id = 12,
			award_config_id = 4,
			rank = "1~1",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[13]=
		{
			id = 13,
			award_config_id = 4,
			rank = "2~2",
			asset_type = "shop_gold_sum",
			asset_count = 5000,
		},
		[14]=
		{
			id = 14,
			award_config_id = 4,
			rank = "3~3",
			asset_type = "shop_gold_sum",
			asset_count = 50000,
		},
		[15]=
		{
			id = 15,
			award_config_id = 5,
			rank = "1~1",
			asset_type = "jing_bi",
			asset_count = 2000,
		},
		[16]=
		{
			id = 16,
			award_config_id = 5,
			rank = "1~1",
			asset_type = "room_card",
			asset_count = 2,
		},
		[17]=
		{
			id = 17,
			award_config_id = 5,
			rank = "1~1",
			asset_type = "zy_city_match_ticket_fs",
			asset_count = 1,
		},
		[18]=
		{
			id = 18,
			award_config_id = 5,
			rank = "2~3",
			asset_type = "jing_bi",
			asset_count = 100,
		},
		[19]=
		{
			id = 19,
			award_config_id = 6,
			rank = "1~1",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[20]=
		{
			id = 20,
			award_config_id = 6,
			rank = "1~1",
			asset_type = "jing_bi",
			asset_count = 300000,
		},
		[21]=
		{
			id = 21,
			award_config_id = 6,
			rank = "1~1",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[22]=
		{
			id = 22,
			award_config_id = 6,
			rank = "2~2",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[23]=
		{
			id = 23,
			award_config_id = 6,
			rank = "2~2",
			asset_type = "jing_bi",
			asset_count = 290000,
		},
		[24]=
		{
			id = 24,
			award_config_id = 6,
			rank = "2~2",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[25]=
		{
			id = 25,
			award_config_id = 6,
			rank = "3~3",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[26]=
		{
			id = 26,
			award_config_id = 6,
			rank = "3~3",
			asset_type = "jing_bi",
			asset_count = 280000,
		},
		[27]=
		{
			id = 27,
			award_config_id = 6,
			rank = "3~3",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[28]=
		{
			id = 28,
			award_config_id = 6,
			rank = "4~4",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[29]=
		{
			id = 29,
			award_config_id = 6,
			rank = "4~4",
			asset_type = "jing_bi",
			asset_count = 270000,
		},
		[30]=
		{
			id = 30,
			award_config_id = 6,
			rank = "4~4",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[31]=
		{
			id = 31,
			award_config_id = 6,
			rank = "5~5",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[32]=
		{
			id = 32,
			award_config_id = 6,
			rank = "5~5",
			asset_type = "jing_bi",
			asset_count = 260000,
		},
		[33]=
		{
			id = 33,
			award_config_id = 6,
			rank = "5~5",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[34]=
		{
			id = 34,
			award_config_id = 6,
			rank = "6~6",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[35]=
		{
			id = 35,
			award_config_id = 6,
			rank = "6~6",
			asset_type = "jing_bi",
			asset_count = 250000,
		},
		[36]=
		{
			id = 36,
			award_config_id = 6,
			rank = "6~6",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[37]=
		{
			id = 37,
			award_config_id = 6,
			rank = "7~7",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[38]=
		{
			id = 38,
			award_config_id = 6,
			rank = "7~7",
			asset_type = "jing_bi",
			asset_count = 240000,
		},
		[39]=
		{
			id = 39,
			award_config_id = 6,
			rank = "7~7",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[40]=
		{
			id = 40,
			award_config_id = 6,
			rank = "8~8",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[41]=
		{
			id = 41,
			award_config_id = 6,
			rank = "8~8",
			asset_type = "jing_bi",
			asset_count = 230000,
		},
		[42]=
		{
			id = 42,
			award_config_id = 6,
			rank = "8~8",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[43]=
		{
			id = 43,
			award_config_id = 6,
			rank = "9~9",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[44]=
		{
			id = 44,
			award_config_id = 6,
			rank = "9~9",
			asset_type = "jing_bi",
			asset_count = 220000,
		},
		[45]=
		{
			id = 45,
			award_config_id = 6,
			rank = "9~9",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[46]=
		{
			id = 46,
			award_config_id = 6,
			rank = "10~10",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[47]=
		{
			id = 47,
			award_config_id = 6,
			rank = "10~10",
			asset_type = "jing_bi",
			asset_count = 210000,
		},
		[48]=
		{
			id = 48,
			award_config_id = 6,
			rank = "10~10",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[49]=
		{
			id = 49,
			award_config_id = 6,
			rank = "11~11",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[50]=
		{
			id = 50,
			award_config_id = 6,
			rank = "11~11",
			asset_type = "jing_bi",
			asset_count = 200000,
		},
		[51]=
		{
			id = 51,
			award_config_id = 6,
			rank = "11~11",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[52]=
		{
			id = 52,
			award_config_id = 6,
			rank = "12~12",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[53]=
		{
			id = 53,
			award_config_id = 6,
			rank = "12~12",
			asset_type = "jing_bi",
			asset_count = 195000,
		},
		[54]=
		{
			id = 54,
			award_config_id = 6,
			rank = "12~12",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[55]=
		{
			id = 55,
			award_config_id = 6,
			rank = "13~13",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[56]=
		{
			id = 56,
			award_config_id = 6,
			rank = "13~13",
			asset_type = "jing_bi",
			asset_count = 190000,
		},
		[57]=
		{
			id = 57,
			award_config_id = 6,
			rank = "13~13",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[58]=
		{
			id = 58,
			award_config_id = 6,
			rank = "14~14",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[59]=
		{
			id = 59,
			award_config_id = 6,
			rank = "14~14",
			asset_type = "jing_bi",
			asset_count = 185000,
		},
		[60]=
		{
			id = 60,
			award_config_id = 6,
			rank = "14~14",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[61]=
		{
			id = 61,
			award_config_id = 6,
			rank = "15~15",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[62]=
		{
			id = 62,
			award_config_id = 6,
			rank = "15~15",
			asset_type = "jing_bi",
			asset_count = 180000,
		},
		[63]=
		{
			id = 63,
			award_config_id = 6,
			rank = "15~15",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[64]=
		{
			id = 64,
			award_config_id = 6,
			rank = "16~16",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[65]=
		{
			id = 65,
			award_config_id = 6,
			rank = "16~16",
			asset_type = "jing_bi",
			asset_count = 175000,
		},
		[66]=
		{
			id = 66,
			award_config_id = 6,
			rank = "16~16",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[67]=
		{
			id = 67,
			award_config_id = 6,
			rank = "17~17",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[68]=
		{
			id = 68,
			award_config_id = 6,
			rank = "17~17",
			asset_type = "jing_bi",
			asset_count = 170000,
		},
		[69]=
		{
			id = 69,
			award_config_id = 6,
			rank = "17~17",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[70]=
		{
			id = 70,
			award_config_id = 6,
			rank = "18~18",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[71]=
		{
			id = 71,
			award_config_id = 6,
			rank = "18~18",
			asset_type = "jing_bi",
			asset_count = 165000,
		},
		[72]=
		{
			id = 72,
			award_config_id = 6,
			rank = "18~18",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[73]=
		{
			id = 73,
			award_config_id = 6,
			rank = "19~19",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[74]=
		{
			id = 74,
			award_config_id = 6,
			rank = "19~19",
			asset_type = "jing_bi",
			asset_count = 160000,
		},
		[75]=
		{
			id = 75,
			award_config_id = 6,
			rank = "19~19",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[76]=
		{
			id = 76,
			award_config_id = 6,
			rank = "20~20",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[77]=
		{
			id = 77,
			award_config_id = 6,
			rank = "20~20",
			asset_type = "jing_bi",
			asset_count = 155000,
		},
		[78]=
		{
			id = 78,
			award_config_id = 6,
			rank = "20~20",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[79]=
		{
			id = 79,
			award_config_id = 6,
			rank = "21~21",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[80]=
		{
			id = 80,
			award_config_id = 6,
			rank = "21~21",
			asset_type = "jing_bi",
			asset_count = 150000,
		},
		[81]=
		{
			id = 81,
			award_config_id = 6,
			rank = "21~21",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[82]=
		{
			id = 82,
			award_config_id = 6,
			rank = "22~22",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[83]=
		{
			id = 83,
			award_config_id = 6,
			rank = "22~22",
			asset_type = "jing_bi",
			asset_count = 145000,
		},
		[84]=
		{
			id = 84,
			award_config_id = 6,
			rank = "22~22",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[85]=
		{
			id = 85,
			award_config_id = 6,
			rank = "23~23",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[86]=
		{
			id = 86,
			award_config_id = 6,
			rank = "23~23",
			asset_type = "jing_bi",
			asset_count = 140000,
		},
		[87]=
		{
			id = 87,
			award_config_id = 6,
			rank = "23~23",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[88]=
		{
			id = 88,
			award_config_id = 6,
			rank = "24~24",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[89]=
		{
			id = 89,
			award_config_id = 6,
			rank = "24~24",
			asset_type = "jing_bi",
			asset_count = 135000,
		},
		[90]=
		{
			id = 90,
			award_config_id = 6,
			rank = "24~24",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[91]=
		{
			id = 91,
			award_config_id = 6,
			rank = "25~25",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[92]=
		{
			id = 92,
			award_config_id = 6,
			rank = "25~25",
			asset_type = "jing_bi",
			asset_count = 130000,
		},
		[93]=
		{
			id = 93,
			award_config_id = 6,
			rank = "25~25",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[94]=
		{
			id = 94,
			award_config_id = 6,
			rank = "26~26",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[95]=
		{
			id = 95,
			award_config_id = 6,
			rank = "26~26",
			asset_type = "jing_bi",
			asset_count = 125000,
		},
		[96]=
		{
			id = 96,
			award_config_id = 6,
			rank = "26~26",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[97]=
		{
			id = 97,
			award_config_id = 6,
			rank = "27~27",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[98]=
		{
			id = 98,
			award_config_id = 6,
			rank = "27~27",
			asset_type = "jing_bi",
			asset_count = 120000,
		},
		[99]=
		{
			id = 99,
			award_config_id = 6,
			rank = "27~27",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[100]=
		{
			id = 100,
			award_config_id = 6,
			rank = "28~28",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[101]=
		{
			id = 101,
			award_config_id = 6,
			rank = "28~28",
			asset_type = "jing_bi",
			asset_count = 115000,
		},
		[102]=
		{
			id = 102,
			award_config_id = 6,
			rank = "28~28",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[103]=
		{
			id = 103,
			award_config_id = 6,
			rank = "29~29",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[104]=
		{
			id = 104,
			award_config_id = 6,
			rank = "29~29",
			asset_type = "jing_bi",
			asset_count = 110000,
		},
		[105]=
		{
			id = 105,
			award_config_id = 6,
			rank = "29~29",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[106]=
		{
			id = 106,
			award_config_id = 6,
			rank = "30~30",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[107]=
		{
			id = 107,
			award_config_id = 6,
			rank = "30~30",
			asset_type = "jing_bi",
			asset_count = 105000,
		},
		[108]=
		{
			id = 108,
			award_config_id = 6,
			rank = "30~30",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[109]=
		{
			id = 109,
			award_config_id = 6,
			rank = "31~31",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[110]=
		{
			id = 110,
			award_config_id = 6,
			rank = "31~31",
			asset_type = "jing_bi",
			asset_count = 100000,
		},
		[111]=
		{
			id = 111,
			award_config_id = 6,
			rank = "31~31",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[112]=
		{
			id = 112,
			award_config_id = 6,
			rank = "32~32",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[113]=
		{
			id = 113,
			award_config_id = 6,
			rank = "32~32",
			asset_type = "jing_bi",
			asset_count = 95000,
		},
		[114]=
		{
			id = 114,
			award_config_id = 6,
			rank = "32~32",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[115]=
		{
			id = 115,
			award_config_id = 6,
			rank = "33~33",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[116]=
		{
			id = 116,
			award_config_id = 6,
			rank = "33~33",
			asset_type = "jing_bi",
			asset_count = 90000,
		},
		[117]=
		{
			id = 117,
			award_config_id = 6,
			rank = "33~33",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[118]=
		{
			id = 118,
			award_config_id = 6,
			rank = "34~34",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[119]=
		{
			id = 119,
			award_config_id = 6,
			rank = "34~34",
			asset_type = "jing_bi",
			asset_count = 85000,
		},
		[120]=
		{
			id = 120,
			award_config_id = 6,
			rank = "34~34",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[121]=
		{
			id = 121,
			award_config_id = 6,
			rank = "35~35",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[122]=
		{
			id = 122,
			award_config_id = 6,
			rank = "35~35",
			asset_type = "jing_bi",
			asset_count = 80000,
		},
		[123]=
		{
			id = 123,
			award_config_id = 6,
			rank = "35~35",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[124]=
		{
			id = 124,
			award_config_id = 6,
			rank = "36~36",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[125]=
		{
			id = 125,
			award_config_id = 6,
			rank = "36~36",
			asset_type = "jing_bi",
			asset_count = 75000,
		},
		[126]=
		{
			id = 126,
			award_config_id = 6,
			rank = "36~36",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[127]=
		{
			id = 127,
			award_config_id = 6,
			rank = "37~37",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[128]=
		{
			id = 128,
			award_config_id = 6,
			rank = "37~37",
			asset_type = "jing_bi",
			asset_count = 70000,
		},
		[129]=
		{
			id = 129,
			award_config_id = 6,
			rank = "37~37",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[130]=
		{
			id = 130,
			award_config_id = 6,
			rank = "38~38",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[131]=
		{
			id = 131,
			award_config_id = 6,
			rank = "38~38",
			asset_type = "jing_bi",
			asset_count = 65000,
		},
		[132]=
		{
			id = 132,
			award_config_id = 6,
			rank = "38~38",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[133]=
		{
			id = 133,
			award_config_id = 6,
			rank = "39~54",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[134]=
		{
			id = 134,
			award_config_id = 6,
			rank = "39~54",
			asset_type = "jing_bi",
			asset_count = 60000,
		},
		[135]=
		{
			id = 135,
			award_config_id = 6,
			rank = "39~54",
			asset_type = "zy_city_match_ticket_js",
			asset_count = 1,
		},
		[136]=
		{
			id = 136,
			award_config_id = 6,
			rank = "55~100",
			asset_type = "shop_gold_sum",
			asset_count = 500,
		},
		[137]=
		{
			id = 137,
			award_config_id = 6,
			rank = "55~100",
			asset_type = "jing_bi",
			asset_count = 60000,
		},
		[138]=
		{
			id = 138,
			award_config_id = 6,
			rank = "101~500",
			asset_type = "shop_gold_sum",
			asset_count = 100,
		},
		[139]=
		{
			id = 139,
			award_config_id = 6,
			rank = "101~500",
			asset_type = "jing_bi",
			asset_count = 30000,
		},
		[140]=
		{
			id = 140,
			award_config_id = 6,
			rank = "501~1000",
			asset_type = "jing_bi",
			asset_count = 20000,
		},
		[141]=
		{
			id = 141,
			award_config_id = 6,
			rank = "1001~5000",
			asset_type = "jing_bi",
			asset_count = 10000,
		},
	},
}