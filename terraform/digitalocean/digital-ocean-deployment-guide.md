# How to Setup and Secure Clawdbot on DigitalOcean

## Overview

This guide walks you through deploying Clawdbot (AI-powered WhatsApp/Telegram assistant) on DigitalOcean, then securing it with Twingate's Zero Trust network access. You'll go from zero to a production-ready AI agent platform with enterprise security in under an hour.

**What You'll Build**:
- Clawdbot Gateway running on DigitalOcean Droplet
- WhatsApp/Telegram bot integration
- Secure access via Twingate (no public exposure)
- Production-ready with monitoring and backups

**Infrastructure**:
- 1 DigitalOcean Droplet (2-4 vCPU, 4-8 GB RAM recommended)
- Twingate Connector for secure access (no public Gateway exposure)
- Private networking only

**Who This Is For**:
- Developers wanting to self-host AI assistants
- Teams needing secure, private AI agent infrastructure
- Anyone moving from Tailscale to more granular access control

**Time to Complete**: 30-45 minutes

---

### Architecture Overview

```
[DigitalOcean Droplet]
     ↓
[Moltbot/Clawdbot Gateway] ← Node.js app on localhost:18789
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
- [ ] SSH key added to DigitalOcean
- [ ] WhatsApp or Telegram account (for bot setup)

### Optional
- [ ] Terraform (for automated deployment)
- [ ] DigitalOcean Spaces (for backups)

---

## Step 1: Create DigitalOcean Droplet (5 minutes)

### 1.1 Choose Your Deployment Method

**Option A: Manual Setup** (recommended for first time)  
**Option B: Terraform** (for automation/repeatability)

We'll cover both. Start with Option A to understand what's happening.

### 1.2 Create Droplet via Web UI

1. Log into [DigitalOcean](https://cloud.digitalocean.com)
2. Click **Create → Droplets**
3. Configure:
   - **Image**: Ubuntu 22.04 LTS
   - **Size**: Basic (2 vCPU, 4 GB RAM recommended)
   - **Region**: Choose closest to your team
   - **VPC**: Create new VPC or use default
   - **SSH Key**: Add your public key
   - **Hostname**: `clawdbot-gateway`
   - **Enable Monitoring**: ✓
4. Click **Create Droplet**

**Note down**:
- Droplet IP address
- SSH access: `ssh root@<droplet-ip>`

---

## Step 2: Install Clawdbot (10 minutes)

### 2.1 SSH into Your Droplet

```bash
ssh root@<your-droplet-ip>
```

### 2.2 Install Node.js 22

Clawdbot requires Node.js ≥22:

```bash
# Install Node.js 22
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# Verify
node --version  # Should show v22.x
```

### 2.3 Install Moltbot CLI

```bash
# Install via official script
curl -fsSL https://molt.bot/install.sh | bash

# Verify
moltbot --version
```

### 2.4 Run Onboarding Wizard

```bash
# Start the wizard
moltbot onboard --install-daemon
```

**Wizard Configuration**:
1. **Gateway Type**: Local (runs on this server)
2. **Auth**: Anthropic API key (paste yours)
3. **Channels**: Select WhatsApp or Telegram
   - WhatsApp: QR login in next step
   - Telegram: Need bot token from @BotFather
4. **Daemon**: Yes (installs systemd service)

**What this creates**:
- Config: `~/.clawdbot/moltbot.json`
- Service: `moltbot-gateway` (systemd)
- Gateway binds to `127.0.0.1:18789` (localhost only)

### 2.5 Connect Chat Platform

**For WhatsApp**:
```bash
moltbot channels login
# Scan QR code with WhatsApp app
# Settings → Linked Devices → Link a Device
```

**For Telegram**:
```bash
# Create bot via @BotFather first
# Then wizard will have configured it
# Or manually edit ~/.clawdbot/moltbot.json
```

### 2.6 Verify Installation

```bash
# Check gateway status
moltbot gateway status

# Health check
moltbot health

# View logs
journalctl -u moltbot-gateway -f
```

**Expected**: Gateway running on port 18789, all health checks pass.

✅ **Checkpoint**: Clawdbot is running on localhost. Now let's set up secure access.

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
  TWINGATE_LABEL_DEPLOYED_BY="clawdbot" \
  bash

# Verify
sudo systemctl status twingate-connector
```

### 3.3 Create Twingate Resources

In Twingate Admin Console:

**Resource 1: Clawdbot Gateway**
1. Go to **Resources → Add Resource**
2. Configure:
   - **Name**: Clawdbot Gateway
   - **Address**: `<droplet-private-ip>`
3. **Create Resource**

### 3.4 Set Access Policy

1. Go to **Access → Policies**
2. Create policy:
   - **Name**: Clawdbot Team Access
   - **Resources**: Clawdbot Gateway
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
   - **Name**: `clawdbot-secure`
   - **Apply to Droplets**: Select your `clawdbot-gateway` Droplet

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

For repeatable infrastructure, use Terraform:

### Terraform Configuration

**terraform/digitalocean/main.tf**:
```hcl
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

# VPC for private networking
resource "digitalocean_vpc" "clawdbot" {
  name     = "clawdbot-vpc"
  region   = var.region
  ip_range = "10.10.10.0/24"
}

# Firewall for Clawdbot + Twingate
resource "digitalocean_firewall" "clawdbot" {
  name = "clawdbot-twingate"

  droplet_ids = [digitalocean_droplet.clawdbot.id]

  # Allow outbound to internet (for API calls and Twingate)
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # No public access to Gateway port
  # Access only via Twingate Connector (localhost)
}

# Droplet for Twingate Connector + Clawdbot Gateway
resource "digitalocean_droplet" "clawdbot" {
  image    = "ubuntu-22-04-x64"
  name     = "clawdbot-twingate"
  region   = var.region
  size     = var.droplet_size
  vpc_uuid = digitalocean_vpc.clawdbot.id

  ssh_keys = [var.ssh_fingerprint]
  monitoring = true  # Enable DO monitoring

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    anthropic_api_key      = var.anthropic_api_key
    gateway_token          = var.gateway_token
    twingate_access_token  = var.twingate_access_token
    twingate_refresh_token = var.twingate_refresh_token
    twingate_network       = var.twingate_network
  })

  tags = ["clawdbot", "twingate"]
}

# Optional: Reserved IP for stability
resource "digitalocean_reserved_ip" "clawdbot" {
  droplet_id = digitalocean_droplet.clawdbot.id
  region     = var.region
}

# Outputs
output "clawdbot_private_ip" {
  value = digitalocean_droplet.clawdbot.ipv4_address_private
}

output "clawdbot_public_ip" {
  value = digitalocean_reserved_ip.clawdbot.ip_address
  description = "Use for initial SSH access, then restrict via firewall"
}
```

**terraform/digitalocean/cloud-init.yaml**:
```yaml
#cloud-config

package_update: true
package_upgrade: true

packages:
  - curl
  - git
  - htop
  - docker.io

write_files:
  - path: /etc/clawdbot/config.json
    permissions: '0600'
    content: |
      {
        "gateway": {
          "bind": "loopback",
          "port": 18789,
          "auth": {
            "mode": "token"
          },
          "controlUi": {
            "enabled": true
          }
        },
        "agents": {
          "defaults": {
            "provider": "anthropic",
            "model": "claude-3-5-sonnet-20241022",
            "sandbox": {
              "mode": "non-main"
            }
          }
        },
        "pairing": {
          "defaults": {
            "mode": "approval-required"
          }
        }
      }

  - path: /etc/environment
    append: true
    content: |
      ANTHROPIC_API_KEY="${anthropic_api_key}"
      CLAWDBOT_GATEWAY_TOKEN="${gateway_token}"
      TWINGATE_ACCESS_TOKEN="${twingate_access_token}"
      TWINGATE_REFRESH_TOKEN="${twingate_refresh_token}"
      TWINGATE_NETWORK="${twingate_network}"

runcmd:
  # Install Node.js 22
  - curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  - apt-get install -y nodejs
  
  # Install Moltbot/Clawdbot
  - curl -fsSL https://molt.bot/install.sh | bash
  
  # Install Twingate Connector
  - |
    curl "https://binaries.twingate.com/connector/setup.sh" | \
    TWINGATE_ACCESS_TOKEN="${twingate_access_token}" \
    TWINGATE_REFRESH_TOKEN="${twingate_refresh_token}" \
    TWINGATE_NETWORK="${twingate_network}" \
    TWINGATE_LABEL_DEPLOYED_BY="clawdbot-auto" \
    bash
  
  # Configure and start Moltbot
  - mkdir -p ~/.clawdbot
  - source /etc/environment
  - moltbot onboard --install-daemon --non-interactive || true
  - systemctl enable moltbot-gateway
  - systemctl start moltbot-gateway
  
  # Verify services
  - systemctl status twingate-connector
  - systemctl status moltbot-gateway
  
  - echo "Twingate Connector and Clawdbot Gateway deployed"

final_message: "Both services ready after $UPTIME seconds"
```

**terraform/digitalocean/variables.tf**:
```hcl
variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc3"
}

variable "droplet_size" {
  description = "Droplet size for Clawdbot Gateway"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "ssh_fingerprint" {
  description = "SSH key fingerprint for Droplet access"
  type        = string
}

variable "anthropic_api_key" {
  description = "Anthropic API key"
  type        = string
  sensitive   = true
}

variable "gateway_token" {
  description = "Clawdbot Gateway authentication token"
  type        = string
  sensitive   = true
}

variable "twingate_access_token" {
  description = "Twingate Connector access token"
  type        = string
  sensitive   = true
}

variable "twingate_refresh_token" {
  description = "Twingate Connector refresh token"
  type        = string
  sensitive   = true
}

variable "twingate_network" {
  description = "Twingate network name"
  type        = string
}

variable "admin_ip_address" {
  description = "Your IP address for SSH access (CIDR format)"
  type        = string
}
```

**terraform/digitalocean/terraform.tfvars** (create this, don't commit):
```hcl
do_token               = "dop_v1_xxxxx"
region                 = "nyc3"
droplet_size           = "s-2vcpu-4gb"
ssh_fingerprint        = "your-ssh-key-fingerprint"
anthropic_api_key      = "sk-ant-xxxxx"
gateway_token          = "your-secure-random-token"
twingate_access_token  = "your-twingate-access-token"
twingate_refresh_token = "your-twingate-refresh-token"
twingate_network       = "yourcompany"
admin_ip_address       = "1.2.3.4/32"  # Your IP for SSH
```

**Deploy**:
```bash
cd terraform/digitalocean
terraform init
terraform plan
terraform apply
```

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
tar -czf moltbot-backup.tar.gz ~/.clawdbot/

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
   echo $CLAWDBOT_GATEWAY_TOKEN
   ```

2. Check token in CLI command
   ```bash
   clawdbot --url ws://<ip>:18789 --token <token> health
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

### Clawdbot/Moltbot Resources
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
