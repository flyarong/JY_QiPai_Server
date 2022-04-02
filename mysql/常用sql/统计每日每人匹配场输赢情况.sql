select DATE_FORMAT(date,'%Y-%m-%d') `日期`,id,sum(change_value) `匹配场输赢` from player_asset_log 
where asset_type = 'jing_bi' and  change_type like 'freestyle_%' and id not like 'robot%' and
	date >= '2019-1-3' and date < '2019-1-5'
group by to_days(date),id
order by date;

