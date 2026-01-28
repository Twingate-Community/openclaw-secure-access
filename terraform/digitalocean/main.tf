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

  ssh_keys   = [var.ssh_fingerprint]
  monitoring = true # Enable DO monitoring

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
  value       = digitalocean_reserved_ip.clawdbot.ip_address
  description = "Use for initial SSH access, then restrict via firewall"
}
