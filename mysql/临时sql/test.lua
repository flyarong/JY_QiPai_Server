-- 查询所有子孙
set @user_id = '105801';
set @start_time ='2019-3-1 0:0:0';
set @end_time ='2019-4-1 0:0:0';


select a.offspring_id ,b.`name` `名字`,
-- d.phone_number `电话`,
if(c.is_gjhhr=1,'高级合伙人','推广员') `角色`,
if(f.channel_type='weixin','游戏中-微信',if(f.channel_type='alipay','游戏中-支付宝',if(f.channel_type='wxgzh','微信公众号',if(f.channel_type='appstore','游戏中-苹果商店',null)))) `渠道`,
f.create_time `首次充值时间`,convert(f.money/100,decimal) `首次充值金额`,a.`offspring_num` `层级`,a.offsprint_parent_id `上级` 
from player_offspring a
left join player_info b on a.offspring_id = b.id 
left join sczd_relation_data c on a.offspring_id = c.id 
left join bind_phone_number d on a.offspring_id = d.player_id
inner join player_pay_order_stat e on a.offspring_id = e.player_id and e.first_complete_time>=@start_time and e.first_complete_time <= @end_time
inner join player_pay_order_all f on e.first_order_id = f.order_id


where f.create_time is not null
order by a.`offspring_num`,f.create_time desc;


set @only_one_level = false;

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
	insert into tmp_user_offspring(id,`level`) select a.offspring_id,@tmp_level from sczd_relation_data a 
		where a.parent_id = @user_id;
		
		
	select is_tgy,is_gjhhr into @is_tgy,@is_gjhhr from sczd_relation_data where id=@user_id;

	if not @only_one_level then -- and @is_gjhhr=1 then
		-- 逐级循环，直到没有
		while row_count() > 0 do

			set @tmp_level = @tmp_level + 1;
			insert into tmp_user_offspring(id,`level`) 
			select a.offspring_id,@tmp_level from sczd_relation_data a
			inner join tmp_user_offspring c on a.parent_id = c.id -- 上级 在 tmp_user_offspring 中
			left join tmp_user_offspring d on a.offspring_id = d.id         -- 自己不能在  tmp_user_offspring 中
			where d.id is null;

		end while;
	end if;

	select a.offspring_id ,b.`name` `名字`,
		-- d.phone_number `电话`,
		if(c.is_gjhhr=1,'高级合伙人','推广员') `角色`,
		if(f.channel_type='weixin','游戏中-微信',if(f.channel_type='alipay','游戏中-支付宝',if(f.channel_type='wxgzh','微信公众号',if(f.channel_type='appstore','游戏中-苹果商店',null)))) `渠道`,
		f.create_time `首次充值时间`,convert(f.money/100,decimal) `首次充值金额`,a.`level` `层级`,c.parent_id `上级` 
		from tmp_user_offspring a
    left join player_info b on a.offspring_id = b.id 
    left join sczd_relation_data c on a.offspring_id = c.id 
		left join bind_phone_number d on a.offspring_id = d.player_id
		inner join player_pay_order_stat e on a.offspring_id = e.player_id and e.first_complete_time>=@start_time and e.first_complete_time <= @end_time
		inner join player_pay_order_all f on e.first_order_id = f.order_id
	
	
		where f.create_time is not null
		order by a.`level`,f.create_time desc;


END;;

delimiter ;

call temp_cha_xun_proc_offspring();

-- DROP TABLE IF EXISTS tmp_user_offspring;
DROP PROCEDURE IF EXISTS temp_cha_xun_proc_offspring;