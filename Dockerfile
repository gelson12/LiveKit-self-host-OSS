# LiveKit OSS self-host — Railway-targeted Dockerfile.
#
# Base image is LiveKit's official server build; we bake in a config
# tuned for Railway's networking model + an entrypoint shim that binds
# signaling to Railway's $PORT (otherwise Railway's HTTPS edge returns
# 502 because LiveKit listens on 7880 but Railway routes to $PORT).

FROM livekit/livekit-server:latest

COPY livekit.yaml /etc/livekit.yaml
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Signaling (auto-rewritten to $PORT) + RTC TCP fallback (7881).
EXPOSE 7880 7881

ENTRYPOINT ["/entrypoint.sh"]
