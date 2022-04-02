select all_achievements-yesterday_all_achievements, a.* from sczd_player_all_achievements a where id = '1011721'

select * from sczd_player_day_achievements_log where id = '105801' and time > '2019-03-02'

select * from tmp_gjhhr_offsprint where player_id = '105801';

-- 每天： 凌晨 3 点之前 算 前一天的
select a.end_time, sum(money) from player_pay_order_all a
inner join tmp_gjhhr_offsprint b on a.player_id = b.offspring_id
where b.player_id = '102493208' and order_status = 'complete' and a.end_time > '2019-03-01 09:23:36'
group by to_days(SUBDATE(a.end_time,interval 10800 second))

-- 业绩明细
select money,a.end_time,a.player_id,a.* from player_pay_order_all a
inner join tmp_gjhhr_offsprint b on a.player_id = b.offspring_id
where b.player_id = '102507911' and order_status = 'complete' and a.end_time > '2019-03-01 08:00:37'
order by a.end_time

-- 业绩合计
select sum(money) from player_pay_order_all a
inner join tmp_gjhhr_offsprint b on a.player_id = b.offspring_id
where a.end_time > '2019-03-01 09:16:37' and b.player_id = '102156533' and order_status = 'complete'
order by a.end_time

-- -------------------
select * from sczd_gjhhr_settle_log where id = '1020356'
select distinct time from sczd_gjhhr_settle_log
select * from sczd_relation_data where id in ('1076418','1011721','105801','108629','1017875','1055452')

/*
1076418
	108629
		1017875
			105801
				1011721
					1055452

*/

select * from sczd_player_day_achievements_log 
where id in ('1076418','1011721','105801','108629','1017875','1055452')  and time > '2019-03-02' 
order by id


-- 每天： 凌晨 3 点之前 算 前一天的
select b.player_id,a.end_time, sum(money) from player_pay_order_all a
inner join tmp_gjhhr_offsprint b on a.player_id = b.offspring_id
where a.end_time > '2019-03-01 09:23:37' and
		  a.end_time < '2019-03-12 03:0:0' and b.player_id in ('1076418','1011721','105801','108629','1017875','1055452') and order_status = 'complete'
group by b.player_id,to_days(SUBDATE(a.end_time,interval 10800 second))
order by b.player_id,a.end_time


