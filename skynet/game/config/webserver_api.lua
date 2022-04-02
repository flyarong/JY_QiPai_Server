
-- web 接口定义

return

	{
		-- 支付
		["/pay/get_goods_list"] = {type="lua",postfix=".lua"},
		["/pay/create_order"] = {type="lua",postfix=".lua"},
		["/pay/query_order"] = {type="lua",postfix=".lua"},
		["/pay/modify_order_status"] = {type="lua",postfix=".lua"},

		-- 商城购物：通过 购物金 线下消费
		["/shop/debug_create_token"] = {type="lua",postfix=".lua"},
		["/shop/get_user_by_id"] = {type="lua",postfix=".lua"},
		["/shop/get_user_by_token"] = {type="lua",postfix=".lua"},
		["/shop/shoping_gold_pay"] = {type="lua",postfix=".lua"},
		["/shop/shoping_gold_refund"] = {type="lua",postfix=".lua"},
		["/shop/reserve_shoping_gold_refund"] = {type="lua",postfix=".lua"},

		-- 提现
		["/withdraw/debug_create_withdraw_id"] = {type="lua",postfix=".lua"},
		["/withdraw/create_withdraw_id"] = {type="lua",postfix=".lua"},
		["/withdraw/query_status"] = {type="lua",postfix=".lua"},
		["/withdraw/change_status"] = {type="lua",postfix=".lua"},

		-- 提现 v2
		["/withdraw2/create_withdraw_id"] = {type="lua",postfix=".lua"},
		["/withdraw2/query_status"] = {type="lua",postfix=".lua"},
		["/withdraw2/change_status"] = {type="lua",postfix=".lua"},
		["/withdraw2/withdraw_gjhhr"] = {type="lua",postfix=".lua"},

		--邮件
		["/email/send_email"] = {type="lua",postfix=".lua"},

		--广播刷新
		["/broadcast/refresh_config"] = {type="lua",postfix=".lua"},

		--web 后台 hermos 的 api 
		["/hermos/wechat_create_user"] = {type="lua",postfix=".lua"},
		["/hermos/collect_user_after_seq"] = {type="lua",postfix=".lua"},
		["/hermos/collect_consumption_after_seq"] = {type="lua",postfix=".lua"},
		["/hermos/merchant_gold_pay"] = {type="lua",postfix=".lua"},
		["/hermos/update_agent_role"] = {type="lua",postfix=".lua"},
		["/hermos/query_one_user"] = {type="lua",postfix=".lua"},
		["/hermos/query_user_detail_info"] = {type="lua",postfix=".lua"},
		["/hermos/query_pay_order"] = {type="lua",postfix=".lua"},
		["/hermos/query_pay_order_list"] = {type="lua",postfix=".lua"},
		["/hermos/query_undone_payment_order"] = {type="lua",postfix=".lua"},
		["/hermos/query_pay_order_detail"] = {type="lua",postfix=".lua"},
		["/hermos/query_user_give_award_info"] = {type="lua",postfix=".lua"},
		["/hermos/query_user_assets"] = {type="lua",postfix=".lua"},
		["/hermos/query_block_list"] = {type="lua",postfix=".lua"},
		["/hermos/query_player_consume"] = {type="lua",postfix=".lua"},
		["/hermos/decrease_player_asset"] = {type="lua",postfix=".lua"},
		["/hermos/decrease_player_ticket"] = {type="lua",postfix=".lua"},
		["/hermos/update_bind_phone_number"] = {type="lua",postfix=".lua"},

		-- 后台管理 api
		["/admin/modify_user"] = {type="lua",postfix=".lua"},
		["/admin/kick"] = {type="lua",postfix=".lua"},
		["/admin/clean_user_cache"] = {type="lua",postfix=".lua"},
		["/admin/server_status"] = {type="lua",postfix=".lua"},
		["/admin/shutdown"] = {type="lua",postfix=".lua"},
		["/admin/reload_config"] = {type="lua",postfix=".lua"},
		["/admin/set_login_switch"] = {type="lua",postfix=".lua"},
		["/admin/get_login_switch"] = {type="lua",postfix=".lua"},
		["/admin/set_payment_switch"] = {type="lua",postfix=".lua"},
		["/admin/get_payment_switch"] = {type="lua",postfix=".lua"},
		
		-- 推广系统
		["/sczd/wechat_create_player"] = {type="lua",postfix=".lua"},
		["/sczd/get_gjhhr_achievements_data"] = {type="lua",postfix=".lua"},
		["/sczd/set_new_gjhhr_msg"] = {type="lua",postfix=".lua"},
		["/sczd/verify_gjhhr_info"] = {type="lua",postfix=".lua"},
		["/sczd/delete_gjhhr_msg"] = {type="lua",postfix=".lua"},
		["/sczd/change_player_relation"] = {type="lua",postfix=".lua"},
	}
