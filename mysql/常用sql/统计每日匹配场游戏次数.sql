
-- 按天
select max(begin_time) _time ,count(*) _count from freestyle_race_log group by to_days(begin_time);

-- 按场次
select game_id 场次编号, if('nil' = name,'<未命名>',name) 场次,count(*) 数量 from freestyle_race_log 
where begin_time > '2018-10-20 0:47:11' group by game_id order by game_id;

