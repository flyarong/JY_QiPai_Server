************************************************************ screen 操作 ******************************************************
screen -ls       查看所有的屏幕
ctrl+A+D         回到主界面
ctrl+D           在具体的screen中可以杀掉screen
screen -ls       显示所有的界面
screen -S nn     新建一个界面，然后就可以在这个界面自己启动服务器，方便查看打印
screen -d xxx    断开别人和界面的链接
screen -r xxx    回到某个界面
screen -x xxx    链接到某个界面，直接忽略断没断开链接   

************************************************************ 进程操作 ******************************************************
htop                                                    查看所有的进程状态，包括cpu,内存等的状态
./show.sh                                               显示启动了的skynet进程
./kill.sh aliyun_test4                                  杀掉测试4 的进程
./kill.sh aliyun_release                                杀掉正式服的进程
./skynet game/launch/aliyun_test4/game_config.lua       启动服务器game_config.lua
crontab -e                                              编辑进程监控配置
                在如下行 首 加上 或 去掉 # 号注释符
    */2 * * * * sh /home/jy/skynet/check_start.sh >> /home/jy/skynet/nohup_start.log

************************************************************ 充值订单 ******************************************************
---- 本地服务器充值 用 网站浏览器 打开 
http://127.0.0.1:8001/pay/modify_order_status?order_id=201901220000001q9dN8&order_status=complete&channel_account_id=shoudong_wss_2019_1_31

---- 203 完成 订单
-- xshell 执行
curl http://127.0.0.1:8001/pay/modify_order_status?order_id=201901300000006mbEtR\&order_status=complete\&channel_account_id=shoudong_wss_2019_1_30


---- 测试4  完成订单，8004是测试4端口。order_status = complete 改状态为完成。channel_account = 写一下是谁操作+时间  ---- 在data 节点上(ps:主要看web服务在那个节点上启动)
curl http://127.0.0.1:8004/pay/modify_order_status?order_id=201901300000006mbEtR\&order_status=complete\&channel_account_id=shoudong_wss_2019_1_30


---- 正式服 完成订单
curl http://127.0.0.1:8000/pay/modify_order_status?order_id=201812210000002rAtaK\&order_status=complete\&channel_account_id=shoudong_wss_2019_1_18



************************************************************ 发送邮箱 ******************************************************

---- 正式服 给四个对应的玩家id发送邮件 邮件中包含了附件 鲸币20000 
curl http://127.0.0.1:8000/email/send_email?data={"players": ["102013924","101051718","102022162","10827331"],"email":{"type":"native","title":"系统奖励","sender":"系统","valid_time":1721547864,"data":"{content='感谢您对《鲸鱼斗地主》的支持，给您带来的不便敬请谅解，愿您在游戏中玩的开心，游戏过程中有任何问题欢迎咨询客服，谢谢。',jing_bi=20000}"}}\&opt_admin=yy\&reason=mj_er_crash_award

data=一个json ，json需要URL编码
最后输入xshell的样子如下:
curl http://127.0.0.1:8000/email/send_email?data=%7b%22players%22%3a+%5b%22102013924%22%2c%22101051718%22%2c%22102022162%22%2c%2210827331%22%5d%2c%22email%22%3a%7b%22type%22%3a%22native%22%2c%22title%22%3a%22%e7%b3%bb%e7%bb%9f%e5%a5%96%e5%8a%b1%22%2c%22sender%22%3a%22%e7%b3%bb%e7%bb%9f%22%2c%22valid_time%22%3a1721547864%2c%22data%22%3a%22%7bcontent%3d%27%e6%84%9f%e8%b0%a2%e6%82%a8%e5%af%b9%e3%80%8a%e9%b2%b8%e9%b1%bc%e6%96%97%e5%9c%b0%e4%b8%bb%e3%80%8b%e7%9a%84%e6%94%af%e6%8c%81%ef%bc%8c%e7%bb%99%e6%82%a8%e5%b8%a6%e6%9d%a5%e7%9a%84%e4%b8%8d%e4%be%bf%e6%95%ac%e8%af%b7%e8%b0%85%e8%a7%a3%ef%bc%8c%e6%84%bf%e6%82%a8%e5%9c%a8%e6%b8%b8%e6%88%8f%e4%b8%ad%e7%8e%a9%e7%9a%84%e5%bc%80%e5%bf%83%ef%bc%8c%e6%b8%b8%e6%88%8f%e8%bf%87%e7%a8%8b%e4%b8%ad%e6%9c%89%e4%bb%bb%e4%bd%95%e9%97%ae%e9%a2%98%e6%ac%a2%e8%bf%8e%e5%92%a8%e8%af%a2%e5%ae%a2%e6%9c%8d%ef%bc%8c%e8%b0%a2%e8%b0%a2%e3%80%82%27%2cjing_bi%3d20000%7d%22%7d%7d\&opt_admin=yy\&reason=mj_er_crash_award

---- 正式服 给全服所有玩家发送邮件 只需要把 players 这一项去掉即可

如下
curl http://127.0.0.1:8000/email/send_email?data={"email":{"type":"native","title":"系统奖励","sender":"系统","valid_time":1721547864,"data":"{content='感谢您对《鲸鱼斗地主》的支持，给您带来的不便敬请谅解，愿您在游戏中玩的开心，游戏过程中有任何问题欢迎咨询客服，谢谢。',jing_bi=20000}"}}\&opt_admin=yy\&reason=mj_er_crash_award



********************************************************* 减少一个玩家的资产 ***************************************************

---- 正式服 减少 107477 的钻石 535900 ， 这里可以减少玩家的任何资产，警告只能减少不能增加即change_value只能为负数
---- opt_admin 为操作人 reason 为操作原因

curl http://127.0.0.1:8000/hermos/decrease_player_asset?user_id=107477\&asset_type=diamond\&change_value=-535900\&opt_admin=opt_admin\&reason=reason