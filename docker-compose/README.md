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

- **OpenClaw Gateway**: Main service on localhost:18789 (local access only)
- **OpenClaw CLI**: Interactive CLI for configuration (manual start only)
- **Caddy**: Reverse proxy for HTTP access (port 80)
- **Twingate Connector**: Secure remote access enablement

## Security Notes

- **Gateway binds to localhost only** (`127.0.0.1:18789`) - not accessible from network
- **Caddy provides HTTP access** - eliminates need for SSH tunneling
- **Twingate provides Zero Trust access** - no public port exposure
- **Never commit `.env`** - it contains secrets and API keys

## Local Access Only

If you only need local access, comment out the `caddy` and `twingate-connector` services in `docker-compose.yml`:

```yaml
# Comment out these sections:
# caddy:
#   ...
# twingate-connector:
#   ...
```

Then start only the gateway:
```bash
docker compose up -d openclaw-gateway
```

## After Deployment

1. **Local access**: Navigate to `http://localhost:18789/?token=<your-token>`
2. **Remote access** (if enabled):
   - Configure Twingate Resource in Admin Console
   - Point resource to Docker host IP, port 80
   - Assign access to users/groups
   - Connect via Twingate Client

See the full [deployment guide](https://docs.twingate.com/docs/openclaw-docker-compose) for complete setup instructions.
