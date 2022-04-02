

select max(a.date) _date ,count(a.change_value * b.value) _value 
from player_prop_log a inner join prop_type b on a.prop_type = b.prop_type
where a.change_value > 0 and a.change_type = 'freestyle_award'
group by to_days(date)