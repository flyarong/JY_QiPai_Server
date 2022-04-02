

-- 按天
select max(_time) _time ,count(*) _count from (
	SELECT id ,max(begin_time) _time FROM match_nor_log where id > 0 group by id
)a
group by to_days(a._time);


-- 按场次
select game_id 场次编号, if('nil' = name,'<未命名>',name) 场次,count(*) 数量 from match_nor_log 
where begin_time > '2018-10-20 0:47:11' group by game_id order by game_id;
