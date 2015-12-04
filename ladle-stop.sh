#!/bin/sh
# stop ladle by sending 'kill' to it via its socket
# usage: ladle-stop.sh host port
echo 'kill' | nc $1 $2