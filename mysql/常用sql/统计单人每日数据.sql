
# 钻石 购买
select date `日期`,sum(change_value) `钻石` from player_asset_log 
where id = '1036008' and asset_type = 'diamond' and change_type = 'buy'
group by to_days(date)
order by date;

# 鲸币 收入
select date `日期`,sum(change_value) `鲸币` from player_asset_log
where id = '1036008' and asset_type = 'jing_bi' and change_value > 0
group by to_days(date)
order by date;

# 鲸币 消耗
select date `日期`,sum(change_value) `鲸币` from player_asset_log
where id = '1036008' and asset_type = 'jing_bi' and change_value < 0
group by to_days(date)
order by date;