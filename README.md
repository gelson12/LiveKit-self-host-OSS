# LiveKit self-host OSS — Railway deploy

Replaces a LiveKit Cloud subscription. **Same WebRTC protocol, same SDK, same key/secret model — just self-hosted, so no per-minute quota.**

## What this is

A 4-line Dockerfile that pulls `livekit/livekit-server` and bakes in a config tuned for Railway. Plus a `livekit.yaml` and a `railway.json` so Railway picks the right builder.

You point the `friday_jarvis2` and `OpenJarvis` worker services at the public URL this service produces, and you stop paying LiveKit Cloud.

## Deploy to Railway (≈3 min)

1. **Railway → New Project / Service → Deploy from GitHub repo** → pick this repo.
2. **Variables → New Variable**, set:

   ```
   LIVEKIT_KEYS=<api-key>: <api-secret>
   ```

   Format is **YAML map syntax on one line** — literal `<key><space><colon><space><secret>`. The actual values are delivered out-of-band (chat / password manager / wherever) — never committed.

3. **Settings → Networking → Generate Domain.**
4. **Settings → Networking → Target Port** = `7880`.
5. Wait for first deploy. After Active, copy the public URL (e.g. `livekit-prod-xxxx.up.railway.app`).
6. On the **`friday_jarvis2`** and **`OpenJarvis`** Railway services, update:

   - `LIVEKIT_URL`        = `wss://livekit-prod-xxxx.up.railway.app`
   - `LIVEKIT_API_KEY`    = same key from step 2
   - `LIVEKIT_API_SECRET` = same secret from step 2

Both worker services redeploy automatically. Bridges automatically re-fetch JWTs through the existing `/api/bridge/token` endpoint and connect to the new self-hosted server. **The LiveKit Cloud subscription can be cancelled.**

## What's in here

| File | Purpose |
|---|---|
| `Dockerfile` | Pulls `livekit/livekit-server:latest`, bakes in `livekit.yaml`, exposes 7880/7881 |
| `livekit.yaml` | TCP-friendly media + external IP advertising. Keys come from env var, never committed |
| `railway.json` | Tells Railway to build with the Dockerfile, restart 10× on failure |

## Why TCP-only for media?

Railway's primary public networking is TCP. UDP exposure exists on some plans but is limited. WebRTC defaults to UDP for lowest latency but negotiates TCP fallback when UDP isn't reachable. With our config, the SFU advertises both — clients with UDP available use UDP, others fall back to TCP automatically. For voice / desktop control, the TCP penalty (~50-100 ms) is unnoticeable.

If you later want UDP media on this Railway deploy, see the [Railway UDP docs](https://docs.railway.com/) or move this service to a host with native UDP (Hetzner / DigitalOcean / your own VPS).

## Resource sizing

- ~512 MB RAM idle, ~1 GB under load (one voice room + a couple of bridges).
- ~0.25 vCPU baseline, bursts to ~1 vCPU on call setup.
- Negligible disk.

Railway **Hobby plan** ($5/month) covers this comfortably. The free trial credit may stretch it longer.

## Regenerating keys (if compromised)

```powershell
# In any PowerShell window:
$key = "API" + -join ((65..90 + 97..122 + 48..57) | Get-Random -Count 16 | %{[char]$_})
$secret = -join ((65..90 + 97..122 + 48..57) | Get-Random -Count 48 | %{[char]$_})
"LIVEKIT_API_KEY    = $key"
"LIVEKIT_API_SECRET = $secret"
```

Paste both into Railway variables on **this** service (`LIVEKIT_KEYS=<key>: <secret>`) AND on the `LIVEKIT_API_KEY` + `LIVEKIT_API_SECRET` vars of `friday_jarvis2` + `OpenJarvis`. All three redeploy and the rotation is complete — bridges auto-reconnect via the token endpoint.
