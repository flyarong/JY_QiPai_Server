SELECT
to_days(player_register.register_time)-TO_DAYS('2018-9-5') day_diff,
max(player_register.register_time) _time,
count(*) _count
FROM
player_register
where register_channel='wechat'
GROUP BY day_diff;


