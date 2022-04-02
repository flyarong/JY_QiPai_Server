-- 查询所有上级
set @user_id = '10585186';

DROP PROCEDURE IF EXISTS temp_cha_xun_proc_parent;

delimiter ;;
CREATE DEFINER=CURRENT_USER PROCEDURE temp_cha_xun_proc_parent()
    SQL SECURITY INVOKER
BEGIN


	DROP TABLE IF EXISTS tmp_user_parent;
	CREATE TABLE tmp_user_parent  (
      order_id bigint NOT NULL AUTO_INCREMENT,
	  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
	  PRIMARY KEY (`order_id`)
	);
    
	-- 第一级 上级
	insert into tmp_user_parent(id) select parent_id from club_info where id = @user_id;

	-- 逐级循环，直到没有
	while row_count() > 0 do

       insert into tmp_user_parent(id) select parent_id from club_info where id in (select id from tmp_user_parent) and parent_id not in (select id from tmp_user_parent);

	end while;

	select a.id,b.`name`,c.parent_id from tmp_user_parent a 
    inner join player_info b on a.id = b.id 
    inner join club_info c on a.id = c.id 
    order by a.order_id;


END;;

delimiter ;

call temp_cha_xun_proc_parent();

DROP TABLE IF EXISTS tmp_user_parent;
DROP PROCEDURE IF EXISTS temp_cha_xun_proc_parent;