
select a.player_id,b.parent_ids from (
	select distinct player_id from (

		select player_id from zy_city_match_hx_lose
		union
		select player_id from zy_city_match_rank_hx
	) a ) a 
left join club_info b on a.player_id = b.id
where player_id not like 'v%'
order by length(parent_ids) desc;
	
select a.*,b.phone_number from zy_city_match_rank_fs a 
left join bind_phone_number b on a.player_id = b.player_id
where a.player_id not like 'v%'
order by a.rank;