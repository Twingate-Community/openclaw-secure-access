# Secure OpenClaw Deployments

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-1.0+-purple.svg)](https://www.terraform.io/)

Production-ready deployment guides for [OpenClaw](https://molt.bot) (AI-powered chat assistant) across multiple cloud providers and platforms, with Zero Trust security via [Twingate](https://www.twingate.com).

## 🎯 What This Is

A curated collection of **Infrastructure as Code** and **step-by-step guides** for deploying OpenClaw securely in any environment. Each deployment includes:

- ✅ **Terraform automation** (where applicable)
- ✅ **Zero Trust security** with Twingate
- ✅ **No public port exposure** (Gateway on localhost only)
- ✅ **Production-ready configuration**
- ✅ **Cost-optimized** for small teams

## 🚀 Available Deployments

| Platform | Guide | Infrastructure |
|----------|-------|----------------|
| **DigitalOcean** | [Deployment Guide](terraform/digitalocean/digital-ocean-deployment-guide.md) | [Terraform](terraform/digitalocean/) |

## 🏗️ Architecture Pattern

All deployments follow a consistent security-first architecture:

```
┌─────────────────────────────────────────┐
│  Cloud Provider (DO/AWS/GCP/Azure/etc)  │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  VM/Container/Droplet           │    │
│  │                                 │    │
│  │  ┌──────────────────────────┐   │    │
│  │  │ OpenClaw Gateway          │   │    │
│  │  │ Binds: localhost:18789   │   │    │
│  │  └──────────────────────────┘   │    │
│  │                                 │    │
│  │  ┌──────────────────────────┐   │    │
│  │  │ Twingate Connector       │   │    │
│  │  │ Outbound-only connection │   │    │
│  │  └──────────────────────────┘   │    │
│  │                                 │    │
│  │  Firewall: Zero inbound rules   │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
                  ↓
          [Twingate Cloud]
         Zero Trust Policies
                  ↓
            [Your Team]
        Secure remote access
```

### Security Principles

1. **Zero Inbound Ports**: Gateway binds to localhost only, no public exposure
2. **Zero Trust Access**: All connections via Twingate with granular policies
3. **Outbound-Only**: Connector initiates outbound connection to Twingate cloud
4. **Audit Logging**: Track all access attempts and sessions
5. **MFA Enforcement**: Optional but recommended for all team members

## 📚 Quick Start

### Choose Your Platform

1. Browse the [deployments table](#-available-deployments) above
2. Click on your preferred platform's deployment guide
3. Follow the step-by-step instructions

### Common Prerequisites

All deployments require:

- **Cloud/Platform Account**: Sign up for your chosen provider
- **Twingate Account**: [Free account](https://www.twingate.com) for Zero Trust access

## 🔧 What is OpenClaw?

[OpenClaw](https://openclaw.ai) is an AI-powered assistant that runs on WhatsApp and Telegram. It provides:

- **Claude/GPT Integration**: Chat with Claude or GPT via WhatsApp/Telegram
- **Tool Support**: Web search, code execution, file handling
- **Multi-user**: Team access with role-based controls
- **Self-hosted**: You control the data and infrastructure

### Why Self-Host?

- **Privacy**: Your conversations never leave your infrastructure
- **Control**: Full control over AI provider, models, and configuration
- **Cost**: Pay only for what you use (API calls + infrastructure)
- **Security**: Zero Trust architecture with enterprise-grade access controls

## 🔐 Security Best Practices

All deployments in this repo follow these principles:

1. **Never expose Gateway publicly**: Always bind to `localhost/127.0.0.1`
2. **Zero inbound firewall rules**: Use Twingate for all remote access
3. **Secrets management**: Never commit API keys or tokens
4. **Least privilege**: Grant minimum required permissions
5. **Enable MFA**: Require multi-factor auth for Twingate access
6. **Monitor access**: Review Twingate audit logs regularly
7. **Keep updated**: Regularly update OS, Docker images, and dependencies

## 📖 Additional Resources

- [OpenClaw Documentation](https://docs.openclaw.ai/)
- [Twingate Documentation](https://docs.twingate.com)

## 📝 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙋 Support

- **Issues**: [GitHub Issues](https://github.com/Twingate-Community/openclaw-secure-access/issues)
- **Twingate Subreddit**: [r/Twingate](https://reddit.com/r/twingate)

---

Built with ❤️ for secure, self-hosted AI assistants.
