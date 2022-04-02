-- 查询所有子孙
set @user_id = '105801';
set @start_time ='2019-3-1 0:0:0';
set @end_time ='2019-4-1 0:0:0';
set @`level` = null;


select a.offspring_id `id`,b.`name` `名字`,
-- d.phone_number `电话`,
if(c.is_gjhhr=1,'高级合伙人','推广员') `角色`,
g.first_login_time `首次登录时间`,
if(f.channel_type='weixin','游戏中-微信',if(f.channel_type='alipay','游戏中-支付宝',if(f.channel_type='wxgzh','微信公众号',if(f.channel_type='appstore','游戏中-苹果商店',null)))) `渠道`,
f.create_time `首次充值时间`,convert(f.money/100,decimal) `首次充值金额`,a.`offspring_num` `层级`,a.offsprint_parent_id `上级` 
from player_offspring a
inner join player_info b on a.offspring_id = b.id 
inner join sczd_relation_data c on a.offspring_id = c.id 
left join bind_phone_number d on a.offspring_id = d.player_id
inner join player_pay_order_stat e on a.offspring_id = e.player_id
inner join player_pay_order_all f on e.first_order_id = f.order_id
inner join player_login_stat g on g.id = a.offspring_id

where a.player_id= @user_id and f.create_time is not null and (a.`offspring_num` = @`level` or @`level` is null)
and e.first_complete_time>=@start_time and e.first_complete_time <= @end_time
and g.first_login_time>=@start_time and g.first_login_time <= @end_time

order by a.`offspring_num`,f.create_time desc;
