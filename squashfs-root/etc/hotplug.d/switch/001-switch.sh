#!/bin/sh
logger -t switch "ACTION=$ACTION  PORT=$PORT  SPEED=$SPEED DUPLEX=$DUPLEX"
killall -16 udhcpc
