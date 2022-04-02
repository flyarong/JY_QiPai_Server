
-- 检查日志错误
select a.id,b.yesterday_all_achievements,a.achievements,a.achievements -b.yesterday_all_achievements diff 
from  sczd_player_day_achievements_log a inner join sczd_player_all_achievements b on a.id = b.id
order by diff desc;

-- 修复日志数据
update sczd_player_day_achievements_log a join sczd_player_all_achievements b on a.id = b.id
set a.achievements = b.yesterday_all_achievements,a.all_achievements=b.yesterday_all_achievements;

