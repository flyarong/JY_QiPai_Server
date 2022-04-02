
CREATE TABLE `tmp_gjhhr_offsprint`  (
  `player_id` varchar(50) NOT NULL,
  `offspring_id` varchar(50) NOT NULL,
  PRIMARY KEY (`player_id`, `offspring_id`)
);

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
	select distinct player_id from tmp_gjhhr_offsprint
) a

