
-- 人次
select max(date) _time,count(*)
from player_prop_log 
where prop_type = 'room_card' and change_value < 0
group by to_days(date)
order by _time desc

--select * from friendgame_room_log