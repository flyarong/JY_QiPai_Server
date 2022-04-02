select order_id,player_id,create_time,order_status,error_desc from player_pay_order where product_id = '8' and
player_id in( 
'102384766',
'102384457'
);

select order_id,player_id,product_desc,create_time,order_status,error_desc,a.* from player_pay_order a where player_id in( 
'102385228'
);

select * from player_info where name like '%耗%' 
select * from club_info where id = '102377389'
select * from player_register where id = '102377389'
select * from player_login_log where id = '102377389'

-- 查 n 小时前所有
select order_id `订单号`,player_id `玩家id`,product_desc `商品`,create_time `时间`,order_status `状态`,error_desc `错误描述` from player_pay_order 
where date_add(create_time, interval 30 hour) >= now() and order_status <> 'complete'
order by create_time

-- 超时 且手工完成了的
select a.create_time,a.end_time,order_id,order_status,a.* from player_pay_order_log a 
where order_status = 'complete' and to_days(create_time) = to_days('2018-12-9') order by TIMESTAMPDIFF(minute,create_time,end_time) desc limit 100;

-- 手工完成了的
select a.create_time,a.end_time,order_id,order_status,TIMESTAMPDIFF(minute,create_time,end_time) diff,a.* from player_pay_order_log a 
where channel_account_id like 'shougong_chuli%' and to_days(create_time) = to_days('2018-12-9') order by create_time desc limit 100;

-- 今天未到账的
select a.create_time,a.end_time,order_id,order_status,a.channel_type,a.* from player_pay_order a where create_time > '2018-12-11' and order_status <> 'complete' order by create_time


-- 查今天 礼包
select order_id,player_id,product_desc,create_time,order_status,error_desc from player_pay_order 
where to_days(create_time) = to_days(now()) and product_id = '8' and order_status <> 'complete'
order by order_status, create_time

-- 查 12-4 以来所有
select order_id `订单号`,player_id `玩家id`,product_desc `商品`,create_time `时间`,order_status `状态`,error_desc `错误描述` from player_pay_order 
where create_time > '2018-12-04 0:0:0' and order_status <> 'complete'
order by create_time