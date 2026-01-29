# Terraform Files for Moltbot on DigitalOcean

This directory contains Terraform configuration for deploying Moltbot with Twingate on DigitalOcean.

## Files

- `main.tf` - Main Terraform configuration (VPC, Firewall, Droplet)
- `variables.tf` - Variable definitions
- `cloud-init.yaml` - Cloud-init configuration for automated setup
- `terraform.tfvars.example` - Example variables file (copy and customize)

## Usage

1. **Copy the example variables file**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars`** with your values:
   - DigitalOcean API token
   - Anthropic API key
   - Twingate tokens (from Twingate Admin Console)
   - SSH key fingerprint
   - Your IP address for initial SSH access

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Review the plan**:
   ```bash
   terraform plan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## What Gets Created

- **Firewall**: Zero inbound rules, all outbound allowed
- **Droplet**: Ubuntu 22.04 with Twingate Connector + Moltbot Gateway
- **Reserved IP**: Optional static IP for the Droplet

## Security Notes

- **Never commit `terraform.tfvars`** - it contains secrets
- The firewall has ZERO inbound rules - all access via Twingate
- Gateway runs on localhost:18789 only
- Twingate provides secure remote access

## After Deployment

1. Get the Droplet IP from outputs
2. Configure Twingate Resources in Admin Console
3. Access via Twingate Client

See the main deployment guide for complete setup instructions.
