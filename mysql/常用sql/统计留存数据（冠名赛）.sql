
-- 留存
select pt._login_time `时间`,count(*) `用户数量`,
	concat(floor((count(per_day1.id)*100)/count(*)) , '%') `次留`,
	concat(floor((count(per_day3.id)*100)/count(*)) , '%') `3留` ,
	concat(floor((count(per_day7.id)*100)/count(*)) , '%') `7留`
from 
(
		SELECT pll.id, min(pll.login_time) _login_time,to_days(min(pll.login_time)) _day
		FROM player_login_log pll 
		inner join player_register pr on pll.id = pr.id  and pr.register_channel='wechat'
		inner join (select distinct player_id from naming_match_players_info) nm on pll.id = nm.player_id
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


-- 清单
select b.match_id, a.name `微信名`,b.player_id `游戏id`,c._login_time `首次登录时间` from player_info a
inner join (select distinct match_id, player_id from naming_match_players_info) b on a.id = b.player_id
left join (
		SELECT pll.id, min(pll.login_time) _login_time,to_days(min(pll.login_time)) _day
		FROM player_login_log pll 
		inner join player_register pr on pll.id = pr.id  and pr.register_channel='wechat'
		inner join (select distinct player_id from naming_match_players_info) nm on pll.id = nm.player_id
		group by pll.id
		
) c on c.id = a.id

-- 登录
select * from player_login_log where id = '101748312'







