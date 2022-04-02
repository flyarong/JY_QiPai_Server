-- 查询所有子孙
set @user_id = '105801';

DROP PROCEDURE IF EXISTS temp_cha_xun_proc_offspring;

delimiter ;;
CREATE DEFINER=CURRENT_USER PROCEDURE temp_cha_xun_proc_offspring()
    SQL SECURITY INVOKER
BEGIN


	DROP TABLE IF EXISTS tmp_user_offspring; 
	CREATE TABLE tmp_user_offspring  (
      order_id bigint NOT NULL AUTO_INCREMENT,
	  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
      `level` int NOT NULL,
	  PRIMARY KEY (`order_id`)
	);
    
	set @tmp_level = 1;
	
	-- 自己
	insert into tmp_user_offspring(id,`level`) values(@user_id,0);
		
	-- 第一级 孩子
	insert into tmp_user_offspring(id,`level`) select a.id,@tmp_level from club_info a 
		left join webdb_trans.jyh_user b on a.id = b.id 
		where a.parent_id = @user_id and (b.game_partner_level != 'GamePartnerSenior' or b.game_partner_level is null);
		
		
	select game_partner_level into @my_level from webdb_trans.jyh_user where id=@user_id;

	if @my_level='GamePartnerSenior' then
		-- 逐级循环，直到没有
		while row_count() > 0 do

			set @tmp_level = @tmp_level + 1;
			insert into tmp_user_offspring(id,`level`) 
			select a.id,@tmp_level from club_info a
			left join webdb_trans.jyh_user b on a.id = b.id
			inner join tmp_user_offspring c on a.parent_id = c.id -- 上级 在 tmp_user_offspring 中
			left join tmp_user_offspring d on a.id = d.id         -- 自己不能在  tmp_user_offspring 中
			where 
				(b.game_partner_level != 'GamePartnerSenior' or b.game_partner_level is null) and 
				d.id is null;

		end while;
	end if;

	select a.id ID,b.`name` `昵称`,
		c.parent_id `上级ID` ,h.`name` `上级昵称`,
		-- d.phone_number `电话`,
		g.login_time `首次登录时间`,
		f.create_time `首次充值时间`,
		f.count `充值次数`,
		if(e.game_partner_level='GamePartner','合伙人',(if(e.game_partner_level='GamePartnerSenior','高级合伙人',if(e.game_partner_level='GamePartnerInternship','实习合伙人','普通玩家')))) `角色`,
		i.shangjia `是否商家`,
		-- if(f.channel_type='weixin','游戏中-微信',if(f.channel_type='alipay','游戏中-支付宝',if(f.channel_type='wxgzh','微信公众号',if(f.channel_type='appstore','游戏中-苹果商店',null)))) `渠道`,
		a.`level` `层级`
		
		from tmp_user_offspring a
    left join player_info b on a.id = b.id 
    left join club_info c on a.id = c.id 
		left join bind_phone_number d on a.id = d.player_id
		left join webdb_trans.jyh_user e on a.id = e.id
		left join (
			select player_id,channel_type,min(create_time) create_time,count(*) count from player_pay_order_all where order_status='complete' group by player_id
			) f on a.id = f.player_id
		left join ( 
				select a.id,min(a.login_time) login_time from player_login_log a inner join player_verify b on a.id=b.id and b.channel_type='wechat'  group by a.id
		  ) g on a.id = g.id
		left join player_info h on c.parent_id = h.id
		left join (select id,'商家' shangjia from  webdb_trans.jyh_user where roles_status like '%"Merchant": "Enabled"%') i on a.id = i.id
		
		
		-- where f.create_time is not null
    -- order by f.create_time;
		order by a.`level`;


END;;

delimiter ;

call temp_cha_xun_proc_offspring();

-- DROP TABLE IF EXISTS tmp_user_offspring;
DROP PROCEDURE IF EXISTS temp_cha_xun_proc_offspring;