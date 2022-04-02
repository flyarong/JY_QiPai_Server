return {
	game_main=
	{
		[1]=
		{
			id = 1,
			game_id = 4,
			game_name = "体验场",
			game_type = "nor_fishing_nor",
			manager_path = "fishing_nor_manager_service/fishing_nor_manager_service",
			enable = 1,
		},
		[2]=
		{
			id = 2,
			game_id = 1,
			game_name = "初级场",
			game_type = "nor_fishing_nor",
			manager_path = "fishing_nor_manager_service/fishing_nor_manager_service",
			enable = 1,
		},
		[3]=
		{
			id = 3,
			game_id = 2,
			game_name = "中级场",
			game_type = "nor_fishing_nor",
			manager_path = "fishing_nor_manager_service/fishing_nor_manager_service",
			enable = 1,
		},
		[4]=
		{
			id = 4,
			game_id = 3,
			game_name = "高级场",
			game_type = "nor_fishing_nor",
			manager_path = "fishing_nor_manager_service/fishing_nor_manager_service",
			enable = 1,
		},
	},
	game_rule=
	{
		[1]=
		{
			id = 1,
			game_id = 4,
			game_level = 1,
			gun_id = {1,2,3,4,5,6,7,8,9,10,},
			gun_rate = {10,20,30,40,50,60,70,80,90,100,},
			enter_cfg_id = 4,
			fish_config = "fish_data_config_4",
		},
		[2]=
		{
			id = 2,
			game_id = 1,
			game_level = 2,
			gun_id = {11,12,13,14,15,16,17,18,19,20,},
			gun_rate = {100,200,300,400,500,600,700,800,900,1000,},
			enter_cfg_id = 1,
			fish_config = "fish_data_config_1",
		},
		[3]=
		{
			id = 3,
			game_id = 2,
			game_level = 3,
			gun_id = {21,22,23,24,25,26,27,28,29,30,},
			gun_rate = {1000,2000,3000,4000,5000,6000,7000,8000,9000,10000,},
			enter_cfg_id = 2,
			fish_config = "fish_data_config_2",
		},
		[4]=
		{
			id = 4,
			game_id = 3,
			game_level = 4,
			gun_id = {31,32,33,34,35,36,37,38,39,40,},
			gun_rate = {10000,20000,30000,40000,50000,60000,70000,80000,90000,100000,},
			enter_cfg_id = 3,
			fish_config = "fish_data_config_3",
		},
	},
	enter_cfg=
	{
		[1]=
		{
			id = 1,
			enter_cfg_id = 4,
			asset_type = "jing_bi",
			asset_count = 0,
			judge_type = 3,
		},
		[2]=
		{
			id = 2,
			enter_cfg_id = 4,
			asset_type = "jing_bi",
			asset_count = 20000,
			judge_type = 4,
		},
		[3]=
		{
			id = 3,
			enter_cfg_id = 1,
			asset_type = "jing_bi",
			asset_count = 1000,
			judge_type = 3,
		},
		[4]=
		{
			id = 4,
			enter_cfg_id = 1,
			asset_type = "jing_bi",
			asset_count = 2000000,
			judge_type = 4,
		},
		[5]=
		{
			id = 5,
			enter_cfg_id = 2,
			asset_type = "jing_bi",
			asset_count = 10000,
			judge_type = 3,
		},
		[6]=
		{
			id = 6,
			enter_cfg_id = 2,
			asset_type = "jing_bi",
			asset_count = 20000000,
			judge_type = 4,
		},
		[7]=
		{
			id = 7,
			enter_cfg_id = 3,
			asset_type = "jing_bi",
			asset_count = 100000,
			judge_type = 3,
		},
	},
}