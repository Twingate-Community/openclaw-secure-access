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
resource "digitalocean_vpc" "moltbot" {
  name   = "moltbot-vpc"
  region = var.region
}

# Firewall for Moltbot + Twingate
resource "digitalocean_firewall" "moltbot" {
  name = "moltbot-twingate"

  droplet_ids = [digitalocean_droplet.moltbot.id]
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

# Droplet for Twingate Connector + Moltbot Gateway
resource "digitalocean_droplet" "moltbot" {
  image    = "moltbot" # DigitalOcean Marketplace image
  name     = "moltbot-twingate"
  region   = var.region
  size     = var.droplet_size
  vpc_uuid = digitalocean_vpc.moltbot.id

  ssh_keys   = [var.ssh_fingerprint]
  monitoring = true # Enable DO monitoring

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    gateway_token          = var.gateway_token
    twingate_access_token  = var.twingate_access_token
    twingate_refresh_token = var.twingate_refresh_token
    twingate_network       = var.twingate_network
  })

  tags = ["moltbot", "twingate"]
}

# Optional: Reserved IP for stability
resource "digitalocean_reserved_ip" "moltbot" {
  droplet_id = digitalocean_droplet.moltbot.id
  region     = var.region
}

# Outputs
output "moltbot_private_ip" {
  value = digitalocean_droplet.moltbot.ipv4_address_private
}
