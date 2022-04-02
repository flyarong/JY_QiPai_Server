select a.id `玩家ID`,a.`name` `昵称`,b.parent_id `上级ID`,c.login_time `首次登录`,
d.create_time `首次充值`,e.count `充值次数` ,f.count `竞标赛场数`,g.count `自由场局数`,
h.count `房卡场次数`
from (select id,`name` from player_info where id in (
'1020356',
'10100836',
'1076813',
'10125017',
'1086530',
'10125691',
'10111287',
'1016865',
'1061680'
)) a

left join sczd_relation_data b on a.id = b.id
left join player_first_login c on a.id = c.id
left join player_first_pay d on a.id = d.player_id
left join (select player_id,count(*) count from player_pay_order_all where order_status = 'complete' group by player_id) e on a.id = e.player_id
left join (select player_id,count(*) count from match_nor_player_log group by player_id) f on a.id = f.player_id
left join (select player_id,count(*) count from freestyle_race_player_log group by player_id) g on a.id = g.player_id
left join (select player_id,count(*) count from player_friendgame_record group by player_id) h on a.id = h.player_id 

