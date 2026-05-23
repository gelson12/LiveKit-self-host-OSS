#!/bin/sh
# entrypoint.sh — generate the final livekit.yaml at container start.
#
# Why generate (not just sed-rewrite)?  Two Railway-specific quirks:
#
#   1. Railway injects $PORT (e.g. 8080) and routes the public HTTPS
#      domain to that port. LiveKit's default 7880 → 502 at the edge
#      with X-Railway-Fallback: true.
#
#   2. YAML `keys: {}` (empty map) may not reliably be replaced by an
#      env-var override at startup; the server may treat the empty map
#      as authoritative and reject every JWT as "no matching key".
#
# Solution: bake the runtime values (port + keys) into a fresh config
# file at container start, then exec livekit-server against it.

set -e

PORT_VAL="${PORT:-7880}"
KEYS_VAL="${LIVEKIT_KEYS:-}"

echo "[entrypoint] booting LiveKit OSS on Railway"
echo "[entrypoint]   PORT env       = ${PORT:-<unset, defaulting to 7880>}"
echo "[entrypoint]   bind port      = ${PORT_VAL}"
echo "[entrypoint]   LIVEKIT_KEYS   = ${KEYS_VAL:+set (length ${#KEYS_VAL})}${KEYS_VAL:-MISSING}"

if [ -z "$KEYS_VAL" ]; then
    echo "[entrypoint] FATAL: LIVEKIT_KEYS env var is empty."
    echo "[entrypoint] Set it on Railway → this service → Variables → LIVEKIT_KEYS=<api-key>: <api-secret>"
    exit 1
fi

CONFIG=/tmp/livekit.yaml
cat > "$CONFIG" <<EOF
port: ${PORT_VAL}

rtc:
  tcp_port: 7881
  port_range_start: 50000
  port_range_end: 60000
  use_external_ip: true

log_level: info

keys:
  ${KEYS_VAL}
EOF

echo "[entrypoint] generated config at ${CONFIG}:"
echo "----------------------------------------"
# Print config WITHOUT the secret — show only the key portion of the first key line.
# (Avoids leaking the secret to deploy logs.)
sed -E 's/(^  [A-Za-z0-9_]+: ).+$/\1<redacted>/' "$CONFIG"
echo "----------------------------------------"
echo "[entrypoint] launching: /livekit-server --config ${CONFIG}"

exec /livekit-server --config "$CONFIG"
