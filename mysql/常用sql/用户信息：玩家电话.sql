SELECT
pi.id,
pi.`name`,
pi.sex,
bpn.phone_number,
bpn.bind_time
FROM
bind_phone_number AS bpn
LEFT JOIN player_info AS pi ON bpn.player_id = pi.id
INNER JOIN player_register AS pr ON pr.id = pi.id
WHERE pr.register_channel = 'wechat' 
