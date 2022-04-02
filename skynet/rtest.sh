#!/bin/sh

# data
scp -r ./luaclib/* root@172.18.107.235:/home/jy/skynet4/luaclib/
scp -r ./cservice/* root@172.18.107.235:/home/jy/skynet4/cservice/
scp -r ./skynet root@172.18.107.235:/home/jy/skynet4/skynet

# game
scp -r ./luaclib/* root@172.18.107.233:/home/jy/skynet4/luaclib/
scp -r ./cservice/* root@172.18.107.233:/home/jy/skynet4/cservice/
scp -r ./skynet root@172.18.107.233:/home/jy/skynet4/skynet

# gate
scp -r ./luaclib/* root@172.18.107.234:/home/jy/skynet4/luaclib/
scp -r ./cservice/* root@172.18.107.234:/home/jy/skynet4/cservice/
scp -r ./skynet root@172.18.107.234:/home/jy/skynet4/skynet

# tg
scp -r ./luaclib/* root@172.18.107.238:/home/jy/skynet4/luaclib/
scp -r ./cservice/* root@172.18.107.238:/home/jy/skynet4/cservice/
scp -r ./skynet root@172.18.107.238:/home/jy/skynet4/skynet

