select max(time) _time,max(player_count) _count from statistics_system_realtime where channel = 'wechat' group by to_days(time)
