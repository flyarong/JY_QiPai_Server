
DROP PROCEDURE IF EXISTS temp_check_user;

delimiter ;;
CREATE DEFINER=CURRENT_USER PROCEDURE temp_check_user()
    SQL SECURITY INVOKER
BEGIN

	DROP TABLE IF EXISTS temp_check_user_table;
	CREATE TABLE temp_check_user_table  (
		`order` bigint NOT NULL AUTO_INCREMENT,
	  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
		PRIMARY KEY (`order`)
	);
    
	insert into temp_check_user_table(`id`) values 
    ('101576685'),
    ('10846008'),
    ('101425721'),
    ('10671400'),
    ('10667302'),
    ('101058719'),
    ('101578997'),
    ('101488364'),
    ('1030871'),
    ('10846008'),
    ('10593020'),
    ('101345678'),
    ('101467138'),
    ('101508317'),
    ('101562336'),
    ('1081014'),
    ('101572415'),
    ('101572962'),
    ('101577763'),
    ('101578721'),
    ('101581290'),
    ('101057853'),
    ('101577264'),
    ('101554312'),
    ('10723258'),
    ('101576379');
		
		select a.`order`,a.id check_id,b.`repeat`, c.* from temp_check_user_table a 
		left join  (select id,if(count(*)>1,'有重复','') `repeat` from temp_check_user_table group by `id`) b on a.id = b.id -- 去重
		left join player_info c on a.id = c.id 
		order by a.`order`;

END;;

delimiter ;

call temp_check_user();

DROP TABLE IF EXISTS temp_check_user_table;
DROP PROCEDURE IF EXISTS temp_check_user;