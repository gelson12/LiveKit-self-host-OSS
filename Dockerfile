# LiveKit OSS self-host — Railway-targeted Dockerfile.
#
# Base image is LiveKit's official server build; we bake in a config
# tuned for Railway's networking model (TCP-favoured, optional UDP range)
# so the same image runs cleanly on Railway, Hetzner, DigitalOcean, etc.

FROM livekit/livekit-server:latest

# Bake our config into the image at a stable path.
COPY livekit.yaml /etc/livekit.yaml

# Signaling (default 7880) + RTC TCP fallback (7881).
EXPOSE 7880 7881

# We always bind signaling to 7880 inside the container; Railway maps the
# public domain at Settings → Networking → Target Port = 7880.
#
# The LIVEKIT_KEYS env var supplied at runtime is merged into the config
# (Livekit Server reads env vars with the LIVEKIT_ prefix).
ENTRYPOINT ["/livekit-server", "--config", "/etc/livekit.yaml"]
