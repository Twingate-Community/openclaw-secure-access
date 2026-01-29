# How to Setup and Secure Moltbot on DigitalOcean

## Overview

This guide walks you through deploying Moltbot (AI-powered WhatsApp/Telegram assistant) on DigitalOcean using the official [Moltbot Marketplace app](https://marketplace.digitalocean.com/apps/moltbot), then securing it with Twingate's Zero Trust network access. You'll go from zero to a production-ready AI agent platform with enterprise security in under 30 minutes.

**What You'll Build**:
- Moltbot Gateway running on DigitalOcean Droplet
- WhatsApp/Telegram bot integration
- Secure access via Twingate (no public exposure)
- Production-ready with monitoring and backups

**Infrastructure**:
- 1 DigitalOcean Droplet with Moltbot from Marketplace (2-4 vCPU, 4-8 GB RAM recommended)
- Twingate Connector for secure access (no public Gateway exposure)
- Private networking only

**Who This Is For**:
- Developers wanting to self-host AI assistants
- Teams needing secure, private AI agent infrastructure
- Anyone moving from Tailscale to more granular access control

**Time to Complete**: 20-30 minutes

---

### Architecture Overview

```
[DigitalOcean Droplet]
     ↓
[Moltbot Gateway] ← Node.js app on localhost:18789
     ↓
[WhatsApp/Telegram] ← Chat channels
     ↓
[Claude/OpenAI APIs] ← AI providers

Security Layer:
[Twingate Connector] on same Droplet
     ↓
[Twingate Cloud] enforces access policies
     ↓
[Team Members] ← Twingate Client enables secure remote access
                 (like SSH tunneling but with Zero Trust controls)
```

**Why DigitalOcean?** Simple, reliable, great for small teams. A single Droplet runs everything.

**Why Twingate?** Essential for secure access to the Gateway. Provides Zero Trust security—control who accesses the Gateway, get audit logs, enforce MFA. Enables secure remote access without exposing ports or managing SSH keys.

---

## Prerequisites

### Required
- [ ] DigitalOcean account ([sign up here](https://www.digitalocean.com))
- [ ] Twingate account ([sign up here](https://www.twingate.com))
- [ ] Anthropic API key ([get here](https://console.anthropic.com))
- [ ] SSH key added to DigitalOcean (for configuration access)
- [ ] WhatsApp or Telegram account (for bot setup)

### Optional
- [ ] Terraform (for automated infrastructure deployment)
- [ ] DigitalOcean Spaces (for backups)

**Note**: With the marketplace app, manual setup via web UI is quick and straightforward. Terraform is optional for teams needing repeatable infrastructure.

---

## Step 1: Create Moltbot Droplet from Marketplace (2 minutes)

### 1.1 Deploy from DigitalOcean Marketplace

1. Visit the [Moltbot Marketplace page](https://marketplace.digitalocean.com/apps/moltbot)
2. Click **Create Moltbot Droplet**
3. Configure:
   - **Size**: Basic (s-2vcpu-4gb or larger recommended)
   - **Region**: Choose closest to your team
   - **VPC**: Create new VPC or use default
   - **SSH Key**: Add your public key
   - **Hostname**: `moltbot-gateway`
   - **Enable Monitoring**: ✓
4. Click **Create Droplet**

**What You Get**:
- Ubuntu 22.04 LTS base
- Moltbot pre-installed (Version 2026.1.24-1)
- Node.js and dependencies ready
- Ready for configuration

**Note down**:
- Droplet IP address
- SSH access: `ssh root@<droplet-ip>`

### 1.2 Alternative: Deploy via API

For automation or CI/CD:

```bash
export TOKEN="your-digitalocean-api-token"

curl -X POST -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer '$TOKEN'' -d \
    '{"name":"moltbot-gateway","region":"nyc3","size":"s-2vcpu-4gb","image":"moltbot"}' \
    "https://api.digitalocean.com/v2/droplets"
```

---

## Step 2: Configure Moltbot (2 minutes)

### 2.1 SSH into Your Droplet

```bash
ssh root@<your-droplet-ip>
```

### 2.2 Configure Caddy for Private IP Only

The marketplace image includes Caddy as a reverse proxy. Configure it to only listen on the private IP:

```bash
# Get your droplet's private IP
PRIVATE_IP=$(hostname -I | awk '{print $2}')
echo "Private IP: $PRIVATE_IP"

# Update Caddyfile to remove public access
sudo tee /etc/caddy/Caddyfile > /dev/null <<EOF
${PRIVATE_IP} {
    reverse_proxy localhost:18789
    header X-DO-MARKETPLACE "moltbot"
}
EOF

# Restart Caddy
sudo systemctl restart caddy

# Verify Caddy is running
sudo systemctl status caddy
```

**What this does**: Restricts the reverse proxy to only respond on the private IP address, removing all public internet access. The gateway is now only accessible via Twingate.

✅ **Checkpoint**: Moltbot is pre-configured and running, Caddy only listens on private IP. Now let's set up secure access.

---

## Step 3: Enable Secure Access with Twingate (15 minutes)

First we'll set up Twingate so we can access the Droplet securely, then lock down the VPC completely.

### 3.1 Create Twingate Account

1. Sign up at [twingate.com](https://www.twingate.com)
2. Create Network: `yourcompany.twingate.com`
3. Invite team members (optional for now)

### 3.2 Install Twingate Connector

Still SSH'd into your Droplet:

```bash
# Get tokens from Twingate Admin Console:
# Settings → Connectors → Deploy Connector → Generate Tokens

export TWINGATE_ACCESS_TOKEN="your-access-token"
export TWINGATE_REFRESH_TOKEN="your-refresh-token"
export TWINGATE_NETWORK="yourcompany"  # Without .twingate.com

# Install Connector
curl "https://binaries.twingate.com/connector/setup.sh" | \
  sudo TWINGATE_ACCESS_TOKEN="$TWINGATE_ACCESS_TOKEN" \
  TWINGATE_REFRESH_TOKEN="$TWINGATE_REFRESH_TOKEN" \
  TWINGATE_NETWORK="$TWINGATE_NETWORK" \
  TWINGATE_LABEL_DEPLOYED_BY="moltbot" \
  bash

# Verify
sudo systemctl status twingate-connector
```

### 3.3 Create Twingate Resources

In Twingate Admin Console:

**Resource 1: Moltbot Gateway**
1. Go to **Resources → Add Resource**
2. Configure:
   - **Name**: Moltbot Gateway
   - **Address**: `<droplet-private-ip>`
3. **Create Resource**

### 3.4 Set Access Policy

1. Go to **Access → Policies**
2. Create policy:
   - **Name**: Moltbot Team Access
   - **Resources**: Moltbot Gateway
   - **Users/Groups**: Your team
   - **Require MFA**: ✓ (recommended)
3. **Save**

### 3.5 Test Twingate Access

On your laptop/desktop:

```bash
# Start ssh forwarding
ssh -L 18789:127.0.0.1:18789 user@your-server-ip

# Install Twingate Client (Mac/Windows/Linux)
# https://www.twingate.com/download

# Sign in with your Twingate account and open in browser: http://127.0.0.1:18789
```

**How it works**: Twingate enables secure remote connections to your Droplet without opening ports or running a VPN. The Connector creates an outbound connection to Twingate's cloud, allowing you to access localhost services on the Droplet with Zero Trust policies, audit logs, and no exposed ports on your VPC.

✅ **Checkpoint**: Twingate access is working! Now we can lock down the VPC.

---

## Step 4: Lock Down the VPC (5 minutes)

Now that Twingate provides access, remove all public inbound ports for maximum security.

### 4.1 Configure DigitalOcean Cloud Firewall

1. Go to [DigitalOcean Console → Networking → Firewalls](https://cloud.digitalocean.com/networking/firewalls)
2. Click **Create Firewall**
3. Configure:
   - **Name**: `moltbot-secure`
   - **Apply to Droplets**: Select your `moltbot-gateway` Droplet

### 4.2 Inbound Rules

**Zero Inbound Rules** (completely locked down):

Leave the inbound rules section **empty**. Do not add any rules.

**Why?** Twingate provides all access via outbound Connector connections. No inbound ports needed—not even SSH.

### 4.3 Outbound Rules

**Allow All Outbound** (required for API calls, Twingate, and package updates):

| Type | Protocol | Port Range | Destinations |
|------|----------|------------|--------------|
| All TCP | TCP | All | All IPv4, All IPv6 |
| All UDP | UDP | All | All IPv4, All IPv6 |

### 4.4 Apply Firewall

1. Click **Create Firewall**
2. Verify it's applied to your Droplet

**Verify Lockdown**:
```bash
# From a machine WITHOUT Twingate Client - should timeout
ssh <user>@<droplet-ip>
# Expected: Connection timeout (no SSH port exposed)

# From your machine WITH Twingate Client - should work
ssh <user>@<droplet-ip>
# Expected: Connected via Twingate
```

✅ **Checkpoint**: VPC is completely locked down. All access is via Twingate only.

---

## Alternative: Terraform Automation (Optional)

For repeatable, automated infrastructure deployment, use the provided Terraform configuration files in this directory.

### Prerequisites

1. Install Terraform ([download here](https://www.terraform.io/downloads))
2. Gather required credentials:
   - DigitalOcean API token
   - Twingate Connector tokens (from Twingate Admin Console)
   - SSH key fingerprint

### Quick Start

1. **Copy the example variables file**:
   ```bash
   cd terraform/digitalocean
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars`** with your values:
   - `do_token`: Your DigitalOcean API token
   - `twingate_access_token`: From Twingate Admin Console
   - `twingate_refresh_token`: From Twingate Admin Console
   - `twingate_network`: Your Twingate network name (without .twingate.com)
   - `ssh_fingerprint`: Your SSH key fingerprint from DigitalOcean
   - `region`, `droplet_size`: Customize as needed

3. **Deploy**:
   ```bash
   terraform init
   terraform plan    # Review what will be created
   terraform apply   # Deploy infrastructure
   ```

### What Gets Created

The Terraform configuration will automatically create:
- **Firewall**: Zero inbound rules, all outbound allowed
- **Droplet**: Ubuntu with Moltbot marketplace image
- **Reserved IP**: Static IP address for the droplet
- **Caddy Configuration**: Via cloud-init, restricts to private IP only
- **Twingate Connector**: Installed and configured via cloud-init

### Files Included

- [`main.tf`](main.tf): Main infrastructure configuration
- [`variables.tf`](variables.tf): Variable definitions
- [`cloud-init.yaml`](cloud-init.yaml): Automated server configuration
- [`terraform.tfvars.example`](terraform.tfvars.example): Example variables template

### After Deployment

1. Get the droplet IP from Terraform outputs:
   ```bash
   terraform output moltbot_private_ip
   ```

2. **Configure Twingate Resource** (required for access):
   - Go to Twingate Admin Console
   - Navigate to **Resources → Add Resource**
   - Configure:
     - **Name**: Moltbot Gateway
     - **Address**: Use the `moltbot_private_ip` from step 1
   - Install Twingate Client on your local machine

   See Step 3.3 in the main guide above for detailed instructions.

3. **Configure AI Provider**: After Twingate resource is set up:
   - SSH into the droplet via Twingate
   - Follow the [Model Providers documentation](https://docs.molt.bot/concepts/model-providers#model-providers) to configure providers
   - Restart the gateway: `systemctl restart moltbot`

**Note**: The gateway will prompt for AI provider configuration on first access if not already configured.

---

## Step 5: Production Considerations

### 5.1 Monitoring

**Built-in DigitalOcean Monitoring** (enabled during Droplet creation):
- CPU, memory, disk usage
- Bandwidth monitoring
- Alert notifications

**Check Service Health**:
```bash
# Gateway health
moltbot health
moltbot status

# Connector health
sudo systemctl status twingate-connector

# Resource usage
htop
df -h
```

### 5.2 Backups

**Config Backup**:
```bash
# Backup Moltbot config
tar -czf moltbot-backup.tar.gz ~/.moltbot/

# Includes:
# - moltbot.json (main config)
# - gateway.auth.token
# - agent auth profiles
# - OAuth credentials (if used)
# - workspace/skills

# Upload to DigitalOcean Spaces or S3
s3cmd put moltbot-backup.tar.gz s3://backups/
```

### 5.3 Security Hardening
```bash
# Enable automatic security updates
apt-get install -y unattended-upgrades

# Rotate Gateway tokens regularly
moltbot security rotate-tokens

# Review Twingate audit logs weekly
# Admin Console → Activity → Audit Logs
```

---

## Troubleshooting

### Issue: Can't connect to Gateway through Twingate

**Symptoms**: Timeout or connection refused

**Debug Steps**:
1. Verify Twingate Client is connected
   ```bash
   twingate status
   ```

2. Check Connector status in Admin Console
   - Should show "Connected"
   - Check last seen timestamp

3. Verify resource configuration
   - Correct IP address
   - Correct port (18789)
   - User has access policy

4. Verify SSH tunnel is open
```bash
ssh -L 18789:127.0.0.1:18789 user@your-server-ip
```

5. Test from Connector host
   ```bash
   # SSH to Connector host
   curl http://127.0.0.1:18789/health
   ```

6. Check Gateway is listening
   ```bash
   # On Gateway host
   netstat -tlnp | grep 18789
   # Should show: 127.0.0.1:18789 LISTEN
   ```

### Issue: Authentication failing

**Symptoms**: 401 Unauthorized errors

**Debug Steps**:
1. Verify Gateway token is set
   ```bash
   echo $MOLTBOT_GATEWAY_TOKEN
   ```

2. Check token in CLI command
   ```bash
   moltbot --url ws://<ip>:18789 --token <token> health
   ```

3. Review Gateway logs
   ```bash
   journalctl -u moltbot-gateway -n 100 | grep auth
   ```

### Issue: Twingate Connector offline

**Symptoms**: Resource unreachable, Connector shows "Disconnected"

**Debug Steps**:
1. Check Connector service
   ```bash
   systemctl status twingate-connector
   ```

2. Review Connector logs
   ```bash
   journalctl -u twingate-connector -f
   ```

3. Verify network connectivity
   ```bash
   # Test Twingate Cloud connectivity
   ping <network>.twingate.com
   ```

4. Regenerate Connector tokens if needed
   - Admin Console → Connectors → Regenerate Tokens
   - Update Connector configuration
   - Restart service

---

## Support & Resources

### Twingate Resources
- [Documentation](https://docs.twingate.com)
- [Support Portal](https://help.twingate.com)
- [Community Forum](https://community.twingate.com)
- [Status Page](https://status.twingate.com)

### Moltbot Resources
- [Documentation](https://docs.molt.bot)
- [Getting Started](https://docs.molt.bot/start/getting-started)
- [GitHub](https://github.com/moltbot/moltbot)
- Community Discord (check GitHub README)

### Getting Help
- Twingate Support: support@twingate.com
- Twingate Sales: sales@twingate.com (for enterprise features)
- Emergency: Check support portal for 24/7 options

---

## Conclusion

You now have a production-ready Clawdbot deployment on DigitalOcean with:

✅ **Private by Default**: Gateway never exposed to internet  
✅ **Secure Access**: Twingate Zero Trust instead of SSH tunnels  
✅ **Resource Efficient**: Single Droplet runs everything  
✅ **Observable**: Full audit logs and monitoring  
✅ **Scalable**: Easy to add team members and regions  

**Next Steps**:
- Configure custom skills for your use case
- Set up automated backups to DigitalOcean Spaces
- Add more team members via Twingate
- Explore multi-region deployment

**Questions?** Check the troubleshooting section or reach out to Twingate support.

---

## Appendix: Complete Terraform Example

See the reference repository for complete Infrastructure as Code for DigitalOcean:
- `terraform/digitalocean/` - Production-ready Terraform modules
- `kubernetes/digitalocean/` - DigitalOcean Kubernetes (DOKS) deployment
- `scripts/` - Utility scripts for backup, monitoring, maintenance

**Includes**:
- VPC and network configuration
- Twingate Connector / Clawdbot Gateway Droplet
- DigitalOcean Firewall rules

**Clone and deploy**:
```bash
git clone https://github.com/twingate/clawdbot-digitalocean
cd clawdbot-digitalocean/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply
```

Happy deploying! 🚀
