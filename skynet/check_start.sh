#!/bin/sh
alive=`ps aux | grep -v grep | grep tg_config | grep skynet | wc -l`
if [ $alive == "1" ]; then
    echo "alive"
else
	cd /home/jy/skynet
    nohup ./skynet game/launch/aliyun_release/tg_config.lua > skynet_node_l_log 2>&1 &    
fi


#*/1 * * * * sh /home/jy/skynet/check_start.sh >> /home/jy/skynet/nohup_start.log
