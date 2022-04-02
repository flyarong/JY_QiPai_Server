
select max(a.date) _date,sum(a.change_value) _sum_value from 
	player_prop_log a inner join player_register b on a.id = b.id
where b.register_channel='wechat' and prop_type='room_card' and change_value < 0
group by to_days(a.date)
