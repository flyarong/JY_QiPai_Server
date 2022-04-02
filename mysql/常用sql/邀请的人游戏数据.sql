
select a.id `玩家id`,b._count `斗地主局数`,c._count `麻将局数`,d.register_time `注册时间` from
(select * from club_info where parent_id = '1020282') a
left join (select player_id,count(*) _count from nor_ddz_nor_race_player_log group by player_id) b on a.id = b.player_id
left join (select player_id,count(*) _count from nor_mj_xzdd_race_player_log group by player_id) c on a.id = c.player_id
left join player_register d on a.id = d.id
where to_days(d.register_time) = to_days('2018-12-6 11:42:29');