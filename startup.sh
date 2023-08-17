#!/bin/bash

# piaware is a bit buggy (as of 2023-08-17). Although you can specify a `receiver-host` in the
# configuration file, piaware won't start its feeder if it isn't localhost. The reason
# seems to be that it uses netcat to make sure something is listening on port localhost:3005. You'll
# see messages like `no ADS-B data program is serving on port 30005, not starting multilateration client yet`
# if you try to use something other than localhost.
#
# Use socat to redirect localhost:30005 to the real host.

if [ -n "${RECEIVER_HOST}" ] && [ "${RECEIVER_HOST}" != "localhost" ]; then
    echo "Starting background socat to host ${RECEIVER_HOST}"
    socat TCP-LISTEN:30005,fork,reuseaddr "TCP:${RECEIVER_HOST}:30005" &
fi 

exec /usr/bin/piaware -plainlog -statusfile /status.json
