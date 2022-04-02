select max(date) _date,sum(change_value) _sum_value from (
	select a.* from player_asset_log a inner join player_register b on  a.id = b.id where b.register_channel='wechat'
) a where asset_type = 'diamond' and change_type='email_attachment' group by to_days(date);



select b.* from ( 
	-- 赠送 了金币的
	select * from (
		select a.* from player_asset_log a inner join player_register b on  a.id = b.id where b.register_channel='wechat'
	) a where asset_type = 'diamond' and change_type='email_attachment' and to_days(date)=to_days('2018-9-5')
) a
right join 
(
	-- 注册的
	SELECT * FROM
	player_register
	where register_channel='wechat' and to_days(register_time) = to_days('2018-9-5')
) b

on a.id = b.id
where a.id is null;

select * from player_asset_log where id = '10139217';