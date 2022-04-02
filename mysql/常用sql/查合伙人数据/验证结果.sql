
-- tmp_user_offspring2 为所有
-- tmp_user_offspring1 为去掉高级合伙人 以下的
select a.id,b.parent_id,b.parent_ids,c.id jyh_user_id,c.game_partner_level from (
		select a.id from tmp_user_offspring2 a 
		left join tmp_user_offspring1 b on a.id=b.id
		where b.id is null ) a
left join club_info b on a.id = b.id
left join webdb_trans.jyh_user c on b.parent_id = c.id;

select * from club_info where id = '101818373';

select * from webdb_trans.jyh_user where id = '102195460';

