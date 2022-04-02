SELECT
player_prop.prop_type,
sum(player_prop.prop_count)
FROM
player_register
INNER JOIN player_prop ON player_prop.id = player_register.id
WHERE
player_register.register_channel = 'wechat'
GROUP BY
player_prop.prop_type
