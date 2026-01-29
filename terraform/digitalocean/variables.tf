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
  description = "Droplet size for Moltbot Gateway"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "ssh_fingerprint" {
  description = "SSH key fingerprint for Droplet access"
  type        = string
}

variable "gateway_token" {
  description = "Moltbot Gateway authentication token"
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
