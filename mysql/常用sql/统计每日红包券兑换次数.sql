
select * from player_prop_log where change_type = 'shoping' and change_value > 0;
select * from player_prop_log where change_id = 'SW201809060000030';
select * from player_prop_log where id = '1014751';

select max(a.date) _date,count(a.change_value) _count from 
	player_prop_log a inner join player_register b on a.id = b.id
where b.register_channel='wechat' and a.change_type = 'shoping' and a.change_value < 0
group by to_days(a.date);


select 10000 * 4 - 100 * 50