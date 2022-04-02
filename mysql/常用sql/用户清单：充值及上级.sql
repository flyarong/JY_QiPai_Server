select player_id,b.parent_id,min(create_time) _time  from
(

	select * from player_pay_order_log 
	union
	select * from player_pay_order
	
) a left join club_info b on a.player_id = b.id

where a.order_status = 'complete' 

group by a.player_id

order by _time

