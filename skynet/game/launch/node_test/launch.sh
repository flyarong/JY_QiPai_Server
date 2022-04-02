#!/bin/sh

./skynet `dirname $0`/node_1.lua
ping -c 2 127.0.0.1>nul
./skynet `dirname $0`/node_2.lua
ping -c 2 127.0.0.1>nul
./skynet `dirname $0`/node_3.lua
