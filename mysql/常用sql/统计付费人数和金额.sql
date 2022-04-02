
-- 每天
select max(create_time) _time, count(*) _count,sum(money) _money from (
	select player_id,money,create_time from player_pay_order where order_status = 'complete'
	union
	select player_id,money,create_time from player_pay_order_log where order_status = 'complete'
) a group by to_days(create_time) order by _time;


	-- 按支付渠道分组
	select channel_type,sum(money) _money from (
		select player_id,channel_type,money,create_time from player_pay_order where order_status = 'complete'
		union
		select player_id,channel_type,money,create_time from player_pay_order_log where order_status = 'complete'
	) a group by channel_type;

-- 总人数
select count(*) from (
	select DISTINCT(player_id) from (
		select player_id,create_time from player_pay_order where order_status = 'complete'
		union
		select player_id,create_time from player_pay_order_log where order_status = 'complete'
	) a
) b;

-- 总金额
	select sum(money) _money from (
		select player_id,money,create_time from player_pay_order where order_status = 'complete'
		union
		select player_id,money,create_time from player_pay_order_log where order_status = 'complete'
	) a;
	
	-- 金额：按支付渠道分组
	select channel_type,sum(money) _money from (
		select player_id,channel_type,money,create_time from player_pay_order where order_status = 'complete'
		union
		select player_id,channel_type,money,create_time from player_pay_order_log where order_status = 'complete'
	) a group by channel_type;
