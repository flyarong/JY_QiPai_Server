-- 次日留存
select pt._login_time,count(*) _login_total,
	concat(floor((count(per_day1.id)*100)/count(*)) , '%') _day1_per,
	concat(floor((count(per_day3.id)*100)/count(*)) , '%') _day3_per ,
	concat(floor((count(per_day7.id)*100)/count(*)) , '%') _day7_per
from 
(
		SELECT pll.id, min(pll.login_time) _login_time,to_days(min(pll.login_time)) _day
		FROM player_login_log pll 
		inner join player_register pr on pll.id = pr.id  and pr.register_channel='wechat'
		group by pll.id
		
) pt left join (

	select id,login_time,to_days(login_time) _day from player_login_log group by id,to_days(login_time)
	
)	per_day1 on pt.id = per_day1.id and per_day1._day = pt._day + 1