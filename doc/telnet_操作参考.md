
*** 操作前奏：在xshell 中输入命令 telnet 127.0.0.1 端口号        连接telnet控制台

端口号为服务器启动配置中的center.lua中的  admin_console_port  配置项


*********************************************************************** 道具发放 ***********************************************************************
道理类型表：
	diamond                砖石
	jing_bi                鲸币
	cash                   现金券
	shop_gold_sum          红包劵
	room_card              房卡
	jipaiqi                记牌器
	prop_jicha_cash        生财之道的级差现金
	prop_1                 竞标赛门票
	prop_2                 千元赛门票
	
--------------- 发锤子; 参数:玩家id,道具名称,数量
give "105585","prop_hammer_1",100
give "105585","prop_hammer_2",100
give "105585","prop_hammer_3",100
give "105585","prop_hammer_4",100


-------------- 发鲸币
give "107317","jing_bi",10000


*********************************************************************** 生财之道相关 ***********************************************************************
------ 建立一个绑定关系；参数:玩家id，上级id，操作者
call sczd_center_service change_player_relation "106245","105528","wss"


------ 解除一个玩家的上级绑定；参数:玩家id，上级id，操作者
call sczd_center_service change_player_relation "105510","null","wss"

------ 步步生财 打开七天权限，可以一直往下做任务
call task_center_service open_bbsc_day_permit "105549",7


*********************************************************************** 重载配置或lua文件 ***********************************************************************
------- 重加载配置 ; 用来重加载 nodefunc.query_global_config()  方式载入的配置
call reload_center reload_config "zajindan_service"


------- 重载lua文件 ; 用来重加载 base.import() 加载的lua文件
call reload_center reload_lua "game/services/sczd_center_service/sczd_config.lua"


*********************************************************************** 打印玩家调试信息 ***********************************************************************
------- 打印一个服务的DATA数据，可以是player_agent
call debug_console_service get_service_debug_data "105528","DATA"

------- 打印一个服务的DATA数据，也可以说中心服务
call debug_console_service get_service_debug_data "sczd_center_service","DATA"

------- 获得玩家的游戏信息
call debug_console_service get_player_debug_game_info "102332567"

------- 强制踢掉一个房间的某一桌
call debug_console_service force_break_room_table "freestyle_service_2_room_1",10

------- 获取一个比赛场里面正在游戏中的玩家
call debug_console_service get_match_gaming_id "match_service_2_manager_467"


*********************************************************************** 设置center的配置 ***********************************************************************
----- 设置幸运号,
setcfg lucky_id_num 2            -- 幸运号个数
setcfg lucky_id_1 105433         -- 1号幸运号
setcfg lucky_id_2 105434         -- 2号幸运号



*********************************************************************** 发送广播通知***********************************************************************

-- 字很大的广播
call broadcast_center_service broadcast 1,{type=2,format_type=1,content="hello abcd123456"}

-- 普通的广播
call broadcast_center_service broadcast 1,{type=1,format_type=1,content="hello abcd123456"}


*********************************************************************** 请求托管进入游戏***********************************************************************

-- game_id=86 游戏的id
-- match_service_86 游戏的报名点服务 （这里表示的是冠名赛86号的比赛报名点）
call tuoguan_service assign_tuoguan_player 5,{game_id=86,game_type="nor_ddz_nor",service_id="match_service_86",match_name = "match_game"}



*********************************************************************** 设置礼包的数量***********************************************************************

-- 参数为 礼包id 数量 （这里是设置数量到多少，不是增加多少）
call pay_service update_gift_bag_data 12,1000





*********************************************************************** 设置提现配置参数***********************************************************************
参数
	1.个人单次 额度 限制
	2.每天 个人 额度限制
	3.每天 个人 次数限制
	4.每天 所有人总额 限制
	nil 代表不改变

-- 普通提现
call asset_service set_withdraw_cash_cfg nil,nil,nil,nil

-- 高级合伙人提现
call asset_service set_withdraw_cash_gjhhr_cfg nil,nil,nil,nil



*********************************************************************** 设置匹配场匹配参数***********************************************************************

-- 设置 游戏id 18 的 匹配场的托管请求间隔为 1秒
setcfg freestyle_game_tuoguan_update_interval_18 1

-- 设置 游戏id 18 的 匹配场的托管请求间隔随机浮动为 正负1秒
setcfg tuoguan_update_interval_random_18 1

-- 设置 游戏id 17 的 匹配场的玩家自由匹配最少人数 为 10 人
setcfg tuoguan_freestyle_game_free_match_player_min_num_17 10



