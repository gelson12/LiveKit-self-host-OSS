#!/bin/sh
# entrypoint.sh — substitute Railway's $PORT into the config at startup.
#
# Railway routes the auto-generated public HTTPS domain to whatever port
# the container reports as `$PORT` (Railway injects it). LiveKit's
# config defaults to 7880 — so without this shim, Railway sends traffic
# to (say) 8080 and the container listens on 7880, giving a 502 at the
# edge.
#
# We sed-rewrite livekit.yaml on each start so `port:` matches whatever
# Railway gave us. Outside Railway (no $PORT), it falls back to 7880.

set -e

PORT="${PORT:-7880}"
sed -i "s/^port: .*/port: ${PORT}/" /etc/livekit.yaml
echo "[entrypoint] LiveKit signaling port = ${PORT}"

exec /livekit-server --config /etc/livekit.yaml
