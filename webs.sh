#!/bin/sh
# Run the ladle web server
# Usage: webs $port

# NOTE: sudo is required to run on ports lower than 1000, 
# so it is used here.

sudo lua ladle.lua $1
