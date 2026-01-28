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
