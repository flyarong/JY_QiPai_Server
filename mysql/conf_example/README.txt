1.安装的时候最好从官网下载，一个一个安装。
2.初始账户密码应该是root@123456,但是网上有的说是随机产生一个密码，第一次进去一定要改一下密码。（否则看*1）
3.先进行优化配置my.cnf，里面配置的文件夹肯定会有权限问题。
4.启动cd /etc/init.d/sudo ./mysql start
5.root用户可能无法进行远程登录，创建其他用户用于远程登录。


#递归修改文件夹mydir及包含的所有子文件（夹）的所属用户（jay）和用户组（fefjay）：
#chown -R jay:fefjay mydir #mysql:mysql


#权限修改完了，注意这个动态权限管理
#vi /etc/apparmor.d/usr.sbin.mysqld
#/etc/init.d/apparmor restart


*1：
[mysqld]节点上加skip-grant-tables
重启服务，root登录，回车后即可进入
登录之后查询plugin字段值可能需要修改
select plugin from user where user = 'root';
update user set plugin='mysql_native_password';
update user set authentication_string=password('abc123') where user='root' and host='%';