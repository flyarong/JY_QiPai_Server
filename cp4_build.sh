#!/bin/sh

# data
scp -rp ./skynet/luaclib/* root@172.18.107.235:/home/jy/skynet4/luaclib/
scp -rp ./skynet/cservice/* root@172.18.107.235:/home/jy/skynet4/cservice/
scp -rp ./skynet/skynet root@172.18.107.235:/home/jy/skynet4/skynet

# game
scp -rp ./skynet/luaclib/* root@172.18.107.233:/home/jy/skynet4/luaclib/
scp -rp ./skynet/cservice/* root@172.18.107.233:/home/jy/skynet4/cservice/
scp -rp ./skynet/skynet root@172.18.107.233:/home/jy/skynet4/skynet

# gate
scp -rp ./skynet/luaclib/* root@172.18.107.234:/home/jy/skynet4/luaclib/
scp -rp ./skynet/cservice/* root@172.18.107.234:/home/jy/skynet4/cservice/
scp -rp ./skynet/skynet root@172.18.107.234:/home/jy/skynet4/skynet

# tg
scp -rp ./skynet/luaclib/* root@172.18.107.238:/home/jy/skynet4/luaclib/
scp -rp ./skynet/cservice/* root@172.18.107.238:/home/jy/skynet4/cservice/
scp -rp ./skynet/skynet root@172.18.107.238:/home/jy/skynet4/skynet

