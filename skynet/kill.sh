#!/bin/sh
if [ ! -n "$1" ]; then
  echo "No argument!"
  echo "example :"
  echo "  ./kill.sh lyx_test1"
  exit 1
fi

ps -aux | grep "[g]ame/launch/$1" | awk '{print $2}'| xargs kill -9
