
-- 留存
select date_format(pt._login_time,'%Y-%m-%d') `日期`,count(*) `登录数量`,
	concat(floor((count(per_day1.id)*100)/count(*)) , '%') `次日留存`,
	concat(floor((count(per_day3.id)*100)/count(*)) , '%') `3日留存` ,
	concat(floor((count(per_day7.id)*100)/count(*)) , '%') `7日留存`
from 
(
		SELECT pll.id, min(pll.login_time) _login_time,to_days(min(pll.login_time)) _day
		FROM player_login_log pll 
		inner join player_register pr on pll.id = pr.id  and pr.register_channel='wechat'
		group by pll.id
		
) pt left join (

	select id,login_time,to_days(login_time) _day from player_login_log group by id,to_days(login_time)
	
)	per_day1 on pt.id = per_day1.id and per_day1._day = pt._day + 1

left join (

	select id,login_time,to_days(login_time) _day from player_login_log group by id,to_days(login_time)
	
)	per_day3 on pt.id = per_day3.id and per_day3._day = pt._day + 2

left join (

	select id,login_time,to_days(login_time) _day from player_login_log group by id,to_days(login_time)
	
)	per_day7 on pt.id = per_day7.id and per_day7._day = pt._day + 6

group by pt._day
