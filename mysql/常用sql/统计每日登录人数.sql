-- 去重
select _days,max(_time) _time,count(*) _count from
(select id,to_days(login_time) _days ,max(login_time) _time from 
	(select player_login_log.* from player_login_log inner join player_register on player_login_log.id = player_register.id where player_register.register_channel='wechat' ) b
    group by id,to_days(login_time)) a
group by _days;

