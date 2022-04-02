-- 查询所有子孙
set @user_id = '108629';

DROP PROCEDURE IF EXISTS temp_cha_xun_proc_offspring;

delimiter ;;
CREATE DEFINER=CURRENT_USER PROCEDURE temp_cha_xun_proc_offspring()
    SQL SECURITY INVOKER
BEGIN


	DROP TABLE IF EXISTS tmp_user_offspring;
	CREATE TABLE tmp_user_offspring  (
      order_id bigint NOT NULL AUTO_INCREMENT,
	  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
      `level` int NOT NULL,
	  PRIMARY KEY (`order_id`)
	);
    
	set @tmp_level = 1;
		
	-- 第一级 孩子
	insert into tmp_user_offspring(id,`level`) select id,@tmp_level from club_info where parent_id = @user_id;

	-- 逐级循环，直到没有
	while row_count() > 0 do

		set @tmp_level = @tmp_level + 1;
		insert into tmp_user_offspring(id,`level`) select id,@tmp_level from club_info where parent_id in (select id from tmp_user_offspring) and id not in (select id from tmp_user_offspring);

	end while;

	select a.id,b.`name`,a.`level`,c.parent_ids from tmp_user_offspring a 
    inner join player_info b on a.id = b.id 
    inner join club_info c on a.id = c.id 
    order by a.order_id;


END;;

delimiter ;

call temp_cha_xun_proc_offspring();

DROP TABLE IF EXISTS tmp_user_offspring;
DROP PROCEDURE IF EXISTS temp_cha_xun_proc_offspring;