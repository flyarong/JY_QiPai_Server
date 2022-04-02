SELECT
to_days(player_login_log.login_time)-to_days('2018-9-5') _to_days,
max(player_login_log.login_time) _time,
count(*) _count
FROM
player_login_log
INNER JOIN player_register ON player_login_log.id = player_register.id
WHERE
player_register.register_channel = 'wechat'

GROUP BY _to_days
