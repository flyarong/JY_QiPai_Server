local skynet = require "skynet"

local service_type={
	["system_service"]={
		resource=0 -- by lyx : 系统服务，不纳入资源管理
	},
	["node_test_service/node_test_service"]={	-- 服务器 多节点测试用 服务
		resource=1
	},
	["player_agent/player_agent"]={
		resource=1,
		node_name= skynet.getenv("plyer_agent_node") or "game",
	},
	["test_agent"]={
		resource=1
	},
	["ddz_test_agent"]={
		resource=1
	},
	["ddz_freestyle_room_service/ddz_freestyle_room_service"]={
		resource=1
	},
	["ddz_freestyle_service/ddz_freestyle_service"]={
		resource=1
	},
	["lzddz_freestyle_room_service/lzddz_freestyle_room_service"]={
		resource=1
	},
	["lzddz_freestyle_service/lzddz_freestyle_service"]={
		resource=1
	},
	["ddz_million_service/ddz_million_service"]={
		resource=1
	},
	["ddz_million_room_service/ddz_million_room_service"]={
		resource=1
	},
	["ddz_million_service/ddz_million_service"]={
		resource=1
	},
	["majiang_freestyle_room_service/majiang_freestyle_room_service"]={
		resource=1
	},
	["majiang_freestyle_service/majiang_freestyle_service"]={
		resource=1
	},
	["normal_mjxl_freestyle_room_service/normal_mjxl_freestyle_room_service"]={
		resource=1
	},
	["normal_mjxl_freestyle_service/normal_mjxl_freestyle_service"]={
		resource=1
	},
	["tyddz_freestyle_room_service/tyddz_freestyle_room_service"]={
		resource=1
	},
	["tyddz_freestyle_service/tyddz_freestyle_service"]={
		resource=1
	},
	["ddz_match_xsyd_manager_service/ddz_match_xsyd_manager_service"]={
		resource=1
	},
	["pay_service/pay_service"]={
		resource=1
	},
	["friendgame_service/friendgame_service"]={
		resource=1
	},
	["friendgame_service/friendgame_service"]={
		resource=1
	},
	["common_mj_xzdd_room_service/common_mj_xzdd_room_service"]={
		resource=1
	},
	["common_ddz_nor_room_service/common_ddz_nor_room_service"]={
		resource=1
	},
	["common_gobang_nor_room_service/common_gobang_nor_room_service"]={
		resource=1
	},
	["normal_match_service/normal_match_service"]={
		resource=1
	},
	["match_center_service/match_center_service"]={
		resource=1
	},

	["city_match_manager_service/city_match_manager_service"]={
		resource=1
	},

	["city_match_fs_manager_service/city_match_fs_manager_service"]={
		resource=1
	},


	["naming_match_manager_service/naming_match_manager_service"]={
		resource=1
	},

	
	["normal_match_manager_service/normal_match_manager_service"]={
		resource=1
	},
	["freestyle_nor_manager_service/freestyle_nor_manager_service"]={
		resource=1
	},
	["zajindan_room_service/zajindan_room_service"]={
		resource=1
	},
	["xiaoxiaole_room_service/xiaoxiaole_room_service"]={
		resource=1
	},
	["tuoguan_service/tuoguan_agent"]={
		resource=1,
		node_name= skynet.getenv("tuoguan_test_node") or "tg",
	},

	["freestyle_activity_lian_sheng_service/freestyle_activity_lian_sheng_service"]={
		resource=1
	},

	["freestyle_activity_lei_sheng_service/freestyle_activity_lei_sheng_service"]={
		resource=1
	},

	["freestyle_activity_free_activity_tian_jiang_cai_shen_service/freestyle_activity_free_activity_tian_jiang_cai_shen_service"]={
		resource=1
	},

	["common_fishing_nor_room_service/common_fishing_nor_room_service"]={
		resource=1
	},

	["fishing_nor_manager_service/fishing_nor_manager_service"]={
		resource=1
	},

}
return service_type