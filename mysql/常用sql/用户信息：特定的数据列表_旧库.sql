select 
a.id,
a.register_time,
to_days(now())-to_days(a.register_time) reg_days,
 b._count login_count,
 c._count match_count,
 d._count free_count,
 e._count friend_count,
 f.money pay

from player_register a 
left join (select id,count(*) _count from player_login_log group by id ) b on a.id = b.id
left join (select player_id,count(*) _count from match_ddz_player_log group by player_id ) c on a.id = c.player_id
left join (select player_id,count(*) _count from (
	select * from freestyle_ddz_race_player_log
	union all
	select * from `freestyle_majiang_race_player_log`) a group by player_id ) d on a.id = d.player_id
left join (select player_id,count(*) _count from (
		select p1_id player_id from friendgame_history_record
		union all
		select p2_id player_id from friendgame_history_record
		union all
		select p3_id player_id from friendgame_history_record
		union all
		select p3_id player_id from friendgame_history_record
) a group by player_id ) e on a.id = e.player_id
left join (
	select player_id,sum(money) money from (
	select player_id,money from player_pay_order where order_status='complete' 
	union all 
	select player_id,money from player_pay_order_log where order_status='complete' 
) a group by player_id) f on a.id = f.player_id

where a.id in (
'101004481',
'10104265',
'10104338',
'101280669',
'101379096',
'101425721',
'101433731',
'10155180',
'101597756',
'1016865',
'101690747',
'101692294',
'101698639',
'101701779',
'101702512',
'10171215',
'101715623',
'101726796',
'1017875',
'101816720',
'10182232',
'101833658',
'101868259',
'1018816',
'101911620',
'1019250',
'1019261',
'1019500',
'101959592',
'101973061',
'10198556',
'1020282',
'1020356',
'102037739',
'102051910',
'102067739',
'102069503',
'102069869',
'102069953',
'102069986',
'102070596',
'102074157',
'102077092',
'10207994',
'102089130',
'102089765',
'102112039',
'102127000',
'102127248',
'10212760',
'102130157',
'102133166',
'102135794',
'102137113',
'1024412',
'10259751',
'1027071',
'10276108',
'10301038',
'1030871',
'10319189',
'1033249',
'1033543',
'1033951',
'1036347',
'10379434',
'1041114',
'1044281',
'1044780',
'1045627',
'1054409',
'1057390',
'1060183',
'10679181',
'1070332',
'10718441',
'1076418',
'10782885',
'1078568',
'1082645',
'1083589',
'108629',
'10921147',
'109221' 
 )







