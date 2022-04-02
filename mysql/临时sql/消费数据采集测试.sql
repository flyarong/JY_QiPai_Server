set @last_asset_log_seq = 38323;
set @start_seq = 100;

SELECT
ppl.change_id AS consumptionId,
ppl.prop_type AS currency,
ppl.change_type as type,
ppl.change_value,
ppl.id AS userId,
ci.parent_ids AS parentUserIds,
ppl.sync_seq AS collectSeq,
ppl.date AS time
FROM
(
	SELECT a.change_id,a.prop_type,a.change_type,a.change_value,a.id,a.shop_gold_sync_seq sync_seq,a.`date`
	FROM player_prop_log AS a
	LEFT JOIN player_asset_refund AS b ON b.log_id = a.log_id
	LEFT JOIN player_asset_refund AS c ON c.log_id_refund = a.log_id
	where b.log_id is null and c.log_id_refund is null and shop_gold_sync_seq > @start_seq and shop_gold_sync_seq <= @last_asset_log_seq
		UNION
	SELECT a.change_id,a.asset_type prop_type,a.change_type,a.change_value,a.id,a.sync_seq,a.`date`
	FROM player_asset_log AS a
	LEFT JOIN player_asset_refund AS b ON b.log_id = a.log_id
	LEFT JOIN player_asset_refund AS c ON c.log_id_refund = a.log_id
	where b.log_id is null and c.log_id_refund is null and a.sync_seq > @start_seq and a.sync_seq <= @last_asset_log_seq
	
) AS ppl
LEFT JOIN club_info AS ci ON ci.id = ppl.id
INNER JOIN (select * from player_register where register_channel = 'wechat' ) AS pr ON pr.id = ppl.id 
-- where ppl.change_type like '%signup' -- and ppl.change_value > 0
order by ppl.sync_seq;