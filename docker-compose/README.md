# Docker Compose Deployment for OpenClaw

This directory contains Docker Compose configuration for deploying OpenClaw (formerly Clawdbot and Moltbot) with optional Twingate secure remote access on any Docker host.

## Files

- `docker-compose.yml` - Docker Compose configuration (Gateway, CLI, Caddy, Twingate Connector)
- `Caddyfile` - Caddy reverse proxy configuration
- `.env.example` - Example environment variables file (copy and customize)

## Usage

1. **Copy the example environment file**:
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env`** with your values:
   - AI provider API key (Anthropic Claude or OpenAI)
   - Twingate tokens (if enabling remote access)

3. **Create directories for volumes**:
   ```bash
   mkdir -p config workspace
   ```

4. **Run onboarding wizard**:
   ```bash
   docker compose run --rm openclaw-cli onboard
   ```

5. **Generate gateway token**:
   ```bash
   docker compose run --rm openclaw-cli dashboard --no-open
   ```
   Copy the token and add it to `.env` as `OPENCLAW_GATEWAY_TOKEN`

6. **Start OpenClaw**:
   ```bash
   docker compose up -d
   ```

## What Gets Created

- **OpenClaw Gateway**: Main service, binds to localhost inside the container (no direct host exposure)
- **Caddy**: Reverse proxy — the only way to reach the gateway (port 80)
- **OpenClaw CLI**: Interactive CLI for onboarding and diagnostics (manual start only)
- **Twingate Connector**: Optional, for secure remote access

## Architecture

Caddy and the CLI share the gateway's network namespace (`network_mode: service:openclaw-gateway`), so they can reach the gateway on `localhost:18789` without exposing that port to the host or the Docker network. Only port 80 (Caddy) is mapped to the host.

## Security Notes

- **Gateway binds to localhost only** — not accessible from the host or network directly
- **Caddy is the sole entry point** — reverse proxies `localhost:18789` → port `80`
- **Host port 80 is bound to `127.0.0.1`** — not reachable from the network
- **Twingate provides Zero Trust access** — no public port exposure for remote access
- **Never commit `.env`** — it contains secrets and API keys

## Local Access Only

If you only need local access, comment out the `twingate-connector` service in `docker-compose.yml` and start normally:

```bash
docker compose up -d
```

## After Deployment

1. **Local access**: Navigate to `http://localhost/?token=<your-token>`
2. **Remote access** (if Twingate enabled):
   - Configure Twingate Resource in Admin Console
   - Point resource to Docker host IP, port 80
   - Assign access to users/groups
   - Connect via Twingate Client

See the full [deployment guide](https://docs.twingate.com/docs/openclaw-docker-compose) for complete setup instructions.
