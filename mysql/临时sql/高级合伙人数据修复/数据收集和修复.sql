
-- --------------------------------------------------------------------
-- 表结构

CREATE TABLE `tmp_gjhhr_offsprint`  (
  `player_id` varchar(50) NOT NULL,
  `offspring_id` varchar(50) NOT NULL,
  PRIMARY KEY (`player_id`, `offspring_id`)
);


CREATE TABLE `tmp_gjhhr_pay_day`  (
  `player_id` varchar(50) NOT NULL,
  `day_index` varchar(50) NOT NULL,
	`money` int NOT NULL,
  PRIMARY KEY (`player_id`, `day_index`)
);

CREATE TABLE `tmp_gjhhr_pay_month`  (
  `player_id` varchar(50) NOT NULL,
	`money` int NOT NULL,
	time_start datetime not null,
	time_tongji datetime not null,
  PRIMARY KEY (`player_id`)
);

CREATE TABLE `tmp_gjhhr_achievements_month`  (
  `player_id` varchar(50) NOT NULL,
	`money` int NOT NULL,
  PRIMARY KEY (`player_id`)
);

CREATE TABLE `tmp_gjhhr_achievements_diff`  (
  `player_id` varchar(50) NOT NULL,
	`all_achievements` int NOT NULL,
	`money` int NOT NULL,
	diff  int NOT NULL,
  PRIMARY KEY (`player_id`)
);

CREATE TABLE `tmp_gjhhr_day_log_fix`  (
  player_id varchar(50) NOT NULL,
	day_index int not null,
	log_no int(11) not null,
	achievements int NOT NULL,
	all_achievements int NOT NULL,
	time datetime,
  PRIMARY KEY (player_id,day_index),
	INDEX `tmp_gjhhr_day_log_fix_log_no`(`log_no`) USING BTREE
);


-- --------------------------------------------------------------------
-- 所有子孙

truncate tmp_gjhhr_offsprint;

-- 直接孩子
insert into tmp_gjhhr_offsprint(player_id,offspring_id) 
select a.parent_id,a.id from sczd_relation_data a
left join tmp_gjhhr_offsprint b on a.parent_id = b.player_id and a.id = b.offspring_id
where a.parent_id is not null and b.player_id is null;

-- 孩子的 子孙：多次执行，直到影响的函数为 0 
insert into tmp_gjhhr_offsprint(player_id,offspring_id) 
select a.player_id,a.offspring_id from 
(
	select a.player_id,b.offspring_id from tmp_gjhhr_offsprint a
	inner join tmp_gjhhr_offsprint b on a.offspring_id = b.player_id
	group by a.player_id,b.offspring_id
) a
left join tmp_gjhhr_offsprint c on a.player_id = c.player_id and a.offspring_id = c.offspring_id
where c.player_id is null and c.offspring_id is null;

-- 自己也加里面（算业绩），只执行一次
insert into tmp_gjhhr_offsprint(player_id,offspring_id) 
select player_id,player_id from (
	select distinct player_id from tmp_gjhhr_offsprint where player_id not in (select player_id from tmp_gjhhr_offsprint where offspring_id = player_id)
) a

-- --------------------------------------------------------------------
-- 每天的消费

truncate tmp_gjhhr_pay_day;
insert into tmp_gjhhr_pay_day(player_id,day_index,money)
select player_id,day_index,sum(money) money from (
	select a.player_id,to_days(SUBDATE(a.end_time,interval 10800 second))-to_days('2019-03-01') + 1 day_index, money from player_pay_order_all a
	inner join sczd_relation_data b on a.player_id = b.id
	where a.end_time > '2019-03-01 09:23:36' and order_status = 'complete'
) a
group by a.player_id,a.day_index;

-- --------------------------------------------------------------------
-- 当月消费

truncate tmp_gjhhr_pay_month;
insert into tmp_gjhhr_pay_month(player_id,money,time_start,time_tongji)
select a.player_id,sum(money) money,'2019-03-01 09:23:36',now() from player_pay_order_all a
inner join sczd_relation_data b on a.player_id = b.id
where a.end_time >= '2019-03-01 09:23:36' and order_status = 'complete'
group by a.player_id;

-- --------------------------------------------------------------------
-- 当月业绩

truncate tmp_gjhhr_achievements_month;
insert into tmp_gjhhr_achievements_month(player_id,money)
select b.player_id, sum(money) money from tmp_gjhhr_pay_month a
inner join tmp_gjhhr_offsprint b on a.player_id = b.offspring_id
group by b.player_id;


-- 核对 业绩 数额
truncate tmp_gjhhr_achievements_diff;
insert into tmp_gjhhr_achievements_diff(player_id,all_achievements,money,diff)
select player_id,all_achievements,money,diff from (
	select a.player_id,b.all_achievements,a.money,b.all_achievements - a.money diff from tmp_gjhhr_achievements_month a
	inner join sczd_player_all_achievements b on a.player_id = b.id 
) a;

-- --------------------------------------------------------------------
-- 修复每天业绩日志（注意： 经核对，总业绩是正确的，这里仅用 sczd_player_day_achievements_log 表中的数据 自修复！！！）

-- 整理 每天数据 到临时表
truncate tmp_gjhhr_day_log_fix;
insert into tmp_gjhhr_day_log_fix(player_id,day_index,log_no,achievements,all_achievements,time)
select id,(to_days(time)-to_days('2019-03-01')) day_index,`no`,achievements,all_achievements,time  from sczd_player_day_achievements_log where time > '2019-03-02' order by id,time;

-- 验证 不匹配的数据
select distinct time from (
	select a.player_id,a.day_index,a.log_no,a.achievements,a.all_achievements,a.time from tmp_gjhhr_day_log_fix a
	inner join tmp_gjhhr_day_log_fix b on a.player_id = b.player_id and a.day_index = b.day_index+1
	where a.all_achievements <> (a.achievements + b.all_achievements)
) a;

-- 在临时表中 修复不匹配的数据
update tmp_gjhhr_day_log_fix a inner join tmp_gjhhr_day_log_fix b 
on a.player_id = b.player_id and a.day_index = b.day_index+1
set a.achievements=a.all_achievements-b.all_achievements;

-- 验证修复后的数据
select * from tmp_gjhhr_day_log_fix where player_id = '102493208';

-- 修复数据（在 master 执行，执行前必须备份！！！！！）
-- update sczd_player_day_achievements_log a inner join tmp_gjhhr_day_log_fix b 
-- on a.`no` = b.log_no 
-- set a.achievements = b.achievements;








