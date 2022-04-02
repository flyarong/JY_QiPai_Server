set @start_time = '2018-12-14 0:0:0';
 
	select a.id ,b.`name` `名字`,d.phone_number `电话`,
		if(e.game_partner_level='GamePartner','合伙人',if(e.game_partner_level='GamePartnerSenior','高级合伙人',if(e.game_partner_level='GamePartnerInternship','实习合伙人','普通玩家'))) `角色`,
		if(f.channel_type='weixin','游戏中-微信',if(f.channel_type='alipay','游戏中-支付宝',if(f.channel_type='wxgzh','微信公众号',if(f.channel_type='appstore','游戏中-苹果商店',null)))) `渠道`,
		f.create_time `购买时间`,c.parent_id `上级` 
		from (
				select distinct(player_id) id from  (select * from player_pay_order where order_status='complete' union all select * from player_pay_order_log where order_status='complete') a
			) a
    left join player_info b on a.id = b.id 
    left join club_info c on a.id = c.id 
		left join bind_phone_number d on a.id = d.player_id
		left join webdb_trans.jyh_user e on a.id = e.id
		left join (select player_id,channel_type,min(create_time) create_time from 
			(select * from player_pay_order where order_status='complete' union all select * from player_pay_order_log where order_status='complete') a
			where product_id='8' and create_time >= @start_time group by player_id) f on a.id = f.player_id
			where f.create_time is not null
    order by f.create_time;

