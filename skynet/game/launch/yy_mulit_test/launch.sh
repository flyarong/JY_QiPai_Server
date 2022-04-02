#!/bin/sh

./skynet `dirname $0`/game_config.lua
ping -c 2 127.0.0.1>nul
./skynet `dirname $0`/gate_config.lua
ping -c 2 127.0.0.1>nul
./skynet `dirname $0`/data_config.lua
