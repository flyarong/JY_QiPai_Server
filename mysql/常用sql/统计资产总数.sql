SELECT
sum(player_asset.diamond) diamond,
sum(player_asset.jing_bi) jing_bi,
sum(player_asset.cash) cash,
player_register.id,
player_register.register_channel
FROM
player_asset
INNER JOIN player_register ON player_asset.id = player_register.id
WHERE
player_register.register_channel = 'wechat'
